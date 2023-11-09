# Copyright (C) 2023 Intel Corporation
# SPDX-License-Identifier: MIT

#-----------------------------------------------------------------------------
# Description
#-----------------------------------------------------------------------------
#
# Pin and location assignments
#
#-----------------------------------------------------------------------------

# Clock
set_location_assignment PIN_GC23 -to SYS_REFCLK 
set_location_assignment PIN_GE22 -to "SYS_REFCLK(n)"
set_instance_assignment -name IO_STANDARD "TRUE DIFFERENTIAL SIGNALING" -to SYS_REFCLK -entity top
set_instance_assignment -name INPUT_TERMINATION DIFFERENTIAL -to SYS_REFCLK


set_location_assignment PIN_CE18 -to qsfp_ref_clk
set_location_assignment PIN_CA18 -to "qsfp_ref_clk(n)"

set_instance_assignment -name IO_STANDARD    "DIFFERENTIAL LVPECL"                           -to qsfp_ref_clk
set_instance_assignment -name HSSI_PARAMETER "refclk_divider_enable_termination=enable_term" -to qsfp_ref_clk
set_instance_assignment -name HSSI_PARAMETER "refclk_divider_enable_3p3v=disable_3p3v_tol"   -to qsfp_ref_clk
set_instance_assignment -name HSSI_PARAMETER "refclk_divider_disable_hysteresis=enable_hyst" -to qsfp_ref_clk
set_instance_assignment -name HSSI_PARAMETER "refclk_divider_powerdown_mode=false"           -to qsfp_ref_clk
