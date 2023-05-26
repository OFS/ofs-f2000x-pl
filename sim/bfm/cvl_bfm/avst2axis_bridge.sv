// Copyright (C) 2020 Intel Corporation.
// SPDX-License-Identifier: MIT

module avst2axis_bridge #(
  parameter                   WORDS = 1,
  parameter                   WIDTH = 64,
  parameter                   EMPTY_WIDTH =3
)(
  input                       aclk,
  input                       aresetn,
  input                       tx_error_i,
  input                       tx_skip_crc_i,
  input              [  7:0]  ptp_fp_i,
  input                       ptp_ins_ets_i,
  input                       ptp_ts_req_i,
  input              [ 95:0]  ptp_tx_its_i,
  input                       ptp_ins_cf_i,
  input                       ptp_ins_zero_csum_i,
  input                       ptp_ins_update_eb_i,
  input                       ptp_ins_ts_format_i,
  input              [ 15:0]  ptp_ins_ts_offset_i,
  input              [ 15:0]  ptp_ins_cf_offset_i,
  input              [ 15:0]  ptp_ins_csum_offset_i,
  input              [ 15:0]  ptp_ins_eb_offset_i,

  // AXI-S interface
  output                      axis_tvalid_o,
  output   [WIDTH*WORDS-1:0]  axis_tdata_o,
  input                       axis_tready_i,
  output [WIDTH*WORDS/8-1:0]  axis_tkeep_o,
  output                      axis_tlast_o,
  output             [  1:0]  axis_tuser_client_o,
  output             [ 89:0]  axis_tuser_ptp_o,
  output             [327:0]  axis_tuser_ptp_ext_o,

  // AValon-ST Interface
  input                       avst_valid_i,
  input    [WIDTH*WORDS-1:0]  avst_data_i,
  input    [EMPTY_WIDTH-1:0]  avst_empty_i,
  input                       avst_sop_i,
  input                       avst_eop_i,
  output                      avst_ready_o

);

  //----------------------------------------
  // Output logic
  //----------------------------------------
  genvar i;

  assign axis_tvalid_o = avst_valid_i;
  //assign axis_tdata_o  = avst_data_i;
  assign avst_ready_o  = axis_tready_i;
  assign axis_tlast_o  = avst_eop_i;
  assign axis_tkeep_o  = avst_eop_i? ({(WIDTH*WORDS/8){1'b1}} >> avst_empty_i) : {(WIDTH*WORDS/8){1'b1}};

  assign axis_tuser_client_o = {tx_skip_crc_i,tx_error_i};
  assign axis_tuser_ptp_o    = {44'b0,24'b0,ptp_fp_i,10'b0,ptp_ins_ets_i,ptp_ts_req_i,1'b0,1'b0};
  assign axis_tuser_ptp_ext_o[193:0]= {30'b0,ptp_ins_ts_offset_i,ptp_ins_cf_offset_i,ptp_ins_csum_offset_i,ptp_ins_eb_offset_i,ptp_ins_zero_csum_i,ptp_ins_update_eb_i,ptp_ins_ts_format_i,ptp_tx_its_i,ptp_ins_cf_i};
  assign axis_tuser_ptp_ext_o[327:194]= '0;

  generate for (i=0;i<(WIDTH*WORDS/8);i++) begin : data_byte_flip
    assign axis_tdata_o[i*8 +: 8] =  avst_data_i[WIDTH*WORDS-i*8-1 -: 8];
  end endgenerate


endmodule
//------------------------------------------------------------------------------
//
//
// End avst2axis_bridge.sv
//
//------------------------------------------------------------------------------
