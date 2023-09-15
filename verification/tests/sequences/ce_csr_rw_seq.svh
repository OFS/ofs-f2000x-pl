// Copyright (C) 2023 Intel Corporation
// SPDX-License-Identifier: MIT

`ifndef CE_CSR_RW_SEQ_SVH
`define CE_CSR_RW_SEQ_SVH

class ce_csr_rw_seq extends base_seq;
 `uvm_object_utils(ce_csr_rw_seq)
 `uvm_declare_p_sequencer(virtual_sequencer)

  function new(string name = "ce_csr_rw_seq");
  super.new(name);
  endfunction : new

  task body();

    bit [63:0]   wdata,rdata,mask,expdata,addr;
    super.body();
      `uvm_info(get_name(), "Entering ce_csr_rw_seq...", UVM_LOW)
	         
       	addr = tb_cfg0.PF4_BAR0+'h0108;
        wdata = 64'h1;
	mmio_write64(.addr_(addr), .data_(wdata));
	mmio_read64 (.addr_(addr), .data_(rdata));
      	if(rdata == wdata)
         `uvm_info(get_name(), $psprintf(" CSR_CE2HOST_DATA_REQ_LIMIT match 64 !Addr= %0h,  Exp = %0h, Act = %0h", addr, wdata, rdata),UVM_LOW)
        else
         `uvm_error(get_name(), $psprintf("CSR_CE2HOST_DATA_REQ_LIMIT Data mismatch 64! Addr= %0h, Exp = %0h, Act = %0h", addr,wdata, rdata))

	 addr = tb_cfg0.PF4_BAR0+'h0100;
         wdata = 64'hdeadbeefdeadbeef;
	 mmio_write64(.addr_(addr), .data_(wdata));
         mmio_read64 (.addr_(addr), .data_(rdata));
        if(rdata == wdata)
         `uvm_info(get_name(), $psprintf(" CSR_HOST_SCRATCHPAD match 64 !Addr= %0h,  Exp = %0h, Act = %0h", addr, wdata, rdata),UVM_LOW)
        else
        `uvm_error(get_name(), $psprintf("CSR_HOST_SCRATCHPAD Data mismatch 64! Addr= %0h, Exp = %0h, Act = %0h", addr,wdata, rdata))

      	
       	addr = tb_cfg0.PF4_BAR0+'h0110;
        mask = 64'h00000000deadbeef;
        wdata = 64'hdeadbeefdeadbeef & mask;
        mmio_write64(.addr_(addr), .data_(wdata));
	mmio_read64 (.addr_(addr), .data_(rdata));
        if(rdata == wdata)
         `uvm_info(get_name(), $psprintf("  CSR_SRC_ADDR match 64 !Addr= %0h,  Exp = %0h, Act = %0h", addr, wdata, rdata),UVM_LOW)
        else
         `uvm_error(get_name(), $psprintf(" CSR_SRC_ADDR Data mismatch 64! Addr= %0h, Exp = %0h, Act = %0h", addr,wdata, rdata))

	addr = tb_cfg0.PF4_BAR0+'h0118;
	wdata = 64'h000000001eadbeef;
	mmio_write64(.addr_(addr), .data_(wdata));
	mmio_read64 (.addr_(addr), .data_(rdata));
        if(rdata == wdata)
          `uvm_info(get_name(), $psprintf("  CSR_DST_ADDR match 64 !Addr= %0h,  Exp = %0h, Act = %0h", addr, wdata, rdata),UVM_LOW)
        else
         `uvm_error(get_name(), $psprintf(" CSR_DST_ADDR Data mismatch 64! Addr= %0h, Exp = %0h, Act = %0h", addr,wdata, rdata))
      
	addr = tb_cfg0.PF4_BAR0+'h0120;
	mask = 64'h00000000deadbeef;
        wdata = 64'hdeadbeefdeadbeef & mask;
	mmio_write64(.addr_(addr), .data_(wdata));
	mmio_read64 (.addr_(addr), .data_(rdata));
        if(rdata == wdata)
         `uvm_info(get_name(), $psprintf(" CSR_DATA_SIZE  Data match 64 !Addr= %0h,  Exp = %0h, Act = %0h", addr, wdata, rdata),UVM_LOW)
         else
         `uvm_error(get_name(), $psprintf(" CSR_DATA_SIZE Data mismatch 64! Addr= %0h, Exp = %0h, Act = %0h", addr,wdata, rdata))
	 			
	addr = tb_cfg0.PF4_BAR0+'h0128;
	mask = 64'h0000000000000001;
        wdata = 64'hdeadbeefdeadbeef & mask;
	mmio_write64(.addr_(addr), .data_(wdata));
	mmio_read64 (.addr_(addr), .data_(rdata));
 
        if(rdata== wdata)
         `uvm_info(get_name(), $psprintf("CSR_HOST2CE_MRD_START Data match 64 !Addr= %0h,  Exp = %0h, Act = %0h", addr, wdata, rdata),UVM_LOW)
        else
         `uvm_error(get_name(), $psprintf("CSR_HOST2CE_MRD_START Data mismatch 64! Addr= %0h, Exp = %0h, Act = %0h", addr,wdata, rdata))
	   	
	addr = tb_cfg0.PF4_BAR0+'h0138;
	mask = 64'h0000000000000001;
        wdata = 64'hdeadbeefdeadbeef & mask;
	mmio_write64(.addr_(addr), .data_(wdata));
	mmio_read64 (.addr_(addr), .data_(rdata));
        if(rdata == wdata)
          `uvm_info(get_name(), $psprintf(" CSR_HOST2HPS_IMG_XFR match 64 !Addr= %0h,  Exp = %0h, Act = %0h", addr, wdata, rdata),UVM_LOW)
        else
         `uvm_error(get_name(), $psprintf(" CSR_HOST2HPS_IMG_XFR Data mismatch 64! Addr= %0h, Exp = %0h, Act = %0h", addr,wdata, rdata))

      	 
        `uvm_info(get_name(), "Exiting  ce_csr_rw_seq...", UVM_LOW)
    endtask : body
endclass :  ce_csr_rw_seq

`endif //  CE_CSR_RW_SEQ_SVH


