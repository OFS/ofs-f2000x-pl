// Copyright (C) 2020 Intel Corporation.
// SPDX-License-Identifier: MIT
//---------------------------------------------------------
// Test module for the simulation. 
//---------------------------------------------------------

import host_bfm_types_pkg::*;

module unit_test #(
   parameter SOC_ATTACH = 0,
   parameter type pf_type = default_pfs, 
   parameter pf_type pf_list = '{1'b1}, 
   parameter type vf_type = default_vfs, 
   parameter vf_type vf_list = '{0}
)(
   input logic clk,
   input logic rst_n,
   input logic csr_clk,
   input logic csr_rst_n
);

import pfvf_class_pkg::*;
import host_memory_class_pkg::*;
import tag_manager_class_pkg::*;
import pfvf_status_class_pkg::*;
import packet_class_pkg::*;
import host_axis_send_class_pkg::*;
import host_axis_receive_class_pkg::*;
import host_transaction_class_pkg::*;
import host_bfm_class_pkg::*;
import test_csr_defs::*;


//---------------------------------------------------------
// FLR handle and FLR Memory
//---------------------------------------------------------
//HostFLREvent flr;
//HostFLREvent flrs_received[$];
//HostFLREvent flrs_sent_history[$];


//---------------------------------------------------------
// Packet Handles and Storage
//---------------------------------------------------------
Packet            #(pf_type, vf_type, pf_list, vf_list) p;
PacketPUMemReq    #(pf_type, vf_type, pf_list, vf_list) pumr;
PacketPUAtomic    #(pf_type, vf_type, pf_list, vf_list) pua;
PacketPUCompletion#(pf_type, vf_type, pf_list, vf_list) puc;
PacketDMMemReq    #(pf_type, vf_type, pf_list, vf_list) dmmr;
PacketDMCompletion#(pf_type, vf_type, pf_list, vf_list) dmc;
PacketUnknown     #(pf_type, vf_type, pf_list, vf_list) pu;
PacketPUMsg       #(pf_type, vf_type, pf_list, vf_list) pmsg;
PacketPUVDM       #(pf_type, vf_type, pf_list, vf_list) pvdm;


Packet#(pf_type, vf_type, pf_list, vf_list) q[$];
Packet#(pf_type, vf_type, pf_list, vf_list) qr[$];


//---------------------------------------------------------
// Transaction Handles and Storage
//---------------------------------------------------------
Transaction       #(pf_type, vf_type, pf_list, vf_list) t;
ReadTransaction   #(pf_type, vf_type, pf_list, vf_list) rt;
WriteTransaction  #(pf_type, vf_type, pf_list, vf_list) wt;
AtomicTransaction #(pf_type, vf_type, pf_list, vf_list) at;
SendMsgTransaction#(pf_type, vf_type, pf_list, vf_list) mt;
SendVDMTransaction#(pf_type, vf_type, pf_list, vf_list) vt;

Transaction#(pf_type, vf_type, pf_list, vf_list) tx_transaction_queue[$];
Transaction#(pf_type, vf_type, pf_list, vf_list) tx_active_transaction_queue[$];
Transaction#(pf_type, vf_type, pf_list, vf_list) tx_completed_transaction_queue[$];
Transaction#(pf_type, vf_type, pf_list, vf_list) tx_errored_transaction_queue[$];
Transaction#(pf_type, vf_type, pf_list, vf_list) tx_history_transaction_queue[$];


//---------------------------------------------------------
// PFVF Structs 
//---------------------------------------------------------
pfvf_struct pfvf;

byte_t msg_buf[];
byte_t vdm_buf[];

//---------------------------------------------------------
//  BEGIN: Test Tasks and Utilities
//---------------------------------------------------------
parameter MAX_TEST = 100;
//parameter TIMEOUT = 1.5ms;
//parameter TIMEOUT = 10.0ms;
parameter TIMEOUT = 30.0ms;


typedef struct packed {
   logic result;
   logic [1024*8-1:0] name;
} t_test_info;
typedef enum bit {ADDR32, ADDR64} e_addr_mode;

int err_count = 0;
logic [31:0] test_id;
t_test_info [MAX_TEST-1:0] test_summary;
logic reset_test;
logic [7:0] checker_err_count;
logic test_done;
logic test_result;

//---------------------------------------------------------
//  Test Utilities
//---------------------------------------------------------
function void incr_err_count();
   err_count++;
endfunction


function int get_err_count();
   return err_count;
endfunction


//---------------------------------------------------------
//  Test Tasks
//---------------------------------------------------------
task incr_test_id;
begin
   test_id = test_id + 1;
end
endtask

task post_test_util;
   input logic [31:0] old_test_err_count;
   logic result;
begin
   if (get_err_count() > old_test_err_count) 
   begin
      result = 1'b0;
   end else begin
      result = 1'b1;
   end

   repeat (10) @(posedge clk);

   @(posedge clk);
      reset_test = 1'b1;
   repeat (5) @(posedge clk);
   reset_test = 1'b0;

   if (result) 
   begin
      $display("\nTest status: OK");
      test_summary[test_id].result = 1'b1;
   end 
   else 
   begin
      $display("\nTest status: FAILED");
      test_summary[test_id].result = 1'b0;
   end
   incr_test_id(); 
end
endtask

task print_test_header;
   input [1024*8-1:0] test_name;
begin
   $display("\n********************************************");
   $display(" Running TEST(%0d) : %0s", test_id, test_name);
   $display("********************************************");   
   test_summary[test_id].name = test_name;
end
endtask


// Deassert AFU reset
task deassert_afu_reset;
   int count;
   logic [63:0] scratch;
   logic [31:0] wdata;
   logic        error;
   logic [31:0] PORT_CONTROL;
begin
   count = 0;
   PORT_CONTROL = 32'h71000 + 32'h38;
   //De-assert Port Reset 
   $display("\nDe-asserting Port Reset...");
   pfvf = '{0,0,0}; // Set PFVF to PF0
   host_bfm_top.host_bfm.set_pfvf_setting(pfvf);
   host_bfm_top.host_bfm.read64(PORT_CONTROL, scratch);
   wdata = scratch[31:0];
   wdata[0] = 1'b0;
   host_bfm_top.host_bfm.write32(PORT_CONTROL, wdata);
   #5000000 host_bfm_top.host_bfm.read64(PORT_CONTROL, scratch);
   if (scratch[4] != 1'b0) begin
      $display("\nERROR: Port Reset Ack Asserted!");
      incr_err_count();
      $finish;       
   end
   $display("\nAFU is out of reset ...");
   host_bfm_top.host_bfm.revert_to_last_pfvf_setting();
end
endtask


//-------------------
// Test cases 
//-------------------
// Test 32-bit CSR access
task test_csr_access_32;
   output logic       result;
   input e_addr_mode  addr_mode;
   input logic [63:0] addr;
   input logic [31:0] data;
   logic [31:0] scratch;
   logic error;
   cpl_status_t cpl_status;
begin
   result = 1'b1;

   host_bfm_top.host_bfm.write32(addr, data);
   host_bfm_top.host_bfm.read32_with_completion_status(addr, scratch, error, cpl_status);

   if (error) begin
       $display("\nERROR: Completion is returned with unsuccessful status.\n");
       incr_err_count();
       result = 1'b0;
   end else if (scratch !== data) begin
       $display("\nERROR: CSR write and read mismatch! write=0x%x read=0x%x\n", data, scratch);
       incr_err_count();
       result = 1'b0;
   end
end
endtask

// Test 32-bit CSR access to unused CSR region
task test_unused_csr_access_32;
   output logic       result;
   input e_addr_mode  addr_mode;
   input logic [63:0] addr;
   input logic [31:0] data;
   logic [31:0] scratch;
   logic error;
   cpl_status_t cpl_status;
begin
   result = 1'b1;

   host_bfm_top.host_bfm.write32(addr, data);
   host_bfm_top.host_bfm.read32_with_completion_status(addr, scratch, error, cpl_status);

   if (error) begin
       $display("\nERROR: Completion is returned with unsuccessful status.\n");
       incr_err_count();
       result = 1'b0;
   end else if (scratch !== 32'h0) begin
       $display("\nERROR: Expected 32'h0 to be returned for unused CSR region, actual:0x%x\n",scratch);      
       incr_err_count();
       result = 1'b0;
   end
end
endtask

// Test 64-bit CSR access
task test_csr_access_64;
   output logic       result;
   input e_addr_mode  addr_mode;
   input logic [63:0] addr;
   input logic [63:0] data;
   logic [63:0] scratch;
   logic error;
   cpl_status_t cpl_status;
begin
   result = 1'b1;

   host_bfm_top.host_bfm.write64(addr, data);
   host_bfm_top.host_bfm.read64_with_completion_status(addr, scratch, error, cpl_status);

   if (error) begin
       $display("\nERROR: Completion is returned with unsuccessful status.\n");
       incr_err_count();
       result = 1'b0;
   end else if (scratch !== data) begin
       $display("\nERROR: CSR write and read mismatch! write=0x%x read=0x%x\n", data, scratch);
       incr_err_count();
       result = 1'b0;
   end
end
endtask

// Test 64-bit CSR read access
task test_csr_read_64;
   output logic       result;
   input e_addr_mode  addr_mode;
   input logic [63:0] addr;
   input logic [63:0] data;
   logic [63:0] scratch;
   logic error;
   cpl_status_t cpl_status;
begin
   result = 1'b1;
   host_bfm_top.host_bfm.read64_with_completion_status(addr, scratch, error, cpl_status);

   if (error) begin
       $display("\nERROR: Completion is returned with unsuccessful status.\n");
       incr_err_count();
       result = 1'b0;
   end else if (scratch !== data) begin
       $display("\nERROR: CSR read mismatch! expected=0x%x actual=0x%x\n", data, scratch);
       incr_err_count();
       result = 1'b0;
   end
end
endtask

// Test 32-bit CSR read access
task test_csr_read_32;
   output logic       result;
   input e_addr_mode  addr_mode;
   input logic [63:0] addr;
   input logic [31:0] data;
   logic [31:0] scratch;
   logic error;
   cpl_status_t cpl_status;
begin
   result = 1'b1;
   host_bfm_top.host_bfm.read32_with_completion_status(addr, scratch, error, cpl_status);

   if (error) begin
       $display("\nERROR: Completion is returned with unsuccessful status.\n");
       incr_err_count();
       result = 1'b0;
   end else if (scratch !== data) begin
       $display("\nERROR: CSR read mismatch! expected=0x%x actual=0x%x\n", data, scratch);
       incr_err_count();
       result = 1'b0;
   end
end
endtask

// Test 64-bit CSR access to unused CSR region
task test_unused_csr_access_64;
   output logic       result;
   input e_addr_mode  addr_mode;
   input logic [63:0] addr;
   input logic [63:0] data;
   logic [63:0] scratch;
   logic error;
   cpl_status_t cpl_status;
begin
   result = 1'b1;

   host_bfm_top.host_bfm.write64(addr, data);
   host_bfm_top.host_bfm.read64_with_completion_status(addr, scratch, error, cpl_status);

   if (error) begin
       $display("\nERROR: Completion is returned with unsuccessful status.\n");
       incr_err_count();
       result = 1'b0;
   end else if (scratch !== 64'h0) begin
       $display("\nERROR: Expected 64'h0 to be returned for unused CSR region, actual:0x%x\n",scratch);      
       incr_err_count();
       result = 1'b0;
   end
end
endtask

task test_csr_ro_access_64;
   output logic       result;
   input e_addr_mode  addr_mode;
   input logic [63:0] addr;
   input logic [63:0] data;
   logic [63:0] scratch;
   logic error;
   cpl_status_t cpl_status;
begin
   result = 1'b1;

   host_bfm_top.host_bfm.read64_with_completion_status(addr, scratch, error, cpl_status);

   if (error) begin
       $display("\nERROR: Completion is returned with unsuccessful status.\n");
       incr_err_count();
       result = 1'b0;
   end else if (scratch !== data) begin
       $display("\nERROR: CSR expected and read mismatch! expected=0x%x read=0x%x\n", data, scratch);
       incr_err_count();
       result = 1'b0;
   end
end
endtask


//---------------------------------------------------------
//  END: Test Tasks and Utilities
//---------------------------------------------------------

//---------------------------------------------------------
// Initials for Sim Setup
//---------------------------------------------------------
generate
if (!SOC_ATTACH)
begin
   initial 
   begin
      reset_test = 1'b0;
      test_id = '0;
      test_done = 1'b0;
      test_result = 1'b0;
   end
end
endgenerate


generate
if (!SOC_ATTACH)
begin
   initial 
   begin
      fork: timeout_thread begin
         $display("Begin Timeout Thread.  Test will time out in %0t\n", TIMEOUT);
        // timeout thread, wait for TIMEOUT period to pass
        #(TIMEOUT);
        // The test hasn't finished within TIMEOUT Period
        @(posedge clk);
        $display ("TIMEOUT, test_pass didn't go high in %0t\n", TIMEOUT);
        disable timeout_thread;
      end
    
      wait (test_done == 1) begin
         // Test summary
         $display("\n********************");
         $display("  Test summary");
         $display("********************");
         for (int i=0; i < test_id; i=i+1) 
         begin
            if (test_summary[i].result)
               $display("   %0s (id=%0d) - pass", test_summary[i].name, i);
            else
               $display("   %0s (id=%0d) - FAILED", test_summary[i].name, i);
         end

         if(get_err_count() == 0) 
         begin
             $display("Test passed!");
         end 
         else 
         begin
             if (get_err_count() != 0) 
             begin
                $display("Test FAILED! %d errors reported.\n", get_err_count());
             end
          end
      end
      
      join_any    
      $finish();  
   end
end
endgenerate

generate
if (SOC_ATTACH)
begin
   always begin : main   
      #10000;
      $display(">>> HOST Test: SOC will remain quiet for this test.");
      wait(0);
   end
end
else
begin
   always begin : main   
      $display("Start of MAIN Always.");
      #10000;
      $display("MAIN Always - After Delay");
      wait (rst_n);
      $display("MAIN Always - After Wait for rst_n.");
      wait (csr_rst_n);
      $display("MAIN Always - After Wait for csr_rst_n.");
      //-------------------------
      // deassert port reset
      //-------------------------
      deassert_afu_reset();
      $display("MAIN Always - After Deassert of AFU Reset.");
      //-------------------------
      // Test scenarios 
      //-------------------------
      main_test(test_result);
      $display("MAIN Always - After Main Task.");
      test_done = 1'b1;
   end
end
endgenerate


task test_mmio_addr32;
   output logic result;
begin
   print_test_header("test_mmio_addr32");
   test_mmio(result, ADDR32);
end
endtask

// Test MMIO access with 64-bit address 
task test_mmio_addr64;
   output logic result;
begin
   print_test_header("test_mmio_addr64");
   test_mmio(result, ADDR64);
end
endtask

// Test memory write 32-bit address 
task test_mmio;
   output logic result;
   input e_addr_mode addr_mode;
   logic [63:0] base_addr;
   logic [63:0] addr;
   logic [63:0] scratch;
   logic        error;
   logic [31:0] old_test_err_count;
begin
   old_test_err_count = get_err_count();
   result = 1'b1;
   
   //-----------
   // Test MMIO write stall issue
   //-----------
   host_bfm_top.host_bfm.write32(PMCI_FBM_AR, {8{4'h1}});
   host_bfm_top.host_bfm.write32(PMCI_FBM_AR, {8{4'h2}});
   @(posedge clk);
   host_bfm_top.host_bfm.write32(PMCI_FBM_AR, {8{4'h3}});
   test_csr_read_32(result, ADDR32, PMCI_FBM_AR, 'h03333333); // PMCI_FBM_AR RW range is 27:0
   
   $display("Test CSR access");
      test_csr_read_64(result,addr_mode, PMCI_DFH, 'h3000000010001012);
      test_csr_access_32(result, addr_mode, PMCI_FBM_AR, 'h0111_2222);   
     // test_csr_access_32(result, addr_mode, PMCI_SEU_ERR, 'h1111_2222);   
     // test_csr_access_32(result, addr_mode, PMCI_VDM_BA, 'h0004_2000);   
     // test_csr_access_32(result, addr_mode, PMCI_PCIE_SS_BA, 'h0001_2222);   
     // test_csr_access_32(result, addr_mode, PMCI_HSSI_SS_BA, 'h0001_2222);   
     // test_csr_access_32(result, addr_mode, PMCI_QSFPA_BA, 'h0001_2222);   
     // test_csr_access_32(result, addr_mode, PMCI_QSFPB_BA, 'h0001_2222);   
      test_csr_access_32(result, addr_mode, PMCI_SPI_CSR, 'h0000_0002);   
      test_csr_access_32(result, addr_mode, PMCI_SPI_AR, 'h0000_2222);   
      test_csr_read_32(result, addr_mode, PMCI_SPI_RD_DR, 'h0);
      test_csr_access_32(result, addr_mode, PMCI_SPI_WR_DR, 'h1111_2222);   
      //test_csr_access_32(result, addr_mode, PMCI_FBM_FIFO, 'h1111_2222);   
      //test_csr_access_64(result, addr_mode, PMCI_VDM_FCR, 'h1111_2222_3333_4444);   
      //test_csr_access_64(result, addr_mode, PMCI_VDM_PDR, 'h1111_2222_3333_4444);   

   post_test_util(old_test_err_count);
end
endtask


task create_vdm_msg_rand_packet;
   input logic         has_data;
   input logic [9:0]   length;
   static logic [31:0] msg_word = 32'hC0DE_1234;
   logic [31:0] msg_words[$];
   byte_t tmp_vdm_buf[];
begin 
    vt = new(
      .access_source("Unit Test"),
      .data_present( (has_data) ? DATA_PRESENT : NO_DATA_PRESENT),
      .msg_route(VDM_BROADCAST_FROM_ROOT_COMPLEX),
      .requester_id(16'h0000),
      .msg_code(VDM_TYPE1),
      .pci_target_id(16'hFFFF),
      .vendor_id(16'h1AB4),
      .length_dw(length)
   );
   msg_words.delete();
   for (int i = 0; i < int'(length-10'd1); i++)
   begin
      msg_words.push_back(msg_word);
   end
   vdm_buf = new[((int'(length-10'd1))*4)+1]; // In bytes.
   tmp_vdm_buf = {<<8{{<<32{msg_words}}}};
   for (int i = 0; i < tmp_vdm_buf.size(); i++)
   begin
      vdm_buf[i] = tmp_vdm_buf[i];
   end
   vdm_buf[tmp_vdm_buf.size()] = 8'hFF;
   vt.request_packet.set_data(vdm_buf);
   $display("VDM Message from Rand Packet Task:");
   vt.print_data();
   t = vt;
   $display("   ** Start Sending VDM TLP message packet **");
   host_bfm_top.mutex_mmio_rx_req_input_transaction_queue.get();
   host_bfm_top.mmio_rx_req_input_transaction_queue.push_back(t);
   host_bfm_top.mutex_mmio_rx_req_input_transaction_queue.put();
   $display("   ** End Sending VDM TLP message packet **");
   //hdr = '0;
   //hdr.dw0.fmttype = {has_data, 6'b110011}; //fmttype[6:5]=2'b11, fmttype[4:3]=2'b10, fmttype[2:0]=3'b010
   //hdr.dw0.length  = length;
   //hdr.msg_code    = 'h7f;
   //hdr.tag         = {2'h0,2'h3,4'h0}; 
   //hdr.pci_target_id =16'hFFFF; 
   //hdr.vendor_id   = 'h1ab4; 
   //hdr.upper_msg   = 32'h010000C0; //MCTP header info: RSVD = 4'h0, hdr version = 4'h1, destination ID = 8'h0, 
                                   //source EID = 8'h0, SOM = 1'b1, EOM = 1'b1, PktSeq = 2'b0, TO = 1'b0, MsgTag = 3'b0   
   //`ifdef HTILE
      //hdr = to_little_endian(hdr);
   //`endif
   $display("   ** start Sending VDM TLP message packets **");
   //pld = {{15{32'hc0de_1234}},8'hFF};
   //create_packet(pkt_buf, buf_size, has_data, ADDR64, length, hdr, 0, 0, 0, 0,pld, 0);
   //write_test_packet(pkt_buf, buf_size);
   //f_send_test_packet();
   host_bfm_top.mutex_mmio_rx_req_input_transaction_queue.get();
   host_bfm_top.mmio_rx_req_input_transaction_queue.push_back(t);
   host_bfm_top.mutex_mmio_rx_req_input_transaction_queue.put();
   $display("   ** End Sending VDM TLP message packets **");
end
endtask


// Test MMIO access with 64-bit address 
task test_vdm_tx_rx_lpbk;
   output logic result;
begin
   print_test_header("test_vdm_tx_rx_lpbk");
   test_vdm_tx_rx_lpbk_test(result); //Randomize eid,deid,targetid,msg_tag etc
   #0.1ms;
   test_vdm_rx_rand_test(result);
end
endtask


task test_vdm_rx_rand_test;
  
  output logic result;
begin

  create_vdm_msg_rand_packet(1,16);
  #0.1ms;
     //BMC txns for RX path
  begin @(posedge top_tb.bmc_m10.m10_clk); 
     force top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_addr = 'h0;
     force top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_write ='h1;
     force top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_wrdata ={1'h0,2'h0,1'h1,1'h0};
  end
  @(posedge top_tb.bmc_m10.m10_clk);
  @(posedge top_tb.bmc_m10.m10_clk);
  @(posedge top_tb.bmc_m10.m10_clk);

  begin @(posedge top_tb.bmc_m10.m10_clk); 
     force top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_addr = 'h0;
     force top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_write ='h1;
     force top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_wrdata ={1'h1,3'h0,1'h1};
  end/*
  begin @(posedge top_tb.bmc_m10.m10_clk); 
     force top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_addr = 'h0;
     force top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_write ='h1;
     force top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_wrdata ={1'h1,3'h0,1'h1};
  end*/
  @(posedge top_tb.bmc_m10.m10_clk);
  @(posedge top_tb.bmc_m10.m10_clk);
     force top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_write ='h0;
  #200us;
  begin @(posedge top_tb.bmc_m10.m10_clk);
     force top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_addr = 'h0;
     force top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_read ='h1;
     //vdm_pkt_length=top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_rddata ;
  end 
  begin @(posedge top_tb.bmc_m10.m10_clk);
     force top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_addr = 'h1;
     force top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_read ='h1;
    // mctp_header=top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_rddata;
  end 
  begin @(posedge top_tb.bmc_m10.m10_clk);
     force top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_addr = 'h200;
     force top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_read ='h1;
  end 
  begin @(posedge top_tb.bmc_m10.m10_clk); 
     force top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_read ='h0;
  end
  begin @(posedge top_tb.bmc_m10.m10_clk); 
     force top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_addr = 'h0;
     force top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_write ='h1;
     force top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_wrdata ={1'h0,2'h0,1'h0,1'h0};
  end
  begin @(posedge top_tb.bmc_m10.m10_clk); 
     force top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_write ='h0;
  end
  #0.4ms;
end
endtask



task test_vdm_tx_rx_lpbk_test;

   output logic result;
   logic [31:0] scratch,ack;
   logic [31:0] cnt, rdcnt;
   logic        error;
   logic [31:0] old_test_err_count;
   logic [62:0] rdata,wdata,exp_data;
   logic [31:0] vdm_wdata,mctp_header,vdm_pkt_length;
   static logic [7:0] i_temp;
   static logic [7:0] j_temp;
   //bit [7:0] cnt;
   bit [7:0] valid_cnt;
   logic [31:0] vdm_ref_pld[$];
   logic [31:0] rx_vdm_pld[$];
   logic [1:0][255:0] act_data;
   logic [15:0][31:0] tx_data;
   logic [15:0][31:0] rx_data;
   logic [255:0] ref_data_temp;
   logic [511:0] lpbk_vdm_msg;
   logic [15:0][31:0] vdm_pkt;
   logic  [7:0] lpbk_fmt_type;
   logic  [9:0] lpbk_len;
   logic  [15:0] lpbk_vendor_id;
   logic  [31:0] lpbk_mctp_hdr;
   logic  [7:0]  lpbk_msg_code;
   bit [2:0]  msg_tag;
   bit [7:0]  deid;
   bit [15:0] target_id;
   logic [31:0] msg_payload_words[];
   byte_t msg_payload_bytes[];
   
   bit act_vdm_valid; 
begin
   old_test_err_count = get_err_count();
   result = 1'b1;
   $display("Test MCTP VDM TX-RX Loopback ");
   repeat (6) @(posedge clk);

   host_bfm_top.host_bfm.write32(PMCI_VDM_BA, 'h0010_2000);
    
   begin @(negedge top_tb.bmc_m10.m10_clk);
     force top_tb.bmc_m10.egrs_spi_master.avmm_csr_addr ='h3;
     force top_tb.bmc_m10.egrs_spi_master.avmm_csr_write ='h1;
     force top_tb.bmc_m10.egrs_spi_master.avmm_csr_wrdata ='hFF;
     force top_tb.bmc_m10.egrs_spi_master.avmm_csr_byteen ='hf;
   end  
   begin @(negedge top_tb.bmc_m10.m10_clk);
     force top_tb.bmc_m10.egrs_spi_master.avmm_csr_addr ='h1;
     force top_tb.bmc_m10.egrs_spi_master.avmm_csr_write ='h1;
     force top_tb.bmc_m10.egrs_spi_master.avmm_csr_wrdata ='h08;
     force top_tb.bmc_m10.egrs_spi_master.avmm_csr_byteen ='hf;
   end  
   begin @(negedge top_tb.bmc_m10.m10_clk);
     force top_tb.bmc_m10.egrs_spi_master.avmm_csr_addr ='h0;
     force top_tb.bmc_m10.egrs_spi_master.avmm_csr_write ='h1;
     force top_tb.bmc_m10.egrs_spi_master.avmm_csr_wrdata ='h002;
     force top_tb.bmc_m10.egrs_spi_master.avmm_csr_byteen ='hf;
   end
   @(negedge top_tb.bmc_m10.m10_clk);
   force top_tb.bmc_m10.egrs_spi_master.avmm_csr_write ='h0;
   while(!top_tb.bmc_m10.egrs_spi_master.ack_trans) begin
     force top_tb.bmc_m10.egrs_spi_master.avmm_csr_addr ='h0;
     force top_tb.bmc_m10.egrs_spi_master.avmm_csr_read ='h1;
       @(posedge top_tb.bmc_m10.m10_clk);
   end
   @(negedge top_tb.bmc_m10.m10_clk);
   force top_tb.bmc_m10.egrs_spi_master.avmm_csr_read ='h0;
   begin @(negedge top_tb.bmc_m10.m10_clk);
     force top_tb.bmc_m10.egrs_spi_master.avmm_csr_addr ='h0;
     force top_tb.bmc_m10.egrs_spi_master.avmm_csr_write ='h1;
     force top_tb.bmc_m10.egrs_spi_master.avmm_csr_wrdata ='h000;
     force top_tb.bmc_m10.egrs_spi_master.avmm_csr_byteen ='hf;
   end
    #200us;
    begin @(posedge top_tb.bmc_m10.m10_clk);
    force top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_addr ='h4;
    force top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_read ='h1;

    while(!( top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_rddata[1]==0 && top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_rddvld ==1))
    begin
       $display("Waiting for rdvld and rddata[1]");
       @(posedge top_tb.bmc_m10.m10_clk);
       $display("After posedge   rddata[1] = %h and rdvld = %h",top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_rddata[1],top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_rddvld);
    end
  
    for ( int i=0;i<16;i++) 
    begin @(posedge top_tb.bmc_m10.m10_clk);
       i_temp=i; 
       force top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_read ='h0;
       force top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_addr = 'h300+i_temp;
       force top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_write ='h1;
       assert(std::randomize(vdm_wdata));
       force top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_wrdata =vdm_wdata;
       //force top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_wrdata = {top_tb.DUT.pcie_wrapper.pcie_top.tester.test_vdm_tx_rx_lpbk_test.vdm_wdata[31:0]};
       vdm_ref_pld.push_back(vdm_wdata);
    end 
    begin @(posedge top_tb.bmc_m10.m10_clk);
       force top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_addr = 'h5;
       force top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_write ='h1;
       assert(std::randomize(deid)with {deid inside {'h0,'hFF};});
       assert(std::randomize(msg_tag));
       assert(std::randomize(target_id));
       force top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_wrdata ={1'h0,1'h1,1'h0,msg_tag,deid,target_id};
    end
    begin @(posedge top_tb.bmc_m10.m10_clk); 
       force top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_addr = 'h4;
       force top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_write ='h1;
       force top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_wrdata ={12'h10,2'h3,3'h0,1'h1};
    end
    end
    @(posedge top_tb.bmc_m10.m10_clk); 
    @(posedge top_tb.bmc_m10.m10_clk); 
    force top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_write ='h0;
    
    //Get the actual values from PCIe BFM//

    //f_shmem_vdm_pyld_display(act_data,lpbk_fmt_type,lpbk_len,lpbk_vendor_id,lpbk_mctp_hdr,lpbk_msg_code);
    $display("Waiting for VDM Reception at BFM at time %0t.", $realtime);
    @(posedge clk iff (host_bfm_top.tx_inbound_message_queue.size() > 0));
    $display("VDM message received by BFM at time %0t.", $realtime);
    p = host_bfm_top.tx_inbound_message_queue.pop_front();
    $display("VDM message received:");
    p.print_packet_long();
    msg_payload_bytes = new[p.get_payload_size()];
    p.get_payload(msg_payload_bytes);
    $display(">>> VDM Payload Info:");
    $display("    msg_payload_bytes:");
    $display(msg_payload_bytes);
    msg_payload_words = {<<32{{<<8{msg_payload_bytes}}}};
    $display("    msg_payload_words:");
    $display(msg_payload_words);
    for (int i = 0; i < 16; i++)
    begin
       tx_data[i] = msg_payload_words[i];
    end
    lpbk_fmt_type  = p.get_fmt_type();
    lpbk_len       = p.get_length_dw();
    lpbk_vendor_id = p.get_vendor_id();
    lpbk_msg_code  = p.get_msg_code();
    if(lpbk_fmt_type !=='h70) begin
      $display("Error in tx format type: Expected: 8'h70   Received: 8'h%H", lpbk_fmt_type);
      incr_err_count();
      result = 1'b0;
    end
    if(lpbk_len !=='d16) begin
      $display("Error in tx length: Expected: 10'd16   Received: 10'd%0d", lpbk_len);
      incr_err_count();
      result = 1'b0;
    end
    if(lpbk_vendor_id !=='h1ab4) begin
      $display("Error in tx vendor ID: Expected: 16'h1AB4   Received: 16'h%H", lpbk_vendor_id);
      incr_err_count();
      result = 1'b0;
    end
    if(lpbk_msg_code !== 'h7f) begin
      $display("Error in tx message code: Expected: 8'h7F   Received: 8'h%H", lpbk_msg_code);
      incr_err_count();
      result = 1'b0;
    end
    if (result == 1'b1)
    begin
       $display("Received VDM Message has the correct format!");
    end
    #200us;
    //$display("    tx_data:");
    //for ( int i=0;i<16;i++) begin
     //tx_data[i] =vdm_ref_pld.pop_front();
     //$display("tx_data word %0d: %H", i, tx_data[i]);
    //end

    //lpbk_vdm_msg={act_data[1],act_data[0]};
    //Loopback at RX side begins
    //test_vdm_msg_rx_path (result,lpbk_fmt_type,lpbk_len,lpbk_vendor_id,lpbk_mctp_hdr,lpbk_msg_code,lpbk_vdm_msg);  // 64B   VDM packet
    vt = new(
      .access_source("Unit Test"),
      .data_present(DATA_PRESENT),
      .msg_route(VDM_ROUTED_BY_ID),
      .requester_id(16'hFFFF),
      .msg_code(lpbk_msg_code),
      .pci_target_id(16'h0000),
      .vendor_id(lpbk_vendor_id),
      .length_dw(lpbk_len)
   );
   //vt.request_packet = p;
   vt.request_packet.set_data(msg_payload_bytes);
   $display("Loopback VDM Message:");
   vt.print_data();
   t = vt;
   $display("   ** Start Sending VDM TLP message packet **");
   host_bfm_top.mutex_mmio_rx_req_input_transaction_queue.get();
   host_bfm_top.mmio_rx_req_input_transaction_queue.push_back(t);
   host_bfm_top.mutex_mmio_rx_req_input_transaction_queue.put();
   $display("   ** End Sending VDM TLP message packet **");
    //BMC txns for RX path
    begin @(posedge top_tb.bmc_m10.m10_clk); 
       force top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_addr = 'h0;
       force top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_write ='h1;
       force top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_wrdata ={1'h0,2'h0,1'h1,1'h0};
    end
    @(posedge top_tb.bmc_m10.m10_clk);
    @(posedge top_tb.bmc_m10.m10_clk);
    @(posedge top_tb.bmc_m10.m10_clk);

    begin @(posedge top_tb.bmc_m10.m10_clk); 
       force top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_addr = 'h0;
       force top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_write ='h1;
       force top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_wrdata ={1'h1,3'h0,1'h1};
    end/*
    begin @(posedge top_tb.bmc_m10.m10_clk); 
       force top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_addr = 'h0;
       force top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_write ='h1;
       force top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_wrdata ={1'h1,3'h0,1'h1};
    end*/
    @(posedge top_tb.bmc_m10.m10_clk);
    @(posedge top_tb.bmc_m10.m10_clk);
       force top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_write ='h0;
    #200us;
    begin @(posedge top_tb.bmc_m10.m10_clk);
       force top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_addr = 'h0;
       force top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_read ='h1;
       vdm_pkt_length=top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_rddata ;
    end 
    begin @(posedge top_tb.bmc_m10.m10_clk);
       force top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_addr = 'h1;
       force top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_read ='h1;
       mctp_header=top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_rddata;
    end 
    begin @(posedge top_tb.bmc_m10.m10_clk);
       force top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_addr = 'h200;
       force top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_read ='h1;
       vdm_pkt=top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_rddata ;
    end 
    begin @(posedge top_tb.bmc_m10.m10_clk); 
       force top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_read ='h0;
    end
    begin @(posedge top_tb.bmc_m10.m10_clk); 
       force top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_addr = 'h0;
       force top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_write ='h1;
       force top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_wrdata ={1'h0,2'h0,1'h0,1'h0};
    end
    begin @(posedge top_tb.bmc_m10.m10_clk); 
       force top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_write ='h0;
    end
    #1ms;
    fork begin
    for ( int j=0;j<16;j++) begin
    begin @(posedge top_tb.bmc_m10.m10_clk);
      if(!top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_waitreq) begin
       j_temp=j;
       force top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_addr = 'h200+j_temp;
       force top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_read ='h1;
       //vdm_pkt=top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_rddata ;
      end
      else begin
          j=j-1;
      end 
    end
    end
    end
    begin
      while (!top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_rddvld) begin
        @(posedge top_tb.bmc_m10.m10_clk);
      end
      while(valid_cnt<16) begin
      if(top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_rddvld==1) begin
        vdm_pkt=top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_rddata ;
        rx_vdm_pld.push_back(vdm_pkt);
        valid_cnt=valid_cnt+1;
      end
        @(posedge top_tb.bmc_m10.m10_clk);
      end
    end
    join

    for (int i = 0; i < 16; i++) begin
      rx_data[i]=rx_vdm_pld.pop_front();
    end
    pyld_compare(tx_data,rx_data,result);
     
    force top_tb.bmc_m10.m10_pcie_vdm.avmm_nios_read ='h0;

   // force top_tb.bmc_m10.egrs_spi_master.avmm_csr_wrdata ='h00; //clearing of EID value for 100% toggle coverage

    #100us; 
    post_test_util(old_test_err_count);
end
endtask


//Compare the payload (VDM Message) in BMC with Shared memory in PCIe BFM.
task pyld_compare(input [15:0][31:0]tx_vdm_data,input [15:0][31:0] rx_vdm_data,output bit result);

for(int i=0;i<16;i++) begin
  if(rx_vdm_data[i]==tx_vdm_data[i])
    $display("VDM payloads are matching on BMC and PCIe BFM side");
  else begin
    $display("VDM payloads are not matching ,BMC side VDM value is %h,PCIe BFM side VDM value is %h",tx_vdm_data[i],rx_vdm_data[i]);
    incr_err_count();
    result = 1'b0;
  end
end
endtask


//---------------------------------------------------------
//  Unit Test Procedure
//---------------------------------------------------------
task main_test;
   output logic test_result;
   begin
      $display("Entering PMCI VDM TX/RX Random Loopback Test.");
      host_bfm_top.host_bfm.set_mmio_mode(PU_METHOD_TRANSACTION);
      host_bfm_top.host_bfm.set_dm_mode(DM_AUTO_TRANSACTION);
      pfvf = '{0,0,0}; // Set PFVF to PF0
      host_bfm_top.host_bfm.set_pfvf_setting(pfvf);

      test_vdm_tx_rx_lpbk (test_result);
   end
endtask


endmodule
