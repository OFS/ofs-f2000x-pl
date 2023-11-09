// Copyright (C) 2023 Intel Corporation
// SPDX-License-Identifier: MIT

`ifndef MMIOINSUFFICIENTDATA_TEST_SVH
`define MMIOINSUFFICIENTDATA_TEST_SVH

class MMIOInsufficientData_callback extends `AXI_SLAVE_CALLBACK;
    function new(string name = "MMIOInsufficientData_callback");
        super.new(name);
    endfunction : new

    virtual function void pre_read_data_phase_started(`AXI_SLAVE axi_slave , `AXI_TRANSACTION_CLASS xact);
        $display("Yang in pre_read_data_phase_started");
        // change MMIO response data payload to satisfy mmio_rsp.data.size() < mmio_rsp.length
    endfunction : pre_read_data_phase_started

endclass : MMIOInsufficientData_callback


class MMIOInsufficientData_test extends base_test;
    rand bit[1:0] wrrd_randcode;
    rand bit[2:0] tc;
    MMIOInsufficientData_callback err_callback;

   constraint t_avmmdma {
      wrrd_randcode inside {0, 1};
      tc dist {0 := 50, [1:7] := 50};
   }

  `uvm_component_utils(MMIOInsufficientData_test)
   `VIP_ERR_CATCHER_CLASS err_catcher;
   function new(string name = "MMIOInsufficientData_test", uvm_component parent=null);
      super.new(name,parent);
   endfunction : new

   virtual function void build();
        
     super.build();
     err_callback = new("err_callback");
     err_catcher=new();
   //add error message string to error catcher 
     err_catcher.add_message_id_to_demote("/register_fail:ACTIVE_DRIVER_APP:COMPLETION:appl_driver_low_byte_count/");
     err_catcher.add_message_id_to_demote("/register_fail:ACTIVE_DRIVER_APP:COMPLETION:appl_driver_mem_read_bad_cpl_lower_addr/");
     uvm_report_cb::add(null,err_catcher);
			
  endfunction : build 

  task run_phase(uvm_phase phase);
     
    `PCIE_TL_SERV_SET_TC_MAP_SEQ tl_serv;
    MMIOInsufficientData_seq m_seq;
    super.run_phase(phase);
    phase.raise_objection(this);
    m_seq =MMIOInsufficientData_seq::type_id::create("m_seq");
    m_seq.start(tb_env0.v_sequencer);
    phase.drop_objection(this);
 
    uvm_config_db#(int unsigned)::set(this, "*", "tc", tc);

    //-------------------------------------------
    // By default PCIe VIP has traffic_class =0
    // For non_zero TC, need to set up VC as below.
    //-------------------------------------------
    tl_serv = `PCIE_TL_SERV_SET_TC_MAP_SEQ::type_id::create("tl_serv");
    tl_serv.tc_enable = 1;
    tl_serv.tc_num = tc;
    tl_serv.vc_num = 0;
    tl_serv.start(tb_env0.root.pcie_agent.tl_seqr);

  endtask : run_phase         

endclass
`endif








