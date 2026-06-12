// -*- mode: verilog; mode: font-lock; indent-tabs-mode: nil -*-
// vi: set et ts=3 sw=3 sts=3:
//
// Copyright 2026 Steffen Persvold
// SPDX-License-Identifier: Apache-2.0
//
// ========================================================================
// File        : tb.sv
// Author      : Steffen Persvold
// Created     : May 16, 2026
// ========================================================================
// Description : Top testbench
// ========================================================================
//

`ifndef UNIQUE_TAG
 `define UNIQUE_TAG "NDf0EjIxjsZbmheYe4u"
`endif

`ifndef TESTNAME
 `define TESTNAME "de25_nano_top"
`endif

module tb
  ();

   timeunit 1ns;
   timeprecision 1ps;

   event done;
   bit   result;

   initial begin
      if ($test$plusargs("DUMP")) begin
         $display("%t INFO: module=%m, starting dumpfile", $time);
`ifdef HAVE_VCDPLUSON
         $vcdpluson;
`else
         $dumpfile("tb.fst");
         $dumpvars(0, tb);
`endif
      end
   end

   logic                        clk = 1'b0;
   logic                        rst = 1'b1;

   parameter real CLOCK_FREQ = 50.0; // MHz
   localparam CLOCK_PERIOD = 1000.0 / CLOCK_FREQ; // ns
   always #(CLOCK_PERIOD/2) clk = ~clk;

   //

   // CLOCK/RESET/MISC
   wire                         CLOCK0_50 = clk;
   wire                         CLOCK1_50 = clk;
   wire                         CLOCK2_50 = clk;
   wire [ 1: 0]                 KEY = {~rst, ~rst};
   wire [ 3: 0]                 SW = 4'b0000;
   wire [ 7: 0]                 LED;
`ifdef ENABLE_SDRAM
   // SDRAM
   wire                         DRAM_CLK;
   wire                         DRAM_CKE;
   wire [12: 0]                 DRAM_ADDR;
   wire [ 1: 0]                 DRAM_BA;
   wire [15: 0]                 DRAM_DQ;
   wire [ 1: 0]                 DRAM_DQM;
   wire [ 1: 0]                 DRAM_CS_n;
   wire                         DRAM_WE_n;
   wire                         DRAM_CAS_n;
   wire                         DRAM_RAS_n;
`endif //  `ifdef ENABLE_SDRAM
`ifdef ENABLE_LPDDR4A
   // LPDDR4A
   wire                         LPDDR4A_REFCLK_p;
   wire                         LPDDR4A_CS_n;
   wire [ 5: 0]                 LPDDR4A_CA;
   wire                         LPDDR4A_CK;
   wire                         LPDDR4A_CKE;
   wire                         LPDDR4A_CK_n;
   wire [ 3: 0]                 LPDDR4A_DM;
   wire [31: 0]                 LPDDR4A_DQ;
   wire [ 3: 0]                 LPDDR4A_DQS;
   wire [ 3: 0]                 LPDDR4A_DQS_n;
   wire                         LPDDR4A_RESET_n;
   wire                         LPDDR4A_RZQ;
`endif //  `ifdef ENABLE_LPDDR4A
`ifdef ENABLE_LPDDR4B
   // LPDDR4B
   wire                         LPDDR4B_REFCLK_p;
   wire                         LPDDR4B_CS_n;
   wire [ 5: 0]                 LPDDR4B_CA;
   wire                         LPDDR4B_CK;
   wire                         LPDDR4B_CKE;
   wire                         LPDDR4B_CK_n;
   wire [ 3: 0]                 LPDDR4B_DM;
   wire [31: 0]                 LPDDR4B_DQ;
   wire [ 3: 0]                 LPDDR4B_DQS;
   wire [ 3: 0]                 LPDDR4B_DQS_n;
   wire                         LPDDR4B_RESET_n;
   wire                         LPDDR4B_RZQ;
`endif //  `ifdef ENABLE_LPDDR4B
`ifdef ENABLE_HDMI
   // HDMI
   wire                         HDMI_LRCLK;
   wire                         HDMI_MCLK;
   wire                         HDMI_SCLK;
   wire                         HDMI_I2S;
   wire                         HDMI_I2C_SCL;
   wire                         HDMI_I2C_SDA;
   wire                         HDMI_TX_INT = 1'b1;
   wire                         HDMI_TX_CLK;
   wire                         HDMI_TX_HS;
   wire                         HDMI_TX_VS;
   wire                         HDMI_TX_DE;
   wire [23: 0]                 HDMI_TX_D;
`endif //  `ifdef ENABLE_HDMI
`ifdef ENABLE_CAM
   // CAM
   wire                         CAM_CLK_p;
   wire                         CAM_CLK_n;
   wire [ 1: 0]                 CAM_D_p;
   wire [ 1: 0]                 CAM_D_n;
   wire                         CAM_I2C_SCL;
   wire                         CAM_I2C_SDA;
   wire                         CAM_GPIO;
   wire                         CAM_RZQ1;
`endif //  `ifdef ENABLE_CAM
`ifdef ENABLE_HPS
   // HPS
   wire                         HPS_CLK_25;
   wire                         HPS_ENET_MDC;
   wire                         HPS_ENET_MDIO;
   wire                         HPS_ENET_RX_CLK;
   wire                         HPS_ENET_RX_CTL;
   wire [ 3: 0]                 HPS_ENET_RX_DATA;
   wire                         HPS_ENET_TX_CLK;
   wire                         HPS_ENET_TX_CTL;
   wire [ 3: 0]                 HPS_ENET_TX_DATA;
   wire                         HPS_SD_CLK;
   wire                         HPS_SD_CMD;
   wire [ 3: 0]                 HPS_SD_DATA;
   wire                         HPS_USB_CLK;
   wire [ 7: 0]                 HPS_USB_DATA;
   wire                         HPS_USB_DIR;
   wire                         HPS_USB_NXT;
   wire                         HPS_USB_STP;
   wire                         HPS_UART_TX;
   wire                         HPS_UART_RX;
   wire                         HPS_I2C_SCL;
   wire                         HPS_I2C_SDA;
   wire                         HPS_GSENSOR_I2C_EN;
   wire                         HPS_GSENSOR_INT;
   wire                         HPS_KEY;
   wire                         HPS_LED;
`endif //  `ifdef ENABLE_HPS
`ifdef ENABLE_GPIO
   // GPIO
   wire [35: 0]                 GPIO0_D;
   wire [35: 0]                 GPIO1_D;
`endif
   // UART
   wire                         FPGA_UART_TX;
   wire                         FPGA_UART_RX = 1'b1;
   ///////// ADC /////////
   wire                         ADC_SCK;
   wire                         ADC_SDO;
   wire                         ADC_SDI;
   wire                         ADC_CS_n;
   ///////// FAN /////////
   wire                         FAN_ALERT_n;

   //

   pullup (HDMI_I2C_SCL);
   pullup (HDMI_I2C_SDA);

   // Sim-only ADV7513 replacement: ACKs every byte the on-board
   // hdmi_i2c master sends so it clears its setup LUT and asserts
   // ready. No real HDMI sink modelling.
   hdmi_i2c_stub u_hdmi_i2c_stub
     (.scl (HDMI_I2C_SCL),
      .sda (HDMI_I2C_SDA));

   de25_nano_top dut
     (.*);

   // =====================================================================
   // HDMI PLL reconfiguration test
   //
   // Drives CSR transactions onto the lwh2f AXI4 master (via `force` over
   // the HPS-driven signals, since the HPS is a black box in sim) and
   // monitors the reconfiguration FSM hierarchically (dut.avl_* core_avl
   // bus + the PLLCTRL status read-back). buf_refclk == CLOCK0_50 == clk.
   // =====================================================================

   // clk_sys (core_pll output) is the CSR/bridge clock -- alias it out for
   // event control in the CSR tasks.
   wire tb_clk_sys = dut.clk_sys;

   int          pll_errors = 0;
   task automatic chk(input bit cond, input string msg);
      if (!cond) begin pll_errors++; $display("  FAIL: %s", msg); end
   endtask

   // ---- core_avl write-burst monitor (end-anchored, skew-proof) ----------
   bit          mon_active = 1'b0;
   logic [8:0]  mon_addr;
   logic [7:0]  mon_burst [$];
   logic [8:0]  seq_addr  [$];
   logic [31:0] seq_word  [$];

   always @(posedge clk) begin
      if (dut.avl_write) begin
         if (!mon_active) begin mon_addr = dut.avl_address; mon_burst.delete(); end
         mon_active = 1;
         mon_burst.push_back(dut.avl_writedata);
      end
      else begin
         if (mon_active && mon_burst.size() >= 5) begin
            int s; s = mon_burst.size();
            seq_addr.push_back(mon_addr);
            seq_word.push_back({mon_burst[s-2], mon_burst[s-3], mon_burst[s-4], mon_burst[s-5]});
         end
         mon_active = 0;
         mon_burst.delete();
      end
   end

   // ---- core_avl read-burst monitor (for the FSM's RMW read-backs) --------
   // The 4 payload bytes are the LAST 4 cycles of the read strobe (LSB first,
   // MSB last); end-anchor them. Captures the *current* register contents the
   // FSM preserves (the bits outside each RMW mask).
   bit          mon_ractive = 1'b0;
   logic [8:0]  mon_raddr;
   logic [7:0]  mon_rburst [$];
   logic [8:0]  rseq_addr  [$];
   logic [31:0] rseq_word  [$];

   always @(posedge clk) begin
      if (dut.avl_read) begin
         if (!mon_ractive) begin mon_raddr = dut.avl_address; mon_rburst.delete(); end
         mon_ractive = 1;
         mon_rburst.push_back(dut.avl_readdata);
      end
      else begin
         if (mon_ractive && mon_rburst.size() >= 5) begin
            int s; s = mon_rburst.size();
            rseq_addr.push_back(mon_raddr);
            rseq_word.push_back({mon_rburst[s-1], mon_rburst[s-2], mon_rburst[s-3], mon_rburst[s-4]});
         end
         mon_ractive = 0;
         mon_rburst.delete();
      end
   end

   // ---- CSR access over the lwh2f AXI4 slave -----------------------------
   // The HPS is a black box in sim, so we override its lwh2f master with
   // `force`. A force's RHS must be static (VCS rejects automatic task args),
   // so the master signals are forced ONCE onto these static driver regs and
   // the tasks just write the regs with ordinary blocking assignments.
   localparam logic [28:0] PLLDIVCNT_OFF = 29'h100;
   localparam logic [28:0] PLLCTRL_OFF   = 29'h104;

   logic [ 3:0] drv_awid;    logic [28:0] drv_awaddr;  logic [ 7:0] drv_awlen;
   logic [ 2:0] drv_awsize;  logic [ 1:0] drv_awburst; logic        drv_awlock;
   logic [ 3:0] drv_awcache; logic [ 2:0] drv_awprot;  logic        drv_awvalid;
   logic [31:0] drv_wdata;   logic [ 3:0] drv_wstrb;    logic        drv_wlast;
   logic        drv_wvalid;  logic        drv_bready;
   logic [ 3:0] drv_arid;    logic [28:0] drv_araddr;  logic [ 7:0] drv_arlen;
   logic [ 2:0] drv_arsize;  logic [ 1:0] drv_arburst; logic        drv_arlock;
   logic [ 3:0] drv_arcache; logic [ 2:0] drv_arprot;  logic        drv_arvalid;
   logic        drv_rready;

   // Park the master idle, then bind the DUT's lwh2f inputs to the driver regs.
   task automatic csr_init;
      drv_awid='0; drv_awaddr='0; drv_awlen='0; drv_awsize=3'd2; drv_awburst=2'b01;
      drv_awlock='0; drv_awcache='0; drv_awprot='0; drv_awvalid=1'b0;
      drv_wdata='0; drv_wstrb='0; drv_wlast=1'b0; drv_wvalid=1'b0; drv_bready=1'b0;
      drv_arid='0; drv_araddr='0; drv_arlen='0; drv_arsize=3'd2; drv_arburst=2'b01;
      drv_arlock='0; drv_arcache='0; drv_arprot='0; drv_arvalid=1'b0; drv_rready=1'b0;
      force dut.lwh2f_awid    = drv_awid;
      force dut.lwh2f_awaddr  = drv_awaddr;
      force dut.lwh2f_awlen   = drv_awlen;
      force dut.lwh2f_awsize  = drv_awsize;
      force dut.lwh2f_awburst = drv_awburst;
      force dut.lwh2f_awlock  = drv_awlock;
      force dut.lwh2f_awcache = drv_awcache;
      force dut.lwh2f_awprot  = drv_awprot;
      force dut.lwh2f_awvalid = drv_awvalid;
      force dut.lwh2f_wdata   = drv_wdata;
      force dut.lwh2f_wstrb   = drv_wstrb;
      force dut.lwh2f_wlast   = drv_wlast;
      force dut.lwh2f_wvalid  = drv_wvalid;
      force dut.lwh2f_bready  = drv_bready;
      force dut.lwh2f_arid    = drv_arid;
      force dut.lwh2f_araddr  = drv_araddr;
      force dut.lwh2f_arlen   = drv_arlen;
      force dut.lwh2f_arsize  = drv_arsize;
      force dut.lwh2f_arburst = drv_arburst;
      force dut.lwh2f_arlock  = drv_arlock;
      force dut.lwh2f_arcache = drv_arcache;
      force dut.lwh2f_arprot  = drv_arprot;
      force dut.lwh2f_arvalid = drv_arvalid;
      force dut.lwh2f_rready  = drv_rready;
   endtask

   // Single-beat AXI write. Combinational handshake signals are sampled #1
   // after the clk_sys edge to avoid the NBA settle race.
   task automatic csr_write(input logic [28:0] off, input logic [31:0] data);
      @(posedge tb_clk_sys); #1;
      drv_awaddr = off; drv_awvalid = 1'b1;
      drv_wdata  = data; drv_wstrb = 4'hF; drv_wlast = 1'b1; drv_wvalid = 1'b1;
      drv_bready = 1'b1;
      while (!dut.lwh2f_awready) begin @(posedge tb_clk_sys); #1; end
      @(posedge tb_clk_sys); #1; drv_awvalid = 1'b0;
      while (!dut.lwh2f_wready)  begin @(posedge tb_clk_sys); #1; end
      @(posedge tb_clk_sys); #1; drv_wvalid = 1'b0;
      while (!dut.lwh2f_bvalid)  begin @(posedge tb_clk_sys); #1; end
      @(posedge tb_clk_sys); #1; drv_bready = 1'b0;
   endtask

   // Single-beat AXI read.
   task automatic csr_read(input logic [28:0] off, output logic [31:0] data);
      @(posedge tb_clk_sys); #1;
      drv_araddr = off; drv_arvalid = 1'b1; drv_rready = 1'b1;
      while (!dut.lwh2f_arready) begin @(posedge tb_clk_sys); #1; end
      @(posedge tb_clk_sys); #1; drv_arvalid = 1'b0;
      while (!dut.lwh2f_rvalid)  begin @(posedge tb_clk_sys); #1; end
      data = dut.lwh2f_rdata;
      @(posedge tb_clk_sys); #1; drv_rready = 1'b0;
   endtask

   // Full reconfig sequence + checks. M=32, N=4, C=10.
   task automatic pll_recfg_test;
      logic [31:0] rd;
      int          to;
      // 10 core_avl writes: 0x10, 0x58, 0x40, 0x44, 0x5C, 0x80, 0x80, 0x48,
      // 0x88, 0x48.
      localparam int     NW = 10;
      localparam int     I_C0 = 4, I_RST = 5, I_CALEN = 7, I_REQ = 8, I_CALDIS = 9;
      static logic [8:0] exp_a [10] =
        '{9'h010, 9'h058, 9'h040, 9'h044, 9'h05C, 9'h080, 9'h080, 9'h048, 9'h088, 9'h048};

      $display("[pll] reconfig test: M=297 N=5 C=20 (VCO=2970MHz, clk_pix=148.5MHz)");
      csr_init();

      // wait for system reset + PLL lock
      to = 0;
      while ((dut.rst_sys || !dut.por_rstn || !dut.hdmi_pll_locked) && to < 200000) begin
         @(posedge tb_clk_sys); to++;
      end
      chk(!dut.rst_sys, "rst_sys still asserted");
      chk(dut.por_rstn, "por_rstn not released");

      csr_read(PLLCTRL_OFF, rd);
      chk(rd[0] == 1'b0, "apply busy before trigger");

      // program divisors (C[24:16]=20, N[15:9]=5, M[8:0]=297), then trigger
      csr_write(PLLDIVCNT_OFF, 32'h0014_0B29);
      seq_addr.delete(); seq_word.delete();      // capture only this reconfig
      csr_write(PLLCTRL_OFF, 32'h0000_0001);     // apply = 1

      // poll until busy clears (apply -> FSM -> done CDC round-trip)
      to = 0;
      do begin csr_read(PLLCTRL_OFF, rd); to++; end while (rd[0] && to < 8000);
      chk(rd[0] == 1'b0, "apply did not clear (busy stuck)");

      // Both PLL models now end locked: the Verilator stub (drops/relocks on
      // recal) and the real Altera IOPLL sim model (with correct RMW + recal
      // re-arm at the start rather than after relock). Assert the happy path.
      chk(rd[1] == 1'b1, "locked not set after reconfig");
      chk(rd[2] == 1'b0, "error set after reconfig");

      csr_read(PLLDIVCNT_OFF, rd);
      chk(rd == 32'h0014_0B29, "PLLDIVCNT readback mismatch");

      // let any trailing core_avl burst settle, then check the sequence
      repeat (32) @(posedge clk);
      chk(seq_addr.size() == NW, $sformatf("expected %0d core_avl writes, got %0d", NW, seq_addr.size()));
      if (seq_addr.size() == NW) begin
         foreach (exp_a[i])
           chk(seq_addr[i] == exp_a[i],
               $sformatf("avl addr[%0d]=0x%03h exp 0x%03h", i, seq_addr[i], exp_a[i]));
         // Documented flow: 0x10 enable, ..., 0x80 reset, 0x48 cal-enable,
         // 0x88 initiate, (wait lock), 0x48 cal-disable.
         chk(seq_word[0][0]         == 1'b1, "0x10 d[0] (enable) not set");
         chk(seq_word[I_RST][2]     == 1'b1, "0x80 d[2] (reset assert) not set");
         chk(seq_word[I_CALEN][14]  == 1'b1, "0x48 d[14] (cal enable) not set");
         chk(seq_word[I_REQ][11]    == 1'b1, "0x88 d[11] (initiate cal) not set");
         chk(seq_word[I_CALDIS][14] == 1'b0, "0x48 d[14] (cal disable, post-lock) not cleared");
         // Counter regs (all-bits writes): fields are exact.
         chk(seq_word[2][28:20] == 9'd297,                                "M total != 297");
         chk((int'(seq_word[2][7:0])    + int'(seq_word[2][16:9]))  == 5,  "N hi+lo != 5");
         chk((int'(seq_word[I_C0][7:0]) + int'(seq_word[I_C0][30:23])) == 20, "C hi+lo != 20");
      end

      if (pll_errors == 0) $display("[pll] reconfig test PASSED");
      else                 $display("[pll] reconfig test FAILED (%0d errors)", pll_errors);
   endtask

   // Program one {M,N,C}, then decode and print exactly what the FSM drives
   // onto core_avl (M+N @0x40, charge pump @0x44, C0 @0x5C, and every other
   // touched register). Reporting only -- no pass/fail -- so the values can be
   // compared against the IP wizard.
   task automatic pll_program(input string name,
                              input int m, input int n, input int c);
      logic [31:0] rd, divcnt;
      int          to;
      real         vco, fout;

      divcnt = (c << 16) | (n << 9) | m;
      vco    = 50.0 * m / n;            // MHz
      fout   = vco / c;

      $display("");
      $display("--- %s : M=%0d N=%0d C=%0d  PLLDIVCNT=0x%08h  VCO=%0.3f MHz  clk_pix=%0.4f MHz ---",
               name, m, n, c, divcnt, vco, fout);

      csr_read(PLLCTRL_OFF, rd);
      if (rd[0]) $display("    (warning: apply still busy before programming)");

      csr_write(PLLDIVCNT_OFF, divcnt);
      seq_addr.delete(); seq_word.delete();        // capture only this reconfig
      rseq_addr.delete(); rseq_word.delete();
      csr_write(PLLCTRL_OFF, 32'h0000_0001);       // apply = 1

      to = 0;
      do begin csr_read(PLLCTRL_OFF, rd); to++; end while (rd[0] && to < 20000);
      repeat (32) @(posedge clk);

      foreach (seq_addr[i]) begin
         case (seq_addr[i])
           9'h040: $display("    [%0d] 0x040 M+N: 0x%08h  M_total=%0d  N hi=%0d lo=%0d odd=%0d byp=%0d (N=%0d)",
                            i, seq_word[i], seq_word[i][28:20],
                            seq_word[i][7:0], seq_word[i][16:9], seq_word[i][17], seq_word[i][8],
                            int'(seq_word[i][7:0]) + int'(seq_word[i][16:9]));
           9'h044: $display("    [%0d] 0x044 CP : 0x%08h  code[15:1]=0x%04h  hi=%05b mid=%05b lo=%05b",
                            i, seq_word[i], seq_word[i][15:1],
                            seq_word[i][15:11], seq_word[i][10:6], seq_word[i][5:1]);
           9'h05C: $display("    [%0d] 0x05C C0 : 0x%08h  C hi=%0d lo=%0d odd=%0d byp=%0d (C=%0d)",
                            i, seq_word[i], seq_word[i][7:0], seq_word[i][30:23],
                            seq_word[i][31], seq_word[i][8],
                            int'(seq_word[i][7:0]) + int'(seq_word[i][30:23]));
           default: $display("    [%0d] 0x%03h    : 0x%08h", i, seq_addr[i], seq_word[i]);
         endcase
      end
      $display("    => %0d core_avl writes, PLLCTRL=0x%08h: locked=%0d error=%0d%s",
               seq_addr.size(), rd, rd[1], rd[2], rd[0] ? " APPLY-STUCK" : "");
      $display("    read-backs (current register contents the FSM RMW-preserves):");
      foreach (rseq_addr[i])
        $display("      R 0x%03h = 0x%08h", rseq_addr[i], rseq_word[i]);
   endtask

   // Static drivers for forcing the core_avl bus (a force's RHS must be static,
   // so the tasks write these regs with blocking assignments).
   logic [8:0]  drv_avl_addr  = '0;
   logic        drv_avl_read  = 1'b0;
   logic        drv_avl_write = 1'b0;
   logic [7:0]  drv_avl_wdata = 8'h00;

   // Drive one core_avl read burst directly (FSM idle), so we can read ANY
   // register, not just the ones the FSM touches. Replays the FSM's 10-cycle
   // read strobe; the read monitor reconstructs the word.
   task automatic avl_read_reg(input logic [8:0] addr);
      @(posedge clk); #1;
      drv_avl_write = 1'b0; drv_avl_wdata = 8'h00;
      drv_avl_addr  = addr; drv_avl_read  = 1'b1;
      repeat (10) @(posedge clk);          // ACT = PRE(5) + 5
      #1; drv_avl_read = 1'b0;
      repeat (6) @(posedge clk);           // >= IDLE
   endtask

   // Full register-space dump. Run while the FSM is idle. Call it BEFORE any
   // reconfig to capture the IP-generated defaults; after a reconfig the
   // registers the FSM writes (0x40/0x44/0x5C) reflect the last programmed
   // config and the rest still show the IP default.
   task automatic avl_dump_all(input string when);
      logic [8:0] a;
      force dut.avl_address   = drv_avl_addr;
      force dut.avl_read      = drv_avl_read;
      force dut.avl_write     = drv_avl_write;
      force dut.avl_writedata = drv_avl_wdata;
      $display("");
      $display("######## full core_avl register dump (%s) ########", when);
      rseq_addr.delete(); rseq_word.delete();
      for (a = 9'h000; a <= 9'h0a0; a = a + 9'h004) avl_read_reg(a);
      repeat (8) @(posedge clk);
      foreach (rseq_addr[i])
        $display("    0x%03h = 0x%08h", rseq_addr[i], rseq_word[i]);
      $display("######## end register dump ########");
      release dut.avl_address;
      release dut.avl_read;
      release dut.avl_write;
      release dut.avl_writedata;
   endtask

   // Sweep the divisor sets the Linux driver selects for the common modes, to
   // observe the FSM's per-config core_avl programming (M/N/C encoding + charge
   // pump) for comparison against the IP wizard.
   task automatic pll_sweep;
      $display("");
      $display("################ PLL config sweep: FSM core_avl writes ################");
      pll_program("1080p   148.500MHz", 297, 5,  20);
      pll_program("720p     74.250MHz", 297, 5,  40);
      pll_program("SXGA    135.000MHz", 297, 5,  22);
      pll_program("XGA      65.000MHz", 312, 5,  48);
      pll_program("SVGA     40.000MHz",  64, 1,  80);
      pll_program("VGA      25.175MHz", 287, 5, 114);
      pll_program("240p     25.176MHz", 143, 4,  71);
      $display("");
      $display("################ end PLL config sweep ################");
   endtask

   //

   longint unsigned expectedRunTime;
   initial expectedRunTime = 1_000;

   initial begin
      fork
         begin: testBlock
            runtest;
         end
         begin: timeoutBlock
            while ($realtime < expectedRunTime) #1000;
            $display("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++");
            $display("+ ERROR: Test has exceeded timeout value expectedRunTime");
            $display("+ Test finished at time %t", $realtime);
            $display("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++");
            $display("");
         end
      join_any
      #200;
      #200;
      $finish;
   end

   task runtest;
      begin
         expectedRunTime = 64'd1_000_000_000;

         #1000ns;
         @(posedge clk) #0.1ns;
         rst = '0;
         #10000ns;

//         avl_dump_all("initial / IP-generated config");
         pll_recfg_test();
//         pll_sweep();
//         avl_dump_all("final / after sweep");

         result = (pll_errors == 0);
         ->done;
      end
   endtask

   always @done begin
      #1;
      $display(" ");
      $display("=================================================================================");
      $display("= %s = Final Test Result: %s = %s", `TESTNAME,
               ((result !== 1'b1) ? "failed" : "passed"), `UNIQUE_TAG);
      $display("=================================================================================");
      $finish;
   end

endmodule // tb
