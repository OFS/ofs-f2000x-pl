# Copyright (C) 2021 Intel Corporation.
# SPDX-License-Identifier: MIT
#
#// Description:
#//  	Makefile for Partition Compile
#// 
#// Author: Sonith Ajmal 
#//
#// $Id: Makefile_VCS.mk $
#////////////////////////////////////////////////////////////////////////////////////////////////

ifndef OFS_ROOTDIR
    $(error undefined OFS_ROOTDIR)
endif
ifndef WORKDIR
    WORKDIR := $(OFS_ROOTDIR)
endif

#ifndef UVM_HOME
#    $(error undefined UVM_HOME)
#endif 

#ifndef TESTNAME
#    $(error undefined TESTNAME)
#endif    
TEST_DIR :=  $(shell ./create_dir.pl $(VERDIR)/sim/$(TESTNAME) )

SCRIPTS_DIR = $(VERDIR)/scripts
SIM_BASE=$(VERDIR)/sim

VCDFILE = $(SCRIPTS_DIR)/vpd_dump.key
FSDBFILE = $(SCRIPTS_DIR)/fsdb_dump.tcl

AGILEX_DIR = $(OFS_ROOTDIR)/sim/n6000/base_x16/scripts/agilex_f_dk
ADP_DIR = $(OFS_ROOTDIR)/sim/n6000/base_x16/scripts/adp
export VIPDIR = $(VERDIR)
export RALDIR = $(VERDIR)/testbench/ral

PLATFORM_DIR = $(AGILEX_DIR)

#VLOG_OPT = -kdb -full64 -error=noMPD -ntb_opts uvm-1.2 +vcs+initreg+random +vcs+lic+wait -ntb_opts dtm -sverilog -timescale=1ns/1fs +libext+.v+.sv -CFLAGS -debug_pp -l vlog.log -assert enable_diag -ignore unique_checks -debug_all
VLOG_OPT = -kdb -full64 -error=noMPD -ntb_opts uvm-1.2 +vcs+initreg+random +vcs+lic+wait -ntb_opts dtm -sverilog -timescale=1ns/1fs +libext+.v+.sv -l vlog.log -assert enable_diag -ignore unique_checks 
VLOG_OPT += -Mdir=./csrc +warn=noBCNACMBP -CFLAGS -y $(VERDIR)/vip/pcie_vip/src/verilog/vcs -y $(VERDIR)/vip/pcie_vip/src/sverilog/vcs -P $(VERDIR)/scripts/vip/pli.tab $(WORKDIR)/scripts/vip/msglog.o -notice +incdir+./ 
VLOG_OPT += +define+INCLUDE_MEM_TG +define+INCLUDE_HSSI +define+INCLUDE_PCIE_SS  +define+INCLUDE_PR +define+INCLUDE_MSIX
VLOG_OPT += +define+SIM_MODE +define+SIM_SERIAL +define+PU_MMIO #Enable PCIE Serial link up for p-tile and Power user MMIO for PO FIM
VLOG_OPT += +define+SIMULATION_MODE
VLOG_OPT += +define+UVM_DISABLE_AUTO_ITEM_RECORDING
VLOG_OPT += +define+UVM_PACKER_MAX_BYTES=1500000
VLOG_OPT += +define+MMIO_TIMEOUT_IN_CYCLES=512
VLOG_OPT += +define+SVT_PCIE_ENABLE_GEN3+GEN3+SVT_PCIE_ENABLE_10_BIT_TAGS
VLOG_OPT += +define+SVT_UVM_TECHNOLOGY
VLOG_OPT += +define+SVT_ETHERNET +define+VIP_ETHERNET_40G100G_OPT_SVT
VLOG_OPT += +define+ETH_CAUI_25G_INTERFACE_WIDTH=8 +define+SVT_ETHERNET_CLKGEN
VLOG_OPT += +define+VIP_ETHERNET_100G_SVT +define+SVT_ETHERNET_DEBUG_BUS_ENABLE
VLOG_OPT += +define+SYNOPSYS_SV
VLOG_OPT += +define+BASE_AFU=dummy_afu+
VLOG_OPT += +incdir+$(WORKDIR)/src/includes
VLOG_OPT += +incdir+$(WORKDIR)/src/fims/n6000/includes
VLOG_OPT += +incdir+$(WORKDIR)/ipss/n6000/pcie/rtl
VLOG_OPT += +incdir+$(WORKDIR)/ipss/n6000/eth/rtl/inc
VLOG_OPT += +incdir+$(RALDIR)
VLOG_OPT += -debug_access+f

VLOG_OPTS_AGLX += $(VLOG_OPT)

VCS_OPT = -full64 -ntb_opts uvm-1.2 -licqueue  +vcs+lic+wait -l vcs.log -partcomp n6000_tb_lib.n6000_tb_top   -partcomp_dir=./lib/libraries/iofs_partition_lib -partcomp
VCS_OPT  += -debug_access+f

USER_DEFINED_ELAB_OPTIONS = -partcomp n6000_tb_lib.n6000_tb_top   -partcomp_dir=iofs_partition_lib -partcomp

SIMV_OPT = +UVM_TESTNAME=$(TESTNAME) +TIMEOUT=$(TIMEOUT)
#SIMV_OPT += +UVM_NO_RELNOTES
#SIMV_OPT += -l runsim.log 
SIMV_OPT += +ntb_disable_cnst_null_object_warning=1 -assert nopostproc +vcs+lic+wait +vcs+initreg+0 
#SIMV_OPT += +UVM_PHASE_TRACE
SIMV_OPT +=  +vcs+lic+wait 
SIMV_OPT += +vcs+nospecify+notimingchecks +vip_verbosity=svt_pcie_pl:UVM_NONE,svt_pcie_dl:UVM_NONE,svt_pcie_tl:UVM_NONE  
#SIMV_OPT +=  +vcs+lic+wait -ucli -i $(VCDFILE)

ifndef SEED
    SIMV_OPT += +ntb_random_seed_automatic
else
    SIMV_OPT += +ntb_random_seed=$(SEED)
endif

ifndef MSG
    SIMV_OPT += +UVM_VERBOSITY=UVM_LOW
else
    SIMV_OPT += +UVM_VERBOSITY=$(MSG)
endif
ifdef TEST_LPBK
    VLOG_OPT += +define+TEST_LPBK 
endif

ifdef RUNSIM_LOG
SIMV_OPT += -l runsim.log 
endif

ifdef DUMP
    #VLOG_OPT += -debug_all 
    #VCS_OPT += -debug_all 
    VLOG_OPT += -debug_access+f
    VCS_OPT += -debug_access+f
    SIMV_OPT += -ucli -i $(VCDFILE)
endif

ifdef DUMP_FSDB
    #VLOG_OPT += -debug_all 
    #VCS_OPT += -debug_all 
    VLOG_OPT += -debug_access+f
    VCS_OPT += -debug_access+f
    SIMV_OPT += -ucli -i $(FSDBFILE)
endif

ifdef GUI
    VCS_OPT += -debug_all +memcbk
    SIMV_OPT += -gui
endif

ifdef QUIT
    SIMV_OPT_EXTRA = +UVM_MAX_QUIT_COUNT=1
else
   SIMV_OPT_EXTRA = ""
endif

ifdef COV 
    VLOG_OPT += +define+COV -cm line+cond+fsm+tgl+branch -cm_dir simv.vdb
    VCS_OPT  += -cm line+cond+fsm+tgl+branch  -cm_dir simv.vdb
    SIMV_OPT += -cm line+cond+fsm+tgl+branch -cm_name $(TESTNAME) -cm_dir ../regression.vdb
    #SIMV_OPT += -cm line+cond+fsm+tgl+branch -cm_name seed.1 -cm_dir regression.vdb
endif

ifndef AFU_WITH_PIM
    # No PIM. Use the default exerciser AFU.
    AFU_FLIST_IMPORT=-F $(OFS_ROOTDIR)/sim/n6000/base_x16/scripts/common/rtl_afu_default.f
else
    # Construct both the Platform Interface Manager (PIM) and an AFU that uses it.
    PIM_ROOT_DIR=$(VERDIR)/sim/afu_with_pim
    AFU_FLIST_IMPORT=-F $(PIM_ROOT_DIR)/all_sim_files.list
endif

batch: vcs
	./simv $(SIMV_OPT) $(SIMV_OPT_EXTRA)

dump:
	make DUMP=1

clean:
	@if [ -d worklib ]; then rm -rf worklib; fi;
	@if [ -d libs ]; then rm -rf libs; fi;
	@rm -rf simv* csrc *.out* *.OUT *.log *.txt *.h *.setup *.vpd test_lib.svh .vlogansetup.* *.tr *.ver *.hex *.xml DVEfiles;
	@rm -rf $(VERDIR)/sim $(VERDIR)/ip_libraries $(VERDIR)/vip $(VERDIR)/scripts/qip $(VERDIR)/scripts/rtl_comb.f $(VERDIR)/scripts/rtl_comb_common.f $(VERDIR)/scripts/rtl_pcie.f $(VERDIR)/scripts/ip_list.f $(VERDIR)/scripts/ip_flist.f;

clean_dve:
	@if [ -d worklib ]; then rm -rf worklib; fi;
	@if [ -d libs ]; then rm -rf libs; fi;
	@rm -rf simv* csrc *.out* *.OUT *.log *.txt *.h *.setup *.vpd test_lib.svh .vlogansetup.* *.tr *.ver *.hex *.xml;
             
setup_adp: clean_dve
	#@echo WORK \> DEFAULT > synopsys_sim.setup
	#@echo DEFAULT \: worklib >> synopsys_sim.setup              
	#@mkdir worklib
	@echo \`include \"$(TESTNAME).svh\" > test_lib.svh                
	test -s $(VERDIR)/sim || mkdir $(VERDIR)/sim
	test -s $(VERDIR)/vip || mkdir $(VERDIR)/vip
	mkdir -p $(SIM_BASE)/libs 
	rm -rf $(SCRIPTS_DIR)/qip
	test -s $(SCRIPTS_DIR)/qip || ln -sf $(ADP_DIR)/qip_sim_script qip
	cp -f qip/synopsys/vcsmx/synopsys_sim.setup ../sim/libs/
	echo iofs_svt_lib:                      ./libs/libraries/iofs_svt_lib >> ../sim/libs/synopsys_sim.setup
	echo n6000_top_lib:                   ./libs/libraries/n6000_top_lib >> ../sim/libs/synopsys_sim.setup
	echo n6000_rtl_lib:                   ./libs/libraries/n6000_rtl_lib >> ../sim/libs/synopsys_sim.setup 
	echo n6000_tb_lib:                    ./libs/libraries/n6000_tb_lib >> ../sim/libs/synopsys_sim.setup 
	cp $(SIM_BASE)/libs/synopsys_sim.setup  $(SCRIPTS_DIR)/ 
	test -s $(VERDIR)/vip/axi_vip || mkdir $(VERDIR)/vip/axi_vip
	test -s $(VERDIR)/vip/pcie_vip || mkdir $(VERDIR)/vip/pcie_vip
	cp  $(SCRIPTS_DIR)/init_reg.cfg  $(SIM_BASE)/.
	rsync -avz --checksum --ignore-times $(SIM_BASE)/libs/* $(VERDIR)/sim/
	@echo ''
	@echo VCS_HOME: $(VCS_HOME)
	@$(DESIGNWARE_HOME)/bin/dw_vip_setup -path ../vip/axi_vip -add axi_system_env_svt -svlog
	@$(DESIGNWARE_HOME)/bin/dw_vip_setup -path ../vip/pcie_vip -add pcie_device_agent_svt -svlog
	@$(DESIGNWARE_HOME)/bin/dw_vip_setup -path ../vip/ethernet_vip -add ethernet_agent_svt -svlog
	@echo ''  
  
             
setup_agilex: clean_dve
	#@echo WORK \> DEFAULT > synopsys_sim.setup
	#@echo DEFAULT \: worklib >> synopsys_sim.setup              
	#@mkdir worklib
	@echo \`include \"$(TESTNAME).svh\" > test_lib.svh                
	test -s $(VERDIR)/sim || mkdir $(VERDIR)/sim
	test -s $(VERDIR)/vip || mkdir $(VERDIR)/vip
	mkdir -p $(SIM_BASE)/libs
	rm  -rf $(SCRIPTS_DIR)/qip
#	test -s $(SCRIPTS_DIR)/qip || ln -s $(AGILEX_DIR)/qip_sim_script qip
	test -s $(SCRIPTS_DIR)/qip || ln -sf $(AGILEX_DIR)/qip_sim_script qip
	cp -f qip/synopsys/vcsmx/synopsys_sim.setup ../sim/libs/
	echo iofs_svt_lib:                      ./libs/libraries/iofs_svt_lib >> ../sim/libs/synopsys_sim.setup
	echo n6000_top_lib:                   ./libs/libraries/n6000_top_lib >> ../sim/libs/synopsys_sim.setup
	echo n6000_rtl_lib:                   ./libs/libraries/n6000_rtl_lib >> ../sim/libs/synopsys_sim.setup 
	echo n6000_tb_lib:                    ./libs/libraries/n6000_tb_lib >> ../sim/libs/synopsys_sim.setup 
	cp $(SIM_BASE)/libs/synopsys_sim.setup  $(SCRIPTS_DIR)/ 
	test -s $(VERDIR)/vip/axi_vip || mkdir $(VERDIR)/vip/axi_vip
	test -s $(VERDIR)/vip/pcie_vip || mkdir $(VERDIR)/vip/pcie_vip
	cp  $(SCRIPTS_DIR)/init_reg.cfg  $(SIM_BASE)/.
	rsync -avz --checksum --ignore-times $(SIM_BASE)/libs/* $(VERDIR)/sim/
	@echo ''
	@echo VCS_HOME: $(VCS_HOME)
	@$(DESIGNWARE_HOME)/bin/dw_vip_setup -path ../vip/axi_vip -add axi_system_env_svt -svlog
	@$(DESIGNWARE_HOME)/bin/dw_vip_setup -path ../vip/pcie_vip -add pcie_device_agent_svt -svlog
	@$(DESIGNWARE_HOME)/bin/dw_vip_setup -path ../vip/ethernet_vip -add ethernet_agent_svt -svlog
	@echo ''  
  

#cmplib_agilex:setup
#	#mkdir -p ../sim/ip_libraries
#	#mkdir -p ../ip_libraries
#	test -s $(SCRIPTS_DIR)/qip || ln -s $(AGILEX_DIR)/qip_sim_script qip
#	cp -f qip/synopsys/vcsmx/synopsys_sim.setup ../sim/ip_libraries/
#	echo iofs_svt_lib:                              ./work/iofs_svt_lib >> ../iplibraries/synopsys_sim.setup
#	echo n6000_top_lib:                           ./work/n6000_top_lib >> ../iplibraries/synopsys_sim.setup
#	echo n6000_rtl_lib:                           ./work/n6000_rtl_lib >> ../iplibraries/synopsys_sim.setup
#	echo n6000_tb_lib:                            ./work/n6000_tb_lib >> ../iplibraries/synopsys_sim.setup
#	cd ../sim/ip_libraries && ../../scripts/qip/synopsys/vcsmx/vcsmx_setup.sh SKIP_SIM=1 QSYS_SIMDIR=../../scripts/qip QUARTUS_INSTALL_DIR=$(QUARTUS_HOME)
#
vlog_adp_qlib:setup_adp
	mkdir -p ../sim/libs
	test -s $(SCRIPTS_DIR)/qip || ln -sf $(ADP_DIR)/qip_sim_script qip
	cp -f qip/synopsys/vcsmx/synopsys_sim.setup ../sim/libs/
	echo iofs_svt_lib:                      ./libraries/iofs_svt_lib >> ../sim/libs/synopsys_sim.setup
	echo n6000_top_lib:                   ./libraries/iofs_svt_lib >> ../sim/libs/synopsys_sim.setup
	echo n6000_rtl_lib:                   ./libraries/iofs_svt_lib >> ../sim/libs/synopsys_sim.setup
	cd ../sim/libs && ../../scripts/qip/synopsys/vcsmx/vcsmx_setup.sh  SKIP_SIM=1 QSYS_SIMDIR=../../scripts/qip QUARTUS_INSTALL_DIR=$(QUARTUS_HOME)




#vlog_agilex: setup_adp 
#	cd $(VERDIR)/sim && vlogan -ntb_opts uvm-1.2 -sverilog
#	cd $(VERDIR)/sim && vlogan -full64 -ntb_opts uvm-1.2 -sverilog -timescale=1ns/1ns -l vlog_uvm.log
#	test -s $(SCRIPTS_DIR)/rtl_comb.f  || ln -s $(AGILEX_DIR)/rtl_comb.f rtl_comb.f
#	test -s $(SCRIPTS_DIR)/ip_flist.f  || ln -s $(AGILEX_DIR)/ip_flist.f ip_flist.f
#	test -s $(SCRIPTS_DIR)/rtl_pcie.f  || ln -s $(AGILEX_DIR)/../common/rtl_pcie.f rtl_pcie.f
#	test -s $(SCRIPTS_DIR)/rtl_comb_common.f  || ln -s $(AGILEX_DIR)/../common/rtl_comb_common.f rtl_comb_common.f
#	cd $(VERDIR)/sim && vlogan $(VLOG_OPT) +define+INCLUDE_DDR4 +define+AGILEX  -f $(SCRIPTS_DIR)/ip_flist.f -f $(SCRIPTS_DIR)/rtl_comb_common.f -f $(SCRIPTS_DIR)/rtl_comb.f -f $(SCRIPTS_DIR)/rtl_pcie.f -f $(SCRIPTS_DIR)/ver_list.f
#
# svt Compile and Build. Commin for Agilex and ADP 



vlog_svt:  
	cd $(VERDIR)/sim && vlogan -ntb_opts uvm-1.2 -sverilog
	cd $(VERDIR)/sim && vlogan -full64 -ntb_opts uvm-1.2 -sverilog -timescale=1ns/1ns -l vlog_svt_uvm.log
	cd $(VERDIR)/sim && vlogan $(VLOG_OPT) +define+SIM_VIP  -f $(SCRIPTS_DIR)/svt_list.f -work n6000_tb_lib

build_svt :  vlog_svt 
	     cd $(VERDIR)/sim && vcs $(VCS_OPT) 

###  ADP Compile & Build

cmplib_adp:setup_adp
	cd ../sim && ../scripts/qip/synopsys/vcsmx/vcsmx_setup.sh  SKIP_SIM=1 USER_DEFINED_COMPILE_OPTIONS=-v2005 QSYS_SIMDIR=../scripts/qip  QUARTUS_INSTALL_DIR=$(QUARTUS_HOME) 


vlog_adp_rtl:  
ifdef AFU_WITH_PIM
	"$(OFS_ROOTDIR)"/verification/scripts/pim/ofs_pim_sim_setup.sh -t "$(PIM_ROOT_DIR)" -b adp -f base "$(AFU_WITH_PIM)"
endif
	cd $(VERDIR)/sim && vlogan -ntb_opts uvm-1.2 -sverilog
	cd $(VERDIR)/sim && vlogan -full64 -ntb_opts uvm-1.2 -sverilog -timescale=1ns/1ns -l vlog_rtl_uvm.log
	rm -rf $(SCRIPTS_DIR)/rtl_comb.f  
	rm -rf  $(SCRIPTS_DIR)/rtl_pcie.f
	rm -rf $(SCRIPTS_DIR)/rtl_comb_common.f
	test -s $(SCRIPTS_DIR)/rtl_comb.f  || ln -sf $(ADP_DIR)/rtl_comb.f rtl_comb.f
	test -s $(SCRIPTS_DIR)/rtl_pcie.f  || ln -sf $(ADP_DIR)/../common/rtl_pcie.f rtl_pcie.f
	test -s $(SCRIPTS_DIR)/rtl_comb_common.f  || ln -sf $(ADP_DIR)/../common/rtl_comb_common.f rtl_comb_common.f
	cd $(VERDIR)/sim && vlogan $(VLOG_OPT) +define+SIM_VIP +define+INCLUDE_PMCI -f $(SCRIPTS_DIR)/rtl_comb_common.f -f $(SCRIPTS_DIR)/rtl_comb.f -f $(SCRIPTS_DIR)/rtl_pcie.f $(AFU_FLIST_IMPORT) -work n6000_rtl_lib 

vlog_adp_ss_lib: 
	cd $(VERDIR)/sim && vlogan -ntb_opts uvm-1.2 -sverilog
	cd $(VERDIR)/sim && vlogan -full64 -ntb_opts uvm-1.2 -sverilog -timescale=1ns/1ns -l vlog_ss_lib_uvm.log
	rm -rf $(SCRIPTS_DIR)/ip_flist.f  
	test -s $(SCRIPTS_DIR)/ip_flist.f  || ln -s $(ADP_DIR)/ip_flist.f ip_flist.f
	cd $(VERDIR)/sim && vlogan $(VLOG_OPT) +define+SIM_VIP +define+INCLUDE_PMCI -f $(SCRIPTS_DIR)/ip_flist.f  -work n6000_top_lib

vlog_adp_verif: 
	cd $(VERDIR)/sim && vlogan -ntb_opts uvm-1.2 -sverilog
	cd $(VERDIR)/sim && vlogan -full64 -ntb_opts uvm-1.2 -sverilog -timescale=1ns/1ns -l vlog_verif_uvm.log
	cd $(VERDIR)/sim && vlogan $(VLOG_OPT) +define+SIM_VIP +define+INCLUDE_PMCI -f $(SCRIPTS_DIR)/ver_list.f   -work n6000_tb_lib   

vlog_adp:  vlog_adp_rtl vlog_adp_ss_lib  vlog_svt  vlog_adp_verif

## Adp Builds 

build_adp_ss_lib: vlog_adp_ss_lib
	     cd $(VERDIR)/sim && vcs $(VCS_OPT) 
	 #vlog_adp_ss_lib \


 
build_adp_rtl:  vlog_adp_rtl  
		cd $(VERDIR)/sim && vcs $(VCS_OPT) 

build_adp_verif:   vlog_adp_verif 
		   cd $(VERDIR)/sim && vcs $(VCS_OPT) 

build_adp: vlog_adp 
	cd $(VERDIR)/sim && vcs $(VCS_OPT)
ifdef DUMP_FSDB
	 @arc shell synopsys_verdi/R-2020.12-SP2 synopsys_verdi-lic/config
endif

# Compile and Build Agilex

cmplib_agilex:setup_agilex
	rm -f $(SCRIPTS_DIR)/ip_flist.f
	test -s $(SCRIPTS_DIR)/ip_flist.f  || ln -sf $(AGILEX_DIR)/ip_flist.f ip_flist.f
	cd ../sim && ../scripts/qip/synopsys/vcsmx/vcsmx_setup.sh  SKIP_SIM=1 USER_DEFINED_COMPILE_OPTIONS=-v2005 QSYS_SIMDIR=../scripts/qip QUARTUS_INSTALL_DIR=$(QUARTUS_HOME)



vlog_agilex_rtl:  
ifdef AFU_WITH_PIM
	"$(OFS_ROOTDIR)"/verification/scripts/pim/ofs_pim_sim_setup.sh -t "$(PIM_ROOT_DIR)" -b agilex_f_dk -f base "$(AFU_WITH_PIM)"
endif
	cd $(VERDIR)/sim && vlogan -ntb_opts uvm-1.2 -sverilog
	cd $(VERDIR)/sim && vlogan -full64 -ntb_opts uvm-1.2 -sverilog -timescale=1ns/1ns -l vlog_rtl_uvm.log
	rm -rf $(SCRIPTS_DIR)/rtl_comb.f  
	rm -rf  $(SCRIPTS_DIR)/rtl_pcie.f
	rm -rf $(SCRIPTS_DIR)/rtl_comb_common.f
	test -s $(SCRIPTS_DIR)/rtl_comb.f  || ln -sf $(AGILEX_DIR)/rtl_comb.f rtl_comb.f
	test -s $(SCRIPTS_DIR)/rtl_pcie.f  || ln -sf $(AGILEX_DIR)/../common/rtl_pcie.f rtl_pcie.f
	test -s $(SCRIPTS_DIR)/rtl_comb_common.f  || ln -sf $(AGILEX_DIR)/../common/rtl_comb_common.f rtl_comb_common.f
	cd $(VERDIR)/sim && vlogan $(VLOG_OPT) +define+INCLUDE_DDR4 +define+AGILEX   -f $(SCRIPTS_DIR)/rtl_comb_common.f -f $(SCRIPTS_DIR)/rtl_comb.f -f $(SCRIPTS_DIR)/rtl_pcie.f $(AFU_FLIST_IMPORT) -work  n6000_rtl_lib

vlog_agilex_ss_lib: 
	cd $(VERDIR)/sim && vlogan -ntb_opts uvm-1.2 -sverilog
	cd $(VERDIR)/sim && vlogan -full64 -ntb_opts uvm-1.2 -sverilog -timescale=1ns/1ns -l vlog_ss_lib_uvm.log
	test -s $(SCRIPTS_DIR)/ip_flist.f  || ln -s $(AGILEX_DIR)/ip_flist.f ip_flist.f
	cd $(VERDIR)/sim && vlogan $(VLOG_OPT)  +define+INCLUDE_DDR4 +define+AGILEX -f $(SCRIPTS_DIR)/ip_flist.f  -work n6000_top_lib

vlog_agilex_verif: 
	cd $(VERDIR)/sim && vlogan -ntb_opts uvm-1.2 -sverilog
	cd $(VERDIR)/sim && vlogan -full64 -ntb_opts uvm-1.2 -sverilog -timescale=1ns/1ns -l vlog_verif_uvm.log
	cd $(VERDIR)/sim && vlogan $(VLOG_OPT)  +define+INCLUDE_DDR4 +define+AGILEX -f $(SCRIPTS_DIR)/ver_list.f   -work n6000_tb_lib   

vlog_agilex:  vlog_agilex_rtl vlog_agilex_ss_lib  vlog_svt  vlog_agilex_verif

## Agilex Builds 

build_agilex_ss_lib: vlog_agilex_ss_lib
	     cd $(VERDIR)/sim && vcs $(VCS_OPT) 
	 #vlog_agilex_ss_lib \


 
build_agilex_rtl:  vlog_agilex_rtl  
		cd $(VERDIR)/sim && vcs $(VCS_OPT) 

build_agilex_verif:   vlog_agilex_verif 
		   cd $(VERDIR)/sim && vcs $(VCS_OPT) 


build_agilex: vlog_agilex
	cd $(VERDIR)/sim && vcs $(VCS_OPT)
ifdef DUMP_FSDB
	 @arc shell synopsys_verdi/R-2020.12-SP2 synopsys_verdi-lic/config
endif

#build_adp: vlog_adp_lib elab_iofslib elab_rtl elab_svt elab_verif compile

##build_gkx:cmplib_agilex vlog_agilex
##	cd $(VERDIR)/sim && vcs $(VCS_OPT) n6000_tb_top
##
##build_gka:cmplib_adp vlog_adp
##	cd $(VERDIR)/sim && vcs $(VCS_OPT) n6000_tb_top


view:
	dve -full64 -vpd inter.vpd&
urg:
	urg -dir simv.vdb -dir regression.vdb -report regression.urgReport -grade index
run:    
ifndef TEST_DIR
	$(error undefined TESTNAME)
else
	cd $(VERDIR)/sim && mkdir $(TEST_DIR) && cd $(TEST_DIR) && cp -f ../*.hex . && cp -f $(OFS_ROOTDIR)/src/ip/n6000/fme_id_rom/fme_id.mif . && cp -f $(SCRIPTS_DIR)/fme_id.ver . | true  && cp -f $(VERDIR)/sim/serdes.firmware.rom . && ../simv $(SIMV_OPT) $(SIMV_OPT_EXTRA)
endif
rundb:    
ifndef TESTNAME
	$(error undefined TESTNAME)
else
	cd $(VERDIR)/sim && ./simv $(SIMV_OPT) $(SIMV_OPT_EXTRA)
endif

#compile:
#	 cd $(SIM_BASE) &&   cp ../scripts/init_reg.cfg  $(SIM_BASE)/. && cp -f ../scripts/*.hex .  && $(VCS)
compile:
	 cd $(SIM_BASE) &&   cp ../scripts/init_reg.cfg  $(SIM_BASE)/. && cp -f ../scripts/*.hex .  && $(VCS)

build_run: vcs run
build_all: cmplib vcs
do_it_all: cmplib vcs run


