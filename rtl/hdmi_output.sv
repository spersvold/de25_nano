// -*- mode: verilog; mode: font-lock; indent-tabs-mode: nil -*-
// vi: set et ts=3 sw=3 sts=3:
//
// Copyright 2021 Steffen Persvold
// SPDX-License-Identifier: Apache-2.0
//
// ========================================================================
// File        : hdmi_output.sv
// Author      : Steffen Persvold
// Created     : April 15, 2021
// ========================================================================
// Description : HDMI output drivers
// ========================================================================
//

module hdmi_output
  (
    input  logic         clk_pix        // Pixel clock

   // VGA input
   ,input  logic         vga_hs         // VGA H_SYNC
   ,input  logic         vga_vs         // VGA V_SYNC
   ,input  logic         vga_de         // VGA Display Enable
   ,input  logic [ 7:0]  vga_r          // VGA Red
   ,input  logic [ 7:0]  vga_g          // VGA Green
   ,input  logic [ 7:0]  vga_b          // VGA Blue

   // HDMI output
   ,output logic         HDMI_TX_HS
   ,output logic         HDMI_TX_VS
   ,output logic         HDMI_TX_DE
   ,output logic [23:0]  HDMI_TX_D
   ,output logic         HDMI_TX_CLK
   );

   //
   // HDMI Output registers
   //

   tennm_ph2_ddio_out #
     (// Parameters.
      .asclr_ena ("ASCLR_ENA_NONE"),
      .mode      ("MODE_DDR"),
      .sclr_ena  ("SCLR_ENA_NONE"))
   u_hdmi_tx_clk_ddio_out
     (// Inputs.
      .areset   (1'd1),
      .clk      (clk_pix),
      .datainhi (1'd1), // Invert clock for best setup/hold margin
      .datainlo (1'd0), // Invert clock for best setup/hold margin
      .ena      (1'd1),
      .sreset   (1'd1),
      // Outputs.
      .dataout  (HDMI_TX_CLK)
      );

   // Display Enable
   tennm_ph2_ddio_out #
     (// Parameters.
      .asclr_ena ("ASCLR_ENA_NONE"),
      .mode      ("MODE_DDR"),
      .sclr_ena  ("SCLR_ENA_NONE"))
   u_hdmi_tx_de_ddio_out
     (// Inputs.
      .areset   (1'd1),
      .clk      (clk_pix),
      .datainhi (vga_de),
      .datainlo (vga_de),
      .ena      (1'd1),
      .sreset   (1'd1),
      // Outputs.
      .dataout  (HDMI_TX_DE)
      );

   // Horizontal Sync
   tennm_ph2_ddio_out #
     (// Parameters.
      .asclr_ena ("ASCLR_ENA_NONE"),
      .mode      ("MODE_DDR"),
      .sclr_ena  ("SCLR_ENA_NONE"))
   u_hdmi_tx_hs_ddio_out
     (// Inputs.
      .areset   (1'd1),
      .clk      (clk_pix),
      .datainhi (vga_hs),
      .datainlo (vga_hs),
      .ena      (1'd1),
      .sreset   (1'd1),
      // Outputs.
      .dataout  (HDMI_TX_HS)
      );

   // Vertical Sync
   tennm_ph2_ddio_out #
     (// Parameters.
      .asclr_ena ("ASCLR_ENA_NONE"),
      .mode      ("MODE_DDR"),
      .sclr_ena  ("SCLR_ENA_NONE"))
   u_hdmi_tx_vs_ddio_out
     (// Inputs.
      .areset   (1'd1),
      .clk      (clk_pix),
      .datainhi (vga_vs),
      .datainlo (vga_vs),
      .ena      (1'd1),
      .sreset   (1'd1),
      // Outputs.
      .dataout  (HDMI_TX_VS)
      );

   // Red
   tennm_ph2_ddio_out #
     (// Parameters.
      .asclr_ena ("ASCLR_ENA_NONE"),
      .mode      ("MODE_DDR"),
      .sclr_ena  ("SCLR_ENA_NONE"))
   u_hdmi_tx_r_ddio_out[7:0]
     (// Inputs.
      .areset   (1'd1),
      .clk      (clk_pix),
      .datainhi (vga_r),
      .datainlo (vga_r),
      .ena      (1'd1),
      .sreset   (1'd1),
      // Outputs.
      .dataout  (HDMI_TX_D[23:16])
      );

   // Green
   tennm_ph2_ddio_out #
     (// Parameters.
      .asclr_ena ("ASCLR_ENA_NONE"),
      .mode      ("MODE_DDR"),
      .sclr_ena  ("SCLR_ENA_NONE"))
   u_hdmi_tx_g_ddio_out[7:0]
     (// Inputs.
      .areset   (1'd1),
      .clk      (clk_pix),
      .datainhi (vga_g),
      .datainlo (vga_g),
      .ena      (1'd1),
      .sreset   (1'd1),
      // Outputs.
      .dataout  (HDMI_TX_D[15:8])
      );

   // Blue
   tennm_ph2_ddio_out #
     (// Parameters.
      .asclr_ena ("ASCLR_ENA_NONE"),
      .mode      ("MODE_DDR"),
      .sclr_ena  ("SCLR_ENA_NONE"))
   u_hdmi_tx_b_ddio_out[7:0]
     (// Inputs.
      .areset   (1'd1),
      .clk      (clk_pix),
      .datainhi (vga_b),
      .datainlo (vga_b),
      .ena      (1'd1),
      .sreset   (1'd1),
      // Outputs.
      .dataout  (HDMI_TX_D[7:0])
      );

endmodule // hdmi_output
