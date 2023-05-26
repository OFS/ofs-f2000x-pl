// Copyright (C) 2020 Intel Corporation.
// SPDX-License-Identifier: MIT

//
// Description
//-----------------------------------------------------------------------------
// NCSI PMCI Nios FW accessible CSR module
//-----------------------------------------------------------------------------

module ncsi_csr_pnios #(
   //NCSI Capability Parameters
   parameter   CAP_NUM_CH               = 5'h1,     //No. of channels supported
   parameter   CAP_NUM_UNIMAC           = 4'h1,     //No. of Unicast MAC addr filters supported
   parameter   CAP_NUM_MULMAC           = 4'h0,     //No. of Multicast MAC addr filters supported
   parameter   CAP_NUM_MIXMAC           = 4'h0,     //No. of Mixed MAC addr filters supported
   parameter   CAP_NUM_VLAN             = 4'h1,     //No. of VLAN tag filters supported
   parameter   CAP_VLAN_MODE            = 3'h7,     //VLAN tag filtering mode supported
   parameter   CAP_ALL_MCAST            = 1'b0,     //Is all multicast address supported?
   parameter   CAP_BCAST_FILTERS        = 32'h1,    //Broadcast Packet Filter Capabilities
   parameter   CAP_MCAST_FILTERS        = 32'h0,    //Multicast Packet Filter Capabilities
   
   //NCSI Channel to HSSI Channel Map 
   parameter   NCSI_2_HSSI_CH_MAP_0     = 64'h0,    //ch#0  to ch#7 
   parameter   NCSI_2_HSSI_CH_MAP_1     = 64'h0,    //ch#8  to ch#15
   parameter   NCSI_2_HSSI_CH_MAP_2     = 64'h0,    //ch#16 to ch#23
   parameter   NCSI_2_HSSI_CH_MAP_3     = 64'h0,    //ch#24 to ch#30
   
   //NCSI Buffer Depth Parameters 
   parameter   IPT_BUFR_DEPTH           = 8192,     //Ingress Passthrough Buffer Depth
   parameter   EPT_BUFR_DEPTH           = 2048,     //Egress Passthrough Buffer Depth
   
   parameter   MAX_FC_REQ               = 16,       //Max no. of Filter Configuration request entries
   parameter   MAX_MAC_NUM              = 1         //Max no. of MAC addr filters per channel
)(
   input  logic                        clk                  ,
   input  logic                        reset                ,
   input  logic                        pulse_1ms            ,

   //AVMM slave (connected to PMCI-Nios)
   input  logic [10:0]                 nios_csr_addr        ,
   input  logic                        nios_csr_write       ,
   input  logic                        nios_csr_read        ,
   input  logic [31:0]                 nios_csr_wrdata      ,
 //input  logic [3:0]                  nios_csr_byteen      ,
   output logic [31:0]                 nios_csr_rddata      ,
   output logic                        nios_csr_rddvld      ,
   input  logic                        nios_csr_waitreq     ,
   
   //NCSI Mailbox
   output logic [31:0]                 ncsi_fc_doorbell_c   ,
   input  logic [31:0]                 ncsi_fc_doorbell_s   ,
   output logic                        ncsi_fcdb_cfglost_clr,
   output logic [63:0]                 ncsi_fc_ctrl_reg[MAX_FC_REQ - 1:0],
   input  logic [63:0]                 ncsi_fc_sts_reg[MAX_FC_REQ - 1:0],
   output logic [MAX_FC_REQ - 1:0]     ncsi_fc_sts_clr_pls  ,
   
   //CSR - other module i/f
   input  logic                        rbt_clk_prsnt        ,
   
   input  logic                        ncsi_rx_cmd_pulse    ,
   input  logic [11:0]                 ncsi_rx_cmd_size     ,
   input  logic [15:0]                 ncsi_rx_cmd_err      ,
   output logic                        ncsi_rx_cmd_busy     ,
   
   output logic                        ncsi_tx_resp_avail   ,
   output logic                        ncsi_tx_resp_naen    ,
   output logic [11:0]                 ncsi_tx_resp_size    ,
   output logic                        ncsi_tx_eb4sr        ,
   input  logic                        ncsi_tx_resp_sent    ,
   
   output logic                        ncsi_intr            ,
   
   output logic                        package_en           ,
   output logic                        ignr_fltr_cfg        ,
   output logic [2:0]                  package_id           ,
   output logic                        eptb_nios_reset      ,
   output logic                        iptb_nios_reset      ,
   
   output logic [CAP_NUM_CH-1:0]       ncsi_ch_en           ,
   output logic [CAP_NUM_CH-1:0]       ncsi_ptnw_tx_en      ,
   output logic [CAP_NUM_CH-1:0]       ncsi_ch_init_st      ,
   
   output logic [47:0]                 mac_addr_fltr[MAX_MAC_NUM-1:0],
   output logic [MAX_MAC_NUM-1:0]      mac_addr_fltr_en
);

localparam T5_INTR_TIMER     = 6'd40;    //T5 interrupt generation timer ~40ms
localparam T6_INTR_TIMER     = 11'd1900; //T6 interrupt generation timer ~1.9sec


logic          vld_csr_wr        ;
logic          daemon_idle       ;
logic          daemon_done       ;
logic          daemon_done_r1    ;
logic          daemon_up         ;
logic          daemon_up_r1      ;
logic          ignr_fltr_cfg_pls ;
logic          cmd_rx_intr_sts   ;
logic          t5_intr_sts       ;
logic          t6_intr_sts       ;
logic          hb_intr_sts       ;
logic [3:0]    ncsi_intr_en      ;
logic [31:0]   ncsi_capab_reg_0  ;
logic [31:0]   ncsi_capab_reg_1  ;
logic [31:0]   ncsi_capab_reg_2  ;
logic [31:0]   ncsi_rx_cmd_sts   ;
logic [31:0]   ncsi_tx_resp_ctrl ;
logic [31:0]   ncsi_gen_ctrl     ;
logic [31:0]   ncsi_ch_en_reg    ;
logic [31:0]   ptnw_tx_en_reg    ;
logic [31:0]   ch_init_st_reg    ;
logic [31:0]   ncsi_intr_reg     ;
logic [31:0]   nios_rddata_0     ;
integer        mac_n             ;
integer        fc_ctrl           ;
integer        fc_sts            ;
integer        i                 ;
logic [31:0]   ncsi_fc_ctrl_reg_i[256];
logic [31:0]   ncsi_fc_sts_reg_i[256];

logic          t5_timer_en       ;
logic [5:0]    t5_timer          ;
logic          t5_timer_expr     ;
logic          t6_timer_en       ;
logic [10:0]   t6_timer          ;
logic          t6_timer_expr     ;


//-----------------------------------------------------------------------------
// Nios Writeable Registers
//-----------------------------------------------------------------------------
always_comb
begin : nios_csr_wr_comb
   vld_csr_wr  = nios_csr_write & ~nios_csr_waitreq;
   daemon_idle = (ncsi_fc_doorbell_s[31:28] == 4'd0) ? 1'b1 : 1'b0;
   daemon_done = (ncsi_fc_doorbell_s[31:28] == 4'd3) ? 1'b1 : 1'b0;
   daemon_up   = ncsi_fc_doorbell_s[23]; //Host booted + NCSI daemon up & running

   ncsi_rx_cmd_busy = cmd_rx_intr_sts;
   
   //>>>>>>> offset-0x104 <<<<<<<
   if(nios_csr_addr == 11'h41 && vld_csr_wr && nios_csr_wrdata[22])
      ncsi_fcdb_cfglost_clr = 1'b1;
   else
      ncsi_fcdb_cfglost_clr = 1'b0;
end : nios_csr_wr_comb

always_ff @(posedge clk, posedge reset)
begin : nios_csr_wr_seq
   if(reset) begin
      daemon_done_r1       <= 1'b0;
      cmd_rx_intr_sts      <= 1'b0;
      ncsi_tx_resp_avail   <= 1'b0;
      ncsi_tx_resp_naen    <= 1'b0;
      ncsi_tx_resp_size    <= 12'h0;
      ncsi_tx_eb4sr        <= 1'b0;
      package_en           <= 1'b0;
      ignr_fltr_cfg        <= 1'b0;
      ignr_fltr_cfg_pls    <= 1'b0;
      package_id           <= 3'h0;
      eptb_nios_reset      <= 1'b0;
      iptb_nios_reset      <= 1'b0;
      ncsi_ch_en           <= '0;
      ncsi_ptnw_tx_en      <= '0;
      ncsi_ch_init_st      <= '0;
      t5_intr_sts          <= 1'b0;
      t6_intr_sts          <= 1'b0;
      hb_intr_sts          <= 1'b0;
      daemon_up_r1         <= 1'b0;
      ncsi_intr_en         <= 4'd0;
      ncsi_fc_doorbell_c   <= 32'd0;
      mac_addr_fltr        <= '{default:48'd0};
      mac_addr_fltr_en     <= '0;
      ncsi_fc_ctrl_reg     <= '{default:64'd0};
      ncsi_fc_sts_clr_pls  <= '0;
   end else begin
      daemon_done_r1 <= daemon_done;
      daemon_up_r1   <= daemon_up;
      
      //>>>>>>> Offset-0xA0 <<<<<<<
      if (nios_csr_addr == 11'h28 && vld_csr_wr) begin
         ncsi_tx_resp_avail <= nios_csr_wrdata[0];
         ncsi_tx_resp_naen  <= nios_csr_wrdata[1];
         ncsi_tx_resp_size  <= nios_csr_wrdata[15:4];
         ncsi_tx_eb4sr      <= nios_csr_wrdata[16];
      end else if (ncsi_tx_resp_sent) //RTL selft clear
         ncsi_tx_resp_avail <= 1'b0;
      
      //>>>>>>> Offset-0xC0 <<<<<<<
      if (nios_csr_addr == 11'h30 && vld_csr_wr) begin
         package_en      <= nios_csr_wrdata[0]    ;
         ignr_fltr_cfg   <= nios_csr_wrdata[1]    ;
         package_id      <= nios_csr_wrdata[10:8] ;
         eptb_nios_reset <= nios_csr_wrdata[30]   ;
         iptb_nios_reset <= nios_csr_wrdata[31]   ;
      end else if(!daemon_done_r1 && daemon_done)
         ignr_fltr_cfg   <= 1'b0;
      
      if (nios_csr_addr == 11'h30 && vld_csr_wr && nios_csr_wrdata[1])
         ignr_fltr_cfg_pls   <= 1'b1;
      else
         ignr_fltr_cfg_pls   <= 1'b0;
      
      //>>>>>>> Offset-0xC4 <<<<<<<
      if (nios_csr_addr == 11'h31 && vld_csr_wr)
         ncsi_ch_en      <= nios_csr_wrdata[CAP_NUM_CH-1:0];
      
      //>>>>>>> Offset-0xC8 <<<<<<<
      if (nios_csr_addr == 11'h32 && vld_csr_wr)
         ncsi_ptnw_tx_en  <= nios_csr_wrdata[CAP_NUM_CH-1:0];
      
      //>>>>>>> Offset-0xCC <<<<<<<
      if (nios_csr_addr == 11'h33 && vld_csr_wr)
         ncsi_ch_init_st  <= nios_csr_wrdata[CAP_NUM_CH-1:0];
      
      //>>>>>>> Offset-0xF0 bit[0] <<<<<<<
      //Drop all error packets except command buffer overflow error(err[0]) 
      if(ncsi_rx_cmd_pulse && ncsi_rx_cmd_err[5:1] == 4'd0)
         cmd_rx_intr_sts   <= 1'b1;
      else if (nios_csr_addr == 11'h3C && vld_csr_wr)
         cmd_rx_intr_sts   <= cmd_rx_intr_sts & ~nios_csr_wrdata[0]; //W1C

      //>>>>>>> Offset-0xF0 bit[1] <<<<<<<
      if(t5_timer_expr)
         t5_intr_sts <= 1'b1;
      else if (nios_csr_addr == 11'h3C && vld_csr_wr)
         t5_intr_sts <= t5_intr_sts & ~nios_csr_wrdata[1]; //W1C
         
      //>>>>>>> Offset-0xF0 bit[2] <<<<<<<
      if(t6_timer_expr)
         t6_intr_sts <= 1'b1;
      else if (nios_csr_addr == 11'h3C && vld_csr_wr)
         t6_intr_sts <= t6_intr_sts & ~nios_csr_wrdata[2]; //W1C
         
      //>>>>>>> Offset-0xF0 bit[3] <<<<<<<
      if(!daemon_up_r1 && daemon_up)
         hb_intr_sts <= 1'b1;
      else if (nios_csr_addr == 11'h3C && vld_csr_wr)
         hb_intr_sts <= hb_intr_sts & ~nios_csr_wrdata[3]; //W1C
      
      //>>>>>>> Offset-0xF0 bits[18:16] <<<<<<<
      if (nios_csr_addr == 11'h3C && vld_csr_wr)
         ncsi_intr_en  <= nios_csr_wrdata[24+:4];
      
      //>>>>>>> offset-0x100 <<<<<<<
      // Filter configuration doorbell register
      if (nios_csr_addr == 11'h40 && vld_csr_wr) begin
         if(!daemon_idle && (!daemon_done || !daemon_done_r1))
            ncsi_fc_doorbell_c[30] <= 1'b1;                //req_fail (error)
         else
            ncsi_fc_doorbell_c <= {nios_csr_wrdata[31],    //req_bit
                                   1'b0,                   //req_fail (no error)
                                   nios_csr_wrdata[29],    //init_state_enter
                                   1'b0,                   //reserved
                                   nios_csr_wrdata[27:23], //req_id + clear_history
                                   15'd0,                  //reserved
                                   nios_csr_wrdata[7:0]};  //num_req
      end
      
      if (daemon_done && !daemon_done_r1 || ignr_fltr_cfg_pls)
         ncsi_fc_doorbell_c[31] <= 1'b0; //req_bit(RTL selft clear)
      
      //>>>>>>> offset-0x200~0x2FF <<<<<<<
      for(mac_n=0; mac_n<MAX_MAC_NUM; mac_n++) begin
         if (vld_csr_wr && nios_csr_addr[10:6] == 5'h2 && 
             nios_csr_addr[5:1]  == mac_n && !nios_csr_addr[0])
            mac_addr_fltr[mac_n][31:0]  <= nios_csr_wrdata;
         if (vld_csr_wr && nios_csr_addr[10:6] == 5'h2 && 
             nios_csr_addr[5:1]  == mac_n && nios_csr_addr[0]) begin
            mac_addr_fltr[mac_n][47:32]  <= nios_csr_wrdata[15:0];
            mac_addr_fltr_en[mac_n]      <= nios_csr_wrdata[31];
         end
      end
      
      //>>>>>>> offset-0x400~0x7FF <<<<<<<
      for(fc_ctrl=0; fc_ctrl<MAX_FC_REQ; fc_ctrl++) begin
         if (vld_csr_wr && nios_csr_addr[10:8] == 3'h1 && 
             nios_csr_addr[7:1]  == fc_ctrl && !nios_csr_addr[0])
            ncsi_fc_ctrl_reg[fc_ctrl][31:0]  <= nios_csr_wrdata;
         if (vld_csr_wr && nios_csr_addr[10:8] == 3'h1 && 
             nios_csr_addr[7:1]  == fc_ctrl && nios_csr_addr[0])
            ncsi_fc_ctrl_reg[fc_ctrl][63:32] <= nios_csr_wrdata;
      end
      
      //>>>>>>> offset-0x800~0x9FF <<<<<<<
      for(fc_sts=0; fc_sts<MAX_FC_REQ; fc_sts++) begin
         if (vld_csr_wr && nios_csr_addr[10:8] == 3'h2 && 
                           nios_csr_addr[7:0]  == fc_sts && nios_csr_wrdata[31])
            ncsi_fc_sts_clr_pls[fc_sts]  <= 1'b1;
         else
            ncsi_fc_sts_clr_pls[fc_sts]  <= 1'b0;
      end
   end
end : nios_csr_wr_seq


//-----------------------------------------------------------------------------
// Nios Readable Registers
//-----------------------------------------------------------------------------
always_comb
begin : nios_csr_rd_comb
   ncsi_capab_reg_0[4:0]   = CAP_NUM_CH;
   ncsi_capab_reg_0[7:5]   = '0;
   ncsi_capab_reg_0[11:8]  = CAP_NUM_UNIMAC;
   ncsi_capab_reg_0[15:12] = CAP_NUM_MULMAC;
   ncsi_capab_reg_0[19:16] = CAP_NUM_MIXMAC;
   ncsi_capab_reg_0[23:20] = CAP_NUM_VLAN;
   ncsi_capab_reg_0[26:24] = CAP_VLAN_MODE;
   ncsi_capab_reg_0[30:27] = '0;
   ncsi_capab_reg_0[31]    = CAP_ALL_MCAST;
   
   ncsi_capab_reg_1[15:0]  = CAP_BCAST_FILTERS[15:0];
   ncsi_capab_reg_1[31:16] = CAP_MCAST_FILTERS[15:0];
   
   ncsi_capab_reg_2[15:0]  = IPT_BUFR_DEPTH;
   ncsi_capab_reg_2[23:16] = '0;
   ncsi_capab_reg_2[31:24] = MAX_FC_REQ;
   
   ncsi_rx_cmd_sts[0]      = cmd_rx_intr_sts;
   ncsi_rx_cmd_sts[3:1]    = '0;
   ncsi_rx_cmd_sts[15:4]   = ncsi_rx_cmd_size;
   ncsi_rx_cmd_sts[31:16]  = ncsi_rx_cmd_err;

   ncsi_tx_resp_ctrl[0]    = ncsi_tx_resp_avail;
   ncsi_tx_resp_ctrl[1]    = ncsi_tx_resp_naen;
   ncsi_tx_resp_ctrl[3:2]  = '0;
   ncsi_tx_resp_ctrl[15:4] = ncsi_tx_resp_size;
   ncsi_tx_resp_ctrl[16]   = ncsi_tx_eb4sr;
   ncsi_tx_resp_ctrl[31:17] = '0;
   
   ncsi_gen_ctrl[0]        = package_en;
   ncsi_gen_ctrl[1]        = ignr_fltr_cfg;
   ncsi_gen_ctrl[7:2]      = '0;
   ncsi_gen_ctrl[10:8]     = package_id;
   ncsi_gen_ctrl[29:11]    = '0;
   ncsi_gen_ctrl[30]       = eptb_nios_reset;
   ncsi_gen_ctrl[31]       = iptb_nios_reset;
   
   ncsi_ch_en_reg[CAP_NUM_CH-1:0]   = ncsi_ch_en;
   ncsi_ch_en_reg[31:CAP_NUM_CH]    = '0;
   
   ptnw_tx_en_reg[CAP_NUM_CH-1:0]   = ncsi_ptnw_tx_en;
   ptnw_tx_en_reg[31:CAP_NUM_CH]    = '0;
   
   ch_init_st_reg[CAP_NUM_CH-1:0]   = ncsi_ch_init_st;
   ch_init_st_reg[31:CAP_NUM_CH]    = '0;
   
   ncsi_intr_reg[0]        = cmd_rx_intr_sts;
   ncsi_intr_reg[1]        = t5_intr_sts;
   ncsi_intr_reg[2]        = t6_intr_sts;
   ncsi_intr_reg[3]        = hb_intr_sts;
   ncsi_intr_reg[4]        = rbt_clk_prsnt;
   ncsi_intr_reg[17:5]     = '0;
   ncsi_intr_reg[18]       = t6_timer_en; //start bit for T6
   ncsi_intr_reg[23:19]    = '0;
   ncsi_intr_reg[27:24]    = ncsi_intr_en;
   ncsi_intr_reg[31:28]    = '0;
   
   case (nios_csr_addr[7:0])
      8'h0  /*000*/ : nios_rddata_0 = ncsi_capab_reg_0;
      8'h1  /*004*/ : nios_rddata_0 = ncsi_capab_reg_1;
      8'h2  /*008*/ : nios_rddata_0 = ncsi_capab_reg_2;
      
      8'h10 /*040*/ : nios_rddata_0 = NCSI_2_HSSI_CH_MAP_0[31:0];
      8'h11 /*044*/ : nios_rddata_0 = NCSI_2_HSSI_CH_MAP_0[63:32];
      8'h12 /*048*/ : nios_rddata_0 = NCSI_2_HSSI_CH_MAP_1[31:0];
      8'h13 /*04C*/ : nios_rddata_0 = NCSI_2_HSSI_CH_MAP_1[63:32];
      8'h14 /*050*/ : nios_rddata_0 = NCSI_2_HSSI_CH_MAP_2[31:0];
      8'h15 /*054*/ : nios_rddata_0 = NCSI_2_HSSI_CH_MAP_2[63:32];
      8'h16 /*058*/ : nios_rddata_0 = NCSI_2_HSSI_CH_MAP_3[31:0];
      8'h17 /*05C*/ : nios_rddata_0 = NCSI_2_HSSI_CH_MAP_3[63:32];
      
      8'h20 /*080*/ : nios_rddata_0 = ncsi_rx_cmd_sts;
      
      8'h28 /*0A0*/ : nios_rddata_0 = ncsi_tx_resp_ctrl;

      8'h30 /*0C0*/ : nios_rddata_0 = ncsi_gen_ctrl;
      8'h31 /*0C4*/ : nios_rddata_0 = ncsi_ch_en_reg;
      8'h32 /*0C8*/ : nios_rddata_0 = ptnw_tx_en_reg;
      8'h33 /*0CC*/ : nios_rddata_0 = ch_init_st_reg;
      
      8'h3C /*0F0*/ : nios_rddata_0 = ncsi_intr_reg;
      
      8'h40 /*100*/ : nios_rddata_0 = ncsi_fc_doorbell_c;
      8'h41 /*104*/ : nios_rddata_0 = ncsi_fc_doorbell_s;
      default : nios_rddata_0 = 32'hDEADBEEF;
   endcase
   
   for(i=0; i<128; i++) begin
      if(i<MAX_FC_REQ) begin
         ncsi_fc_ctrl_reg_i[2*i+0] = ncsi_fc_ctrl_reg[i][31:0];
         ncsi_fc_ctrl_reg_i[2*i+1] = ncsi_fc_ctrl_reg[i][63:32];
         ncsi_fc_sts_reg_i[i]      = {ncsi_fc_sts_reg[i][63:56], ncsi_fc_sts_reg[i][23:0]};
         ncsi_fc_sts_reg_i[MAX_FC_REQ+i] = 32'd0;
      end else begin
         ncsi_fc_ctrl_reg_i[2*i+0] = 32'd0;
         ncsi_fc_ctrl_reg_i[2*i+1] = 32'd0;
         ncsi_fc_sts_reg_i[i]      = 32'd0;
         ncsi_fc_sts_reg_i[MAX_FC_REQ+i] = 32'd0;
      end
   end
   
end : nios_csr_rd_comb

always_ff @(posedge clk, posedge reset)
begin : nios_csr_rd_seq
   if(reset) begin
      nios_csr_rddvld    <= 1'b0;
      nios_csr_rddata    <= 32'd0;
   end else if (!nios_csr_addr[10] && nios_csr_read && !nios_csr_waitreq) begin
      nios_csr_rddvld    <= 1'b1;
      
      case (nios_csr_addr[9:8])
         2'h0    : nios_csr_rddata <= nios_rddata_0;
         2'h1    : nios_csr_rddata <= ncsi_fc_ctrl_reg_i[nios_csr_addr[7:0]];
         2'h2    : nios_csr_rddata <= ncsi_fc_sts_reg_i[nios_csr_addr[7:0]];
         default : nios_csr_rddata <= 32'hDEADBEEF;
      endcase 
   end else begin
      nios_csr_rddvld <= 1'b0;
   end
end : nios_csr_rd_seq


//-----------------------------------------------------------------------------
// Nios Interrupt Generation
//-----------------------------------------------------------------------------
always_ff @(posedge clk, posedge reset)
begin : nios_intr_seq
   if(reset) begin
      t5_timer_en    <= 1'b0;
      t5_timer       <= 6'd0;
      t5_timer_expr  <= 1'b0;
      t6_timer_en    <= 1'b0;
      t6_timer       <= 11'd0;
      t6_timer_expr  <= 1'b0;
   end else begin
      //T5 timer (50ms-delta)
      if(t5_timer_expr || nios_csr_addr == 11'h3C && vld_csr_wr && nios_csr_wrdata[9])
         t5_timer_en <= 1'b0;
      else if(ncsi_rx_cmd_pulse && ncsi_rx_cmd_err[5:1] == 4'd0)
         t5_timer_en <= 1'b1;
      
      if(!t5_timer_en)
         t5_timer <= 6'd0;
      else if(t5_timer_en && pulse_1ms)
         t5_timer <= t5_timer + 1'b1;
      
      t5_timer_expr <= (t5_timer == T5_INTR_TIMER && pulse_1ms) ? 1'b1 : 1'b0;
      
      //T6 timer (2sec-delta)
      if(t6_timer_expr || nios_csr_addr == 11'h3C && vld_csr_wr && nios_csr_wrdata[10])
         t6_timer_en <= 1'b0;
      else if(nios_csr_addr == 11'h3C && vld_csr_wr && nios_csr_wrdata[18])
         t6_timer_en <= 1'b1;
      
      if(!t6_timer_en)
         t6_timer <= 11'd0;
      else if(t6_timer_en && pulse_1ms)
         t6_timer <= t6_timer + 1'b1;
      
      t6_timer_expr <= (t6_timer == T6_INTR_TIMER && pulse_1ms) ? 1'b1 : 1'b0;
   end
end : nios_intr_seq

always_comb
begin : nios_intr_comb
   ncsi_intr    = cmd_rx_intr_sts & ncsi_intr_en[0] |
                  t5_intr_sts     & ncsi_intr_en[1] |
                  t6_intr_sts     & ncsi_intr_en[2] |
                  hb_intr_sts     & ncsi_intr_en[3];
end : nios_intr_comb


endmodule