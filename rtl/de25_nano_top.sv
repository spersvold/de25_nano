// -*- mode: verilog; mode: font-lock; indent-tabs-mode: nil -*-
// vi: set et ts=3 sw=3 sts=3:
//
// Copyright 2026 Steffen Persvold
// SPDX-License-Identifier: Apache-2.0
//
// ========================================================================
// File        : de25_nano_top.sv
// Author      : Steffen Persvold
// Created     : April 15, 2026
// ========================================================================
// Description : DE25 Nano FPGA Top-level wrapper
// ========================================================================
//

`define ENABLE_LPDDR4A
`define ENABLE_HPS
`define ENABLE_HDMI
//`define ENABLE_FPGA2HPS
`define ENABLE_FPGA2SDRAM
//`define ENABLE_HPS2FPGA

module de25_nano_top
  (
   // CLOCK
    input  wire              CLOCK0_50
   ,input  wire              CLOCK1_50
   ,input  wire              CLOCK2_50

   // KEY
   ,input  wire    [ 1: 0]   KEY

   // SW
   ,input  wire    [ 3: 0]   SW

   // LED
   ,output wire    [ 7: 0]   LED

`ifdef ENABLE_SDRAM
   // SDRAM
   ,output wire              DRAM_CLK
   ,output wire              DRAM_CKE
   ,output wire    [12: 0]   DRAM_ADDR
   ,output wire    [ 1: 0]   DRAM_BA
   ,inout  wire    [15: 0]   DRAM_DQ
   ,output wire              DRAM_LDQM
   ,output wire              DRAM_UDQM
   ,output wire    [ 1: 0]   DRAM_CS_n
   ,output wire              DRAM_WE_n
   ,output wire              DRAM_CAS_n
   ,output wire              DRAM_RAS_n
`endif //  `ifdef ENABLE_SDRAM

`ifdef ENABLE_LPDDR4A
   // LPDDR4A
   ,input  wire              LPDDR4A_REFCLK_p
   ,output wire              LPDDR4A_CS_n
   ,output wire    [ 5: 0]   LPDDR4A_CA
   ,output wire              LPDDR4A_CK
   ,output wire              LPDDR4A_CK_n
   ,output wire              LPDDR4A_CKE
   ,inout  wire    [ 3: 0]   LPDDR4A_DM
   ,inout  wire    [31: 0]   LPDDR4A_DQ
   ,inout  wire    [ 3: 0]   LPDDR4A_DQS
   ,inout  wire    [ 3: 0]   LPDDR4A_DQS_n
   ,output wire              LPDDR4A_RESET_n
   ,input  wire              LPDDR4A_RZQ
`endif //  `ifdef ENABLE_LPDDR4A

`ifdef ENABLE_LPDDR4B
   // LPDDR4B
   ,input  wire              LPDDR4B_REFCLK_p
   ,output wire              LPDDR4B_CS_n
   ,output wire    [ 5: 0]   LPDDR4B_CA
   ,output wire              LPDDR4B_CK
   ,output wire              LPDDR4B_CK_n
   ,output wire              LPDDR4B_CKE
   ,inout  wire    [ 3: 0]   LPDDR4B_DM
   ,inout  wire    [31: 0]   LPDDR4B_DQ
   ,inout  wire    [ 3: 0]   LPDDR4B_DQS
   ,inout  wire    [ 3: 0]   LPDDR4B_DQS_n
   ,output wire              LPDDR4B_RESET_n
   ,input  wire              LPDDR4B_RZQ
`endif //  `ifdef ENABLE_LPDDR4B

`ifdef ENABLE_HDMI
   // HDMI
   ,inout  wire              HDMI_LRCLK
   ,inout  wire              HDMI_MCLK
   ,inout  wire              HDMI_SCLK
   ,output wire              HDMI_TX_CLK
   ,output wire              HDMI_TX_HS
   ,output wire              HDMI_TX_VS
   ,output wire    [23: 0]   HDMI_TX_D
   ,output wire              HDMI_TX_DE
   ,inout  wire              HDMI_I2C_SCL
   ,inout  wire              HDMI_I2C_SDA
   ,input  wire              HDMI_TX_INT
   ,inout  wire              HDMI_I2S
`endif //  `ifdef ENABLE_HDMI

`ifdef ENABLE_CAM
   // CAM
   ,input  wire              CAM_CLK_p
   ,input  wire              CAM_CLK_n
   ,input  wire    [ 1: 0]   CAM_D_p
   ,input  wire    [ 1: 0]   CAM_D_n
   ,inout  wire              CAM_I2C_SCL
   ,inout  wire              CAM_I2C_SDA
   ,inout  wire              CAM_GPIO
   ,input  wire              CAM_RZQ1
`endif //  `ifdef ENABLE_CAM

`ifdef ENABLE_HPS
   // HPS
   ,input  wire              HPS_CLK_25
   ,output wire              HPS_ENET_MDC
   ,inout  wire              HPS_ENET_MDIO
   ,input  wire              HPS_ENET_RX_CLK
   ,input  wire              HPS_ENET_RX_CTL
   ,input  wire    [ 3: 0]   HPS_ENET_RX_DATA
   ,output wire              HPS_ENET_TX_CLK
   ,output wire              HPS_ENET_TX_CTL
   ,output wire    [ 3: 0]   HPS_ENET_TX_DATA
   ,output wire              HPS_SD_CLK
   ,inout  wire              HPS_SD_CMD
   ,inout  wire    [ 3: 0]   HPS_SD_DATA
   ,input  wire              HPS_USB_CLK
   ,inout  wire    [ 7: 0]   HPS_USB_DATA
   ,input  wire              HPS_USB_DIR
   ,input  wire              HPS_USB_NXT
   ,output wire              HPS_USB_STP
   ,output wire              HPS_UART_TX
   ,input  wire              HPS_UART_RX
   ,inout  wire              HPS_I2C_SCL
   ,inout  wire              HPS_I2C_SDA
   ,inout  wire              HPS_GSENSOR_I2C_EN
   ,inout  wire              HPS_GSENSOR_INT
   ,inout  wire              HPS_KEY
   ,inout  wire              HPS_LED
`endif //  `ifdef ENABLE_HPS

   // FPGA UART
   ,output wire              FPGA_UART_TX
   ,input  wire              FPGA_UART_RX

   ///////// ADC /////////
   ,output wire              ADC_SCK
   ,input  wire              ADC_SDO
   ,output wire              ADC_SDI
   ,output wire              ADC_CS_n

`ifdef ENABLE_GPIO
   ///////// GPIO /////////
   ,inout  wire    [35: 0]   GPIO0_D
   ,inout  wire    [35: 0]   GPIO1_D
`endif //  `ifdef ENABLE_GPIO

   ///////// FAN /////////
   ,input  wire              FAN_ALERT_n
   );

   // ========================================================================
   // ========================================================================

   wire                      buf_refclk;
   assign buf_refclk = CLOCK0_50;

   wire [1:0]                key_in;
   assign key_in = KEY;

   wire [1:0]                key_f;
   signal_filter u_btn_filter[1:0]
     (.clk        (buf_refclk),
      .unfiltered (key_in),
      .filtered   (key_f),
      .stable     ());

   wire                      ninit_done;
   reset_release u_reset_release
     (.ninit_done);

   // synthesis translate_off
`ifdef SIMULATION
   localparam [22:0] POR_COUNT_100MS = 23'd499;
`else
   // synthesis translate_on
   localparam [22:0] POR_COUNT_100MS = 23'd4999999;
   // synthesis translate_off
`endif
   // synthesis translate_on

   // 100ms Power-On Reset (POR) counter
   logic [22:0]              por_counter; initial por_counter = '0;
   logic                     por_done;

   always @(posedge buf_refclk) begin
      if (por_counter < POR_COUNT_100MS) begin  // 100ms at 50MHz
         por_counter <= por_counter + 1'b1;
         por_done <= 1'b0;
      end
      else begin
         por_done <= 1'b1;
      end
   end

   wire                      por_rstn_in;
   wire                      por_rstn;
   assign por_rstn_in = key_f[0] & ~ninit_done & por_done;

   areset_synchronizer #(.ACTIVE_HIGH (0)) u_por_rstn_sync
     (.clk       (buf_refclk),
      .reset_in  (por_rstn_in),
      .reset_out (por_rstn));

   //
   // Core PLL
   //

   wire                      clk_sys;
   wire                      core_pll_locked;

   wire                      pll_rst;
   assign pll_rst = ~(key_f[0] & ~ninit_done);

   core_pll u_core_pll
     (.refclk  (CLOCK2_50),
      .locked  (core_pll_locked),
      .rst     (pll_rst),
      .clk_sys
      );

   // HPS Reset signals/handshake
   wire                      h2f_reset_reset;                    // Active high reset from the HPS Reset Manager.
   wire                      h2f_warm_reset_handshake_reset_req; // HPS warm reset request. Identical to watchdog reset except this is asserted by SDM. Active-low.
   wire                      h2f_warm_reset_handshake_reset_ack; // HPS warm reset acknowledge response to SDM. Should be asserted when all HPS soft logic is successfully in reset. Active-low.

   // Synchroize PLL Lock and use as system reset
   wire                      rst_sys_in;
   assign rst_sys_in = ~(key_f[1] & core_pll_locked & por_done) |
                       h2f_reset_reset |
                       (h2f_warm_reset_handshake_reset_req == 1'b0);

   assign h2f_warm_reset_handshake_reset_ack = h2f_warm_reset_handshake_reset_req;

   wire                      rst_sys;
   areset_synchronizer #(.ACTIVE_HIGH (1)) u_sys_reset_sync
     (.clk       (clk_sys),
      .reset_in  (rst_sys_in),
      .reset_out (rst_sys));

   //
   // HPS Subsystem
   //

   localparam [ 0:0] AXMMUSECSID = 1'b0;      // Use Non-Secure MMU Context (MMU Active)
   localparam [15:0] AXMMUSID    = 16'h0010;  // MMU Stream ID (when not secure)

   // FPGA2HPS Interrupts
   wire [31:0]               f2h_irq0;

`ifdef ENABLE_FPGA2HPS
   // FPGA2HPS ACE5Lite Slave port (FPGA -> HPS; 256-bit data, 32-bit addr)
   wire [4:0]                fpga2hps_awid;
   wire [31:0]               fpga2hps_awaddr;
   wire [3:0]                fpga2hps_awregion = 4'h0;
   wire [1:0]                fpga2hps_awdomain = 2'b01;
   wire [3:0]                fpga2hps_awsnoop = 4'h0;
   wire [7:0]                fpga2hps_awlen;
   wire [2:0]                fpga2hps_awsize;
   wire [2:0]                fpga2hps_arsize;
   wire [1:0]                fpga2hps_awburst;
   wire                      fpga2hps_awlock;
   wire [3:0]                fpga2hps_awcache;
   wire [2:0]                fpga2hps_awprot;
   wire [3:0]                fpga2hps_awqos = 4'h0;
   wire [7:0]                fpga2hps_awuser = 8'h04; // To CCS
   wire [10:0]               fpga2hps_awstashnid = 11'h0;
   wire                      fpga2hps_awstashniden = 1'b0;
   wire [4:0]                fpga2hps_awstashlpid = 5'h0;
   wire                      fpga2hps_awstashlpiden = 1'b0;
   wire [5:0]                fpga2hps_awatop = 6'h0;
   wire                      fpga2hps_awmmusecsid = AXMMUSECSID;
   wire [15:0]               fpga2hps_awmmusid = AXMMUSID;
   wire                      fpga2hps_awvalid;
   wire                      fpga2hps_awready;
   wire [255:0]              fpga2hps_wdata;
   wire [31:0]               fpga2hps_wstrb;
   wire                      fpga2hps_wlast;
   wire [7:0]                fpga2hps_wuser = 8'h04;
   wire                      fpga2hps_wvalid;
   wire                      fpga2hps_wready;
   wire [4:0]                fpga2hps_bid;
   wire [1:0]                fpga2hps_bresp;
   wire [7:0]                fpga2hps_buser;
   wire                      fpga2hps_bvalid;
   wire                      fpga2hps_bready;
   wire [4:0]                fpga2hps_arid;
   wire [31:0]               fpga2hps_araddr;
   wire [3:0]                fpga2hps_arregion = 4'h0;
   wire [1:0]                fpga2hps_ardomain = 2'b01;
   wire [3:0]                fpga2hps_arsnoop = 4'h0;
   wire [7:0]                fpga2hps_arlen;
   wire [1:0]                fpga2hps_arburst;
   wire                      fpga2hps_arlock;
   wire [3:0]                fpga2hps_arcache;
   wire [2:0]                fpga2hps_arprot;
   wire [3:0]                fpga2hps_arqos = 4'hf; // Latency sensitive
   wire [7:0]                fpga2hps_aruser = 8'h04; // To CCS
   wire                      fpga2hps_armmusecsid = AXMMUSECSID;
   wire [15:0]               fpga2hps_armmusid = AXMMUSID;
   wire                      fpga2hps_arvalid;
   wire                      fpga2hps_arready;
   wire [4:0]                fpga2hps_rid;
   wire [255:0]              fpga2hps_rdata;
   wire [1:0]                fpga2hps_rresp;
   wire                      fpga2hps_rlast;
   wire [7:0]                fpga2hps_ruser;
   wire                      fpga2hps_rvalid;
   wire                      fpga2hps_rready;
`endif //  `ifdef ENABLE_FPGA2HPS

`ifdef ENABLE_FPGA2SDRAM
   // FPGA2SDRAM AXI4 Slave port (FPGA -> SDRAM; 256-bit data, 32-bit addr)
   wire [4:0]                f2sdram_awid;
   wire [31:0]               f2sdram_awaddr;
   wire [3:0]                f2sdram_awregion = 4'h0;
   wire [7:0]                f2sdram_awlen;
   wire [2:0]                f2sdram_awsize;
   wire [1:0]                f2sdram_awburst;
   wire                      f2sdram_awlock;
   wire [3:0]                f2sdram_awcache;
   wire [2:0]                f2sdram_awprot;
   wire [3:0]                f2sdram_awqos = 4'h0;
   wire [24:0]               f2sdram_awuser = {AXMMUSID, AXMMUSECSID, 8'hE0};
   wire                      f2sdram_awvalid;
   wire                      f2sdram_awready;
   wire [255:0]              f2sdram_wdata;
   wire [31:0]               f2sdram_wstrb;
   wire                      f2sdram_wlast;
   wire [7:0]                f2sdram_wuser = 8'h00;
   wire                      f2sdram_wvalid;
   wire                      f2sdram_wready;
   wire [4:0]                f2sdram_bid;
   wire [1:0]                f2sdram_bresp;
   wire [7:0]                f2sdram_buser;
   wire                      f2sdram_bvalid;
   wire                      f2sdram_bready;
   wire [4:0]                f2sdram_arid;
   wire [31:0]               f2sdram_araddr;
   wire [3:0]                f2sdram_arregion = 4'h0;
   wire [7:0]                f2sdram_arlen;
   wire [2:0]                f2sdram_arsize;
   wire [1:0]                f2sdram_arburst;
   wire                      f2sdram_arlock;
   wire [3:0]                f2sdram_arcache;
   wire [2:0]                f2sdram_arprot;
   wire [3:0]                f2sdram_arqos = 4'hf; // Latency sensitive
   wire [24:0]               f2sdram_aruser = {AXMMUSID, AXMMUSECSID, 8'hE0};
   wire                      f2sdram_arvalid;
   wire                      f2sdram_arready;
   wire [4:0]                f2sdram_rid;
   wire [255:0]              f2sdram_rdata;
   wire [1:0]                f2sdram_rresp;
   wire                      f2sdram_rlast;
   wire [7:0]                f2sdram_ruser;
   wire                      f2sdram_rvalid;
   wire                      f2sdram_rready;
`endif //  `ifdef ENABLE_FPGA2SDRAM

`ifdef ENABLE_HPS2FPGA
   // HPS2FPGA AXI4 Master port (HPS -> FPGA; 128-bit data, 32-bit addr)
   wire [3:0]                hps2fpga_awid;
   wire [31:0]               hps2fpga_awaddr;
   wire [7:0]                hps2fpga_awlen;
   wire [2:0]                hps2fpga_awsize;
   wire [1:0]                hps2fpga_awburst;
   wire                      hps2fpga_awlock;
   wire [3:0]                hps2fpga_awcache;
   wire [2:0]                hps2fpga_awprot;
   wire                      hps2fpga_awvalid;
   wire                      hps2fpga_awready = 1'b0;
   wire [127:0]              hps2fpga_wdata;
   wire [15:0]               hps2fpga_wstrb;
   wire                      hps2fpga_wlast;
   wire                      hps2fpga_wvalid;
   wire                      hps2fpga_wready = 1'b0;
   wire [3:0]                hps2fpga_bid = 4'h0;
   wire [1:0]                hps2fpga_bresp = 2'b00;
   wire                      hps2fpga_bvalid = 1'b0;
   wire                      hps2fpga_bready;
   wire [3:0]                hps2fpga_arid;
   wire [31:0]               hps2fpga_araddr;
   wire [7:0]                hps2fpga_arlen;
   wire [2:0]                hps2fpga_arsize;
   wire [1:0]                hps2fpga_arburst;
   wire                      hps2fpga_arlock;
   wire [3:0]                hps2fpga_arcache;
   wire [2:0]                hps2fpga_arprot;
   wire                      hps2fpga_arvalid;
   wire                      hps2fpga_arready = 1'b0;
   wire [3:0]                hps2fpga_rid = 4'h0;
   wire [127:0]              hps2fpga_rdata = 128'h0;
   wire [1:0]                hps2fpga_rresp = 2'b00;
   wire                      hps2fpga_rlast = 1'b0;
   wire                      hps2fpga_rvalid = 1'b0;
   wire                      hps2fpga_rready;
`endif //  `ifdef ENABLE_HPS2FPGA

   // LWHPS2FPGA AXI4 Master port (HPS -> FPGA, lightweight; 32-bit data, 29-bit addr)
   wire [3:0]                lwhps2fpga_awid;
   wire [28:0]               lwhps2fpga_awaddr;
   wire [7:0]                lwhps2fpga_awlen;
   wire [2:0]                lwhps2fpga_awsize;
   wire [1:0]                lwhps2fpga_awburst;
   wire                      lwhps2fpga_awlock;
   wire [3:0]                lwhps2fpga_awcache;
   wire [2:0]                lwhps2fpga_awprot;
   wire                      lwhps2fpga_awvalid;
   wire                      lwhps2fpga_awready;
   wire [31:0]               lwhps2fpga_wdata;
   wire [3:0]                lwhps2fpga_wstrb;
   wire                      lwhps2fpga_wlast;
   wire                      lwhps2fpga_wvalid;
   wire                      lwhps2fpga_wready;
   wire [3:0]                lwhps2fpga_bid;
   wire [1:0]                lwhps2fpga_bresp;
   wire                      lwhps2fpga_bvalid;
   wire                      lwhps2fpga_bready;
   wire [3:0]                lwhps2fpga_arid;
   wire [28:0]               lwhps2fpga_araddr;
   wire [7:0]                lwhps2fpga_arlen;
   wire [2:0]                lwhps2fpga_arsize;
   wire [1:0]                lwhps2fpga_arburst;
   wire                      lwhps2fpga_arlock;
   wire [3:0]                lwhps2fpga_arcache;
   wire [2:0]                lwhps2fpga_arprot;
   wire                      lwhps2fpga_arvalid;
   wire                      lwhps2fpga_arready;
   wire [3:0]                lwhps2fpga_rid;
   wire [31:0]               lwhps2fpga_rdata;
   wire [1:0]                lwhps2fpga_rresp;
   wire                      lwhps2fpga_rlast;
   wire                      lwhps2fpga_rvalid;
   wire                      lwhps2fpga_rready;

   hps_wrapper u_hps_wrapper
     (.clk_sys,
      .rst_sys,
      .h2f_reset_reset,
      .h2f_warm_reset_handshake_reset_req,
      .h2f_warm_reset_handshake_reset_ack,
`ifdef ENABLE_FPGA2HPS
      //
      .fpga2hps_awid,
      .fpga2hps_awaddr,
      .fpga2hps_awregion,
      .fpga2hps_awdomain,
      .fpga2hps_awsnoop,
      .fpga2hps_awlen,
      .fpga2hps_awsize,
      .fpga2hps_awburst,
      .fpga2hps_awlock,
      .fpga2hps_awcache,
      .fpga2hps_awprot,
      .fpga2hps_awqos,
      .fpga2hps_awuser,
      .fpga2hps_awstashnid,
      .fpga2hps_awstashniden,
      .fpga2hps_awstashlpid,
      .fpga2hps_awstashlpiden,
      .fpga2hps_awatop,
      .fpga2hps_awmmusecsid,
      .fpga2hps_awmmusid,
      .fpga2hps_awvalid,
      .fpga2hps_awready,
      .fpga2hps_wdata,
      .fpga2hps_wstrb,
      .fpga2hps_wlast,
      .fpga2hps_wuser,
      .fpga2hps_wvalid,
      .fpga2hps_wready,
      .fpga2hps_bid,
      .fpga2hps_bresp,
      .fpga2hps_buser,
      .fpga2hps_bvalid,
      .fpga2hps_bready,
      .fpga2hps_arid,
      .fpga2hps_araddr,
      .fpga2hps_arregion,
      .fpga2hps_ardomain,
      .fpga2hps_arsnoop,
      .fpga2hps_arlen,
      .fpga2hps_arsize,
      .fpga2hps_arburst,
      .fpga2hps_arlock,
      .fpga2hps_arcache,
      .fpga2hps_arprot,
      .fpga2hps_arqos,
      .fpga2hps_aruser,
      .fpga2hps_armmusecsid,
      .fpga2hps_armmusid,
      .fpga2hps_arvalid,
      .fpga2hps_arready,
      .fpga2hps_rid,
      .fpga2hps_rdata,
      .fpga2hps_rresp,
      .fpga2hps_rlast,
      .fpga2hps_ruser,
      .fpga2hps_rvalid,
      .fpga2hps_rready,
`endif //  `ifdef ENABLE_FPGA2HPS
`ifdef ENABLE_FPGA2SDRAM
      //
      .f2sdram_awid,
      .f2sdram_awaddr,
      .f2sdram_awregion,
      .f2sdram_awlen,
      .f2sdram_awsize,
      .f2sdram_awburst,
      .f2sdram_awlock,
      .f2sdram_awcache,
      .f2sdram_awprot,
      .f2sdram_awqos,
      .f2sdram_awuser,
      .f2sdram_awvalid,
      .f2sdram_awready,
      .f2sdram_wdata,
      .f2sdram_wstrb,
      .f2sdram_wlast,
      .f2sdram_wuser,
      .f2sdram_wvalid,
      .f2sdram_wready,
      .f2sdram_bid,
      .f2sdram_bresp,
      .f2sdram_buser,
      .f2sdram_bvalid,
      .f2sdram_bready,
      .f2sdram_arid,
      .f2sdram_araddr,
      .f2sdram_arregion,
      .f2sdram_arlen,
      .f2sdram_arsize,
      .f2sdram_arburst,
      .f2sdram_arlock,
      .f2sdram_arcache,
      .f2sdram_arprot,
      .f2sdram_arqos,
      .f2sdram_aruser,
      .f2sdram_arvalid,
      .f2sdram_arready,
      .f2sdram_rid,
      .f2sdram_rdata,
      .f2sdram_rresp,
      .f2sdram_rlast,
      .f2sdram_ruser,
      .f2sdram_rvalid,
      .f2sdram_rready,
`endif //  `ifdef ENABLE_FPGA2SDRAM
`ifdef ENABLE_HPS2FPGA
      //
      .hps2fpga_awid,
      .hps2fpga_awaddr,
      .hps2fpga_awlen,
      .hps2fpga_awsize,
      .hps2fpga_awburst,
      .hps2fpga_awlock,
      .hps2fpga_awcache,
      .hps2fpga_awprot,
      .hps2fpga_awvalid,
      .hps2fpga_awready,
      .hps2fpga_wdata,
      .hps2fpga_wstrb,
      .hps2fpga_wlast,
      .hps2fpga_wvalid,
      .hps2fpga_wready,
      .hps2fpga_bid,
      .hps2fpga_bresp,
      .hps2fpga_bvalid,
      .hps2fpga_bready,
      .hps2fpga_arid,
      .hps2fpga_araddr,
      .hps2fpga_arlen,
      .hps2fpga_arsize,
      .hps2fpga_arburst,
      .hps2fpga_arlock,
      .hps2fpga_arcache,
      .hps2fpga_arprot,
      .hps2fpga_arvalid,
      .hps2fpga_arready,
      .hps2fpga_rid,
      .hps2fpga_rdata,
      .hps2fpga_rresp,
      .hps2fpga_rlast,
      .hps2fpga_rvalid,
      .hps2fpga_rready,
`endif //  `ifdef ENABLE_HPS2FPGA
      //
      .lwhps2fpga_awid,
      .lwhps2fpga_awaddr,
      .lwhps2fpga_awlen,
      .lwhps2fpga_awsize,
      .lwhps2fpga_awburst,
      .lwhps2fpga_awlock,
      .lwhps2fpga_awcache,
      .lwhps2fpga_awprot,
      .lwhps2fpga_awvalid,
      .lwhps2fpga_awready,
      .lwhps2fpga_wdata,
      .lwhps2fpga_wstrb,
      .lwhps2fpga_wlast,
      .lwhps2fpga_wvalid,
      .lwhps2fpga_wready,
      .lwhps2fpga_bid,
      .lwhps2fpga_bresp,
      .lwhps2fpga_bvalid,
      .lwhps2fpga_bready,
      .lwhps2fpga_arid,
      .lwhps2fpga_araddr,
      .lwhps2fpga_arlen,
      .lwhps2fpga_arsize,
      .lwhps2fpga_arburst,
      .lwhps2fpga_arlock,
      .lwhps2fpga_arcache,
      .lwhps2fpga_arprot,
      .lwhps2fpga_arvalid,
      .lwhps2fpga_arready,
      .lwhps2fpga_rid,
      .lwhps2fpga_rdata,
      .lwhps2fpga_rresp,
      .lwhps2fpga_rlast,
      .lwhps2fpga_rvalid,
      .lwhps2fpga_rready,
      //
      .hps_io_hps_osc_clk        (HPS_CLK_25),
      .hps_io_mdio0_mdc          (HPS_ENET_MDC),
      .hps_io_mdio0_mdio         (HPS_ENET_MDIO),
      .hps_io_emac0_rx_clk       (HPS_ENET_RX_CLK),
      .hps_io_emac0_rx_ctl       (HPS_ENET_RX_CTL),
      .hps_io_emac0_rxd0         (HPS_ENET_RX_DATA[0]),
      .hps_io_emac0_rxd1         (HPS_ENET_RX_DATA[1]),
      .hps_io_emac0_rxd2         (HPS_ENET_RX_DATA[2]),
      .hps_io_emac0_rxd3         (HPS_ENET_RX_DATA[3]),
      .hps_io_emac0_tx_clk       (HPS_ENET_TX_CLK),
      .hps_io_emac0_tx_ctl       (HPS_ENET_TX_CTL),
      .hps_io_emac0_txd0         (HPS_ENET_TX_DATA[0]),
      .hps_io_emac0_txd1         (HPS_ENET_TX_DATA[1]),
      .hps_io_emac0_txd2         (HPS_ENET_TX_DATA[2]),
      .hps_io_emac0_txd3         (HPS_ENET_TX_DATA[3]),
      .hps_io_sdmmc_cclk         (HPS_SD_CLK),
      .hps_io_sdmmc_cmd          (HPS_SD_CMD),
      .hps_io_sdmmc_data0        (HPS_SD_DATA[0]),
      .hps_io_sdmmc_data1        (HPS_SD_DATA[1]),
      .hps_io_sdmmc_data2        (HPS_SD_DATA[2]),
      .hps_io_sdmmc_data3        (HPS_SD_DATA[3]),
      .hps_io_usb0_clk           (HPS_USB_CLK),
      .hps_io_usb0_data0         (HPS_USB_DATA[0]),
      .hps_io_usb0_data1         (HPS_USB_DATA[1]),
      .hps_io_usb0_data2         (HPS_USB_DATA[2]),
      .hps_io_usb0_data3         (HPS_USB_DATA[3]),
      .hps_io_usb0_data4         (HPS_USB_DATA[4]),
      .hps_io_usb0_data5         (HPS_USB_DATA[5]),
      .hps_io_usb0_data6         (HPS_USB_DATA[6]),
      .hps_io_usb0_data7         (HPS_USB_DATA[7]),
      .hps_io_usb0_dir           (HPS_USB_DIR),
      .hps_io_usb0_nxt           (HPS_USB_NXT),
      .hps_io_usb0_stp           (HPS_USB_STP),
      .hps_io_uart1_tx           (HPS_UART_TX),
      .hps_io_uart1_rx           (HPS_UART_RX),
      .hps_io_i2c1_scl           (HPS_I2C_SCL),
      .hps_io_i2c1_sda           (HPS_I2C_SDA),
      .hps_io_gpio28             (HPS_GSENSOR_INT),
      .hps_io_gpio34             (HPS_GSENSOR_I2C_EN),
      .hps_io_gpio40             (HPS_KEY),
      .hps_io_gpio41             (HPS_LED),
      .mem_0_cs                  (LPDDR4A_CS_n),
      .mem_0_ca                  (LPDDR4A_CA),
      .mem_0_ck_t                (LPDDR4A_CK),
      .mem_0_ck_c                (LPDDR4A_CK_n),
      .mem_0_cke                 (LPDDR4A_CKE),
      .mem_0_dmi                 (LPDDR4A_DM),
      .mem_0_dq                  (LPDDR4A_DQ),
      .mem_0_dqs_t               (LPDDR4A_DQS),
      .mem_0_dqs_c               (LPDDR4A_DQS_n),
      .mem_0_reset_n             (LPDDR4A_RESET_n),
      .oct_rzqin_0               (LPDDR4A_RZQ),
      .ref_clk                   (LPDDR4A_REFCLK_p),
      .f2h_irq0                  (f2h_irq0)
      );

   // HDMI PHY I2C init -- ADV7513-class chips need a register-write
   // sequence over I2C before they forward video out. Runs on the
   // chipset clock since the engine sits naturally alongside the rest
   // of the HDMI output path; ready returns to the SoC unsynchronized
   // (clk_28m is ratio-synchronous to clk_sys).
   //
   // SDA is open-drain: sda_e gates a tri-state pad driver, sda_o is
   // tied 0 inside the module so we only ever drive low (external pull-
   // up on the board resolves '1'). SCL is push-pull from our side --
   // ADV7513 tolerates that.
   wire                      hdmi_scl;
   wire                      hdmi_sda_i;
   wire                      hdmi_sda_o;
   wire                      hdmi_sda_e;
   wire                      hdmi_config_done;

   assign HDMI_I2C_SCL = hdmi_scl;
   assign HDMI_I2C_SDA = hdmi_sda_e ? hdmi_sda_o : 1'bz;
   assign hdmi_sda_i   = HDMI_I2C_SDA;

   hdmi_tx_config #(.CLK_HZ (50000000)) u_hdmi_tx_config
     (.clk      (buf_refclk),
      .rstn     (por_rstn),
      .tx_int_n (HDMI_TX_INT),
      .scl      (hdmi_scl),
      .sda_i    (hdmi_sda_i),
      .sda_o    (hdmi_sda_o),
      .sda_e    (hdmi_sda_e),
      .done     (hdmi_config_done));

   //
   // HDMI PLL
   //

   wire                      clk_pix;
   wire                      hdmi_pll_locked;

   // core_avl reconfiguration bus (buf_refclk domain), driven by hdmi_pll_recfg
   wire [8:0]                avl_address;
   wire                      avl_read;
   wire [7:0]                avl_readdata;
   wire                      avl_write;
   wire [7:0]                avl_writedata;

   hdmi_pll u_hdmi_pll
     (.refclk             (CLOCK1_50),
      .locked             (hdmi_pll_locked),
      .rst                (pll_rst),
      .clk_pix,
      // dynamic reconfiguration (HVIO core_avl, IOSSM role driven by us)
      .core_avl_clk       (buf_refclk),
      .core_avl_address   (avl_address),
      .core_avl_read      (avl_read),
      .core_avl_readdata  (avl_readdata),
      .core_avl_write     (avl_write),
      .core_avl_writedata (avl_writedata)
      );

   // Pixel-domain reset: mirrors rst_sys but gated on the PIXEL PLL lock
   // (hdmi_pll_locked) instead of core_pll, and synchronized to clk_pix. So the
   // pixel domain is held in reset whenever clk_pix is invalid -- including
   // during a PLL reconfig, where hdmi_pll drops lock -- and releases cleanly
   // once the pixel clock relocks.
   wire                      rst_pix_in;
   assign rst_pix_in = ~(key_f[1] & hdmi_pll_locked & por_done);

   wire                      rst_pix;
   areset_synchronizer #(.ACTIVE_HIGH (1)) u_pix_reset_sync
     (.clk       (clk_pix),
      .reset_in  (rst_pix_in),
      .reset_out (rst_pix));

   // clk_pix frequency monitor (bring-up / SignalTap). Counts clk_pix edges over
   // a fixed window timed by buf_refclk (50 MHz): freq_pix_khz reads the pixel
   // clock in kHz (148500 = 148.5 MHz, 74250 = 74.25 MHz, 0 = stopped). Lives in
   // the buf_refclk domain so it stays readable even while clk_pix is unstable.
   // Uses rst_pix as its measurement reset: rst_pix asserts only on PLL unlock /
   // POR / the reset key (not on the software VEN), so the counter runs whenever
   // the PLL is locked and reads the relocked frequency right after a reconfig.
`ifdef SIMULATION
   localparam int FREQ_WINDOW = 5000;    // 100 us @ 50 MHz; freq_pix_khz = f_pix(kHz)/10
`else
   localparam int FREQ_WINDOW = 50000;   // 1 ms @ 50 MHz; freq_pix_khz = f_pix in kHz
`endif
   (* preserve *)
   wire [23:0]               freq_pix_khz;   // buf_refclk domain
   freq_counter #(.REF_WINDOW (FREQ_WINDOW), .CNT_W (24)) u_freq_pix
     (.ref_clk    (buf_refclk),
      .ref_rst_n  (por_rstn),
      .meas_clk   (clk_pix),
      .meas_rst_n (~rst_pix),
      .freq_out   (freq_pix_khz));

   //
   // HDMI PLL dynamic reconfiguration
   //
   // The video controller exposes PLLDIVCNT (logical M/N/C) and a W1S
   // PLLCTRL.apply trigger in the clk_sys CSR domain. hdmi_pll_recfg runs the
   // Agilex 5 HVIO reconfiguration sequence in the buf_refclk (core_avl) domain.
   // apply/done cross via toggle CDC; M/N/C are quasi-static (held stable by
   // the apply/done handshake); locked/error are level-synchronized to clk_sys.

   wire [31:0]               hdmi_pll_divcnt;       // PLLDIVCNT (clk_sys, quasi-static)
   wire                      hdmi_pll_apply;        // trigger pulse (clk_sys)
   wire                      hdmi_pll_done;         // done pulse (clk_sys)
   wire                      hdmi_pll_error;        // synced recal error (clk_sys)
   wire                      hdmi_pll_locked_sys;   // synced PLL locked (clk_sys)

   wire                      hdmi_recfg_start;      // buf_refclk
   wire                      hdmi_recfg_done;       // buf_refclk
   wire                      hdmi_recfg_error;      // buf_refclk

   // apply trigger: clk_sys -> buf_refclk
   cdc_tgl u_pll_apply_cdc
     (.clk_i (clk_sys), .rst_i (rst_sys), .clk_o (buf_refclk),
      .i (hdmi_pll_apply), .o (hdmi_recfg_start));

   // done pulse: buf_refclk -> clk_sys
   cdc_tgl u_pll_done_cdc
     (.clk_i (buf_refclk), .rst_i (~por_rstn), .clk_o (clk_sys),
      .i (hdmi_recfg_done), .o (hdmi_pll_done));

   // status levels -> clk_sys
   synchronizer u_pll_error_sync  (.clk (clk_sys), .d (hdmi_recfg_error), .q (hdmi_pll_error));
   synchronizer u_pll_locked_sync (.clk (clk_sys), .d (hdmi_pll_locked),  .q (hdmi_pll_locked_sys));

   hdmi_pll_recfg u_hdmi_pll_recfg
     (.clk           (buf_refclk),
      .rst_n         (por_rstn),
      .start         (hdmi_recfg_start),
      .m             (hdmi_pll_divcnt[ 8:0]),
      .n             (hdmi_pll_divcnt[15:9]),
      .c             (hdmi_pll_divcnt[24:16]),
      .pll_locked_in (hdmi_pll_locked),
      .done          (hdmi_recfg_done),
      .error         (hdmi_recfg_error),
      .avl_address,
      .avl_write,
      .avl_writedata,
      .avl_read,
      .avl_readdata);

   //
   // Video Controller
   //

   // vctrl vsync interrupt -> HPS via fpga2hps_interrupt_irq0[0] (GIC SPI 17).
   logic                     vctrl_irq;
   assign f2h_irq0 = {31'b0, vctrl_irq};

   wire [7:0]                vga_r, vga_g, vga_b;
   wire                      vga_hs, vga_vs, vga_bl;

   vctrl_wrapper #
     (.AXI_ID_W   (5),
      .AXI_ADDR_W (32),
      .AXI_DATA_W (256))
   u_vctrl_wrapper
     (.clk_sys,
      .rst_sys,
      .clk_pix,
      .rst_pix,
      .vctrl_irq,
      //
      .pll_divcnt   (hdmi_pll_divcnt),
      .pll_apply    (hdmi_pll_apply),
      .pll_done     (hdmi_pll_done),
      .pll_locked   (hdmi_pll_locked_sys),
      .pll_error    (hdmi_pll_error),
      //
      .vga_r,  .vga_g,  .vga_b,
      .vga_hs, .vga_vs, .vga_bl,
      //
      .lwhps2fpga_awid,
      .lwhps2fpga_awaddr,
      .lwhps2fpga_awlen,
      .lwhps2fpga_awsize,
      .lwhps2fpga_awburst,
      .lwhps2fpga_awlock,
      .lwhps2fpga_awcache,
      .lwhps2fpga_awprot,
      .lwhps2fpga_awvalid,
      .lwhps2fpga_awready,
      .lwhps2fpga_wdata,
      .lwhps2fpga_wstrb,
      .lwhps2fpga_wlast,
      .lwhps2fpga_wvalid,
      .lwhps2fpga_wready,
      .lwhps2fpga_bid,
      .lwhps2fpga_bresp,
      .lwhps2fpga_bvalid,
      .lwhps2fpga_bready,
      .lwhps2fpga_arid,
      .lwhps2fpga_araddr,
      .lwhps2fpga_arlen,
      .lwhps2fpga_arsize,
      .lwhps2fpga_arburst,
      .lwhps2fpga_arlock,
      .lwhps2fpga_arcache,
      .lwhps2fpga_arprot,
      .lwhps2fpga_arvalid,
      .lwhps2fpga_arready,
      .lwhps2fpga_rid,
      .lwhps2fpga_rdata,
      .lwhps2fpga_rresp,
      .lwhps2fpga_rlast,
      .lwhps2fpga_rvalid,
      .lwhps2fpga_rready,
      //
`ifdef ENABLE_FPGA2HPS
      .m_axi_arid    (fpga2hps_arid),
      .m_axi_araddr  (fpga2hps_araddr),
      .m_axi_arlen   (fpga2hps_arlen),
      .m_axi_arsize  (fpga2hps_arsize),
      .m_axi_arburst (fpga2hps_arburst),
      .m_axi_arlock  (fpga2hps_arlock),
      .m_axi_arcache (fpga2hps_arcache),
      .m_axi_arprot  (fpga2hps_arprot),
      .m_axi_arvalid (fpga2hps_arvalid),
      .m_axi_arready (fpga2hps_arready),
      .m_axi_rid     (fpga2hps_rid),
      .m_axi_rdata   (fpga2hps_rdata),
      .m_axi_rresp   (fpga2hps_rresp),
      .m_axi_rlast   (fpga2hps_rlast),
      .m_axi_rvalid  (fpga2hps_rvalid),
      .m_axi_rready  (fpga2hps_rready),
      .m_axi_awid    (fpga2hps_awid),
      .m_axi_awaddr  (fpga2hps_awaddr),
      .m_axi_awlen   (fpga2hps_awlen),
      .m_axi_awsize  (fpga2hps_awsize),
      .m_axi_awburst (fpga2hps_awburst),
      .m_axi_awlock  (fpga2hps_awlock),
      .m_axi_awcache (fpga2hps_awcache),
      .m_axi_awprot  (fpga2hps_awprot),
      .m_axi_awvalid (fpga2hps_awvalid),
      .m_axi_awready (fpga2hps_awready),
      .m_axi_wdata   (fpga2hps_wdata),
      .m_axi_wstrb   (fpga2hps_wstrb),
      .m_axi_wlast   (fpga2hps_wlast),
      .m_axi_wvalid  (fpga2hps_wvalid),
      .m_axi_wready  (fpga2hps_wready),
      .m_axi_bid     (fpga2hps_bid),
      .m_axi_bresp   (fpga2hps_bresp),
      .m_axi_bvalid  (fpga2hps_bvalid),
      .m_axi_bready  (fpga2hps_bready)
`else // !`ifdef ENABLE_FPGA2HPS
      .m_axi_arid    (f2sdram_arid),
      .m_axi_araddr  (f2sdram_araddr),
      .m_axi_arlen   (f2sdram_arlen),
      .m_axi_arsize  (f2sdram_arsize),
      .m_axi_arburst (f2sdram_arburst),
      .m_axi_arlock  (f2sdram_arlock),
      .m_axi_arcache (f2sdram_arcache),
      .m_axi_arprot  (f2sdram_arprot),
      .m_axi_arvalid (f2sdram_arvalid),
      .m_axi_arready (f2sdram_arready),
      .m_axi_rid     (f2sdram_rid),
      .m_axi_rdata   (f2sdram_rdata),
      .m_axi_rresp   (f2sdram_rresp),
      .m_axi_rlast   (f2sdram_rlast),
      .m_axi_rvalid  (f2sdram_rvalid),
      .m_axi_rready  (f2sdram_rready),
      .m_axi_awid    (f2sdram_awid),
      .m_axi_awaddr  (f2sdram_awaddr),
      .m_axi_awlen   (f2sdram_awlen),
      .m_axi_awsize  (f2sdram_awsize),
      .m_axi_awburst (f2sdram_awburst),
      .m_axi_awlock  (f2sdram_awlock),
      .m_axi_awcache (f2sdram_awcache),
      .m_axi_awprot  (f2sdram_awprot),
      .m_axi_awvalid (f2sdram_awvalid),
      .m_axi_awready (f2sdram_awready),
      .m_axi_wdata   (f2sdram_wdata),
      .m_axi_wstrb   (f2sdram_wstrb),
      .m_axi_wlast   (f2sdram_wlast),
      .m_axi_wvalid  (f2sdram_wvalid),
      .m_axi_wready  (f2sdram_wready),
      .m_axi_bid     (f2sdram_bid),
      .m_axi_bresp   (f2sdram_bresp),
      .m_axi_bvalid  (f2sdram_bvalid),
      .m_axi_bready  (f2sdram_bready)
`endif // !`ifdef ENABLE_FPGA2HPS
      );

   wire                      hdmi_config_done_pix;
   synchronizer hdmi_config_done_sync (.clk(clk_pix), .d(hdmi_config_done), .q(hdmi_config_done_pix));

   // hdmi_output expects active-high Data Enable; the core provides Blanking
   wire                      vga_de = ~vga_bl & hdmi_config_done_pix;

   // HDMI Transmitter outputs
   hdmi_output u_hdmi_output
     (.clk_pix,
      .vga_hs,
      .vga_vs,
      .vga_de,
      .vga_r,
      .vga_g,
      .vga_b,
      .HDMI_TX_HS,
      .HDMI_TX_VS,
      .HDMI_TX_DE,
      .HDMI_TX_D,
      .HDMI_TX_CLK
      );

   // Other I/O
   assign LED[0] = ~core_pll_locked;
   assign LED[1] = ~hdmi_pll_locked;
   assign LED[2] = ~hdmi_config_done;
   assign LED[3] = 1'b1;
   assign LED[4] = 1'b1;
   assign LED[5] = 1'b1;
   assign LED[6] = 1'b1;
   assign LED[7] = 1'b1;

   // FPGA UART unused
   assign FPGA_UART_TX = 1'b1;

   // ADC unused
   assign ADC_SCK = 1'b1;
   assign ADC_SDI = 1'b1;
   assign ADC_CS_n = 1'b1;

endmodule // de25_nano_top
