// -*- mode: verilog; mode: font-lock; indent-tabs-mode: nil -*-
// vi: set et ts=3 sw=3 sts=3:
//
// Copyright 2021-2026 Steffen Persvold
// SPDX-License-Identifier: Apache-2.0
//
// ========================================================================
// File        : hdmi_pll_recfg.sv
// Author      : Steffen Persvold
// ========================================================================
// Description : Agilex 5 HVIO I/O PLL dynamic reconfiguration FSM.
//
//   Drives the hdmi_pll core_avl reconfiguration interface to retune the
//   pixel clock (C0 output) to arbitrary M/N/C divisor settings, then
//   recalibrates the PLL. Implements the byte-burst AVL transaction
//   protocol and the reconfigure -> reset -> recalibrate sequence from the
//   "Clocking and PLL User Guide: Agilex 5 FPGAs and SoCs" (doc 813671),
//   sections 6.2/6.3.
//
//   Every step is a READ-MODIFY-WRITE (per the user guide, section 6.3): read
//   the current value, change only the documented bits (a per-register mask),
//   write it back. Most registers share their 32 bits with settings we must
//   NOT disturb (charge pump 0x44 only owns [15:1]; the control/status regs
//   hold several bits each) -- overwriting a byte that is only partly ours can
//   make the PLL lose lock. The M+N (0x40) and C0 (0x5C) counters are fully
//   defined by the divide settings, so they take the same RMW path with an
//   all-ones mask -- effectively a whole-word write.
//
//   Runs entirely in the core_avl_clk domain (board: CLOCK0_50). The
//   start/done/status handshake to the clk_sys CSR domain is crossed
//   externally (cdc_tgl + synchronizer); m/n/c are quasi-static.
//
//   Sequence (documented flow; every step is a read-modify-write):
//     0x10 [0]=1        ; enable reconfiguration
//     0x58 [7]=0,[21]=0 ; clear calibration status
//     0x40 M + N        ; M total, N high/low/odd/bypass (all bits)
//     0x44 [15:1]=cp(M) ; charge pump current (must track M)
//     0x5C C0           ; C0 high/low/odd/bypass + preset/mux (all bits)
//     0x80 [2]=1        ; assert PLL reset
//     0x80 [2]=0        ; release PLL reset
//     0x48 [14]=1       ; enable calibration
//     0x88 [11]=1       ; initiate calibration
//     wait locked       ; (drop then re-assert), with timeout -> error
//     0x48 [14]=0       ; disable calibration (after relock)
//     confirm locked    ; require lock stable for a settling window before done
//                       ;   (the disable write can briefly disturb the lock; a
//                       ;   poller must not sample the dip), timeout -> error
//     done
// ========================================================================
//

module hdmi_pll_recfg
  #(
    parameter int unsigned PRE  = 5,   // AVL preamble (write) / discard (read) cycles
    parameter int unsigned IDLE = 5    // AVL inter-transaction idle cycles
    )
  (
   input  logic        clk,             // core_avl_clk domain (CLOCK0_50)
   input  logic        rst_n,           // active-low reset, clk domain

   // Control / status (already crossed into this domain)
   input  logic        start,           // 1-cycle start pulse
   input  logic [ 8:0] m,               // M total count (quasi-static)
   input  logic [ 6:0] n,               // N divide       (quasi-static)
   input  logic [ 8:0] c,               // C0 divide      (quasi-static)
   input  logic        pll_locked_in,   // raw PLL locked (synced internally)

   output logic        done,            // 1-cycle completion/abort pulse
   output logic        error,           // recal timeout/failure (level)

   // core_avl master to hdmi_pll
   output logic [ 8:0] avl_address,
   output logic        avl_write,
   output logic [ 7:0] avl_writedata,
   output logic        avl_read,
   input  logic [ 7:0] avl_readdata
   );

   // ------------------------------------------------------------------
   // core_avl register addresses (doc 813671 Table 21)
   // ------------------------------------------------------------------
   localparam logic [8:0] A_REGEN   = 9'h010; // registers enable (d[0])
   localparam logic [8:0] A_CLRCAL  = 9'h058; // clear cal status (d[7],d[21])
   localparam logic [8:0] A_MN      = 9'h040; // M + N counter
   localparam logic [8:0] A_CP      = 9'h044; // charge pump current (d[15:1])
   localparam logic [8:0] A_C0      = 9'h05C; // C0 counter
   localparam logic [8:0] A_RESET   = 9'h080; // PLL reset (d[2])
   localparam logic [8:0] A_RECALEN = 9'h048; // enable recal (d[14])
   localparam logic [8:0] A_RECALRQ = 9'h088; // request recal (d[11])

   // Per-register RMW masks: the documented bits we are allowed to change.
   // Everything outside the mask is preserved from the read. Every step is a
   // read-modify-write; the counter regs (0x40, 0x5C) just use an all-ones
   // mask so they overwrite the full word.
   localparam logic [31:0] MASK_REGEN   = 32'h0000_0001; // [0]
   localparam logic [31:0] MASK_CLRCAL  = 32'h0020_0080; // [21],[7]
   localparam logic [31:0] MASK_CP      = 32'h0000_FFFE; // [15:1]
   localparam logic [31:0] MASK_RESET   = 32'h0000_0004; // [2]
   localparam logic [31:0] MASK_RECALEN = 32'h0000_4000; // [14]
   localparam logic [31:0] MASK_RECALRQ = 32'h0000_0800; // [11]

   // ------------------------------------------------------------------
   // Lock synchronizer into this domain
   // ------------------------------------------------------------------
   logic locked_s;
   synchronizer #(.DEPTH(3)) u_lock_sync
     (.clk(clk), .d(pll_locked_in), .q(locked_s));

   // ------------------------------------------------------------------
   // Divisor -> counter field encoding:
   //   high = ceil(D/2), low = floor(D/2), odd = D[0], bypass = (D==1)
   // ------------------------------------------------------------------

   // Charge pump current code, data[15:1] = {[15:11],[10:6],[5:1]}
   // (doc 813671 Table 23, deduped; M range here is 4..320).
   function automatic logic [14:0] cp_code(input logic [8:0] mm);
      if      (mm <= 9'd7)   cp_code = {5'b00011, 5'b10001, 5'b11010};
      else if (mm <= 9'd10)  cp_code = {5'b00010, 5'b10000, 5'b11000};
      else if (mm <= 9'd15)  cp_code = {5'b00010, 5'b01100, 5'b10010};
      else if (mm <= 9'd23)  cp_code = {5'b00001, 5'b01001, 5'b01110};
      else if (mm <= 9'd43)  cp_code = {5'b00000, 5'b01000, 5'b01100};
      else if (mm <= 9'd64)  cp_code = {5'b00000, 5'b00110, 5'b01001};
      else if (mm <= 9'd85)  cp_code = {5'b00000, 5'b00110, 5'b00110};
      else if (mm <= 9'd124) cp_code = {5'b00000, 5'b00101, 5'b00101};
      else if (mm <= 9'd160) cp_code = {5'b00000, 5'b00011, 5'b00011};
      else                   cp_code = {5'b00000, 5'b00010, 5'b00010};
   endfunction

   // ------------------------------------------------------------------
   // Per-register field values (only the masked bits matter; the rest are
   // preserved by the RMW so they are left 0 here).
   // ------------------------------------------------------------------
   logic [ 8:0] mr;
   logic [ 6:0] nr;
   logic [ 8:0] cr;

   logic [31:0] v_mn, v_cp, v_c0;
   always_comb begin
      // M + N counter (0x40)
      v_mn          = 32'h0;
      v_mn[28:20]   = mr;                   // M total count
      v_mn[31]      = 1'b0;                 // M bypass (M>=4, never bypass)
      v_mn[ 7:0]    = 8'((nr + 7'd1) >> 1); // N high
      v_mn[16:9]    = 8'(nr >> 1);          // N low
      v_mn[17]      = nr[0];                // N odd
      v_mn[ 8]      = (nr == 7'd1);         // N bypass
      // Charge pump (0x44)
      v_cp          = 32'h0;
      v_cp[15:1]    = cp_code(mr);
      // C0 counter (0x5C) -- full write, so author preset/phasemux too
      v_c0          = 32'h0;
      v_c0[ 7:0]    = 8'((cr + 9'd1) >> 1); // C high
      v_c0[30:23]   = 8'(cr >> 1);          // C low
      v_c0[31]      = cr[0];                // C odd
      v_c0[ 8]      = (cr == 9'd1);         // C bypass
      v_c0[18:11]   = 8'd1;                 // counter preset = 1 (no phase shift)
      v_c0[21:19]   = 3'd0;                 // phase mux preset = 0
   end

   // ==================================================================
   // Byte-burst transaction engine (read or write).
   //   Both strobe core_avl for PRE+5 cycles, then idle IDLE cycles.
   //   Write: PRE x 0x00 preamble, then 4 payload bytes LSB..MSB with the
   //          last byte held one extra cycle.
   //   Read : PRE discard cycles + the always-0x00 first valid word, then
   //          4 valid bytes LSB..MSB captured into te_rdata.
   //   Address held constant throughout.
   // ==================================================================
   localparam int unsigned ACT = PRE + 5;   // active-strobe cycles

   typedef enum logic [1:0] {TE_IDLE, TE_ACT, TE_POST} te_state_t;
   te_state_t   te_st;
   logic [3:0]  te_cnt;
   logic        te_we;
   logic [ 8:0] te_addr;
   logic [31:0] te_wdata;
   logic [31:0] te_rdata;
   logic        te_start;
   logic        te_done;

   // write byte select: 0x00 during preamble, then payload bytes (last held)
   logic [7:0]  te_wbyte;
   always_comb begin
      te_wbyte = 8'h00;
      if (te_cnt >= 4'(PRE))
        unique case (4'(te_cnt - 4'(PRE)))
          4'd0:    te_wbyte = te_wdata[ 7: 0];
          4'd1:    te_wbyte = te_wdata[15: 8];
          4'd2:    te_wbyte = te_wdata[23:16];
          default: te_wbyte = te_wdata[31:24]; // byte 3 and its hold cycle
        endcase
   end

   always_ff @(posedge clk or negedge rst_n)
     if (~rst_n)
       begin
          te_st   <= TE_IDLE;
          te_cnt  <= '0;
          te_done <= 1'b0;
          te_rdata<= '0;
       end
     else
       begin
          te_done <= 1'b0;
          unique case (te_st)
            TE_IDLE :
              if (te_start)
                begin
                   te_cnt <= '0;
                   te_st  <= TE_ACT;
                end
            TE_ACT :
              begin
                 // read capture: skip PRE discard + the 0x00 first valid word
                 if (~te_we)
                   unique case (te_cnt)
                     4'(PRE+1): te_rdata[ 7: 0] <= avl_readdata;
                     4'(PRE+2): te_rdata[15: 8] <= avl_readdata;
                     4'(PRE+3): te_rdata[23:16] <= avl_readdata;
                     4'(PRE+4): te_rdata[31:24] <= avl_readdata;
                     default: ;
                   endcase
                 if (te_cnt == 4'(ACT-1))
                   begin
                      te_cnt <= '0;
                      te_st  <= TE_POST;
                   end
                 else
                   te_cnt <= te_cnt + 4'd1;
              end
            TE_POST :
              if (te_cnt == 4'(IDLE-1))
                begin
                   te_done <= 1'b1;
                   te_st   <= TE_IDLE;
                end
              else
                te_cnt <= te_cnt + 4'd1;
            default : te_st <= TE_IDLE;
          endcase
       end

   // The hardened HVIO IOSSM decodes core_avl_address as a 32-bit WORD index,
   // but doc 813671 Table 21 (and our A_* localparams) are BYTE offsets -- so on
   // silicon we drop the two byte-select bits (HW-confirmed: this >>2 is what
   // made runtime reconfig actually take effect; without it every access landed
   // four registers high). The Altera .vo and the Verilator stub model the
   // conduit as byte-addressed, so in simulation we drive the byte offset as-is.
`ifdef SIMULATION
   assign avl_address   = te_addr;
`else
   assign avl_address   = {2'b00, te_addr[8:2]};
`endif
   assign avl_write     = (te_st == TE_ACT) &  te_we;
   assign avl_read      = (te_st == TE_ACT) & ~te_we;
   assign avl_writedata = ((te_st == TE_ACT) & te_we) ? te_wbyte : 8'h00;

   // ==================================================================
   // Main reconfiguration sequencer. Each step is read -> modify -> write.
   // ==================================================================
   typedef enum logic [2:0] {
      S_IDLE, S_DECODE, S_READ, S_WRITE, S_WLOCK_LO, S_WLOCK_HI, S_WLOCK_OK, S_DONE
   } state_t;
   state_t              state;
   logic [3:0]          step;

   logic [31:0]         op_mask;   // bits this step is allowed to change
   logic [31:0]         op_value;  // desired values for those bits

   // Timeouts, as log2(cycles). LOCK_TIMEOUT bounds the wait for the PLL to
   // re-lock after recal (-> error). LO_TIMEOUT bounds the wait to observe the
   // lock *drop* first (it may have dropped at the 0x80 reset and re-asserted
   // before we sample it). Shortened under SIMULATION so sim doesn't sit
   // through the HW-scale relock budget -- mirrors the POR-counter pattern in
   // de25_nano_top.
`ifdef SIMULATION
   localparam int unsigned LOCK_TIMEOUT = 11; // ~41 us @ 50 MHz
   localparam int unsigned LO_TIMEOUT   = 9;  // ~10 us @ 50 MHz
`else
   localparam int unsigned LOCK_TIMEOUT = 20; // ~21 ms @ 50 MHz
   localparam int unsigned LO_TIMEOUT   = 14; // ~328 us @ 50 MHz
`endif

   logic [LOCK_TIMEOUT-1:0] to_cnt;

   // Lock-stability window: before signalling done, require locked to stay high
   // this many consecutive cycles (~10 us @ 50 MHz). The 0x48 cal-disable write
   // can briefly disturb a freshly-locked PLL; gating done on a settled lock
   // keeps a poller from sampling the dip and reading "not locked". Any low
   // cycle restarts the window, and LOCK_TIMEOUT (to_cnt) still bounds it.
   localparam int unsigned STABLE_LOG = 9;
   logic [STABLE_LOG-1:0] stbl;

   always_ff @(posedge clk or negedge rst_n)
     if (~rst_n)
       begin
          state    <= S_IDLE;
          step     <= '0;
          te_start <= 1'b0;
          te_we    <= 1'b0;
          te_addr  <= '0;
          te_wdata <= '0;
          op_mask  <= '0;
          op_value <= '0;
          mr       <= '0;
          nr       <= '0;
          cr       <= '0;
          error    <= 1'b0;
          done     <= 1'b0;
          to_cnt   <= '0;
          stbl     <= '0;
       end
     else
       begin
          te_start <= 1'b0;
          done     <= 1'b0;

          unique case (state)
            S_IDLE :
              if (start)
                begin
                   mr    <= m;   // latch quasi-static divisors
                   nr    <= n;
                   cr    <= c;
                   step  <= '0;
                   error <= 1'b0;
                   state <= S_DECODE;
                end

            // Decode the current step into (addr, mask, value) and launch the
            // read; wait-lock and done steps branch out instead.
            S_DECODE :
              begin
                 te_we <= 1'b0;          // default: read phase (RMW); full-write steps override
                 // Documented reconfiguration flow -- every step is a
                 // read-modify-write (0x40/0x5C use an all-ones mask, i.e. a
                 // full write). recal-enable [14] is set before the recal and
                 // cleared AFTER relock (step 10), per the doc.
                 unique case (step)
                   4'd0  : begin te_addr <= A_REGEN;   op_mask <= MASK_REGEN;    op_value <= 32'h0000_0001; te_start <= 1'b1; state <= S_READ; end // 0x10 [0]=1   enable reconfig
                   4'd1  : begin te_addr <= A_CLRCAL;  op_mask <= MASK_CLRCAL;   op_value <= 32'h0000_0000; te_start <= 1'b1; state <= S_READ; end // 0x58 clear cal status [7],[21]
                   4'd2  : begin te_addr <= A_MN;      op_mask <= 32'hFFFF_FFFF; op_value <= v_mn;          te_start <= 1'b1; state <= S_READ; end // 0x40 M + N (all bits)
                   4'd3  : begin te_addr <= A_CP;      op_mask <= MASK_CP;       op_value <= v_cp;          te_start <= 1'b1; state <= S_READ; end // 0x44 charge pump [15:1]
                   4'd4  : begin te_addr <= A_C0;      op_mask <= 32'hFFFF_FFFF; op_value <= v_c0;          te_start <= 1'b1; state <= S_READ; end // 0x5C C0 (all bits)
                   4'd5  : begin te_addr <= A_RESET;   op_mask <= MASK_RESET;    op_value <= 32'h0000_0004; te_start <= 1'b1; state <= S_READ; end // 0x80 [2]=1   reset assert
                   4'd6  : begin te_addr <= A_RESET;   op_mask <= MASK_RESET;    op_value <= 32'h0000_0000; te_start <= 1'b1; state <= S_READ; end // 0x80 [2]=0   reset deassert
                   4'd7  : begin te_addr <= A_RECALEN; op_mask <= MASK_RECALEN;  op_value <= 32'h0000_4000; te_start <= 1'b1; state <= S_READ; end // 0x48 [14]=1  calibration enable
                   4'd8  : begin te_addr <= A_RECALRQ; op_mask <= MASK_RECALRQ;  op_value <= 32'h0000_0800; te_start <= 1'b1; state <= S_READ; end // 0x88 [11]=1  initiate calibration
                   4'd9  : begin to_cnt <= '0; state <= S_WLOCK_LO; end                                                                            // wait for PLL lock (post-recal)
                   4'd10 : begin te_addr <= A_RECALEN; op_mask <= MASK_RECALEN;  op_value <= 32'h0000_0000; te_start <= 1'b1; state <= S_READ; end // 0x48 [14]=0  calibration disable
                   4'd11 : begin to_cnt <= '0; stbl <= '0; state <= S_WLOCK_OK; end                                                                  // confirm lock is settled before done
                   default: state <= S_DONE;
                 endcase
              end

            // Read complete: merge the masked bits and launch the write-back.
            S_READ :
              if (te_done)
                begin
                   te_wdata <= (te_rdata & ~op_mask) | (op_value & op_mask);
                   te_we    <= 1'b1;
                   te_start <= 1'b1;
                   state    <= S_WRITE;
                end

            S_WRITE :
              if (te_done)
                begin
                   step  <= step + 4'd1;
                   state <= S_DECODE;
                end

            // Wait for lock to drop (recal in progress). Bounded: if we never
            // observe the drop, proceed to wait for the high level.
            S_WLOCK_LO :
              if (~locked_s | to_cnt[LO_TIMEOUT-1])
                begin
                   to_cnt <= '0;
                   state  <= S_WLOCK_HI;
                end
              else
                to_cnt <= to_cnt + 1'b1;

            // Wait for relock, with timeout -> error. Either way advance to
            // the recal-disable write so the FSM always completes.
            S_WLOCK_HI :
              if (locked_s)
                begin
                   step  <= step + 4'd1;
                   state <= S_DECODE;
                end
              else if (&to_cnt)
                begin
                   error <= 1'b1;
                   step  <= step + 4'd1;
                   state <= S_DECODE;
                end
              else
                to_cnt <= to_cnt + 1'b1;

            // Final lock-stability gate: locked must hold high for STABLE_LOG
            // consecutive cycles before done. A low cycle restarts the window;
            // to_cnt keeps climbing regardless so a never-settling lock still
            // times out to error (no deadlock).
            S_WLOCK_OK :
              if (~locked_s)
                begin
                   stbl <= '0;
                   if (&to_cnt)
                     begin error <= 1'b1; step <= step + 4'd1; state <= S_DECODE; end
                   else
                     to_cnt <= to_cnt + 1'b1;
                end
              else if (&stbl)
                begin
                   step  <= step + 4'd1;
                   state <= S_DECODE;
                end
              else
                begin
                   stbl   <= stbl + 1'b1;
                   to_cnt <= to_cnt + 1'b1;
                end

            S_DONE :
              begin
                 done  <= 1'b1;
                 state <= S_IDLE;
              end

            default : state <= S_IDLE;
          endcase
       end

endmodule // hdmi_pll_recfg
