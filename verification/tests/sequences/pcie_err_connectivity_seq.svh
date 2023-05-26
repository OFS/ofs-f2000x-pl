// Copyright (C) 2023 Intel Corporation
// SPDX-License-Identifier: MIT

`ifndef PCIE_ERR_CONECTIVITY_SEQ_SVH
`define PCIE_ERR_CONECTIVITY_SEQ_SVH

class pcie_err_connectivity_seq extends base_seq;
    `uvm_object_utils(pcie_err_connectivity_seq)
    `uvm_declare_p_sequencer(virtual_sequencer)

  rand bit[63:0]    intr_addr;
  rand bit[63:0]    intr_wr_data;
  rand bit[63:0]    fme_err_code;//1:PartialReconfigFIFOParityErr, 2:RemoteSTPParityErr, 32:AfuAccessModeErr
  rand bit inj_pcie_err; 
  rand bit inj_fme_err; 
  static int e_set;

  rand bit [63:0] dut_mem_start;
  rand bit [63:0] dut_mem_end;

  constraint addr_cons {
     dut_mem_end > dut_mem_start;
     intr_addr[7:0] == 0;
     intr_addr   >= dut_mem_start;
     intr_addr    < dut_mem_end;
     intr_addr[63:32] == 32'b0;
  }
    
  constraint wr_dat_cons {
     !(intr_wr_data inside {64'h0});
      intr_wr_data[63:32] == 32'b0; 
  }


  constraint fme_err_code_cons {
     fme_err_code inside {64'h1};//1:PartialReconfigFIFOParityErr
  }

  constraint err_type_cons{
    soft inj_pcie_err==1;
    soft inj_fme_err==0;
  }
 
    function new(string name = "pcie_err_connectivity_seq");
        super.new(name);
    endfunction : new

    task body();
        bit [63:0] wdata, rdata, addr, intr_masked_data;
        bit [63:0] afu_id_l, afu_id_h;
        bit msix_req_set;
        `PCIE_MEM_SERV target_mem_seq;


        super.body();
        `uvm_info(get_name(), "Entering fme_intr_seq...", UVM_LOW)

        repeat(1)begin

  	  this.randomize() with{dut_mem_start == tb_cfg0.dut_mem_start && dut_mem_end == tb_cfg0.dut_mem_end;};
          `uvm_info(get_name(), $psprintf("TEST: STEP 0 - inj_pcie_err=%0d, inj_fme_err=%0d dut_mem_start=%0h dut_mem_end=%0h", inj_pcie_err, inj_fme_err, dut_mem_start, dut_mem_end), UVM_LOW)


          `uvm_info(get_name(), $psprintf("TEST: STEP 1 - Configure MSIX Table BAR0 MSIX_ADDR6/MSIX_CTLDAT6"), UVM_LOW)
          `uvm_info(get_name(), $psprintf("TEST: MMIO WRITE to MSIX_ADDR6"), UVM_LOW)
          mmio_write64(.addr_(tb_cfg0.PF0_BAR4+FME_MSIX_BASE_ADDR+'h60), .data_(intr_addr));
          #1us;

          `uvm_info(get_name(), $psprintf("TEST: MMIO WRITE to MSIX_CTLDAT6 with masked Interrupt"), UVM_LOW)
          intr_masked_data[31:0] = intr_wr_data[31:0];
          intr_masked_data[63:32] = 32'b1; 
          mmio_write64(.addr_(tb_cfg0.PF0_BAR4+FME_MSIX_BASE_ADDR+'h68), .data_(intr_masked_data));
          #25us;
 
	  if(inj_pcie_err)begin
            `uvm_info(get_name(), $psprintf("TEST: STEP 2 - PCIE ERROR _err_code=%0x",'h4), UVM_LOW)
             force tb_top.DUT.pcie_wrapper.pcie_ss_top.pcie_ss.pcie_ss.p0_tileif.ss_app_vf_err_ca_postedreq_s3 = 1'b1; 
             force tb_top.DUT.pcie_wrapper.pcie_ss_top.pcie_ss.pcie_ss.p0_tileif.ss_app_vf_err_ca_postedreq_s2 = 1'b1;    
             force tb_top.DUT.pcie_wrapper.pcie_ss_top.pcie_ss.pcie_ss.p0_tileif.ss_app_vf_err_ca_postedreq_s1 = 1'b1; 
             force tb_top.DUT.pcie_wrapper.pcie_ss_top.pcie_ss.pcie_ss.p0_tileif.ss_app_vf_err_ca_postedreq_s0 = 1'b1; 
             force tb_top.DUT.pcie_wrapper.pcie_ss_top.pcie_ss.pcie_ss.p0_tileif.ss_app_vf_err_ur_postedreq_s3 = 1'b1; 
             force tb_top.DUT.pcie_wrapper.pcie_ss_top.pcie_ss.pcie_ss.p0_tileif.ss_app_vf_err_ur_postedreq_s2 = 1'b1; 
             force tb_top.DUT.pcie_wrapper.pcie_ss_top.pcie_ss.pcie_ss.p0_tileif.ss_app_vf_err_ur_postedreq_s1 = 1'b1; 
             force tb_top.DUT.pcie_wrapper.pcie_ss_top.pcie_ss.pcie_ss.p0_tileif.ss_app_vf_err_ur_postedreq_s0 = 1'b1; 
             force tb_top.DUT.pcie_wrapper.pcie_ss_top.pcie_ss.pcie_ss.p0_tileif.ss_app_vf_err_poisonedcompl_s3 =1'b1;  
             force tb_top.DUT.pcie_wrapper.pcie_ss_top.pcie_ss.pcie_ss.p0_tileif.ss_app_vf_err_poisonedcompl_s2 =1'b1;
             force tb_top.DUT.pcie_wrapper.pcie_ss_top.pcie_ss.pcie_ss.p0_tileif.ss_app_vf_err_poisonedcompl_s1 =1'b1;
             force tb_top.DUT.pcie_wrapper.pcie_ss_top.pcie_ss.pcie_ss.p0_tileif.ss_app_vf_err_poisonedcompl_s0 =1'b1;
             force tb_top.DUT.pcie_wrapper.pcie_ss_top.pcie_ss.pcie_ss.p0_tileif.ss_app_vf_err_poisonedwrreq_s3 =1'b1;
             force tb_top.DUT.pcie_wrapper.pcie_ss_top.pcie_ss.pcie_ss.p0_tileif.ss_app_vf_err_poisonedwrreq_s2 =1'b1;
             force tb_top.DUT.pcie_wrapper.pcie_ss_top.pcie_ss.pcie_ss.p0_tileif.ss_app_vf_err_poisonedwrreq_s1 =1'b1;
             force tb_top.DUT.pcie_wrapper.pcie_ss_top.pcie_ss.pcie_ss.p0_tileif.ss_app_vf_err_poisonedwrreq_s0 =1'b1;
            // mmio_write64(.addr_(tb_cfg0.PF0_BAR0+RAS_ERROR_INJ_VERIF), .data_('h4));//inject NO_FATAL_ERR
	  end
	  
          `uvm_info(get_name(), $psprintf("TEST: STEP 3 - Poll MSIX interrupt signal"), UVM_LOW)
          fork 
            begin
               #10us;
            end
            begin
             `uvm_info(get_type_name(),$sformatf("Waiting for MSIX Req"),UVM_LOW)
	     @(posedge `MSIX_TOP.o_intr_valid)
	     @(posedge `MSIX_TOP.o_msix_valid)
             msix_req_set = 1'b1;
            end
          join_any
          disable fork;

          if(msix_req_set)                                                                      
            `uvm_fatal(get_type_name(),"TEST: msix_req generated for masked fme interrupt")
          else
            `uvm_info(get_name(), $psprintf("TEST: msix_req not generated for masked interrupt"), UVM_LOW)

          `uvm_info(get_name(), $psprintf("TEST: STEP 4 - Check MSIX_PBA[6] is set for masked FME interrupt"), UVM_LOW)
          for(int i=0;i<200;i++) begin
            mmio_read64(.addr_(tb_cfg0.PF0_BAR4+MSIX_PBA_BASE_ADDR),.data_(rdata));
            if(rdata[6]) break;
            #1ns;
          end
          assert(rdata[6]) else 
            `uvm_error(get_type_name(),$sformatf("TEST : MSIX_PBA[6] not set post masked interrupt"))

          `uvm_info(get_name(), $psprintf("TEST: STEP 5 - Unmasked FME interrupt by writing on MSIX_CTLDAT6[63:32]"), UVM_LOW)
          mmio_write64(.addr_(tb_cfg0.PF0_BAR4+FME_MSIX_BASE_ADDR+'h68), .data_(intr_wr_data));

          `uvm_info(get_name(), $psprintf("TEST: STEP 6 - Poll MSIX interrupt signal"), UVM_LOW)
          fork 
            begin
               #10us;
            end
            begin
             `uvm_info(get_type_name(),$sformatf("Waiting for MSIX Req"),UVM_LOW)
	     @(posedge `MSIX_TOP.o_intr_valid)
	     @(posedge `MSIX_TOP.o_msix_valid)
             msix_req_set = 1'b1;
            end
          join_any
          disable fork;

          if(!msix_req_set)                                                                      
                `uvm_fatal(get_type_name(), "TEST: msix_req not generated after unmasking FME interrupt")
          else
            `uvm_info(get_name(), $psprintf("TEST: msix_req generated after unmasking FME interrupt"), UVM_LOW)

          #1us;
          `uvm_info(get_name(), $psprintf("TEST: STEP 7 - Check MSIX_PBA[6] is clear after asserting pending FME interrupt"), UVM_LOW)
          mmio_read64(.addr_(tb_cfg0.PF0_BAR4+MSIX_PBA_BASE_ADDR),.data_(rdata));
          assert(rdata[6]==0) else 
            `uvm_error(get_type_name(),$sformatf("TEST : MSIX_PBA[6] is not clear after asserting pending FME interrupt"));

          `uvm_info(get_name(), $psprintf("TEST: STEP 8 - Read Host memory"), UVM_LOW)
          `uvm_do_on_with(target_mem_seq, p_sequencer.root_virt_seqr.mem_target_seqr, {
              service_type      == `PCIE_MEM_SERV::READ_BUFFER;
              address           == intr_addr;
              dword_length      == 1;
              first_byte_enable == 4'hF;
              last_byte_enable  == 4'hF;
              byte_enables      == 4'hF;
          })

          if(changeEndian(target_mem_seq.data_buf[0]) !== intr_wr_data)
              `uvm_error(get_name(), $psprintf("Interrupt write data mismatch exp = %0h act = %0h", intr_wr_data, changeEndian(target_mem_seq.data_buf[0])))
          else
              `uvm_info(get_name(), $psprintf("TEST: Interrupt data match intr_addr=%0h intr_wr_data = %0h", intr_addr, intr_wr_data), UVM_LOW)

	  if(inj_pcie_err)begin
             uvm_status_e      status;
             tb_env0.pcie_regs.PCIE_ERROR.read(status,rdata);
             `ifdef COV tb_env0.pcie_regs.PCIE_ERROR.cg_vals.sample();`endif
            `uvm_info(get_name(), $psprintf("TEST: STEP 9 - READ PCIE_ERROR rdata=%0h",rdata), UVM_LOW)
              release tb_top.DUT.pcie_wrapper.pcie_ss_top.pcie_ss.pcie_ss.p0_tileif.ss_app_vf_err_ca_postedreq_s3; 
              release tb_top.DUT.pcie_wrapper.pcie_ss_top.pcie_ss.pcie_ss.p0_tileif.ss_app_vf_err_ca_postedreq_s2;    
              release tb_top.DUT.pcie_wrapper.pcie_ss_top.pcie_ss.pcie_ss.p0_tileif.ss_app_vf_err_ca_postedreq_s1; 
              release tb_top.DUT.pcie_wrapper.pcie_ss_top.pcie_ss.pcie_ss.p0_tileif.ss_app_vf_err_ca_postedreq_s0; 
              release tb_top.DUT.pcie_wrapper.pcie_ss_top.pcie_ss.pcie_ss.p0_tileif.ss_app_vf_err_ur_postedreq_s3; 
              release tb_top.DUT.pcie_wrapper.pcie_ss_top.pcie_ss.pcie_ss.p0_tileif.ss_app_vf_err_ur_postedreq_s2; 
              release tb_top.DUT.pcie_wrapper.pcie_ss_top.pcie_ss.pcie_ss.p0_tileif.ss_app_vf_err_ur_postedreq_s1; 
              release tb_top.DUT.pcie_wrapper.pcie_ss_top.pcie_ss.pcie_ss.p0_tileif.ss_app_vf_err_ur_postedreq_s0; 
              release tb_top.DUT.pcie_wrapper.pcie_ss_top.pcie_ss.pcie_ss.p0_tileif.ss_app_vf_err_poisonedcompl_s3;  
              release tb_top.DUT.pcie_wrapper.pcie_ss_top.pcie_ss.pcie_ss.p0_tileif.ss_app_vf_err_poisonedcompl_s2;
              release tb_top.DUT.pcie_wrapper.pcie_ss_top.pcie_ss.pcie_ss.p0_tileif.ss_app_vf_err_poisonedcompl_s1;
              release tb_top.DUT.pcie_wrapper.pcie_ss_top.pcie_ss.pcie_ss.p0_tileif.ss_app_vf_err_poisonedcompl_s0;
              release tb_top.DUT.pcie_wrapper.pcie_ss_top.pcie_ss.pcie_ss.p0_tileif.ss_app_vf_err_poisonedwrreq_s3;
              release tb_top.DUT.pcie_wrapper.pcie_ss_top.pcie_ss.pcie_ss.p0_tileif.ss_app_vf_err_poisonedwrreq_s2;
              release tb_top.DUT.pcie_wrapper.pcie_ss_top.pcie_ss.pcie_ss.p0_tileif.ss_app_vf_err_poisonedwrreq_s1;
              release tb_top.DUT.pcie_wrapper.pcie_ss_top.pcie_ss.pcie_ss.p0_tileif.ss_app_vf_err_poisonedwrreq_s0; 
             tb_env0.pcie_regs.PCIE_ERROR.read(status,rdata);
             if(rdata!==16'hFFFF)
              `uvm_error(get_name(), $psprintf("PCIE_ERROR reg is not set as expected ,rdata=%b",rdata))
             tb_env0.pcie_regs.PCIE_ERROR.write(status,'hFFFF);
             tb_env0.pcie_regs.PCIE_ERROR.read(status,rdata);
             if(|rdata)
              `uvm_error(get_name(), $psprintf("PCIE_ERROR reg CLEAR is not done ,rdata=%b",rdata))
            `uvm_info(get_name(), $psprintf("TEST: STEP 9 - Clear PCIE ERROR and msix_req_set"), UVM_LOW)
	  end
	  
          msix_req_set = 0;
          #1us;
        end

       `uvm_info(get_name(), "Exiting pcie_err_connectivity_seq...", UVM_LOW)

    endtask : body

endclass : pcie_err_connectivity_seq

`endif // PCIE_ERR_CONECTIVITY_SEQ_SVH
