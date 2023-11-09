// Copyright (C) 2023 Intel Corporation
// SPDX-License-Identifier: MIT

`ifndef HE_USER_INTR_SEQ_SVH
`define HE_USER_INTR_SEQ_SVH

class he_user_intr_seq extends base_seq;
    `uvm_object_utils(he_user_intr_seq)
    `uvm_declare_p_sequencer(virtual_sequencer)

    rand bit [31:0] num_lines;
    rand bit [63:0] src_addr, dst_addr;
    rand bit [63:0] dsm_addr;
    rand bit [ 2:0] mode;
    rand bit [ 1:0] req_len;
    rand bit        src_addr_64bit, dst_addr_64bit, dsm_addr_64bit;
    rand bit        he_mem;
    bit [63:0] base_addr,addr;
    rand bit        cont_mode;
    rand int        run_time_in_ms;
    bit [511:0]     dsm_data;
    rand bit        report_perf_data;
    rand int        num_of_user_intr;

    rand bit[63:0] intr_addr, intr_wr_data, msix_addr_reg, msix_ctldat_reg;
    int timeout;
    rand bit [1:0] intr_id;
    bit msix_req_set;

    rand bit [63:0] dut_mem_start;
    rand bit [63:0] dut_mem_end;

    constraint num_lines_c {
        num_lines inside {[1:5]};
	if(mode != 3'b011) {
	    (num_lines % (2**req_len)) == 0;
	    (num_lines / (2**req_len)) >  0;
	}
	else {
	    num_lines % 2 == 0;
	    ((num_lines/2) % (2**req_len)) == 0;
	    ((num_lines/2) / (2**req_len)) >  0;
	}
	solve mode before num_lines;
	solve req_len before num_lines;
    }

    constraint req_len_c {
	req_len inside {2'b00, 2'b01, 2'b10};
    }

    constraint mode_c { soft mode == 3'b000; } // LPBK1
    constraint he_mem_c { soft he_mem == 0; }

    constraint cont_mode_c {
        soft cont_mode == 0;
    }

    constraint run_time_in_ms_c {
        run_time_in_ms inside {[1:5]};
    }

    constraint report_perf_data_c {
        soft report_perf_data == 0;
    }

    constraint intr_addr_cons {
    dut_mem_end > dut_mem_start;
    intr_addr[7:0] == 0;
    intr_addr   >= dut_mem_start;
    intr_addr    < dut_mem_end;
    intr_addr[63:32] == 32'b0;
    }
      
    constraint intr_wr_data_cons{
       !(intr_wr_data inside {64'h0});
        intr_wr_data[63:32] == 32'b0; 
    }
    
    constraint msix_addr_reg_cons {
        msix_addr_reg inside {20'h0_3000, 20'h0_3010, 20'h0_3020, 20'h0_3030};
    }
    
    constraint msix_ctldat_reg_cons {
       solve msix_addr_reg before msix_ctldat_reg;
       (msix_addr_reg == 20'h3000) -> {msix_ctldat_reg inside {20'h3008};}
       (msix_addr_reg == 20'h3010) -> {msix_ctldat_reg inside {20'h3018};}
       (msix_addr_reg == 20'h3020) -> {msix_ctldat_reg inside {20'h3028};}
       (msix_addr_reg == 20'h3030) -> {msix_ctldat_reg inside {20'h3038};}
    } 
    
    constraint intr_id_cons {
        solve msix_addr_reg before intr_id;
        (msix_addr_reg == 20'h3000) -> {intr_id inside {2'b00};}
        (msix_addr_reg == 20'h3010) -> {intr_id inside {2'b01};}
        (msix_addr_reg == 20'h3020) -> {intr_id inside {2'b10};}
        (msix_addr_reg == 20'h3030) -> {intr_id inside {2'b11};}
    } 
    
    constraint num_of_user_intr_c { soft num_of_user_intr == 1; }

    function new(string name = "he_user_intr_seq");
        super.new(name);
    endfunction : new

    task body();
	bit [63:0]                  wdata, rdata;
	bit [63:0]                  dsm_addr_tmp;	
	`PCIE_MEM_SERV target_mem_seq;
	bit [511:0]                 src_data[], dst_data[];
        int                         loop_iteration;

        super.body();
	this.randomize() with{dut_mem_start == tb_cfg0.dut_mem_start && dut_mem_end == tb_cfg0.dut_mem_end;};
        loop_iteration = num_of_user_intr;
        `uvm_info(get_name(), $psprintf("STEP 0 : Generating %0d User Interrupts dut_mem_start=%0h dut_mem_end=%0h", loop_iteration, dut_mem_start, dut_mem_end), UVM_LOW)

        repeat(loop_iteration) begin

          `ifdef INCLUDE_DDR4                             
	  	addr  = tb_cfg0.PF0_BAR0;
	  	rdata = '0;
	  	while(rdata[11:0] != 12'h9) begin
	  		addr = addr + rdata[39:16];
	  		mmio_read64(.addr_(addr), .data_(rdata));
	  	end
	  	addr = addr + 'h8;
	  	mmio_read64 (.addr_(addr), .data_(rdata));
	  	`uvm_info(get_name(), $psprintf("EMIF_STATUS  data Addr= %0h, Act = %0h", addr, rdata),UVM_LOW)
       	  	while(rdata[0]==0)
	  	begin
	  	mmio_read64 (.addr_(addr), .data_(rdata));
	  	`uvm_info(get_name(), $psprintf("EMIF_STATUS  data Addr= %0h, Act = %0h", addr, rdata),UVM_LOW)
	  	#50us;
	  	end
	  `endif
	  `uvm_info(get_name(), "Entering he_user_intr_seq...", UVM_LOW)

	  if(he_mem) base_addr = tb_cfg0.HE_MEM_BASE;
	  else       base_addr = tb_cfg0.HE_LB_BASE;

	  src_addr = alloc_mem(num_lines, !src_addr_64bit);
	  dst_addr = alloc_mem(num_lines, !dst_addr_64bit);
	  dsm_addr = alloc_mem(1, !dsm_addr_64bit);

	  //this.randomize();
	  `uvm_info(get_name(), $psprintf("he_mem = %0d, src_addr = %0h, dst_addr = %0h, dsm_addr = %0h. num_lines = %0d, req_len = %0h, mode = %0b, cont_mode = %0d", he_mem, src_addr, dst_addr, dsm_addr, num_lines, req_len, mode, cont_mode), UVM_LOW)
	  src_data = new[num_lines];
	  dst_data = new[num_lines];

	  // Prepare source data in host memory
	  for(int i = 0; i < num_lines; i++) begin
	      `uvm_do_on_with(target_mem_seq, p_sequencer.root_virt_seqr.mem_target_seqr, {
	          service_type      == `PCIE_MEM_SERV::WRITE_BUFFER;
	          address           == src_addr + 'h40*i;
	          dword_length      == 16;
	          first_byte_enable == 4'hf;
	          last_byte_enable  == 4'hf;
	          byte_enables      == 4'hf;
	      })
	  end

          // initialize DSM data
	  `uvm_do_on_with(target_mem_seq, p_sequencer.root_virt_seqr.mem_target_seqr, {
	      service_type      == `PCIE_MEM_SERV::WRITE_BUFFER;
	      //address           == {dsm_h, dsm_l};
	      address           == dsm_addr;
	      foreach(data_buf[i]) { data_buf[i] == 0; }
	      dword_length      == 16;
	      first_byte_enable == 4'hf;
	      last_byte_enable  == 4'hf;
	      byte_enables      == 4'hf;
	  })

          // Program CSR_CTL to reset HE-LPBK
	  wdata = 64'h0;
          mmio_write64(.addr_(base_addr+'h138), .data_(wdata));
          mmio_read64 (.addr_(base_addr+'h138), .data_(rdata));	
	  `uvm_info(get_name(), $psprintf("CSR_CTL = %0h", rdata), UVM_LOW)

          // Program CSR_CTL to remove reset HE-LPBK
	  wdata = 64'h1;
          mmio_write64(.addr_(base_addr+'h138), .data_(wdata));
          mmio_read64 (.addr_(base_addr+'h138), .data_(rdata));	
	  `uvm_info(get_name(), $psprintf("CSR_CTL = %0h", rdata), UVM_LOW)

	  // Program CSR_SRC_ADDR
          mmio_write64(.addr_(base_addr+'h120), .data_(src_addr>>6));
          mmio_read64 (.addr_(base_addr+'h120), .data_(rdata));	
	  `uvm_info(get_name(), $psprintf("CSR_SRC_ADDR = %0h", rdata), UVM_LOW)

	  // Program CSR_DST_ADDR
          mmio_write64(.addr_(base_addr+'h128), .data_(dst_addr>>6));
          mmio_read64 (.addr_(base_addr+'h128), .data_(rdata));	
	  `uvm_info(get_name(), $psprintf("CSR_DST_ADDR = %0h", rdata), UVM_LOW)

	  dsm_addr_tmp = dsm_addr >> 6;
	  // Program CSR_AFU_DSM_BASEH
          mmio_write32(.addr_(base_addr+'h114), .data_(dsm_addr_tmp[63:32]));
          mmio_read32 (.addr_(base_addr+'h114), .data_(rdata));	
	  `uvm_info(get_name(), $psprintf("DSM_H_ADDR = %0h", rdata), UVM_LOW)

	  // Program CSR_AFU_DSM_BASEL
          mmio_write32(.addr_(base_addr+'h110), .data_(dsm_addr_tmp[31:0]));
          mmio_read32 (.addr_(base_addr+'h110), .data_(rdata));	
	  `uvm_info(get_name(), $psprintf("DSM_L_ADDR = %0h", rdata), UVM_LOW)

	  // Program CSR_NUM_LINES
          mmio_write64(.addr_(base_addr+'h130), .data_(num_lines-1));
          mmio_read64 (.addr_(base_addr+'h130), .data_(rdata));	
	  `uvm_info(get_name(), $psprintf("CSR_NUM_LINES = %0h", rdata), UVM_LOW)

	  // Program CSR_CFG
	  wdata = {57'h0, req_len, mode, cont_mode, 1'b0};
          mmio_write64(.addr_(base_addr+'h140), .data_(wdata));
          mmio_read64 (.addr_(base_addr+'h140), .data_(rdata));	
	  `uvm_info(get_name(), $psprintf("CSR_CFG = %0h", rdata), UVM_LOW)

          config_he_user_intr();

          // Program CSR_CTL to start HE-LPBK
	  wdata = 64'h3;
          mmio_write64(.addr_(base_addr+'h138), .data_(wdata));
          mmio_read64 (.addr_(base_addr+'h138), .data_(rdata));	
	  `uvm_info(get_name(), $psprintf("CSR_CTL = %0h", rdata), UVM_LOW)

	  if(cont_mode) begin
	      //repeat(run_time_in_ms) #1ms;
	      #800ns;
              // Program CSR_CTL to start HE-LPBK
              mmio_read64 (.addr_(base_addr+'h138), .data_(rdata));	
	      rdata[2] = 1;
              mmio_write64(.addr_(base_addr+'h138), .data_(rdata));
              mmio_read64 (.addr_(base_addr+'h138), .data_(rdata));	
	      `uvm_info(get_name(), $psprintf("CSR_CTL = %0h", rdata), UVM_LOW)
	  end

          rdata = 0;
	  dsm_data = '0;

	  check_he_user_intr();
	  // Polling DSM
	  fork
	      while(!dsm_data[0]) begin
                  `uvm_do_on_with(target_mem_seq, p_sequencer.root_virt_seqr.mem_target_seqr, {
	              service_type      == `PCIE_MEM_SERV::READ_BUFFER;
                      address           == dsm_addr;
                      dword_length      == 16;
                      first_byte_enable == 4'hF;
                      last_byte_enable  == 4'hF;
                      byte_enables      == 4'hF;
	          })

	          foreach(target_mem_seq.data_buf[i])
	              dsm_data |= changeEndian(target_mem_seq.data_buf[i]) << (i*32);
	  	`uvm_info(get_name(), $psprintf("Polling DSM status Addr = %0h Data = %h", target_mem_seq.address, dsm_data), UVM_LOW)
	  	//dsm_data = rdata;
	  	#1us;
	      end
	      #50us;
	  join_any
	  if(!dsm_data[0])
	      `uvm_fatal(get_name(), $psprintf("TIMEOUT! polling dsm_addr = %0h!", dsm_addr))

          if(mode == 3'b000) begin
	      // Compare data
	      for(int i = 0; i < num_lines; i++) begin
                  `uvm_do_on_with(target_mem_seq, p_sequencer.root_virt_seqr.mem_target_seqr, {
	              service_type      == `PCIE_MEM_SERV::READ_BUFFER;
                      address           == src_addr + 'h40*i;
                      dword_length      == 16;
                      first_byte_enable == 4'hF;
                      last_byte_enable  == 4'hF;
                      byte_enables      == 4'hF;
	          })
	          foreach(target_mem_seq.data_buf[j])
	              src_data[i] |= changeEndian(target_mem_seq.data_buf[j]) << (j*32);
	          `uvm_info(get_name(), $psprintf("addr = %0h src_data = %0h", target_mem_seq.address, src_data[i]), UVM_LOW)
	      end

	      for(int i = 0; i < num_lines; i++) begin
                  `uvm_do_on_with(target_mem_seq, p_sequencer.root_virt_seqr.mem_target_seqr, {
	              service_type      == `PCIE_MEM_SERV::READ_BUFFER;
                      address           == dst_addr + 'h40*i;
                      dword_length      == 16;
                      first_byte_enable == 4'hF;
                      last_byte_enable  == 4'hF;
                      byte_enables      == 4'hF;
	          })
	          foreach(target_mem_seq.data_buf[j])
	              dst_data[i] |= changeEndian(target_mem_seq.data_buf[j]) << (j*32);
	          `uvm_info(get_name(), $psprintf("addr = %0h dst_data = %0h", target_mem_seq.address, dst_data[i]), UVM_LOW)
	      end

	      foreach(src_data[i]) begin
	          if(src_data[i] !== dst_data[i])
	              `uvm_error(get_name(), $psprintf("Data mismatch! src_data[%0d] = %0h dst_data[%0d] = %0h", i, src_data[i], i, dst_data[i]))
	          else
	              `uvm_info(get_name(), $psprintf("Data match! data[%0d] = %0h", i, src_data[i]), UVM_LOW)
	      end
	  end

          if(!cont_mode)
              check_counter();

          if(report_perf_data) begin
	      if(mode inside {3'b001, 3'b010, 3'b011})
	          report_perf();
	  end

          //check_he_user_intr();

          this.randomize(); //Randomize for next interrupt sequence
          
	end //repeat

 	`uvm_info(get_name(), "Exiting he_user_intr_seq...", UVM_LOW)
    endtask : body

    task check_counter();
        bit [63:0] rdata;
        mmio_read64 (.addr_(base_addr+'h160), .data_(rdata));	
	if(mode == 3'b000) begin // LPBK
	    if((rdata[31:0]-2) != num_lines)
	        `uvm_error(get_name(), $psprintf("Stats counter for numWrites doesn't match num_lines! numWrites = %0h, num_lines = %0h", rdata[31:0]-2, num_lines))
	    if(rdata[63:32] != num_lines)
	        `uvm_error(get_name(), $psprintf("Stats counter for numReads doesn't match num_lines! numReads = %0h, num_lines = %0h", rdata[63:32], num_lines))
	end
	else if(mode == 3'b010) begin // WRITE ONLY
	    if((rdata[31:0]-2) != num_lines)
	        `uvm_error(get_name(), $psprintf("Stats counter for numWrites doesn't match num_lines! numWrites = %0h, num_lines = %0h", rdata[31:0]-2, num_lines))
	end
	else if(mode == 3'b001) begin // READ ONLY
	    if(rdata[63:32] != num_lines)
	        `uvm_error(get_name(), $psprintf("Stats counter for numReads doesn't match num_lines! numReads = %0h, num_lines = %0h", rdata[63:32], num_lines))
	end
	else if(mode == 3'b011) begin // THRUPUT
	    if((rdata[31:0]-2) != (num_lines/2))
	        `uvm_error(get_name(), $psprintf("Stats counter for numWrites doesn't match num_lines! numWrites = %0h, num_lines = %0h", rdata[31:0]-2, num_lines))
	    if(rdata[63:32] != (num_lines/2))
	        `uvm_error(get_name(), $psprintf("Stats counter for numReads doesn't match num_lines! numReads = %0h, num_lines = %0h", rdata[63:32], num_lines))
	end
	//check_afu_intf_error();
    endtask : check_counter

    task report_perf();
        real num_ticks;
	real perf_data;
	num_ticks = dsm_data[103:64];
        perf_data = (num_lines * 64) / (2.8 * num_ticks);
	$display("DSM data = %0h", dsm_data);
	$display("*** PERFORMANCE MEASUREMENT *** ", $psprintf("num_lines = %0d req_len = 0x%0h num_ticks = 0x%0h perf_data = %.4f GB/s", num_lines, req_len, num_ticks, perf_data));
    endtask : report_perf

    virtual task config_he_user_intr();
        bit [63:0] wdata, rdata, addr, intr_masked_data;
	uvm_status_e status;

        `uvm_info(get_name(), $psprintf("TEST: STEP 1 - Configure MSIX Table VF0 BAR4 MSIX_VADDR/MSIX_VCTLDAT"), UVM_LOW)
        `uvm_info(get_name(), $psprintf("TEST: MMIO WRITE to MSIX_VADDR=%0h",(tb_cfg0.PF0_VF0_BAR4+msix_addr_reg)), UVM_LOW)
        mmio_write64(.addr_(tb_cfg0.PF0_VF0_BAR4+msix_addr_reg), .data_(intr_addr));
        #1us;

        `uvm_info(get_name(), $psprintf("TEST: MMIO WRITE to MSIX_VCTLDAT=%0h with masked Interrupt",(tb_cfg0.PF0_VF0_BAR4+msix_ctldat_reg)), UVM_LOW)
        intr_masked_data[31:0] = intr_wr_data[31:0];
        intr_masked_data[63:32] = 32'b1; 
        mmio_write64(.addr_(tb_cfg0.PF0_VF0_BAR4+msix_ctldat_reg), .data_(intr_masked_data));

        #25us;
 
        `uvm_info(get_name(), $psprintf("TEST: STEP 2 - Initiate User interrupt request for ID=%0d",intr_id), UVM_LOW)
	tb_env0.mem_regs.CTL.write(status, 1);	
	tb_env0.mem_regs.INTERRUPT0.read(status, rdata[31:0]);
	rdata[31:16] = intr_id; // Interrupt vector 0..3
	tb_env0.mem_regs.INTERRUPT0.write(status, rdata[31:0]);
	tb_env0.mem_regs.CFG.read(status, rdata);
	rdata[29] = 1;
	tb_env0.mem_regs.CFG.write(status, rdata);

    endtask

    virtual task check_he_user_intr();
        bit [63:0] wdata, rdata, addr, intr_masked_data;
        bit msix_req_set;
        `PCIE_MEM_SERV target_mem_seq;
	uvm_status_e status;

        `uvm_info(get_name(), $psprintf("TEST: STEP 3 - Poll MSIX interrupt signal"), UVM_LOW)
        fork 
          begin
             #10us;
          end
          begin
           `uvm_info(get_type_name(),$sformatf("Waiting for MSIX Req"),UVM_LOW)
	   @(posedge `MSIX_TOP.o_vintr_valid)
	   @(posedge `MSIX_TOP.o_msix_valid)
           msix_req_set = 1'b1;
          end
        join_any
        disable fork;

        if(msix_req_set)                                                                      
          `uvm_fatal(get_type_name(),"TEST: msix_req generated for masked user interrupt")
        else
          `uvm_info(get_name(), $psprintf("TEST: msix_req not generated for masked interrupt"), UVM_LOW)

        `uvm_info(get_name(), $psprintf("TEST: STEP 4 - Check MSIX_VPBA[%0d] is set for masked User interrupt",intr_id), UVM_LOW)
        for(int i=0;i<200;i++) begin
          mmio_read64(.addr_(tb_cfg0.PF0_VF0_BAR4+MSIX_PBA_BASE_ADDR),.data_(rdata));
          if(rdata[intr_id]) break;
          #1ns;
        end
        assert(rdata[intr_id]) else 
          `uvm_error(get_type_name(),$sformatf("TEST : MSIX_VPBA[%0d] not set post masked interrupt",intr_id))

        `uvm_info(get_name(), $psprintf("TEST: STEP 5 - Unmask User interrupt by writing on MSIX_VCTLDAT[63:32]"), UVM_LOW)
        mmio_write64(.addr_(tb_cfg0.PF0_VF0_BAR4+msix_ctldat_reg), .data_(intr_wr_data));

        `uvm_info(get_name(), $psprintf("TEST: STEP 6 - Poll MSIX interrupt signal"), UVM_LOW)
        fork 
          begin
             #10us;
          end
          begin
           `uvm_info(get_type_name(),$sformatf("Waiting for MSIX Req"),UVM_LOW)
	   @(posedge `MSIX_TOP.o_vintr_valid)
	   @(posedge `MSIX_TOP.o_msix_valid)
           msix_req_set = 1'b1;
          end
        join_any
        disable fork;

        if(!msix_req_set)                                                                      
          `uvm_fatal(get_type_name(), "TEST: msix_req not generated after unmasking User interrupt")
        else
          `uvm_info(get_name(), $psprintf("TEST: msix_req generated after unmasking User interrupt"), UVM_LOW)

        #1us;
        `uvm_info(get_name(), $psprintf("TEST: STEP 7 - Check MSIX_VPBA[%0d] is clear after asserting pending User interrupt",intr_id), UVM_LOW)
        mmio_read64(.addr_(tb_cfg0.PF0_VF0_BAR4+MSIX_PBA_BASE_ADDR),.data_(rdata));
        assert(rdata[intr_id]==0) else 
          `uvm_error(get_type_name(),$sformatf("TEST : MSIX_VPBA[%0d] is not clear after asserting pending User interrupt",intr_id));

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

        msix_req_set = 0;
        #1us;
    endtask
endclass : he_user_intr_seq

`endif // HE_USER_INTR_SEQ_SVH
