// Copyright (C) 2023 Intel Corporation
// SPDX-License-Identifier: MIT

`ifndef TB_PKG_SVH
`define TB_PKG_SVH

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import svt_uvm_pkg::*;
    import svt_axi_uvm_pkg::*;

    `define NUM_MASTERS 6
    `define NUM_SLAVES  6

    `define TOP_DUT tb_top.DUT
    `define PG_AFU_TOP tb_top.DUT.soc_afu.port_gasket.pr_slot.afu_main.port_afu_instances

    `define HE_HSSI_TOP `PG_AFU_TOP.afu_gen[1].heh_gen.he_hssi_inst
    `define HE_HSSI_RX_ST_Q(CH) `HE_HSSI_TOP.multi_port_axi_traffic_ctrl_inst.GenBrdg[CH].axis_to_avst_bridge_inst.avst_rx_st

    `ifdef SIM_MODE_SOC
      `define MSIX_TOP tb_top.DUT.soc_pcie_wrapper.msix_top         
    `else
      `define MSIX_TOP tb_top.DUT.pcie_wrapper.msix_top         
    `endif
    `define FME_CSR_TOP tb_top.DUT.fme_top.fme_io
    `define UART_TOP tb_top.DUT.afu_top.vuart_top
    `define PMCI_WRAPPER tb_top.DUT.pmci_wrapper 

   `ifdef ENABLE_SOC_HOST_COVERAGE
     `define PCIE_RX tb_top.DUT.soc_pcie_ss_axis_rx_if
     `define PCIE_TX tb_top.DUT.soc_pcie_ss_axis_tx_if
     `define PCIE_RXREQ tb_top.DUT.soc_pcie_ss_axis_rxreq_if
     `define HOST_PCIE_RX tb_top.DUT.pcie_ss_axis_rx_if
     `define HOST_PCIE_TX tb_top.DUT.pcie_ss_axis_tx_if
     `define HOST_PCIE_RXREQ tb_top.DUT.pcie_ss_axis_rxreq_if
     `define HE_HSSI_TRAFFIC_CTRL `HE_HSSI_TOP.genblk3.eth_traffic_pcie_tlp_to_csr_inst.inst_eth_traffic_csr
   `endif

     localparam NUMB_ETH_CHANNELS =8;
     localparam NUMB_QSFP_PORTS = 2;
     localparam RAS_ERROR_INJ_VERIF            = 20'h0_4068;  //Added to resolve part compile issue
     localparam RAS_NOFAT_ERROR_VERIF          = 20'h0_4050;  //Added to resolve part compile issue
     localparam NUM_CVL_LANES_VERIF            = ofs_fim_eth_plat_if_pkg::NUM_CVL_LANES; //Added to resolve part compile issue

     localparam ST2MM_BASE_ADDR                = 21'h100000; //PF0_BAR0
     localparam PROTOCOL_CHECKER_BASE_ADDR     = 21'h140000; //PF0_BAR0
     localparam PMCI_BASE_ADDR                 = 21'h80000;  //PF0_BAR0
     localparam EMIF_BASE_ADDR                 = 21'h15000;  //PF0_BAR0
     localparam QSFP0_BASE_ADDR                = 21'h12000;  //PF0_BAR0
     localparam QSFP1_BASE_ADDR                = 21'h13000;  //PF0_BAR0
     localparam FME_BASE_ADDR                  = 21'h0000;   //PF0_BAR0
     localparam HOST_PCIE_BASE_ADDR            = 21'h0000;   //PF0_BAR0
     localparam SOC_PCIE_BASE_ADDR             = 21'h10000;  //PF0_BAR0
     localparam HSSI_BASE_ADDR                 = 21'h14000;  //PF0_BAR0
     localparam PORT_GASKET_BASE_ADDR          = 21'h130000; //PF0_BAR0
     localparam HE_MEM_BASE_ADDR               = 21'h0000;   //PF0_VF0_BAR0
     localparam HE_HSSI_BASE_ADDR              = 21'h60000;  //PF0_VF1_BAR0
     localparam MEM_TG_BASE_ADDR               = 21'h0000;   //PF0_VF2_BAR0
     localparam HE_LB_BASE_ADDR                = 21'h0000;   //PF1_BAR0
     localparam FME_MSIX_BASE_ADDR             = 21'h3000;   //PF0_BAR4
     localparam USER_MSIX_BASE_ADDR            = 21'h3000;   //PF0_VF0_BAR4
     localparam MSIX_PBA_BASE_ADDR             = 21'h2000;   //PF0_VF0_BAR4

     localparam DDR_CHANNEL = mem_ss_pkg::DDR_CHANNEL;

    typedef enum {
         HIA_AXI4_ST_MST   = 0,
	HSSI_AXI4_ST_MST_0 = 1,
	HSSI_AXI4_ST_MST_1 = 2,
	HSSI_AXI4_ST_MST_2 = 3,
	PMCI_AXI4_LT_MST   = 4,
	HSSI_AXI4_LT_MST   = 5
    } mst_id_t;
    typedef enum {
         HIA_AXI4_ST_SLV   = 0,
	HSSI_AXI4_ST_SLV_0 = 1,
	HSSI_AXI4_ST_SLV_1 = 2,
	HSSI_AXI4_ST_SLV_2 = 3,
	PMCI_AXI4_LT_SLV   = 4,
	 HIA_AXI4_LT_SLV   = 5
    } slv_id_t;

    `define SOC_NUM_PFS      1
    `define HOST_NUM_PFS     2
     //`define PCIE_DUT      DUT.pcie_wrapper.pcie_ss_top.pcie_ss.pcie_ss_0.gen_ptile.u_ptile.intel_pcie_ptile_ast_qhip.inst.inst.maib_and_tile.z1565a.ctp_tile_encrypted_inst.z1565a_inst.u_wrpcie_top

    `ifdef SIM_MODE_SOC
       `define SOC_PCIE_WRAPPER_SS   DUT.soc_pcie_wrapper.pcie_ss_top.soc_pcie.pcie_ss
       `define SOC_PCIE_DUT   `SOC_PCIE_WRAPPER_SS.pcie_ss.gen_ptile.u_ptile.intel_pcie_ptile_ast_qhip.inst.inst.maib_and_tile.z1565a.ctp_tile_encrypted_inst.z1565a_inst.u_wrpcie_top
       `define SOC_PCIE_QHIP  `SOC_PCIE_WRAPPER_SS.pcie_ss.gen_ptile.u_ptile
     `endif
       `define HOST_PCIE_WRAPPER_SS   DUT.pcie_wrapper.pcie_ss_top.host_pcie.pcie_ss
       `define HOST_PCIE_DUT   `HOST_PCIE_WRAPPER_SS.pcie_ss.gen_ptile.u_ptile.intel_pcie_ptile_ast_qhip.inst.inst.maib_and_tile.z1565a.ctp_tile_encrypted_inst.z1565a_inst.u_wrpcie_top
       `define HOST_PCIE_QHIP  `HOST_PCIE_WRAPPER_SS.pcie_ss.gen_ptile.u_ptile

    `include "cust_axil2mmio_system_configuration.sv"
     import pcie_pkg::*;
     import axi_pkg::*;

    import svt_pcie_uvm_pkg::*;
  import svt_ethernet_uvm_pkg::*;
`include "svt_ethernet.uvm.pkg"
`include "svt_ethernet_txrx_if.svi"
`include "ethernet_reset_if.svi"
  `include "tb_ethernet/ethernet_intermediate_env_10_25.sv"
  `include "hssi_scoreboard.sv" //HSSI monitor scoreboard 

    `include "tb_config.svh"
    `include "virtual_sequencer.svh"
    `include "ral_ofs.sv"
    `include "reg2vip_fme_adapter.svh"
    `ifdef ENABLE_SOC_HOST_COVERAGE
       `include "../../ofs-common/verification/common/coverage/ofs_coverage_interface.sv"
       `include "../../ofs-common/verification/common/coverage/ofs_cov_class.sv"
    `endif
       `include "tb_pmci_mctp/pmci_scoreboard.sv"
    `include "tb_pmci_mctp/m10_interface.sv"
     `include "axi_includes/pmci_axi.sv"
     `include "tb_pmci_mctp/mctp_pcievdm_buffer.sv"
     `include "tb_pmci_mctp/bmc_top.sv"
     `include "tb_pmci_mctp/avmms_2_spim_bridge_tb.sv"
    `include "seq_lib.svh"
    `include "tb_env.svh"
    `include "test_pkg.svh"
    `include "test_top_pkg.svh"
    `include "tx_pkg.svh"
    `include "rx_pkg.svh"
     `include "test_long_pkg.svh"


    `include "tb_ethernet/clk_defines.sv"
   
    `include "axi_includes/st2mm_csr_axil2mmio_bind.sv"
    `include "axi_includes/fme_axil2mmio_bind.sv"
    `include "axi_includes/pg_axil2mmio_bind.sv"
   `ifdef INCLUDE_TOD
      `include "axi_includes/tod_axil2mmio_bind.sv"
   `endif
   `include "axi_includes/passive_vip.sv"
   `ifdef LPBK_WITHOUT_HSSI 
   `include "axi_includes/HE_HSSI_AXIS.sv" //Monitor checks to be fix in TB 
   `endif

`endif //TB_PKG_SVH
