// Copyright (C) 2022 Intel Corporation.
// SPDX-License-Identifier: MIT

//
// Description
//-----------------------------------------------------------------------------
// AFU module instantiates SoC PCIe attached User Logic
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

`ifdef INCLUDE_DDR4
   // Memory subsystem interface
   ofs_fim_emif_axi_mm_if.user           ext_mem_if [AFU_MEM_CHANNEL-1:0],
`endif

`ifdef INCLUDE_HSSI
   ofs_fim_hssi_ss_tx_axis_if.client  hssi_ss_st_tx [MAX_NUM_ETH_CHANNELS-1:0],
   ofs_fim_hssi_ss_rx_axis_if.client  hssi_ss_st_rx [MAX_NUM_ETH_CHANNELS-1:0],
   ofs_fim_hssi_fc_if.client          hssi_fc [MAX_NUM_ETH_CHANNELS-1:0],
   input logic [MAX_NUM_ETH_CHANNELS-1:0] i_hssi_clk_pll,
`endif

   // PCIE subsystem TX/RX interface
   pcie_ss_axis_if.sink                  pcie_ss_axis_rxreq,
   pcie_ss_axis_if.sink                  pcie_ss_axis_rx,
   pcie_ss_axis_if.source                pcie_ss_axis_tx,
   pcie_ss_axis_if.source                pcie_ss_axis_txreq
);

//-----------------------------------------------------------------------------------------------
// Local configuration
//-----------------------------------------------------------------------------------------------
localparam MM_ADDR_WIDTH      = ofs_fim_cfg_pkg::MMIO_ADDR_WIDTH;
localparam MM_DATA_WIDTH      = ofs_fim_cfg_pkg::MMIO_DATA_WIDTH;

localparam PCIE_TDATA_WIDTH   = ofs_fim_cfg_pkg::PCIE_TDATA_WIDTH;
localparam PCIE_TUSER_WIDTH   = ofs_fim_cfg_pkg::PCIE_TUSER_WIDTH;

localparam NUM_MUX_PORTS      = soc_top_cfg_pkg::NUM_TOP_PORTS;
localparam NUM_RTABLE_ENTRIES = soc_top_cfg_pkg::NUM_TOP_RTABLE_ENTRIES;
localparam t_top_pf_vf_entry_info PFVF_ROUTING_TABLE = soc_top_cfg_pkg::TOP_PF_VF_RTABLE;


//-----------------------------------------------------------------------------------------------
// Internal signals
//-----------------------------------------------------------------------------------------------
// AXI-ST TLP interfaces
pcie_ss_axis_if #(
   .DATA_W (PCIE_TDATA_WIDTH),
   .USER_W (PCIE_TUSER_WIDTH))
   // Host channel transformation interface
   mx2ho_tx_port     (.clk(clk), .rst_n(rst_n)),
   ho2mx_rxreq_port  (.clk(clk), .rst_n(rst_n)),
   // Tag remapper
   ho2mx_rx_remap    (.clk(clk), .rst_n(rst_n)),
   ho2mx_rxreq_remap (.clk(clk), .rst_n(rst_n)),
   mx2ho_tx_remap[2] (.clk(clk), .rst_n(rst_n)),
   // PF/VF Mux "A" ports
   mx2fn_rx_a_port [NUM_MUX_PORTS-1:0](.clk(clk), .rst_n(rst_n)),
   fn2mx_tx_a_port [NUM_MUX_PORTS-1:0](.clk(clk), .rst_n(rst_n)),
   // PF/VF Mux "B" ports
   mx2fn_rx_b_port [NUM_MUX_PORTS-1:0](.clk(clk), .rst_n(rst_n)),
   fn2mx_tx_b_port [NUM_MUX_PORTS-1:0](.clk(clk), .rst_n(rst_n));
   
// TX request interface (only DMRd, DMIntr)
pcie_ss_axis_if #(
   .DATA_W (pcie_ss_hdr_pkg::HDR_WIDTH),
   .USER_W (PCIE_TUSER_WIDTH))
   mx2ho_txreq_port (.clk (clk), .rst_n(rst_n));

logic [1:0] pf_vf_fifo_err;
logic [1:0] pf_vf_fifo_perr;

logic       sel_mmio_rsp;
logic       read_flush_done;
logic       afu_softreset;

//-----------------------------------------------------------------------------------------------
// Preserve clocks
//-----------------------------------------------------------------------------------------------
// Make sure all clocks are consumed, in case AFUs don't use them,
// to avoid Quartus problems.
(* noprune *) logic clk_div2_q1, clk_div2_q2;

always_ff @(posedge clk_div2) begin
   clk_div2_q1 <= clk_div2_q2;
   clk_div2_q2 <= !clk_div2_q1;
end

//-----------------------------------------------------------------------------------------------
//                                  Modules instances
//-----------------------------------------------------------------------------------------------
// PF/VF Top-level routing Table 
//
//    +---------------------------------+
//    + Module          | PF/VF         +
//    +---------------------------------+
//    | ST2MM           | PF0           | 
//    | PG-AFU          | PF0-VF        |
//    |    HE-MEM       |    -VF0       |
//    |    HE-HSSI      |    -VF1       |
//    |    HE-MEM_TG    |    -VF2       |
//    | SR-AFU          | PF1+          |
//    +---------------------------------+

//-----------------------------------------------------------------------------------------------
// AFU Peripheral Fabric (APF)
//-----------------------------------------------------------------------------------------------
// This is the AXI-Lite interconnect fabric associated with PF0. It contains AFU feature interfaces 
// local to this hierarchy (protocol checker, port gasket, etc.) that are part of the device feature
// list (DFL), A board peripheral fabric (BPF) interface that exposes board (top) level features in
// a separate memory map partition (FME, HSSI, Memory, etc.), and services the interconnect 
// requirements of features in the OFS FIM (BPF to PF0 MSIX mailbox)
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
ofs_fim_axi_lite_if #(.AWADDR_WIDTH(MM_ADDR_WIDTH), .ARADDR_WIDTH(MM_ADDR_WIDTH)) apf_mctp_mst_if ();
ofs_fim_axi_lite_if #(.AWADDR_WIDTH(16), .ARADDR_WIDTH(16))                       apf_achk_slv_if ();
soc_apf_top apf (
   .clk   ( clk_csr   ),
   .rst_n ( rst_n_csr ),
   .*
);

//-----------------------------------------------------------------------------------------------
// FLR routing
//-----------------------------------------------------------------------------------------------
// Route FLR requests to their respective PF/VF ports.
//-----------------------------------------------------------------------------------------------
t_axis_pcie_flr afu_flr_req [NUM_MUX_PORTS-1:0];
t_axis_pcie_flr afu_flr_rsp [NUM_MUX_PORTS-1:0];

flr_mux #(
   .NUM_PORT           (NUM_MUX_PORTS),
   .NUM_RTABLE_ENTRIES (NUM_RTABLE_ENTRIES),
   .PFVF_ROUTING_TABLE (PFVF_ROUTING_TABLE)
) flr_mux_inst (
   .clk       (clk_csr),
   .rst_n     (rst_n_csr),
   .h_flr_req (pcie_flr_req),
   .h_flr_rsp (pcie_flr_rsp),
   .a_flr_req (afu_flr_req),
   .a_flr_rsp (afu_flr_rsp)
);

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

   .i_afu_softreset      (afu_softreset),

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
   .NUM_PORT(NUM_MUX_PORTS),
   .NUM_RTABLE_ENTRIES(NUM_RTABLE_ENTRIES),
   .PFVF_ROUTING_TABLE(PFVF_ROUTING_TABLE)
) pf_vf_mux_a (
   .clk             (clk               ),
   .rst_n           (rst_n             ),
   .ho2mx_rx_port   (ho2mx_rxreq_remap ),
   .mx2ho_tx_port   (mx2ho_tx_remap[0] ),
   .mx2fn_rx_port   (mx2fn_rx_a_port ),
   .fn2mx_tx_port   (fn2mx_tx_a_port   ),
   .out_fifo_err    (pf_vf_fifo_err[0] ),
   .out_fifo_perr   (pf_vf_fifo_perr[0])
);

// Secondary PF/VF MUX ("B" ports). Only TX is implemented, since a
// single RX stream is sufficient. The RX input to the MUX is tied off.
// AFU B TX ports are multiplexed into a single TX B channel that is
// passed to the A/B MUX above.
pf_vf_mux_w_params   #(
   .MUX_NAME ("B"),
   .NUM_PORT(NUM_MUX_PORTS),
   .NUM_RTABLE_ENTRIES(NUM_RTABLE_ENTRIES),
   .PFVF_ROUTING_TABLE(PFVF_ROUTING_TABLE)
) pf_vf_mux_b (
   .clk             (clk               ),
   .rst_n           (rst_n             ),
   .ho2mx_rx_port   (ho2mx_rx_remap    ),
   .mx2ho_tx_port   (mx2ho_tx_remap[1] ),
   .mx2fn_rx_port   (mx2fn_rx_b_port   ),
   .fn2mx_tx_port   (fn2mx_tx_b_port   ),
   .out_fifo_err    (pf_vf_fifo_err[1] ),
   .out_fifo_perr   (pf_vf_fifo_perr[1])
);

//-----------------------------------------------------------------------------------------------
// PCIe Streaming-to-AXI-Lite (ST2MM)
//-----------------------------------------------------------------------------------------------
// ST2MM translates the PCIe Subsystem TLP-over-AXI-ST channel to AXI-Lite transfers. This feature 
// is required to be routed to PF0, which is reflected in the default routing configuration:
// top_cfg_pkg::TOP_PF_VF_RTABLE
//
// This block maps all MMIO transfers to the `axi_m_if` port which manages device features connected
// to APF/BPF. Management Component Transport Protocol (MCTP) messages are mapped to the 
// `axi_m_pmci_vdm_if` port but are not externally routed in the SoC Attached AFU
//-----------------------------------------------------------------------------------------------
st2mm #(
   .PF_NUM          (0),
   .VF_NUM          (0),
   .VF_ACTIVE       (0),
   .MM_ADDR_WIDTH   (MM_ADDR_WIDTH),
   .MM_DATA_WIDTH   (MM_DATA_WIDTH),
   .PMCI_BASEADDR   (fabric_width_pkg::bpf_pmci_slv_baseaddress),
   .TX_VDM_OFFSET   (16'h2000),
   .RX_VDM_OFFSET   (16'h2000),
   .READ_ALLOWANCE  (1),
   .WRITE_ALLOWANCE (1),
   .FEAT_ID         (12'h14),
   .FEAT_VER        (4'h0),
   .END_OF_LIST     (fabric_width_pkg::soc_apf_st2mm_slv_eol),
   .NEXT_DFH_OFFSET (fabric_width_pkg::soc_apf_st2mm_slv_next_dfh_offset)
) st2mm (
   .clk               (clk                         ),
   .rst_n             (rst_n                       ),
   .clk_csr           (clk_csr                     ),
   .rst_n_csr         (rst_n_csr                   ),
   .axis_rx_if        (mx2fn_rx_a_port[PF0_MGMT_PID]),
   .axis_tx_if        (fn2mx_tx_a_port[PF0_MGMT_PID]),
   .axi_m_pmci_vdm_if (apf_mctp_mst_if             ),
   .axi_m_if          (apf_st2mm_mst_if            ),
   .axi_s_if          (apf_st2mm_slv_if            )
);
// Tie-off TX/RX B port
assign fn2mx_tx_b_port[PF0_MGMT_PID].tvalid = 1'b0;
assign mx2fn_rx_b_port[PF0_MGMT_PID].tready = 1'b1;

// FLR has no meaning for PF0 management, but must propagate to VFs in pg_afu
logic pf0_flr_rst_n;
flr_rst_mgr #(
   .NUM_PF (1),
   .NUM_VF (0),
   .MAX_NUM_VF (0)
) pf0_flr (
   .clk_sys      (clk),
   .rst_n_sys    (rst_n),
   .clk_csr      (clk_csr),
   .rst_n_csr    (rst_n_csr),
   .pcie_flr_req (afu_flr_req[PF0_MGMT_PID]),
   .pcie_flr_rsp (afu_flr_rsp[PF0_MGMT_PID]),
   .pf_flr_rst_n (pf0_flr_rst_n)
);

//-----------------------------------------------------------------------------------------------
// Static Region (SR) AFU (fim_afu_instances)
//-----------------------------------------------------------------------------------------------
// This block implements the static region AFU. In the reference implementation separate 
// physical interfaces are created for each function mapped to this region. They are ST2MM (PF0) 
// and HE-LB (PF1). For the SoC attach design the host attached side only implements static region 
// logic.
//-----------------------------------------------------------------------------------------------
generate if(soc_top_cfg_pkg::NUM_SR_PORTS > 0) begin : sr_afu
   soc_fim_afu_instances #(
      .NUM_PF             (soc_top_cfg_pkg::FIM_NUM_PF),
      .NUM_VF             (soc_top_cfg_pkg::FIM_NUM_VF),
      .MAX_NUM_VF         (soc_top_cfg_pkg::FIM_MAX_NUM_VF),
      .NUM_MUX_PORTS      (soc_top_cfg_pkg::NUM_SR_RTABLE_ENTRIES),
      .PFVF_ROUTING_TABLE (soc_top_cfg_pkg::SR_PF_VF_RTABLE)
   ) fim_afu_instances (
      .clk               (clk),
      .rst_n             (rst_n),

      .flr_req           (afu_flr_req[SR_SHARED_PFVF_PID]),
      .flr_rsp           (afu_flr_rsp[SR_SHARED_PFVF_PID]),

      .clk_csr           (clk_csr),
      .rst_n_csr         (rst_n_csr),

      .afu_axi_rx_a_if   (mx2fn_rx_a_port[SR_SHARED_PFVF_PID]),
      .afu_axi_tx_a_if   (fn2mx_tx_a_port[SR_SHARED_PFVF_PID]),
      .afu_axi_rx_b_if   (mx2fn_rx_b_port[SR_SHARED_PFVF_PID]),
      .afu_axi_tx_b_if   (fn2mx_tx_b_port[SR_SHARED_PFVF_PID])
   );
end : sr_afu
endgenerate

//-----------------------------------------------------------------------------------------------
// Port Gasket (PG) AFU
//-----------------------------------------------------------------------------------------------
// The port gasket implements the Partial Reconfiguration (PR) region AFU and supporting 
// infrastucture including freeze bridges, the PR controller feature, user clock feature, and remote 
// signal tap feature. The reference implementation connects a single physical interface routed to 
// 3VFs on PF0. In the PR region the VFs are then routed to HE-MEM (PF0-VF0), HE-HSSI(PF0-VF1), 
// and MEM-TG (PF0-VF2). The reference routing table is provided in $OFS_ROOTDIR/afu_top/mux/top_cfg_pkg.sv
//-----------------------------------------------------------------------------------------------
localparam PG_NUM_RTABLE_ENTRIES = soc_top_cfg_pkg::PG_NUM_RTABLE_ENTRIES;
localparam t_prr_pf_vf_entry_info PG_PFVF_ROUTING_TABLE = soc_top_cfg_pkg::PG_PF_VF_RTABLE;

typedef pcie_ss_hdr_pkg::ReqHdr_pf_vf_info_t[PG_AFU_NUM_PORTS-1:0] t_afu_prr_pf_vf_map;
function automatic t_afu_prr_pf_vf_map gen_prr_pf_vf_map();
   t_afu_prr_pf_vf_map map;
   for (int p = 0; p < PG_AFU_NUM_PORTS; p = p + 1) begin
      map[p].pf_num = PG_PFVF_ROUTING_TABLE[p].pf;
      map[p].vf_num = PG_PFVF_ROUTING_TABLE[p].vf;
      map[p].vf_active = PG_PFVF_ROUTING_TABLE[p].vf_active;
      map[p].link_num = 0;
   end
   return map;
endfunction // gen_pf_vf_map

localparam pcie_ss_hdr_pkg::ReqHdr_pf_vf_info_t[PG_AFU_NUM_PORTS-1:0] PG_PF_VF_INFO =
   gen_prr_pf_vf_map();

generate if (PG_AFU_NUM_PORTS > 0) begin : pg_afu
port_gasket #( 
   .PG_NUM_PORTS(PG_AFU_NUM_PORTS),              // Number of PCIe ports to PR region
   .NUM_PF      (soc_top_cfg_pkg::FIM_NUM_PF),
   .NUM_VF      (soc_top_cfg_pkg::FIM_NUM_VF),
   .MAX_NUM_VF  (soc_top_cfg_pkg::FIM_MAX_NUM_VF),
   .PORT_PF_VF_INFO(PG_PF_VF_INFO),              // PCIe port data
   .NUM_MEM_CH(AFU_MEM_CHANNEL),                 // Number of Memory Porst to PR region
   .END_OF_LIST    (fabric_width_pkg::soc_apf_pr_slv_eol),                       // port_gasket DFH end of list field
   .NEXT_DFH_OFFSET(fabric_width_pkg::soc_apf_pr_slv_next_dfh_offset),                   // Next offset in OFS management DFH
   .PG_NUM_RTABLE_ENTRIES (PG_NUM_RTABLE_ENTRIES),
   .PG_PFVF_ROUTING_TABLE (PG_PFVF_ROUTING_TABLE)
) port_gasket(
   .refclk              (SYS_REFCLK),            // 100 MHz refclk for user clk pll
   .clk                 ,                        // PCIe Clk
   .clk_div2,                                    // Half frequency of PCIe clk
   .clk_div4,                                    // Quarter frequency of PCIe clk
   .clk_100            (clk_csr),                // 100 MHz for user clk logic
   .clk_csr            (clk_csr),                // 100 MHz CSR interface clock

   .rst_n,                                       // Reset from hip
   .rst_n_100          (rst_n_csr),              // Reset from hip on csr clk
   .rst_n_csr          (rst_n_csr),              // Reset from hip on csr clk

   // FLR interface
   .pg_pf_flr_rst_n    (pf0_flr_rst_n),
   .flr_req            (afu_flr_req[PG_SHARED_VF_PID]),
   .flr_rsp            (afu_flr_rsp[PG_SHARED_VF_PID]),

`ifdef INCLUDE_DDR4
   .afu_mem_if         (ext_mem_if),             // Memory interface
`endif

`ifdef INCLUDE_HSSI                              // Instantiates HE-HSSI in PR region
   .hssi_ss_st_tx      (hssi_ss_st_tx),           // HSSI Tx
   .hssi_ss_st_rx      (hssi_ss_st_rx),           // HSSI Rx
   .hssi_fc            (hssi_fc),                 // Flow control interface
   .i_hssi_clk_pll     (i_hssi_clk_pll),          // HSSI clocks
`endif

   .i_sel_mmio_rsp     (sel_mmio_rsp),
   .i_read_flush_done  (read_flush_done),
   .o_afu_softreset    (afu_softreset),
   .o_pr_parity_error  (pr_parity_error),        // Partial Reconfiguration FIFO Parity Error Indication from PR Controller.

   .axi_rx_a_if        (mx2fn_rx_a_port[PG_SHARED_VF_PID]),
   .axi_tx_a_if        (fn2mx_tx_a_port[PG_SHARED_VF_PID]),
   .axi_rx_b_if        (mx2fn_rx_b_port[PG_SHARED_VF_PID]),
   .axi_tx_b_if        (fn2mx_tx_b_port[PG_SHARED_VF_PID]),

   .axi_s_if           (apf_pr_slv_if)         // CSR interface from APF
);
end : pg_afu
else begin
   dummy_csr #(
      .NEXT_DFH_OFFSET  (fabric_width_pkg::soc_apf_pr_slv_next_dfh_offset),
      .END_OF_LIST      (fabric_width_pkg::soc_apf_pr_slv_eol)
   ) emif_dummy_csr (
      .clk         (clk_csr),
      .rst_n       (rst_n_csr),
      .csr_lite_if (apf_pgsk_slv_if)
   );
end // else: !if(PG_AFU_NUM_PORTS > 0)
endgenerate

//----------------------------------------------------------------
// MCTP management interface : tied off for SoC
//----------------------------------------------------------------
always_ff @ (posedge clk_csr)
begin
   apf_mctp_mst_if.bvalid   <= apf_mctp_mst_if.wvalid;
   apf_mctp_mst_if.rvalid   <= apf_mctp_mst_if.arvalid;
   apf_mctp_mst_if.awready  <= 1'b1;
   apf_mctp_mst_if.wready   <= 1'b1;
   apf_mctp_mst_if.arready  <= 1'b1;
   apf_mctp_mst_if.bready   <= 1'b1;
   apf_mctp_mst_if.rready   <= 1'b1;
end

endmodule
