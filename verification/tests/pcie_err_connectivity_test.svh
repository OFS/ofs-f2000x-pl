// Copyright (C) 2023 Intel Corporation
// SPDX-License-Identifier: MIT

`ifndef PCIE_ERR_CONNECTIVITY_TEST_SVH
`define PCIE_ERR_CONNECTIVITY_TEST_SVH

class pcie_err_connectivity_test extends base_test;
    `uvm_component_utils(pcie_err_connectivity_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

  task run_phase(uvm_phase phase);
  pcie_err_connectivity_seq m_seq;
  super.run_phase(phase);
	phase.raise_objection(this);
	m_seq = pcie_err_connectivity_seq::type_id::create("m_seq");
	m_seq.start(tb_env0.v_sequencer);
	phase.drop_objection(this);
    endtask : run_phase

endclass : pcie_err_connectivity_test

`endif // PCIE_ERR_CONNECTIVITY_TEST_SVH
