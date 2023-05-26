// Copyright (C) 2020 Intel Corporation.
// SPDX-License-Identifier: MIT


`timescale 1ns/1ps
module axi_lite_bfm #(
  parameter                        ADDR_WIDTH = 32,
  parameter                        DATA_WIDTH = 32
)(
  input                            aclk,
  input                            aresetn,
  output                           axi_lite_awvalid_o,
  input                            axi_lite_awready_i,
  output                    [2:0]  axi_lite_awprot_o,
  output         [ADDR_WIDTH-1:0]  axi_lite_awaddr_o,
  output         [DATA_WIDTH-1:0]  axi_lite_wdata_o,
  output       [DATA_WIDTH/8-1:0]  axi_lite_wstrb_o,
  output                           axi_lite_wvalid_o,
  input                            axi_lite_wready_i,
  input                            axi_lite_bvalid_i,
  output                           axi_lite_bready_o,
  input                     [1:0]  axi_lite_bresp_i,

  output                           axi_lite_arvalid_o,
  input                            axi_lite_arready_i,
  output                    [2:0]  axi_lite_arprot_o,
  output         [ADDR_WIDTH-1:0]  axi_lite_araddr_o,
  input          [DATA_WIDTH-1:0]  axi_lite_rdata_i,
  input                     [1:0]  axi_lite_rresp_i,
  input                            axi_lite_rvalid_i,
  output                           axi_lite_rready_o
);

  //--------------------------------------------------------------------------------
  // Signals
  //--------------------------------------------------------------------------------

  // AVMM slave interface
  reg    [ADDR_WIDTH-1:0]  avmm_address;
  reg    [DATA_WIDTH-1:0]  avmm_writedata;
  reg  [DATA_WIDTH/8-1:0]  avmm_byteenable;
  reg    [DATA_WIDTH-1:0]  avmm_readdata;
  reg                      avmm_read_op;
  reg                      avmm_write_op;
  wire                     avmm_waitrequest;
  wire                     avmm_readdata_valid;
  integer csr_err = 0;

  //--------------------------------------------------------------------------------
  // AVMM Tasks
  //--------------------------------------------------------------------------------

  task automatic avmm_write  (input logic [31:0] addr,   input logic [31:0] data, input logic [ 3:0] strb = 4'hF);
    avmm_address  = addr;
    avmm_read_op = 1'b0;
    avmm_byteenable = strb;
    @(negedge aclk);
    avmm_write_op     = 1'b1;
    avmm_writedata = data;
    $display("TBINFO:%t\tAddress offset = %h, WriteData = %h", $time,avmm_address, avmm_writedata);
    @(posedge aclk);
    while (avmm_waitrequest !== 1'b0) @(negedge aclk);
     @(negedge aclk);
    avmm_write_op <= 1'b0;
  endtask

  task avmm_read_chk;
    input logic [31:0]      addr;
    input logic [31:0]      refdout;
    input logic [31:0]      mask;
    avmm_address          = addr;
    avmm_write_op     = 1'b0;
    avmm_byteenable = 4'hF;
    @(negedge aclk);
    avmm_read_op  = 1'b1;
    @(posedge aclk);
    while (avmm_waitrequest !== 1'b0) @(negedge aclk);
    @(posedge aclk);
    avmm_read_op  <= 1'b0;
    while (avmm_readdata_valid !== 1'b1) @(negedge aclk);
    if (refdout == (avmm_readdata & mask))
      $display("TBINFO:%t\tAddress offset = %h, ReadData  = %h", $time, avmm_address, avmm_readdata);
    else begin
      $display("TBINFO:%t\tERROR - Base Address = %h, ReadData = %h, Expected_ReadData = %h", $time, avmm_address, avmm_readdata & mask, refdout[31:0]);
      csr_err = csr_err + 1;
    end
  endtask

  task automatic avmm_read( input logic [31:0] addr,output reg [31:0]  readdata, input logic [3:0] strb = 4'hf);
    readdata = 0;
    avmm_address      = addr;
    avmm_write_op     = 1'b0;
    @(negedge aclk);
    avmm_read_op  = 1'b1;
    @(posedge aclk);
    while (avmm_waitrequest !== 1'b0) @(negedge aclk);
    @(posedge aclk);
    avmm_read_op  <= 1'b0;
    while (avmm_readdata_valid !== 1'b1) @(negedge aclk);
    $display("TBINFO:%t\tAddress offset = %h, ReadData  = %h", $time, avmm_address, avmm_readdata );
    if(strb[0]) readdata[ 7: 0] = avmm_readdata[7:0];
    if(strb[1]) readdata[15: 8] = avmm_readdata[15:8];
    if(strb[2]) readdata[23:16] = avmm_readdata[23:16];
    if(strb[3]) readdata[31:24] = avmm_readdata[31:24];
  endtask

  task clear_error;
    begin
      csr_err = 0;
    end
  endtask

  task automatic ptpRegConfig (input [31:0] base, input [31:0] offset0, input [31:0] offset1, input [2:0] cmd_sel, input [3:0] port_no);
    begin
      logic [31:0] control = 0;
      control[2:0] = (cmd_sel[2:0] == 3)? 3'h1 : (cmd_sel[2:0] == 3'h5)? 3'h4 : (cmd_sel[2:0] == 3'h6)? 3'h4 : (cmd_sel[2:0] == 3'h7)? 3'h2 : 3'h0;
      axiBFM.avmm_write  ((base | 32'h2A) + port_no*4, offset0);
      axiBFM.avmm_write  ((base | 32'h3A) + port_no*4, offset1);
      axiBFM.avmm_write  ((base | 32'h4A) + port_no*4, control);
    end
  endtask

  //--------------------------------------------------------------------------------
  // AXILite
  //--------------------------------------------------------------------------------

  avmm2axiLite_bridge axiLite_master (
    .aclk                     ( aclk ),
    .aresetn                  ( aresetn ),
    .avmm_address_i           ( avmm_address ),
    .avmm_writedata_i         ( avmm_writedata ),
    .avmm_byteenable_i        ( avmm_byteenable ),
    .avmm_readdata_o          ( avmm_readdata ),
    .avmm_read_i              ( avmm_read_op ),
    .avmm_write_i             ( avmm_write_op ),
    .avmm_waitrequest_o       ( avmm_waitrequest ),
    .avmm_readdata_valid_o    ( avmm_readdata_valid ),
    .axi_lite_awvalid_o       ( axi_lite_awvalid_o ),
    .axi_lite_awready_i       ( axi_lite_awready_i ),
    .axi_lite_awprot_o        ( axi_lite_awprot_o ),
    .axi_lite_awaddr_o        ( axi_lite_awaddr_o ),
    .axi_lite_wdata_o         ( axi_lite_wdata_o  ),
    .axi_lite_wstrb_o         ( axi_lite_wstrb_o ),
    .axi_lite_wvalid_o        ( axi_lite_wvalid_o ),
    .axi_lite_wready_i        ( axi_lite_wready_i ),
    .axi_lite_bvalid_i        ( axi_lite_bvalid_i ),
    .axi_lite_bready_o        ( axi_lite_bready_o ),
    .axi_lite_bresp_i         ( axi_lite_bresp_i ),
    .axi_lite_arvalid_o       ( axi_lite_arvalid_o ),
    .axi_lite_arready_i       ( axi_lite_arready_i ),
    .axi_lite_arprot_o        ( axi_lite_arprot_o ),
    .axi_lite_araddr_o        ( axi_lite_araddr_o ),
    .axi_lite_rdata_i         ( axi_lite_rdata_i  ),
    .axi_lite_rresp_i         ( axi_lite_rresp_i ),
    .axi_lite_rvalid_i        ( axi_lite_rvalid_i ),
    .axi_lite_rready_o        ( axi_lite_rready_o )
  );

endmodule
