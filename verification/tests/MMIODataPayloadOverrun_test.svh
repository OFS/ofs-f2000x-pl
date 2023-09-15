// Copyright (C) 2023 Intel Corporation
// SPDX-License-Identifier: MIT

`ifndef MMIODATAPAYLOADOVERRUN_TEST_SVH
`define MMIODATAPAYLOADOVERRUN_TEST_SVH

class MMIODataPayloadOverrun_callback extends `AXI_SLAVE_CALLBACK;
  function new(string name = "MMIODataPayloadOverrun_callback");
     super.new(name);
  endfunction : new

  virtual function void pre_read_data_phase_started(`AXI_SLAVE axi_slave , `AXI_TRANSACTION_CLASS xact);
     $display("Yang in pre_read_data_phase_started");
     // change MMIO response data payload to satisfy mmio_rsp.data.size() > mmio_rsp.length
  endfunction : pre_read_data_phase_started

endclass : MMIODataPayloadOverrun_callback


class MMIODataPayloadOverrun_test extends base_test;
   rand bit[1:0] wrrd_randcode;
   rand bit[2:0] tc;
   MMIODataPayloadOverrun_callback err_callback;

   constraint t_avmmdma {
      wrrd_randcode inside {0, 1};
      tc dist {0 := 50, [1:7] := 50};
   }

  `uvm_component_utils(MMIODataPayloadOverrun_test)
   `VIP_ERR_CATCHER_CLASS err_catcher;
   function new(string name = "MMIODataPayloadOverrun_test", uvm_component parent=null);
      super.new(name,parent);
   endfunction : new

   virtual function void build();

     super.build();
     err_callback = new("err_callback");
     err_catcher=new();
     //add error message string to error catcher 
     err_catcher.add_message_id_to_demote("/register_fail:ACTIVE_DRIVER_APP:COMPLETION:appl_driver_high_byte_count/");
     err_catcher.add_message_id_to_demote("/register_fail:ACTIVE_DRIVER_APP:COMPLETION:appl_driver_mem_read_bad_cpl_lower_addr/");
     uvm_report_cb::add(null,err_catcher);
                         
   endfunction : build 

  virtual function void connect_phase(uvm_phase phase);
     super.connect_phase(phase);
     uvm_callbacks#(`AXI_SLAVE, `AXI_SLAVE_CALLBACK)::add(tb_env0.axi_system_env.slave[0].driver, err_callback);
  endfunction : connect_phase

  task run_phase(uvm_phase phase);
     
     `PCIE_TL_SERV_SET_TC_MAP_SEQ tl_serv;
     MMIODataPayloadOverrun_seq m_seq;
     super.run_phase(phase);
     phase.raise_objection(this);
     m_seq =MMIODataPayloadOverrun_seq::type_id::create("m_seq");
     m_seq.start(tb_env0.v_sequencer);
     phase.drop_objection(this);
 
     uvm_config_db#(int unsigned)::set(this, "*", "tc", tc);

     `uvm_info(get_name(), "deasserted_overrun_bit...", UVM_LOW)
     
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








