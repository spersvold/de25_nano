// -*- mode: verilog; mode: font-lock; indent-tabs-mode: nil -*-
// vi: set et ts=3 sw=3 sts=3:
//
// Copyright 2026 Steffen Persvold
// SPDX-License-Identifier: Apache-2.0
//
// ========================================================================
// File        : lw_ctrl_bridge.sv
// Author      : Steffen Persvold
// ========================================================================
// Description : Control-plane bridge for the lightweight HPS->FPGA AXI4 bus.
//
//   Converts the 32-bit lwh2f AXI4 slave port into two downstream
//   request/acknowledge register buses, selected by address region:
//     - cfg_* : the video controller register bus, and
//     - cmd_* : the command DMA register bus.
//   Both buses share the same handshake (single-cycle pulse on *_req, target
//   replies with *_ack and, for reads, *_q/*_rdata). Any other region is
//   reserved and terminates locally (reads 0, writes accepted).
//
//   The bus is handled single-outstanding (one read OR one write transaction
//   at a time), which is sufficient for a control plane. INCR/FIXED bursts of
//   any length are supported by iterating the address one beat at a time.
//
//   Address map (offsets within the lwh2f window, byte addresses):
//     0x0_0000 .. 0x0_0FFF (4 KiB) : video controller (addr[11:2] -> cfg_adr,
//                                    bit 11 selects the CLUT inside vctrl)
//     0x0_1000 .. 0x0_1FFF (4 KiB) : command DMA registers (cmd_*)
//     everything else              : reserved (reads 0, writes accepted)
// ========================================================================
//

module lw_ctrl_bridge
  (
    input  logic         clk,        // coreclk
    input  logic         rst,        // active-high synchronous reset

    // ----------------------------------------------------------------------
    // lwh2f AXI4 slave port (32-bit data, 29-bit address)
    // ----------------------------------------------------------------------
    input  logic [ 3:0]  s_axi_awid,
    input  logic [28:0]  s_axi_awaddr,
    input  logic [ 7:0]  s_axi_awlen,
    input  logic [ 2:0]  s_axi_awsize,
    input  logic [ 1:0]  s_axi_awburst,
    input  logic         s_axi_awlock,
    input  logic [ 3:0]  s_axi_awcache,
    input  logic [ 2:0]  s_axi_awprot,
    input  logic         s_axi_awvalid,
    output logic         s_axi_awready,
    input  logic [31:0]  s_axi_wdata,
    input  logic [ 3:0]  s_axi_wstrb,
    input  logic         s_axi_wlast,
    input  logic         s_axi_wvalid,
    output logic         s_axi_wready,
    output logic [ 3:0]  s_axi_bid,
    output logic [ 1:0]  s_axi_bresp,
    output logic         s_axi_bvalid,
    input  logic         s_axi_bready,
    input  logic [ 3:0]  s_axi_arid,
    input  logic [28:0]  s_axi_araddr,
    input  logic [ 7:0]  s_axi_arlen,
    input  logic [ 2:0]  s_axi_arsize,
    input  logic [ 1:0]  s_axi_arburst,
    input  logic         s_axi_arlock,
    input  logic [ 3:0]  s_axi_arcache,
    input  logic [ 2:0]  s_axi_arprot,
    input  logic         s_axi_arvalid,
    output logic         s_axi_arready,
    output logic [ 3:0]  s_axi_rid,
    output logic [31:0]  s_axi_rdata,
    output logic [ 1:0]  s_axi_rresp,
    output logic         s_axi_rlast,
    output logic         s_axi_rvalid,
    input  logic         s_axi_rready,

    // ----------------------------------------------------------------------
    // Video controller cfg_* request/acknowledge bus (master)
    // ----------------------------------------------------------------------
    output logic         cfg_req,
    output logic [11:2]  cfg_adr,
    output logic         cfg_we,
    output logic [ 3:0]  cfg_be,
    output logic [31:0]  cfg_d,
    input  logic [31:0]  cfg_q,
    input  logic         cfg_ack,

    // ----------------------------------------------------------------------
    // Command DMA cmd_* request/acknowledge bus (master)
    // ----------------------------------------------------------------------
    output logic         cmd_req,
    output logic [11:2]  cmd_adr,
    output logic         cmd_we,
    output logic [ 3:0]  cmd_be,
    output logic [31:0]  cmd_d,
    input  logic [31:0]  cmd_q,
    input  logic         cmd_ack
    );

   // ========================================================================
   // Region decode
   // ========================================================================
   localparam logic [1:0] RESP_OKAY    = 2'b00;

   localparam logic [1:0] REGION_VCTRL = 2'd0;   // 0x0_0000 .. 0x0_0FFF
   localparam logic [1:0] REGION_DMA   = 2'd1;   // 0x0_1000 .. 0x0_1FFF
   localparam logic [1:0] REGION_RSVD  = 2'd2;   // everything else

   function automatic logic [1:0] region_of(input logic [28:0] a);
      logic [1:0] r;
      unique case (a[28:12])
        17'd0  : r = REGION_VCTRL;
        17'd1  : r = REGION_DMA;
        default: r = REGION_RSVD;
      endcase
      return r;
   endfunction

   // ========================================================================
   // FSM
   // ========================================================================
   typedef enum logic [2:0] {
      ST_IDLE,
      ST_WR,        // accept a W beat
      ST_WR_REG,    // wait for target ack (register write)
      ST_WR_NEXT,   // advance / finish write burst
      ST_B,         // write response
      ST_RD_REG,    // issue read, wait for target ack
      ST_RD_DATA    // drive R beat
   } state_t;

   state_t              state;

   logic [28:0]         addr;       // current beat byte address
   logic [ 7:0]         beats;      // remaining beats after the current one
   logic [ 3:0]         id;         // captured AWID / ARID
   logic [ 1:0]         cur_region; // target region for this transaction

   logic [31:0]         rdata_q;    // captured read data for the current beat

   // Shared request latches, broadcast to both downstream buses. Only the
   // *_req pulse (and the ack/rdata selection) differs per region.
   logic        tgt_we;
   logic [11:2] tgt_adr;
   logic [ 3:0] tgt_be;
   logic [31:0] tgt_d;

   assign cfg_adr = tgt_adr;
   assign cfg_we  = tgt_we;
   assign cfg_be  = tgt_be;
   assign cfg_d   = tgt_d;
   assign cmd_adr = tgt_adr;
   assign cmd_we  = tgt_we;
   assign cmd_be  = tgt_be;
   assign cmd_d   = tgt_d;

   // ack / read-data selected by the active region (valid for non-reserved)
   wire         tgt_ack = (cur_region == REGION_DMA) ? cmd_ack : cfg_ack;
   wire [31:0]  tgt_q   = (cur_region == REGION_DMA) ? cmd_q   : cfg_q;

   // Issue a request to the region's target: latch the shared fields and pulse
   // the matching *_req. Reserved regions never call this.
   task automatic issue_req(input logic [1:0]  rgn,
                            input logic        we,
                            input logic [11:2] a,
                            input logic [ 3:0] be,
                            input logic [31:0] d);
      tgt_we  <= we;
      tgt_adr <= a;
      tgt_be  <= be;
      tgt_d   <= d;
      if      (rgn == REGION_VCTRL) cfg_req <= 1'b1;
      else if (rgn == REGION_DMA)   cmd_req <= 1'b1;
   endtask

   always_ff @(posedge clk) begin
      // default single-cycle strobes
      cfg_req <= 1'b0;
      cmd_req <= 1'b0;

      unique case (state)
        // ------------------------------------------------------------------
        ST_IDLE: begin
           if (s_axi_awvalid) begin           // write has priority
              addr       <= s_axi_awaddr;
              beats      <= s_axi_awlen;
              id         <= s_axi_awid;
              cur_region <= region_of(s_axi_awaddr);
              state      <= ST_WR;
           end
           else if (s_axi_arvalid) begin
              addr       <= s_axi_araddr;
              beats      <= s_axi_arlen;
              id         <= s_axi_arid;
              cur_region <= region_of(s_axi_araddr);
              // kick off the first read beat
              if (region_of(s_axi_araddr) != REGION_RSVD)
                issue_req(region_of(s_axi_araddr), 1'b0, s_axi_araddr[11:2], 4'h0, 32'h0);
              state      <= ST_RD_REG;
           end
        end

        // ----- write data ------------------------------------------------
        ST_WR: begin
           if (s_axi_wvalid) begin
              if (cur_region != REGION_RSVD) begin
                 issue_req(cur_region, 1'b1, addr[11:2], s_axi_wstrb, s_axi_wdata);
                 state <= ST_WR_REG;
              end
              else begin
                 // reserved region: consume the beat, no side effect
                 state <= ST_WR_NEXT;
              end
           end
        end

        ST_WR_REG: begin
           if (tgt_ack) state <= ST_WR_NEXT;
        end

        ST_WR_NEXT: begin
           if (beats == '0) begin
              state <= ST_B;
           end
           else begin
              beats <= beats - 8'd1;
              addr  <= addr + 29'd4;
              state <= ST_WR;
           end
        end

        ST_B: begin
           if (s_axi_bready) state <= ST_IDLE;
        end

        // ----- read data -------------------------------------------------
        ST_RD_REG: begin
           if (cur_region == REGION_RSVD) begin
              rdata_q <= '0;             // reserved region reads as 0
              state   <= ST_RD_DATA;
           end
           else if (tgt_ack) begin
              rdata_q <= tgt_q;
              state   <= ST_RD_DATA;
           end
        end

        ST_RD_DATA: begin
           if (s_axi_rready) begin
              if (beats == '0) begin
                 state <= ST_IDLE;
              end
              else begin
                 beats <= beats - 8'd1;
                 addr  <= addr + 29'd4;
                 // issue the next read beat (addr still holds the current one)
                 if (cur_region != REGION_RSVD)
                   issue_req(cur_region, 1'b0, addr[11:2] + 10'd1, 4'h0, 32'h0);
                 state <= ST_RD_REG;
              end
           end
        end

        default: state <= ST_IDLE;
      endcase

      if (rst) begin
         state   <= ST_IDLE;
         cfg_req <= 1'b0;
         cmd_req <= 1'b0;
      end
   end

   // ========================================================================
   // Channel handshake outputs (combinational from state)
   // ========================================================================
   // AW is accepted in IDLE together with the decision to start a write.
   assign s_axi_awready = (state == ST_IDLE) & s_axi_awvalid;
   // AR is accepted in IDLE only when no write is starting.
   assign s_axi_arready = (state == ST_IDLE) & ~s_axi_awvalid & s_axi_arvalid;

   // W is accepted in ST_WR (target: latched into the bus the same cycle;
   // reserved: consumed directly).
   assign s_axi_wready  = (state == ST_WR) & s_axi_wvalid;

   assign s_axi_bid     = id;
   assign s_axi_bresp   = RESP_OKAY;
   assign s_axi_bvalid  = (state == ST_B);

   assign s_axi_rid     = id;
   assign s_axi_rdata   = rdata_q;
   assign s_axi_rresp   = RESP_OKAY;
   assign s_axi_rlast   = (beats == '0);
   assign s_axi_rvalid  = (state == ST_RD_DATA);

endmodule // lw_ctrl_bridge
