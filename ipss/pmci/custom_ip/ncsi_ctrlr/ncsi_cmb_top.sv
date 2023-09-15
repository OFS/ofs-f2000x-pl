// Copyright (C) 2020 Intel Corporation.
// SPDX-License-Identifier: MIT

// Description
//-----------------------------------------------------------------------------
// NCSI CSR, mailbox and buffer top module
//-----------------------------------------------------------------------------


module ncsi_cmb_top #(
   parameter   DEVICE_FAMILY            = "Agilex", //FPGA Device Family
   
   //NCSI DFH Parameters
   parameter   NCSI_DFH_END_OF_LIST     = 1'b0,     //DFH End of List
   parameter   NCSI_DFH_NEXT_DFH_OFFSET = 24'h1000, //Next DFH Offset
   parameter   NCSI_DFH_FEAT_VER        = 4'h1,     //DFH Feature Revision
   parameter   NCSI_DFH_FEAT_ID         = 12'h23,   //DFH Feature ID
   
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
   //input clock & reset
   input  logic                        clk                  ,
   input  logic                        reset                ,
   input  logic                        pulse_1ms            ,
    
   //AVMM slave (connected to PMCI-Nios)
   input  logic [10:0]                 nios_avmm_s_addr     ,
   input  logic                        nios_avmm_s_write    ,
   input  logic                        nios_avmm_s_read     ,
   input  logic [31:0]                 nios_avmm_s_wrdata   ,
 //input  logic [3:0]                  nios_avmm_s_byteen   ,
   output logic [31:0]                 nios_avmm_s_rddata   ,
   output logic                        nios_avmm_s_rddvld   ,
   output logic                        nios_avmm_s_waitreq  ,
   
   //AVMM slave (NCSI DFH + CSR access of OFS-SW)
   input  logic [8:0]                  ofs_avmm_s_addr      ,
   input  logic                        ofs_avmm_s_write     ,
   input  logic                        ofs_avmm_s_read      ,
   input  logic [63:0]                 ofs_avmm_s_wrdata    ,
   input  logic [7:0]                  ofs_avmm_s_byteen    ,
   output logic [63:0]                 ofs_avmm_s_rddata    ,
   output logic                        ofs_avmm_s_rddvld    ,
   output logic                        ofs_avmm_s_waitreq   ,

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

   //Control and Status signals
   input  logic                        rbt_clk_prsnt        ,
   
   output logic                        ncsi_intr            ,
   
   output logic                        package_en           ,
   output logic                        ignr_fltr_cfg        ,
   output logic [2:0]                  package_id           ,
   output logic                        eptb_nios_reset      ,
   output logic                        iptb_nios_reset      ,
   
   output logic [CAP_NUM_CH-1:0]       ncsi_ch_en           ,
   output logic [CAP_NUM_CH-1:0]       ncsi_ptnw_tx_en      ,
   output logic [CAP_NUM_CH-1:0]       ncsi_ch_init_st      ,
   
   output logic [47:0]                 mac_addr_fltr[MAX_MAC_NUM-1:0], //[CAP_NUM_CH-1:0]
   output logic [MAX_MAC_NUM-1:0]      mac_addr_fltr_en     ,          //[CAP_NUM_CH-1:0]
   
   //NCSI debug registers
   output logic                        ncsi_pt_lpbk_en      
);

logic [31:0]                 ncsi_fc_doorbell_c   ;
logic [31:0]                 ncsi_fc_doorbell_s   ;
logic                        ncsi_fcdb_cfglost_clr;
logic [63:0]                 ncsi_fc_ctrl_reg[MAX_FC_REQ - 1:0];
logic [63:0]                 ncsi_fc_sts_reg[MAX_FC_REQ - 1:0] ;
logic [MAX_FC_REQ - 1:0]     ncsi_fc_sts_clr_pls  ;

logic [31:0]                 nios_csr_rddata      ;
logic                        nios_csr_rddvld      ;

logic                        ncsi_rx_cmd_pulse    ;
logic [11:0]                 ncsi_rx_cmd_size     ;
logic [15:0]                 ncsi_rx_cmd_err      ;
logic                        ncsi_rx_cmd_busy     ;

logic                        ncsi_tx_resp_avail   ;
logic                        ncsi_tx_resp_naen    ;
logic [11:0]                 ncsi_tx_resp_size    ;
logic                        ncsi_tx_eb4sr        ;
logic                        ncsi_tx_resp_sent    ;

logic [31:0]                 nios_bfr_rddata_c    ; //command buffer
logic [31:0]                 nios_bfr_rddata_r    ; //response buffer
logic                        nios_bfr_rddvld_c    ;
logic                        nios_bfr_rddvld_r    ;

logic [15:0]                 ncsi_rx_cmd_good_cntr;
logic [15:0]                 ncsi_rx_cmd_err_cntr ;
logic [15:0]                 ncsi_tx_resp_cntr    ;


//-----------------------------------------------------------------------------
// OFS accessible CSR
//-----------------------------------------------------------------------------
ncsi_csr_ofs #(
   //NCSI DFH Parameters
   .NCSI_DFH_END_OF_LIST (NCSI_DFH_END_OF_LIST ),
   .NCSI_DFH_NEXT_DFH_OFFSET (NCSI_DFH_NEXT_DFH_OFFSET ),
   .NCSI_DFH_FEAT_VER    (NCSI_DFH_FEAT_VER    ),
   .NCSI_DFH_FEAT_ID     (NCSI_DFH_FEAT_ID     ),
   
   //NCSI Channel to HSSI Channel Map 
   .NCSI_2_HSSI_CH_MAP_0 (NCSI_2_HSSI_CH_MAP_0 ),
   .NCSI_2_HSSI_CH_MAP_1 (NCSI_2_HSSI_CH_MAP_1 ),
   .NCSI_2_HSSI_CH_MAP_2 (NCSI_2_HSSI_CH_MAP_2 ),
   .NCSI_2_HSSI_CH_MAP_3 (NCSI_2_HSSI_CH_MAP_3 ),
   
   .MAX_FC_REQ           (MAX_FC_REQ           )
)ncsi_csr_ofs(
   .clk                  (clk                  ),
   .reset                (reset                ),

   //AVMM slave (NCSI DFH + CSR access of OFS-SW)
   .ofs_avmm_s_addr      (ofs_avmm_s_addr      ),
   .ofs_avmm_s_write     (ofs_avmm_s_write     ),
   .ofs_avmm_s_read      (ofs_avmm_s_read      ),
   .ofs_avmm_s_wrdata    (ofs_avmm_s_wrdata    ),
   .ofs_avmm_s_byteen    (ofs_avmm_s_byteen    ),
   .ofs_avmm_s_rddata    (ofs_avmm_s_rddata    ),
   .ofs_avmm_s_rddvld    (ofs_avmm_s_rddvld    ),
   .ofs_avmm_s_waitreq   (ofs_avmm_s_waitreq   ),
   
   //NCSI Mailbox
   .ncsi_fc_doorbell_c   (ncsi_fc_doorbell_c   ),
   .ncsi_fc_doorbell_s   (ncsi_fc_doorbell_s   ),
   .ncsi_fcdb_cfglost_clr(ncsi_fcdb_cfglost_clr),
   .ncsi_fc_ctrl_reg     (ncsi_fc_ctrl_reg     ),
   .ncsi_fc_sts_reg      (ncsi_fc_sts_reg      ),
   .ncsi_fc_sts_clr_pls  (ncsi_fc_sts_clr_pls  ),
   
   //NCSI debug registers
   .ncsi_pt_lpbk_en      (ncsi_pt_lpbk_en      ),
   .ncsi_rx_cmd_good_cntr(ncsi_rx_cmd_good_cntr),
   .ncsi_rx_cmd_err_cntr (ncsi_rx_cmd_err_cntr ),   
   .ncsi_tx_resp_cntr    (ncsi_tx_resp_cntr    )
);

//-----------------------------------------------------------------------------
// PMCI Nios Accessible CSR
//-----------------------------------------------------------------------------
ncsi_csr_pnios #(
   //NCSI Capability Parameters
   .CAP_NUM_CH           (CAP_NUM_CH           ),
   .CAP_NUM_UNIMAC       (CAP_NUM_UNIMAC       ),
   .CAP_NUM_MULMAC       (CAP_NUM_MULMAC       ),
   .CAP_NUM_MIXMAC       (CAP_NUM_MIXMAC       ),
   .CAP_NUM_VLAN         (CAP_NUM_VLAN         ),
   .CAP_VLAN_MODE        (CAP_VLAN_MODE        ),
   .CAP_ALL_MCAST        (CAP_ALL_MCAST        ),
   .CAP_BCAST_FILTERS    (CAP_BCAST_FILTERS    ),
   .CAP_MCAST_FILTERS    (CAP_MCAST_FILTERS    ),
   
   //NCSI Channel to HSSI Channel Map 
   .NCSI_2_HSSI_CH_MAP_0 (NCSI_2_HSSI_CH_MAP_0 ),
   .NCSI_2_HSSI_CH_MAP_1 (NCSI_2_HSSI_CH_MAP_1 ),
   .NCSI_2_HSSI_CH_MAP_2 (NCSI_2_HSSI_CH_MAP_2 ),
   .NCSI_2_HSSI_CH_MAP_3 (NCSI_2_HSSI_CH_MAP_3 ),
   
   //NCSI Buffer Depth Parameters 
   .IPT_BUFR_DEPTH       (IPT_BUFR_DEPTH       ),
   .EPT_BUFR_DEPTH       (EPT_BUFR_DEPTH       ),

   .MAX_FC_REQ           (MAX_FC_REQ           ),
   .MAX_MAC_NUM          (MAX_MAC_NUM          )
)ncsi_csr_pnios(
   .clk                  (clk                  ),
   .reset                (reset                ),
   .pulse_1ms            (pulse_1ms            ),

   //AVMM slave (connected to PMCI-Nios)
   .nios_csr_addr        (nios_avmm_s_addr     ),
   .nios_csr_write       (nios_avmm_s_write    ),
   .nios_csr_read        (nios_avmm_s_read     ),
   .nios_csr_wrdata      (nios_avmm_s_wrdata   ),
 //.nios_csr_byteen      (nios_avmm_s_byteen   ),
   .nios_csr_rddata      (nios_csr_rddata      ),
   .nios_csr_rddvld      (nios_csr_rddvld      ),
   .nios_csr_waitreq     (nios_avmm_s_waitreq  ),
   
   //NCSI Mailbox
   .ncsi_fc_doorbell_c   (ncsi_fc_doorbell_c   ),
   .ncsi_fc_doorbell_s   (ncsi_fc_doorbell_s   ),
   .ncsi_fcdb_cfglost_clr(ncsi_fcdb_cfglost_clr),
   .ncsi_fc_ctrl_reg     (ncsi_fc_ctrl_reg     ),
   .ncsi_fc_sts_reg      (ncsi_fc_sts_reg      ),
   .ncsi_fc_sts_clr_pls  (ncsi_fc_sts_clr_pls  ),
   
   //CSR - other module i/f
   .rbt_clk_prsnt        (rbt_clk_prsnt        ),
   
   .ncsi_rx_cmd_pulse    (ncsi_rx_cmd_pulse    ),
   .ncsi_rx_cmd_size     (ncsi_rx_cmd_size     ),
   .ncsi_rx_cmd_err      (ncsi_rx_cmd_err      ),
   .ncsi_rx_cmd_busy     (ncsi_rx_cmd_busy     ),
   
   .ncsi_tx_resp_avail   (ncsi_tx_resp_avail   ),
   .ncsi_tx_resp_naen    (ncsi_tx_resp_naen    ),
   .ncsi_tx_resp_size    (ncsi_tx_resp_size    ),
   .ncsi_tx_eb4sr        (ncsi_tx_eb4sr        ),
   .ncsi_tx_resp_sent    (ncsi_tx_resp_sent    ),
   
   .ncsi_intr            (ncsi_intr            ),
   
   .package_en           (package_en           ),
   .ignr_fltr_cfg        (ignr_fltr_cfg        ),
   .package_id           (package_id           ),
   .eptb_nios_reset      (eptb_nios_reset      ),
   .iptb_nios_reset      (iptb_nios_reset      ),

   .ncsi_ch_en           (ncsi_ch_en           ),
   .ncsi_ptnw_tx_en      (ncsi_ptnw_tx_en      ),
   .ncsi_ch_init_st      (ncsi_ch_init_st      ),

   .mac_addr_fltr        (mac_addr_fltr        ),
   .mac_addr_fltr_en     (mac_addr_fltr_en     )
);


//-----------------------------------------------------------------------------
// NCSI Command and Response/AEN Buffers
//-----------------------------------------------------------------------------
ncsi_cra_buffer #(
   .DEVICE_FAMILY        (DEVICE_FAMILY        )
)ncsi_cra_buffer(
   .clk                  (clk                  ),
   .reset                (reset                ),

   //AVMM slave (connected to PMCI-Nios)
   .nios_bfr_addr        (nios_avmm_s_addr     ),
   .nios_bfr_write       (nios_avmm_s_write    ),
   .nios_bfr_read        (nios_avmm_s_read     ),
   .nios_bfr_wrdata      (nios_avmm_s_wrdata   ),
 //.nios_bfr_byteen      (nios_avmm_s_byteen   ),
   .nios_bfr_rddata_c    (nios_bfr_rddata_c    ), //command buffer
   .nios_bfr_rddata_r    (nios_bfr_rddata_r    ), //response buffer
   .nios_bfr_rddvld_c    (nios_bfr_rddvld_c    ),
   .nios_bfr_rddvld_r    (nios_bfr_rddvld_r    ),
   .nios_bfr_waitreq     (nios_avmm_s_waitreq  ),
   
   //NCSI Parser to Buffer Command Rx AvST i/f
   .p2b_ncrx_data        (p2b_ncrx_data        ),
   .p2b_ncrx_sop         (p2b_ncrx_sop         ),
   .p2b_ncrx_eop         (p2b_ncrx_eop         ),
   .p2b_ncrx_err         (p2b_ncrx_err         ),
   .p2b_ncrx_mod         (p2b_ncrx_mod         ),
   .p2b_ncrx_vld         (p2b_ncrx_vld         ),
   .p2b_ncrx_rdy         (p2b_ncrx_rdy         ),
   
   //NCSI Buffer to Arbiter Response/AEN Tx AvST i/f
   .b2a_nrtx_data        (b2a_nrtx_data        ),
   .b2a_nrtx_sop         (b2a_nrtx_sop         ),
   .b2a_nrtx_eop         (b2a_nrtx_eop         ),
   .b2a_nrtx_mod         (b2a_nrtx_mod         ),
   .b2a_nrtx_err         (b2a_nrtx_err         ),
   .b2a_nrtx_rna         (b2a_nrtx_rna         ),
   .b2a_nrtx_eb4sr       (b2a_nrtx_eb4sr       ),
   .b2a_nrtx_vld         (b2a_nrtx_vld         ),
   .b2a_nrtx_rdy         (b2a_nrtx_rdy         ),
   .b2a_nrtx_sent        (b2a_nrtx_sent        ),
   
   //Nios CSR i/f
   .ncsi_rx_cmd_pulse    (ncsi_rx_cmd_pulse    ),
   .ncsi_rx_cmd_size     (ncsi_rx_cmd_size     ),
   .ncsi_rx_cmd_err      (ncsi_rx_cmd_err      ),
   .ncsi_rx_cmd_busy     (ncsi_rx_cmd_busy     ),
   .ncsi_tx_resp_avail   (ncsi_tx_resp_avail   ),
   .ncsi_tx_resp_naen    (ncsi_tx_resp_naen    ),
   .ncsi_tx_resp_size    (ncsi_tx_resp_size    ),
   .ncsi_tx_eb4sr        (ncsi_tx_eb4sr        ),
   .ncsi_tx_resp_sent    (ncsi_tx_resp_sent    ),
   
   .ncsi_rx_cmd_good_cntr(ncsi_rx_cmd_good_cntr),
   .ncsi_rx_cmd_err_cntr (ncsi_rx_cmd_err_cntr ),   
   .ncsi_tx_resp_cntr    (ncsi_tx_resp_cntr    )
);

//-----------------------------------------------------------------------------
// PMCI Nios AvMM Response
//-----------------------------------------------------------------------------
always_ff @(posedge clk, posedge reset)
begin : nios_avmm_rd_seq
   if(reset) begin
      nios_avmm_s_rddvld   <= 1'b0;
      nios_avmm_s_rddata   <= 32'd0;
   end else begin
      nios_avmm_s_rddvld    <= nios_csr_rddvld | nios_bfr_rddvld_c | nios_bfr_rddvld_r;
      
      if (nios_bfr_rddvld_c) 
         nios_avmm_s_rddata <= nios_bfr_rddata_c;
      else if (nios_bfr_rddvld_r) 
         nios_avmm_s_rddata <= nios_bfr_rddata_r;
      else
         nios_avmm_s_rddata <= nios_csr_rddata;
   end
end : nios_avmm_rd_seq

assign nios_avmm_s_waitreq = 1'b0;

endmodule
