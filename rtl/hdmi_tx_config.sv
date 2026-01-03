// -*- mode: verilog; mode: font-lock; indent-tabs-mode: nil -*-
// vi: set et ts=3 sw=3 sts=3:
//
// Copyright 2026 Steffen Persvold
// SPDX-License-Identifier: Apache-2.0
//
// ========================================================================
// File        : hdmi_tx_config.sv
// Author      : Steffen Persvold (spersvold@gmail.com)
// Created     : May 22, 2026
// ========================================================================
// Description : HDMI transmitter I2C init controller (ADV7513-class)
//
// Drives a fixed LUT of register writes to the on-board HDMI
// transmitter at startup, then asserts `done so the SoC can gate
// downstream HDMI signal generation. Re-runs the init sequence if
// HDMI_TX_INT drops (cable hot-plug / PHY reset).
//
// ========================================================================

module hdmi_tx_config
 #(parameter int unsigned CLK_HZ     = 28_375_000,   //  28.375 MHz
   parameter int unsigned I2C_HZ     =    100_000,   // 100.000 kHz
   parameter logic [7:0]  SLAVE_ADDR = 8'h72         // ADV7513 write address
   )
  (
   input  logic          clk,
   input  logic          rstn,            // Sync reset, active low

   input  logic          tx_int_n,        // hot-plug interrupt (active-low)

   output logic          scl,             // push-pull SCL drive
   input  logic          sda_i,           // sampled SDA from pad
   output logic          sda_o,           // SDA drive value (always 0)
   output logic          sda_e,           // SDA drive enable (open-drain)

   output logic          done             // init sequence complete
   );

   // Derived parameters
   localparam int unsigned DIV_MAX   = CLK_HZ/I2C_HZ/2;
   localparam int unsigned DIV_W     = $clog2(DIV_MAX + 1);

   localparam int unsigned LUT_SIZE  = 33;
   localparam int unsigned LUT_IDX_W = $clog2(LUT_SIZE);

   logic [DIV_W-1:0]     i2c_clk_div;
   logic [23:0]          i2c_data;
   logic                 i2c_ctrl_clk;
   logic                 i2c_ctrl_en;
   logic                 i2c_go;
   logic                 i2c_end;
   logic                 i2c_ack;
   logic [15:0]          lut_data;
   logic [LUT_IDX_W-1:0] lut_index;

   typedef enum logic [1:0] {
      I_IDLE,
      I_WAIT,
      I_DONE
   } init_state_e;

   init_state_e  init_state;

   // ========================================================================
   // Clock divider
   // ========================================================================

   always_ff @(posedge clk) begin
      if (~rstn) begin
         i2c_ctrl_clk <= 1'b0;
         i2c_clk_div  <= '0;
      end
      else begin
         i2c_ctrl_en <= 1'b0;

         if (i2c_clk_div < DIV_W'(DIV_MAX)) begin
            i2c_clk_div <= i2c_clk_div + DIV_W'(1);
         end
         else begin
            i2c_clk_div  <= '0;
            i2c_ctrl_clk <= ~i2c_ctrl_clk;
            i2c_ctrl_en  <= 1'b1;
         end
      end
   end

   // ========================================================================
   // Init FSM
   // ========================================================================

   always_ff @(posedge clk) begin
      if (~rstn) begin
         done       <= 1'b0;
         lut_index  <= 6'd0;
         i2c_go     <= 1'b0;
         init_state <= I_IDLE;
      end
      else if (i2c_ctrl_clk & i2c_ctrl_en) begin
         if (lut_index < 6'(LUT_SIZE)) begin
            done <= 1'b0;
            unique case (init_state)
              I_IDLE: begin
                 i2c_data   <= {SLAVE_ADDR,lut_data};
                 i2c_go     <= 1'b1;
                 init_state <= I_WAIT;
              end
              I_WAIT: if (i2c_end) begin
                 i2c_go     <= 1'b0;
                 init_state <= (~i2c_ack) ? I_DONE : I_IDLE;
              end
              I_DONE: begin
                 lut_index  <= lut_index + 6'd1;
                 init_state <= I_IDLE;
              end
              default: init_state <= I_IDLE;
            endcase
         end
         else begin
            done <= 1'b1;
            if (~tx_int_n) begin
               lut_index <= 6'd0;
            end
         end
      end
   end


   // ====================================================================
   // LUT — ADV7513 setup script
   //
   // Each entry packs { sub_addr[15:8], data[7:0] }. The slave address
   // (SLAVE_ADDR) is prepended at transaction-issue time inside the
   // init FSM so each LUT row stays 16 bits.
   // ====================================================================

   localparam logic [15:0] LUT [0:LUT_SIZE-1] = '{
      16'h9803,  // Must be set to 0x03 for proper operation
      16'h0100,  // Set 'N' value at 6144
      16'h0218,  // Set 'N' value at 6144
      16'h0300,  // Set 'N' value at 6144
      16'h0b2e,  // MCLK active
      16'h0cbc,  // Serial Audio standard i2s, R0x0C[1:0] = 00
      16'h1472,  // Audio Word Length 16 bit, 8 channels
      16'h1520,  // Input 444 (RGB or YCrCb) + separate syncs, 48 kHz fs
      16'h1630,  // Output format 444, 24-bit input
      16'h1846,  // Disable CSC
      16'h4080,  // General control packet enable
      16'h4110,  // Power down control
      16'h49a8,  // Dither mode 12-to-10 bit
      16'h5510,  // RGB in AVI infoframe
      16'h5608,  // Active format aspect
      16'h96f6,  // Interrupt mask
      16'h7307,  // Info frame channel count = 8
      16'h761f,  // Speaker allocation for 8 channels
      16'h9803,  // Must be set to 0x03 for proper operation
      16'h9902,  // Must be set to default
      16'h9ae0,  // Must be set to 0b1110000
      16'h9c30,  // PLL filter R1 value
      16'h9d61,  // Clock divide
      16'ha2a4,  // Must be set to 0xA4 for proper operation
      16'ha3a4,  // Must be set to 0xA4 for proper operation
      16'ha504,  // Must be set to default
      16'hab40,  // Must be set to default
      16'haf16,  // Select HDMI mode
      16'hba60,  // No clock delay
      16'hd1ff,  // Must be set to default
      16'hde10,  // Must be set to default
      16'he460,  // Must be set to default
      16'hfa7d   // Phase-lookup retry count
   };

   assign lut_data = LUT[lut_index];

   logic        sdo;
   logic        sclk;
   logic [23:0] sd;
   logic [ 5:0] sd_counter;
   logic [ 2:0] ack;

   assign scl   = sclk | ( ((sd_counter >= 6'd4) & (sd_counter <= 6'd30)) ? ~i2c_ctrl_clk : 1'b0 );
   assign sda_e = ~sdo;
   assign sda_o = 1'b0;

   assign i2c_ack = |ack;

   always_ff @(posedge clk) begin
      if (~rstn) begin
         sd_counter <= 6'b111111;
      end
      else if (i2c_ctrl_clk & i2c_ctrl_en) begin
         if (~i2c_go)
           sd_counter <= 6'd0;
         else if (sd_counter < 6'b111111)
           sd_counter <= sd_counter + 6'd1;
      end
   end

   always_ff @(posedge clk) begin
      if (~rstn) begin
         sclk    <= 1'b1;
         sdo     <= 1'b1;
         ack     <= '0;
         i2c_end <= 1'b0;
      end
      else if (i2c_ctrl_clk & i2c_ctrl_en) begin
         unique case (sd_counter)
           6'd0  : begin
              ack     <= '0;
              i2c_end <= 1'b0;
              sdo     <= 1'b1;
              sclk    <= 1'b1;
           end
           //START
           6'd1  : begin sd <= i2c_data; sdo <= 1'b0;end
           6'd2  : sclk <= 1'b0;
           //SLAVE ADDR
           6'd3  : sdo <= sd[23];
           6'd4  : sdo <= sd[22];
           6'd5  : sdo <= sd[21];
           6'd6  : sdo <= sd[20];
           6'd7  : sdo <= sd[19];
           6'd8  : sdo <= sd[18];
           6'd9  : sdo <= sd[17];
           6'd10 : sdo <= sd[16];
           6'd11 : sdo <= 1'b1;//ACK
           //SUB ADDR
           6'd12  : begin sdo <= sd[15]; ack[0] <= sda_i; end
           6'd13  : sdo <= sd[14];
           6'd14  : sdo <= sd[13];
           6'd15  : sdo <= sd[12];
           6'd16  : sdo <= sd[11];
           6'd17  : sdo <= sd[10];
           6'd18  : sdo <= sd[9];
           6'd19  : sdo <= sd[8];
           6'd20  : sdo <= 1'b1;//ACK
           //DATA
           6'd21  : begin sdo <= sd[7]; ack[1] <= sda_i; end
           6'd22  : sdo <= sd[6];
           6'd23  : sdo <= sd[5];
           6'd24  : sdo <= sd[4];
           6'd25  : sdo <= sd[3];
           6'd26  : sdo <= sd[2];
           6'd27  : sdo <= sd[1];
           6'd28  : sdo <= sd[0];
           6'd29  : sdo <= 1'b1;//ACK
           //STOP
           6'd30 : begin sdo <= 1'b0; sclk <= 1'b0; ack[2] <= sda_i; end
           6'd31 : sclk <= 1'b1;
           6'd32 : begin sdo <= 1'b1; i2c_end <= 1'b1; end
           default: begin
              ack     <= '0;
              i2c_end <= 1'b0;
              sdo     <= 1'b1;
              sclk    <= 1'b1;
           end
         endcase
      end
   end

endmodule // hdmi_tx_config
