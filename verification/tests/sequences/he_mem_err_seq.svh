// Copyright (C) 2023 Intel Corporation
// SPDX-License-Identifier: MIT

`ifndef HE_MEM_ERR_SEQ_SVH
`define HE_MEM_ERR_SEQ_SVH

class he_mem_err_seq extends he_lpbk_seq;
   `uvm_object_utils(he_mem_err_seq)
    `uvm_declare_p_sequencer(virtual_sequencer)
   
    constraint he_mem_c { he_mem == 1; }
      constraint req_len_c   { req_len == 2'b0; }
    constraint num_lines_c { num_lines == 0; } 

     function new(string name = "he_mem_err_seq");
      super.new(name);
     endfunction : new


endclass : he_mem_err_seq

`endif

