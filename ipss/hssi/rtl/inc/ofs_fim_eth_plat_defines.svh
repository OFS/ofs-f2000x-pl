// Copyright (C) 2020 Intel Corporation.
// SPDX-License-Identifier: MIT

//
// Description
//-----------------------------------------------------------------------------
//
//  Derived defines for HSSI SS
//
//----------------------------------------------------------------------------

`ifndef ofs_fim_eth_plat_defines
`define ofs_fim_eth_plat_defines

   `ifdef ETH_100G

      `ifdef INCLUDE_CVL
         `ifndef INCLUDE_PTP
            `define INCLUDE_PTP
            `define INCLUDE_HSSI_PORT_0_PTP
            `define INCLUDE_HSSI_PORT_4_PTP
            `define INCLUDE_HSSI_PORT_8_PTP
            `define INCLUDE_HSSI_PORT_12_PTP
         `endif

         `define INCLUDE_HSSI_PORT_0
         `define INCLUDE_HSSI_PORT_4
         `define INCLUDE_HSSI_PORT_8
         `define INCLUDE_HSSI_PORT_12
      `else
         `define INCLUDE_HSSI_PORT_0
         `define INCLUDE_HSSI_PORT_4
      `endif

   `elsif ETH_10G

      `ifdef INCLUDE_CVL
         `ifndef INCLUDE_PTP
            `define INCLUDE_PTP
            `define INCLUDE_HSSI_PORT_0_PTP
            `define INCLUDE_HSSI_PORT_1_PTP
            `define INCLUDE_HSSI_PORT_2_PTP
            `define INCLUDE_HSSI_PORT_3_PTP
            `define INCLUDE_HSSI_PORT_4_PTP
            `define INCLUDE_HSSI_PORT_5_PTP
            `define INCLUDE_HSSI_PORT_6_PTP
            `define INCLUDE_HSSI_PORT_7_PTP
            `define INCLUDE_HSSI_PORT_8_PTP
            `define INCLUDE_HSSI_PORT_9_PTP
            `define INCLUDE_HSSI_PORT_10_PTP
            `define INCLUDE_HSSI_PORT_11_PTP
            `define INCLUDE_HSSI_PORT_12_PTP
            `define INCLUDE_HSSI_PORT_13_PTP
            `define INCLUDE_HSSI_PORT_14_PTP
            `define INCLUDE_HSSI_PORT_15_PTP
         `endif

         `define INCLUDE_HSSI_PORT_0
         `define INCLUDE_HSSI_PORT_1
         `define INCLUDE_HSSI_PORT_2
         `define INCLUDE_HSSI_PORT_3
         `define INCLUDE_HSSI_PORT_4
         `define INCLUDE_HSSI_PORT_5
         `define INCLUDE_HSSI_PORT_6
         `define INCLUDE_HSSI_PORT_7
         `define INCLUDE_HSSI_PORT_8
         `define INCLUDE_HSSI_PORT_9
         `define INCLUDE_HSSI_PORT_10
         `define INCLUDE_HSSI_PORT_11
         `define INCLUDE_HSSI_PORT_12
         `define INCLUDE_HSSI_PORT_13
         `define INCLUDE_HSSI_PORT_14
         `define INCLUDE_HSSI_PORT_15
      `else
         `define INCLUDE_HSSI_PORT_0
         `define INCLUDE_HSSI_PORT_1
         `define INCLUDE_HSSI_PORT_2
         `define INCLUDE_HSSI_PORT_3
         `define INCLUDE_HSSI_PORT_4
         `define INCLUDE_HSSI_PORT_5
         `define INCLUDE_HSSI_PORT_6
         `define INCLUDE_HSSI_PORT_7
      `endif

   `else // 25G as default
      `ifndef ETH_25G
      `define ETH_25G
      `endif

      `ifdef INCLUDE_CVL
         `ifndef INCLUDE_PTP
            `define INCLUDE_PTP
            `define INCLUDE_HSSI_PORT_0_PTP
            `define INCLUDE_HSSI_PORT_1_PTP
            `define INCLUDE_HSSI_PORT_2_PTP
            `define INCLUDE_HSSI_PORT_3_PTP
            `define INCLUDE_HSSI_PORT_10_PTP
            `define INCLUDE_HSSI_PORT_11_PTP
            `define INCLUDE_HSSI_PORT_12_PTP
            `define INCLUDE_HSSI_PORT_13_PTP
         `endif

         `define INCLUDE_HSSI_PORT_0
         `define INCLUDE_HSSI_PORT_1
         `define INCLUDE_HSSI_PORT_2
         `define INCLUDE_HSSI_PORT_3
         `define INCLUDE_HSSI_PORT_10
         `define INCLUDE_HSSI_PORT_11
         `define INCLUDE_HSSI_PORT_12
         `define INCLUDE_HSSI_PORT_13
      `else
         `define INCLUDE_HSSI_PORT_0
         `define INCLUDE_HSSI_PORT_1
         `define INCLUDE_HSSI_PORT_2
         `define INCLUDE_HSSI_PORT_3
         `define INCLUDE_HSSI_PORT_4
         `define INCLUDE_HSSI_PORT_5
         `define INCLUDE_HSSI_PORT_6
         `define INCLUDE_HSSI_PORT_7
      `endif

   `endif
`endif
