# Copyright (C) 2020 Intel Corporation.
# SPDX-License-Identifier: MIT

#
# Description
#-----------------------------------------------------------------------------
#
# PMCI pin and location assignments
#
#-----------------------------------------------------------------------------

# SPI Pins
set_location_assignment PIN_GJ24 -to spi_egress_sclk
set_location_assignment PIN_HH26 -to spi_egress_csn
set_location_assignment PIN_HB27 -to spi_egress_miso
set_location_assignment PIN_HB29 -to spi_egress_mosi

set_location_assignment PIN_GJ26 -to spi_ingress_sclk
set_location_assignment PIN_GW28 -to spi_ingress_csn
set_location_assignment PIN_HH28 -to spi_ingress_miso
set_location_assignment PIN_HF29 -to spi_ingress_mosi

set_instance_assignment -name IO_STANDARD "1.2 V" -to spi_egress_sclk
set_instance_assignment -name IO_STANDARD "1.2 V" -to spi_egress_csn
set_instance_assignment -name IO_STANDARD "1.2 V" -to spi_egress_miso
set_instance_assignment -name IO_STANDARD "1.2 V" -to spi_egress_mosi

set_instance_assignment -name IO_STANDARD "1.2 V" -to spi_ingress_sclk
set_instance_assignment -name IO_STANDARD "1.2 V" -to spi_ingress_csn
set_instance_assignment -name IO_STANDARD "1.2 V" -to spi_ingress_miso
set_instance_assignment -name IO_STANDARD "1.2 V" -to spi_ingress_mosi

set_instance_assignment -name SLEW_RATE 0 -to spi_egress_mosi
set_instance_assignment -name SLEW_RATE 0 -to spi_egress_csn
set_instance_assignment -name SLEW_RATE 0 -to spi_egress_sclk
set_instance_assignment -name SLEW_RATE 0 -to spi_egress_miso

set_instance_assignment -name SLEW_RATE 0 -to spi_ingress_sclk
set_instance_assignment -name SLEW_RATE 0 -to spi_ingress_csn
set_instance_assignment -name SLEW_RATE 0 -to spi_ingress_miso
set_instance_assignment -name SLEW_RATE 0 -to spi_ingress_mosi

# QSPI Pins
set_location_assignment PIN_HF21 -to qspi_dclk
set_location_assignment PIN_GW20 -to qspi_ncs
set_location_assignment PIN_FK26 -to qspi_data[0]
set_location_assignment PIN_FK22 -to qspi_data[1]
set_location_assignment PIN_HH24 -to qspi_data[2]
set_location_assignment PIN_HF25 -to qspi_data[3]

set_instance_assignment -name IO_STANDARD "1.2 V" -to qspi_dclk
set_instance_assignment -name IO_STANDARD "1.2 V" -to qspi_ncs
set_instance_assignment -name IO_STANDARD "1.2 V" -to qspi_data

set_instance_assignment -name SLEW_RATE 0 -to qspi_ncs
set_instance_assignment -name SLEW_RATE 0 -to qspi_data
set_instance_assignment -name SLEW_RATE 0 -to qspi_dclk

# RMII Pins
set_location_assignment PIN_GU21 -to ncsi_rbt_ncsi_arb_in 
set_location_assignment PIN_GJ22 -to ncsi_rbt_ncsi_arb_out
set_location_assignment PIN_GG19 -to ncsi_rbt_ncsi_crs_dv
set_location_assignment PIN_GP18 -to ncsi_rbt_ncsi_txd[0]
set_location_assignment PIN_GU19 -to ncsi_rbt_ncsi_txd[1]
#set_location_assignment PIN_GP20 -to ncsi_rbt_ncsi_rx_er
set_location_assignment PIN_GG23 -to ncsi_rbt_ncsi_tx_en
set_location_assignment PIN_GJ20 -to ncsi_rbt_ncsi_rxd[0]
set_location_assignment PIN_GG21 -to ncsi_rbt_ncsi_rxd[1]
set_location_assignment PIN_FH29 -to ncsi_rbt_ncsi_clk

set_instance_assignment -name IO_STANDARD "1.2 V" -to ncsi_rbt_ncsi_arb_in
set_instance_assignment -name IO_STANDARD "1.2 V" -to ncsi_rbt_ncsi_arb_out
set_instance_assignment -name IO_STANDARD "1.2 V" -to ncsi_rbt_ncsi_crs_dv
set_instance_assignment -name IO_STANDARD "1.2 V" -to ncsi_rbt_ncsi_txd
set_instance_assignment -name IO_STANDARD "1.2 V" -to ncsi_rbt_ncsi_tx_en
set_instance_assignment -name IO_STANDARD "1.2 V" -to ncsi_rbt_ncsi_rxd
set_instance_assignment -name IO_STANDARD "1.2 V" -to ncsi_rbt_ncsi_clk

set_instance_assignment -name SLEW_RATE 0 -to ncsi_rbt_ncsi_arb_in
set_instance_assignment -name SLEW_RATE 0 -to ncsi_rbt_ncsi_arb_out
set_instance_assignment -name SLEW_RATE 0 -to ncsi_rbt_ncsi_crs_dv
set_instance_assignment -name SLEW_RATE 0 -to ncsi_rbt_ncsi_txd
set_instance_assignment -name SLEW_RATE 0 -to ncsi_rbt_ncsi_tx_en
set_instance_assignment -name SLEW_RATE 0 -to ncsi_rbt_ncsi_rxd
set_instance_assignment -name SLEW_RATE 0 -to ncsi_rbt_ncsi_clk

# M|C10 Misc Pins
set_location_assignment PIN_GE28 -to m10_gpio_fpga_m10_hb
set_location_assignment PIN_GC29 -to m10_gpio_fpga_seu_error
set_location_assignment PIN_FY27 -to m10_gpio_fpga_therm_shdn

set_instance_assignment -name IO_STANDARD "1.2 V" -to m10_gpio_fpga_m10_hb
set_instance_assignment -name IO_STANDARD "1.2 V" -to m10_gpio_fpga_seu_error
set_instance_assignment -name IO_STANDARD "1.2 V" -to m10_gpio_fpga_therm_shdn

set_instance_assignment -name SLEW_RATE 0 -to m10_gpio_fpga_m10_hb
set_instance_assignment -name SLEW_RATE 0 -to m10_gpio_fpga_seu_error
set_instance_assignment -name SLEW_RATE 0 -to m10_gpio_fpga_therm_shdn
