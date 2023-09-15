// Copyright (C) 2023 Intel Corporation
// SPDX-License-Identifier: MIT

`ifndef MMIOTIMEDOUT_TEST_SVH
`define MMIOTIMEDOUT_TEST_SVH

class MMIOTimedOut_callback extends `AXI_SLAVE_CALLBACK;
  function new(string name = "MMIOTimedOut_callback");
      super.new(name);
  endfunction : new

  virtual function void post_input_port_get(`AXI_SLAVE axi_slave, `AXI_TRANSACTION_CLASS xact , ref bit drop);
      $display("Yang in post_input_port_get");
  endfunction : post_input_port_get 

endclass : MMIOTimedOut_callback


class MMIOTimedout_test extends base_test;
   rand bit[1:0] wrrd_randcode;
   rand bit[2:0] tc;
   MMIOTimedOut_callback err_callback;

   constraint t_avmmdma {
      wrrd_randcode inside {0, 1};
      tc dist {0 := 50, [1:7] := 50};
   }
    
  `uvm_component_utils(MMIOTimedout_test)
   `VIP_ERR_CATCHER_CLASS err_catcher;

  function new(string name = "MMIOTimedout_test", uvm_component parent=null);
     super.new(name,parent);
  endfunction : new

  virtual function void build();

     super.build();
     err_callback = new("err_callback");
     err_catcher=new();
     err_catcher.add_message_id_to_demote("/register_fail:ACTIVE_DRIVER_APP:COMPLETION:appl_driver_mem_read_bad_cpl_lower_addr/");
     uvm_report_cb::add(null,err_catcher);

  endfunction : build 

  task run_phase(uvm_phase phase);
    
     `PCIE_TL_SERV_SET_TC_MAP_SEQ tl_serv;
     MMIOTimedOut_seq m_seq;
     super.run_phase(phase);
     phase.raise_objection(this);
     m_seq =MMIOTimedOut_seq::type_id::create("m_seq");
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








