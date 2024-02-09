// Copyright (C) 2020 Intel Corporation.
// SPDX-License-Identifier: MIT

//
// Description
//-----------------------------------------------------------------------------
// NCSI RBT Rx traffic parser module
//-----------------------------------------------------------------------------

module ncsi_rx_parser #(
   parameter   DEVICE_FAMILY            = "Agilex", //FPGA Device Family
   parameter   CAP_NUM_CH               = 5'h1      //No. of channels supported
)(
   //input clock & reset
   input  logic                        clk                  ,
   input  logic                        reset                ,
   input  logic                        clk_ncsi             ,
   input  logic                        rst_ncsi             ,
   
   //TSE MAC Rx interface
   input  logic [31:0]                 mac_rx_data          ,
   input  logic                        mac_rx_sop           ,
   input  logic                        mac_rx_eop           ,
   input  logic [5:0]                  mac_rx_err           ,
   input  logic [1:0]                  mac_rx_mod           ,
   input  logic                        mac_rx_vld           ,
   output logic                        mac_rx_rdy           ,
   
   input  logic [3:0]                  mac_rx_frm_type      ,
   
   //NCSI Parser to Buffer Command Rx AvST i/f
   output logic [31:0]                 p2b_ncrx_data        ,
   output logic                        p2b_ncrx_sop         ,
   output logic                        p2b_ncrx_eop         ,
   output logic [5:0]                  p2b_ncrx_err         ,
   output logic [1:0]                  p2b_ncrx_mod         ,
   output logic                        p2b_ncrx_vld         ,
   input  logic                        p2b_ncrx_rdy         ,
   
   //NCSI Parser to Egress Passthrough AvST i/f
   output logic [31:0]                 p2e_eptrx_data       ,
   output logic                        p2e_eptrx_sop        ,
   output logic                        p2e_eptrx_eop        ,
   output logic [5:0]                  p2e_eptrx_err        ,
   output logic [1:0]                  p2e_eptrx_mod        ,
   output logic [47:0]                 p2e_eptrx_sma        ,
   output logic                        p2e_eptrx_bcst       ,
   output logic                        p2e_eptrx_mcst       ,
   output logic                        p2e_eptrx_vld        ,
   input  logic                        p2e_eptrx_rdy        ,

   //Nios CSR i/f
   input  logic [2:0]                  package_id                   

);

enum {
   RXP_RESET_BIT = 0,
   RXP_IDLE_BIT  = 1,
   RXP_NCM_BIT   = 2,
   RXP_EPT_BIT   = 3,
   RXP_DROP_BIT  = 4
} rxp_state_bit;

enum logic [4:0] {
   RXP_RESET_ST  = 5'h1 << RXP_RESET_BIT,
   RXP_IDLE_ST   = 5'h1 << RXP_IDLE_BIT ,
   RXP_NCM_ST    = 5'h1 << RXP_NCM_BIT  ,
   RXP_EPT_ST    = 5'h1 << RXP_EPT_BIT  ,
   RXP_DROP_ST   = 5'h1 << RXP_DROP_BIT 
} rxp_state, rxp_next;

typedef struct packed {
    logic           sop;
    logic           eop;
    logic   [5:0]   err;
    logic   [1:0]   mod;
    logic   [31:0]  data;
} rx_avst_t;

logic          rx_dvld           ;  
logic          rxfifo_wrreq      ;  
logic          rxfifo_wrfull     ;  
logic [2:0]    rxfifo_wrusedw    ;  
rx_avst_t      rxfifo_wrdata     ;
rx_avst_t      rxfifo_rddata     ;
logic          rxfifo_rdreq      ;  
logic          rxfifo_rdempty    ;  

logic          ch_id_match       ;  
logic          pkt_size_lt22     ;  
logic          pkt_size_lt15     ;  
logic [2:0]    word_num          ;
logic          rx_bcast_msg      ;
logic          rx_mcast_msg      ;
logic [47:0]   src_mac_addr      ;
logic          rx_ncsi_msg       ;
logic          rx_ncsi_msg_vld   ;
logic          drop_msg          ;
logic          flags_valid       ;
logic          flags_valid_sync  ;
logic          flags_valid_sync_r1;
logic          rxfifo_rden       ;
rx_avst_t      ncsi_rx_rec       ;
logic          rx_bcast_msg_sync ;
logic          rx_mcast_msg_sync ;
logic [47:0]   src_mac_addr_sync ;


//-----------------------------------------------------------------------------
// Rx FIFO Write Logic
//-----------------------------------------------------------------------------
always_ff @(posedge clk_ncsi, posedge rst_ncsi)
begin : rxfifo_wr_seq
   if(rst_ncsi) begin
    rxfifo_wrreq           <= 1'b0;
    mac_rx_rdy             <= 1'b0;
    rxfifo_wrdata          <= '{default:0};
   end else begin
      mac_rx_rdy           <= (rxfifo_wrfull || rxfifo_wrusedw > 3'd3) ? 1'b0 : 1'b1;
      rxfifo_wrreq         <= rx_dvld;
      rxfifo_wrdata.sop    <= mac_rx_sop;
      rxfifo_wrdata.eop    <= mac_rx_eop;
      rxfifo_wrdata.err    <= mac_rx_err;
      rxfifo_wrdata.mod    <= mac_rx_mod;
      rxfifo_wrdata.data   <= mac_rx_data;
   end
end : rxfifo_wr_seq

assign rx_dvld = mac_rx_vld;

//-----------------------------------------------------------------------------
// CDC FIFO - NCSI to PMCI clock domain
//-----------------------------------------------------------------------------
dcfifo  ncsi_rx_cdc_fifo (
   .aclr       (rst_ncsi      ),
   .wrclk      (clk_ncsi      ),
   .wrreq      (rxfifo_wrreq  ),
   .wrfull     (rxfifo_wrfull ),
   .wrempty    (              ),
   .data       (rxfifo_wrdata ),
   .wrusedw    (rxfifo_wrusedw),
   .rdclk      (clk           ),
   .rdreq      (rxfifo_rdreq  ),
   .rdempty    (rxfifo_rdempty),
   .rdfull     (),
   .q          (rxfifo_rddata ),
   .rdusedw    (),
   .eccstatus  ());
defparam
   ncsi_rx_cdc_fifo.enable_ecc  = "FALSE",
   ncsi_rx_cdc_fifo.intended_device_family  = DEVICE_FAMILY,
   ncsi_rx_cdc_fifo.lpm_hint  = "DISABLE_DCFIFO_EMBEDDED_TIMING_CONSTRAINT=TRUE",
   ncsi_rx_cdc_fifo.lpm_numwords  = 8,
   ncsi_rx_cdc_fifo.lpm_showahead  = "ON",
   ncsi_rx_cdc_fifo.lpm_type  = "dcfifo",
   ncsi_rx_cdc_fifo.lpm_width  = 42,
   ncsi_rx_cdc_fifo.lpm_widthu  = 3,
   ncsi_rx_cdc_fifo.overflow_checking  = "ON",
   ncsi_rx_cdc_fifo.rdsync_delaypipe  = 4,
   ncsi_rx_cdc_fifo.underflow_checking  = "ON",
   ncsi_rx_cdc_fifo.use_eab  = "ON",
   ncsi_rx_cdc_fifo.wrsync_delaypipe  = 4;


//-----------------------------------------------------------------------------
// Rx Frame Parsing Logic
//-----------------------------------------------------------------------------
always_comb
begin : rx_parse_comb
   if(mac_rx_data[7:5] == package_id && 
              (mac_rx_data[4:0] < CAP_NUM_CH || mac_rx_data[4:0] == 5'h1F))
      ch_id_match = 1'b1;
   else
      ch_id_match = 1'b0;
   
   pkt_size_lt15  = (word_num < 3'd3 || word_num == 3'd3 && mac_rx_mod[1]) ? 1'b1 : 1'b0;
   pkt_size_lt22  = (word_num < 3'd5 || word_num == 3'd5 && mac_rx_mod == 2'd3) ? 1'b1 : 1'b0;
end : rx_parse_comb

always_ff @(posedge clk_ncsi, posedge rst_ncsi)
begin : rx_parse_seq
   if(rst_ncsi) begin
      word_num          <= 3'd0;
      rx_bcast_msg      <= 1'b0;
      rx_mcast_msg      <= 1'b0;
      src_mac_addr      <= 48'd0;
      rx_ncsi_msg       <= 1'b0;
      rx_ncsi_msg_vld   <= 1'b0;
      drop_msg          <= 1'b0;
      flags_valid       <= 1'b0;
   end else begin
      if(mac_rx_sop && rx_dvld)
         word_num       <= 3'd1;
      else if(word_num != 3'd7 && rx_dvld)
         word_num       <= word_num + 1'b1;
      
      //Broadcast Message
      if(mac_rx_sop && rx_dvld)
         rx_bcast_msg   <= mac_rx_frm_type[2];
      
      //Multicast Message
      if(mac_rx_sop && rx_dvld)
         rx_mcast_msg   <= mac_rx_frm_type[1];
      
      //Source MAC address
      if(word_num == 3'd1 && rx_dvld)
         src_mac_addr[47:32] <= mac_rx_data[15:0];
      else if(word_num == 3'd2 && rx_dvld)
         src_mac_addr[31:0]  <= mac_rx_data;
      
      //NCSI Control Message
      if(word_num == 3'd3 && rx_dvld && rx_bcast_msg && mac_rx_data[31:16] == 16'h88F8)
         rx_ncsi_msg    <= 1'b1;
      else if(word_num == 3'd3 && rx_dvld)
         rx_ncsi_msg    <= 1'b0;
      
      //Our NCSI Control Message
      if(mac_rx_sop && rx_dvld)
         rx_ncsi_msg_vld <= 1'b0;
      else if(word_num == 3'd4 && rx_dvld && rx_ncsi_msg && ch_id_match)
         rx_ncsi_msg_vld <= 1'b1;
      
      //Drop if Channel-ID doesnt match
      //Drop if any message size less than 15
      //Drop if NCSI message size less than 22
      if(mac_rx_sop && rx_dvld)
         drop_msg <= 1'b0;
      else if(word_num == 3'd4 && rx_dvld && rx_ncsi_msg && !ch_id_match ||
         pkt_size_lt15 && rx_dvld && mac_rx_eop ||
         pkt_size_lt22 && rx_dvld && rx_ncsi_msg && mac_rx_eop)
         drop_msg <= 1'b1;
      
      //Indicate valid to FIFO read FSM
      if(mac_rx_sop && rx_dvld)
         flags_valid <= 1'b0;
      else if(word_num == 3'd4 && rx_dvld || 
              word_num  < 3'd4 && rx_dvld && mac_rx_eop)
         flags_valid <= 1'b1;
   end
end : rx_parse_seq

altera_std_synchronizer #(
   .depth    (2)
) sync_flags (
   .clk      (clk                ),
   .reset_n  (~reset             ),
   .din      (flags_valid        ),
   .dout     (flags_valid_sync   )
);

//-----------------------------------------------------------------------------
// Rx FIFO Read state machine
//-----------------------------------------------------------------------------
always_ff @(posedge clk, posedge reset)
begin : rxp_fsm_seq
   if(reset)
      rxp_state <= RXP_RESET_ST;
   else
      rxp_state <= rxp_next;
end : rxp_fsm_seq

always_comb
begin : rxp_fsm_comb
   rxp_next = rxp_state;
   unique case (1'b1) //Reverse Case Statement
      rxp_state[RXP_RESET_BIT]:   //RXP_RESET_ST
         if(reset)
            rxp_next = RXP_RESET_ST;
         else
            rxp_next = RXP_IDLE_ST;
      
      rxp_state[RXP_IDLE_BIT]:   //RXP_IDLE_ST
         if(rxfifo_rddata.sop && !rxfifo_rdempty && flags_valid_sync && 
                                                   !flags_valid_sync_r1) begin
            if(drop_msg)
               rxp_next = RXP_DROP_ST;
            else if(rx_ncsi_msg_vld)
               rxp_next = RXP_NCM_ST;
            else 
               rxp_next = RXP_EPT_ST;
         end 

      rxp_state[RXP_NCM_BIT]:    //RXP_NCM_ST 
         if(rxfifo_rddata.eop && !rxfifo_rdempty)
               rxp_next = RXP_IDLE_ST;
               
      rxp_state[RXP_EPT_BIT]:    //RXP_EPT_ST 
         if(rxfifo_rddata.eop && !rxfifo_rdempty)
               rxp_next = RXP_IDLE_ST;
      
      rxp_state[RXP_DROP_BIT]:   //RXP_DROP_ST
         if(rxfifo_rddata.eop && !rxfifo_rdempty)
               rxp_next = RXP_IDLE_ST;
   endcase
end : rxp_fsm_comb


//-----------------------------------------------------------------------------
// Rx FIFO Read logic
//-----------------------------------------------------------------------------
always_ff @(posedge clk, posedge reset)
begin : rxp_rd_seq
   if(reset) begin
      flags_valid_sync_r1 <= 1'b0;
      rxfifo_rden         <= 1'b0;
      ncsi_rx_rec         <= '{default:0};
      rx_bcast_msg_sync   <= 1'b0;
      rx_mcast_msg_sync   <= 1'b0;
      src_mac_addr_sync   <= 48'h0;
   end else begin
      flags_valid_sync_r1 <= flags_valid_sync;
      
      if(rxp_state[RXP_NCM_BIT] && p2b_ncrx_rdy  ||
         rxp_state[RXP_EPT_BIT] && p2e_eptrx_rdy ||
         rxp_state[RXP_DROP_BIT])
         rxfifo_rden      <= 1'b1;
      else
         rxfifo_rden      <= 1'b0;
         
      ncsi_rx_rec         <= rxfifo_rddata; 
      if(flags_valid_sync) begin
         rx_bcast_msg_sync <= rx_bcast_msg;
         rx_mcast_msg_sync <= rx_mcast_msg;
         src_mac_addr_sync <= src_mac_addr;
      end
      
      p2b_ncrx_vld  = rxp_state[RXP_NCM_BIT] & rxfifo_rden & ~rxfifo_rdempty;
      p2e_eptrx_vld = rxp_state[RXP_EPT_BIT] & rxfifo_rden & ~rxfifo_rdempty;
   end
end : rxp_rd_seq


always_comb
begin : rxp_rd_comb
   rxfifo_rdreq   = rxfifo_rden & ~rxfifo_rdempty;

   p2b_ncrx_data  = ncsi_rx_rec.data;
   p2b_ncrx_sop   = ncsi_rx_rec.sop ;
   p2b_ncrx_eop   = ncsi_rx_rec.eop ;
   p2b_ncrx_err   = ncsi_rx_rec.err ;
   p2b_ncrx_mod   = ncsi_rx_rec.mod ;

   p2e_eptrx_data = ncsi_rx_rec.data;
   p2e_eptrx_sop  = ncsi_rx_rec.sop ;
   p2e_eptrx_eop  = ncsi_rx_rec.eop ;
   p2e_eptrx_err  = ncsi_rx_rec.err ;
   p2e_eptrx_mod  = ncsi_rx_rec.mod ;
   p2e_eptrx_sma  = src_mac_addr_sync ;
   p2e_eptrx_bcst = rx_bcast_msg_sync ;
   p2e_eptrx_mcst = rx_mcast_msg_sync ;
end : rxp_rd_comb


endmodule
