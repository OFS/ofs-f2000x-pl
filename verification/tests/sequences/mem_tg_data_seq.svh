// Copyright (C) 2023 Intel Corporation
// SPDX-License-Identifier: MIT

`ifndef IOFS_AC_MEM_TG_DATA_SEQ_SVH
 `define IOFS_AC_MEM_TG_DATA_SEQ_SVH

class mem_tg_data_seq extends base_seq;
   `uvm_object_utils(mem_tg_data_seq)
   `uvm_declare_p_sequencer(virtual_sequencer)

   function new(string name = "mem_tg_data_seq");
      super.new(name);
   endfunction : new

   task body();
      localparam CSR_ADDR_SHIFT = 3 ;
      localparam NUM_TG = 4;
      localparam MEM_SS_BASE = 'h62000;
      localparam EMIF_CAPABILITY_OFFSET = 'h10;
      localparam EMIF_STATUS_OFFSET = 'h08;
      localparam EMIF_STATUS_ADDR = MEM_SS_BASE + EMIF_STATUS_OFFSET;
      localparam EMIF_CAPABILITY_ADDR = MEM_SS_BASE + EMIF_CAPABILITY_OFFSET;
      bit [63:0] wdata;
      bit [63:0] rdata;
      bit [63:0] mask;
      bit [63:0] expdata;
      bit [63:0] addr;
      int        ch     = 1;

      super.body();

      `uvm_info(get_name, "Verify that all EMIF channels are present.", UVM_LOW)
      addr = tb_cfg0.PF0_BAR0 + EMIF_CAPABILITY_ADDR;
      mmio_read32 (.addr_(addr), .data_(rdata));
      if (rdata[3:0] != 4'b1111) begin
         `uvm_fatal(get_name, $psprintf("EMIF_CAPABILITY = %04b!", rdata[3:0]))
      end

      #100us;
      `uvm_info(get_name, $psprintf("Poll for the EMIF channel calibration status to be set.", ch), UVM_LOW)
      addr = tb_cfg0.PF0_BAR0 + EMIF_STATUS_ADDR;		
      do begin
         #1us;
         mmio_read32 (.addr_(addr), .data_(rdata));
         `uvm_info(get_name(), $psprintf("EMIF_STATUS = %0b", rdata[NUM_TG-1:0]), UVM_LOW)
      end
      while (rdata[7:0] == 0);

      if (rdata[7:4] != 0) begin
         `uvm_fatal(get_name, $psprintf("EMIF_STATUS.CalFailure: %04b", rdata[7:4]))
      end

      // Find a channel that passed if any
      for (ch = 0; ch < 4 && rdata[ch] == 0; ch++);
      if (ch == 4) begin
         `uvm_fatal(get_name, $psprintf("EMIF_STATUS.CalSuccess: %04b", rdata[3:0]))
      end
      else begin
         `uvm_info(get_name, $psprintf("Using EMIF channel %1d", ch), UVM_LOW)
      end
      
      `uvm_info(get_name, "Verify the WRITE, READ, REPEAT, and LOOP counts are 1.", UVM_LOW)
      expdata = 64'd1;
      addr    = tb_cfg0.PF0_VF2_BAR0+MEM_TG_BASE_ADDR+'h1000+(ch*'h1000)+'h08;
      mmio_read32 (.addr_(addr), .data_(rdata));
      if (rdata[31:0] != expdata[31:0]) begin
         `uvm_error(get_name(), $psprintf("TG_LOOP_COUNT_%1d Data mismatch 32! Addr= %0h, Exp = %0h, Act = %0h", ch, addr, expdata[31:0], rdata))
      end

      addr    = tb_cfg0.PF0_VF2_BAR0+MEM_TG_BASE_ADDR+'h1000+(ch*'h1000)+'h0c;
      mmio_read32 (.addr_(addr), .data_(rdata));
      if (rdata[31:0] != expdata[31:0]) begin
         `uvm_error(get_name(), $psprintf("TG_WRITE_COUNT_%1d Data mismatch 32! Addr= %0h, Exp = %0h, Act = %0h", ch, addr, expdata[31:0], rdata))
      end

      addr    = tb_cfg0.PF0_VF2_BAR0+MEM_TG_BASE_ADDR+'h1000+(ch*'h1000)+'h10;
      mmio_read32 (.addr_(addr), .data_(rdata));
      if (rdata[31:0] != expdata[31:0]) begin
         `uvm_error(get_name(), $psprintf("TG_READ_COUNT_%1d Data mismatch 32! Addr= %0h, Exp = %0h, Act = %0h", ch, addr, expdata[31:0], rdata))
      end

      addr    = tb_cfg0.PF0_VF2_BAR0+MEM_TG_BASE_ADDR+'h1000+(ch*'h1000)+'h14;
      mmio_read32 (.addr_(addr), .data_(rdata));
      if (rdata[31:0] != expdata[31:0]) begin
         `uvm_error(get_name(), $psprintf("TG_WRITE_REPEAT_COUNT_%1d Data mismatch 32! Addr= %0h, Exp = %0h, Act = %0h", ch, addr, expdata[31:0], rdata))
      end

      addr    = tb_cfg0.PF0_VF2_BAR0+MEM_TG_BASE_ADDR+'h1000+(ch*'h1000)+'h18;
      mmio_read32 (.addr_(addr), .data_(rdata));
      if (rdata[31:0] != expdata[31:0]) begin
         `uvm_error(get_name(), $psprintf("TG_READ_REPEAT_COUNT_%1d Data mismatch 32! Addr= %0h, Exp = %0h, Act = %0h", ch, addr, expdata[31:0], rdata))
      end

      `uvm_info(get_name, $psprintf("Writing to MEM_TG_CTRL on channel %1d", ch), UVM_LOW)
      addr  = tb_cfg0.PF0_VF2_BAR0+MEM_TG_BASE_ADDR+'h30;
      wdata = 1'b1 << ch;
      mmio_write32(.addr_(addr), .data_(wdata));

      addr = tb_cfg0.PF0_VF2_BAR0+MEM_TG_BASE_ADDR+'h38;
      do begin
         #1us;
         mmio_read32 (.addr_(addr), .data_(rdata));
      end
      while (rdata[4*ch+0]);

      if (rdata[4*ch+3] == 0) begin
         `uvm_error(get_name(), $psprintf("MEM_TG_STATUS for channel %1d is PASS = %b, FAIL = %b, TIMEOUT - %b.", ch, rdata[4*ch+3], rdata[4*ch+2], rdata[4*ch+1]))
      end

      addr = tb_cfg0.PF0_VF2_BAR0+MEM_TG_BASE_ADDR+'h50+(ch<<CSR_ADDR_SHIFT);
      mmio_read32 (.addr_(addr), .data_(rdata));
      `uvm_info(get_name(), $psprintf("CLOCK_COUNT[%1d] = %1d.", ch, rdata), UVM_LOW)

      #1us;
      `uvm_info(get_name, $psprintf("Writing to MEM_TG_CTRL on channel %1d", ch), UVM_LOW)
      addr  = tb_cfg0.PF0_VF2_BAR0+MEM_TG_BASE_ADDR+'h30;
      wdata = 1'b1 << ch;
      mmio_write32(.addr_(addr), .data_(wdata));

      // Wait for a little while and then Poll the status
      addr = tb_cfg0.PF0_VF2_BAR0+MEM_TG_BASE_ADDR+'h38;
      do begin
         #1us;
         mmio_read32 (.addr_(addr), .data_(rdata));
      end
      while (rdata[4*ch+0]);

      if (rdata[4*ch+3] == 0) begin
         `uvm_error(get_name(), $psprintf("MEM_TG_STATUS for channel %1d is PASS = %b, FAIL = %b, TIMEOUT - %b.", ch, rdata[4*ch+3], rdata[4*ch+2], rdata[4*ch+1]))
      end

      addr = tb_cfg0.PF0_VF2_BAR0+MEM_TG_BASE_ADDR+'h50+(ch<<CSR_ADDR_SHIFT);
      mmio_read32 (.addr_(addr), .data_(rdata));
      `uvm_info(get_name(), $psprintf("CLOCK_COUNT[%1d] = %1d.", ch, rdata), UVM_LOW)


      `uvm_info(get_name(), $psprintf("Generating performance data for channel %1d.", ch), UVM_LOW)
      `uvm_info(get_name(), $psprintf("Setting channel %1d TG_WRITE_COUNT and TG_LOOP_COUNT to 8.", ch), UVM_LOW)
      wdata  = 8;
      addr   = tb_cfg0.PF0_VF2_BAR0+MEM_TG_BASE_ADDR+'h1000+(ch*'h1000)+'h08; // TG_LOOP_COUNT
      mmio_write32(.addr_(addr), .data_(wdata));
      addr   = tb_cfg0.PF0_VF2_BAR0+MEM_TG_BASE_ADDR+'h1000+(ch*'h1000)+'h48; // TG_ADDR_MODE_WR
      wdata  = 1;                                            // sequenctial mode
      mmio_write32(.addr_(addr), .data_(wdata));
      addr   = tb_cfg0.PF0_VF2_BAR0+MEM_TG_BASE_ADDR+'h1000+(ch*'h1000)+'h10; // TG_READ_COUNT
      wdata  = 0;
      mmio_write32(.addr_(addr), .data_(wdata));
      for (int size = 1; size <= 128; size *= 2) begin
         `uvm_info(get_name(), $psprintf("Setting channel %1d TG_BURST_LENGTH and TG_SEQ_ADDR_INCR to %1d.", ch, size), UVM_LOW)
         wdata = size;
         addr  = tb_cfg0.PF0_VF2_BAR0+MEM_TG_BASE_ADDR+'h1000+(ch*'h1000)+'h1c; // TG_BURST_LENGTH
         mmio_write32(.addr_(addr), .data_(wdata));
         addr  = tb_cfg0.PF0_VF2_BAR0+MEM_TG_BASE_ADDR+'h1000+(ch*'h1000)+'h74; // TG_SEQ_ADDR_INCR
         mmio_write32(.addr_(addr), .data_(wdata));
         `uvm_info(get_name(), $psprintf("Setting channel %1d TG_WRITE_COUNT to 8 and TG_READ_COUNT to 0.", ch), UVM_LOW)
         wdata = 8;
         addr  = tb_cfg0.PF0_VF2_BAR0+MEM_TG_BASE_ADDR+'h1000+(ch*'h1000)+'h0c; // TG_WRITE_COUNT
         mmio_write32(.addr_(addr), .data_(wdata));
         wdata = 0;
         addr  = tb_cfg0.PF0_VF2_BAR0+MEM_TG_BASE_ADDR+'h1000+(ch*'h1000)+'h10; // TG_READ_COUNT
         mmio_write32(.addr_(addr), .data_(wdata));
         wdata = 1;
         addr  = tb_cfg0.PF0_VF2_BAR0+MEM_TG_BASE_ADDR+'h1000+(ch*'h1000)+'h04; // TG_START
         mmio_write32(.addr_(addr), .data_(wdata));
         addr = tb_cfg0.PF0_VF2_BAR0+MEM_TG_BASE_ADDR+'h1000+(ch*'h1000)+'ha8; // TG_TEST_COMPLETE
         do begin
            #1us;
            mmio_read32 (.addr_(addr), .data_(rdata));
         end
         while (!rdata[0]);

         addr = tb_cfg0.PF0_VF2_BAR0+MEM_TG_BASE_ADDR+'h38; // MEM_TG_STAT
         mmio_read32 (.addr_(addr), .data_(rdata));
         `uvm_info(get_name(), $psprintf("MEM_TG_STAT for channel %1d is PASS = %b, FAIL = %b, TIMEOUT - %b.",
                                         ch, rdata[4*ch+3], rdata[4*ch+2], rdata[4*ch+1]), UVM_LOW)
         addr = tb_cfg0.PF0_VF2_BAR0+MEM_TG_BASE_ADDR+'h50+(ch<<CSR_ADDR_SHIFT);
         mmio_read32 (.addr_(addr), .data_(rdata));
         `uvm_info(get_name(), $psprintf("WRITE Size %1d CLOCK_COUNT[%1d] = %1d.", size, ch, rdata), UVM_LOW)
         `uvm_info(get_name(), $psprintf("Setting channel %1d TG_READ_COUNT to 8 and TG_WRITE_COUNT to 0.", ch), UVM_LOW)
         wdata = 8;
         addr  = tb_cfg0.PF0_VF2_BAR0+MEM_TG_BASE_ADDR+'h1000+(ch*'h1000)+'h10; // TG_READ_COUNT
         mmio_write32(.addr_(addr), .data_(wdata));
         wdata = 0;
         addr  = tb_cfg0.PF0_VF2_BAR0+MEM_TG_BASE_ADDR+'h1000+(ch*'h1000)+'h0c; // TG_WRITE_COUNT
         mmio_write32(.addr_(addr), .data_(wdata));
         wdata = 1;
         addr  = tb_cfg0.PF0_VF2_BAR0+MEM_TG_BASE_ADDR+'h1000+(ch*'h1000)+'h04; // TG_START
         mmio_write32(.addr_(addr), .data_(wdata));
         addr = tb_cfg0.PF0_VF2_BAR0+MEM_TG_BASE_ADDR+'h1000+(ch*'h1000)+'ha8; // TG_TEST_COMPLETE
         do begin
            #1us;
            mmio_read32 (.addr_(addr), .data_(rdata));
         end
         while (!rdata[0]);

         addr = tb_cfg0.PF0_VF2_BAR0+MEM_TG_BASE_ADDR+'h38; // MEM_TG_STAT
         mmio_read32 (.addr_(addr), .data_(rdata));
         `uvm_error(get_name(), $psprintf("MEM_TG_STAT for channel %1d is PASS = %b, FAIL = %b, TIMEOUT - %b.", ch, rdata[4*ch+3], rdata[4*ch+2], rdata[4*ch+1]))
         addr = tb_cfg0.PF0_VF2_BAR0+MEM_TG_BASE_ADDR+'h50+(ch<<CSR_ADDR_SHIFT);
         mmio_read32 (.addr_(addr), .data_(rdata));
         `uvm_info(get_name(), $psprintf("READ Size %1d CLOCK_COUNT[%1d] = %1d.", size, ch, rdata), UVM_LOW)
      end

      `uvm_info(get_name(), "Exiting  mem_tg_data_seq...", UVM_LOW)

   endtask : body
endclass :  mem_tg_data_seq

`endif //  IOFS_AC_MEM_TG_DATA_SEQ_SVH


