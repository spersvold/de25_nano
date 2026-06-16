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
      // this will cause %t to show simulation times using ns
      $timeformat(-9,3," ns",13);
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

   logic                        lpddr4clk = 1'b0;
   parameter real LPDDR4_FREQ = 166.668; // MHz
   localparam LPDDR4_PERIOD = 1000.0 / LPDDR4_FREQ; // ns
   always #(LPDDR4_PERIOD/2) lpddr4clk = ~lpddr4clk;

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
   wire                         LPDDR4A_REFCLK_p = lpddr4clk;
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
   wire                         LPDDR4B_REFCLK_p = lpddr4clk;
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

`ifndef VERILATOR
`ifdef ENABLE_LPDDR4A
   altera_emif_lpddr4_model_arch_top #
     (.MEM_CS_WIDTH       (1),
      .MEM_NUM_RANKS      (1),
      .MEM_CKE_WIDTH      (1),
      .MEM_CK_C_WIDTH     (1),
      .MEM_CK_T_WIDTH     (1),
      .MEM_BA_WIDTH       (3),
      .MEM_ROW_ADDR_WIDTH (15),
      .MEM_COL_ADDR_WIDTH (10),
      .MEM_DQ_WIDTH       (32),
      .MEM_CA_WIDTH       (6),
      .MEM_DMI_WIDTH      (4),
      .MEM_DQS_C_WIDTH    (4),
      .MEM_DQS_T_WIDTH    (4),
      .MEM_RESET_N_WIDTH  (1),
      .MEM_VERBOSE        (0))
   u_lpddr4a
     (.mem_reset_n_0 (LPDDR4A_RESET_n),
      .mem_zq_0      (),
      //
      .mem_cke_0     (LPDDR4A_CKE),
      .mem_cs_0      (LPDDR4A_CS_n),
      .mem_ca_0      (LPDDR4A_CA),
      .mem_dq_0      (LPDDR4A_DQ),
      .mem_dqs_t_0   (LPDDR4A_DQS),
      .mem_dqs_c_0   (LPDDR4A_DQS_n),
      .mem_dmi_0     (LPDDR4A_DM),
      .mem_ck_t_0    (LPDDR4A_CK),
      .mem_ck_c_0    (LPDDR4A_CK_n),
      .oct_rzqin_0   (LPDDR4A_RZQ),
      //
      .mem_cke_1     (),
      .mem_cs_1      (),
      .mem_ca_1      (),
      .mem_dq_1      (),
      .mem_dqs_t_1   (),
      .mem_dqs_c_1   (),
      .mem_dmi_1     (),
      .mem_ck_t_1    (),
      .mem_ck_c_1    (),
      .oct_rzqin_1   (),
      //
      .mem_cke_2     (),
      .mem_cs_2      (),
      .mem_ca_2      (),
      .mem_dq_2      (),
      .mem_dqs_t_2   (),
      .mem_dqs_c_2   (),
      .mem_dmi_2     (),
      .mem_ck_t_2    (),
      .mem_ck_c_2    (),
      .oct_rzqin_2   (),
      //
      .mem_cke_3     (),
      .mem_cs_3      (),
      .mem_ca_3      (),
      .mem_dq_3      (),
      .mem_dqs_t_3   (),
      .mem_dqs_c_3   (),
      .mem_dmi_3     (),
      .mem_ck_t_3    (),
      .mem_ck_c_3    (),
      .oct_rzqin_3   ()
      );
`endif //  `ifdef ENABLE_LPDDR4A
`ifdef ENABLE_LPDDR4B
   altera_emif_lpddr4_model_arch_top #
     (.MEM_CS_WIDTH       (1),
      .MEM_NUM_RANKS      (1),
      .MEM_CKE_WIDTH      (1),
      .MEM_CK_C_WIDTH     (1),
      .MEM_CK_T_WIDTH     (1),
      .MEM_BA_WIDTH       (3),
      .MEM_ROW_ADDR_WIDTH (15),
      .MEM_COL_ADDR_WIDTH (10),
      .MEM_DQ_WIDTH       (32),
      .MEM_CA_WIDTH       (6),
      .MEM_DMI_WIDTH      (4),
      .MEM_DQS_C_WIDTH    (4),
      .MEM_DQS_T_WIDTH    (4),
      .MEM_RESET_N_WIDTH  (1),
      .MEM_VERBOSE        (0))
   u_lpddr4b
     (.mem_reset_n_0 (LPDDR4B_RESET_n),
      .mem_zq_0      (),
      //
      .mem_cke_0     (LPDDR4B_CKE),
      .mem_cs_0      (LPDDR4B_CS_n),
      .mem_ca_0      (LPDDR4B_CA),
      .mem_dq_0      (LPDDR4B_DQ),
      .mem_dqs_t_0   (LPDDR4B_DQS),
      .mem_dqs_c_0   (LPDDR4B_DQS_n),
      .mem_dmi_0     (LPDDR4B_DM),
      .mem_ck_t_0    (LPDDR4B_CK),
      .mem_ck_c_0    (LPDDR4B_CK_n),
      .oct_rzqin_0   (LPDDR4B_RZQ),
      //
      .mem_cke_1     (),
      .mem_cs_1      (),
      .mem_ca_1      (),
      .mem_dq_1      (),
      .mem_dqs_t_1   (),
      .mem_dqs_c_1   (),
      .mem_dmi_1     (),
      .mem_ck_t_1    (),
      .mem_ck_c_1    (),
      .oct_rzqin_1   (),
      //
      .mem_cke_2     (),
      .mem_cs_2      (),
      .mem_ca_2      (),
      .mem_dq_2      (),
      .mem_dqs_t_2   (),
      .mem_dqs_c_2   (),
      .mem_dmi_2     (),
      .mem_ck_t_2    (),
      .mem_ck_c_2    (),
      .oct_rzqin_2   (),
      //
      .mem_cke_3     (),
      .mem_cs_3      (),
      .mem_ca_3      (),
      .mem_dq_3      (),
      .mem_dqs_t_3   (),
      .mem_dqs_c_3   (),
      .mem_dmi_3     (),
      .mem_ck_t_3    (),
      .mem_ck_c_3    (),
      .oct_rzqin_3   ()
      );
`endif //  `ifdef ENABLE_LPDDR4B
`endif //  `ifndef VERILATOR

   // =====================================================================
   // HDMI PLL reconfiguration test
   //
   // Drives CSR transactions onto the lwhps2fpga AXI4 master (via `force` over
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

`ifndef VERILATOR
   // ----------------------------------------------------------------------
   // AXI VALID-stability checks. Once a *VALID is asserted it must stay
   // asserted, with a stable payload, until *READY -- the exact rule the
   // combinatorial vctrl_axim m_axi_arvalid broke (a vblank frame_sys retracted
   // a not-yet-accepted AR and desynced the slave). These would have caught it
   // and guard against regressions. VCS only (Verilator SVA support is partial).
   // ----------------------------------------------------------------------
   property p_valid_stable(valid, ready, payload);
      @(posedge tb_clk_sys) disable iff (dut.rst_sys)
        (valid && !ready) |=> (valid && $stable(payload));
   endproperty

   a_scanout_ar: assert property
     (p_valid_stable(dut.u_vctrl_wrapper.u_vctrl_axim.m_axi_arvalid,
                     dut.u_vctrl_wrapper.u_vctrl_axim.m_axi_arready,
                     dut.u_vctrl_wrapper.u_vctrl_axim.m_axi_araddr))
     else $error("%t SCANOUT m_axi: arvalid retracted or araddr changed before arready", $time);
`ifdef ENABLE_HPS2FPGA
   a_h2f_ar: assert property
     (p_valid_stable(dut.hps2fpga_arvalid, dut.hps2fpga_arready, dut.hps2fpga_araddr))
     else $error("%t HPS2FPGA: arvalid retracted or araddr changed before arready", $time);
   a_h2f_aw: assert property
     (p_valid_stable(dut.hps2fpga_awvalid, dut.hps2fpga_awready, dut.hps2fpga_awaddr))
     else $error("%t HPS2FPGA: awvalid retracted or awaddr changed before awready", $time);
`endif
`endif //  `ifndef VERILATOR

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

   // ---- CSR access over the lwhps2fpga AXI4 slave -----------------------------
   // The HPS is a black box in sim, so we override its lwhps2fpga master with
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

   // Park the master idle, then bind the DUT's lwhps2fpga inputs to the driver regs.
   task automatic csr_init;
      drv_awid='0; drv_awaddr='0; drv_awlen='0; drv_awsize=3'd2; drv_awburst=2'b01;
      drv_awlock='0; drv_awcache='0; drv_awprot='0; drv_awvalid=1'b0;
      drv_wdata='0; drv_wstrb='0; drv_wlast=1'b0; drv_wvalid=1'b0; drv_bready=1'b0;
      drv_arid='0; drv_araddr='0; drv_arlen='0; drv_arsize=3'd2; drv_arburst=2'b01;
      drv_arlock='0; drv_arcache='0; drv_arprot='0; drv_arvalid=1'b0; drv_rready=1'b0;
      force dut.lwhps2fpga_awid    = drv_awid;
      force dut.lwhps2fpga_awaddr  = drv_awaddr;
      force dut.lwhps2fpga_awlen   = drv_awlen;
      force dut.lwhps2fpga_awsize  = drv_awsize;
      force dut.lwhps2fpga_awburst = drv_awburst;
      force dut.lwhps2fpga_awlock  = drv_awlock;
      force dut.lwhps2fpga_awcache = drv_awcache;
      force dut.lwhps2fpga_awprot  = drv_awprot;
      force dut.lwhps2fpga_awvalid = drv_awvalid;
      force dut.lwhps2fpga_wdata   = drv_wdata;
      force dut.lwhps2fpga_wstrb   = drv_wstrb;
      force dut.lwhps2fpga_wlast   = drv_wlast;
      force dut.lwhps2fpga_wvalid  = drv_wvalid;
      force dut.lwhps2fpga_bready  = drv_bready;
      force dut.lwhps2fpga_arid    = drv_arid;
      force dut.lwhps2fpga_araddr  = drv_araddr;
      force dut.lwhps2fpga_arlen   = drv_arlen;
      force dut.lwhps2fpga_arsize  = drv_arsize;
      force dut.lwhps2fpga_arburst = drv_arburst;
      force dut.lwhps2fpga_arlock  = drv_arlock;
      force dut.lwhps2fpga_arcache = drv_arcache;
      force dut.lwhps2fpga_arprot  = drv_arprot;
      force dut.lwhps2fpga_arvalid = drv_arvalid;
      force dut.lwhps2fpga_rready  = drv_rready;
   endtask

   // Single-beat AXI write. Combinational handshake signals are sampled #1
   // after the clk_sys edge to avoid the NBA settle race.
   task automatic csr_write(input logic [28:0] off, input logic [31:0] data);
      @(posedge tb_clk_sys); #1;
      drv_awaddr = off; drv_awvalid = 1'b1;
      drv_wdata  = data; drv_wstrb = 4'hF; drv_wlast = 1'b1; drv_wvalid = 1'b1;
      drv_bready = 1'b1;
      fork
         begin : aw
            wait (dut.lwhps2fpga_awready);
            @(posedge tb_clk_sys); #1; drv_awvalid = 1'b0;
         end
         begin : w
            wait (dut.lwhps2fpga_wready);
            @(posedge tb_clk_sys); #1; drv_wvalid = 1'b0;
         end
      join
      wait (dut.lwhps2fpga_bvalid);
      @(posedge tb_clk_sys); #1; drv_bready = 1'b0;
      $display("%t CSR_WRITE: off=%h, data=%h", $time, off, data);
   endtask

   // Single-beat AXI read.
   task automatic csr_read(input logic [28:0] off, output logic [31:0] data);
      @(posedge tb_clk_sys); #1;
      drv_araddr = off; drv_arvalid = 1'b1; drv_rready = 1'b1;
      wait (dut.lwhps2fpga_arready);
      @(posedge tb_clk_sys); #1; drv_arvalid = 1'b0;
      wait (dut.lwhps2fpga_rvalid);
      data = dut.lwhps2fpga_rdata;
      $display("%t CSR_READ: off=%h, data=%h", $time, off, data);
      @(posedge tb_clk_sys); #1; drv_rready = 1'b0;
   endtask

`ifdef ENABLE_HPS2FPGA
   // =====================================================================
   // HPS2FPGA (full h2f) AXI4 master BFM + scanout/crossbar observation.
   //
   // The HPS is a black box in sim, so -- exactly like the lwhps2fpga CSR
   // path above -- we `force` the h2f master signals onto static driver regs
   // and drive 128-bit write bursts. This exercises the 128->256 axi_adapter
   // and the crossbar arbitration against the vctrl scanout master, all the
   // way into the behavioural EMIF model. h2f is synchronous to clk_sys.
   // =====================================================================
   logic [ 3:0]  h2_awid;   logic [31:0]  h2_awaddr;  logic [ 7:0] h2_awlen;
   logic [ 2:0]  h2_awsize; logic [ 1:0]  h2_awburst; logic        h2_awlock;
   logic [ 3:0]  h2_awcache;logic [ 2:0]  h2_awprot;  logic        h2_awvalid;
   logic [127:0] h2_wdata;  logic [15:0]  h2_wstrb;   logic        h2_wlast;
   logic         h2_wvalid; logic         h2_bready;
   logic [ 3:0]  h2_arid;   logic [31:0]  h2_araddr;  logic [ 7:0] h2_arlen;
   logic [ 2:0]  h2_arsize; logic [ 1:0]  h2_arburst; logic        h2_arlock;
   logic [ 3:0]  h2_arcache;logic [ 2:0]  h2_arprot;  logic        h2_arvalid;
   logic         h2_rready;

   task automatic h2f_init;
      h2_awid=4'hA; h2_awaddr='0; h2_awlen='0; h2_awsize=3'd4; h2_awburst=2'b01;
      h2_awlock='0; h2_awcache='0; h2_awprot='0; h2_awvalid=1'b0;
      h2_wdata='0; h2_wstrb='0; h2_wlast=1'b0; h2_wvalid=1'b0; h2_bready=1'b0;
      h2_arid=4'hD; h2_araddr='0; h2_arlen='0; h2_arsize=3'd4; h2_arburst=2'b01;
      h2_arlock='0; h2_arcache='0; h2_arprot='0; h2_arvalid=1'b0; h2_rready=1'b0;
      force dut.hps2fpga_awid    = h2_awid;
      force dut.hps2fpga_awaddr  = h2_awaddr;
      force dut.hps2fpga_awlen   = h2_awlen;
      force dut.hps2fpga_awsize  = h2_awsize;
      force dut.hps2fpga_awburst = h2_awburst;
      force dut.hps2fpga_awlock  = h2_awlock;
      force dut.hps2fpga_awcache = h2_awcache;
      force dut.hps2fpga_awprot  = h2_awprot;
      force dut.hps2fpga_awvalid = h2_awvalid;
      force dut.hps2fpga_wdata   = h2_wdata;
      force dut.hps2fpga_wstrb   = h2_wstrb;
      force dut.hps2fpga_wlast   = h2_wlast;
      force dut.hps2fpga_wvalid  = h2_wvalid;
      force dut.hps2fpga_bready  = h2_bready;
      force dut.hps2fpga_arid    = h2_arid;
      force dut.hps2fpga_araddr  = h2_araddr;
      force dut.hps2fpga_arlen   = h2_arlen;
      force dut.hps2fpga_arsize  = h2_arsize;
      force dut.hps2fpga_arburst = h2_arburst;
      force dut.hps2fpga_arlock  = h2_arlock;
      force dut.hps2fpga_arcache = h2_arcache;
      force dut.hps2fpga_arprot  = h2_arprot;
      force dut.hps2fpga_arvalid = h2_arvalid;
      force dut.hps2fpga_rready  = h2_rready;
   endtask

   task automatic h2f_idle;
      h2_awvalid=1'b0; h2_wvalid=1'b0; h2_wlast=1'b0; h2_bready=1'b0;
      h2_arvalid=1'b0; h2_rready=1'b0;
   endtask

   // 128-bit INCR write burst: `beats` beats at byte `addr`, data an
   // incrementing pattern from `seed` (one 32-bit word per lane).
   task automatic h2f_write_burst(input logic [31:0] addr, input int beats,
                                  input logic [31:0] seed);
      int i;
      @(posedge tb_clk_sys); #1;
      h2_awaddr = addr; h2_awlen = 8'(beats-1); h2_awsize = 3'd4;
      h2_awburst = 2'b01; h2_awvalid = 1'b1; h2_bready = 1'b1;
      fork
         begin : aw
            wait (dut.hps2fpga_awready);
            @(posedge tb_clk_sys); #1; h2_awvalid = 1'b0;
         end
         begin : w
            for (i = 0; i < beats; i++) begin
               h2_wdata = {seed + 32'(4*i+3), seed + 32'(4*i+2),
                           seed + 32'(4*i+1), seed + 32'(4*i+0)};
               h2_wstrb = 16'hFFFF; h2_wlast = (i == beats-1); h2_wvalid = 1'b1;
               wait (dut.hps2fpga_wready);
               @(posedge tb_clk_sys); #1;
            end
            h2_wvalid = 1'b0; h2_wlast = 1'b0;
         end
      join
      wait (dut.hps2fpga_bvalid);
      @(posedge tb_clk_sys); #1; h2_bready = 1'b0;
   endtask

   // 128-bit INCR read burst at byte `addr`; checks each returned beat against
   // the incrementing pattern h2f_write_burst(.,.,seed) would have written.
   // This is the read direction through the crossbar (slave 1) and the
   // axi_adapter 256->128 DOWN-size -- the path suspected broken. Returns the
   // mismatch count in `bad`.
   task automatic h2f_read_burst(input  logic [31:0] addr, input int beats,
                                 input  logic [31:0] seed, output int bad);
      int i;
      logic [127:0] exp;
      bad = 0;
      @(posedge tb_clk_sys); #1;
      h2_araddr = addr; h2_arlen = 8'(beats-1); h2_arsize = 3'd4;
      h2_arburst = 2'b01; h2_arvalid = 1'b1; h2_rready = 1'b1;
      fork
         begin : ar
            wait (dut.hps2fpga_arready);
            @(posedge tb_clk_sys); #1; h2_arvalid = 1'b0;
         end
         begin : r
            for (i = 0; i < beats; i++) begin
               wait (dut.hps2fpga_rvalid);
               exp = {seed + 32'(4*i+3), seed + 32'(4*i+2),
                      seed + 32'(4*i+1), seed + 32'(4*i+0)};
               if (dut.hps2fpga_rdata !== exp) begin
                  bad++;
                  if (bad <= 4)
                    $display("  [h2f-rd] beat %0d @0x%08h: got 0x%032h exp 0x%032h",
                             i, addr + 32'(16*i), dut.hps2fpga_rdata, exp);
               end
               if (i == beats-1)
                 chk(dut.hps2fpga_rlast, "h2f read: rlast not set on final beat");
               @(posedge tb_clk_sys); #1;
            end
            h2_rready = 1'b0;
         end
      join
   endtask

   // Single 32-bit WRITE (arsize=2, arlen=0, wstrb on the addressed lane only)
   // -- mimics a CPU/devmem 32-bit store through the 128-bit h2f bridge. The
   // adapter must place these 4 bytes on the correct lane of the 256-bit master
   // with a matching narrow wstrb (a partial/sub-slave-width write).
   task automatic h2f_write32(input logic [31:0] addr, input logic [31:0] data);
      logic [1:0] lane;
      lane = addr[3:2];
      @(posedge tb_clk_sys); #1;
      h2_awaddr = addr; h2_awlen = 8'd0; h2_awsize = 3'd2; h2_awburst = 2'b01;
      h2_awvalid = 1'b1; h2_bready = 1'b1;
      h2_wdata = '0; h2_wdata[lane*32 +: 32] = data;
      h2_wstrb = '0; h2_wstrb[lane*4  +: 4] = 4'hF;
      h2_wlast = 1'b1; h2_wvalid = 1'b1;
      fork
         begin : aw
            wait (dut.hps2fpga_awready);
            @(posedge tb_clk_sys); #1; h2_awvalid = 1'b0;
         end
         begin : w
            wait (dut.hps2fpga_wready);
            @(posedge tb_clk_sys); #1; h2_wvalid = 1'b0; h2_wlast = 1'b0;
         end
      join
      wait (dut.hps2fpga_bvalid);
      @(posedge tb_clk_sys); #1; h2_bready = 1'b0;
      $display("%t H2F_WR32: @0x%08h lane%0d data=0x%08h", $time, addr, lane, data);
   endtask

   // Single 32-bit READ (arsize=2, arlen=0) -- mimics a CPU/devmem 32-bit load
   // through the 128-bit h2f bridge. Captures the addressed 32-bit lane of the
   // returned beat and checks it. This is the partial-read path the host
   // devmem readback uses, distinct from the full-width burst above.
   task automatic h2f_read32(input logic [31:0] addr, input logic [31:0] exp);
      logic [1:0]  lane;
      logic [31:0] got;
      lane = addr[3:2];
      @(posedge tb_clk_sys); #1;
      h2_araddr = addr; h2_arlen = 8'd0; h2_arsize = 3'd2; h2_arburst = 2'b01;
      h2_arvalid = 1'b1; h2_rready = 1'b1;
      fork
         begin : ar
            wait (dut.hps2fpga_arready);
            @(posedge tb_clk_sys); #1; h2_arvalid = 1'b0;
         end
         begin : r
            wait (dut.hps2fpga_rvalid);
            got = dut.hps2fpga_rdata[lane*32 +: 32];
            chk(dut.hps2fpga_rlast, "h2f read32: rlast not set on single beat");
            @(posedge tb_clk_sys); #1; h2_rready = 1'b0;
         end
      join
      chk(got === exp,
          $sformatf("h2f read32 @0x%08h lane%0d: got 0x%08h exp 0x%08h", addr, lane, got, exp));
      $display("%t H2F_RD32: @0x%08h lane%0d -> 0x%08h (exp 0x%08h)%s",
               $time, addr, lane, got, exp, (got === exp) ? " OK" : " MISMATCH");
   endtask

   // WRAP cache-line read with arcache[1]=1 -- the exact access that wedges the
   // hardware (ARM linefill / login readback). arburst=WRAP + arcache modifiable
   // + full-slave-width beats drives the adapter into its burst-convert/split
   // path, which mishandles WRAP (illegal master burst + phantom early R beats).
   // With CONVERT_BURST=0 on u_axi_adapter the narrow path is taken and this
   // completes cleanly. beats must be power-of-2; addr is NOT 256b-aligned.
   // Bounded waits so a wedge reports instead of hanging the sim.
   task automatic h2f_read_wrap(input logic [31:0] addr, input int beats);
      int i, tmo;
      bit wedged;
      wedged = 1'b0;
      @(posedge tb_clk_sys); #1;
      h2_araddr = addr; h2_arlen = 8'(beats-1); h2_arsize = 3'd4;
      h2_arburst = 2'b10; h2_arcache = 4'h2;        // WRAP + Normal/Modifiable
      h2_arvalid = 1'b1; h2_rready = 1'b1;
      tmo = 0;
      while (!dut.hps2fpga_arready && tmo < 1000) begin @(posedge tb_clk_sys); #1; tmo++; end
      @(posedge tb_clk_sys); #1; h2_arvalid = 1'b0;
      for (i = 0; i < beats; i++) begin
         tmo = 0;
         while (!dut.hps2fpga_rvalid && tmo < 4000) begin @(posedge tb_clk_sys); #1; tmo++; end
         if (tmo >= 4000) begin wedged = 1'b1; break; end
         if (i == beats-1)
           chk(dut.hps2fpga_rlast, "h2f WRAP read: rlast not on final beat");
         @(posedge tb_clk_sys); #1;
      end
      h2_arvalid = 1'b0; h2_rready = 1'b0; h2_arcache = 4'h0;
      chk(!wedged,
          $sformatf("h2f WRAP read @0x%08h WEDGED -- adapter burst-convert WRAP bug", addr));
      $display("%t H2F_RD_WRAP: @0x%08h beats=%0d %s", $time, addr, beats,
               wedged ? "*** WEDGED (bug reproduced) ***" : "completed OK");
   endtask

   // ---- scanout / crossbar / EMIF activity monitor ----------------------
   int           scan_ar = 0, scan_r = 0, emif_ar = 0, emif_aw = 0, emif_w = 0;
   int           h2f_r = 0, m1_r = 0;   // 128b beats to HPS vs 256b beats from xbar
   logic [255:0] first_rdata;
   bit           got_first = 1'b0;
   always @(posedge tb_clk_sys) begin
      if (dut.u_vctrl_wrapper.m_axi_arvalid && dut.u_vctrl_wrapper.m_axi_arready)
        scan_ar++;
      if (dut.u_vctrl_wrapper.m_axi_rvalid && dut.u_vctrl_wrapper.m_axi_rready) begin
         scan_r++;
         if (!got_first) begin
            first_rdata = dut.u_vctrl_wrapper.m_axi_rdata;
            got_first = 1'b1;
         end
      end
`ifdef FIXME
      if (dut.u_vctrl_wrapper.s0_axi4_arvalid && dut.u_vctrl_wrapper.s0_axi4_arready)
        emif_ar++;
      if (dut.u_vctrl_wrapper.s0_axi4_awvalid && dut.u_vctrl_wrapper.s0_axi4_awready)
        emif_aw++;
      if (dut.u_vctrl_wrapper.s0_axi4_wvalid && dut.u_vctrl_wrapper.s0_axi4_wready)
        emif_w++;
      // adapter read downsize: 256b beats in (m1_axi) vs 128b beats out (hps2fpga)
      if (dut.u_vctrl_wrapper.m1_axi_rvalid && dut.u_vctrl_wrapper.m1_axi_rready)
        m1_r++;
`endif
      if (dut.hps2fpga_rvalid && dut.hps2fpga_rready)
        h2f_r++;
   end
`endif //  `ifdef ENABLE_HPS2FPGA

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
      do begin csr_read(PLLCTRL_OFF, rd); #1000; to++; end while (rd[0] && to < 100);
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
      do begin csr_read(PLLCTRL_OFF, rd); #1000; to++; end while (rd[0] && to < 200);
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

`ifdef ENABLE_HPS2FPGA
   // VRAM scanout + h2f arbitration test. Pre-fills the framebuffer through the
   // h2f write path (128->256 adapter + crossbar slave 1), programs a tiny video
   // mode, enables scanout, and runs a few frames while firing concurrent h2f
   // writes -- so the vctrl scanout master (crossbar slave 0) and the h2f writer
   // contend for the EMIF. Reports whether the scanout master actually issues
   // reads (the symptom seen on hardware) and echoes the first read word for an
   // end-to-end check against the pre-filled pattern.
   task automatic vram_scanout_test;
      int to;
      int rd_bad;

      $display("");
      $display("################ VRAM scanout + h2f arbitration test ################");
      $fflush();
      csr_init();
      h2f_init();

      // system up: reset released, pixel PLL locked, EMIF calibrated.
      to = 0;
      while ((dut.rst_sys || !dut.por_rstn || !dut.hdmi_pll_locked ||
              !dut.u_vctrl_wrapper.vctrl_init_done) && to < 400000) begin
         @(posedge tb_clk_sys); to++;
      end
      chk(!dut.rst_sys, "rst_sys still asserted");
      chk(dut.u_vctrl_wrapper.vctrl_init_done, "EMIF cal (vctrl_init_done) never asserted");
      $display("[vram] system up (vctrl_init_done=%0b) after %0d clk_sys cycles",
               dut.u_vctrl_wrapper.vctrl_init_done, to);
      $fflush();

      // Pre-fill framebuffer @ VRAM offset 0: 64 x 128-bit beats = 1 KiB.
      $display("[vram] h2f pre-fill: 64 x 128b INCR burst @ 0x0 (exercises 128->256)");
      $fflush();
      h2f_write_burst(32'h0000_0000, 64, 32'h1000_0000);
      $display("[vram] h2f pre-fill: DONE");
      $fflush();

      // Read the pre-filled region straight back through h2f, isolated from the
      // scanout. This is the suspected path: crossbar slave-1 read + axi_adapter
      // 256->128 down-size. Each 128b beat is checked against the written pattern.
      h2f_read_burst(32'h0000_0000, 64, 32'h1000_0000, rd_bad);
      chk(rd_bad == 0,
          $sformatf("h2f readback: %0d/64 beats mismatched (axi_adapter 256->128 read)", rd_bad));
      $display("[vram] h2f readback @0x0: %0d/64 beats mismatched%s",
               rd_bad, (rd_bad == 0) ? " -- adapter read path OK" : "");
      $fflush();

      // Reproduce the failing host devmem path: a single 32-bit store followed
      // by single 32-bit loads (arsize=2, arlen=0) through the 128-bit h2f
      // bridge -- the partial/sub-slave-width access the adapter must lane-align.
      $display("[vram] devmem-style 32-bit round trip + lane/half sweep:");
      h2f_write32(32'h0000_0000, 32'hDEAD_BEEF);
      // word 0 is now DEADBEEF; words 1..7 keep the pre-fill (seed + w). Sweeping
      // 0x00..0x1C covers all 4 lanes AND both 128-bit halves of 256b word 0,
      // and confirms the narrow write hit ONLY lane 0.
      for (int w = 0; w < 8; w++)
         h2f_read32(32'(4*w), (w == 0) ? 32'hDEAD_BEEF : (32'h1000_0000 + 32'(w)));
      $fflush();

      // Tiny mode so a frame is short in sim: 32x8 visible, 40x12 total, 32bpp.
      csr_write(29'h008, (1 << 24) | (3 << 16) | (32 - 1)); // HTIM  hsw=2 hbp=4 hdisp=32
      csr_write(29'h00c, (0 << 24) | (1 << 16) | (8 - 1));  // VTIM  vsw=1 vbp=2 vdisp=8
      csr_write(29'h010, ((40 - 1) << 16) | (12 - 1));      // HVLEN htot=40 vtot=12
      csr_write(29'h014, 32'h0000_0000);                    // VBARA = offset 0
      csr_write(29'h018, 32'd1024);                         // VSIZ  = 32*8*4
      csr_write(29'h020, 32'h0000_0000);                    // PITCH pad = 0
      csr_write(29'h000, 32'h0000_0001 | 32'h0000_0180 | 32'h0000_0600); // VEN|VBL8|CD32
      $display("[vram] scanout enabled (CTRL=0x781, VBAR=0, VSIZ=1024)");

      scan_ar=0; scan_r=0; emif_ar=0; emif_aw=0; emif_w=0; got_first=1'b0;

      // Run frames while hammering the write port at a separate VRAM region, so
      // the crossbar must arbitrate scanout reads (slave 0) vs h2f writes (slave 1).
      fork
         begin : traffic
            int t_bad;
            forever begin
               h2f_write_burst(32'h0000_2000, 16, 32'h2000_0000);
               // read the (stable) pre-fill region back while scanout also reads
               // it -- exercises crossbar read arbitration + the adapter downsize.
               h2f_read_burst(32'h0000_0000, 16, 32'h1000_0000, t_bad);
               chk(t_bad == 0, "h2f concurrent readback mismatch (adapter under arbitration)");
               repeat (200) @(posedge tb_clk_sys);
            end
         end
         begin : frames
            repeat (8000) @(posedge tb_clk_sys);
         end
      join_any
      disable traffic;
      h2f_idle();

      $display("[vram] scanout AR granted    : %0d", scan_ar);
      $display("[vram] scanout R beats        : %0d", scan_r);
      $display("[vram] EMIF AR (xbar->emif)   : %0d", emif_ar);
      $display("[vram] EMIF AW (xbar->emif)   : %0d", emif_aw);
      $display("[vram] EMIF W beats           : %0d", emif_w);
      $display("[vram] h2f read 128b beats    : %0d (HPS side)", h2f_r);
      $display("[vram] adapter 256b read beats: %0d (xbar side; expect ~h2f/2)", m1_r);
      if (got_first)
        $display("[vram] first scanout 256b word: 0x%064h", first_rdata);

      chk(scan_ar > 0, "vctrl_axim issued NO reads (reproduces the HW symptom)");
      chk(scan_r  > 0, "scanout received NO read data");
      chk(emif_aw > 0, "no h2f writes reached the EMIF through the crossbar");

      if (scan_ar > 0 && scan_r > 0)
        $display("[vram] PASS: scanout reads flow through the crossbar to the EMIF");
      else
        $display("[vram] FAIL: scanout master is not reading -- matches hardware");

      // Reproduce the hardware lockup: a WRAP cache-line read (arcache[1]=1) like
      // an ARM linefill / the login readback. Wedges with the adapter's default
      // burst-convert path; completes with CONVERT_BURST=0 on u_axi_adapter.
      $display("[vram] WRAP cache-line read repro (arburst=WRAP, arcache=0x2 @ 0x70):");
      h2f_read_wrap(32'h0000_0070, 4);

      $display("################ end VRAM scanout test ################");
   endtask
`endif //  `ifdef ENABLE_HPS2FPGA

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
`ifdef ENABLE_HPS2FPGA
         vram_scanout_test();
`endif
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
