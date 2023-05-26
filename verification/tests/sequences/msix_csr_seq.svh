// Copyright (C) 2023 Intel Corporation
// SPDX-License-Identifier: MIT

//===============================================================================================================
/**
 * Abstract:
 * class msix_csr_seq is executed by msix_csr_test.
 * 
 * This sequence uses the RAL model for front-door access of registers 
 * The sequence also uses mmio_read/write tasks for 32/64bit access (for coverage purpose) defined in base_sequence
 *
 * Sequence is running on virtual_sequencer.
 */
//===============================================================================================================

`ifndef MSIX_CSR_SEQ_SVH
`define MSIX_CSR_SEQ_SVH

class msix_csr_seq extends base_seq;
    `uvm_object_utils(msix_csr_seq)
    `uvm_declare_p_sequencer(virtual_sequencer)

     rand int                pcie_tlp_count;
     rand bit  [63:0]        BAR_OFFSET ;       
     rand bit  [63:0]        ADDR;
     rand bit        he_mem_msix,he_lpbk_msix;  
    rand `PCIE_DRIVER_TRANSACTION_CLASS::transaction_type_enum  pcie_trans_type;
    `PCIE_DEV_CFG_CLASS cfg;
  
     constraint msix_hemem_c { soft he_mem_msix == 0;}
     constraint msix_lpbk_c { soft he_lpbk_msix == 0;}
  
        


    function new(string name = "msix_csr_seq");
        super.new(name);
    endfunction : new

    task body();
       bit [63:0]                               wdata, rdata, addr,rw_bits,exp_data,default_value;
        `PCIE_DRIVER_TRANSACTION_CLASS pcie_tran;
        `PCIE_DRIVER_WAIT_UNTIL_IDLE_SEQ wait_until_driver_idle_seq;   
        `PCIE_DRIVER_WAIT_FOR_COMPL_SEQ wait_for_compl_seq;
        uvm_reg_data_t ctl_data;
        uvm_status_e       status;
        ral_block_ac_msix  INTR_REGS;
        super.body();
        `uvm_info(get_name(), "Entering msix_csr_seq...", UVM_LOW)

       if(he_mem_msix==1) INTR_REGS = tb_env0.msix_regs_pf0_vf0;
       else if (he_lpbk_msix==1) INTR_REGS = tb_env0.host_msix_regs_pf1;
       else INTR_REGS = tb_env0.msix_regs;


     //==================================================
     // Write and Read 'hFFFFFFFF_FFFFFFFF to MSIX_ADDR0 
     //==================================================
     wdata='hFFFFFFFF_FFFFFFFF ;
     default_value=64'h0000000000000000 ;
     rw_bits = 'hFFFFFFFFFFFFFFFF ;
     INTR_REGS.MSIX_ADDR0.write(status,wdata);
      `ifdef COV INTR_REGS.MSIX_ADDR0.cg_vals.sample();`endif
     INTR_REGS.MSIX_ADDR0.read(status,rdata);
      `ifdef COV INTR_REGS.MSIX_ADDR0.cg_vals.sample();`endif
     wdata=(wdata&default_value)|rw_bits ;
     `uvm_info(get_name(), $psprintf("Register = %0s, data = %0h rw_bits_data = %h","MSIX_ADDR0",wdata , rw_bits), UVM_LOW)
     if(rdata !== wdata )
      `uvm_error(get_name(), $psprintf("Data mismatch 64! Register = %0s, Exp = %0h, Act = %0h", "MSIX_ADDR0",wdata, rdata))
     else
      `uvm_info(get_name(), $psprintf("Data match 64! Register = %0s, wdata = %0h rdata = %0h","MSIX_ADDR0",wdata, rdata), UVM_LOW)


     //==================================================
     // Write and Read 'hAAAAAAAA_AAAAAAAA to MSIX_ADDR0
     //==================================================
     wdata='hAAAAAAAA_AAAAAAAA ;
     default_value=64'h0000000000000000 ;
     rw_bits = 'hFFFFFFFFFFFFFFFF ;
     INTR_REGS.MSIX_ADDR0.write(status,wdata);
      `ifdef COV INTR_REGS.MSIX_ADDR0.cg_vals.sample();`endif
     INTR_REGS.MSIX_ADDR0.read(status,rdata);
      `ifdef COV INTR_REGS.MSIX_ADDR0.cg_vals.sample();`endif
     wdata=(wdata&rw_bits)|default_value;
     `uvm_info(get_name(), $psprintf("Register = %0s, data = %0h rw_bits_data = %h","MSIX_ADDR0",wdata , rw_bits), UVM_LOW)
     if(rdata !== wdata )
      `uvm_error(get_name(), $psprintf("Data mismatch 64! Register = %0s, Exp = %0h, Act = %0h", "MSIX_ADDR0",wdata, rdata))
     else
      `uvm_info(get_name(), $psprintf("Data match 64! Register = %0s, wdata = %0h rdata = %0h","MSIX_ADDR0",wdata, rdata), UVM_LOW)


     //==================================================
     // Write and Read 'h00000000_00000000 to MSIX_ADDR0
     //==================================================
     wdata='h00000000_00000000 ;
     default_value=64'h0000000000000000 ;
     rw_bits = 'hFFFFFFFFFFFFFFFF ;
     INTR_REGS.MSIX_ADDR0.write(status,wdata);
      `ifdef COV INTR_REGS.MSIX_ADDR0.cg_vals.sample();`endif
     INTR_REGS.MSIX_ADDR0.read(status,rdata);
      `ifdef COV INTR_REGS.MSIX_ADDR0.cg_vals.sample();`endif
     wdata=(wdata|default_value)&(~rw_bits) ;
     `uvm_info(get_name(), $psprintf("Register = %0s, data = %0h rw_bits_data = %h","MSIX_ADDR0",wdata , rw_bits), UVM_LOW)
     if(rdata !== wdata )
      `uvm_error(get_name(), $psprintf("Data mismatch 64! Register = %0s, Exp = %0h, Act = %0h", "MSIX_ADDR0",wdata, rdata))
     else
      `uvm_info(get_name(), $psprintf("Data match 64! Register = %0s, wdata = %0h rdata = %0h","MSIX_ADDR0",wdata, rdata), UVM_LOW)

     //==================================================
     // Write and Read 32'hFFFFFFFF to MSIX_ADDR0 
     //==================================================
     wdata=32'hFFFFFFFF ;
     default_value=64'h0000000000000000 ;
     rw_bits = 'hFFFFFFFF ;
     INTR_REGS.MSIX_ADDR0.write(status,wdata);
      `ifdef COV INTR_REGS.MSIX_ADDR0.cg_vals.sample();`endif
     INTR_REGS.MSIX_ADDR0.read(status,rdata);
      `ifdef COV INTR_REGS.MSIX_ADDR0.cg_vals.sample();`endif
     wdata=(wdata&default_value)|rw_bits ;
     `uvm_info(get_name(), $psprintf("Register = %0s, data = %0h rw_bits_data = %h","MSIX_ADDR0",wdata , rw_bits), UVM_LOW)
     if(rdata !== wdata )
      `uvm_error(get_name(), $psprintf("Data mismatch 64! Register = %0s, Exp = %0h, Act = %0h", "MSIX_ADDR0",wdata, rdata))
     else
      `uvm_info(get_name(), $psprintf("Data match 64! Register = %0s, wdata = %0h rdata = %0h","MSIX_ADDR0",wdata, rdata), UVM_LOW)


     //==================================================
     // Write and Read 32'hAAAAAAAA to MSIX_ADDR0
     //==================================================
     wdata=32'hAAAAAAAA ;
     default_value=64'h0000000000000000 ;
     rw_bits = 'hFFFFFFFF ;
     INTR_REGS.MSIX_ADDR0.write(status,wdata);
      `ifdef COV INTR_REGS.MSIX_ADDR0.cg_vals.sample();`endif
     INTR_REGS.MSIX_ADDR0.read(status,rdata);
      `ifdef COV INTR_REGS.MSIX_ADDR0.cg_vals.sample();`endif
     wdata=(wdata&rw_bits)|default_value;
     `uvm_info(get_name(), $psprintf("Register = %0s, data = %0h rw_bits_data = %h","MSIX_ADDR0",wdata , rw_bits), UVM_LOW)
     if(rdata !== wdata )
      `uvm_error(get_name(), $psprintf("Data mismatch 64! Register = %0s, Exp = %0h, Act = %0h", "MSIX_ADDR0",wdata, rdata))
     else
      `uvm_info(get_name(), $psprintf("Data match 64! Register = %0s, wdata = %0h rdata = %0h","MSIX_ADDR0",wdata, rdata), UVM_LOW)


     //==================================================
     // Write and Read 32'h00000000 to MSIX_ADDR0
     //==================================================
     wdata=32'h00000000 ;
     default_value=64'h0000000000000000 ;
     rw_bits = 'hFFFFFFFF ;
     INTR_REGS.MSIX_ADDR0.write(status,wdata);
      `ifdef COV INTR_REGS.MSIX_ADDR0.cg_vals.sample();`endif
     INTR_REGS.MSIX_ADDR0.read(status,rdata);
      `ifdef COV INTR_REGS.MSIX_ADDR0.cg_vals.sample();`endif
     wdata=(wdata|default_value)&(~rw_bits) ;
     `uvm_info(get_name(), $psprintf("Register = %0s, data = %0h rw_bits_data = %h","MSIX_ADDR0",wdata , rw_bits), UVM_LOW)
     if(rdata !== wdata )
      `uvm_error(get_name(), $psprintf("Data mismatch 64! Register = %0s, Exp = %0h, Act = %0h", "MSIX_ADDR0",wdata, rdata))
     else
      `uvm_info(get_name(), $psprintf("Data match 64! Register = %0s, wdata = %0h rdata = %0h","MSIX_ADDR0",wdata, rdata), UVM_LOW)

     //==================================================
     // Write and Read 'hFFFFFFFF_FFFFFFFF to MSIX_CTLDAT0
     //==================================================
     wdata='hFFFFFFFF_FFFFFFFF ;
     default_value=64'h0000000100000000 ;
     rw_bits = 'hFFFFFFFFFFFFFFFF ;
     INTR_REGS.MSIX_CTLDAT0.write(status,wdata);
      `ifdef COV INTR_REGS.MSIX_CTLDAT0.cg_vals.sample();`endif
     INTR_REGS.MSIX_CTLDAT0.read(status,rdata);
      `ifdef COV INTR_REGS.MSIX_CTLDAT0.cg_vals.sample();`endif
     wdata=(wdata&default_value)|rw_bits ;
     `uvm_info(get_name(), $psprintf("Register = %0s, data = %0h rw_bits_data = %h","MSIX_CTLDAT0",wdata , rw_bits), UVM_LOW)
     if(rdata !== wdata )
      `uvm_error(get_name(), $psprintf("Data mismatch 64! Register = %0s, Exp = %0h, Act = %0h", "MSIX_CTLDAT0",wdata, rdata))
     else
      `uvm_info(get_name(), $psprintf("Data match 64! Register = %0s, wdata = %0h rdata = %0h","MSIX_CTLDAT0",wdata, rdata), UVM_LOW)


     //==================================================
     // Write and Read 'hAAAAAAAA_AAAAAAAA to MSIX_CTLDAT0
     //==================================================
     wdata='hAAAAAAAB_AAAAAAAA ;
     default_value=64'h00000001_00000000 ;
     rw_bits = 'hFFFFFFFF_FFFFFFFF ;
     INTR_REGS.MSIX_CTLDAT0.write(status,wdata);
      `ifdef COV INTR_REGS.MSIX_CTLDAT0.cg_vals.sample();`endif
     INTR_REGS.MSIX_CTLDAT0.read(status,rdata);
      `ifdef COV INTR_REGS.MSIX_CTLDAT0.cg_vals.sample();`endif
     wdata=(wdata&rw_bits)|default_value;
     `uvm_info(get_name(), $psprintf("Register = %0s, data = %0h rw_bits_data = %h","MSIX_CTLDAT0",wdata , rw_bits), UVM_LOW)
     if(rdata !== wdata )
      `uvm_error(get_name(), $psprintf("Data mismatch 64! Register = %0s, Exp = %0h, Act = %0h", "MSIX_CTLDAT0",wdata, rdata))
     else
      `uvm_info(get_name(), $psprintf("Data match 64! Register = %0s, wdata = %0h rdata = %0h","MSIX_CTLDAT0",wdata, rdata), UVM_LOW)


     //==================================================
     // Write and Read 'h00000000_00000000 to MSIX_CTLDAT0
     //==================================================
     wdata='h00000000_00000000 ;
     default_value=64'h0000000100000000 ;
     rw_bits = 'hFFFFFFFFFFFFFFFF ;
     INTR_REGS.MSIX_CTLDAT0.write(status,wdata);
      `ifdef COV INTR_REGS.MSIX_CTLDAT0.cg_vals.sample();`endif
     INTR_REGS.MSIX_CTLDAT0.read(status,rdata);
      `ifdef COV INTR_REGS.MSIX_CTLDAT0.cg_vals.sample();`endif
     wdata=(wdata|default_value)&(~rw_bits) ;
     `uvm_info(get_name(), $psprintf("Register = %0s, data = %0h rw_bits_data = %h","MSIX_CTLDAT0",wdata , rw_bits), UVM_LOW)
     if(rdata !== wdata )
      `uvm_error(get_name(), $psprintf("Data mismatch 64! Register = %0s, Exp = %0h, Act = %0h", "MSIX_CTLDAT0",wdata, rdata))
     else
      `uvm_info(get_name(), $psprintf("Data match 64! Register = %0s, wdata = %0h rdata = %0h","MSIX_CTLDAT0",wdata, rdata), UVM_LOW)


     //==================================================
     // Write and Read 'hFFFFFFFF_FFFFFFFF to MSIX_ADDR1
     //==================================================
     wdata='hFFFFFFFF_FFFFFFFF ;
     default_value=64'h0000000000000000 ;
     rw_bits = 'hFFFFFFFFFFFFFFFF ;
     INTR_REGS.MSIX_ADDR1.write(status,wdata);
      `ifdef COV INTR_REGS.MSIX_ADDR1.cg_vals.sample();`endif
     INTR_REGS.MSIX_ADDR1.read(status,rdata);
      `ifdef COV INTR_REGS.MSIX_ADDR1.cg_vals.sample();`endif
     wdata=(wdata&default_value)|rw_bits ;
     `uvm_info(get_name(), $psprintf("Register = %0s, data = %0h rw_bits_data = %h","MSIX_ADDR1",wdata , rw_bits), UVM_LOW)
     if(rdata !== wdata )
      `uvm_error(get_name(), $psprintf("Data mismatch 64! Register = %0s, Exp = %0h, Act = %0h", "MSIX_ADDR1",wdata, rdata))
     else
      `uvm_info(get_name(), $psprintf("Data match 64! Register = %0s, wdata = %0h rdata = %0h","MSIX_ADDR1",wdata, rdata), UVM_LOW)


     //==================================================
     // Write and Read 'hAAAAAAAA_AAAAAAAA to MSIX_ADDR1
     //==================================================
     wdata='hAAAAAAAA_AAAAAAAA ;
     default_value=64'h0000000000000000 ;
     rw_bits = 'hFFFFFFFFFFFFFFFF ;
     INTR_REGS.MSIX_ADDR1.write(status,wdata);
      `ifdef COV INTR_REGS.MSIX_ADDR1.cg_vals.sample();`endif
     INTR_REGS.MSIX_ADDR1.read(status,rdata);
      `ifdef COV INTR_REGS.MSIX_ADDR1.cg_vals.sample();`endif
     wdata=(wdata&rw_bits)|default_value;
     `uvm_info(get_name(), $psprintf("Register = %0s, data = %0h rw_bits_data = %h","MSIX_ADDR1",wdata , rw_bits), UVM_LOW)
     if(rdata !== wdata )
      `uvm_error(get_name(), $psprintf("Data mismatch 64! Register = %0s, Exp = %0h, Act = %0h", "MSIX_ADDR1",wdata, rdata))
     else
      `uvm_info(get_name(), $psprintf("Data match 64! Register = %0s, wdata = %0h rdata = %0h","MSIX_ADDR1",wdata, rdata), UVM_LOW)


     //==================================================
     // Write and Read 'h00000000_00000000 to MSIX_ADDR1
     //==================================================
     wdata='h00000000_00000000 ;
     default_value=64'h0000000000000000 ;
     rw_bits = 'hFFFFFFFFFFFFFFFF ;
     INTR_REGS.MSIX_ADDR1.write(status,wdata);
      `ifdef COV INTR_REGS.MSIX_ADDR1.cg_vals.sample();`endif
     INTR_REGS.MSIX_ADDR1.read(status,rdata);
      `ifdef COV INTR_REGS.MSIX_ADDR1.cg_vals.sample();`endif
     wdata=(wdata|default_value)&(~rw_bits) ;
     `uvm_info(get_name(), $psprintf("Register = %0s, data = %0h rw_bits_data = %h","MSIX_ADDR1",wdata , rw_bits), UVM_LOW)
     if(rdata !== wdata )
      `uvm_error(get_name(), $psprintf("Data mismatch 64! Register = %0s, Exp = %0h, Act = %0h", "MSIX_ADDR1",wdata, rdata))
     else
      `uvm_info(get_name(), $psprintf("Data match 64! Register = %0s, wdata = %0h rdata = %0h","MSIX_ADDR1",wdata, rdata), UVM_LOW)


     //==================================================
     // Write and Read 'hFFFFFFFF_FFFFFFFF to MSIX_CTLDAT1
     //==================================================
     wdata='hFFFFFFFF_FFFFFFFF ;
     default_value=64'h0000000100000000 ;
     rw_bits = 'hFFFFFFFFFFFFFFFF ;
     INTR_REGS.MSIX_CTLDAT1.write(status,wdata);
      `ifdef COV INTR_REGS.MSIX_CTLDAT1.cg_vals.sample();`endif
     INTR_REGS.MSIX_CTLDAT1.read(status,rdata);
      `ifdef COV INTR_REGS.MSIX_CTLDAT1.cg_vals.sample();`endif
     wdata=(wdata&default_value)|rw_bits ;
     `uvm_info(get_name(), $psprintf("Register = %0s, data = %0h rw_bits_data = %h","MSIX_CTLDAT1",wdata , rw_bits), UVM_LOW)
     if(rdata !== wdata )
      `uvm_error(get_name(), $psprintf("Data mismatch 64! Register = %0s, Exp = %0h, Act = %0h", "MSIX_CTLDAT1",wdata, rdata))
     else
      `uvm_info(get_name(), $psprintf("Data match 64! Register = %0s, wdata = %0h rdata = %0h","MSIX_CTLDAT1",wdata, rdata), UVM_LOW)


     //==================================================
     // Write and Read 'hAAAAAAAA_AAAAAAAA to MSIX_CTLDAT1
     //==================================================
     wdata='hAAAAAAAB_AAAAAAAA ;
     default_value=64'h0000000100000000 ;
     rw_bits = 'hFFFFFFFFFFFFFFFF ;
     INTR_REGS.MSIX_CTLDAT1.write(status,wdata);
      `ifdef COV INTR_REGS.MSIX_CTLDAT1.cg_vals.sample();`endif
     INTR_REGS.MSIX_CTLDAT1.read(status,rdata);
      `ifdef COV INTR_REGS.MSIX_CTLDAT1.cg_vals.sample();`endif
     wdata=(wdata&rw_bits)|default_value;
     `uvm_info(get_name(), $psprintf("Register = %0s, data = %0h rw_bits_data = %h","MSIX_CTLDAT1",wdata , rw_bits), UVM_LOW)
     if(rdata !== wdata )
      `uvm_error(get_name(), $psprintf("Data mismatch 64! Register = %0s, Exp = %0h, Act = %0h", "MSIX_CTLDAT1",wdata, rdata))
     else
      `uvm_info(get_name(), $psprintf("Data match 64! Register = %0s, wdata = %0h rdata = %0h","MSIX_CTLDAT1",wdata, rdata), UVM_LOW)


     //==================================================
     // Write and Read 'h00000000_00000000 to MSIX_CTLDAT1
     //==================================================
     wdata='h00000000_00000000 ;
     default_value=64'h0000000100000000 ;
     rw_bits = 'hFFFFFFFFFFFFFFFF ;
     INTR_REGS.MSIX_CTLDAT1.write(status,wdata);
      `ifdef COV INTR_REGS.MSIX_CTLDAT1.cg_vals.sample();`endif
     INTR_REGS.MSIX_CTLDAT1.read(status,rdata);
      `ifdef COV INTR_REGS.MSIX_CTLDAT1.cg_vals.sample();`endif
     wdata=(wdata|default_value)&(~rw_bits) ;
     `uvm_info(get_name(), $psprintf("Register = %0s, data = %0h rw_bits_data = %h","MSIX_CTLDAT1",wdata , rw_bits), UVM_LOW)
     if(rdata !== wdata )
      `uvm_error(get_name(), $psprintf("Data mismatch 64! Register = %0s, Exp = %0h, Act = %0h", "MSIX_CTLDAT1",wdata, rdata))
     else
      `uvm_info(get_name(), $psprintf("Data match 64! Register = %0s, wdata = %0h rdata = %0h","MSIX_CTLDAT1",wdata, rdata), UVM_LOW)


     //==================================================
     // Write and Read 'hFFFFFFFF_FFFFFFFF to MSIX_ADDR2
     //==================================================
     wdata='hFFFFFFFF_FFFFFFFF ;
     default_value=64'h0000000000000000 ;
     rw_bits = 'hFFFFFFFFFFFFFFFF ;
     INTR_REGS.MSIX_ADDR2.write(status,wdata);
      `ifdef COV INTR_REGS.MSIX_ADDR2.cg_vals.sample();`endif
     INTR_REGS.MSIX_ADDR2.read(status,rdata);
      `ifdef COV INTR_REGS.MSIX_ADDR2.cg_vals.sample();`endif
     wdata=(wdata&default_value)|rw_bits ;
     `uvm_info(get_name(), $psprintf("Register = %0s, data = %0h rw_bits_data = %h","MSIX_ADDR2",wdata , rw_bits), UVM_LOW)
     if(rdata !== wdata )
      `uvm_error(get_name(), $psprintf("Data mismatch 64! Register = %0s, Exp = %0h, Act = %0h", "MSIX_ADDR2",wdata, rdata))
     else
      `uvm_info(get_name(), $psprintf("Data match 64! Register = %0s, wdata = %0h rdata = %0h","MSIX_ADDR2",wdata, rdata), UVM_LOW)


     //==================================================
     // Write and Read 'hAAAAAAAA_AAAAAAAA to MSIX_ADDR2
     //==================================================
     wdata='hAAAAAAAA_AAAAAAAA ;
     default_value=64'h0000000000000000 ;
     rw_bits = 'hFFFFFFFFFFFFFFFF ;
     INTR_REGS.MSIX_ADDR2.write(status,wdata);
      `ifdef COV INTR_REGS.MSIX_ADDR2.cg_vals.sample();`endif
     INTR_REGS.MSIX_ADDR2.read(status,rdata);
      `ifdef COV INTR_REGS.MSIX_ADDR2.cg_vals.sample();`endif
     wdata=(wdata&rw_bits)|default_value;
     `uvm_info(get_name(), $psprintf("Register = %0s, data = %0h rw_bits_data = %h","MSIX_ADDR2",wdata , rw_bits), UVM_LOW)
     if(rdata !== wdata )
      `uvm_error(get_name(), $psprintf("Data mismatch 64! Register = %0s, Exp = %0h, Act = %0h", "MSIX_ADDR2",wdata, rdata))
     else
      `uvm_info(get_name(), $psprintf("Data match 64! Register = %0s, wdata = %0h rdata = %0h","MSIX_ADDR2",wdata, rdata), UVM_LOW)


     //==================================================
     // Write and Read 'h00000000_00000000 to MSIX_ADDR2
     //==================================================
     wdata='h00000000_00000000 ;
     default_value=64'h0000000000000000 ;
     rw_bits = 'hFFFFFFFFFFFFFFFF ;
     INTR_REGS.MSIX_ADDR2.write(status,wdata);
      `ifdef COV INTR_REGS.MSIX_ADDR2.cg_vals.sample();`endif
     INTR_REGS.MSIX_ADDR2.read(status,rdata);
      `ifdef COV INTR_REGS.MSIX_ADDR2.cg_vals.sample();`endif
     wdata=(wdata|default_value)&(~rw_bits) ;
     `uvm_info(get_name(), $psprintf("Register = %0s, data = %0h rw_bits_data = %h","MSIX_ADDR2",wdata , rw_bits), UVM_LOW)
     if(rdata !== wdata )
      `uvm_error(get_name(), $psprintf("Data mismatch 64! Register = %0s, Exp = %0h, Act = %0h", "MSIX_ADDR2",wdata, rdata))
     else
      `uvm_info(get_name(), $psprintf("Data match 64! Register = %0s, wdata = %0h rdata = %0h","MSIX_ADDR2",wdata, rdata), UVM_LOW)


     //==================================================
     // Write and Read 'hFFFFFFFF_FFFFFFFF to MSIX_CTLDAT2
     //==================================================
     wdata='hFFFFFFFF_FFFFFFFF ;
     default_value=64'h0000000100000000 ;
     rw_bits = 'hFFFFFFFFFFFFFFFF ;
     INTR_REGS.MSIX_CTLDAT2.write(status,wdata);
      `ifdef COV INTR_REGS.MSIX_CTLDAT2.cg_vals.sample();`endif
     INTR_REGS.MSIX_CTLDAT2.read(status,rdata);
      `ifdef COV INTR_REGS.MSIX_CTLDAT2.cg_vals.sample();`endif
     wdata=(wdata&default_value)|rw_bits ;
     `uvm_info(get_name(), $psprintf("Register = %0s, data = %0h rw_bits_data = %h","MSIX_CTLDAT2",wdata , rw_bits), UVM_LOW)
     if(rdata !== wdata )
      `uvm_error(get_name(), $psprintf("Data mismatch 64! Register = %0s, Exp = %0h, Act = %0h", "MSIX_CTLDAT2",wdata, rdata))
     else
      `uvm_info(get_name(), $psprintf("Data match 64! Register = %0s, wdata = %0h rdata = %0h","MSIX_CTLDAT2",wdata, rdata), UVM_LOW)


     //==================================================
     // Write and Read 'hAAAAAAAA_AAAAAAAA to MSIX_CTLDAT2
     //==================================================
     wdata='hAAAAAAAB_AAAAAAAA ;
     default_value=64'h0000000100000000 ;
     rw_bits = 'hFFFFFFFFFFFFFFFF ;
     INTR_REGS.MSIX_CTLDAT2.write(status,wdata);
      `ifdef COV INTR_REGS.MSIX_CTLDAT2.cg_vals.sample();`endif
     INTR_REGS.MSIX_CTLDAT2.read(status,rdata);
      `ifdef COV INTR_REGS.MSIX_CTLDAT2.cg_vals.sample();`endif
     wdata=(wdata&rw_bits)|default_value;
     `uvm_info(get_name(), $psprintf("Register = %0s, data = %0h rw_bits_data = %h","MSIX_CTLDAT2",wdata , rw_bits), UVM_LOW)
     if(rdata !== wdata )
      `uvm_error(get_name(), $psprintf("Data mismatch 64! Register = %0s, Exp = %0h, Act = %0h", "MSIX_CTLDAT2",wdata, rdata))
     else
      `uvm_info(get_name(), $psprintf("Data match 64! Register = %0s, wdata = %0h rdata = %0h","MSIX_CTLDAT2",wdata, rdata), UVM_LOW)


     //==================================================
     // Write and Read 'h00000000_00000000 to MSIX_CTLDAT2
     //==================================================
     wdata='h00000000_00000000 ;
     default_value=64'h0000000100000000 ;
     rw_bits = 'hFFFFFFFFFFFFFFFF ;
     INTR_REGS.MSIX_CTLDAT2.write(status,wdata);
      `ifdef COV INTR_REGS.MSIX_CTLDAT2.cg_vals.sample();`endif
     INTR_REGS.MSIX_CTLDAT2.read(status,rdata);
      `ifdef COV INTR_REGS.MSIX_CTLDAT2.cg_vals.sample();`endif
     wdata=(wdata|default_value)&(~rw_bits) ;
     `uvm_info(get_name(), $psprintf("Register = %0s, data = %0h rw_bits_data = %h","MSIX_CTLDAT2",wdata , rw_bits), UVM_LOW)
     if(rdata !== wdata )
      `uvm_error(get_name(), $psprintf("Data mismatch 64! Register = %0s, Exp = %0h, Act = %0h", "MSIX_CTLDAT2",wdata, rdata))
     else
      `uvm_info(get_name(), $psprintf("Data match 64! Register = %0s, wdata = %0h rdata = %0h","MSIX_CTLDAT2",wdata, rdata), UVM_LOW)


     //==================================================
     // Write and Read 'hFFFFFFFF_FFFFFFFF to MSIX_ADDR3
     //==================================================
     wdata='hFFFFFFFF_FFFFFFFF ;
     default_value=64'h0000000000000000 ;
     rw_bits = 'hFFFFFFFFFFFFFFFF ;
     INTR_REGS.MSIX_ADDR3.write(status,wdata);
      `ifdef COV INTR_REGS.MSIX_ADDR3.cg_vals.sample();`endif
     INTR_REGS.MSIX_ADDR3.read(status,rdata);
      `ifdef COV INTR_REGS.MSIX_ADDR3.cg_vals.sample();`endif
     wdata=(wdata&default_value)|rw_bits ;
     `uvm_info(get_name(), $psprintf("Register = %0s, data = %0h rw_bits_data = %h","MSIX_ADDR3",wdata , rw_bits), UVM_LOW)
     if(rdata !== wdata )
      `uvm_error(get_name(), $psprintf("Data mismatch 64! Register = %0s, Exp = %0h, Act = %0h", "MSIX_ADDR3",wdata, rdata))
     else
      `uvm_info(get_name(), $psprintf("Data match 64! Register = %0s, wdata = %0h rdata = %0h","MSIX_ADDR3",wdata, rdata), UVM_LOW)


     //==================================================
     // Write and Read 'hAAAAAAAA_AAAAAAAA to MSIX_ADDR3
     //==================================================
     wdata='hAAAAAAAA_AAAAAAAA ;
     default_value=64'h0000000000000000 ;
     rw_bits = 'hFFFFFFFFFFFFFFFF ;
     INTR_REGS.MSIX_ADDR3.write(status,wdata);
      `ifdef COV INTR_REGS.MSIX_ADDR3.cg_vals.sample();`endif
     INTR_REGS.MSIX_ADDR3.read(status,rdata);
      `ifdef COV INTR_REGS.MSIX_ADDR3.cg_vals.sample();`endif
     wdata=(wdata&rw_bits)|default_value;
     `uvm_info(get_name(), $psprintf("Register = %0s, data = %0h rw_bits_data = %h","MSIX_ADDR3",wdata , rw_bits), UVM_LOW)
     if(rdata !== wdata )
      `uvm_error(get_name(), $psprintf("Data mismatch 64! Register = %0s, Exp = %0h, Act = %0h", "MSIX_ADDR3",wdata, rdata))
     else
      `uvm_info(get_name(), $psprintf("Data match 64! Register = %0s, wdata = %0h rdata = %0h","MSIX_ADDR3",wdata, rdata), UVM_LOW)


     //==================================================
     // Write and Read 'h00000000_00000000 to MSIX_ADDR3
     //==================================================
     wdata='h00000000_00000000 ;
     default_value=64'h0000000000000000 ;
     rw_bits = 'hFFFFFFFFFFFFFFFF ;
     INTR_REGS.MSIX_ADDR3.write(status,wdata);
      `ifdef COV INTR_REGS.MSIX_ADDR3.cg_vals.sample();`endif
     INTR_REGS.MSIX_ADDR3.read(status,rdata);
      `ifdef COV INTR_REGS.MSIX_ADDR3.cg_vals.sample();`endif
     wdata=(wdata|default_value)&(~rw_bits) ;
     `uvm_info(get_name(), $psprintf("Register = %0s, data = %0h rw_bits_data = %h","MSIX_ADDR3",wdata , rw_bits), UVM_LOW)
     if(rdata !== wdata )
      `uvm_error(get_name(), $psprintf("Data mismatch 64! Register = %0s, Exp = %0h, Act = %0h", "MSIX_ADDR3",wdata, rdata))
     else
      `uvm_info(get_name(), $psprintf("Data match 64! Register = %0s, wdata = %0h rdata = %0h","MSIX_ADDR3",wdata, rdata), UVM_LOW)


     //==================================================
     // Write and Read 'hFFFFFFFF_FFFFFFFF to MSIX_CTLDAT3
     //==================================================
     wdata='hFFFFFFFF_FFFFFFFF ;
     default_value=64'h0000000100000000 ;
     rw_bits = 'hFFFFFFFFFFFFFFFF ;
     INTR_REGS.MSIX_CTLDAT3.write(status,wdata);
      `ifdef COV INTR_REGS.MSIX_CTLDAT3.cg_vals.sample();`endif
     INTR_REGS.MSIX_CTLDAT3.read(status,rdata);
      `ifdef COV INTR_REGS.MSIX_CTLDAT3.cg_vals.sample();`endif
     wdata=(wdata&default_value)|rw_bits ;
     `uvm_info(get_name(), $psprintf("Register = %0s, data = %0h rw_bits_data = %h","MSIX_CTLDAT3",wdata , rw_bits), UVM_LOW)
     if(rdata !== wdata )
      `uvm_error(get_name(), $psprintf("Data mismatch 64! Register = %0s, Exp = %0h, Act = %0h", "MSIX_CTLDAT3",wdata, rdata))
     else
      `uvm_info(get_name(), $psprintf("Data match 64! Register = %0s, wdata = %0h rdata = %0h","MSIX_CTLDAT3",wdata, rdata), UVM_LOW)


     //==================================================
     // Write and Read 'hAAAAAAAA_AAAAAAAA to MSIX_CTLDAT3
     //==================================================
     wdata='hAAAAAAAB_AAAAAAAA ;
     default_value=64'h0000000100000000 ;
     rw_bits = 'hFFFFFFFFFFFFFFFF ;
     INTR_REGS.MSIX_CTLDAT3.write(status,wdata);
      `ifdef COV INTR_REGS.MSIX_CTLDAT3.cg_vals.sample();`endif
     INTR_REGS.MSIX_CTLDAT3.read(status,rdata);
      `ifdef COV INTR_REGS.MSIX_CTLDAT3.cg_vals.sample();`endif
     wdata=(wdata&rw_bits)|default_value;
     `uvm_info(get_name(), $psprintf("Register = %0s, data = %0h rw_bits_data = %h","MSIX_CTLDAT3",wdata , rw_bits), UVM_LOW)
     if(rdata !== wdata )
      `uvm_error(get_name(), $psprintf("Data mismatch 64! Register = %0s, Exp = %0h, Act = %0h", "MSIX_CTLDAT3",wdata, rdata))
     else
      `uvm_info(get_name(), $psprintf("Data match 64! Register = %0s, wdata = %0h rdata = %0h","MSIX_CTLDAT3",wdata, rdata), UVM_LOW)


     //==================================================
     // Write and Read 'h00000000_00000000 to MSIX_CTLDAT3
     //==================================================
     wdata='h00000000_00000000 ;
     default_value=64'h0000000100000000 ;
     rw_bits = 'hFFFFFFFFFFFFFFFF ;
     INTR_REGS.MSIX_CTLDAT3.write(status,wdata);
      `ifdef COV INTR_REGS.MSIX_CTLDAT3.cg_vals.sample();`endif
     INTR_REGS.MSIX_CTLDAT3.read(status,rdata);
      `ifdef COV INTR_REGS.MSIX_CTLDAT3.cg_vals.sample();`endif
     wdata=(wdata|default_value)&(~rw_bits) ;
     `uvm_info(get_name(), $psprintf("Register = %0s, data = %0h rw_bits_data = %h","MSIX_CTLDAT3",wdata , rw_bits), UVM_LOW)
     if(rdata !== wdata )
      `uvm_error(get_name(), $psprintf("Data mismatch 64! Register = %0s, Exp = %0h, Act = %0h", "MSIX_CTLDAT3",wdata, rdata))
     else
      `uvm_info(get_name(), $psprintf("Data match 64! Register = %0s, wdata = %0h rdata = %0h","MSIX_CTLDAT3",wdata, rdata), UVM_LOW)


     //==================================================
     // Write and Read 'hFFFFFFFF_FFFFFFFF to MSIX_ADDR4
     //==================================================
     wdata='hFFFFFFFF_FFFFFFFF ;
     default_value=64'h0000000000000000 ;
     rw_bits = 'hFFFFFFFFFFFFFFFF ;
     INTR_REGS.MSIX_ADDR4.write(status,wdata);
      `ifdef COV INTR_REGS.MSIX_ADDR4.cg_vals.sample();`endif
     INTR_REGS.MSIX_ADDR4.read(status,rdata);
      `ifdef COV INTR_REGS.MSIX_ADDR4.cg_vals.sample();`endif
     wdata=(wdata&default_value)|rw_bits ;
     `uvm_info(get_name(), $psprintf("Register = %0s, data = %0h rw_bits_data = %h","MSIX_ADDR4",wdata , rw_bits), UVM_LOW)
     if(rdata !== wdata )
      `uvm_error(get_name(), $psprintf("Data mismatch 64! Register = %0s, Exp = %0h, Act = %0h", "MSIX_ADDR4",wdata, rdata))
     else
      `uvm_info(get_name(), $psprintf("Data match 64! Register = %0s, wdata = %0h rdata = %0h","MSIX_ADDR4",wdata, rdata), UVM_LOW)


     //==================================================
     // Write and Read 'hAAAAAAAA_AAAAAAAA to MSIX_ADDR4
     //==================================================
     wdata='hAAAAAAAA_AAAAAAAA ;
     default_value=64'h0000000000000000 ;
     rw_bits = 'hFFFFFFFFFFFFFFFF ;
     INTR_REGS.MSIX_ADDR4.write(status,wdata);
      `ifdef COV INTR_REGS.MSIX_ADDR4.cg_vals.sample();`endif
     INTR_REGS.MSIX_ADDR4.read(status,rdata);
      `ifdef COV INTR_REGS.MSIX_ADDR4.cg_vals.sample();`endif
     wdata=(wdata&rw_bits)|default_value;
     `uvm_info(get_name(), $psprintf("Register = %0s, data = %0h rw_bits_data = %h","MSIX_ADDR4",wdata , rw_bits), UVM_LOW)
     if(rdata !== wdata )
      `uvm_error(get_name(), $psprintf("Data mismatch 64! Register = %0s, Exp = %0h, Act = %0h", "MSIX_ADDR4",wdata, rdata))
     else
      `uvm_info(get_name(), $psprintf("Data match 64! Register = %0s, wdata = %0h rdata = %0h","MSIX_ADDR4",wdata, rdata), UVM_LOW)


     //==================================================
     // Write and Read 'h00000000_00000000 to MSIX_ADDR4
     //==================================================
     wdata='h00000000_00000000 ;
     default_value=64'h0000000000000000 ;
     rw_bits = 'hFFFFFFFFFFFFFFFF ;
     INTR_REGS.MSIX_ADDR4.write(status,wdata);
      `ifdef COV INTR_REGS.MSIX_ADDR4.cg_vals.sample();`endif
     INTR_REGS.MSIX_ADDR4.read(status,rdata);
      `ifdef COV INTR_REGS.MSIX_ADDR4.cg_vals.sample();`endif
     wdata=(wdata|default_value)&(~rw_bits) ;
     `uvm_info(get_name(), $psprintf("Register = %0s, data = %0h rw_bits_data = %h","MSIX_ADDR4",wdata , rw_bits), UVM_LOW)
     if(rdata !== wdata )
      `uvm_error(get_name(), $psprintf("Data mismatch 64! Register = %0s, Exp = %0h, Act = %0h", "MSIX_ADDR4",wdata, rdata))
     else
      `uvm_info(get_name(), $psprintf("Data match 64! Register = %0s, wdata = %0h rdata = %0h","MSIX_ADDR4",wdata, rdata), UVM_LOW)


     //==================================================
     // Write and Read 'hFFFFFFFF_FFFFFFFF to MSIX_CTLDAT4
     //==================================================
     wdata='hFFFFFFFF_FFFFFFFF ;
     default_value=64'h0000000100000000 ;
     rw_bits = 'hFFFFFFFFFFFFFFFF ;
     INTR_REGS.MSIX_CTLDAT4.write(status,wdata);
      `ifdef COV INTR_REGS.MSIX_CTLDAT4.cg_vals.sample();`endif
     INTR_REGS.MSIX_CTLDAT4.read(status,rdata);
      `ifdef COV INTR_REGS.MSIX_CTLDAT4.cg_vals.sample();`endif
     wdata=(wdata&default_value)|rw_bits ;
     `uvm_info(get_name(), $psprintf("Register = %0s, data = %0h rw_bits_data = %h","MSIX_CTLDAT4",wdata , rw_bits), UVM_LOW)
     if(rdata !== wdata )
      `uvm_error(get_name(), $psprintf("Data mismatch 64! Register = %0s, Exp = %0h, Act = %0h", "MSIX_CTLDAT4",wdata, rdata))
     else
      `uvm_info(get_name(), $psprintf("Data match 64! Register = %0s, wdata = %0h rdata = %0h","MSIX_CTLDAT4",wdata, rdata), UVM_LOW)


     //==================================================
     // Write and Read 'hAAAAAAAA_AAAAAAAA to MSIX_CTLDAT4
     //==================================================
     wdata='hAAAAAAAB_AAAAAAAA ;
     default_value=64'h0000000100000000 ;
     rw_bits = 'hFFFFFFFFFFFFFFFF ;
     INTR_REGS.MSIX_CTLDAT4.write(status,wdata);
      `ifdef COV INTR_REGS.MSIX_CTLDAT4.cg_vals.sample();`endif
     INTR_REGS.MSIX_CTLDAT4.read(status,rdata);
      `ifdef COV INTR_REGS.MSIX_CTLDAT4.cg_vals.sample();`endif
     wdata=(wdata&rw_bits)|default_value;
     `uvm_info(get_name(), $psprintf("Register = %0s, data = %0h rw_bits_data = %h","MSIX_CTLDAT4",wdata , rw_bits), UVM_LOW)
     if(rdata !== wdata )
      `uvm_error(get_name(), $psprintf("Data mismatch 64! Register = %0s, Exp = %0h, Act = %0h", "MSIX_CTLDAT4",wdata, rdata))
     else
      `uvm_info(get_name(), $psprintf("Data match 64! Register = %0s, wdata = %0h rdata = %0h","MSIX_CTLDAT4",wdata, rdata), UVM_LOW)


     //==================================================
     // Write and Read 'h00000000_00000000 to MSIX_CTLDAT4
     //==================================================
     wdata='h00000000_00000000 ;
     default_value=64'h0000000100000000 ;
     rw_bits = 'hFFFFFFFFFFFFFFFF ;
     INTR_REGS.MSIX_CTLDAT4.write(status,wdata);
      `ifdef COV INTR_REGS.MSIX_CTLDAT4.cg_vals.sample();`endif
     INTR_REGS.MSIX_CTLDAT4.read(status,rdata);
      `ifdef COV INTR_REGS.MSIX_CTLDAT4.cg_vals.sample();`endif
     wdata=(wdata|default_value)&(~rw_bits) ;
     `uvm_info(get_name(), $psprintf("Register = %0s, data = %0h rw_bits_data = %h","MSIX_CTLDAT4",wdata , rw_bits), UVM_LOW)
     if(rdata !== wdata )
      `uvm_error(get_name(), $psprintf("Data mismatch 64! Register = %0s, Exp = %0h, Act = %0h", "MSIX_CTLDAT4",wdata, rdata))
     else
      `uvm_info(get_name(), $psprintf("Data match 64! Register = %0s, wdata = %0h rdata = %0h","MSIX_CTLDAT4",wdata, rdata), UVM_LOW)


     //==================================================
     // Write and Read 'hFFFFFFFF_FFFFFFFF to MSIX_ADDR5
     //==================================================
     wdata='hFFFFFFFF_FFFFFFFF ;
     default_value=64'h0000000000000000 ;
     rw_bits = 'hFFFFFFFFFFFFFFFF ;
     INTR_REGS.MSIX_ADDR5.write(status,wdata);
      `ifdef COV INTR_REGS.MSIX_ADDR5.cg_vals.sample();`endif
     INTR_REGS.MSIX_ADDR5.read(status,rdata);
      `ifdef COV INTR_REGS.MSIX_ADDR5.cg_vals.sample();`endif
     wdata=(wdata&default_value)|rw_bits ;
     `uvm_info(get_name(), $psprintf("Register = %0s, data = %0h rw_bits_data = %h","MSIX_ADDR5",wdata , rw_bits), UVM_LOW)
     if(rdata !== wdata )
      `uvm_error(get_name(), $psprintf("Data mismatch 64! Register = %0s, Exp = %0h, Act = %0h", "MSIX_ADDR5",wdata, rdata))
     else
      `uvm_info(get_name(), $psprintf("Data match 64! Register = %0s, wdata = %0h rdata = %0h","MSIX_ADDR5",wdata, rdata), UVM_LOW)


     //==================================================
     // Write and Read 'hAAAAAAAA_AAAAAAAA to MSIX_ADDR5
     //==================================================
     wdata='hAAAAAAAA_AAAAAAAA ;
     default_value=64'h0000000000000000 ;
     rw_bits = 'hFFFFFFFFFFFFFFFF ;
     INTR_REGS.MSIX_ADDR5.write(status,wdata);
      `ifdef COV INTR_REGS.MSIX_ADDR5.cg_vals.sample();`endif
     INTR_REGS.MSIX_ADDR5.read(status,rdata);
      `ifdef COV INTR_REGS.MSIX_ADDR5.cg_vals.sample();`endif
     wdata=(wdata&rw_bits)|default_value;
     `uvm_info(get_name(), $psprintf("Register = %0s, data = %0h rw_bits_data = %h","MSIX_ADDR5",wdata , rw_bits), UVM_LOW)
     if(rdata !== wdata )
      `uvm_error(get_name(), $psprintf("Data mismatch 64! Register = %0s, Exp = %0h, Act = %0h", "MSIX_ADDR5",wdata, rdata))
     else
      `uvm_info(get_name(), $psprintf("Data match 64! Register = %0s, wdata = %0h rdata = %0h","MSIX_ADDR5",wdata, rdata), UVM_LOW)


     //==================================================
     // Write and Read 'h00000000_00000000 to MSIX_ADDR5
     //==================================================
     wdata='h00000000_00000000 ;
     default_value=64'h0000000000000000 ;
     rw_bits = 'hFFFFFFFFFFFFFFFF ;
     INTR_REGS.MSIX_ADDR5.write(status,wdata);
      `ifdef COV INTR_REGS.MSIX_ADDR5.cg_vals.sample();`endif
     INTR_REGS.MSIX_ADDR5.read(status,rdata);
      `ifdef COV INTR_REGS.MSIX_ADDR5.cg_vals.sample();`endif
     wdata=(wdata|default_value)&(~rw_bits) ;
     `uvm_info(get_name(), $psprintf("Register = %0s, data = %0h rw_bits_data = %h","MSIX_ADDR5",wdata , rw_bits), UVM_LOW)
     if(rdata !== wdata )
      `uvm_error(get_name(), $psprintf("Data mismatch 64! Register = %0s, Exp = %0h, Act = %0h", "MSIX_ADDR5",wdata, rdata))
     else
      `uvm_info(get_name(), $psprintf("Data match 64! Register = %0s, wdata = %0h rdata = %0h","MSIX_ADDR5",wdata, rdata), UVM_LOW)


     //==================================================
     // Write and Read 'hFFFFFFFF_FFFFFFFF to MSIX_CTLDAT5
     //==================================================
     wdata='hFFFFFFFF_FFFFFFFF ;
     default_value=64'h0000000100000000 ;
     rw_bits = 'hFFFFFFFFFFFFFFFF ;
     INTR_REGS.MSIX_CTLDAT5.write(status,wdata);
      `ifdef COV INTR_REGS.MSIX_CTLDAT5.cg_vals.sample();`endif
     INTR_REGS.MSIX_CTLDAT5.read(status,rdata);
      `ifdef COV INTR_REGS.MSIX_CTLDAT5.cg_vals.sample();`endif
     wdata=(wdata&default_value)|rw_bits ;
     `uvm_info(get_name(), $psprintf("Register = %0s, data = %0h rw_bits_data = %h","MSIX_CTLDAT5",wdata , rw_bits), UVM_LOW)
     if(rdata !== wdata )
      `uvm_error(get_name(), $psprintf("Data mismatch 64! Register = %0s, Exp = %0h, Act = %0h", "MSIX_CTLDAT5",wdata, rdata))
     else
      `uvm_info(get_name(), $psprintf("Data match 64! Register = %0s, wdata = %0h rdata = %0h","MSIX_CTLDAT5",wdata, rdata), UVM_LOW)


     //==================================================
     // Write and Read 'hAAAAAAAA_AAAAAAAA to MSIX_CTLDAT5
     //==================================================
     wdata='hAAAAAAAB_AAAAAAAA ;
     default_value=64'h0000000100000000 ;
     rw_bits = 'hFFFFFFFFFFFFFFFF ;
     INTR_REGS.MSIX_CTLDAT5.write(status,wdata);
      `ifdef COV INTR_REGS.MSIX_CTLDAT5.cg_vals.sample();`endif
     INTR_REGS.MSIX_CTLDAT5.read(status,rdata);
      `ifdef COV INTR_REGS.MSIX_CTLDAT5.cg_vals.sample();`endif
     wdata=(wdata&rw_bits)|default_value;
     `uvm_info(get_name(), $psprintf("Register = %0s, data = %0h rw_bits_data = %h","MSIX_CTLDAT5",wdata , rw_bits), UVM_LOW)
     if(rdata !== wdata )
      `uvm_error(get_name(), $psprintf("Data mismatch 64! Register = %0s, Exp = %0h, Act = %0h", "MSIX_CTLDAT5",wdata, rdata))
     else
      `uvm_info(get_name(), $psprintf("Data match 64! Register = %0s, wdata = %0h rdata = %0h","MSIX_CTLDAT5",wdata, rdata), UVM_LOW)


     //==================================================
     // Write and Read 'h00000000_00000000 to MSIX_CTLDAT5
     //==================================================
     wdata='h00000000_00000000 ;
     default_value=64'h0000000100000000 ;
     rw_bits = 'hFFFFFFFFFFFFFFFF ;
     INTR_REGS.MSIX_CTLDAT5.write(status,wdata);
      `ifdef COV INTR_REGS.MSIX_CTLDAT5.cg_vals.sample();`endif
     INTR_REGS.MSIX_CTLDAT5.read(status,rdata);
      `ifdef COV INTR_REGS.MSIX_CTLDAT5.cg_vals.sample();`endif
     wdata=(wdata|default_value)&(~rw_bits) ;
     `uvm_info(get_name(), $psprintf("Register = %0s, data = %0h rw_bits_data = %h","MSIX_CTLDAT5",wdata , rw_bits), UVM_LOW)
     if(rdata !== wdata )
      `uvm_error(get_name(), $psprintf("Data mismatch 64! Register = %0s, Exp = %0h, Act = %0h", "MSIX_CTLDAT5",wdata, rdata))
     else
      `uvm_info(get_name(), $psprintf("Data match 64! Register = %0s, wdata = %0h rdata = %0h","MSIX_CTLDAT5",wdata, rdata), UVM_LOW)


     //==================================================
     // Write and Read 'hFFFFFFFF_FFFFFFFF to MSIX_ADDR6
     //==================================================
     wdata='hFFFFFFFF_FFFFFFFF ;
     default_value=64'h0000000000000000 ;
     rw_bits = 'hFFFFFFFFFFFFFFFF ;
     INTR_REGS.MSIX_ADDR6.write(status,wdata);
      `ifdef COV INTR_REGS.MSIX_ADDR6.cg_vals.sample();`endif
     INTR_REGS.MSIX_ADDR6.read(status,rdata);
      `ifdef COV INTR_REGS.MSIX_ADDR6.cg_vals.sample();`endif
     wdata=(wdata&default_value)|rw_bits ;
     `uvm_info(get_name(), $psprintf("Register = %0s, data = %0h rw_bits_data = %h","MSIX_ADDR6",wdata , rw_bits), UVM_LOW)
     if(rdata !== wdata )
      `uvm_error(get_name(), $psprintf("Data mismatch 64! Register = %0s, Exp = %0h, Act = %0h", "MSIX_ADDR6",wdata, rdata))
     else
      `uvm_info(get_name(), $psprintf("Data match 64! Register = %0s, wdata = %0h rdata = %0h","MSIX_ADDR6",wdata, rdata), UVM_LOW)


     //==================================================
     // Write and Read 'hAAAAAAAA_AAAAAAAA to MSIX_ADDR6
     //==================================================
     wdata='hAAAAAAAA_AAAAAAAA ;
     default_value=64'h0000000000000000 ;
     rw_bits = 'hFFFFFFFFFFFFFFFF ;
     INTR_REGS.MSIX_ADDR6.write(status,wdata);
      `ifdef COV INTR_REGS.MSIX_ADDR6.cg_vals.sample();`endif
     INTR_REGS.MSIX_ADDR6.read(status,rdata);
      `ifdef COV INTR_REGS.MSIX_ADDR6.cg_vals.sample();`endif
     wdata=(wdata&rw_bits)|default_value;
     `uvm_info(get_name(), $psprintf("Register = %0s, data = %0h rw_bits_data = %h","MSIX_ADDR6",wdata , rw_bits), UVM_LOW)
     if(rdata !== wdata )
      `uvm_error(get_name(), $psprintf("Data mismatch 64! Register = %0s, Exp = %0h, Act = %0h", "MSIX_ADDR6",wdata, rdata))
     else
      `uvm_info(get_name(), $psprintf("Data match 64! Register = %0s, wdata = %0h rdata = %0h","MSIX_ADDR6",wdata, rdata), UVM_LOW)


     //==================================================
     // Write and Read 'h00000000_00000000 to MSIX_ADDR6
     //==================================================
     wdata='h00000000_00000000 ;
     default_value=64'h0000000000000000 ;
     rw_bits = 'hFFFFFFFFFFFFFFFF ;
     INTR_REGS.MSIX_ADDR6.write(status,wdata);
      `ifdef COV INTR_REGS.MSIX_ADDR6.cg_vals.sample();`endif
     INTR_REGS.MSIX_ADDR6.read(status,rdata);
      `ifdef COV INTR_REGS.MSIX_ADDR6.cg_vals.sample();`endif
     wdata=(wdata|default_value)&(~rw_bits) ;
     `uvm_info(get_name(), $psprintf("Register = %0s, data = %0h rw_bits_data = %h","MSIX_ADDR6",wdata , rw_bits), UVM_LOW)
     if(rdata !== wdata )
      `uvm_error(get_name(), $psprintf("Data mismatch 64! Register = %0s, Exp = %0h, Act = %0h", "MSIX_ADDR6",wdata, rdata))
     else
      `uvm_info(get_name(), $psprintf("Data match 64! Register = %0s, wdata = %0h rdata = %0h","MSIX_ADDR6",wdata, rdata), UVM_LOW)


     //==================================================
     // Write and Read 'hFFFFFFFF_FFFFFFFF to MSIX_CTLDAT6
     //==================================================
     wdata='hFFFFFFFF_FFFFFFFF ;
     default_value=64'h0000000100000000 ;
     rw_bits = 'hFFFFFFFFFFFFFFFF ;
     INTR_REGS.MSIX_CTLDAT6.write(status,wdata);
      `ifdef COV INTR_REGS.MSIX_CTLDAT6.cg_vals.sample();`endif
     INTR_REGS.MSIX_CTLDAT6.read(status,rdata);
      `ifdef COV INTR_REGS.MSIX_CTLDAT6.cg_vals.sample();`endif
     wdata=(wdata&default_value)|rw_bits ;
     `uvm_info(get_name(), $psprintf("Register = %0s, data = %0h rw_bits_data = %h","MSIX_CTLDAT6",wdata , rw_bits), UVM_LOW)
     if(rdata !== wdata )
      `uvm_error(get_name(), $psprintf("Data mismatch 64! Register = %0s, Exp = %0h, Act = %0h", "MSIX_CTLDAT6",wdata, rdata))
     else
      `uvm_info(get_name(), $psprintf("Data match 64! Register = %0s, wdata = %0h rdata = %0h","MSIX_CTLDAT6",wdata, rdata), UVM_LOW)


     //==================================================
     // Write and Read 'hAAAAAAAA_AAAAAAAA to MSIX_CTLDAT6
     //==================================================
     wdata='hAAAAAAAB_AAAAAAAA ;
     default_value=64'h0000000100000000 ;
     rw_bits = 'hFFFFFFFFFFFFFFFF ;
     INTR_REGS.MSIX_CTLDAT6.write(status,wdata);
      `ifdef COV INTR_REGS.MSIX_CTLDAT6.cg_vals.sample();`endif
     INTR_REGS.MSIX_CTLDAT6.read(status,rdata);
      `ifdef COV INTR_REGS.MSIX_CTLDAT6.cg_vals.sample();`endif
     wdata=(wdata&rw_bits)|default_value;
     `uvm_info(get_name(), $psprintf("Register = %0s, data = %0h rw_bits_data = %h","MSIX_CTLDAT6",wdata , rw_bits), UVM_LOW)
     if(rdata !== wdata )
      `uvm_error(get_name(), $psprintf("Data mismatch 64! Register = %0s, Exp = %0h, Act = %0h", "MSIX_CTLDAT6",wdata, rdata))
     else
      `uvm_info(get_name(), $psprintf("Data match 64! Register = %0s, wdata = %0h rdata = %0h","MSIX_CTLDAT6",wdata, rdata), UVM_LOW)


     //==================================================
     // Write and Read 'h00000000_00000000 to MSIX_CTLDAT6
     //==================================================
     wdata='h00000000_00000000 ;
     default_value=64'h0000000100000000 ;
     rw_bits = 'hFFFFFFFFFFFFFFFF ;
     INTR_REGS.MSIX_CTLDAT6.write(status,wdata);
      `ifdef COV INTR_REGS.MSIX_CTLDAT6.cg_vals.sample();`endif
     INTR_REGS.MSIX_CTLDAT6.read(status,rdata);
      `ifdef COV INTR_REGS.MSIX_CTLDAT6.cg_vals.sample();`endif
     wdata=(wdata|default_value)&(~rw_bits) ;
     `uvm_info(get_name(), $psprintf("Register = %0s, data = %0h rw_bits_data = %h","MSIX_CTLDAT6",wdata , rw_bits), UVM_LOW)
     if(rdata !== wdata )
      `uvm_error(get_name(), $psprintf("Data mismatch 64! Register = %0s, Exp = %0h, Act = %0h", "MSIX_CTLDAT6",wdata, rdata))
     else
      `uvm_info(get_name(), $psprintf("Data match 64! Register = %0s, wdata = %0h rdata = %0h","MSIX_CTLDAT6",wdata, rdata), UVM_LOW)


     /*//==================================================
     // Write and Read 'hFFFFFFFF_FFFFFFFF to MSIX_ADDR7
     //==================================================
     wdata='hFFFFFFFF_FFFFFFFF ;
     default_value=64'h0000000000000000 ;
     rw_bits = 'hFFFFFFFFFFFFFFFF ;
     INTR_REGS.MSIX_ADDR7.write(status,wdata);
      `ifdef COV INTR_REGS.MSIX_ADDR7.cg_vals.sample();`endif
     INTR_REGS.MSIX_ADDR7.read(status,rdata);
      `ifdef COV INTR_REGS.MSIX_ADDR7.cg_vals.sample();`endif
     wdata=(wdata&default_value)|rw_bits ;
     `uvm_info(get_name(), $psprintf("Register = %0s, data = %0h rw_bits_data = %h","MSIX_ADDR7",wdata , rw_bits), UVM_LOW)
     if(rdata !== wdata )
      `uvm_error(get_name(), $psprintf("Data mismatch 64! Register = %0s, Exp = %0h, Act = %0h", "MSIX_ADDR7",wdata, rdata))
     else
      `uvm_info(get_name(), $psprintf("Data match 64! Register = %0s, wdata = %0h rdata = %0h","MSIX_ADDR7",wdata, rdata), UVM_LOW)


     //==================================================
     // Write and Read 'hAAAAAAAA_AAAAAAAA to MSIX_ADDR7
     //==================================================
     wdata='hAAAAAAAA_AAAAAAAA ;
     default_value=64'h0000000000000000 ;
     rw_bits = 'hFFFFFFFFFFFFFFFF ;
     INTR_REGS.MSIX_ADDR7.write(status,wdata);
      `ifdef COV INTR_REGS.MSIX_ADDR7.cg_vals.sample();`endif
     INTR_REGS.MSIX_ADDR7.read(status,rdata);
      `ifdef COV INTR_REGS.MSIX_ADDR7.cg_vals.sample();`endif
     wdata=(wdata&rw_bits)|default_value;
     `uvm_info(get_name(), $psprintf("Register = %0s, data = %0h rw_bits_data = %h","MSIX_ADDR7",wdata , rw_bits), UVM_LOW)
     if(rdata !== wdata )
      `uvm_error(get_name(), $psprintf("Data mismatch 64! Register = %0s, Exp = %0h, Act = %0h", "MSIX_ADDR7",wdata, rdata))
     else
      `uvm_info(get_name(), $psprintf("Data match 64! Register = %0s, wdata = %0h rdata = %0h","MSIX_ADDR7",wdata, rdata), UVM_LOW)


     //==================================================
     // Write and Read 'h00000000_00000000 to MSIX_ADDR7
     //==================================================
     wdata='h00000000_00000000 ;
     default_value=64'h0000000000000000 ;
     rw_bits = 'hFFFFFFFFFFFFFFFF ;
     INTR_REGS.MSIX_ADDR7.write(status,wdata);
      `ifdef COV INTR_REGS.MSIX_ADDR7.cg_vals.sample();`endif
     INTR_REGS.MSIX_ADDR7.read(status,rdata);
      `ifdef COV INTR_REGS.MSIX_ADDR7.cg_vals.sample();`endif
     wdata=(wdata|default_value)&(~rw_bits) ;
     `uvm_info(get_name(), $psprintf("Register = %0s, data = %0h rw_bits_data = %h","MSIX_ADDR7",wdata , rw_bits), UVM_LOW)
     if(rdata !== wdata )
      `uvm_error(get_name(), $psprintf("Data mismatch 64! Register = %0s, Exp = %0h, Act = %0h", "MSIX_ADDR7",wdata, rdata))
     else
      `uvm_info(get_name(), $psprintf("Data match 64! Register = %0s, wdata = %0h rdata = %0h","MSIX_ADDR7",wdata, rdata), UVM_LOW)


     //==================================================
     // Write and Read 'hFFFFFFFF_FFFFFFFF to MSIX_CTLDAT7
     //==================================================
     wdata='hFFFFFFFF_FFFFFFFF ;
     default_value=64'h0000000100000000 ;
     rw_bits = 'hFFFFFFFFFFFFFFFF ;
     INTR_REGS.MSIX_CTLDAT7.write(status,wdata);
      `ifdef COV INTR_REGS.MSIX_CTLDAT7.cg_vals.sample();`endif
     INTR_REGS.MSIX_CTLDAT7.read(status,rdata);
      `ifdef COV INTR_REGS.MSIX_CTLDAT7.cg_vals.sample();`endif
     wdata=(wdata&default_value)|rw_bits ;
     `uvm_info(get_name(), $psprintf("Register = %0s, data = %0h rw_bits_data = %h","MSIX_CTLDAT7",wdata , rw_bits), UVM_LOW)
     if(rdata !== wdata )
      `uvm_error(get_name(), $psprintf("Data mismatch 64! Register = %0s, Exp = %0h, Act = %0h", "MSIX_CTLDAT7",wdata, rdata))
     else
      `uvm_info(get_name(), $psprintf("Data match 64! Register = %0s, wdata = %0h rdata = %0h","MSIX_CTLDAT7",wdata, rdata), UVM_LOW)


     //==================================================
     // Write and Read 'hAAAAAAAA_AAAAAAAA to MSIX_CTLDAT7
     //==================================================
     wdata='hAAAAAAAB_AAAAAAAA ;
     default_value=64'h0000000100000000 ;
     rw_bits = 'hFFFFFFFFFFFFFFFF ;
     INTR_REGS.MSIX_CTLDAT7.write(status,wdata);
      `ifdef COV INTR_REGS.MSIX_CTLDAT7.cg_vals.sample();`endif
     INTR_REGS.MSIX_CTLDAT7.read(status,rdata);
      `ifdef COV INTR_REGS.MSIX_CTLDAT7.cg_vals.sample();`endif
     wdata=(wdata&rw_bits)|default_value;
     `uvm_info(get_name(), $psprintf("Register = %0s, data = %0h rw_bits_data = %h","MSIX_CTLDAT7",wdata , rw_bits), UVM_LOW)
     if(rdata !== wdata )
      `uvm_error(get_name(), $psprintf("Data mismatch 64! Register = %0s, Exp = %0h, Act = %0h", "MSIX_CTLDAT7",wdata, rdata))
     else
      `uvm_info(get_name(), $psprintf("Data match 64! Register = %0s, wdata = %0h rdata = %0h","MSIX_CTLDAT7",wdata, rdata), UVM_LOW)


     //==================================================
     // Write and Read 'h00000000_00000000 to MSIX_CTLDAT7
     //==================================================
     wdata='h00000000_00000000 ;
     default_value=64'h0000000100000000 ;
     rw_bits = 'hFFFFFFFFFFFFFFFF ;
     INTR_REGS.MSIX_CTLDAT7.write(status,wdata);
      `ifdef COV INTR_REGS.MSIX_CTLDAT7.cg_vals.sample();`endif
     INTR_REGS.MSIX_CTLDAT7.read(status,rdata);
      `ifdef COV INTR_REGS.MSIX_CTLDAT7.cg_vals.sample();`endif
     wdata=(wdata|default_value)&(~rw_bits) ;
     `uvm_info(get_name(), $psprintf("Register = %0s, data = %0h rw_bits_data = %h","MSIX_CTLDAT7",wdata , rw_bits), UVM_LOW)
     if(rdata !== wdata )
      `uvm_error(get_name(), $psprintf("Data mismatch 64! Register = %0s, Exp = %0h, Act = %0h", "MSIX_CTLDAT7",wdata, rdata))
     else
      `uvm_info(get_name(), $psprintf("Data match 64! Register = %0s, wdata = %0h rdata = %0h","MSIX_CTLDAT7",wdata, rdata), UVM_LOW)
*/

     //==================================================
     // Write and Read 'hFFFFFFFF_FFFFFFFF to MSIX_PBA
     //==================================================
     wdata='hFFFFFFFF_FFFFFFFF ;
     default_value=64'h0000000000000000 ;
     rw_bits = 'h0000000000000000 ;
     INTR_REGS.MSIX_PBA.write(status,wdata);
      `ifdef COV INTR_REGS.MSIX_PBA.cg_vals.sample();`endif
     INTR_REGS.MSIX_PBA.read(status,rdata);
      `ifdef COV INTR_REGS.MSIX_PBA.cg_vals.sample();`endif
     wdata=(wdata&default_value)|rw_bits ;
     `uvm_info(get_name(), $psprintf("Register = %0s, data = %0h rw_bits_data = %h","MSIX_PBA",wdata , rw_bits), UVM_LOW)
     if(rdata !== wdata )
      `uvm_error(get_name(), $psprintf("Data mismatch 64! Register = %0s, Exp = %0h, Act = %0h", "MSIX_PBA",wdata, rdata))
     else
      `uvm_info(get_name(), $psprintf("Data match 64! Register = %0s, wdata = %0h rdata = %0h","MSIX_PBA",wdata, rdata), UVM_LOW)


     //==================================================
     // Write and Read 'hAAAAAAAA_AAAAAAAA to MSIX_PBA
     //==================================================
     wdata='hAAAAAAAA_AAAAAAAA ;
     default_value=64'h0000000000000000 ;
     rw_bits = 'h0000000000000000 ;
     INTR_REGS.MSIX_PBA.write(status,wdata);
      `ifdef COV INTR_REGS.MSIX_PBA.cg_vals.sample();`endif
     INTR_REGS.MSIX_PBA.read(status,rdata);
      `ifdef COV INTR_REGS.MSIX_PBA.cg_vals.sample();`endif
     wdata=(wdata&rw_bits)|default_value;
     `uvm_info(get_name(), $psprintf("Register = %0s, data = %0h rw_bits_data = %h","MSIX_PBA",wdata , rw_bits), UVM_LOW)
     if(rdata !== wdata )
      `uvm_error(get_name(), $psprintf("Data mismatch 64! Register = %0s, Exp = %0h, Act = %0h", "MSIX_PBA",wdata, rdata))
     else
      `uvm_info(get_name(), $psprintf("Data match 64! Register = %0s, wdata = %0h rdata = %0h","MSIX_PBA",wdata, rdata), UVM_LOW)


     //==================================================
     // Write and Read 'h00000000_00000000 to MSIX_PBA
     //==================================================
     wdata='h00000000_00000000 ;
     default_value=64'h0000000000000000 ;
     rw_bits = 'h0000000000000000 ;
     INTR_REGS.MSIX_PBA.write(status,wdata);
      `ifdef COV INTR_REGS.MSIX_PBA.cg_vals.sample();`endif
     INTR_REGS.MSIX_PBA.read(status,rdata);
      `ifdef COV INTR_REGS.MSIX_PBA.cg_vals.sample();`endif
     wdata=(wdata|default_value)&(~rw_bits) ;
     `uvm_info(get_name(), $psprintf("Register = %0s, data = %0h rw_bits_data = %h","MSIX_PBA",wdata , rw_bits), UVM_LOW)
     if(rdata !== wdata )
      `uvm_error(get_name(), $psprintf("Data mismatch 64! Register = %0s, Exp = %0h, Act = %0h", "MSIX_PBA",wdata, rdata))
     else
      `uvm_info(get_name(), $psprintf("Data match 64! Register = %0s, wdata = %0h rdata = %0h","MSIX_PBA",wdata, rdata), UVM_LOW)


 /*    //==================================================
     // Write and Read 'hFFFFFFFF_FFFFFFFF to MSIX_COUNT_CSR
     //==================================================
     wdata='hFFFFFFFF_FFFFFFFF ;
     default_value=64'h0000000000000000 ;
     rw_bits = 'h00000000FFFFFFFF ;
     INTR_REGS.MSIX_COUNT_CSR.write(status,wdata);
      `ifdef COV INTR_REGS.MSIX_COUNT_CSR.cg_vals.sample();`endif
     INTR_REGS.MSIX_COUNT_CSR.read(status,rdata);
      `ifdef COV INTR_REGS.MSIX_COUNT_CSR.cg_vals.sample();`endif
     wdata=(wdata&default_value)|rw_bits ;
     `uvm_info(get_name(), $psprintf("Register = %0s, data = %0h rw_bits_data = %h","MSIX_COUNT_CSR",wdata , rw_bits), UVM_LOW)
     if(rdata !== wdata )
      `uvm_error(get_name(), $psprintf("Data mismatch 64! Register = %0s, Exp = %0h, Act = %0h", "MSIX_COUNT_CSR",wdata, rdata))
     else
      `uvm_info(get_name(), $psprintf("Data match 64! Register = %0s, wdata = %0h rdata = %0h","MSIX_COUNT_CSR",wdata, rdata), UVM_LOW)


     //==================================================
     // Write and Read 'hAAAAAAAA_AAAAAAAA to MSIX_COUNT_CSR
     //==================================================
     wdata='hAAAAAAAA_AAAAAAAA ;
     default_value=64'h0000000000000000 ;
     rw_bits = 'h00000000FFFFFFFF ;
     INTR_REGS.MSIX_COUNT_CSR.write(status,wdata);
      `ifdef COV INTR_REGS.MSIX_COUNT_CSR.cg_vals.sample();`endif
     INTR_REGS.MSIX_COUNT_CSR.read(status,rdata);
      `ifdef COV INTR_REGS.MSIX_COUNT_CSR.cg_vals.sample();`endif
     wdata=(wdata&rw_bits)|default_value;
     `uvm_info(get_name(), $psprintf("Register = %0s, data = %0h rw_bits_data = %h","MSIX_COUNT_CSR",wdata , rw_bits), UVM_LOW)
     if(rdata !== wdata )
      `uvm_error(get_name(), $psprintf("Data mismatch 64! Register = %0s, Exp = %0h, Act = %0h", "MSIX_COUNT_CSR",wdata, rdata))
     else
      `uvm_info(get_name(), $psprintf("Data match 64! Register = %0s, wdata = %0h rdata = %0h","MSIX_COUNT_CSR",wdata, rdata), UVM_LOW)


     //==================================================
     // Write and Read 'h00000000_00000000 to MSIX_COUNT_CSR
     //==================================================
     wdata='h00000000_00000000 ;
     default_value=64'h0000000000000000 ;
     rw_bits = 'h00000000FFFFFFFF ;
     INTR_REGS.MSIX_COUNT_CSR.write(status,wdata);
      `ifdef COV INTR_REGS.MSIX_COUNT_CSR.cg_vals.sample();`endif
     INTR_REGS.MSIX_COUNT_CSR.read(status,rdata);
      `ifdef COV INTR_REGS.MSIX_COUNT_CSR.cg_vals.sample();`endif
     wdata=(wdata|default_value)&(~rw_bits) ;
     `uvm_info(get_name(), $psprintf("Register = %0s, data = %0h rw_bits_data = %h","MSIX_COUNT_CSR",wdata , rw_bits), UVM_LOW)
     if(rdata !== wdata )
      `uvm_error(get_name(), $psprintf("Data mismatch 64! Register = %0s, Exp = %0h, Act = %0h", "MSIX_COUNT_CSR",wdata, rdata))
     else
      `uvm_info(get_name(), $psprintf("Data match 64! Register = %0s, wdata = %0h rdata = %0h","MSIX_COUNT_CSR",wdata, rdata), UVM_LOW) */


      #5us; // Buffer time
      `uvm_do_on(wait_until_driver_idle_seq,p_sequencer.root_virt_seqr.driver_seqr[0])
     `uvm_info(get_name(), "Exiting msix_csr_seq...", UVM_LOW)

    endtask : body

endclass : msix_csr_seq

`endif // MSIX_CSR_SEQ_SVH


