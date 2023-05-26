// Copyright (C) 2020 Intel Corporation.
// SPDX-License-Identifier: MIT


`timescale 1ns/1ps
module axis_bfm #(
  parameter                   WORDS = 1,
  parameter                   WIDTH = 64,
  parameter                   PORT_NO=0,
  parameter                   PTP =1
)(
  input                       app_ss_lite_areset_n,
  input                       tx_aclk,
  input                       tx_aresetn,
  input                       rx_aclk,
  input                       rx_aresetn,
  input                [7:0]  ptp_fp_i,
  input               [95:0]  ptp_tx_its_i,
  input                [2:0]  ptp_cmd_sel_i,
  input                       ptp_ets_valid_i,
  input               [95:0]  ptp_ets_i,
  input               [ 7:0]  ptp_ets_fp_i,
  input               [95:0]  ptp_rx_its_i,
  input               [95:0]  txrx_ts_diff_thres_i,

  output                      axis_tx_tvalid_o,
  output   [WIDTH*WORDS-1:0]  axis_tx_tdata_o,
  input                       axis_tx_tready_i,
  output [WIDTH*WORDS/8-1:0]  axis_tx_tkeep_o,
  output                      axis_tx_tlast_o,
  output               [1:0]  axis_tx_tuser_client_o,
  output              [89:0]  axis_tx_tuser_ptp_o,
  output             [327:0]  axis_tx_tuser_ptp_ext_o,

  input                       axis_rx_tvalid_i,
  input    [WIDTH*WORDS-1:0]  axis_rx_tdata_i,
  output                      axis_rx_tready_o,
  input  [WIDTH*WORDS/8-1:0]  axis_rx_tkeep_i,
  input                       axis_rx_tlast_i,
  input                [6:0]  axis_rx_tuser_client_i,
  input                [4:0]  axis_rx_tuser_sts_i,
  input               [31:0]  axis_rx_tuser_sts_ext_i
);

  //--------------------------------------------------------------------------------
  // Signals
  //--------------------------------------------------------------------------------

  localparam EWIDTH = $clog2(WORDS*WIDTH/8);

  reg                    tx_startofpacket=0;
  reg                    tx_endofpacket=0;
  reg                    tx_valid=0;
  reg                    tx_error=0;
  wire                   tx_ready;
  reg  [EWIDTH-1:0]      tx_empty=0;
  reg  [WORDS*WIDTH-1:0] tx_data=0;
  reg                    tx_skip_crc=0;

  wire [5:0]             rx_error;
  wire                   rx_valid;
  wire                   rx_ready=1'b1;
  wire                   rx_startofpacket;
  wire                   rx_endofpacket;
  wire [WORDS*WIDTH-1:0] rx_data;
  wire [EWIDTH-1:0]      rx_empty;

  reg                    ptp_ts_req = 0;
  reg                    ptp_ins_ets = 0;
  reg                    ptp_ins_cf = 0;
  reg                    ptp_ins_zero_csum = 0;
  reg                    ptp_ins_update_eb = 0;
  reg                    ptp_ins_ts_format = 0;
  reg  [15:0]            ptp_ins_ts_offset = 0;
  reg  [15:0]            ptp_ins_cf_offset = 0;
  reg  [15:0]            ptp_ins_csum_offset = 0;
  reg  [15:0]            ptp_ins_eb_offset = 0;

  reg         ptp_testing = 0;
  wire [31:0] tx_ts_req_cnt;
  wire [31:0] tx_ets_cnt;
  wire [31:0] rx_its_cnt;
  wire [31:0] tx_fp_err_cnt;
  wire [31:0] txrx_ts_diff_err_cnt;
  wire        txrx_ts_diff_min_sign;
  wire [95:0] txrx_ts_diff_min;
  wire        txrx_ts_diff_max_sign;
  wire [95:0] txrx_ts_diff_max;

  int errcnt=0;
  int ptp_err=0;

  logic [31:0] tx_pkt_cnt = 0;
  logic [31:0] rx_pkt_cnt = 0;

  //--------------------------------------------------------------------------------
  // AVST-AXIS BRidge
  //--------------------------------------------------------------------------------

  avst2axis_bridge #(
    .WORDS                           ( WORDS ),
    .WIDTH                           ( WIDTH ),
    .EMPTY_WIDTH                     ( EWIDTH )
  ) avst2axis_bridge (
    .aclk                            ( tx_aclk ),
    .aresetn                         ( tx_aresetn ),
    .tx_error_i                      ( tx_error ),
    .tx_skip_crc_i                   ( tx_skip_crc ),
    .ptp_fp_i                        ( ptp_fp_i ),
    .ptp_ins_ets_i                   ( ptp_ins_ets ),
    .ptp_ts_req_i                    ( ptp_ts_req ),
    .ptp_tx_its_i                    ( ptp_tx_its_i ),
    .ptp_ins_cf_i                    ( ptp_ins_cf),
    .ptp_ins_zero_csum_i             ( ptp_ins_zero_csum ),
    .ptp_ins_update_eb_i             ( ptp_ins_update_eb ),
    .ptp_ins_ts_format_i             ( ptp_ins_ts_format ),
    .ptp_ins_ts_offset_i             ( ptp_ins_ts_offset ),
    .ptp_ins_cf_offset_i             ( ptp_ins_cf_offset ),
    .ptp_ins_csum_offset_i           ( ptp_ins_csum_offset ),
    .ptp_ins_eb_offset_i             ( ptp_ins_eb_offset ),

    .axis_tvalid_o                   ( axis_tx_tvalid_o ),
    .axis_tdata_o                    ( axis_tx_tdata_o  ),
    .axis_tready_i                   ( axis_tx_tready_i ),
    .axis_tkeep_o                    ( axis_tx_tkeep_o  ),
    .axis_tlast_o                    ( axis_tx_tlast_o  ),
    .axis_tuser_client_o             ( axis_tx_tuser_client_o ),
    .axis_tuser_ptp_o                ( axis_tx_tuser_ptp_o ),
    .axis_tuser_ptp_ext_o            ( axis_tx_tuser_ptp_ext_o ),
    .avst_valid_i                    ( tx_valid ),
    .avst_data_i                     ( tx_data ),
    .avst_empty_i                    ( tx_empty ),
    .avst_sop_i                      ( tx_startofpacket ),
    .avst_eop_i                      ( tx_endofpacket ),
    .avst_ready_o                    ( tx_ready )
  );


  //--------------------------------------------------------------------------------
  // AXIS-AVST BRidge
  //--------------------------------------------------------------------------------

  axis2avst_bridge #(
    .WORDS                           ( WORDS ),
    .WIDTH                           ( WIDTH ),
    .EMPTY_WIDTH                     ( EWIDTH )
  )  axis2avst_bridge (
    .aclk                            ( rx_aclk ),
    .aresetn                         ( rx_aresetn ),
    .axis_tvalid_i                   ( axis_rx_tvalid_i ),
    .axis_tdata_i                    ( axis_rx_tdata_i ),
    .axis_tready_o                   ( axis_rx_tready_o ),
    .axis_tkeep_i                    ( axis_rx_tkeep_i ),
    .axis_tlast_i                    ( axis_rx_tlast_i ),
    .axis_tuser_client_i             ( axis_rx_tuser_client_i ),
    .axis_tuser_sts                  ( axis_rx_tuser_sts_i ),
    .axis_tuser_sts_ext              ( axis_rx_tuser_sts_ext_i ),
    .avst_valid_o                    ( rx_valid ),
    .avst_data_o                     ( rx_data ),
    .avst_empty_o                    ( rx_empty ),
    .avst_sop_o                      ( rx_startofpacket ),
    .avst_eop_o                      ( rx_endofpacket ),
    .avst_ready_i                    ( rx_ready )
  );

  //--------------------------------------------------------------------------------
  // PTP checker
  //--------------------------------------------------------------------------------

generate if (PTP) begin: ptp_chk
  
  alt_ehipc3_fm_sl_ptp_chk ptp_chk
        (
            // Clock and reset
            .i_ptp_clk                  (tx_aclk),
            .i_ptp_rst_n                (app_ss_lite_areset_n),

            // EHIP datapath signals (For timestamp reconstruction)
            .i_tx_valid                 (tx_valid && tx_ready && ptp_testing),
            .i_tx_startofpacket         (tx_startofpacket),
            .i_rx_valid                 (rx_valid && ptp_testing),
            .i_rx_startofpacket         (rx_startofpacket),

            // User TX 2-step timestamp request
            .i_ptp_ts_req               (ptp_ts_req || ptp_ins_ets || ptp_ins_cf),
            .i_ptp_fp                   (ptp_fp_i),

            // EHIP TX 2-step timestamp
            .i_ptp_ets_valid            (ptp_ets_valid_i && ptp_testing),
            .i_ptp_ets                  (ptp_ets_i),
            .i_ptp_ets_fp               (ptp_ets_fp_i),

            // EHIP RX timestamp
            .i_ptp_rx_its               (ptp_rx_its_i),

            // Maximum allowable timestamp differences
            .i_txrx_ts_diff_thres       (txrx_ts_diff_thres_i),

            // Statistics
            .o_tx_ts_req_cnt            (tx_ts_req_cnt),
            .o_tx_ets_cnt               (tx_ets_cnt),
            .o_rx_its_cnt               (rx_its_cnt),
            .o_tx_fp_err_cnt            (tx_fp_err_cnt),
            .o_txrx_ts_diff_err_cnt     (txrx_ts_diff_err_cnt),
            .o_txrx_ts_diff_min_sign    (txrx_ts_diff_min_sign),
            .o_txrx_ts_diff_min         (txrx_ts_diff_min),
            .o_txrx_ts_diff_max_sign    (txrx_ts_diff_max_sign),
            .o_txrx_ts_diff_max         (txrx_ts_diff_max)
        );
end endgenerate

  //--------------------------------------------------------------------------------
  // AVST Packet
  //--------------------------------------------------------------------------------

  task send_packets_10G25G_avl;
        input  [31:0]  number_of_packets;
        input  [31:0]  pkt_base_index;
        integer m,j,k;
        integer data_word;
        begin
            fork
                for (m = 1; m <= number_of_packets; m = m + 1) begin
                    @(posedge tx_aclk);
                    tx_pkt_cnt = tx_pkt_cnt + 1;

                    wait_for_ready_avl();
                    $display("TBINFO:%t\tPort %0d - Sending  Packet %0d", $time,PORT_NO, pkt_base_index+m);

                    tx_data[00+:64]  = 64'hfbE42339_00000000;
                    tx_startofpacket= 1'b1;
                    tx_valid        = 1'b1;
                    cfg_ptp_cmd;
                    wait_for_ready_avl;

                    for (k = 1; k <= 8; k = k +1) begin
                        data_word                  = m + (k << 8) + (k << 16) + (k << 24);
                        tx_data[0+:64]  = {data_word, (32'h0036_0000 | m)};
                        tx_startofpacket= 1'b0;
                        tx_valid        = 1'b1;
                        tx_endofpacket  = (k == 8) ? 1'b1 : 1'b0;
                        tx_empty[0+:3]  = (k == 8) ? 'd4 : 'd0;
                        cfg_ptp_cmd;
                        wait_for_ready_avl();
                    end

                    tx_data[0+:64]   = 0;
                    tx_endofpacket   = 0;
                    tx_startofpacket = 0;
                    tx_valid         = 0;
                    tx_empty[0+:3]    = 0;
                    cfg_ptp_cmd();
                end

                for (j = 1; j <= number_of_packets; j = j+1) begin
                    while (!(rx_valid && rx_endofpacket)) @(posedge rx_aclk);
                    rx_pkt_cnt = rx_pkt_cnt + 1;
                    $display("TBINFO:%t\tPort %0d - Received Packet %0d", $time, PORT_NO, pkt_base_index+j);
                    @(posedge rx_aclk);
                end
            join
        end
    endtask

    task send_packets_100G_avl;
        input  [31:0]  number_of_packets;
        integer i,j,k,l;
        integer data_word;
        begin
            fork
                for (i = 1; i <= number_of_packets; i = i +1) begin
                    @(posedge tx_aclk);
                    tx_pkt_cnt = tx_pkt_cnt + 1;

                    wait_for_ready_avl;
                    $display("TBINFO:%t\tPort %0d -  Sending Packet %d...",$time,PORT_NO,i);
                    tx_data          = 512'hFB555555_555555D5_AAAAAAAA_00000000_ABE42339_F0001E42_339F0100_00000000_ABE42339_F0001E42_339F0100_00000000_ABE42339_F0001E42_339F0100_00000000;
                    tx_startofpacket = 1'b1;
                    tx_valid         = 1'b1;
                    cfg_ptp_cmd;
                    wait_for_ready_avl;

                    for (k = 1; k <= 8; k = k +1) begin
                        data_word = i + (k << 8) + (k << 16) + (k << 24);
                        tx_data          = {data_word, i};
                        tx_startofpacket = 1'b0;
                        tx_valid         = 1'b1;
                        tx_endofpacket = (k == 8) ? 1'b1 : 1'b0;
                        tx_empty = (k == 8) ? 'd4 : 'd0;
                        cfg_ptp_cmd;
                        wait_for_ready_avl;
                    end

                    tx_data          = 0;
                    tx_endofpacket   = 0;
                    tx_startofpacket = 0;
                    tx_valid         = 0;
                    tx_empty         = 0;
                    cfg_ptp_cmd;
                end

                for (j = 1; j <= number_of_packets; j = j+1) begin
                    while ( !(rx_valid && !rx_startofpacket && !rx_endofpacket)) @(posedge rx_aclk);
                    rx_pkt_cnt = rx_pkt_cnt +1;
                    $display("TBINFO:%t\tPort %0d -  Received Packet %d...",$time,PORT_NO,rx_data[31:0]);
                    @(posedge rx_aclk);
                    while (!rx_startofpacket && (j != number_of_packets)) @(posedge rx_aclk);
                    @(posedge rx_aclk);
                end
         join
        end
    endtask

  //--------------------------------------------------------------------------------
  // Wait for AVST ready
  //--------------------------------------------------------------------------------

    task wait_for_ready_avl;
        #1;
        if(!tx_ready) begin
            while(!tx_ready) @(posedge tx_aclk);
        end
        else begin
             @(posedge tx_aclk);
        end
    endtask // wait_for_ready_avl

  //--------------------------------------------------------------------------------
  // PTP Setup
  //--------------------------------------------------------------------------------

    task cfg_ptp_cmd;
        if(tx_startofpacket && PTP) begin
        ptp_ins_ts_offset   [0+:16] = 16'd48;
        ptp_ins_cf_offset   [0+:16] = 16'd22;
        ptp_ins_csum_offset [0+:16] = 16'd40;
        ptp_ins_eb_offset   [0+:16] = 16'd58;
            case(ptp_cmd_sel_i[0+:3])
                0: begin // Non-PTP
                    ptp_ts_req        = 1'b0;
                    ptp_ins_ets       = 1'b0;
                    ptp_ins_cf        = 1'b0;
                    ptp_ins_zero_csum = 1'b0;
                    ptp_ins_update_eb = 1'b0;
                    ptp_ins_ts_format = 1'b0;
                end
                1: begin // 2-step
                    ptp_ts_req        = 1'b1;
                    ptp_ins_ets       = 1'b0;
                    ptp_ins_cf        = 1'b0;
                    ptp_ins_zero_csum = 1'b0;
                    ptp_ins_update_eb = 1'b0;
                    ptp_ins_ts_format = 1'b0;
                end
                2: begin // 1-step: Insert 1588v2 egress timestamp
                    ptp_ts_req        = 1'b0;
                    ptp_ins_ets       = 1'b1;
                    ptp_ins_cf        = 1'b0;
                    ptp_ins_zero_csum = 1'b0;
                    ptp_ins_update_eb = 1'b0;
                    ptp_ins_ts_format = 1'b0;
                end
                3: begin // 1-step: Insert 1588v1 egress timestamp
                    ptp_ts_req        = 1'b0;
                    ptp_ins_ets       = 1'b1;
                    ptp_ins_cf        = 1'b0;
                    ptp_ins_zero_csum = 1'b0;
                    ptp_ins_update_eb = 1'b0;
                    ptp_ins_ts_format = 1'b1;
                end
                4: begin // 1-step: Modify CorrectionField
                    ptp_ts_req        = 1'b0;
                    ptp_ins_ets       = 1'b0;
                    ptp_ins_cf        = 1'b1;
                    ptp_ins_zero_csum = 1'b0;
                    ptp_ins_update_eb = 1'b0;
                    ptp_ins_ts_format = 1'b0;
                end
                5: begin // 1-step: Insert 1588v2 egress timestamp, clear checksum
                    ptp_ts_req        = 1'b0;
                    ptp_ins_ets       = 1'b1;
                    ptp_ins_cf        = 1'b0;
                    ptp_ins_zero_csum = 1'b1;
                    ptp_ins_update_eb = 1'b0;
                    ptp_ins_ts_format = 1'b0;
                end
                6: begin // 1-step: Modify CorrectionField, clear checksum
                    ptp_ts_req        = 1'b0;
                    ptp_ins_ets       = 1'b0;
                    ptp_ins_cf        = 1'b1;
                    ptp_ins_zero_csum = 1'b1;
                    ptp_ins_update_eb = 1'b0;
                    ptp_ins_ts_format = 1'b0;
                end
                7: begin // 1-step: Modify CorrectionField, update extended byte
                    ptp_ts_req        = 1'b0;
                    ptp_ins_ets       = 1'b0;
                    ptp_ins_cf        = 1'b1;
                    ptp_ins_zero_csum = 1'b0;
                    ptp_ins_update_eb = 1'b1;
                    ptp_ins_ts_format = 1'b0;
                end
                default: begin
                    ptp_ts_req        = 1'b0;
                    ptp_ins_ets       = 1'b0;
                    ptp_ins_cf        = 1'b0;
                    ptp_ins_zero_csum = 1'b0;
                    ptp_ins_update_eb = 1'b0;
                    ptp_ins_ts_format = 1'b0;
                end
            endcase
        end
        else begin
            ptp_ts_req        = 1'b0;
            ptp_ins_ets       = 1'b0;
            ptp_ins_cf        = 1'b0;
            ptp_ins_zero_csum = 1'b0;
            ptp_ins_update_eb = 1'b0;
            ptp_ins_ts_format = 1'b0;
        end
    endtask

  //--------------------------------------------------------------------------------
  // PTP Functions
  //--------------------------------------------------------------------------------

    reg  [4:0]                      vl;
    reg  [19:0][38:0]               vl_offset_load_arr;
    reg  [19:0]                     vl_offset_collected;
    typedef struct packed {
        bit [2:0]  gb_state;
        bit [1:0]  ba_phase;
        bit [4:0]  ba_pos;
        bit [14:0] am_count;
        bit [4:0]  local_vl;
        bit [4:0]  remote_vl;
        bit [2:0]  local_pl;
    } read_vl_data_s;
    read_vl_data_s [19:0]           vl_data;

    reg  [2:0]                      ln;
    reg  [1:0]                      phy_ln0_map;
    reg  [31:0]                     skew_ln[4];
    reg  [31:0]                     cw_pos_rx[4];
    reg  [31:0]                     min_val[$];
    reg  [31:0]                     min_skew;
    reg  [31:0]                     lane_skew_adjust;
    reg  [31:0]                     Tlat_final;

    typedef struct packed {
        bit [1:0]  selected_pl;
        bit [31:0] deskew_delay;
    } rx_rsfec_dskw_delay_s;
    rx_rsfec_dskw_delay_s           dskw_delay;

    // Calculating VL offset based on the sampled Virtual Lane data
    function calculate_vl_offset(read_vl_data_s vl_data);

       static bit [31:0] UI_25G = 32'h00_09_EE_01;
       bit neg_am_offset,neg_am_shift, neg_am_proc;
       static bit [31:0]   am_interval = 32'd320/5; // Use 32'd81920/5 for non-Sim Mode or actual hardware
       bit [31:0]   vl_offset;
       int          final_offset,bit_offset_pre_mod,gb_shift_pre_mod;
       static int unsigned max_final_offset =  32'hFF_FF_FF_FF;
       int unsigned sublane,state_offset,bit_offset,am_offset,gb_shift,am_shift,proc_offset,am_proc_offset;
       bit [63:0] vl_offset_result;

       // =========================================================================
       //Calculation of sublane
       // =========================================================================
       sublane = (vl_data.local_vl % 5);

       $display($sformatf("SUBLANE for local VL %0d is %0d",vl_data.local_vl,sublane));

       // =========================================================================
       // Calculation of bit offset
       // =========================================================================
       bit_offset_pre_mod = (((vl_data.ba_pos - 'd21)*5) - ((vl_data.ba_phase) * 'd22) + sublane);

       if (bit_offset_pre_mod < 0) begin
        $display($sformatf("NEG_BIT_OFFSET_pre_mod for local VL %0d is %0d, %b",
           vl_data.local_vl, bit_offset_pre_mod, bit_offset_pre_mod));

        // First convert the negative no. to a positive, by adding (modN*N)
        // Then perform a mod to generate a proper unsigned positive result.
        bit_offset = (bit_offset_pre_mod + (66*66)) % 66; // simplistic math for a mod of negative no.

        $display($sformatf("BIT_OFFSET for local VL %0d is %0d",
           vl_data.local_vl, bit_offset));
       end
       else begin // positive or zero
        $display($sformatf("POS_BIT_OFFSET_pre_mod for local VL %0d is %0d, %b",
           vl_data.local_vl, bit_offset_pre_mod, bit_offset_pre_mod));

        bit_offset = bit_offset_pre_mod % 66;

        $display($sformatf("BIT_OFFSET for local VL %0d is %0d",
           vl_data.local_vl, bit_offset));
       end

       // =========================================================================
       // Calculation of Gear box shift
       // =========================================================================
       gb_shift_pre_mod = (vl_data.gb_state - 4) + (vl_data.ba_phase * 3);

       if (gb_shift_pre_mod < 0) begin
        $display($sformatf("NEG_GB_SHIFT_pre_mod for local VL %0d is %0d, %b",
           vl_data.local_vl, gb_shift_pre_mod, gb_shift_pre_mod));

        // First convert the negative no. to a positive, by adding (modN*N)
        // Then perform a mod to generate a proper unsigned positive result.
        gb_shift = (gb_shift_pre_mod + (5*5)) % 5; // simplistic math for a mod of negative no.

        $display($sformatf("GB_SHIFT for local VL %0d is %0d",
           vl_data.local_vl, gb_shift));
       end
       else begin // positive or zero
        $display($sformatf("POS_GB_SHIFT_pre_mod for local VL %0d is %0d, %b",
           vl_data.local_vl, gb_shift_pre_mod, gb_shift_pre_mod));

        gb_shift = gb_shift_pre_mod % 5;

        $display($sformatf("GB_SHIFT for local VL %0d is %0d",
           vl_data.local_vl, gb_shift));
       end

       // =========================================================================
       // Calculation of AM offset
       // =========================================================================
       $display(
          $sformatf("=== AM offset calc. for local VL %0d, AM-count=%0d, am_interval=%0d",
             vl_data.local_vl, vl_data.am_count, am_interval));
       if(vl_data.am_count > am_interval/2) begin
         if (vl_data.am_count >= am_interval) begin
            am_shift = (vl_data.am_count - am_interval);
            am_offset =  (am_shift * 5) + gb_shift;
            neg_am_shift = 0; neg_am_offset = 0;
            $display(
               $sformatf(" AM_cnt is GT AM_intvl: Positive AM_OFFSET %0d, local VL %0d, Non-neg am_shift %0d, gb_shift %0d",
                  am_offset, vl_data.local_vl, am_shift, gb_shift));
            $display($sformatf(" Positive AM_OFFSET for local VL %0d is %0d ",
               vl_data.local_vl,am_offset));
         end
         else begin // less than
            am_shift = (am_interval - vl_data.am_count);
            if ((am_shift*5) > gb_shift) begin // am_shift is negative
               am_offset =  (am_shift * 5) - gb_shift;
               neg_am_shift = 1; neg_am_offset = 1;
            end
            else begin // unlikely., am_shift is 1 or 0
               am_offset =  gb_shift - (am_shift * 5);
               neg_am_shift = 1; neg_am_offset = 0;
            end

            $display(
               $sformatf("AM_cnt is LT AM_intvl: Negative AM_OFFSET %0d, local VL %0d, Neg am_shift %0d, gb_shift %0d",
                  am_offset, vl_data.local_vl, am_shift, gb_shift));
            $display($sformatf("AM_cnt is LT AM_intvl: Negative AM_OFFSET for local VL %0d is %0d ",
               vl_data.local_vl,am_offset));
         end
       end
       else begin // equal or less than
         am_shift = vl_data.am_count;
         am_offset =  (am_shift * 5) + gb_shift;
         neg_am_offset = 0; neg_am_shift = 0;
        $display(
           $sformatf("AM_cnt is LT AM_intvl/2: Positive AM_OFFSET %0d, local VL %0d, Positive am_shift %0d, gb_shift %0d",
              am_offset, vl_data.local_vl, am_shift, gb_shift));
        $display($sformatf("AM_cnt is LT AM_intvl/2: Positive AM_OFFSET for local VL %0d is %0d ",
           vl_data.local_vl, am_offset));
       end

       // =========================================================================
       // lookup proc_offset
       // =========================================================================
       proc_offset = get_proc_offset(vl_data);

       // Calculation of VL offset

       // We deduct/add the am_offset based on its nature
       // 1) If the final result is negative, we convert the 2's complement number by deducting from its max value and
       // then multiply to RX_UI , also setting the sign bit 31st to 1.
       // 2) if the final result is positive we multply it to RX_UI directly and then setting the sign bit (31st) to 0

       if (neg_am_offset) begin
          if (am_offset > proc_offset) begin
             am_proc_offset = am_offset - proc_offset;
             neg_am_proc = 1;
          end
          else begin // unlikely, proc_offset is a small value, <=7
             am_proc_offset = proc_offset - am_offset;
             neg_am_proc = 0;
          end
       end

       if (neg_am_offset) begin
          if (neg_am_proc) begin // b_o - (-am_proc) = b_o + am_proc, f_o = +
             final_offset = signed'({1'b0,bit_offset}) + signed'({1'b0,(am_proc_offset * 66)});
          end
          else begin // b_o - (am_proc) = b_o - am_proc
             final_offset = signed'({1'b0,bit_offset}) - (am_proc_offset * 66);
          end
       end
       else begin //  b_o - (am_o + proc_o)
          final_offset = signed'({1'b0,bit_offset}) - ((am_offset + proc_offset) * 66);
       end

       $display($sformatf("FINAL offset for local VL %0d, RVL %0d, is %0d ",
          vl_data.local_vl, vl_data.remote_vl, final_offset));

       if ((vl_data.remote_vl >= 16) && (vl_data.remote_vl <= 19)) begin
          final_offset = final_offset ;
          $display($sformatf("Additional Math for FINAL offset, Local VL %0d, RVL %0d, is %0d ",
             vl_data.local_vl, vl_data.remote_vl, final_offset));
       end


       // Negative offset
       if(final_offset < 0) begin
        vl_offset_result = ((max_final_offset - final_offset +1)* UI_25G)>>8;
        vl_offset[30:0] = vl_offset_result[30:0];
        vl_offset[31] = 1;
       end
       // Positive offset
       else begin
        vl_offset_result = (final_offset * UI_25G) >>8;
        vl_offset[30:0] = vl_offset_result[30:0];
        vl_offset[31] = 0;
       end

       $display(
         $sformatf("Before Rotation:VL_OFFSET:RVL_PL %0d_%0d,LVL %0d Sign=%b, 'h%0h ns, 'h%0h Fns",
         vl_data.remote_vl,vl_data.local_pl,vl_data.local_vl,vl_offset[31],
         vl_offset[30:16],vl_offset[15:0]));

       // Generating array based on the collected VL information
       vl_offset_collected[vl_data.local_vl] = 1;
       vl_offset_load_arr[vl_data.local_vl][38:7]    = vl_offset;
       vl_offset_load_arr[vl_data.local_vl][6:5]     = vl_data.local_pl;
       vl_offset_load_arr[vl_data.local_vl][4:0]     = ((vl_data.remote_vl + 4) % 20);

       $display($sformatf("After Rotation:VL_OFFSET:RVL_PL %0d_%0d,Sign=%b, 'h%0h ns, 'h%0h Fns",
          vl_offset_load_arr[vl_data.local_vl][4:0], vl_offset_load_arr[vl_data.local_vl][6:5],
          vl_offset_load_arr[vl_data.local_vl][38], vl_offset_load_arr[vl_data.local_vl][37:23],
          vl_offset_load_arr[vl_data.local_vl][22:7]));

    endfunction

    // Calculating VL offset based on the sampled Virtual Lane data
    function int unsigned get_proc_offset(read_vl_data_s vl_data);

       case (vl_data.local_vl)
          0,5,10,15: begin
            case(vl_data.ba_phase)
               2: begin
                  case(vl_data.ba_pos)
                     21,20,19,18,17: get_proc_offset = 5;
                     3,2,1,0: get_proc_offset = 7;
                     default: begin
                        if ((vl_data.ba_pos >= 4) && (vl_data.ba_pos <= 16)) begin
                           get_proc_offset = 6;
                        end
                        else begin
                           get_proc_offset = 0; // not tabled for this ba_pos value
                        end
                     end
                  endcase
               end
               1: begin
                     if ((vl_data.ba_pos >= 0) && (vl_data.ba_pos <= 12)) begin
                        get_proc_offset = 6;
                     end
                     else if ((vl_data.ba_pos >= 13) && (vl_data.ba_pos <= 21)) begin
                        get_proc_offset = 5;
                     end
                     else begin
                        get_proc_offset = 0; // not tabled for this ba_pos value
                     end
               end
               0: begin
                     if ((vl_data.ba_pos >= 0) && (vl_data.ba_pos <= 7)) begin
                        get_proc_offset = 6;
                     end
                     else if ((vl_data.ba_pos >= 8) && (vl_data.ba_pos <= 20)) begin
                        get_proc_offset = 5;
                     end
                     else if (vl_data.ba_pos == 21) get_proc_offset = 4;
                     else begin
                        get_proc_offset = 0; // not tabled for this ba_pos value
                     end
               end
               default: get_proc_offset = 0; // not tabled for this ba_phase value
            endcase
          end
          1,6,11,16: begin
            case(vl_data.ba_phase)
               2: begin
                  case(vl_data.ba_pos)
                     21,20,19,18,17: get_proc_offset = 5;
                     3,2,1,0: get_proc_offset = 7;
                     default: begin
                        if ((vl_data.ba_pos >= 4) && (vl_data.ba_pos <= 16)) begin
                           get_proc_offset = 6;
                        end
                        else begin
                           get_proc_offset = 0; // not tabled for this ba_pos value
                        end
                     end
                  endcase
               end
               1: begin
                     if ((vl_data.ba_pos >= 0) && (vl_data.ba_pos <= 11)) begin
                        get_proc_offset = 6;
                     end
                     else if ((vl_data.ba_pos >= 12) && (vl_data.ba_pos <= 21)) begin
                        get_proc_offset = 5;
                     end
                     else begin
                        get_proc_offset = 0; // not tabled for this ba_pos value
                     end
               end
               0: begin
                     if ((vl_data.ba_pos >= 0) && (vl_data.ba_pos <= 7)) begin
                        get_proc_offset = 6;
                     end
                     else if ((vl_data.ba_pos >= 8) && (vl_data.ba_pos <= 20)) begin
                        get_proc_offset = 5;
                     end
                     else if (vl_data.ba_pos == 21) get_proc_offset = 4;
                     else begin
                        get_proc_offset = 0; // not tabled for this ba_pos value
                     end
               end
               default: get_proc_offset = 0; // not tabled for this ba_phase value
            endcase
          end
          2,7,12,17: begin
            case(vl_data.ba_phase)
               2: begin
                  case(vl_data.ba_pos)
                     21,20,19,18,17: get_proc_offset = 5;
                     2,1,0: get_proc_offset = 7;
                     default: begin
                        if ((vl_data.ba_pos >= 3) && (vl_data.ba_pos <= 16)) begin
                           get_proc_offset = 6;
                        end
                        else begin
                           get_proc_offset = 0; // not tabled for this ba_pos value
                        end
                     end
                  endcase
               end
               1: begin
                     if ((vl_data.ba_pos >= 0) && (vl_data.ba_pos <= 11)) begin
                        get_proc_offset = 6;
                     end
                     else if ((vl_data.ba_pos >= 12) && (vl_data.ba_pos <= 21)) begin
                        get_proc_offset = 5;
                     end
                     else begin
                        get_proc_offset = 0; // not tabled for this ba_pos value
                     end
               end
               0: begin
                     if ((vl_data.ba_pos >= 0) && (vl_data.ba_pos <= 7)) begin
                        get_proc_offset = 6;
                     end
                     else if ((vl_data.ba_pos >= 8) && (vl_data.ba_pos <= 20)) begin
                        get_proc_offset = 5;
                     end
                     else if (vl_data.ba_pos == 21) get_proc_offset = 4;
                     else begin
                        get_proc_offset = 0; // not tabled for this ba_pos value
                     end
               end
               default: get_proc_offset = 0; // not tabled for this ba_phase value
            endcase
          end
          3,8,13,18: begin
            case(vl_data.ba_phase)
               2: begin
                  case(vl_data.ba_pos)
                     21,20,19,18,17,16: get_proc_offset = 5;
                     2,1,0: get_proc_offset = 7;
                     default: begin
                        if ((vl_data.ba_pos >= 3) && (vl_data.ba_pos <= 15)) begin
                           get_proc_offset = 6;
                        end
                        else begin
                           get_proc_offset = 0; // not tabled for this ba_pos value
                        end
                     end
                  endcase
               end
               1: begin
                     if ((vl_data.ba_pos >= 0) && (vl_data.ba_pos <= 11)) begin
                        get_proc_offset = 6;
                     end
                     else if ((vl_data.ba_pos >= 12) && (vl_data.ba_pos <= 21)) begin
                        get_proc_offset = 5;
                     end
                     else begin
                        get_proc_offset = 0; // not tabled for this ba_pos value
                     end
               end
               0: begin
                     if ((vl_data.ba_pos >= 0) && (vl_data.ba_pos <= 7)) begin
                        get_proc_offset = 6;
                     end
                     else if ((vl_data.ba_pos >= 8) && (vl_data.ba_pos <= 20)) begin
                        get_proc_offset = 5;
                     end
                     else if (vl_data.ba_pos == 21) get_proc_offset = 4;
                     else begin
                        get_proc_offset = 0; // not tabled for this ba_pos value
                     end
               end
               default: get_proc_offset = 0; // not tabled for this ba_phase value
            endcase
          end
          4,9,14,19: begin
            case(vl_data.ba_phase)
               2: begin
                  case(vl_data.ba_pos)
                     21,20,19,18,17,16: get_proc_offset = 5;
                     2,1,0: get_proc_offset = 7;
                     default: begin
                        if ((vl_data.ba_pos >= 3) && (vl_data.ba_pos <= 15)) begin
                           get_proc_offset = 6;
                        end
                        else begin
                           get_proc_offset = 0; // not tabled for this ba_pos value
                        end
                     end
                  endcase
               end
               1: begin
                     if ((vl_data.ba_pos >= 0) && (vl_data.ba_pos <= 11)) begin
                        get_proc_offset = 6;
                     end
                     else if ((vl_data.ba_pos >= 12) && (vl_data.ba_pos <= 21)) begin
                        get_proc_offset = 5;
                     end
                     else begin
                        get_proc_offset = 0; // not tabled for this ba_pos value
                     end
               end
               0: begin
                     if ((vl_data.ba_pos >= 0) && (vl_data.ba_pos <= 6)) begin
                        get_proc_offset = 6;
                     end
                     else if ((vl_data.ba_pos >= 7) && (vl_data.ba_pos <= 20)) begin
                        get_proc_offset = 5;
                     end
                     else if (vl_data.ba_pos == 21) get_proc_offset = 4;
                     else begin
                        get_proc_offset = 0; // not tabled for this ba_pos value
                     end
               end
               default: get_proc_offset = 0; // not tabled for this ba_phase value
            endcase
          end
          default: get_proc_offset = 0; // not tabled for this ba_phase value
       endcase

       $display($sformatf("proc_offset = %0d, vl_data = %p", get_proc_offset, vl_data));

       return get_proc_offset;

    endfunction

   // Capturing the data and storing it into VL struct
   function generate_vl_data_fec_mode(rx_rsfec_dskw_delay_s m_dskw_delay);

      static bit [31:0] UI_25G = 32'h00_09_EE_01;
      bit [31:0]   vl_offset;
      int          vl_offset_bits;
      static int unsigned max_final_offset =  32'hFF_FF_FF_FF;
      bit [63:0] vl_offset_result;

      for (int i=0; i<20; i++) begin : GEN_VL_OFFSET_FEC_MODE
         vl_offset_bits = m_dskw_delay.deskew_delay + $floor(i/4);
         $display(
            $sformatf("before-rotation: VL[PL] %0d[%0d], deskew_delay = %0d UI, vl_offset_bits = %0d",
               i, m_dskw_delay.selected_pl, m_dskw_delay.deskew_delay, vl_offset_bits));
         if ((i >= 16) && (i <= 19)) begin
            vl_offset_bits = vl_offset_bits ;
            $display(
               $sformatf("before-rotation: VL[PL] %0d[%0d], deskew_delay = %0d UI, vl_offset_bits_shifted = %0d",
                  i, m_dskw_delay.selected_pl, m_dskw_delay.deskew_delay, vl_offset_bits));

         end
         if (vl_offset_bits < 0) begin
             vl_offset_result = ((max_final_offset - vl_offset_bits +1)* UI_25G)>>8;
             vl_offset[30:0] = vl_offset_result[30:0];
             vl_offset[31] = 1;
         end
         else begin
            vl_offset_result = (vl_offset_bits * UI_25G) >>8;
            vl_offset[30:0] = vl_offset_result[30:0];
            vl_offset[31] = 0;
         end

         // Generating array based on the collected VL information
         vl_offset_collected[i]         = 1;
         vl_offset_load_arr[i][38:7]    = vl_offset;
         vl_offset_load_arr[i][6:5]     = m_dskw_delay.selected_pl;
         vl_offset_load_arr[i][4:0]     = ((i+4)%20);

         $display(
            $sformatf("After rotation: VL_OFFSET for RVL[PL] %0d[%0d] = %0h ns %0h Fns, Sign bit= %0d ",
               vl_offset_load_arr[i][4:0], vl_offset_load_arr[i][6:5], vl_offset_load_arr[i][37:23],
               vl_offset_load_arr[i][22:7], vl_offset_load_arr[i][38]));

      end : GEN_VL_OFFSET_FEC_MODE

   endfunction

endmodule
