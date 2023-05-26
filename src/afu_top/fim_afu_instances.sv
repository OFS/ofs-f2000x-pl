// Copyright (C) 2020 Intel Corporation.
// SPDX-License-Identifier: MIT

//
// Description
//-----------------------------------------------------------------------------
//  Instantiates ST2MM, HE-LB Dummy, HE-LB, VirtIO, and HPS in FIM base compile 
//  static region
// -----------------------------------------------------------------------------
//
// Created for use of the PF/VF Configuration tool, where only AFU endpoints are
// connected. The user is instructed to utilize the PORT_PF_VF_INFO parameter
// to access all information regarding a specific endpoint with a PID.
// 
// The default PID mapping is as follows:
//    PID 0  - PF0       - ST2MM
//    PID 1  - PF1       - HE-LB Dummy 
//    PID 2  - PF2       - HE-LB
//    PID 3  - PF3       - VIO
//    PID 4  - PF4       - HPS-CE
//    PID 5+ - PF5+/VF1+ - NULL AFUs
//    
// Note that when CVL is not included, HE-HSSI is moved to the PR region 
// (afu_main.port_afu_instances) and the PID values are reduced by 1

`include "fpga_defines.vh"
`ifdef INCLUDE_HSSI
   `include "ofs_fim_eth_plat_defines.svh"
   import ofs_fim_eth_if_pkg::*;
`endif 
import top_cfg_pkg::*;
import pcie_ss_axis_pkg::*;

module fim_afu_instances # (
   parameter NUM_SR_PORTS = 1,
   parameter NUM_PF       = top_cfg_pkg::FIM_NUM_PF,
   parameter NUM_VF       = top_cfg_pkg::FIM_NUM_VF,
   // PF/VF to which each port is mapped
   parameter pcie_ss_hdr_pkg::ReqHdr_pf_vf_info_t[NUM_SR_PORTS-1:0] SR_PF_VF_INFO =
                {NUM_SR_PORTS{pcie_ss_hdr_pkg::ReqHdr_pf_vf_info_t'(0)}},

   parameter NUM_MEM_CH      = 0,
   parameter MAX_ETH_CH      = ofs_fim_eth_plat_if_pkg::MAX_NUM_ETH_CHANNELS
)(
   input  logic clk,
   input  logic clk_div2,
   input  logic clk_div4,
   input  logic uclk_usr,
   input  logic uclk_usr_div2,

   input  logic rst_n,
   input  logic [NUM_SR_PORTS-1:0] func_pf_rst_n,
   input  logic [NUM_SR_PORTS-1:0] func_vf_rst_n,
   input  logic [NUM_SR_PORTS-1:0] port_rst_n,
   input  logic clk_csr,
   input  logic rst_n_csr,      
  
   ofs_fim_axi_lite_if       apf_mctp_mst_if,
   ofs_fim_axi_lite_if       apf_st2mm_mst_if,
   ofs_fim_axi_lite_if.slave apf_st2mm_slv_if,

   pcie_ss_axis_if.sink   afu_axi_rx_a_if[NUM_SR_PORTS-1:0], 
   pcie_ss_axis_if.source afu_axi_tx_a_if[NUM_SR_PORTS-1:0],
   pcie_ss_axis_if.sink   afu_axi_rx_b_if[NUM_SR_PORTS-1:0], 
   pcie_ss_axis_if.source afu_axi_tx_b_if[NUM_SR_PORTS-1:0]
);

import ofs_fim_cfg_pkg::*;

localparam MM_ADDR_WIDTH     = ofs_fim_cfg_pkg::MMIO_ADDR_WIDTH;
localparam MM_DATA_WIDTH     = ofs_fim_cfg_pkg::MMIO_DATA_WIDTH;
localparam NUM_TAGS  = ofs_pcie_ss_cfg_pkg::PCIE_EP_MAX_TAGS;

//
// Macros for mapping port defintions to PF/VF resets. We use macros instead
// of functions to avoid problems with continuous assignment.
//

// Get the VF function level reset if VF is active for the function.
// If VF is not active, return a constant: not in reset.
`define GET_FUNC_VF_RST_N(PF, VF, VF_ACTIVE) ((VF_ACTIVE != 0) ? vf_flr_rst_n[PF][VF] : 1'b1)

// Construct the full reset for a function, combining PF and VF resets.
`define GET_FUNC_RST_N(PF, VF, VF_ACTIVE) (pf_flr_rst_n[PF] & `GET_FUNC_VF_RST_N(PF, VF, VF_ACTIVE))

localparam ST2MM_PID = 0; 
localparam HLB_PID = 1; 
localparam FIRST_NULL_PID = 2;

//----------------------------------------------------------------
// ST2MM
//----------------------------------------------------------------
st2mm #(
   .PF_NUM          (SR_PF_VF_INFO[ST2MM_PID].pf_num),
   .VF_NUM          (SR_PF_VF_INFO[ST2MM_PID].vf_num),
   .VF_ACTIVE       (SR_PF_VF_INFO[ST2MM_PID].vf_active),
   .MM_ADDR_WIDTH   (MM_ADDR_WIDTH),
   .MM_DATA_WIDTH   (MM_DATA_WIDTH),
   .PMCI_BASEADDR   (20'h80000),
   .TX_VDM_OFFSET   (16'h2000), 
   .RX_VDM_OFFSET   (16'h2000), 
   .READ_ALLOWANCE  (1),
   .WRITE_ALLOWANCE (1),
   .FEAT_ID         (12'h14),
   .FEAT_VER        (4'h0),
   .END_OF_LIST     (1'b0),
   .NEXT_DFH_OFFSET (24'h30000)
) st2mm (
   .clk               (clk                         ),
   .rst_n             (rst_n                       ),
   .clk_csr           (clk_csr                     ),
   .rst_n_csr         (rst_n_csr                   ),
   .axis_rx_if        (afu_axi_rx_a_if[ST2MM_PID]), // pipe2fn_rx_a_port[0]
   .axis_tx_if        (afu_axi_tx_a_if[ST2MM_PID]),
   .axi_m_pmci_vdm_if (apf_mctp_mst_if             ),
   .axi_m_if          (apf_st2mm_mst_if            ),
   .axi_s_if          (apf_st2mm_slv_if            )   
);

// we do not use the TX B port
assign afu_axi_tx_b_if[ST2MM_PID].tvalid = 1'b0;
assign afu_axi_rx_b_if[ST2MM_PID].tready = 1'b1;

//----------------------------------------------------------------
//HE-LB 
//----------------------------------------------------------------
   `ifdef USE_NULL_HE_LB
		generate if (HLB_PID < NUM_SR_PORTS) begin : hlb_null_gen
			he_null #(
				 .CSR_DATA_WIDTH (64),
				 .CSR_ADDR_WIDTH (16),
				 .CSR_DEPTH      (4),
				 .PF_ID          (SR_PF_VF_INFO[HLB_PID].pf_num),
				 .VF_ID          (SR_PF_VF_INFO[HLB_PID].vf_num),
				 .VF_ACTIVE      (SR_PF_VF_INFO[HLB_PID].vf_active)
			) null_he_lb (
				 .clk                (clk),
				 .rst_n       (port_rst_n[HLB_PID]),
				 .i_rx_if     (afu_axi_rx_a_if[HLB_PID]),
				 .o_tx_if     (afu_axi_tx_a_if[HLB_PID])
			);

                        // we do not use the TX B port
                        assign afu_axi_tx_b_if[HLB_PID].tvalid = 1'b0;
                        assign afu_axi_rx_b_if[HLB_PID].tready = 1'b1;
		end
		endgenerate
   `else // (not) USE_NULL_HE_LB
		generate if (HLB_PID < NUM_SR_PORTS) begin : hlb_top_gen
			he_lb_top #(
				.PF_ID(SR_PF_VF_INFO[HLB_PID].pf_num),
				.VF_ID(SR_PF_VF_INFO[HLB_PID].vf_num),
				.VF_ACTIVE(SR_PF_VF_INFO[HLB_PID].vf_active)
			) he_lb_top (
				.clk        (clk),
			        .rst_n      (port_rst_n[HLB_PID]),
				.axi_rx_a_if(afu_axi_rx_a_if[HLB_PID]),
				.axi_rx_b_if(afu_axi_rx_b_if[HLB_PID]),
				.axi_tx_a_if(afu_axi_tx_a_if[HLB_PID]),
				.axi_tx_b_if(afu_axi_tx_b_if[HLB_PID])
			   );
		end
		endgenerate
   `endif // USE_NULL_HE_LB

genvar i;
generate
    for(i=FIRST_NULL_PID; i<NUM_SR_PORTS; i=i+1)  begin : gen_he_null
      he_null #(
         .PF_ID (SR_PF_VF_INFO[i].pf_num),
         .VF_ID (SR_PF_VF_INFO[i].vf_num),
         .VF_ACTIVE (SR_PF_VF_INFO[i].vf_active)
      ) he_null_sr (
         .clk (clk),
         .rst_n (port_rst_n[i]),
         .i_rx_if (afu_axi_rx_a_if[i]),
         .o_tx_if (afu_axi_tx_a_if[i])
      );

      // we do not use the TX B port
      assign afu_axi_tx_b_if[i].tvalid = 1'b0;
      assign afu_axi_rx_b_if[i].tready = 1'b1;
    end
endgenerate

endmodule
