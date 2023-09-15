// Copyright (C) 2023 Intel Corporation
// SPDX-License-Identifier: MIT

/**
 * Abstract:
 * The file contains the class extended from uvm_test
 * A simple ethernet_base_test does the following:
 * 1. Instantiates & creates the environment class.
 * 2. Instantiate & sets "mac_address" as a part of configuration,
 *    and passes the MAC/PHY configuration for the two agnets inside 
 *    the environment.
 * 3. Configure the ethernet_simple_reset_sequence as the default sequence
 *    for the reset phase of the TB ENV virtual sequencer
 * 4. Set the default_sequence in the run_phase of virtual sequencer in the environment.
 * 5. Set the default sequence length = 1.
 * 6. Set the Pass/Fail criterion in the final_phase() using report_server. 
 */

`ifndef GUARD_ETHERNET_BASE_TEST_SV
`define GUARD_ETHERNET_BASE_TEST_SV

`include "cust_ethernet_agent_configuration.sv"
`include "ethernet_intermediate_env_10_25.sv"

//class ethernet_base_test extends uvm_test;
class ethernet_base_test extends base_test;

  /** UVM component utility macro */
  `uvm_component_utils(ethernet_base_test)

  /** Instance of the environment */
  ethernet_intermediate_env env;

  /** Instantiate the configuration for MAC*/
  cust_ethernet_agent_configuration mac_cfg;


  /** Class constructor */
  function new(string name = "ethernet_base_test", uvm_component parent=null);
    super.new(name,parent);
  endfunction : new

  /** build() - Method to build various component */
  virtual function void build_phase(uvm_phase phase);
    `uvm_info("build_phase", "Entered ...", UVM_LOW)
    super.build_phase(phase);

    `uvm_info("build_phase", "Exited ...", UVM_LOW)
  endfunction : build_phase
  
  function void final_phase(uvm_phase phase);
    uvm_report_server svr;
    `uvm_info("final_phase", "Entered ...",UVM_LOW)

    super.final_phase(phase);

    svr = uvm_report_server::get_server();

    `uvm_info("final_phase", "Exited ...",UVM_LOW)
  endfunction

  function void disable_VIP_ERR();
    `uvm_info("BASE_TEST", "DISABLE_VIP_ERR ...",UVM_LOW)

        for(int i=0 ;i<8 ; i++) begin
          tb_env0.env.vip_ethernet_mac[i].monitor.err_check_rx.svt_err_xsbi_unexpected_block_between_idle.set_default_fail_effect(svt_err_check_stats::IGNORE);
          tb_env0.env.vip_ethernet_mac[i].monitor.err_check_rx.svt_err_mac_multicast_source_addr_error.set_default_fail_effect(svt_err_check_stats::IGNORE);
          tb_env0.env.vip_ethernet_mac[i].monitor.err_check_rx.svt_err_xsbi_error_control_char.set_default_fail_effect(svt_err_check_stats::IGNORE);
          tb_env0.env.vip_ethernet_mac[i].monitor.err_check_rx.svt_err_xsbi_unexpected_block_within_data.set_default_fail_effect(svt_err_check_stats::IGNORE);
          tb_env0.env.vip_ethernet_mac[i].monitor.err_check_rx.svt_err_xsbi_invalid_sync_header.set_default_fail_effect(svt_err_check_stats::IGNORE);
          tb_env0.env.vip_ethernet_mac[i].monitor.err_check_rx.svt_err_xsbi_unexpected_block_error_after_error.set_default_fail_effect(svt_err_check_stats::IGNORE);
          tb_env0.env.vip_ethernet_mac[i].monitor.err_check_rx.svt_err_xsbi_invalid_block_type_field.set_default_fail_effect(svt_err_check_stats::IGNORE);	   
          tb_env0.env.vip_ethernet_mac[i].monitor.err_check_rx.svt_err_xgmii_error_c_char_not_allowed.set_default_fail_effect(svt_err_check_stats::IGNORE);
          tb_env0.env.vip_ethernet_mac[i].monitor.err_check_rx.svt_err_mac_rsvrd_c_char_not_allowed.set_default_fail_effect(svt_err_check_stats::IGNORE);
          tb_env0.env.vip_ethernet_mac[i].monitor.err_check_rx.svt_err_xsbi_invalid_reserved_field.set_default_fail_effect(svt_err_check_stats::IGNORE);
          tb_env0.env.vip_ethernet_mac[i].monitor.err_check_rx.svt_xsbi_err_unexpected_block_before_str.set_default_fail_effect(svt_err_check_stats::IGNORE);
          tb_env0.env.vip_ethernet_mac[i].monitor.err_check_rx.svt_err_xsbi_invalid_block_with_ordered_set.set_default_fail_effect(svt_err_check_stats::IGNORE);
          tb_env0.env.vip_ethernet_mac[i].monitor.err_check_rx.svt_err_xsbi_unexpected_block_after_terminate.set_default_fail_effect(svt_err_check_stats::IGNORE);
          tb_env0.env.vip_ethernet_mac[i].monitor.err_check_rx.svt_err_xsbi_reserved_control_char.set_default_fail_effect(svt_err_check_stats::IGNORE);
          tb_env0.env.vip_ethernet_mac[i].monitor.err_check_rx.svt_err_xgmii_control_char_in_frame_not_allowed.set_default_fail_effect(svt_err_check_stats::IGNORE);
          tb_env0.env.vip_ethernet_mac[i].monitor.err_check_rx.svt_err_xgmii_no_start_c_char_before_term_c_char.set_default_fail_effect(svt_err_check_stats::IGNORE);
          tb_env0.env.vip_ethernet_mac[i].monitor.err_check_rx.svt_err_xsbi_signal_ordered_set.set_default_fail_effect(svt_err_check_stats::IGNORE); 
          tb_env0.env.vip_ethernet_mac[i].monitor.err_check_rx.svt_err_xgmii_rsvrd_seq_not_allowed.set_default_fail_effect(svt_err_check_stats::IGNORE); 
          tb_env0.env.vip_ethernet_mac[i].monitor.err_check_rx.svt_err_xxvsbi_invalid_reserved_field.set_default_fail_effect(svt_err_check_stats::IGNORE); 
          tb_env0.env.vip_ethernet_mac[i].monitor.err_check_rx.svt_err_xxvsbi_invalid_bit_in_align_marker.set_default_fail_effect(svt_err_check_stats::IGNORE); 
          tb_env0.env.vip_ethernet_mac[i].monitor.err_check_rx.svt_err_xxvsbi_lsbi_invalid_btf.set_default_fail_effect(svt_err_check_stats::IGNORE); 
          tb_env0.env.vip_ethernet_mac[i].monitor.err_check_rx.svt_err_xxvsbi_lsbi_invalid_checksum.set_default_fail_effect(svt_err_check_stats::IGNORE); 
          tb_env0.env.vip_ethernet_mac[i].monitor.err_check_rx.svt_err_xxvsbi_lsbi_invalid_first_five_bit_of_transcode.set_default_fail_effect(svt_err_check_stats::IGNORE);
          tb_env0.env.vip_ethernet_mac[i].monitor.err_check_rx.svt_err_xxvsbi_lsbi_invalid_second_align_marker.set_default_fail_effect(svt_err_check_stats::IGNORE);
        end
  endfunction

  function void enable_VIP_ERR(); 
    `uvm_info("BASE_TEST", "ENABLE_VIP_ERR ...",UVM_LOW)
       
         for(int i=0;i<8;i++) begin
          tb_env0.env.vip_ethernet_mac[i].monitor.err_check_rx.svt_err_xsbi_unexpected_block_between_idle.set_default_fail_effect(svt_err_check_stats::ERROR);
          tb_env0.env.vip_ethernet_mac[i].monitor.err_check_rx.svt_err_xsbi_error_control_char.set_default_fail_effect(svt_err_check_stats::ERROR);
          tb_env0.env.vip_ethernet_mac[i].monitor.err_check_rx.svt_err_xsbi_unexpected_block_within_data.set_default_fail_effect(svt_err_check_stats::ERROR);
          tb_env0.env.vip_ethernet_mac[i].monitor.err_check_rx.svt_err_xsbi_invalid_sync_header.set_default_fail_effect(svt_err_check_stats::ERROR);
          tb_env0.env.vip_ethernet_mac[i].monitor.err_check_rx.svt_err_xsbi_unexpected_block_error_after_error.set_default_fail_effect(svt_err_check_stats::ERROR);
          tb_env0.env.vip_ethernet_mac[i].monitor.err_check_rx.svt_err_xsbi_invalid_block_type_field.set_default_fail_effect(svt_err_check_stats::ERROR);	   
          tb_env0.env.vip_ethernet_mac[i].monitor.err_check_rx.svt_err_xgmii_error_c_char_not_allowed.set_default_fail_effect(svt_err_check_stats::ERROR);
          tb_env0.env.vip_ethernet_mac[i].monitor.err_check_rx.svt_err_mac_rsvrd_c_char_not_allowed.set_default_fail_effect(svt_err_check_stats::ERROR);
          tb_env0.env.vip_ethernet_mac[i].monitor.err_check_rx.svt_err_xsbi_invalid_reserved_field.set_default_fail_effect(svt_err_check_stats::ERROR);
          tb_env0.env.vip_ethernet_mac[i].monitor.err_check_rx.svt_xsbi_err_unexpected_block_before_str.set_default_fail_effect(svt_err_check_stats::ERROR);
          tb_env0.env.vip_ethernet_mac[i].monitor.err_check_rx.svt_err_xsbi_invalid_block_with_ordered_set.set_default_fail_effect(svt_err_check_stats::ERROR);
          tb_env0.env.vip_ethernet_mac[i].monitor.err_check_rx.svt_err_xsbi_unexpected_block_after_terminate.set_default_fail_effect(svt_err_check_stats::ERROR);
          tb_env0.env.vip_ethernet_mac[i].monitor.err_check_rx.svt_err_xsbi_reserved_control_char.set_default_fail_effect(svt_err_check_stats::ERROR);
          tb_env0.env.vip_ethernet_mac[i].monitor.err_check_rx.svt_err_xgmii_control_char_in_frame_not_allowed.set_default_fail_effect(svt_err_check_stats::ERROR);
          tb_env0.env.vip_ethernet_mac[i].monitor.err_check_rx.svt_err_xgmii_no_start_c_char_before_term_c_char.set_default_fail_effect(svt_err_check_stats::ERROR);
          tb_env0.env.vip_ethernet_mac[i].monitor.err_check_rx.svt_err_xsbi_signal_ordered_set.set_default_fail_effect(svt_err_check_stats::ERROR); 
          tb_env0.env.vip_ethernet_mac[i].monitor.err_check_rx.svt_err_xgmii_rsvrd_seq_not_allowed.set_default_fail_effect(svt_err_check_stats::ERROR); 
          tb_env0.env.vip_ethernet_mac[i].monitor.err_check_rx.svt_err_xxvsbi_invalid_reserved_field.set_default_fail_effect(svt_err_check_stats::ERROR); 
          tb_env0.env.vip_ethernet_mac[i].monitor.err_check_rx.svt_err_xxvsbi_invalid_bit_in_align_marker.set_default_fail_effect(svt_err_check_stats::ERROR); 
          tb_env0.env.vip_ethernet_mac[i].monitor.err_check_rx.svt_err_xxvsbi_lsbi_invalid_btf.set_default_fail_effect(svt_err_check_stats::ERROR); 
          tb_env0.env.vip_ethernet_mac[i].monitor.err_check_rx.svt_err_xxvsbi_lsbi_invalid_checksum.set_default_fail_effect(svt_err_check_stats::ERROR); 
          tb_env0.env.vip_ethernet_mac[i].monitor.err_check_rx.svt_err_xxvsbi_lsbi_invalid_first_five_bit_of_transcode.set_default_fail_effect(svt_err_check_stats::ERROR);
          tb_env0.env.vip_ethernet_mac[i].monitor.err_check_rx.svt_err_xxvsbi_lsbi_invalid_second_align_marker.set_default_fail_effect(svt_err_check_stats::ERROR);
         end
   endfunction



endclass

`endif
