// Copyright (C) 2023 Intel Corporation
// SPDX-License-Identifier: MIT

//===============================================================================================================
/**
* Abstract:
* class he_lbbk_thruput_contmode_seq is executed by he_lbbk_thruput_contmode_test.
* 
* This sequence verifies the thruput continuous mode functionality   
* The sequence extends the he_lpbk_seq.  
* Sequence is running on virtual_sequencer.
*/
//=========================================================================================================

`ifndef HE_LPBK_THRUPUT_CONTMODE_SEQ_SVH
`define HE_LPBK_THRUPUT_CONTMODE_SEQ_SVH

class he_lpbk_thruput_contmode_seq extends he_lpbk_seq;
    `uvm_object_utils(he_lpbk_thruput_contmode_seq)
    `uvm_declare_p_sequencer(virtual_sequencer)

    constraint mode_c { mode == 3'b011; } // Thruput only
    
    constraint cont_mode_c {
        cont_mode == 1;
    }                                     //Continuous Mode enabled

    function new(string name = "he_lpbk_thruput_contmode_seq");
        super.new(name);
    endfunction : new

endclass : he_lpbk_thruput_contmode_seq
`endif // HE_LPBK_THRUPUT_CONTMODE_SEQ_SVH

