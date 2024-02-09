// Copyright (C) 2023 Intel Corporation
// SPDX-License-Identifier: MIT

`ifndef HOST_PCIE_CSR_TEST_SVH
`define HOST_PCIE_CSR_TEST_SVH

class host_pcie_csr_test extends base_test;
    `uvm_component_utils(host_pcie_csr_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

  task run_phase(uvm_phase phase);
  host_pcie_csr_seq m_seq;
  super.run_phase(phase);
	phase.raise_objection(this);
	m_seq = host_pcie_csr_seq::type_id::create("m_seq");
	m_seq.start(tb_env0.v_sequencer);
	phase.drop_objection(this);
    endtask : run_phase

endclass : host_pcie_csr_test

`endif // PCIE_CSR_TEST_SVH
