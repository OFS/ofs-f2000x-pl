// Copyright (C) 2023 Intel Corporation
// SPDX-License-Identifier: MIT

`ifndef SOC_BASE_TEST_SVH
`define SOC_BASE_TEST_SVH

class soc_base_test extends uvm_test;
    `uvm_component_utils(soc_base_test)

    iofs_ac_tb_config tb_cfg0;
    iofs_ac_tb_config tb_cfg1;
    iofs_ac_tb_env    tb_env0;
    uvm_table_printer printer;
    int               regress_mode_en;
    int               timeout;
    int               test_pass = 1;
    int               sim_length_reached;
    uvm_report_object reporter;
    bit               exp_timeout = 0;

    function new(string name, uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    virtual function void build_phase(uvm_phase phase);
        string regress_mode_en_str;
        super.build_phase(phase);
	tb_cfg0 = iofs_ac_tb_config::type_id::create("tb_cfg0", this);
	tb_cfg0.pcie_cfg.root_cfg = new();
	tb_cfg0.pcie_cfg.setup_pcie_device_system_defaults();
        randomize(tb_cfg0);
	tb_cfg0.enable = 1;
	uvm_config_db #(iofs_ac_tb_config)::set(this, "tb_env0","tb_cfg0", tb_cfg0);
	tb_cfg1 = iofs_ac_tb_config::type_id::create("tb_cfg1", this);
	tb_cfg1.pcie_cfg.root_cfg = new();
	tb_cfg1.pcie_cfg.setup_pcie_device_system_defaults();
	tb_cfg1.pcie_cfg.root_cfg.pcie_cfg.transaction_log_filename = "trans_root1.log";
        randomize(tb_cfg1);
	tb_cfg1.enable = 0;
	uvm_config_db #(iofs_ac_tb_config)::set(this, "tb_env0","tb_cfg1", tb_cfg1);

	tb_env0 = iofs_ac_tb_env::type_id::create("tb_env0", this);

	/** Set the default_sequence for slave vip */
        //uvm_config_db#(uvm_object_wrapper)::set(this, "tb_env0.axi_system_env.slave[0].sequencer.run_phase", "default_sequence", axi_slave_mem_response_sequence::type_id::get());
        /** Apply the default reset sequence */
        //uvm_config_db#(uvm_object_wrapper)::set(this, "tb_env0.sequencer.reset_phase", "default_sequence", axi_simple_reset_sequence::type_id::get());
        //uvm_config_db#(uvm_object_wrapper)::set(this, "tb_env0.v_sequencer.configure_phase", "default_sequence", iofs_ac_config_seq::type_id::get());

        printer = new();
        printer.knobs.depth = 5;
        printer.knobs.name_width = 40;
        printer.knobs.type_width = 32;
        printer.knobs.value_width = 32;

        if($value$plusargs("REGRESS_MODE=%s", regress_mode_en_str)) begin
            regress_mode_en = regress_mode_en_str.atoi();   //1-Regress Mode 0-Smoke Mode
            set_config_int("*.v_sequencer", "regress_mode_en", regress_mode_en);
        end		
	
    endfunction : build_phase

    function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
	uvm_top.print_topology();
    endfunction : end_of_elaboration_phase

    //task configure_phase(uvm_phase phase);
    //    iofs_ac_config_seq config_seq;
    //    super.configure_phase(phase);
    //    config_seq = iofs_ac_config_seq::type_id::create("config_seq");
    //    config_seq.start(tb_env0.v_sequencer);
    //endtask : configure_phase


    virtual task timeout_watch(uvm_phase phase);
        string msgid;
        int timeout,flush_timeout;
        string timeout_str;
        
        msgid = get_name();
        timeout=this.timeout;

        if(!timeout) begin
            if($value$plusargs("TIMEOUT=%s", timeout_str)) begin
                timeout = timeout_str.atoi();   // in us
            end else
                timeout = 2000;
        end

        reporter.uvm_report_info(msgid, $psprintf("TIMEOUT = %d", timeout), UVM_LOW);            
        repeat(timeout) begin
            # 1us;         
        end
        sim_length_reached = 1;
        reporter.uvm_report_info(msgid, "Reached simulation duration, finishing test...", UVM_LOW);
 
        //Regress mode tests run for 'timeout', so need larger flush times       
        flush_timeout=(timeout>2000)?2*timeout:2000;

        repeat(flush_timeout) begin
            # 1us;         
        end
        test_pass = 0;
        if(regress_mode_en) phase.phase_done.display_objections();
        if (exp_timeout) begin
            `uvm_warning(msgid, "*** TIMED OUT! ***")   
            phase.phase_done.display_objections();
        end else begin
            `uvm_fatal(msgid, "*** TIMED OUT! ***")    
        end
    endtask : timeout_watch

    //function void final_phase(uvm_phase phase);
    //    uvm_report_server svr;
    //    `uvm_info("final_phase", "Entered...", UVM_LOW)
    //    super.final_phase(phase);
    //    svr = uvm_report_server::get_server();
    //    if(svr.get_severity_count(UVM_FATAL) +
    //       svr.get_severity_count(UVM_ERROR) +
    //       svr.get_severity_count(UVM_WARNING) > 0)
    //        `uvm_info("final_phase", "\nSvtTestEpilog: Failed\n", UVM_LOW)
    //    else
    //        `uvm_info("final_phase", "\nSvtTestEpilog: Passed\n", UVM_LOW)

    //    `uvm_info("final_phase", "Exiting...", UVM_LOW)
    //endfunction : final_phase

endclass : soc_base_test

`endif // SOC_BASE_TEST_SVH
