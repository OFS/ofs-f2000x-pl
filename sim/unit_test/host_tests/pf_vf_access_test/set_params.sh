# Copyright 2023 Intel Corporation
# SPDX-License-Identifier: MIT

if [ $MSIM -eq 1 ]; then
    DEFINES="+define+SIM_MODE \
 +define+VCD_ON \
 +define+INCLUDE_MEM_TG \
 +define+SIM_USE_PCIE_GEN3X16_BFM \
 +define+SIM_PCIE_CPL_TIMEOUT \
 +define+SIM_PCIE_CPL_TIMEOUT_CYCLES=26'd12500000 \
 +define+BASE_AFU=dummy_afu \
 +define+RP_MAX_TAGS=64"
elif [ $VCSMX -eq 1 ] ; then
    DEFINES="+define+SIM_MODE \
    +define+VCD_ON \
    +define+SIM_USE_PCIE_GEN3X16_BFM \
    +define+SIM_PCIE_CPL_TIMEOUT \
    +define+SIM_PCIE_CPL_TIMEOUT_CYCLES=26'd12500000 \
    +define+BASE_AFU=dummy_afu \
    +define+RP_MAX_TAGS=64"
else #VCS
    DEFINES="+define+SIM_MODE \
    +define+VCD_ON \
    +define+SIM_USE_PCIE_GEN3X16_BFM \
    +define+SIM_PCIE_CPL_TIMEOUT \
    +define+SIM_PCIE_CPL_TIMEOUT_CYCLES=26'd12500000 \
    +define+BASE_AFU=dummy_afu \
    +define+RP_MAX_TAGS=64"
fi

VLOG_SUPPRESS="8386,7033,7061,7041"

SV_OPTS="+initreg+0 +initwire+0"

MSIM_OPTS=(-c opt -suppress 7033,12023,3053,3053 -do "run -all ; quit -f")