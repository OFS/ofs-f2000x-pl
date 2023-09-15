// Copyright (C) 2020 Intel Corporation.
// SPDX-License-Identifier: MIT

//
// Description
//-----------------------------------------------------------------------------
// NCSI RBT Tx traffic arbiter module
//-----------------------------------------------------------------------------

module ncsi_tx_arb #(
   parameter   DEVICE_FAMILY            = "Agilex", //FPGA Device Family
   parameter   CAP_NUM_CH               = 5'h1      //No. of channels supported
)(
   //input clock & reset
   input  logic                        clk                  ,
   input  logic                        reset                ,
   input  logic                        clk_ncsi             ,
   input  logic                        rst_ncsi             ,
   
   //TSE MAC Tx interface
   output logic [31:0]                 mac_tx_data          ,
   output logic                        mac_tx_sop           ,
   output logic                        mac_tx_eop           ,
   output logic                        mac_tx_err           ,
   output logic [1:0]                  mac_tx_mod           ,
   output logic                        mac_tx_vld           ,
   input  logic                        mac_tx_rdy           ,
   input  logic                        mac_tx_septy         ,
   
   input  logic                        rmii_tx_en           ,
   
   //NCSI Resp Buffer to Arbiter Response/AEN Tx AvST i/f
   input  logic [31:0]                 b2a_nrtx_data        ,
   input  logic                        b2a_nrtx_sop         ,
   input  logic                        b2a_nrtx_eop         ,
   input  logic [1:0]                  b2a_nrtx_mod         ,
   input  logic                        b2a_nrtx_err         ,
   input  logic                        b2a_nrtx_rna         ,
   input  logic                        b2a_nrtx_eb4sr       ,
   input  logic                        b2a_nrtx_vld         ,
   output logic                        b2a_nrtx_rdy         ,
   output logic                        b2a_nrtx_sent        ,
   
   //NCSI Ingress Passthrough to Arbiter Tx AvST i/f
   input  logic [31:0]                 i2a_ipttx_data       ,
   input  logic                        i2a_ipttx_sop        ,
   input  logic                        i2a_ipttx_eop        ,
   input  logic                        i2a_ipttx_err        ,
   input  logic [1:0]                  i2a_ipttx_mod        ,
   input  logic                        i2a_ipttx_vld        ,
   output logic                        i2a_ipttx_rdy        ,

   //Nios CSR i/f
   input  logic                        package_en           
);

enum {
   TXA_RESET_BIT = 0,
   TXA_IDLE_BIT  = 1,
   TXA_NRM_BIT   = 2,
   TXA_IPT_BIT   = 3,
   TXA_WAIT_BIT  = 4
} txa_state_bit;

enum logic [4:0] {
   TXA_RESET_ST  = 5'h1 << TXA_RESET_BIT,
   TXA_IDLE_ST   = 5'h1 << TXA_IDLE_BIT ,
   TXA_NRM_ST    = 5'h1 << TXA_NRM_BIT  ,
   TXA_IPT_ST    = 5'h1 << TXA_IPT_BIT  ,
   TXA_WAIT_ST   = 5'h1 << TXA_WAIT_BIT  
} txa_state, txa_next;

typedef struct packed {
    logic           sop;
    logic           eop;
    logic           err;
    logic   [1:0]   mod;
    logic   [31:0]  data;
} tx_avst_t;

logic [5:0]    txen_idle_cntr    ;
logic          ncsi_tx_idle      ;
logic          ncsi_tx_idle_sync ;
logic          ncsi_tx_idle_sync_r1;

logic          txfifo_wrreq      ;
logic          txfifo_wrfull     ;
logic [2:0]    txfifo_wrusedw    ;
tx_avst_t      txfifo_wrdata     ;
tx_avst_t      txfifo_rddata     ;
logic          txfifo_rdreq      ;
logic          txfifo_rdempty    ;

tx_avst_t      txfifo_rddata_r1  ;


//-----------------------------------------------------------------------------
// NCSI RBT Tx Idle Detection
//-----------------------------------------------------------------------------
always_ff @(posedge clk_ncsi, posedge rst_ncsi)
begin : txen_idle_seq
   if(rst_ncsi) begin
      txen_idle_cntr <= 6'd0;
      ncsi_tx_idle   <= 1'b0;
   end else begin
      if(rmii_tx_en)
         txen_idle_cntr <= 6'd0;
      else if(!ncsi_tx_idle)
         txen_idle_cntr <= txen_idle_cntr + 1'b1;
      
      ncsi_tx_idle <= (txen_idle_cntr >= 6'd56) ? 1'b1 : 1'b0;
   end
end : txen_idle_seq

//-----------------------------------------------------------------------------
// NCSI RBT Tx Idle Synchronizer
//-----------------------------------------------------------------------------
altera_std_synchronizer #(
   .depth    (2)
) sync_txidle (
   .clk      (clk               ),
   .reset_n  (~reset            ),
   .din      (ncsi_tx_idle      ),
   .dout     (ncsi_tx_idle_sync )
);

//-----------------------------------------------------------------------------
// Tx FIFO Arbitier state machine
//-----------------------------------------------------------------------------
always_ff @(posedge clk, posedge reset)
begin : txa_fsm_seq
   if(reset)
      txa_state <= TXA_RESET_ST;
   else
      txa_state <= txa_next;
end : txa_fsm_seq

always_comb
begin : txa_fsm_comb
   txa_next = txa_state;
   unique case (1'b1) //Reverse Case Statement
      txa_state[TXA_RESET_BIT]:   //TXA_RESET_ST
         if(reset)
            txa_next = TXA_RESET_ST;
         else
            txa_next = TXA_IDLE_ST;
      
      txa_state[TXA_IDLE_BIT]:   //TXA_IDLE_ST
         if(b2a_nrtx_vld && b2a_nrtx_sop)
            txa_next = TXA_NRM_ST;
         else if(i2a_ipttx_vld && i2a_ipttx_sop && package_en)
            txa_next = TXA_IPT_ST;

      txa_state[TXA_NRM_BIT]:    //TXA_NRM_ST 
         if(b2a_nrtx_eop && b2a_nrtx_vld && b2a_nrtx_rdy)
            if(b2a_nrtx_rna && !package_en)
               txa_next = TXA_WAIT_ST;
            else
               txa_next = TXA_IDLE_ST;
            
      txa_state[TXA_IPT_BIT]:    //TXA_IPT_ST 
         if(i2a_ipttx_eop && i2a_ipttx_vld && i2a_ipttx_rdy)
            txa_next = TXA_IDLE_ST;
            
      txa_state[TXA_WAIT_BIT]:    //TXA_WAIT_ST 
         if(ncsi_tx_idle_sync && !ncsi_tx_idle_sync_r1)
            txa_next = TXA_IDLE_ST;
   endcase
end : txa_fsm_comb


//-----------------------------------------------------------------------------
// Tx FIFO Write logic
//-----------------------------------------------------------------------------
always_ff @(posedge clk, posedge reset)
begin : txa_wr_seq
   if(reset) begin
      ncsi_tx_idle_sync_r1 <= 1'b0;
      txfifo_wrdata  <= '{default:0};
      txfifo_wrreq   <= 1'b0;
      b2a_nrtx_rdy   <= 1'b0;
      b2a_nrtx_sent  <= 1'b0;
      i2a_ipttx_rdy  <= 1'b0;
   end else begin
      ncsi_tx_idle_sync_r1 <= ncsi_tx_idle_sync;
      if(txa_state[TXA_NRM_BIT])
         txfifo_wrdata  <= {b2a_nrtx_sop, b2a_nrtx_eop, b2a_nrtx_err, b2a_nrtx_mod, b2a_nrtx_data};
      else if(txa_state[TXA_IPT_BIT])
         txfifo_wrdata  <= {i2a_ipttx_sop, i2a_ipttx_eop, i2a_ipttx_err, i2a_ipttx_mod, i2a_ipttx_data};
      
      if(txa_state[TXA_NRM_BIT] && b2a_nrtx_vld  && b2a_nrtx_rdy ||
         txa_state[TXA_IPT_BIT] && i2a_ipttx_vld && i2a_ipttx_rdy)
         txfifo_wrreq   <= 1'b1;
      else
         txfifo_wrreq   <= 1'b0;
         
      if(txa_state[TXA_NRM_BIT] && txfifo_wrusedw < 3'd4 && !txfifo_wrfull)
         b2a_nrtx_rdy   <= 1'b1;
      else 
         b2a_nrtx_rdy   <= 1'b0;
         
      if(txa_state[TXA_NRM_BIT] && b2a_nrtx_eop && b2a_nrtx_vld && 
                                b2a_nrtx_rdy && (!b2a_nrtx_rna || package_en) ||
         txa_state[TXA_WAIT_BIT] && ncsi_tx_idle_sync && !ncsi_tx_idle_sync_r1)
         b2a_nrtx_sent  <= 1'b1;
      else 
         b2a_nrtx_sent  <= 1'b0;
         
      if(txa_state[TXA_IPT_BIT] && txfifo_wrusedw < 3'd4 && !txfifo_wrfull)
         i2a_ipttx_rdy  <= 1'b1;
      else 
         i2a_ipttx_rdy  <= 1'b0;
   end
end : txa_wr_seq


//-----------------------------------------------------------------------------
// CDC FIFO - PMCI to NCSI clock domain
//-----------------------------------------------------------------------------
dcfifo  ncsi_tx_cdc_fifo (
   .aclr       (reset         ),
   .wrclk      (clk           ),
   .wrreq      (txfifo_wrreq  ),
   .wrfull     (txfifo_wrfull ),
   .wrempty    (              ),
   .data       (txfifo_wrdata ),
   .wrusedw    (txfifo_wrusedw),
   .rdclk      (clk_ncsi      ),
   .rdreq      (txfifo_rdreq  ),
   .rdempty    (txfifo_rdempty),
   .rdfull     (),
   .q          (txfifo_rddata ),
   .rdusedw    (),
   .eccstatus  ());
defparam
   ncsi_tx_cdc_fifo.enable_ecc  = "FALSE",
   ncsi_tx_cdc_fifo.intended_device_family  = DEVICE_FAMILY,
   ncsi_tx_cdc_fifo.lpm_hint  = "DISABLE_DCFIFO_EMBEDDED_TIMING_CONSTRAINT=TRUE",
   ncsi_tx_cdc_fifo.lpm_numwords  = 8,
   ncsi_tx_cdc_fifo.lpm_showahead  = "ON",
   ncsi_tx_cdc_fifo.lpm_type  = "dcfifo",
   ncsi_tx_cdc_fifo.lpm_width  = 37,
   ncsi_tx_cdc_fifo.lpm_widthu  = 3,
   ncsi_tx_cdc_fifo.overflow_checking  = "ON",
   ncsi_tx_cdc_fifo.rdsync_delaypipe  = 4,
   ncsi_tx_cdc_fifo.underflow_checking  = "ON",
   ncsi_tx_cdc_fifo.use_eab  = "ON",
   ncsi_tx_cdc_fifo.wrsync_delaypipe  = 4;


//-----------------------------------------------------------------------------
// TxFIFO Read Logic
//-----------------------------------------------------------------------------
always_ff @(posedge clk_ncsi, posedge rst_ncsi)
begin : txfifo_rd_seq
   if(rst_ncsi) begin
    txfifo_rdreq     <= 1'b0;
    txfifo_rddata_r1 <= '{default:0};
    mac_tx_vld       <= 1'b0;
   end else begin
      txfifo_rddata_r1  <= txfifo_rddata;
      
      mac_tx_vld     <= ~txfifo_rdempty & txfifo_rdreq;
      
      txfifo_rdreq   <= ~txfifo_rdempty & mac_tx_rdy & mac_tx_septy;
   end
end : txfifo_rd_seq

always_comb
begin : txfifo_rd_comb
   mac_tx_sop  = txfifo_rddata_r1.sop;
   mac_tx_eop  = txfifo_rddata_r1.eop;
   mac_tx_err  = txfifo_rddata_r1.err;
   mac_tx_mod  = txfifo_rddata_r1.mod;
   mac_tx_data = txfifo_rddata_r1.data;
end : txfifo_rd_comb


endmodule
