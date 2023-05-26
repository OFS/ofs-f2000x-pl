// Copyright (C) 2023 Intel Corporation
// SPDX-License-Identifier: MIT

`ifndef IOFS_AC_MEM_TG_CH_HOP_SEQ_SVH
`define IOFS_AC_MEM_TG_CH_HOP_SEQ_SVH

 class mem_tg_ch_hop_seq extends base_seq;
  `uvm_object_utils(mem_tg_ch_hop_seq)
  `uvm_declare_p_sequencer(virtual_sequencer)

   function new(string name = "mem_tg_ch_hop_seq");
   	super.new(name);
   endfunction : new

   task body();
      localparam NUM_TG = 4;
      localparam MEM_SS_BASE = 'h62000;
      localparam EMIF_STATUS_OFFSET = 'h08;
      localparam EMIF_STATUS_ADDR = MEM_SS_BASE + EMIF_STATUS_OFFSET;
      bit [63:0]   wdata;
      bit [63:0]   rdata;
      bit [63:0]   mask;
      bit [63:0]   expdata;
      bit [63:0]   addr;
      bit [NUM_TG-1:0] ch_ready;
      int              ch;
      int              ch_count;
      bit              ch_err;
      
      super.body();
	         
      
      `uvm_info(get_name(), "Entering mem_tg_ch_hop_seq...", UVM_LOW)
	         
      `uvm_info(get_name, "Enabling TG", UVM_LOW);
      addr  = tb_cfg0.PF0_VF2_BAR0+MEM_TG_BASE_ADDR+'h40;
      wdata = 1;
      mmio_write32(.addr_(addr), .data_(wdata));

      ch_err  = 0;
      expdata = 'ha9;
      do begin
         do begin
            #5us;
            addr = tb_cfg0.PF0_BAR0 + EMIF_STATUS_ADDR;
            mmio_read32 (.addr_(addr), .data_(rdata));
            `uvm_info(get_name(), $psprintf("EMIF_STATUS = %0b", rdata[NUM_TG-1:0]), UVM_LOW)
         end
         while (rdata[NUM_TG-1:0] == 0);

         ch_ready = rdata[NUM_TG-1:0];
         for (ch_count = 0; ch_count < 20; ch_count++) begin
            for (ch = 0; ch < NUM_TG; ch++) begin
               if (ch_ready[ch]) begin
                  addr  = tb_cfg0.PF0_VF2_BAR0+MEM_TG_BASE_ADDR+'h1000+(ch*'h1000) + 'h000;
                  mmio_read32 (.addr_(addr), .data_(rdata));
                  if (rdata == expdata) begin
                     `uvm_info(get_name(), $psprintf(" TG_VERSION_%1d match 32 !Addr= %0h,  Exp = %0h, Act = %0h", ch, addr, expdata, rdata), UVM_LOW)
                  end
                  else begin
                     `uvm_error(get_name(), $psprintf("TG_VERSION_%1d data mismatch 32! Addr= %0h, Exp = %0h, Act = %0h", ch, addr, expdata, rdata))
                     ch_err = 1;
                  end
               end
            end
         end
      end // do begin
      while (ch_ready != 4'b1111 && !ch_err);

      `uvm_info(get_name(), "Exiting  mem_tg_ch_hop_seq...", UVM_LOW)

   endtask : body

endclass :  mem_tg_ch_hop_seq

`endif //  IOFS_AC_MEM_TG_CH_HOP_SEQ_SVH


