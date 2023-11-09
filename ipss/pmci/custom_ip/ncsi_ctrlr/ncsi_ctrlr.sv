// Copyright (C) 2020 Intel Corporation.
// SPDX-License-Identifier: MIT

//
// Description
//-----------------------------------------------------------------------------
// NCSI controller controls the NCSI RBT interface. The NCSI control traffic
// received from host is forwarded to PMCI-Nios and pass through taffic to AFU's 
// packet filter block. Similarly, the control traffic from PMCI-Nios and pass 
// through traffic from AFU's packet filter is muxed and forwarded to host over 
// RBT interface.
//-----------------------------------------------------------------------------

module ncsi_ctrlr #(
   parameter   DEVICE_FAMILY            = "Agilex", //FPGA Device Family

   //Shell Related Parameters
   parameter   SS_ADDR_WIDTH            = 21,
   parameter   NCSI_AFU_BADDR           = 24'h0,    //NCSI AFU/management base address
   
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
   
   parameter   MAX_FC_REQ               = 16        //Max no. of Filter Configuration request entries
)(
   input  logic                        clk                  ,
   input  logic                        reset                ,

   //NCSI-RBT Interface Signals
   input  logic                        ncsi_clk             ,
   input  logic [1:0]                  ncsi_rxd             ,
   input  logic                        ncsi_crs_dv          ,
   input  logic                        ncsi_rx_err          ,
   output logic [1:0]                  ncsi_txd             ,
   output logic                        ncsi_tx_en           ,
   input  logic                        ncsi_arb_in          ,
   output logic                        ncsi_arb_out         ,
   
   //RMII2MII IP interface
   output logic                        clk_ncsi             ,
   output logic                        rst_ncsi             ,
   
   output logic [1:0]                  rmii2mii_rxd         ,
   output logic                        rmii2mii_crs_dv      ,
   output logic                        rmii2mii_rx_err      ,
   input  logic [1:0]                  rmii2mii_txd         ,
   input  logic                        rmii2mii_tx_en       ,
   
   output logic                        rmii2mii_ena_10      ,
   
   //TSE MAC IP interface
   input  logic [31:0]                 mac_rx_data          ,
   input  logic                        mac_rx_sop           ,
   input  logic                        mac_rx_eop           ,
   input  logic [5:0]                  mac_rx_err           ,
   input  logic [1:0]                  mac_rx_mod           ,
   input  logic                        mac_rx_vld           ,
   output logic                        mac_rx_rdy           ,
   
   output logic [31:0]                 mac_tx_data          ,
   output logic                        mac_tx_sop           ,
   output logic                        mac_tx_eop           ,
   output logic                        mac_tx_err           ,
   output logic [1:0]                  mac_tx_mod           ,
   output logic                        mac_tx_vld           ,
   input  logic                        mac_tx_rdy           ,
   
   output logic                        mac_tx_crc_fwd       ,
   input  logic                        mac_tx_septy         ,
   input  logic                        mac_tx_uflow         ,
   input  logic                        mac_tx_a_full        ,
   input  logic                        mac_tx_a_empty       ,
   input  logic [17:0]                 mac_rx_err_stat      ,
   input  logic [3:0]                  mac_rx_frm_type      ,
   input  logic                        mac_rx_dsav          ,
   input  logic                        mac_rx_a_full        ,
   input  logic                        mac_rx_a_empty       ,
   
   output logic                        mac_set_10           ,
   output logic                        mac_set_1000         ,
   input  logic                        mac_eth_mode         ,
   input  logic                        mac_ena_10           ,
   
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
   
   //AVMM slave (Ingress Passthrough i/f from BNIC/OVS)
   input  logic [0:0]                  ipt_avmm_s_addr      ,
   input  logic                        ipt_avmm_s_write     ,
   input  logic                        ipt_avmm_s_read      ,
   input  logic [63:0]                 ipt_avmm_s_wrdata    ,
   input  logic [7:0]                  ipt_avmm_s_byteen    ,
   output logic [63:0]                 ipt_avmm_s_rddata    ,
   output logic                        ipt_avmm_s_rddvld    ,
   output logic                        ipt_avmm_s_waitreq   ,
   
   //AVMM Master (Egress Passthrough i/f to BNIC/OVS)
   output logic [SS_ADDR_WIDTH-1:0]    ept_avmm_m_addr      ,
   output logic                        ept_avmm_m_write     ,
   output logic                        ept_avmm_m_read      ,
   output logic [63:0]                 ept_avmm_m_wrdata    ,
   output logic [7:0]                  ept_avmm_m_byteen    ,
   input  logic [63:0]                 ept_avmm_m_rddata    ,
   input  logic                        ept_avmm_m_rddvld    ,
   input  logic                        ept_avmm_m_waitreq   ,

   //Interrupt
   output logic                        ncsi_intr         
);

//Maximum 64 MAC address filters are supported
localparam  MAX_MAC_NUM     = (CAP_NUM_UNIMAC + CAP_NUM_MIXMAC) > 8 ? 8*CAP_NUM_CH : 
                              (CAP_NUM_UNIMAC + CAP_NUM_MIXMAC)*CAP_NUM_CH;
localparam  IPT_MAX_PKT_LEN = 1600;
localparam  EPT_MAX_PKT_LEN = 1600;

logic                        pulse_1us            ;
logic                        pulse_1ms            ;
logic                        rbt_clk_prsnt        ;

logic                        ena_10_r             ;
logic                        ena_10_ccd1          ;
logic                        ena_10_ccd2          ;

//NCSI Parser to Buffer Command Rx AvST i/f
logic [31:0]                 p2b_ncrx_data        ;
logic                        p2b_ncrx_sop         ;
logic                        p2b_ncrx_eop         ;
logic [5:0]                  p2b_ncrx_err         ;
logic [1:0]                  p2b_ncrx_mod         ;
logic                        p2b_ncrx_vld         ;
logic                        p2b_ncrx_rdy         ;
   
//NCSI Parser to Egress Passthrough AvST i/f
logic [31:0]                 p2e_eptrx_data       ;
logic                        p2e_eptrx_sop        ;
logic                        p2e_eptrx_eop        ;
logic [5:0]                  p2e_eptrx_err        ;
logic [1:0]                  p2e_eptrx_mod        ;
logic [47:0]                 p2e_eptrx_sma        ;
logic                        p2e_eptrx_bcst       ;
logic                        p2e_eptrx_mcst       ;
logic                        p2e_eptrx_vld        ;
logic                        p2e_eptrx_rdy        ;

//NCSI Resp Buffer to Arbiter Response/AEN Tx AvST i/f
logic [31:0]                 b2a_nrtx_data        ;
logic                        b2a_nrtx_sop         ;
logic                        b2a_nrtx_eop         ;
logic [1:0]                  b2a_nrtx_mod         ;
logic                        b2a_nrtx_err         ;
logic                        b2a_nrtx_rna         ;
logic                        b2a_nrtx_eb4sr       ;
logic                        b2a_nrtx_vld         ;
logic                        b2a_nrtx_rdy         ;
logic                        b2a_nrtx_sent        ;

//NCSI Ingress Passthrough to Arbiter Tx AvST i/f
logic [31:0]                 i2a_ipttx_data       ;
logic                        i2a_ipttx_sop        ;
logic                        i2a_ipttx_eop        ;
logic                        i2a_ipttx_err        ;
logic [1:0]                  i2a_ipttx_mod        ;
logic                        i2a_ipttx_vld        ;
logic                        i2a_ipttx_rdy        ;

//NCSI Ingress Passthrough to Egress Passthrough Loopback
logic [31:0]                 i2e_lpbk_data        ;
logic                        i2e_lpbk_sop         ;
logic                        i2e_lpbk_eop         ;
logic [1:0]                  i2e_lpbk_mod         ;
logic                        i2e_lpbk_vld         ;
logic                        i2e_lpbk_rdy         ;


logic                        package_en           ;
logic                        ignr_fltr_cfg        ;
logic [2:0]                  package_id           ;
logic                        eptb_nios_reset      ;
logic                        iptb_nios_reset      ;

logic [CAP_NUM_CH-1:0]       ncsi_ch_en           ;
logic [CAP_NUM_CH-1:0]       ncsi_ptnw_tx_en      ;
logic [CAP_NUM_CH-1:0]       ncsi_ch_init_st      ;

logic [47:0]                 mac_addr_fltr[MAX_MAC_NUM-1:0];
logic [MAX_MAC_NUM-1:0]      mac_addr_fltr_en     ;

logic                        ncsi_pt_lpbk_en      ;


//-----------------------------------------------------------------------------
// NCSI clock and reset generation
//-----------------------------------------------------------------------------
ncsi_crg ncsi_crg (
   //input clock & reset
   .clk           (clk           ),
   .reset         (reset         ),
   .ncsi_clk      (ncsi_clk      ),  
    
   //output clock & reset  
   .clk_ncsi      (clk_ncsi      ),
   .rst_ncsi      (rst_ncsi      ),
   .pulse_1us     (pulse_1us     ),
   .pulse_1ms     (pulse_1ms     ),
   .rbt_clk_prsnt (rbt_clk_prsnt )
);

//-----------------------------------------------------------------------------
// RMII2MII IP connections
//-----------------------------------------------------------------------------
assign rmii2mii_rxd      = ncsi_rxd;
assign rmii2mii_crs_dv   = ncsi_crs_dv;
assign rmii2mii_rx_err   = ncsi_rx_err;
assign ncsi_txd          = rmii2mii_txd;
assign ncsi_tx_en        = rmii2mii_tx_en;

always_ff @(posedge clk) begin
    ena_10_r <= mac_ena_10;
end

always_ff @(posedge clk_ncsi) begin
   ena_10_ccd1 <= ena_10_r;    // cross clk domain
   ena_10_ccd2 <= ena_10_ccd1;      
end

assign rmii2mii_ena_10  = ena_10_ccd2;

//-----------------------------------------------------------------------------
// TSE MAC IP Connections
//-----------------------------------------------------------------------------
assign mac_tx_crc_fwd   = 1'b0;
assign mac_set_10       = 1'b0;
assign mac_set_1000     = 1'b0;


//-----------------------------------------------------------------------------
// NCSI Rx Parser Instantiation
//-----------------------------------------------------------------------------
ncsi_rx_parser #(
   .DEVICE_FAMILY        (DEVICE_FAMILY        ),
   .CAP_NUM_CH           (CAP_NUM_CH           )
)ncsi_rx_parser(
   //input clock & reset
   .clk                  (clk                  ),
   .reset                (reset                ),
   .clk_ncsi             (clk_ncsi             ),
   .rst_ncsi             (rst_ncsi             ),
   
   //TSE MAC Rx interface
   .mac_rx_data          (mac_rx_data          ),
   .mac_rx_sop           (mac_rx_sop           ),
   .mac_rx_eop           (mac_rx_eop           ),
   .mac_rx_err           (mac_rx_err           ),
   .mac_rx_mod           (mac_rx_mod           ),
   .mac_rx_vld           (mac_rx_vld           ),
   .mac_rx_rdy           (mac_rx_rdy           ),
   .mac_rx_frm_type      (mac_rx_frm_type      ),
   
   //NCSI Parser to Buffer Command Rx AvST i/f
   .p2b_ncrx_data        (p2b_ncrx_data        ),
   .p2b_ncrx_sop         (p2b_ncrx_sop         ),
   .p2b_ncrx_eop         (p2b_ncrx_eop         ),
   .p2b_ncrx_err         (p2b_ncrx_err         ),
   .p2b_ncrx_mod         (p2b_ncrx_mod         ),
   .p2b_ncrx_vld         (p2b_ncrx_vld         ),
   .p2b_ncrx_rdy         (p2b_ncrx_rdy         ),
   
   //NCSI Parser to Ingress Passthrough AvST i/f
   .p2e_eptrx_data       (p2e_eptrx_data       ),
   .p2e_eptrx_sop        (p2e_eptrx_sop        ),
   .p2e_eptrx_eop        (p2e_eptrx_eop        ),
   .p2e_eptrx_err        (p2e_eptrx_err        ),
   .p2e_eptrx_mod        (p2e_eptrx_mod        ),
   .p2e_eptrx_sma        (p2e_eptrx_sma        ),
   .p2e_eptrx_bcst       (p2e_eptrx_bcst       ),
   .p2e_eptrx_mcst       (p2e_eptrx_mcst       ),
   .p2e_eptrx_vld        (p2e_eptrx_vld        ),
   .p2e_eptrx_rdy        (p2e_eptrx_rdy        ),


   //Nios CSR i/f
   .package_id           (package_id           )

);

//-----------------------------------------------------------------------------
// NCSI Tx Arbiter Instantiation
//-----------------------------------------------------------------------------
ncsi_tx_arb #(
   .DEVICE_FAMILY        (DEVICE_FAMILY        ),
   .CAP_NUM_CH           (CAP_NUM_CH           )
)ncsi_tx_arb(
   //input clock & reset
   .clk                  (clk                  ),
   .reset                (reset                ),
   .clk_ncsi             (clk_ncsi             ),
   .rst_ncsi             (rst_ncsi             ),
   
   //TSE MAC Tx interface
   .mac_tx_data          (mac_tx_data          ),
   .mac_tx_sop           (mac_tx_sop           ),
   .mac_tx_eop           (mac_tx_eop           ),
   .mac_tx_err           (mac_tx_err           ),
   .mac_tx_mod           (mac_tx_mod           ),
   .mac_tx_vld           (mac_tx_vld           ),
   .mac_tx_rdy           (mac_tx_rdy           ),
   .mac_tx_septy         (mac_tx_septy         ),
   
   .rmii_tx_en           (rmii2mii_tx_en       ),
   
   //NCSI Resp Buffer to Arbiter Response/AEN Tx AvST i/f
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
   
   //NCSI Ingress Passthrough to Arbiter Tx AvST i/f
   .i2a_ipttx_data       (i2a_ipttx_data       ),
   .i2a_ipttx_sop        (i2a_ipttx_sop        ),
   .i2a_ipttx_eop        (i2a_ipttx_eop        ),
   .i2a_ipttx_err        (i2a_ipttx_err        ),
   .i2a_ipttx_mod        (i2a_ipttx_mod        ),
   .i2a_ipttx_vld        (i2a_ipttx_vld        ),
   .i2a_ipttx_rdy        (i2a_ipttx_rdy        ),

   //Nios CSR i/f
   .package_en           (package_en           )
);

//-----------------------------------------------------------------------------
// CSR + Mailbox + NCSI command/response Buffers Instantiation
//-----------------------------------------------------------------------------
ncsi_cmb_top #(
   .DEVICE_FAMILY        (DEVICE_FAMILY        ),

   
   //NCSI DFH Parameters
   .NCSI_DFH_END_OF_LIST (NCSI_DFH_END_OF_LIST ),
   .NCSI_DFH_NEXT_DFH_OFFSET (NCSI_DFH_NEXT_DFH_OFFSET ),
   .NCSI_DFH_FEAT_VER    (NCSI_DFH_FEAT_VER    ),
   .NCSI_DFH_FEAT_ID     (NCSI_DFH_FEAT_ID     ),
   
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
)ncsi_cmb_top(
   //input clock & reset
   .clk                  (clk                  ),
   .reset                (reset                ),
   .pulse_1ms            (pulse_1ms            ),
    
   //AVMM slave (connected to PMCI-Nios)
   .nios_avmm_s_addr     (nios_avmm_s_addr     ),
   .nios_avmm_s_write    (nios_avmm_s_write    ),
   .nios_avmm_s_read     (nios_avmm_s_read     ),
   .nios_avmm_s_wrdata   (nios_avmm_s_wrdata   ),
 //.nios_avmm_s_byteen   (nios_avmm_s_byteen   ),
   .nios_avmm_s_rddata   (nios_avmm_s_rddata   ),
   .nios_avmm_s_rddvld   (nios_avmm_s_rddvld   ),
   .nios_avmm_s_waitreq  (nios_avmm_s_waitreq  ),
   
   //AVMM slave (NCSI DFH + CSR access of OFS-SW)
   .ofs_avmm_s_addr      (ofs_avmm_s_addr      ),
   .ofs_avmm_s_write     (ofs_avmm_s_write     ),
   .ofs_avmm_s_read      (ofs_avmm_s_read      ),
   .ofs_avmm_s_wrdata    (ofs_avmm_s_wrdata    ),
   .ofs_avmm_s_byteen    (ofs_avmm_s_byteen    ),
   .ofs_avmm_s_rddata    (ofs_avmm_s_rddata    ),
   .ofs_avmm_s_rddvld    (ofs_avmm_s_rddvld    ),
   .ofs_avmm_s_waitreq   (ofs_avmm_s_waitreq   ),

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

   //Control and Status signals
   .rbt_clk_prsnt        (rbt_clk_prsnt        ),

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
   .mac_addr_fltr_en     (mac_addr_fltr_en     ),
   
   //NCSI debug registers
   .ncsi_pt_lpbk_en      (ncsi_pt_lpbk_en      )
);


//-----------------------------------------------------------------------------
// NCSI Ingress Passthrough Module Instantiation
//-----------------------------------------------------------------------------
ncsi_ipt #(
   .DEVICE_FAMILY        (DEVICE_FAMILY        ),
   .CAP_NUM_CH           (CAP_NUM_CH           ),
   .IPT_BUFR_DEPTH       (IPT_BUFR_DEPTH       ),
   .IPT_MAX_PKT_LEN      (IPT_MAX_PKT_LEN      )
)ncsi_ipt(
   //input clock & reset
   .clk                  (clk                  ),
   .reset                (reset                ),
   
   //AVMM slave (Ingress Passthrough i/f from BNIC/OVS)
   .ipt_avmm_s_addr      (ipt_avmm_s_addr      ),
   .ipt_avmm_s_write     (ipt_avmm_s_write     ),
   .ipt_avmm_s_read      (ipt_avmm_s_read      ),
   .ipt_avmm_s_wrdata    (ipt_avmm_s_wrdata    ),
   .ipt_avmm_s_byteen    (ipt_avmm_s_byteen    ),
   .ipt_avmm_s_rddata    (ipt_avmm_s_rddata    ),
   .ipt_avmm_s_rddvld    (ipt_avmm_s_rddvld    ),
   .ipt_avmm_s_waitreq   (ipt_avmm_s_waitreq   ),

   //NCSI Ingress Passthrough to Arbiter Tx AvST i/f
   .i2a_ipttx_data       (i2a_ipttx_data       ),
   .i2a_ipttx_sop        (i2a_ipttx_sop        ),
   .i2a_ipttx_eop        (i2a_ipttx_eop        ),
   .i2a_ipttx_err        (i2a_ipttx_err        ),
   .i2a_ipttx_mod        (i2a_ipttx_mod        ),
   .i2a_ipttx_vld        (i2a_ipttx_vld        ),
   .i2a_ipttx_rdy        (i2a_ipttx_rdy        ),

   //NCSI Ingress Passthrough to Egress Passthrough Loopback
   .i2e_lpbk_data        (i2e_lpbk_data        ),
   .i2e_lpbk_sop         (i2e_lpbk_sop         ),
   .i2e_lpbk_eop         (i2e_lpbk_eop         ),
   .i2e_lpbk_mod         (i2e_lpbk_mod         ),
   .i2e_lpbk_vld         (i2e_lpbk_vld         ),
   .i2e_lpbk_rdy         (i2e_lpbk_rdy         ),
   
   //Nios CSR i/f
   .ignr_fltr_cfg        (ignr_fltr_cfg        ),
   .ncsi_pt_lpbk_en      (ncsi_pt_lpbk_en      ),
   .ncsi_ch_en           (ncsi_ch_en           ),
   .ncsi_ch_init_st      (ncsi_ch_init_st      )
);


//-----------------------------------------------------------------------------
// NCSI Egress Passthrough Module Instantiation
//-----------------------------------------------------------------------------
ncsi_ept #(
   .DEVICE_FAMILY        (DEVICE_FAMILY        ),
   .SS_ADDR_WIDTH        (SS_ADDR_WIDTH        ),
   .NCSI_AFU_BADDR       (NCSI_AFU_BADDR       ),
   .CAP_NUM_CH           (CAP_NUM_CH           ),
   .EPT_BUFR_DEPTH       (EPT_BUFR_DEPTH       ),
   .EPT_MAX_PKT_LEN      (EPT_MAX_PKT_LEN      ),
   .MAX_MAC_NUM          (MAX_MAC_NUM          )
)ncsi_ept(
   //input clock & reset
   .clk                  (clk                  ),
   .reset                (reset                ),
   .pulse_1us            (pulse_1us            ),
   
   //AVMM Master (Egress Passthrough i/f to BNIC/OVS)
   .ept_avmm_m_addr      (ept_avmm_m_addr      ),
   .ept_avmm_m_write     (ept_avmm_m_write     ),
   .ept_avmm_m_read      (ept_avmm_m_read      ),
   .ept_avmm_m_wrdata    (ept_avmm_m_wrdata    ),
   .ept_avmm_m_byteen    (ept_avmm_m_byteen    ),
   .ept_avmm_m_rddata    (ept_avmm_m_rddata    ),
   .ept_avmm_m_rddvld    (ept_avmm_m_rddvld    ),
   .ept_avmm_m_waitreq   (ept_avmm_m_waitreq   ),
   
   //NCSI Parser to Egress Passthrough AvST i/f
   .p2e_eptrx_data       (p2e_eptrx_data       ),
   .p2e_eptrx_sop        (p2e_eptrx_sop        ),
   .p2e_eptrx_eop        (p2e_eptrx_eop        ),
   .p2e_eptrx_err        (p2e_eptrx_err        ),
   .p2e_eptrx_mod        (p2e_eptrx_mod        ),
   .p2e_eptrx_sma        (p2e_eptrx_sma        ),
   .p2e_eptrx_bcst       (p2e_eptrx_bcst       ),
   .p2e_eptrx_mcst       (p2e_eptrx_mcst       ),
   .p2e_eptrx_vld        (p2e_eptrx_vld        ),
   .p2e_eptrx_rdy        (p2e_eptrx_rdy        ),

   //NCSI Ingress Passthrough to Egress Passthrough Loopback
   .i2e_lpbk_data        (i2e_lpbk_data        ),
   .i2e_lpbk_sop         (i2e_lpbk_sop         ),
   .i2e_lpbk_eop         (i2e_lpbk_eop         ),
   .i2e_lpbk_mod         (i2e_lpbk_mod         ),
   .i2e_lpbk_vld         (i2e_lpbk_vld         ),
   .i2e_lpbk_rdy         (i2e_lpbk_rdy         ),
   
   //Nios CSR i/f   
   .ignr_fltr_cfg        (ignr_fltr_cfg        ),
   .ncsi_pt_lpbk_en      (ncsi_pt_lpbk_en      ),
   .ncsi_ptnw_tx_en      (ncsi_ptnw_tx_en      ),
   .mac_addr_fltr        (mac_addr_fltr        ),
   .mac_addr_fltr_en     (mac_addr_fltr_en     )
);


//-----------------------------------------------------------------------------
// NCSI Arbitration Loopback
//-----------------------------------------------------------------------------
assign ncsi_arb_out  = ncsi_arb_in;

endmodule 