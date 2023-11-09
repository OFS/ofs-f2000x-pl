// Copyright (C) 2020 Intel Corporation.
// SPDX-License-Identifier: MIT

//
// Description
//-----------------------------------------------------------------------------
// NCSI command request and response buffer module
//-----------------------------------------------------------------------------

module ncsi_cra_buffer #(
   parameter   DEVICE_FAMILY            = "Agilex"  //FPGA Device Family
)(
   input  logic                        clk                  ,
   input  logic                        reset                ,

   //AVMM slave (connected to PMCI-Nios)
   input  logic [10:0]                 nios_bfr_addr        ,
   input  logic                        nios_bfr_write       ,
   input  logic                        nios_bfr_read        ,
   input  logic [31:0]                 nios_bfr_wrdata      ,
 //input  logic [3:0]                  nios_bfr_byteen      ,
   output logic [31:0]                 nios_bfr_rddata_c    , //command buffer
   output logic [31:0]                 nios_bfr_rddata_r    , //response buffer
   output logic                        nios_bfr_rddvld_c    ,
   output logic                        nios_bfr_rddvld_r    ,
   input  logic                        nios_bfr_waitreq     ,
   
   //NCSI Parser to Buffer Command Rx AvST i/f
   input  logic [31:0]                 p2b_ncrx_data        ,
   input  logic                        p2b_ncrx_sop         ,
   input  logic                        p2b_ncrx_eop         ,
   input  logic [5:0]                  p2b_ncrx_err         ,
   input  logic [1:0]                  p2b_ncrx_mod         ,
   input  logic                        p2b_ncrx_vld         ,
   output logic                        p2b_ncrx_rdy         ,
   
   //NCSI Buffer to Arbiter Response/AEN Tx AvST i/f
   output logic [31:0]                 b2a_nrtx_data        ,
   output logic                        b2a_nrtx_sop         ,
   output logic                        b2a_nrtx_eop         ,
   output logic [1:0]                  b2a_nrtx_mod         ,
   output logic                        b2a_nrtx_err         ,
   output logic                        b2a_nrtx_rna         ,
   output logic                        b2a_nrtx_eb4sr       ,
   output logic                        b2a_nrtx_vld         ,
   input  logic                        b2a_nrtx_rdy         ,
   input  logic                        b2a_nrtx_sent        ,
   
   //Nios CSR i/f
   output logic                        ncsi_rx_cmd_pulse    ,
   output logic [11:0]                 ncsi_rx_cmd_size     ,
   output logic [15:0]                 ncsi_rx_cmd_err      ,
   input  logic                        ncsi_rx_cmd_busy     ,
   
   input  logic                        ncsi_tx_resp_avail   ,
   input  logic                        ncsi_tx_resp_naen    ,
   input  logic [11:0]                 ncsi_tx_resp_size    ,
   input  logic                        ncsi_tx_eb4sr        ,
   output logic                        ncsi_tx_resp_sent    ,

   output logic [15:0]                 ncsi_rx_cmd_good_cntr,
   output logic [15:0]                 ncsi_rx_cmd_err_cntr ,
   output logic [15:0]                 ncsi_tx_resp_cntr 
);

enum {
   RSP_RESET_BIT = 0,
   RSP_IDLE_BIT  = 1,
   RSP_HDR1_BIT  = 2,
   RSP_HDR2_BIT  = 3,
   RSP_HDR3_BIT  = 4,
   RSP_PLD_BIT   = 5,
   RSP_WAIT_BIT  = 6
} rsp_state_bit;

enum logic [6:0] {
   RSP_RESET_ST  = 7'h1 << RSP_RESET_BIT,
   RSP_IDLE_ST   = 7'h1 << RSP_IDLE_BIT ,
   RSP_HDR1_ST   = 7'h1 << RSP_HDR1_BIT ,
   RSP_HDR2_ST   = 7'h1 << RSP_HDR2_BIT ,
   RSP_HDR3_ST   = 7'h1 << RSP_HDR3_BIT ,
   RSP_PLD_ST    = 7'h1 << RSP_PLD_BIT  ,
   RSP_WAIT_ST   = 7'h1 << RSP_WAIT_BIT  
} rsp_state, rsp_next;

logic [7:0]    cmd_bfr_b_addr    ;
logic [31:0]   cmd_bfr_b_rdd     ;
logic [7:0]    cmd_bfr_a_addr    ;
logic [31:0]   cmd_bfr_a_wrd     ;
logic          cmd_bfr_a_wren    ;
logic [31:0]   cmd_bfr_a_rdd     ;
logic [7:0]    resp_bfr_a_addr   ;
logic [31:0]   resp_bfr_a_wrd    ;
logic          resp_bfr_a_wren   ;
logic [31:0]   resp_bfr_a_rdd    ;
logic [8:0]    resp_bfr_b_addr   ;
logic [31:0]   resp_bfr_b_rdd    ;

logic          nios_bfr_rden_c   ;
logic          nios_bfr_rden_r   ;
logic [1:0]    cmd_rx_wcntr      ;
logic          cmd_rx_wip        ;
logic [15:0]   p2b_ncrx_data_r1  ;
logic          resp_bfr_b_rden   ;
logic          resp_bfr_b_rden_r1;
logic          resp_bfr_b_rden_r2;
logic [15:0]   resp_bfr_b_rdd_r1 ;


//-----------------------------------------------------------------------------
// Nios Buffer Access Logic
//-----------------------------------------------------------------------------
always_comb
begin : nios_accs_comb
   cmd_bfr_b_addr    = nios_bfr_addr[7:0];
   resp_bfr_a_addr   = nios_bfr_addr[7:0];
   
   if(nios_bfr_addr[10:8] == 3'h6)
      resp_bfr_a_wren = nios_bfr_write & ~nios_bfr_waitreq;
   else
      resp_bfr_a_wren = 1'b0;
   
   resp_bfr_a_wrd    = nios_bfr_wrdata;
   
   nios_bfr_rddata_c = cmd_bfr_b_rdd;
   nios_bfr_rddata_r = resp_bfr_a_rdd;
end : nios_accs_comb

always_ff @(posedge clk, posedge reset)
begin : nios_accs_seq
   if(reset) begin
    nios_bfr_rden_c    <= 1'b0;
    nios_bfr_rden_r    <= 1'b0;
    nios_bfr_rddvld_c  <= 1'b0;
    nios_bfr_rddvld_r  <= 1'b0;
   end else begin
      if(nios_bfr_addr[10:9] == 2'h2 && nios_bfr_read && !nios_bfr_waitreq)
         nios_bfr_rden_c <= 1'b1;
      else
         nios_bfr_rden_c <= 1'b0;
      
      if(nios_bfr_addr[10:9] == 2'h3 && nios_bfr_read && !nios_bfr_waitreq)
         nios_bfr_rden_r <= 1'b1;
      else
         nios_bfr_rden_r <= 1'b0;
         
      nios_bfr_rddvld_c  <= nios_bfr_rden_c;   
      nios_bfr_rddvld_r  <= nios_bfr_rden_r;   
   end
end : nios_accs_seq

//-----------------------------------------------------------------------------
// Command message write
//-----------------------------------------------------------------------------
always_ff @(posedge clk, posedge reset)
begin : cmd_msg_rx_seq
   if(reset) begin
      cmd_rx_wcntr      <= 2'd0;
      cmd_rx_wip        <= 1'b0;
      p2b_ncrx_data_r1  <= 16'd0;
      cmd_bfr_a_wren    <= 1'b0;
      cmd_bfr_a_addr    <= 8'h0;
      cmd_bfr_a_wrd     <= 32'h0;
      ncsi_rx_cmd_pulse <= 1'b0;
      ncsi_rx_cmd_size  <= 12'h0;
      ncsi_rx_cmd_err   <= 16'h0;
   end else begin
      if(p2b_ncrx_sop && p2b_ncrx_vld && p2b_ncrx_rdy)
         cmd_rx_wcntr <= 2'd0;
      else if(cmd_rx_wcntr != 2'd3 && p2b_ncrx_vld && p2b_ncrx_rdy)
         cmd_rx_wcntr <= cmd_rx_wcntr + 1'b1;

      if(p2b_ncrx_eop && p2b_ncrx_vld && p2b_ncrx_rdy)
         cmd_rx_wip  <= 1'b0;
      else if(cmd_rx_wcntr == 2'd2 && p2b_ncrx_vld && p2b_ncrx_rdy && !ncsi_rx_cmd_busy)
         cmd_rx_wip  <= 1'b1;
      
      if(p2b_ncrx_vld && p2b_ncrx_rdy)
         p2b_ncrx_data_r1  <= p2b_ncrx_data[15:0];
         
      if(cmd_rx_wip && p2b_ncrx_vld && p2b_ncrx_rdy || ncsi_rx_cmd_pulse)
         cmd_bfr_a_wren <= 1'b1;
      else 
         cmd_bfr_a_wren <= 1'b0;
         
      if(p2b_ncrx_sop && p2b_ncrx_vld && p2b_ncrx_rdy)
         cmd_bfr_a_addr <= 8'd0;
      else if(cmd_bfr_a_wren && cmd_bfr_a_addr != 8'hFF)
         cmd_bfr_a_addr <= cmd_bfr_a_addr + 1'b1;
         
      cmd_bfr_a_wrd  <= {p2b_ncrx_data_r1, p2b_ncrx_data[31:16]};
      
      if(cmd_rx_wip && p2b_ncrx_eop && p2b_ncrx_vld && p2b_ncrx_rdy) begin
         ncsi_rx_cmd_pulse    <= 1'b1;
         ncsi_rx_cmd_size     <= {cmd_bfr_a_addr, 2'd0} + 3'd6 - p2b_ncrx_mod;
         ncsi_rx_cmd_err[15]  <= p2b_ncrx_err[0];
         ncsi_rx_cmd_err[5:1] <= p2b_ncrx_err[5:1];
         ncsi_rx_cmd_err[0]   <= (cmd_bfr_a_addr == 8'hFF) ? 1'b1 : 1'b0; //1023?
      end else
         ncsi_rx_cmd_pulse <= 1'b0;
   end
end : cmd_msg_rx_seq

assign p2b_ncrx_rdy = 1'b1;

//-----------------------------------------------------------------------------
// NCSI Command Buffer
// Port-A : Cmd Message Write (RTL)
// Port-B : PMCI Nios Read
// Command Buffer : 0x000~0x0FF (Nios 0x1000~0x13FF)
//-----------------------------------------------------------------------------
altera_syncram cmd_buffer 
(
   .clock0           (clk              ),
   .address_a        (cmd_bfr_a_addr   ),
   .data_a           (cmd_bfr_a_wrd    ),
   .wren_a           (cmd_bfr_a_wren   ),
   .q_a              (cmd_bfr_a_rdd    ),
   .address_b        (cmd_bfr_b_addr   ),
   .data_b           ({32{1'b1}}       ),
   .wren_b           (1'b0             ),
   .q_b              (cmd_bfr_b_rdd    ),
   .aclr0            (1'b0             ),
   .aclr1            (1'b0             ),
   .address2_a       (1'b1             ),
   .address2_b       (1'b1             ),
   .addressstall_a   (1'b0             ),
   .addressstall_b   (1'b0             ),
   .byteena_a        (1'b1             ),
   .byteena_b        (1'b1             ),
   .clock1           (1'b1             ),
   .clocken0         (1'b1             ),
   .clocken1         (1'b1             ),
   .clocken2         (1'b1             ),
   .clocken3         (1'b1             ),
   .eccencbypass     (1'b0             ),
   .eccencparity     (8'b0             ),
   .eccstatus        (                 ),
   .rden_a           (1'b1             ),
   .rden_b           (1'b1             ),
   .sclr             (1'b0             )
);

defparam
   cmd_buffer.address_aclr_b          = "NONE",
   cmd_buffer.address_reg_b           = "CLOCK0",
   cmd_buffer.clock_enable_input_a    = "BYPASS",
   cmd_buffer.clock_enable_input_b    = "BYPASS",
   cmd_buffer.clock_enable_output_b   = "BYPASS",
   cmd_buffer.intended_device_family  = DEVICE_FAMILY,
   cmd_buffer.lpm_type                = "altera_syncram",
   cmd_buffer.numwords_a              = 256,
   cmd_buffer.numwords_b              = 256,
   cmd_buffer.operation_mode          = "DUAL_PORT",
   cmd_buffer.outdata_aclr_b          = "NONE",
   cmd_buffer.outdata_sclr_b          = "NONE",
   cmd_buffer.outdata_reg_b           = "CLOCK0",
   cmd_buffer.power_up_uninitialized  = "FALSE",
   cmd_buffer.read_during_write_mode_mixed_ports  = "DONT_CARE",
   cmd_buffer.widthad_a               = 8,
   cmd_buffer.widthad_b               = 8,
   cmd_buffer.width_a                 = 32,
   cmd_buffer.width_b                 = 32,
   cmd_buffer.width_byteena_a         = 1,
   cmd_buffer.width_byteena_b         = 1;


//-----------------------------------------------------------------------------
// Response/AEN Message Construction FSM
//-----------------------------------------------------------------------------
always_ff @(posedge clk, posedge reset)
begin : rsp_fsm_seq
   if(reset)
      rsp_state <= RSP_RESET_ST;
   else
      rsp_state <= rsp_next;
end : rsp_fsm_seq

always_comb
begin : rsp_fsm_comb
   rsp_next = rsp_state;
   unique case (1'b1) //Reverse Case Statement
      rsp_state[RSP_RESET_BIT]:   //RSP_RESET_ST
         if(reset)
            rsp_next = RSP_RESET_ST;
         else
            rsp_next = RSP_IDLE_ST;
      
      rsp_state[RSP_IDLE_BIT]:   //RSP_IDLE_ST
         if(ncsi_tx_resp_avail)
            rsp_next = RSP_HDR1_ST;
            
      rsp_state[RSP_HDR1_BIT]:   //RSP_HDR1_ST
         if(b2a_nrtx_rdy)
            rsp_next = RSP_HDR2_ST;
            
      rsp_state[RSP_HDR2_BIT]:   //RSP_HDR2_ST
         if(b2a_nrtx_rdy)
            rsp_next = RSP_HDR3_ST;
            
      rsp_state[RSP_HDR3_BIT]:   //RSP_HDR3_ST
         if(b2a_nrtx_rdy)
            rsp_next = RSP_PLD_ST;

      rsp_state[RSP_PLD_BIT]:   //RSP_PLD_ST 
         if(b2a_nrtx_eop && b2a_nrtx_vld && b2a_nrtx_rdy)
            rsp_next = RSP_WAIT_ST;

      rsp_state[RSP_WAIT_BIT]:   //RSP_WAIT_ST 
         if(b2a_nrtx_sent)
            rsp_next = RSP_IDLE_ST;
   endcase
end : rsp_fsm_comb

//-----------------------------------------------------------------------------
// Response/AEN Message Readout
//-----------------------------------------------------------------------------
always_ff @(posedge clk, posedge reset)
begin : resp_msg_rx_seq
   if(reset) begin
      resp_bfr_b_addr      <= 9'h0;
      resp_bfr_b_rden      <= 1'b0;
      resp_bfr_b_rden_r1   <= 1'b0;
      resp_bfr_b_rden_r2   <= 1'b0;
      resp_bfr_b_rdd_r1    <= 16'd0;
      b2a_nrtx_vld         <= 1'b0;
      b2a_nrtx_sop         <= 1'b0;
      b2a_nrtx_eop         <= 1'b0;
      b2a_nrtx_mod         <= 2'd0;
      b2a_nrtx_data        <= 32'd0;
   end else begin
      if(!rsp_state[RSP_PLD_BIT])
         resp_bfr_b_addr <= 9'd0;
      else if(b2a_nrtx_vld && b2a_nrtx_rdy)
         resp_bfr_b_addr <= resp_bfr_b_addr + 1'b1;
        
      if(rsp_state[RSP_PLD_BIT]  && b2a_nrtx_rdy && b2a_nrtx_vld)
         resp_bfr_b_rden <= 1'b1;
      else 
         resp_bfr_b_rden <= 1'b0;
      
      resp_bfr_b_rden_r1 <= resp_bfr_b_rden;
      
      if(rsp_state[RSP_HDR3_BIT] && b2a_nrtx_rdy || resp_bfr_b_rden_r1)
         resp_bfr_b_rden_r2 <= 1'b1;
      else
         resp_bfr_b_rden_r2 <= 1'b0;
      
      if(rsp_state[RSP_IDLE_BIT])
         resp_bfr_b_rdd_r1  <= 16'h88F8;
      else if(rsp_state[RSP_PLD_BIT])  
         resp_bfr_b_rdd_r1  <= resp_bfr_b_rdd[15:0];
         
      if(rsp_state[RSP_IDLE_BIT] && ncsi_tx_resp_avail || 
         rsp_state[RSP_HDR1_BIT] || rsp_state[RSP_HDR2_BIT] || 
         rsp_state[RSP_HDR3_BIT] && !b2a_nrtx_rdy ||
         rsp_state[RSP_PLD_BIT]  && resp_bfr_b_rden_r2)
         b2a_nrtx_vld       <= 1'b1;
      else if(b2a_nrtx_rdy)
         b2a_nrtx_vld       <= 1'b0;
      
      if(rsp_state[RSP_IDLE_BIT])
         b2a_nrtx_data   <= 32'hFFFF_FFFF;
      else if(rsp_state[RSP_PLD_BIT] && resp_bfr_b_rden_r2)  
         b2a_nrtx_data   <= {resp_bfr_b_rdd_r1, resp_bfr_b_rdd[31:16]};
         
      if(rsp_state[RSP_IDLE_BIT] && ncsi_tx_resp_avail)
         b2a_nrtx_sop    <= 1'b1;
      else if(b2a_nrtx_vld && b2a_nrtx_rdy)
         b2a_nrtx_sop    <= 1'b0;
      
      if(rsp_state[RSP_PLD_BIT] && (
          ncsi_tx_resp_size[1:0] == 2'd3 && resp_bfr_b_addr == (ncsi_tx_resp_size[9:2] + 1'b1) ||
          ncsi_tx_resp_size[1:0] != 2'd3 && resp_bfr_b_addr == (ncsi_tx_resp_size[9:2]))) begin
         b2a_nrtx_eop    <= 1'b1;
         b2a_nrtx_mod    <= ~ncsi_tx_resp_size[1:0] + 2'h3;
      end else if(rsp_state[RSP_IDLE_BIT]) begin
         b2a_nrtx_eop    <= 1'b0;
         b2a_nrtx_mod    <= 2'd0;
      end
   end
end : resp_msg_rx_seq

assign  b2a_nrtx_err       = 1'b0;
assign  b2a_nrtx_rna       = ncsi_tx_resp_naen;
assign  b2a_nrtx_eb4sr     = ncsi_tx_eb4sr;
assign  ncsi_tx_resp_sent  = b2a_nrtx_sent;

//-----------------------------------------------------------------------------
// NCSI Response/AEN Buffer
// Port-A : PMCI Nios Write
// Port-B : Response Message Read (RTL)
// ResponseBuffer : 0x100~0x1FF (Nios 0x1800~0x1BFF)
//-----------------------------------------------------------------------------
altera_syncram resp_buffer 
(
   .clock0           (clk              ),
   .address_a        (resp_bfr_a_addr  ),
   .data_a           (resp_bfr_a_wrd   ),
   .wren_a           (resp_bfr_a_wren  ),
   .q_a              (resp_bfr_a_rdd   ),
   .address_b        (resp_bfr_b_addr[7:0]),
   .data_b           ({32{1'b1}}       ),
   .wren_b           (1'b0             ),
   .q_b              (resp_bfr_b_rdd   ),
   .aclr0            (1'b0             ),
   .aclr1            (1'b0             ),
   .address2_a       (1'b1             ),
   .address2_b       (1'b1             ),
   .addressstall_a   (1'b0             ),
   .addressstall_b   (1'b0             ),
   .byteena_a        (1'b1             ),
   .byteena_b        (1'b1             ),
   .clock1           (1'b1             ),
   .clocken0         (1'b1             ),
   .clocken1         (1'b1             ),
   .clocken2         (1'b1             ),
   .clocken3         (1'b1             ),
   .eccencbypass     (1'b0             ),
   .eccencparity     (8'b0             ),
   .eccstatus        (                 ),
   .rden_a           (1'b1             ),
   .rden_b           (1'b1             ),
   .sclr             (1'b0             )
);

defparam
   resp_buffer.address_aclr_b          = "NONE",
   resp_buffer.address_reg_b           = "CLOCK0",
   resp_buffer.clock_enable_input_a    = "BYPASS",
   resp_buffer.clock_enable_input_b    = "BYPASS",
   resp_buffer.clock_enable_output_b   = "BYPASS",
   resp_buffer.intended_device_family  = DEVICE_FAMILY,
   resp_buffer.lpm_type                = "altera_syncram",
   resp_buffer.numwords_a              = 256,
   resp_buffer.numwords_b              = 256,
   resp_buffer.operation_mode          = "DUAL_PORT",
   resp_buffer.outdata_aclr_b          = "NONE",
   resp_buffer.outdata_sclr_b          = "NONE",
   resp_buffer.outdata_reg_b           = "CLOCK0",
   resp_buffer.power_up_uninitialized  = "FALSE",
   resp_buffer.read_during_write_mode_mixed_ports  = "DONT_CARE",
   resp_buffer.widthad_a               = 8,
   resp_buffer.widthad_b               = 8,
   resp_buffer.width_a                 = 32,
   resp_buffer.width_b                 = 32,
   resp_buffer.width_byteena_a         = 1;


//-----------------------------------------------------------------------------
// Debug Registers
//-----------------------------------------------------------------------------
always_ff @(posedge clk, posedge reset)
begin : dbug_sts_seq
   if(reset) begin
      ncsi_rx_cmd_good_cntr <= 16'h0;
      ncsi_rx_cmd_err_cntr  <= 16'h0;
      ncsi_tx_resp_cntr     <= 16'h0;
   end else begin      
      if(ncsi_rx_cmd_pulse && !ncsi_rx_cmd_err[15] && !ncsi_rx_cmd_err[0])
         ncsi_rx_cmd_good_cntr <= ncsi_rx_cmd_good_cntr + 1'b1;
      
      if(ncsi_rx_cmd_pulse && (ncsi_rx_cmd_err[15] || ncsi_rx_cmd_err[0]))
         ncsi_rx_cmd_err_cntr  <= ncsi_rx_cmd_err_cntr + 1'b1;
         
      if(ncsi_tx_resp_avail && ncsi_tx_resp_sent)
         ncsi_tx_resp_cntr     <= ncsi_tx_resp_cntr + 1'b1;
   end
end : dbug_sts_seq


endmodule