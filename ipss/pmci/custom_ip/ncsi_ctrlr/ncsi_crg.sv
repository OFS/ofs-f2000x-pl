// Copyright (C) 2020 Intel Corporation.
// SPDX-License-Identifier: MIT

//
// Description
//-----------------------------------------------------------------------------
// NCSI clock, reset and timing control signal generation module
//-----------------------------------------------------------------------------

module ncsi_crg (
   //input clock & reset
   input  logic       clk           ,
   input  logic       reset         ,
   input  logic       ncsi_clk      ,  
    
   //output clock & reset  
   output logic       clk_ncsi      ,
   output logic       rst_ncsi      ,
   output logic       pulse_1us     ,
   output logic       pulse_1ms     ,
   output logic       rbt_clk_prsnt  
);

localparam CLK_PERIOD  = 10000; //in picoseconds
localparam CLK_CNT_1US = int'(1000000/CLK_PERIOD) - 2;
localparam CNTR_WID    = $clog2(CLK_CNT_1US+1);

logic                   ncsi_rst_i;
logic [CNTR_WID-1:0]    cntr_1us; 
logic [9:0]             cntr_1ms; 
logic                   toggle_1us;
logic                   toggle_1us_sync;
logic                   toggle_1us_sync_r1;
logic [5:0]             rbt_clk_cntr;
logic                   rbt_clk_detect;
logic                   rbt_clk_detect_sync;


altera_std_synchronizer #(
   .depth(5)
) rst_ncsi_inst (
   .clk      (ncsi_clk     ),
   .reset_n  (~reset       ),
   .din      (1'b1         ),
   .dout     (ncsi_rst_i   )
);

assign clk_ncsi       = ncsi_clk;
assign rst_ncsi       = ~ncsi_rst_i;

//-----------------------------------------------------------------------------
// Timing Pulse Generation
//-----------------------------------------------------------------------------
always_ff @(posedge clk, posedge reset)
begin : tmng_pls_seq
   if(reset) begin
      cntr_1us    <= '0;
      pulse_1us   <= 1'b0;
      cntr_1ms    <= 10'd0;
      pulse_1ms   <= 1'b0;
   end else begin
      pulse_1us   <= (cntr_1us == CLK_CNT_1US) ? 1'b1 : 1'b0;
      
      if(pulse_1us)
         cntr_1us <= '0;
      else
         cntr_1us <= cntr_1us + 1'b1;
      
      pulse_1ms   <= (cntr_1ms == 10'd999 && pulse_1us) ? 1'b1 : 1'b0;
      
      if(pulse_1ms)
         cntr_1ms <= 10'd0;
      else if(pulse_1us)
         cntr_1ms <= cntr_1ms + 1'b1;
   end
end : tmng_pls_seq

//-----------------------------------------------------------------------------
// Logic to detect NCSI RBT clock
//-----------------------------------------------------------------------------
always_ff @(posedge clk, posedge reset)
begin : tggl_1us_seq
   if(reset) begin
      toggle_1us <= 1'b0;
   end else begin
      if(pulse_1us)
         toggle_1us <= ~toggle_1us;
   end
end : tggl_1us_seq

altera_std_synchronizer #(                                             
   .depth(3)                                                     
) sync_1us_inst (                                                       
   .clk      (ncsi_clk        ),                                                    
   .reset_n  (~rst_ncsi       ),                                                 
   .din      (toggle_1us      ),                                              
   .dout     (toggle_1us_sync )                                              
);

//Check if NCSI clock toggles enough for every 1us in PMCI clock
always_ff @(posedge ncsi_clk, posedge rst_ncsi)
begin : clk_dtct_seq
   if(rst_ncsi) begin
      toggle_1us_sync_r1   <= 1'b0;
      rbt_clk_cntr         <= 6'd0;
      rbt_clk_detect       <= 1'b0;
   end else begin
      toggle_1us_sync_r1   <= toggle_1us_sync;
      
      if(toggle_1us_sync_r1 != toggle_1us_sync)
         rbt_clk_cntr      <= 6'd0;
      else
         rbt_clk_cntr      <= rbt_clk_cntr + 1'b1;
      
      if(toggle_1us_sync_r1 != toggle_1us_sync && rbt_clk_cntr > 6'd31)
         rbt_clk_detect    <= 1'b1;
      else if(toggle_1us_sync_r1 != toggle_1us_sync)
         rbt_clk_detect    <= 1'b0;
   end
end : clk_dtct_seq


altera_std_synchronizer #(                                             
   .depth(3)                                                     
) sync_clkdtct_inst (                                                       
   .clk      (clk                ),                                                    
   .reset_n  (~reset             ),                                                 
   .din      (rbt_clk_detect     ),                                              
   .dout     (rbt_clk_detect_sync)                                              
);

assign rbt_clk_prsnt = rbt_clk_detect_sync;

endmodule