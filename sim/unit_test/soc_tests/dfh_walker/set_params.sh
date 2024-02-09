# Copyright 2023 Intel Corporation
# SPDX-License-Identifier: MIT

DEFINES="+define+SIM_MODE \
 +define+VCD_ON \
 +define+SIM_MODE_SOC \
 +define+SIM_USE_PCIE_GEN3X16_BFM \
 +define+SIM_PCIE_CPL_TIMEOUT \
 +define+SIM_PCIE_CPL_TIMEOUT_CYCLES=26'd12500000 \
 +define+BASE_AFU=dummy_afu \
 +define+RP_MAX_TAGS=64"

MSIM_OPTS=(-c opt -suppress 7033,12023,3053,3053 -do "run -all ; quit -f")

VLOG_SUPPRESS="8386,7033,7061"

SV_OPTS="+initreg+0 +initwire+0"