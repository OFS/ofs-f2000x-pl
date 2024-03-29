# Copyright 2023 Intel Corporation
# SPDX-License-Identifier: MIT

if [ $MSIM -eq 1 ]; then
    DEFINES="+define+SIM_MODE \
 +define+INCLUDE_PMCI \
 +define+BMC_EN \
 +define+VCD_ON \
 +define+SIM_USE_PCIE_GEN3X16_BFM \
 +define+SIM_PCIE_CPL_TIMEOUT \
 +define+SIM_PCIE_CPL_TIMEOUT_CYCLES=26'd12500000 \
 +define+BASE_AFU=dummy_afu \
 +define+RP_MAX_TAGS=64 \
 +define+SIM_USE_PCIE_DUMMY_CSR \
 +define+SIM_USE_PCIE_DUMMY_CSR"
elif [ $VCSMX -eq 1 ] ; then
    DEFINES="+define+SIM_MODE \
 +define+INCLUDE_PMCI \
 +define+BMC_EN \
 +define+VCD_ON \
 +define+SIM_USE_PCIE_GEN3X16_BFM \
 +define+SIM_PCIE_CPL_TIMEOUT \
 +define+SIM_PCIE_CPL_TIMEOUT_CYCLES=26'd12500000 \
 +define+BASE_AFU=dummy_afu \
 +define+RP_MAX_TAGS=64 \
 +define+SIM_USE_PCIE_DUMMY_CSR"
else #VCS
    DEFINES="+define+SIM_MODE \
 +define+INCLUDE_PMCI \
 +define+BMC_EN \
 +define+VCD_ON \
 +define+SIM_USE_PCIE_GEN3X16_BFM \
 +define+SIM_PCIE_CPL_TIMEOUT \
 +define+SIM_PCIE_CPL_TIMEOUT_CYCLES=26'd12500000 \
 +define+BASE_AFU=dummy_afu \
 +define+RP_MAX_TAGS=64 \
 +define+SIM_USE_PCIE_DUMMY_CSR"
fi

# MSIM
MSIM_OPTS=(-c opt -suppress 7033,12023,3053,2732 -do "run -all ; quit -f")

VLOG_SUPPRESS="8386,7033,7061,2732"

SV_OPTS="+initreg+0 +initwire+0"

# VCS
NTB_OPTS="+define+VCS_ \
 +nbaopt \
 +delay_mode_zero"

CM_OPTIONS="-cm tgl+line+cond+fsm+branch -cm_dir simv.vdb -cm_hier cm_hier.file"

VCS_SIMV_PARAMS="$SIM_OPTIONS $USER_DEFINED_SIM_OPTIONS -cm tgl+line+cond+fsm+branch -cm_name $TEST_NAME -cm_hier cm_hier.file -cm_test pmci -cm_dir ../../../regression.vdb -l transcript"