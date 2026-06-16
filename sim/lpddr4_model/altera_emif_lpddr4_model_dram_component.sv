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




/* verilator lint_off ZERODLY */
/* verilator lint_off COMBDLY */
/* verilator lint_off LATCH */
/* verilator lint_off CASEX */
/* verilator lint_off REALCVT */
/* verilator lint_off WIDTHEXPAND */
/* verilator lint_off WIDTHTRUNC */
module altera_emif_lpddr4_model_dram_component
    # (
   parameter PROTOCOL_ENUM                                      = "MEM_PROTOCOL_LPDDR4",
   parameter DEVICE_NAME                                        = "UNINITIALIZED_DEVICE",
   parameter MEM_CK_WIDTH                                       = 1,
   parameter MEM_CS_WIDTH                                       = 1,
   parameter MEM_CA_WIDTH                                       = 6,
   parameter MEM_ROW_ADDR_WIDTH                                 = 1,
   parameter MEM_COL_ADDR_WIDTH                                 = 1,
   parameter MEM_BA_WIDTH                                       = 1,
   parameter MEM_DQ_WIDTH                                       = 16,
   parameter MEM_DQS_WIDTH                                      = 2,
   parameter MEM_DMI_WIDTH                                      = 2,
   parameter MEM_RESET_N_WIDTH                                  = 1,
   parameter MEM_ZQ_WIDTH                                       = 1,
   parameter MEM_DENSITY                                        = "2Gb",
   parameter MEM_CHANNEL_IDX                                    = "-1",
   parameter MEM_RANK_IDX                                       = -1,
   parameter MEM_DEVICE_IDX                                     = -1,
   parameter MEM_VERBOSE                                        = 1
   ) (

   input  logic                                                   mem_ck_t,
   input  logic                                                   mem_ck_c,
   input  logic                                                   mem_cke,
   input  logic                     [MEM_CS_WIDTH-1:0]            mem_cs,
   input  logic                     [MEM_CA_WIDTH -1:0]           mem_ca,
   inout  tri                       [MEM_DQ_WIDTH -1:0]           mem_dq,
   inout  tri                       [MEM_DQS_WIDTH-1:0]           mem_dqs_t,
   inout  tri                       [MEM_DQS_WIDTH-1:0]           mem_dqs_c,
   inout  tri                       [MEM_DMI_WIDTH-1:0]           mem_dmi,
   input  logic                                                   mem_reset_n

   );

   timeunit 1ps;
   timeprecision 1ps;

   localparam  MAX_LATENCY  = 64;
   localparam  OPCODE_WIDTH = 7;

   localparam  MAX_ROW_ADDR_WIDTH  = 19;

   localparam  MEM_DQS_GROUP_SIZE  = MEM_DQ_WIDTH / MEM_DQS_WIDTH;

   localparam  DISABLE_DES_DISPLAY = 1;
   localparam  DISABLE_NOP_DISPLAY = 1;

   bit         command_in_progress     = 1'b0;

   bit         activate_in_progress    = 1'b0;

   typedef enum logic[OPCODE_WIDTH-1:0] {
      OPCODE_DES     = 'b0_xxxxxx,
      OPCODE_MPC     = 'b1_100000,
      OPCODE_NOP     = 'b1_000000,
      OPCODE_PRE     = 'b1_x10000,
      OPCODE_REF     = 'b1_x01000,
      OPCODE_SRE     = 'b1_x11000,
      OPCODE_WR1     = 'b1_x00100,
      OPCODE_SRX     = 'b1_x10100,
      OPCODE_MWR1    = 'b1_001100,
      OPCODE_RD1     = 'b1_x00010,
      OPCODE_CAS2    = 'b1_x10010,
      OPCODE_MRW1    = 'b1_x00110,
      OPCODE_MRW2    = 'b1_x10110,
      OPCODE_MRR1    = 'b1_x01110,
      OPCODE_ACT1    = 'b1_xxxx01
   } OPCODE_TYPE;

   typedef enum {
      DDR_CMD_TYPE_DES,
      DDR_CMD_TYPE_MPC,
      DDR_CMD_TYPE_NOP,
      DDR_CMD_TYPE_PRE,
      DDR_CMD_TYPE_REF,
      DDR_CMD_TYPE_SRE,
      DDR_CMD_TYPE_WR1,
      DDR_CMD_TYPE_SRX,
      DDR_CMD_TYPE_MWR,
      DDR_CMD_TYPE_RD1,
      DDR_CMD_TYPE_CAS2,
      DDR_CMD_TYPE_MRW1,
      DDR_CMD_TYPE_MRW2,
      DDR_CMD_TYPE_MRR1,
      DDR_CMD_TYPE_ACT1,
      DDR_CMD_TYPE_ACT2
   } DDR_CMD_TYPE;

   typedef enum {
      WRITE,
      MASK_WRITE,
      READ,
      MRR,
      MPC,
      NONE
   } CAS_TYPE;


    bit                             mr_REF_mode       = 1'b0;
    bit                             mr_latency_mode   = 1'b0;
    bit [1:0]                       mr_RZQI           = 2'b00;
    bit                             mr_CATR           = 1'b0;

    bit [2:0]                       mr_REF_rate       = 3'b011;
    bit                             mr_TUF            = 1'b0;

    bit [7:0]                       mr_mfg_ID         = 8'b0000_0000;
    bit [7:0]                       mr_rev_ID1        = 8'b0000_0000;
    bit [7:0]                       mr_rev_ID2        = 8'b0000_0000;

    bit [1:0]                       mr_type           = 2'b00;
    bit [3:0]                       mr_density        = 4'b0000;
    bit [1:0]                       mr_io_width       = 2'b00;

    bit [7:0]                       mr_dqs_osc_lsb    = 8'b0000_0000;
    bit [7:0]                       mr_dqs_osc_msb    = 8'b0000_0000;

    bit [2:0]                       mr_mac_value      = 3'b000;
    bit                             mr_unlimited_mac  = 1'b1;

    bit [7:0]                       mr_PPR_resource   = 8'b0000_0000;

    bit [1:0][1:0]                  mr_BL             = 2'b00;
    bit [1:0]                       mr_WR_PRE         = 1'b1;
    bit [1:0]                       mr_RD_PRE         = 1'b0;
    bit [1:0][2:0]                  mr_nWR            = 3'b000;
    bit [1:0]                       mr_RPST           = 1'b0;

    bit [1:0][2:0]                  mr_RL             = 3'b000;
    bit [1:0][2:0]                  mr_WL             = 3'b110;
    bit [1:0]                       mr_WLS            = 1'b0;
    bit                             mr_WR_LEV         = 1'b0;

    bit [1:0]                       mr_PU_Cal         = 1'b1;
    bit [1:0]                       mr_WR_PST         = 1'b0;
    bit                             mr_PPRP           = 1'b0;
    bit [1:0][2:0]                  mr_PDDS           = 3'b110;
    bit [1:0]                       mr_DBI_RD         = 1'b0;
    bit [1:0]                       mr_DBI_WR         = 1'b0;

    bit                             mr_SR_abort       = 1'b0;
    bit                             mr_PPRE           = 1'b0;
    bit [1:0]                       mr_thermal_offset = 2'b00;

    bit                             mr_ZQ_reset       = 1'b0;

    bit [1:0][2:0]                  mr_DQ_ODT         = 3'b000;
    bit [1:0][2:0]                  mr_CA_ODT         = 3'b000;

    bit                             mr_CBT            = 1'b0;
    bit                             mr_RPT            = 1'b0;
    bit                             mr_VRO            = 1'b0;
    bit                             mr_VRCG           = 1'b0;
    bit                             mr_RRO            = 1'b0;
    bit                             mr_DMD            = 1'b0;
    bit                             mr_FSP_WR         = 1'b0;
    bit                             mr_FSP_OP         = 1'b0;

    bit [7:0]                       mr_LBI_DQ_cal     = 8'h55;

    bit [7:0]                       mr_bank_mask      = 8'b0000_0000;

    bit [7:0]                       mr_PASR_mask      = 8'b0000_0000;

    bit [7:0]                       mr_UBI_DQ_cal     = 8'h55;

    bit [1:0][2:0]                  mr_SoC_ODT        = 3'b000;
    bit [1:0]                       mr_ODTE_CK        = 1'b0;
    bit [1:0]                       mr_ODTE_CS        = 1'b0;
    bit [1:0]                       mr_ODTD_CA        = 1'b0;
    bit                             mr_x8ODTD_lower   = 1'b0;
    bit                             mr_x8ODTD_upper   = 1'b0;

    bit [7:0]                       mr_DQS_ITRT       = 8'b0000_0001;

    bit [2:0]                       mr_TRR_mode_BAn   = 3'b000;
    bit                             mr_TRR_mode       = 1'b0;


    bit [1:0][5:0]                  mr_VREF_CA        = 6'b00_0000;
    bit [1:0]                       mr_VREF_CA_range  = 1'b1;
    bit                             mr_CBT_mode       = 1'b0;

    bit [1:0][5:0]                  mr_VREF_DQ        = 6'b00_0000;
    bit [1:0]                       mr_VREF_DQ_range  = 1'b1;



   int                                    read_latency;
   int                                    write_latency;

   int                                    clock_cycle;

   time                                   last_refresh_time;

   time                                   tRCD;
   int                                    tRCD_cycle;
   time                                   tCK;
   time                                   tDQSCK   = 2500;
   time                                   tDQSQ    = 0.18 * (tCK/2);
   int                                    nRTP;
   int                                    nWR;

   bit  write_start              = 'b0;
   bit  write_end                = 'b0;
   bit  write_active             = 'b0;
   bit  write_sample             = 'b0;
   bit  write_sample_q           = 'b0;
   int  write_counter            = 0;
   bit  [MEM_DQ_WIDTH - 1:0] write_data;
   bit  preamble_start           = 'b0;
   bit  preamble_sample          = 'b0;
   bit  preamble_dqs_oen         = 'b0;
   bit  preamble_dqs_toggle      = 'b0;
   int  preamble_counter         = 0;
   bit  read_start               = 'b0;
   bit  read_end                 = 'b0;
   bit  read_active              = 'b0;
   bit  read_sample              = 'b0;
   bit  read_sample_q            = 'b0;
   int  read_counter             = 0;
   bit  [MEM_DQ_WIDTH - 1:0] read_data;
   bit  postamble_start          = 'b0;
   bit  postamble_dqs_oen        = 'b0;
   bit  postamble_dqs_toggle     = 'b0;
   int  postamble_counter        = 0;

   assign   tRCD        = 4*tCK;
   assign   tRCD_cycle  = (tRCD / tCK);

   typedef enum {
      IDLE,
      SELF_REFRESH,
      ACTIVE
   } BANK_STATE;

   typedef struct {
      BANK_STATE                          state;
      bit [MEM_ROW_ADDR_WIDTH-1:0]   opened_row;
      time                                last_ref_time;
      int                                 last_ref_cycle;
      int                                 last_activate_cycle;
      int                                 last_precharge_cycle;
      int                                 last_write_cmd_cycle;
      int                                 last_write_access_cycle;
      int                                 last_read_cmd_cycle;
      int                                 last_read_access_cycle;
   } bank_struct;

   bank_struct bank_status [0:7];

   bit [MEM_DQ_WIDTH-1:0] mem_data[*];

   typedef struct {
      DDR_CMD_TYPE                           cmd_type;
      CAS_TYPE                               cas_type;
      int                                    word_count;
      int                                    burst_length;
      bit   [MEM_BA_WIDTH - 1:0]        bank;
      bit   [MEM_ROW_ADDR_WIDTH - 1:0]  row_address;
      bit   [MEM_COL_ADDR_WIDTH - 1:0]  col_address;
      bit   [OPCODE_WIDTH-1:0]               opcode;
      bit   [6:0]                            mr_index;
      bit   [7:0]                            mr_wdata;
      bit                                    ab_ap;
   } command_struct;

   command_struct                                  active_command;
   command_struct                                  new_command;
   command_struct                                  act1_command;
   command_struct                                  mrw1_command;
   command_struct                                  precharge_command;
   command_struct                                  activate_command;

   DDR_CMD_TYPE                                    write_command_queue[$];
   CAS_TYPE                                        write_cas_type_queue[$];
   int                                             write_word_count_queue[$];
   int                                             write_burst_length_queue[$];
   bit         [MEM_BA_WIDTH - 1:0]                write_bank_queue[$];
   bit         [MEM_ROW_ADDR_WIDTH - 1:0]          write_row_address_queue[$];
   bit         [MEM_COL_ADDR_WIDTH - 1:0]          write_col_address_queue[$];

   DDR_CMD_TYPE                                    read_command_queue[$];
   CAS_TYPE                                        read_cas_type_queue[$];
   int                                             read_word_count_queue[$];
   int                                             read_burst_length_queue[$];
   bit         [MEM_BA_WIDTH - 1:0]                read_bank_queue[$];
   bit         [MEM_ROW_ADDR_WIDTH - 1:0]          read_row_address_queue[$];
   bit         [MEM_COL_ADDR_WIDTH - 1:0]          read_col_address_queue[$];
   bit         [6:0]                               read_register_index_queue[$];
   bit         [7:0]                               read_register_contents_queue[$];

   DDR_CMD_TYPE                                    precharge_command_queue[$];
   bit         [MEM_BA_WIDTH - 1:0]                precharge_bank_queue[$];
   bit                                             precharge_ab_ap_queue[$];

   DDR_CMD_TYPE                                    activate_command_queue[$];
   bit         [MEM_BA_WIDTH - 1:0]                activate_bank_queue[$];
   bit         [MEM_ROW_ADDR_WIDTH - 1:0]          activate_row_address_queue[$];

   bit         [2*MAX_LATENCY + 1:0]              read_command_pipeline;
   bit         [2*MAX_LATENCY + 1:0]              write_command_pipeline;
   bit         [2*MAX_LATENCY + 1:0]              precharge_command_pipeline;
   bit         [2*MAX_LATENCY + 1:0]              activate_command_pipeline;

   reg         [MEM_DQ_WIDTH - 1:0]                mem_dq_from_mem;

   wire        [MEM_DQ_WIDTH - 1:0]                full_dmi_in;
   reg         [MEM_DQS_WIDTH - 1:0]               dmi_out;
   logic       [MEM_DQ_WIDTH - 1:0]                full_dmi_out;

   task automatic init_queue;
      int i;

      while (write_command_queue.size()        > 0)   write_command_queue.delete(0);
      while (write_cas_type_queue.size()       > 0)   write_cas_type_queue.delete(0);
      while (write_word_count_queue.size()     > 0)   write_word_count_queue.delete(0);
      while (write_burst_length_queue.size()   > 0)   write_burst_length_queue.delete(0);
      while (write_row_address_queue.size()    > 0)   write_row_address_queue.delete(0);
      while (write_col_address_queue.size()    > 0)   write_col_address_queue.delete(0);
      while (write_bank_queue.size()           > 0)   write_bank_queue.delete(0);

      while (read_command_queue.size()         > 0)   read_command_queue.delete(0);
      while (read_cas_type_queue.size()        > 0)   read_cas_type_queue.delete(0);
      while (read_word_count_queue.size()      > 0)   read_word_count_queue.delete(0);
      while (read_burst_length_queue.size()    > 0)   read_burst_length_queue.delete(0);
      while (read_row_address_queue.size()     > 0)   read_row_address_queue.delete(0);
      while (read_col_address_queue.size()     > 0)   read_col_address_queue.delete(0);
      while (read_bank_queue.size()            > 0)   read_bank_queue.delete(0);
      while (read_register_index_queue.size()  > 0)   read_register_index_queue.delete(0);
      while (read_register_contents_queue.size() > 0) read_register_contents_queue.delete(0);

      while (precharge_command_queue.size()    > 0)   precharge_command_queue.delete(0);
      while (precharge_bank_queue.size()       > 0)   precharge_bank_queue.delete(0);
      while (precharge_ab_ap_queue.size()      > 0)   precharge_ab_ap_queue.delete(0);

      while (activate_command_queue.size()     > 0)   activate_command_queue.delete(0);
      while (activate_bank_queue.size()        > 0)   activate_bank_queue.delete(0);
      while (activate_row_address_queue.size() > 0)   activate_row_address_queue.delete(0);

      for (i = 0; i < (2 * MAX_LATENCY) + 2; i++) begin
         read_command_pipeline[i]      = 0;
         write_command_pipeline[i]     = 0;
         precharge_command_pipeline[i] = 0;
         activate_command_pipeline[i]  = 0;
      end
   endtask

   task automatic init_banks;
      int i;

      if (MEM_VERBOSE)
         $display("[%0t] [CHANNEL ID=%s] [RANK ID=%0d] [DEVICE ID=%0d] :  Initializing all bank states", $time, MEM_CHANNEL_IDX, MEM_RANK_IDX, MEM_DEVICE_IDX);
      for (i = 0; i < 8; i++) begin
         bank_status[i].state                   = IDLE;
         bank_status[i].opened_row              = '0;
         bank_status[i].last_ref_time           = 0;
         bank_status[i].last_ref_cycle          = 0;
         bank_status[i].last_activate_cycle     = 0;
         bank_status[i].last_precharge_cycle    = 0;
         bank_status[i].last_read_cmd_cycle     = 0;
         bank_status[i].last_read_access_cycle  = 0;
         bank_status[i].last_write_cmd_cycle    = 0;
         bank_status[i].last_write_access_cycle = 0;
      end
   endtask

   always_comb begin
      case(mr_WL[mr_FSP_OP])
         3'b000  : begin write_latency = mr_WLS ? 4  : 4;  nWR = 6;  end
         3'b001  : begin write_latency = mr_WLS ? 8  : 6;  nWR = 10; end
         3'b010  : begin write_latency = mr_WLS ? 12 : 8;  nWR = 16; end
         3'b011  : begin write_latency = mr_WLS ? 18 : 10; nWR = 20; end
         3'b100  : begin write_latency = mr_WLS ? 22 : 12; nWR = 24; end
         3'b101  : begin write_latency = mr_WLS ? 26 : 14; nWR = 30; end
         3'b110  : begin write_latency = mr_WLS ? 30 : 16; nWR = 34; end
         3'b111  : begin write_latency = mr_WLS ? 34 : 18; nWR = 40; end
         default : begin write_latency = 4;  nWR = 6;                end
      endcase
   end

   always_comb begin
      if(mr_DBI_RD[mr_FSP_OP] == 1'b0) begin
         case(mr_RL[mr_FSP_OP])
            3'b000  : begin read_latency = 6;  nRTP = 8;  end
            3'b001  : begin read_latency = 10; nRTP = 8;  end
            3'b010  : begin read_latency = 14; nRTP = 8;  end
            3'b011  : begin read_latency = 20; nRTP = 8;  end
            3'b100  : begin read_latency = 24; nRTP = 10; end
            3'b101  : begin read_latency = 28; nRTP = 12; end
            3'b110  : begin read_latency = 32; nRTP = 14; end
            3'b111  : begin read_latency = 36; nRTP = 16; end
            default : begin read_latency = 6;  nRTP = 8;  end
         endcase
      end
      else if(mr_DBI_RD[mr_FSP_OP] == 1'b1) begin
         case(mr_RL[mr_FSP_OP])
            3'b000  : begin read_latency = 6;  nRTP = 8;  end
            3'b001  : begin read_latency = 12; nRTP = 8;  end
            3'b010  : begin read_latency = 16; nRTP = 8;  end
            3'b011  : begin read_latency = 22; nRTP = 8;  end
            3'b100  : begin read_latency = 28; nRTP = 10; end
            3'b101  : begin read_latency = 32; nRTP = 12; end
            3'b110  : begin read_latency = 36; nRTP = 14; end
            3'b111  : begin read_latency = 40; nRTP = 16; end
            default : begin read_latency = 6;  nRTP = 8;  end
         endcase
      end
      else begin
         if (MEM_VERBOSE)
            $display("[%0t] [CHANNEL ID=%s] [RANK ID=%0d] [DEVICE ID=%0d] :  DBI setting not set", $time, MEM_CHANNEL_IDX, MEM_RANK_IDX, MEM_DEVICE_IDX);
      end
   end

   task automatic cmd_des; if (MEM_VERBOSE && !DISABLE_DES_DISPLAY)  $display("[%0t] [CHANNEL ID=%s] [RANK ID=%0d] [DEVICE ID=%0d] :  DES Command",                        $time, MEM_CHANNEL_IDX, MEM_RANK_IDX, MEM_DEVICE_IDX); endtask
   task automatic cmd_mpc; if (MEM_VERBOSE)                          $display("[%0t] [CHANNEL ID=%s] [RANK ID=%0d] [DEVICE ID=%0d] :  MPC Command (not yet implemented)",  $time, MEM_CHANNEL_IDX, MEM_RANK_IDX, MEM_DEVICE_IDX); endtask
   task automatic cmd_nop; if (MEM_VERBOSE)                          $display("[%0t] [CHANNEL ID=%s] [RANK ID=%0d] [DEVICE ID=%0d] :  NOP Command",                        $time, MEM_CHANNEL_IDX, MEM_RANK_IDX, MEM_DEVICE_IDX); endtask

   task automatic cmd_ref(command_struct cmd);
      if (cmd.ab_ap) begin
         int bank;
         for (bank = 0; bank < 8; bank++) begin
            bank_status[bank].last_ref_cycle = clock_cycle;
            bank_status[bank].last_ref_time  = $time;
         end
         if (MEM_VERBOSE)
            $display("[%0t] [CHANNEL ID=%s] [RANK ID=%0d] [DEVICE ID=%0d] :  REFRESH ALL BANKS", $time, MEM_CHANNEL_IDX, MEM_RANK_IDX, MEM_DEVICE_IDX);
      end else if (!cmd.ab_ap) begin
         bank_status[cmd.bank].last_ref_cycle = clock_cycle;
         bank_status[cmd.bank].last_ref_time  = $time;
         if (MEM_VERBOSE)
            $display("[%0t] [CHANNEL ID=%s] [RANK ID=%0d] [DEVICE ID=%0d] :  REFRESH PER BANK - BANK [ %0h ]", $time, MEM_CHANNEL_IDX, MEM_RANK_IDX, MEM_DEVICE_IDX, cmd.bank);
      end else begin
         $display("[%0t] [CHANNEL ID=%s] [RANK ID=%0d] [DEVICE ID=%0d] :  Internal Error: REFRESH COMMAND CALLED WITHOUT AB BIT SET", $time, MEM_CHANNEL_IDX, MEM_RANK_IDX, MEM_DEVICE_IDX);
         $stop(1);
      end
   endtask

   task automatic cmd_sre; if (MEM_VERBOSE)                          $display("[%0t] [CHANNEL ID=%s] [RANK ID=%0d] [DEVICE ID=%0d] :  SRE Command (not supported)",        $time, MEM_CHANNEL_IDX, MEM_RANK_IDX, MEM_DEVICE_IDX); endtask

   task automatic cmd_wr1();
      if (MEM_VERBOSE)
         $display("[%0t] [CHANNEL ID=%s] [RANK ID=%0d] [DEVICE ID=%0d] :  WRITE-1 Command, to be followed by CAS-2 (WRITE-2) command", $time, MEM_CHANNEL_IDX, MEM_RANK_IDX, MEM_DEVICE_IDX);
   endtask

   task automatic cmd_srx; if (MEM_VERBOSE)                          $display("[%0t] [CHANNEL ID=%s] [RANK ID=%0d] [DEVICE ID=%0d] :  SRX Command (not supported)",        $time, MEM_CHANNEL_IDX, MEM_RANK_IDX, MEM_DEVICE_IDX); endtask
   task automatic cmd_mwr; if (MEM_VERBOSE)                          $display("[%0t] [CHANNEL ID=%s] [RANK ID=%0d] [DEVICE ID=%0d] :  MWR Command, to be followed by CAS-2 (MWR-2) command", $time, MEM_CHANNEL_IDX, MEM_RANK_IDX, MEM_DEVICE_IDX); endtask
   task automatic cmd_rd1();
      if (MEM_VERBOSE)
         $display("[%0t] [CHANNEL ID=%s] [RANK ID=%0d] [DEVICE ID=%0d] :  READ-1 Command, to be followed by CAS-2 (READ-2) command", $time, MEM_CHANNEL_IDX, MEM_RANK_IDX, MEM_DEVICE_IDX);
   endtask

   task automatic cmd_cas(command_struct cmd);
         bit [7:0] register_contents;

      case(cmd.cas_type)
         WRITE :  begin
                     if (MEM_VERBOSE)  $display("[%0t] [CHANNEL ID=%s] [RANK ID=%0d] [DEVICE ID=%0d] :  WRITE (BL%0d) - BANK [ %0h ] - ROW [ %0h ] - COL [ %0h ] - Autoprecharge=%0d",
                        $time, MEM_CHANNEL_IDX, MEM_RANK_IDX, MEM_DEVICE_IDX, cmd.burst_length, cmd.bank, cmd.row_address, cmd.col_address, cmd.ab_ap);

                     write_command_queue.push_back(cmd.cmd_type);
                     write_cas_type_queue.push_back(cmd.cas_type);
                     write_word_count_queue.push_back(0);
                     write_burst_length_queue.push_back(cmd.burst_length);
                     write_row_address_queue.push_back(cmd.row_address);
                     write_col_address_queue.push_back(cmd.col_address);
                     write_bank_queue.push_back(cmd.bank);

                     if (write_latency == 0) begin
                        $display("[%0t] [CHANNEL ID=%s] [RANK ID=%0d] [DEVICE ID=%0d] :  ERROR: Invalid write latency setting", $time, MEM_CHANNEL_IDX, MEM_RANK_IDX, MEM_DEVICE_IDX);
                     end

                     write_command_pipeline[(2*write_latency) + 1] = 1'b1;

                     bank_status[cmd.bank].last_write_cmd_cycle = clock_cycle;

                     if(cmd.ab_ap) begin
                        precharge_command_queue.push_back(cmd.cmd_type);
                        precharge_bank_queue.push_back(cmd.bank);
                        precharge_ab_ap_queue.push_back(0);
                        precharge_command_pipeline[write_latency + (cmd.burst_length)/2 + nWR + 1] = 1;
                     end
                  end
         READ  :  begin
                     if (MEM_VERBOSE)  $display("[%0t] [CHANNEL ID=%s] [RANK ID=%0d] [DEVICE ID=%0d] :  READ (BL%0d) - BANK [ %0h ] - ROW [ %0h ] - COL [ %0h ] - Autoprecharge=%0d",
                        $time, MEM_CHANNEL_IDX, MEM_RANK_IDX, MEM_DEVICE_IDX, cmd.burst_length, cmd.bank, cmd.row_address, cmd.col_address, cmd.ab_ap);

                     read_command_queue.push_back(cmd.cmd_type);
                     read_cas_type_queue.push_back(cmd.cas_type);
                     read_word_count_queue.push_back(0);
                     read_burst_length_queue.push_back(cmd.burst_length);
                     read_row_address_queue.push_back(cmd.row_address);
                     read_col_address_queue.push_back(cmd.col_address);
                     read_bank_queue.push_back(cmd.bank);

                     if (read_latency == 0) begin
                        $display("[%0t] [CHANNEL ID=%s] [RANK ID=%0d] [DEVICE ID=%0d] :  ERROR: Invalid read latency setting", $time, MEM_CHANNEL_IDX, MEM_RANK_IDX, MEM_DEVICE_IDX);
                     end

                     read_command_pipeline[(2*read_latency) + 1] = 1'b1;

                     bank_status[cmd.bank].last_read_cmd_cycle = clock_cycle;

                     if(cmd.ab_ap) begin
                        precharge_command_queue.push_back(cmd.cmd_type);
                        precharge_bank_queue.push_back(cmd.bank);
                        precharge_ab_ap_queue.push_back(0);
                        precharge_command_pipeline[nRTP] = 1;
                     end
                  end
         MASK_WRITE : begin
                     if (MEM_VERBOSE)  $display("[%0t] [CHANNEL ID=%s] [RANK ID=%0d] [DEVICE ID=%0d] :  MASK WRITE (BL%0d) - BANK [ %0h ] - ROW [ %0h ] - COL [ %0h ] - Autoprecharge=%0d",
                        $time, MEM_CHANNEL_IDX, MEM_RANK_IDX, MEM_DEVICE_IDX, cmd.burst_length, cmd.bank, cmd.row_address, cmd.col_address, cmd.ab_ap);

                     write_command_queue.push_back(cmd.cmd_type);
                     write_cas_type_queue.push_back(cmd.cas_type);
                     write_word_count_queue.push_back(0);
                     write_burst_length_queue.push_back(cmd.burst_length);
                     write_row_address_queue.push_back(cmd.row_address);
                     write_col_address_queue.push_back(cmd.col_address);
                     write_bank_queue.push_back(cmd.bank);

                     if (write_latency == 0) begin
                        $display("[%0t] [CHANNEL ID=%s] [RANK ID=%0d] [DEVICE ID=%0d] :  ERROR: Invalid write latency setting", $time, MEM_CHANNEL_IDX, MEM_RANK_IDX, MEM_DEVICE_IDX);
                     end

                     write_command_pipeline[(2*write_latency) + 1] = 1'b1;

                     bank_status[cmd.bank].last_write_cmd_cycle = clock_cycle;

                     if(cmd.ab_ap) begin
                        precharge_command_queue.push_back(cmd.cmd_type);
                        precharge_bank_queue.push_back(cmd.bank);
                        precharge_ab_ap_queue.push_back(0);
                        precharge_command_pipeline[write_latency + (cmd.burst_length)/2 + nWR + 1] = 1;
                     end
                  end
         MRR   :  begin
                     if (MEM_VERBOSE)
                        $display("[%0t] [CHANNEL ID=%s] [RANK ID=%0d] [DEVICE ID=%0d] :  MRR/CAS-2 Command", $time, MEM_CHANNEL_IDX, MEM_RANK_IDX, MEM_DEVICE_IDX);

                     if(cmd.mr_index == 7'h01) begin
                        if (MEM_VERBOSE)
                           $display("[%0t] [CHANNEL ID=%s] [RANK ID=%0d] [DEVICE ID=%0d] :  MRR [ %0d ] - Scheduled", $time, MEM_CHANNEL_IDX, MEM_RANK_IDX, MEM_DEVICE_IDX, cmd.mr_index);

                        read_command_queue.push_back(cmd.cmd_type);
                        read_cas_type_queue.push_back(cmd.cas_type);
                        read_command_queue.push_back(DDR_CMD_TYPE_MRR1);
                        read_register_index_queue.push_back(cmd.mr_index);
                        read_burst_length_queue.push_back(cmd.burst_length);
                        case(cmd.mr_index)
                           7'h00 : register_contents = {mr_CATR, 2'b00, mr_RZQI, 1'b0, mr_latency_mode, mr_REF_mode};
                           7'h01 : register_contents = {mr_RPST[mr_FSP_OP], mr_nWR[mr_FSP_OP][2:0], mr_RD_PRE[mr_FSP_OP], mr_WR_PRE[mr_FSP_OP], mr_BL[mr_FSP_OP][1:0]};
                           7'h02 : register_contents = {mr_WR_LEV, mr_WLS[mr_FSP_OP], mr_WL[mr_FSP_OP][2:0], mr_RL[mr_FSP_OP][2:0]};
                           7'h03 : register_contents = {mr_DBI_WR[mr_FSP_OP], mr_DBI_RD[mr_FSP_OP], mr_PDDS[mr_FSP_OP][2:0], mr_PPRP, mr_WR_PST[mr_FSP_OP], mr_PU_Cal[mr_FSP_OP]};
                           7'h04 : register_contents = {mr_TUF, mr_thermal_offset, mr_PPRE, mr_SR_abort, mr_REF_rate};
                           7'h05 : register_contents = {mr_mfg_ID};
                           7'h06 : register_contents = {mr_rev_ID1};
                           7'h07 : register_contents = {mr_rev_ID2};
                           7'h08 : register_contents = {mr_io_width, mr_density, mr_type};
                           7'h09 : register_contents = {8'b00000000};
                           7'h0A : register_contents = {7'b0000000, mr_ZQ_reset};
                           7'h0B : register_contents = {1'b0, mr_CA_ODT[mr_FSP_OP][2:0], 1'b0, mr_DQ_ODT[mr_FSP_OP][2:0]};
                           7'h0C : register_contents = {mr_CBT_mode, mr_VREF_CA_range[mr_FSP_OP], mr_VREF_CA[mr_FSP_OP][5:0]};
                           7'h0D : register_contents = {mr_FSP_OP, mr_FSP_WR, mr_DMD, mr_RRO, mr_VRCG, mr_VRO, mr_RPT, mr_CBT};
                           7'h0E : register_contents = {1'b0, mr_VREF_DQ_range[mr_FSP_OP], mr_VREF_DQ[mr_FSP_OP][5:0]};
                           7'h0F : register_contents = {mr_LBI_DQ_cal};
                           7'h10 : register_contents = {mr_bank_mask};
                           7'h11 : register_contents = {mr_PASR_mask};
                           7'h12 : register_contents = {mr_dqs_osc_lsb};
                           7'h13 : register_contents = {mr_dqs_osc_msb};
                           7'h14 : register_contents = {mr_UBI_DQ_cal};
                           7'h15 : register_contents = {8'b00000000};
                           7'h16 : register_contents = {mr_x8ODTD_upper, mr_x8ODTD_lower, mr_ODTD_CA[mr_FSP_OP], mr_ODTE_CS[mr_FSP_OP], mr_ODTE_CK[mr_FSP_OP], mr_SoC_ODT[mr_FSP_OP][1:0]};
                           7'h17 : register_contents = {mr_DQS_ITRT};
                           7'h18 : register_contents = {mr_TRR_mode, mr_TRR_mode_BAn, mr_unlimited_mac, mr_mac_value};
                           7'h19 : register_contents = {mr_PPR_resource};
                           7'h1A : register_contents = {8'b00000000};
                           7'h1B : register_contents = {8'b00000000};
                           7'h1C : register_contents = {8'b00000000};
                           7'h1D : register_contents = {8'b00000000};
                           7'h1E : register_contents = {8'b00000000};
                           7'h1F : register_contents = {8'b00000000};
                           7'h20 : register_contents = {8'b00000000};
                           7'h21 : register_contents = {8'b00000000};
                           7'h22 : register_contents = {8'b00000000};
                           7'h23 : register_contents = {8'b00000000};
                           7'h24 : register_contents = {8'b00000000};
                           7'h25 : register_contents = {8'b00000000};
                           7'h26 : register_contents = {8'b00000000};
                           7'h27 : register_contents = {8'b00000000};
                           7'h28 : register_contents = {8'b00000000};
                           7'h29 : register_contents = {8'b00000000};
                           7'h2A : register_contents = {8'b00000000};
                           7'h2B : register_contents = {8'b00000000};
                           7'h2C : register_contents = {8'b00000000};
                           7'h2D : register_contents = {8'b00000000};
                           7'h2E : register_contents = {8'b00000000};
                           7'h2F : register_contents = {8'b00000000};
                           7'h30 : register_contents = {8'b00000000};
                           7'h31 : register_contents = {8'b00000000};
                           7'h32 : register_contents = {8'b00000000};
                           7'h33 : register_contents = {8'b00000000};
                           7'h34 : register_contents = {8'b00000000};
                           7'h35 : register_contents = {8'b00000000};
                           7'h36 : register_contents = {8'b00000000};
                           7'h37 : register_contents = {8'b00000000};
                           7'h38 : register_contents = {8'b00000000};
                           7'h39 : register_contents = {8'b00000000};
                           7'h3A : register_contents = {8'b00000000};
                           7'h3B : register_contents = {8'b00000000};
                           7'h3C : register_contents = {8'b00000000};
                           7'h3D : register_contents = {8'b00000000};
                           7'h3E : register_contents = {8'b00000000};
                           7'h3F : register_contents = {8'b00000000};
                           default: if (MEM_VERBOSE) $display("[%0t] [CHANNEL ID=%s] [RANK ID=%0d] [DEVICE ID=%0d] :  MRR Command - MRR [ %0d ] - Not Yet Implemented", $time, MEM_CHANNEL_IDX, MEM_RANK_IDX, MEM_DEVICE_IDX, cmd.mr_index);
                        endcase
                        read_register_contents_queue.push_back(register_contents);
                     end

                     if (read_latency == 0) begin
                        $display("[%0t] [CHANNEL ID=%s] [RANK ID=%0d] [DEVICE ID=%0d] :  Internal Error: Invalid read latency setting", $time, MEM_CHANNEL_IDX, MEM_RANK_IDX, MEM_DEVICE_IDX);
                        $stop(1);
                     end

                     read_command_pipeline[(2*read_latency) + 1] = 1;
                  end
         MPC   :  begin
                     if (MEM_VERBOSE)  $display("[%0t] [CHANNEL ID=%s] [RANK ID=%0d] [DEVICE ID=%0d] :  MPC-2 Command (not yet implemented)", $time, MEM_CHANNEL_IDX, MEM_RANK_IDX, MEM_DEVICE_IDX);
                  end
         default: begin
                     if (MEM_VERBOSE)  $display("[%0t] [CHANNEL ID=%s] [RANK ID=%0d] [DEVICE ID=%0d] :  ERROR: CAS-2 Command called without specifying command type", $time, MEM_CHANNEL_IDX, MEM_RANK_IDX, MEM_DEVICE_IDX);
         end
      endcase

   endtask

   task automatic cmd_mrw(command_struct cmd);
      if ((cmd.mr_index == 6'h00) ||
          (cmd.mr_index == 6'h05) ||
          (cmd.mr_index == 6'h06) ||
          (cmd.mr_index == 6'h07) ||
          (cmd.mr_index == 6'h08) ||
          (cmd.mr_index == 6'h12) ||
          (cmd.mr_index == 6'h13) ||
          (cmd.mr_index == 6'h19))
      begin
         if (MEM_VERBOSE)
            $display("[%0t] [CHANNEL ID=%s] [RANK ID=%0d] [DEVICE ID=%0d] :  MRW Command - MR[ %0d ] -> %0b :  ERROR: write to read-only register", $time, MEM_CHANNEL_IDX, MEM_RANK_IDX, MEM_DEVICE_IDX, cmd.mr_index, cmd.mr_wdata);
      end else

      if ((cmd.mr_index == 6'h01) ||
          (cmd.mr_index == 6'h02) ||
          (cmd.mr_index == 6'h03) ||
          (cmd.mr_index == 6'h04) ||
          (cmd.mr_index == 6'h09) ||
          (cmd.mr_index == 6'h0A) ||
          (cmd.mr_index == 6'h0B) ||
          (cmd.mr_index == 6'h0C) ||
          (cmd.mr_index == 6'h0D) ||
          (cmd.mr_index == 6'h0E) ||
          (cmd.mr_index == 6'h0F) ||
          (cmd.mr_index == 6'h10) ||
          (cmd.mr_index == 6'h11) ||
          (cmd.mr_index == 6'h14) ||
          (cmd.mr_index == 6'h16) ||
          (cmd.mr_index == 6'h17) ||
          (cmd.mr_index == 6'h18))
      begin
         if (MEM_VERBOSE)
            $display("[%0t] [CHANNEL ID=%s] [RANK ID=%0d] [DEVICE ID=%0d] :  MRW Command - MR[ %0d ] -> %0b", $time, MEM_CHANNEL_IDX, MEM_RANK_IDX, MEM_DEVICE_IDX, cmd.mr_index, cmd.mr_wdata);
         case(cmd.mr_index)
            6'h01 : begin
                           mr_BL                [mr_FSP_WR] = cmd.mr_wdata[1:0];
                           mr_WR_PRE            [mr_FSP_WR] = cmd.mr_wdata[2];
                           mr_RD_PRE            [mr_FSP_WR] = cmd.mr_wdata[3];
                           mr_nWR               [mr_FSP_WR] = cmd.mr_wdata[6:4];
                           mr_RPST              [mr_FSP_WR] = cmd.mr_wdata[7];
                    end
            6'h02 : begin
                           mr_RL                [mr_FSP_WR] = cmd.mr_wdata[2:0];
                           mr_WL                [mr_FSP_WR] = cmd.mr_wdata[5:3];
                           mr_WLS               [mr_FSP_WR] = cmd.mr_wdata[6];
                           mr_WR_LEV                        = cmd.mr_wdata[7];
                    end
            6'h03 : begin
                           mr_PU_Cal            [mr_FSP_WR] = cmd.mr_wdata[0];
                           mr_WR_PST            [mr_FSP_WR] = cmd.mr_wdata[1];
                           mr_PPRP                          = cmd.mr_wdata[2];
                           mr_PDDS              [mr_FSP_WR] = cmd.mr_wdata[5:3];
                           mr_DBI_RD            [mr_FSP_WR] = cmd.mr_wdata[6];
                           mr_DBI_WR            [mr_FSP_WR] = cmd.mr_wdata[7];
                    end
            6'h04 : begin
                           mr_SR_abort                      = cmd.mr_wdata[3];
                           mr_PPRE                          = cmd.mr_wdata[4];
                           mr_thermal_offset                = cmd.mr_wdata[6:5];
                    end
            6'h09 : begin
                           if (MEM_VERBOSE)
                              $display("[%0t] [CHANNEL ID=%s] [RANK ID=%0d] [DEVICE ID=%0d] :  MRW Command - MR[ %0d ] -> %0b :  ERROR: attempting to write to MR9 which is a vendor specific test register",
                                       $time, MEM_CHANNEL_IDX, MEM_RANK_IDX, MEM_DEVICE_IDX, cmd.mr_index, cmd.mr_wdata);
                    end
            6'h0A : begin
                           mr_ZQ_reset                      = cmd.mr_wdata[0];
                    end
            6'h0B : begin
                           mr_DQ_ODT            [mr_FSP_WR] = cmd.mr_wdata[2:0];
                           mr_CA_ODT            [mr_FSP_WR] = cmd.mr_wdata[6:4];
                    end
            6'h0C : begin
                           mr_VREF_CA           [mr_FSP_WR] = cmd.mr_wdata[5:0];
                           mr_VREF_CA_range     [mr_FSP_WR] = cmd.mr_wdata[6];
                           mr_CBT_mode                      = cmd.mr_wdata[7];
                    end
            6'h0D : begin
                           mr_CBT                           = cmd.mr_wdata[0];
                           mr_RPT                           = cmd.mr_wdata[1];
                           mr_VRO                           = cmd.mr_wdata[2];
                           mr_VRCG                          = cmd.mr_wdata[3];
                           mr_RRO                           = cmd.mr_wdata[4];
                           mr_DMD                           = cmd.mr_wdata[5];
                           mr_FSP_WR                        = cmd.mr_wdata[6];
                           mr_FSP_OP                        = cmd.mr_wdata[7];
                    end
            6'h0E : begin
                           mr_VREF_DQ           [mr_FSP_WR] = cmd.mr_wdata[5:0];
                           mr_VREF_DQ_range     [mr_FSP_WR] = cmd.mr_wdata[6];
                    end
            6'h0F : begin
                           mr_LBI_DQ_cal                    = cmd.mr_wdata[7:0];
                    end
            6'h10 : begin
                           mr_bank_mask                     = cmd.mr_wdata[7:0];
                    end
            6'h11 : begin
                           mr_PASR_mask                     = cmd.mr_wdata[7:0];
                    end
            6'h14 : begin
                           mr_UBI_DQ_cal                    = cmd.mr_wdata[7:0];
                    end
            6'h16 : begin
                           mr_SoC_ODT           [mr_FSP_WR] = cmd.mr_wdata[2:0];
                           mr_ODTE_CK           [mr_FSP_WR] = cmd.mr_wdata[3];
                           mr_ODTE_CS           [mr_FSP_WR] = cmd.mr_wdata[4];
                           mr_ODTD_CA           [mr_FSP_WR] = cmd.mr_wdata[5];
                           mr_x8ODTD_lower                  = cmd.mr_wdata[6];
                           mr_x8ODTD_upper                  = cmd.mr_wdata[7];
                    end
            6'h17 : begin
                           mr_DQS_ITRT                      = cmd.mr_wdata[7:0];
                    end
            6'h18 : begin
                           mr_TRR_mode_BAn                  = cmd.mr_wdata[6:4];
                           mr_TRR_mode                      = cmd.mr_wdata[7];
                    end
            default : if (MEM_VERBOSE) $display("[%0t] [CHANNEL ID=%s] [RANK ID=%0d] [DEVICE ID=%0d] :  MRW Command - MR[ %0d ] -> %0h - Invalid Mode Register Address or Register Not Supported", $time, MEM_CHANNEL_IDX, MEM_RANK_IDX, MEM_DEVICE_IDX, cmd.mr_index, cmd.mr_wdata);
         endcase
      end else
      begin
             if (MEM_VERBOSE) $display("[%0t] [CHANNEL ID=%s] [RANK ID=%0d] [DEVICE ID=%0d] :  MRW Command - MR[ %0d ] -> %0h - Invalid Mode Register Address or Register Not Supported", $time, MEM_CHANNEL_IDX, MEM_RANK_IDX, MEM_DEVICE_IDX, cmd.mr_index, cmd.mr_wdata);
      end

   endtask

   task automatic cmd_set_activate(command_struct cmd);
      if(MEM_VERBOSE)
         $display("[%0t] [CHANNEL ID=%s] [RANK ID=%0d] [DEVICE ID=%0d] :  ACTIVATE (queue) - BA [%0h] - ROW [ %0h ]", $time, MEM_CHANNEL_IDX, MEM_RANK_IDX, MEM_DEVICE_IDX, cmd.bank, cmd.row_address);
      activate_command_queue.push_back(cmd.cmd_type);
      activate_row_address_queue.push_back(cmd.row_address);
      activate_bank_queue.push_back(cmd.bank);
      activate_command_pipeline[ 2*tRCD_cycle - 1 ] = 1;
      bank_status[cmd.bank].last_activate_cycle = clock_cycle;
   endtask

   task automatic cmd_activate(command_struct cmd);
      if (MEM_VERBOSE)
         $display("[%0t] [CHANNEL ID=%s] [RANK ID=%0d] [DEVICE ID=%0d] :  ACTIVATE (execute) - BA [%0h] - ROW [ %0h ] ", $time, MEM_CHANNEL_IDX, MEM_RANK_IDX, MEM_DEVICE_IDX, cmd.bank, cmd.row_address);
      if (bank_status[cmd.bank].state != IDLE)
         $display("[%0t] [CHANNEL ID=%s] [RANK ID=%0d] [DEVICE ID=%0d] :  ACTIVATE (execute) - BA [%0h] :  ERROR: attempting to activate bank from non-Idle state", $time, MEM_CHANNEL_IDX, MEM_RANK_IDX, MEM_DEVICE_IDX, cmd.bank);
      bank_status[cmd.bank].state        = ACTIVE;
      bank_status[cmd.bank].opened_row   = cmd.row_address;
   endtask

   task automatic cmd_precharge(command_struct cmd);
      if (cmd.ab_ap) begin
         if (MEM_VERBOSE)
            $display("[%0t] [CHANNEL ID=%s] [RANK ID=%0d] [DEVICE ID=%0d] :  PRECHARGE ALL BANKS", $time, MEM_CHANNEL_IDX, MEM_RANK_IDX, MEM_DEVICE_IDX);
         for(int i = 0; i < 8; i++) begin
            bank_status[i].state = IDLE;
         end
         bank_status[cmd.bank].opened_row           = 'b0;
         bank_status[cmd.bank].last_precharge_cycle = clock_cycle;
      end else begin
         if (MEM_VERBOSE)
            $display("[%0t] [CHANNEL ID=%s] [RANK ID=%0d] [DEVICE ID=%0d] :  PRECHARGE BANK - BA [%0h]", $time, MEM_CHANNEL_IDX, MEM_RANK_IDX, MEM_DEVICE_IDX, cmd.bank);
         bank_status[cmd.bank].state                = IDLE;
         bank_status[cmd.bank].opened_row           = 'b0;
         bank_status[cmd.bank].last_precharge_cycle = clock_cycle;
      end
   endtask

   task automatic cmd_unknown(command_struct cmd); if (MEM_VERBOSE) $display("[%0t] [CHANNEL ID=%s] [RANK ID=%0d] [DEVICE ID=%0d] :  ERROR: Unknown Command (OPCODE %b). Command ignored.", $time, MEM_CHANNEL_IDX, MEM_RANK_IDX, MEM_DEVICE_IDX, cmd.opcode); endtask

   bit   ck_t_sample_enable         = 1'b0;
   bit   ck_t_sample_enable_delay   = 1'b0;
   time  time_stamp;

   initial begin
      $display("Altera Generic LPDDR4 Memory Model");
      clock_cycle = 0;

      init_queue();
      init_banks();
      mem_data.delete();

   end

   always @ (posedge mem_ck_t) begin
      clock_cycle = clock_cycle + 1;

      ck_t_sample_enable_delay = ck_t_sample_enable;

      if (clock_cycle % 100 == 99)
         ck_t_sample_enable = 1'b1;
      else
         ck_t_sample_enable = 1'b0;

      if (ck_t_sample_enable == 1'b1) begin
         time_stamp = $time;
      end

      if (ck_t_sample_enable_delay && !ck_t_sample_enable) begin
         tCK = $time - time_stamp;
      end
   end

   always @ (posedge mem_ck_t or negedge mem_ck_t) begin
       if(mem_ck_t)
           cmd_int_p;
       cmd_gen_b;
       if(mem_ck_t)
           preamble_cnt_p;
       fork
           write_cnt_b;
           read_cnt_b;
       join
       if(mem_ck_t)
           postamble_cnt_p;
   end

   bit [MAX_ROW_ADDR_WIDTH-1:0] row_address_max_width;

   task automatic cmd_int_p;

      if(mem_cs) begin

         if (!command_in_progress) begin
            new_command.cas_type       = NONE;
            new_command.word_count     = 0;
            new_command.burst_length   = 0;
            new_command.bank           = 0;
            new_command.col_address    = 'b0;
            new_command.row_address    = 'b0;
            new_command.mr_index       = 'b0;
            new_command.mr_wdata       = 'b0;
            new_command.ab_ap          = 'b0;
         end

         if (!activate_in_progress) begin
            new_command.opcode[OPCODE_WIDTH-1]   = 1'b1;
            new_command.opcode[OPCODE_WIDTH-2:0] = mem_ca;
         end

         casex(new_command.opcode)
            OPCODE_MPC  : begin new_command.cmd_type = DDR_CMD_TYPE_MPC;
                                                                                                                              command_in_progress = 1'b1;
                          end
            OPCODE_NOP  : begin new_command.cmd_type = DDR_CMD_TYPE_NOP;
                                                                                                                              command_in_progress = 1'b1;
                          end
            OPCODE_PRE  : begin new_command.cmd_type = DDR_CMD_TYPE_PRE;
                                                                                 new_command.ab_ap              = mem_ca[5];
                                                                                                                              command_in_progress = 1'b1;
                          end
            OPCODE_REF  : begin new_command.cmd_type = DDR_CMD_TYPE_REF;
                                                                                 new_command.ab_ap              = mem_ca[5];
                                                                                                                              command_in_progress = 1'b1;
                          end
            OPCODE_SRE  : begin new_command.cmd_type = DDR_CMD_TYPE_SRE;
                                                                                                                              command_in_progress = 1'b1;
                          end
            OPCODE_WR1  : begin new_command.cmd_type = DDR_CMD_TYPE_WR1;
                                                                                 if      (mr_BL[mr_FSP_OP] == 2'b00) new_command.burst_length = 16;
                                                                                 else if (mr_BL[mr_FSP_OP] == 2'b01) new_command.burst_length = 32;
                                                                                 else if (mr_BL[mr_FSP_OP] == 2'b10) new_command.burst_length = (mem_ca[5] ? 32 : 16);
                                                                                 else $display("[%0t] [CHANNEL ID=%s] [RANK ID=%0d] [DEVICE ID=%0d] :  Internal Error: Burst Length set incorrectly in MR1", $time, MEM_CHANNEL_IDX, MEM_RANK_IDX, MEM_DEVICE_IDX);
                                                                                 new_command.cas_type           = WRITE;
                                                                                                                              command_in_progress = 1'b1;
                          end
            OPCODE_SRX  : begin new_command.cmd_type = DDR_CMD_TYPE_SRX;
                                                                                                                              command_in_progress = 1'b1;
                          end
            OPCODE_RD1  : begin new_command.cmd_type = DDR_CMD_TYPE_RD1;
                                                                                 if      (mr_BL[mr_FSP_OP] == 2'b00) new_command.burst_length = 16;
                                                                                 else if (mr_BL[mr_FSP_OP] == 2'b01) new_command.burst_length = 32;
                                                                                 else if (mr_BL[mr_FSP_OP] == 2'b10) new_command.burst_length = (mem_ca[5] ? 32 : 16);
                                                                                 else $display("[%0t] [CHANNEL ID=%s] [RANK ID=%0d] [DEVICE ID=%0d] :  Internal Error: Burst Length set incorrectly in MR1", $time, MEM_CHANNEL_IDX, MEM_RANK_IDX, MEM_DEVICE_IDX);
                                                                                 new_command.cas_type           = READ;
                                                                                                                              command_in_progress = 1'b1;
                          end
            OPCODE_CAS2 : begin new_command.cmd_type = DDR_CMD_TYPE_CAS2;
                                                                                 new_command.col_address[8]     = mem_ca[5];
                          end
            OPCODE_MWR1 : begin new_command.cmd_type = DDR_CMD_TYPE_MWR;
                                                                                 if      (mr_BL[mr_FSP_OP] == 2'b00) new_command.burst_length = 16;
                                                                                 else if (mr_BL[mr_FSP_OP] == 2'b01) new_command.burst_length = 32;
                                                                                 else if (mr_BL[mr_FSP_OP] == 2'b10) new_command.burst_length = (mem_ca[5] ? 32 : 16);
                                                                                 else $display("[%0t] [CHANNEL ID=%s] [RANK ID=%0d] [DEVICE ID=%0d] :  Internal Error: Burst Length set incorrectly in MR1", $time, MEM_CHANNEL_IDX, MEM_RANK_IDX, MEM_DEVICE_IDX);
                                                                                 new_command.cas_type           = MASK_WRITE;
                                                                                                                              command_in_progress = 1'b1;
                          end
            OPCODE_MRW1 : begin new_command.cmd_type = DDR_CMD_TYPE_MRW1;
                                                                                 new_command.mr_wdata[7]        = mem_ca[5];
                                                                                                                              command_in_progress = 1'b1;
                          end
            OPCODE_MRW2 : begin new_command.cmd_type = DDR_CMD_TYPE_MRW2;
                                                                                 new_command.mr_wdata[6]        = mem_ca[5];
                          end
            OPCODE_MRR1 : begin new_command.cmd_type = DDR_CMD_TYPE_MRR1;
                                                                                 new_command.burst_length = 16;
                                                                                 new_command.cas_type           = MRR;
                                                                                                                              command_in_progress = 1'b1;
                          end
            OPCODE_ACT1 : begin
                              if (!activate_in_progress) begin
                                 new_command.cmd_type = DDR_CMD_TYPE_ACT1;

                                                                                 row_address_max_width        = 0;
                                                                                 row_address_max_width[15:12] = mem_ca[5:2];
                                                                                                                              command_in_progress = 1'b1;
                              end else if (activate_in_progress) begin
                                 new_command.cmd_type = DDR_CMD_TYPE_ACT2;

                                                                                 row_address_max_width[18:17] = mem_ca[1:0];
                                                                                 row_address_max_width[9:6]   = mem_ca[5:2];
                              end else begin
                                 $display("[%0t] [CHANNEL ID=%s] [RANK ID=%0d] [DEVICE ID=%0d] :  Internal Error: activate_in_progress flag was not reset to false", $time, MEM_CHANNEL_IDX, MEM_RANK_IDX, MEM_DEVICE_IDX);
                                 $stop(1);
                              end
                          end
            OPCODE_DES  : begin new_command.cmd_type = DDR_CMD_TYPE_DES;   end
            default     : begin cmd_unknown(new_command);                  end
         endcase
      end

      else if(!mem_cs && command_in_progress) begin
         casex(new_command.opcode)
            OPCODE_MPC  : begin
                                                                                                                              command_in_progress = 1'b0;
                                cmd_mpc();
                          end
            OPCODE_NOP  : begin
                                                                                                                              command_in_progress = 1'b0;
                                cmd_nop();
                          end
            OPCODE_PRE  : begin
                                                                                 new_command.bank              = mem_ca[2:0];
                                                                                                                              command_in_progress = 1'b0;
                                cmd_precharge(new_command);
                          end
            OPCODE_REF  : begin
                                                                                 new_command.bank              = mem_ca[2:0];
                                                                                                                              command_in_progress = 1'b0;
                                cmd_ref(new_command);
                          end
            OPCODE_SRE  : begin
                                                                                                                              command_in_progress = 1'b0;
                                cmd_sre();
                          end
            OPCODE_WR1  : begin
                                                                                 new_command.bank              = mem_ca[2:0];
                                                                                 new_command.col_address[9]    = mem_ca[4];
                                                                                 new_command.ab_ap             = mem_ca[5];
                                cmd_wr1();
                          end
            OPCODE_SRX  : begin
                                                                                                                              command_in_progress = 1'b0;
                                cmd_srx();
                          end
            OPCODE_MWR1 : begin
                                                                                 new_command.bank              = mem_ca[2:0];
                                                                                 new_command.col_address[9]    = mem_ca[4];
                                                                                 new_command.ab_ap             = mem_ca[5];
                                cmd_mwr();
                          end
            OPCODE_RD1  : begin
                                                                                 new_command.bank              = mem_ca[2:0];
                                                                                 new_command.col_address[9]    = mem_ca[4];
                                                                                 new_command.ab_ap             = mem_ca[5];
                                cmd_rd1();
                          end
            OPCODE_CAS2 : begin
                                                                                 new_command.col_address[7:2]  = mem_ca;
                                                                                 new_command.col_address[1:0]  = 2'b00;
                                                                                 new_command.row_address       = bank_status[new_command.bank].opened_row;
                                                                                                                              command_in_progress = 1'b0;
                                cmd_cas(new_command);
                          end
            OPCODE_MRW1 : begin new_command.mr_index[5:0] = mem_ca[5:0];
                                                                                 new_command.mr_index = mem_ca;
                          end
            OPCODE_MRW2 : begin new_command.mr_wdata[5:0] = mem_ca[5:0];
                                                                                                                              command_in_progress = 1'b0;
                                cmd_mrw(new_command);
                          end
            OPCODE_MRR1  : begin new_command.mr_index[5:0] = mem_ca[5:0];
                           end
            OPCODE_ACT1 : begin
                              if (!activate_in_progress) begin
                                                                                 new_command.bank             = mem_ca[2:0];
                                                                                 row_address_max_width[16]    = mem_ca[3];
                                                                                 row_address_max_width[11:10] = mem_ca[5:4];
                                                                                                                              activate_in_progress = 1'b1;
                              end else if (activate_in_progress) begin
                                                                                 row_address_max_width[5:0]   = mem_ca[5:0];
                                                                                 new_command.row_address      = row_address_max_width[MEM_ROW_ADDR_WIDTH-1:0];
                                                                                                                              command_in_progress = 1'b0;
                                                                                                                              activate_in_progress  = 1'b0;
                                 cmd_set_activate(new_command);
                              end else begin
                                 $display("[%0t] [CHANNEL ID=%s] [RANK ID=%0d] [DEVICE ID=%0d] :  Internal Error: activate_in_progress flag was not reset to false", $time, MEM_CHANNEL_IDX, MEM_RANK_IDX, MEM_DEVICE_IDX);
                                 $stop(1);
                              end
                          end
            default     : begin cmd_unknown(new_command); end
         endcase
      end

      else if(!mem_cs && !command_in_progress) begin
         new_command.cmd_type = DDR_CMD_TYPE_DES;
         cmd_des();
         command_in_progress = 1'b0;
      end

      else begin
      end
   endtask

   task automatic cmd_gen_b;

      read_command_pipeline      = read_command_pipeline      >> 1;
      write_command_pipeline     = write_command_pipeline     >> 1;
      activate_command_pipeline  = activate_command_pipeline  >> 1;
      precharge_command_pipeline = precharge_command_pipeline >> 1;

      if (read_command_pipeline[0]) begin
         if (read_command_queue.size() == 0) begin
            $display("[%0t] [CHANNEL ID=%s] [RANK ID=%0d] [DEVICE ID=%0d] :  Internal Error: READ command queue empty but READ commands expected!",   $time, MEM_CHANNEL_IDX, MEM_RANK_IDX, MEM_DEVICE_IDX);
            $stop(1);
         end
      end

      if (write_command_pipeline[0]) begin
         if (write_command_queue.size() == 0) begin
            $display("[%0t] [CHANNEL ID=%s] [RANK ID=%0d] [DEVICE ID=%0d] :  Internal Error: WRITE command queue empty but WRITE commands expected!", $time, MEM_CHANNEL_IDX, MEM_RANK_IDX, MEM_DEVICE_IDX);
            $stop(1);
         end
      end




         if (read_command_pipeline[0]) begin
            active_command.cmd_type     = read_command_queue.pop_front();
            active_command.cas_type     = read_cas_type_queue.pop_front();

            if (active_command.cas_type == MRR) begin
               active_command.mr_wdata     = read_register_contents_queue.pop_front();
               active_command.mr_index     = read_register_index_queue.pop_front();
               active_command.burst_length = read_burst_length_queue.pop_front();
            end else begin
               active_command.word_count   = read_word_count_queue.pop_front();
               active_command.burst_length = read_burst_length_queue.pop_front();
               active_command.bank         = read_bank_queue.pop_front();
               active_command.col_address  = read_col_address_queue.pop_front();
               active_command.row_address  = read_row_address_queue.pop_front();
            end

            /*if ((active_command.cmd_type != DDR_CMD_TYPE_RD16) &&
                (active_command.cmd_type != DDR_CMD_TYPE_RD32)) begin
               $display("[%0t] [CHANNEL ID=%s] [RANK ID=%0d] [DEVICE ID=%0d] :  Internal Error: Expected READ command not in queue!", $time, MEM_CHANNEL_IDX, MEM_RANK_IDX, MEM_DEVICE_IDX);
               $stop(1);
            end*/


         end else if (write_command_pipeline[0]) begin
            active_command.cmd_type     = write_command_queue.pop_front();
            active_command.cas_type     = write_cas_type_queue.pop_front();
            active_command.word_count   = write_word_count_queue.pop_front();
            active_command.burst_length = write_burst_length_queue.pop_front();
            active_command.bank         = write_bank_queue.pop_front();
            active_command.col_address  = write_col_address_queue.pop_front();
            active_command.row_address  = write_row_address_queue.pop_front();


            /*
            if ((active_command.cmd_type != DDR_CMD_TYPE_MWR) &&
                (active_command.cmd_type != DDR_CMD_TYPE_WR16) &&
                (active_command.cmd_type != DDR_CMD_TYPE_WR32)) begin
               $display("[%0t] [CHANNEL ID=%s] [RANK ID=%0d] [DEVICE ID=%0d] :  Internal Error: Expected WRITE command not in queue!", $time, MEM_CHANNEL_IDX, MEM_RANK_IDX, MEM_DEVICE_IDX);
               $stop(1);
            end */
         end

      if (precharge_command_pipeline[0]) begin
         precharge_command.cmd_type    = precharge_command_queue.pop_front();
         precharge_command.bank        = precharge_bank_queue.pop_front();
         precharge_command.ab_ap       = precharge_ab_ap_queue.pop_front();
         cmd_precharge(precharge_command);
      end

      if (activate_command_pipeline[0]) begin
         if(activate_command_queue.size() == 0) begin
           $display("[%0t] [CHANNEL ID=%s] [RANK ID=%0d] [DEVICE ID=%0d] :  Internal Error: ACTIVATE command queue empty but ACTIVATE commands expected!", $time, MEM_CHANNEL_IDX, MEM_RANK_IDX, MEM_DEVICE_IDX);
         end
         activate_command.cmd_type     = activate_command_queue.pop_front();
         activate_command.bank         = activate_bank_queue.pop_front();
         activate_command.row_address  = activate_row_address_queue.pop_front();
         cmd_activate(activate_command);

      end
   endtask

   generate
     genvar dmi_count_in;
     for (dmi_count_in = 0; dmi_count_in < MEM_DQS_WIDTH; dmi_count_in = dmi_count_in + 1) begin: dmi_mapping
         assign full_dmi_in [(dmi_count_in + 1) * MEM_DQS_GROUP_SIZE - 1 : dmi_count_in * MEM_DQS_GROUP_SIZE] = {MEM_DQS_GROUP_SIZE{mem_dmi[dmi_count_in]}};
     end
   endgenerate

   task automatic write_cnt_b;

      write_sample = write_command_pipeline[0];

      if(!write_sample_q && write_sample) begin
         write_start = 1'b1;
      end else begin
         write_start = 1'b0;
      end

      write_sample_q = write_sample;

      if (write_start) begin
         write_counter = 1;
      end else if (write_counter == active_command.burst_length) begin
         write_counter = 0;
      end else if (write_counter > 0) begin
         write_counter += 1;
      end

      if (write_counter == active_command.burst_length) begin
         write_end = 1'b1;
      end else begin
         write_end = 1'b0;
      end

      if (write_counter > 0) begin
         write_active = 1'b1;
         write_data   = mem_dq;
         write_memory(active_command, write_data, full_dmi_in);
         active_command.word_count += 1;
      end else begin
         write_active = 1'b0;
         write_data   = 'bx;
      end
   endtask


   task write_memory(
      input command_struct                                cmd,
      input [MEM_DQ_WIDTH - 1:0]                          write_data,
      input [MEM_DQ_WIDTH - 1:0]                          dmi_in);

      bit [4+MEM_ROW_ADDR_WIDTH+MEM_COL_ADDR_WIDTH+5-1:0] address;
      bit [MEM_DQ_WIDTH - 1:0]                            masked_data;
      bit [MEM_DQS_WIDTH - 1:0]                           dm_en;

      integer i;

      address = {cmd.bank, cmd.row_address, cmd.col_address} + cmd.word_count;

      if (~mr_DMD && mr_DBI_WR[mr_FSP_OP] && cmd.cas_type == MASK_WRITE) begin
         for (int i = 0; i < MEM_DQS_WIDTH; i = i + 1) begin
            integer sum;
            sum = 0;
            for (int j = 2; j < (MEM_DQS_GROUP_SIZE); j = j + 1) begin
               sum = sum + write_data[i*(MEM_DQS_GROUP_SIZE) + j];
            end
            dm_en[i] = sum >= 5;
         end
      end

      for(i = 0; i < MEM_DQ_WIDTH; i = i + 1) begin
         if (~mr_DMD || mr_DBI_WR[mr_FSP_OP]) begin
            if ((dmi_in[i] !== 0 && dmi_in[i] !== 1)) begin
               $display("[%0t] [CHANNEL ID=%s] [RANK ID=%0d] [DEVICE ID=%0d] :  ERROR: Unexpected mem_dmi value when DM/WDBI enabled: %h", $time, MEM_CHANNEL_IDX, MEM_RANK_IDX, MEM_DEVICE_IDX, dmi_in);
            end
         end

         if (cmd.cas_type == WRITE) begin
            if (mr_DBI_WR[mr_FSP_OP]) begin
               masked_data[i] = dmi_in[i] ? ~write_data[i] : write_data[i];
            end else if (~mr_DMD && dmi_in[i]) begin
                  $display("[%0t] [CHANNEL ID=%s] [RANK ID=%0d] [DEVICE ID=%0d] :  ERROR: mem_dmi value should be 0 for WRITE command when DM is enabled: %h", $time, MEM_CHANNEL_IDX, MEM_RANK_IDX, MEM_DEVICE_IDX, dmi_in);
            end else begin
               masked_data[i] = write_data[i];
            end
         end else if (cmd.cas_type == MASK_WRITE) begin
            if (mr_DMD) begin
               $display("[%0t] [CHANNEL ID=%s] [RANK ID=%0d] [DEVICE ID=%0d] :  ERROR: Unexpected MASK_WRITE command when DM is disabled", $time, MEM_CHANNEL_IDX, MEM_RANK_IDX, MEM_DEVICE_IDX);
            end else if (~mr_DBI_WR[mr_FSP_OP]) begin
               if (dmi_in[i]) begin
                  if (mem_data.exists(address)) begin
                     masked_data[i] = mem_data[address][i];
                  end else begin
                     masked_data[i] = 'x;
                  end
               end else begin
                  masked_data[i] = write_data[i];
               end
            end else if (dm_en[i/MEM_DQS_GROUP_SIZE] && ~dmi_in[i]) begin
               if (mem_data.exists(address)) begin
                  masked_data[i] = mem_data[address][i];
               end else begin
                  masked_data[i] = 'x;
               end
            end else begin
               masked_data[i] = dmi_in[i] ? ~write_data[i] : write_data[i];
            end
         end else begin
               $display("[%0t] [CHANNEL ID=%s] [RANK ID=%0d] [DEVICE ID=%0d] :  ERROR: Unexpected command type %s %s", $time, MEM_CHANNEL_IDX, MEM_RANK_IDX, MEM_DEVICE_IDX, cmd.cas_type, cmd.cmd_type);
         end
      end

      if (MEM_VERBOSE) begin
         if (~mr_DMD || mr_DBI_WR[mr_FSP_OP]) begin
            $display("[%0t] [CHANNEL ID=%s] [RANK ID=%0d] [DEVICE ID=%0d] :  Writing data %h (%h) DMI %h @ %0h BANK[%0h] ROW[%0h] COL[%0h] burst %0d",
                  $time, MEM_CHANNEL_IDX, MEM_RANK_IDX, MEM_DEVICE_IDX, masked_data, write_data, dmi_in, address, cmd.bank, cmd.row_address, cmd.col_address, cmd.word_count);
         end else begin
            $display("[%0t] [CHANNEL ID=%s] [RANK ID=%0d] [DEVICE ID=%0d] :  Writing data %h DMI %h @ %0h BANK[%0h] ROW[%0h] COL[%0h] burst %0d",
                  $time, MEM_CHANNEL_IDX, MEM_RANK_IDX, MEM_DEVICE_IDX, masked_data, dmi_in, address, cmd.bank, cmd.row_address, cmd.col_address, cmd.word_count);
         end
      end

      mem_data[address] = masked_data;

      bank_status[cmd.bank].last_write_access_cycle = clock_cycle;

   endtask



   task automatic preamble_cnt_p;
      preamble_sample <= read_command_pipeline[6];
      if (!preamble_sample && read_command_pipeline[6]) begin
         preamble_start    <= 1'b1;
         preamble_counter  <= 1;
      end else begin
         preamble_start    <= 1'b0;
         if (preamble_counter == 3) begin
            preamble_counter <= 0;
         end else if (preamble_counter > 0) begin
            preamble_counter <= preamble_counter + 1;
         end
      end
   endtask

   task preamble_gen;
      input        dqs_pre;
      input  int   preamble_counter;
      output       preamble_dqs_oen;
      output       preamble_dqs_toggle;

      case(dqs_pre)
         1'b0  : begin
                   case(preamble_counter)
                      0: begin preamble_dqs_oen <= 1'b0;     preamble_dqs_toggle <= 1'b0; end
                      1: begin preamble_dqs_oen <= 1'b1;     preamble_dqs_toggle <= 1'b0; end
                      2: begin preamble_dqs_oen <= 1'b1;     preamble_dqs_toggle <= 1'b0; end
                      3: begin preamble_dqs_oen <= 1'b0;     preamble_dqs_toggle <= 1'b0; end
                   endcase
                 end
         1'b1  : begin
                   case(preamble_counter)
                      0: begin preamble_dqs_oen <= 1'b0;     preamble_dqs_toggle <= 1'b0; end
                      1: begin preamble_dqs_oen <= 1'b1;     preamble_dqs_toggle <= 1'b0; end
                      2: begin preamble_dqs_oen <= 1'b1;     preamble_dqs_toggle <= 1'b1; end
                      3: begin preamble_dqs_oen <= 1'b0;     preamble_dqs_toggle <= 1'b0; end
                   endcase
                 end
      endcase
   endtask

   always @ (*) begin
      preamble_gen(mr_RD_PRE[mr_FSP_WR], preamble_counter, preamble_dqs_oen, preamble_dqs_toggle);
   end

   task automatic read_cnt_b;

      read_sample = read_command_pipeline[0];



      if (!read_sample_q && read_sample) begin
         read_start = 1'b1;
      end else begin
         read_start = 1'b0;
      end

      read_sample_q = read_sample;

      if (read_start) begin
         read_counter = 1;
      end else if (read_counter == active_command.burst_length) begin
         read_counter = 0;
      end else if (read_counter > 0) begin
         read_counter += 1;
      end

      if ((read_counter > 0) && (read_counter == active_command.burst_length)) begin
         read_end = 1'b1;
      end else if (~mem_ck_t) begin
         read_end = 1'b0;
      end

      if (read_counter > 0) begin
         read_active = 1'b1;
            if (active_command.cas_type == MRR) begin
               if (read_counter < 5) begin
                  read_data[7:0]  = active_command.mr_wdata;
                  read_data[15:8] = 'h00;
               end else begin
                  read_data[15:0] = 'h0000;
               end
               $display("[%0t] [CHANNEL ID=%s] [RANK ID=%0d] [DEVICE ID=%0d] :  MRR [ %0d ] -> %b", $time, MEM_CHANNEL_IDX, MEM_RANK_IDX, MEM_DEVICE_IDX, active_command.mr_index, read_data);
            end else begin
               if (mr_DBI_RD[mr_FSP_OP]) begin
                  read_memory(active_command, mem_dq_from_mem, dmi_out);
                  read_data = mem_dq_from_mem ^ full_dmi_out;
               end else
                  read_memory(active_command, read_data, dmi_out);
            end
         active_command.word_count += 1;
      end else begin
         read_active = 1'b0;
      end
   endtask

   task read_memory(
      input command_struct             cmd,
      output [MEM_DQ_WIDTH - 1:0] read_data,
      output [MEM_DQS_WIDTH - 1:0] dmi_out);

      bit [4+MEM_ROW_ADDR_WIDTH+MEM_COL_ADDR_WIDTH+5-1:0] address;

      address = {cmd.bank, cmd.row_address, cmd.col_address} + cmd.word_count;

         if (mr_DBI_RD) begin
            for (int i = 0; i < MEM_DQS_WIDTH; i = i + 1) begin
               integer sum;
               sum = 0;
               for (int j = 0; j < (MEM_DQS_GROUP_SIZE); j = j + 1) begin
                  sum = sum + mem_data[address][i*(MEM_DQS_GROUP_SIZE) + j];
               end
               dmi_out[i] = sum > 4;
            end
            read_data = mem_data[address];
         end else begin
            dmi_out = 'z;
            read_data = mem_data[address];
         end

         for (int i = 0; i < MEM_DQ_WIDTH; i = i + 1) begin: dmi_out_mapping
             full_dmi_out [i] = dmi_out[i / MEM_DQS_GROUP_SIZE];
         end


      if (MEM_VERBOSE)
         $display("[%0t] [CHANNEL ID=%s] [RANK ID=%0d] [DEVICE ID=%0d] :  Reading data %h @ %0h BANK[%0h] ROW[%0h] COL[%0h] burst %0d",
                  $time, MEM_CHANNEL_IDX, MEM_RANK_IDX, MEM_DEVICE_IDX, read_data, address, cmd.bank, cmd.row_address, cmd.col_address, cmd.word_count);

      bank_status[cmd.bank].last_read_access_cycle = clock_cycle;
   endtask


   task automatic postamble_cnt_p;
      if (read_end) begin
         postamble_start      <= 1'b1;
         postamble_counter    <= 1;
      end else begin
         postamble_start      <= 1'b0;
         if (postamble_counter == 2) begin
            postamble_counter <= 0;
         end else if (postamble_counter > 0) begin
            postamble_counter <= postamble_counter + 1;
         end
      end
   endtask

   task postamble_gen;
      input        dqs_post;
      input  int   postamble_counter;
      output       postamble_dqs_oen;
      output       postamble_dqs_toggle;

      case(dqs_post)
         1'b0  : begin
                   case(postamble_counter)
                      0: begin postamble_dqs_oen <= 1'b0;     postamble_dqs_toggle <= 1'b0; end
                      1: begin postamble_dqs_oen <= 1'b0;     postamble_dqs_toggle <= 1'b0; end
                      2: begin postamble_dqs_oen <= 1'b0;     postamble_dqs_toggle <= 1'b0; end
                   endcase
                 end
         1'b1  : begin
                   case(postamble_counter)
                      0: begin postamble_dqs_oen <= 1'b0;     postamble_dqs_toggle <= 1'b0; end
                      1: begin postamble_dqs_oen <= 1'b1;     postamble_dqs_toggle <= 1'b1; end
                      2: begin postamble_dqs_oen <= 1'b0;     postamble_dqs_toggle <= 1'b0; end
                   endcase
                 end
      endcase
   endtask

   always @ (*) begin
      postamble_gen(mr_RPST[mr_FSP_WR], postamble_counter, postamble_dqs_oen, postamble_dqs_toggle);
   end


   logic [MEM_DQ_WIDTH -1:0]           mem_dq_int;
   logic [MEM_DMI_WIDTH-1:0]           mem_dmi_int;
   logic [MEM_DQS_WIDTH-1:0]           mem_dqs_t_int;
   logic [MEM_DQS_WIDTH-1:0]           mem_dqs_c_int;
   logic [MEM_DQ_WIDTH -1:0]           mem_dq_int_delay;
   logic [MEM_DMI_WIDTH-1:0]           mem_dmi_int_delay;
   logic [MEM_DQS_WIDTH-1:0]           mem_dqs_t_int_delay;
   logic [MEM_DQS_WIDTH-1:0]           mem_dqs_c_int_delay;
   logic                               mem_dqs_oen;


   assign mem_dq_int[15:0] = read_active ? read_data[15:0] : 'bz;

   assign mem_dmi_int         = mr_DBI_RD ? (read_active ? dmi_out : 'z) : 'z;

   assign mem_dqs_oen         = read_active | preamble_dqs_oen | postamble_dqs_oen;

   assign mem_dqs_t_int[0] = (read_active | preamble_dqs_toggle | postamble_dqs_toggle) ? mem_ck_t : 1'b0;
   assign mem_dqs_t_int[1] = (read_active | preamble_dqs_toggle | postamble_dqs_toggle) ? mem_ck_t : 1'b0;
   assign mem_dqs_c_int[0] = (read_active | preamble_dqs_toggle | postamble_dqs_toggle) ? mem_ck_c : 1'b1;
   assign mem_dqs_c_int[1] = (read_active | preamble_dqs_toggle | postamble_dqs_toggle) ? mem_ck_c : 1'b1;

   always_comb begin
      mem_dq_int_delay        <= #(tDQSCK) mem_dq_int;

      mem_dmi_int_delay       <= #(tDQSCK) mem_dmi_int;

      mem_dqs_t_int_delay[0]  <= #(tDQSCK+tDQSQ) (mem_dqs_oen ? mem_dqs_t_int[0] : 'bz);
      mem_dqs_t_int_delay[1]  <= #(tDQSCK+tDQSQ) (mem_dqs_oen ? mem_dqs_t_int[1] : 'bz);
      mem_dqs_c_int_delay[0]  <= #(tDQSCK+tDQSQ) (mem_dqs_oen ? mem_dqs_c_int[0] : 'bz);
      mem_dqs_c_int_delay[1]  <= #(tDQSCK+tDQSQ) (mem_dqs_oen ? mem_dqs_c_int[1] : 'bz);
   end

   assign mem_dq              = mem_dq_int_delay;
   assign mem_dmi             = mem_dmi_int_delay;
   assign mem_dqs_t           = mem_dqs_t_int_delay;
   assign mem_dqs_c           = mem_dqs_c_int_delay;

endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "+qL3hlshuw3vl105k04c4hDzfWgPSh5sVI/ghdJXk44XYu5+Y2kb3X2D97dl4myk2GIrABCQ+//lQ9PbcrMpaedxlxbRS2oWnBsOGXND/uDLU78WuXe8IluK542JWM0Aq87DaeZITm+H/eLx0Wv9HAGhJ07dBaLvKkPWBtg8rXsyUwQNr/JbEusQM2wKWTHh+vFhnlX/HbTTazDHawScbgHGadk2olDQ2A/yNzOpmwmTWHAu+w/LTEiNf+NEACgfP3LV0UTo1XaiQb9rMSkDe0uEgBY7CGzPuHRlGrg5s687SUdxW0Q4klLICeVYrOXRsUv23nGwdZVtoahDrHXBJF23tvrBhmOvo4iIz6hfTbjOAJ5xjIPmjpSigvnXwTfp7rNz7MmgeF7B7eCJiwDvvPXaRAX7sxeQnIbh8jFG7d8OEWH5Kj8+pLA0FHBMUQ/4EbeNJ3rozcJITlJm+4DSthe7qUlhGUmo9f0EgfBWkeQ0fIUAEAk6sssakhC1zLS5RhW2TjZjFOSm3XGWhRC26NQKZlztN62QRtvfGA+/ritQS10x/AhK9xz7+LuevFVwJTOQOpAUeRPal5+kQERypKPfRnxY/xMoQGmEArGR4FnXRETQWVBR0uTKNWkYLSNzouSV+znr3SzMVWnqZ5WE4UXFp0fFndt4CwVbFyX8cKRDMRvAeBw3DoqXxzwLLAJaZu97L3tyXlBM6TTiZgBXx0dSZi1PgKXNDbladntjX/fW29qgo50s8XzHRm1hXHwIujrbu+dYoDAawC2L01xRZZDzoCf3sE1hEtZp3OgwyWMq82bTAzqrUlkULPK+vS9DNLBKRN+lTgKvluHVJWFLEGieoNRQv4C4XcgnSO4KIPLwsGWZ4MVwh4bhcj1qvMUH/oxSzac/fjIzYjA/OSvm9KKuyXcyRDipiOcc7UZVeSk9WkvlJZGQX0TYaUotQKJxmpeHW7nDABjvAjLNIH/AYaWevd3hzmdHx99Tou68o5DaL6K75kns4PkqOwdPimPl"
`endif
