// Copyright (C) 2023 Intel Corporation
// SPDX-License-Identifier: MIT

`ifndef  IOFS_AC_MEM_TG_CH_HOP_TEST_SVH
 `define  IOFS_AC_MEM_TG_CH_HOP_TEST_SVH

class  mem_tg_ch_hop_test extends base_test;
   `uvm_component_utils(mem_tg_ch_hop_test)

   function new(string name, uvm_component parent);
      super.new(name, parent);
   endfunction : new

   task run_phase(uvm_phase phase);
      mem_tg_ch_hop_seq m_seq;
      super.run_phase(phase);
      phase.raise_objection(this);
      m_seq = mem_tg_ch_hop_seq::type_id::create("m_seq");
      m_seq.start(tb_env0.v_sequencer);
      phase.drop_objection(this);
   endtask : run_phase

endclass : mem_tg_ch_hop_test
`endif //  IOFS_AC_MEM_TG_CH_HOP_TEST_SVH
