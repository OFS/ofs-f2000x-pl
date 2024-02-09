# Copyright (C) 2020 Intel Corporation.
# SPDX-License-Identifier: MIT

#
# Description
#-----------------------------------------------------------------------------
#
# Pin and location assignments
#
#-----------------------------------------------------------------------------
# Host PCIe
set_location_assignment PIN_GA68 -to PCIE_RX_P[0]
set_location_assignment PIN_FW65 -to PCIE_RX_P[1]
set_location_assignment PIN_FN68 -to PCIE_RX_P[2]
set_location_assignment PIN_FL65 -to PCIE_RX_P[3]
set_location_assignment PIN_FE68 -to PCIE_RX_P[4]
set_location_assignment PIN_FC65 -to PCIE_RX_P[5]
set_location_assignment PIN_ET68 -to PCIE_RX_P[6]
set_location_assignment PIN_EP65 -to PCIE_RX_P[7]
set_location_assignment PIN_EH68 -to PCIE_RX_P[8]
set_location_assignment PIN_EF65 -to PCIE_RX_P[9]
set_location_assignment PIN_DY68 -to PCIE_RX_P[10]
set_location_assignment PIN_DV65 -to PCIE_RX_P[11]
set_location_assignment PIN_DL68 -to PCIE_RX_P[12]
set_location_assignment PIN_DJ65 -to PCIE_RX_P[13]
set_location_assignment PIN_DC68 -to PCIE_RX_P[14]
set_location_assignment PIN_DA65 -to PCIE_RX_P[15]

set_location_assignment PIN_GD69 -to PCIE_RX_N[0]
set_location_assignment PIN_FU66 -to PCIE_RX_N[1]
set_location_assignment PIN_FR69 -to PCIE_RX_N[2]
set_location_assignment PIN_FJ66 -to PCIE_RX_N[3]
set_location_assignment PIN_FG69 -to PCIE_RX_N[4]
set_location_assignment PIN_FA66 -to PCIE_RX_N[5]
set_location_assignment PIN_EV69 -to PCIE_RX_N[6]
set_location_assignment PIN_EM66 -to PCIE_RX_N[7]
set_location_assignment PIN_EK69 -to PCIE_RX_N[8]
set_location_assignment PIN_ED66 -to PCIE_RX_N[9]
set_location_assignment PIN_EB69 -to PCIE_RX_N[10]
set_location_assignment PIN_DT66 -to PCIE_RX_N[11]
set_location_assignment PIN_DN69 -to PCIE_RX_N[12]
set_location_assignment PIN_DG66 -to PCIE_RX_N[13]
set_location_assignment PIN_DE69 -to PCIE_RX_N[14]
set_location_assignment PIN_CW66 -to PCIE_RX_N[15]

set_location_assignment PIN_GA62 -to PCIE_TX_P[0]
set_location_assignment PIN_FW59 -to PCIE_TX_P[1]
set_location_assignment PIN_FN62 -to PCIE_TX_P[2]
set_location_assignment PIN_FL59 -to PCIE_TX_P[3]
set_location_assignment PIN_FE62 -to PCIE_TX_P[4]
set_location_assignment PIN_FC59 -to PCIE_TX_P[5]
set_location_assignment PIN_ET62 -to PCIE_TX_P[6]
set_location_assignment PIN_EP59 -to PCIE_TX_P[7]
set_location_assignment PIN_EH62 -to PCIE_TX_P[8]
set_location_assignment PIN_EF59 -to PCIE_TX_P[9]
set_location_assignment PIN_DY62 -to PCIE_TX_P[10]
set_location_assignment PIN_DV59 -to PCIE_TX_P[11]
set_location_assignment PIN_DL62 -to PCIE_TX_P[12]
set_location_assignment PIN_DJ59 -to PCIE_TX_P[13]
set_location_assignment PIN_DC62 -to PCIE_TX_P[14]
set_location_assignment PIN_DA59 -to PCIE_TX_P[15]

set_location_assignment PIN_GD63 -to PCIE_TX_N[0]
set_location_assignment PIN_FU60 -to PCIE_TX_N[1]
set_location_assignment PIN_FR63 -to PCIE_TX_N[2]
set_location_assignment PIN_FJ60 -to PCIE_TX_N[3]
set_location_assignment PIN_FG63 -to PCIE_TX_N[4]
set_location_assignment PIN_FA60 -to PCIE_TX_N[5]
set_location_assignment PIN_EV63 -to PCIE_TX_N[6]
set_location_assignment PIN_EM60 -to PCIE_TX_N[7]
set_location_assignment PIN_EK63 -to PCIE_TX_N[8]
set_location_assignment PIN_ED60 -to PCIE_TX_N[9]
set_location_assignment PIN_EB63 -to PCIE_TX_N[10]
set_location_assignment PIN_DT60 -to PCIE_TX_N[11]
set_location_assignment PIN_DN63 -to PCIE_TX_N[12]
set_location_assignment PIN_DG60 -to PCIE_TX_N[13]
set_location_assignment PIN_DE63 -to PCIE_TX_N[14]
set_location_assignment PIN_CW60 -to PCIE_TX_N[15]

set_instance_assignment -name IO_STANDARD "HIGH SPEED DIFFERENTIAL I/O" -to PCIE_RX_P
set_instance_assignment -name IO_STANDARD "HIGH SPEED DIFFERENTIAL I/O" -to PCIE_TX_P

set_location_assignment PIN_DF57 -to PCIE_REFCLK0
set_location_assignment PIN_DD56 -to "PCIE_REFCLK0(n)"

set_location_assignment PIN_CV57 -to PCIE_REFCLK1
set_location_assignment PIN_CT56 -to "PCIE_REFCLK1(n)"

set_location_assignment PIN_GJ56 -to PCIE_RESET_N

set_instance_assignment -name IO_STANDARD HCSL -to PCIE_REFCLK0
set_instance_assignment -name IO_STANDARD HCSL -to PCIE_REFCLK1
set_instance_assignment -name IO_STANDARD 1.8V -to PCIE_RESET_N

# SoC PCIe
set_location_assignment PIN_CR62 -to SOC_PCIE_TX_P[0]
set_location_assignment PIN_CN59 -to SOC_PCIE_TX_P[1]
set_location_assignment PIN_CF62 -to SOC_PCIE_TX_P[2]
set_location_assignment PIN_CD59 -to SOC_PCIE_TX_P[3]
set_location_assignment PIN_BV62 -to SOC_PCIE_TX_P[4]
set_location_assignment PIN_BT59 -to SOC_PCIE_TX_P[5]
set_location_assignment PIN_BK62 -to SOC_PCIE_TX_P[6]
set_location_assignment PIN_BH59 -to SOC_PCIE_TX_P[7]
set_location_assignment PIN_BA62 -to SOC_PCIE_TX_P[8]
set_location_assignment PIN_AW59 -to SOC_PCIE_TX_P[9]
set_location_assignment PIN_AN62 -to SOC_PCIE_TX_P[10]
set_location_assignment PIN_AL59 -to SOC_PCIE_TX_P[11]
set_location_assignment PIN_AE62 -to SOC_PCIE_TX_P[12]
set_location_assignment PIN_AB59 -to SOC_PCIE_TX_P[13]
set_location_assignment PIN_T62  -to SOC_PCIE_TX_P[14]
set_location_assignment PIN_P59  -to SOC_PCIE_TX_P[15]

set_location_assignment PIN_CU63 -to SOC_PCIE_TX_N[0]
set_location_assignment PIN_CK60 -to SOC_PCIE_TX_N[1]
set_location_assignment PIN_CH63 -to SOC_PCIE_TX_N[2]
set_location_assignment PIN_CB60 -to SOC_PCIE_TX_N[3]
set_location_assignment PIN_BY63 -to SOC_PCIE_TX_N[4]
set_location_assignment PIN_BP60 -to SOC_PCIE_TX_N[5]
set_location_assignment PIN_BM63 -to SOC_PCIE_TX_N[6]
set_location_assignment PIN_BE60 -to SOC_PCIE_TX_N[7]
set_location_assignment PIN_BC63 -to SOC_PCIE_TX_N[8]
set_location_assignment PIN_AU60 -to SOC_PCIE_TX_N[9]
set_location_assignment PIN_AR63 -to SOC_PCIE_TX_N[10]
set_location_assignment PIN_AJ60 -to SOC_PCIE_TX_N[11]
set_location_assignment PIN_AG63 -to SOC_PCIE_TX_N[12]
set_location_assignment PIN_Y60  -to SOC_PCIE_TX_N[13]
set_location_assignment PIN_V63  -to SOC_PCIE_TX_N[14]
set_location_assignment PIN_M60  -to SOC_PCIE_TX_N[15]

set_location_assignment PIN_CR68 -to SOC_PCIE_RX_P[0]
set_location_assignment PIN_CN65 -to SOC_PCIE_RX_P[1]
set_location_assignment PIN_CF68 -to SOC_PCIE_RX_P[2]
set_location_assignment PIN_CD65 -to SOC_PCIE_RX_P[3]
set_location_assignment PIN_BV68 -to SOC_PCIE_RX_P[4]
set_location_assignment PIN_BT65 -to SOC_PCIE_RX_P[5]
set_location_assignment PIN_BK68 -to SOC_PCIE_RX_P[6]
set_location_assignment PIN_BH65 -to SOC_PCIE_RX_P[7]
set_location_assignment PIN_BA68 -to SOC_PCIE_RX_P[8]
set_location_assignment PIN_AW65 -to SOC_PCIE_RX_P[9]
set_location_assignment PIN_AN68 -to SOC_PCIE_RX_P[10]
set_location_assignment PIN_AL65 -to SOC_PCIE_RX_P[11]
set_location_assignment PIN_AE68 -to SOC_PCIE_RX_P[12]
set_location_assignment PIN_AB65 -to SOC_PCIE_RX_P[13]
set_location_assignment PIN_T68  -to SOC_PCIE_RX_P[14]
set_location_assignment PIN_P65  -to SOC_PCIE_RX_P[15]

set_location_assignment PIN_CU69 -to SOC_PCIE_RX_N[0]
set_location_assignment PIN_CK66 -to SOC_PCIE_RX_N[1]
set_location_assignment PIN_CH69 -to SOC_PCIE_RX_N[2]
set_location_assignment PIN_CB66 -to SOC_PCIE_RX_N[3]
set_location_assignment PIN_BY69 -to SOC_PCIE_RX_N[4]
set_location_assignment PIN_BP66 -to SOC_PCIE_RX_N[5]
set_location_assignment PIN_BM69 -to SOC_PCIE_RX_N[6]
set_location_assignment PIN_BE66 -to SOC_PCIE_RX_N[7]
set_location_assignment PIN_BC69 -to SOC_PCIE_RX_N[8]
set_location_assignment PIN_AU66 -to SOC_PCIE_RX_N[9]
set_location_assignment PIN_AR69 -to SOC_PCIE_RX_N[10]
set_location_assignment PIN_AJ66 -to SOC_PCIE_RX_N[11]
set_location_assignment PIN_AG69 -to SOC_PCIE_RX_N[12]
set_location_assignment PIN_Y66  -to SOC_PCIE_RX_N[13]
set_location_assignment PIN_V69  -to SOC_PCIE_RX_N[14]
set_location_assignment PIN_M66  -to SOC_PCIE_RX_N[15]

set_instance_assignment -name IO_STANDARD "HIGH SPEED DIFFERENTIAL I/O" -to SOC_PCIE_RX_P
set_instance_assignment -name IO_STANDARD "HIGH SPEED DIFFERENTIAL I/O" -to SOC_PCIE_TX_P

set_location_assignment PIN_BG57 -to SOC_PCIE_REFCLK0
set_location_assignment PIN_BF56 -to "SOC_PCIE_REFCLK0(n)"

set_location_assignment PIN_AY57 -to SOC_PCIE_REFCLK1
set_location_assignment PIN_AV56 -to "SOC_PCIE_REFCLK1(n)"

set_location_assignment PIN_AY51 -to SOC_PCIE_RESET_N

set_instance_assignment -name IO_STANDARD HCSL -to SOC_PCIE_REFCLK0
set_instance_assignment -name IO_STANDARD HCSL -to SOC_PCIE_REFCLK1
set_instance_assignment -name IO_STANDARD 1.8V -to SOC_PCIE_RESET_N
