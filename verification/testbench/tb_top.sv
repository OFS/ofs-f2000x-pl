//Copyright 2021 Intel Corporation
//SPDX-License-Identifier: MIT
//===============================================================================================================
/**
 * Abstract:
 * module tb_top is top level verfication module .
 * 
 * This module has instance of DUT,DDR_MEM,PCIE_VIP and ETHERNET_VIP. 
                  1.TEST_LPBK  : Used when HSSI RX_LPK test to be run ,it will chnage the time scale precision
                  2.DDR4       : Includes the EMIF MEMORY module in design
 * 
 * UVM task run_test() is called in this module to start the execution of tests
 */
//===============================================================================================================

`timescale 1ps/1ps

`ifdef TEST_LPBK //Use this switch to run rx loopback test to create accurated frequncies of ETH_VIP clks
    `timescale 1ps/1fs
`endif

module tb_top;
    
    //------------------------------------------------------------------------------
    // Serial interface signals
    //------------------------------------------------------------------------------
    logic [ofs_fim_cfg_pkg::PCIE_LANES-1:0] soc_root0_tx_datap;        //-------------------------------------
    logic [ofs_fim_cfg_pkg::PCIE_LANES-1:0] soc_endpoint0_tx_datap;    //-------------------------------------
    logic [ofs_fim_cfg_pkg::PCIE_LANES-1:0] soc_endpoint0_tx_datan;
    logic [ofs_fim_cfg_pkg::PCIE_LANES-1:0] host_root0_tx_datap;        //-------------------------------------
    logic [ofs_fim_cfg_pkg::PCIE_LANES-1:0] host_endpoint0_tx_datap;    //-------------------------------------
    logic [ofs_fim_cfg_pkg::PCIE_LANES-1:0] host_endpoint0_tx_datan;

    bit pmci_master;
    bit bmc_en;

    reg SYS_RefClk   = 0;
    reg PCIE_RefClk  = 0;
    reg ETH_RefClk   = 0;
    reg PCIE_RESET_N = 0;
    reg soc_PCIE_RESET_N = 0;
    reg host_PCIE_RESET_N = 0;
    bit outclk_0 = 1'b0; 
    bit outclk_1 = 1'b0;
    bit outclk_2 = 1'b0;
    bit outclk_3 = 1'b0;
    bit outclk_4 = 1'b0;
    bit tbclk_1Ghz = 0;
    bit reference_clk;
   
   m10_interface m10_if();

  `ifdef INCLUDE_HSSI
      wire [NUMB_ETH_CHANNELS-1:0] qsfp1_lpbk_serial;
      ofs_fim_hssi_serial_if hssi_if [ofs_fim_eth_plat_if_pkg::NUM_ETH_LANES-1:0]();
  `endif
   always #50 reference_clk        = ~reference_clk;

    `AXI_IF axi_if();
    `AXI_IF axi_passive_if[5]();
    `ifdef LPBK_WITHOUT_HSSI
      `AXI_IF axis_HSSI_if();
    `endif

     `ETH_TXRX_IF mac_ethernet_if[8](reference_clk);
    `include "tb_ethernet/ethernet_clk_gen.sv"
    genvar i;
    generate
      for( i=0; i<8; i++) begin : ethernet_mac
         `ETH_XXM_BFM_DRV ethernet_mac_txrx(mac_ethernet_if[i]);
         `ETH_XXM_MON_CHK_DRV   ethernet_mac_mon(mac_ethernet_if[i]);
       end
    endgenerate

    ethernet_reset_if ethernet_reset_if();
    assign ethernet_reset_if.clk = gmii_rx_clk;
    for(i=0; i<8; i++) begin
      assign mac_ethernet_if[i].reset = ethernet_reset_if.reset;
    end

`ifdef INCLUDE_DDR4
   ofs_fim_emif_ddr4_if ddr4_mem [DDR_CHANNEL-1:0] ();
`endif


    //coverage interface
    `ifdef ENABLE_SOC_HOST_COVERAGE
        coverage_intf  cov_intf();
    `endif

  `ifdef SIM_MODE_SOC
        `PCIE_DEV_AGNT_X16_8G_HDL root0(
            .reset        (~soc_PCIE_RESET_N),
            .rx_datap_0   ( soc_endpoint0_tx_datap[0]), // inputs
            .rx_datap_1   ( soc_endpoint0_tx_datap[1]),
            .rx_datap_2   ( soc_endpoint0_tx_datap[2]),
            .rx_datap_3   ( soc_endpoint0_tx_datap[3]),
            .rx_datap_4   ( soc_endpoint0_tx_datap[4]),
            .rx_datap_5   ( soc_endpoint0_tx_datap[5]),
            .rx_datap_6   ( soc_endpoint0_tx_datap[6]),
            .rx_datap_7   ( soc_endpoint0_tx_datap[7]),
            .rx_datap_8   ( soc_endpoint0_tx_datap[8]),
            .rx_datap_9   ( soc_endpoint0_tx_datap[9]),
            .rx_datap_10  ( soc_endpoint0_tx_datap[10]),
            .rx_datap_11  ( soc_endpoint0_tx_datap[11]),
            .rx_datap_12  ( soc_endpoint0_tx_datap[12]),
            .rx_datap_13  ( soc_endpoint0_tx_datap[13]),
            .rx_datap_14  ( soc_endpoint0_tx_datap[14]),
            .rx_datap_15  ( soc_endpoint0_tx_datap[15]),
            .rx_datan_0   ( soc_endpoint0_tx_datan[0]), // inputs
            .rx_datan_1   ( soc_endpoint0_tx_datan[1]),
            .rx_datan_2   ( soc_endpoint0_tx_datan[2]),
            .rx_datan_3   ( soc_endpoint0_tx_datan[3]),
            .rx_datan_4   ( soc_endpoint0_tx_datan[4]),
            .rx_datan_5   ( soc_endpoint0_tx_datan[5]),
            .rx_datan_6   ( soc_endpoint0_tx_datan[6]),
            .rx_datan_7   ( soc_endpoint0_tx_datan[7]),
            .rx_datan_8   ( soc_endpoint0_tx_datan[8]),
            .rx_datan_9   ( soc_endpoint0_tx_datan[9]),
            .rx_datan_10  ( soc_endpoint0_tx_datan[10]),
            .rx_datan_11  ( soc_endpoint0_tx_datan[11]),
            .rx_datan_12  ( soc_endpoint0_tx_datan[12]),
            .rx_datan_13  ( soc_endpoint0_tx_datan[13]),
            .rx_datan_14  ( soc_endpoint0_tx_datan[14]),
            .rx_datan_15  ( soc_endpoint0_tx_datan[15]),

            .tx_datap_0   (soc_root0_tx_datap[0]),  // outputs
            .tx_datap_1   (soc_root0_tx_datap[1]),
            .tx_datap_2   (soc_root0_tx_datap[2]),
            .tx_datap_3   (soc_root0_tx_datap[3]),
            .tx_datap_4   (soc_root0_tx_datap[4]),
            .tx_datap_5   (soc_root0_tx_datap[5]),
            .tx_datap_6   (soc_root0_tx_datap[6]),
            .tx_datap_7   (soc_root0_tx_datap[7]),
            .tx_datap_8   (soc_root0_tx_datap[8]),
            .tx_datap_9   (soc_root0_tx_datap[9]),
            .tx_datap_10  (soc_root0_tx_datap[10]),
            .tx_datap_11  (soc_root0_tx_datap[11]),
            .tx_datap_12  (soc_root0_tx_datap[12]),
            .tx_datap_13  (soc_root0_tx_datap[13]),
            .tx_datap_14  (soc_root0_tx_datap[14]),
            .tx_datap_15  (soc_root0_tx_datap[15])
       );
     `endif
       `PCIE_DEV_AGNT_X16_8G_HDL 
       root1(
            .reset        (~host_PCIE_RESET_N),
            .rx_datap_0   ( host_endpoint0_tx_datap[0]), // inputs
            .rx_datap_1   ( host_endpoint0_tx_datap[1]),
            .rx_datap_2   ( host_endpoint0_tx_datap[2]),
            .rx_datap_3   ( host_endpoint0_tx_datap[3]),
            .rx_datap_4   ( host_endpoint0_tx_datap[4]),
            .rx_datap_5   ( host_endpoint0_tx_datap[5]),
            .rx_datap_6   ( host_endpoint0_tx_datap[6]),
            .rx_datap_7   ( host_endpoint0_tx_datap[7]),
            .rx_datap_8   ( host_endpoint0_tx_datap[8]),
            .rx_datap_9   ( host_endpoint0_tx_datap[9]),
            .rx_datap_10  ( host_endpoint0_tx_datap[10]),
            .rx_datap_11  ( host_endpoint0_tx_datap[11]),
            .rx_datap_12  ( host_endpoint0_tx_datap[12]),
            .rx_datap_13  ( host_endpoint0_tx_datap[13]),
            .rx_datap_14  ( host_endpoint0_tx_datap[14]),
            .rx_datap_15  ( host_endpoint0_tx_datap[15]),
            .rx_datan_0   ( host_endpoint0_tx_datan[0]), // inputs
            .rx_datan_1   ( host_endpoint0_tx_datan[1]),
            .rx_datan_2   ( host_endpoint0_tx_datan[2]),
            .rx_datan_3   ( host_endpoint0_tx_datan[3]),
            .rx_datan_4   ( host_endpoint0_tx_datan[4]),
            .rx_datan_5   ( host_endpoint0_tx_datan[5]),
            .rx_datan_6   ( host_endpoint0_tx_datan[6]),
            .rx_datan_7   ( host_endpoint0_tx_datan[7]),
            .rx_datan_8   ( host_endpoint0_tx_datan[8]),
            .rx_datan_9   ( host_endpoint0_tx_datan[9]),
            .rx_datan_10  ( host_endpoint0_tx_datan[10]),
            .rx_datan_11  ( host_endpoint0_tx_datan[11]),
            .rx_datan_12  ( host_endpoint0_tx_datan[12]),
            .rx_datan_13  ( host_endpoint0_tx_datan[13]),
            .rx_datan_14  ( host_endpoint0_tx_datan[14]),
            .rx_datan_15  ( host_endpoint0_tx_datan[15]),
            
            .tx_datap_0   ( host_root0_tx_datap[0]),  // outputs
            .tx_datap_1   ( host_root0_tx_datap[1]),
            .tx_datap_2   ( host_root0_tx_datap[2]),
            .tx_datap_3   ( host_root0_tx_datap[3]),
            .tx_datap_4   ( host_root0_tx_datap[4]),
            .tx_datap_5   ( host_root0_tx_datap[5]),
            .tx_datap_6   ( host_root0_tx_datap[6]),
            .tx_datap_7   ( host_root0_tx_datap[7]),
            .tx_datap_8   ( host_root0_tx_datap[8]),
            .tx_datap_9   ( host_root0_tx_datap[9]),
            .tx_datap_10  ( host_root0_tx_datap[10]),
            .tx_datap_11  ( host_root0_tx_datap[11]),
            .tx_datap_12  ( host_root0_tx_datap[12]),
            .tx_datap_13  ( host_root0_tx_datap[13]),
            .tx_datap_14  ( host_root0_tx_datap[14]),
            .tx_datap_15  ( host_root0_tx_datap[15])
            );
    defparam root0.DISPLAY_NAME = "root0.";
    defparam root1.DISPLAY_NAME = "root1.";

top DUT (
   .SYS_REFCLK          (SYS_RefClk),
   .qsfp_ref_clk    (ETH_RefClk),	
 `ifdef INCLUDE_DDR4
   .ddr4_mem     (ddr4_mem),
 `endif
 `ifdef INCLUDE_HSSI
   .qsfpa_i2c_scl   (qsfpa_i2c_scl),
   .qsfpa_i2c_sda   (qsfpa_i2c_sda),
   .qsfpb_i2c_scl   (qsfpb_i2c_scl),
   .qsfpb_i2c_sda   (qsfpb_i2c_sda),
   .qsfpa_resetn    (qsfpa_resetn),                      
   .qsfpa_modeseln  (qsfpa_modeseln),                  
   .qsfpa_modprsln  (qsfpa_modprsln),                   
   .qsfpa_lpmode    (qsfpa_lpmode),                      
   .qsfpa_intn      (qsfpa_intn),
   .qsfpb_resetn    (qsfpb_resetn),                     
   .qsfpb_modeseln  (qsfpb_modeseln),                  
   .qsfpb_modprsln  (qsfpb_modprsln),                  
   .qsfpb_lpmode    (qsfpb_lpmode),                     
   .qsfpb_intn      (qsfpb_intn),
   .hssi_if         (hssi_if[ofs_fim_eth_plat_if_pkg::NUM_ETH_LANES-1:0]),
  `endif	
`ifdef SIM_MODE_SOC
   .SOC_PCIE_REFCLK0    (PCIE_RefClk),
   .SOC_PCIE_REFCLK1    (PCIE_RefClk),
   .SOC_PCIE_RESET_N    (soc_PCIE_RESET_N),
   .SOC_PCIE_RX_P       (soc_root0_tx_datap),
   .SOC_PCIE_RX_N       (~soc_root0_tx_datap),
   .SOC_PCIE_TX_P       (soc_endpoint0_tx_datap),
   .SOC_PCIE_TX_N       (soc_endpoint0_tx_datan),
`endif
   .PCIE_REFCLK0    (PCIE_RefClk),
   .PCIE_REFCLK1    (PCIE_RefClk),
   .PCIE_RESET_N    (host_PCIE_RESET_N),
   .PCIE_RX_P       (host_root0_tx_datap),
   .PCIE_RX_N       (~host_root0_tx_datap),
   .PCIE_TX_P       (host_endpoint0_tx_datap),
   .PCIE_TX_N       (host_endpoint0_tx_datan)
);


// EMIF memory model - If ECC is enabled then an additional ECC model must be used
`ifdef INCLUDE_DDR4
   genvar ch;
   generate
      for(ch=0; ch < DDR_CHANNEL; ch = ch+1) begin : mem_model
         initial ddr4_mem[ch].ref_clk = '0;
         always #833 ddr4_mem[ch].ref_clk = ~ddr4_mem[ch].ref_clk; // 1200 MHz
         ed_sim_mem ddr_mem_inst (
            .mem_ck     (ddr4_mem[ch].ck),
            .mem_ck_n   (ddr4_mem[ch].ck_n),
            .mem_a      (ddr4_mem[ch].a),
            .mem_act_n  (ddr4_mem[ch].act_n),
            .mem_ba     (ddr4_mem[ch].ba),
            .mem_bg     (ddr4_mem[ch].bg),
            .mem_cke    (ddr4_mem[ch].cke),
            .mem_cs_n   (ddr4_mem[ch].cs_n),
            .mem_odt    (ddr4_mem[ch].odt),
            .mem_reset_n(ddr4_mem[ch].reset_n),
            .mem_par    (ddr4_mem[ch].par),
            .mem_alert_n(ddr4_mem[ch].alert_n),
            .mem_dqs    (ddr4_mem[ch].dqs),
            .mem_dqs_n  (ddr4_mem[ch].dqs_n),
            .mem_dq     (ddr4_mem[ch].dq),
            .mem_dbi_n  (ddr4_mem[ch].dbi_n)
         );
      end
   endgenerate
`endif
     // HSSI serial loopback
      `ifdef INCLUDE_HSSI
         genvar j;
         for( j=0; j<ofs_fim_eth_plat_if_pkg::NUM_ETH_LANES; j++) begin
             assign hssi_if[j].rx_p = hssi_if[j].tx_p;
         end
     `endif


//// TEST LOOPBACK////////////////////
  int Lane;
  bit run_multiport;
  bit MODE_25G_10G;
   initial begin
    Lane=10;
     //$display("Forcing will be done test RX_LPBK");
         #2;
    if (uvm_config_db#(int)::get(null,"uvm_test_top.tb_env0", "Lane", Lane))
       //`uvm_fatal("TB_TOP","LANE IS NOT SELECTED");
       $display("LANE SELECTED:%d",Lane);
   if (uvm_config_db#(bit)::get(null,"uvm_test_top.tb_env0", "run_multiport",run_multiport))
       `uvm_info("build_phase", "MULTIPORT_MODE SELECTED ...",UVM_LOW);
    if (uvm_config_db#(bit)::get(null,"uvm_test_top.tb_env0", "MODE_25G_10G", MODE_25G_10G))
      `uvm_info("build_phase", "25G_10G_MODE SELECTED ...",UVM_LOW);

     `include "tb_ethernet/Test_LPBK.sv"
    end
    initial begin
      `ifdef TEST_LPBK
      ethernet_reset_if.reset = 1'b0;
      @(posedge ethernet_reset_if.clk)
      ethernet_reset_if.reset = 1'b1;
      @(posedge ethernet_reset_if.clk)
      ethernet_reset_if.reset = 1'b0;
      `uvm_info("TOP", "ETH_RESET_APPLIED ...",UVM_LOW);
      `endif
    end
    
/////////////////////////////////////////

always #500ps tbclk_1Ghz = ~tbclk_1Ghz;

`ifdef SIM_MODE_SOC
   initial begin
      #1ps;

         force `SOC_PCIE_QHIP.intel_pcie_ptile_ast_qhip.inst.inst.maib_and_tile.z1565a.ctp_tile_encrypted_inst.z1565a_inst.u_wrtilectrl.wrssm_aibaux_cnoc_clk_occ.uu_wrdft_ckmux21_inst.ck1 = tbclk_1Ghz;
         force `SOC_PCIE_QHIP.intel_pcie_ptile_ast_qhip.inst.inst.maib_and_tile.z1565a.ctp_tile_encrypted_inst.z1565a_inst.u_wrtilectrl.wrssm_aibaux_cnoc_clk_occ.uu_wrdft_ckmux21_inst.s0=1;
         force `SOC_PCIE_QHIP.intel_pcie_ptile_ast_qhip.inst.inst.maib_and_tile.z1565a.ctp_tile_encrypted_inst.z1565a_inst.u_wrtilectrl.wrssm_config_avmm_clk_div_mux.s0=1;
         force `SOC_PCIE_QHIP.intel_pcie_ptile_ast_qhip.inst.inst.maib_and_tile.z1565a.ctp_tile_encrypted_inst.z1565a_inst.u_wrphy_top.pcs.i_pcie_pcs.upcs_clk_ctl.pcs_laneX_mpllb_sel[15:0] ='hFFFF;
         force `SOC_PCIE_QHIP.intel_pcie_ptile_ast_qhip.inst.inst.maib_and_tile.z1565a.ctp_tile_encrypted_inst.z1565a_inst.u_wrphy_top.pcs.i_pcie_pcs.upcs_clk_ctl.pcs_laneX_rate[47:0]= 'h6db6db6db6db;
         #1ps;

         fork
         begin
            @(posedge `SOC_PCIE_DUT.u_core16.u_ip.u_cfg.u_cfg_dbi_if.cfg_blk_done_o);
            #1ps;
            if( `SOC_PCIE_WRAPPER_SS.soc_pcie_ss.hssi_ctp_topology =="pcie_x8x8") begin
               release `SOC_PCIE_QHIP.intel_pcie_ptile_ast_qhip.inst.inst.maib_and_tile.z1565a.ctp_tile_encrypted_inst.z1565a_inst.u_wrphy_top.pcs.i_pcie_pcs.upcs_clk_ctl.pcs_laneX_rate[23:0];
               release `SOC_PCIE_QHIP.intel_pcie_ptile_ast_qhip.inst.inst.maib_and_tile.z1565a.ctp_tile_encrypted_inst.z1565a_inst.u_wrphy_top.pcs.i_pcie_pcs.upcs_clk_ctl.pcs_laneX_mpllb_sel[7:0];
            end 
            else begin
               release `SOC_PCIE_QHIP.intel_pcie_ptile_ast_qhip.inst.inst.maib_and_tile.z1565a.ctp_tile_encrypted_inst.z1565a_inst.u_wrphy_top.pcs.i_pcie_pcs.upcs_clk_ctl.pcs_laneX_rate[47:0];
               release `SOC_PCIE_QHIP.intel_pcie_ptile_ast_qhip.inst.inst.maib_and_tile.z1565a.ctp_tile_encrypted_inst.z1565a_inst.u_wrphy_top.pcs.i_pcie_pcs.upcs_clk_ctl.pcs_laneX_mpllb_sel[15:0];
            end
         end
         begin
            if(`SOC_PCIE_WRAPPER_SS.soc_pcie_ss.hssi_ctp_topology =="pcie_x8x8") begin
               @(posedge `SOC_PCIE_DUT.u_core8.u_ip.u_cfg.u_cfg_dbi_if.cfg_blk_done_o);
               #1ps;
               release `SOC_PCIE_QHIP.intel_pcie_ptile_ast_qhip.inst.inst.maib_and_tile.z1565a.ctp_tile_encrypted_inst.z1565a_inst.u_wrphy_top.pcs.i_pcie_pcs.upcs_clk_ctl.pcs_laneX_rate[47:24];
               release `SOC_PCIE_QHIP.intel_pcie_ptile_ast_qhip.inst.inst.maib_and_tile.z1565a.ctp_tile_encrypted_inst.z1565a_inst.u_wrphy_top.pcs.i_pcie_pcs.upcs_clk_ctl.pcs_laneX_mpllb_sel[15:8];
            end
         end
         join
         release `SOC_PCIE_QHIP.intel_pcie_ptile_ast_qhip.inst.inst.maib_and_tile.z1565a.ctp_tile_encrypted_inst.z1565a_inst.u_wrtilectrl.wrssm_aibaux_cnoc_clk_occ.uu_wrdft_ckmux21_inst.s0;
         release `SOC_PCIE_QHIP.intel_pcie_ptile_ast_qhip.inst.inst.maib_and_tile.z1565a.ctp_tile_encrypted_inst.z1565a_inst.u_wrtilectrl.wrssm_config_avmm_clk_div_mux.s0;
         //enable the DWIP to run in Fast link mode by forcing. 
         force `SOC_PCIE_DUT.u_core16.u_ip.u_dwc.diag_ctrl_bus[2] = 1'b1;
         force `SOC_PCIE_DUT.u_core8.u_ip.u_dwc.diag_ctrl_bus[2] = 1'b1;
 
   end
 `endif
   initial begin
      #1ps;

         force `HOST_PCIE_QHIP.intel_pcie_ptile_ast_qhip.inst.inst.maib_and_tile.z1565a.ctp_tile_encrypted_inst.z1565a_inst.u_wrtilectrl.wrssm_aibaux_cnoc_clk_occ.uu_wrdft_ckmux21_inst.ck1 = tbclk_1Ghz;
         force `HOST_PCIE_QHIP.intel_pcie_ptile_ast_qhip.inst.inst.maib_and_tile.z1565a.ctp_tile_encrypted_inst.z1565a_inst.u_wrtilectrl.wrssm_aibaux_cnoc_clk_occ.uu_wrdft_ckmux21_inst.s0=1;
         force `HOST_PCIE_QHIP.intel_pcie_ptile_ast_qhip.inst.inst.maib_and_tile.z1565a.ctp_tile_encrypted_inst.z1565a_inst.u_wrtilectrl.wrssm_config_avmm_clk_div_mux.s0=1;
         force `HOST_PCIE_QHIP.intel_pcie_ptile_ast_qhip.inst.inst.maib_and_tile.z1565a.ctp_tile_encrypted_inst.z1565a_inst.u_wrphy_top.pcs.i_pcie_pcs.upcs_clk_ctl.pcs_laneX_mpllb_sel[15:0] ='hFFFF;
         force `HOST_PCIE_QHIP.intel_pcie_ptile_ast_qhip.inst.inst.maib_and_tile.z1565a.ctp_tile_encrypted_inst.z1565a_inst.u_wrphy_top.pcs.i_pcie_pcs.upcs_clk_ctl.pcs_laneX_rate[47:0]= 'h6db6db6db6db;
         #1ps;

         fork
         begin
            @(posedge `HOST_PCIE_DUT.u_core16.u_ip.u_cfg.u_cfg_dbi_if.cfg_blk_done_o);
            #1ps;
            if( `HOST_PCIE_WRAPPER_SS.pcie_ss.hssi_ctp_topology =="pcie_x8x8") begin
               release `HOST_PCIE_QHIP.intel_pcie_ptile_ast_qhip.inst.inst.maib_and_tile.z1565a.ctp_tile_encrypted_inst.z1565a_inst.u_wrphy_top.pcs.i_pcie_pcs.upcs_clk_ctl.pcs_laneX_rate[23:0];
               release `HOST_PCIE_QHIP.intel_pcie_ptile_ast_qhip.inst.inst.maib_and_tile.z1565a.ctp_tile_encrypted_inst.z1565a_inst.u_wrphy_top.pcs.i_pcie_pcs.upcs_clk_ctl.pcs_laneX_mpllb_sel[7:0];
            end 
            else begin
               release `HOST_PCIE_QHIP.intel_pcie_ptile_ast_qhip.inst.inst.maib_and_tile.z1565a.ctp_tile_encrypted_inst.z1565a_inst.u_wrphy_top.pcs.i_pcie_pcs.upcs_clk_ctl.pcs_laneX_rate[47:0];
               release `HOST_PCIE_QHIP.intel_pcie_ptile_ast_qhip.inst.inst.maib_and_tile.z1565a.ctp_tile_encrypted_inst.z1565a_inst.u_wrphy_top.pcs.i_pcie_pcs.upcs_clk_ctl.pcs_laneX_mpllb_sel[15:0];
            end
         end
         begin
            if(`HOST_PCIE_WRAPPER_SS.pcie_ss.hssi_ctp_topology =="pcie_x8x8") begin
               @(posedge `HOST_PCIE_DUT.u_core8.u_ip.u_cfg.u_cfg_dbi_if.cfg_blk_done_o);
               #1ps;
               release `HOST_PCIE_QHIP.intel_pcie_ptile_ast_qhip.inst.inst.maib_and_tile.z1565a.ctp_tile_encrypted_inst.z1565a_inst.u_wrphy_top.pcs.i_pcie_pcs.upcs_clk_ctl.pcs_laneX_rate[47:24];
               release `HOST_PCIE_QHIP.intel_pcie_ptile_ast_qhip.inst.inst.maib_and_tile.z1565a.ctp_tile_encrypted_inst.z1565a_inst.u_wrphy_top.pcs.i_pcie_pcs.upcs_clk_ctl.pcs_laneX_mpllb_sel[15:8];
            end
         end
         join
         release `HOST_PCIE_QHIP.intel_pcie_ptile_ast_qhip.inst.inst.maib_and_tile.z1565a.ctp_tile_encrypted_inst.z1565a_inst.u_wrtilectrl.wrssm_aibaux_cnoc_clk_occ.uu_wrdft_ckmux21_inst.s0;
         release `HOST_PCIE_QHIP.intel_pcie_ptile_ast_qhip.inst.inst.maib_and_tile.z1565a.ctp_tile_encrypted_inst.z1565a_inst.u_wrtilectrl.wrssm_config_avmm_clk_div_mux.s0;
         //enable the DWIP to run in Fast link mode by forcing. 
         force `HOST_PCIE_DUT.u_core16.u_ip.u_dwc.diag_ctrl_bus[2] = 1'b1;
         force `HOST_PCIE_DUT.u_core8.u_ip.u_dwc.diag_ctrl_bus[2] = 1'b1;
 
   end

   `ifdef SIM_MODE
      initial begin
         #20us;
        force {tb_top.DUT.sys_pll.locked} = 1'b1;

        force tb_top.DUT.sys_pll.outclk_0 = outclk_0; 
        force tb_top.DUT.sys_pll.outclk_1 = outclk_1; 
        force tb_top.DUT.sys_pll.outclk_2 = outclk_2;
        force tb_top.DUT.sys_pll.outclk_3 = outclk_3;
        force tb_top.DUT.sys_pll.outclk_4 = outclk_4;

      end 
   `endif
 
  pmci_axi    pmci_axi(axi_if,m10_if);
  bmc_top     bmc_m10(m10_if);

  passive_vip passive_vip(axi_passive_if[0],axi_passive_if[1],axi_passive_if[2],axi_passive_if[3],axi_passive_if[4]); 
  `ifdef LPBK_WITHOUT_HSSI
    HE_HSSI_AXIS HE_HSSI_AXIS_INST(axis_HSSI_if);
  `endif
    initial #1us //Min RESET period is 1us
     PCIE_RESET_N = 1;
     initial #1us        soc_PCIE_RESET_N = 1;
     initial #1us        host_PCIE_RESET_N = 1;
     always #5ns SYS_RefClk  = ~SYS_RefClk;
     always #5ns PCIE_RefClk = ~PCIE_RefClk;
     always #3200 ETH_RefClk = ~ETH_RefClk;

     always #1063ps  outclk_0 = ~outclk_0; //470MHz
     always #4965ps  outclk_1 = ~outclk_1; //100.71MHz
     always #2837ps  outclk_2 = ~outclk_2; //176.243MHz
     always #3191ps  outclk_3 = ~outclk_3; //156.66MHz
     always #9929ps  outclk_4 = ~outclk_4; //50.358MHz

      
 
//AXI Lite 2 MMIO Monitors    
    `AXI_IF st2mm_csr_axil2mmio_if();
    `AXI_IF fme_axil2mmio_if();
    `AXI_IF pg_axil2mmio_if();
    st2mm_csr_axil2mmio_bind st2mm_csr_axil2mmio_bind(st2mm_csr_axil2mmio_if); 
    fme_axil2mmio_bind fme_axil2mmio_bind(fme_axil2mmio_if); 
    pg_axil2mmio_bind pg_axil2mmio_bind(pg_axil2mmio_if); 
    `ifdef INCLUDE_TOD
      `AXI_IF tod_axil2mmio_if();
      tod_axil2mmio_bind tod_axil2mmio_bind(tod_axil2mmio_if); 
    `endif   

    initial begin
        uvm_config_db#(virtual `AXI_IF)::set(uvm_root::get(), "*", "vif", axi_if);
        uvm_config_db#(virtual `AXI_IF)::set(uvm_root::get(), "uvm_test_top.tb_env0.st2mm_csr_axil2mmio_env", "vif", st2mm_csr_axil2mmio_if); 
        uvm_config_db#(virtual `AXI_IF)::set(uvm_root::get(), "uvm_test_top.tb_env0.fme_axil2mmio_env", "vif", fme_axil2mmio_if); 
        uvm_config_db#(virtual `AXI_IF)::set(uvm_root::get(), "uvm_test_top.tb_env0.pg_axil2mmio_env", "vif", pg_axil2mmio_if); 
        `ifdef INCLUDE_TOD
        uvm_config_db#(virtual `AXI_IF)::set(uvm_root::get(), "uvm_test_top.tb_env0.tod_axil2mmio_env", "vif", tod_axil2mmio_if); 
        `endif                                                               

       `ifdef LPBK_WITHOUT_HSSI
          uvm_config_db#(virtual `AXI_IF)::set(uvm_root::get(), "uvm_test_top.tb_env0.axis_HSSI_env", "vif", axis_HSSI_if);
       `endif
        uvm_config_db#(virtual m10_interface)::set(uvm_root::get(), "*", "m10_clk", m10_if);
        uvm_config_db#(virtual `AXI_IF)::set(uvm_root::get(), "uvm_test_top.tb_env0.PCie2AFU_BRIDGE", "vif", axi_passive_if[0]);
        uvm_config_db#(virtual `AXI_IF)::set(uvm_root::get(), "uvm_test_top.tb_env0.MUX2HE_HSSI_BRIDGE", "vif", axi_passive_if[1]);
        uvm_config_db#(virtual `AXI_IF)::set(uvm_root::get(), "uvm_test_top.tb_env0.HE_HSSI2HSSI_BRIDGE", "vif", axi_passive_if[2]);  //add here
        uvm_config_db#(virtual `AXI_IF)::set(uvm_root::get(), "uvm_test_top.tb_env0.BPF_BRIDGE", "vif", axi_passive_if[3]); 
        uvm_config_db#(virtual `AXI_IF)::set(uvm_root::get(), "uvm_test_top.tb_env0.SOCPCie2AFU_BRIDGE", "vif", axi_passive_if[4]);

       /** Set the reset interface on the virtual sequencer */
      //uvm_config_db#(virtual ethernet_reset_if.ethernet_reset_modport)::set(uvm_root::get(), "*", "reset_mp", ethernet_reset_if.ethernet_reset_modport);
      `ifdef ENABLE_SOC_HOST_COVERAGE
         uvm_config_db#(virtual coverage_intf)::set(uvm_root::get(), "*", "cov_intf", cov_intf);
      `endif
    end
     genvar index;
     generate
       for( index=0; index<8; index++) begin
         initial begin
         uvm_config_db#(virtual `ETH_TXRX_IF)::set(uvm_root::get(),$sformatf("uvm_test_top.tb_env0.env.vip_ethernet_mac[%0d]*",index), "if_port", mac_ethernet_if[index]);
         end
       end
     endgenerate

    initial begin
      fork begin
        #2;
        uvm_config_db#(int)::get(null, "uvm_test_top.tb_env0", "pmci_master", pmci_master); 
        uvm_config_db#(int)::get(null, "uvm_test_top.tb_env0", "bmc_en", bmc_en); 
      end
      begin
        run_test();
      end
      join_any
    // `uvm_info("SEED:", $sformatf("random seed = %0d \n", $get_initial_random_seed()), UVM_LOW);
    end     
endmodule : tb_top

