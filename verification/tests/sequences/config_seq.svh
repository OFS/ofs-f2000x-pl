//Copyright 2021 Intel Corporation
//SPDX-License-Identifier: MIT
//===============================================================================================================
/**
 * Abstract:
 * class config_seq is executed from base sequence.
 * 
 * This sequence initiates the PCIE_VIP link-up sequence and enumeration sequence.
 * Once enumeraion is done it generates the soft_reset
 *
 * Sequence is running on virtual_sequencer .
 *
 */
//===============================================================================================================

`ifndef CONFIG_SEQ_SVH
`define CONFIG_SEQ_SVH

class config_seq extends uvm_sequence;
    `uvm_object_utils(config_seq)
    `uvm_declare_p_sequencer(virtual_sequencer)

    tb_config                  tb_cfg0;
    pcie_device_bring_up_link_sequence bring_up_link_seq;
    enumerate_seq                      enumerate_seq, root1_enumerate_seq;
    bit [2:0]                          tc;
    //enumerate_seq                      root1_enumerate_seq;
    tb_config                  tb_cfg1;
    pcie_device_bring_up_link_sequence root1_bring_up_link_seq;

    function new(string name = "config_seq");
        super.new(name);
    endfunction : new

    task body();
        bit status;
        super.body();
	`uvm_info(get_name(), $psprintf("Entering config sequence tb_cfg0.enabled = %0d tb_cfg1.enabled = %0d", tb_cfg0.enable, tb_cfg1.enable), UVM_LOW)
	fork
	begin
	  if(tb_cfg0.enable == 1) begin
	    // linkup
	    `uvm_info(get_name(), "Root0 Linking up...", UVM_LOW)
	    `uvm_do_on(bring_up_link_seq, p_sequencer.root_virt_seqr)
	    `uvm_info(get_name(), "Root0 Link is up now", UVM_LOW)
	    // enumerating PCIe HIP
	    `uvm_info(get_name(), "Root0 Enumerating...", UVM_LOW)
	    `uvm_do_on_with(enumerate_seq, p_sequencer.root_virt_seqr.driver_transaction_seqr[0],{
              pf0_bar0     == tb_cfg0.PF0_BAR0;  
              pf0_bar4     == tb_cfg0.PF0_BAR4;  
             // pf1_bar0     == tb_cfg0.PF1_BAR0;
              /*pf2_bar0     == tb_cfg0.PF2_BAR0;
              pf3_bar0     == tb_cfg0.PF3_BAR0;
              pf4_bar0     == tb_cfg0.PF4_BAR0;
              pf0_expansion_rom_bar == tb_cfg0.PF0_EXP_ROM_BAR0;*/
              pf0_vf0_bar0 == tb_cfg0.PF0_VF0_BAR0;
              pf0_vf0_bar4 == tb_cfg0.PF0_VF0_BAR4;
              pf0_vf1_bar0 == tb_cfg0.PF0_VF1_BAR0;
              pf0_vf2_bar0 == tb_cfg0.PF0_VF2_BAR0;
               is_soc == 1;
              //pf1_vf0_bar0 == tb_cfg0.PF1_VF0_BAR0;
             })
             enumerate_seq.print();
	    `uvm_info(get_name(), "Root0 Enumeration is done", UVM_LOW)
	  end
	end
	begin
	  if(tb_cfg1.enable == 1) begin
	    // linkup
	    `uvm_info(get_name(), "Root1 Linking up...", UVM_LOW)
	    `uvm_do_on(root1_bring_up_link_seq, p_sequencer.root1_virt_seqr)
	    `uvm_info(get_name(), "Root1 Link is up now", UVM_LOW)
	    // enumerating PCIe HIP
	    `uvm_info(get_name(), $psprintf("Root1 Enumerating... PF0_BAR0 = %0h", tb_cfg1.PF0_BAR0), UVM_LOW)
	    `uvm_do_on_with(root1_enumerate_seq, p_sequencer.root1_virt_seqr.driver_transaction_seqr[0],{
	      // TODO
              pf0_bar0     == tb_cfg1.PF0_BAR0;  
             // pf0_bar4     == tb_cfg1.PF0_BAR4;  
              pf1_bar0     == tb_cfg1.PF1_BAR0;
              pf1_bar4     == tb_cfg1.PF1_BAR4;
             /* pf2_bar0     == tb_cfg1.PF2_BAR0;
              pf3_bar0     == tb_cfg1.PF3_BAR0;
              pf4_bar0     == tb_cfg1.PF4_BAR0;
              pf0_expansion_rom_bar == tb_cfg1.PF0_EXP_ROM_BAR0;*/
              //pf0_vf0_bar0 == tb_cfg1.PF0_VF0_BAR0;
              //pf0_vf0_bar4 == tb_cfg1.PF0_VF0_BAR4;
              //pf0_vf1_bar0 == tb_cfg1.PF0_VF1_BAR0;
              //pf0_vf2_bar0 == tb_cfg1.PF0_VF2_BAR0;
              //pf1_vf0_bar0 == tb_cfg1.PF1_VF0_BAR0;
               is_soc == 0;
             })
             root1_enumerate_seq.print();
	    `uvm_info(get_name(), "Root1 Enumeration is done", UVM_LOW)
	  end
	end
        join

	status = uvm_config_db #(int unsigned)::get(null, get_full_name(), "tc", tc);
	tc = (status) ? tc : 0;

        // initial port reset
	`uvm_info(get_name(), "Port reseting", UVM_LOW)
	// TODO
	fork 
         begin
	  if(tb_cfg0.enable == 1) begin
             port_rst();
          end
         end
         begin
	  if(tb_cfg1.enable == 1) begin
	    // port_rst_root1(); //check with sonith
          end
         end
        join
	`uvm_info(get_name(), "Port reset is done", UVM_LOW)

	`uvm_info(get_name(), "Exiting config sequence", UVM_LOW)
    endtask : body

    task port_rst();
        `PCIE_DRIVER_WAIT_FOR_COMPL_SEQ wait_for_compl_seq; 
        `PCIE_DRIVER_TRANSACTION_CLASS                     r_trans;
	`PCIE_DRIVER_MEM_REQ_SEQ            w_trans;
	bit [63:0]                                          rdata, wdata;

        `uvm_do_on_with(r_trans, p_sequencer.root_virt_seqr.driver_transaction_seqr[0], { 
	    r_trans.transaction_type    == `PCIE_DRIVER_TRANSACTION_CLASS::MEM_RD;
            r_trans.address             == tb_cfg0.PF0_BAR0+PORT_GASKET_BASE_ADDR+'h1038;
            r_trans.length              == 2;
            r_trans.traffic_class       == 0;
            r_trans.address_translation == 0;
            r_trans.first_dw_be         == 4'b1111;
            r_trans.last_dw_be          == 4'b1111;
            r_trans.ep                  == 0;
            r_trans.th                  == 0;
            r_trans.block               == 0; 
	})
        `uvm_do_on_with(wait_for_compl_seq, p_sequencer.root_virt_seqr.driver_seqr[0], {
	    wait_for_compl_seq.command_num == r_trans.command_num;
	})
        rdata = { changeEndian (r_trans.payload[1]), changeEndian (r_trans.payload[0])} ;

        if(rdata[0])begin
            `uvm_info(get_name(), $psprintf("Port reset bit is set to default 0x1 value. PORT_CONTROL = %0h", rdata), UVM_LOW)
            wdata = {rdata[63:1],1'b0};// De-assert Port reset by writing 1'b0 on PORT_CONTROL[0]
            //STEP 1: write Port Control Reset bit PORT_CONTROL[0]
            `uvm_do_on_with(w_trans,p_sequencer.root_virt_seqr.driver_transaction_seqr[0], { 
                w_trans.transaction_type    == `PCIE_DRIVER_TRANSACTION_CLASS::MEM_WR;
                w_trans.address             == tb_cfg0.PF0_BAR0+PORT_GASKET_BASE_ADDR+'h1038;
                w_trans.length              == 'h2;
                w_trans.traffic_class       == tc; 
                w_trans.address_translation == 0;
                w_trans.first_dw_be         == 4'b1111;
                w_trans.last_dw_be          == 4'b1111;
                w_trans.th                  == 0;
                w_trans.ep                  == 0;
                w_trans.write_payload[0]    == changeEndian(wdata[31:0]);
                w_trans.write_payload[1]    == changeEndian(wdata[63:32]);
                w_trans.block               == 0; 
            })
            #1us;
            //Read port_control Reg to see PortSoftResetAck- PORT_CONTROL[4] set to 1'b0
            `uvm_do_on_with(r_trans,p_sequencer.root_virt_seqr.driver_transaction_seqr[0], {
                r_trans.transaction_type    == `PCIE_DRIVER_TRANSACTION_CLASS::MEM_RD;
                r_trans.address             == tb_cfg0.PF0_BAR0+PORT_GASKET_BASE_ADDR+'h1038;
                r_trans.length              == 2;
                r_trans.traffic_class       == 0;
                r_trans.address_translation == 0;
                r_trans.first_dw_be         == 4'b1111;
                r_trans.last_dw_be          == 4'b1111;
                r_trans.ep                  == 0;
                r_trans.th                  == 0;
                r_trans.block               == 0; 
            })

            `uvm_do_on_with(wait_for_compl_seq,p_sequencer.root_virt_seqr.driver_seqr[0], {
	        wait_for_compl_seq.command_num == r_trans.command_num;
	    })
            rdata = { changeEndian (r_trans.payload[1]), changeEndian (r_trans.payload[0])} ;
            if(rdata[4] != 0)
                `uvm_error(get_name(), $psprintf("Port reset is not released, PortSoftResetAck is still 1'b1! PORT_CONTROL = %0h", rdata))

        end
        else begin
            `uvm_error(get_name(), $psprintf("Port reset bit is not set to default 0x1 value. PORT_CONTROL = %0h", rdata))
            if(rdata[4] != 0)
              `uvm_error(get_name(), $psprintf("Port reset is not released, PortSoftResetAck is still 1'b1! PORT_CONTROL = %0h", rdata))
        end
	
    endtask : port_rst

    task port_rst_root1();
        `PCIE_DRIVER_WAIT_FOR_COMPL_SEQ wait_for_compl_seq; 
        `PCIE_DRIVER_TRANSACTION_CLASS                     r_trans;
	`PCIE_DRIVER_MEM_REQ_SEQ            w_trans;
	bit [63:0]                                          rdata, wdata;

        `uvm_do_on_with(r_trans, p_sequencer.root1_virt_seqr.driver_transaction_seqr[0], { 
	    r_trans.transaction_type    == `PCIE_DRIVER_TRANSACTION_CLASS::MEM_RD;
            r_trans.address             == tb_cfg1.PF0_BAR0+PORT_GASKET_BASE_ADDR+'h1038;
            r_trans.length              == 2;
            r_trans.traffic_class       == 0;
            r_trans.address_translation == 0;
            r_trans.first_dw_be         == 4'b1111;
            r_trans.last_dw_be          == 4'b1111;
            r_trans.ep                  == 0;
            r_trans.th                  == 0;
            r_trans.block               == 0; 
	})
        `uvm_do_on_with(wait_for_compl_seq, p_sequencer.root1_virt_seqr.driver_seqr[0], {
	    wait_for_compl_seq.command_num == r_trans.command_num;
	})
        rdata = { changeEndian (r_trans.payload[1]), changeEndian (r_trans.payload[0])} ;

        if(rdata[0])begin
            `uvm_info(get_name(), $psprintf("Port reset bit is set to default 0x1 value. PORT_CONTROL = %0h", rdata), UVM_LOW)
            wdata = {rdata[63:1],1'b0};// De-assert Port reset by writing 1'b0 on PORT_CONTROL[0]
            //STEP 1: write Port Control Reset bit PORT_CONTROL[0]
            `uvm_do_on_with(w_trans,p_sequencer.root1_virt_seqr.driver_transaction_seqr[0], { 
                w_trans.transaction_type    == `PCIE_DRIVER_TRANSACTION_CLASS::MEM_WR;
                w_trans.address             == tb_cfg1.PF0_BAR0+PORT_GASKET_BASE_ADDR+'h1038;
                w_trans.length              == 'h2;
                w_trans.traffic_class       == tc; 
                w_trans.address_translation == 0;
                w_trans.first_dw_be         == 4'b1111;
                w_trans.last_dw_be          == 4'b1111;
                w_trans.th                  == 0;
                w_trans.ep                  == 0;
                w_trans.write_payload[0]    == changeEndian(wdata[31:0]);
                w_trans.write_payload[1]    == changeEndian(wdata[63:32]);
                w_trans.block               == 0; 
            })
            #1us;
            //Read port_control Reg to see PortSoftResetAck- PORT_CONTROL[4] set to 1'b0
            `uvm_do_on_with(r_trans,p_sequencer.root1_virt_seqr.driver_transaction_seqr[0], {
                r_trans.transaction_type    == `PCIE_DRIVER_TRANSACTION_CLASS::MEM_RD;
                r_trans.address             == tb_cfg1.PF0_BAR0+PORT_GASKET_BASE_ADDR+'h1038;
                r_trans.length              == 2;
                r_trans.traffic_class       == 0;
                r_trans.address_translation == 0;
                r_trans.first_dw_be         == 4'b1111;
                r_trans.last_dw_be          == 4'b1111;
                r_trans.ep                  == 0;
                r_trans.th                  == 0;
                r_trans.block               == 0; 
            })

            `uvm_do_on_with(wait_for_compl_seq,p_sequencer.root1_virt_seqr.driver_seqr[0], {
	        wait_for_compl_seq.command_num == r_trans.command_num;
	    })
            rdata = { changeEndian (r_trans.payload[1]), changeEndian (r_trans.payload[0])} ;
            if(rdata[4] != 0)
                `uvm_error(get_name(), $psprintf("Port reset is not released, PortSoftResetAck is still 1'b1! PORT_CONTROL = %0h", rdata))

        end
        else begin
            `uvm_error(get_name(), $psprintf("Port reset bit is not set to default 0x1 value. PORT_CONTROL = %0h", rdata))
            if(rdata[4] != 0)
              `uvm_error(get_name(), $psprintf("Port reset is not released, PortSoftResetAck is still 1'b1! PORT_CONTROL = %0h", rdata))
        end
	
    endtask : port_rst_root1

    function [31:0] changeEndian;   //transform data from the memory to big-endian form
        input [31:0] value;
        changeEndian = {value[7:0], value[15:8], value[23:16], value[31:24]};
    endfunction

endclass : config_seq

`endif // CONFIG_SEQ_SVH
