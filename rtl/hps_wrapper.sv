// -*- mode: verilog; mode: font-lock; indent-tabs-mode: nil -*-
// vi: set et ts=3 sw=3 sts=3:
//
// Copyright 2026 Steffen Persvold
// SPDX-License-Identifier: Apache-2.0
//
// ========================================================================
// File        : hps_wrapper.sv
// Author      : Steffen Persvold
// Created     : April 15, 2026
// ========================================================================
// Description : Agilex 5 HPS subsystem
// ========================================================================
//

module hps_wrapper
  (
    input  wire         clk_sys
   ,input  wire         rst_sys
   // Active high reset from the HPS Reset Manager.
   ,output wire         h2f_reset_reset
   // HPS warm reset request. Identical to watchdog reset except this is asserted by SDM.
   ,output wire         h2f_warm_reset_handshake_reset_req
   // HPS warm reset acknowledge response to SDM. Should be asserted when all HPS soft logic is successfully in reset.
   ,input  wire         h2f_warm_reset_handshake_reset_ack
   // FPGA2HPS AXI Slave port (FPGA -> HPS; 256-bit data, 32-bit addr)
   // AW channel
   ,input  wire [4:0]   f2h_awid
   ,input  wire [31:0]  f2h_awaddr
   ,input  wire [7:0]   f2h_awlen
   ,input  wire [2:0]   f2h_awsize
   ,input  wire [1:0]   f2h_awburst
   ,input  wire         f2h_awlock
   ,input  wire [3:0]   f2h_awcache
   ,input  wire [2:0]   f2h_awprot
   ,input  wire [3:0]   f2h_awqos
   ,input  wire         f2h_awvalid
   ,output wire         f2h_awready
   ,input  wire [3:0]   f2h_awregion
   // W channel
   ,input  wire [255:0] f2h_wdata
   ,input  wire [31:0]  f2h_wstrb
   ,input  wire         f2h_wlast
   ,input  wire         f2h_wvalid
   ,output wire         f2h_wready
   ,input  wire [7:0]   f2h_wuser
   // B channel
   ,output wire [4:0]   f2h_bid
   ,output wire [1:0]   f2h_bresp
   ,output wire         f2h_bvalid
   ,input  wire         f2h_bready
   ,output wire [7:0]   f2h_buser
   // AR channel
   ,input  wire [4:0]   f2h_arid
   ,input  wire [31:0]  f2h_araddr
   ,input  wire [7:0]   f2h_arlen
   ,input  wire [2:0]   f2h_arsize
   ,input  wire [1:0]   f2h_arburst
   ,input  wire         f2h_arlock
   ,input  wire [3:0]   f2h_arcache
   ,input  wire [2:0]   f2h_arprot
   ,input  wire [3:0]   f2h_arqos
   ,input  wire         f2h_arvalid
   ,output wire         f2h_arready
   ,input  wire [3:0]   f2h_arregion
   // R channel
   ,output wire [4:0]   f2h_rid
   ,output wire [255:0] f2h_rdata
   ,output wire [1:0]   f2h_rresp
   ,output wire         f2h_rlast
   ,output wire         f2h_rvalid
   ,input  wire         f2h_rready
   ,output wire [7:0]   f2h_ruser
   // LWHPS2FPGA AXI4 Master port (HPS -> FPGA, lightweight; 32-bit data, 29-bit addr)
   // AW channel
   ,output wire [3:0]   lwh2f_awid
   ,output wire [28:0]  lwh2f_awaddr
   ,output wire [7:0]   lwh2f_awlen
   ,output wire [2:0]   lwh2f_awsize
   ,output wire [1:0]   lwh2f_awburst
   ,output wire         lwh2f_awlock
   ,output wire [3:0]   lwh2f_awcache
   ,output wire [2:0]   lwh2f_awprot
   ,output wire         lwh2f_awvalid
   ,input  wire         lwh2f_awready
   // W channel
   ,output wire [31:0]  lwh2f_wdata
   ,output wire [3:0]   lwh2f_wstrb
   ,output wire         lwh2f_wlast
   ,output wire         lwh2f_wvalid
   ,input  wire         lwh2f_wready
   // B channel
   ,input  wire [3:0]   lwh2f_bid
   ,input  wire [1:0]   lwh2f_bresp
   ,input  wire         lwh2f_bvalid
   ,output wire         lwh2f_bready
   // AR channel
   ,output wire [3:0]   lwh2f_arid
   ,output wire [28:0]  lwh2f_araddr
   ,output wire [7:0]   lwh2f_arlen
   ,output wire [2:0]   lwh2f_arsize
   ,output wire [1:0]   lwh2f_arburst
   ,output wire         lwh2f_arlock
   ,output wire [3:0]   lwh2f_arcache
   ,output wire [2:0]   lwh2f_arprot
   ,output wire         lwh2f_arvalid
   ,input  wire         lwh2f_arready
   // R channel
   ,input  wire [3:0]   lwh2f_rid
   ,input  wire [31:0]  lwh2f_rdata
   ,input  wire [1:0]   lwh2f_rresp
   ,input  wire         lwh2f_rlast
   ,input  wire         lwh2f_rvalid
   ,output wire         lwh2f_rready
   // HPS Peripheral I/O
   ,input  wire         hps_io_hps_osc_clk
   ,output wire         hps_io_mdio0_mdc
   ,inout  wire         hps_io_mdio0_mdio
   ,input  wire         hps_io_emac0_rx_clk
   ,input  wire         hps_io_emac0_rx_ctl
   ,input  wire         hps_io_emac0_rxd0
   ,input  wire         hps_io_emac0_rxd1
   ,input  wire         hps_io_emac0_rxd2
   ,input  wire         hps_io_emac0_rxd3
   ,output wire         hps_io_emac0_tx_clk
   ,output wire         hps_io_emac0_tx_ctl
   ,output wire         hps_io_emac0_txd0
   ,output wire         hps_io_emac0_txd1
   ,output wire         hps_io_emac0_txd2
   ,output wire         hps_io_emac0_txd3
   ,output wire         hps_io_sdmmc_cclk
   ,inout  wire         hps_io_sdmmc_cmd
   ,inout  wire         hps_io_sdmmc_data0
   ,inout  wire         hps_io_sdmmc_data1
   ,inout  wire         hps_io_sdmmc_data2
   ,inout  wire         hps_io_sdmmc_data3
   ,input  wire         hps_io_usb0_clk
   ,inout  wire         hps_io_usb0_data0
   ,inout  wire         hps_io_usb0_data1
   ,inout  wire         hps_io_usb0_data2
   ,inout  wire         hps_io_usb0_data3
   ,inout  wire         hps_io_usb0_data4
   ,inout  wire         hps_io_usb0_data5
   ,inout  wire         hps_io_usb0_data6
   ,inout  wire         hps_io_usb0_data7
   ,input  wire         hps_io_usb0_dir
   ,input  wire         hps_io_usb0_nxt
   ,output wire         hps_io_usb0_stp
   ,output wire         hps_io_uart1_tx
   ,input  wire         hps_io_uart1_rx
   ,inout  wire         hps_io_i2c1_sda
   ,inout  wire         hps_io_i2c1_scl
   ,inout  wire         hps_io_gpio28
   ,inout  wire         hps_io_gpio34
   ,inout  wire         hps_io_gpio40
   ,inout  wire         hps_io_gpio41
   // LPDDR4 I/O
   ,output wire [0:0]   mem_0_cs
   ,output wire [5:0]   mem_0_ca
   ,output wire [0:0]   mem_0_cke
   ,inout  wire [31:0]  mem_0_dq
   ,inout  wire [3:0]   mem_0_dqs_t
   ,inout  wire [3:0]   mem_0_dqs_c
   ,inout  wire [3:0]   mem_0_dmi
   ,output wire [0:0]   mem_0_ck_t
   ,output wire [0:0]   mem_0_ck_c
   ,output wire         mem_0_reset_n
   ,input  wire         oct_rzqin_0
   ,input  wire         ref_clk
   // FPGA-to-HPS interrupt requests, lower 32 bits (irq0[x] -> GIC SPI 17+x).
   ,input  wire [31:0]  f2h_irq0
   );

   // =========================================================================================
   // HPS misc signals
   // =========================================================================================

   wire [31:0]          fpga2hps_interrupt_irq0_irq = f2h_irq0;   //  fpga2hps_interrupt_irq0.irq,              FPGA-to-HPS interrupts (lower 32 bits).
   wire [31:0]          fpga2hps_interrupt_irq1_irq = '0;   //  fpga2hps_interrupt_irq1.irq,              FPGA-to-HPS interrupts (higher 32 bits).

   // =========================================================================================
   // FPGA2HPS Bridge (ACE5Lite)
   // =========================================================================================
   // AW channel
   wire [4:0]           fpga2hps_awid;                      //                 fpga2hps.awid,             Identification tag for a write transaction.
   wire [31:0]          fpga2hps_awaddr;                    //                         .awaddr,           The address of the first transfer in a write transaction.
   wire [1:0]           fpga2hps_awdomain;                  //                         .awdomain,         Indicates the shareability domain of a write transaction.
   wire [3:0]           fpga2hps_awsnoop;                   //                         .awsnoop,          Indicates transaction type for a shareable write transaction.
   wire [7:0]           fpga2hps_awlen;                     //                         .awlen,            Exact number of data ransfers in a write transaction.
   wire [2:0]           fpga2hps_awsize;                    //                         .awsize,           The number of bytes in each data transfer of a write transaction.
   wire [2:0]           fpga2hps_arsize;                    //                         .arsize,           The number of bytes in each data transfer of a read transaction.
   wire [1:0]           fpga2hps_awburst;                   //                         .awburst,          Burst type indicating how address changes between each transfer of a write transaction.
   wire                 fpga2hps_awlock;                    //                         .awlock,           Provides info on atomic characteristics of a write transaction.
   wire [3:0]           fpga2hps_awcache;                   //                         .awcache,          Indicates how a write transaction is required to progress through a system.
   wire [2:0]           fpga2hps_awprot;                    //                         .awprot,           Protection attributes of a write transaction: privelege, security level, and access type.
   wire [3:0]           fpga2hps_awqos;                     //                         .awqos,            Quality of service identifier for a write transaction.
   wire [3:0]           fpga2hps_awregion;                  //                         .awregion,         Region indicator for a write transaction.
   wire [10:0]          fpga2hps_awstashnid;                //                         .awstashnid,       Node identifier of the target for a stash operation.
   wire                 fpga2hps_awstashniden;              //                         .awstashniden,     Indicates whether the AWSTASHNID signal is valid.
   wire [4:0]           fpga2hps_awstashlpid;               //                         .awstashlpid,      Logical processor identifier within the target for a stash operation.
   wire                 fpga2hps_awstashlpiden;             //                         .awstashlpiden,    Indicates whether the AWSTASHLPID signal is valid.
   wire [5:0]           fpga2hps_awatop;                    //                         .awatop,           Indicates the type and endianness of atomic transactions.
   wire [7:0]           fpga2hps_awuser;                    //                         .awuser,           Extension of the write address channel.
   wire                 fpga2hps_awvalid;                   //                         .awvalid,          Indicates the write address channel signals are valid.
   wire                 fpga2hps_awready;                   //                         .awready,          Indicates a transfer on the write address channel can be accepted.
   // W channel
   wire [255:0]         fpga2hps_wdata;                     //                         .wdata,            Write data.
   wire [31:0]          fpga2hps_wstrb;                     //                         .wstrb,            Write strobes indicating which byte lanes hold valid data.
   wire                 fpga2hps_wlast;                     //                         .wlast,            Indicates the last data transfer in a write transaction.
   wire [7:0]           fpga2hps_wuser;                     //                         .wuser,            Extension of the write data channel.
   wire                 fpga2hps_wvalid;                    //                         .wvalid,           Indicates the write data channel signals are valid.
   wire                 fpga2hps_wready;                    //                         .wready,           Indicates a transfer on the write data channel can be accepted.
   // B channel
   wire [4:0]           fpga2hps_bid;                       //                         .bid,              Identification tag for a write response.
   wire [1:0]           fpga2hps_bresp;                     //                         .bresp,            Write response indicating status of a write transaction.
   wire [7:0]           fpga2hps_buser;                     //                         .buser,            Extension of the write response channel.
   wire                 fpga2hps_bvalid;                    //                         .bvalid,           Indicates the write response channel signals are valid.
   wire                 fpga2hps_bready;                    //                         .bready,           Indicates a transfer on the write response channel can be accepted.
   // AR channel
   wire [4:0]           fpga2hps_arid;                      //                         .arid,             Identification tag for a read transaction.
   wire [31:0]          fpga2hps_araddr;                    //                         .araddr,           The address of the first transfer of a read transaction.
   wire [1:0]           fpga2hps_ardomain;                  //                         .ardomain,         Indicates the shareability domain of a read transaction.
   wire [3:0]           fpga2hps_arsnoop;                   //                         .arsnoop,          Indicates the transaction type for shareable read transactions.
   wire [7:0]           fpga2hps_arlen;                     //                         .arlen,            The exact number of data transfers in a read transaction.
   wire [1:0]           fpga2hps_arburst;                   //                         .arburst,          Burst type indicating how address changes between each transfer in a read transaction.
   wire                 fpga2hps_arlock;                    //                         .arlock,           Provides info on atomic characteristics of a read transaction.
   wire [3:0]           fpga2hps_arcache;                   //                         .arcache,          Indicates how a read transaction is required to progress through a system.
   wire [2:0]           fpga2hps_arprot;                    //                         .arprot,           Protection attributes of a read transaction: privelege, security level, and access type.
   wire [3:0]           fpga2hps_arqos;                     //                         .arqos,            Quality of service identifier for a read transaction.
   wire [3:0]           fpga2hps_arregion;                  //                         .arregion,         Region indicator for a read transaction.
   wire [7:0]           fpga2hps_aruser;                    //                         .aruser,           Extension of the read address channel.
   wire                 fpga2hps_arvalid;                   //                         .arvalid,          Indicates the read address channels signals are valid.
   wire                 fpga2hps_arready;                   //                         .arready,          Indicates a transfer on the read address channel can be accepted.
   // R channel
   wire [4:0]           fpga2hps_rid;                       //                         .rid,              Identification tag for read data and response.
   wire [255:0]         fpga2hps_rdata;                     //                         .rdata,            Read data.
   wire [1:0]           fpga2hps_rresp;                     //                         .rresp,            Indicates the status of a read transfer.
   wire                 fpga2hps_rlast;                     //                         .rlast,            Indicates the last data transfer in a read transaction.
   wire [7:0]           fpga2hps_ruser;                     //                         .ruser,            Extension of the read data channel.
   wire                 fpga2hps_rvalid;                    //                         .rvalid,           Indicates the read data channel signals are valid.
   wire                 fpga2hps_rready;                    //                         .rready,           Indicates a transfer on the read data channel can be accepted.

   // =========================================================================================
   // HPS2EMIF CSR Bridge (AXI4Lite)
   // =========================================================================================
   wire                 io96b0_to_hps_ch0_axil_clk;         //            io96b0_to_hps.ch0_axil_clk,     Clock source signal. Synchronous signals are sampled on the rising edge of this clock.
   wire                 io96b0_to_hps_ch0_axil_reset_n;     //                         .ch0_axil_reset_n, Required placeholder reset. The actual bridge reset is driven by HPS Reset Manager.
   // AW channel
   wire [26:0]          io96b0_to_hps_ch0_axil_awaddr;      //                         .ch0_axil_awaddr,  The address of the first transfer in a write transaction.
   wire [2:0]           io96b0_to_hps_ch0_axil_awprot;      //                         .ch0_axil_awprot,  Placegolder AWPROT. Protection attributes not supported for this bridge.
   wire                 io96b0_to_hps_ch0_axil_awvalid;     //                         .ch0_axil_awvalid, Indicates write address channel signals are valid.
   wire                 io96b0_to_hps_ch0_axil_awready;     //                         .ch0_axil_awready, Indicates a transfer on the write address channel can be accepted.
   // W channel
   wire [31:0]          io96b0_to_hps_ch0_axil_wdata;       //                         .ch0_axil_wdata,   Write data.
   wire [3:0]           io96b0_to_hps_ch0_axil_wstrb;       //                         .ch0_axil_wstrb,   Write strobes indicating which bye lanes hold valid data.
   wire                 io96b0_to_hps_ch0_axil_wvalid;      //                         .ch0_axil_wvalid,  Indicates write data channel signals are valid.
   wire                 io96b0_to_hps_ch0_axil_wready;      //                         .ch0_axil_wready,  Indicates a transfer on the write data channel can be accepted.
   // B channel
   wire [1:0]           io96b0_to_hps_ch0_axil_bresp;       //                         .ch0_axil_bresp,   Indicates status of write transaction.
   wire                 io96b0_to_hps_ch0_axil_bvalid;      //                         .ch0_axil_bvalid,  Indicates write response channel signals are valid.
   wire                 io96b0_to_hps_ch0_axil_bready;      //                         .ch0_axil_bready,  Indicates a transfer on the write response channel can be accepted.
   // AR channel
   wire [26:0]          io96b0_to_hps_ch0_axil_araddr;      //                         .ch0_axil_araddr,  The address of the first transfer in a read transaction.
   wire [2:0]           io96b0_to_hps_ch0_axil_arprot;      //                         .ch0_axil_arprot,  Placeholder ARPROT. Protection attributes not supported for this bridge.
   wire                 io96b0_to_hps_ch0_axil_arvalid;     //                         .ch0_axil_arvalid, Indicates read address channel signals are valid.
   wire                 io96b0_to_hps_ch0_axil_arready;     //                         .ch0_axil_arready, Indicates a transfer on the read address channel can be accepted.
   // R channel
   wire [31:0]          io96b0_to_hps_ch0_axil_rdata;       //                         .ch0_axil_rdata,   Read data.
   wire [1:0]           io96b0_to_hps_ch0_axil_rresp;       //                         .ch0_axil_rresp,   Indicates status of read transaction.
   wire                 io96b0_to_hps_ch0_axil_rvalid;      //                         .ch0_axil_rvalid,  Indicates read data channel signals are valid.
   wire                 io96b0_to_hps_ch0_axil_rready;      //                         .ch0_axil_rready,  Indicates a transfer on the read data channel can be accepted.

   // =========================================================================================
   // HPS2EMIF Bridge (AXI4)
   // =========================================================================================
   wire                 io96b0_to_hps_axi4_ch0_clk;         //                         .axi4_ch0_clk,     Clock source signal. Synchronous signals are sampled on the rising edge of this clock.
   wire                 io96b0_to_hps_axi4_ch0_reset_n;     //                         .axi4_ch0_reset_n, Required placeholder reset. The actual bridge reset is driven by HPS Reset Manager.
   // AW channel
   wire [6:0]           io96b0_to_hps_axi4_ch0_awid;        //                         .axi4_ch0_awid,    Identification tag for a write transaction.
   wire [39:0]          io96b0_to_hps_axi4_ch0_awaddr;      //                         .axi4_ch0_awaddr,  The address of the first transfer in a write transaction.
   wire [2:0]           io96b0_to_hps_axi4_ch0_awprot;      //                         .axi4_ch0_awprot,  Placeholder AWPROT. Protection attributes not supported for this bridge.
   wire [1:0]           io96b0_to_hps_axi4_ch0_awburst;     //                         .axi4_ch0_awburst, Burst type indicating how address changes between each transfer in a write transaction.
   wire [7:0]           io96b0_to_hps_axi4_ch0_awlen;       //                         .axi4_ch0_awlen,   Exact number of data transfers in a write transaction.
   wire                 io96b0_to_hps_axi4_ch0_awlock;      //                         .axi4_ch0_awlock,  Provides info on atomic characteristics of a write transaction.
   wire [3:0]           io96b0_to_hps_axi4_ch0_awqos;       //                         .axi4_ch0_awqos,   Quality of service identifier for a write transaction.
   wire [2:0]           io96b0_to_hps_axi4_ch0_awsize;      //                         .axi4_ch0_awsize,  Number of bytes in each data transfer in a write transaction.
   wire [13:0]          io96b0_to_hps_axi4_ch0_awuser;      //                         .axi4_ch0_awuser,  Extension of write address channel.
   wire                 io96b0_to_hps_axi4_ch0_awvalid;     //                         .axi4_ch0_awvalid, Indicates write address channel signals are valid.
   wire                 io96b0_to_hps_axi4_ch0_awready;     //                         .axi4_ch0_awready, Indicates a transfer on the write address channel can be accepted.
   // W channel
   wire [255:0]         io96b0_to_hps_axi4_ch0_wdata;       //                         .axi4_ch0_wdata,   Write data.
   wire                 io96b0_to_hps_axi4_ch0_wlast;       //                         .axi4_ch0_wlast,   Indicates the last data transfer in a write transaction.
   wire [31:0]          io96b0_to_hps_axi4_ch0_wstrb;       //                         .axi4_ch0_wstrb,   Write strobes indicating which byte lanes hold valid data.
   wire [31:0]          io96b0_to_hps_axi4_ch0_wuser;       //                         .axi4_ch0_wuser,   Extension of the write data channel.
   wire                 io96b0_to_hps_axi4_ch0_wvalid;      //                         .axi4_ch0_wvalid,  Indicates write data channel signals are valid.
   wire                 io96b0_to_hps_axi4_ch0_wready;      //                         .axi4_ch0_wready,  Indicates a transfer on the write data channel can be accepted.
   // B channel
   wire [6:0]           io96b0_to_hps_axi4_ch0_bid;         //                         .axi4_ch0_bid,     Identification tag for a write response.
   wire [1:0]           io96b0_to_hps_axi4_ch0_bresp;       //                         .axi4_ch0_bresp,   Indicates the status of a write transaction.
   wire                 io96b0_to_hps_axi4_ch0_bvalid;      //                         .axi4_ch0_bvalid,  Indicates write response channel signals are valid.
   wire                 io96b0_to_hps_axi4_ch0_bready;      //                         .axi4_ch0_bready,  Indicates a transfer on write response channel can be accepted.
   // AR channel
   wire [6:0]           io96b0_to_hps_axi4_ch0_arid;        //                         .axi4_ch0_arid,    Identification tag for a read transaction.
   wire [39:0]          io96b0_to_hps_axi4_ch0_araddr;      //                         .axi4_ch0_araddr,  The address of the first transfer in a read transaction.
   wire [2:0]           io96b0_to_hps_axi4_ch0_arprot;      //                         .axi4_ch0_arprot,  Placeholder ARPROT. Protection attributes not supported for this bridge.
   wire [1:0]           io96b0_to_hps_axi4_ch0_arburst;     //                         .axi4_ch0_arburst, Burst type indicating how address changes between each transfer in a read transaction.
   wire [7:0]           io96b0_to_hps_axi4_ch0_arlen;       //                         .axi4_ch0_arlen,   Exact number of data transfers in a read transaction.
   wire                 io96b0_to_hps_axi4_ch0_arlock;      //                         .axi4_ch0_arlock,  Provides info on atomic characteristics of a read transaction.
   wire [3:0]           io96b0_to_hps_axi4_ch0_arqos;       //                         .axi4_ch0_arqos,   Quality of service identifier for a read transaction.
   wire [2:0]           io96b0_to_hps_axi4_ch0_arsize;      //                         .axi4_ch0_arsize,  The number of bytes in each data transfer in a read transaction.
   wire [13:0]          io96b0_to_hps_axi4_ch0_aruser;      //                         .axi4_ch0_aruser,  Extension of read address channel.
   wire                 io96b0_to_hps_axi4_ch0_arvalid;     //                         .axi4_ch0_arvalid, Indicates read address channel signals are valid.
   wire                 io96b0_to_hps_axi4_ch0_arready;     //                         .axi4_ch0_arready, Indicates a transfer on the read address channel can be accepted.
   // R channel
   wire [6:0]           io96b0_to_hps_axi4_ch0_rid;         //                         .axi4_ch0_rid,     Identification tag for read data and response.
   wire [255:0]         io96b0_to_hps_axi4_ch0_rdata;       //                         .axi4_ch0_rdata,   Read data.
   wire [1:0]           io96b0_to_hps_axi4_ch0_rresp;       //                         .axi4_ch0_rresp,   Indicates the status of a read transfer.
   wire                 io96b0_to_hps_axi4_ch0_rlast;       //                         .axi4_ch0_rlast,   Indicates the last data transfer in a read transaction.
   wire [31:0]          io96b0_to_hps_axi4_ch0_ruser;       //                         .axi4_ch0_ruser,   Extension of read data channel.
   wire                 io96b0_to_hps_axi4_ch0_rvalid;      //                         .axi4_ch0_rvalid,  Indicates read data channel signals are valid.
   wire                 io96b0_to_hps_axi4_ch0_rready;      //                         .axi4_ch0_rready,  Indicates a transfer on read data channel can be accepted.

   //

   // Hard Processor System (HPS)
   agilex_hps u_agilex_hps
     (.h2f_reset_reset,
      .h2f_warm_reset_handshake_reset_req,
      .h2f_warm_reset_handshake_reset_ack,
      .fpga2hps_interrupt_irq0_irq,
      .fpga2hps_interrupt_irq1_irq,
      //
      .emac0_app_rst_reset_n      (),
      // LightWeight HPS2FPGA Bridge
      .lwhps2fpga_axi_clock_clk   (clk_sys),
      .lwhps2fpga_axi_reset_reset (rst_sys),
      .lwhps2fpga_awid            (lwh2f_awid),
      .lwhps2fpga_awaddr          (lwh2f_awaddr),
      .lwhps2fpga_awlen           (lwh2f_awlen),
      .lwhps2fpga_awsize          (lwh2f_awsize),
      .lwhps2fpga_awburst         (lwh2f_awburst),
      .lwhps2fpga_awlock          (lwh2f_awlock),
      .lwhps2fpga_awcache         (lwh2f_awcache),
      .lwhps2fpga_awprot          (lwh2f_awprot),
      .lwhps2fpga_awvalid         (lwh2f_awvalid),
      .lwhps2fpga_awready         (lwh2f_awready),
      .lwhps2fpga_wdata           (lwh2f_wdata),
      .lwhps2fpga_wstrb           (lwh2f_wstrb),
      .lwhps2fpga_wlast           (lwh2f_wlast),
      .lwhps2fpga_wvalid          (lwh2f_wvalid),
      .lwhps2fpga_wready          (lwh2f_wready),
      .lwhps2fpga_bid             (lwh2f_bid),
      .lwhps2fpga_bresp           (lwh2f_bresp),
      .lwhps2fpga_bvalid          (lwh2f_bvalid),
      .lwhps2fpga_bready          (lwh2f_bready),
      .lwhps2fpga_arid            (lwh2f_arid),
      .lwhps2fpga_araddr          (lwh2f_araddr),
      .lwhps2fpga_arlen           (lwh2f_arlen),
      .lwhps2fpga_arsize          (lwh2f_arsize),
      .lwhps2fpga_arburst         (lwh2f_arburst),
      .lwhps2fpga_arlock          (lwh2f_arlock),
      .lwhps2fpga_arcache         (lwh2f_arcache),
      .lwhps2fpga_arprot          (lwh2f_arprot),
      .lwhps2fpga_arvalid         (lwh2f_arvalid),
      .lwhps2fpga_arready         (lwh2f_arready),
      .lwhps2fpga_rid             (lwh2f_rid),
      .lwhps2fpga_rdata           (lwh2f_rdata),
      .lwhps2fpga_rresp           (lwh2f_rresp),
      .lwhps2fpga_rlast           (lwh2f_rlast),
      .lwhps2fpga_rvalid          (lwh2f_rvalid),
      .lwhps2fpga_rready          (lwh2f_rready),
      // FPGA2HPS Bridge
      .fpga2hps_clock_clk         (clk_sys),
      .fpga2hps_reset_reset       (rst_sys),
      .fpga2hps_awid,
      .fpga2hps_awaddr,
      .fpga2hps_awdomain,
      .fpga2hps_awsnoop,
      .fpga2hps_awlen,
      .fpga2hps_awsize,
      .fpga2hps_arsize,
      .fpga2hps_awburst,
      .fpga2hps_awlock,
      .fpga2hps_awcache,
      .fpga2hps_awprot,
      .fpga2hps_awqos,
      .fpga2hps_awregion,
      .fpga2hps_awstashnid,
      .fpga2hps_awstashniden,
      .fpga2hps_awstashlpid,
      .fpga2hps_awstashlpiden,
      .fpga2hps_awatop,
      .fpga2hps_awuser,
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
      .fpga2hps_ardomain,
      .fpga2hps_arsnoop,
      .fpga2hps_arlen,
      .fpga2hps_arburst,
      .fpga2hps_arlock,
      .fpga2hps_arcache,
      .fpga2hps_arprot,
      .fpga2hps_arqos,
      .fpga2hps_arregion,
      .fpga2hps_aruser,
      .fpga2hps_arvalid,
      .fpga2hps_arready,
      .fpga2hps_rid,
      .fpga2hps_rdata,
      .fpga2hps_rresp,
      .fpga2hps_rlast,
      .fpga2hps_ruser,
      .fpga2hps_rvalid,
      .fpga2hps_rready,
      // HPS Peripheral I/O
      .hps_io_hps_osc_clk,
      .hps_io_mdio0_mdc,
      .hps_io_mdio0_mdio,
      .hps_io_emac0_rx_clk,
      .hps_io_emac0_rx_ctl,
      .hps_io_emac0_rxd0,
      .hps_io_emac0_rxd1,
      .hps_io_emac0_rxd2,
      .hps_io_emac0_rxd3,
      .hps_io_emac0_tx_clk,
      .hps_io_emac0_tx_ctl,
      .hps_io_emac0_txd0,
      .hps_io_emac0_txd1,
      .hps_io_emac0_txd2,
      .hps_io_emac0_txd3,
      .hps_io_sdmmc_cclk,
      .hps_io_sdmmc_cmd,
      .hps_io_sdmmc_data0,
      .hps_io_sdmmc_data1,
      .hps_io_sdmmc_data2,
      .hps_io_sdmmc_data3,
      .hps_io_usb0_clk,
      .hps_io_usb0_data0,
      .hps_io_usb0_data1,
      .hps_io_usb0_data2,
      .hps_io_usb0_data3,
      .hps_io_usb0_data4,
      .hps_io_usb0_data5,
      .hps_io_usb0_data6,
      .hps_io_usb0_data7,
      .hps_io_usb0_dir,
      .hps_io_usb0_nxt,
      .hps_io_usb0_stp,
      .hps_io_uart1_tx,
      .hps_io_uart1_rx,
      .hps_io_i2c1_sda,
      .hps_io_i2c1_scl,
      .hps_io_gpio28,
      .hps_io_gpio34,
      .hps_io_gpio40,
      .hps_io_gpio41,
      // HPS2EMIF CSR Bridge
      .io96b0_to_hps_ch0_axil_clk,
      .io96b0_to_hps_ch0_axil_reset_n,
      .io96b0_to_hps_ch0_axil_awaddr,
      .io96b0_to_hps_ch0_axil_awprot,
      .io96b0_to_hps_ch0_axil_awvalid,
      .io96b0_to_hps_ch0_axil_awready,
      .io96b0_to_hps_ch0_axil_wdata,
      .io96b0_to_hps_ch0_axil_wstrb,
      .io96b0_to_hps_ch0_axil_wvalid,
      .io96b0_to_hps_ch0_axil_wready,
      .io96b0_to_hps_ch0_axil_bresp,
      .io96b0_to_hps_ch0_axil_bvalid,
      .io96b0_to_hps_ch0_axil_bready,
      .io96b0_to_hps_ch0_axil_araddr,
      .io96b0_to_hps_ch0_axil_arprot,
      .io96b0_to_hps_ch0_axil_arvalid,
      .io96b0_to_hps_ch0_axil_arready,
      .io96b0_to_hps_ch0_axil_rdata,
      .io96b0_to_hps_ch0_axil_rresp,
      .io96b0_to_hps_ch0_axil_rvalid,
      .io96b0_to_hps_ch0_axil_rready,
      // HPS2EMIF Bridge
      .io96b0_to_hps_axi4_ch0_clk,
      .io96b0_to_hps_axi4_ch0_reset_n,
      .io96b0_to_hps_axi4_ch0_awaddr,
      .io96b0_to_hps_axi4_ch0_awprot,
      .io96b0_to_hps_axi4_ch0_awburst,
      .io96b0_to_hps_axi4_ch0_awid,
      .io96b0_to_hps_axi4_ch0_awlen,
      .io96b0_to_hps_axi4_ch0_awlock,
      .io96b0_to_hps_axi4_ch0_awqos,
      .io96b0_to_hps_axi4_ch0_awsize,
      .io96b0_to_hps_axi4_ch0_awuser,
      .io96b0_to_hps_axi4_ch0_awvalid,
      .io96b0_to_hps_axi4_ch0_awready,
      .io96b0_to_hps_axi4_ch0_wdata,
      .io96b0_to_hps_axi4_ch0_wlast,
      .io96b0_to_hps_axi4_ch0_wstrb,
      .io96b0_to_hps_axi4_ch0_wuser,
      .io96b0_to_hps_axi4_ch0_wvalid,
      .io96b0_to_hps_axi4_ch0_wready,
      .io96b0_to_hps_axi4_ch0_bid,
      .io96b0_to_hps_axi4_ch0_bresp,
      .io96b0_to_hps_axi4_ch0_bvalid,
      .io96b0_to_hps_axi4_ch0_bready,
      .io96b0_to_hps_axi4_ch0_araddr,
      .io96b0_to_hps_axi4_ch0_arprot,
      .io96b0_to_hps_axi4_ch0_arburst,
      .io96b0_to_hps_axi4_ch0_arid,
      .io96b0_to_hps_axi4_ch0_arlen,
      .io96b0_to_hps_axi4_ch0_arlock,
      .io96b0_to_hps_axi4_ch0_arqos,
      .io96b0_to_hps_axi4_ch0_arsize,
      .io96b0_to_hps_axi4_ch0_aruser,
      .io96b0_to_hps_axi4_ch0_arvalid,
      .io96b0_to_hps_axi4_ch0_arready,
      .io96b0_to_hps_axi4_ch0_rdata,
      .io96b0_to_hps_axi4_ch0_rid,
      .io96b0_to_hps_axi4_ch0_rresp,
      .io96b0_to_hps_axi4_ch0_rlast,
      .io96b0_to_hps_axi4_ch0_ruser,
      .io96b0_to_hps_axi4_ch0_rvalid,
      .io96b0_to_hps_axi4_ch0_rready
      );

   // HPS EMIF Bridge
   emif_io96b_hps u_emif_io96b_hps
     (.s0_noc_axi4lite_clock     (io96b0_to_hps_ch0_axil_clk),
      .s0_noc_axi4lite_reset_n   (io96b0_to_hps_ch0_axil_reset_n),
      .s0_noc_axi4lite_awaddr    (io96b0_to_hps_ch0_axil_awaddr),
      .s0_noc_axi4lite_awprot    (io96b0_to_hps_ch0_axil_awprot),
      .s0_noc_axi4lite_awvalid   (io96b0_to_hps_ch0_axil_awvalid),
      .s0_noc_axi4lite_awready   (io96b0_to_hps_ch0_axil_awready),
      .s0_noc_axi4lite_wdata     (io96b0_to_hps_ch0_axil_wdata),
      .s0_noc_axi4lite_wstrb     (io96b0_to_hps_ch0_axil_wstrb),
      .s0_noc_axi4lite_wvalid    (io96b0_to_hps_ch0_axil_wvalid),
      .s0_noc_axi4lite_wready    (io96b0_to_hps_ch0_axil_wready),
      .s0_noc_axi4lite_bresp     (io96b0_to_hps_ch0_axil_bresp),
      .s0_noc_axi4lite_bvalid    (io96b0_to_hps_ch0_axil_bvalid),
      .s0_noc_axi4lite_bready    (io96b0_to_hps_ch0_axil_bready),
      .s0_noc_axi4lite_araddr    (io96b0_to_hps_ch0_axil_araddr),
      .s0_noc_axi4lite_arprot    (io96b0_to_hps_ch0_axil_arprot),
      .s0_noc_axi4lite_arvalid   (io96b0_to_hps_ch0_axil_arvalid),
      .s0_noc_axi4lite_arready   (io96b0_to_hps_ch0_axil_arready),
      .s0_noc_axi4lite_rresp     (io96b0_to_hps_ch0_axil_rresp),
      .s0_noc_axi4lite_rdata     (io96b0_to_hps_ch0_axil_rdata),
      .s0_noc_axi4lite_rvalid    (io96b0_to_hps_ch0_axil_rvalid),
      .s0_noc_axi4lite_rready    (io96b0_to_hps_ch0_axil_rready),
      //
      .noc_aclk_0                (io96b0_to_hps_axi4_ch0_clk),
      .noc_rst_n_0               (io96b0_to_hps_axi4_ch0_reset_n),
      .s0_axi4_awaddr            (io96b0_to_hps_axi4_ch0_awaddr),
      .s0_axi4_awburst           (io96b0_to_hps_axi4_ch0_awburst),
      .s0_axi4_awid              (io96b0_to_hps_axi4_ch0_awid),
      .s0_axi4_awlen             (io96b0_to_hps_axi4_ch0_awlen),
      .s0_axi4_awlock            (io96b0_to_hps_axi4_ch0_awlock),
      .s0_axi4_awqos             (io96b0_to_hps_axi4_ch0_awqos),
      .s0_axi4_awsize            (io96b0_to_hps_axi4_ch0_awsize),
      .s0_axi4_awvalid           (io96b0_to_hps_axi4_ch0_awvalid),
      .s0_axi4_awuser            (io96b0_to_hps_axi4_ch0_awuser),
      .s0_axi4_awprot            (io96b0_to_hps_axi4_ch0_awprot),
      .s0_axi4_awready           (io96b0_to_hps_axi4_ch0_awready),
      .s0_axi4_wdata             (io96b0_to_hps_axi4_ch0_wdata),
      .s0_axi4_wstrb             (io96b0_to_hps_axi4_ch0_wstrb),
      .s0_axi4_wlast             (io96b0_to_hps_axi4_ch0_wlast),
      .s0_axi4_wuser             (io96b0_to_hps_axi4_ch0_wuser),
      .s0_axi4_wvalid            (io96b0_to_hps_axi4_ch0_wvalid),
      .s0_axi4_wready            (io96b0_to_hps_axi4_ch0_wready),
      .s0_axi4_bid               (io96b0_to_hps_axi4_ch0_bid),
      .s0_axi4_bresp             (io96b0_to_hps_axi4_ch0_bresp),
      .s0_axi4_bvalid            (io96b0_to_hps_axi4_ch0_bvalid),
      .s0_axi4_bready            (io96b0_to_hps_axi4_ch0_bready),
      .s0_axi4_araddr            (io96b0_to_hps_axi4_ch0_araddr),
      .s0_axi4_arburst           (io96b0_to_hps_axi4_ch0_arburst),
      .s0_axi4_arid              (io96b0_to_hps_axi4_ch0_arid),
      .s0_axi4_arlen             (io96b0_to_hps_axi4_ch0_arlen),
      .s0_axi4_arlock            (io96b0_to_hps_axi4_ch0_arlock),
      .s0_axi4_arqos             (io96b0_to_hps_axi4_ch0_arqos),
      .s0_axi4_arsize            (io96b0_to_hps_axi4_ch0_arsize),
      .s0_axi4_arvalid           (io96b0_to_hps_axi4_ch0_arvalid),
      .s0_axi4_aruser            (io96b0_to_hps_axi4_ch0_aruser),
      .s0_axi4_arprot            (io96b0_to_hps_axi4_ch0_arprot),
      .s0_axi4_arready           (io96b0_to_hps_axi4_ch0_arready),
      .s0_axi4_rdata             (io96b0_to_hps_axi4_ch0_rdata),
      .s0_axi4_rid               (io96b0_to_hps_axi4_ch0_rid),
      .s0_axi4_rresp             (io96b0_to_hps_axi4_ch0_rresp),
      .s0_axi4_rlast             (io96b0_to_hps_axi4_ch0_rlast),
      .s0_axi4_ruser             (io96b0_to_hps_axi4_ch0_ruser),
      .s0_axi4_rvalid            (io96b0_to_hps_axi4_ch0_rvalid),
      .s0_axi4_rready            (io96b0_to_hps_axi4_ch0_rready),
      //
      .mem_0_cs,
      .mem_0_ca,
      .mem_0_cke,
      .mem_0_dq,
      .mem_0_dqs_t,
      .mem_0_dqs_c,
      .mem_0_dmi,
      .mem_0_ck_t,
      .mem_0_ck_c,
      .mem_0_reset_n,
      .oct_rzqin_0,
      .ref_clk
      );

   // AXI4 <-> ACE5Lite conversion
   ace5_translate #
     (.WSTRB_WIDTH (32),
      .USER_WIDTH  (8))
   u_ace5_translate
     (.clk                      (clk_sys),
      .reset                    (rst_sys),
      .m_ace5lite_awid          (fpga2hps_awid),
      .m_ace5lite_awaddr        (fpga2hps_awaddr),
      .m_ace5lite_awdomain      (fpga2hps_awdomain),
      .m_ace5lite_awsnoop       (fpga2hps_awsnoop),
      .m_ace5lite_awlen         (fpga2hps_awlen),
      .m_ace5lite_awsize        (fpga2hps_awsize),
      .m_ace5lite_awburst       (fpga2hps_awburst),
      .m_ace5lite_awlock        (fpga2hps_awlock),
      .m_ace5lite_awcache       (fpga2hps_awcache),
      .m_ace5lite_awprot        (fpga2hps_awprot),
      .m_ace5lite_awqos         (fpga2hps_awqos),
      .m_ace5lite_awregion      (fpga2hps_awregion),
      .m_ace5lite_awstashnid    (fpga2hps_awstashnid),
      .m_ace5lite_awstashniden  (fpga2hps_awstashniden),
      .m_ace5lite_awstashlpid   (fpga2hps_awstashlpid),
      .m_ace5lite_awstashlpiden (fpga2hps_awstashlpiden),
      .m_ace5lite_awatop        (fpga2hps_awatop),
      .m_ace5lite_awuser        (fpga2hps_awuser),
      .m_ace5lite_awvalid       (fpga2hps_awvalid),
      .m_ace5lite_awready       (fpga2hps_awready),
      .m_ace5lite_wdata         (fpga2hps_wdata),
      .m_ace5lite_wstrb         (fpga2hps_wstrb),
      .m_ace5lite_wlast         (fpga2hps_wlast),
      .m_ace5lite_wuser         (fpga2hps_wuser),
      .m_ace5lite_wvalid        (fpga2hps_wvalid),
      .m_ace5lite_wready        (fpga2hps_wready),
      .m_ace5lite_bid           (fpga2hps_bid),
      .m_ace5lite_bresp         (fpga2hps_bresp),
      .m_ace5lite_buser         (fpga2hps_buser),
      .m_ace5lite_bvalid        (fpga2hps_bvalid),
      .m_ace5lite_bready        (fpga2hps_bready),
      .m_ace5lite_arid          (fpga2hps_arid),
      .m_ace5lite_araddr        (fpga2hps_araddr),
      .m_ace5lite_ardomain      (fpga2hps_ardomain),
      .m_ace5lite_arsnoop       (fpga2hps_arsnoop),
      .m_ace5lite_arlen         (fpga2hps_arlen),
      .m_ace5lite_arsize        (fpga2hps_arsize),
      .m_ace5lite_arburst       (fpga2hps_arburst),
      .m_ace5lite_arlock        (fpga2hps_arlock),
      .m_ace5lite_arcache       (fpga2hps_arcache),
      .m_ace5lite_arprot        (fpga2hps_arprot),
      .m_ace5lite_arqos         (fpga2hps_arqos),
      .m_ace5lite_arregion      (fpga2hps_arregion),
      .m_ace5lite_aruser        (fpga2hps_aruser),
      .m_ace5lite_arvalid       (fpga2hps_arvalid),
      .m_ace5lite_arready       (fpga2hps_arready),
      .m_ace5lite_rid           (fpga2hps_rid),
      .m_ace5lite_rdata         (fpga2hps_rdata),
      .m_ace5lite_rresp         (fpga2hps_rresp),
      .m_ace5lite_rlast         (fpga2hps_rlast),
      .m_ace5lite_rvalid        (fpga2hps_rvalid),
      .m_ace5lite_rready        (fpga2hps_rready),
      .m_ace5lite_ruser         (fpga2hps_ruser),
      //
      .s_axi_awid               (f2h_awid),
      .s_axi_awaddr             (f2h_awaddr),
      .s_axi_awlen              (f2h_awlen),
      .s_axi_awsize             (f2h_awsize),
      .s_axi_awburst            (f2h_awburst),
      .s_axi_awlock             (f2h_awlock),
      .s_axi_awcache            (f2h_awcache),
      .s_axi_awprot             (f2h_awprot),
      .s_axi_awqos              (f2h_awqos),
      .s_axi_awregion           (f2h_awregion),
      .s_axi_awvalid            (f2h_awvalid),
      .s_axi_awready            (f2h_awready),
      .s_axi_wdata              (f2h_wdata),
      .s_axi_wstrb              (f2h_wstrb),
      .s_axi_wlast              (f2h_wlast),
      .s_axi_wuser              (f2h_wuser),
      .s_axi_wvalid             (f2h_wvalid),
      .s_axi_wready             (f2h_wready),
      .s_axi_bid                (f2h_bid),
      .s_axi_bresp              (f2h_bresp),
      .s_axi_buser              (f2h_buser),
      .s_axi_bvalid             (f2h_bvalid),
      .s_axi_bready             (f2h_bready),
      .s_axi_arid               (f2h_arid),
      .s_axi_araddr             (f2h_araddr),
      .s_axi_arlen              (f2h_arlen),
      .s_axi_arsize             (f2h_arsize),
      .s_axi_arburst            (f2h_arburst),
      .s_axi_arlock             (f2h_arlock),
      .s_axi_arcache            (f2h_arcache),
      .s_axi_arprot             (f2h_arprot),
      .s_axi_arqos              (f2h_arqos),
      .s_axi_arregion           (f2h_arregion),
      .s_axi_arvalid            (f2h_arvalid),
      .s_axi_arready            (f2h_arready),
      .s_axi_rid                (f2h_rid),
      .s_axi_rdata              (f2h_rdata),
      .s_axi_rresp              (f2h_rresp),
      .s_axi_rlast              (f2h_rlast),
      .s_axi_ruser              (f2h_ruser),
      .s_axi_rvalid             (f2h_rvalid),
      .s_axi_rready             (f2h_rready)
      );

endmodule // hps_wrapper
