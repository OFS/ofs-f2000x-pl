# Copyright 2023 Intel Corporation
# SPDX-License-Identifier: MIT

if [ $MSIM -eq 1 ] ; then
 DEFINES="+define+SIM_MODE \
 +define+SIM_MODE_SOC \
 +define+VCD_ON \
 +define+SIM_USE_PCIE_GEN3X16_BFM \
 +define+SIM_PCIE_CPL_TIMEOUT \
 +define+SIM_PCIE_CPL_TIMEOUT_CYCLES=26'd12500000 \
 +define+BASE_AFU=dummy_afu \
 +define+RP_MAX_TAGS=64 \
 +define+INCLUDE_DDR4 \
 +define+INCLUDE_MEM_TG \
 +define+SIM_MODE_NO_MSS_RST \
 +define+SIM_TIMEOUT=64'd10000000000"
elif [ $VCSMX -eq 1 ] ; then
 DEFINES="+define+SIM_MODE \
 +define+SIM_MODE_SOC \
 +define+VCD_ON \
 +define+SIM_USE_PCIE_GEN3X16_BFM \
 +define+SIM_PCIE_CPL_TIMEOUT \
 +define+SIM_PCIE_CPL_TIMEOUT_CYCLES=26'd12500000 \
 +define+BASE_AFU=dummy_afu \
 +define+RP_MAX_TAGS=64 \
 +define+INCLUDE_DDR4 \
 +define+SIM_MODE_NO_MSS_RST \
 +define+SIM_TIMEOUT=10000000000"
else
 DEFINES="+define+SIM_MODE \
 +define+SIM_MODE_SOC \
 +define+VCD_ON \
 +define+SIM_USE_PCIE_GEN3X16_BFM \
 +define+SIM_PCIE_CPL_TIMEOUT \
 +define+SIM_PCIE_CPL_TIMEOUT_CYCLES=26'd12500000 \
 +define+BASE_AFU=dummy_afu \
 +define+RP_MAX_TAGS=64 \
 +define+INCLUDE_DDR4 \
 +define+SIM_MODE_NO_MSS_RST \
 +define+SIM_TIMEOUT=10000000000"
fi
MSIM_OPTS=(-c top_tb -suppress 7033,12023,3053,2732 -voptargs="-access=rw+/. -designfile design_2.bin -debug +initreg+0+top_tb/DUT. +initwire+0 +noinitreg+top_tb/DUT/mem_ss_top." -qwavedb=+signal -do "add log -r /* ; run -all; quit -f")

VLOG_SUPPRESS="8386,7033,7061,2388,2732"

SV_OPTS="+initreg+0+top_tb/DUT. +initwire+0 +noinitreg+top_tb/DUT/mem_ss_top."

