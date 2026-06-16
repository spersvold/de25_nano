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


///////////////////////////////////////////////////////////////////////////////
// Models a single LPDDR4 channel formed by one or two ranks
// Top > Channel > Rank > DRAM
///////////////////////////////////////////////////////////////////////////////

module altera_emif_lpddr4_model_channel
   # (

      parameter MEM_CKE_WIDTH                         = 1,
      parameter MEM_CK_WIDTH                          = 1,
      parameter MEM_CS_WIDTH                          = 1,
      parameter MEM_CA_WIDTH                          = 7,
      parameter MEM_DQ_WIDTH                          = 16,
      parameter MEM_DMI_WIDTH                         = 2,
      parameter MEM_DQS_WIDTH                         = 2,
      parameter MEM_ROW_ADDR_WIDTH                    = 13,
      parameter MEM_COL_ADDR_WIDTH                    = 6,
      parameter MEM_BA_WIDTH                          = 4,
      parameter MEM_RESET_N_WIDTH                     = 1,
      parameter MEM_ZQ_WIDTH                          = 1,
      parameter MEM_DENSITY                           = "2Gb",
      parameter MEM_CHANNEL_IDX                       = "-1",
      parameter MEM_NUM_RANKS                         = 1,
      parameter MEM_VERBOSE                           = 1
   
   ) (

      input  logic                                    mem_ck_t,
      input  logic                                    mem_ck_c,
      input  logic                                    mem_cke,
      input  logic      [MEM_CS_WIDTH     -1 : 0]     mem_cs,
      input  logic      [MEM_CA_WIDTH     -1 : 0]     mem_ca,
      inout  tri        [MEM_DQ_WIDTH     -1 : 0]     mem_dq,
      inout  tri        [MEM_DQS_WIDTH    -1 : 0]     mem_dqs_t,
      inout  tri        [MEM_DQS_WIDTH    -1 : 0]     mem_dqs_c,
      inout  tri        [MEM_DMI_WIDTH    -1 : 0]     mem_dmi,
      input  logic                                    mem_reset_n
   
   );


   timeunit 1ps;
   timeprecision 1ps;

   genvar rank_id;
   generate
      for (rank_id = 0; rank_id < MEM_CS_WIDTH; rank_id = rank_id + 1) begin : rank_gen
      
         altera_emif_lpddr4_model_rank # (
            .MEM_CK_WIDTH                       (MEM_CK_WIDTH),
            .MEM_CA_WIDTH                       (MEM_CA_WIDTH),
            .MEM_DQ_WIDTH                       (MEM_DQ_WIDTH),
            .MEM_DQS_WIDTH                      (MEM_DQS_WIDTH),
            .MEM_DMI_WIDTH                      (MEM_DMI_WIDTH),
            .MEM_ROW_ADDR_WIDTH                 (MEM_ROW_ADDR_WIDTH),
            .MEM_COL_ADDR_WIDTH                 (MEM_COL_ADDR_WIDTH),
            .MEM_BA_WIDTH                       (MEM_BA_WIDTH),
            .MEM_RESET_N_WIDTH                  (MEM_RESET_N_WIDTH),
            .MEM_ZQ_WIDTH                       (MEM_ZQ_WIDTH),
            .MEM_DENSITY                        ("2Gb"),
            .MEM_CHANNEL_IDX                    (MEM_CHANNEL_IDX),
            .MEM_RANK_IDX                       (rank_id),
            .MEM_VERBOSE                        (MEM_VERBOSE)

         ) rank_inst (
            
            .mem_ck_t                           (mem_ck_t),
            .mem_ck_c                           (mem_ck_c),
            .mem_cke                            (mem_cke),
            .mem_cs                             (mem_cs[rank_id]),
            .mem_ca                             (mem_ca),
            .mem_dq                             (mem_dq),
            .mem_dqs_t                          (mem_dqs_t),
            .mem_dqs_c                          (mem_dqs_c),
            .mem_dmi                            (mem_dmi),
            .mem_reset_n                        (mem_reset_n)
         
         );

      end
   endgenerate

endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "+qL3hlshuw3vl105k04c4hDzfWgPSh5sVI/ghdJXk44XYu5+Y2kb3X2D97dl4myk2GIrABCQ+//lQ9PbcrMpaedxlxbRS2oWnBsOGXND/uDLU78WuXe8IluK542JWM0Aq87DaeZITm+H/eLx0Wv9HAGhJ07dBaLvKkPWBtg8rXsyUwQNr/JbEusQM2wKWTHh+vFhnlX/HbTTazDHawScbgHGadk2olDQ2A/yNzOpmwnP69+LQ5Bcb0jS9XfBbscsAUmLTFFfSIFC6C0k4k+bEHlR7VgINN5dmv2Pdrk3fQI+WXeyHd3EtEDeYZf2VxdEtAZVhX+IBvSIV0CWgskBgHrDGWtQ8kp459jNw3q7IFHX6+GlnY9SiY3KfIerzt6/Lntwgpn0OD5v7n8bIvPvO9d0gDoH6yoHK0RSMndgwg/Eud4cr8dOW+pdRvuYjSM+E7cd9s9g03bKIIrj083jyYvkBsiVXfmDC18pR59LDmwUB2wNgvokn1UE8AAc2dJcpy/zDgIEjF0k9PVjjh1vC7fn2CNxAl6l2JsqKtKDTohKZvWTY5+deCeKjXjXEb74JAJW9vv3YIr9sWn3lxiv3Kpwz5LQ+v54ZX2bYKqmrf7Hl6PwsHKhEj7/E5BKr+wXRSygvHdUaTZSnmCe3kKPeodcXd7AhK4MF9ou6GTG6dWkSvi7vZ+egA5Wt/42rTYecw0AHn3oQyw52ZKJWrqDkeoMwJKgv5UdYLYXk4+LxszARRrQbU+XRn2/68ZZAyq1Pxoto6LfWC4+H9ESwR985/kJP/DcHMeuHh3FoP5j9g2XWv3BrjdoiZ5lX5Yrp+wdJmp21ROG6kZkzhAs4DxH2JIy9YGjLCXP92XSfqujItA9xJkNye1/vqBcYH4r/lWK+LSyAruidG92INGkrJ/H2LosPlc7j2iZGxrRPW+HVCLxqK1cwRabP4Edp7PDnl6W1scKUVVCzfHS8jrY0qWp4WOjxLB64CrZXSS+1dWhcblFrdIUd7celZYEDbfTso2A"
`endif