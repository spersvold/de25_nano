// -*- mode: verilog; mode: font-lock; indent-tabs-mode: nil -*-
// vi: set et ts=3 sw=3 sts=3:
//
// Copyright 2026 Steffen Persvold
// SPDX-License-Identifier: Apache-2.0
//
// ========================================================================
// File        : freq_counter.sv
// Author      : Steffen Persvold
// ========================================================================
// Description : Relative frequency monitor / counter.
//
//   Counts meas_clk cycles over a fixed window of REF_WINDOW ref_clk cycles.
//   With REF_WINDOW set to ref_clk's frequency in kHz (50000 for a 50 MHz
//   reference => a 1 ms window), freq_out reads the measured frequency in kHz
//   directly: 148.5 MHz -> 148500, 74.25 MHz -> 74250. Reads 0 when meas_clk
//   is stopped.
//
//   meas_clk is asynchronous to ref_clk, so its free-running counter is
//   crossed into the ref_clk domain as Gray code (only one bit changes per
//   step -> safe through a 3-FF synchronizer; the recovered value is off by at
//   most 1 LSB, negligible over a window). freq_out therefore lives entirely
//   in the ref_clk domain and is stable to sample (SignalTap / CSR) even while
//   meas_clk is glitching or absent.
// ========================================================================

module freq_counter
  #(parameter int REF_WINDOW = 50000,   // ref_clk cycles per measurement window
    parameter int CNT_W      = 24)      // counter width (>= log2 of max cycles/window)
   (input  logic             ref_clk,
    input  logic             ref_rst_n,
    input  logic             meas_clk,
    input  logic             meas_rst_n,
    output logic [CNT_W-1:0] freq_out);   // ref_clk domain: meas_clk cycles per window

   localparam int WIN_W = $clog2(REF_WINDOW);

   // ---- meas_clk domain: free-running counter (Gray-encoded for the CDC) ----
   logic [CNT_W-1:0] bin;
   always_ff @(posedge meas_clk or negedge meas_rst_n)
     if (~meas_rst_n) bin <= '0;
     else             bin <= bin + 1'b1;

   wire [CNT_W-1:0] gray = bin ^ (bin >> 1);

   // ---- ref_clk domain: synchronize Gray, decode to binary ----
   logic [CNT_W-1:0] g1, g2, g3, binr;
   always_ff @(posedge ref_clk or negedge ref_rst_n)
     if (~ref_rst_n) begin g1 <= '0; g2 <= '0; g3 <= '0; end
     else            begin g1 <= gray; g2 <= g1; g3 <= g2; end

   always_comb begin
      binr[CNT_W-1] = g3[CNT_W-1];
      for (int i = CNT_W-2; i >= 0; i = i - 1)
        binr[i] = binr[i+1] ^ g3[i];
   end

   // ---- ref_clk domain: window timer + per-window difference ----
   logic [WIN_W-1:0] win;
   logic [CNT_W-1:0] prev;
   always_ff @(posedge ref_clk or negedge ref_rst_n)
     if (~ref_rst_n) begin
        win <= '0; prev <= '0; freq_out <= '0;
     end else if (win == WIN_W'(REF_WINDOW - 1)) begin
        win      <= '0;
        freq_out <= binr - prev;   // meas_clk cycles elapsed over the window
        prev     <= binr;
     end else begin
        win <= win + 1'b1;
     end

endmodule // freq_counter
