// Copyright (C) 2023 Intel Corporation
// SPDX-License-Identifier: MIT

//===============================================================================================================
/**
* Abstract:
* class he_mem_lpbk_reqlen8_seq is executed by he_mem_lpbk_reqlen8_test
* 
* This sequence verifies the loopback functionality of the HE-MEM_LPBK module  
* The sequence extends the he_mem_lpbk_seq and it is constraint for req_len 8 
* Sequence is running on virtual_sequencer 
*/
//=========================================================================================================
`ifndef HE_MEM_LPBK_REQLEN8_SEQ_SVH
`define HE_MEM_LPBK_REQLEN8_SEQ_SVH

class he_mem_lpbk_reqlen8_seq extends he_mem_lpbk_seq;
    `uvm_object_utils(he_mem_lpbk_reqlen8_seq)
    `uvm_declare_p_sequencer(virtual_sequencer)

    constraint req_len_c   { req_len == 4'b11; }
    constraint num_lines_c { num_lines == 128; }

    function new(string name = "he_mem_lpbk_reqlen8_seq");
        super.new(name);
    endfunction : new

endclass : he_mem_lpbk_reqlen8_seq

`endif // HE_MEM_LPBK_REQLEN8_SEQ_SVH
