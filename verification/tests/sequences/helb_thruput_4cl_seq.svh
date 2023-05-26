// Copyright (C) 2023 Intel Corporation
// SPDX-License-Identifier: MIT

//===============================================================================================================
/**
* Abstract:
* class helb_thruput_4cl_seq is executed by helb_thruput_4cl_test.
* 
* This sequence verifies the thruput-mode functionality of the HE-LPBK module  
* The sequence extends the he_lpbk_seq and it is constraint for 4-cache-line read 
*  The number of read and write  transaction is verified comparing with DSM status register
* Sequence is running on virtual_sequencer.
/
*/
//============================================================================================================

`ifndef HELB_THRUPUT_4CL_SEQ_SVH
`define HELB_THRUPUT_4CL_SEQ_SVH

class helb_thruput_4cl_seq extends he_lpbk_seq;
    `uvm_object_utils(helb_thruput_4cl_seq)
    `uvm_declare_p_sequencer(virtual_sequencer)

    constraint mode_c { mode == 3'b011; } // Thruput 
    constraint num_lines_c { num_lines == 1024; }
    constraint req_len_c { req_len == 2'b10; }
    constraint report_perf_data_c { report_perf_data == 1; }

    function new(string name = "helb_thruput_4cl_seq");
        super.new(name);
    endfunction : new

endclass : helb_thruput_4cl_seq

`endif // HELB_THRUPUT_4CL_SEQ_SVH
