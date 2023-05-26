# Copyright (C) 2020 Intel Corporation.
# SPDX-License-Identifier: MIT

#

SCRIPT_NAME=$BASH_SOURCE
SCRIPT_DIR="$(cd "$(dirname -- "$SCRIPT_NAME")" 2>/dev/null && pwd -P)"

BFM_DIR="$(readlink -f ${SCRIPT_DIR})/../../bfm/rp_bfm_simple"

BFM_SRC="+incdir+$BFM_DIR \
$BFM_DIR/test_utils.sv \
$BFM_DIR/test_pcie_utils.sv \
$BFM_DIR/ready_gen.sv \
$BFM_DIR/packet_sender.sv \
$BFM_DIR/packet_receiver.sv \
$BFM_DIR/shmem.sv \
$BFM_DIR/pcie_flr.sv \
$BFM_DIR/tester.sv \
$BFM_DIR/../cvl_bfm/avmm2axiLite_bridge.sv \
$BFM_DIR/../cvl_bfm/axi_lite_bfm.sv \
$BFM_DIR/../cvl_bfm/axis2avst_bridge.sv \
$BFM_DIR/../cvl_bfm/avst2axis_bridge.sv \
$BFM_DIR/../cvl_bfm/alt_ehipc3_fm_sl_ptp_chk.sv \
$BFM_DIR/../cvl_bfm/axis_bfm.sv \
$BFM_DIR/../cvl_bfm/cvl_bfm_serial.sv \
$BFM_DIR/top_tb.sv"

