# Copyright (C) 2020 Intel Corporation.
# SPDX-License-Identifier: MIT

#

# Common files
set_global_assignment -name SYSTEMVERILOG_FILE $::env(BUILD_ROOT_REL)/ipss/mem/rtl/rst_hs.sv
set_global_assignment -name SYSTEMVERILOG_FILE $::env(BUILD_ROOT_REL)/ipss/mem/rtl/mem_ss_csr.sv
set_global_assignment -name SYSTEMVERILOG_FILE $::env(BUILD_ROOT_REL)/ipss/mem/rtl/ofs_fim_emif_axi_mm_if.sv

# Platform specific files
set_global_assignment -name SYSTEMVERILOG_FILE $::env(BUILD_ROOT_REL)/ipss/mem/rtl/mem_ss_pkg.sv
set_global_assignment -name SYSTEMVERILOG_FILE $::env(BUILD_ROOT_REL)/ipss/mem/rtl/ofs_fim_emif_if.sv
set_global_assignment -name SYSTEMVERILOG_FILE $::env(BUILD_ROOT_REL)/ipss/mem/rtl/mem_ss_top.sv


# MemSS IP
set_global_assignment -name IP_FILE ../ip_lib/ipss/mem/qip/mem_ss/mem_ss_fm.ip
# Used only in simulation. Loading it here adds ed_sim_mem to the simulation environment.
# It is not instantiated on HW.
set_global_assignment -name IP_FILE ../ip_lib/ipss/mem/qip/ed_sim/ed_sim_mem.ip
