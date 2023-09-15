// Copyright (C) 2020 Intel Corporation.
// SPDX-License-Identifier: MIT

//
// Description
//-----------------------------------------------------------------------------
//
//
//
//-----------------------------------------------------------------------------

`ifndef __PFVF_SIM_PKG__
`define __PFVF_SIM_PKG__

package pfvf_sim_pkg;
// FIM Configuration Tool Begin
localparam HLB_PF     =1; 
localparam HLB_VF     =0; 
localparam HLB_VA     =0; 

localparam HEM_PF     =0; 
localparam HEM_VF     =0; 
localparam HEM_VA     =1; 

localparam HEH_PF     =0; 
localparam HEH_VF     =1; 
localparam HEH_VA     =1; 

localparam HEM_TG_PF  =0; 
localparam HEM_TG_VF  =2; 
localparam HEM_TG_VA  =1; 

localparam ST2MM_PF   =0; 
localparam ST2MM_VF   =0; 
localparam ST2MM_VA   =0; 
// FIM Configuration tool end
endpackage
`endif
