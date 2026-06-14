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

   (* preserve *) wire                      h2f_reset_reset_buf;
   (* preserve *) wire                      h2f_warm_reset_handshake_reset_req_buf;

   synchronizer u_h2f_reset_reset_sync
     (.clk(buf_refclk), .d(h2f_reset_reset), .q(h2f_reset_reset_buf));
   synchronizer u_h2f_reset_req_sync
     (.clk(buf_refclk), .d(h2f_warm_reset_handshake_reset_req), .q(h2f_warm_reset_handshake_reset_req_buf));

   //
   // HPS Subsystem
   //

   // FPGA2HPS AXI Slave port
   wire [4:0]                f2h_awid;
   wire [31:0]               f2h_awaddr;
   wire [7:0]                f2h_awlen;
   wire [2:0]                f2h_awsize;
   wire [1:0]                f2h_awburst;
   wire                      f2h_awlock;
   wire [3:0]                f2h_awcache;
   wire [2:0]                f2h_awprot;
   wire [3:0]                f2h_awqos = 4'h0;
   wire                      f2h_awvalid;
   wire                      f2h_awready;
   wire [3:0]                f2h_awregion = 4'h0;
   wire [255:0]              f2h_wdata;
   wire [31:0]               f2h_wstrb;
   wire                      f2h_wlast;
   wire                      f2h_wvalid;
   wire                      f2h_wready;
   wire [7:0]                f2h_wuser = 8'h00;
   wire [4:0]                f2h_bid;
   wire [1:0]                f2h_bresp;
   wire                      f2h_bvalid;
   wire                      f2h_bready;
   wire [7:0]                f2h_buser;
   wire [4:0]                f2h_arid;
   wire [31:0]               f2h_araddr;
   wire [7:0]                f2h_arlen;
   wire [2:0]                f2h_arsize;
   wire [1:0]                f2h_arburst;
   wire                      f2h_arlock;
   wire [3:0]                f2h_arcache;
   wire [2:0]                f2h_arprot;
   wire [3:0]                f2h_arqos = 4'h1; // Latency sensitive
   wire                      f2h_arvalid;
   wire                      f2h_arready;
   wire [3:0]                f2h_arregion = 4'h0;
   wire [4:0]                f2h_rid;
   wire [255:0]              f2h_rdata;
   wire [1:0]                f2h_rresp;
   wire                      f2h_rlast;
   wire                      f2h_rvalid;
   wire                      f2h_rready;
   wire [7:0]                f2h_ruser;

   // FPGA2HPS Interrupts
   wire [31:0]               f2h_irq0;

   // LWHPS2FPGA AXI4 Master port (HPS -> FPGA, lightweight)
   wire [3:0]                lwh2f_awid;
   wire [28:0]               lwh2f_awaddr;
   wire [7:0]                lwh2f_awlen;
   wire [2:0]                lwh2f_awsize;
   wire [1:0]                lwh2f_awburst;
   wire                      lwh2f_awlock;
   wire [3:0]                lwh2f_awcache;
   wire [2:0]                lwh2f_awprot;
   wire                      lwh2f_awvalid;
   wire                      lwh2f_awready;
   wire [31:0]               lwh2f_wdata;
   wire [3:0]                lwh2f_wstrb;
   wire                      lwh2f_wlast;
   wire                      lwh2f_wvalid;
   wire                      lwh2f_wready;
   wire [3:0]                lwh2f_bid;
   wire [1:0]                lwh2f_bresp;
   wire                      lwh2f_bvalid;
   wire                      lwh2f_bready;
   wire [3:0]                lwh2f_arid;
   wire [28:0]               lwh2f_araddr;
   wire [7:0]                lwh2f_arlen;
   wire [2:0]                lwh2f_arsize;
   wire [1:0]                lwh2f_arburst;
   wire                      lwh2f_arlock;
   wire [3:0]                lwh2f_arcache;
   wire [2:0]                lwh2f_arprot;
   wire                      lwh2f_arvalid;
   wire                      lwh2f_arready;
   wire [3:0]                lwh2f_rid;
   wire [31:0]               lwh2f_rdata;
   wire [1:0]                lwh2f_rresp;
   wire                      lwh2f_rlast;
   wire                      lwh2f_rvalid;
   wire                      lwh2f_rready;

   hps_wrapper u_hps_wrapper
     (.clk_sys,
      .rst_sys,
      .h2f_reset_reset,
      .h2f_warm_reset_handshake_reset_req,
      .h2f_warm_reset_handshake_reset_ack,
      //
      .f2h_awid,
      .f2h_awaddr,
      .f2h_awlen,
      .f2h_awsize,
      .f2h_awburst,
      .f2h_awlock,
      .f2h_awcache,
      .f2h_awprot,
      .f2h_awqos,
      .f2h_awvalid,
      .f2h_awready,
      .f2h_awregion,
      .f2h_wdata,
      .f2h_wstrb,
      .f2h_wlast,
      .f2h_wvalid,
      .f2h_wready,
      .f2h_wuser,
      .f2h_bid,
      .f2h_bresp,
      .f2h_bvalid,
      .f2h_bready,
      .f2h_buser,
      .f2h_arid,
      .f2h_araddr,
      .f2h_arlen,
      .f2h_arsize,
      .f2h_arburst,
      .f2h_arlock,
      .f2h_arcache,
      .f2h_arprot,
      .f2h_arqos,
      .f2h_arvalid,
      .f2h_arready,
      .f2h_arregion,
      .f2h_rid,
      .f2h_rdata,
      .f2h_rresp,
      .f2h_rlast,
      .f2h_rvalid,
      .f2h_rready,
      .f2h_ruser,
      //
      .lwh2f_awid,
      .lwh2f_awaddr,
      .lwh2f_awlen,
      .lwh2f_awsize,
      .lwh2f_awburst,
      .lwh2f_awlock,
      .lwh2f_awcache,
      .lwh2f_awprot,
      .lwh2f_awvalid,
      .lwh2f_awready,
      .lwh2f_wdata,
      .lwh2f_wstrb,
      .lwh2f_wlast,
      .lwh2f_wvalid,
      .lwh2f_wready,
      .lwh2f_bid,
      .lwh2f_bresp,
      .lwh2f_bvalid,
      .lwh2f_bready,
      .lwh2f_arid,
      .lwh2f_araddr,
      .lwh2f_arlen,
      .lwh2f_arsize,
      .lwh2f_arburst,
      .lwh2f_arlock,
      .lwh2f_arcache,
      .lwh2f_arprot,
      .lwh2f_arvalid,
      .lwh2f_arready,
      .lwh2f_rid,
      .lwh2f_rdata,
      .lwh2f_rresp,
      .lwh2f_rlast,
      .lwh2f_rvalid,
      .lwh2f_rready,
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

   //
   // Control-plane bridge: lwh2f AXI4 -> video controller cfg bus
   //

   wire                      cfg_req, cmd_req;
   wire [11:2]               cfg_adr, cmd_adr;
   wire                      cfg_we, cmd_we;
   wire [ 3:0]               cfg_be, cmd_be;
   wire [31:0]               cfg_d, cmd_d;
   wire [31:0]               cfg_q, cmd_q;
   wire                      cfg_ack, cmd_ack;

   lw_ctrl_bridge u_lw_ctrl_bridge
     (.clk            (clk_sys),
      .rst            (rst_sys),
      .s_axi_awid     (lwh2f_awid),
      .s_axi_awaddr   (lwh2f_awaddr),
      .s_axi_awlen    (lwh2f_awlen),
      .s_axi_awsize   (lwh2f_awsize),
      .s_axi_awburst  (lwh2f_awburst),
      .s_axi_awlock   (lwh2f_awlock),
      .s_axi_awcache  (lwh2f_awcache),
      .s_axi_awprot   (lwh2f_awprot),
      .s_axi_awvalid  (lwh2f_awvalid),
      .s_axi_awready  (lwh2f_awready),
      .s_axi_wdata    (lwh2f_wdata),
      .s_axi_wstrb    (lwh2f_wstrb),
      .s_axi_wlast    (lwh2f_wlast),
      .s_axi_wvalid   (lwh2f_wvalid),
      .s_axi_wready   (lwh2f_wready),
      .s_axi_bid      (lwh2f_bid),
      .s_axi_bresp    (lwh2f_bresp),
      .s_axi_bvalid   (lwh2f_bvalid),
      .s_axi_bready   (lwh2f_bready),
      .s_axi_arid     (lwh2f_arid),
      .s_axi_araddr   (lwh2f_araddr),
      .s_axi_arlen    (lwh2f_arlen),
      .s_axi_arsize   (lwh2f_arsize),
      .s_axi_arburst  (lwh2f_arburst),
      .s_axi_arlock   (lwh2f_arlock),
      .s_axi_arcache  (lwh2f_arcache),
      .s_axi_arprot   (lwh2f_arprot),
      .s_axi_arvalid  (lwh2f_arvalid),
      .s_axi_arready  (lwh2f_arready),
      .s_axi_rid      (lwh2f_rid),
      .s_axi_rdata    (lwh2f_rdata),
      .s_axi_rresp    (lwh2f_rresp),
      .s_axi_rlast    (lwh2f_rlast),
      .s_axi_rvalid   (lwh2f_rvalid),
      .s_axi_rready   (lwh2f_rready),
      // video controller config bus
      .cfg_req,
      .cfg_adr,
      .cfg_we,
      .cfg_be,
      .cfg_d,
      .cfg_q,
      .cfg_ack,
      // dma command bus
      .cmd_req,
      .cmd_adr,
      .cmd_we,
      .cmd_be,
      .cmd_d,
      .cmd_q,
      .cmd_ack
      );

   // XXX: Tie-off DMA Command bus
   logic                     cmd_ack_r;
   always_ff @(posedge clk_sys) begin
      cmd_ack_r <= cmd_req;
   end
   assign cmd_ack = cmd_ack_r;
   assign cmd_q = '0;

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
   wire                      hdmi_pll_locked_sys;   // synced PLL locked (clk_sys)
   wire                      hdmi_pll_error_sys;    // synced recal error (clk_sys)

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
   synchronizer u_pll_locked_sync (.clk (clk_sys), .d (hdmi_pll_locked),  .q (hdmi_pll_locked_sys));
   synchronizer u_pll_error_sync  (.clk (clk_sys), .d (hdmi_recfg_error), .q (hdmi_pll_error_sys));

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

   wire                      hdmi_config_done_pix;
   synchronizer hdmi_config_done_sync (.clk(clk_pix), .d(hdmi_config_done), .q(hdmi_config_done_pix));

   //
   // Video Controller
   //
   // Full framebuffer scanout core. It is programmed over the cfg_* register
   // bus (timing, pitch, color depth, palette, enable) and fetches pixel data
   // through the fb_* memory read port.

   localparam int            VR_SIZE  = 1920 * 1080 * 4; // worst case: 1080p @ 32 bpp
   localparam int            VR_DATAW = 32;              // FB data width (cproc only supports 32)
   localparam int            LB_DEPTH = 2048;            // line buffer depth = max horizontal res
   localparam int            VR_ADDRW = $clog2(VR_SIZE);

   wire [7:0]                vga_r, vga_g, vga_b;
   wire                      vga_hs, vga_vs, vga_bl;
   // hdmi_output expects active-high Data Enable; the core provides Blanking
   wire                      vga_de = ~vga_bl & hdmi_config_done_pix;

   wire                      frame_sys;      // start-of-frame strobe (to scanout master)
   wire [31:2]               vctrl_vbar;     // video base address (from VBAR reg)

   // Frame buffer read port - driven by the scanout AXI master (u_vctrl_axim)
   wire                      fb_rdreq;
   wire [VR_ADDRW-1:0]       fb_raddr;
   wire                      fb_rdack;
   wire [VR_DATAW-1:0]       fb_rdata;
   wire                      fb_rvalid;

   // vctrl vsync interrupt -> HPS via fpga2hps_interrupt_irq0[0] (GIC SPI 17).
   wire                      vctrl_irq;
   assign f2h_irq0 = {31'b0, vctrl_irq};

   vctrl_core #
     (.VR_SIZE  (VR_SIZE),
      .VR_DATAW (VR_DATAW),
      .LB_DEPTH (LB_DEPTH))
   u_vctrl_core
     (.clk_sys,
      .rst_sys,
      .cfg_req,
      .cfg_adr,
      .cfg_we,
      .cfg_be,
      .cfg_d,
      .cfg_q,
      .cfg_ack,
      .irq        (vctrl_irq),
      .frame_sys,
      .vbar       (vctrl_vbar),
      .fb_rdreq,
      .fb_raddr,
      .fb_rdack,
      .fb_rdata,
      .fb_rvalid,
      .clk_pix,
      .rst_pix,
      .pll_divcnt (hdmi_pll_divcnt),
      .pll_apply  (hdmi_pll_apply),
      .pll_done   (hdmi_pll_done),
      .pll_locked (hdmi_pll_locked_sys),
      .pll_error  (hdmi_pll_error_sys),
      .vga_r,
      .vga_g,
      .vga_b,
      .vga_bl,
      .vga_hs,
      .vga_vs
      );

   //
   // Scanout AXI read master (native 256-bit, internal line buffer)
   //

   wire [31:0]               fb_base = {vctrl_vbar, 2'b00};

   vctrl_axim #
     (.ADDR_WIDTH     (32),
      .AXI_DATA_WIDTH (256),
      .FB_DATA_WIDTH  (VR_DATAW),
      .FB_ADDR_WIDTH  (VR_ADDRW),
      .ID_WIDTH       (5),
      .BURST_LEN      (8),
      .FIFO_LGDEPTH   (6))
   u_vctrl_axim
     (.clk           (clk_sys),
      .rst           (rst_sys),
      .frame_sys,
      .fb_base,
      .fb_rdreq,
      .fb_raddr,
      .fb_rdack,
      .fb_rdata,
      .fb_rvalid,
      .m_axi_arid    (f2h_arid),
      .m_axi_araddr  (f2h_araddr),
      .m_axi_arlen   (f2h_arlen),
      .m_axi_arsize  (f2h_arsize),
      .m_axi_arburst (f2h_arburst),
      .m_axi_arlock  (f2h_arlock),
      .m_axi_arcache (f2h_arcache),
      .m_axi_arprot  (f2h_arprot),
      .m_axi_arvalid (f2h_arvalid),
      .m_axi_arready (f2h_arready),
      .m_axi_rid     (f2h_rid),
      .m_axi_rdata   (f2h_rdata),
      .m_axi_rresp   (f2h_rresp),
      .m_axi_rlast   (f2h_rlast),
      .m_axi_rvalid  (f2h_rvalid),
      .m_axi_rready  (f2h_rready),
      .m_axi_awid    (f2h_awid),
      .m_axi_awaddr  (f2h_awaddr),
      .m_axi_awlen   (f2h_awlen),
      .m_axi_awsize  (f2h_awsize),
      .m_axi_awburst (f2h_awburst),
      .m_axi_awlock  (f2h_awlock),
      .m_axi_awcache (f2h_awcache),
      .m_axi_awprot  (f2h_awprot),
      .m_axi_awvalid (f2h_awvalid),
      .m_axi_awready (f2h_awready),
      .m_axi_wdata   (f2h_wdata),
      .m_axi_wstrb   (f2h_wstrb),
      .m_axi_wlast   (f2h_wlast),
      .m_axi_wvalid  (f2h_wvalid),
      .m_axi_wready  (f2h_wready),
      .m_axi_bid     (f2h_bid),
      .m_axi_bresp   (f2h_bresp),
      .m_axi_bvalid  (f2h_bvalid),
      .m_axi_bready  (f2h_bready)
      );

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
