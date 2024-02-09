# Copyright (C) 2020 Intel Corporation.
# SPDX-License-Identifier: MIT


#-----------------------------------------------------------------------------
# Description
#-----------------------------------------------------------------------------
#
#   PMCI Controller SDC 
#
#-----------------------------------------------------------------------------
set file_path [file normalize [info script]]
set file_dir [file dirname $file_path]

source $file_dir/top_sdc_util.tcl

#**************************************************************
# Create Clock
#**************************************************************
create_clock -name spi_egress_sclk -period 40 -waveform {0.000 20} [get_ports {spi_egress_sclk}]

# NCSI RBT clock (50 MHz)
create_clock -name ncsi_rbt_ncsi_clk  -period 20.000 [get_ports ncsi_rbt_ncsi_clk]

set PMCI_CLK sys_pll|iopll_0_clk_100m

set_clock_groups -asynchronous -group {sys_pll|iopll_0_clk_100m} -group {spi_egress_sclk}
set_clock_groups -asynchronous -group {ncsi_rbt_ncsi_clk}

#**************************************************************
# Egress SPI
#**************************************************************
set_input_delay  -max 6  -clock { spi_egress_sclk }              [get_ports {spi_egress_csn}]
set_input_delay  -min 0  -clock { spi_egress_sclk }              [get_ports {spi_egress_csn}]
set_input_delay  -max 12 -clock { spi_egress_sclk }              [get_ports {spi_egress_mosi}]
set_input_delay  -min 0  -clock { spi_egress_sclk }              [get_ports {spi_egress_mosi}]
set_output_delay -max 8  -clock { spi_egress_sclk }  -clock_fall [get_ports {spi_egress_miso}]
set_output_delay -min 0  -clock { spi_egress_sclk }  -clock_fall [get_ports {spi_egress_miso}]

set_false_path -from [get_ports {spi_egress_csn}] -to [get_ports {spi_egress_miso}]

# Fix broken constraint for async path from spiphyslave.sdc
set_false_path -to [get_pins -no_case -compatibility_mode *SPIPhy_MISOctl\|rdshiftreg*\|*]

# Reset sync constraint for spi_csn->MISO st ready
add_reset_sync_sdc {*|SPIPhy_MISOctl|*stsinkready*|clrn}

#**************************************************************
# Ingress SPI
#**************************************************************
create_generated_clock \
 -source [get_pins {pmci_wrapper|pmci_ss|spi_master|avmms_2_spim_bridge_0|spim_clk|clk}] \
 -divide_by 4 -multiply_by 1 -duty_cycle 50 -phase 0 -offset 0 \
 -name ingrs_spi_clk_int [get_pins {pmci_wrapper|pmci_ss|spi_master|avmms_2_spim_bridge_0|spim_clk|q}]

create_generated_clock \
 -source [get_pins {pmci_wrapper|pmci_ss|spi_master|avmms_2_spim_bridge_0|spim_clk|q}] \
 -name ingrs_spi_clk [get_ports {spi_ingress_sclk}]

set_multicycle_path 2 -setup -start -from $PMCI_CLK -to ingrs_spi_clk
set_multicycle_path 2 -setup -end -from ingrs_spi_clk -to $PMCI_CLK

set_multicycle_path 3 -hold -start -from $PMCI_CLK -to ingrs_spi_clk
set_multicycle_path 3 -hold -end -from ingrs_spi_clk -to $PMCI_CLK

set_output_delay -max 15 -clock [get_clocks ingrs_spi_clk] -clock_fall [get_ports {spi_ingress_csn}]
set_output_delay -min 0  -clock [get_clocks ingrs_spi_clk] -clock_fall [get_ports {spi_ingress_csn}]
set_output_delay -max 15 -clock [get_clocks ingrs_spi_clk] -clock_fall [get_ports {spi_ingress_mosi}]
set_output_delay -min 0  -clock [get_clocks ingrs_spi_clk] -clock_fall [get_ports {spi_ingress_mosi}]
set_input_delay  -max 7  -clock [get_clocks ingrs_spi_clk]             [get_ports {spi_ingress_miso}]
set_input_delay  -min 0  -clock [get_clocks ingrs_spi_clk]             [get_ports {spi_ingress_miso}]


#**************************************************************
# Flash QSPI
#**************************************************************
create_generated_clock \
 -source [get_pins {pmci_wrapper|pmci_ss|flash_ctrlr|intel_generic_serial_flash_interface_top_0|qspi_inf_inst|flash_clk_reg|clk}] \
 -divide_by 6 -multiply_by 1 -duty_cycle 50 -phase 0 -offset 0 \
 -name flash_qspi_clk_int [get_pins {pmci_wrapper|pmci_ss|flash_ctrlr|intel_generic_serial_flash_interface_top_0|qspi_inf_inst|flash_clk_reg|q}]

create_generated_clock \
 -source [get_pins {pmci_wrapper|pmci_ss|flash_ctrlr|intel_generic_serial_flash_interface_top_0|qspi_inf_inst|flash_clk_reg|q}] \
 -name flash_qspi_clk [get_ports {qspi_dclk}]

set_multicycle_path 3 -setup -start -from $PMCI_CLK -to flash_qspi_clk
set_multicycle_path 3 -setup -end -from flash_qspi_clk -to $PMCI_CLK

set_multicycle_path 5 -hold -start -from $PMCI_CLK -to flash_qspi_clk
set_multicycle_path 5 -hold -end -from flash_qspi_clk -to $PMCI_CLK

set_output_delay -max 25 -clock [get_clocks flash_qspi_clk]             [get_ports {qspi_ncs}]
set_output_delay -min 0  -clock [get_clocks flash_qspi_clk]             [get_ports {qspi_ncs}]
set_output_delay -max 25 -clock [get_clocks flash_qspi_clk]             [get_ports {qspi_data[*]}]
set_output_delay -min 0  -clock [get_clocks flash_qspi_clk]             [get_ports {qspi_data[*]}]
set_input_delay  -max 15 -clock [get_clocks flash_qspi_clk] -clock_fall [get_ports {qspi_data[*]}]
set_input_delay  -min 0  -clock [get_clocks flash_qspi_clk] -clock_fall [get_ports {qspi_data[*]}]

#**************************************************************
# NCSI RBT 
#**************************************************************
set_input_delay  -max 15 -clock [get_clocks { ncsi_rbt_ncsi_clk }] [get_ports {ncsi_rbt_ncsi_rxd[*]}]
set_input_delay  -min -1 -clock [get_clocks { ncsi_rbt_ncsi_clk }] [get_ports {ncsi_rbt_ncsi_rxd[*]}]
                                                                                
set_input_delay  -max 15 -clock [get_clocks { ncsi_rbt_ncsi_clk }] [get_ports {ncsi_rbt_ncsi_crs_dv}]
set_input_delay  -min -1 -clock [get_clocks { ncsi_rbt_ncsi_clk }] [get_ports {ncsi_rbt_ncsi_crs_dv}]
                                                                                
set_output_delay -max 3  -clock [get_clocks { ncsi_rbt_ncsi_clk }] [get_ports {ncsi_rbt_ncsi_txd[*]}]
set_output_delay -min 0  -clock [get_clocks { ncsi_rbt_ncsi_clk }] [get_ports {ncsi_rbt_ncsi_txd[*]}]
                                                                                
set_output_delay -max 3  -clock [get_clocks { ncsi_rbt_ncsi_clk }] [get_ports {ncsi_rbt_ncsi_tx_en}]
set_output_delay -min 0  -clock [get_clocks { ncsi_rbt_ncsi_clk }] [get_ports {ncsi_rbt_ncsi_tx_en}]

set_max_delay -from [get_clocks $PMCI_CLK] -to [get_clocks ncsi_rbt_ncsi_clk] 20 
set_max_delay -from [get_clocks ncsi_rbt_ncsi_clk] -to [get_clocks $PMCI_CLK] 10 

#**************************************************************
# Other Inputs/Outputs
#**************************************************************

#set_input_delay  -clock $PMCI_CLK -max 20 [get_ports {m10_gpio_fpga_usr_100m}]
#set_input_delay  -clock $PMCI_CLK -min  0 [get_ports {m10_gpio_fpga_usr_100m}]
set_input_delay  -clock $PMCI_CLK -max 20 -source_latency_included [get_ports {m10_gpio_fpga_m10_hb}]
set_input_delay  -clock $PMCI_CLK -min  0 -source_latency_included [get_ports {m10_gpio_fpga_m10_hb}]

