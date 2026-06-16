// -*- mode: verilog; mode: font-lock; indent-tabs-mode: nil -*-
// vi: set et ts=3 sw=3 sts=3:
//
// Copyright 2026 Steffen Persvold
// SPDX-License-Identifier: Apache-2.0
//
// ========================================================================
// File        : quartus_sim_stubs.sv
// Author      : Steffen Persvold (spersvold@gmail.com)
// Created     : May 25, 2026
// ========================================================================
// Description : Verilator-only stub library for the small set of Quartus
//               sim_lib primitives and qsys-generated IPs that the
//               de25_nano build actually instantiates.
//
// Why this exists:
//   The real Quartus eda/sim_lib files plus the qsys-generated IP
//   simulation models (encrypted *.vo blobs, vendor 'protect blocks,
//   specify blocks, attribute pragmas) are unparseable for the
//   open-source flow even though VCS accepts them. The set of
//   primitives our RTL directly touches is tiny -- DDIO output, I/O
//   buffers, a pseudo-differential output, two IOPLL wrappers, and
//   reset_release -- so a tiny self-contained stub file is cheap.
//
// Scope:
//   - Functional behaviour only. No timing accuracy, no PLL phase
//     relationships, no SI/SSO modelling. Sufficient for bring-up
//     traffic (SDRAM transactions, QSPI boot, HDMI pixel stream,
//     SoC top wiring); insufficient for anything that depends on
//     real clock-to-clock phase or pad timing.
//   - Parameters from the real cells are declared and ignored. Only
//     the parameters that affect functional behaviour are honoured
//     (PLL frequencies on the IOPLL wrappers).
//   - Modules are shared across both FPGA boards via a relative path
//     from each verif/ env's flist (cf. mbox_client_sim.sv).
//
// ========================================================================

// The real Quartus cells default many of their ports; our consumers
// only wire the few that matter (e.g. DDIO_OUT just uses clk + the
// two data lanes).

// ====================================================================
// tennm_ph2_ddio_out -- DDR output register
//
// Both halves are captured on the SAME posedge clk into internal
// flops; the output then muxes between them based on the live clk
// phase (high half = reg_hi, low half = reg_lo). This matches the
// ODDR-style behaviour of the real cell and is what callers expect:
//
//   - Address/command path (datainhi == datainlo, both tied to an
//     upstream posedge-clk flop): output presents the latched value
//     for the full clk period, transitioning at posedge -- i.e. one
//     cycle of latency, like a plain D-FF. Sampling datainlo on
//     negedge instead would pick up the post-posedge (NBA-fired)
//     value of the upstream flop and shift the output transition by
//     half a clk period, which is wrong.
//
//   - DRAM_CLK path (datainhi=0, datainlo=1): output is in phase
//     with clk (same-frequency clock, NOT inverted). This matches
//     the real cell's convention -- datainlo is presented during
//     the clk-high half, datainhi during the clk-low half.
// ====================================================================

module tennm_ph2_ddio_out
  (
   input  wire areset,
   input  wire sreset,
   input  wire ena,
   input  wire clk,
   input  wire datainlo,
   input  wire datainhi,
   output wire dataout
   );

   parameter mode      = "MODE_DDR";
   parameter asclr_ena = "ASCLR_ENA_NONE";
   parameter sclr_ena  = "SCLR_ENA_NONE";

   reg reg_hi = 1'b0;
   reg reg_lo = 1'b0;

   always @(posedge clk) begin
      reg_hi <= datainhi;
      reg_lo <= datainlo;
   end

   // datainlo is presented while clk is HIGH, datainhi while clk is
   // LOW -- this is the real cell's convention, opposite to what the
   // port names suggest. Matters for DRAM_CLK generation: with
   // datainhi=0/datainlo=1, output tracks clk in phase (rising edge
   // 1/4 cycle after the command transition, center-aligned), not
   // inverted. For datainhi==datainlo the choice has no effect.
   assign dataout = clk ? reg_lo : reg_hi;

endmodule

// ====================================================================
// reset_release -- qsys IP wrapper; just drives ninit_done low (=done)
//
// In silicon, ninit_done is asserted while the device is still
// initialising from POR; the real IP gates this on the SDM
// completion. In sim we declare init complete from time 0.
// ====================================================================

module reset_release
  (
   output wire ninit_done
   );

   assign ninit_done = 1'b0;

endmodule

// ====================================================================
// core_pll -- qsys IOPLL wrapper, single output
// ====================================================================

module core_pll
  (
   input  wire refclk,
   output wire locked,
   input  wire rst,
   output wire clk_sys
   );

   parameter real CLK_SYS_HZ  = 250_000_000.0;
   parameter real LOCK_TIME_NS = 1000.0;

   localparam real CLK_SYS_HALF_NS = 0.5e9 / CLK_SYS_HZ;

   logic clk_sys_r    = 1'b0;
   logic locked_r     = 1'b0;

   always #(CLK_SYS_HALF_NS) clk_sys_r    = ~clk_sys_r;

   always @(rst) begin
      if (rst) locked_r <= 1'b0;
      else begin
         #(LOCK_TIME_NS) locked_r <= 1'b1;
      end
   end

   assign clk_sys    = rst ? 1'b0 : clk_sys_r;
   assign locked     = locked_r;

endmodule

// ====================================================================
// hdmi_pll -- qsys IOPLL wrapper, single output (de25_nano HDMI)
// ====================================================================

module hdmi_pll
  (
   input  wire        refclk,
   output wire        locked,
   input  wire        rst,
   output wire        clk_pix,
   // dynamic reconfiguration (HVIO core_avl) -- behavioral lock model only
   input  wire        core_avl_clk,
   input  wire [8:0]  core_avl_address,
   input  wire        core_avl_read,
   output wire [7:0]  core_avl_readdata,
   input  wire        core_avl_write,
   input  wire [7:0]  core_avl_writedata
   );

   parameter real CLK_PIX_HZ = 148_500_000.0;
   parameter real LOCK_TIME_NS = 1000.0;
   // recalibration relock latency, in core_avl_clk cycles
   parameter int  RECAL_CYCLES = 64;

   localparam real CLK_PIX_HALF_NS = 0.5e9 / CLK_PIX_HZ;

   logic clk_pix_r = 1'b0;
   logic locked_r  = 1'b0;

   always #(CLK_PIX_HALF_NS) clk_pix_r = ~clk_pix_r;

   always @(rst) begin
      if (rst) locked_r <= 1'b0;
      else begin
         #(LOCK_TIME_NS) locked_r <= 1'b1;
      end
   end

   // Behavioral reconfiguration lock model: a recal request (write to 0x88)
   // drops lock for RECAL_CYCLES then re-asserts. This is NOT a faithful AVL
   // model (the byte-burst protocol/timing is only validated in hardware) --
   // it exists so hdmi_pll_recfg's wait-for-lock and done handshake can be
   // exercised end-to-end. clk_pix stays at the fixed default rate.
   logic [15:0] recal_cnt = '0;
   logic        recal_busy = 1'b0;
   always @(posedge core_avl_clk or posedge rst) begin
      if (rst) begin
         recal_busy <= 1'b0;
         recal_cnt  <= '0;
      end else if (core_avl_write && core_avl_address == 9'h088) begin
         recal_busy <= 1'b1;
         recal_cnt  <= 16'(RECAL_CYCLES);
      end else if (recal_busy) begin
         if (recal_cnt != 0) recal_cnt <= recal_cnt - 16'd1;
         else                recal_busy <= 1'b0;
      end
   end

   assign clk_pix          = rst ? 1'b0 : clk_pix_r;
   assign locked           = locked_r & ~recal_busy;
   assign core_avl_readdata = 8'h00;

endmodule

// ====================================================================
// agilex_hps -- HPS black box
// ====================================================================

module agilex_hps (
		output wire         h2f_reset_reset,
`ifdef ENABLE_HPS2FPGA
		input  wire         hps2fpga_axi_clock_clk,
		input  wire         hps2fpga_axi_reset_reset,
		output wire [3:0]   hps2fpga_awid,
		output wire [31:0]  hps2fpga_awaddr,
		output wire [7:0]   hps2fpga_awlen,
		output wire [2:0]   hps2fpga_awsize,
		output wire [1:0]   hps2fpga_awburst,
		output wire         hps2fpga_awlock,
		output wire [3:0]   hps2fpga_awcache,
		output wire [2:0]   hps2fpga_awprot,
		output wire         hps2fpga_awvalid,
		input  wire         hps2fpga_awready,
		output wire [127:0] hps2fpga_wdata,
		output wire [15:0]  hps2fpga_wstrb,
		output wire         hps2fpga_wlast,
		output wire         hps2fpga_wvalid,
		input  wire         hps2fpga_wready,
		input  wire [3:0]   hps2fpga_bid,
		input  wire [1:0]   hps2fpga_bresp,
		input  wire         hps2fpga_bvalid,
		output wire         hps2fpga_bready,
		output wire [3:0]   hps2fpga_arid,
		output wire [31:0]  hps2fpga_araddr,
		output wire [7:0]   hps2fpga_arlen,
		output wire [2:0]   hps2fpga_arsize,
		output wire [1:0]   hps2fpga_arburst,
		output wire         hps2fpga_arlock,
		output wire [3:0]   hps2fpga_arcache,
		output wire [2:0]   hps2fpga_arprot,
		output wire         hps2fpga_arvalid,
		input  wire         hps2fpga_arready,
		input  wire [3:0]   hps2fpga_rid,
		input  wire [127:0] hps2fpga_rdata,
		input  wire [1:0]   hps2fpga_rresp,
		input  wire         hps2fpga_rlast,
		input  wire         hps2fpga_rvalid,
		output wire         hps2fpga_rready,
`endif
		input  wire         lwhps2fpga_axi_clock_clk,
		input  wire         lwhps2fpga_axi_reset_reset,
		output wire [3:0]   lwhps2fpga_awid,
		output wire [28:0]  lwhps2fpga_awaddr,
		output wire [7:0]   lwhps2fpga_awlen,
		output wire [2:0]   lwhps2fpga_awsize,
		output wire [1:0]   lwhps2fpga_awburst,
		output wire         lwhps2fpga_awlock,
		output wire [3:0]   lwhps2fpga_awcache,
		output wire [2:0]   lwhps2fpga_awprot,
		output wire         lwhps2fpga_awvalid,
		input  wire         lwhps2fpga_awready,
		output wire [31:0]  lwhps2fpga_wdata,
		output wire [3:0]   lwhps2fpga_wstrb,
		output wire         lwhps2fpga_wlast,
		output wire         lwhps2fpga_wvalid,
		input  wire         lwhps2fpga_wready,
		input  wire [3:0]   lwhps2fpga_bid,
		input  wire [1:0]   lwhps2fpga_bresp,
		input  wire         lwhps2fpga_bvalid,
		output wire         lwhps2fpga_bready,
		output wire [3:0]   lwhps2fpga_arid,
		output wire [28:0]  lwhps2fpga_araddr,
		output wire [7:0]   lwhps2fpga_arlen,
		output wire [2:0]   lwhps2fpga_arsize,
		output wire [1:0]   lwhps2fpga_arburst,
		output wire         lwhps2fpga_arlock,
		output wire [3:0]   lwhps2fpga_arcache,
		output wire [2:0]   lwhps2fpga_arprot,
		output wire         lwhps2fpga_arvalid,
		input  wire         lwhps2fpga_arready,
		input  wire [3:0]   lwhps2fpga_rid,
		input  wire [31:0]  lwhps2fpga_rdata,
		input  wire [1:0]   lwhps2fpga_rresp,
		input  wire         lwhps2fpga_rlast,
		input  wire         lwhps2fpga_rvalid,
		output wire         lwhps2fpga_rready,
		output wire         emac0_app_rst_reset_n,
		output wire         h2f_warm_reset_handshake_reset_req,
		input  wire         h2f_warm_reset_handshake_reset_ack,
		input  wire         hps_io_hps_osc_clk,
		inout  wire         hps_io_sdmmc_data0,
		inout  wire         hps_io_sdmmc_data1,
		output wire         hps_io_sdmmc_cclk,
		inout  wire         hps_io_sdmmc_data2,
		inout  wire         hps_io_sdmmc_data3,
		inout  wire         hps_io_sdmmc_cmd,
		input  wire         hps_io_usb0_clk,
		output wire         hps_io_usb0_stp,
		input  wire         hps_io_usb0_dir,
		inout  wire         hps_io_usb0_data0,
		inout  wire         hps_io_usb0_data1,
		input  wire         hps_io_usb0_nxt,
		inout  wire         hps_io_usb0_data2,
		inout  wire         hps_io_usb0_data3,
		inout  wire         hps_io_usb0_data4,
		inout  wire         hps_io_usb0_data5,
		inout  wire         hps_io_usb0_data6,
		inout  wire         hps_io_usb0_data7,
		output wire         hps_io_emac0_tx_clk,
		output wire         hps_io_emac0_tx_ctl,
		input  wire         hps_io_emac0_rx_clk,
		input  wire         hps_io_emac0_rx_ctl,
		output wire         hps_io_emac0_txd0,
		output wire         hps_io_emac0_txd1,
		input  wire         hps_io_emac0_rxd0,
		input  wire         hps_io_emac0_rxd1,
		output wire         hps_io_emac0_txd2,
		output wire         hps_io_emac0_txd3,
		input  wire         hps_io_emac0_rxd2,
		input  wire         hps_io_emac0_rxd3,
		inout  wire         hps_io_mdio0_mdio,
		output wire         hps_io_mdio0_mdc,
		output wire         hps_io_uart1_tx,
		input  wire         hps_io_uart1_rx,
		inout  wire         hps_io_i2c1_sda,
		inout  wire         hps_io_i2c1_scl,
		inout  wire         hps_io_gpio28,
		inout  wire         hps_io_gpio34,
		inout  wire         hps_io_gpio40,
		inout  wire         hps_io_gpio41,
		input  wire [31:0]  fpga2hps_interrupt_irq1_irq,
		input  wire [31:0]  fpga2hps_interrupt_irq0_irq,
`ifdef ENABLE_FPGA2SDRAM
		input  wire         f2sdram_axi_clock_clk,
		input  wire         f2sdram_axi_reset_reset,
		input  wire [31:0]  f2sdram_araddr,
		input  wire [1:0]   f2sdram_arburst,
		input  wire [3:0]   f2sdram_arcache,
		input  wire [4:0]   f2sdram_arid,
		input  wire [7:0]   f2sdram_arlen,
		input  wire         f2sdram_arlock,
		input  wire [2:0]   f2sdram_arprot,
		input  wire [3:0]   f2sdram_arqos,
		output wire         f2sdram_arready,
		input  wire [2:0]   f2sdram_arsize,
		input  wire         f2sdram_arvalid,
		input  wire [31:0]  f2sdram_awaddr,
		input  wire [1:0]   f2sdram_awburst,
		input  wire [3:0]   f2sdram_awcache,
		input  wire [4:0]   f2sdram_awid,
		input  wire [7:0]   f2sdram_awlen,
		input  wire         f2sdram_awlock,
		input  wire [2:0]   f2sdram_awprot,
		input  wire [3:0]   f2sdram_awqos,
		output wire         f2sdram_awready,
		input  wire [2:0]   f2sdram_awsize,
		input  wire         f2sdram_awvalid,
		output wire [4:0]   f2sdram_bid,
		input  wire         f2sdram_bready,
		output wire [1:0]   f2sdram_bresp,
		output wire         f2sdram_bvalid,
		output wire [255:0] f2sdram_rdata,
		output wire [4:0]   f2sdram_rid,
		output wire         f2sdram_rlast,
		input  wire         f2sdram_rready,
		output wire [1:0]   f2sdram_rresp,
		output wire         f2sdram_rvalid,
		input  wire [255:0] f2sdram_wdata,
		input  wire         f2sdram_wlast,
		output wire         f2sdram_wready,
		input  wire [31:0]  f2sdram_wstrb,
		input  wire         f2sdram_wvalid,
		input  wire [24:0]  f2sdram_aruser,
		input  wire [24:0]  f2sdram_awuser,
		input  wire [7:0]   f2sdram_wuser,
		output wire [7:0]   f2sdram_buser,
		input  wire [3:0]   f2sdram_arregion,
		output wire [7:0]   f2sdram_ruser,
		input  wire [3:0]   f2sdram_awregion,
`endif
`ifdef ENABLE_FPGA2HPS
		input  wire         fpga2hps_clock_clk,
		input  wire         fpga2hps_reset_reset,
		input  wire [4:0]   fpga2hps_awid,
		input  wire [31:0]  fpga2hps_awaddr,
		input  wire [1:0]   fpga2hps_awdomain,
		input  wire [3:0]   fpga2hps_awsnoop,
		input  wire [7:0]   fpga2hps_awlen,
		input  wire [2:0]   fpga2hps_awsize,
		input  wire [2:0]   fpga2hps_arsize,
		input  wire [1:0]   fpga2hps_awburst,
		input  wire         fpga2hps_awlock,
		input  wire [3:0]   fpga2hps_awcache,
		input  wire [2:0]   fpga2hps_awprot,
		input  wire [3:0]   fpga2hps_awqos,
		input  wire         fpga2hps_awvalid,
		output wire         fpga2hps_awready,
		input  wire [255:0] fpga2hps_wdata,
		input  wire [31:0]  fpga2hps_wstrb,
		input  wire         fpga2hps_wlast,
		input  wire         fpga2hps_wvalid,
		output wire         fpga2hps_wready,
		input  wire [10:0]  fpga2hps_awstashnid,
		input  wire         fpga2hps_awstashniden,
		input  wire [4:0]   fpga2hps_awstashlpid,
		input  wire         fpga2hps_awstashlpiden,
		input  wire [5:0]   fpga2hps_awatop,
		output wire [4:0]   fpga2hps_bid,
		output wire [1:0]   fpga2hps_bresp,
		output wire         fpga2hps_bvalid,
		input  wire         fpga2hps_bready,
		input  wire [4:0]   fpga2hps_arid,
		input  wire [31:0]  fpga2hps_araddr,
		input  wire [1:0]   fpga2hps_ardomain,
		input  wire [3:0]   fpga2hps_arsnoop,
		input  wire [7:0]   fpga2hps_arlen,
		input  wire [1:0]   fpga2hps_arburst,
		input  wire         fpga2hps_arlock,
		input  wire [3:0]   fpga2hps_arcache,
		input  wire [2:0]   fpga2hps_arprot,
		input  wire [3:0]   fpga2hps_arqos,
		input  wire         fpga2hps_arvalid,
		output wire         fpga2hps_arready,
		output wire [4:0]   fpga2hps_rid,
		output wire [255:0] fpga2hps_rdata,
		output wire [1:0]   fpga2hps_rresp,
		output wire         fpga2hps_rlast,
		output wire         fpga2hps_rvalid,
		input  wire         fpga2hps_rready,
		input  wire [7:0]   fpga2hps_aruser,
		input  wire         fpga2hps_armmusecsid,
		input  wire [15:0]  fpga2hps_armmusid,
		input  wire [7:0]   fpga2hps_awuser,
		input  wire         fpga2hps_awmmusecsid,
		input  wire [15:0]  fpga2hps_awmmusid,
		input  wire [3:0]   fpga2hps_arregion,
		input  wire [3:0]   fpga2hps_awregion,
		input  wire [7:0]   fpga2hps_wuser,
		output wire [7:0]   fpga2hps_buser,
		output wire [7:0]   fpga2hps_ruser,
`endif
		input  wire         io96b0_to_hps_ch0_axil_clk,
		input  wire         io96b0_to_hps_ch0_axil_reset_n,
		input  wire         io96b0_to_hps_ch0_axil_arready,
		input  wire         io96b0_to_hps_ch0_axil_awready,
		input  wire [1:0]   io96b0_to_hps_ch0_axil_bresp,
		input  wire         io96b0_to_hps_ch0_axil_bvalid,
		input  wire [31:0]  io96b0_to_hps_ch0_axil_rdata,
		input  wire [1:0]   io96b0_to_hps_ch0_axil_rresp,
		input  wire         io96b0_to_hps_ch0_axil_rvalid,
		input  wire         io96b0_to_hps_ch0_axil_wready,
		output wire [26:0]  io96b0_to_hps_ch0_axil_araddr,
		output wire         io96b0_to_hps_ch0_axil_arvalid,
		output wire [26:0]  io96b0_to_hps_ch0_axil_awaddr,
		output wire         io96b0_to_hps_ch0_axil_awvalid,
		output wire         io96b0_to_hps_ch0_axil_bready,
		output wire         io96b0_to_hps_ch0_axil_rready,
		output wire [31:0]  io96b0_to_hps_ch0_axil_wdata,
		output wire [3:0]   io96b0_to_hps_ch0_axil_wstrb,
		output wire         io96b0_to_hps_ch0_axil_wvalid,
		output wire [2:0]   io96b0_to_hps_ch0_axil_arprot,
		output wire [2:0]   io96b0_to_hps_ch0_axil_awprot,
		input  wire         io96b0_to_hps_axi4_ch0_clk,
		input  wire         io96b0_to_hps_axi4_ch0_reset_n,
		input  wire         io96b0_to_hps_axi4_ch0_arready,
		input  wire         io96b0_to_hps_axi4_ch0_awready,
		input  wire [6:0]   io96b0_to_hps_axi4_ch0_bid,
		input  wire [1:0]   io96b0_to_hps_axi4_ch0_bresp,
		input  wire         io96b0_to_hps_axi4_ch0_bvalid,
		input  wire [255:0] io96b0_to_hps_axi4_ch0_rdata,
		input  wire [6:0]   io96b0_to_hps_axi4_ch0_rid,
		input  wire         io96b0_to_hps_axi4_ch0_rlast,
		input  wire [1:0]   io96b0_to_hps_axi4_ch0_rresp,
		input  wire [31:0]  io96b0_to_hps_axi4_ch0_ruser,
		input  wire         io96b0_to_hps_axi4_ch0_rvalid,
		input  wire         io96b0_to_hps_axi4_ch0_wready,
		output wire [39:0]  io96b0_to_hps_axi4_ch0_araddr,
		output wire [1:0]   io96b0_to_hps_axi4_ch0_arburst,
		output wire [6:0]   io96b0_to_hps_axi4_ch0_arid,
		output wire [7:0]   io96b0_to_hps_axi4_ch0_arlen,
		output wire         io96b0_to_hps_axi4_ch0_arlock,
		output wire [3:0]   io96b0_to_hps_axi4_ch0_arqos,
		output wire [2:0]   io96b0_to_hps_axi4_ch0_arsize,
		output wire [13:0]  io96b0_to_hps_axi4_ch0_aruser,
		output wire         io96b0_to_hps_axi4_ch0_arvalid,
		output wire [39:0]  io96b0_to_hps_axi4_ch0_awaddr,
		output wire [1:0]   io96b0_to_hps_axi4_ch0_awburst,
		output wire [6:0]   io96b0_to_hps_axi4_ch0_awid,
		output wire [7:0]   io96b0_to_hps_axi4_ch0_awlen,
		output wire         io96b0_to_hps_axi4_ch0_awlock,
		output wire [3:0]   io96b0_to_hps_axi4_ch0_awqos,
		output wire [2:0]   io96b0_to_hps_axi4_ch0_awsize,
		output wire [13:0]  io96b0_to_hps_axi4_ch0_awuser,
		output wire         io96b0_to_hps_axi4_ch0_awvalid,
		output wire         io96b0_to_hps_axi4_ch0_bready,
		output wire         io96b0_to_hps_axi4_ch0_rready,
		output wire [255:0] io96b0_to_hps_axi4_ch0_wdata,
		output wire         io96b0_to_hps_axi4_ch0_wlast,
		output wire [31:0]  io96b0_to_hps_axi4_ch0_wstrb,
		output wire [31:0]  io96b0_to_hps_axi4_ch0_wuser,
		output wire         io96b0_to_hps_axi4_ch0_wvalid,
		output wire [2:0]   io96b0_to_hps_axi4_ch0_arprot,
		output wire [2:0]   io96b0_to_hps_axi4_ch0_awprot
	);

   assign h2f_reset_reset = 1'b0;
   assign h2f_warm_reset_handshake_reset_req = 1'b1;

endmodule


module emif_io96b_hps (
		output wire         s0_noc_axi4lite_clock,
		output wire         s0_noc_axi4lite_reset_n,
		input  wire [26:0]  s0_noc_axi4lite_awaddr,
		input  wire         s0_noc_axi4lite_awvalid,
		output wire         s0_noc_axi4lite_awready,
		input  wire [26:0]  s0_noc_axi4lite_araddr,
		input  wire         s0_noc_axi4lite_arvalid,
		output wire         s0_noc_axi4lite_arready,
		input  wire [31:0]  s0_noc_axi4lite_wdata,
		input  wire         s0_noc_axi4lite_wvalid,
		output wire         s0_noc_axi4lite_wready,
		output wire [1:0]   s0_noc_axi4lite_rresp,
		output wire [31:0]  s0_noc_axi4lite_rdata,
		output wire         s0_noc_axi4lite_rvalid,
		input  wire         s0_noc_axi4lite_rready,
		output wire [1:0]   s0_noc_axi4lite_bresp,
		output wire         s0_noc_axi4lite_bvalid,
		input  wire         s0_noc_axi4lite_bready,
		input  wire [2:0]   s0_noc_axi4lite_awprot,
		input  wire [2:0]   s0_noc_axi4lite_arprot,
		input  wire [3:0]   s0_noc_axi4lite_wstrb,
		input  wire [39:0]  s0_axi4_awaddr,
		input  wire [1:0]   s0_axi4_awburst,
		input  wire [6:0]   s0_axi4_awid,
		input  wire [7:0]   s0_axi4_awlen,
		input  wire         s0_axi4_awlock,
		input  wire [3:0]   s0_axi4_awqos,
		input  wire [2:0]   s0_axi4_awsize,
		input  wire         s0_axi4_awvalid,
		input  wire [13:0]  s0_axi4_awuser,
		input  wire [2:0]   s0_axi4_awprot,
		output wire         s0_axi4_awready,
		input  wire [39:0]  s0_axi4_araddr,
		input  wire [1:0]   s0_axi4_arburst,
		input  wire [6:0]   s0_axi4_arid,
		input  wire [7:0]   s0_axi4_arlen,
		input  wire         s0_axi4_arlock,
		input  wire [3:0]   s0_axi4_arqos,
		input  wire [2:0]   s0_axi4_arsize,
		input  wire         s0_axi4_arvalid,
		input  wire [13:0]  s0_axi4_aruser,
		input  wire [2:0]   s0_axi4_arprot,
		output wire         s0_axi4_arready,
		input  wire [255:0] s0_axi4_wdata,
		input  wire [31:0]  s0_axi4_wstrb,
		input  wire         s0_axi4_wlast,
		input  wire         s0_axi4_wvalid,
		output wire         s0_axi4_wready,
		input  wire         s0_axi4_bready,
		output wire [6:0]   s0_axi4_bid,
		output wire [1:0]   s0_axi4_bresp,
		output wire         s0_axi4_bvalid,
		input  wire         s0_axi4_rready,
		output wire [255:0] s0_axi4_rdata,
		output wire [6:0]   s0_axi4_rid,
		output wire         s0_axi4_rlast,
		output wire [1:0]   s0_axi4_rresp,
		output wire         s0_axi4_rvalid,
		output wire         noc_aclk_0,
		output wire         noc_rst_n_0,
		input  wire [31:0]  s0_axi4_wuser,
		output wire [31:0]  s0_axi4_ruser,
		output wire [0:0]   mem_0_cs,
		output wire [5:0]   mem_0_ca,
		output wire [0:0]   mem_0_cke,
		inout  wire [31:0]  mem_0_dq,
		inout  wire [3:0]   mem_0_dqs_t,
		inout  wire [3:0]   mem_0_dqs_c,
		inout  wire [3:0]   mem_0_dmi,
		output wire [0:0]   mem_0_ck_t,
		output wire [0:0]   mem_0_ck_c,
		output wire         mem_0_reset_n,
		input  wire         oct_rzqin_0,
		input  wire         ref_clk
	);
endmodule

module ace5_translate #(
		parameter WSTRB_WIDTH = 32,
		parameter USER_WIDTH  = 8
	) (
		input  wire         clk,
		input  wire         reset,
		output wire [4:0]   m_ace5lite_awid,
		output wire [31:0]  m_ace5lite_awaddr,
		output wire [1:0]   m_ace5lite_awdomain,
		output wire [3:0]   m_ace5lite_awsnoop,
		output wire [7:0]   m_ace5lite_awlen,
		output wire [2:0]   m_ace5lite_awsize,
		output wire [1:0]   m_ace5lite_awburst,
		output wire         m_ace5lite_awlock,
		output wire [3:0]   m_ace5lite_awcache,
		output wire [2:0]   m_ace5lite_awprot,
		output wire [3:0]   m_ace5lite_awqos,
		output wire [3:0]   m_ace5lite_awregion,
		output wire [10:0]  m_ace5lite_awstashnid,
		output wire         m_ace5lite_awstashniden,
		output wire [4:0]   m_ace5lite_awstashlpid,
		output wire         m_ace5lite_awstashlpiden,
		output wire [5:0]   m_ace5lite_awatop,
		output wire [7:0]   m_ace5lite_awuser,
		output wire         m_ace5lite_awvalid,
		input  wire         m_ace5lite_awready,
		output wire [255:0] m_ace5lite_wdata,
		output wire [31:0]  m_ace5lite_wstrb,
		output wire         m_ace5lite_wlast,
		output wire [7:0]   m_ace5lite_wuser,
		output wire         m_ace5lite_wvalid,
		input  wire         m_ace5lite_wready,
		input  wire [4:0]   m_ace5lite_bid,
		input  wire [1:0]   m_ace5lite_bresp,
		input  wire [7:0]   m_ace5lite_buser,
		input  wire         m_ace5lite_bvalid,
		output wire         m_ace5lite_bready,
		output wire [4:0]   m_ace5lite_arid,
		output wire [31:0]  m_ace5lite_araddr,
		output wire [1:0]   m_ace5lite_ardomain,
		output wire [3:0]   m_ace5lite_arsnoop,
		output wire [7:0]   m_ace5lite_arlen,
		output wire [2:0]   m_ace5lite_arsize,
		output wire [1:0]   m_ace5lite_arburst,
		output wire         m_ace5lite_arlock,
		output wire [3:0]   m_ace5lite_arcache,
		output wire [2:0]   m_ace5lite_arprot,
		output wire [3:0]   m_ace5lite_arqos,
		output wire [3:0]   m_ace5lite_arregion,
		output wire [7:0]   m_ace5lite_aruser,
		output wire         m_ace5lite_arvalid,
		input  wire         m_ace5lite_arready,
		input  wire [4:0]   m_ace5lite_rid,
		input  wire [255:0] m_ace5lite_rdata,
		input  wire [1:0]   m_ace5lite_rresp,
		input  wire         m_ace5lite_rlast,
		input  wire         m_ace5lite_rvalid,
		output wire         m_ace5lite_rready,
		input  wire [7:0]   m_ace5lite_ruser,
		input  wire [4:0]   s_axi_awid,
		input  wire [31:0]  s_axi_awaddr,
		input  wire [7:0]   s_axi_awlen,
		input  wire [2:0]   s_axi_awsize,
		input  wire [1:0]   s_axi_awburst,
		input  wire         s_axi_awlock,
		input  wire [3:0]   s_axi_awcache,
		input  wire [2:0]   s_axi_awprot,
		input  wire [3:0]   s_axi_awqos,
		input  wire         s_axi_awvalid,
		output wire         s_axi_awready,
		input  wire [3:0]   s_axi_awregion,
		input  wire [255:0] s_axi_wdata,
		input  wire [31:0]  s_axi_wstrb,
		input  wire         s_axi_wlast,
		input  wire         s_axi_wvalid,
		output wire         s_axi_wready,
		input  wire [7:0]   s_axi_wuser,
		output wire [4:0]   s_axi_bid,
		output wire [1:0]   s_axi_bresp,
		output wire         s_axi_bvalid,
		input  wire         s_axi_bready,
		output wire [7:0]   s_axi_buser,
		input  wire [4:0]   s_axi_arid,
		input  wire [31:0]  s_axi_araddr,
		input  wire [7:0]   s_axi_arlen,
		input  wire [2:0]   s_axi_arsize,
		input  wire [1:0]   s_axi_arburst,
		input  wire         s_axi_arlock,
		input  wire [3:0]   s_axi_arcache,
		input  wire [2:0]   s_axi_arprot,
		input  wire [3:0]   s_axi_arqos,
		input  wire         s_axi_arvalid,
		output wire         s_axi_arready,
		input  wire [3:0]   s_axi_arregion,
		output wire [4:0]   s_axi_rid,
		output wire [255:0] s_axi_rdata,
		output wire [1:0]   s_axi_rresp,
		output wire         s_axi_rlast,
		output wire         s_axi_rvalid,
		input  wire         s_axi_rready,
		output wire [7:0]   s_axi_ruser
	);
endmodule

module lpddr4b_vram (
		input  wire [3:0]   s0_axi4_awid,            //     s0_axi4.awid
		input  wire [31:0]  s0_axi4_awaddr,          //            .awaddr
		input  wire [7:0]   s0_axi4_awlen,           //            .awlen
		input  wire [2:0]   s0_axi4_awsize,          //            .awsize
		input  wire [1:0]   s0_axi4_awburst,         //            .awburst
		input  wire [0:0]   s0_axi4_awlock,          //            .awlock
		input  wire [3:0]   s0_axi4_awcache,         //            .awcache
		input  wire [2:0]   s0_axi4_awprot,          //            .awprot
		input  wire [3:0]   s0_axi4_awqos,           //            .awqos
		input  wire         s0_axi4_awvalid,         //            .awvalid
		output wire         s0_axi4_awready,         //            .awready
		input  wire [127:0] s0_axi4_wdata,           //            .wdata
		input  wire [15:0]  s0_axi4_wstrb,           //            .wstrb
		input  wire         s0_axi4_wlast,           //            .wlast
		input  wire         s0_axi4_wvalid,          //            .wvalid
		output wire         s0_axi4_wready,          //            .wready
		output wire [3:0]   s0_axi4_bid,             //            .bid
		output wire [1:0]   s0_axi4_bresp,           //            .bresp
		output wire         s0_axi4_bvalid,          //            .bvalid
		input  wire         s0_axi4_bready,          //            .bready
		input  wire [3:0]   s0_axi4_arid,            //            .arid
		input  wire [31:0]  s0_axi4_araddr,          //            .araddr
		input  wire [7:0]   s0_axi4_arlen,           //            .arlen
		input  wire [2:0]   s0_axi4_arsize,          //            .arsize
		input  wire [1:0]   s0_axi4_arburst,         //            .arburst
		input  wire [0:0]   s0_axi4_arlock,          //            .arlock
		input  wire [3:0]   s0_axi4_arcache,         //            .arcache
		input  wire [2:0]   s0_axi4_arprot,          //            .arprot
		input  wire [3:0]   s0_axi4_arqos,           //            .arqos
		input  wire         s0_axi4_arvalid,         //            .arvalid
		output wire         s0_axi4_arready,         //            .arready
		output wire [3:0]   s0_axi4_rid,             //            .rid
		output wire [127:0] s0_axi4_rdata,           //            .rdata
		output wire [1:0]   s0_axi4_rresp,           //            .rresp
		output wire         s0_axi4_rlast,           //            .rlast
		output wire         s0_axi4_rvalid,          //            .rvalid
		input  wire         s0_axi4_rready,          //            .rready
		input  wire [4:0]   s1_axi4_awid,            //     s1_axi4.awid
		input  wire [31:0]  s1_axi4_awaddr,          //            .awaddr
		input  wire [7:0]   s1_axi4_awlen,           //            .awlen
		input  wire [2:0]   s1_axi4_awsize,          //            .awsize
		input  wire [1:0]   s1_axi4_awburst,         //            .awburst
		input  wire [0:0]   s1_axi4_awlock,          //            .awlock
		input  wire [3:0]   s1_axi4_awcache,         //            .awcache
		input  wire [2:0]   s1_axi4_awprot,          //            .awprot
		input  wire [3:0]   s1_axi4_awqos,           //            .awqos
		input  wire         s1_axi4_awvalid,         //            .awvalid
		output wire         s1_axi4_awready,         //            .awready
		input  wire [255:0] s1_axi4_wdata,           //            .wdata
		input  wire [31:0]  s1_axi4_wstrb,           //            .wstrb
		input  wire         s1_axi4_wlast,           //            .wlast
		input  wire         s1_axi4_wvalid,          //            .wvalid
		output wire         s1_axi4_wready,          //            .wready
		output wire [4:0]   s1_axi4_bid,             //            .bid
		output wire [1:0]   s1_axi4_bresp,           //            .bresp
		output wire         s1_axi4_bvalid,          //            .bvalid
		input  wire         s1_axi4_bready,          //            .bready
		input  wire [4:0]   s1_axi4_arid,            //            .arid
		input  wire [31:0]  s1_axi4_araddr,          //            .araddr
		input  wire [7:0]   s1_axi4_arlen,           //            .arlen
		input  wire [2:0]   s1_axi4_arsize,          //            .arsize
		input  wire [1:0]   s1_axi4_arburst,         //            .arburst
		input  wire [0:0]   s1_axi4_arlock,          //            .arlock
		input  wire [3:0]   s1_axi4_arcache,         //            .arcache
		input  wire [2:0]   s1_axi4_arprot,          //            .arprot
		input  wire [3:0]   s1_axi4_arqos,           //            .arqos
		input  wire         s1_axi4_arvalid,         //            .arvalid
		output wire         s1_axi4_arready,         //            .arready
		output wire [4:0]   s1_axi4_rid,             //            .rid
		output wire [255:0] s1_axi4_rdata,           //            .rdata
		output wire [1:0]   s1_axi4_rresp,           //            .rresp
		output wire         s1_axi4_rlast,           //            .rlast
		output wire         s1_axi4_rvalid,          //            .rvalid
		input  wire         s1_axi4_rready,          //            .rready
		input  wire         clk_sys_clk,             //     clk_sys.clk
		input  wire         core_init_n_reset_n,     // core_init_n.reset_n
		output wire         ctrl_ready_reset_n,      //  ctrl_ready.reset_n
		input  wire [26:0]  s0_axi4lite_awaddr,      // s0_axi4lite.awaddr
		input  wire [2:0]   s0_axi4lite_awprot,      //            .awprot
		input  wire         s0_axi4lite_awvalid,     //            .awvalid
		output wire         s0_axi4lite_awready,     //            .awready
		input  wire [26:0]  s0_axi4lite_araddr,      //            .araddr
		input  wire [2:0]   s0_axi4lite_arprot,      //            .arprot
		input  wire         s0_axi4lite_arvalid,     //            .arvalid
		output wire         s0_axi4lite_arready,     //            .arready
		input  wire [31:0]  s0_axi4lite_wdata,       //            .wdata
		input  wire [3:0]   s0_axi4lite_wstrb,       //            .wstrb
		input  wire         s0_axi4lite_wvalid,      //            .wvalid
		output wire         s0_axi4lite_wready,      //            .wready
		input  wire         s0_axi4lite_bready,      //            .bready
		output wire [1:0]   s0_axi4lite_bresp,       //            .bresp
		output wire         s0_axi4lite_bvalid,      //            .bvalid
		input  wire         s0_axi4lite_rready,      //            .rready
		output wire [31:0]  s0_axi4lite_rdata,       //            .rdata
		output wire [1:0]   s0_axi4lite_rresp,       //            .rresp
		output wire         s0_axi4lite_rvalid,      //            .rvalid
		output wire [0:0]   mem_0_mem_cs,            //       mem_0.mem_cs
		output wire [5:0]   mem_0_mem_ca,            //            .mem_ca
		output wire [0:0]   mem_0_mem_cke,           //            .mem_cke
		inout  wire [31:0]  mem_0_mem_dq,            //            .mem_dq
		inout  wire [3:0]   mem_0_mem_dqs_t,         //            .mem_dqs_t
		inout  wire [3:0]   mem_0_mem_dqs_c,         //            .mem_dqs_c
		inout  wire [3:0]   mem_0_mem_dmi,           //            .mem_dmi
		output wire [0:0]   mem_ck_0_mem_ck_t,       //    mem_ck_0.mem_ck_t
		output wire [0:0]   mem_ck_0_mem_ck_c,       //            .mem_ck_c
		output wire         mem_reset_n_mem_reset_n, // mem_reset_n.mem_reset_n
		input  wire         oct_0_oct_rzqin,         //       oct_0.oct_rzqin
		input  wire         ref_clk_clk,             //     ref_clk.clk
		input  wire         rst_sys_reset            //     rst_sys.reset
	);

   // =====================================================================
   //  Behavioral simulation model -- NOT the real Intel EMIF.
   //  Just enough to exercise the VRAM datapath end to end:
   //    * AXI-Lite calibration CSR always reports "cal done"
   //    * s0_axi4_reset_n (AXI-ready) deasserts a few cycles after
   //      core_init_n is released
   //    * s0_axi4 is a sparse AXI4 memory (INCR bursts honoured, wstrb
   //      honoured), one outstanding read + one outstanding write.
   //  Functionally correct, not cycle-accurate (depth-1, no reordering).
   // =====================================================================

   // Sparse backing store, indexed by 256-bit word address.
   logic [255:0] mem [longint];

   // ---------------------------------------------------------------------
   // AXI-Lite calibration status register.
   //   reads  -> 32'h1 (bit0 = cal success, bit1 = cal fail)
   //   writes -> accepted and B-acked (the cal driver never writes, but
   //             keep it deadlock-free in case something else does)
   // ---------------------------------------------------------------------
   logic        l_arready, l_rvalid;
   logic        l_aw_seen, l_w_seen, l_bvalid;
   always_ff @(posedge clk_sys_clk) begin
      if (rst_sys_reset) begin
         l_arready <= 1'b0;
         l_rvalid  <= 1'b0;
         l_aw_seen <= 1'b0;
         l_w_seen  <= 1'b0;
         l_bvalid  <= 1'b0;
      end else begin
         // read: single-beat handshake
         l_arready <= s0_axi4lite_arvalid & ~l_arready & ~l_rvalid;
         if (s0_axi4lite_arvalid & l_arready)    l_rvalid <= 1'b1;
         else if (l_rvalid & s0_axi4lite_rready) l_rvalid <= 1'b0;
         // write: latch AW/W, then B
         if (s0_axi4lite_awvalid & s0_axi4lite_awready) l_aw_seen <= 1'b1;
         if (s0_axi4lite_wvalid  & s0_axi4lite_wready)  l_w_seen  <= 1'b1;
         if (l_aw_seen & l_w_seen & ~l_bvalid)          l_bvalid  <= 1'b1;
         if (l_bvalid & s0_axi4lite_bready) begin
            l_bvalid  <= 1'b0;
            l_aw_seen <= 1'b0;
            l_w_seen  <= 1'b0;
         end
      end
   end
   assign s0_axi4lite_arready = l_arready;
   assign s0_axi4lite_rvalid  = l_rvalid;
   assign s0_axi4lite_rdata   = 32'h0000_0001; // bit0 = cal done, bit1 = cal fail
   assign s0_axi4lite_rresp   = 2'b00;
   assign s0_axi4lite_awready = ~rst_sys_reset & ~l_aw_seen;
   assign s0_axi4lite_wready  = ~rst_sys_reset & ~l_w_seen;
   assign s0_axi4lite_bvalid  = l_bvalid;
   assign s0_axi4lite_bresp   = 2'b00;

   // ---------------------------------------------------------------------
   // AXI4 domain reset: go "ready" a few cycles after core_init_n release.
   // ---------------------------------------------------------------------
   logic [3:0] rdy_cnt = 4'h0;
   logic       axi_rdy = 1'b0;
   always_ff @(posedge clk_sys_clk) begin
      if (!core_init_n_reset_n) begin
         rdy_cnt <= 4'h0;
         axi_rdy <= 1'b0;
      end else if (!axi_rdy) begin
         rdy_cnt <= rdy_cnt + 4'h1;
         if (&rdy_cnt) axi_rdy <= 1'b1;
      end
   end
   assign ctrl_ready_reset_n = axi_rdy;

`ifdef FIXME
   // ---------------------------------------------------------------------
   // AXI4 read channel (single outstanding, INCR).
   // ---------------------------------------------------------------------
   logic         rd_busy;
   logic [6:0]   rd_id;
   longint       rd_addr;   // byte address
   logic [7:0]   rd_left;   // beats remaining (incl. current)
   logic [2:0]   rd_size;
   logic [255:0] rd_data_c;

   always_comb begin
      if (mem.exists(rd_addr >> 5)) rd_data_c = mem[rd_addr >> 5];
      else                          rd_data_c = 256'd0;
   end

   always_ff @(posedge clk_sys_clk) begin
      if (!axi_rdy) begin
         rd_busy <= 1'b0;
      end else if (!rd_busy) begin
         if (s0_axi4_arvalid) begin
            rd_busy <= 1'b1;
            rd_id   <= s0_axi4_arid;
            rd_addr <= longint'(s0_axi4_araddr);
            rd_left <= s0_axi4_arlen + 8'd1;
            rd_size <= s0_axi4_arsize;
         end
      end else if (s0_axi4_rready) begin
         rd_addr <= rd_addr + (longint'(1) << rd_size);
         rd_left <= rd_left - 8'd1;
         if (rd_left == 8'd1) rd_busy <= 1'b0;
      end
   end
   assign s0_axi4_arready = axi_rdy & ~rd_busy;
   assign s0_axi4_rvalid  = rd_busy;
   assign s0_axi4_rdata   = rd_data_c;
   assign s0_axi4_rlast   = (rd_left == 8'd1);
   assign s0_axi4_rid     = rd_id;
   assign s0_axi4_rresp   = 2'b00;

   // ---------------------------------------------------------------------
   // AXI4 write channel (single outstanding, INCR + byte strobes).
   // ---------------------------------------------------------------------
   localparam logic [1:0] WS_AW = 2'd0, WS_W = 2'd1, WS_B = 2'd2;
   logic [1:0]  wr_state;
   logic [6:0]  wr_id;
   longint      wr_addr;
   logic [2:0]  wr_size;

   always_ff @(posedge clk_sys_clk) begin
      if (!axi_rdy) begin
         wr_state <= WS_AW;
      end else begin
         case (wr_state)
           WS_AW:
              if (s0_axi4_awvalid) begin
                 wr_id    <= s0_axi4_awid;
                 wr_addr  <= longint'(s0_axi4_awaddr);
                 wr_size  <= s0_axi4_awsize;
                 wr_state <= WS_W;
              end
           WS_W:
              if (s0_axi4_wvalid) begin
                 logic [255:0] cur;
                 cur = mem.exists(wr_addr >> 5) ? mem[wr_addr >> 5] : 256'd0;
                 for (int b = 0; b < 32; b++)
                    if (s0_axi4_wstrb[b])
                       cur[b*8 +: 8] = s0_axi4_wdata[b*8 +: 8];
                 mem[wr_addr >> 5] = cur;
                 wr_addr <= wr_addr + (longint'(1) << wr_size);
                 if (s0_axi4_wlast) wr_state <= WS_B;
              end
           WS_B:
              if (s0_axi4_bready) wr_state <= WS_AW;
           default: wr_state <= WS_AW;
         endcase
      end
   end
   assign s0_axi4_awready = axi_rdy & (wr_state == WS_AW);
   assign s0_axi4_wready  = axi_rdy & (wr_state == WS_W);
   assign s0_axi4_bvalid  = (wr_state == WS_B);
   assign s0_axi4_bid     = wr_id;
   assign s0_axi4_bresp   = 2'b00;
`endif

   // Unused physical DRAM interface (no DRAM model attached in sim).
   assign mem_0_mem_cs      = '0;
   assign mem_0_mem_ca      = '0;
   assign mem_0_mem_cke     = '0;
   assign mem_ck_0_mem_ck_t = '0;
   assign mem_ck_0_mem_ck_c = '0;
   assign mem_0_mem_dq      = 'z;
   assign mem_0_mem_dqs_t   = 'z;
   assign mem_0_mem_dqs_c   = 'z;
   assign mem_0_mem_dmi     = 'z;
   assign mem_reset_n_mem_reset_n = 1'b0;

endmodule // lpddr4b_vram
