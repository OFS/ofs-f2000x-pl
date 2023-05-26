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
   typedef int 		 t_guid_map [bit[127:0]];
   

   localparam FME_GUID     = 128'hBFAF2AE94A5246E382FE38F0F9E17764;
   localparam PCIE_GUID    = 128'h00000000000000010000000000000000; 
   localparam HE_LB_GUID   = 128'h56E203E9864F49A7B94B12284C31E02B;
   localparam HE_MEM_GUID  = 128'h8568AB4E6BA54616BB652A578330A8EB;
   localparam HE_HSSI_GUID = 128'h823C334C98BF11EABB370242AC130002;
   localparam HE_NULL_GUID = 128'h3E7B60A0DF2D4850AA31F54A3E403501;
   localparam VIO_GUID     = 128'h1AAE155CACC54210B9ABEFBD90B970C4;
   localparam CE_GUID      = 128'h44BFC10DB42A44E5BD4257DC93EA7F91;
   localparam MEM_TG_GUID  = 128'h4DADEA342C7848CBA3DC5B831F5CECBB;

   localparam FME_SCRATCH_ADDR     = 'h28;
   localparam PCIE_SCRATCH_ADDR    = 'h8;
   localparam HE_LB_SCRATCH_ADDR   = 'h100;
   localparam HE_MEM_SCRATCH_ADDR  = 'h100;
   localparam HE_HSSI_SCRATCH_ADDR = 'h48;
   localparam MEM_TG_SCRATCH_ADDR  = 'h28;
   localparam HE_NULL_SCRATCH_ADDR = 'h18;
   localparam VIO_SCRATCH_ADDR     = 'h18;
   localparam CE_SCRATCH_ADDR      = 'h100; 
endpackage

`endif
