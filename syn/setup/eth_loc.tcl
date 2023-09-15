# Copyright (C) 2023 Intel Corporation.
# SPDX-License-Identifier: MIT

#
# Description
#-----------------------------------------------------------------------------
#
# Pin and location assignments
#
#-----------------------------------------------------------------------------
set_location_assignment PIN_EH1  -to qsfp_serial[0].tx_p[0]
set_location_assignment PIN_EK4  -to qsfp_serial[0].tx_p[1]
set_location_assignment PIN_ET1  -to qsfp_serial[0].tx_p[2]
set_location_assignment PIN_EV4  -to qsfp_serial[0].tx_p[3]

set_location_assignment PIN_EH8  -to qsfp_serial[0].rx_p[0]
set_location_assignment PIN_EK13 -to qsfp_serial[0].rx_p[1]
set_location_assignment PIN_ET8  -to qsfp_serial[0].rx_p[2]
set_location_assignment PIN_EV13 -to qsfp_serial[0].rx_p[3]

set_location_assignment PIN_GA1  -to qsfp_serial[1].tx_p[0]
set_location_assignment PIN_GD4  -to qsfp_serial[1].tx_p[1]
set_location_assignment PIN_GL1  -to qsfp_serial[1].tx_p[2]
set_location_assignment PIN_GN4  -to qsfp_serial[1].tx_p[3]

set_location_assignment PIN_GA8  -to qsfp_serial[1].rx_p[0]
set_location_assignment PIN_GD13 -to qsfp_serial[1].rx_p[1]
set_location_assignment PIN_GL8  -to qsfp_serial[1].rx_p[2]
set_location_assignment PIN_GN13 -to qsfp_serial[1].rx_p[3]

set_instance_assignment -name IO_STANDARD "HIGH SPEED DIFFERENTIAL I/O" -to qsfp_serial[*].tx*[*]
set_instance_assignment -name GXB_0PPM_CORECLK ON                       -to qsfp_serial[*].tx*[*]
set_instance_assignment -name IO_STANDARD "HIGH SPEED DIFFERENTIAL I/O" -to qsfp_serial[*].rx*[*]
set_instance_assignment -name GXB_0PPM_CORECLK ON                       -to qsfp_serial[*].rx*[*]

set_location_assignment PIN_GU23 -to qsfpa_i2c_scl
set_location_assignment PIN_GP22 -to qsfpa_i2c_sda
set_location_assignment PIN_HF19 -to qsfpa_intn
set_location_assignment PIN_HB19 -to qsfpa_lpmode
set_location_assignment PIN_HH18 -to qsfpa_modeseln
set_location_assignment PIN_GJ18 -to qsfpa_modprsln
set_location_assignment PIN_GW18 -to qsfpa_resetn

set_location_assignment PIN_GP26 -to qsfpb_i2c_scl
set_location_assignment PIN_GG27 -to qsfpb_i2c_sda
set_location_assignment PIN_GU25 -to qsfpb_intn
set_location_assignment PIN_GJ28 -to qsfpb_lpmode
set_location_assignment PIN_GP24 -to qsfpb_modeseln
set_location_assignment PIN_GG29 -to qsfpb_modprsln
set_location_assignment PIN_GU27 -to qsfpb_resetn

set_location_assignment PIN_FH19 -to qsfpa_act_red
set_location_assignment PIN_FK18 -to qsfpa_act_green
set_location_assignment PIN_FT19 -to qsfpb_act_red
set_location_assignment PIN_FP18 -to qsfpb_act_green
set_location_assignment PIN_FH21 -to qsfpa_speed_yellow
set_location_assignment PIN_FK20 -to qsfpa_speed_green
set_location_assignment PIN_FT21 -to qsfpb_speed_yellow
set_location_assignment PIN_FP20 -to qsfpb_speed_green

set_instance_assignment -name IO_STANDARD "1.2 V" -to qsfpa_i2c_scl
set_instance_assignment -name IO_STANDARD "1.2 V" -to qsfpa_i2c_sda
set_instance_assignment -name IO_STANDARD "1.2 V" -to qsfpa_intn
set_instance_assignment -name IO_STANDARD "1.2 V" -to qsfpa_lpmode
set_instance_assignment -name IO_STANDARD "1.2 V" -to qsfpa_modeseln
set_instance_assignment -name IO_STANDARD "1.2 V" -to qsfpa_modprsln
set_instance_assignment -name IO_STANDARD "1.2 V" -to qsfpa_resetn

set_instance_assignment -name IO_STANDARD "1.2 V" -to qsfpb_i2c_scl
set_instance_assignment -name IO_STANDARD "1.2 V" -to qsfpb_i2c_sda
set_instance_assignment -name IO_STANDARD "1.2 V" -to qsfpb_intn
set_instance_assignment -name IO_STANDARD "1.2 V" -to qsfpb_lpmode
set_instance_assignment -name IO_STANDARD "1.2 V" -to qsfpb_modeseln
set_instance_assignment -name IO_STANDARD "1.2 V" -to qsfpb_modprsln
set_instance_assignment -name IO_STANDARD "1.2 V" -to qsfpb_resetn

set_instance_assignment -name IO_STANDARD "1.2 V" -to qsfpa_act_green -entity top
set_instance_assignment -name IO_STANDARD "1.2 V" -to qsfpa_act_red -entity top
set_instance_assignment -name IO_STANDARD "1.2 V" -to qsfpb_act_green -entity top
set_instance_assignment -name IO_STANDARD "1.2 V" -to qsfpb_act_red -entity top
set_instance_assignment -name IO_STANDARD "1.2 V" -to qsfpa_speed_green -entity top
set_instance_assignment -name IO_STANDARD "1.2 V" -to qsfpa_speed_yellow -entity top
set_instance_assignment -name IO_STANDARD "1.2 V" -to qsfpb_speed_green -entity top
set_instance_assignment -name IO_STANDARD "1.2 V" -to qsfpb_speed_yellow -entity top

set_instance_assignment -name SLEW_RATE 0 -to qsfpa_i2c_scl
set_instance_assignment -name SLEW_RATE 0 -to qsfpa_i2c_sda
set_instance_assignment -name SLEW_RATE 0 -to qsfpa_intn
set_instance_assignment -name SLEW_RATE 0 -to qsfpa_lpmode
set_instance_assignment -name SLEW_RATE 0 -to qsfpa_modeseln
set_instance_assignment -name SLEW_RATE 0 -to qsfpa_modprsln
set_instance_assignment -name SLEW_RATE 0 -to qsfpa_resetn

set_instance_assignment -name SLEW_RATE 0 -to qsfpb_i2c_scl
set_instance_assignment -name SLEW_RATE 0 -to qsfpb_i2c_sda
set_instance_assignment -name SLEW_RATE 0 -to qsfpb_intn
set_instance_assignment -name SLEW_RATE 0 -to qsfpb_lpmode
set_instance_assignment -name SLEW_RATE 0 -to qsfpb_modeseln
set_instance_assignment -name SLEW_RATE 0 -to qsfpb_modprsln
set_instance_assignment -name SLEW_RATE 0 -to qsfpb_resetn

set_instance_assignment -name SLEW_RATE 0 -to qsfpa_act_green -entity top
set_instance_assignment -name SLEW_RATE 0 -to qsfpa_act_red -entity top
set_instance_assignment -name SLEW_RATE 0 -to qsfpb_act_green -entity top
set_instance_assignment -name SLEW_RATE 0 -to qsfpb_act_red -entity top
set_instance_assignment -name SLEW_RATE 0 -to qsfpa_speed_green -entity top
set_instance_assignment -name SLEW_RATE 0 -to qsfpa_speed_yellow -entity top
set_instance_assignment -name SLEW_RATE 0 -to qsfpb_speed_green -entity top
set_instance_assignment -name SLEW_RATE 0 -to qsfpb_speed_yellow -entity top

