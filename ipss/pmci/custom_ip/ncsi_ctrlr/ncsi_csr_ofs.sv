// Copyright (C) 2020 Intel Corporation.
// SPDX-License-Identifier: MIT

//
// Description
//-----------------------------------------------------------------------------
// NCSI host OFS accessible CSR module
//-----------------------------------------------------------------------------

module ncsi_csr_ofs #(
   //NCSI DFH Parameters
   parameter   NCSI_DFH_END_OF_LIST     = 1'b0,     //DFH End of List
   parameter   NCSI_DFH_NEXT_DFH_OFFSET = 24'h1000, //Next DFH Offset
   parameter   NCSI_DFH_FEAT_VER        = 4'h1,     //DFH Feature Revision
   parameter   NCSI_DFH_FEAT_ID         = 12'h23,   //DFH Feature ID
   
   //NCSI Channel to HSSI Channel Map 
   parameter   NCSI_2_HSSI_CH_MAP_0     = 64'h0,    //ch#0  to ch#7 
   parameter   NCSI_2_HSSI_CH_MAP_1     = 64'h0,    //ch#8  to ch#15
   parameter   NCSI_2_HSSI_CH_MAP_2     = 64'h0,    //ch#16 to ch#23
   parameter   NCSI_2_HSSI_CH_MAP_3     = 64'h0,    //ch#24 to ch#30
   
   parameter   MAX_FC_REQ               = 16        //Max no. of Filter Configuration request entries
)(
   input  logic                        clk                  ,
   input  logic                        reset                ,

   //AVMM slave (NCSI DFH + CSR access of OFS-SW)
   input  logic [8:0]                  ofs_avmm_s_addr      ,
   input  logic                        ofs_avmm_s_write     ,
   input  logic                        ofs_avmm_s_read      ,
   input  logic [63:0]                 ofs_avmm_s_wrdata    ,
   input  logic [7:0]                  ofs_avmm_s_byteen    ,
   output logic [63:0]                 ofs_avmm_s_rddata    ,
   output logic                        ofs_avmm_s_rddvld    ,
   output logic                        ofs_avmm_s_waitreq   ,
   
   //NCSI Mailbox
   input  logic [31:0]                 ncsi_fc_doorbell_c   ,
   output logic [31:0]                 ncsi_fc_doorbell_s   ,
   input  logic                        ncsi_fcdb_cfglost_clr,
   input  logic [63:0]                 ncsi_fc_ctrl_reg[MAX_FC_REQ - 1:0], //[1:0][31:0]
   output logic [63:0]                 ncsi_fc_sts_reg[MAX_FC_REQ - 1:0],   //[1:0][31:0]
   input  logic [MAX_FC_REQ - 1:0]     ncsi_fc_sts_clr_pls  ,
   
   //NCSI debug registers
   output logic                        ncsi_pt_lpbk_en      ,
   input  logic [15:0]                 ncsi_rx_cmd_good_cntr,
   input  logic [15:0]                 ncsi_rx_cmd_err_cntr ,
   input  logic [15:0]                 ncsi_tx_resp_cntr 
);


localparam NCSI_DFH_FTYPE     = 4'h3;     //NCSI DFH Feature Type
localparam NCSI_DFH_VERSION   = 8'h0;     //NCSI DFH Version
localparam NCSI_DFH_MINOR_REV = 4'h1;     //NCSI DFH Minor Revision 
localparam NCSI_DFH_RSVD      = 7'h0;     //NCSI DFH Reserved 

localparam NCSI_DFH_GUID_L    = 64'hb604ae6890b01de0; //NCSI DFH GUID Low
localparam NCSI_DFH_GUID_H    = 64'h8bfb86a280ad4036; //NCSI DFH GUID HIgh 

localparam NCSI_DFH_CSR_ADDR  = 63'h80;   //NCSI DFH CSR address
localparam NCSI_DFH_CSR_RELN  = 1'b0;     //NCSI DFH CSR address relation  

localparam NCSI_DFH_CSR_SIZE  = 32'hB80;  //NCSI DFH CSR Size
localparam NCSI_DFH_CSR_HASP  = 1'b0;     //NCSI DFH CSR Has Parameters?
localparam NCSI_DFH_CSR_GID   = 15'h0;    //NCSI DFH CSR Grouping ID
localparam NCSI_DFH_CSR_IID   = 16'h0;    //NCSI DFH CSR Instance ID

integer           fc_sts                  ;
integer           i                       ;
logic [63:0]      ncsi_dfh_hdr            ;
logic [63:0]      ncsi_dfh_csr_adr        ;
logic [63:0]      ncsi_dfh_csr_sng        ;
logic [63:0]      ofs_rddata_0            ;
logic [63:0]      ncsi_fc_ctrl_reg_i[128] ;
logic [63:0]      ncsi_fc_sts_reg_i[128]  ;


//-----------------------------------------------------------------------------
// Host Writeable Registers
//-----------------------------------------------------------------------------
always_ff @(posedge clk, posedge reset)
begin : host_csr_wr_seq
   if(reset) begin
      ncsi_fc_doorbell_s   <= 32'd0;
      ncsi_fc_sts_reg      <= '{default:64'd0};
      ncsi_pt_lpbk_en      <= 1'b0;
   end else begin
      if (ofs_avmm_s_write && !ofs_avmm_s_waitreq && 
          ofs_avmm_s_addr == 9'h10 && ofs_avmm_s_byteen[3:0] == 4'hF) begin
         ncsi_fc_doorbell_s[31:23] <= ofs_avmm_s_wrdata[31:23];
         ncsi_fc_doorbell_s[22]    <= ncsi_fc_doorbell_s[22] | ofs_avmm_s_wrdata[22];
         ncsi_fc_doorbell_s[21:8]  <= 14'd0;
         ncsi_fc_doorbell_s[7:0]   <= ofs_avmm_s_wrdata[7:0];
      end else if(ncsi_fcdb_cfglost_clr)
         ncsi_fc_doorbell_s[22]    <= 1'b0;
      
      for(fc_sts=0; fc_sts<MAX_FC_REQ; fc_sts++) begin
         if (ofs_avmm_s_write && !ofs_avmm_s_waitreq && 
             ofs_avmm_s_addr[8:7] == 2'h2 && 
             ofs_avmm_s_addr[6:0] == fc_sts && ofs_avmm_s_byteen[3:0] == 4'hF)
            ncsi_fc_sts_reg[fc_sts][31:0]  <= ofs_avmm_s_wrdata[31:0];
            
         if (ofs_avmm_s_write && !ofs_avmm_s_waitreq && 
             ofs_avmm_s_addr[8:7] == 2'h2 && 
             ofs_avmm_s_addr[6:0] == fc_sts && ofs_avmm_s_byteen[7:4] == 4'hF)
            ncsi_fc_sts_reg[fc_sts][63:32] <= ofs_avmm_s_wrdata[63:32];
         else if(ncsi_fc_sts_clr_pls[fc_sts])
            ncsi_fc_sts_reg[fc_sts][63] <= 1'b0;
      end
      
      if (ofs_avmm_s_addr == 9'h60 && ofs_avmm_s_byteen[0])
         ncsi_pt_lpbk_en <= ofs_avmm_s_wrdata[0];
   end
end : host_csr_wr_seq

//-----------------------------------------------------------------------------
// Host Readable Registers
//-----------------------------------------------------------------------------
always_comb
begin : host_csr_rd_comb
   ncsi_dfh_hdr[63:60]     = NCSI_DFH_FTYPE;
   ncsi_dfh_hdr[59:52]     = NCSI_DFH_VERSION;
   ncsi_dfh_hdr[51:48]     = NCSI_DFH_MINOR_REV;
   ncsi_dfh_hdr[47:41]     = NCSI_DFH_RSVD;
   ncsi_dfh_hdr[40]        = NCSI_DFH_END_OF_LIST;
   ncsi_dfh_hdr[39:16]     = NCSI_DFH_NEXT_DFH_OFFSET;
   ncsi_dfh_hdr[15:12]     = NCSI_DFH_FEAT_VER;
   ncsi_dfh_hdr[11:0]      = NCSI_DFH_FEAT_ID;
   
   ncsi_dfh_csr_adr[63:1]  = NCSI_DFH_CSR_ADDR;
   ncsi_dfh_csr_adr[0]     = NCSI_DFH_CSR_RELN;
   
   ncsi_dfh_csr_sng[63:32] = NCSI_DFH_CSR_SIZE;
   ncsi_dfh_csr_sng[31]    = NCSI_DFH_CSR_HASP;
   ncsi_dfh_csr_sng[30:16] = NCSI_DFH_CSR_GID ;
   ncsi_dfh_csr_sng[15:0]  = NCSI_DFH_CSR_IID ;
   
   case (ofs_avmm_s_addr[6:0])
      7'h0  /*00*/  : ofs_rddata_0 = ncsi_dfh_hdr;
      7'h1  /*08*/  : ofs_rddata_0 = NCSI_DFH_GUID_L;
      7'h2  /*10*/  : ofs_rddata_0 = NCSI_DFH_GUID_H;
      7'h3  /*18*/  : ofs_rddata_0 = ncsi_dfh_csr_adr;
      7'h4  /*20*/  : ofs_rddata_0 = ncsi_dfh_csr_sng;
      
      7'h10 /*80*/  : ofs_rddata_0 = {ncsi_fc_doorbell_c, ncsi_fc_doorbell_s};

      7'h18 /*C0*/  : ofs_rddata_0 = NCSI_2_HSSI_CH_MAP_0;
      7'h19 /*C8*/  : ofs_rddata_0 = NCSI_2_HSSI_CH_MAP_1;
      7'h1A /*D0*/  : ofs_rddata_0 = NCSI_2_HSSI_CH_MAP_2;
      7'h1B /*D8*/  : ofs_rddata_0 = NCSI_2_HSSI_CH_MAP_3;
      
      7'h60 /*300*/ : ofs_rddata_0 = {63'd0, ncsi_pt_lpbk_en};
      7'h61 /*308*/ : ofs_rddata_0 = {16'd0, ncsi_tx_resp_cntr, ncsi_rx_cmd_err_cntr, ncsi_rx_cmd_good_cntr};
      
      default : ofs_rddata_0 = 64'hBAADBEEF_DEADBEEF;
   endcase
   
   for(i=0; i<128; i++) begin
      if(i<MAX_FC_REQ) begin
         ncsi_fc_ctrl_reg_i[i] = ncsi_fc_ctrl_reg[i];
         ncsi_fc_sts_reg_i[i]  = ncsi_fc_sts_reg[i];
      end else begin
         ncsi_fc_ctrl_reg_i[i] = 64'd0;
         ncsi_fc_sts_reg_i[i]  = 64'd0;
      end
   end
end : host_csr_rd_comb

always_ff @(posedge clk, posedge reset)
begin : host_csr_rd_seq
   if(reset) begin
      ofs_avmm_s_rddvld    <= 1'b0;
      ofs_avmm_s_rddata    <= 64'd0;
   end else if (ofs_avmm_s_read && !ofs_avmm_s_waitreq) begin
      ofs_avmm_s_rddvld    <= 1'b1;
      
      case (ofs_avmm_s_addr[8:7])
         2'h0    : ofs_avmm_s_rddata <= ofs_rddata_0;
         2'h1    : ofs_avmm_s_rddata <= ncsi_fc_ctrl_reg_i[ofs_avmm_s_addr[6:0]];
         2'h2    : ofs_avmm_s_rddata <= ncsi_fc_sts_reg_i[ofs_avmm_s_addr[6:0]];
         default : ofs_avmm_s_rddata <= 64'hBAADBEEF_DEADBEEF;
      endcase 
   end else begin
      ofs_avmm_s_rddvld <= 1'b0;
   end
end : host_csr_rd_seq

assign ofs_avmm_s_waitreq = 1'b0;

endmodule 