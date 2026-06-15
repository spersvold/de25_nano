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
   parameter  int  AXI_ID_W   = 5,
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
   ,output logic         vctrl_irq         // Interrupt
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
   // ----------------------------------------------------------------------
   // AXI4 read master (write channel tied idle)
   // ----------------------------------------------------------------------
   // AR channel
   ,output axid_t        m_axi_arid
   ,output axaddr_t      m_axi_araddr
   ,output logic [7:0]   m_axi_arlen
   ,output logic [2:0]   m_axi_arsize
   ,output logic [1:0]   m_axi_arburst
   ,output logic         m_axi_arlock
   ,output logic [3:0]   m_axi_arcache
   ,output logic [2:0]   m_axi_arprot
   ,output logic         m_axi_arvalid
   ,input  logic         m_axi_arready
   // R channel
   ,input  axid_t        m_axi_rid
   ,input  axdata_t      m_axi_rdata
   ,input  logic [1:0]   m_axi_rresp
   ,input  logic         m_axi_rlast
   ,input  logic         m_axi_rvalid
   ,output logic         m_axi_rready
    //
   ,output axid_t        m_axi_awid
   ,output axaddr_t      m_axi_awaddr
   ,output logic [7:0]   m_axi_awlen
   ,output logic [2:0]   m_axi_awsize
   ,output logic [1:0]   m_axi_awburst
   ,output logic         m_axi_awlock
   ,output logic [3:0]   m_axi_awcache
   ,output logic [2:0]   m_axi_awprot
   ,output logic         m_axi_awvalid
   ,input  logic         m_axi_awready
   ,output axdata_t      m_axi_wdata
   ,output axstrb_t      m_axi_wstrb
   ,output logic         m_axi_wlast
   ,output logic         m_axi_wvalid
   ,input  logic         m_axi_wready
   ,input  axid_t        m_axi_bid
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

   // XXX: Tie-off DMA Command bus
   logic                     cmd_ack_r;
   always_ff @(posedge clk_sys) begin
      cmd_ack_r <= cmd_req;
   end
   assign cmd_ack = cmd_ack_r;
   assign cmd_q = '0;

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
      .irq        (vctrl_irq),
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

   wire [31:0]               fb_base = {vctrl_vbar, 2'b00};
   wire [31:0]               fb_size = {vctrl_vsiz, 2'b00};

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
      .ven           (vctrl_ven),
      .fetch_idle    (vctrl_fetch_idle),
      .fb_rdreq,
      .fb_raddr,
      .fb_rdack,
      .fb_rdata,
      .fb_rvalid,
      //
      .m_axi_arid,
      .m_axi_araddr,
      .m_axi_arlen,
      .m_axi_arsize,
      .m_axi_arburst,
      .m_axi_arlock,
      .m_axi_arcache,
      .m_axi_arprot,
      .m_axi_arvalid,
      .m_axi_arready,
      .m_axi_rid,
      .m_axi_rdata,
      .m_axi_rresp,
      .m_axi_rlast,
      .m_axi_rvalid,
      .m_axi_rready,
      .m_axi_awid,
      .m_axi_awaddr,
      .m_axi_awlen,
      .m_axi_awsize,
      .m_axi_awburst,
      .m_axi_awlock,
      .m_axi_awcache,
      .m_axi_awprot,
      .m_axi_awvalid,
      .m_axi_awready,
      .m_axi_wdata,
      .m_axi_wstrb,
      .m_axi_wlast,
      .m_axi_wvalid,
      .m_axi_wready,
      .m_axi_bid,
      .m_axi_bresp,
      .m_axi_bvalid,
      .m_axi_bready
      );

endmodule // vctrl_wrapper
