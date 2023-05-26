# Copyright (C) 2020 Intel Corporation.
# SPDX-License-Identifier: MIT

#
# Description
#-----------------------------------------------------------------------------
#
#   Platform top level SDC 
#
#-----------------------------------------------------------------------------

set file_path [file normalize [info script]]
set file_dir [file dirname $file_path]

source $file_dir/top_sdc_util.tcl

#**************************************************************
# Time Information
#**************************************************************
set_time_format -unit ns -decimal_places 3

#**************************************************************
# Create Clock
#**************************************************************
derive_clock_uncertainty

create_clock -name SYS_REFCLK             -period  10.000 -waveform {0.000  5.000} [get_ports {SYS_REFCLK}]
create_clock -name PCIE_REFCLK0           -period  10.000 -waveform {0.000  5.000} [get_ports {PCIE_REFCLK0}]
create_clock -name PCIE_REFCLK1           -period  10.000 -waveform {0.000  5.000} [get_ports {PCIE_REFCLK1}]

create_clock -name SOC_PCIE_REFCLK0       -period  10.000 -waveform {0.000  5.000} [get_ports {SOC_PCIE_REFCLK0}]
create_clock -name SOC_PCIE_REFCLK1       -period  10.000 -waveform {0.000  5.000} [get_ports {SOC_PCIE_REFCLK1}]

create_clock -name {altera_reserved_tck}  -period 100.000 -waveform {0.000 50.000} [get_ports {altera_reserved_tck}]

#**************************************************************
# Create Generated Clock
#**************************************************************
create_generated_clock -add -name host_pcie|avmm_clock0 \
    -source      [get_pins -compatibility_mode "*host_pcie*\|*clkdiv_inst\|inclk"] \
    -divide_by 2 [get_pins -compatibility_mode "*host_pcie*\|*clkdiv_inst\|clock_div2"]

create_generated_clock -add -name soc_pcie|avmm_clock0 \
    -source      [get_pins -compatibility_mode "*soc_pcie*\|*clkdiv_inst\|inclk"] \
    -divide_by 2 [get_pins -compatibility_mode "*soc_pcie*\|*clkdiv_inst\|clock_div2"]

#**************************************************************
# Set Clock Groups
#**************************************************************
set_clock_groups -asynchronous -group {altera_reserved_tck}
set_clock_groups -asynchronous -group {sys_pll|iopll_0_clk_sys}

set_clock_groups -asynchronous -group {sys_pll|iopll_0_clk_sys}  -group {*|pcie_ss|gen_ptile.u_ptile|intel_pcie_ptile_ast_qhip|inst|inst|maib_and_tile|xcvr_hip_native|rx_ch15}
set_clock_groups -asynchronous -group {host_pcie|avmm_clock0}    -group {*|pcie_ss|gen_ptile.u_ptile|intel_pcie_ptile_ast_qhip|inst|inst|maib_and_tile|xcvr_hip_native|rx_ch15}
set_clock_groups -asynchronous -group {soc_pcie|avmm_clock0}     -group {*|pcie_ss|gen_ptile.u_ptile|intel_pcie_ptile_ast_qhip|inst|inst|maib_and_tile|xcvr_hip_native|rx_ch15}
set_clock_groups -asynchronous -group {sys_pll|iopll_0_clk_100m} -group {*|pcie_ss|gen_ptile.u_ptile|intel_pcie_ptile_ast_qhip|inst|inst|maib_and_tile|xcvr_hip_native|rx_ch15}

# temporary constraint while mem_tg is fixed to not instantiate dbg fabric
set_clock_groups -asynchronous -group {sys_pll|iopll_0_clk_100m} -group {mem_ss_top|mem_ss_fm_inst|mem_ss_fm_0|intf_0_core_usr_clk}


#**************************************************************
# Set Multicycle Path
#**************************************************************

#**************************************************************
# Set False Path
#**************************************************************
# Agilex M20K protection signal. Constraint missing in Quartus 23.1, can be
# removed in 23.2
set_false_path -from [get_keepers {soc_afu|port_gasket|pr_ctrl|pr_m20k_ce_state[1]}] -to soc_afu|port_gasket|pr_slot|afu_main*

#---------------------------------------------
# CDC constraints for reset synchronizers
#---------------------------------------------
add_reset_sync_sdc {*rst_ctrl|rst_clk100m_resync|resync_chains[0].synchronizer_nocut|*|clrn}	
add_reset_sync_sdc {*rst_ctrl|rst_clk50m_resync|resync_chains[0].synchronizer_nocut|*|clrn}	
add_reset_sync_sdc {*rst_ctrl|rst_clk_sys_resync|resync_chains[0].synchronizer_nocut|*|clrn}	
add_reset_sync_sdc {*rst_ctrl|pwr_good_n_resync|resync_chains[0].synchronizer_nocut|*|clrn}
add_reset_sync_sdc {*rst_ctrl|pwr_good_csr_clk_n_resync|resync_chains[0].synchronizer_nocut|*|clrn}
add_reset_sync_sdc {*rst_ctrl|rst_in_resync|resync_chains[0].synchronizer_nocut|*|clrn}
add_reset_sync_sdc {*rst_ctrl|rst_warm_in_resync|resync_chains[0].synchronizer_nocut*|*|clrn}
add_reset_sync_sdc {*rst_ctrl|rst_clk_ptp_slv_resync|resync_chains[0].synchronizer_nocut*|*|clrn}

add_reset_sync_sdc {*|pcie_bridge|pcie_bridge_cdc|rx_cdc|rx_avst_dcfifo|rst_rclk_resync|resync_chains[0].synchronizer_nocut|*|clrn}
add_reset_sync_sdc {*|pcie_bridge|pcie_bridge_cdc|rx_cdc|rx_avst_dcfifo|dcfifo|dcfifo_component|auto_generated|wraclr|*|clrn}
add_reset_sync_sdc {*|pcie_bridge|pcie_bridge_cdc|tx_cdc|tx_axis_dcfifo|rst_rclk_resync|resync_chains[0].synchronizer_nocut|*|clrn}
add_reset_sync_sdc {*|pcie_bridge|pcie_bridge_cdc|tx_cdc|tx_axis_dcfifo|dcfifo|dcfifo_component|auto_generated|rdaclr|*|clrn}
add_reset_sync_sdc {*|pcie_flr_resync|flr_req_fifo|rst_rclk_resync|resync_chains[0].synchronizer_nocut|*|clrn}
add_reset_sync_sdc {*|pcie_flr_resync|flr_req_fifo|dcfifo|dcfifo_component|auto_generated|rdaclr|*|clrn}
add_reset_sync_sdc {*|pcie_flr_resync|flr_rsp_fifo|rst_rclk_resync|resync_chains[0].synchronizer_nocut|*|clrn}
add_reset_sync_sdc {*|pcie_flr_resync|flr_rsp_fifo|dcfifo|dcfifo_component|auto_generated|wraclr|*|clrn}

add_reset_sync_sdc {afu_top|flr_rst_ctrl|*pf_flr_resync*|resync_chains[0].synchronizer_nocut|*|clrn}
add_reset_sync_sdc {afu_top|flr_rst_ctrl|*vf_flr_resync*|resync_chains[0].synchronizer_nocut|*|clrn}
add_reset_sync_sdc {*|st2mm|tx_cdc_fifo|fifo|rst_rclk_resync|resync_chains[0].synchronizer_nocut|*|clrn}
add_reset_sync_sdc {*|st2mm|tx_cdc_fifo|fifo|dcfifo|dcfifo_component|auto_generated|rdaclr|*|clrn}
add_reset_sync_sdc {*|st2mm|rx_cdc_fifo|fifo|rst_rclk_resync|resync_chains[0].synchronizer_nocut|*|clrn}
add_reset_sync_sdc {*|st2mm|rx_cdc_fifo|fifo|dcfifo|dcfifo_component|auto_generated|rdaclr|*|clrn}

add_reset_sync_sdc {afu_top|*|*he_hssi_top|GenRstSync[*].*_reset_synchronizer|resync_chains[*].*|*|clrn}
add_reset_sync_sdc {afu_top|*|*|*|he_hssi_top|GenRstSync[*].*_reset_synchronizer|resync_chains[*].*|*|clrn}
add_reset_sync_sdc {afu_top|fim_afu_instances|*GenCPR[*].cvl_data_sync|fifo|rst_rclk_resync|resync_chains[0].synchronizer_nocut|*|clrn}
add_reset_sync_sdc {afu_top|fim_afu_instances|*GenCPR[*].cvl_data_sync|fifo|dcfifo|dcfifo_component|auto_generated|rdaclr|*|clrn}
add_reset_sync_sdc {afu_top|*|*he_hssi_top|GenCPR[*].cvl_data_sync|fifo|rst_rclk_resync|resync_chains[0].synchronizer_nocut|*|clrn}
add_reset_sync_sdc {afu_top|*|*he_hssi_top|GenCPR[*].cvl_data_sync|fifo|dcfifo|dcfifo_component|auto_generated|rdaclr|*|clrn}
add_reset_sync_sdc {mem_ss_top|rst_hs_resync|resync_chains[*].*|*|clrn}

#---------------------------------------------
# CDC constraints for synchronizers
#---------------------------------------------
add_sync_sdc {pcie_wrapper|pcie_top|csr_resync|resync_chains[*].synchronizer_nocut|din_s1}
add_sync_sdc {rst_ctrl|pcie_cold_rst_ack_sync|resync_chains[*].synchronizer_nocut|din_s1}
add_sync_sdc {afu_top|flr_rst_ctrl|flr_ack_resync|resync_chains[*].synchronizer_nocut|din_s1}
add_sync_sdc {afu_top|flr_rst_ctrl|clr_ack_resync|resync_chains[*].synchronizer_nocut|din_s1}

add_sync_sdc {afu_top|he_hssi_top|*|resync_chains[*].synchronizer_nocut|din_s1}
add_sync_sdc {afu_top|*|*|*|he_hssi_top|*|resync_chains[*].synchronizer_nocut|din_s1}

add_sync_sdc {mem_ss_top|mem_ss_cal_success_resync|resync_chains[*].synchronizer_nocut|din_s1}
add_sync_sdc {mem_ss_top|mem_ss_cal_fail_resync|resync_chains[*].synchronizer_nocut|din_s1}

#---------------------------------------------
# Multicycle path 
#---------------------------------------------
   
#**************************************************************
# Set Input Delay
#**************************************************************

#**************************************************************
# Set Output Delay
#**************************************************************


