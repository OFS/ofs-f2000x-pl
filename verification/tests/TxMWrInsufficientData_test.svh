// Copyright (C) 2023 Intel Corporation
// SPDX-License-Identifier: MIT

`ifndef  TXMWRINSUFFICIENTDATA_TEST_SVH
`define  TXMWRINSUFFICIENTDATA_TEST_SVH

class TxMWrInsufficientData_test extends base_test;
  rand bit[2:0] tc;
  constraint t_avmmdma {
    tc dist {0 := 50, [1:7] := 50};
  }

  `uvm_component_utils(TxMWrInsufficientData_test)

  function new(string name = "TxMWrInsufficientData_test", uvm_component parent=null);
    super.new(name,parent);
  endfunction : new

  virtual function void build();
    super.build();
    assert(this.randomize());
    uvm_config_db#(int)::set(this, "*tb_env0*", "rx_err_enable", 8'b0000_1000);
    uvm_config_db#(int)::set(this, "*tb_env0*", "flush_disable", 1);
    //set_config_int("*tb_env0*", "rx_err_enable", 8'b0000_1000);
    //set_config_int("*tb_env0*", "flush_disable", 1);
  endfunction : build 

 task run_phase(uvm_phase phase);
    TxMWrInsufficientData_seq   m_seq;
    `PCIE_TL_SERV_SET_TC_MAP_SEQ tl_serv;
    super.run_phase(phase);
    phase.raise_objection(this);
    m_seq =TxMWrInsufficientData_seq::type_id::create("m_seq");
    m_seq.randomize();
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
