// Copyright (C) 2021 Intel Corporation.
// SPDX-License-Identifier: MIT

//
// Description
//-----------------------------------------------------------------------------
//
// This package defines the parameters used in PF/VF Mux module
//
//-----------------------------------------------------------------------------
package soc_top_cfg_pkg;
   import ofs_fim_cfg_pkg::*;

   // Parameters
   parameter NUM_HOST = 1;
   parameter NUM_PORT = 2;
    // PG mux parameter
   parameter  PG_NUM_HOST = 1;
   parameter  PG_NUM_PORT = 3;

   parameter  FIM_NUM_PF         = 1;
   parameter  FIM_NUM_VF         = 3;
   parameter  FIM_MAX_NUM_VF     = 3;
   parameter  FIM_PF_WIDTH       = (FIM_NUM_PF < 2) ? 1 : $clog2(FIM_NUM_PF);
   parameter  FIM_VF_WIDTH       = (FIM_NUM_VF < 2) ? 1 : $clog2(FIM_NUM_VF);
 
 
//-------------------------------------------------------------------
// PF/VF Mapping Table 
//
//
// SoC AFU: 
//    +---------------------------------+
//    + Module          | PF/VF         +
//    +---------------------------------+
//    | ST2MM           | PF0           | 
//    | HE-MEM          | PF0-VF0       |
//    | HE-HSSI         | PF0-VF1       |
//    | MEM-TG          | PF0-VF2       |
//    +---------------------------------+
//
//-------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------------------------------------
//  Physical Function#       Virtual Active           Virtual Function#        Switch/Mux Port ID        // AXI-S Pipeline Depth        // FPGA Device PF/VF to Switch Port Map
//------------------------------------------------------------------------------------------------------------------------------------------------------

   // ----- Mapping Table Begin -----
   // PF/VF Port IDs
   parameter SR_PF0_PF0_PID = 0;
   parameter PG_SHARED_VF_PID = 1;

   parameter PRR_PF0_VF0_PID = 0;
   parameter PRR_PF0_VF1_PID = 1;
   parameter PRR_PF0_VF2_PID = 2;

   //=========================================================================================================================
   //                           PF/VF Mux Routing Table
   //=========================================================================================================================

   // The routing table is passed to the main PF/VF MUX instantiated in afu_top.
   // The PF/VF MUX has a function that parses the table in order to generate
   // a routing network.

 
   localparam NUM_RTABLE_ENTRIES = NUM_PORT-1+PG_NUM_PORT+2;
      
   localparam PG_NUM_RTABLE_ENTRIES = 3;
   
   // A subset of the multiplexed PF/VF ports are passed through the port
   // gasket to afu_main(). The following arrays indicate the PF/VF numbers
   // associated with an equal-sized array of AXI TLP interfaces passed
   // to afu_main().

   // Number of MUX ports connected to the port gasket region (PR)
   localparam  PG_AFU_NUM_PORTS = 3;

   localparam  NUM_SR_PORTS = NUM_PORT-1;

   // Port PF/VF mapping within the port gasket
   localparam int          PG_AFU_MUX_PID         [PG_AFU_NUM_PORTS] = '{PRR_PF0_VF0_PID, PRR_PF0_VF1_PID, PRR_PF0_VF2_PID};
   localparam logic [10:0] PG_AFU_PORTS_VF_NUM    [PG_AFU_NUM_PORTS] = '{0, 1, 2};
   localparam logic        PG_AFU_PORTS_VF_ACTIVE [PG_AFU_NUM_PORTS] = '{1, 1, 1};
   localparam logic [2:0]  PG_AFU_PORTS_PF_NUM    [PG_AFU_NUM_PORTS] = '{0, 0, 0};
   typedef enum                                                         {PRR_PF0_VF0_PID_IDX, PRR_PF0_VF1_PID_IDX, PRR_PF0_VF2_PID_IDX} e_sr_mux_pid_idx;

   localparam int          AFU_SR_MUX_PID        [NUM_SR_PORTS] = '{SR_PF0_PF0_PID};
   localparam logic [11:0] PG_SR_PORTS_VF_NUM    [NUM_SR_PORTS] = '{0};
   localparam logic        PG_SR_PORTS_VF_ACTIVE [NUM_SR_PORTS] = '{0};
   localparam logic [2:0]  PG_SR_PORTS_PF_NUM    [NUM_SR_PORTS] = '{0};

   import pcie_ss_hdr_pkg::ReqHdr_pf_vf_info_t;
   typedef pcie_ss_hdr_pkg::ReqHdr_pf_vf_info_t [NUM_SR_PORTS-1:0] t_soc_sr_afu_pf_vf_info;
   typedef pcie_ss_hdr_pkg::ReqHdr_pf_vf_info_t [PG_AFU_NUM_PORTS-1:0] t_pg_afu_pf_vf_info;
   typedef pf_vf_mux_pkg::t_pfvf_rtable_entry   [NUM_RTABLE_ENTRIES-1:0] t_pf_vf_entry_info;
   typedef pf_vf_mux_pkg::t_pfvf_rtable_entry   [PG_NUM_RTABLE_ENTRIES-1:0] t_prr_pf_vf_entry_info;
   

   function automatic t_pg_afu_pf_vf_info get_pg_pf_vf_info();
      t_pg_afu_pf_vf_info map;
      for (int p = 0; p < PG_AFU_NUM_PORTS; p = p + 1) begin
   	 map[p].pf_num    = PG_AFU_PORTS_PF_NUM[p];
   	 map[p].vf_num    = PG_AFU_PORTS_VF_NUM[p];
   	 map[p].vf_active = PG_AFU_PORTS_VF_ACTIVE[p];
      end
      return map;
   endfunction // gen_pf_vf_map
   
   function automatic t_soc_sr_afu_pf_vf_info get_soc_sr_pf_vf_info();
      t_soc_sr_afu_pf_vf_info map;
      for (int p = 0; p < NUM_SR_PORTS; p = p + 1) begin
	 map[p].pf_num    = PG_SR_PORTS_PF_NUM[p];
	 map[p].vf_num    = PG_SR_PORTS_VF_NUM[p];
	 map[p].vf_active = PG_SR_PORTS_VF_ACTIVE[p];
      end
      return map;
   endfunction // gen_pf_vf_map

   //Sets the routing table in Static Region
   // Sets the PID routing information in fim_afu_instances
   function automatic t_pf_vf_entry_info get_pf_vf_entry_info();
      t_pf_vf_entry_info map;
      for (int p = 0; p < NUM_RTABLE_ENTRIES; p = p + 1) begin
         if(p<NUM_SR_PORTS) begin                                //Updates the routing table entry for all functions
            map[p].pf        = PG_SR_PORTS_PF_NUM[p];               // in the static region
	    map[p].vf        = PG_SR_PORTS_VF_NUM[p];
	    map[p].vf_active = PG_SR_PORTS_VF_ACTIVE[p];
            map[p].pfvf_port = AFU_SR_MUX_PID[p];
         // Updates routing table for the physical port to PR region
         end else if ( p>=NUM_SR_PORTS && (p<(NUM_SR_PORTS+PG_AFU_NUM_PORTS))) begin 
            map[p].pf        = PG_AFU_PORTS_PF_NUM[p-PG_SHARED_VF_PID];             
   	    map[p].vf        = PG_AFU_PORTS_VF_NUM[p-PG_SHARED_VF_PID];
   	    map[p].vf_active = PG_AFU_PORTS_VF_ACTIVE[p-PG_SHARED_VF_PID];
            map[p].pfvf_port = PG_SHARED_VF_PID;
         // Default routing table entry which maps to PID 0 always
         end else begin
            map[p].pf    = -1;
	    map[p].vf    = -1;
	    map[p].vf_active = (p == (NUM_RTABLE_ENTRIES-1));
            map[p].pfvf_port = 0;
         end
      end
      return map;
   endfunction // gen_pf_vf_map

   function automatic t_prr_pf_vf_entry_info get_prr_pf_vf_entry_info();
      t_prr_pf_vf_entry_info map;
      for (int p = 0; p < PG_AFU_NUM_PORTS; p = p + 1) begin
         map[p].pf        = PG_AFU_PORTS_PF_NUM[p];
   	 map[p].vf        = PG_AFU_PORTS_VF_NUM[p];
   	 map[p].vf_active = PG_AFU_PORTS_VF_ACTIVE[p];
         map[p].pfvf_port = PG_AFU_MUX_PID[p];
      end
      return map;
   endfunction // gen_pf_vf_map

        
 

endpackage : soc_top_cfg_pkg
