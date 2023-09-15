# Copyright (C) 2022 Intel Corporation.
# SPDX-License-Identifier: MIT

# ***Following instructions are for External customers only****
# ***Unit tests under this folder structure are for faster simulation of AFU Blocks and other downstream logic***
# ***This simulation uses simple pcie bfm, and will avoid enumeration sequence waiting time***

Initial Setup:
1)	Get a "bash" shell (e.g. xterm)
2)	Go to the OFS Repo root directory.
3)  Set all tool paths vcs, python etc. Please make sure Tool versions used are as follows:
    VCS : vcsmx/Q-2020.03-SP2
    Python : python/3.7.7
    Quartus : 21.4
    #Not needed for unit test# SNPS VIP Portfolio Version : vip_Q-2020.03A
    #Not needed for unit test# PCIe VIP : Q-2020.03
    #Not needed for unit test# AXI VIP : Q-2020.03
    #Not needed for unit test# Ethernet VIP : Q-2020.03
4)	Set the required environment and directory Structure variables (as shown below)
    export OFS_ROOTDIR=<pwd>
    export QUARTUS_HOME=<Quartus Installation path upto /quartus>
    export QUARTUS_INSTALL_DIR=$QUARTUS_HOME
    export IMPORT_IP_ROOTDIR=$QUARTUS_HOME/../ip
5) Generate the sim files. 
   The sim files are not checked in and are generated on the fly. In order to do this, run the following steps
    a. Got to $OFS_ROOTDIR/ofs-common/scripts/common/sim
    b  Run the script "sh gen_sim_files.sh <target>" for e.g. "sh gen_sim_files.sh f2000x"


5) **Running Test******
    Unit tests are placed under $OFS_ROOTDIR/sim/unit_test, for example $OFS_ROOTDIR/sim/unit_test/he_lb_test
    To run the simulation for each test: 
       Go to $OFS_ROOTDIR/ofs-common/scripts/common/sim, run the following command
       for HOST tests
          VCS        : sh run_sim.sh TEST=host_tests/<test name>
	  VCSMX      : sh run_sim.sh TEST=host_tests/<test name> VCSMX=1
	  QuestaSim  : sh run_sim.sh TEST=host_tests/<test name> MSIM=1
       for SOC tests
	  VCS        : sh run_sim.sh TEST=soc_tests/<test name>
	  VCSMX      : sh run_sim.sh TEST=soc_tests/<test name> VCSMX=1
	  QuestaSim  : sh run_sim.sh TEST=soc_tests/<test name> MSIM=1
    Please refer readme under respective testcase for more info.

*****How to Run Unit level Regressions?******

** usage : python regress_run.py --help

 -l, --local Run regression locally, or run it on Farm. (Default:False)
 -n[N], --n_procs [N] Maximum number of processes/UVM tests to run in parallel when run locally. This has no effect on Farm run. (Default #CPUs-1: 11)
 -k, --pack [{'all','fme','he','hssi','list','mem','pmci'}] Test package to run during regression (Default: %(default)s)')
 -s [{vcs,msim,vcsmx}], --sim [{vcs,msim,vcsmx}] Simulator used for regression test. (Default: vcs)
 -g, --gen_sim_files, Generate IP simulation files. This should only be done once per repo update.  (Default: %(default)s)
 -e, --email_list Sends the regression results on email provided in list (Default : It will send it to regression Owner)

1)  for host_tests - cd $VERDIR/../sim/unit_test/host_tests 
    for soc_tests  - cd $VERDIR/../sim/unit_test/soc_tests

###run locally, with 8 processes, for adp platform, using test_pkg set of tests, using VCS with code coverage, to generate IP simulation files.  
python regress_run.py -l -n 8 -k all -s vcs -g

###Same as above, but run on Intel Farm (no --local):   
python regress_run.py --local --n_procs 8 --pack all --sim vcs -g

###Running script using defaults: run on Farm, adp platform, using test_pkg set of pmci tests, to generate IP simulation files using VCS with code coverage and sends result to owner 
python regress_run.py -g

2)  Results are created in individual testcase log dir

