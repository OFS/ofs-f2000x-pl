// Copyright (C) 2021 Intel Corporation.
// SPDX-License-Identifier: MIT

//
// Description
//-----------------------------------------------------------------------------
//
// Define the parameters used in PF/VF MUX module.
//
// This reference implementation routes every function (PFs and VFs) to
// unique ports. PF0 VFs are routed to the port gasket. All PFs and
// VFs on ports other than PF0 are routed to the static region.
//
// FIM developers may change the routing policy by replacing the routing
// table generated here. In general, the table only needs to be changed
// if multiple functions are going to be mapped to the same router port.
//
// NOTE: The function-level reset mapping in afu_top matches the default
//       router port mapping. If the mapping here changes then the reset
//       mapping in afu_top must also be changed!
//
//-----------------------------------------------------------------------------

// Load macros derived from the PCIe SS configuration
`include "ofs_ip_cfg_db.vh"

package top_cfg_pkg;

   // The static region PF/VF MUX has an additional port for PF0 VFs, which
   // will all be routed through a single port toward the port gasket.
   // localparam NUM_PORT = NUM_SR_PORTS + 1;

   localparam FIM_NUM_PF     = `OFS_FIM_IP_CFG_PCIE_SS_NUM_PFS;
   localparam FIM_NUM_VF     = `OFS_FIM_IP_CFG_PCIE_SS_TOTAL_NUM_VFS;
   localparam FIM_MAX_NUM_VF = `OFS_FIM_IP_CFG_PCIE_SS_MAX_VFS_PER_PF;
   localparam FIM_PF_WIDTH   = (FIM_NUM_PF < 2) ? 1 : $clog2(FIM_NUM_PF);
   localparam FIM_VF_WIDTH   = (FIM_NUM_VF < 2) ? 1 : $clog2(FIM_NUM_VF);

   // Number of hosts addressable in the PF/VF MUX (typically 1)
   localparam NUM_HOST = 1;

   // Vector indicating whether a PF is enabled, extracted from the PCIe SS
   localparam MAX_PF_NUM = `OFS_FIM_IP_CFG_PCIE_SS_MAX_PF_NUM;
   localparam logic PF_ENABLED_VEC[MAX_PF_NUM+1] = '{ `OFS_FIM_IP_CFG_PCIE_SS_PF_ENABLED_VEC };
   // Vector with number of VFs per PF
   localparam int   PF_NUM_VFS_VEC[MAX_PF_NUM+1] = '{ `OFS_FIM_IP_CFG_PCIE_SS_NUM_VFS_VEC };

   // =====================================================================
   //                Static region PF/VF MUX routing table
   // =====================================================================

   // Build the default static region routing table. The functions are in a header
   // file because the algorithm is general but the data types are dependent on
   // the parameters above.
   //
   // The included code generates a routing table as a parameter named
   // SR_PF_VF_RTABLE of type t_pf_vf_entry_info (also generated). See
   // the header file in ofs-common/src/common/lib/mux/ for more details.
   //
   // A developer building a new FIM could choose to remove this include
   // and generate a workload-specific table here. The table could be generated
   // either with a different function or with static initializers.

   // There is no port gasket (PR region) for the host PCIe connection
   localparam ENABLE_PG_SHARED_VF = 0;
   localparam PG_NUM_PORT = 0;

   // Number of ports in AFU top, ST2MM (OFS management), static-region
   localparam NUM_TOP_PORTS = int'(PF_ENABLED_VEC[0]) + ((PF_NUM_VFS_VEC[0] > 0) | (MAX_PF_NUM > 0));
   
   // Number of ports in the static-region AFU block:
   //  - A port for each non-PF0 function
   localparam NUM_SR_PORTS = FIM_NUM_PF + FIM_NUM_VF - int'(PF_ENABLED_VEC[0]);
   
   `include "pf_vf_mux_default_rtable.vh"

endpackage : top_cfg_pkg
