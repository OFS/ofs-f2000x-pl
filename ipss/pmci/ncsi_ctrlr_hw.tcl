# Copyright (C) 2020 Intel Corporation.
# SPDX-License-Identifier: MIT

# 
# Description
# -----------------------------------------------------------------------------
# This is the _hw.tcl of NCSI Controller
# -----------------------------------------------------------------------------


# -----------------------------------------------------------------------------
# Module Properties
# -----------------------------------------------------------------------------
package require -exact qsys 20.3

set_module_property DESCRIPTION "NCSI Controller IP"
set_module_property NAME ncsi_ctrlr
set_module_property VERSION 1.0
set_module_property GROUP "PMCI-SS Custom IP"
set_module_property DISPLAY_NAME "NCSI Controller"
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
# set_module_property INTERNAL false
# set_module_property OPAQUE_ADDRESS_MAP true

set_module_property VALIDATION_CALLBACK     ip_validate
set_module_property ELABORATION_CALLBACK    ip_elaborate

# -----------------------------------------------------------------------------
# Files
# -----------------------------------------------------------------------------
add_fileset synth_fileset QUARTUS_SYNTH synth_callback_procedure
set_fileset_property synth_fileset TOP_LEVEL ncsi_ctrlr
# set_fileset_property synth_fileset ENABLE_RELATIVE_INCLUDE_PATHS false
# set_fileset_property synth_fileset ENABLE_FILE_OVERWRITE_MODE false
add_fileset simver_fileset SIM_VERILOG synth_callback_procedure
set_fileset_property simver_fileset TOP_LEVEL ncsi_ctrlr
add_fileset simvhd_fileset SIM_VHDL synth_callback_procedure
set_fileset_property simvhd_fileset TOP_LEVEL ncsi_ctrlr

# proc synth_callback_procedure { } {
proc synth_callback_procedure { entity_name } {
   add_fileset_file ncsi_ctrlr.sv SYSTEM_VERILOG PATH "./custom_ip/ncsi_ctrlr/ncsi_ctrlr.sv" TOP_LEVEL_FILE
   add_fileset_file ncsi_csr_ofs.sv SYSTEM_VERILOG PATH "./custom_ip/ncsi_ctrlr/ncsi_csr_ofs.sv"
   add_fileset_file ncsi_csr_pnios.sv SYSTEM_VERILOG PATH "./custom_ip/ncsi_ctrlr/ncsi_csr_pnios.sv"
   add_fileset_file ncsi_crg.sv SYSTEM_VERILOG PATH "./custom_ip/ncsi_ctrlr/ncsi_crg.sv"
   add_fileset_file ncsi_cmb_top.sv SYSTEM_VERILOG PATH "./custom_ip/ncsi_ctrlr/ncsi_cmb_top.sv"
   add_fileset_file ncsi_cra_buffer.sv SYSTEM_VERILOG PATH "./custom_ip/ncsi_ctrlr/ncsi_cra_buffer.sv"
   add_fileset_file ncsi_tx_arb.sv SYSTEM_VERILOG PATH "./custom_ip/ncsi_ctrlr/ncsi_tx_arb.sv"
   add_fileset_file ncsi_ipt.sv SYSTEM_VERILOG PATH "./custom_ip/ncsi_ctrlr/ncsi_ipt.sv"
   add_fileset_file ncsi_ept.sv SYSTEM_VERILOG PATH "./custom_ip/ncsi_ctrlr/ncsi_ept.sv"
   add_fileset_file ncsi_rx_parser.sv SYSTEM_VERILOG PATH "./custom_ip/ncsi_ctrlr/ncsi_rx_parser.sv"
}


# -----------------------------------------------------------------------------
# Parameters
# -----------------------------------------------------------------------------
add_parameter SS_ADDR_WIDTH INTEGER 24 "Address width of IOFS FIM sub systems. This will also be used as address width of the passthrough egress master AvMM interface"
set_parameter_property SS_ADDR_WIDTH DISPLAY_NAME "IOFS Access Address Width"
set_parameter_property SS_ADDR_WIDTH GROUP "IOFS Related Parameters"
set_parameter_property SS_ADDR_WIDTH UNITS None
set_parameter_property SS_ADDR_WIDTH HDL_PARAMETER true
set_parameter_property SS_ADDR_WIDTH AFFECTS_ELABORATION true
set_parameter_property SS_ADDR_WIDTH AFFECTS_GENERATION false
set_parameter_property SS_ADDR_WIDTH ENABLED true
set_parameter_property SS_ADDR_WIDTH ALLOWED_RANGES {10:32}


add_parameter NCSI_AFU_BADDR INTEGER 0x0 "AFU's NCSI management module's base address in BPF interconnect"
set_parameter_property NCSI_AFU_BADDR DISPLAY_NAME "AFU's NCSI management module's base address"
set_parameter_property NCSI_AFU_BADDR GROUP "IOFS Related Parameters"
set_parameter_property NCSI_AFU_BADDR UNITS None
set_parameter_property NCSI_AFU_BADDR HDL_PARAMETER true
set_parameter_property NCSI_AFU_BADDR AFFECTS_ELABORATION true
set_parameter_property NCSI_AFU_BADDR AFFECTS_GENERATION false
set_parameter_property NCSI_AFU_BADDR ENABLED true
set_parameter_property NCSI_AFU_BADDR ALLOWED_RANGES {0x0:0xFFFFFF}
set_parameter_property NCSI_AFU_BADDR DISPLAY_HINT hexadecimal


add_parameter NCSI_DFH_END_OF_LIST INTEGER 0 "NCSI DFH End of List"
set_parameter_property NCSI_DFH_END_OF_LIST DISPLAY_NAME "NCSI DFH End of List"
set_parameter_property NCSI_DFH_END_OF_LIST GROUP "NCSI DFH Paramters"
set_parameter_property NCSI_DFH_END_OF_LIST UNITS None
set_parameter_property NCSI_DFH_END_OF_LIST HDL_PARAMETER true
set_parameter_property NCSI_DFH_END_OF_LIST AFFECTS_ELABORATION true
set_parameter_property NCSI_DFH_END_OF_LIST AFFECTS_GENERATION false
set_parameter_property NCSI_DFH_END_OF_LIST ENABLED true
set_parameter_property NCSI_DFH_END_OF_LIST ALLOWED_RANGES { \
   "0:0(NCSI is NOT the end of DFH list)" \
   "1:1(NCSI is the end of DFH list)" \
}

add_parameter NCSI_DFH_NEXT_DFH_OFFSET INTEGER 0x0 "NCSI's Next DFH Offset"
set_parameter_property NCSI_DFH_NEXT_DFH_OFFSET DISPLAY_NAME "NCSI's Next DFH Offset"
set_parameter_property NCSI_DFH_NEXT_DFH_OFFSET GROUP "NCSI DFH Paramters"
set_parameter_property NCSI_DFH_NEXT_DFH_OFFSET UNITS None
set_parameter_property NCSI_DFH_NEXT_DFH_OFFSET HDL_PARAMETER true
set_parameter_property NCSI_DFH_NEXT_DFH_OFFSET AFFECTS_ELABORATION true
set_parameter_property NCSI_DFH_NEXT_DFH_OFFSET AFFECTS_GENERATION false
set_parameter_property NCSI_DFH_NEXT_DFH_OFFSET ENABLED true
set_parameter_property NCSI_DFH_NEXT_DFH_OFFSET ALLOWED_RANGES {0x0:0xFFFFFF}
set_parameter_property NCSI_DFH_NEXT_DFH_OFFSET DISPLAY_HINT hexadecimal

add_parameter NCSI_DFH_FEAT_VER INTEGER 0x1 "NCSI's DFH Feature Revision"
set_parameter_property NCSI_DFH_FEAT_VER DISPLAY_NAME "NCSI DFH Feature Revision"
set_parameter_property NCSI_DFH_FEAT_VER GROUP "NCSI DFH Paramters"
set_parameter_property NCSI_DFH_FEAT_VER UNITS None
set_parameter_property NCSI_DFH_FEAT_VER HDL_PARAMETER true
set_parameter_property NCSI_DFH_FEAT_VER AFFECTS_ELABORATION true
set_parameter_property NCSI_DFH_FEAT_VER AFFECTS_GENERATION false
set_parameter_property NCSI_DFH_FEAT_VER ENABLED true
set_parameter_property NCSI_DFH_FEAT_VER ALLOWED_RANGES {0x0:0xF}

add_parameter NCSI_DFH_FEAT_ID INTEGER 0x23 "NCSI's DFH Feature ID"
set_parameter_property NCSI_DFH_FEAT_ID DISPLAY_NAME "NCSI DFH Feature ID"
set_parameter_property NCSI_DFH_FEAT_ID GROUP "NCSI DFH Paramters"
set_parameter_property NCSI_DFH_FEAT_ID UNITS None
set_parameter_property NCSI_DFH_FEAT_ID HDL_PARAMETER true
set_parameter_property NCSI_DFH_FEAT_ID AFFECTS_ELABORATION true
set_parameter_property NCSI_DFH_FEAT_ID AFFECTS_GENERATION false
set_parameter_property NCSI_DFH_FEAT_ID ENABLED true
set_parameter_property NCSI_DFH_FEAT_ID ALLOWED_RANGES {0x0:0xFFF}
set_parameter_property NCSI_DFH_FEAT_ID DISPLAY_HINT hexadecimal


# -----------------------------------------------------------------------------
# Port - Clock
# -----------------------------------------------------------------------------
add_interface clock clock end
set_interface_property clock ENABLED true
set_interface_property clock EXPORT_OF ""
set_interface_property clock PORT_NAME_MAP ""
set_interface_property clock CMSIS_SVD_VARIABLES ""
set_interface_property clock SVD_ADDRESS_GROUP ""
set_interface_property clock IPXACT_REGISTER_MAP_VARIABLES ""

add_interface_port clock clk clk Input 1


# -----------------------------------------------------------------------------
# Port - Reset
# -----------------------------------------------------------------------------
add_interface reset reset end
set_interface_property reset associatedClock clock
set_interface_property reset synchronousEdges DEASSERT
set_interface_property reset ENABLED true
set_interface_property reset EXPORT_OF ""
set_interface_property reset PORT_NAME_MAP ""
set_interface_property reset CMSIS_SVD_VARIABLES ""
set_interface_property reset SVD_ADDRESS_GROUP ""
set_interface_property reset IPXACT_REGISTER_MAP_VARIABLES ""

add_interface_port reset reset reset Input 1


# -----------------------------------------------------------------------------
# Port - RBT interface (conduit)
# -----------------------------------------------------------------------------
add_interface ncsi_rbt_if conduit end
set_interface_property ncsi_rbt_if associatedClock clock
set_interface_property ncsi_rbt_if associatedReset reset
set_interface_property ncsi_rbt_if ENABLED true
set_interface_property ncsi_rbt_if EXPORT_OF ""
set_interface_property ncsi_rbt_if PORT_NAME_MAP ""
set_interface_property ncsi_rbt_if CMSIS_SVD_VARIABLES ""
set_interface_property ncsi_rbt_if SVD_ADDRESS_GROUP ""
set_interface_property ncsi_rbt_if IPXACT_REGISTER_MAP_VARIABLES ""

add_interface_port ncsi_rbt_if ncsi_clk ncsi_clk Input 1
add_interface_port ncsi_rbt_if ncsi_rxd ncsi_rxd Input 2
add_interface_port ncsi_rbt_if ncsi_crs_dv ncsi_crs_dv Input 1
add_interface_port ncsi_rbt_if ncsi_rx_err ncsi_rx_err Input 1
add_interface_port ncsi_rbt_if ncsi_txd ncsi_txd Output 2
add_interface_port ncsi_rbt_if ncsi_tx_en ncsi_tx_en Output 1
add_interface_port ncsi_rbt_if ncsi_arb_in ncsi_arb_in Input 1
add_interface_port ncsi_rbt_if ncsi_arb_out ncsi_arb_out Output 1


# -----------------------------------------------------------------------------
# Port - NCSI Clock Out
# -----------------------------------------------------------------------------
add_interface clk_ncsi clock start
set_interface_property clk_ncsi associatedDirectClock ""
set_interface_property clk_ncsi ENABLED true
set_interface_property clk_ncsi EXPORT_OF ""
set_interface_property clk_ncsi PORT_NAME_MAP ""
set_interface_property clk_ncsi CMSIS_SVD_VARIABLES ""
set_interface_property clk_ncsi SVD_ADDRESS_GROUP ""
set_interface_property clk_ncsi IPXACT_REGISTER_MAP_VARIABLES ""

add_interface_port clk_ncsi clk_ncsi clk Output 1


# -----------------------------------------------------------------------------
# Port - NCSI Reset Out
# -----------------------------------------------------------------------------
add_interface rst_ncsi reset start
set_interface_property rst_ncsi associatedClock clk_ncsi
set_interface_property rst_ncsi associatedDirectReset ""
set_interface_property rst_ncsi associatedResetSinks reset
set_interface_property rst_ncsi synchronousEdges DEASSERT
set_interface_property rst_ncsi ENABLED true
set_interface_property rst_ncsi EXPORT_OF ""
set_interface_property rst_ncsi PORT_NAME_MAP ""
set_interface_property rst_ncsi CMSIS_SVD_VARIABLES ""
set_interface_property rst_ncsi SVD_ADDRESS_GROUP ""
set_interface_property rst_ncsi IPXACT_REGISTER_MAP_VARIABLES ""

add_interface_port rst_ncsi rst_ncsi reset Output 1


# -----------------------------------------------------------------------------
# Port - RMII2MII RMII interface (conduit)
# -----------------------------------------------------------------------------
add_interface r2m_rmii_if conduit end
set_interface_property r2m_rmii_if associatedClock none
set_interface_property r2m_rmii_if associatedReset none
set_interface_property r2m_rmii_if ENABLED true
set_interface_property r2m_rmii_if EXPORT_OF ""
set_interface_property r2m_rmii_if PORT_NAME_MAP ""
set_interface_property r2m_rmii_if CMSIS_SVD_VARIABLES ""
set_interface_property r2m_rmii_if SVD_ADDRESS_GROUP ""
set_interface_property r2m_rmii_if IPXACT_REGISTER_MAP_VARIABLES ""

add_interface_port r2m_rmii_if rmii2mii_rxd rxdata Output 2
add_interface_port r2m_rmii_if rmii2mii_crs_dv crs Output 1
add_interface_port r2m_rmii_if rmii2mii_rx_err rxerror Output 1
add_interface_port r2m_rmii_if rmii2mii_txd txdata Input 2
add_interface_port r2m_rmii_if rmii2mii_tx_en txenable Input 1


# -----------------------------------------------------------------------------
# Port - RMII2MII MACSPEED interface (conduit)
# -----------------------------------------------------------------------------
add_interface r2m_mspeed_if conduit end
set_interface_property r2m_mspeed_if associatedClock none
set_interface_property r2m_mspeed_if associatedReset none
set_interface_property r2m_mspeed_if ENABLED true
set_interface_property r2m_mspeed_if EXPORT_OF ""
set_interface_property r2m_mspeed_if PORT_NAME_MAP ""
set_interface_property r2m_mspeed_if CMSIS_SVD_VARIABLES ""
set_interface_property r2m_mspeed_if SVD_ADDRESS_GROUP ""
set_interface_property r2m_mspeed_if IPXACT_REGISTER_MAP_VARIABLES ""

add_interface_port r2m_mspeed_if rmii2mii_ena_10 ena_10 Output 1


# -----------------------------------------------------------------------------
# Port - MAC User Rx interface (AvST)
# -----------------------------------------------------------------------------
add_interface mac_urx_if avalon_streaming end
set_interface_property mac_urx_if associatedClock clk_ncsi
set_interface_property mac_urx_if dataBitsPerSymbol 8
set_interface_property mac_urx_if errorDescriptor ""
set_interface_property mac_urx_if firstSymbolInHighOrderBits true
set_interface_property mac_urx_if maxChannel 0
set_interface_property mac_urx_if readyAllowance 0
set_interface_property mac_urx_if readyLatency 2
set_interface_property mac_urx_if ENABLED true
set_interface_property mac_urx_if EXPORT_OF ""
set_interface_property mac_urx_if PORT_NAME_MAP ""
set_interface_property mac_urx_if CMSIS_SVD_VARIABLES ""
set_interface_property mac_urx_if SVD_ADDRESS_GROUP ""
set_interface_property mac_urx_if IPXACT_REGISTER_MAP_VARIABLES ""

add_interface_port mac_urx_if mac_rx_data data Input 32
add_interface_port mac_urx_if mac_rx_sop startofpacket Input 1
add_interface_port mac_urx_if mac_rx_eop endofpacket Input 1
add_interface_port mac_urx_if mac_rx_err error Input 6
add_interface_port mac_urx_if mac_rx_mod empty Input 2
add_interface_port mac_urx_if mac_rx_vld valid Input 1
add_interface_port mac_urx_if mac_rx_rdy ready Output 1


# -----------------------------------------------------------------------------
# Port - MAC User Tx interface (AvST)
# -----------------------------------------------------------------------------
add_interface mac_utx_if avalon_streaming start
set_interface_property mac_utx_if associatedClock clk_ncsi
set_interface_property mac_utx_if dataBitsPerSymbol 8
set_interface_property mac_utx_if errorDescriptor ""
set_interface_property mac_utx_if firstSymbolInHighOrderBits true
set_interface_property mac_utx_if maxChannel 0
set_interface_property mac_utx_if readyAllowance 0
set_interface_property mac_utx_if readyLatency 0
set_interface_property mac_utx_if ENABLED true
set_interface_property mac_utx_if EXPORT_OF ""
set_interface_property mac_utx_if PORT_NAME_MAP ""
set_interface_property mac_utx_if CMSIS_SVD_VARIABLES ""
set_interface_property mac_utx_if SVD_ADDRESS_GROUP ""
set_interface_property mac_utx_if IPXACT_REGISTER_MAP_VARIABLES ""

add_interface_port mac_utx_if mac_tx_data data Output 32
add_interface_port mac_utx_if mac_tx_sop startofpacket Output 1
add_interface_port mac_utx_if mac_tx_eop endofpacket Output 1
add_interface_port mac_utx_if mac_tx_err error Output 1
add_interface_port mac_utx_if mac_tx_mod empty Output 2
add_interface_port mac_utx_if mac_tx_vld valid Output 1
add_interface_port mac_utx_if mac_tx_rdy ready Input 1


# -----------------------------------------------------------------------------
# Port - MAC Misc interface (conduit)
# -----------------------------------------------------------------------------
add_interface mac_misc_if conduit end
set_interface_property mac_misc_if associatedClock none
set_interface_property mac_misc_if associatedReset none
set_interface_property mac_misc_if ENABLED true
set_interface_property mac_misc_if EXPORT_OF ""
set_interface_property mac_misc_if PORT_NAME_MAP ""
set_interface_property mac_misc_if CMSIS_SVD_VARIABLES ""
set_interface_property mac_misc_if SVD_ADDRESS_GROUP ""
set_interface_property mac_misc_if IPXACT_REGISTER_MAP_VARIABLES ""

add_interface_port mac_misc_if mac_tx_crc_fwd ff_tx_crc_fwd Output 1
add_interface_port mac_misc_if mac_tx_septy    ff_tx_septy   Input 1
add_interface_port mac_misc_if mac_tx_uflow    tx_ff_uflow   Input 1
add_interface_port mac_misc_if mac_tx_a_full   ff_tx_a_full  Input 1
add_interface_port mac_misc_if mac_tx_a_empty  ff_tx_a_empty Input 1
add_interface_port mac_misc_if mac_rx_err_stat rx_err_stat   Input 18
add_interface_port mac_misc_if mac_rx_frm_type rx_frm_type   Input 4
add_interface_port mac_misc_if mac_rx_dsav     ff_rx_dsav    Input 1
add_interface_port mac_misc_if mac_rx_a_full   ff_rx_a_full  Input 1
add_interface_port mac_misc_if mac_rx_a_empty  ff_rx_a_empty Input 1


# -----------------------------------------------------------------------------
# Port - MAC Status interface (conduit)
# -----------------------------------------------------------------------------
add_interface mac_sts_if conduit end
set_interface_property mac_sts_if associatedClock none
set_interface_property mac_sts_if associatedReset none
set_interface_property mac_sts_if ENABLED true
set_interface_property mac_sts_if EXPORT_OF ""
set_interface_property mac_sts_if PORT_NAME_MAP ""
set_interface_property mac_sts_if CMSIS_SVD_VARIABLES ""
set_interface_property mac_sts_if SVD_ADDRESS_GROUP ""
set_interface_property mac_sts_if IPXACT_REGISTER_MAP_VARIABLES ""

add_interface_port mac_sts_if mac_set_10   set_10   Output 1
add_interface_port mac_sts_if mac_set_1000 set_1000 Output 1
add_interface_port mac_sts_if mac_eth_mode eth_mode Input 1
add_interface_port mac_sts_if mac_ena_10   ena_10   Input 1


# -----------------------------------------------------------------------------
# Port - PMCI-Nios AvMM Slave
# -----------------------------------------------------------------------------
add_interface nios_avmm_slv avalon end
set_interface_property nios_avmm_slv addressUnits WORDS
set_interface_property nios_avmm_slv associatedClock clock
set_interface_property nios_avmm_slv associatedReset reset
set_interface_property nios_avmm_slv bitsPerSymbol 8
set_interface_property nios_avmm_slv burstOnBurstBoundariesOnly false
set_interface_property nios_avmm_slv burstcountUnits WORDS
set_interface_property nios_avmm_slv explicitAddressSpan 0
set_interface_property nios_avmm_slv holdTime 0
set_interface_property nios_avmm_slv linewrapBursts false
set_interface_property nios_avmm_slv maximumPendingReadTransactions 1
set_interface_property nios_avmm_slv maximumPendingWriteTransactions 0
set_interface_property nios_avmm_slv readLatency 0
set_interface_property nios_avmm_slv readWaitTime 1
set_interface_property nios_avmm_slv setupTime 0
set_interface_property nios_avmm_slv timingUnits Cycles
set_interface_property nios_avmm_slv writeWaitTime 0
set_interface_property nios_avmm_slv ENABLED true
set_interface_property nios_avmm_slv EXPORT_OF ""
set_interface_property nios_avmm_slv PORT_NAME_MAP ""
set_interface_property nios_avmm_slv CMSIS_SVD_VARIABLES ""
set_interface_property nios_avmm_slv SVD_ADDRESS_GROUP ""

add_interface_port nios_avmm_slv nios_avmm_s_write write Input 1
add_interface_port nios_avmm_slv nios_avmm_s_read read Input 1
add_interface_port nios_avmm_slv nios_avmm_s_addr address Input 11
add_interface_port nios_avmm_slv nios_avmm_s_rddata readdata Output 32
add_interface_port nios_avmm_slv nios_avmm_s_rddvld readdatavalid Output 1
add_interface_port nios_avmm_slv nios_avmm_s_waitreq waitrequest Output 1
add_interface_port nios_avmm_slv nios_avmm_s_wrdata writedata Input 32
#add_interface_port nios_avmm_slv nios_avmm_s_byteen byteenable Input 4


# -----------------------------------------------------------------------------
# Port - OFS-SW AvMM Slave
# -----------------------------------------------------------------------------
add_interface ofs_avmm_slv avalon end
set_interface_property ofs_avmm_slv addressUnits WORDS
set_interface_property ofs_avmm_slv associatedClock clock
set_interface_property ofs_avmm_slv associatedReset reset
set_interface_property ofs_avmm_slv bitsPerSymbol 8
set_interface_property ofs_avmm_slv burstOnBurstBoundariesOnly false
set_interface_property ofs_avmm_slv burstcountUnits WORDS
set_interface_property ofs_avmm_slv explicitAddressSpan 0
set_interface_property ofs_avmm_slv holdTime 0
set_interface_property ofs_avmm_slv linewrapBursts false
set_interface_property ofs_avmm_slv maximumPendingReadTransactions 1
set_interface_property ofs_avmm_slv maximumPendingWriteTransactions 0
set_interface_property ofs_avmm_slv readLatency 0
set_interface_property ofs_avmm_slv readWaitTime 1
set_interface_property ofs_avmm_slv setupTime 0
set_interface_property ofs_avmm_slv timingUnits Cycles
set_interface_property ofs_avmm_slv writeWaitTime 0
set_interface_property ofs_avmm_slv ENABLED true
set_interface_property ofs_avmm_slv EXPORT_OF ""
set_interface_property ofs_avmm_slv PORT_NAME_MAP ""
set_interface_property ofs_avmm_slv CMSIS_SVD_VARIABLES ""
set_interface_property ofs_avmm_slv SVD_ADDRESS_GROUP ""

add_interface_port ofs_avmm_slv ofs_avmm_s_write write Input 1
add_interface_port ofs_avmm_slv ofs_avmm_s_read read Input 1
add_interface_port ofs_avmm_slv ofs_avmm_s_addr address Input 9
add_interface_port ofs_avmm_slv ofs_avmm_s_rddata readdata Output 64
add_interface_port ofs_avmm_slv ofs_avmm_s_rddvld readdatavalid Output 1
add_interface_port ofs_avmm_slv ofs_avmm_s_waitreq waitrequest Output 1
add_interface_port ofs_avmm_slv ofs_avmm_s_wrdata writedata Input 64
add_interface_port ofs_avmm_slv ofs_avmm_s_byteen byteenable Input 8


# -----------------------------------------------------------------------------
# Port - Ingress Passthrough AvMM Slave
# -----------------------------------------------------------------------------
add_interface ipt_avmm_slv avalon end
set_interface_property ipt_avmm_slv addressUnits WORDS
set_interface_property ipt_avmm_slv associatedClock clock
set_interface_property ipt_avmm_slv associatedReset reset
set_interface_property ipt_avmm_slv bitsPerSymbol 8
set_interface_property ipt_avmm_slv burstOnBurstBoundariesOnly false
set_interface_property ipt_avmm_slv burstcountUnits WORDS
set_interface_property ipt_avmm_slv explicitAddressSpan 0
set_interface_property ipt_avmm_slv holdTime 0
set_interface_property ipt_avmm_slv linewrapBursts false
set_interface_property ipt_avmm_slv maximumPendingReadTransactions 1
set_interface_property ipt_avmm_slv maximumPendingWriteTransactions 0
set_interface_property ipt_avmm_slv readLatency 0
set_interface_property ipt_avmm_slv readWaitTime 1
set_interface_property ipt_avmm_slv setupTime 0
set_interface_property ipt_avmm_slv timingUnits Cycles
set_interface_property ipt_avmm_slv writeWaitTime 0
set_interface_property ipt_avmm_slv ENABLED true
set_interface_property ipt_avmm_slv EXPORT_OF ""
set_interface_property ipt_avmm_slv PORT_NAME_MAP ""
set_interface_property ipt_avmm_slv CMSIS_SVD_VARIABLES ""
set_interface_property ipt_avmm_slv SVD_ADDRESS_GROUP ""

add_interface_port ipt_avmm_slv ipt_avmm_s_write write Input 1
add_interface_port ipt_avmm_slv ipt_avmm_s_read read Input 1
add_interface_port ipt_avmm_slv ipt_avmm_s_addr address Input 1
add_interface_port ipt_avmm_slv ipt_avmm_s_rddata readdata Output 64
add_interface_port ipt_avmm_slv ipt_avmm_s_rddvld readdatavalid Output 1
add_interface_port ipt_avmm_slv ipt_avmm_s_waitreq waitrequest Output 1
add_interface_port ipt_avmm_slv ipt_avmm_s_wrdata writedata Input 64
add_interface_port ipt_avmm_slv ipt_avmm_s_byteen byteenable Input 8


# -----------------------------------------------------------------------------
# Port - Egress Passthrough AvMM master
# -----------------------------------------------------------------------------
add_interface ept_avmm_mstr avalon start
set_interface_property ept_avmm_mstr addressGroup 0
set_interface_property ept_avmm_mstr addressUnits SYMBOLS
set_interface_property ept_avmm_mstr associatedClock clock
set_interface_property ept_avmm_mstr associatedReset reset
set_interface_property ept_avmm_mstr bitsPerSymbol 8
set_interface_property ept_avmm_mstr burstOnBurstBoundariesOnly false
set_interface_property ept_avmm_mstr burstcountUnits WORDS
set_interface_property ept_avmm_mstr doStreamReads false
set_interface_property ept_avmm_mstr doStreamWrites false
set_interface_property ept_avmm_mstr holdTime 0
set_interface_property ept_avmm_mstr linewrapBursts false
set_interface_property ept_avmm_mstr maximumPendingReadTransactions 0
set_interface_property ept_avmm_mstr maximumPendingWriteTransactions 0
set_interface_property ept_avmm_mstr minimumResponseLatency 1
set_interface_property ept_avmm_mstr readLatency 0
set_interface_property ept_avmm_mstr readWaitTime 1
set_interface_property ept_avmm_mstr setupTime 0
set_interface_property ept_avmm_mstr timingUnits Cycles
set_interface_property ept_avmm_mstr waitrequestAllowance 0
set_interface_property ept_avmm_mstr writeWaitTime 0
set_interface_property ept_avmm_mstr ENABLED true
set_interface_property ept_avmm_mstr EXPORT_OF ""
set_interface_property ept_avmm_mstr PORT_NAME_MAP ""
set_interface_property ept_avmm_mstr CMSIS_SVD_VARIABLES ""
set_interface_property ept_avmm_mstr SVD_ADDRESS_GROUP ""
set_interface_property ept_avmm_mstr IPXACT_REGISTER_MAP_VARIABLES ""

add_interface_port ept_avmm_mstr ept_avmm_m_addr address Output -1
add_interface_port ept_avmm_mstr ept_avmm_m_write write Output 1
add_interface_port ept_avmm_mstr ept_avmm_m_read read Output 1
add_interface_port ept_avmm_mstr ept_avmm_m_wrdata writedata Output 64
add_interface_port ept_avmm_mstr ept_avmm_m_byteen byteenable Output 8
add_interface_port ept_avmm_mstr ept_avmm_m_rddata readdata Input 64
add_interface_port ept_avmm_mstr ept_avmm_m_rddvld readdatavalid Input 1
add_interface_port ept_avmm_mstr ept_avmm_m_waitreq waitrequest Input 1


# -----------------------------------------------------------------------------
# Port - Command Rx Interrupt Sender 
# -----------------------------------------------------------------------------
add_interface ncsi_intr interrupt sender
set_interface_property ncsi_intr associatedAddressablePoint {nios_avmm_slv}                   
set_interface_property ncsi_intr associatedClock {clock}                             
set_interface_property ncsi_intr associatedReset {reset}                           
set_interface_property ncsi_intr irqScheme {NONE}                                  

add_interface_port ncsi_intr ncsi_intr irq Output 1 
# 
# # -----------------------------------------------------------------------------
# # Port - Command Rx Interrupt Sender 
# # -----------------------------------------------------------------------------
# add_interface ncsi_t5_intr interrupt sender
# set_interface_property ncsi_t5_intr associatedAddressablePoint {nios_avmm_slv}                   
# set_interface_property ncsi_t5_intr associatedClock {clock}                             
# set_interface_property ncsi_t5_intr associatedReset {reset}                           
# set_interface_property ncsi_t5_intr irqScheme {NONE}                                  
# 
# add_interface_port ncsi_t5_intr ncsi_t5_intr irq Output 1 
# 
# # -----------------------------------------------------------------------------
# # Port - Command Rx Interrupt Sender 
# # -----------------------------------------------------------------------------
# add_interface ncsi_t6_intr interrupt sender
# set_interface_property ncsi_t6_intr associatedAddressablePoint {nios_avmm_slv}                   
# set_interface_property ncsi_t6_intr associatedClock {clock}                             
# set_interface_property ncsi_t6_intr associatedReset {reset}                           
# set_interface_property ncsi_t6_intr irqScheme {NONE}                                  
# 
# add_interface_port ncsi_t6_intr ncsi_t6_intr irq Output 1 

# # -----------------------------------------------------------------------------
# # Port - Command Rx Interrupt Sender 
# # -----------------------------------------------------------------------------
# #add_interface ncsi_rx_intr interrupt end
# add_interface ncsi_intr interrupt s
# set_interface_property ncsi_intr associatedClock clock
# set_interface_property ncsi_intr associatedReset reset
# set_interface_property ncsi_intr bridgedReceiverOffset ""
# set_interface_property ncsi_intr bridgesToReceiver ""
# set_interface_property ncsi_intr ENABLED true
# set_interface_property ncsi_intr EXPORT_OF ""
# set_interface_property ncsi_intr PORT_NAME_MAP ""
# set_interface_property ncsi_intr CMSIS_SVD_VARIABLES ""
# set_interface_property ncsi_intr SVD_ADDRESS_GROUP ""
# set_interface_property ncsi_intr IPXACT_REGISTER_MAP_VARIABLES ""
# 
# # add_interface_port ncsi_rx_intr ncsi_rx_intr irq Output 1
# add_interface_port ncsi_intr ncsi_intr irq Output 1


# # -----------------------------------------------------------------------------
# # Port - T5 Expire Interrupt Sender
# # -----------------------------------------------------------------------------
# add_interface ncsi_t5_intr interrupt end
# set_interface_property ncsi_t5_intr associatedClock clock
# set_interface_property ncsi_t5_intr associatedReset reset
# set_interface_property ncsi_t5_intr bridgedReceiverOffset ""
# set_interface_property ncsi_t5_intr bridgesToReceiver ""
# set_interface_property ncsi_t5_intr ENABLED true
# set_interface_property ncsi_t5_intr EXPORT_OF ""
# set_interface_property ncsi_t5_intr PORT_NAME_MAP ""
# set_interface_property ncsi_t5_intr CMSIS_SVD_VARIABLES ""
# set_interface_property ncsi_t5_intr SVD_ADDRESS_GROUP ""
# set_interface_property ncsi_t5_intr IPXACT_REGISTER_MAP_VARIABLES ""
# 
# add_interface_port ncsi_t5_intr ncsi_t5_intr irq Output 1
# 
# 
# # -----------------------------------------------------------------------------
# # Port - T6 Expire Interrupt Sender
# # -----------------------------------------------------------------------------
# add_interface ncsi_t6_intr interrupt end
# set_interface_property ncsi_t6_intr associatedClock clock
# set_interface_property ncsi_t6_intr associatedReset reset
# set_interface_property ncsi_t6_intr bridgedReceiverOffset ""
# set_interface_property ncsi_t6_intr bridgesToReceiver ""
# set_interface_property ncsi_t6_intr ENABLED true
# set_interface_property ncsi_t6_intr EXPORT_OF ""
# set_interface_property ncsi_t6_intr PORT_NAME_MAP ""
# set_interface_property ncsi_t6_intr CMSIS_SVD_VARIABLES ""
# set_interface_property ncsi_t6_intr SVD_ADDRESS_GROUP ""
# set_interface_property ncsi_t6_intr IPXACT_REGISTER_MAP_VARIABLES ""
# 
# add_interface_port ncsi_t6_intr ncsi_t6_intr irq Output 1


# -----------------------------------------------------------------------------
# Validate IP
# -----------------------------------------------------------------------------
proc ip_validate { } {

}

# -----------------------------------------------------------------------------
# Elaborate IP
# -----------------------------------------------------------------------------
proc ip_elaborate { } {
   
   set ept_awidth [ get_parameter_value SS_ADDR_WIDTH ]
   set_port_property ept_avmm_m_addr width_expr $ept_awidth
   
  #add_hdl_instance rmii intel_fpga_mii2rmii 1.0.0
}