// -*- mode: verilog; mode: font-lock; indent-tabs-mode: nil -*-
// vi: set et ts=3 sw=3 sts=3:
//
// Copyright 2026 Steffen Persvold
// SPDX-License-Identifier: Apache-2.0
//
// ========================================================================
// File        : vctrl_wrapper.sv
// Author      : Steffen Persvold
// ========================================================================
//

module vctrl_wrapper
 #(
   parameter  int  AXI_ID_W   = 4,
   parameter  int  AXI_ADDR_W = 32,
   parameter  int  AXI_DATA_W = 256,
   //
   localparam type axid_t   = logic [AXI_ID_W    -1:0],
   localparam type axaddr_t = logic [AXI_ADDR_W  -1:0],
   localparam type axdata_t = logic [AXI_DATA_W  -1:0],
   localparam type axstrb_t = logic [AXI_DATA_W/8-1:0]
   )
  (
    input  logic         clk_sys           // System clock
   ,input  logic         rst_sys           // System reset
   //
   ,input  logic         clk_pix           // Pixel clock
   ,input  logic         rst_pix           // Pixel reset
   //
   ,output logic [1:0]   vctrl_irq         // Interrupt
   ,output logic         vctrl_init_done   // Init done
   //
   ,output logic [31:0]  pll_divcnt        // PLLDIVCNT (clk_sys, quasi-static)
   ,output logic         pll_apply         // trigger pulse (clk_sys)
   ,input  logic         pll_done          // done pulse (clk_sys)
   ,input  logic         pll_locked        // synced PLL locked (clk_sys)
   ,input  logic         pll_error         // synced recal error (clk_sys)
   // HDMI
   ,output logic [7:0]   vga_r             // Red
   ,output logic [7:0]   vga_g             // Green
   ,output logic [7:0]   vga_b             // Blue
   ,output logic         vga_hs            // Horizontal Sync
   ,output logic         vga_vs            // Vertical Sync
   ,output logic         vga_bl            // Blanking
   //
   // ----------------------------------------------------------------------
   // LWHPS2FPGA AXI4 Master port (HPS -> FPGA, lightweight; 32-bit data, 29-bit addr)
   // ----------------------------------------------------------------------
   // AW channel
   ,input  logic [3:0]   lwhps2fpga_awid
   ,input  logic [28:0]  lwhps2fpga_awaddr
   ,input  logic [7:0]   lwhps2fpga_awlen
   ,input  logic [2:0]   lwhps2fpga_awsize
   ,input  logic [1:0]   lwhps2fpga_awburst
   ,input  logic         lwhps2fpga_awlock
   ,input  logic [3:0]   lwhps2fpga_awcache
   ,input  logic [2:0]   lwhps2fpga_awprot
   ,input  logic         lwhps2fpga_awvalid
   ,output logic         lwhps2fpga_awready
   // W channel
   ,input  logic [31:0]  lwhps2fpga_wdata
   ,input  logic [3:0]   lwhps2fpga_wstrb
   ,input  logic         lwhps2fpga_wlast
   ,input  logic         lwhps2fpga_wvalid
   ,output logic         lwhps2fpga_wready
   // B channel
   ,output logic [3:0]   lwhps2fpga_bid
   ,output logic [1:0]   lwhps2fpga_bresp
   ,output logic         lwhps2fpga_bvalid
   ,input  logic         lwhps2fpga_bready
   // AR channel
   ,input  logic [3:0]   lwhps2fpga_arid
   ,input  logic [28:0]  lwhps2fpga_araddr
   ,input  logic [7:0]   lwhps2fpga_arlen
   ,input  logic [2:0]   lwhps2fpga_arsize
   ,input  logic [1:0]   lwhps2fpga_arburst
   ,input  logic         lwhps2fpga_arlock
   ,input  logic [3:0]   lwhps2fpga_arcache
   ,input  logic [2:0]   lwhps2fpga_arprot
   ,input  logic         lwhps2fpga_arvalid
   ,output logic         lwhps2fpga_arready
   // R channel
   ,output logic [3:0]   lwhps2fpga_rid
   ,output logic [31:0]  lwhps2fpga_rdata
   ,output logic [1:0]   lwhps2fpga_rresp
   ,output logic         lwhps2fpga_rlast
   ,output logic         lwhps2fpga_rvalid
   ,input  logic         lwhps2fpga_rready
   // HPS2FPGA AXI4 Master port (HPS -> FPGA; 128-bit data, 32-bit addr)
   // AW channel
   ,input  wire [3:0]    hps2fpga_awid
   ,input  wire [31:0]   hps2fpga_awaddr
   ,input  wire [7:0]    hps2fpga_awlen
   ,input  wire [2:0]    hps2fpga_awsize
   ,input  wire [1:0]    hps2fpga_awburst
   ,input  wire          hps2fpga_awlock
   ,input  wire [3:0]    hps2fpga_awcache
   ,input  wire [2:0]    hps2fpga_awprot
   ,input  wire          hps2fpga_awvalid
   ,output wire          hps2fpga_awready
   // W channel
   ,input  wire [127:0]  hps2fpga_wdata
   ,input  wire [15:0]   hps2fpga_wstrb
   ,input  wire          hps2fpga_wlast
   ,input  wire          hps2fpga_wvalid
   ,output wire          hps2fpga_wready
   // B channel
   ,output wire [3:0]    hps2fpga_bid
   ,output wire [1:0]    hps2fpga_bresp
   ,output wire          hps2fpga_bvalid
   ,input  wire          hps2fpga_bready
   // AR channel
   ,input  wire [3:0]    hps2fpga_arid
   ,input  wire [31:0]   hps2fpga_araddr
   ,input  wire [7:0]    hps2fpga_arlen
   ,input  wire [2:0]    hps2fpga_arsize
   ,input  wire [1:0]    hps2fpga_arburst
   ,input  wire          hps2fpga_arlock
   ,input  wire [3:0]    hps2fpga_arcache
   ,input  wire [2:0]    hps2fpga_arprot
   ,input  wire          hps2fpga_arvalid
   ,output wire          hps2fpga_arready
   // R channel
   ,output wire [3:0]    hps2fpga_rid
   ,output wire [127:0]  hps2fpga_rdata
   ,output wire [1:0]    hps2fpga_rresp
   ,output wire          hps2fpga_rlast
   ,output wire          hps2fpga_rvalid
   ,input  wire          hps2fpga_rready
   // LPDDR4B
   ,input  wire          LPDDR4B_REFCLK_p
   ,output wire          LPDDR4B_CS_n
   ,output wire [ 5: 0]  LPDDR4B_CA
   ,output wire          LPDDR4B_CK
   ,output wire          LPDDR4B_CK_n
   ,output wire          LPDDR4B_CKE
   ,inout  wire [ 3: 0]  LPDDR4B_DM
   ,inout  wire [31: 0]  LPDDR4B_DQ
   ,inout  wire [ 3: 0]  LPDDR4B_DQS
   ,inout  wire [ 3: 0]  LPDDR4B_DQS_n
   ,output wire          LPDDR4B_RESET_n
   ,input  wire          LPDDR4B_RZQ
   // ----------------------------------------------------------------------
   // AXI4 read/write master
   // ----------------------------------------------------------------------
   // AR channel
   ,output logic [4:0]   m_axi_arid
   ,output logic [31:0]  m_axi_araddr
   ,output logic [7:0]   m_axi_arlen
   ,output logic [2:0]   m_axi_arsize
   ,output logic [1:0]   m_axi_arburst
   ,output logic         m_axi_arlock
   ,output logic [3:0]   m_axi_arcache
   ,output logic [2:0]   m_axi_arprot
   ,output logic         m_axi_arvalid
   ,input  logic         m_axi_arready
   // R channel
   ,input  logic [4:0]   m_axi_rid
   ,input  axdata_t      m_axi_rdata
   ,input  logic [1:0]   m_axi_rresp
   ,input  logic         m_axi_rlast
   ,input  logic         m_axi_rvalid
   ,output logic         m_axi_rready
   // AW channel
   ,output logic [4:0]   m_axi_awid
   ,output logic [31:0]  m_axi_awaddr
   ,output logic [7:0]   m_axi_awlen
   ,output logic [2:0]   m_axi_awsize
   ,output logic [1:0]   m_axi_awburst
   ,output logic         m_axi_awlock
   ,output logic [3:0]   m_axi_awcache
   ,output logic [2:0]   m_axi_awprot
   ,output logic         m_axi_awvalid
   ,input  logic         m_axi_awready
   // W channel
   ,output axdata_t      m_axi_wdata
   ,output axstrb_t      m_axi_wstrb
   ,output logic         m_axi_wlast
   ,output logic         m_axi_wvalid
   ,input  logic         m_axi_wready
   // B channel
   ,input  logic [4:0]   m_axi_bid
   ,input  logic [1:0]   m_axi_bresp
   ,input  logic         m_axi_bvalid
   ,output logic         m_axi_bready
   );

   //
   // Control-plane bridge: lwhps2fpga AXI4 -> video controller cfg bus
   //

   logic                 cfg_req, cmd_req;
   logic [11:2]          cfg_adr, cmd_adr;
   logic                 cfg_we, cmd_we;
   logic [ 3:0]          cfg_be, cmd_be;
   logic [31:0]          cfg_d, cmd_d;
   logic [31:0]          cfg_q, cmd_q;
   logic                 cfg_ack, cmd_ack;

   lw_ctrl_bridge u_lw_ctrl_bridge
     (.clk            (clk_sys),
      .rst            (rst_sys),
      .s_axi_awid     (lwhps2fpga_awid),
      .s_axi_awaddr   (lwhps2fpga_awaddr),
      .s_axi_awlen    (lwhps2fpga_awlen),
      .s_axi_awsize   (lwhps2fpga_awsize),
      .s_axi_awburst  (lwhps2fpga_awburst),
      .s_axi_awlock   (lwhps2fpga_awlock),
      .s_axi_awcache  (lwhps2fpga_awcache),
      .s_axi_awprot   (lwhps2fpga_awprot),
      .s_axi_awvalid  (lwhps2fpga_awvalid),
      .s_axi_awready  (lwhps2fpga_awready),
      .s_axi_wdata    (lwhps2fpga_wdata),
      .s_axi_wstrb    (lwhps2fpga_wstrb),
      .s_axi_wlast    (lwhps2fpga_wlast),
      .s_axi_wvalid   (lwhps2fpga_wvalid),
      .s_axi_wready   (lwhps2fpga_wready),
      .s_axi_bid      (lwhps2fpga_bid),
      .s_axi_bresp    (lwhps2fpga_bresp),
      .s_axi_bvalid   (lwhps2fpga_bvalid),
      .s_axi_bready   (lwhps2fpga_bready),
      .s_axi_arid     (lwhps2fpga_arid),
      .s_axi_araddr   (lwhps2fpga_araddr),
      .s_axi_arlen    (lwhps2fpga_arlen),
      .s_axi_arsize   (lwhps2fpga_arsize),
      .s_axi_arburst  (lwhps2fpga_arburst),
      .s_axi_arlock   (lwhps2fpga_arlock),
      .s_axi_arcache  (lwhps2fpga_arcache),
      .s_axi_arprot   (lwhps2fpga_arprot),
      .s_axi_arvalid  (lwhps2fpga_arvalid),
      .s_axi_arready  (lwhps2fpga_arready),
      .s_axi_rid      (lwhps2fpga_rid),
      .s_axi_rdata    (lwhps2fpga_rdata),
      .s_axi_rresp    (lwhps2fpga_rresp),
      .s_axi_rlast    (lwhps2fpga_rlast),
      .s_axi_rvalid   (lwhps2fpga_rvalid),
      .s_axi_rready   (lwhps2fpga_rready),
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

   logic                     frame_sys;      // start-of-frame strobe (to scanout master)
   logic [31:2]              vctrl_vbar;     // video base address (from VBAR reg)
   logic [31:2]              vctrl_vsiz;     // scanout buffer size (from VSIZ reg)
   logic                     vctrl_ven;      // scanout enable -> gates the fetch master
   logic                     vctrl_fetch_idle; // fetch master idle (no reads in flight)

   // Frame buffer read port - driven by the scanout AXI master (u_vctrl_axim)
   logic                     fb_rdreq;
   logic [VR_ADDRW-1:0]      fb_raddr;
   logic                     fb_rdack;
   logic [VR_DATAW-1:0]      fb_rdata;
   logic                     fb_rvalid;

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
      .irq        (vctrl_irq[0]),
      .frame_sys,
      .vbar       (vctrl_vbar),
      .vsiz       (vctrl_vsiz),
      .ven        (vctrl_ven),
      .fetch_idle (vctrl_fetch_idle),
      .fb_rdreq,
      .fb_raddr,
      .fb_rdack,
      .fb_rdata,
      .fb_rvalid,
      .clk_pix,
      .rst_pix,
      .pll_divcnt,
      .pll_apply,
      .pll_done,
      .pll_locked,
      .pll_error,
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

   wire [AXI_ADDR_W-1:0]     fb_base = AXI_ADDR_W'({vctrl_vbar, 2'b00});
   wire [AXI_ADDR_W-1:0]     fb_size = AXI_ADDR_W'({vctrl_vsiz, 2'b00});

   // ----------------------------------------------------------------------
   // AXI4 master (scanout read-only, write is tied)
   // ----------------------------------------------------------------------
   // AR channel
   axid_t                    s1_axi4_arid;
   axaddr_t                  s1_axi4_araddr;
   logic [7:0]               s1_axi4_arlen;
   logic [2:0]               s1_axi4_arsize;
   logic [1:0]               s1_axi4_arburst;
   logic                     s1_axi4_arlock;
   logic [3:0]               s1_axi4_arcache;
   logic [2:0]               s1_axi4_arprot;
   logic                     s1_axi4_arvalid;
   logic                     s1_axi4_arready;
   // R channel
   axid_t                    s1_axi4_rid;
   axdata_t                  s1_axi4_rdata;
   logic [1:0]               s1_axi4_rresp;
   logic                     s1_axi4_rlast;
   logic                     s1_axi4_rvalid;
   logic                     s1_axi4_rready;
   // AW channel
   axid_t                    s1_axi4_awid = '0;
   axaddr_t                  s1_axi4_awaddr = '0;
   logic [7:0]               s1_axi4_awlen = '0;
   logic [2:0]               s1_axi4_awsize = '0;
   logic [1:0]               s1_axi4_awburst = '0;
   logic                     s1_axi4_awlock = '0;
   logic [3:0]               s1_axi4_awcache = '0;
   logic [2:0]               s1_axi4_awprot = '0;
   logic                     s1_axi4_awvalid = '0;
   logic                     s1_axi4_awready;
   // W channel
   axdata_t                  s1_axi4_wdata = '0;
   axstrb_t                  s1_axi4_wstrb = '0;
   logic                     s1_axi4_wlast = '0;
   logic                     s1_axi4_wvalid = '0;
   logic                     s1_axi4_wready;
   // B channel
   axid_t                    s1_axi4_bid;
   logic [1:0]               s1_axi4_bresp;
   logic                     s1_axi4_bvalid;
   logic                     s1_axi4_bready = '1;

   // ----------------------------------------------------------------------
   // AXI4 master (DMA read/write)
   // ----------------------------------------------------------------------
   // AR channel
   axid_t                    s2_axi4_arid;
   axaddr_t                  s2_axi4_araddr;
   logic [7:0]               s2_axi4_arlen;
   logic [2:0]               s2_axi4_arsize;
   logic [1:0]               s2_axi4_arburst;
   logic                     s2_axi4_arlock;
   logic [3:0]               s2_axi4_arcache;
   logic [2:0]               s2_axi4_arprot;
   logic                     s2_axi4_arvalid;
   logic                     s2_axi4_arready;
   // R channel
   axid_t                    s2_axi4_rid;
   axdata_t                  s2_axi4_rdata;
   logic [1:0]               s2_axi4_rresp;
   logic                     s2_axi4_rlast;
   logic                     s2_axi4_rvalid;
   logic                     s2_axi4_rready;
   // AW channel
   axid_t                    s2_axi4_awid;
   axaddr_t                  s2_axi4_awaddr;
   logic [7:0]               s2_axi4_awlen;
   logic [2:0]               s2_axi4_awsize;
   logic [1:0]               s2_axi4_awburst;
   logic                     s2_axi4_awlock;
   logic [3:0]               s2_axi4_awcache;
   logic [2:0]               s2_axi4_awprot;
   logic                     s2_axi4_awvalid;
   logic                     s2_axi4_awready;
   // W channel
   axdata_t                  s2_axi4_wdata;
   axstrb_t                  s2_axi4_wstrb;
   logic                     s2_axi4_wlast;
   logic                     s2_axi4_wvalid;
   logic                     s2_axi4_wready;
   // B channel
   axid_t                    s2_axi4_bid;
   logic [1:0]               s2_axi4_bresp;
   logic                     s2_axi4_bvalid;
   logic                     s2_axi4_bready;

   // EMIF Calibration control bus
   logic [26:0]              axil_driver_araddr;
   logic [2:0]               axil_driver_arprot;
   logic                     axil_driver_arvalid;
   logic                     axil_driver_arready;
   logic [31:0]              axil_driver_rdata;
   logic [1:0]               axil_driver_rresp;
   logic                     axil_driver_rvalid;
   logic                     axil_driver_rready;

   logic [26:0]              axil_driver_awaddr;
   logic [2:0]               axil_driver_awprot;
   logic                     axil_driver_awvalid;
   logic                     axil_driver_awready;
   logic [31:0]              axil_driver_wdata;
   logic [3:0]               axil_driver_wstrb;
   logic                     axil_driver_wvalid;
   logic                     axil_driver_wready;
   logic [1:0]               axil_driver_bresp;
   logic                     axil_driver_bvalid;
   logic                     axil_driver_bready;

   logic                     cal_done_rst_n;

   axil_driver_calibration u_axil_calib
     (.axil_driver_clk     (clk_sys),
      .axil_driver_rst_n   (~rst_sys),
      .axil_driver_araddr,
      .axil_driver_arprot,
      .axil_driver_arvalid,
      .axil_driver_arready,
      .axil_driver_rdata,
      .axil_driver_rresp,
      .axil_driver_rvalid,
      .axil_driver_rready,
      .axil_driver_awaddr,
      .axil_driver_awprot,
      .axil_driver_awvalid,
      .axil_driver_awready,
      .axil_driver_wdata,
      .axil_driver_wstrb,
      .axil_driver_wvalid,
      .axil_driver_wready,
      .axil_driver_bresp,
      .axil_driver_bvalid,
      .axil_driver_bready,
      .cal_done_rst_n
      );

   // ========================================================================
   // The AXI interconnect master IDs are 6-bit, but the HPS F2SDRAM/F2HPS
   // ports only accept 5-bit. We narrow AWID/ARID by dropping bit[2] and
   // restore it as 0 on the returning BID/RID.
   //
   // This is lossless ONLY because all of our masters (scanout, vctrl_dma
   // read, vctrl_dma write) tie their ID to 0 -- see vctrl_axim,
   // vctrl_dma_rd, vctrl_dma_wr. With 4-bit master IDs plus 2 source-index
   // bits = 6, bit[2] falls inside the master-ID field under either possible
   // interconnect layout ({src,id} or {id,src}), so it is always 0 and the
   // insert-0 on the response path reconstructs the original ID exactly. The
   // other five bits (including whichever carry response routing) are echoed
   // by the slave untouched, so routing is preserved regardless of MSB/LSB.
   //
   // WARNING: if any master is ever given a non-zero ID (e.g. distinct IDs
   // for out-of-order blitter reads), bit[2] can become 1 and this silently
   // mis-routes F2SDRAM responses. The assertions below guard the invariant.
   // ========================================================================
   wire [5:0]                m_axi_awid_w;
   wire [5:0]                m_axi_arid_w;
   wire [5:0]                m_axi_bid_w;
   wire [5:0]                m_axi_rid_w;

   assign m_axi_awid = {m_axi_awid_w[5:3], m_axi_awid_w[1:0]};
   assign m_axi_arid = {m_axi_arid_w[5:3], m_axi_arid_w[1:0]};

   assign m_axi_bid_w = {m_axi_bid[4:2], 1'b0, m_axi_bid[1:0]};
   assign m_axi_rid_w = {m_axi_rid[4:2], 1'b0, m_axi_rid[1:0]};

   // synthesis translate_off
   // Guard the narrowing invariant above: the dropped bit must always be 0.
   assert property (@(posedge clk_sys) disable iff (rst_sys)
                    m_axi_arvalid |-> m_axi_arid_w[2] == 1'b0)
     else $error("m_axi_arid_w[2] != 0: ID narrowing to F2SDRAM is lossy");
   assert property (@(posedge clk_sys) disable iff (rst_sys)
                    m_axi_awvalid |-> m_axi_awid_w[2] == 1'b0)
     else $error("m_axi_awid_w[2] != 0: ID narrowing to F2SDRAM is lossy");
   // synthesis translate_on

   // HPS SDRAM is always above 2GiB so force bit[31] = 1
   assign m_axi_araddr[31] = 1'b1;
   assign m_axi_awaddr[31] = 1'b1;

   lpddr4b_vram u_lpddr4b
     (.clk_sys_clk         (clk_sys),
      .rst_sys_reset       (rst_sys),
      .core_init_n_reset_n (cal_done_rst_n),
      .ctrl_ready_reset_n  (vctrl_init_done),
      // FPGA2SDRAM/FPGA2HPS
      .m_axi_awaddr        (m_axi_awaddr[30:0]),
      .m_axi_awburst,
      .m_axi_awid          (m_axi_awid_w),
      .m_axi_awlen,
      .m_axi_awlock,
      .m_axi_awcache,
      .m_axi_awqos         (),
      .m_axi_awsize,
      .m_axi_awvalid,
      .m_axi_awprot,
      .m_axi_awready,
      .m_axi_araddr        (m_axi_araddr[30:0]),
      .m_axi_arburst,
      .m_axi_arid          (m_axi_arid_w),
      .m_axi_arlen,
      .m_axi_arlock,
      .m_axi_arcache,
      .m_axi_arqos         (),
      .m_axi_arsize,
      .m_axi_arvalid,
      .m_axi_arprot,
      .m_axi_arready,
      .m_axi_wdata,
      .m_axi_wstrb,
      .m_axi_wlast,
      .m_axi_wvalid,
      .m_axi_wready,
      .m_axi_bready,
      .m_axi_bid          (m_axi_bid_w),
      .m_axi_bresp,
      .m_axi_bvalid,
      .m_axi_rready,
      .m_axi_rdata,
      .m_axi_rid          (m_axi_rid_w),
      .m_axi_rlast,
      .m_axi_rresp,
      .m_axi_rvalid,
      // HPS2FPGA
      .s0_axi4_awaddr      (hps2fpga_awaddr),
      .s0_axi4_awburst     (hps2fpga_awburst),
      .s0_axi4_awid        (hps2fpga_awid),
      .s0_axi4_awlen       (hps2fpga_awlen),
      .s0_axi4_awlock      (hps2fpga_awlock),
      .s0_axi4_awcache     (hps2fpga_awcache),
      .s0_axi4_awqos       (4'h0),
      .s0_axi4_awsize      (hps2fpga_awsize),
      .s0_axi4_awvalid     (hps2fpga_awvalid),
      .s0_axi4_awprot      (hps2fpga_awprot),
      .s0_axi4_awready     (hps2fpga_awready),
      .s0_axi4_araddr      (hps2fpga_araddr),
      .s0_axi4_arburst     (hps2fpga_arburst),
      .s0_axi4_arid        (hps2fpga_arid),
      .s0_axi4_arlen       (hps2fpga_arlen),
      .s0_axi4_arlock      (hps2fpga_arlock),
      .s0_axi4_arcache     (hps2fpga_arcache),
      .s0_axi4_arqos       (4'h0),
      .s0_axi4_arsize      (hps2fpga_arsize),
      .s0_axi4_arvalid     (hps2fpga_arvalid),
      .s0_axi4_arprot      (hps2fpga_arprot),
      .s0_axi4_arready     (hps2fpga_arready),
      .s0_axi4_wdata       (hps2fpga_wdata),
      .s0_axi4_wstrb       (hps2fpga_wstrb),
      .s0_axi4_wlast       (hps2fpga_wlast),
      .s0_axi4_wvalid      (hps2fpga_wvalid),
      .s0_axi4_wready      (hps2fpga_wready),
      .s0_axi4_bready      (hps2fpga_bready),
      .s0_axi4_bid         (hps2fpga_bid),
      .s0_axi4_bresp       (hps2fpga_bresp),
      .s0_axi4_bvalid      (hps2fpga_bvalid),
      .s0_axi4_rready      (hps2fpga_rready),
      .s0_axi4_rdata       (hps2fpga_rdata),
      .s0_axi4_rid         (hps2fpga_rid),
      .s0_axi4_rlast       (hps2fpga_rlast),
      .s0_axi4_rresp       (hps2fpga_rresp),
      .s0_axi4_rvalid      (hps2fpga_rvalid),
      // FB scanout
      .s1_axi4_awaddr,
      .s1_axi4_awburst,
      .s1_axi4_awid,
      .s1_axi4_awlen,
      .s1_axi4_awlock,
      .s1_axi4_awcache,
      .s1_axi4_awqos       (4'h0),
      .s1_axi4_awsize,
      .s1_axi4_awvalid,
      .s1_axi4_awprot,
      .s1_axi4_awready,
      .s1_axi4_araddr,
      .s1_axi4_arburst,
      .s1_axi4_arid,
      .s1_axi4_arlen,
      .s1_axi4_arlock,
      .s1_axi4_arcache,
      .s1_axi4_arqos       (4'h0),
      .s1_axi4_arsize,
      .s1_axi4_arvalid,
      .s1_axi4_arprot,
      .s1_axi4_arready,
      .s1_axi4_wdata,
      .s1_axi4_wstrb,
      .s1_axi4_wlast,
      .s1_axi4_wvalid,
      .s1_axi4_wready,
      .s1_axi4_bready,
      .s1_axi4_bid,
      .s1_axi4_bresp,
      .s1_axi4_bvalid,
      .s1_axi4_rready,
      .s1_axi4_rdata,
      .s1_axi4_rid,
      .s1_axi4_rlast,
      .s1_axi4_rresp,
      .s1_axi4_rvalid,
      // DMA
      .s2_axi4_awaddr,
      .s2_axi4_awburst,
      .s2_axi4_awid,
      .s2_axi4_awlen,
      .s2_axi4_awlock,
      .s2_axi4_awcache,
      .s2_axi4_awqos       (4'h0),
      .s2_axi4_awsize,
      .s2_axi4_awvalid,
      .s2_axi4_awprot,
      .s2_axi4_awready,
      .s2_axi4_araddr,
      .s2_axi4_arburst,
      .s2_axi4_arid,
      .s2_axi4_arlen,
      .s2_axi4_arlock,
      .s2_axi4_arcache,
      .s2_axi4_arqos       (4'h0),
      .s2_axi4_arsize,
      .s2_axi4_arvalid,
      .s2_axi4_arprot,
      .s2_axi4_arready,
      .s2_axi4_wdata,
      .s2_axi4_wstrb,
      .s2_axi4_wlast,
      .s2_axi4_wvalid,
      .s2_axi4_wready,
      .s2_axi4_bready,
      .s2_axi4_bid,
      .s2_axi4_bresp,
      .s2_axi4_bvalid,
      .s2_axi4_rready,
      .s2_axi4_rdata,
      .s2_axi4_rid,
      .s2_axi4_rlast,
      .s2_axi4_rresp,
      .s2_axi4_rvalid,
      //
      .s0_axi4lite_awaddr  (axil_driver_awaddr),
      .s0_axi4lite_awprot  (axil_driver_awprot),
      .s0_axi4lite_awvalid (axil_driver_awvalid),
      .s0_axi4lite_awready (axil_driver_awready),
      .s0_axi4lite_araddr  (axil_driver_araddr),
      .s0_axi4lite_arprot  (axil_driver_arprot),
      .s0_axi4lite_arvalid (axil_driver_arvalid),
      .s0_axi4lite_arready (axil_driver_arready),
      .s0_axi4lite_wdata   (axil_driver_wdata),
      .s0_axi4lite_wstrb   (axil_driver_wstrb),
      .s0_axi4lite_wvalid  (axil_driver_wvalid),
      .s0_axi4lite_wready  (axil_driver_wready),
      .s0_axi4lite_bready  (axil_driver_bready),
      .s0_axi4lite_bresp   (axil_driver_bresp),
      .s0_axi4lite_bvalid  (axil_driver_bvalid),
      .s0_axi4lite_rready  (axil_driver_rready),
      .s0_axi4lite_rdata   (axil_driver_rdata),
      .s0_axi4lite_rresp   (axil_driver_rresp),
      .s0_axi4lite_rvalid  (axil_driver_rvalid),
      //
      .mem_0_mem_cs            (LPDDR4B_CS_n),
      .mem_0_mem_ca            (LPDDR4B_CA),
      .mem_0_mem_cke           (LPDDR4B_CKE),
      .mem_0_mem_dq            (LPDDR4B_DQ),
      .mem_0_mem_dqs_t         (LPDDR4B_DQS),
      .mem_0_mem_dqs_c         (LPDDR4B_DQS_n),
      .mem_0_mem_dmi           (LPDDR4B_DM),
      .mem_ck_0_mem_ck_t       (LPDDR4B_CK),
      .mem_ck_0_mem_ck_c       (LPDDR4B_CK_n),
      .mem_reset_n_mem_reset_n (LPDDR4B_RESET_n),
      .oct_0_oct_rzqin         (LPDDR4B_RZQ),
      .ref_clk_clk             (LPDDR4B_REFCLK_p)
      );

   //
   // Framebuffer scanout engine (reads from VRAM)
   //

   wire                      axim_ven = vctrl_init_done & vctrl_ven;

   vctrl_axim #
     (.ADDR_WIDTH     (AXI_ADDR_W),
      .AXI_DATA_WIDTH (AXI_DATA_W),
      .FB_DATA_WIDTH  (VR_DATAW),
      .FB_ADDR_WIDTH  (VR_ADDRW),
      .ID_WIDTH       (AXI_ID_W),
      .BURST_LEN      (16), // DATA_WIDTH=256, BURST_LEN=16 -> 512Byte per burst
      .FIFO_LGDEPTH   (9))  // DATA_WIDTH=256, 512 entries -> 16KiB
   u_vctrl_axim
     (.clk           (clk_sys),
      .rst           (rst_sys),
      //
      .frame_sys,
      .fb_base,
      .fb_size,
      .ven           (axim_ven),
      .fetch_idle    (vctrl_fetch_idle),
      .fb_rdreq,
      .fb_raddr,
      .fb_rdack,
      .fb_rdata,
      .fb_rvalid,
      // AXI read master -> VRAM
      .m_axi_arid    (s1_axi4_arid),
      .m_axi_araddr  (s1_axi4_araddr),
      .m_axi_arlen   (s1_axi4_arlen),
      .m_axi_arsize  (s1_axi4_arsize),
      .m_axi_arburst (s1_axi4_arburst),
      .m_axi_arlock  (s1_axi4_arlock),
      .m_axi_arcache (s1_axi4_arcache),
      .m_axi_arprot  (s1_axi4_arprot),
      .m_axi_arvalid (s1_axi4_arvalid),
      .m_axi_arready (s1_axi4_arready),
      .m_axi_rid     (s1_axi4_rid),
      .m_axi_rdata   (s1_axi4_rdata),
      .m_axi_rresp   (s1_axi4_rresp),
      .m_axi_rlast   (s1_axi4_rlast),
      .m_axi_rvalid  (s1_axi4_rvalid),
      .m_axi_rready  (s1_axi4_rready)
      );

   //
   // DMA engine (reads from HPS, writes to VRAM)
   //

   vctrl_dma #
     (.ADDR_WIDTH     (AXI_ADDR_W),
      .AXI_DATA_WIDTH (AXI_DATA_W),
      .ID_WIDTH       (AXI_ID_W),
      .BURST_LEN      (16), // DATA_WIDTH=256, BURST_LEN=16 -> 512Byte per burst
      .FIFO_LGDEPTH   (9))  // DATA_WIDTH=256, 512 entries -> 16KiB
   u_vctrl_dma
     (.clk_sys,
      .rst_sys,
      .cmd_req,
      .cmd_adr,
      .cmd_we,
      .cmd_be,
      .cmd_d,
      .cmd_q,
      .cmd_ack,
      .irq           (vctrl_irq[1]),
      // AXI read master -> HPS
      .m_axi_arid    (s2_axi4_arid),
      .m_axi_araddr  (s2_axi4_araddr),
      .m_axi_arlen   (s2_axi4_arlen),
      .m_axi_arsize  (s2_axi4_arsize),
      .m_axi_arburst (s2_axi4_arburst),
      .m_axi_arlock  (s2_axi4_arlock),
      .m_axi_arcache (s2_axi4_arcache),
      .m_axi_arprot  (s2_axi4_arprot),
      .m_axi_arvalid (s2_axi4_arvalid),
      .m_axi_arready (s2_axi4_arready),
      .m_axi_rid     (s2_axi4_rid),
      .m_axi_rdata   (s2_axi4_rdata),
      .m_axi_rresp   (s2_axi4_rresp),
      .m_axi_rlast   (s2_axi4_rlast),
      .m_axi_rvalid  (s2_axi4_rvalid),
      .m_axi_rready  (s2_axi4_rready),
      // AXI write master -> VRAM
      .m_axi_awid    (s2_axi4_awid),
      .m_axi_awaddr  (s2_axi4_awaddr),
      .m_axi_awlen   (s2_axi4_awlen),
      .m_axi_awsize  (s2_axi4_awsize),
      .m_axi_awburst (s2_axi4_awburst),
      .m_axi_awlock  (s2_axi4_awlock),
      .m_axi_awcache (s2_axi4_awcache),
      .m_axi_awprot  (s2_axi4_awprot),
      .m_axi_awvalid (s2_axi4_awvalid),
      .m_axi_awready (s2_axi4_awready),
      .m_axi_wdata   (s2_axi4_wdata),
      .m_axi_wstrb   (s2_axi4_wstrb),
      .m_axi_wlast   (s2_axi4_wlast),
      .m_axi_wvalid  (s2_axi4_wvalid),
      .m_axi_wready  (s2_axi4_wready),
      .m_axi_bid     (s2_axi4_bid),
      .m_axi_bresp   (s2_axi4_bresp),
      .m_axi_bvalid  (s2_axi4_bvalid),
      .m_axi_bready  (s2_axi4_bready)
      );

endmodule // vctrl_wrapper
