// Copyright (C) 2020 Intel Corporation.
// SPDX-License-Identifier: MIT

//
// Description
//-----------------------------------------------------------------------------
//
//  CSR address 
//
//-----------------------------------------------------------------------------
`ifndef __TEST_CSR_DEFS__
`define __TEST_CSR_DEFS__

package test_csr_defs;
   // ******************************************************************************************
   // DFH logic
   // ******************************************************************************************
   typedef struct packed {
      logic [3:0]  feat_type;
      logic [7:0]  rsvd1;
      logic [3:0]  afu_minor_ver;
      logic [6:0]  rsvd0;
      logic        eol;
      logic [23:0] nxt_dfh_offset;
      logic [3:0]  afu_major_ver;
      logic [11:0] feat_id;
   } t_dfh;

   // localparam DFH_START_OFFSET = 32'h0; 
   localparam DFH_START_OFFSET = 32'h15000; 
   localparam EMIF_DFH_FEAT_ID = 12'h9; 

   // ******************************************************************************************
   // EMIF feature registers
   // ******************************************************************************************
   localparam EMIF_STATUS_OFFSET     = 32'h8;
   localparam EMIF_CAPABILITY_OFFSET = EMIF_STATUS_OFFSET + 32'h8;
   localparam EMIF_DFH_VAL           = 64'h3_00000_06B000_1009;

   // ******************************************************************************************
   // Memory Subsyste feature registers
   // ******************************************************************************************
   localparam MEM_SS_CSR_OFFSET    = 32'h6000;
   
   localparam MEM_SS_EFFMON_OFFSET = 32'h1000;

   localparam MEM_SS_VERSION_OFFSET     = MEM_SS_CSR_OFFSET;
   localparam MEM_SS_FEAT_LIST_OFFSET   = MEM_SS_CSR_OFFSET + 'h4;
   localparam MEM_SS_FEAT_LIST_2_OFFSET = MEM_SS_CSR_OFFSET + 'h8;
   localparam MEM_SS_IF_ATTR_OFFSET     = MEM_SS_CSR_OFFSET + 'h10;
   localparam MEM_SS_SCRATCH_OFFSET     = MEM_SS_CSR_OFFSET + 'h20;
   localparam MEM_SS_STATUS_OFFSET      = MEM_SS_CSR_OFFSET + 'h50;
   localparam MEM_SS_CH_ATTR_OFFSET     = MEM_SS_CSR_OFFSET + 'h100;


   // Mem SS CSR default values
   localparam MEM_SS_MAJ_VER_NUM = 16'h1;
   localparam MEM_SS_MIN_VER_NUM = 8'h0;

   localparam MEM_SS_MEM_TYPE = 8'b1; // 1 = DDR4
   localparam MEM_SS_IF_TYPE  = 2'b0; // 0 = AXI4
   
   localparam MEM_SS_AUTO_PRECHARGE = 1'b1;
   localparam MEM_SS_NUM_WR_CPY     = 4'h1;
   localparam MEM_SS_NUM_USR_POOLS  = 3'h1;
   localparam MEM_SS_RDY_LATENCY    = 4'h3;
`ifdef ADP_MEM
   localparam MEM_SS_NUM_CH_VAL     = 4'h4;
`else
   localparam MEM_SS_NUM_CH_VAL     = 4'h1;
`endif

   localparam MEM_SS_VERSION_VAL      = {MEM_SS_MAJ_VER_NUM,
					 MEM_SS_MIN_VER_NUM,
					 8'h0};
   localparam MEM_SS_FEAT_LIST_VAL    = {8'h0,
					 MEM_SS_MEM_TYPE,
					 14'h0,
					 MEM_SS_IF_TYPE};
   localparam MEM_SS_FEAT_LIST_2_VAL  = {28'h0,
					 MEM_SS_NUM_CH_VAL};


   localparam MEM_SS_IF_ATTR_VAL    = 32'h0;
   
   localparam MEM_SS_CH_ATTR_VAL    = {4'h0,
				       MEM_SS_AUTO_PRECHARGE,
				       MEM_SS_NUM_USR_POOLS,
				       MEM_SS_NUM_WR_CPY,
				       16'h0,
				       MEM_SS_RDY_LATENCY};

   localparam MEM_SS_EFFMON_START_VAL = 32'b1;
endpackage

`endif
