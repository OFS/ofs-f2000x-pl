#!/bin/bash
# Copyright 2022-2023 Intel Corporation
# SPDX-License-Identifier: MIT

# This script relies on the following set of software tools, (intelFPGA_pro, Synopsys, Questasim and Intel OFS) which should be installed using the directory structure below. Tool versions can vary.

##├── intelFPGA_pro
##│   └── 23.1
##│       ├── devdata
##│       ├── gcc
##│       ├── hld
##│       ├── hls
##│       ├── ip
##│       ├── licenses
##│       ├── logs
##│       ├── nios2eds
##│       ├── niosv
##│       ├── qsys
##│       ├── quartus
##│       ├── questa_fe
##│       ├── questa_fse
##│       ├── syscon
##│       └── uninstall
##├── mentor
##│   ├── questasim
##│   │   └── 2021.4
##├── synopsys
##│   ├── vcsmx
##│   │   └── S-2021.09-SP1
##│   └── vip_common
##│       └── vip_Q-2020.03A
##├── user_area
##│   └── ofs-X.X.X

## ofs-X.X.X is a directory the user creates based on version they want to test e.g ofs-2.3.1 

## The Intel OFS repos are then cloned beneath ofs-X.X.X and is assigned to the $IOFS_BUILD_ROOT environment variable. This script is then copied to the same directory location, see example below

##├── ofs-2.3.1
##│   ├── examples-afu
##│   ├── linux-dfl
##│   ├── ofs-f2000x-pl
##│   ├── 
##│   ├── 
##│   ├── opae-sdk
##│   ├── opae-sim
##│   ├── ofs_f2000x_eval.sh

# Repository Contents
## examples-afu	          (Basic Building Blocks (BBB) for Intel FPGAs is a suite of application building blocks and shims for transforming the CCI-P interface)
## linux-dfl	            (Contains mirror of linux-dfl and specific Intel OFS drivers that are being upstreamed to the Linux kernel)
## ofs-f2000x-pl	        (Contains FIM or shell RTL, automated compilation scripts, unit tests and UVM test framework)
##
##
## opae-sdk	              (Contains the files for building and installing Open Programmable Acceleration Engine Software Development Kit from source)
## opae-sim	              (Contains the files for an AFU developer to build the Accelerator Funcitonal Unit Simulation Environment (ASE) for workload development)

#################################################################################################################################################################################
# To adapt this script to the user environment please follow the instructions below which explains which line numbers to change in the ofs_f2000x_eval.sh script ################
#################################################################################################################################################################################
# User Directory Creation
# Create the top-level source directory and then clone Intel OFS repositories
mkdir ofs-2.3.1

In the example above we have used ofs-2.3.1 as the directory name

# Set-Up Proxy Server (lines 65-67)
# Please edit the lines indicated to add the location of your proxy server to allow access to external internet to build software packages
export http_proxy=
export https_proxy=
export no_proxy=

# License Files (lines 70-72)
# Please enter the the license file locations for the following tool variables
export LM_LICENSE_FILE=
export DW_LICENSE_FILE=
export SNPSLMD_LICENSE_FILE=

# Tools Location (line 85, 86, 87, 88)
# ************** Set Location of Quartus, Synopsys, Questasim and oneAPI Tools ***************** #
export QUARTUS_TOOLS_LOCATION=/home
export SYNOPSYS_TOOLS_LOCATION=/home
export QUESTASIM_TOOLS_LOCATION=/home
#
# ************** Set Location of Quartus, Synopsys, Questasim and oneAPI Tools ***************** #

In the example above /home is used as the base location of Quartus, Synopsys and Questasim tools, /opt is used for the oneAPI tools

# Set Quartus Tools Version (line 93)
# ************** Set version of Quartus ***************** #
export QUARTUS_VERSION=23.1
# ************** Set version of Quartus ***************** #

In the example above "23.1" is used as the Quartus Tools version

# Set OPAE Tools Version(line 106)
# ************** change OPAE SDK VERSION ***************** #
export OPAE_SDK_VERSION=2.5.0-1
# ************** change OPAE SDK VERSION ***************** #

In the example above "2.5.0-1" is used as the OPAE SDK tools version

# PCIe (Bus Number) (lines 230 and 237)
# The Bus number must be entered by the user after installing the hardware in the chosen server, in the example below "b1" is the Bus Number for a single card
export ADP_CARD0_BUS_NUMBER=b1

# Set BMC FLASH Image Version(RTL and FW) (line 394)
export BMC_RTL_FW_FLASH=AC_BMC_RSU_user_retail_3.2.0_unsigned.rsu

# The BMC firmware can be updated and the file name will change based on revision number. In the example above "AC_BMC_RSU_user_retail_3.2.0_unsigned.rsu" is the FW file used to update the BMC. 
# Please place the new flash file in the following newly created location $OFS_ROOTDIR/bmc_flash_files

#################################################################################
#################### AFU Set-up  ################################################
#################################################################################

# Testing Remote Signal Tap

after the building steps 17 and 18 from the script (ofs_f2000x_eval.sh)

"17  - Build Partial Reconfiguration Tree for $ADP_PLATFORM Hardware with Remote Signal Tap"
"18  - Build Base FIM Identification(ID) into PR Build Tree template with Remote Signal Tap"

# Then to test the Remote Signal Tap feature for the host_chan_mmio example, copy the supplied host_chan_mmio.stp Signal Tap file to the following location
$IOFS_BUILD_ROOT

#################################################################################
#################### Multi-Test Set-up  #########################################
#################################################################################

# A user can run a sequence of tests and execute them sequentially. In the example below when the user selects option 46 from the main menu the script will execute 24 tests ie (main menu options 2, 9, 12, 13, 14, 15, 16, 17, 18, 32, 34, 35, 37, 39, 40, 41, 42, 43 and 44. All other tests with an "X" indicates do not run that test

intectiveprum=0
declare -A MULTI_TEST

# Enter Number of sequential tests to run
MULTI_TEST[46,tests]=19

# Enter options number from main menu

# "=======================================================================================" 
# "========================= ADP TOOLS MENU ==============================================" 
# "======================================================================================="
MULTI_TEST[46,X]=1
MULTI_TEST[46,0]=2
# "=======================================================================================" 
# "========================= ADP HARDWARE MENU ===========================================" 
# "=======================================================================================" 
MULTI_TEST[46,X]=3
MULTI_TEST[46,X]=4
MULTI_TEST[46,X]=5
MULTI_TEST[46,X]=6
MULTI_TEST[46,X]=7
MULTI_TEST[46,X]=8
# "======================================================================================="
# "========================= ADP PF/VF MUX MENU =========================================="
# "======================================================================================="
MULTI_TEST[46,1]=9
MULTI_TEST[46,X]=10
MULTI_TEST[46,X]=11
# "=======================================================================================" 
# "========================= ADP FIM/PR BUILD MENU =======================================" 
# "=======================================================================================" 
MULTI_TEST[46,2]=12
MULTI_TEST[46,3]=13
MULTI_TEST[46,4]=14
MULTI_TEST[46,5]=15
MULTI_TEST[46,6]=16
MULTI_TEST[46,7]=17
MULTI_TEST[46,8]=18
# "=======================================================================================" 
# "========================= ADP HARDWARE PROGRAMMING/DIAGNOSTIC MENU ====================" 
# "=======================================================================================" 
MULTI_TEST[46,X]=19
MULTI_TEST[46,X]=20
MULTI_TEST[46,X]=21
MULTI_TEST[46,X]=22
MULTI_TEST[46,X]=23
MULTI_TEST[46,X]=24
MULTI_TEST[46,X]=25
MULTI_TEST[46,X]=26
MULTI_TEST[46,X]=27
MULTI_TEST[46,X]=28
MULTI_TEST[46,X]=29
MULTI_TEST[46,X]=30
MULTI_TEST[46,X]=31
# "=======================================================================================" 
# "========================== ADP HARDWARE AFU TESTING MENU ==============================" 
# "=======================================================================================" 
MULTI_TEST[46,9]=32
MULTI_TEST[46,X]=33
MULTI_TEST[46,10]=34
MULTI_TEST[46,11]=35
MULTI_TEST[46,X]=36
# "=======================================================================================" 
# "========================== ADP HARDWARE AFU BBB TESTING MENU ==========================" 
# "======================================================================================="
MULTI_TEST[46,12]=37
MULTI_TEST[46,X]=38
# "=======================================================================================" 
# "========================== ADP UNIT TEST PROJECT MENU =================================" 
# "======================================================================================="
MULTI_TEST[46,13]=39
MULTI_TEST[46,14]=40
# "=======================================================================================" 
# "========================== ADP UVM PROJECT MENU =======================================" 
# "======================================================================================="
MULTI_TEST[46,15]=41
MULTI_TEST[46,16]=42
MULTI_TEST[46,17]=43
MULTI_TEST[46,18]=44
MULTI_TEST[46,X]=45
