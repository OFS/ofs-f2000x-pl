// Copyright (C) 2020 Intel Corporation.
// SPDX-License-Identifier: MIT

//
// Description
//-----------------------------------------------------------------------------
//
//   CVL BFM (hssi ss + packet client for tb )
//
//-----------------------------------------------------------------------------
`timescale 1ps / 1ps
import ofs_fim_eth_if_pkg::*;

module cvl_bfm_serial (
   input  logic                     clk_ref, 
   output logic [NUM_CVL_LANES-1:0] cvl_serial_tx_p,
   input  logic [NUM_CVL_LANES-1:0] cvl_serial_rx_p
);

  //--------------------------------------------------------------------------------
  // Signals List
  //--------------------------------------------------------------------------------
  logic        subsystem_cold_rst_n;
  logic        subsystem_cold_rst_ack_n;
  logic        reset_done=0;
  logic        app_ss_lite_clk = 0;
  logic        app_ss_lite_areset_n;
  logic[7:0]   serial_loop_tx;
  logic        clk_ptp_sample = 0;

  // Port-0
  logic         app_ss_st_p0_tx_areset_n;
  logic         app_ss_st_p0_tx_tvalid;
  logic         ss_app_st_p0_tx_tready;
  logic [ETH_PACKET_WIDTH-1:0] app_ss_st_p0_tx_tdata;
  logic [ETH_TKEEP_WIDTH-1:0]  app_ss_st_p0_tx_tkeep;
  logic         app_ss_st_p0_tx_tlast;
  logic [1:0]   app_ss_st_p0_tx_tuser_client;
  logic         app_ss_st_p0_rx_areset_n;
  logic         ss_app_st_p0_rx_tvalid;
  logic [ETH_PACKET_WIDTH-1:0] ss_app_st_p0_rx_tdata;
  logic [ETH_TKEEP_WIDTH-1:0]  ss_app_st_p0_rx_tkeep;
  logic         ss_app_st_p0_rx_tlast;
  logic [6:0]   ss_app_st_p0_rx_tuser_client;
  logic [4:0]   ss_app_st_p0_rx_tuser_sts;
  logic         p0_tx_pause = 1'b0;
  logic         p0_rx_pause;
  logic [7:0]   p0_tx_pfc = 8'b0;
  logic [7:0]   p0_rx_pfc;
  logic         p0_tx_lanes_stable;
  logic         p0_rx_pcs_ready;
  logic         p0_tx_pll_locked;
  logic         p0_tx_rst_n;
  logic         p0_rx_rst_n;
  logic         p0_rx_rst_ack_n;
  logic         p0_tx_rst_ack_n;
  logic         p0_ereset_n;
  logic         p0_clk_pll;
  logic         p0_clk_tx_div;
  logic         p0_clk_rec_div64;
  logic         p0_clk_rec_div;
  logic         p0_reconfig_clk;
  wire          app_ss_st_p0_tx_clk = p0_clk_pll;
  wire          app_ss_st_p0_rx_clk = p0_clk_pll;

  // Port-1
  logic         app_ss_st_p1_tx_areset_n;
  logic         app_ss_st_p1_tx_tvalid;
  logic         ss_app_st_p1_tx_tready;
  logic [ETH_PACKET_WIDTH-1:0] app_ss_st_p1_tx_tdata;
  logic [ETH_TKEEP_WIDTH-1:0]  app_ss_st_p1_tx_tkeep;
  logic         app_ss_st_p1_tx_tlast;
  logic [1:0]   app_ss_st_p1_tx_tuser_client;
  logic         app_ss_st_p1_rx_areset_n;
  logic         ss_app_st_p1_rx_tvalid;
  logic [ETH_PACKET_WIDTH-1:0] ss_app_st_p1_rx_tdata;
  logic [ETH_TKEEP_WIDTH-1:0]  ss_app_st_p1_rx_tkeep;
  logic         ss_app_st_p1_rx_tlast;
  logic [6:0]   ss_app_st_p1_rx_tuser_client;
  logic [4:0]   ss_app_st_p1_rx_tuser_sts;
  logic         p1_tx_pause = 1'b0;
  logic         p1_rx_pause;
  logic [7:0]   p1_tx_pfc = 8'b0;
  logic [7:0]   p1_rx_pfc;
  logic         p1_tx_lanes_stable;
  logic         p1_rx_pcs_ready;
  logic         p1_tx_pll_locked;
  logic         p1_tx_rst_n;
  logic         p1_rx_rst_n;
  logic         p1_rx_rst_ack_n;
  logic         p1_tx_rst_ack_n;
  logic         p1_ereset_n;
  logic         p1_clk_pll;
  logic         p1_clk_tx_div;
  logic         p1_clk_rec_div64;
  logic         p1_clk_rec_div;
  logic         p1_reconfig_clk;
  wire          app_ss_st_p1_tx_clk = p1_clk_pll;
  wire          app_ss_st_p1_rx_clk = p1_clk_pll;
  
  // Port-2
  logic         app_ss_st_p2_tx_areset_n;
  logic         app_ss_st_p2_tx_tvalid;
  logic         ss_app_st_p2_tx_tready;
  logic [ETH_PACKET_WIDTH-1:0] app_ss_st_p2_tx_tdata;
  logic [ETH_TKEEP_WIDTH-1:0]  app_ss_st_p2_tx_tkeep;
  logic         app_ss_st_p2_tx_tlast;
  logic [1:0]   app_ss_st_p2_tx_tuser_client;
  logic         app_ss_st_p2_rx_areset_n;
  logic         ss_app_st_p2_rx_tvalid;
  logic [ETH_PACKET_WIDTH-1:0] ss_app_st_p2_rx_tdata;
  logic [ETH_TKEEP_WIDTH-1:0]  ss_app_st_p2_rx_tkeep;
  logic         ss_app_st_p2_rx_tlast;
  logic [6:0]   ss_app_st_p2_rx_tuser_client;
  logic [4:0]   ss_app_st_p2_rx_tuser_sts;
  logic         p2_tx_pause = 1'b0;
  logic         p2_rx_pause;
  logic [7:0]   p2_tx_pfc = 8'b0;
  logic [7:0]   p2_rx_pfc;
  logic         p2_tx_lanes_stable;
  logic         p2_rx_pcs_ready;
  logic         p2_tx_pll_locked;
  logic         p2_tx_rst_n;
  logic         p2_rx_rst_n;
  logic         p2_rx_rst_ack_n;
  logic         p2_tx_rst_ack_n;
  logic         p2_ereset_n;
  logic         p2_clk_pll;
  logic         p2_clk_tx_div;
  logic         p2_clk_rec_div64;
  logic         p2_clk_rec_div;
  logic         p2_reconfig_clk;
  wire          app_ss_st_p2_tx_clk = p2_clk_pll;
  wire          app_ss_st_p2_rx_clk = p2_clk_pll;
  
  // Port-3
  logic         app_ss_st_p3_tx_areset_n;
  logic         app_ss_st_p3_tx_tvalid;
  logic         ss_app_st_p3_tx_tready;
  logic [ETH_PACKET_WIDTH-1:0] app_ss_st_p3_tx_tdata;
  logic [ETH_TKEEP_WIDTH-1:0]  app_ss_st_p3_tx_tkeep;
  logic         app_ss_st_p3_tx_tlast;
  logic [1:0]   app_ss_st_p3_tx_tuser_client;
  logic         app_ss_st_p3_rx_areset_n;
  logic         ss_app_st_p3_rx_tvalid;
  logic [ETH_PACKET_WIDTH-1:0] ss_app_st_p3_rx_tdata;
  logic [ETH_TKEEP_WIDTH-1:0]  ss_app_st_p3_rx_tkeep;
  logic         ss_app_st_p3_rx_tlast;
  logic [6:0]   ss_app_st_p3_rx_tuser_client;
  logic [4:0]   ss_app_st_p3_rx_tuser_sts;
  logic         p3_tx_pause = 1'b0;
  logic         p3_rx_pause;
  logic [7:0]   p3_tx_pfc = 8'b0;
  logic [7:0]   p3_rx_pfc;
  logic         p3_tx_lanes_stable;
  logic         p3_rx_pcs_ready;
  logic         p3_tx_pll_locked;
  logic         p3_tx_rst_n;
  logic         p3_rx_rst_n;
  logic         p3_rx_rst_ack_n;
  logic         p3_tx_rst_ack_n;
  logic         p3_ereset_n;
  logic         p3_clk_pll;
  logic         p3_clk_tx_div;
  logic         p3_clk_rec_div64;
  logic         p3_clk_rec_div;
  logic         p3_reconfig_clk;
  wire          app_ss_st_p3_tx_clk = p3_clk_pll;
  wire          app_ss_st_p3_rx_clk = p3_clk_pll;
  
  // Port-4
  logic         app_ss_st_p4_tx_areset_n;
  logic         app_ss_st_p4_tx_tvalid;
  logic         ss_app_st_p4_tx_tready;
  logic [ETH_PACKET_WIDTH-1:0] app_ss_st_p4_tx_tdata;
  logic [ETH_TKEEP_WIDTH-1:0]  app_ss_st_p4_tx_tkeep;
  logic         app_ss_st_p4_tx_tlast;
  logic [1:0]   app_ss_st_p4_tx_tuser_client;
  logic         app_ss_st_p4_rx_areset_n;
  logic         ss_app_st_p4_rx_tvalid;
  logic [ETH_PACKET_WIDTH-1:0] ss_app_st_p4_rx_tdata;
  logic [ETH_TKEEP_WIDTH-1:0]  ss_app_st_p4_rx_tkeep;
  logic         ss_app_st_p4_rx_tlast;
  logic [6:0]   ss_app_st_p4_rx_tuser_client;
  logic [4:0]   ss_app_st_p4_rx_tuser_sts;
  logic         p4_tx_pause = 1'b0;
  logic         p4_rx_pause;
  logic [7:0]   p4_tx_pfc = 8'b0;
  logic [7:0]   p4_rx_pfc;
  logic         p4_tx_lanes_stable;
  logic         p4_rx_pcs_ready;
  logic         p4_tx_pll_locked;
  logic         p4_tx_rst_n;
  logic         p4_rx_rst_n;
  logic         p4_rx_rst_ack_n;
  logic         p4_tx_rst_ack_n;
  logic         p4_ereset_n;
  logic         p4_clk_pll;
  logic         p4_clk_tx_div;
  logic         p4_clk_rec_div64;
  logic         p4_clk_rec_div;
  logic         p4_reconfig_clk;
  wire          app_ss_st_p4_tx_clk = p4_clk_pll;
  wire          app_ss_st_p4_rx_clk = p4_clk_pll;
  
  // Port-5
  logic         app_ss_st_p5_tx_areset_n;
  logic         app_ss_st_p5_tx_tvalid;
  logic         ss_app_st_p5_tx_tready;
  logic [ETH_PACKET_WIDTH-1:0] app_ss_st_p5_tx_tdata;
  logic [ETH_TKEEP_WIDTH-1:0]  app_ss_st_p5_tx_tkeep;
  logic         app_ss_st_p5_tx_tlast;
  logic [1:0]   app_ss_st_p5_tx_tuser_client;
  logic         app_ss_st_p5_rx_areset_n;
  logic         ss_app_st_p5_rx_tvalid;
  logic [ETH_PACKET_WIDTH-1:0] ss_app_st_p5_rx_tdata;
  logic [ETH_TKEEP_WIDTH-1:0]  ss_app_st_p5_rx_tkeep;
  logic         ss_app_st_p5_rx_tlast;
  logic [6:0]   ss_app_st_p5_rx_tuser_client;
  logic [4:0]   ss_app_st_p5_rx_tuser_sts;
  logic         p5_tx_pause = 1'b0;
  logic         p5_rx_pause;
  logic [7:0]   p5_tx_pfc = 8'b0;
  logic [7:0]   p5_rx_pfc;
  logic         p5_tx_lanes_stable;
  logic         p5_rx_pcs_ready;
  logic         p5_tx_pll_locked;
  logic         p5_tx_rst_n;
  logic         p5_rx_rst_n;
  logic         p5_rx_rst_ack_n;
  logic         p5_tx_rst_ack_n;
  logic         p5_ereset_n;
  logic         p5_clk_pll;
  logic         p5_clk_tx_div;
  logic         p5_clk_rec_div64;
  logic         p5_clk_rec_div;
  logic         p5_reconfig_clk;
  wire          app_ss_st_p5_tx_clk = p5_clk_pll;
  wire          app_ss_st_p5_rx_clk = p5_clk_pll;
   
  // Port-6
  logic         app_ss_st_p6_tx_areset_n;
  logic         app_ss_st_p6_tx_tvalid;
  logic         ss_app_st_p6_tx_tready;
  logic [ETH_PACKET_WIDTH-1:0] app_ss_st_p6_tx_tdata;
  logic [ETH_TKEEP_WIDTH-1:0]  app_ss_st_p6_tx_tkeep;
  logic         app_ss_st_p6_tx_tlast;
  logic [1:0]   app_ss_st_p6_tx_tuser_client;
  logic         app_ss_st_p6_rx_areset_n;
  logic         ss_app_st_p6_rx_tvalid;
  logic [ETH_PACKET_WIDTH-1:0] ss_app_st_p6_rx_tdata;
  logic [ETH_TKEEP_WIDTH-1:0]  ss_app_st_p6_rx_tkeep;
  logic         ss_app_st_p6_rx_tlast;
  logic [6:0]   ss_app_st_p6_rx_tuser_client;
  logic [4:0]   ss_app_st_p6_rx_tuser_sts;
  logic         p6_tx_pause = 1'b0;
  logic         p6_rx_pause;
  logic [7:0]   p6_tx_pfc = 8'b0;
  logic [7:0]   p6_rx_pfc;
  logic         p6_tx_lanes_stable;
  logic         p6_rx_pcs_ready;
  logic         p6_tx_pll_locked;
  logic         p6_tx_rst_n;
  logic         p6_rx_rst_n;
  logic         p6_rx_rst_ack_n;
  logic         p6_tx_rst_ack_n;
  logic         p6_ereset_n;
  logic         p6_clk_pll;
  logic         p6_clk_tx_div;
  logic         p6_clk_rec_div64;
  logic         p6_clk_rec_div;
  logic         p6_reconfig_clk;
  wire          app_ss_st_p6_tx_clk = p6_clk_pll;
  wire          app_ss_st_p6_rx_clk = p6_clk_pll;
   
  // Port-7
  logic         app_ss_st_p7_tx_areset_n;
  logic         app_ss_st_p7_tx_tvalid;
  logic         ss_app_st_p7_tx_tready;
  logic [ETH_PACKET_WIDTH-1:0] app_ss_st_p7_tx_tdata;
  logic [ETH_TKEEP_WIDTH-1:0]  app_ss_st_p7_tx_tkeep;
  logic         app_ss_st_p7_tx_tlast;
  logic [1:0]   app_ss_st_p7_tx_tuser_client;
  logic         app_ss_st_p7_rx_areset_n;
  logic         ss_app_st_p7_rx_tvalid;
  logic [ETH_PACKET_WIDTH-1:0] ss_app_st_p7_rx_tdata;
  logic [ETH_TKEEP_WIDTH-1:0]  ss_app_st_p7_rx_tkeep;
  logic         ss_app_st_p7_rx_tlast;
  logic [6:0]   ss_app_st_p7_rx_tuser_client;
  logic [4:0]   ss_app_st_p7_rx_tuser_sts;
  logic         p7_tx_pause = 1'b0;
  logic         p7_rx_pause;
  logic [7:0]   p7_tx_pfc = 8'b0;
  logic [7:0]   p7_rx_pfc;
  logic         p7_tx_lanes_stable;
  logic         p7_rx_pcs_ready;
  logic         p7_tx_pll_locked;
  logic         p7_tx_rst_n;
  logic         p7_rx_rst_n;
  logic         p7_rx_rst_ack_n;
  logic         p7_tx_rst_ack_n;
  logic         p7_ereset_n;
  logic         p7_clk_pll;
  logic         p7_clk_tx_div;
  logic         p7_clk_rec_div64;
  logic         p7_clk_rec_div;
  logic         p7_reconfig_clk;
  wire          app_ss_st_p7_tx_clk = p7_clk_pll;
  wire          app_ss_st_p7_rx_clk = p7_clk_pll;

  logic [31:0]  app_ss_lite_awaddr;
  logic [2:0]   app_ss_lite_awprot;
  logic         app_ss_lite_awvalid;
  logic         ss_app_lite_awready;
  logic [31:0]  app_ss_lite_wdata;
  logic [3:0]   app_ss_lite_wstrb;
  logic         app_ss_lite_wvalid;
  logic         ss_app_lite_wready;
  logic [1:0]   ss_app_lite_bresp;
  logic         ss_app_lite_bvalid;
  logic         app_ss_lite_bready;
  logic [31:0]  app_ss_lite_araddr;
  logic [2:0]   app_ss_lite_arprot;
  logic         app_ss_lite_arvalid;
  logic         ss_app_lite_arready;
  logic [31:0]  ss_app_lite_rdata;
  logic         ss_app_lite_rvalid;
  logic         app_ss_lite_rready;
  logic [1:0]   ss_app_lite_rresp;

  //--------------------------------------------------------------------------------
  // TB components
  //--------------------------------------------------------------------------------

  //----------------------------------------
  // Clock & Reset
  //----------------------------------------

  always begin
    #5000 app_ss_lite_clk = ~app_ss_lite_clk;
  end
  
  always begin
    #4375 clk_ptp_sample  = ~clk_ptp_sample;
  end


   initial begin
      app_ss_lite_areset_n     = 0;
      
      p0_tx_rst_n              = 1'b0;
      p0_rx_rst_n              = 1'b0;
      app_ss_st_p0_tx_areset_n = 1'b0;
      app_ss_st_p0_rx_areset_n = 1'b0;
      
      p1_tx_rst_n              = 1'b0;
      p1_rx_rst_n              = 1'b0;
      app_ss_st_p1_tx_areset_n = 1'b0;
      app_ss_st_p1_rx_areset_n = 1'b0;
      
      p2_tx_rst_n              = 1'b0;
      p2_rx_rst_n              = 1'b0;
      app_ss_st_p2_tx_areset_n = 1'b0;
      app_ss_st_p2_rx_areset_n = 1'b0;
      
      p3_tx_rst_n              = 1'b0;
      p3_rx_rst_n              = 1'b0;
      app_ss_st_p3_tx_areset_n = 1'b0;
      app_ss_st_p3_rx_areset_n = 1'b0;

      p4_tx_rst_n              = 1'b0;
      p4_rx_rst_n              = 1'b0;
      app_ss_st_p4_tx_areset_n = 1'b0;
      app_ss_st_p4_rx_areset_n = 1'b0;
      
      p5_tx_rst_n              = 1'b0;
      p5_rx_rst_n              = 1'b0;
      app_ss_st_p5_tx_areset_n = 1'b0;
      app_ss_st_p5_rx_areset_n = 1'b0;
      
      p6_tx_rst_n              = 1'b0;
      p6_rx_rst_n              = 1'b0;
      app_ss_st_p6_tx_areset_n = 1'b0;
      app_ss_st_p6_rx_areset_n = 1'b0;
      
      p7_tx_rst_n              = 1'b0;
      p7_rx_rst_n              = 1'b0;
      app_ss_st_p7_tx_areset_n = 1'b0;
      app_ss_st_p7_rx_areset_n = 1'b0;
      
      subsystem_cold_rst_n = 0;
      $display("TBINFO:%t	Subsystem cold reset is asserted",$time);
      $display("TBINFO:%t	Waiting for subsystem cold reset assertion acknowledgment",$time);
      wait(!subsystem_cold_rst_ack_n);
      $display("TBINFO:%t	Subsystem cold reset assertion acknowledged",$time);

      subsystem_cold_rst_n = 1;
      $display("TBINFO:%t	Subsystem cold reset is deasserted",$time);
   `ifdef INCLUDE_HSSI_PORT_0
      wait(!p0_tx_rst_ack_n);
      $display("TBINFO:%t	Port %0d Tx reset assertion acknowledged",$time,0);
      wait(!p0_rx_rst_ack_n);
      $display("TBINFO:%t	Port %0d Rx reset assertion acknowledged",$time,0);
   `endif
   `ifdef INCLUDE_HSSI_PORT_1
      wait(!p1_tx_rst_ack_n);
      $display("TBINFO:%t	Port %0d Tx reset assertion acknowledged",$time,1);
      wait(!p1_rx_rst_ack_n);
      $display("TBINFO:%t	Port %0d Rx reset assertion acknowledged",$time,1);
   `endif
   `ifdef INCLUDE_HSSI_PORT_2
      wait(!p2_tx_rst_ack_n);
      $display("TBINFO:%t	Port %0d Tx reset assertion acknowledged",$time,2);
      wait(!p2_rx_rst_ack_n);
      $display("TBINFO:%t	Port %0d Rx reset assertion acknowledged",$time,2);
   `endif
   `ifdef INCLUDE_HSSI_PORT_3
      wait(!p3_tx_rst_ack_n);
      $display("TBINFO:%t	Port %0d Tx reset assertion acknowledged",$time,3);
      wait(!p3_rx_rst_ack_n);
      $display("TBINFO:%t	Port %0d Rx reset assertion acknowledged",$time,3);
   `endif
   `ifdef INCLUDE_HSSI_PORT_4
      wait(!p4_tx_rst_ack_n);
      $display("TBINFO:%t	Port %0d Tx reset assertion acknowledged",$time,4);
      wait(!p4_rx_rst_ack_n);
      $display("TBINFO:%t	Port %0d Rx reset assertion acknowledged",$time,4);
   `endif
   `ifdef INCLUDE_HSSI_PORT_5
      wait(!p5_tx_rst_ack_n);
      $display("TBINFO:%t	Port %0d Tx reset assertion acknowledged",$time,5);
      wait(!p5_rx_rst_ack_n);
      $display("TBINFO:%t	Port %0d Rx reset assertion acknowledged",$time,5);
   `endif
   `ifdef INCLUDE_HSSI_PORT_6
      wait(!p6_tx_rst_ack_n);
      $display("TBINFO:%t	Port %0d Tx reset assertion acknowledged",$time,6);
      wait(!p6_rx_rst_ack_n);
      $display("TBINFO:%t	Port %0d Rx reset assertion acknowledged",$time,6);
   `endif
   `ifdef INCLUDE_HSSI_PORT_7
      wait(!p7_tx_rst_ack_n);
      $display("TBINFO:%t	Port %0d Tx reset assertion acknowledged",$time,7);
      wait(!p7_rx_rst_ack_n);
      $display("TBINFO:%t	Port %0d Rx reset assertion acknowledged",$time,7);
   `endif

   `ifdef INCLUDE_HSSI_PORT_0
      $display("TBINFO:%t	Port %0d - Waiting for Tx PLL Lock",$time,0);
      wait (p0_tx_pll_locked === 1'b1);
      $display("TBINFO:%t	Port %0d - Asserted Tx PLL Lock",$time,0);
   `endif
   `ifdef INCLUDE_HSSI_PORT_1
      $display("TBINFO:%t	Port %0d - Waiting for Tx PLL Lock",$time,1);
      wait (p1_tx_pll_locked === 1'b1);
      $display("TBINFO:%t	Port %0d - Asserted Tx PLL Lock",$time,1);
   `endif
   `ifdef INCLUDE_HSSI_PORT_2
     $display("TBINFO:%t	Port %0d - Waiting for Tx PLL Lock",$time,2);
      wait (p2_tx_pll_locked === 1'b1);
      $display("TBINFO:%t	Port %0d - Asserted Tx PLL Lock",$time,2);
   `endif
   `ifdef INCLUDE_HSSI_PORT_3
      $display("TBINFO:%t	Port %0d - Waiting for Tx PLL Lock",$time,3);
      wait (p3_tx_pll_locked === 1'b1);
      $display("TBINFO:%t	Port %0d - Asserted Tx PLL Lock",$time,3);
   `endif
   `ifdef INCLUDE_HSSI_PORT_4
      $display("TBINFO:%t	Port %0d - Waiting for Tx PLL Lock",$time,4);
      wait (p4_tx_pll_locked === 1'b1);
      $display("TBINFO:%t	Port %0d - Asserted Tx PLL Lock",$time,4);
   `endif
   `ifdef INCLUDE_HSSI_PORT_5
      $display("TBINFO:%t	Port %0d - Waiting for Tx PLL Lock",$time,5);
      wait (p5_tx_pll_locked === 1'b1);
      $display("TBINFO:%t	Port %0d - Asserted Tx PLL Lock",$time,5);
   `endif
   `ifdef INCLUDE_HSSI_PORT_6
      $display("TBINFO:%t	Port %0d - Waiting for Tx PLL Lock",$time,6);
      wait (p6_tx_pll_locked === 1'b1);
      $display("TBINFO:%t	Port %0d - Asserted Tx PLL Lock",$time,6);
   `endif
   `ifdef INCLUDE_HSSI_PORT_7
      $display("TBINFO:%t	Port %0d - Waiting for Tx PLL Lock",$time,7);
      wait (p7_tx_pll_locked === 1'b1);
      $display("TBINFO:%t	Port %0d - Asserted Tx PLL Lock",$time,7);
   `endif
      //subsystem_cold_rst_n = 1;
      //app_ss_lite_areset_n = 0;
      #500;
      app_ss_lite_areset_n = 1;
      `ifdef INCLUDE_HSSI_PORT_0
      @(posedge p0_clk_pll);
      p0_tx_rst_n = 1'b1;
      @(posedge p0_clk_pll);
      p0_rx_rst_n = 1'b1;
      @(posedge app_ss_st_p0_rx_clk);
      app_ss_st_p0_rx_areset_n = 1'b1;
      @(posedge app_ss_st_p0_tx_clk);
      app_ss_st_p0_tx_areset_n = 1'b1;
      `endif
      `ifdef INCLUDE_HSSI_PORT_1
      @(posedge p1_clk_pll);
      p1_tx_rst_n = 1'b1;
      @(posedge p1_clk_pll);
      p1_rx_rst_n = 1'b1;
      @(posedge app_ss_st_p1_rx_clk);
      app_ss_st_p1_rx_areset_n = 1'b1;
      @(posedge app_ss_st_p1_tx_clk);
      app_ss_st_p1_tx_areset_n = 1'b1;
      `endif
      `ifdef INCLUDE_HSSI_PORT_2
      @(posedge p2_clk_pll);
      p2_tx_rst_n = 1'b1;
      @(posedge p2_clk_pll);
      p2_rx_rst_n = 1'b1;
      @(posedge app_ss_st_p2_rx_clk);
      app_ss_st_p2_rx_areset_n = 1'b1;
      @(posedge app_ss_st_p2_tx_clk);
      app_ss_st_p2_tx_areset_n = 1'b1;
      `endif
      `ifdef INCLUDE_HSSI_PORT_3
      @(posedge p3_clk_pll);
      p3_tx_rst_n = 1'b1;
      @(posedge p3_clk_pll);
      p3_rx_rst_n = 1'b1;
      @(posedge app_ss_st_p3_rx_clk);
      app_ss_st_p3_rx_areset_n = 1'b1;
      @(posedge app_ss_st_p3_tx_clk);
      app_ss_st_p3_tx_areset_n = 1'b1;
      `endif
      `ifdef INCLUDE_HSSI_PORT_4
      @(posedge p4_clk_pll);
      p4_tx_rst_n = 1'b1;
      @(posedge p4_clk_pll);
      p4_rx_rst_n = 1'b1;
      @(posedge app_ss_st_p4_rx_clk);
      app_ss_st_p4_rx_areset_n = 1'b1;
      @(posedge app_ss_st_p4_tx_clk);
      app_ss_st_p4_tx_areset_n = 1'b1;
      `endif
      `ifdef INCLUDE_HSSI_PORT_5
      @(posedge p5_clk_pll);
      p5_tx_rst_n = 1'b1;
      @(posedge p5_clk_pll);
      p5_rx_rst_n = 1'b1;
      @(posedge app_ss_st_p5_rx_clk);
      app_ss_st_p5_rx_areset_n = 1'b1;
      @(posedge app_ss_st_p5_tx_clk);
      app_ss_st_p5_tx_areset_n = 1'b1;
      `endif
      `ifdef INCLUDE_HSSI_PORT_6
      @(posedge p6_clk_pll);
      p6_tx_rst_n = 1'b1;
      @(posedge p6_clk_pll);
      p6_rx_rst_n = 1'b1;
      @(posedge app_ss_st_p6_rx_clk);
      app_ss_st_p6_rx_areset_n = 1'b1;
      @(posedge app_ss_st_p6_tx_clk);
      app_ss_st_p6_tx_areset_n = 1'b1;
      `endif
      `ifdef INCLUDE_HSSI_PORT_7
      @(posedge p7_clk_pll);
      p7_tx_rst_n = 1'b1;
      @(posedge p7_clk_pll);
      p7_rx_rst_n = 1'b1;
      @(posedge app_ss_st_p7_rx_clk);
      app_ss_st_p7_rx_areset_n = 1'b1;
      @(posedge app_ss_st_p7_tx_clk);
      app_ss_st_p7_tx_areset_n = 1'b1;
      `endif

   `ifdef INCLUDE_HSSI_PORT_0
      wait(p0_tx_rst_ack_n);
      $display("TBINFO:%t	Port %0d Tx reset deassertion acknowledged",$time,0);
      wait(p0_rx_rst_ack_n);
      $display("TBINFO:%t	Port %0d Rx reset deassertion acknowledged",$time,0);
   `endif
   `ifdef INCLUDE_HSSI_PORT_1
      wait(p1_tx_rst_ack_n);
      $display("TBINFO:%t	Port %0d Tx reset deassertion acknowledged",$time,1);
      wait(p1_rx_rst_ack_n);
      $display("TBINFO:%t	Port %0d Rx reset deassertion acknowledged",$time,1);
   `endif
   `ifdef INCLUDE_HSSI_PORT_2
      wait(p2_tx_rst_ack_n);
      $display("TBINFO:%t	Port %0d Tx reset deassertion acknowledged",$time,2);
      wait(p2_rx_rst_ack_n);
      $display("TBINFO:%t	Port %0d Rx reset deassertion acknowledged",$time,2);
   `endif
   `ifdef INCLUDE_HSSI_PORT_3
      wait(p3_tx_rst_ack_n);
      $display("TBINFO:%t	Port %0d Tx reset deassertion acknowledged",$time,3);
      wait(p3_rx_rst_ack_n);
      $display("TBINFO:%t	Port %0d Rx reset deassertion acknowledged",$time,3);
   `endif
   `ifdef INCLUDE_HSSI_PORT_4
      wait(p4_tx_rst_ack_n);
      $display("TBINFO:%t	Port %0d Tx reset deassertion acknowledged",$time,4);
      wait(p4_rx_rst_ack_n);
      $display("TBINFO:%t	Port %0d Rx reset deassertion acknowledged",$time,4);
   `endif
   `ifdef INCLUDE_HSSI_PORT_5
      wait(p5_tx_rst_ack_n);
      $display("TBINFO:%t	Port %0d Tx reset deassertion acknowledged",$time,5);
      wait(p5_rx_rst_ack_n);
      $display("TBINFO:%t	Port %0d Rx reset deassertion acknowledged",$time,5);
   `endif
   `ifdef INCLUDE_HSSI_PORT_6
      wait(p6_tx_rst_ack_n);
      $display("TBINFO:%t	Port %0d Tx reset deassertion acknowledged",$time,6);
      wait(p6_rx_rst_ack_n);
      $display("TBINFO:%t	Port %0d Rx reset deassertion acknowledged",$time,6);
   `endif
   `ifdef INCLUDE_HSSI_PORT_7
      wait(p7_tx_rst_ack_n);
      $display("TBINFO:%t	Port %0d Tx reset deassertion acknowledged",$time,7);
      wait(p7_rx_rst_ack_n);
      $display("TBINFO:%t	Port %0d Rx reset deassertion acknowledged",$time,7);
   `endif

      $display("TBINFO:%t	Waiting for subsystem cold reset deassertion acknowledgment",$time);
      wait(subsystem_cold_rst_ack_n);
      $display("TBINFO:%t	Subsystem cold reset deassertion acknowledged",$time);
    
      //#100000;
      $display("TBINFO:%t	Reset Sequence Complete",$time);
      reset_done=1;
  end

  //----------------------------------------
  // BFM
  //----------------------------------------

   `ifdef ETH_10G
      hssi_ss_16x10g hssi_ss (
    `elsif ETH_100G
      hssi_ss_4x100g hssi_ss (
    `else
      hssi_ss_8x25g_cvl hssi_ss (
   `endif 
   .app_ss_lite_clk                    (app_ss_lite_clk),
   .app_ss_lite_areset_n               (app_ss_lite_areset_n),
   .app_ss_lite_awaddr                 (app_ss_lite_awaddr[25:0]),
   .app_ss_lite_awprot                 (app_ss_lite_awprot),
   .app_ss_lite_awvalid                (app_ss_lite_awvalid),
   .ss_app_lite_awready                (ss_app_lite_awready),
   .app_ss_lite_wdata                  (app_ss_lite_wdata),
   .app_ss_lite_wstrb                  (app_ss_lite_wstrb),
   .app_ss_lite_wvalid                 (app_ss_lite_wvalid),
   .ss_app_lite_wready                 (ss_app_lite_wready),
   .ss_app_lite_bresp                  (ss_app_lite_bresp),
   .ss_app_lite_bvalid                 (ss_app_lite_bvalid),
   .app_ss_lite_bready                 (app_ss_lite_bready),
   .app_ss_lite_araddr                 (app_ss_lite_araddr[25:0]),
   .app_ss_lite_arprot                 (app_ss_lite_arprot),
   .app_ss_lite_arvalid                (app_ss_lite_arvalid),
   .ss_app_lite_arready                (ss_app_lite_arready),
   .ss_app_lite_rdata                  (ss_app_lite_rdata),
   .ss_app_lite_rvalid                 (ss_app_lite_rvalid),
   .app_ss_lite_rready                 (app_ss_lite_rready),
   .ss_app_lite_rresp                  (ss_app_lite_rresp),
`ifdef INCLUDE_HSSI_PORT_8
   .p8_app_ss_st_tx_clk                ( app_ss_st_p0_tx_clk ),
   .p8_app_ss_st_tx_areset_n           ( app_ss_st_p0_tx_areset_n ),
   .p8_app_ss_st_rx_clk                ( app_ss_st_p0_rx_clk ),
   .p8_app_ss_st_rx_areset_n           ( app_ss_st_p0_rx_areset_n ),
   `ifdef ETH_100G
   .p8_rx_serial                       ( serial_loop_tx[3:0] ),
   .p8_tx_serial                       ( serial_loop_tx[3:0] ),
   `else
   .p8_rx_serial                       ( serial_loop_tx[0] ),
   .p8_tx_serial                       ( serial_loop_tx[0] ),
   `endif
   .i_p8_tx_rst_n                      ( p0_tx_rst_n ),
   .i_p8_rx_rst_n                      ( p0_rx_rst_n ),
`endif
`ifdef INCLUDE_HSSI_PORT_9
   .p9_app_ss_st_tx_clk                ( app_ss_st_p1_tx_clk ),
   .p9_app_ss_st_tx_areset_n           ( app_ss_st_p1_tx_areset_n ),
   .p9_app_ss_st_rx_clk                ( app_ss_st_p1_rx_clk ),
   .p9_app_ss_st_rx_areset_n           ( app_ss_st_p1_rx_areset_n ),
   .p9_tx_serial                       ( serial_loop_tx[1] ),
   .p9_rx_serial                       ( serial_loop_tx[1] ),
   .i_p9_tx_rst_n                      ( p1_tx_rst_n ),
   .i_p9_rx_rst_n                      ( p1_rx_rst_n ),
`endif
`ifdef INCLUDE_HSSI_PORT_10
   .p10_app_ss_st_tx_clk                ( app_ss_st_p2_tx_clk ),
   .p10_app_ss_st_tx_areset_n           ( app_ss_st_p2_tx_areset_n ),
   .p10_app_ss_st_rx_clk                ( app_ss_st_p2_rx_clk ),
   .p10_app_ss_st_rx_areset_n           ( app_ss_st_p2_rx_areset_n ),
   .p10_tx_serial                       ( serial_loop_tx[2] ),
   .p10_rx_serial                       ( serial_loop_tx[2] ),
   .i_p10_tx_rst_n                      ( p2_tx_rst_n ),
   .i_p10_rx_rst_n                      ( p2_rx_rst_n ),
`endif
`ifdef INCLUDE_HSSI_PORT_11
   .p11_app_ss_st_tx_clk                ( app_ss_st_p3_tx_clk ),
   .p11_app_ss_st_tx_areset_n           ( app_ss_st_p3_tx_areset_n ),
   .p11_app_ss_st_rx_clk                ( app_ss_st_p3_rx_clk ),
   .p11_app_ss_st_rx_areset_n           ( app_ss_st_p3_rx_areset_n ),
   .p11_tx_serial                       ( serial_loop_tx[3] ),
   .p11_rx_serial                       ( serial_loop_tx[3] ),
   .i_p11_tx_rst_n                      ( p3_tx_rst_n ),
   .i_p11_rx_rst_n                      ( p3_rx_rst_n ),
`endif
`ifdef INCLUDE_HSSI_PORT_12
   .p12_app_ss_st_tx_clk                ( app_ss_st_p4_tx_clk ),
   .p12_app_ss_st_tx_areset_n           ( app_ss_st_p4_tx_areset_n ),
   .p12_app_ss_st_rx_clk                ( app_ss_st_p4_rx_clk ),
   .p12_app_ss_st_rx_areset_n           ( app_ss_st_p4_rx_areset_n ),
   `ifdef ETH_100G
   .p12_tx_serial                       ( serial_loop_tx[7:4] ),
   .p12_rx_serial                       ( serial_loop_tx[7:4] ),
   `else
   .p12_rx_serial                       ( serial_loop_tx[4] ),
   .p12_tx_serial                       ( serial_loop_tx[4] ),
   `endif
   .i_p12_tx_rst_n                      ( p4_tx_rst_n ),
   .i_p12_rx_rst_n                      ( p4_rx_rst_n ),
`endif
`ifdef INCLUDE_HSSI_PORT_13
   .p13_app_ss_st_tx_clk                ( app_ss_st_p5_tx_clk ),
   .p13_app_ss_st_tx_areset_n           ( app_ss_st_p5_tx_areset_n ),
   .p13_app_ss_st_rx_clk                ( app_ss_st_p5_rx_clk ),
   .p13_app_ss_st_rx_areset_n           ( app_ss_st_p5_rx_areset_n ),
   .p13_tx_serial                       ( serial_loop_tx[5] ),
   .p13_rx_serial                       ( serial_loop_tx[5] ),
   .i_p13_tx_rst_n                      ( p5_tx_rst_n ),
   .i_p13_rx_rst_n                      ( p5_rx_rst_n ),
`endif
`ifdef INCLUDE_HSSI_PORT_14
   .p14_app_ss_st_tx_clk                ( app_ss_st_p6_tx_clk ),
   .p14_app_ss_st_tx_areset_n           ( app_ss_st_p6_tx_areset_n ),
   .p14_app_ss_st_rx_clk                ( app_ss_st_p6_rx_clk ),
   .p14_app_ss_st_rx_areset_n           ( app_ss_st_p6_rx_areset_n ),
   .p14_tx_serial                       ( serial_loop_tx[6] ),
   .p14_rx_serial                       ( serial_loop_tx[6] ),
   .i_p14_tx_rst_n                      ( p6_tx_rst_n ),
   .i_p14_rx_rst_n                      ( p6_rx_rst_n ),
`endif
`ifdef INCLUDE_HSSI_PORT_15
   .p15_app_ss_st_tx_clk                ( app_ss_st_p7_tx_clk ),
   .p15_app_ss_st_tx_areset_n           ( app_ss_st_p7_tx_areset_n ),
   .p15_app_ss_st_rx_clk                ( app_ss_st_p7_rx_clk ),
   .p15_app_ss_st_rx_areset_n           ( app_ss_st_p7_rx_areset_n ),
   .p15_tx_serial                       ( serial_loop_tx[7] ),
   .p15_rx_serial                       ( serial_loop_tx[7] ),
   .i_p15_tx_rst_n                      ( p7_tx_rst_n ),
   .i_p15_rx_rst_n                      ( p7_rx_rst_n ),
`endif
`ifdef INCLUDE_HSSI_PORT_0
   .p0_app_ss_st_tx_clk                ( app_ss_st_p0_tx_clk ),
   .p0_app_ss_st_tx_areset_n           ( app_ss_st_p0_tx_areset_n ),
   .p0_app_ss_st_tx_tvalid             ( app_ss_st_p0_tx_tvalid ),
   .p0_ss_app_st_tx_tready             ( ss_app_st_p0_tx_tready ),
   .p0_app_ss_st_tx_tdata              ( app_ss_st_p0_tx_tdata ),
   .p0_app_ss_st_tx_tkeep              ( app_ss_st_p0_tx_tkeep ),
   .p0_app_ss_st_tx_tlast              ( app_ss_st_p0_tx_tlast ),
   .p0_app_ss_st_tx_tuser_client       ( app_ss_st_p0_tx_tuser_client ),
   `ifdef INCLUDE_HSSI_PORT_0_PTP
   .p0_app_ss_st_tx_tuser_ptp          ( 'h0 ),
   .p0_app_ss_st_tx_tuser_ptp_extended ( 'h0 ),
   `endif
   .p0_app_ss_st_rx_clk                ( app_ss_st_p0_rx_clk ),
   .p0_app_ss_st_rx_areset_n           ( app_ss_st_p0_rx_areset_n ),
   .p0_ss_app_st_rx_tvalid             ( ss_app_st_p0_rx_tvalid ),
   .p0_ss_app_st_rx_tdata              ( ss_app_st_p0_rx_tdata ),
   .p0_ss_app_st_rx_tkeep              ( ss_app_st_p0_rx_tkeep ),
   .p0_ss_app_st_rx_tlast              ( ss_app_st_p0_rx_tlast ),
   .p0_ss_app_st_rx_tuser_client       ( ss_app_st_p0_rx_tuser_client ),
   .p0_ss_app_st_rx_tuser_sts          ( ss_app_st_p0_rx_tuser_sts ),
   .i_p0_tx_pause                      ( p0_tx_pause ),
   .o_p0_rx_pause                      ( p0_rx_pause ),
   .i_p0_tx_pfc                        ( p0_tx_pfc ),
   .o_p0_rx_pfc                        ( p0_rx_pfc ),
   `ifdef ETH_100G
   .p0_tx_serial                       ( cvl_serial_tx_p[3:0] ),
   .p0_tx_serial_n                     ( ),
   .p0_rx_serial                       ( cvl_serial_rx_p[3:0] ),
   .p0_rx_serial_n                     ( 'h0 ),
   `else
   .p0_tx_serial                       ( cvl_serial_tx_p[0] ),
   .p0_tx_serial_n                     ( ),
   .p0_rx_serial                       ( cvl_serial_rx_p[0] ),
   .p0_rx_serial_n                     ( 'h0 ),
      `ifdef INCLUDE_HSSI_PORT_0_PTP
      .i_p0_clk_ptp_sample                ( clk_ptp_sample ),
      .i_p0_clk_tx_tod                    ( p0_clk_tx_div ),
      .i_p0_clk_rx_tod                    ( p0_clk_rec_div ),
      `endif
   `endif
   .p0_tx_lanes_stable                 ( p0_tx_lanes_stable ),
   .p0_rx_pcs_ready                    ( p0_rx_pcs_ready ),
   .o_p0_tx_pll_locked                 ( p0_tx_pll_locked ),
   .i_p0_tx_rst_n                      ( p0_tx_rst_n ),
   .i_p0_rx_rst_n                      ( p0_rx_rst_n ),
   .o_p0_rx_rst_ack_n                  ( p0_rx_rst_ack_n ),
   .o_p0_tx_rst_ack_n                  ( p0_tx_rst_ack_n ),
   .o_p0_ereset_n                      ( p0_ereset_n ),
   .o_p0_clk_pll                       ( p0_clk_pll ),
   .o_p0_clk_tx_div                    ( p0_clk_tx_div ),
   .o_p0_clk_rec_div64                 ( p0_clk_rec_div64 ),
   .o_p0_clk_rec_div                   ( p0_clk_rec_div ),
`endif
`ifdef INCLUDE_HSSI_PORT_1
   .p1_app_ss_st_tx_clk                ( app_ss_st_p1_tx_clk ),
   .p1_app_ss_st_tx_areset_n           ( app_ss_st_p1_tx_areset_n ),
   .p1_app_ss_st_tx_tvalid             ( app_ss_st_p1_tx_tvalid ),
   .p1_ss_app_st_tx_tready             ( ss_app_st_p1_tx_tready ),
   .p1_app_ss_st_tx_tdata              ( app_ss_st_p1_tx_tdata ),
   .p1_app_ss_st_tx_tkeep              ( app_ss_st_p1_tx_tkeep ),
   .p1_app_ss_st_tx_tlast              ( app_ss_st_p1_tx_tlast ),
   .p1_app_ss_st_tx_tuser_client       ( app_ss_st_p1_tx_tuser_client ),
   `ifdef INCLUDE_HSSI_PORT_1_PTP
   .p1_app_ss_st_tx_tuser_ptp          ( 'h0 ),
   .p1_app_ss_st_tx_tuser_ptp_extended ( 'h0 ),
   `endif
   .p1_app_ss_st_rx_clk                ( app_ss_st_p1_rx_clk ),
   .p1_app_ss_st_rx_areset_n           ( app_ss_st_p1_rx_areset_n ),
   .p1_ss_app_st_rx_tvalid             ( ss_app_st_p1_rx_tvalid ),
   .p1_ss_app_st_rx_tdata              ( ss_app_st_p1_rx_tdata ),
   .p1_ss_app_st_rx_tkeep              ( ss_app_st_p1_rx_tkeep ),
   .p1_ss_app_st_rx_tlast              ( ss_app_st_p1_rx_tlast ),
   .p1_ss_app_st_rx_tuser_client       ( ss_app_st_p1_rx_tuser_client ),
   .p1_ss_app_st_rx_tuser_sts          ( ss_app_st_p1_rx_tuser_sts ),
   .i_p1_tx_pause                      ( p1_tx_pause ),
   .o_p1_rx_pause                      ( p1_rx_pause ),
   .i_p1_tx_pfc                        ( p1_tx_pfc ),
   .o_p1_rx_pfc                        ( p1_rx_pfc ),
   .p1_tx_serial                       ( cvl_serial_tx_p[1] ),
   .p1_tx_serial_n                     ( ),
   .p1_rx_serial                       ( cvl_serial_rx_p[1] ),
   .p1_rx_serial_n                     ( 'h0 ),
   `ifdef INCLUDE_HSSI_PORT_1_PTP
   .i_p1_clk_tx_tod                    ( p1_clk_tx_div ),
   .i_p1_clk_rx_tod                    ( p1_clk_rec_div ),
   `endif
   .p1_tx_lanes_stable                 ( p1_tx_lanes_stable ),
   .p1_rx_pcs_ready                    ( p1_rx_pcs_ready ),
   .o_p1_tx_pll_locked                 ( p1_tx_pll_locked ),
   .i_p1_tx_rst_n                      ( p1_tx_rst_n ),
   .i_p1_rx_rst_n                      ( p1_rx_rst_n ),
   .o_p1_rx_rst_ack_n                  ( p1_rx_rst_ack_n ),
   .o_p1_tx_rst_ack_n                  ( p1_tx_rst_ack_n ),
   .o_p1_ereset_n                      ( p1_ereset_n ),
   .o_p1_clk_pll                       ( p1_clk_pll ),
   .o_p1_clk_tx_div                    ( p1_clk_tx_div ),
   .o_p1_clk_rec_div64                 ( p1_clk_rec_div64 ),
   .o_p1_clk_rec_div                   ( p1_clk_rec_div ),
`endif
`ifdef INCLUDE_HSSI_PORT_2
   .p2_app_ss_st_tx_clk                ( app_ss_st_p2_tx_clk ),
   .p2_app_ss_st_tx_areset_n           ( app_ss_st_p2_tx_areset_n ),
   .p2_app_ss_st_tx_tvalid             ( app_ss_st_p2_tx_tvalid ),
   .p2_ss_app_st_tx_tready             ( ss_app_st_p2_tx_tready ),
   .p2_app_ss_st_tx_tdata              ( app_ss_st_p2_tx_tdata ),
   .p2_app_ss_st_tx_tkeep              ( app_ss_st_p2_tx_tkeep ),
   .p2_app_ss_st_tx_tlast              ( app_ss_st_p2_tx_tlast ),
   .p2_app_ss_st_tx_tuser_client       ( app_ss_st_p2_tx_tuser_client ),
   `ifdef INCLUDE_HSSI_PORT_2_PTP
   .p2_app_ss_st_tx_tuser_ptp          ( 'h0 ),
   .p2_app_ss_st_tx_tuser_ptp_extended ( 'h0 ),
   `endif
   .p2_app_ss_st_rx_clk                ( app_ss_st_p2_rx_clk ),
   .p2_app_ss_st_rx_areset_n           ( app_ss_st_p2_rx_areset_n ),
   .p2_ss_app_st_rx_tvalid             ( ss_app_st_p2_rx_tvalid ),
   .p2_ss_app_st_rx_tdata              ( ss_app_st_p2_rx_tdata ),
   .p2_ss_app_st_rx_tkeep              ( ss_app_st_p2_rx_tkeep ),
   .p2_ss_app_st_rx_tlast              ( ss_app_st_p2_rx_tlast ),
   .p2_ss_app_st_rx_tuser_client       ( ss_app_st_p2_rx_tuser_client ),
   .p2_ss_app_st_rx_tuser_sts          ( ss_app_st_p2_rx_tuser_sts ),
   .i_p2_tx_pause                      ( p2_tx_pause ),
   .o_p2_rx_pause                      ( p2_rx_pause ),
   .i_p2_tx_pfc                        ( p2_tx_pfc ),
   .o_p2_rx_pfc                        ( p2_rx_pfc ),
   .p2_tx_serial                       ( cvl_serial_tx_p[2] ),
   .p2_tx_serial_n                     ( ),
   .p2_rx_serial                       ( cvl_serial_rx_p[2] ),
   .p2_rx_serial_n                     ( 'h0 ),
   `ifdef INCLUDE_HSSI_PORT_2_PTP
   .i_p2_clk_tx_tod                    ( p2_clk_tx_div ),
   .i_p2_clk_rx_tod                    ( p2_clk_rec_div ),
   `endif
   .p2_tx_lanes_stable                 ( p2_tx_lanes_stable ),
   .p2_rx_pcs_ready                    ( p2_rx_pcs_ready ),
   .o_p2_tx_pll_locked                 ( p2_tx_pll_locked ),
   .i_p2_tx_rst_n                      ( p2_tx_rst_n ),
   .i_p2_rx_rst_n                      ( p2_rx_rst_n ),
   .o_p2_rx_rst_ack_n                  ( p2_rx_rst_ack_n ),
   .o_p2_tx_rst_ack_n                  ( p2_tx_rst_ack_n ),
   .o_p2_ereset_n                      ( p2_ereset_n ),
   .o_p2_clk_pll                       ( p2_clk_pll ),
   .o_p2_clk_tx_div                    ( p2_clk_tx_div ),
   .o_p2_clk_rec_div64                 ( p2_clk_rec_div64 ),
   .o_p2_clk_rec_div                   ( p2_clk_rec_div ),
`endif
`ifdef INCLUDE_HSSI_PORT_3
   .p3_app_ss_st_tx_clk                ( app_ss_st_p3_tx_clk ),
   .p3_app_ss_st_tx_areset_n           ( app_ss_st_p3_tx_areset_n ),
   .p3_app_ss_st_tx_tvalid             ( app_ss_st_p3_tx_tvalid ),
   .p3_ss_app_st_tx_tready             ( ss_app_st_p3_tx_tready ),
   .p3_app_ss_st_tx_tdata              ( app_ss_st_p3_tx_tdata ),
   .p3_app_ss_st_tx_tkeep              ( app_ss_st_p3_tx_tkeep ),
   .p3_app_ss_st_tx_tlast              ( app_ss_st_p3_tx_tlast ),
   .p3_app_ss_st_tx_tuser_client       ( app_ss_st_p3_tx_tuser_client ),
   `ifdef INCLUDE_HSSI_PORT_3_PTP
   .p3_app_ss_st_tx_tuser_ptp          ( 'h0 ),
   .p3_app_ss_st_tx_tuser_ptp_extended ( 'h0 ),
   `endif
   .p3_app_ss_st_rx_clk                ( app_ss_st_p3_rx_clk ),
   .p3_app_ss_st_rx_areset_n           ( app_ss_st_p3_rx_areset_n ),
   .p3_ss_app_st_rx_tvalid             ( ss_app_st_p3_rx_tvalid ),
   .p3_ss_app_st_rx_tdata              ( ss_app_st_p3_rx_tdata ),
   .p3_ss_app_st_rx_tkeep              ( ss_app_st_p3_rx_tkeep ),
   .p3_ss_app_st_rx_tlast              ( ss_app_st_p3_rx_tlast ),
   .p3_ss_app_st_rx_tuser_client       ( ss_app_st_p3_rx_tuser_client ),
   .p3_ss_app_st_rx_tuser_sts          ( ss_app_st_p3_rx_tuser_sts ),
   .i_p3_tx_pause                      ( p3_tx_pause ),
   .o_p3_rx_pause                      ( p3_rx_pause ),
   .i_p3_tx_pfc                        ( p3_tx_pfc ),
   .o_p3_rx_pfc                        ( p3_rx_pfc ),
   .p3_tx_serial                       ( cvl_serial_tx_p[3] ),
   .p3_tx_serial_n                     ( ),
   .p3_rx_serial                       ( cvl_serial_rx_p[3] ),
   .p3_rx_serial_n                     ( 'h0 ),
   `ifdef INCLUDE_HSSI_PORT_3_PTP
   .i_p3_clk_tx_tod                    ( p3_clk_tx_div ),
   .i_p3_clk_rx_tod                    ( p3_clk_rec_div ),
   `endif
   .p3_tx_lanes_stable                 ( p3_tx_lanes_stable ),
   .p3_rx_pcs_ready                    ( p3_rx_pcs_ready ),
   .o_p3_tx_pll_locked                 ( p3_tx_pll_locked ),
   .i_p3_tx_rst_n                      ( p3_tx_rst_n ),
   .i_p3_rx_rst_n                      ( p3_rx_rst_n ),
   .o_p3_rx_rst_ack_n                  ( p3_rx_rst_ack_n ),
   .o_p3_tx_rst_ack_n                  ( p3_tx_rst_ack_n ),
   .o_p3_ereset_n                      ( p3_ereset_n ),
   .o_p3_clk_pll                       ( p3_clk_pll ),
   .o_p3_clk_tx_div                    ( p3_clk_tx_div ),
   .o_p3_clk_rec_div64                 ( p3_clk_rec_div64 ),
   .o_p3_clk_rec_div                   ( p3_clk_rec_div ),
`endif
`ifdef INCLUDE_HSSI_PORT_4
   .p4_app_ss_st_tx_clk                ( app_ss_st_p4_tx_clk ),
   .p4_app_ss_st_tx_areset_n           ( app_ss_st_p4_tx_areset_n ),
   .p4_app_ss_st_tx_tvalid             ( app_ss_st_p4_tx_tvalid ),
   .p4_ss_app_st_tx_tready             ( ss_app_st_p4_tx_tready ),
   .p4_app_ss_st_tx_tdata              ( app_ss_st_p4_tx_tdata ),
   .p4_app_ss_st_tx_tkeep              ( app_ss_st_p4_tx_tkeep ),
   .p4_app_ss_st_tx_tlast              ( app_ss_st_p4_tx_tlast ),
   .p4_app_ss_st_tx_tuser_client       ( app_ss_st_p4_tx_tuser_client ),
   `ifdef INCLUDE_HSSI_PORT_4_PTP
   .p4_app_ss_st_tx_tuser_ptp          ( 'h0 ),
   .p4_app_ss_st_tx_tuser_ptp_extended ( 'h0 ),
   `endif
   .p4_app_ss_st_rx_clk                ( app_ss_st_p4_rx_clk ),
   .p4_app_ss_st_rx_areset_n           ( app_ss_st_p4_rx_areset_n ),
   .p4_ss_app_st_rx_tvalid             ( ss_app_st_p4_rx_tvalid ),
   .p4_ss_app_st_rx_tdata              ( ss_app_st_p4_rx_tdata ),
   .p4_ss_app_st_rx_tkeep              ( ss_app_st_p4_rx_tkeep ),
   .p4_ss_app_st_rx_tlast              ( ss_app_st_p4_rx_tlast ),
   .p4_ss_app_st_rx_tuser_client       ( ss_app_st_p4_rx_tuser_client ),
   .p4_ss_app_st_rx_tuser_sts          ( ss_app_st_p4_rx_tuser_sts ),
   .i_p4_tx_pause                      ( p4_tx_pause ),
   .o_p4_rx_pause                      ( p4_rx_pause ),
   .i_p4_tx_pfc                        ( p4_tx_pfc ),
   .o_p4_rx_pfc                        ( p4_rx_pfc ),
   `ifdef ETH_100G
   .p4_tx_serial                       ( cvl_serial_tx_p[7:4] ),
   .p4_tx_serial_n                     ( ),
   .p4_rx_serial                       ( cvl_serial_rx_p[7:4] ),
   .p4_rx_serial_n                     ( 'h0 ),
   `else
   .p4_tx_serial                       ( cvl_serial_tx_p[4] ),
   .p4_tx_serial_n                     ( ),
   .p4_rx_serial                       ( cvl_serial_rx_p[4] ),
   .p4_rx_serial_n                     ( 'h0 ),
      `ifdef INCLUDE_HSSI_PORT_4_PTP
      .i_p4_clk_ptp_sample                ( clk_ptp_sample ),
      .i_p4_clk_tx_tod                    ( p4_clk_tx_div ),
      .i_p4_clk_rx_tod                    ( p4_clk_rec_div ),
      `endif
   `endif
   .p4_tx_lanes_stable                 ( p4_tx_lanes_stable ),
   .p4_rx_pcs_ready                    ( p4_rx_pcs_ready ),
   .o_p4_tx_pll_locked                 ( p4_tx_pll_locked ),
   .i_p4_tx_rst_n                      ( p4_tx_rst_n ),
   .i_p4_rx_rst_n                      ( p4_rx_rst_n ),
   .o_p4_rx_rst_ack_n                  ( p4_rx_rst_ack_n ),
   .o_p4_tx_rst_ack_n                  ( p4_tx_rst_ack_n ),
   .o_p4_ereset_n                      ( p4_ereset_n ),
   .o_p4_clk_pll                       ( p4_clk_pll ),
   .o_p4_clk_tx_div                    ( p4_clk_tx_div ),
   .o_p4_clk_rec_div64                 ( p4_clk_rec_div64 ),
   .o_p4_clk_rec_div                   ( p4_clk_rec_div ),
`endif
`ifdef INCLUDE_HSSI_PORT_5
   .p5_app_ss_st_tx_clk                ( app_ss_st_p5_tx_clk ),
   .p5_app_ss_st_tx_areset_n           ( app_ss_st_p5_tx_areset_n ),
   .p5_app_ss_st_tx_tvalid             ( app_ss_st_p5_tx_tvalid ),
   .p5_ss_app_st_tx_tready             ( ss_app_st_p5_tx_tready ),
   .p5_app_ss_st_tx_tdata              ( app_ss_st_p5_tx_tdata ),
   .p5_app_ss_st_tx_tkeep              ( app_ss_st_p5_tx_tkeep ),
   .p5_app_ss_st_tx_tlast              ( app_ss_st_p5_tx_tlast ),
   .p5_app_ss_st_tx_tuser_client       ( app_ss_st_p5_tx_tuser_client ),
   `ifdef INCLUDE_HSSI_PORT_5_PTP
   .p5_app_ss_st_tx_tuser_ptp          ( 'h0 ),
   .p5_app_ss_st_tx_tuser_ptp_extended ( 'h0 ),
   `endif
   .p5_app_ss_st_rx_clk                ( app_ss_st_p5_rx_clk ),
   .p5_app_ss_st_rx_areset_n           ( app_ss_st_p5_rx_areset_n ),
   .p5_ss_app_st_rx_tvalid             ( ss_app_st_p5_rx_tvalid ),
   .p5_ss_app_st_rx_tdata              ( ss_app_st_p5_rx_tdata ),
   .p5_ss_app_st_rx_tkeep              ( ss_app_st_p5_rx_tkeep ),
   .p5_ss_app_st_rx_tlast              ( ss_app_st_p5_rx_tlast ),
   .p5_ss_app_st_rx_tuser_client       ( ss_app_st_p5_rx_tuser_client ),
   .p5_ss_app_st_rx_tuser_sts          ( ss_app_st_p5_rx_tuser_sts ),
   .i_p5_tx_pause                      ( p5_tx_pause ),
   .o_p5_rx_pause                      ( p5_rx_pause ),
   .i_p5_tx_pfc                        ( p5_tx_pfc ),
   .o_p5_rx_pfc                        ( p5_rx_pfc ),
   .p5_tx_serial                       ( cvl_serial_tx_p[5] ),
   .p5_tx_serial_n                     ( ),
   .p5_rx_serial                       ( cvl_serial_rx_p[5] ),
   .p5_rx_serial_n                     ( 'h0 ),
   `ifdef INCLUDE_HSSI_PORT_5_PTP
   .i_p5_clk_tx_tod                    ( p5_clk_tx_div ),
   .i_p5_clk_rx_tod                    ( p5_clk_rec_div ),
   `endif
   .p5_tx_lanes_stable                 ( p5_tx_lanes_stable ),
   .p5_rx_pcs_ready                    ( p5_rx_pcs_ready ),
   .o_p5_tx_pll_locked                 ( p5_tx_pll_locked ),
   .i_p5_tx_rst_n                      ( p5_tx_rst_n ),
   .i_p5_rx_rst_n                      ( p5_rx_rst_n ),
   .o_p5_rx_rst_ack_n                  ( p5_rx_rst_ack_n ),
   .o_p5_tx_rst_ack_n                  ( p5_tx_rst_ack_n ),
   .o_p5_ereset_n                      ( p5_ereset_n ),
   .o_p5_clk_pll                       ( p5_clk_pll ),
   .o_p5_clk_tx_div                    ( p5_clk_tx_div ),
   .o_p5_clk_rec_div64                 ( p5_clk_rec_div64 ),
   .o_p5_clk_rec_div                   ( p5_clk_rec_div ),
`endif
`ifdef INCLUDE_HSSI_PORT_6
   .p6_app_ss_st_tx_clk                ( app_ss_st_p6_tx_clk ),
   .p6_app_ss_st_tx_areset_n           ( app_ss_st_p6_tx_areset_n ),
   .p6_app_ss_st_tx_tvalid             ( app_ss_st_p6_tx_tvalid ),
   .p6_ss_app_st_tx_tready             ( ss_app_st_p6_tx_tready ),
   .p6_app_ss_st_tx_tdata              ( app_ss_st_p6_tx_tdata ),
   .p6_app_ss_st_tx_tkeep              ( app_ss_st_p6_tx_tkeep ),
   .p6_app_ss_st_tx_tlast              ( app_ss_st_p6_tx_tlast ),
   .p6_app_ss_st_tx_tuser_client       ( app_ss_st_p6_tx_tuser_client ),
   `ifdef INCLUDE_HSSI_PORT_6_PTP
   .p6_app_ss_st_tx_tuser_ptp          ( 'h0 ),
   .p6_app_ss_st_tx_tuser_ptp_extended ( 'h0 ),
   .p6_app_ss_st_rx_clk                ( app_ss_st_p6_rx_clk ),
   `endif
   .p6_app_ss_st_rx_areset_n           ( app_ss_st_p6_rx_areset_n ),
   .p6_ss_app_st_rx_tvalid             ( ss_app_st_p6_rx_tvalid ),
   .p6_ss_app_st_rx_tdata              ( ss_app_st_p6_rx_tdata ),
   .p6_ss_app_st_rx_tkeep              ( ss_app_st_p6_rx_tkeep ),
   .p6_ss_app_st_rx_tlast              ( ss_app_st_p6_rx_tlast ),
   .p6_ss_app_st_rx_tuser_client       ( ss_app_st_p6_rx_tuser_client ),
   .p6_ss_app_st_rx_tuser_sts          ( ss_app_st_p6_rx_tuser_sts ),
   .i_p6_tx_pause                      ( p6_tx_pause ),
   .o_p6_rx_pause                      ( p6_rx_pause ),
   .i_p6_tx_pfc                        ( p6_tx_pfc ),
   .o_p6_rx_pfc                        ( p6_rx_pfc ),
   .p6_tx_serial                       ( cvl_serial_tx_p[6] ),
   .p6_tx_serial_n                     ( ),
   .p6_rx_serial                       ( cvl_serial_rx_p[6] ),
   .p6_rx_serial_n                     ( 'h0 ),
   `ifdef INCLUDE_HSSI_PORT_6_PTP
   .i_p6_clk_tx_tod                    ( p6_clk_tx_div ),
   .i_p6_clk_rx_tod                    ( p6_clk_rec_div ),
   `endif
   .p6_tx_lanes_stable                 ( p6_tx_lanes_stable ),
   .p6_rx_pcs_ready                    ( p6_rx_pcs_ready ),
   .o_p6_tx_pll_locked                 ( p6_tx_pll_locked ),
   .i_p6_tx_rst_n                      ( p6_tx_rst_n ),
   .i_p6_rx_rst_n                      ( p6_rx_rst_n ),
   .o_p6_rx_rst_ack_n                  ( p6_rx_rst_ack_n ),
   .o_p6_tx_rst_ack_n                  ( p6_tx_rst_ack_n ),
   .o_p6_ereset_n                      ( p6_ereset_n ),
   .o_p6_clk_pll                       ( p6_clk_pll ),
   .o_p6_clk_tx_div                    ( p6_clk_tx_div ),
   .o_p6_clk_rec_div64                 ( p6_clk_rec_div64 ),
   .o_p6_clk_rec_div                   ( p6_clk_rec_div ),
`endif
`ifdef INCLUDE_HSSI_PORT_7
   .p7_app_ss_st_tx_clk                ( app_ss_st_p7_tx_clk ),
   .p7_app_ss_st_tx_areset_n           ( app_ss_st_p7_tx_areset_n ),
   .p7_app_ss_st_tx_tvalid             ( app_ss_st_p7_tx_tvalid ),
   .p7_ss_app_st_tx_tready             ( ss_app_st_p7_tx_tready ),
   .p7_app_ss_st_tx_tdata              ( app_ss_st_p7_tx_tdata ),
   .p7_app_ss_st_tx_tkeep              ( app_ss_st_p7_tx_tkeep ),
   .p7_app_ss_st_tx_tlast              ( app_ss_st_p7_tx_tlast ),
   .p7_app_ss_st_tx_tuser_client       ( app_ss_st_p7_tx_tuser_client ),
   `ifdef INCLUDE_HSSI_PORT_7_PTP
   .p7_app_ss_st_tx_tuser_ptp          ( 'h0 ),
   .p7_app_ss_st_tx_tuser_ptp_extended ( 'h0 ),
   `endif
   .p7_app_ss_st_rx_clk                ( app_ss_st_p7_rx_clk ),
   .p7_app_ss_st_rx_areset_n           ( app_ss_st_p7_rx_areset_n ),
   .p7_ss_app_st_rx_tvalid             ( ss_app_st_p7_rx_tvalid ),
   .p7_ss_app_st_rx_tdata              ( ss_app_st_p7_rx_tdata ),
   .p7_ss_app_st_rx_tkeep              ( ss_app_st_p7_rx_tkeep ),
   .p7_ss_app_st_rx_tlast              ( ss_app_st_p7_rx_tlast ),
   .p7_ss_app_st_rx_tuser_client       ( ss_app_st_p7_rx_tuser_client ),
   .p7_ss_app_st_rx_tuser_sts          ( ss_app_st_p7_rx_tuser_sts ),
   .i_p7_tx_pause                      ( p7_tx_pause ),
   .o_p7_rx_pause                      ( p7_rx_pause ),
   .i_p7_tx_pfc                        ( p7_tx_pfc ),
   .o_p7_rx_pfc                        ( p7_rx_pfc ),
   .p7_tx_serial                       ( cvl_serial_tx_p[7] ),
   .p7_tx_serial_n                     ( ),
   .p7_rx_serial                       ( cvl_serial_rx_p[7] ),
   .p7_rx_serial_n                     ( 'h0 ),
   `ifdef INCLUDE_HSSI_PORT_7_PTP
   .i_p7_clk_tx_tod                    ( p7_clk_tx_div ),
   .i_p7_clk_rx_tod                    ( p7_clk_rec_div ),
   `endif
   .p7_tx_lanes_stable                 ( p7_tx_lanes_stable ),
   .p7_rx_pcs_ready                    ( p7_rx_pcs_ready ),
   .o_p7_tx_pll_locked                 ( p7_tx_pll_locked ),
   .i_p7_tx_rst_n                      ( p7_tx_rst_n ),
   .i_p7_rx_rst_n                      ( p7_rx_rst_n ),
   .o_p7_rx_rst_ack_n                  ( p7_rx_rst_ack_n ),
   .o_p7_tx_rst_ack_n                  ( p7_tx_rst_ack_n ),
   .o_p7_ereset_n                      ( p7_ereset_n ),
   .o_p7_clk_pll                       ( p7_clk_pll ),
   .o_p7_clk_tx_div                    ( p7_clk_tx_div ),
   .o_p7_clk_rec_div64                 ( p7_clk_rec_div64 ),
   .o_p7_clk_rec_div                   ( p7_clk_rec_div ),
`endif
   .subsystem_cold_rst_n               (subsystem_cold_rst_n),
   .subsystem_cold_rst_ack_n           (subsystem_cold_rst_ack_n),
   .i_clk_ref                          ({3{clk_ref}})
  );

  //--------------------------------------------------------------------------------
  // BFM
  //--------------------------------------------------------------------------------

  axi_lite_bfm axiBFM (
    .aclk                           (app_ss_lite_clk),
    .aresetn                        (app_ss_lite_areset_n),
    .axi_lite_awvalid_o             (app_ss_lite_awvalid),
    .axi_lite_awready_i             (ss_app_lite_awready),
    .axi_lite_awprot_o              (app_ss_lite_awprot),
    .axi_lite_awaddr_o              (app_ss_lite_awaddr),
    .axi_lite_wdata_o               (app_ss_lite_wdata),
    .axi_lite_wstrb_o               (app_ss_lite_wstrb),
    .axi_lite_wvalid_o              (app_ss_lite_wvalid),
    .axi_lite_wready_i              (ss_app_lite_wready),
    .axi_lite_bvalid_i              (ss_app_lite_bvalid),
    .axi_lite_bready_o              (app_ss_lite_bready),
    .axi_lite_bresp_i               (ss_app_lite_bresp),
    .axi_lite_arvalid_o             (app_ss_lite_arvalid),
    .axi_lite_arready_i             (ss_app_lite_arready),
    .axi_lite_arprot_o              (app_ss_lite_arprot),
    .axi_lite_araddr_o              (app_ss_lite_araddr),
    .axi_lite_rdata_i               (ss_app_lite_rdata),
    .axi_lite_rresp_i               (ss_app_lite_rresp),
    .axi_lite_rvalid_i              (ss_app_lite_rvalid),
    .axi_lite_rready_o              (app_ss_lite_rready)
  );


localparam P0_PTP = 0;
`ifdef INCLUDE_HSSI_PORT_0
  axis_bfm #(
    .WORDS                          (1),
    .WIDTH                          (ETH_PACKET_WIDTH),
    .PORT_NO                        (0),
    .PTP                            (P0_PTP)
  ) axis_bfm_p0 (
    .app_ss_lite_areset_n           (app_ss_lite_areset_n),
    .tx_aclk                        (app_ss_st_p0_tx_clk),
    .tx_aresetn                     (app_ss_st_p0_tx_areset_n),
    .rx_aclk                        (app_ss_st_p0_rx_clk),
    .rx_aresetn                     (app_ss_st_p0_rx_areset_n),
    .ptp_fp_i                       ('0),
    .ptp_cmd_sel_i                  ('0),
    .ptp_ets_valid_i                ('0),
    .ptp_ets_i                      ('0),
    .ptp_ets_fp_i                   ('0),
    .ptp_rx_its_i                   ('0),
    .txrx_ts_diff_thres_i           ('0),
    .axis_tx_tvalid_o               (app_ss_st_p0_tx_tvalid),
    .axis_tx_tdata_o                (app_ss_st_p0_tx_tdata),
    .axis_tx_tready_i               (ss_app_st_p0_tx_tready),
    .axis_tx_tkeep_o                (app_ss_st_p0_tx_tkeep),
    .axis_tx_tlast_o                (app_ss_st_p0_tx_tlast),
    .axis_tx_tuser_client_o         (app_ss_st_p0_tx_tuser_client),
    .axis_rx_tvalid_i               (ss_app_st_p0_rx_tvalid),
    .axis_rx_tdata_i                (ss_app_st_p0_rx_tdata),
    .axis_rx_tready_o               (app_ss_st_p0_rx_tready),
    .axis_rx_tkeep_i                (ss_app_st_p0_rx_tkeep),
    .axis_rx_tlast_i                (ss_app_st_p0_rx_tlast),
    .axis_rx_tuser_client_i         (ss_app_st_p0_rx_tuser_client),
    .axis_rx_tuser_sts_i            (ss_app_st_p0_rx_tuser_sts),
    .axis_rx_tuser_sts_ext_i        ()
  );
`endif
`ifdef INCLUDE_HSSI_PORT_1
  localparam P1_PTP = 0;
  axis_bfm #(
    .WORDS                          (1),
    .WIDTH                          (ETH_PACKET_WIDTH),
    .PORT_NO                        (1),
    .PTP                            (P1_PTP)
  ) axis_bfm_p1 (
    .app_ss_lite_areset_n           (app_ss_lite_areset_n),
    .tx_aclk                        (app_ss_st_p1_tx_clk),
    .tx_aresetn                     (app_ss_st_p1_tx_areset_n),
    .rx_aclk                        (app_ss_st_p1_rx_clk),
    .rx_aresetn                     (app_ss_st_p1_rx_areset_n),
    .ptp_fp_i                       ('0),
    .ptp_cmd_sel_i                  ('0),
    .ptp_ets_valid_i                ('0),
    .ptp_ets_i                      ('0),
    .ptp_ets_fp_i                   ('0),
    .ptp_rx_its_i                   ('0),
    .txrx_ts_diff_thres_i           ('0),
    .axis_tx_tvalid_o               (app_ss_st_p1_tx_tvalid),
    .axis_tx_tdata_o                (app_ss_st_p1_tx_tdata),
    .axis_tx_tready_i               (ss_app_st_p1_tx_tready),
    .axis_tx_tkeep_o                (app_ss_st_p1_tx_tkeep),
    .axis_tx_tlast_o                (app_ss_st_p1_tx_tlast),
    .axis_tx_tuser_client_o         (app_ss_st_p1_tx_tuser_client),
    .axis_rx_tvalid_i               (ss_app_st_p1_rx_tvalid),
    .axis_rx_tdata_i                (ss_app_st_p1_rx_tdata),
    .axis_rx_tready_o               (app_ss_st_p1_rx_tready),
    .axis_rx_tkeep_i                (ss_app_st_p1_rx_tkeep),
    .axis_rx_tlast_i                (ss_app_st_p1_rx_tlast),
    .axis_rx_tuser_client_i         (ss_app_st_p1_rx_tuser_client),
    .axis_rx_tuser_sts_i            (ss_app_st_p1_rx_tuser_sts),
    .axis_rx_tuser_sts_ext_i        ()
  );
`endif
`ifdef INCLUDE_HSSI_PORT_2
  localparam P2_PTP = 0;
  axis_bfm #(
    .WORDS                          (1),
    .WIDTH                          (ETH_PACKET_WIDTH),
    .PORT_NO                        (2),
    .PTP                            (P2_PTP)
  ) axis_bfm_p2 (
    .app_ss_lite_areset_n           (app_ss_lite_areset_n),
    .tx_aclk                        (app_ss_st_p2_tx_clk),
    .tx_aresetn                     (app_ss_st_p2_tx_areset_n),
    .rx_aclk                        (app_ss_st_p2_rx_clk),
    .rx_aresetn                     (app_ss_st_p2_rx_areset_n),
    .ptp_fp_i                       ('0),
    .ptp_cmd_sel_i                  ('0),
    .ptp_ets_valid_i                ('0),
    .ptp_ets_i                      ('0),
    .ptp_ets_fp_i                   ('0),
    .ptp_rx_its_i                   ('0),
    .txrx_ts_diff_thres_i           ('0),
    .axis_tx_tvalid_o               (app_ss_st_p2_tx_tvalid),
    .axis_tx_tdata_o                (app_ss_st_p2_tx_tdata),
    .axis_tx_tready_i               (ss_app_st_p2_tx_tready),
    .axis_tx_tkeep_o                (app_ss_st_p2_tx_tkeep),
    .axis_tx_tlast_o                (app_ss_st_p2_tx_tlast),
    .axis_tx_tuser_client_o         (app_ss_st_p2_tx_tuser_client),
    .axis_rx_tvalid_i               (ss_app_st_p2_rx_tvalid),
    .axis_rx_tdata_i                (ss_app_st_p2_rx_tdata),
    .axis_rx_tready_o               (app_ss_st_p2_rx_tready),
    .axis_rx_tkeep_i                (ss_app_st_p2_rx_tkeep),
    .axis_rx_tlast_i                (ss_app_st_p2_rx_tlast),
    .axis_rx_tuser_client_i         (ss_app_st_p2_rx_tuser_client),
    .axis_rx_tuser_sts_i            (ss_app_st_p2_rx_tuser_sts),
    .axis_rx_tuser_sts_ext_i        ()
  );
`endif
`ifdef INCLUDE_HSSI_PORT_3
  localparam P3_PTP = 0;
  axis_bfm #(
    .WORDS                          (1),
    .WIDTH                          (ETH_PACKET_WIDTH),
    .PORT_NO                        (3),
    .PTP                            (P3_PTP)
  ) axis_bfm_p3 (
    .app_ss_lite_areset_n           (app_ss_lite_areset_n),
    .tx_aclk                        (app_ss_st_p3_tx_clk),
    .tx_aresetn                     (app_ss_st_p3_tx_areset_n),
    .rx_aclk                        (app_ss_st_p3_rx_clk),
    .rx_aresetn                     (app_ss_st_p3_rx_areset_n),
    .ptp_fp_i                       ('0),
    .ptp_cmd_sel_i                  ('0),
    .ptp_ets_valid_i                ('0),
    .ptp_ets_i                      ('0),
    .ptp_ets_fp_i                   ('0),
    .ptp_rx_its_i                   ('0),
    .txrx_ts_diff_thres_i           ('0),
    .axis_tx_tvalid_o               (app_ss_st_p3_tx_tvalid),
    .axis_tx_tdata_o                (app_ss_st_p3_tx_tdata),
    .axis_tx_tready_i               (ss_app_st_p3_tx_tready),
    .axis_tx_tkeep_o                (app_ss_st_p3_tx_tkeep),
    .axis_tx_tlast_o                (app_ss_st_p3_tx_tlast),
    .axis_tx_tuser_client_o         (app_ss_st_p3_tx_tuser_client),
    .axis_rx_tvalid_i               (ss_app_st_p3_rx_tvalid),
    .axis_rx_tdata_i                (ss_app_st_p3_rx_tdata),
    .axis_rx_tready_o               (app_ss_st_p3_rx_tready),
    .axis_rx_tkeep_i                (ss_app_st_p3_rx_tkeep),
    .axis_rx_tlast_i                (ss_app_st_p3_rx_tlast),
    .axis_rx_tuser_client_i         (ss_app_st_p3_rx_tuser_client),
    .axis_rx_tuser_sts_i            (ss_app_st_p3_rx_tuser_sts),
    .axis_rx_tuser_sts_ext_i        ()
  );
`endif
`ifdef INCLUDE_HSSI_PORT_4
localparam P4_PTP = 0;
  axis_bfm #(
    .WORDS                          (1),
    .WIDTH                          (ETH_PACKET_WIDTH),
    .PORT_NO                        (4),
    .PTP                            (P4_PTP)
  ) axis_bfm_p4 (
    .app_ss_lite_areset_n           (app_ss_lite_areset_n),
    .tx_aclk                        (app_ss_st_p4_tx_clk),
    .tx_aresetn                     (app_ss_st_p4_tx_areset_n),
    .rx_aclk                        (app_ss_st_p4_rx_clk),
    .rx_aresetn                     (app_ss_st_p4_rx_areset_n),
    .ptp_fp_i                       ('0),
    .ptp_cmd_sel_i                  ('0),
    .ptp_ets_valid_i                ('0),
    .ptp_ets_i                      ('0),
    .ptp_ets_fp_i                   ('0),
    .ptp_rx_its_i                   ('0),
    .txrx_ts_diff_thres_i           ('0),
    .axis_tx_tvalid_o               (app_ss_st_p4_tx_tvalid),
    .axis_tx_tdata_o                (app_ss_st_p4_tx_tdata),
    .axis_tx_tready_i               (ss_app_st_p4_tx_tready),
    .axis_tx_tkeep_o                (app_ss_st_p4_tx_tkeep),
    .axis_tx_tlast_o                (app_ss_st_p4_tx_tlast),
    .axis_tx_tuser_client_o         (app_ss_st_p4_tx_tuser_client),
    .axis_rx_tvalid_i               (ss_app_st_p4_rx_tvalid),
    .axis_rx_tdata_i                (ss_app_st_p4_rx_tdata),
    .axis_rx_tready_o               (app_ss_st_p4_rx_tready),
    .axis_rx_tkeep_i                (ss_app_st_p4_rx_tkeep),
    .axis_rx_tlast_i                (ss_app_st_p4_rx_tlast),
    .axis_rx_tuser_client_i         (ss_app_st_p4_rx_tuser_client),
    .axis_rx_tuser_sts_i            (ss_app_st_p4_rx_tuser_sts),
    .axis_rx_tuser_sts_ext_i        ()
  );
`endif
`ifdef INCLUDE_HSSI_PORT_5
  localparam P5_PTP = 0;
  axis_bfm #(
    .WORDS                          (1),
    .WIDTH                          (ETH_PACKET_WIDTH),
    .PORT_NO                        (5),
    .PTP                            (P5_PTP)
  ) axis_bfm_p5 (
    .app_ss_lite_areset_n           (app_ss_lite_areset_n),
    .tx_aclk                        (app_ss_st_p5_tx_clk),
    .tx_aresetn                     (app_ss_st_p5_tx_areset_n),
    .rx_aclk                        (app_ss_st_p5_rx_clk),
    .rx_aresetn                     (app_ss_st_p5_rx_areset_n),
    .ptp_fp_i                       ('0),
    .ptp_cmd_sel_i                  ('0),
    .ptp_ets_valid_i                ('0),
    .ptp_ets_i                      ('0),
    .ptp_ets_fp_i                   ('0),
    .ptp_rx_its_i                   ('0),
    .txrx_ts_diff_thres_i           ('0),
    .axis_tx_tvalid_o               (app_ss_st_p5_tx_tvalid),
    .axis_tx_tdata_o                (app_ss_st_p5_tx_tdata),
    .axis_tx_tready_i               (ss_app_st_p5_tx_tready),
    .axis_tx_tkeep_o                (app_ss_st_p5_tx_tkeep),
    .axis_tx_tlast_o                (app_ss_st_p5_tx_tlast),
    .axis_tx_tuser_client_o         (app_ss_st_p5_tx_tuser_client),
    .axis_rx_tvalid_i               (ss_app_st_p5_rx_tvalid),
    .axis_rx_tdata_i                (ss_app_st_p5_rx_tdata),
    .axis_rx_tready_o               (app_ss_st_p5_rx_tready),
    .axis_rx_tkeep_i                (ss_app_st_p5_rx_tkeep),
    .axis_rx_tlast_i                (ss_app_st_p5_rx_tlast),
    .axis_rx_tuser_client_i         (ss_app_st_p5_rx_tuser_client),
    .axis_rx_tuser_sts_i            (ss_app_st_p5_rx_tuser_sts),
    .axis_rx_tuser_sts_ext_i        ()
  );
`endif
`ifdef INCLUDE_HSSI_PORT_6
  localparam P6_PTP = 0;
  axis_bfm #(
    .WORDS                          (1),
    .WIDTH                          (ETH_PACKET_WIDTH),
    .PORT_NO                        (6),
    .PTP                            (P6_PTP)
  ) axis_bfm_p6 (
    .app_ss_lite_areset_n           (app_ss_lite_areset_n),
    .tx_aclk                        (app_ss_st_p6_tx_clk),
    .tx_aresetn                     (app_ss_st_p6_tx_areset_n),
    .rx_aclk                        (app_ss_st_p6_rx_clk),
    .rx_aresetn                     (app_ss_st_p6_rx_areset_n),
    .ptp_fp_i                       ('0),
    .ptp_cmd_sel_i                  ('0),
    .ptp_ets_valid_i                ('0),
    .ptp_ets_i                      ('0),
    .ptp_ets_fp_i                   ('0),
    .ptp_rx_its_i                   ('0),
    .txrx_ts_diff_thres_i           ('0),
    .axis_tx_tvalid_o               (app_ss_st_p6_tx_tvalid),
    .axis_tx_tdata_o                (app_ss_st_p6_tx_tdata),
    .axis_tx_tready_i               (ss_app_st_p6_tx_tready),
    .axis_tx_tkeep_o                (app_ss_st_p6_tx_tkeep),
    .axis_tx_tlast_o                (app_ss_st_p6_tx_tlast),
    .axis_tx_tuser_client_o         (app_ss_st_p6_tx_tuser_client),
    .axis_rx_tvalid_i               (ss_app_st_p6_rx_tvalid),
    .axis_rx_tdata_i                (ss_app_st_p6_rx_tdata),
    .axis_rx_tready_o               (app_ss_st_p6_rx_tready),
    .axis_rx_tkeep_i                (ss_app_st_p6_rx_tkeep),
    .axis_rx_tlast_i                (ss_app_st_p6_rx_tlast),
    .axis_rx_tuser_client_i         (ss_app_st_p6_rx_tuser_client),
    .axis_rx_tuser_sts_i            (ss_app_st_p6_rx_tuser_sts),
    .axis_rx_tuser_sts_ext_i        ()
  );
`endif
`ifdef INCLUDE_HSSI_PORT_7
  localparam P7_PTP = 0;
  axis_bfm #(
    .WORDS                          (1),
    .WIDTH                          (ETH_PACKET_WIDTH),
    .PORT_NO                        (7),
    .PTP                            (P7_PTP)
  ) axis_bfm_p7 (
    .app_ss_lite_areset_n           (app_ss_lite_areset_n),
    .tx_aclk                        (app_ss_st_p7_tx_clk),
    .tx_aresetn                     (app_ss_st_p7_tx_areset_n),
    .rx_aclk                        (app_ss_st_p7_rx_clk),
    .rx_aresetn                     (app_ss_st_p7_rx_areset_n),
    .ptp_fp_i                       ('0),
    .ptp_cmd_sel_i                  ('0),
    .ptp_ets_valid_i                ('0),
    .ptp_ets_i                      ('0),
    .ptp_ets_fp_i                   ('0),
    .ptp_rx_its_i                   ('0),
    .txrx_ts_diff_thres_i           ('0),
    .axis_tx_tvalid_o               (app_ss_st_p7_tx_tvalid),
    .axis_tx_tdata_o                (app_ss_st_p7_tx_tdata),
    .axis_tx_tready_i               (ss_app_st_p7_tx_tready),
    .axis_tx_tkeep_o                (app_ss_st_p7_tx_tkeep),
    .axis_tx_tlast_o                (app_ss_st_p7_tx_tlast),
    .axis_tx_tuser_client_o         (app_ss_st_p7_tx_tuser_client),
    .axis_rx_tvalid_i               (ss_app_st_p7_rx_tvalid),
    .axis_rx_tdata_i                (ss_app_st_p7_rx_tdata),
    .axis_rx_tready_o               (app_ss_st_p7_rx_tready),
    .axis_rx_tkeep_i                (ss_app_st_p7_rx_tkeep),
    .axis_rx_tlast_i                (ss_app_st_p7_rx_tlast),
    .axis_rx_tuser_client_i         (ss_app_st_p7_rx_tuser_client),
    .axis_rx_tuser_sts_i            (ss_app_st_p7_rx_tuser_sts),
    .axis_rx_tuser_sts_ext_i        ()
  );
`endif

endmodule
//------------------------------------------------------------------------------
//
//
// End tb_hssi_ss_top.sv
//
//------------------------------------------------------------------------------

