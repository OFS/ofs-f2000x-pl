// Copyright (C) 2020 Intel Corporation.
// SPDX-License-Identifier: MIT

//
// Description
//-----------------------------------------------------------------------------
// NCSI ingress passthrough module
//-----------------------------------------------------------------------------

module ncsi_ipt #(
   parameter   DEVICE_FAMILY            = "Agilex", //FPGA Device Family
   parameter   CAP_NUM_CH               = 5'h1,     //No. of channels supported
   parameter   IPT_BUFR_DEPTH           = 8192,     //Ingress Passthrough Buffer Depth
   parameter   IPT_MAX_PKT_LEN          = 1522      //Max packet length of IPT packet
)(
   input  logic                        clk                  ,
   input  logic                        reset                ,
   
   //AVMM slave (Ingress Passthrough i/f from BNIC/OVS)
   input  logic [0:0]                  ipt_avmm_s_addr      ,
   input  logic                        ipt_avmm_s_write     ,
   input  logic                        ipt_avmm_s_read      ,
   input  logic [63:0]                 ipt_avmm_s_wrdata    ,
   input  logic [7:0]                  ipt_avmm_s_byteen    ,
   output logic [63:0]                 ipt_avmm_s_rddata    ,
   output logic                        ipt_avmm_s_rddvld    ,
   output logic                        ipt_avmm_s_waitreq   ,

   //NCSI Ingress Passthrough to Arbiter Tx AvST i/f
   output logic [31:0]                 i2a_ipttx_data       ,
   output logic                        i2a_ipttx_sop        ,
   output logic                        i2a_ipttx_eop        ,
   output logic                        i2a_ipttx_err        ,
   output logic [1:0]                  i2a_ipttx_mod        ,
   output logic                        i2a_ipttx_vld        ,
   input  logic                        i2a_ipttx_rdy        ,

   //NCSI Ingress Passthrough to Egress Passthrough Loopback
   output logic [31:0]                 i2e_lpbk_data        ,
   output logic                        i2e_lpbk_sop         ,
   output logic                        i2e_lpbk_eop         ,
   output logic [1:0]                  i2e_lpbk_mod         ,
   output logic                        i2e_lpbk_vld         ,
   input  logic                        i2e_lpbk_rdy         ,

   //Nios CSR i/f
   input  logic                        ignr_fltr_cfg        ,
   input  logic                        ncsi_pt_lpbk_en      ,
   input  logic [CAP_NUM_CH-1:0]       ncsi_ch_en           ,
   input  logic [CAP_NUM_CH-1:0]       ncsi_ch_init_st      
);

localparam  RAM_DEPTH    = IPT_BUFR_DEPTH/4;
localparam  RAM_AWID     = $clog2(RAM_DEPTH);

localparam  PKT_MAX_BEAT = (IPT_MAX_PKT_LEN+7)/8-1;
localparam  PKT_CWID     = $clog2(PKT_MAX_BEAT+2);
localparam  PKT_LAST_BE  = 7 - (IPT_MAX_PKT_LEN%8);

enum {
   IPT_RX_RESET_BIT = 0,
   IPT_RX_IDLE_BIT  = 1,
   IPT_RX_PLD_BIT   = 2,
   IPT_RX_EOP_BIT   = 3,
   IPT_RX_DROP_BIT  = 4
} ipt_rx_state_bit;

enum logic [4:0] {
   IPT_RX_RESET_ST  = 5'h1 << IPT_RX_RESET_BIT,
   IPT_RX_IDLE_ST   = 5'h1 << IPT_RX_IDLE_BIT ,
   IPT_RX_PLD_ST    = 5'h1 << IPT_RX_PLD_BIT  ,
   IPT_RX_EOP_ST    = 5'h1 << IPT_RX_EOP_BIT  ,
   IPT_RX_DROP_ST   = 5'h1 << IPT_RX_DROP_BIT  
} ipt_rx_state, ipt_rx_next;

typedef struct packed {
    logic           sop;
    logic           eop;
    logic   [1:0]   mod;
    logic   [31:0]  data;
} ipt_pkt_t;

logic [RAM_AWID:0]   ipt_bfr_a_addr    ;
ipt_pkt_t            ipt_bfr_a_wrd     ;
logic                ipt_bfr_a_wren    ;
ipt_pkt_t            ipt_bfr_a_rdd     ;
logic [RAM_AWID:0]   ipt_bfr_b_addr    ;
ipt_pkt_t            ipt_bfr_b_rdd     ;

logic                flow_ctrl_sop     ;
logic                flow_ctrl_eop     ;
logic                flow_ctrl_dvld    ;
logic                bfr_wr_vld        ;
logic                ipt_bfr_full      ;
logic                flow_ctrl_dvld_r1 ;
logic [31:0]         ipt_rx_data_r1    ;
logic [3:0]          ipt_rx_byteen_r1  ;
logic                rx_sop_flag       ;
logic [PKT_CWID:0]   rx_pkt_bcnt       ;
logic                drop_rx_pkt       ;
logic                skip_eop_wait     ;
logic [RAM_AWID:0]   prev_pkt_waddr    ;

logic                tx_sink_rdy       ;
logic                pkt_tx_start      ;
logic                ipt_bfr_empty     ;
logic                ipt_tx_wip        ;
logic                ipt_bfr_b_rden    ;
logic                ipt_bfr_b_rden_r1 ;
logic                ipt_bfr_b_rden_r2 ;
logic                tx_sink_vld       ;
logic [31:0]         tx_sink_data      ;
logic                tx_sink_sop       ;
logic                tx_sink_eop       ;
logic [1:0]          tx_sink_mod       ;


//------------------------------------------------------------------------------
// Function to convert byte-en to mod
//------------------------------------------------------------------------------
function automatic logic[1:0] be2mod (                                  
   input logic [3:0] be
);                                                                              
   if(be[3:0] == 4'hF)
      be2mod = 2'd0;
   else if(be[3:1] == 3'h7)
      be2mod = 2'd1;
   else if(be[3:2] == 2'h3)
      be2mod = 2'd2;
   else if(be[3])
      be2mod = 2'd3;
   else
      be2mod = 2'd0;
   return be2mod;                                                        
endfunction

//-----------------------------------------------------------------------------
// Ingress Passthrough AvMM Slave Read
//-----------------------------------------------------------------------------
always_ff @(posedge clk, posedge reset)
begin : ipt_avmm_seq
   if(reset) begin
      ipt_avmm_s_waitreq    <= 1'b1;
      ipt_avmm_s_rddvld     <= 1'b0;
   end else begin
      if (ipt_avmm_s_read && !ipt_avmm_s_waitreq)
         ipt_avmm_s_rddvld <= 1'b1;
      else
         ipt_avmm_s_rddvld <= 1'b0;
         
      if (ipt_avmm_s_write && !ipt_avmm_s_waitreq || ipt_rx_state[IPT_RX_EOP_BIT])
         ipt_avmm_s_waitreq <= 1'b1;
      else
         ipt_avmm_s_waitreq <= 1'b0;
   end
end : ipt_avmm_seq

assign ipt_avmm_s_rddata = 64'd0;


//-----------------------------------------------------------------------------
// Tx FIFO Arbitier state machine
//-----------------------------------------------------------------------------
always_ff @(posedge clk, posedge reset)
begin : ipt_rx_fsm_seq
   if(reset)
      ipt_rx_state <= IPT_RX_RESET_ST;
   else
      ipt_rx_state <= ipt_rx_next;
end : ipt_rx_fsm_seq

always_comb
begin : ipt_rx_fsm_comb
   ipt_rx_next = ipt_rx_state;
   unique case (1'b1) //Reverse Case Statement
      ipt_rx_state[IPT_RX_RESET_BIT]:   //IPT_RX_RESET_ST
         if(reset)
            ipt_rx_next = IPT_RX_RESET_ST;
         else
            ipt_rx_next = IPT_RX_IDLE_ST;
      
      ipt_rx_state[IPT_RX_IDLE_BIT]:   //IPT_RX_IDLE_ST
         if(flow_ctrl_sop)
            ipt_rx_next = IPT_RX_PLD_ST;

      ipt_rx_state[IPT_RX_PLD_BIT]:    //IPT_RX_PLD_ST 
         if(ipt_bfr_full && bfr_wr_vld || drop_rx_pkt)
            ipt_rx_next = IPT_RX_DROP_ST;
         else if(flow_ctrl_eop)
            ipt_rx_next = IPT_RX_EOP_ST;
      
      //Update EOP bit of the packet
      ipt_rx_state[IPT_RX_EOP_BIT]:    //IPT_RX_EOP_ST 
         if(drop_rx_pkt)
            ipt_rx_next = IPT_RX_DROP_ST;
         else
            ipt_rx_next = IPT_RX_IDLE_ST;
            
      //Drop packet
      ipt_rx_state[IPT_RX_DROP_BIT]:   //IPT_RX_DROP_ST 
         if(flow_ctrl_eop || skip_eop_wait)
            ipt_rx_next = IPT_RX_IDLE_ST;
   endcase
end : ipt_rx_fsm_comb


//-----------------------------------------------------------------------------
// FSM Control Signals
//-----------------------------------------------------------------------------
always_comb
begin : ifsm_ctrl_comb
   if(ipt_avmm_s_write && !ipt_avmm_s_waitreq && !ipt_avmm_s_addr && ipt_avmm_s_byteen[0]) begin
      flow_ctrl_sop  = ipt_avmm_s_wrdata[0];
      flow_ctrl_eop  = ipt_avmm_s_wrdata[1];
   end else begin
      flow_ctrl_sop  = 1'b0;
      flow_ctrl_eop  = 1'b0;
   end
   
   flow_ctrl_dvld = ~ipt_avmm_s_waitreq & ipt_avmm_s_write & ipt_avmm_s_addr;
   
   bfr_wr_vld = flow_ctrl_dvld | flow_ctrl_dvld_r1;
   
   if(ipt_bfr_a_addr[RAM_AWID-1:0] == ipt_bfr_b_addr[RAM_AWID-1:0] && 
      ipt_bfr_a_addr[RAM_AWID]     != ipt_bfr_b_addr[RAM_AWID])
      ipt_bfr_full = 1'b1;
   else
      ipt_bfr_full = 1'b0;
end : ifsm_ctrl_comb


//-----------------------------------------------------------------------------
// Ingress AVMM slave logic
//-----------------------------------------------------------------------------
always_ff @(posedge clk, posedge reset)
begin : ipt_bfr_wr_seq
   if(reset) begin
      flow_ctrl_dvld_r1    <= 1'b0;
      ipt_rx_data_r1       <= 32'd0;
      ipt_rx_byteen_r1     <= 4'd0;
      rx_sop_flag          <= 1'b0;
      rx_pkt_bcnt          <= '0;
      drop_rx_pkt          <= 1'b0;
      skip_eop_wait        <= 1'b0;
      prev_pkt_waddr       <= '0;
      ipt_bfr_a_wren       <= 1'b0;
      ipt_bfr_a_addr       <= '0;
      ipt_bfr_a_wrd        <= '{default:0};
   end else begin
      flow_ctrl_dvld_r1 <= (flow_ctrl_dvld && ipt_avmm_s_byteen[3]) ? 1'b1 : 1'b0;
      
      if(flow_ctrl_dvld) begin
         ipt_rx_data_r1    <= ipt_avmm_s_wrdata[31:0];
         ipt_rx_byteen_r1  <= ipt_avmm_s_byteen[3:0];
      end
      
      if(ipt_bfr_a_wren)
         rx_sop_flag       <= 1'b0;
      else if(ipt_rx_state[IPT_RX_IDLE_BIT])
         rx_sop_flag       <= 1'b1;
      
      if(ipt_rx_state[IPT_RX_IDLE_BIT])
         rx_pkt_bcnt      <= '0;
      else if(flow_ctrl_dvld)
         rx_pkt_bcnt      <= rx_pkt_bcnt + 1'b1;
       
      //drop packet if channel is disabled
      //drop packet if buffer has no storage
      //drop packet if size is too small (less than 15bytes)
      //drop packet if size is too large (more than IPT_MAX_PKT_LEN)
      if(!ncsi_ch_en[0] && !ncsi_pt_lpbk_en ||
         rx_pkt_bcnt <  'd2 && flow_ctrl_eop || 
         rx_pkt_bcnt == 'd1 && flow_ctrl_dvld && ipt_avmm_s_byteen[7:1] != 7'h7F || 
         rx_pkt_bcnt >  PKT_MAX_BEAT && flow_ctrl_dvld) 
         drop_rx_pkt       <= 1'b1;
      else
         drop_rx_pkt       <= 1'b0;
      
      skip_eop_wait <= ipt_rx_state[IPT_RX_EOP_BIT] & drop_rx_pkt;
      
      //Previous address to revert back to in case of drops
      if(ipt_rx_state[IPT_RX_IDLE_BIT])
         prev_pkt_waddr  <= ipt_bfr_a_addr;
         
      if(ipt_rx_state[IPT_RX_PLD_BIT] && bfr_wr_vld && !ipt_bfr_full ||
                                                ipt_rx_state[IPT_RX_EOP_BIT])
         ipt_bfr_a_wren <= 1'b1;
      else
         ipt_bfr_a_wren <= 1'b0;
      
      if(ipt_rx_state[IPT_RX_DROP_BIT])
         ipt_bfr_a_addr <= prev_pkt_waddr;
      else if(ipt_rx_state[IPT_RX_EOP_BIT])
         ipt_bfr_a_addr <= ipt_bfr_a_addr - 1'b1;
      else if(ipt_bfr_a_wren)
         ipt_bfr_a_addr <= ipt_bfr_a_addr + 1'b1;
         
      if(ipt_rx_state[IPT_RX_EOP_BIT])
         ipt_bfr_a_wrd.eop   <= 1'b1;
      else if(flow_ctrl_dvld_r1) begin
         ipt_bfr_a_wrd.sop   <= 1'b0;
         ipt_bfr_a_wrd.eop   <= 1'b0;
         ipt_bfr_a_wrd.mod   <= be2mod(ipt_rx_byteen_r1);
         ipt_bfr_a_wrd.data  <= ipt_rx_data_r1;
      end else if(flow_ctrl_dvld) begin
         ipt_bfr_a_wrd.sop   <= rx_sop_flag;
         ipt_bfr_a_wrd.eop   <= 1'b0;
         ipt_bfr_a_wrd.mod   <= be2mod(ipt_avmm_s_byteen[7:4]);
         ipt_bfr_a_wrd.data  <= ipt_avmm_s_wrdata[63:32];
      end
   end
end : ipt_bfr_wr_seq

//-----------------------------------------------------------------------------
// NCSI Ingress Passthrough Buffer
// Port-A : IPT Rx side (from IOFS/AFU) write
// Port-B : IPT Tx side (to NCSI Tx Arbiter) read
//-----------------------------------------------------------------------------
altera_syncram ipt_buffer 
(
   .clock0           (clk              ),
   .address_a        (ipt_bfr_a_addr[RAM_AWID-1:0]),
   .data_a           (ipt_bfr_a_wrd    ),
   .wren_a           (ipt_bfr_a_wren   ),
   .q_a              (ipt_bfr_a_rdd    ),
   .address_b        (ipt_bfr_b_addr[RAM_AWID-1:0]),
   .data_b           ({32{1'b1}}       ),
   .wren_b           (1'b0             ),
   .q_b              (ipt_bfr_b_rdd    ),
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
   ipt_buffer.address_aclr_b          = "NONE",
   ipt_buffer.address_reg_b           = "CLOCK0",
   ipt_buffer.clock_enable_input_a    = "BYPASS",
   ipt_buffer.clock_enable_input_b    = "BYPASS",
   ipt_buffer.clock_enable_output_b   = "BYPASS",
   ipt_buffer.intended_device_family  = DEVICE_FAMILY,
   ipt_buffer.lpm_type                = "altera_syncram",
   ipt_buffer.numwords_a              = RAM_DEPTH,
   ipt_buffer.numwords_b              = RAM_DEPTH,
   ipt_buffer.operation_mode          = "DUAL_PORT",
   ipt_buffer.outdata_aclr_b          = "NONE",
   ipt_buffer.outdata_sclr_b          = "NONE",
   ipt_buffer.outdata_reg_b           = "CLOCK0",
   ipt_buffer.power_up_uninitialized  = "FALSE",
   ipt_buffer.read_during_write_mode_mixed_ports  = "DONT_CARE",
   ipt_buffer.widthad_a               = RAM_AWID,
   ipt_buffer.widthad_b               = RAM_AWID,
   ipt_buffer.width_a                 = 36,
   ipt_buffer.width_b                 = 36,
   ipt_buffer.width_byteena_a         = 1,
   ipt_buffer.width_byteena_b         = 1;


//-----------------------------------------------------------------------------
// Ingress Passthrough Tx (AvST) Logic
//-----------------------------------------------------------------------------
always_comb
begin : ipt_bfr_rd_comb
   tx_sink_rdy  = ~ncsi_pt_lpbk_en & i2a_ipttx_rdy | ncsi_pt_lpbk_en & i2e_lpbk_rdy;
   pkt_tx_start = ~ipt_bfr_empty & ipt_bfr_b_rdd.sop;
end : ipt_bfr_rd_comb

always_ff @(posedge clk, posedge reset)
begin : ipt_bfr_rd_seq
   if(reset) begin
      ipt_bfr_empty     <= 1'b0;
      ipt_tx_wip        <= 1'b0;
      ipt_bfr_b_addr    <= '0;
      ipt_bfr_b_rden    <= 1'b0;
      ipt_bfr_b_rden_r1 <= 1'b0;
      ipt_bfr_b_rden_r2 <= 1'b0;
      tx_sink_vld       <= 1'b0;
      tx_sink_data      <= 32'd0;
      tx_sink_sop       <= 1'b0;
      tx_sink_eop       <= 1'b0;
      tx_sink_mod       <= 2'd0;
   end else begin
      if(prev_pkt_waddr[RAM_AWID-1:0] == ipt_bfr_b_addr[RAM_AWID-1:0] && 
         prev_pkt_waddr[RAM_AWID]     == ipt_bfr_b_addr[RAM_AWID])
         ipt_bfr_empty <= 1'b1;
      else
         ipt_bfr_empty <= 1'b0;
      
      if(tx_sink_eop && tx_sink_vld && tx_sink_rdy)
         ipt_tx_wip <= 1'b0;
      else if(pkt_tx_start)
         ipt_tx_wip <= 1'b1;
      
      if(tx_sink_vld && tx_sink_rdy)
         ipt_bfr_b_addr <= ipt_bfr_b_addr + 1'b1;
         
      if(!ipt_tx_wip && pkt_tx_start || 
          ipt_tx_wip && tx_sink_vld && tx_sink_rdy)
         ipt_bfr_b_rden <= 1'b1;
      else 
         ipt_bfr_b_rden <= 1'b0;
      
      ipt_bfr_b_rden_r1 <= ipt_bfr_b_rden;
      ipt_bfr_b_rden_r2 <= ipt_bfr_b_rden_r1;
      
      if(ipt_tx_wip && ipt_bfr_b_rden_r2)
         tx_sink_vld       <= 1'b1;
      else if(tx_sink_rdy)
         tx_sink_vld       <= 1'b0;
      
      if(ipt_bfr_b_rden_r2) begin
         tx_sink_data <= ipt_bfr_b_rdd.data;
         tx_sink_sop  <= ipt_bfr_b_rdd.sop;
         tx_sink_eop  <= ipt_bfr_b_rdd.eop;
         tx_sink_mod  <= (ipt_bfr_b_rdd.eop) ? ipt_bfr_b_rdd.mod : 2'd0;
      end 
   end
end : ipt_bfr_rd_seq


//-----------------------------------------------------------------------------
// Ingress Passthrough Tx (AvST) Logic
//-----------------------------------------------------------------------------
always_comb
begin : ipt_avst_seq
   i2a_ipttx_data = tx_sink_data;
   i2a_ipttx_sop  = tx_sink_sop;
   i2a_ipttx_eop  = tx_sink_eop;
   i2a_ipttx_err  = 1'b0;
   i2a_ipttx_mod  = tx_sink_mod;
   i2a_ipttx_vld  = ~ncsi_pt_lpbk_en & tx_sink_vld;
   
   i2e_lpbk_data  = tx_sink_data;
   i2e_lpbk_sop   = tx_sink_sop;
   i2e_lpbk_eop   = tx_sink_eop;
   i2e_lpbk_mod   = tx_sink_mod;
   i2e_lpbk_vld   = ncsi_pt_lpbk_en & tx_sink_vld;
end : ipt_avst_seq

endmodule
