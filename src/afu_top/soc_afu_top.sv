// Copyright (C) 2022 Intel Corporation.
// SPDX-License-Identifier: MIT

//
// Description
//-----------------------------------------------------------------------------
// AFU module instantiates User Logic
//-----------------------------------------------------------------------------

`ifdef INCLUDE_HSSI
   `include "ofs_fim_eth_plat_defines.svh"
`endif 


module soc_afu_top
   import ofs_fim_cfg_pkg::*;
   import soc_top_cfg_pkg::*;
   import pcie_ss_axis_pkg::*;
   `ifdef INCLUDE_HSSI
      import ofs_fim_eth_if_pkg::*;
   `endif
#(
   parameter AFU_MEM_CHANNEL = 0
)(
   input wire                            SYS_REFCLK,
   input wire                            clk,
   input wire                            rst_n,
   input wire                            clk_div2,
   input wire                            rst_n_clk_div2,
   
   input wire                            clk_csr,
   input wire                            rst_n_csr,
   input wire                            pwr_good_csr_clk_n,
   input wire                            clk_50m,
   input wire                            rst_n_50m,

   // FLR 
   input  t_axis_pcie_flr                pcie_flr_req,
   output t_axis_pcie_flr                pcie_flr_rsp,
   output logic                          pr_parity_error,
   input  t_pcie_tag_mode                tag_mode,

   ofs_fim_axi_lite_if.master            apf_bpf_slv_if,
   ofs_fim_axi_lite_if.slave             apf_bpf_mst_if,

   `ifdef INCLUDE_DDR4
      // Memory subsystem interface  
      ofs_fim_emif_axi_mm_if.user         ext_mem_if [AFU_MEM_CHANNEL-1:0],
   `endif

   `ifdef INCLUDE_HSSI
      ofs_fim_hssi_ss_tx_axis_if.client  hssi_ss_st_tx [MAX_NUM_ETH_CHANNELS-1:0],
      ofs_fim_hssi_ss_rx_axis_if.client  hssi_ss_st_rx [MAX_NUM_ETH_CHANNELS-1:0],
      ofs_fim_hssi_fc_if.client          hssi_fc [MAX_NUM_ETH_CHANNELS-1:0],
      `ifdef INCLUDE_PTP
         ofs_fim_hssi_ptp_tx_tod_if.client     hssi_ptp_tx_tod [MAX_NUM_ETH_CHANNELS-1:0],
         ofs_fim_hssi_ptp_rx_tod_if.client     hssi_ptp_rx_tod [MAX_NUM_ETH_CHANNELS-1:0],
         ofs_fim_hssi_ptp_tx_egrts_if.client   hssi_ptp_tx_egrts [MAX_NUM_ETH_CHANNELS-1:0],
         ofs_fim_hssi_ptp_rx_ingrts_if.client  hssi_ptp_rx_ingrts [MAX_NUM_ETH_CHANNELS-1:0],
         input logic                           i_ehip_clk_806,
         input logic                           i_ehip_clk_403,
         input logic                           i_ehip_pll_locked,
      `endif
      input logic [MAX_NUM_ETH_CHANNELS-1:0] i_hssi_clk_pll,
   `endif

   // PCIE subsystem TX/RX interface
   pcie_ss_axis_if.sink                  pcie_ss_axis_rxreq,
   pcie_ss_axis_if.sink                  pcie_ss_axis_rx,
   pcie_ss_axis_if.source                pcie_ss_axis_tx
);

//-------------------------------------------------------------------
// PF/VF Mapping Table 
//
//    +---------------------------------+
//    + Module          | PF/VF         +
//    +---------------------------------+
//    | ST2MM           | PF0           | 
//    | HE-MEM          | PF0-VF0       |
//    | HE-HSSI         | PF0-VF1       |
//    | HE-MEM_TG       | PF0-VF2       |
//    +---------------------------------+
//
//-------------------------------------------------------------------

localparam MM_ADDR_WIDTH     = ofs_fim_cfg_pkg::MMIO_ADDR_WIDTH;
localparam MM_DATA_WIDTH     = ofs_fim_cfg_pkg::MMIO_DATA_WIDTH;

localparam AFU_NUM_PORT        = soc_top_cfg_pkg::NUM_PORT;
localparam AFU_RTABLE_ENTRIES  = soc_top_cfg_pkg::NUM_RTABLE_ENTRIES;
localparam PG_AFU_NUM_PORTS    = soc_top_cfg_pkg::PG_AFU_NUM_PORTS;
localparam pf_vf_mux_pkg::t_pfvf_rtable_entry [AFU_RTABLE_ENTRIES-1:0] AFU_ROUTING_TABLE = soc_top_cfg_pkg::get_pf_vf_entry_info();
localparam NUM_SR_PORTS              = soc_top_cfg_pkg::NUM_SR_PORTS;
localparam int AFU_SR_PID [NUM_SR_PORTS] = soc_top_cfg_pkg::AFU_SR_MUX_PID;
   
localparam NUM_PF            = soc_top_cfg_pkg::FIM_NUM_PF;
localparam NUM_VF            = soc_top_cfg_pkg::FIM_NUM_VF;   
localparam MAX_NUM_VF        = soc_top_cfg_pkg::FIM_MAX_NUM_VF;

localparam MUX_NUM_FUNC      = NUM_PF + NUM_VF + 1 - PG_AFU_NUM_PORTS;
localparam PF_WIDTH          = soc_top_cfg_pkg::FIM_PF_WIDTH;
localparam VF_WIDTH          = soc_top_cfg_pkg::FIM_VF_WIDTH;

localparam PCIE_TDATA_WIDTH  = ofs_fim_cfg_pkg::PCIE_TDATA_WIDTH;
localparam PCIE_TUSER_WIDTH  = ofs_fim_cfg_pkg::PCIE_TUSER_WIDTH;

localparam NUM_TAGS  = ofs_pcie_ss_cfg_pkg::PCIE_EP_MAX_TAGS;

//---------------------------------------------------------------------------------------
// Preserve clocks
//---------------------------------------------------------------------------------------
// Make sure all clocks are consumed, in case AFUs don't use them,
// to avoid Quartus problems.
(* noprune *) logic clk_div2_q1, clk_div2_q2;

always_ff @(posedge clk_div2) begin
   clk_div2_q1 <= clk_div2_q2;
   clk_div2_q2 <= !clk_div2_q1;
end

//---------------------------------------------------------------------------------------
// AFU Peripheral Fabric (APF)
//---------------------------------------------------------------------------------------
//  AXI4-lite interfaces
ofs_fim_axi_lite_if #(.AWADDR_WIDTH(MM_ADDR_WIDTH), .ARADDR_WIDTH(MM_ADDR_WIDTH)) apf_st2mm_mst_if();
ofs_fim_axi_lite_if #(.AWADDR_WIDTH(16), .ARADDR_WIDTH(16))                       apf_st2mm_slv_if();
ofs_fim_axi_lite_if #(.AWADDR_WIDTH(16), .ARADDR_WIDTH(16))                       apf_pr_slv_if();
ofs_fim_axi_lite_if #(.AWADDR_WIDTH(MM_ADDR_WIDTH), .ARADDR_WIDTH(MM_ADDR_WIDTH)) apf_mctp_mst_if ();
ofs_fim_axi_lite_if #(.AWADDR_WIDTH(16), .ARADDR_WIDTH(16))                       apf_achk_slv_if ();
soc_apf_top apf (
   .clk   ( clk_csr   ),
   .rst_n ( rst_n_csr ),
   .*
);

//-------------------------------------
// Internal signals
//-------------------------------------

// Protocol checker ports
pcie_ss_axis_if #(
    .DATA_W (PCIE_TDATA_WIDTH),
    .USER_W (PCIE_TUSER_WIDTH)
 ) ho2mx_rxreq_port (.clk(clk), .rst_n(rst_n)),
   mx2ho_tx_port    (.clk(clk), .rst_n(rst_n)),
   // A/B arbiter local write commits to AFU, MMIO req
   arb2mx_rxreq_port(.clk(clk), .rst_n(rst_n));
   
// // A ports (PCIe SS RX traffic)
pcie_ss_axis_if #(
   .DATA_W (PCIE_TDATA_WIDTH),
   .USER_W (PCIE_TUSER_WIDTH)
) pipe2fn_rx_a_port [NUM_SR_PORTS-1:0](.clk(clk), .rst_n(rst_n));

pcie_ss_axis_if #(
   .DATA_W (PCIE_TDATA_WIDTH),
   .USER_W (PCIE_TUSER_WIDTH)
) mx2pipe_rx_a_port [MUX_NUM_FUNC-1:0](.clk(clk), .rst_n(rst_n));

// A ports (first tree of AFU TX ports)
pcie_ss_axis_if #(
   .DATA_W (PCIE_TDATA_WIDTH),
   .USER_W (PCIE_TUSER_WIDTH)
) fn2pipe_tx_a_port [NUM_SR_PORTS-1:0](.clk(clk), .rst_n(rst_n));

pcie_ss_axis_if #(
   .DATA_W (PCIE_TDATA_WIDTH),
   .USER_W (PCIE_TUSER_WIDTH)
) fn2mx_tx_a_port [MUX_NUM_FUNC-1:0](.clk(clk), .rst_n(rst_n));

// B PF/VF AFU side (local write completions)
pcie_ss_axis_if #(
   .DATA_W (PCIE_TDATA_WIDTH),
   .USER_W (PCIE_TUSER_WIDTH)
) mx2fn_rx_b_port [MUX_NUM_FUNC-1:0](.clk(clk), .rst_n(rst_n));

// B ports (second tree of AFU TX ports)
pcie_ss_axis_if #(
   .DATA_W (PCIE_TDATA_WIDTH),
   .USER_W (PCIE_TUSER_WIDTH)
) fn2mx_tx_b_port [MUX_NUM_FUNC-1:0](.clk(clk), .rst_n(rst_n));

pcie_ss_axis_if #(
   .DATA_W (PCIE_TDATA_WIDTH),
   .USER_W (PCIE_TUSER_WIDTH)
) ho2mx_rx_remap (.clk(clk), .rst_n(rst_n));

pcie_ss_axis_if #(
   .DATA_W (PCIE_TDATA_WIDTH),
   .USER_W (PCIE_TUSER_WIDTH)
) mx2ho_tx_remap[2](.clk(clk), .rst_n(rst_n));


pcie_ss_axis_if #(
   .DATA_W (PCIE_TDATA_WIDTH),
   .USER_W (PCIE_TUSER_WIDTH)
) sr_afu_rx_b_port [NUM_SR_PORTS-1:0]( .clk(clk), .rst_n(rst_n));

pcie_ss_axis_if #(
   .DATA_W (PCIE_TDATA_WIDTH),
   .USER_W (PCIE_TUSER_WIDTH)
) sr_afu_tx_b_port [NUM_SR_PORTS-1:0](.clk(clk), .rst_n(rst_n));            // B AFU

logic [PG_AFU_NUM_PORTS-1:0] pg_func_pf_rst_n;       // Port gasket FLR PF reset
logic [PG_AFU_NUM_PORTS-1:0] pg_func_vf_rst_n;       // Port gasket FLR VF reset

logic [NUM_SR_PORTS-1:0] fim_afu_func_pf_rst_n;       // fim_afu_instances FLR PF reset
logic [NUM_SR_PORTS-1:0] fim_afu_func_vf_rst_n;       // fim_afu_instances FLR VF reset
logic [NUM_SR_PORTS-1:0] fim_afu_port_rst_n;
logic [NUM_SR_PORTS-1:0] fim_afu_port_rst_n_csr;
logic [NUM_PF-1:0]              pf_flr_rst_n;
logic [NUM_PF-1:0][NUM_VF-1:0]  vf_flr_rst_n;

logic [1:0] pf_vf_fifo_err;
logic [1:0] pf_vf_fifo_perr;

logic       sel_mmio_rsp;
logic       read_flush_done;
logic       afu_softreset;


//---------------------------------------------------------------------------------------
//                                  Modules instances
//---------------------------------------------------------------------------------------

//----------------------------------------------------------------
// FLR reset controller 
//----------------------------------------------------------------
flr_rst_mgr #(
   .NUM_PF (NUM_PF),
   .NUM_VF (NUM_VF),
   .MAX_NUM_VF (MAX_NUM_VF)
) flr_rst_mgr (
   .clk_sys      (clk),             // Global clock
   .rst_n_sys    (rst_n),

   .clk_csr      (clk_csr),         // Clock for pcie_flr_req/rsp
   .rst_n_csr    (rst_n_csr),

   .pcie_flr_req (pcie_flr_req),
   .pcie_flr_rsp (pcie_flr_rsp),

   .pf_flr_rst_n (pf_flr_rst_n),
   .vf_flr_rst_n (vf_flr_rst_n)
);

//
// Macros for mapping port defintions to PF/VF resets. We use macros instead
// of functions to avoid problems with continuous assignment.
//

// Get the VF function level reset if VF is active for the function.
// If VF is not active, return a constant: not in reset.
`define GET_FUNC_VF_RST_N(PF, VF, VF_ACTIVE) ((VF_ACTIVE != 0) ? vf_flr_rst_n[PF][VF] : 1'b1)

// Construct the full reset for a function, combining PF and VF resets.
`define GET_FUNC_RST_N(PF, VF, VF_ACTIVE) (pf_flr_rst_n[PF] & `GET_FUNC_VF_RST_N(PF, VF, VF_ACTIVE))


//----------------------------------------------------------------
// AFU Interface and Protocol Checker
//----------------------------------------------------------------
   afu_intf #( 
      .ENABLE (1'b1),
      // The tag mapper is free to use all available tags in the
      // PCIe SS, independent of the limit imposed on AFUs by
      // ofs_pcie_ss_cfg_pkg::PCIE_EP_MAX_TAGS. The maximum tag
      // value has to take into account that 10 bit mode tags
      // shift to 256 and above.
      .PCIE_EP_MAX_TAGS (ofs_pcie_ss_cfg_pkg::PCIE_TILE_MAX_TAGS + 256)
   ) afu_intf_inst (
      .clk                (clk),
      .rst_n              (rst_n),
                          
      .clk_csr            (clk_csr), // Clock 100 MHz
      .rst_n_csr          (rst_n_csr),
      .pwr_good_csr_clk_n (pwr_good_csr_clk_n),
      
      .i_afu_softreset      (afu_softreset),

      .o_sel_mmio_rsp     ( sel_mmio_rsp    ),
      .o_read_flush_done  ( read_flush_done ),
      
      .h2a_axis_rx        ( pcie_ss_axis_rxreq ),
      .a2h_axis_tx        ( pcie_ss_axis_tx    ),
                          
      .csr_if             ( apf_achk_slv_if ),
                          
      .afu_axis_rx        ( ho2mx_rxreq_port ),
      .afu_axis_tx        ( mx2ho_tx_port )
  );
   
// Moving tag remap,arb & mux into this module
afu_host_channel afu_host_channel_inst (
   .clk            (clk),
   .rst_n          (rst_n),
   .ho2mx_rx_port  (pcie_ss_axis_rx),
   .mx2ho_tx_port,
   .ho2mx_rx_remap,
   .ho2mx_rxreq_port,
   .arb2mx_rxreq_port,
   .mx2ho_tx_remap,
   .tag_mode
);

// Primary PF/VF MUX ("A" ports). Map individual TX A ports from
// AFUs down to a single, merged A channel. The RX port from host
// to FPGA is demultiplexed and individual connections are forwarded
// to AFUs.
pf_vf_mux_w_params  #(
   .MUX_NAME("SOC_A"),
   .NUM_PORT(AFU_NUM_PORT),
   .NUM_RTABLE_ENTRIES(AFU_RTABLE_ENTRIES),
   .PFVF_ROUTING_TABLE(AFU_ROUTING_TABLE)
) pf_vf_mux_a (
   .clk             (clk               ),
   .rst_n           (rst_n             ),
   .ho2mx_rx_port   (arb2mx_rxreq_port ), // MMIO req & wr commits
   .mx2ho_tx_port   (mx2ho_tx_remap[0] ),
   .mx2fn_rx_port   (mx2pipe_rx_a_port ),
   .fn2mx_tx_port   (fn2mx_tx_a_port   ),
   .out_fifo_err    (pf_vf_fifo_err[0] ),
   .out_fifo_perr   (pf_vf_fifo_perr[0])
);

// Secondary PF/VF MUX ("B" ports). Only TX is implemented, since a
// single RX stream is sufficient. The RX input to the MUX is tied off.
// AFU B TX ports are multiplexed into a single TX B channel that is
// passed to the A/B MUX above.
pf_vf_mux_w_params   #(
   .MUX_NAME("SOC_B"),
   .NUM_PORT(AFU_NUM_PORT),
   .NUM_RTABLE_ENTRIES(AFU_RTABLE_ENTRIES),
   .PFVF_ROUTING_TABLE(AFU_ROUTING_TABLE)
) pf_vf_mux_b (
   .clk             (clk               ),
   .rst_n           (rst_n             ),
   .ho2mx_rx_port   (ho2mx_rx_remap    ), // RX Cpl
   .mx2ho_tx_port   (mx2ho_tx_remap[1] ),
   .mx2fn_rx_port   (mx2fn_rx_b_port   ),
   .fn2mx_tx_port   (fn2mx_tx_b_port   ),
   .out_fifo_err    (pf_vf_fifo_err[1] ),
   .out_fifo_perr   (pf_vf_fifo_perr[1])
);

// Create AXI-S Pipeline for Static Region (SR) PIDs 
genvar i;
generate
   for (i = 0; i < NUM_SR_PORTS; i = i + 1) begin : srp 
      axis_pipeline #(
         .TDATA_WIDTH (PCIE_TDATA_WIDTH),
         .TUSER_WIDTH (PCIE_TUSER_WIDTH)
      ) afu_sr_tx_pipeline (
         .clk    (clk),
         .rst_n  (rst_n),
         .axis_m (fn2mx_tx_a_port[AFU_SR_PID[i]]),
         .axis_s (fn2pipe_tx_a_port[i])
      );

      axis_pipeline #(
         .TDATA_WIDTH (PCIE_TDATA_WIDTH),
         .TUSER_WIDTH (PCIE_TUSER_WIDTH)
      ) afu_sr_rx_pipeline (
         .clk    (clk),
         .rst_n  (rst_n),
         .axis_m (pipe2fn_rx_a_port[i]),
         .axis_s (mx2pipe_rx_a_port[AFU_SR_PID[i]]) 
      );

      assign mx2fn_rx_b_port[AFU_SR_PID[i]].tready = sr_afu_rx_b_port[i].tready;
      assign sr_afu_rx_b_port[i].tvalid       = mx2fn_rx_b_port[AFU_SR_PID[i]].tvalid;
      assign sr_afu_rx_b_port[i].tlast        = mx2fn_rx_b_port[AFU_SR_PID[i]].tlast;
      assign sr_afu_rx_b_port[i].tuser_vendor = mx2fn_rx_b_port[AFU_SR_PID[i]].tuser_vendor;
      assign sr_afu_rx_b_port[i].tdata        = mx2fn_rx_b_port[AFU_SR_PID[i]].tdata;
      assign sr_afu_rx_b_port[i].tkeep        = mx2fn_rx_b_port[AFU_SR_PID[i]].tkeep;

      assign sr_afu_tx_b_port[i].tready                  = fn2mx_tx_b_port[AFU_SR_PID[i]].tready;
      assign fn2mx_tx_b_port[AFU_SR_PID[i]].tvalid       = sr_afu_tx_b_port[i].tvalid;
      assign fn2mx_tx_b_port[AFU_SR_PID[i]].tlast        = sr_afu_tx_b_port[i].tlast;
      assign fn2mx_tx_b_port[AFU_SR_PID[i]].tuser_vendor = sr_afu_tx_b_port[i].tuser_vendor;
      assign fn2mx_tx_b_port[AFU_SR_PID[i]].tdata        = sr_afu_tx_b_port[i].tdata;
      assign fn2mx_tx_b_port[AFU_SR_PID[i]].tkeep        = sr_afu_tx_b_port[i].tkeep;

   end
endgenerate

// Map the PF/VF association of Static Region and PR Region ports 
// to the parameters that will be passed to the port gasket and 
// fim_afu_instances.

localparam soc_top_cfg_pkg::t_soc_sr_afu_pf_vf_info SR_PF_VF_INFO = soc_top_cfg_pkg::get_soc_sr_pf_vf_info();

// Mapping FLR rst to fim_afu vector
generate
   for (genvar p = 0; p < NUM_SR_PORTS; p = p + 1)
   begin : fim_afu_rst_vector
      assign fim_afu_func_pf_rst_n[p] = pf_flr_rst_n[soc_top_cfg_pkg::PG_SR_PORTS_PF_NUM[p]];
      assign fim_afu_func_vf_rst_n[p] = `GET_FUNC_VF_RST_N(soc_top_cfg_pkg::PG_SR_PORTS_PF_NUM[p],
                                                      soc_top_cfg_pkg::PG_SR_PORTS_VF_NUM[p],
                                                      soc_top_cfg_pkg::PG_SR_PORTS_VF_ACTIVE[p]);
      // Reset generation for each PCIe port 
      // Reset sources
      // - PF Flr 
      // - VF Flr
      // - PCIe system reset
      always @(posedge clk) fim_afu_port_rst_n[p] <= fim_afu_func_pf_rst_n[p] && fim_afu_func_vf_rst_n[p] && rst_n;

      // Sync to clk_csr
      fim_resync #(
         .SYNC_CHAIN_LENGTH (2),
         .WIDTH             (1),
         .INIT_VALUE        (1),
         .NO_CUT            (0)
       ) port_rst_csr_sync (
        .clk   (clk_csr),
        .reset (1'b0),
        .d     (fim_afu_port_rst_n[p]),
        .q     (fim_afu_port_rst_n_csr[p])
      );
   end
endgenerate

fim_afu_instances #(
   .NUM_SR_PORTS  (NUM_SR_PORTS),
   .SR_PF_VF_INFO (SR_PF_VF_INFO),
   .NUM_PF        (NUM_PF),
   .NUM_VF        (NUM_VF)
) fim_afu_instances (
   .clk                (clk),
   .rst_n              (rst_n),
   .func_pf_rst_n      (fim_afu_func_pf_rst_n),
   .func_vf_rst_n      (fim_afu_func_vf_rst_n),
   .port_rst_n         (fim_afu_port_rst_n),  
   .clk_csr            (clk_csr),
   .rst_n_csr          (rst_n_csr),
   .apf_mctp_mst_if    (apf_mctp_mst_if),
   .apf_st2mm_mst_if   (apf_st2mm_mst_if),
   .apf_st2mm_slv_if   (apf_st2mm_slv_if),
   `ifdef INCLUDE_PTP
      .hssi_ptp_tx_tod    (hssi_ptp_tx_tod),
      .hssi_ptp_rx_tod    (hssi_ptp_rx_tod),
      .hssi_ptp_tx_egrts  (hssi_ptp_tx_egrts),
      .hssi_ptp_rx_ingrts (hssi_ptp_rx_ingrts),
      .i_ehip_clk_806     (i_ehip_clk_806),
      .i_ehip_clk_403     (i_ehip_clk_403),
      .i_ehip_pll_locked  (i_ehip_pll_locked),
   `endif
   .afu_axi_rx_a_if    (pipe2fn_rx_a_port),
   .afu_axi_tx_a_if    (fn2pipe_tx_a_port),
   .afu_axi_rx_b_if    (sr_afu_rx_b_port),
   .afu_axi_tx_b_if    (sr_afu_tx_b_port) 
);

//----------------------------------------------------------------
// Port Gasket
//----------------------------------------------------------------
localparam soc_top_cfg_pkg::t_pg_afu_pf_vf_info PG_PF_VF_INFO = soc_top_cfg_pkg::get_pg_pf_vf_info();
localparam PG_RTABLE_ENTRIES = soc_top_cfg_pkg::PG_NUM_RTABLE_ENTRIES;
localparam pf_vf_mux_pkg::t_pfvf_rtable_entry [PG_RTABLE_ENTRIES-1:0] PG_PFVF_ROUTING_TABLE = soc_top_cfg_pkg::get_prr_pf_vf_entry_info();

// Mapping FLR rst to port vector
generate
   for (genvar p = 0; p < PG_AFU_NUM_PORTS; p = p + 1)
   begin : port_afu_flr_vector
      assign pg_func_pf_rst_n[p] = pf_flr_rst_n[soc_top_cfg_pkg::PG_AFU_PORTS_PF_NUM[p]];
      assign pg_func_vf_rst_n[p] = `GET_FUNC_VF_RST_N(soc_top_cfg_pkg::PG_AFU_PORTS_PF_NUM[p],
                                                      soc_top_cfg_pkg::PG_AFU_PORTS_VF_NUM[p],
                                                      soc_top_cfg_pkg::PG_AFU_PORTS_VF_ACTIVE[p]);
   end
endgenerate

port_gasket #( 
   .PG_NUM_PORTS(PG_AFU_NUM_PORTS),              // Number of PCIe ports to PR region
   .PORT_PF_VF_INFO(PG_PF_VF_INFO),             // PCIe port data
   .NUM_MEM_CH(AFU_MEM_CHANNEL),                 // Number of Memory Porst to PR region
   .END_OF_LIST    (1'b0),                       // port_gasket DFH end of list field
   .NEXT_DFH_OFFSET(24'h10000),                   // Next offset in OFS management DFH
   .PG_NUM_RTABLE_ENTRIES (PG_RTABLE_ENTRIES),
   .PG_PFVF_ROUTING_TABLE (PG_PFVF_ROUTING_TABLE)
) port_gasket(
   .refclk              (SYS_REFCLK),            // 100 MHz refclk for user clk pll
   .clk                 ,                        // PCIe Clk
   .clk_div2,                                    // Half frequency of PCIe clk
   .clk_div4           (clk),
   .clk_100            (clk_csr),                // 100 MHz for user clk logic
   .clk_csr            (clk_csr),                // 100 MHz CSR interface clock

   .rst_n,                                       // Reset from hip
   .rst_n_100          (rst_n_csr),              // Reset from hip on csr clk
   .rst_n_csr          (rst_n_csr),              // Reset from hip on csr clk
   .func_pf_rst_n      (pg_func_pf_rst_n),       // PF FLR 
   .func_vf_rst_n      (pg_func_vf_rst_n),       // VF FLR for each port

   `ifdef INCLUDE_DDR4
      .afu_mem_if      (ext_mem_if),             // Memory interface
   `endif

   `ifdef INCLUDE_HSSI                           // Instantiates HE-HSSI in PR region   
      .hssi_ss_st_tx  (hssi_ss_st_tx),           // HSSI Tx
      .hssi_ss_st_rx  (hssi_ss_st_rx),           // HSSI Rx
      .hssi_fc        (hssi_fc),                 // Flow control interface
      .i_hssi_clk_pll (i_hssi_clk_pll),          // HSSI clocks
   `endif

   .i_sel_mmio_rsp     (sel_mmio_rsp),
   .i_read_flush_done  (read_flush_done),
   .o_afu_softreset    (afu_softreset),
   .o_pr_parity_error  (pr_parity_error),        // Partial Reconfiguration FIFO Parity Error Indication from PR Controller.

   .axi_rx_a_if        (mx2pipe_rx_a_port[PG_SHARED_VF_PID]),  // PCIe intf on clk_2x
   .axi_tx_a_if        (fn2mx_tx_a_port[PG_SHARED_VF_PID]),    // PCIe intf on clk_2x
   .axi_rx_b_if        (mx2fn_rx_b_port[PG_SHARED_VF_PID]),    // PCIe intf on clk_2x
   .axi_tx_b_if        (fn2mx_tx_b_port[PG_SHARED_VF_PID]),   // PCIe intf on clk_2x

   .axi_s_if           (apf_pr_slv_if)         // CSR interface from APF
);

//----------------------------------------------------------------
// MCTP management interface 
//----------------------------------------------------------------
always_ff @ (posedge clk_csr) 
begin
   apf_mctp_mst_if.bvalid   = apf_mctp_mst_if.wvalid;
   apf_mctp_mst_if.rvalid   = apf_mctp_mst_if.arvalid;
   apf_mctp_mst_if.awready  = 1'b1;
   apf_mctp_mst_if.wready   = 1'b1;
   apf_mctp_mst_if.arready  = 1'b1;
   apf_mctp_mst_if.bready   = 1'b1;
   apf_mctp_mst_if.rready   = 1'b1;
end

endmodule
