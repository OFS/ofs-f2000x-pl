// Copyright (C) 2023 Intel Corporation
// SPDX-License-Identifier: MIT

//===============================================================================================================
/**
 * Abstract:
 * class dfh_walking_seq is executed by dfh_walking_test 
 * This sequence checks the DFH offset of all mentioned blocks and EOL
 **/
//===============================================================================================================

`ifndef DFH_WALKING_SEQ_SVH
`define DFH_WALKING_SEQ_SVH

class dfh_walking_seq extends base_seq;
    `uvm_object_utils(dfh_walking_seq)
    `uvm_declare_p_sequencer(virtual_sequencer)
	bit [63:0] rdata;
        bit        eol;
	bit [63:0] addr ;
     // bit [63:0] addr = tb_cfg0.PF0_BAR0;
        bit [63:0] dfh_offset_array[];

 function new(string name = "dfh_walking_seq");
        super.new(name);
	
 endfunction : new


  task body();
   
    	 super.body();
	 addr = tb_cfg0.PF0_BAR0;

	//	dfh_offset_array = new[14];
//	dfh_offset_array[ 0] = tb_cfg0.PF0_BAR0;                           // FME_DFH           0x8000_0000
//	dfh_offset_array[ 1] = dfh_offset_array[ 0] + 64'h0_1000;   // THERM_MNGM_DFH    0x8000_1000
//	dfh_offset_array[ 2] = dfh_offset_array[ 1] + 64'h0_2000;   // GLBL_PERF_DFH     0x8000_3000
//	dfh_offset_array[ 3] = dfh_offset_array[ 2] + 64'h0_1000;   // GLBL_ERROR_DFH    0x8000_4000
//	dfh_offset_array[ 4] = dfh_offset_array[ 3] + 64'h0_C000;   // PMCI_DFH          0x8001_0000
//	dfh_offset_array[ 5] = dfh_offset_array[ 4] + 64'h1_0000;   // PCIE_DFH          0x8002_0000
//	dfh_offset_array[ 6] = dfh_offset_array[ 5] + 64'h1_0000;   // HSSI_DFH          0x8003_0000
//	dfh_offset_array[ 7] = dfh_offset_array[ 6] + 64'h1_0000;   // EMIF_DFH          0x8004_0000
//	dfh_offset_array[ 8] = dfh_offset_array[ 7] + 64'h4_0000;   // ST2MM_DFH         0x8008_0000
//	dfh_offset_array[ 9] = dfh_offset_array[ 8] + 64'h1_0000;   // PR_GASKET_DFH     0x8009_0000
//	dfh_offset_array[10] = dfh_offset_array[ 9] + 64'h0_1000;   // PR_CTRL_STATS_DFH 0x8009_1000
//	dfh_offset_array[11] = dfh_offset_array[10] + 64'h0_1000;   // USER_CLOCK_DFH    0x8009_2000
//	dfh_offset_array[12] = dfh_offset_array[11] + 64'h0_1000;   // REMOTE_STP_DFH    0x8009_3000
//	dfh_offset_array[13] = dfh_offset_array[12] + 64'h0_D000;   // AFU_INTF_DFH      0x800A_0000

        
//	dfh_offset_array = new[14];
	dfh_offset_array = new[15];
	dfh_offset_array[ 0] = tb_cfg0.PF0_BAR0;                     // FME_DFH           0x8000_0000
	dfh_offset_array[ 1] =  dfh_offset_array[ 0] + 64'h0_1000;   // THERM_MNGM_DFH    0x8000_1000
	dfh_offset_array[ 2] =  dfh_offset_array[ 1] + 64'h0_2000;   // GLBL_PERF_DFH     0x8000_3000
	dfh_offset_array[ 3] =  dfh_offset_array[ 2] + 64'h0_1000;   // GLBL_ERROR_DFH    0x8000_4000
//	dfh_offset_array[ 4] =  dfh_offset_array[ 3] + 64'h0_1000;   // PR_DFH            0x8000_5000
//	dfh_offset_array[ 4] =  dfh_offset_array[ 3] + 64'h0_5000;   // PR_DFH            0x8000_5000
//	dfh_offset_array[ 5] =  dfh_offset_array[ 4] + 64'h0_B000;   // PCIE_DFH          0x8001_0000
//	dfh_offset_array[ 4] =  dfh_offset_array[ 3] + 64'h0_C000;   // PCIE_DFH          0x8001_0000 // TODO C000-7000
	dfh_offset_array[ 4] =  dfh_offset_array[ 3] + 64'h0_E000;   // QSFP0_DFH         0x8001_2000
	dfh_offset_array[ 5] =  dfh_offset_array[ 4] + 64'h0_1000;   // QSFP1_DFH         0x8001_3000
	dfh_offset_array[ 6] =  dfh_offset_array[ 5]  + 64'h0_1000;   // HSSI_DFH          0x8001_4000
	dfh_offset_array[ 7] = dfh_offset_array[ 6] + 64'h0_1000;  // EMIF_DFH           0x8001_5000
	dfh_offset_array[ 8] =  dfh_offset_array[ 7] + 64'h6_b000;   // PMCI_DFH          0x8008_0000
	dfh_offset_array[ 9] =  dfh_offset_array[ 8] + 64'h8_0000;   // ST2MM_DFH         0x8010_0000
        //dfh_offset_array[ 10] =  dfh_offset_array[ 9] + 64'h0_0000;   // FME_DFH           0x8005_0000 //change later
	//dfh_offset_array[ 11] = dfh_offset_array[ 10] + 64'h2_1000;  // MCTP_DFH          0x8006_1000//change later
 	dfh_offset_array[ 10] = dfh_offset_array[9] + 64'h3_0000;   // PG_PR_DFH_IDX     0x8013_0000
	dfh_offset_array[ 11] = dfh_offset_array[10] + 64'h0_1000;  // PG_PORT_DFH_IDX   0x8013_1000
	dfh_offset_array[ 12] = dfh_offset_array[11] + 64'h0_1000;  // PG_USER_CLK_DFH_IDX       0x8013_2000
	dfh_offset_array[ 13] = dfh_offset_array[12] + 64'h0_1000;  // PG_REMOTE_STP_DFH_IDX     0x8013_3000
	dfh_offset_array[ 14] = dfh_offset_array[13] + 64'h0_D000;  // PG_AFU_ERR_DFH_IDX        0x8014_0000


  	for(int i = 0; i < dfh_offset_array.size(); i++) begin
	    if(addr != dfh_offset_array[i])
	        `uvm_error(get_name(), $psprintf("DFH offset mismatch! Exp = %0h Act = %0h", dfh_offset_array[i], addr))
	    else
	        `uvm_info(get_name(), $psprintf("DFH offset Match! Exp = %0h Act = %0h", dfh_offset_array[i], addr), UVM_LOW)
	    mmio_read64(addr, rdata);
	    addr += rdata[39:16]; // offset is dword address
	    eol = rdata[40];
	    if(eol && i != (dfh_offset_array.size() - 1))
	        `uvm_error(get_name(), "Unexpected EOL for DFH walking")
	end

	if(~eol)
	    `uvm_error(get_name(), "Expecting EOL being asserted after DFH walking")
    endtask : body


endclass : dfh_walking_seq

`endif // DFH_WALKING_SEQ_SVH
