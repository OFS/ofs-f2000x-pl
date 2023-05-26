// Copyright (C) 2023 Intel Corporation
// SPDX-License-Identifier: MIT

`ifndef HE_MEM_ERR_TEST_SVH
`define HE_MEM_ERR_TEST_SVH

class he_mem_err_test extends base_test;
    `uvm_component_utils(he_mem_err_test)
	
	`VIP_ERR_CATCHER_CLASS err_catcher;
	err_demoter demote;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

   virtual function void build();
 	super.build();
    
    err_catcher=new();
    demote = new();
  //VIP errors and 2 sequence errors is expected as num_lines is made 'h0, hence demoted the error 
    err_catcher.add_message_id_to_demote("/register_fail:ACTIVE_TARGET_APP:MEMORY_REQ:appl_target_uninitialized_mem_data/");
    uvm_report_cb::add(null,err_catcher);
    uvm_report_cb::add(null, demote);

    endfunction: build

    task run_phase(uvm_phase phase);
        he_mem_err_seq m_seq;
        super.run_phase(phase);
	phase.raise_objection(this);
	m_seq = he_mem_err_seq::type_id::create("m_seq");
    m_seq.randomize();
	m_seq.start(tb_env0.v_sequencer);
	phase.drop_objection(this);
    endtask : run_phase

endclass : he_mem_err_test

`endif // HE_MEM_ERR_TEST_SVH
