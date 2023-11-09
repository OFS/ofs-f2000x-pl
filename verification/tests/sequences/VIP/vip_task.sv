// Copyright (C) 2023 Intel Corporation
// SPDX-License-Identifier: MIT

 task mmio_pcie_read32(input bit [63:0] addr_, output bit [31:0] data_, input bit is_soc_ = 1);
     pcie_rd_mmio_seq mmio_rd;
     if(is_soc_) begin
        `uvm_do_on_with(mmio_rd, p_sequencer.root_virt_seqr.driver_transaction_seqr[0], {
            rd_addr == addr_;
            rlen    == 1;
            l_dw_be == 4'b0000;
            block   == 0;
        })
     end
     else begin
        `uvm_do_on_with(mmio_rd, p_sequencer.root1_virt_seqr.driver_transaction_seqr[0], {
            rd_addr == addr_;
            rlen    == 1;
            l_dw_be == 4'b0000;
            block   == 0;
        })
     end
     data_ = changeEndian(mmio_rd.read_tran.payload[0]);
 endtask : mmio_pcie_read32

task mmio_pcie_read64(input  bit [63:0] addr_, output bit [63:0] data_, input bit is_soc_ = 1);
    pcie_rd_mmio_seq mmio_rd;
    if(is_soc_) begin
      `uvm_do_on_with(mmio_rd, p_sequencer.root_virt_seqr.driver_transaction_seqr[0], {
          rd_addr == addr_;
          rlen    == 2;
          l_dw_be == 4'b1111;
          block   == 0;
      })
    end
    else begin
      `uvm_do_on_with(mmio_rd, p_sequencer.root1_virt_seqr.driver_transaction_seqr[0], {
          rd_addr == addr_;
          rlen    == 2;
          l_dw_be == 4'b1111;
          block   == 0;
      })
    end
    data_ = {changeEndian(mmio_rd.read_tran.payload[1]), changeEndian(mmio_rd.read_tran.payload[0])};
endtask : mmio_pcie_read64


 task mmio_pcie_write32(input bit [63:0] addr_, input bit [31:0] data_, input bit is_soc_ = 1);
     pcie_wr_mmio_seq mmio_wr;
     if(is_soc_) begin
       `uvm_do_on_with(mmio_wr, p_sequencer.root_virt_seqr.driver_transaction_seqr[0], { 
           wr_addr       == addr_;
           wrlen         == 'h1;
           f_dw_be       == 4'b1111;
           l_dw_be       == 4'b0000;
           wr_payload[0] == changeEndian(data_);
       })
     end
     else begin
       `uvm_do_on_with(mmio_wr, p_sequencer.root1_virt_seqr.driver_transaction_seqr[0], { 
           wr_addr       == addr_;
           wrlen         == 'h1;
           f_dw_be       == 4'b1111;
           l_dw_be       == 4'b0000;
           wr_payload[0] == changeEndian(data_);

       })
     
     end
 endtask : mmio_pcie_write32 

 task mmio_pcie_write32_w_be(input bit [63:0] addr_, input bit [31:0] data_, input [3:0] be_, input bit is_soc_ = 1);
     pcie_wr_mmio_seq mmio_wr;
     if(is_soc_) begin
       `uvm_do_on_with(mmio_wr, p_sequencer.root_virt_seqr.driver_transaction_seqr[0], { 
           wr_addr       == addr_;
           wrlen         == 'h1;
           f_dw_be       == be_;
           l_dw_be       == 4'b0000;
           wr_payload[0] == changeEndian(data_);
       })
     end
     else begin
       `uvm_do_on_with(mmio_wr, p_sequencer.root1_virt_seqr.driver_transaction_seqr[0], { 
           wr_addr       == addr_;
           wrlen         == 'h1;
           f_dw_be       == be_;
           l_dw_be       == 4'b0000;
           wr_payload[0] == changeEndian(data_);

       })
     
     end
 endtask : mmio_pcie_write32_w_be 

 task mmio_pcie_write64(input bit [63:0] addr_, input bit [63:0] data_, input bit is_soc_ = 1);
     pcie_wr_mmio_seq mmio_wr;
     if(is_soc_) begin
       `uvm_do_on_with(mmio_wr, p_sequencer.root_virt_seqr.driver_transaction_seqr[0], { 
           wr_addr       == addr_;
           wrlen         == 'h2;
           f_dw_be       == 4'b1111;
           l_dw_be       == 4'b1111;
           wr_payload[0] == changeEndian(data_[31:0]);
           wr_payload[1] == changeEndian(data_[63:32]);
       })
     end
     else begin
       `uvm_do_on_with(mmio_wr, p_sequencer.root1_virt_seqr.driver_transaction_seqr[0], { 
           wr_addr       == addr_;
           wrlen         == 'h2;
           f_dw_be       == 4'b1111;
           l_dw_be       == 4'b1111;
           wr_payload[0] == changeEndian(data_[31:0]);
           wr_payload[1] == changeEndian(data_[63:32]);
       })
     
     end
 endtask : mmio_pcie_write64

task mmio_pcie_read32_blocking(input bit [63:0] addr_, output bit [31:0] data_, input bit is_soc_ = 1);
    pcie_rd_mmio_seq mmio_rd;
    bit timeout;
    fork
    begin
    if(is_soc_) begin
      `uvm_do_on_with(mmio_rd, p_sequencer.root_virt_seqr.driver_transaction_seqr[0], {
          rd_addr == addr_;
          rlen    == 1;
          l_dw_be == 4'b0000;
          block   == 1;
      })
    end
    else begin
      `uvm_do_on_with(mmio_rd, p_sequencer.root1_virt_seqr.driver_transaction_seqr[0], {
          rd_addr == addr_;
          rlen    == 1;
          l_dw_be == 4'b0000;
          block   == 1;
      })
    
    end
    data_ = changeEndian(mmio_rd.read_tran.payload[0]);
    end
    begin
      #50us;
      timeout=1;
    end
   join_any
   if(timeout)
        `uvm_fatal(get_name(),$psprintf("MMIO read timed out addr =%0h",addr_))
    
endtask : mmio_pcie_read32_blocking


task mmio_pcie_read64_blocking(input  bit [63:0] addr_, output bit [63:0] data_, input bit is_soc_ = 1);
    pcie_rd_mmio_seq mmio_rd;
    bit timeout=0;
    fork
    begin
    if(is_soc_) begin
       `uvm_do_on_with(mmio_rd, p_sequencer.root_virt_seqr.driver_transaction_seqr[0], {
           rd_addr == addr_;
           rlen    == 2;
           l_dw_be == 4'b1111;
           block   == 1;
       })
    end
    else begin
       `uvm_do_on_with(mmio_rd, p_sequencer.root1_virt_seqr.driver_transaction_seqr[0], {
           rd_addr == addr_;
           rlen    == 2;
           l_dw_be == 4'b1111;
           block   == 1;
       })
    end
    data_ = {changeEndian(mmio_rd.read_tran.payload[1]), changeEndian(mmio_rd.read_tran.payload[0])};
   end
   begin
      #50us;
      timeout=1;
   end
  join_any
  if(timeout)
        `uvm_fatal(get_name(),$psprintf("MMIO read timed out addr =%0h",addr_))
endtask:mmio_pcie_read64_blocking

 task host_pcie_mem_write (input  bit [63:0] addr_, input bit [31:0] data_ [], input int unsigned len ,input bit is_soc_ = 1);
     host_pcie_mem_write_seq pcie_mem_wr_seq;
     `uvm_do_on_with(pcie_mem_wr_seq, p_sequencer.root_virt_seqr.mem_target_seqr, {
	        address           == addr_;
	        dword_length      == len;
                data_seq.size()   == len;
                foreach(data_seq[i]) { data_seq[i] == data_[i]; }
	            })
 endtask

 task host_pcie_mem_read (input  bit [63:0] addr_, output bit [31:0] data_ [],input int unsigned len ,input bit is_soc_ = 1);
     host_pcie_mem_read_seq pcie_mem_rd_seq;
     `uvm_do_on_with(pcie_mem_rd_seq, p_sequencer.root_virt_seqr.mem_target_seqr, {
          address           == addr_;
	  dword_length      == len;
      })
     data_ = new[len] (pcie_mem_rd_seq.data_buf);
     
 endtask
 task pcie_vdm_msg(input bit[9:0] length_);
     pcie_vdm_msg_seq vdm_wr;
     `uvm_do_on_with(vdm_wr, p_sequencer.root1_virt_seqr.driver_transaction_seqr[0], {
          vdm_len == length_;
          fix_payload_en == 1;
          vendor_fields[63:48] == 16'h0;
          vendor_fields[47:32] == 16'h1AB4;
          vendor_fields[31:0]  == 32'h01FF00C0;
          routing_type == 1;
          vdm_payload[0] == changeEndian('hdeadbeef);
          vdm_payload[1] == changeEndian('h55aa55aa);
          vdm_payload[2] == changeEndian('h11223344);
          vdm_payload[3] == changeEndian('hccddeeff);
          vdm_payload[4] == changeEndian('hdeadbeef);
          vdm_payload[5] == changeEndian('h55aa55aa);
          vdm_payload[6] == changeEndian('h11223344);
          vdm_payload[7] == changeEndian('hccddeeff);
          vdm_payload[8] == changeEndian('hdeadbeef);
          vdm_payload[9] == changeEndian('h55aa55aa);
          vdm_payload[10] == changeEndian('h11223344);
          vdm_payload[11] == changeEndian('hccddeeff);
          vdm_payload[12] == changeEndian('h11223344);
          vdm_payload[13] == changeEndian('hccddeeff);
          vdm_payload[14] == changeEndian('h11223344);
          vdm_payload[15] == changeEndian('hccddeeff);
      })
 endtask : pcie_vdm_msg 


 task pcie_vdm_random_msg(input bit[9:0] length_,input bit routing_type_,input bit [7:0] dest_id );
     pcie_vdm_msg_seq vdm_wr;
     if(routing_type_)begin
     `uvm_do_on_with(vdm_wr, p_sequencer.root1_virt_seqr.driver_transaction_seqr[0], {
          vdm_len == length_;
          fix_payload_en == 0;
          vendor_fields[63:48] == 16'h0;
          vendor_fields[47:32] == 16'h1AB4;
          vendor_fields[31:0]  == {8'h01,dest_id,16'h00C0};
          routing_type == 1;
      })
     end
     else begin 
     `uvm_do_on_with(vdm_wr, p_sequencer.root1_virt_seqr.driver_transaction_seqr[0], {
          vdm_len == length_;
          fix_payload_en == 0;
          vendor_fields[47:32] == 16'h1AB4;
          vendor_fields[31:0]  == {8'h01,dest_id,16'h00C0};
          routing_type == 0;
      })
     end
 endtask : pcie_vdm_random_msg


 task pcie_vdm_random_multi_msg(input bit[9:0] length_,input bit routing_type_,input bit [7:0] dest_id ,input bit [1:0] pos_pkt,input bit [1:0] num_ctr);
     pcie_vdm_msg_seq vdm_wr;
     if(routing_type_)begin
     `uvm_do_on_with(vdm_wr, p_sequencer.root1_virt_seqr.driver_transaction_seqr[0], {
          vdm_len == length_;
          fix_payload_en == 0;
          vendor_fields[63:48] == 16'h0;
          vendor_fields[47:32] == 16'h1AB4;
          if(pos_pkt==2'b00){ 
           vendor_fields[31:0]  == {8'h01,dest_id,8'h00,2'b00,num_ctr,4'b0};
          } 
          else if(pos_pkt==2'b10){
           vendor_fields[31:0]  == {8'h01,dest_id,8'h00,2'b10,num_ctr,4'b0};
          }
          else{ 
           vendor_fields[31:0]  == {8'h01,dest_id,8'h00,2'b01,num_ctr,4'b0};
          }
          routing_type == 1;
      })
      
     end
     else begin 
     `uvm_do_on_with(vdm_wr, p_sequencer.root1_virt_seqr.driver_transaction_seqr[0], {
          vdm_len == length_;
          fix_payload_en == 0;
          vendor_fields[47:32] == 16'h1AB4;
          if(pos_pkt==2'b00){ 
           vendor_fields[31:0]  == {8'h01,dest_id,8'h00,2'b00,num_ctr,4'h0};
          }
          else if(pos_pkt==2'b10){
           vendor_fields[31:0]  == {8'h01,dest_id,8'h00,2'b10,num_ctr,4'b0};
          }
          else{ 
           vendor_fields[31:0]  == {8'h01,dest_id,8'h00,2'b01,num_ctr,4'b0};
          }
          routing_type == 0;
      })
     end
 endtask : pcie_vdm_random_multi_msg 

 task pcie_vdm_err_msg(input bit[9:0] length_);
     pcie_vdm_msg_seq vdm_wr;
     `uvm_do_on_with(vdm_wr, p_sequencer.root1_virt_seqr.driver_transaction_seqr[0], {
          vdm_len == length_;
          fix_payload_en == 0;
          vendor_fields[63:48] == 16'h0;
          vendor_fields[47:32] == 16'h03A5; //Actual VID should be 1ab4
          vendor_fields[31:0]  == 32'h01FF00C0;
          routing_type == 1;
      })
 endtask :pcie_vdm_err_msg

 task pcie_pf_vf_bar(input bit is_soc_=1);
    enumerate_seq   enumerate_seq2;
     if(is_soc_) begin
       `uvm_do_on_with(enumerate_seq2, p_sequencer.root_virt_seqr.driver_transaction_seqr[0],{
         pf0_bar0     == tb_cfg0.PF0_BAR0;
         pf0_vf0_bar0 == tb_cfg0.PF0_VF0_BAR0;
         pf0_vf1_bar0 == tb_cfg0.PF0_VF1_BAR0;
         pf0_vf2_bar0 == tb_cfg0.PF0_VF2_BAR0;
         pf0_bar4     == tb_cfg0.PF0_BAR4;
         pf0_vf0_bar4 == tb_cfg0.PF0_VF0_BAR4;
         is_soc      == 1;

        })
     end
     else begin
       `uvm_do_on_with(enumerate_seq2, p_sequencer.root1_virt_seqr.driver_transaction_seqr[0],{
        pf0_bar0     == tb_cfg1.PF0_BAR0;
        pf1_bar0     == tb_cfg1.PF1_BAR0;
         is_soc      == 0;
        })
     
     end
    enumerate_seq2.print();
 endtask :pcie_pf_vf_bar

 task flr_pcie_cfg_rd(input bit[63:0] address_, output bit [31:0] dev_ctl_ ,input bit is_soc_=1);
        cfg_rd_flr_seq flr_rd;
     if(is_soc_) begin
        `uvm_do_on_with(flr_rd, p_sequencer.root_virt_seqr.driver_transaction_seqr[0], {
            rd_addr == address_;
        })
     end
     else begin
        `uvm_do_on_with(flr_rd, p_sequencer.root1_virt_seqr.driver_transaction_seqr[0], {
            rd_addr == address_;
        })
     end
     
        dev_ctl_ = flr_rd.rd_dev_ctl;
 endtask : flr_pcie_cfg_rd

 task flr_pcie_cfg_wr(input bit[63:0] address_, input bit [31:0] dev_ctl_, input bit is_soc_=1);
        cfg_wr_flr_seq flr_wr;
     if(is_soc_) begin
        `uvm_do_on_with(flr_wr, p_sequencer.root_virt_seqr.driver_transaction_seqr[0], {
            wr_addr == address_;
            wr_dev_ctl == dev_ctl_;
        })
     end
     else begin
        `uvm_do_on_with(flr_wr, p_sequencer.root1_virt_seqr.driver_transaction_seqr[0], {
            wr_addr == address_;
            wr_dev_ctl == dev_ctl_;
        })
     end
 
 endtask : flr_pcie_cfg_wr

