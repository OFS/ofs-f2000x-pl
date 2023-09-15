# Copyright 2023 Intel Corporation
# SPDX-License-Identifier: MIT

DEFINES="+define+SIM_MODE \
 +define+SIM_MODE_SOC \
 +define+INCLUDE_DDR4 \
 +define+VCD_ON \
 +define+SIM_USE_PCIE_GEN3X16_BFM \
 +define+SIM_PCIE_CPL_TIMEOUT \
 +define+SIM_PCIE_CPL_TIMEOUT_CYCLES=26'd12500000 \
 +define+BASE_AFU=dummy_afu \
 +define+RP_MAX_TAGS=64"

if [ $MSIM -eq 1 ] ; then
 DEFINES="+define+SIM_MODE \
 +define+SIM_MODE_SOC \
 +define+INCLUDE_DDR4 \
 +define+VCD_ON \
 +define+SIM_USE_PCIE_GEN3X16_BFM \
 +define+SIM_PCIE_CPL_TIMEOUT \
 +define+SIM_PCIE_CPL_TIMEOUT_CYCLES=26'd12500000 \
 +define+BASE_AFU=dummy_afu \
 +define+RP_MAX_TAGS=64 \
 +define+SIM_USE_PCIE_DUMMY_CSR"
fi

MSIM_OPTS=(-c top_tb -suppress 7033,12023,3053,2732 -voptargs="-access=rw+/. -designfile design_2.bin -debug +initreg+0+top_tb/DUT. +initwire+0 +noinitreg+top_tb/DUT/mem_ss_top." -qwavedb=+signal -do "add log -r /* ; run -all; quit -f")

VLOG_SUPPRESS="8386,7033,7061,2388,2732"

SV_OPTS="+initreg+0+top_tb/DUT. +initwire+0 +noinitreg+top_tb/DUT/mem_ss_top."

