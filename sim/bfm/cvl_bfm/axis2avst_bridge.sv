// Copyright (C) 2020 Intel Corporation.
// SPDX-License-Identifier: MIT

module axis2avst_bridge #(
  parameter                   WORDS = 1,
  parameter                   WIDTH = 64,
  parameter                   EMPTY_WIDTH =3
)(
  input                       aclk,
  input                       aresetn,

  // AXI-S interface
  input                       axis_tvalid_i,
  input    [WIDTH*WORDS-1:0]  axis_tdata_i,
  output                      axis_tready_o,
  input  [WIDTH*WORDS/8-1:0]  axis_tkeep_i,
  input                       axis_tlast_i,
  input               [ 6:0]  axis_tuser_client_i, // TBD
  input               [ 4:0]  axis_tuser_sts,      // TBD
  input               [31:0]  axis_tuser_sts_ext,  // TBD

  // AValon-ST Interface
  output                      avst_valid_o,
  output   [WIDTH*WORDS-1:0]  avst_data_o,
  output   [EMPTY_WIDTH-1:0]  avst_empty_o,
  output                      avst_sop_o,
  output                      avst_eop_o,
  input                       avst_ready_i

);

  //----------------------------------------
  // Signals
  //----------------------------------------

  logic [EMPTY_WIDTH-1:0] empty_bytes;
  logic frame_in_prog;
  logic frame_start;
  logic frame_end;

  //----------------------------------------
  // SOP & Empty bytes
  //----------------------------------------

  assign frame_start = axis_tvalid_i? axis_tready_o : 1'b0;
  assign frame_end   = axis_tvalid_i? axis_tready_o & axis_tlast_i : 1'b0;

  always @(posedge aclk, negedge aresetn) begin
    if(!aresetn) begin
      frame_in_prog <= 1'b0;
    end else begin
      frame_in_prog <= (frame_in_prog | frame_start) & ~frame_end;
    end
  end

  always @(*) begin
    empty_bytes = 0;
    for(int i=0;i<WIDTH*WORDS/8;i=i+1)begin
      if(~axis_tkeep_i[WIDTH*WORDS/8-1-i])
        empty_bytes = i;
    end
  end
  
  //----------------------------------------
  // Output logic
  //----------------------------------------

  genvar i;

  assign avst_valid_o = axis_tvalid_i;
  //assign avst_data_o  = axis_tdata_i;
  assign avst_ready_o = avst_ready_i;
  assign avst_sop_o   = axis_tvalid_i & ~frame_in_prog;
  assign avst_eop_o   = axis_tlast_i;
  assign avst_empty_o = axis_tlast_i? empty_bytes : {(WIDTH*WORDS/8){1'b0}};

  assign axis_tready_o = avst_ready_i;

  generate for (i=0;i<(WIDTH*WORDS/8);i++) begin : data_byte_flip
    assign avst_data_o[i*8 +: 8] =  axis_tdata_i[WIDTH*WORDS-i*8-1 -: 8];
  end endgenerate
  

endmodule
//------------------------------------------------------------------------------
//
//
// End axis2avst_bridge.sv
//
//------------------------------------------------------------------------------
