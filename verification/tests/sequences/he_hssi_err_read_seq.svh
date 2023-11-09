// Copyright (C) 2023 Intel Corporation
// SPDX-License-Identifier: MIT

`ifndef HE_HSSI_ERR_READ_SEQ_SVH
`define HE_HSSI_ERR_READ_SEQ_SVH

class he_hssi_err_read_seq extends base_seq;
    `uvm_object_utils(he_hssi_err_read_seq)

    parameter TRAFFIC_CTRL_CMD_ADDR = 32'h30;
    parameter TRAFFIC_CTRL_CH_SEL = 32'h40;
    parameter TG_PKT_LEN_TYPE_ADDR =32'h3801;
    parameter TG_PKT_LEN_TYPE_VAL=1'b0;
    parameter TG_PKT_LEN_ADDR=32'h380D;
    parameter TG_PKT_LEN_VAL=32'h42;
    parameter TG_DATA_PATTERN_ADDR=32'h3802;
    parameter LOOPBACK_EN_ADDR = 32'h3A00;
    parameter TG_DATA_PATTERN_VAL=32'h0;
    parameter TG_NUM_PKT_ADDR=32'h3800;
    parameter TG_NUM_PKT_VAL=32'h20;
    parameter TG_START_XFR_ADDR=32'h3803;
    parameter TM_PKT_BAD_ADDR=32'h3902;
    parameter TM_PKT_GOOD_ADDR=32'h3901;
    parameter MB_ADDRESS_OFFSET = 32'h4;
    parameter MB_RDDATA_OFFSET  = 32'h8;
    parameter MB_WRDATA_OFFSET  = 32'hC;
    parameter MB_NOOP = 32'h0;
    parameter MB_RD = 32'h1;
    parameter MB_WR = 32'h2;
    parameter RX_STATISTICS_ADDR = 32'h3000;
    parameter TX_STATISTICS_ADDR = 32'h7000;
    parameter HSSI_RCFG_CMD_ADDR = 32'h28;
    parameter TM_AVST_RX_ERR_ADDR = 32'h3907;
 
    function new (string name = "he_hssi_err_read_seq");
        super.new(name);
    endfunction : new

    task body();
        logic [63:0] cur_pf_table;
        logic [63:0] framesOK_1,framesOK_2;
	logic        tx_rx_mismatch = 0;
	logic        error_bit = 0;
        int len;
        super.body();
	`uvm_info(get_name(), "Entering sequence...", UVM_LOW)
         read_TM_AVST_RX_ERR();
	`uvm_info(get_name(), "Exiting sequence...", UVM_LOW)
    endtask : body

    task write_mailbox();
        input [63:0] cmd_ctrl_addr;
	input [63:0] addr;
	input [63:0] write_data32;
	begin
             mmio_write32(cmd_ctrl_addr + MB_WRDATA_OFFSET , write_data32);
             mmio_write32(cmd_ctrl_addr + MB_ADDRESS_OFFSET, addr      );
             mmio_write32(cmd_ctrl_addr                    , MB_WR       );
	     read_ack_mailbox(cmd_ctrl_addr);
             mmio_write32(cmd_ctrl_addr                    , MB_NOOP     );
	end
    endtask : write_mailbox

    task read_ack_mailbox;
        input bit [63:0] cmd_ctrl_addr;
        begin
	    bit [63:0] rdata = 64'h0;
	    int        rd_attempts = 0;
	    bit        ack_done_reg = 0;
	    while(~ack_done_reg && rd_attempts < 7) begin
                mmio_read64(cmd_ctrl_addr, rdata);
		ack_done_reg = rdata[2];
		rd_attempts++;
	    end

	    if(~ack_done_reg)
	        `uvm_fatal(get_name(), "Did not ACK for last transaction!")

	end
    endtask : read_ack_mailbox



task read_mailbox;
   input  logic [63:0] cur_pf_table;
   input  logic [31:0] bar;
   input  logic [63:0] cmd_ctrl_addr; // Start address of mailbox access reg
   input  logic [63:0] addr; //Byte address
   output logic [63:0] rd_data64;
   begin
      mmio_write32(cmd_ctrl_addr + MB_ADDRESS_OFFSET, addr); // DW address
      mmio_write32(cmd_ctrl_addr, MB_RD); // read Cmd
      read_ack_mailbox(cmd_ctrl_addr);
      mmio_read64(cmd_ctrl_addr + MB_RDDATA_OFFSET, rd_data64);
     $display("INFO: Read MAILBOX ADDR:%x, READ_DATA64:%X", addr, rd_data64);
      mmio_write32(cmd_ctrl_addr, MB_NOOP); // no op Cmd
   end
endtask
    





// Wait until all packets received back
task read_TM_AVST_RX_ERR;
   logic [63:0] wdata;
   logic [63:0] cur_pf_table;
   logic [63:0] addr;
   logic [31:0] ERR_PKT_RCVD;
   logic [31:0] len;
   
    len=0; //Port 0
    wdata =   32'h1*len;//SEL_PORT_0
    addr = tb_cfg0.PF0_VF1_BAR0+HE_HSSI_BASE_ADDR+TRAFFIC_CTRL_CH_SEL;
    mmio_write32(.addr_(addr), .data_(wdata));
   
    #1us;
    read_mailbox(cur_pf_table, 0, tb_cfg0.PF0_VF1_BAR0+HE_HSSI_BASE_ADDR+TRAFFIC_CTRL_CMD_ADDR, TM_AVST_RX_ERR_ADDR,ERR_PKT_RCVD);
    `uvm_info("body", $sformatf("ERR_REG %b ",ERR_PKT_RCVD), UVM_LOW);
 

endtask



endclass : he_hssi_err_read_seq

`endif // HE_HSSI_ERR_READ_SEQ_SVH
