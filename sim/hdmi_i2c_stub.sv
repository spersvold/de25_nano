// -*- mode: verilog; mode: font-lock; indent-tabs-mode: nil -*-
// vi: set et ts=3 sw=3 sts=3:
//
// Copyright 2026 Steffen Persvold
// SPDX-License-Identifier: Apache-2.0
//
// ========================================================================
// File        : hdmi_i2c_stub.sv
// Author      : Steffen Persvold (spersvold@gmail.com)
// Created     : May 25, 2026
// ========================================================================
// Description : Trivial I2C slave stub for HDMI transmitter setup
//
// Replaces the on-board ADV7513-class HDMI transmitter for the
// purposes of clearing the hdmi_i2c init sequence in sim. Behaviour:
//
//   - No slave-address filtering. Every I2C transaction on the bus
//     is treated as addressed to us.
//   - Drives SDA low for the ACK bit of every byte the master sends
//     (slave-addr, sub-addr, data) -- which is what hdmi_i2c.sv
//     samples to advance through its LUT.
//   - Writes are dropped. Reads (R/W=1) return all zeros (we hold
//     SDA low for the eight data bits). The on-board hdmi_i2c master
//     only ever issues writes, so the read behaviour is just for
//     correctness of the model.
//
// I2C events are tracked from a single always block sensitive to
// SCL falling and SDA edges -- one driver per signal, no race-prone
// multi-process state writes.
//
// ========================================================================

module hdmi_i2c_stub
  (
   input  wire scl,
   inout  wire sda
   );

   // FSM:
   //   IDLE -- no transaction in progress, waiting for START
   //   RX   -- receiving 8 data bits from the master
   //   ACK  -- driving SDA low for the 9th SCL period (write-ACK or
   //           continuing read-data drive of 0)
   //   READ -- driving SDA low for 8 SCL periods (returning 0x00)
   typedef enum logic [1:0] {
      S_IDLE,
      S_RX,
      S_ACK,
      S_READ
   } state_e;

   state_e     state;
   logic [2:0] bit_cnt;
   logic       drive_low;
   logic       addr_phase;   // first byte after START carries R/W

   initial begin
      state      = S_IDLE;
      bit_cnt    = '0;
      drive_low  = 1'b0;
      addr_phase = 1'b0;
   end

   // SDA is open-drain: drive 0 when drive_low is asserted, release
   // otherwise so the master and the tb's pullup own the line.
   assign sda = drive_low ? 1'b0 : 1'bz;

   // ------------------------------------------------------------
   // All FSM updates from one process. Triggered on:
   //   - SCL falling           -> advance bit count / toggle ACK
   //   - SDA change while SCL  -> START / STOP detection
   // SDA changes with SCL low are normal data-bit transitions and
   // are ignored here (the master may move SDA after we release).
   // ------------------------------------------------------------

   logic scl_prev;
   initial scl_prev = 1'b1;

   always @(scl, sda) begin
      if (scl === 1'b0 && scl_prev === 1'b1) begin
         // SCL falling edge.
         unique case (state)

           S_RX: begin
              if (bit_cnt == 3'd7) begin
                 // 8th data bit just completed -- enter ACK slot.
                 // On the address byte the LSB sampled here (sda)
                 // is the R/W bit: 1 = read, 0 = write. Switch to
                 // READ-data drive if the master is reading.
                 if (addr_phase && sda === 1'b1) begin
                    state      <= S_ACK;
                    drive_low  <= 1'b1;
                    addr_phase <= 1'b0;
                    // After the ACK slot we'll go to S_READ.
                 end
                 else begin
                    state      <= S_ACK;
                    drive_low  <= 1'b1;
                    addr_phase <= 1'b0;
                 end
              end
              else begin
                 bit_cnt <= bit_cnt + 3'd1;
              end
           end

           S_ACK: begin
              // ACK slot just completed. Release SDA and start the
              // next byte, unless we still owe read-data bytes.
              state     <= S_RX;
              bit_cnt   <= '0;
              drive_low <= 1'b0;
           end

           S_READ: begin
              // Driving 0x00 for read data. After 8 bits, master's
              // own ACK/NACK bit -- release SDA so master drives it.
              if (bit_cnt == 3'd7) begin
                 state     <= S_RX;
                 bit_cnt   <= '0;
                 drive_low <= 1'b0;
              end
              else begin
                 bit_cnt <= bit_cnt + 3'd1;
              end
           end

           default: ;

         endcase
      end
      else if (scl === 1'b1 && scl_prev === 1'b1) begin
         // SCL stayed high, SDA changed -- START or STOP.
         if (sda === 1'b0) begin
            // START (or repeated START): begin a new byte. Mark
            // address phase so we capture R/W at the LSB.
            state      <= S_RX;
            bit_cnt    <= '0;
            drive_low  <= 1'b0;
            addr_phase <= 1'b1;
         end
         else if (state !== S_IDLE) begin
            // STOP: release the line and idle.
            state      <= S_IDLE;
            bit_cnt    <= '0;
            drive_low  <= 1'b0;
            addr_phase <= 1'b0;
         end
      end
      // SCL rising or SDA change with SCL low -> no state update.
      scl_prev <= scl;
   end

endmodule // hdmi_i2c_stub
