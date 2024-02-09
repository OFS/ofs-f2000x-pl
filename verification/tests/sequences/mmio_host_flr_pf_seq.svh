// Copyright (C) 2023 Intel Corporation
// SPDX-License-Identifier: MIT

`ifndef MMIO_HOST_FLR_PF_SEQ_SVH
`define MMIO_HOST_FLR_PF_SEQ_SVH

parameter HOST_NUM_AFUS = 1;

mmio_seq ac_mmio_seq, ac_mmio_seq_1;

bit[3:0] PF_NUM;
bit[3:0] PF_NUMBER;
bit[63:0] addr, rdata ;

 class mmio_host_flr_pf_seq extends base_seq;
    `uvm_object_utils(mmio_host_flr_pf_seq)
    `uvm_declare_p_sequencer(virtual_sequencer)
    enumerate_seq   enumerate_seq2;
    pcie_device_bring_up_link_sequence bring_up_link_seq;
    uvm_status_e    status;
    uvm_reg_data_t  reg_data;
    `PCIE_DRIVER_MEM_REQ_SEQ mem_request_seq;
    string msgid;
    rand int test_length;
    rand int loops;

    typedef enum {
    PF = 0,
    VF = 1
    } mode_t;

    rand mode_t afu_mode[HOST_NUM_AFUS];
    rand mode_t reset_mode[HOST_NUM_AFUS];
    rand bit                length_in_dw;
    bit  [63:0]        BAR_OFFSET ;       
    rand bit  [63:0]        ADDR;
    rand bit  [63:0]        FADDR;
    rand bit  [63:0]        PADDR;
    rand bit  [63:0]        VPADDR;
    rand bit  [63:0]        AADDR;
    string                  msgid;
    bit[31:0]               dev_ctl;

    constraint afu_mode_constraint {
        soft test_length inside {[20:25]};
        soft loops       == 0;
        afu_mode[0] == PF;
        reset_mode[0] == PF;

    }

    constraint _pcie_length_c {
    length_in_dw  dist {
     2 := 20,
     1 := 5,
     4 := 1
    
   };

    }

// ---------------------------------------------------------------------------

  function new(string name = "mmio_host_flr_pf_seq");
    super.new(name); 
    msgid=get_type_name();
  endfunction    


// ---------------------------------------------------------------------------

  task body ();
    super.body();
    BAR_OFFSET = tb_cfg1.PF0_BAR0;
    `uvm_info(msgid, "Entered MMIO test Sequence", UVM_LOW);
    uvm_config_db#( bit[3:0])::get(null,"uvm_test_top.*", "PF_NUMB", PF_NUM);
    //uvm_config_db#( bit[0])::get(null,"uvm_test_top.*", "PF_NUMB", PF_NUM);
    test_action();
    #30us;
    `uvm_info(msgid, "Exiting MMIO test  Sequence", UVM_LOW);
  endtask

// ---------------------------------------------------------------------------
  task test_action();
        begin
        `uvm_info(msgid, "Entered test action", UVM_LOW);
     #5us; //Removing fork join as not expecting FLR to happen before the begining of trasactions
     //fork
        `uvm_do_on_with(ac_mmio_seq,p_sequencer,{bypass_config_seq==1;})
        #40us;
        afu_flr_reset();
		#10us;
		`uvm_do_on_with(ac_mmio_seq_1,p_sequencer,{bypass_config_seq==1;})
	    end
       //join 

  endtask: test_action

  task afu_flr_reset();

     PF_NUMBER = PF_NUM;

        `uvm_info(msgid,$sformatf("Entered Primary reset task..."),UVM_LOW);

    //PF0

    if ( PF_NUMBER == 0)
      begin

        `uvm_info(msgid,$sformatf("Initiating PF0 FLR Reset..."),UVM_LOW);
                flr_cfg_rd (.address_('h0), .dev_ctl_(dev_ctl), .is_soc_(1'b0));
                flr_cfg_wr (.address_('h0), .dev_ctl_(dev_ctl), .is_soc_(1'b0)); 
        `uvm_info(msgid,$sformatf("Entering wait statement"),UVM_LOW);
           wait (`HOST_AFU.st2mm.flr_rst_n == 0);
           `uvm_info(msgid,$sformatf("Exiting wait statement"),UVM_LOW);

         #30us;
         pcie_pf_vf_bar(.is_soc_(1'b0));
                        
        //ST2MM PF0_BAR0
        `uvm_info(msgid,$sformatf("Entering ST2MM scratchpad read"),UVM_LOW);
        addr = tb_cfg1.PF0_BAR0+ST2MM_BASE_ADDR+'h0008;
        mmio_read64 (addr, rdata,0);
 
      end
    //PF1
    else if ( PF_NUMBER == 1)
	begin

           `uvm_info(msgid,$sformatf("Initiating PF1 FLR Reset..."),UVM_LOW);
                flr_cfg_rd (.address_('h1), .dev_ctl_(dev_ctl), .is_soc_(1'b0));
                flr_cfg_wr (.address_('h1), .dev_ctl_(dev_ctl), .is_soc_(1'b0)); 
           `uvm_info(msgid,$sformatf("Entering wait statement"),UVM_LOW);
           wait (`HOST_AFU_INSTANCES.port_rst_n[0] == 0);
           `uvm_info(msgid,$sformatf("Exiting wait statement"),UVM_LOW);
         //  #4.30us;
         #30us;
         pcie_pf_vf_bar(.is_soc_(1'b0));

         //HE_LPBK PF2
         addr = tb_cfg1.PF1_BAR0+HE_LB_BASE_ADDR+'h100;
         mmio_read64 (addr, rdata,0);
 
        if(rdata == 0)
            `uvm_info(get_name(), $psprintf("HE_LPBK PF1 Scratchpad is reset, addr = %0h, data = %0h", addr, rdata), UVM_LOW)
        else
            `uvm_error(get_name(), $psprintf("HE_LPBK PF1 Scratchpad is not reset Addr = %0h, data = %0h", addr, rdata))
        end

  endtask: afu_flr_reset

 endclass: mmio_host_flr_pf_seq

`endif

    




    



