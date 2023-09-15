# Copyright 2023 Intel Corporation
# SPDX-License-Identifier: MIT

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

MSIM_OPTS=(-c top_tb -suppress 7033,12023,3053,2732 -voptargs="-access=rw+/. -designfile design_2.bin -debug +initreg+0 +initwire+0" -qwavedb=+signal -do "add log -r /* ; run -all; quit -f")

VLOG_SUPPRESS="8386,7033,7061"

SV_OPTS="+initreg+0 +initwire+0"

NTB_OPTS="+define+VCS_ \
 +nbaopt \
 +delay_mode_zero"

CM_OPTIONS="-cm tgl+line+cond+fsm+branch -cm_dir simv.vdb -cm_hier cm_hier.file"

VCS_ERROR_COUNT="+error+10"

VCS_SIMV_PARAMS="$SIM_OPTIONS $USER_DEFINED_SIM_OPTIONS -cm tgl+line+cond+fsm+branch -cm_name $TEST_NAME -cm_hier cm_hier.file -cm_test pmci -cm_dir ../../../regression.vdb -l transcript"