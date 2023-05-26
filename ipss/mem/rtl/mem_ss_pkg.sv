// Copyright (C) 2020 Intel Corporation.
// SPDX-License-Identifier: MIT

//
//-----------------------------------------------------------------------------
// Description
//-----------------------------------------------------------------------------

package mem_ss_pkg;

// FIM MEMORY PARAMS
localparam DDR_CHANNEL        = 4;
localparam AFU_MEM_CHANNEL    = DDR_CHANNEL;

// legacy
localparam MC_CHANNEL         = AFU_MEM_CHANNEL;

// AXI-MM PARAMS
localparam AXI_MEM_DATA_WIDTH      = 512;
localparam AXI_MEM_ADDR_WIDTH      = 32;
localparam AXI_MEM_ID_WIDTH        = 9;
localparam AXI_MEM_USER_WIDTH      = 1;
localparam AXI_MEM_BURST_LEN_WIDTH = 8;

// DDR PARAMS
localparam DDR4_A_WIDTH       = 17;
localparam DDR4_BA_WIDTH      = 2;
localparam DDR4_BG_WIDTH      = 1;
localparam DDR4_CK_WIDTH      = 1;
localparam DDR4_CKE_WIDTH     = 1;
localparam DDR4_CS_WIDTH      = 1;
localparam DDR4_ODT_WIDTH     = 1;
localparam DDR4_DQ_WIDTH      = 32;
localparam DDR4_DQS_WIDTH     = DDR4_DQ_WIDTH/8;

endpackage // mem_ss_pkg

