// Copyright (C) 2020 Intel Corporation.
// SPDX-License-Identifier: MIT

//
// Description
//-----------------------------------------------------------------------------
//
// This package defines the parameters of APF/BPF fabric 
//
//----------------------------------------------------------------------------

`ifndef __FABRIC_PKG_SV__
`define __FABRIC_PKG_SV__

package fabric_pkg;
   localparam NUM_UNUSED_RANGE   = 3;
   localparam bit [NUM_UNUSED_RANGE-1:0][63:0] unused_ranges = {
                                                      {32'h11fff, 32'h11000},   // 0x11000 - 0x11fff 
                                                      {32'h1ffff, 32'h14000},   // 0x14000 - 0x1ffff 
                                                      {32'hfffff, 32'h90000}};  // 0x90000 - 0xfffff

endpackage : fabric_pkg
`endif // __FABRIC_PKG_SV__
