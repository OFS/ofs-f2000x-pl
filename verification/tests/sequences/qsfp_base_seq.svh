//Copyright 2021 Intel Corporation
//SPDX-License-Identifier: MIT
//===============================================================================================================
/**
* Abstract:
* class qsfp_base_seq is executed by qsfp_base_seq 
* The sequence extends the uvm_sequence
* This sequence is used to access the QSFP registers from PMCI block 
* Sequence is running on virtual_sequencer
*  
* */
//===============================================================================================================

`ifndef QSFP_BASE_SEQ_SVH
`define QSFP_BASE_SEQ_SVH

class qsfp_base_seq extends uvm_sequence;
  `uvm_object_utils(qsfp_base_seq)
  `uvm_declare_p_sequencer(virtual_sequencer)

  `AXI_MASTER_READ_XACT_SEQUENCE rd_trans;
  qsfp_axi_derived_write_sequence wr_trans;
  virtual `AXI_IF   axi_if;

  function new(string name = "qsfp_base_seq");
      super.new(name);
  endfunction : new


/*  virtual task body ();

    if(!uvm_config_db #(qsfp_tb_config)::get(get_sequencer(),"*","tb_cfg0",tb_cfg0)) begin
       `uvm_fatal(get_name(),"Couldnt able to get config handle")
    end

    qsfp_if = tb_cfg0.qsfp_if;

  endtask:body */

  task rd_tx_register(input [17:0] address,input [63:0] exp_data);

    rd_trans = `AXI_MASTER_READ_XACT_SEQUENCE::type_id::create("rd_trans");
    rd_trans.randomize() with { rd_trans.addr              == address; };
    rd_trans.exp_data          = exp_data;
    rd_trans.start(p_sequencer.pmci_axi4_lt_mst_seqr);

  endtask:rd_tx_register



  task wr_tx_register(input [17:0] address,input [63:0] wdata,input [7:0] wstrobe);
    `uvm_do_on_with(wr_trans,p_sequencer.pmci_axi4_lt_mst_seqr, { 

        wr_trans.addr                  == address;
        wr_trans.data                  == wdata;
        wr_trans.wstrb                 == wstrobe;
        })
  endtask:wr_tx_register


 endclass : qsfp_base_seq

`endif // QSFP_BASE_SEQ_SVH






