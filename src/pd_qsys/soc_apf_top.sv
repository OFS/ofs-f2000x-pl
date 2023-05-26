// Copyright (C) 2022 Intel Corporation.
// SPDX-License-Identifier: MIT

// Description
//-----------------------------------------------------------------------------
// SoC AFU Peripheral Fabric interface wrapper
//-----------------------------------------------------------------------------

module soc_apf_top (
   input logic clk,
   input logic rst_n,

   // APF managers
   ofs_fim_axi_lite_if.slave apf_st2mm_mst_if,
   ofs_fim_axi_lite_if.slave apf_bpf_mst_if,
   
   // APF functions
   ofs_fim_axi_lite_if.master apf_achk_slv_if,
   ofs_fim_axi_lite_if.master apf_bpf_slv_if,
   ofs_fim_axi_lite_if.master apf_st2mm_slv_if,
   ofs_fim_axi_lite_if.master apf_pr_slv_if
);
  
  
soc_apf apf_inst (
   .clk_clk             (clk),
   .rst_n_reset_n       (rst_n),

   .soc_apf_bpf_mst_awaddr  (apf_bpf_mst_if.awaddr),
   .soc_apf_bpf_mst_awprot  (apf_bpf_mst_if.awprot),
   .soc_apf_bpf_mst_awvalid (apf_bpf_mst_if.awvalid),
   .soc_apf_bpf_mst_awready (apf_bpf_mst_if.awready),
   .soc_apf_bpf_mst_wdata   (apf_bpf_mst_if.wdata),
   .soc_apf_bpf_mst_wstrb   (apf_bpf_mst_if.wstrb),
   .soc_apf_bpf_mst_wvalid  (apf_bpf_mst_if.wvalid),
   .soc_apf_bpf_mst_wready  (apf_bpf_mst_if.wready),
   .soc_apf_bpf_mst_bresp   (apf_bpf_mst_if.bresp),
   .soc_apf_bpf_mst_bvalid  (apf_bpf_mst_if.bvalid),
   .soc_apf_bpf_mst_bready  (apf_bpf_mst_if.bready),
   .soc_apf_bpf_mst_araddr  (apf_bpf_mst_if.araddr),
   .soc_apf_bpf_mst_arprot  (apf_bpf_mst_if.arprot),
   .soc_apf_bpf_mst_arvalid (apf_bpf_mst_if.arvalid),
   .soc_apf_bpf_mst_arready (apf_bpf_mst_if.arready),
   .soc_apf_bpf_mst_rdata   (apf_bpf_mst_if.rdata),
   .soc_apf_bpf_mst_rresp   (apf_bpf_mst_if.rresp),
   .soc_apf_bpf_mst_rvalid  (apf_bpf_mst_if.rvalid),
   .soc_apf_bpf_mst_rready  (apf_bpf_mst_if.rready),

   .soc_apf_st2mm_mst_awaddr  ( apf_st2mm_mst_if.awaddr),
   .soc_apf_st2mm_mst_awprot  ( apf_st2mm_mst_if.awprot),
   .soc_apf_st2mm_mst_awvalid ( apf_st2mm_mst_if.awvalid),
   .soc_apf_st2mm_mst_awready ( apf_st2mm_mst_if.awready),
   .soc_apf_st2mm_mst_wdata   ( apf_st2mm_mst_if.wdata),
   .soc_apf_st2mm_mst_wstrb   ( apf_st2mm_mst_if.wstrb),
   .soc_apf_st2mm_mst_wvalid  ( apf_st2mm_mst_if.wvalid),
   .soc_apf_st2mm_mst_wready  ( apf_st2mm_mst_if.wready),
   .soc_apf_st2mm_mst_bresp   ( apf_st2mm_mst_if.bresp),
   .soc_apf_st2mm_mst_bvalid  ( apf_st2mm_mst_if.bvalid),
   .soc_apf_st2mm_mst_bready  ( apf_st2mm_mst_if.bready),
   .soc_apf_st2mm_mst_araddr  ( apf_st2mm_mst_if.araddr),
   .soc_apf_st2mm_mst_arprot  ( apf_st2mm_mst_if.arprot),
   .soc_apf_st2mm_mst_arvalid ( apf_st2mm_mst_if.arvalid),
   .soc_apf_st2mm_mst_arready ( apf_st2mm_mst_if.arready),
   .soc_apf_st2mm_mst_rdata   ( apf_st2mm_mst_if.rdata),
   .soc_apf_st2mm_mst_rresp   ( apf_st2mm_mst_if.rresp),
   .soc_apf_st2mm_mst_rvalid  ( apf_st2mm_mst_if.rvalid),
   .soc_apf_st2mm_mst_rready  ( apf_st2mm_mst_if.rready),

   .soc_apf_achk_slv_awaddr  (apf_achk_slv_if.awaddr),
   .soc_apf_achk_slv_awprot  (apf_achk_slv_if.awprot),
   .soc_apf_achk_slv_awvalid (apf_achk_slv_if.awvalid),
   .soc_apf_achk_slv_awready (apf_achk_slv_if.awready),
   .soc_apf_achk_slv_wdata   (apf_achk_slv_if.wdata),
   .soc_apf_achk_slv_wstrb   (apf_achk_slv_if.wstrb),
   .soc_apf_achk_slv_wvalid  (apf_achk_slv_if.wvalid),
   .soc_apf_achk_slv_wready  (apf_achk_slv_if.wready),
   .soc_apf_achk_slv_bresp   (apf_achk_slv_if.bresp),
   .soc_apf_achk_slv_bvalid  (apf_achk_slv_if.bvalid),
   .soc_apf_achk_slv_bready  (apf_achk_slv_if.bready),
   .soc_apf_achk_slv_araddr  (apf_achk_slv_if.araddr),
   .soc_apf_achk_slv_arprot  (apf_achk_slv_if.arprot),
   .soc_apf_achk_slv_arvalid (apf_achk_slv_if.arvalid),
   .soc_apf_achk_slv_arready (apf_achk_slv_if.arready),
   .soc_apf_achk_slv_rdata   (apf_achk_slv_if.rdata),
   .soc_apf_achk_slv_rresp   (apf_achk_slv_if.rresp),
   .soc_apf_achk_slv_rvalid  (apf_achk_slv_if.rvalid),
   .soc_apf_achk_slv_rready  (apf_achk_slv_if.rready),
 
   .soc_apf_bpf_slv_awaddr  (apf_bpf_slv_if.awaddr),
   .soc_apf_bpf_slv_awprot  (apf_bpf_slv_if.awprot),
   .soc_apf_bpf_slv_awvalid (apf_bpf_slv_if.awvalid),
   .soc_apf_bpf_slv_awready (apf_bpf_slv_if.awready),
   .soc_apf_bpf_slv_wdata   (apf_bpf_slv_if.wdata),
   .soc_apf_bpf_slv_wstrb   (apf_bpf_slv_if.wstrb),
   .soc_apf_bpf_slv_wvalid  (apf_bpf_slv_if.wvalid),
   .soc_apf_bpf_slv_wready  (apf_bpf_slv_if.wready),
   .soc_apf_bpf_slv_bresp   (apf_bpf_slv_if.bresp),
   .soc_apf_bpf_slv_bvalid  (apf_bpf_slv_if.bvalid),
   .soc_apf_bpf_slv_bready  (apf_bpf_slv_if.bready),
   .soc_apf_bpf_slv_araddr  (apf_bpf_slv_if.araddr),
   .soc_apf_bpf_slv_arprot  (apf_bpf_slv_if.arprot),
   .soc_apf_bpf_slv_arvalid (apf_bpf_slv_if.arvalid),
   .soc_apf_bpf_slv_arready (apf_bpf_slv_if.arready),
   .soc_apf_bpf_slv_rdata   (apf_bpf_slv_if.rdata),
   .soc_apf_bpf_slv_rresp   (apf_bpf_slv_if.rresp),
   .soc_apf_bpf_slv_rvalid  (apf_bpf_slv_if.rvalid),
   .soc_apf_bpf_slv_rready  (apf_bpf_slv_if.rready),

   .soc_apf_st2mm_slv_awaddr  ( apf_st2mm_slv_if.awaddr),
   .soc_apf_st2mm_slv_awprot  ( apf_st2mm_slv_if.awprot),
   .soc_apf_st2mm_slv_awvalid ( apf_st2mm_slv_if.awvalid),
   .soc_apf_st2mm_slv_awready ( apf_st2mm_slv_if.awready),
   .soc_apf_st2mm_slv_wdata   ( apf_st2mm_slv_if.wdata),
   .soc_apf_st2mm_slv_wstrb   ( apf_st2mm_slv_if.wstrb),
   .soc_apf_st2mm_slv_wvalid  ( apf_st2mm_slv_if.wvalid),
   .soc_apf_st2mm_slv_wready  ( apf_st2mm_slv_if.wready),
   .soc_apf_st2mm_slv_bresp   ( apf_st2mm_slv_if.bresp),
   .soc_apf_st2mm_slv_bvalid  ( apf_st2mm_slv_if.bvalid),
   .soc_apf_st2mm_slv_bready  ( apf_st2mm_slv_if.bready),
   .soc_apf_st2mm_slv_araddr  ( apf_st2mm_slv_if.araddr),
   .soc_apf_st2mm_slv_arprot  ( apf_st2mm_slv_if.arprot),
   .soc_apf_st2mm_slv_arvalid ( apf_st2mm_slv_if.arvalid),
   .soc_apf_st2mm_slv_arready ( apf_st2mm_slv_if.arready),
   .soc_apf_st2mm_slv_rdata   ( apf_st2mm_slv_if.rdata),
   .soc_apf_st2mm_slv_rresp   ( apf_st2mm_slv_if.rresp),
   .soc_apf_st2mm_slv_rvalid  ( apf_st2mm_slv_if.rvalid),
   .soc_apf_st2mm_slv_rready  ( apf_st2mm_slv_if.rready),

   .soc_apf_pr_slv_awaddr  ( apf_pr_slv_if.awaddr),
   .soc_apf_pr_slv_awprot  ( apf_pr_slv_if.awprot),
   .soc_apf_pr_slv_awvalid ( apf_pr_slv_if.awvalid),
   .soc_apf_pr_slv_awready ( apf_pr_slv_if.awready),
   .soc_apf_pr_slv_wdata   ( apf_pr_slv_if.wdata),
   .soc_apf_pr_slv_wstrb   ( apf_pr_slv_if.wstrb),
   .soc_apf_pr_slv_wvalid  ( apf_pr_slv_if.wvalid),
   .soc_apf_pr_slv_wready  ( apf_pr_slv_if.wready),
   .soc_apf_pr_slv_bresp   ( apf_pr_slv_if.bresp),
   .soc_apf_pr_slv_bvalid  ( apf_pr_slv_if.bvalid),
   .soc_apf_pr_slv_bready  ( apf_pr_slv_if.bready),
   .soc_apf_pr_slv_araddr  ( apf_pr_slv_if.araddr),
   .soc_apf_pr_slv_arprot  ( apf_pr_slv_if.arprot),
   .soc_apf_pr_slv_arvalid ( apf_pr_slv_if.arvalid),
   .soc_apf_pr_slv_arready ( apf_pr_slv_if.arready),
   .soc_apf_pr_slv_rdata   ( apf_pr_slv_if.rdata),
   .soc_apf_pr_slv_rresp   ( apf_pr_slv_if.rresp),
   .soc_apf_pr_slv_rvalid  ( apf_pr_slv_if.rvalid),
   .soc_apf_pr_slv_rready  ( apf_pr_slv_if.rready)

  
);

endmodule
