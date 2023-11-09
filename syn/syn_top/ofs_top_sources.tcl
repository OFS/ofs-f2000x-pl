# Copyright (C) 2022-2023 Intel Corporation
# SPDX-License-Identifier: MIT

############################################################################################
# OFS IP database
############################################################################################

# Load this first. The script manages a database of IP from which parameters will
# be extracted before synthesis. The parameters are written to header files in
# ofs_ip_cfg_db/.
set_global_assignment -name SOURCE_TCL_SCRIPT_FILE "$::env(BUILD_ROOT_REL)/ofs-common/scripts/common/syn/ip_get_cfg/ofs_ip_cfg_db.tcl"

# Add the constructed IP database to the search path. It will be populated
# by a hook at the end of ipgenerate
set_global_assignment -name SEARCH_PATH "ofs_ip_cfg_db"

############################################################################################
# Post-process the project between modules
############################################################################################
set_global_assignment -name POST_MODULE_SCRIPT_FILE "quartus_sh:$::env(BUILD_ROOT_REL)/syn/setup/post_module_hook.tcl"
# For the archiver to include required tcl packages
set_global_assignment -name SEARCH_PATH "$::env(BUILD_ROOT_REL)/ofs-common/scripts/common/syn/tcl_lib"

############################################################################################
# Design Files
############################################################################################
# Project and IP search paths
set_global_assignment -name SEARCH_PATH "$::env(BUILD_ROOT_REL)/src/includes"
set_global_assignment -name SEARCH_PATH "$::env(BUILD_ROOT_REL)/ipss"
set_global_assignment -name SEARCH_PATH "$::env(BUILD_ROOT_REL)/ofs-common/src/fpga_family/agilex/hssi_ss/inc"

set_global_assignment -name IP_SEARCH_PATHS "$::env(BUILD_ROOT_REL)/ipss/pmci/**/*"

# Packages
set_global_assignment -name SOURCE_TCL_SCRIPT_FILE $::env(BUILD_ROOT_REL)/syn/setup/afu_if_design_files.tcl

# Common files
set_global_assignment -name SOURCE_TCL_SCRIPT_FILE $::env(BUILD_ROOT_REL)/ofs-common/src/common/ofs_common_design_files.tcl
set_global_assignment -name SOURCE_TCL_SCRIPT_FILE $::env(BUILD_ROOT_REL)/ofs-common/src/fpga_family/agilex/ofs_common_agilex_design_files.tcl

# PR slot AFU
## Import a specific AFU
set_global_assignment -name SOURCE_TCL_SCRIPT_FILE $::env(BUILD_ROOT_REL)/ofs-common/src/fpga_family/agilex/afu_main.tcl


# Subsystems
set_global_assignment -name SOURCE_TCL_SCRIPT_FILE ../../ipss/pcie/pcie_ss_design_files.tcl
set_global_assignment -name SOURCE_TCL_SCRIPT_FILE ../../ipss/hssi/eth_design_files.tcl
set_global_assignment -name SOURCE_TCL_SCRIPT_FILE $::env(BUILD_ROOT_REL)/ofs-common/src/fpga_family/agilex/hssi_ss/hssi_wrapper_design_files.tcl
set_global_assignment -name SOURCE_TCL_SCRIPT_FILE ../setup/afu_design_files.tcl
set_global_assignment -name SOURCE_TCL_SCRIPT_FILE ../../src/pd_qsys/fabric/fabric_design_files.tcl
set_global_assignment -name SOURCE_TCL_SCRIPT_FILE ../../ipss/mem/mem_design_files.tcl
set_global_assignment -name SOURCE_TCL_SCRIPT_FILE ../../ipss/pmci/pmci_design_files.tcl

# TOP level
set_global_assignment -name SYSTEMVERILOG_FILE $::env(BUILD_ROOT_REL)/src/top/rst_ctrl.sv
set_global_assignment -name SYSTEMVERILOG_FILE $::env(BUILD_ROOT_REL)/src/top/top.sv

############################################################################################
# SDC Files
############################################################################################
set_global_assignment -name SDC_FILE ../setup/fim_dcfifo.sdc
set_global_assignment -name SDC_FILE ../setup/top.sdc
set_global_assignment -name SDC_FILE ../setup/eth_top.sdc
set_global_assignment -name SDC_FILE ../setup/pmci_top.sdc

# Generate timing reports during quartus_sta
set_global_assignment -name TIMING_ANALYZER_REPORT_SCRIPT $::env(BUILD_ROOT_REL)/ofs-common/scripts/common/syn/report_timing.tcl

############################################################################################
# Generate PR interface ID
############################################################################################
set_global_assignment -name MISC_FILE $::env(BUILD_ROOT_REL)/ofs-common/scripts/common/syn/update_fme_ifc_id.py

############################################################################################
# Assignments to suppress Quartus warnings that can be ignored
############################################################################################
set_global_assignment -name SOURCE_TCL_SCRIPT_FILE ../setup/suppress_warning.tcl

# ############################################################################################
# # PR assignments
# ############################################################################################
set_global_assignment -name SOURCE_TCL_SCRIPT_FILE ../setup/pr_assignments.tcl

############################################################################################
# Pins & Location Assignments
############################################################################################
set_global_assignment -name SOURCE_TCL_SCRIPT_FILE ../setup/top_loc.tcl
set_global_assignment -name SOURCE_TCL_SCRIPT_FILE ../setup/pcie_loc.tcl
set_global_assignment -name SOURCE_TCL_SCRIPT_FILE ../setup/emif_loc.tcl
set_global_assignment -name SOURCE_TCL_SCRIPT_FILE ../setup/pmci_loc.tcl
set_global_assignment -name SOURCE_TCL_SCRIPT_FILE ../setup/eth_loc.tcl

############################################################################################
# Global Signal Assignments
############################################################################################
set_instance_assignment -name GLOBAL_SIGNAL GLOBAL_CLOCK -to SYS_REFCLK -entity top
set_instance_assignment -name GLOBAL_SIGNAL OFF -to pcie_wrapper|pcie_ss_top|pcie_ss|pcie_ss|u_pciess_p0|gen_sub.u_hipif|u_pciess_tx_if|pciess_tx_alignment.tx_alignment_inst|coreclk_warm_rst_n|dreg[1]


############################################################################################
# Signaltap
############################################################################################
# set_global_assignment -name ENABLE_SIGNALTAP ON
# set_global_assignment -name USE_SIGNALTAP_FILE ofs_top.stp
# set_global_assignment -name SIGNALTAP_FILE ofs_top.stp
