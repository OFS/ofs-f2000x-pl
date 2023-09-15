// Copyright (C) 2022 Intel Corporation.
// SPDX-License-Identifier: MIT

//
// Description
//-----------------------------------------------------------------------------
// AFU module instantiates host PCIe attached User Logic
//-----------------------------------------------------------------------------

`ifdef INCLUDE_HSSI
   `include "ofs_fim_eth_plat_defines.svh"
`endif 


module afu_top 
   import ofs_fim_cfg_pkg::*;
   import pcie_ss_axis_pkg::*;
   import top_cfg_pkg::*;
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
   input wire                            clk_div4,
   
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


   // PCIE subsystem TX/RX interface
   pcie_ss_axis_if.sink                  pcie_ss_axis_rxreq,
   pcie_ss_axis_if.sink                  pcie_ss_axis_rx,
   pcie_ss_axis_if.source                pcie_ss_axis_tx,
   pcie_ss_axis_if.source                pcie_ss_axis_txreq
);

//-------------------------------------------------------------------
// PF/VF Mapping Table 
//
//    +---------------------------------+
//    + Module          | PF/VF         +
//    +---------------------------------+
//    | ST2MM           | PF0           | 
//    | HE-LB           | PF1           |
//    +---------------------------------+
//
//-------------------------------------------------------------------

localparam MM_ADDR_WIDTH     = ofs_fim_cfg_pkg::MMIO_ADDR_WIDTH;
localparam MM_DATA_WIDTH     = ofs_fim_cfg_pkg::MMIO_DATA_WIDTH;

localparam AFU_NUM_PORT        = top_cfg_pkg::NUM_PORT;
localparam AFU_RTABLE_ENTRIES  = top_cfg_pkg::NUM_RTABLE_ENTRIES;
localparam top_cfg_pkg::t_pf_vf_entry_info AFU_ROUTING_TABLE = top_cfg_pkg::SR_PF_VF_RTABLE;
localparam NUM_SR_PORTS        = top_cfg_pkg::NUM_SR_PORTS;
   

   
localparam NUM_PF         = top_cfg_pkg::FIM_NUM_PF;
localparam NUM_VF         = top_cfg_pkg::FIM_NUM_VF;
localparam MAX_NUM_VF     = top_cfg_pkg::FIM_MAX_NUM_VF;

localparam NUM_FUNC          = NUM_PF + NUM_VF;
localparam PF_WIDTH          = top_cfg_pkg::FIM_PF_WIDTH; 
localparam VF_WIDTH          = top_cfg_pkg::FIM_VF_WIDTH; 

localparam PCIE_TDATA_WIDTH  = ofs_fim_cfg_pkg::PCIE_TDATA_WIDTH;
localparam PCIE_TUSER_WIDTH  = ofs_fim_cfg_pkg::PCIE_TUSER_WIDTH;

localparam NUM_TAGS  = ofs_pcie_ss_cfg_pkg::PCIE_EP_MAX_TAGS;

//-------------------------------------
// Preserve clocks
//-------------------------------------

// Make sure all clocks are consumed, in case AFUs don't use them,
// to avoid Quartus problems.
(* noprune *) logic clk_div2_q1, clk_div2_q2;

always_ff @(posedge clk_div2) begin
   clk_div2_q1 <= clk_div2_q2;
   clk_div2_q2 <= !clk_div2_q1;
end


//-----------------------------------------------------------------------------------------------
// AFU Peripheral Fabric (APF)
//-----------------------------------------------------------------------------------------------
// This is the AXI-Lite interconnect fabric associated with PF0. It contains AFU feature interfaces 
// local to this hierarchy (only protocol checker on host side of SoC attached design) A board 
// peripheral fabric (BPF) interface that exposes board (top) level features in a separate memory map 
// partition (only PCIe on host side of SoC attached design), and services the interconnect 
// requirements of features in the OFS FIM (Management Component Transport Protocol (MCTP) messages 
// from Xeon host to board management)
//   
// The fabrics are generated using scripts with a text file, with the components and the address 
// map, as the input. Please refer to the README in $OFS_ROOTDIR/src/pd_qsys for more details. This
// script also generates the fabric_width_pkg used below so that the widths of address busses are 
// consistent with the input specified. 
// In order to remove/add components to the DFL list, modify the qsys fabric in 
// src/pd_qsys to add/delete the component and then edit the list below to add/remove the interface. 
// If adding a component connect up the port to the new instance.
//-----------------------------------------------------------------------------------------------

//  AXI4-lite interfaces
ofs_fim_axi_lite_if #(.AWADDR_WIDTH(MM_ADDR_WIDTH), .ARADDR_WIDTH(MM_ADDR_WIDTH)) apf_st2mm_mst_if();
ofs_fim_axi_lite_if #(.AWADDR_WIDTH(16), .ARADDR_WIDTH(16))                       apf_st2mm_slv_if();
ofs_fim_axi_lite_if #(.AWADDR_WIDTH(16), .ARADDR_WIDTH(16))                       apf_pr_slv_if();
ofs_fim_axi_lite_if #(.AWADDR_WIDTH(MM_ADDR_WIDTH), .ARADDR_WIDTH(MM_ADDR_WIDTH)) apf_mctp_mst_if();
ofs_fim_axi_lite_if #(.AWADDR_WIDTH(16), .ARADDR_WIDTH(16))                       apf_achk_slv_if();

apf_top apf (
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
   mx2ho_tx_port    (.clk(clk), .rst_n(rst_n));
   
// // A ports (PCIe SS RX traffic)
pcie_ss_axis_if #(
   .DATA_W (PCIE_TDATA_WIDTH),
   .USER_W (PCIE_TUSER_WIDTH)
) pipe2fn_rx_a_port [NUM_SR_PORTS-1:0](.clk(clk), .rst_n(rst_n));

pcie_ss_axis_if #(
    .DATA_W (pcie_ss_hdr_pkg::HDR_WIDTH),
    .USER_W (PCIE_TUSER_WIDTH)
 ) mx2ho_txreq_port (.clk (clk), .rst_n(rst_n));

pcie_ss_axis_if #(
   .DATA_W (PCIE_TDATA_WIDTH),
   .USER_W (PCIE_TUSER_WIDTH)
) mx2pipe_rx_a_port [NUM_FUNC-1:0](.clk(clk), .rst_n(rst_n));

// A ports (first tree of AFU TX ports)
pcie_ss_axis_if #(
   .DATA_W (PCIE_TDATA_WIDTH),
   .USER_W (PCIE_TUSER_WIDTH)
) fn2pipe_tx_a_port [NUM_SR_PORTS-1:0](.clk(clk), .rst_n(rst_n));

pcie_ss_axis_if #(
   .DATA_W (PCIE_TDATA_WIDTH),
   .USER_W (PCIE_TUSER_WIDTH)
) fn2mx_tx_a_port [NUM_FUNC-1:0](.clk(clk), .rst_n(rst_n));

// B PF/VF AFU side (local write completions)
pcie_ss_axis_if #(
   .DATA_W (PCIE_TDATA_WIDTH),
   .USER_W (PCIE_TUSER_WIDTH)
) mx2fn_rx_b_port [NUM_FUNC-1:0](.clk(clk), .rst_n(rst_n));

// B ports (second tree of AFU TX ports)
pcie_ss_axis_if #(
   .DATA_W (PCIE_TDATA_WIDTH),
   .USER_W (PCIE_TUSER_WIDTH)
) fn2mx_tx_b_port [NUM_FUNC-1:0](.clk(clk), .rst_n(rst_n));

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
) ho2mx_rxreq_remap(.clk(clk), .rst_n(rst_n));

pcie_ss_axis_if #(
   .DATA_W (PCIE_TDATA_WIDTH),
   .USER_W (PCIE_TUSER_WIDTH)
) sr_afu_rx_b_port [NUM_SR_PORTS-1:0]( .clk(clk), .rst_n(rst_n));

pcie_ss_axis_if #(
   .DATA_W (PCIE_TDATA_WIDTH),
   .USER_W (PCIE_TUSER_WIDTH)
) sr_afu_tx_b_port [NUM_SR_PORTS-1:0](.clk(clk), .rst_n(rst_n));            // B AFU

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


//-----------------------------------------------------------------------------------------------
// AFU Interface and Protocol Checker
//-----------------------------------------------------------------------------------------------
// Provides protection to the host PCIe channel from erroneous downstream behavior including:
//    - Malformed requests
//    - Data overrun/underrun
//    - Unsolicited completions   
//    - Completion timeouts
//-----------------------------------------------------------------------------------------------
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
   
   .i_afu_softreset      ('0),

   .o_sel_mmio_rsp     ( sel_mmio_rsp    ),
   .o_read_flush_done  ( read_flush_done ),
   
   .h2a_axis_rx        ( pcie_ss_axis_rxreq ),

   .a2h_axis_tx        ( pcie_ss_axis_tx    ),
   .a2h_axis_txreq     ( pcie_ss_axis_txreq ),
                       
   .csr_if             ( apf_achk_slv_if ),
                       
   .afu_axis_rx        ( ho2mx_rxreq_port ),
   .afu_axis_tx        ( mx2ho_tx_port ),
   .afu_axis_txreq     ( mx2ho_txreq_port )
);

//-----------------------------------------------------------------------------------------------
// AFU host fabric
//-----------------------------------------------------------------------------------------------
//    - Host channel interface transformations
//    - PF/VF Routing
//-----------------------------------------------------------------------------------------------

// Transformations required by the host PCIe interface: 
//    - Tag remapping: remap posted transaction tags to a unique tag from a shared tag pool.
//
//    - routing & arbitration: Route DMRd from "B" Port to TXREQ
//                             arbitrate other traffic channels to TX
afu_host_channel afu_host_channel_inst (
   .clk            (clk),
   .rst_n          (rst_n),
   .ho2mx_rx_port  (pcie_ss_axis_rx),
   .mx2ho_tx_port,
   .mx2ho_txreq_port,
   .ho2mx_rx_remap,
   .ho2mx_rxreq_port,
   .ho2mx_rxreq_remap,
   .mx2ho_tx_remap,
   .tag_mode
);

// Primary PF/VF MUX ("A" ports). Map individual TX A ports from
// AFUs down to a single, merged A channel. The RX port from host
// to FPGA is demultiplexed and individual connections are forwarded
// to AFUs.
pf_vf_mux_w_params  #(
   .MUX_NAME("A"),
   .NUM_PORT(AFU_NUM_PORT),
   .NUM_RTABLE_ENTRIES(AFU_RTABLE_ENTRIES),
   .PFVF_ROUTING_TABLE(AFU_ROUTING_TABLE)
) pf_vf_mux_a (
   .clk             (clk               ),
   .rst_n           (rst_n             ),
   .ho2mx_rx_port   (ho2mx_rxreq_remap ), // MMIO req & wr commits
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
   .MUX_NAME("B"),
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

//-----------------------------------------------------------------------------------------------
// Static Region (SR) AFU (fim_afu_instances)
//-----------------------------------------------------------------------------------------------
// This block implements the static region AFU. In the reference implementation separate 
// physical interfaces are created for each function mapped to this region. They are ST2MM (PF0) 
// and HE-LB (PF1). For the SoC attach design the host attached side only implements static region 
// logic.
//-----------------------------------------------------------------------------------------------

// Create AXI-S Pipeline for SR PIDs 
genvar i;
generate
   for (i = 0; i < NUM_SR_PORTS; i = i + 1) begin : srp 
      axis_pipeline #(
         .TDATA_WIDTH (PCIE_TDATA_WIDTH),
         .TUSER_WIDTH (PCIE_TUSER_WIDTH)
      ) afu_sr_tx_pipeline (
         .clk    (clk),
         .rst_n  (rst_n),
         .axis_m (fn2mx_tx_a_port[i]),
         .axis_s (fn2pipe_tx_a_port[i])
      );

      axis_pipeline #(
         .TDATA_WIDTH (PCIE_TDATA_WIDTH),
         .TUSER_WIDTH (PCIE_TUSER_WIDTH)
      ) afu_sr_rx_pipeline (
         .clk    (clk),
         .rst_n  (rst_n),
         .axis_m (pipe2fn_rx_a_port[i]),
         .axis_s (mx2pipe_rx_a_port[i]) 
      );

      assign mx2fn_rx_b_port[i].tready        = sr_afu_rx_b_port[i].tready;
      assign sr_afu_rx_b_port[i].tvalid       = mx2fn_rx_b_port[i].tvalid;
      assign sr_afu_rx_b_port[i].tlast        = mx2fn_rx_b_port[i].tlast;
      assign sr_afu_rx_b_port[i].tuser_vendor = mx2fn_rx_b_port[i].tuser_vendor;
      assign sr_afu_rx_b_port[i].tdata        = mx2fn_rx_b_port[i].tdata;
      assign sr_afu_rx_b_port[i].tkeep        = mx2fn_rx_b_port[i].tkeep;

      assign sr_afu_tx_b_port[i].tready       = fn2mx_tx_b_port[i].tready;
      assign fn2mx_tx_b_port[i].tvalid        = sr_afu_tx_b_port[i].tvalid;
      assign fn2mx_tx_b_port[i].tlast         = sr_afu_tx_b_port[i].tlast;
      assign fn2mx_tx_b_port[i].tuser_vendor  = sr_afu_tx_b_port[i].tuser_vendor;
      assign fn2mx_tx_b_port[i].tdata         = sr_afu_tx_b_port[i].tdata;
      assign fn2mx_tx_b_port[i].tkeep         = sr_afu_tx_b_port[i].tkeep;

   end
endgenerate
   

// Map the PF/VF association of Static Region
// to the parameters that will be passed to
// fim_afu_instances.
typedef pcie_ss_hdr_pkg::ReqHdr_pf_vf_info_t[NUM_SR_PORTS-1:0] t_afu_sr_pf_vf_map;
function automatic t_afu_sr_pf_vf_map gen_sr_pf_vf_map();
   t_afu_sr_pf_vf_map map;
   for (int p = 0; p < NUM_SR_PORTS; p = p + 1) begin
      map[p].pf_num = SR_PF_VF_RTABLE[p].pf;
      map[p].vf_num = SR_PF_VF_RTABLE[p].vf;
      map[p].vf_active = SR_PF_VF_RTABLE[p].vf_active;
   end
   return map;
endfunction // gen_pf_vf_map

localparam pcie_ss_hdr_pkg::ReqHdr_pf_vf_info_t[NUM_SR_PORTS-1:0] SR_PF_VF_INFO =
   gen_sr_pf_vf_map();

// Mapping FLR rst to fim_afu vector
generate
   for (genvar p = 0; p < NUM_SR_PORTS; p = p + 1)
   begin : fim_afu_rst_vector
      assign fim_afu_func_pf_rst_n[p] = pf_flr_rst_n[SR_PF_VF_RTABLE[p].pf];
      assign fim_afu_func_vf_rst_n[p] = `GET_FUNC_VF_RST_N(SR_PF_VF_RTABLE[p].pf,
                                                           SR_PF_VF_RTABLE[p].vf,
                                                           SR_PF_VF_RTABLE[p].vf_active);
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
   .afu_axi_rx_a_if    (pipe2fn_rx_a_port),
   .afu_axi_tx_a_if    (fn2pipe_tx_a_port),
   .afu_axi_rx_b_if    (sr_afu_rx_b_port),
   .afu_axi_tx_b_if    (sr_afu_tx_b_port) 
);

//----------------------------------------------------------------
// MCTP management interface 
//----------------------------------------------------------------
always_comb 
begin
   apf_mctp_mst_if.bready  = 1'b1;
   apf_mctp_mst_if.rready  = 1'b1;
end


endmodule
