// (C) 2001-2026 Altera Corporation. All rights reserved.
// Your use of Altera Corporation's design tools, logic functions and other
// software and tools, and its AMPP partner logic functions, and any output
// files from any of the foregoing (including device programming or simulation
// files), and any associated documentation or information are expressly subject
// to the terms and conditions of the Altera Program License Subscription
// Agreement, Altera IP License Agreement, or other applicable
// license agreement, including, without limitation, that your use is for the
// sole purpose of programming logic devices manufactured by Altera and sold by
// Altera or its authorized distributors.  Please refer to the applicable
// agreement for further details.


///////////////////////////////////////////////////////////////////////////////////////////
// LPDDR4 Memory model rank formed by wiring together a number of x16 dies in parallel
// Top > Channel > Rank > DRAM
///////////////////////////////////////////////////////////////////////////////////////////

/* verilator lint_off PINMISSING */
module altera_emif_lpddr4_model_rank
   # (

      parameter MEM_CK_WIDTH                             = 1,
      parameter MEM_CS_WIDTH                             = 1,
      parameter MEM_CA_WIDTH                             = 7,
      parameter MEM_DQ_WIDTH                             = 16,
      parameter MEM_DMI_WIDTH                            = 2,
      parameter MEM_DQS_WIDTH                            = 2,
      parameter MEM_ROW_ADDR_WIDTH                       = 13,
      parameter MEM_COL_ADDR_WIDTH                       = 6,
      parameter MEM_BA_WIDTH                             = 4,
      parameter MEM_RESET_N_WIDTH                        = 1,
      parameter MEM_ZQ_WIDTH                             = 1,
      parameter MEM_DENSITY                              = "2Gb",
      parameter MEM_CHANNEL_IDX                          = "-1",
      parameter MEM_RANK_IDX                             = -1,
      parameter MEM_VERBOSE                              = 1

   )  (

      input  logic                                       mem_ck_t,
      input  logic                                       mem_ck_c,
      input  logic                                       mem_cke,
      input  logic         [MEM_CS_WIDTH     -1 : 0]     mem_cs,
      input  logic         [MEM_CA_WIDTH     -1 : 0]     mem_ca,
      inout  tri           [MEM_DQ_WIDTH     -1 : 0]     mem_dq,
      inout  tri           [MEM_DQS_WIDTH    -1 : 0]     mem_dqs_t,
      inout  tri           [MEM_DQS_WIDTH    -1 : 0]     mem_dqs_c,
      inout  tri           [MEM_DMI_WIDTH    -1 : 0]     mem_dmi,
      input  logic                                       mem_reset_n

   );

   timeunit 1ps;
   timeprecision 1ps;

   localparam MEM_NUM_CHIPS_PER_RANK = (MEM_DQ_WIDTH == 16) ? 1 :
                                       ((MEM_DQ_WIDTH == 32) ? 2 :
                                       ((MEM_DQ_WIDTH == 64) ? 4 : 0));

   genvar dram_component_id;

   generate
      for(dram_component_id = 0; dram_component_id < MEM_NUM_CHIPS_PER_RANK; dram_component_id = dram_component_id + 1) begin : dram_component_gen

      localparam DQ_WIDTH_THIS_CHIP   = 16;
      localparam DMI_WIDTH_THIS_CHIP  = 2;
      localparam DQS_WIDTH_THIS_CHIP  = 2;

      altera_emif_lpddr4_model_dram_component #(
         .MEM_CK_WIDTH                       (MEM_CK_WIDTH),
         .MEM_CS_WIDTH                       (MEM_CS_WIDTH),
         .MEM_CA_WIDTH                       (MEM_CA_WIDTH),
         .MEM_DQ_WIDTH                       (DQ_WIDTH_THIS_CHIP),
         .MEM_DMI_WIDTH                      (DMI_WIDTH_THIS_CHIP),
         .MEM_ROW_ADDR_WIDTH                 (MEM_ROW_ADDR_WIDTH),
         .MEM_COL_ADDR_WIDTH                 (MEM_COL_ADDR_WIDTH),
         .MEM_BA_WIDTH                       (MEM_BA_WIDTH),
         .MEM_DQS_WIDTH                      (DQS_WIDTH_THIS_CHIP),
         .MEM_RESET_N_WIDTH                  (MEM_RESET_N_WIDTH),
         .MEM_ZQ_WIDTH                       (MEM_ZQ_WIDTH),
         .MEM_DENSITY                        (MEM_DENSITY),
         .MEM_CHANNEL_IDX                    (MEM_CHANNEL_IDX),
         .MEM_RANK_IDX                       (MEM_RANK_IDX),
         .MEM_DEVICE_IDX                     (dram_component_id),
         .MEM_VERBOSE                        (MEM_VERBOSE)
      ) chip_inst (

         .mem_cke                            (mem_cke),
         .mem_ck_t                           (mem_ck_t),
         .mem_ck_c                           (mem_ck_c),
         .mem_cs                             (mem_cs),
         .mem_ca                             (mem_ca),
         .mem_dq                             (mem_dq        [(dram_component_id+1)*DQ_WIDTH_THIS_CHIP-1:dram_component_id*DQ_WIDTH_THIS_CHIP]),
         .mem_dqs_t                          (mem_dqs_t     [(dram_component_id+1)*DQS_WIDTH_THIS_CHIP-1:dram_component_id*DQS_WIDTH_THIS_CHIP]),
         .mem_dqs_c                          (mem_dqs_c     [(dram_component_id+1)*DQS_WIDTH_THIS_CHIP-1:dram_component_id*DQS_WIDTH_THIS_CHIP]),
         .mem_dmi                            (mem_dmi       [(dram_component_id+1)*DMI_WIDTH_THIS_CHIP-1:dram_component_id*DMI_WIDTH_THIS_CHIP]),
         .mem_reset_n                        (mem_reset_n)
      );

      end
   endgenerate

endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "+qL3hlshuw3vl105k04c4hDzfWgPSh5sVI/ghdJXk44XYu5+Y2kb3X2D97dl4myk2GIrABCQ+//lQ9PbcrMpaedxlxbRS2oWnBsOGXND/uDLU78WuXe8IluK542JWM0Aq87DaeZITm+H/eLx0Wv9HAGhJ07dBaLvKkPWBtg8rXsyUwQNr/JbEusQM2wKWTHh+vFhnlX/HbTTazDHawScbgHGadk2olDQ2A/yNzOpmwnb8g9gArVwSBYeWUf820W7sDjc8v1ELH4LR7IodK+vqKeniF+TMDN6Jz4vvcKUSHoME52oy9UMLLji8EQlWL7H+iy0ycecpu0OyrwrTKWrfSHpZfh8lpSVfLP83/h+tDam5AACsK6cFoS6dCcL/JXAOIOE8h1vZ0z6ijhIgVtxFR3joJdqQ078qlCAkF2+7WUXFGUcAMbNd2nYkpa2t6SWk6m/4A/Uq6yLmte84DCBDo6H3NZnEqFhbxTc/dtgUmjtQPt1gmdsgXl0hXNmSAZkz+SduQCj6d7XDUZrISX6BAnWGGlbjK14PtLEbA5XiX2xJO62jhj/FcDZF9fl5WZNzQkAnVqsBkP0cvNNElJivlKkBAkKeW6dbarzZ+fuSfAOejjhsxfcRt629uM5pAzhPcVcOmiWraYoyR4BjtKybLIvxgo7cv24GVN4IjnYj9IVTa+FcwG1i3lznX9tk5/gFKiHglFPzejrMGjWPrx3eBI4iU5SrGLON+xTsrNkX95WqgaiF2SI+nfkVqFx4dINvZBKuRVe3/QF88BuIoRyExUGtRrc9SFlMFn/vZiXZr62IIf7rx3ogNONHX1olZQv5im+nH2WndhBc1t0AEQwcmSB6cvfxKuUncMBL+e9Gta+49Db9hYfku9uWWEIt/L5OSn8x+Onlb4aPyvbgy6CPBCFL3bLrPxO81kVye6Trpoil+aAu3xd4N15pdHvbBQGyVL00IHh49QqWH9cVLOBCRAtQCpR1PauRz3ICi2stYfrJAJ+yIk3rtrDZSQOTxRP"
`endif
