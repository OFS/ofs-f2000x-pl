# Copyright (C) 2020 Intel Corporation.
# SPDX-License-Identifier: MIT

#
# This file contains PR specific Quartus assignments
#------------------------------------
set TOP_MEM_REGION    "X115 Y310 X219 Y344"
set BOTTOM_MEM_REGION "X0 Y0 X294 Y20"
set SUBSYSTEM_REGION  "X0 Y0 X60 Y279; X0 Y0 X300 Y39; X261 Y0 X300 Y129;"

set AFU_PLACE_REGION  "X61 Y40 X260 Y309; X220 Y130 X294 Y329; X12 Y280 X114 Y329;"
set AFU_ROUTE_REGION  "X0 Y0 X294 Y329"

if { [info exist env(OFS_BUILD_TAG_FLAT) ] } { 
    post_message "Compiling Flat design..." 
} else {
    post_message "Compiling PR Base revision..." 
    #-------------------------------
    # Specify PR Partition and turn PR ON for that partition
    #-------------------------------
    set_global_assignment -name REVISION_TYPE PR_BASE

    # M20K protection signal to PR region (required in Agilex)
#    set_instance_assignment -name M20K_CE_CONTROL_FOR_PR ON -to soc_afu|port_gasket|pr_slot|afu_main|pr_m20k_ce_ctl_req

    #####################################################
    # Main PR Partition -- green_region
    #####################################################
    set_instance_assignment -name PARTITION green_region               -to soc_afu|port_gasket|pr_slot|afu_main
    set_instance_assignment -name CORE_ONLY_PLACE_REGION            ON -to soc_afu|port_gasket|pr_slot|afu_main
    set_instance_assignment -name RESERVE_PLACE_REGION              ON -to soc_afu|port_gasket|pr_slot|afu_main
    set_instance_assignment -name PARTIAL_RECONFIGURATION_PARTITION ON -to soc_afu|port_gasket|pr_slot|afu_main
    set_instance_assignment -name PLACE_REGION $AFU_PLACE_REGION       -to soc_afu|port_gasket|pr_slot|afu_main
    set_instance_assignment -name ROUTE_REGION $AFU_ROUTE_REGION       -to soc_afu|port_gasket|pr_slot|afu_main

    ## Top I/O row memory
    set_instance_assignment -name CORE_ONLY_PLACE_REGION ON       -to mem_ss_top|mem_ss_fm_inst|mem_ss_fm_0|intf_0
    set_instance_assignment -name PLACE_REGION $TOP_MEM_REGION    -to mem_ss_top|mem_ss_fm_inst|mem_ss_fm_0|intf_0

    set_instance_assignment -name CORE_ONLY_PLACE_REGION ON       -to mem_ss_top|mem_ss_fm_inst|mem_ss_fm_0|msa_0
    set_instance_assignment -name PLACE_REGION $TOP_MEM_REGION    -to mem_ss_top|mem_ss_fm_inst|mem_ss_fm_0|msa_0

    set_instance_assignment -name CORE_ONLY_PLACE_REGION ON       -to mem_ss_top|mem_ss_fm_inst|mem_ss_fm_0|intf_1
    set_instance_assignment -name PLACE_REGION $TOP_MEM_REGION    -to mem_ss_top|mem_ss_fm_inst|mem_ss_fm_0|intf_1

    set_instance_assignment -name CORE_ONLY_PLACE_REGION ON       -to mem_ss_top|mem_ss_fm_inst|mem_ss_fm_0|msa_1
    set_instance_assignment -name PLACE_REGION $TOP_MEM_REGION    -to mem_ss_top|mem_ss_fm_inst|mem_ss_fm_0|msa_1

    ## Bottom I/O row memory
    set_instance_assignment -name CORE_ONLY_PLACE_REGION ON       -to mem_ss_top|mem_ss_fm_inst|mem_ss_fm_0|intf_2
    set_instance_assignment -name PLACE_REGION $BOTTOM_MEM_REGION -to mem_ss_top|mem_ss_fm_inst|mem_ss_fm_0|intf_2

    set_instance_assignment -name CORE_ONLY_PLACE_REGION ON       -to mem_ss_top|mem_ss_fm_inst|mem_ss_fm_0|msa_2
    set_instance_assignment -name PLACE_REGION $BOTTOM_MEM_REGION -to mem_ss_top|mem_ss_fm_inst|mem_ss_fm_0|msa_2

    ## Rest of FIM subsystems
    set_instance_assignment -name CORE_ONLY_PLACE_REGION ON       -to pcie_wrapper
    set_instance_assignment -name PLACE_REGION $SUBSYSTEM_REGION  -to pcie_wrapper

    set_instance_assignment -name CORE_ONLY_PLACE_REGION ON       -to soc_pcie_wrapper
    set_instance_assignment -name PLACE_REGION $SUBSYSTEM_REGION  -to soc_pcie_wrapper

    set_instance_assignment -name CORE_ONLY_PLACE_REGION ON       -to hssi_wrapper
    set_instance_assignment -name PLACE_REGION $SUBSYSTEM_REGION  -to hssi_wrapper

    set_instance_assignment -name CORE_ONLY_PLACE_REGION ON       -to pmci_wrapper
    set_instance_assignment -name PLACE_REGION $SUBSYSTEM_REGION  -to pmci_wrapper
    
}
