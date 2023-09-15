// Copyright (C) 2020 Intel Corporation.
// SPDX-License-Identifier: MIT

//
// Description
//-----------------------------------------------------------------------------
// NCSI egress passthrough module
//-----------------------------------------------------------------------------

module ncsi_ept #(
   parameter   DEVICE_FAMILY            = "Agilex", //FPGA Device Family
   parameter   SS_ADDR_WIDTH            = 21,
   parameter   NCSI_AFU_BADDR           = 24'h0,    //NCSI AFU/management base address
   parameter   CAP_NUM_CH               = 5'h1,     //No. of channels supported
   parameter   EPT_BUFR_DEPTH           = 2048,     //Egress Passthrough Buffer Depth
   parameter   EPT_MAX_PKT_LEN          = 1522,     //Max packet length of IPT packet
   parameter   MAX_MAC_NUM              = 1         //Max no. of MAC addr filters per channel
)(
   input  logic                        clk                  ,
   input  logic                        reset                ,
   input  logic                        pulse_1us            ,
   
   //AVMM Master (Egress Passthrough i/f to BNIC/OVS)
   output logic [SS_ADDR_WIDTH-1:0]    ept_avmm_m_addr      ,
   output logic                        ept_avmm_m_write     ,
   output logic                        ept_avmm_m_read      ,
   output logic [63:0]                 ept_avmm_m_wrdata    ,
   output logic [7:0]                  ept_avmm_m_byteen    ,
   input  logic [63:0]                 ept_avmm_m_rddata    ,
   input  logic                        ept_avmm_m_rddvld    ,
   input  logic                        ept_avmm_m_waitreq   ,
   
   //NCSI Parser to Egress Passthrough AvST i/f
   input  logic [31:0]                 p2e_eptrx_data       ,
   input  logic                        p2e_eptrx_sop        ,
   input  logic                        p2e_eptrx_eop        ,
   input  logic [5:0]                  p2e_eptrx_err        ,
   input  logic [1:0]                  p2e_eptrx_mod        ,
   input  logic [47:0]                 p2e_eptrx_sma        ,
   input  logic                        p2e_eptrx_bcst       ,
   input  logic                        p2e_eptrx_mcst       ,
   input  logic                        p2e_eptrx_vld        ,
   output logic                        p2e_eptrx_rdy        ,
   
   //NCSI Ingress Passthrough to Egress Passthrough Loopback
   input  logic [31:0]                 i2e_lpbk_data        ,
   input  logic                        i2e_lpbk_sop         ,
   input  logic                        i2e_lpbk_eop         ,
   input  logic [1:0]                  i2e_lpbk_mod         ,
   input  logic                        i2e_lpbk_vld         ,
   output logic                        i2e_lpbk_rdy         ,   
   
   //Nios CSR i/f
   input  logic                        ignr_fltr_cfg        ,
   input  logic                        ncsi_pt_lpbk_en      ,
   input  logic [CAP_NUM_CH-1:0]       ncsi_ptnw_tx_en      ,
   input  logic [47:0]                 mac_addr_fltr[MAX_MAC_NUM-1:0],
   input  logic [MAX_MAC_NUM-1:0]      mac_addr_fltr_en
);

localparam  RAM_DEPTH   = EPT_BUFR_DEPTH/4;
localparam  RAM_AWID    = $clog2(RAM_DEPTH);

localparam  PKT_MAX_BEAT = (EPT_MAX_PKT_LEN+3)/4-2;
localparam  PKT_CWID     = $clog2(PKT_MAX_BEAT+3);

localparam integer NUM_FCOMP = (MAX_MAC_NUM+7)/8;

typedef struct packed {
    logic           sop;
    logic           eop;
    logic   [1:0]   mod;
    logic   [31:0]  data;
} ept_pkt_t;

enum {
   EPT_RESET_BIT   = 0,
   EPT_IDLE_BIT    = 1,
   EPT_AFU_RDY_BIT = 2,
   EPT_SOP_BIT     = 3,
   EPT_DATA_BIT    = 4,
   EPT_EOP_BIT     = 5
} ept_state_bit;

enum logic [5:0] {
   EPT_RESET_ST    = 6'h1 << EPT_RESET_BIT  ,
   EPT_IDLE_ST     = 6'h1 << EPT_IDLE_BIT   ,
   EPT_AFU_RDY_ST  = 6'h1 << EPT_AFU_RDY_BIT,
   EPT_SOP_ST      = 6'h1 << EPT_SOP_BIT    ,
   EPT_DATA_ST     = 6'h1 << EPT_DATA_BIT   ,
   EPT_EOP_ST      = 6'h1 << EPT_EOP_BIT    
} ept_state, ept_next, ept_state_r1;

logic [RAM_AWID:0]            ept_bfr_a_addr    ;
ept_pkt_t                     ept_bfr_a_wrd     ;
logic                         ept_bfr_a_wren    ;
ept_pkt_t                     ept_bfr_a_rdd     ;
logic [RAM_AWID:0]            ept_bfr_b_addr    ;
ept_pkt_t                     ept_bfr_b_rdd     ;


logic                         ept_rx_dvld       ;
logic                         ept_rx_sop        ;
logic                         ept_rx_eop        ;
logic                         ept_bfr_full      ;
logic                         ept_rx_eop_r1     ;
logic                         ept_rx_wip        ;
logic [PKT_CWID:0]            rx_pkt_bcnt       ;
logic                         drop_ept_pkt      ;
logic [RAM_AWID:0]            prev_pkt_waddr    ;
logic                         ept_bfr_empty     ;
logic                         bufr_rd_vld1      ;
logic                         bufr_rd_vld2      ;
logic                         bufr_rd_vld3      ;
logic [31:0]                  ept_bfr_b_rdd_r1  ;
logic                         pkt_rd_done       ;
logic                         dly_busy_rechk    ;
logic [SS_ADDR_WIDTH-1:0]     afu_ncsi_mgmnt_addr;

integer                       mf1_i             ;
integer                       mf1_j             ;
integer                       mf2_i             ;
integer                       mf3_i             ;
logic [MAX_MAC_NUM-1:0][2:0]  mac_fltr_match1   ;
logic [NUM_FCOMP*8-1:0]       mac_fltr_match2   ;
logic [NUM_FCOMP-1:0]         mac_fltr_match3   ;

//------------------------------------------------------------------------------
// Function to convert mod to byte-en
//------------------------------------------------------------------------------
function automatic logic[7:0] mod2be (                                  
   input logic       qword,
   input logic [1:0] mod
);                                                                              
   if(mod == 2'd0)
      mod2be = qword ? 8'hFF : 8'hF0;
   else if(mod == 2'd1)
      mod2be = qword ? 8'hFE : 8'hE0;
   else if(mod == 2'd2)
      mod2be = qword ? 8'hFC : 8'hC0;
   else
      mod2be = qword ? 8'hF8 : 8'h80;
      
   return mod2be;                                                        
endfunction


//-----------------------------------------------------------------------------
// Egress Passthrough Packet MAC address parsing
//-----------------------------------------------------------------------------
always_ff @(posedge clk, posedge reset)
begin : ept_mac_prse_seq
   if(reset) begin
      mac_fltr_match1 <= '0;
      mac_fltr_match3 <= '0;
   end else begin
      for(mf1_i=0; mf1_i<MAX_MAC_NUM; mf1_i++) begin
         for(mf1_j=0; mf1_j<3; mf1_j++) begin
            if(p2e_eptrx_sma[mf1_j*16+:16] == mac_addr_fltr[mf1_i][mf1_j*16+:16] && 
                                                         mac_addr_fltr_en[mf1_i])
               mac_fltr_match1[mf1_i][mf1_j] <= 1'b1;
            else
               mac_fltr_match1[mf1_i][mf1_j] <= 1'b0;
         end
      end
      
      for(mf3_i=0; mf3_i<NUM_FCOMP; mf3_i++) begin
         mac_fltr_match3[mf3_i] <= (mac_fltr_match2[mf3_i*8+:8]) ? 1'b1 : 1'b0;
      end
   end
end : ept_mac_prse_seq

always_comb
begin : ept_mac_prse_comb
   for(mf2_i=0; mf2_i<MAX_MAC_NUM; mf2_i++) begin
      mac_fltr_match2[mf2_i] = (mac_fltr_match1[mf2_i] == 3'd7) ? 1'b1 : 1'b0;
   end
   mac_fltr_match2[NUM_FCOMP*8-1:MAX_MAC_NUM] = '0;
end : ept_mac_prse_comb

//-----------------------------------------------------------------------------
// Egress Passthrough Packet Buffer Write
//-----------------------------------------------------------------------------
always_comb
begin : ept_bwr_comb
   p2e_eptrx_rdy  = 1'b1;
   i2e_lpbk_rdy   = 1'b1;
   
   ept_rx_dvld = ~ncsi_pt_lpbk_en & p2e_eptrx_vld & p2e_eptrx_rdy | 
                  ncsi_pt_lpbk_en & i2e_lpbk_vld  & i2e_lpbk_rdy;
   
   ept_rx_sop  = ~ncsi_pt_lpbk_en & p2e_eptrx_sop | ncsi_pt_lpbk_en & i2e_lpbk_sop;
   
   ept_rx_eop  = ~ncsi_pt_lpbk_en & p2e_eptrx_eop | ncsi_pt_lpbk_en & i2e_lpbk_eop;
   
   if(ept_bfr_a_addr[RAM_AWID-1:0] == ept_bfr_b_addr[RAM_AWID-1:0] && 
      ept_bfr_a_addr[RAM_AWID]     != ept_bfr_b_addr[RAM_AWID])
      ept_bfr_full = 1'b1;
   else
      ept_bfr_full = 1'b0;
end : ept_bwr_comb

always_ff @(posedge clk, posedge reset)
begin : ept_bwr_seq
   if(reset) begin
      ept_rx_eop_r1     <= 1'b0;
      ept_rx_wip        <= 1'b0;
      rx_pkt_bcnt       <= '0;
      drop_ept_pkt      <= 1'b0;
      prev_pkt_waddr    <= '0;
      ept_bfr_a_wren    <= 1'b0;
      ept_bfr_a_addr    <= '0;
      ept_bfr_a_wrd     <= '{default:0};
   end else begin
      ept_rx_eop_r1 <= ept_rx_eop & ept_rx_dvld;
      
      if(ept_rx_eop_r1)
         ept_rx_wip  <= 1'b0;
      else if(ept_rx_sop && ept_rx_dvld && mac_fltr_match3)
         ept_rx_wip  <= 1'b1;
      
      if(!ept_rx_wip)
         rx_pkt_bcnt <= '0;
      else if(ept_rx_dvld)
         rx_pkt_bcnt <= rx_pkt_bcnt + 1'b1;
      
      //drop packet if Passthroug N/w Tx is disabled
      //drop packet if buffer full
      //drop packet if size is more than supported
      if(!ept_rx_wip)
         drop_ept_pkt  <= 1'b0;
      else if(!ncsi_ptnw_tx_en[0] && !ncsi_pt_lpbk_en ||
              ept_bfr_full && ept_rx_dvld ||
              rx_pkt_bcnt >  PKT_MAX_BEAT && ept_rx_dvld)
         drop_ept_pkt  <= 1'b1;
      
      if(!ept_rx_wip)
         prev_pkt_waddr <= ept_bfr_a_addr;
         
      if(!ept_bfr_full && !drop_ept_pkt && ept_rx_dvld)
         ept_bfr_a_wren <= 1'b1;
      else 
         ept_bfr_a_wren <= 1'b0;
         
      if(drop_ept_pkt)
         ept_bfr_a_addr <= prev_pkt_waddr;
      else if(ept_rx_wip && ept_bfr_a_wren)
         ept_bfr_a_addr <= ept_bfr_a_addr + 1'b1;
      
      if(ncsi_pt_lpbk_en) begin
         ept_bfr_a_wrd.sop  <= i2e_lpbk_sop;
         ept_bfr_a_wrd.eop  <= i2e_lpbk_eop;
         ept_bfr_a_wrd.mod  <= i2e_lpbk_mod;
         ept_bfr_a_wrd.data <= i2e_lpbk_data;
      end else begin
         ept_bfr_a_wrd.sop  <= p2e_eptrx_sop;
         ept_bfr_a_wrd.eop  <= p2e_eptrx_eop;
         ept_bfr_a_wrd.mod  <= p2e_eptrx_mod;
         ept_bfr_a_wrd.data <= p2e_eptrx_data;
      end
   end
end : ept_bwr_seq


//-----------------------------------------------------------------------------
// NCSI Egress Passthrough Buffer
// Port-A : EPT Rx side (from  NCSI Rx Parser) write
// Port-B : EPT Tx side (to IOFS/AFU) read
//-----------------------------------------------------------------------------
altera_syncram ept_buffer 
(
   .clock0           (clk              ),
   .address_a        (ept_bfr_a_addr[RAM_AWID-1:0]),
   .data_a           (ept_bfr_a_wrd    ),
   .wren_a           (ept_bfr_a_wren   ),
   .q_a              (ept_bfr_a_rdd    ),
   .address_b        (ept_bfr_b_addr[RAM_AWID-1:0]),
   .data_b           ({32{1'b1}}       ),
   .wren_b           (1'b0             ),
   .q_b              (ept_bfr_b_rdd    ),
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
   ept_buffer.address_aclr_b          = "NONE",
   ept_buffer.address_reg_b           = "CLOCK0",
   ept_buffer.clock_enable_input_a    = "BYPASS",
   ept_buffer.clock_enable_input_b    = "BYPASS",
   ept_buffer.clock_enable_output_b   = "BYPASS",
   ept_buffer.intended_device_family  = DEVICE_FAMILY,
   ept_buffer.lpm_type                = "altera_syncram",
   ept_buffer.numwords_a              = RAM_DEPTH,
   ept_buffer.numwords_b              = RAM_DEPTH,
   ept_buffer.operation_mode          = "DUAL_PORT",
   ept_buffer.outdata_aclr_b          = "NONE",
   ept_buffer.outdata_sclr_b          = "NONE",
   ept_buffer.outdata_reg_b           = "CLOCK0",
   ept_buffer.power_up_uninitialized  = "FALSE",
   ept_buffer.read_during_write_mode_mixed_ports  = "DONT_CARE",
   ept_buffer.widthad_a               = RAM_AWID,
   ept_buffer.widthad_b               = RAM_AWID,
   ept_buffer.width_a                 = 36,
   ept_buffer.width_b                 = 36,
   ept_buffer.width_byteena_a         = 1,
   ept_buffer.width_byteena_b         = 1;


//-----------------------------------------------------------------------------
// Egress Passthrough Tx FSM.
//-----------------------------------------------------------------------------
always_ff @(posedge clk, posedge reset)
begin : ept_fsm_seq
   if (reset) begin
      ept_state     <= EPT_RESET_ST;
      ept_state_r1  <= EPT_RESET_ST;
   end else begin
      ept_state     <= ept_next;
      ept_state_r1  <= ept_state;
   end
end : ept_fsm_seq

always_comb
begin : ept_fsm_comb
   ept_next = ept_state;
   unique case (1'b1) //Reverse Case Statement
      ept_state[EPT_RESET_BIT]:   //EPT_RESET_ST
         if (reset)
            ept_next = EPT_RESET_ST;
         else
            ept_next = EPT_IDLE_ST;
            
      ept_state[EPT_IDLE_BIT]:    //EPT_IDLE_ST   
         if(!ept_bfr_empty)
            ept_next = EPT_AFU_RDY_ST;
            
      ept_state[EPT_AFU_RDY_BIT]: //EPT_AFU_RDY_ST
         if(ept_avmm_m_rddvld && !ept_avmm_m_rddata[2])
            ept_next = EPT_SOP_ST;

      ept_state[EPT_SOP_BIT]:     //EPT_SOP_ST    
         if(ept_avmm_m_write && !ept_avmm_m_waitreq)
            ept_next = EPT_DATA_ST;

      ept_state[EPT_DATA_BIT]:    //EPT_DATA_ST  
         if(pkt_rd_done && ept_avmm_m_write && !ept_avmm_m_waitreq)
            ept_next = EPT_EOP_ST;

      ept_state[EPT_EOP_BIT]:     //EPT_EOP_ST    
         if(ept_avmm_m_write && !ept_avmm_m_waitreq) begin
            ept_next = EPT_IDLE_ST;
         end 
   endcase
end : ept_fsm_comb


//-----------------------------------------------------------------------------
// Egress Buffer Read Logic
//-----------------------------------------------------------------------------
always_ff @(posedge clk, posedge reset)
begin : ept_bfr_rd
   if (reset) begin
      ept_bfr_empty     <= 1'b0;
      bufr_rd_vld1      <= 1'b0;
      bufr_rd_vld2      <= 1'b0;
      bufr_rd_vld3      <= 1'b0;
      ept_bfr_b_addr    <= '0;
      ept_bfr_b_rdd_r1  <= 32'd0;
      pkt_rd_done       <= 1'b0;
   end else begin
      if(prev_pkt_waddr[RAM_AWID-1:0] == ept_bfr_b_addr[RAM_AWID-1:0] && 
         prev_pkt_waddr[RAM_AWID]     == ept_bfr_b_addr[RAM_AWID])
         ept_bfr_empty <= 1'b1;
      else
         ept_bfr_empty <= 1'b0;
      
      if(!ept_state[EPT_DATA_BIT])
         bufr_rd_vld1    <= 1'b0;
      else if(!ept_avmm_m_write && !bufr_rd_vld1 && !bufr_rd_vld2 && !bufr_rd_vld3)
         bufr_rd_vld1    <= 1'b1;
      else
         bufr_rd_vld1    <= 1'b0;
      
      bufr_rd_vld2       <= bufr_rd_vld1;
      bufr_rd_vld3       <= bufr_rd_vld2;
      ept_bfr_b_rdd_r1   <= ept_bfr_b_rdd;
         
      if(!ept_state[EPT_DATA_BIT])
         pkt_rd_done    <= 1'b0;
      else if(ept_bfr_b_rdd.eop && (!ept_avmm_m_write || bufr_rd_vld3))
         pkt_rd_done    <= 1'b1;

      if(ept_state[EPT_DATA_BIT] && !ept_avmm_m_write && 
                                 !bufr_rd_vld2 && !bufr_rd_vld3 && !pkt_rd_done)
         ept_bfr_b_addr   <= ept_bfr_b_addr + 1'b1;
   end
end : ept_bfr_rd


//-----------------------------------------------------------------------------
// Egress AVMM Master generation
//-----------------------------------------------------------------------------
always_ff @(posedge clk, posedge reset)
begin : ept_avmm_mstr
   if (reset) begin
      dly_busy_rechk      <= 1'b0;
      ept_avmm_m_read     <= 1'b0;
      ept_avmm_m_write    <= 1'b0;
      ept_avmm_m_addr     <= {SS_ADDR_WIDTH{1'b0}};
      ept_avmm_m_wrdata   <= 64'd0;
      ept_avmm_m_byteen   <= 8'd0;
   end else begin
      if(ept_state[EPT_AFU_RDY_BIT] && ept_avmm_m_rddvld && ept_avmm_m_rddata[2])
         dly_busy_rechk       <= 1'b1;
      else if(pulse_1us)
         dly_busy_rechk       <= 1'b0;
      
      if(ept_state[EPT_AFU_RDY_BIT] && !ept_state_r1[EPT_AFU_RDY_BIT] ||
         ept_state[EPT_AFU_RDY_BIT] && dly_busy_rechk && pulse_1us)
         ept_avmm_m_read     <= 1'b1;
      else if(!ept_avmm_m_waitreq)
         ept_avmm_m_read     <= 1'b0;
      
      if(ept_state[EPT_SOP_BIT] && !ept_state_r1[EPT_SOP_BIT] ||
         ept_state[EPT_DATA_BIT] && bufr_rd_vld3 || 
         ept_state[EPT_EOP_BIT] && !ept_state_r1[EPT_EOP_BIT])
         ept_avmm_m_write    <= 1'b1;
      else if(!ept_avmm_m_waitreq)
         ept_avmm_m_write    <= 1'b0;
         
      if(ept_state[EPT_DATA_BIT])
         ept_avmm_m_addr  <= {afu_ncsi_mgmnt_addr[SS_ADDR_WIDTH-1:4], 4'd8};
      else 
         ept_avmm_m_addr  <= {afu_ncsi_mgmnt_addr[SS_ADDR_WIDTH-1:4], 4'd0};
         
      if(ept_state[EPT_DATA_BIT] && bufr_rd_vld3)
         ept_avmm_m_wrdata <= {ept_bfr_b_rdd_r1, ept_bfr_b_rdd.data};
      else if(!ept_state[EPT_DATA_BIT]) 
         ept_avmm_m_wrdata <= {62'd0, 
                                   ept_state[EPT_EOP_BIT], 
                                   ept_state[EPT_SOP_BIT]};
      
      //Byte-enables is 0xFF for all Data transactions except for last
      if(!ept_state[EPT_DATA_BIT])
         ept_avmm_m_byteen <= 8'hFF;
      else if(ept_bfr_b_rdd.eop && (bufr_rd_vld2 || bufr_rd_vld3 && !pkt_rd_done))
         ept_avmm_m_byteen <= mod2be(~pkt_rd_done, ept_bfr_b_rdd.mod);
   end
end : ept_avmm_mstr

assign afu_ncsi_mgmnt_addr = NCSI_AFU_BADDR;


endmodule
