## Copyright (C) 2023 Intel Corporation
## SPDX-License-Identifier: MIT

#--------------------
# AFU modules
#--------------------
set_global_assignment -name SYSTEMVERILOG_FILE $::env(BUILD_ROOT_REL)/src/includes/ofs_pcie_ss_plat_cfg_pkg.sv

#--------------------
# AFU Top
#--------------------
set_global_assignment -name SYSTEMVERILOG_FILE $::env(BUILD_ROOT_REL)/src/afu_top/dummy_csr.sv
set_global_assignment -name SYSTEMVERILOG_FILE $::env(BUILD_ROOT_REL)/src/afu_top/fim_afu_instances.sv
set_global_assignment -name SYSTEMVERILOG_FILE $::env(BUILD_ROOT_REL)/src/afu_top/afu_top.sv
set_global_assignment -name SYSTEMVERILOG_FILE $::env(BUILD_ROOT_REL)/src/afu_top/soc_afu_top.sv
set_global_assignment -name SYSTEMVERILOG_FILE $::env(BUILD_ROOT_REL)/src/afu_top/afu_host_channel.sv

#--------------------
# PF/VF Mux/Demux
#--------------------
set_global_assignment -name SYSTEMVERILOG_FILE $::env(BUILD_ROOT_REL)/src/afu_top/axis_demux.sv
set_global_assignment -name SYSTEMVERILOG_FILE $::env(BUILD_ROOT_REL)/src/afu_top/axis_mux.sv
set_global_assignment -name SYSTEMVERILOG_FILE $::env(BUILD_ROOT_REL)/src/afu_top/mux/top_cfg_pkg.sv
set_global_assignment -name SYSTEMVERILOG_FILE $::env(BUILD_ROOT_REL)/src/afu_top/mux/soc_top_cfg_pkg.sv


#--------------------
# Common sources
#--------------------
set_global_assignment -name SOURCE_TCL_SCRIPT_FILE $::env(BUILD_ROOT_REL)/ofs-common/src/common/mem_tg/mem_tg_design_files.tcl


#--------------------
# PR Gasket modules
#--------------------
# Synthetic timing constraints on user clock to achieve user-defined frequencies.
# *** This must follow the user clock IP. ***
set_global_assignment -name SDC_FILE $::env(BUILD_ROOT_REL)/syn/setup/setup_user_clock_for_pr.sdc

