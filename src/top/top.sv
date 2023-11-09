// Copyright (C) 2021 Intel Corporation.
// SPDX-License-Identifier: MIT

//
// Description
//-----------------------------------------------------------------------------
//
//   Platform top level module
//
//-----------------------------------------------------------------------------
`include "fpga_defines.vh"

`ifdef INCLUDE_HSSI
`include "ofs_fim_eth_plat_defines.svh"
`endif

//-----------------------------------------------------------------------------
// Module ports
//-----------------------------------------------------------------------------

module top 
   import ofs_fim_cfg_pkg::*;
   import ofs_fim_if_pkg::*;
   import pcie_ss_axis_pkg::*;
`ifdef INCLUDE_HSSI
   import ofs_fim_eth_if_pkg::*;
`endif
`ifdef INCLUDE_DDR4 
   import ofs_fim_mem_if_pkg::*;
`endif
(
   input SYS_REFCLK                        ,// System Reference Clock (100MHz)

`ifdef INCLUDE_DDR4
   ofs_fim_emif_ddr4_if.emif ddr4_mem [ofs_fim_mem_if_pkg::NUM_DDR4_CHANNELS-1:0]      , // EMIF DDR4 x32
`endif

`ifdef INCLUDE_HSSI                                                                              
   //QSFP control signals
   input  wire                                 qsfp_ref_clk                      ,// QSFP Ethernet reference clock
   inout  wire                                 qsfpa_i2c_scl                     , // QSFPA I2C SCL
   inout  wire                                 qsfpa_i2c_sda                     , // QSFPA I2C SDA
   inout  wire                                 qsfpb_i2c_scl                     , // QSFPB I2C SCL
   inout  wire                                 qsfpb_i2c_sda                     , // QSFPB I2C SDA
   output wire                                 qsfpa_resetn                      , // QSFPA control
   output wire                                 qsfpa_modeseln                    , // QSFPA control
   input  wire                                 qsfpa_modprsln                    , // QSFPA control
   output wire                                 qsfpa_lpmode                      , // QSFPA control
   input  wire                                 qsfpa_intn                        , // QSFPA control
   output wire                                 qsfpb_resetn                      , // QSFPB control
   output wire                                 qsfpb_modeseln                    , // QSFPB control
   input  wire                                 qsfpb_modprsln                    , // QSFPB control
   output wire                                 qsfpb_lpmode                      , // QSFPB control
   input  wire                                 qsfpb_intn                        , // QSFPB control
   output wire                                 qsfpa_speed_green                 , // QSFPA indicator
   output wire                                 qsfpa_speed_yellow                , // QSFPA indicator
   output wire                                 qsfpa_activity_green              , // QSFPA indicator
   output wire                                 qsfpa_activity_red                , // QSFPA indicator
   output wire                                 qsfpb_speed_green                 , // QSFPB indicator
   output wire                                 qsfpb_speed_yellow                , // QSFPB indicator
   output wire                                 qsfpb_activity_green              , // QSFPB indicator
   output wire                                 qsfpb_activity_red                , // QSFPB indicator
    ofs_fim_hssi_serial_if.hssi                hssi_if [NUM_ETH_LANES-1:0]  , // QSFP serial data
`endif

`ifdef INCLUDE_PMCI                                                                              
   // AC FPGA - AC card BMC interface                                    
   output wire                                 qspi_dclk,
   output wire                                 qspi_ncs,
   inout  wire [3:0]                           qspi_data,
   input  wire                                 ncsi_rbt_ncsi_clk,
   input  wire [1:0]                           ncsi_rbt_ncsi_txd,
   input  wire                                 ncsi_rbt_ncsi_tx_en,
   output wire [1:0]                           ncsi_rbt_ncsi_rxd,
   output wire                                 ncsi_rbt_ncsi_crs_dv,
   input  wire                                 ncsi_rbt_ncsi_arb_in,
   output wire                                 ncsi_rbt_ncsi_arb_out,
   output wire                                 m10_gpio_fpga_seu_error,
   input  wire                                 m10_gpio_fpga_m10_hb,
   output wire                                 m10_gpio_fpga_therm_shdn,
   output wire                                 spi_ingress_sclk,
   output wire                                 spi_ingress_csn,
   input  wire                                 spi_ingress_miso,
   output wire                                 spi_ingress_mosi,
   input  wire                                 spi_egress_mosi,
   input  wire                                 spi_egress_csn,
   input  wire                                 spi_egress_sclk,
   output wire                                 spi_egress_miso,
`endif                                                                                    

   input                                       SOC_PCIE_REFCLK0                  ,// PCIe clock
   input                                       SOC_PCIE_REFCLK1                  ,// PCIe clock
   input                                       SOC_PCIE_RESET_N                  ,// PCIe reset
   input  [ofs_fim_cfg_pkg::PCIE_LANES-1:0]    SOC_PCIE_RX_P                     ,// PCIe RX_P pins 
   input  [ofs_fim_cfg_pkg::PCIE_LANES-1:0]    SOC_PCIE_RX_N                     ,// PCIe RX_N pins 
   output [ofs_fim_cfg_pkg::PCIE_LANES-1:0]    SOC_PCIE_TX_P                     ,// PCIe TX_P pins 
   output [ofs_fim_cfg_pkg::PCIE_LANES-1:0]    SOC_PCIE_TX_N                     ,// PCIe TX_N pins 

   input                                       PCIE_REFCLK0                      ,// PCIe clock
   input                                       PCIE_REFCLK1                      ,// PCIe clock
   input                                       PCIE_RESET_N                      ,// PCIe reset
   input  [ofs_fim_cfg_pkg::PCIE_LANES-1:0]    PCIE_RX_P                         ,// PCIe RX_P pins 
   input  [ofs_fim_cfg_pkg::PCIE_LANES-1:0]    PCIE_RX_N                         ,// PCIe RX_N pins 
   output [ofs_fim_cfg_pkg::PCIE_LANES-1:0]    PCIE_TX_P                         ,// PCIe TX_P pins 
   output [ofs_fim_cfg_pkg::PCIE_LANES-1:0]    PCIE_TX_N                         // PCIe TX_N pins 
);

localparam MM_ADDR_WIDTH = ofs_fim_cfg_pkg::MMIO_ADDR_WIDTH;
localparam MM_DATA_WIDTH = ofs_fim_cfg_pkg::MMIO_DATA_WIDTH;

localparam HOST = 0;
localparam SOC = 1;

//-----------------------------------------------------------------------------
// Internal signals
//-----------------------------------------------------------------------------

// clock signals
wire clk_sys, clk_sys_div2 , clk_sys_div4, clk_ptp_slv;
wire clk_100m;
wire clk_50m;
wire clk_csr;

wire h2f_reset_reset;

// reset signals
logic pll_locked;
logic ninit_done;
logic [SOC:HOST] pcie_reset_status;
logic [SOC:HOST] pcie_cold_rst_ack_n;
logic [SOC:HOST] pcie_warm_rst_ack_n;
logic [SOC:HOST] pcie_cold_rst_n;
logic [SOC:HOST] pcie_warm_rst_n;
logic [SOC:HOST] rst_n_sys;
logic [SOC:HOST] rst_n_100m;
logic [SOC:HOST] rst_n_50m;
logic [SOC:HOST] rst_n_ptp_slv;
logic [SOC:HOST] rst_n_csr;
logic [SOC:HOST] pwr_good_n;
logic [SOC:HOST] pwr_good_csr_clk_n;

//Ctrl Shadow ports
logic         p0_ss_app_st_ctrlshadow_tvalid, soc_p0_ss_app_st_ctrlshadow_tvalid;
logic [39:0]  p0_ss_app_st_ctrlshadow_tdata, soc_p0_ss_app_st_ctrlshadow_tdata;

logic [31:0]  o_pcie_error;

// -----------------------------------------------------------------------------
//  Board peripheral fabric (BPF)
// -----------------------------------------------------------------------------

//  AXI4-lite interfaces
ofs_fim_axi_lite_if #(.AWADDR_WIDTH(fabric_width_pkg::apf_bpf_mst_address_width), .ARADDR_WIDTH(fabric_width_pkg::apf_bpf_mst_address_width)) bpf_host_afu_apf_mst_if (.clk(clk_csr), .rst_n(rst_n_csr[HOST]));
ofs_fim_axi_lite_if #(.AWADDR_WIDTH(fabric_width_pkg::bpf_host_apf_mst_address_width), .ARADDR_WIDTH(fabric_width_pkg::bpf_host_apf_mst_address_width)) bpf_host_apf_mst_if     (.clk(clk_csr), .rst_n(rst_n_csr[SOC]));
ofs_fim_axi_lite_if #(.AWADDR_WIDTH(fabric_width_pkg::soc_apf_bpf_mst_address_width), .ARADDR_WIDTH(fabric_width_pkg::soc_apf_bpf_mst_address_width)) bpf_soc_apf_mst_if  ();
ofs_fim_axi_lite_if #(.AWADDR_WIDTH(fabric_width_pkg::bpf_host_apf_slv_address_width), .ARADDR_WIDTH(fabric_width_pkg::bpf_host_apf_slv_address_width)) bpf_host_apf_slv_if ();
ofs_fim_axi_lite_if #(.AWADDR_WIDTH(fabric_width_pkg::bpf_soc_apf_slv_address_width), .ARADDR_WIDTH(fabric_width_pkg::bpf_soc_apf_slv_address_width)) bpf_soc_apf_slv_if  ();
ofs_fim_axi_lite_if #(.AWADDR_WIDTH(fabric_width_pkg::bpf_fme_mst_address_width), .ARADDR_WIDTH(fabric_width_pkg::bpf_fme_mst_address_width)) bpf_fme_mst_if      ();
ofs_fim_axi_lite_if #(.AWADDR_WIDTH(fabric_width_pkg::bpf_fme_slv_address_width), .ARADDR_WIDTH(fabric_width_pkg::bpf_fme_slv_address_width)) bpf_fme_slv_if      ();
ofs_fim_axi_lite_if #(.AWADDR_WIDTH(fabric_width_pkg::bpf_pmci_mst_address_width), .ARADDR_WIDTH(fabric_width_pkg::bpf_pmci_mst_address_width)) bpf_pmci_mst_if     ();
ofs_fim_axi_lite_if #(.AWADDR_WIDTH(fabric_width_pkg::bpf_pmci_slv_address_width), .ARADDR_WIDTH(fabric_width_pkg::bpf_pmci_slv_address_width)) bpf_pmci_slv_if     ();
ofs_fim_axi_lite_if #(.AWADDR_WIDTH(fabric_width_pkg::bpf_pcie_slv_address_width), .ARADDR_WIDTH(fabric_width_pkg::bpf_pcie_slv_address_width)) bpf_pcie_slv_if     ();
ofs_fim_axi_lite_if #(.AWADDR_WIDTH(fabric_width_pkg::bpf_soc_pcie_slv_address_width), .ARADDR_WIDTH(fabric_width_pkg::bpf_soc_pcie_slv_address_width)) bpf_soc_pcie_slv_if ();
ofs_fim_axi_lite_if #(.AWADDR_WIDTH(fabric_width_pkg::bpf_qsfp0_slv_address_width), .ARADDR_WIDTH(fabric_width_pkg::bpf_qsfp0_slv_address_width)) bpf_qsfp0_slv_if    ();
ofs_fim_axi_lite_if #(.AWADDR_WIDTH(fabric_width_pkg::bpf_qsfp1_slv_address_width), .ARADDR_WIDTH(fabric_width_pkg::bpf_qsfp1_slv_address_width)) bpf_qsfp1_slv_if    ();
ofs_fim_axi_lite_if #(.AWADDR_WIDTH(fabric_width_pkg::bpf_hssi_slv_address_width), .ARADDR_WIDTH(fabric_width_pkg::bpf_hssi_slv_address_width)) bpf_hssi_slv_if     ();
ofs_fim_axi_lite_if #(.AWADDR_WIDTH(fabric_width_pkg::bpf_emif_slv_address_width), .ARADDR_WIDTH(fabric_width_pkg::bpf_emif_slv_address_width)) bpf_emif_slv_if     ();
   
axi_lite_rst_bridge host_soc_rst_bridge (.s_if(bpf_host_afu_apf_mst_if), .m_if(bpf_host_apf_mst_if));

bpf_top soc_bpf (
   .clk   (clk_csr),
   .rst_n (rst_n_csr[SOC]),
   .*	
);

// PCIe Subsystem Interface
pcie_ss_axis_if   pcie_ss_axis_rx_if    (.clk (clk_sys), .rst_n(rst_n_sys[HOST]));
pcie_ss_axis_if   pcie_ss_axis_tx_if    (.clk (clk_sys), .rst_n(rst_n_sys[HOST]));
pcie_ss_axis_if   pcie_ss_axis_rxreq_if (.clk (clk_sys), .rst_n(rst_n_sys[HOST]));
// TXREQ is only headers (read requests)
pcie_ss_axis_if #(
   .DATA_W(pcie_ss_hdr_pkg::HDR_WIDTH),
   .USER_W(ofs_fim_cfg_pkg::PCIE_TUSER_WIDTH)
) pcie_ss_axis_txreq_if(.clk (clk_sys), .rst_n(rst_n_sys[HOST]));
t_axis_pcie_flr   pcie_flr_req;
t_axis_pcie_flr   pcie_flr_rsp;

pcie_ss_axis_if   soc_pcie_ss_axis_rx_if    (.clk (clk_sys), .rst_n(rst_n_sys[SOC]));
pcie_ss_axis_if   soc_pcie_ss_axis_tx_if    (.clk (clk_sys), .rst_n(rst_n_sys[SOC]));
pcie_ss_axis_if   soc_pcie_ss_axis_rxreq_if (.clk (clk_sys), .rst_n(rst_n_sys[SOC]));
// TXREQ is only headers (read requests)
pcie_ss_axis_if #(
   .DATA_W(pcie_ss_hdr_pkg::HDR_WIDTH),
   .USER_W(ofs_fim_cfg_pkg::PCIE_TUSER_WIDTH)
) soc_pcie_ss_axis_txreq_if(.clk (clk_sys), .rst_n(rst_n_sys[SOC]));
t_axis_pcie_flr   soc_pcie_flr_req;
t_axis_pcie_flr   soc_pcie_flr_rsp;

// Partial Reconfiguration FIFO Parity Error from PR Controller
logic pr_parity_error;

// AVST interface
ofs_fim_axi_lite_if m_afu_lite();
ofs_fim_axi_lite_if s_afu_lite();

//Completion Timeout Interface
t_axis_pcie_cplto         axis_cpl_timeout, soc_axis_cpl_timeout;

//Tag Mode
t_pcie_tag_mode tag_mode, soc_tag_mode;


`ifdef INCLUDE_DDR4
localparam AFU_MEM_CHANNEL = ofs_fim_mem_if_pkg::NUM_MEM_CHANNELS;
//AFU EMIF AXI-MM IF
ofs_fim_emif_axi_mm_if #(
   .WDATA_WIDTH  (ofs_fim_mem_if_pkg::AXI_MEM_WDATA_WIDTH),
   .RDATA_WIDTH  (ofs_fim_mem_if_pkg::AXI_MEM_RDATA_WIDTH),
   .AWID_WIDTH   (ofs_fim_mem_if_pkg::AXI_MEM_ID_WIDTH),
   .BUSER_WIDTH  (ofs_fim_mem_if_pkg::AXI_MEM_BUSER_WIDTH),
   .ARID_WIDTH   (ofs_fim_mem_if_pkg::AXI_MEM_ID_WIDTH),
   .AWADDR_WIDTH (ofs_fim_mem_if_pkg::AXI_MEM_ADDR_WIDTH),
   .ARADDR_WIDTH (ofs_fim_mem_if_pkg::AXI_MEM_ADDR_WIDTH)
) afu_ext_mem_if [AFU_MEM_CHANNEL-1:0] ();
`else // !`ifdef INCLUDE_DDR4
localparam AFU_MEM_CHANNEL = 0;
`endif

//-----------------------------------------------------------------------------
// Connections
//-----------------------------------------------------------------------------
assign clk_csr = clk_100m;
assign rst_n_csr = {rst_n_100m, rst_n_100m};


//-----------------------------------------------------------------------------
// Modules instances
//-----------------------------------------------------------------------------
//*******************************
// HSSI Subsystem
//*******************************
`ifndef INCLUDE_HSSI  
// Placeholder logic incase HSSI is not used
dummy_csr #(
   .FEAT_ID          (12'h00f),
   .FEAT_VER         (4'h1),
   .NEXT_DFH_OFFSET  (fabric_width_pkg::bpf_hssi_slv_next_dfh_offset),
   .END_OF_LIST      (fabric_width_pkg::bpf_hssi_slv_eol)
) hssi_dummy_csr (
   .clk         (clk_csr),
   .rst_n       (rst_n_csr[SOC]),
   .csr_lite_if (bpf_hssi_slv_if)
);


dummy_csr #(
   .FEAT_ID          (12'h13),
   .FEAT_VER         (4'h0),
   .NEXT_DFH_OFFSET  (fabric_width_pkg::bpf_qsfp0_slv_next_dfh_offset),
   .END_OF_LIST      (fabric_width_pkg::bpf_qsfp0_slv_eol)
) qsfp0_dummy_csr (
   .clk         (clk_csr),
   .rst_n       (rst_n_csr[SOC]),
   .csr_lite_if (bpf_qsfp0_slv_if)
);

dummy_csr #(
   .FEAT_ID          (12'h13),
   .FEAT_VER         (4'h0),
   .NEXT_DFH_OFFSET  (fabric_width_pkg::bpf_qsfp1_slv_next_dfh_offset),
   .END_OF_LIST      (fabric_width_pkg::bpf_qsfp1_slv_eol)
) qsfp1_dummy_csr (
   .clk         (clk_csr),
   .rst_n       (rst_n_csr[SOC]),
   .csr_lite_if (bpf_qsfp1_slv_if)
);
`else
ofs_fim_hssi_ss_tx_axis_if        hssi_ss_st_tx [MAX_NUM_ETH_CHANNELS-1:0]();
ofs_fim_hssi_ss_rx_axis_if        hssi_ss_st_rx [MAX_NUM_ETH_CHANNELS-1:0]();
ofs_fim_hssi_fc_if                hssi_fc [MAX_NUM_ETH_CHANNELS-1:0]();
logic [MAX_NUM_ETH_CHANNELS-1:0]  hssi_clk_pll;

hssi_wrapper #(
   .NEXT_DFH_OFFSET(fabric_width_pkg::bpf_hssi_slv_next_dfh_offset)
)hssi_wrapper (
   .clk_csr                   (clk_csr),
   .rst_n_csr                 (rst_n_csr[SOC]),
   .csr_lite_if               (bpf_hssi_slv_if),
   .hssi_ss_st_tx             (hssi_ss_st_tx),
   .hssi_ss_st_rx             (hssi_ss_st_rx),
   .hssi_fc                   (hssi_fc),
   .hssi_if                   (hssi_if),
   .i_hssi_clk_ref            ({3{qsfp_ref_clk}}),
   .o_hssi_rec_clk            (),//hssi_rec_clk),
   .o_hssi_clk_pll            (hssi_clk_pll), 
   .o_qsfp_speed_green        ({qsfpa_speed_green, qsfpb_speed_green}),      
   .o_qsfp_speed_yellow       ({qsfpa_speed_yellow, qsfpb_speed_yellow}),   
   .o_qsfp_activity_green     ({qsfpa_activity_green, qsfpb_activity_green}),    
   .o_qsfp_activity_red       ({qsfpa_activity_red, qsfpb_activity_red})
);

//*******************************
// QSFP Controller
//*******************************

wire qsfpa_i2c_scl_in            /* synthesis keep */;
wire qsfpa_i2c_sda_in            /* synthesis keep */;
wire qsfpa_i2c_scl_oe            /* synthesis keep */;
wire qsfpa_i2c_sda_oe            /* synthesis keep */;
wire qsfpa_modesel;
wire qsfpa_reset;

wire qsfpb_i2c_scl_in            /* synthesis keep */;
wire qsfpb_i2c_sda_in            /* synthesis keep */;
wire qsfpb_i2c_scl_oe            /* synthesis keep */;
wire qsfpb_i2c_sda_oe            /* synthesis keep */;
wire qsfpb_modesel;
wire qsfpb_reset;


assign qsfpa_i2c_scl_in = qsfpa_i2c_scl;
assign qsfpa_i2c_sda_in = qsfpa_i2c_sda;
assign qsfpa_i2c_scl    = qsfpa_i2c_scl_oe ? 1'b0 : 1'bz;
assign qsfpa_i2c_sda    = qsfpa_i2c_sda_oe ? 1'b0 : 1'bz;

assign qsfpb_i2c_scl_in = qsfpb_i2c_scl;
assign qsfpb_i2c_sda_in = qsfpb_i2c_sda;
assign qsfpb_i2c_scl    = qsfpb_i2c_scl_oe ? 1'b0 : 1'bz;
assign qsfpb_i2c_sda    = qsfpb_i2c_sda_oe ? 1'b0 : 1'bz;

assign qsfpa_resetn     = ~qsfpa_reset;
assign qsfpa_modeseln   = ~qsfpa_modesel;

assign qsfpb_resetn     = ~qsfpb_reset;
assign qsfpb_modeseln   = ~qsfpb_modesel;


qsfp_top #(
   .ADDR_WIDTH       (fabric_width_pkg::bpf_qsfp0_slv_address_width),
   .DATA_WIDTH       (64),
   .FEAT_ID          (12'h13),
   .FEAT_VER         (4'h0),
   .NEXT_DFH_OFFSET  (fabric_width_pkg::bpf_qsfp0_slv_next_dfh_offset),
   .END_OF_LIST      (fabric_width_pkg::bpf_qsfp0_slv_eol)
) qsfp_0 (
   .clk (clk_csr),
   .reset(~rst_n_csr [SOC]),
   .modprsl(qsfpa_modprsln),
   .int_qsfp(~qsfpa_intn),
   .i2c_0_i2c_serial_sda_in(qsfpa_i2c_sda_in),
   .i2c_0_i2c_serial_scl_in(qsfpa_i2c_scl_in),
   .i2c_0_i2c_serial_sda_oe(qsfpa_i2c_sda_oe),
   .i2c_0_i2c_serial_scl_oe(qsfpa_i2c_scl_oe),
   .modesel(qsfpa_modesel),
   .lpmode(qsfpa_lpmode),
   .softresetqsfpm(qsfpa_reset),
   .csr_lite_if (bpf_qsfp0_slv_if)
);

qsfp_top #(
   .ADDR_WIDTH       (fabric_width_pkg::bpf_qsfp1_slv_address_width),
   .DATA_WIDTH       (64),
   .FEAT_ID          (12'h13),
   .FEAT_VER         (4'h0),
   .NEXT_DFH_OFFSET  (fabric_width_pkg::bpf_qsfp1_slv_next_dfh_offset),
   .END_OF_LIST      (fabric_width_pkg::bpf_qsfp1_slv_eol)
) qsfp_1 (
   .clk (clk_csr),
   .reset(~rst_n_csr [SOC]),
   .modprsl(qsfpb_modprsln),
   .int_qsfp(~qsfpb_intn),
   .i2c_0_i2c_serial_sda_in(qsfpb_i2c_sda_in),
   .i2c_0_i2c_serial_scl_in(qsfpb_i2c_scl_in),
   .i2c_0_i2c_serial_sda_oe(qsfpb_i2c_sda_oe),
   .i2c_0_i2c_serial_scl_oe(qsfpb_i2c_scl_oe),
   .modesel(qsfpb_modesel),
   .lpmode(qsfpb_lpmode),
   .softresetqsfpm(qsfpb_reset),
   .csr_lite_if (bpf_qsfp1_slv_if)
);

`endif

//*******************************
// Configuration reset release IP
//*******************************
`ifdef SIM_MODE
   assign ninit_done = 1'b0;
`else
   cfg_mon cfg_mon (
      .ninit_done (ninit_done)
   );
`endif

   
//*******************************
// System PLL
//*******************************

sys_pll sys_pll (
   .rst                (ninit_done                ),
   .refclk             (SYS_REFCLK                ), // 100 MHz
   .locked             (pll_locked                ),
   .outclk_0           (clk_sys                   ), // 470 MHz
   .outclk_1           (clk_100m                  ), // 100 MHz
   .outclk_2           (clk_sys_div2              ), // 235 MHz
   .outclk_3           (clk_ptp_slv               ), // 155.56MHz
   .outclk_4           (clk_50m                   ), // 50 MHz
   .outclk_5           (clk_sys_div4              )  // 117.5 MHz
);

//*******************************
// Reset controller
//*******************************
rst_ctrl rst_ctrl (
   .clk_sys             (clk_sys                    ),
   .clk_100m            (clk_100m                   ),
   .clk_50m             (clk_50m                    ),
   .clk_ptp_slv         (clk_ptp_slv                ),
   .pll_locked          (pll_locked                 ),
   .pcie_reset_status   (pcie_reset_status   [HOST] ),
   .pcie_cold_rst_ack_n (pcie_cold_rst_ack_n [HOST] ),
   .pcie_warm_rst_ack_n (pcie_warm_rst_ack_n [HOST] ),
                                                 
   .ninit_done          (ninit_done                 ),
   .rst_n_sys           (rst_n_sys           [HOST] ),  // system reset synchronous to clk_sys
   .rst_n_100m          (rst_n_100m          [HOST] ),  // system reset synchronous to clk_100m
   .rst_n_50m           (rst_n_50m           [HOST] ),  // system reset synchronous to clk_50m
   .rst_n_ptp_slv       (rst_n_ptp_slv       [HOST] ),  // system reset synchronous to clk_ptp_slv 
   .pwr_good_n          (pwr_good_n          [HOST] ),  // system reset synchronous to clk_100m
   .pwr_good_csr_clk_n  (pwr_good_csr_clk_n  [HOST] ),  // power good reset synchronous to clk_sys 
   .pcie_cold_rst_n     (pcie_cold_rst_n     [HOST] ),
   .pcie_warm_rst_n     (pcie_warm_rst_n     [HOST] )
); 

rst_ctrl soc_rst_ctrl (
   .clk_sys             (clk_sys                   ),
   .clk_100m            (clk_100m                  ),
   .clk_50m             (clk_50m                   ),
   .clk_ptp_slv         (clk_ptp_slv               ),
   .pll_locked          (pll_locked                ),
   .pcie_reset_status   (pcie_reset_status   [SOC] ),
   .pcie_cold_rst_ack_n (pcie_cold_rst_ack_n [SOC] ),
   .pcie_warm_rst_ack_n (pcie_warm_rst_ack_n [SOC] ),
                                                 
   .ninit_done          (ninit_done                ),
   .rst_n_sys           (rst_n_sys           [SOC] ),  // system reset synchronous to clk_sys
   .rst_n_100m          (rst_n_100m          [SOC] ),  // system reset synchronous to clk_100m
   .rst_n_50m           (rst_n_50m           [SOC] ),  // system reset synchronous to clk_50m
   .rst_n_ptp_slv       (rst_n_ptp_slv       [SOC] ),  // system reset synchronous to clk_ptp_slv 
   .pwr_good_n          (pwr_good_n          [SOC] ),  // system reset synchronous to clk_100m
   .pwr_good_csr_clk_n  (pwr_good_csr_clk_n  [SOC] ),  // power good reset synchronous to clk_sys 
   .pcie_cold_rst_n     (pcie_cold_rst_n     [SOC] ),
   .pcie_warm_rst_n     (pcie_warm_rst_n     [SOC] )
); 
   
//*******************************
// PCIe Subsystem
//*******************************
pcie_wrapper #(  
   .PCIE_LANES       (ofs_fim_cfg_pkg::PCIE_LANES),
   .MM_ADDR_WIDTH    (MM_ADDR_WIDTH),
   .MM_DATA_WIDTH    (MM_DATA_WIDTH),
   .FEAT_ID          (12'h020),
   .FEAT_VER         (4'h0),
   .NEXT_DFH_OFFSET  (fabric_width_pkg::bpf_pcie_slv_next_dfh_offset),
   .END_OF_LIST      (1'b1)  
) pcie_wrapper (
   .ninit_done                     (ninit_done                     ),
   .fim_clk                        (clk_sys                        ),
   .csr_clk                        (clk_csr                        ),
   .fim_rst_n                      (rst_n_sys           [HOST]     ),
   .csr_rst_n                      (rst_n_csr           [HOST]     ),
   .reset_status                   (pcie_reset_status   [HOST]     ),  
   .p0_subsystem_cold_rst_n        (pcie_cold_rst_n     [HOST]     ),     
   .p0_subsystem_warm_rst_n        (pcie_warm_rst_n     [HOST]     ),
   .p0_subsystem_cold_rst_ack_n    (pcie_cold_rst_ack_n [HOST]     ),
   .p0_subsystem_warm_rst_ack_n    (pcie_warm_rst_ack_n [HOST]     ),
   .pin_pcie_refclk0_p             (PCIE_REFCLK0                   ),
   .pin_pcie_refclk1_p             (PCIE_REFCLK1                   ),
   .pin_pcie_in_perst_n            (PCIE_RESET_N                   ),   // connected to HIP
   .pin_pcie_rx_p                  (PCIE_RX_P                      ),
   .pin_pcie_rx_n                  (PCIE_RX_N                      ),
   .pin_pcie_tx_p                  (PCIE_TX_P                      ),                
   .pin_pcie_tx_n                  (PCIE_TX_N                      ),   
   .p0_ss_app_st_ctrlshadow_tvalid (p0_ss_app_st_ctrlshadow_tvalid ),
   .p0_ss_app_st_ctrlshadow_tdata  (p0_ss_app_st_ctrlshadow_tdata  ),
   .axi_st_rxreq_if                (pcie_ss_axis_rxreq_if          ),
   .axi_st_rx_if                   (pcie_ss_axis_rx_if             ),
   .axi_st_tx_if                   (pcie_ss_axis_tx_if             ),
   .axi_st_txreq_if                (pcie_ss_axis_txreq_if          ),
   .csr_lite_if                    (bpf_pcie_slv_if                ),
   .axi_st_flr_req                 (pcie_flr_req                   ),
   .axi_st_flr_rsp                 (pcie_flr_rsp                   ),
   .axis_cpl_timeout               (axis_cpl_timeout               ),
   .tag_mode                       (tag_mode                       )
);

 pcie_wrapper #(  
     .PCIE_LANES       (ofs_fim_cfg_pkg::PCIE_LANES),
     .MM_ADDR_WIDTH    (MM_ADDR_WIDTH),
     .MM_DATA_WIDTH    (MM_DATA_WIDTH),
     .FEAT_ID          (12'h020),
     .FEAT_VER         (4'h0),
     .NEXT_DFH_OFFSET  (fabric_width_pkg::bpf_soc_pcie_slv_next_dfh_offset),
     .END_OF_LIST      (fabric_width_pkg::bpf_soc_pcie_slv_eol),
     .SOC_ATTACH       (1)
) soc_pcie_wrapper (
   .ninit_done                     (ninit_done                         ),
   .fim_clk                        (clk_sys                            ),
   .csr_clk                        (clk_csr                            ),
   .fim_rst_n                      (rst_n_sys           [SOC]          ),
   .csr_rst_n                      (rst_n_csr           [SOC]          ),
   .reset_status                   (pcie_reset_status   [SOC]          ),  
   .p0_subsystem_cold_rst_n        (pcie_cold_rst_n     [SOC]          ),     
   .p0_subsystem_warm_rst_n        (pcie_warm_rst_n     [SOC]          ),
   .p0_subsystem_cold_rst_ack_n    (pcie_cold_rst_ack_n [SOC]          ),
   .p0_subsystem_warm_rst_ack_n    (pcie_warm_rst_ack_n [SOC]          ),
   .pin_pcie_refclk0_p             (SOC_PCIE_REFCLK0                   ),
   .pin_pcie_refclk1_p             (SOC_PCIE_REFCLK1                   ),
   .pin_pcie_in_perst_n            (SOC_PCIE_RESET_N                   ),   // connected to HIP
   .pin_pcie_rx_p                  (SOC_PCIE_RX_P                      ),
   .pin_pcie_rx_n                  (SOC_PCIE_RX_N                      ),
   .pin_pcie_tx_p                  (SOC_PCIE_TX_P                      ),                
   .pin_pcie_tx_n                  (SOC_PCIE_TX_N                      ),   
   .p0_ss_app_st_ctrlshadow_tvalid (soc_p0_ss_app_st_ctrlshadow_tvalid ),
   .p0_ss_app_st_ctrlshadow_tdata  (soc_p0_ss_app_st_ctrlshadow_tdata  ),
   .axi_st_rxreq_if                (soc_pcie_ss_axis_rxreq_if          ),
   .axi_st_rx_if                   (soc_pcie_ss_axis_rx_if             ),
   .axi_st_tx_if                   (soc_pcie_ss_axis_tx_if             ),
   .axi_st_txreq_if                (soc_pcie_ss_axis_txreq_if          ),
   .csr_lite_if                    (bpf_soc_pcie_slv_if                ),
   .axi_st_flr_req                 (soc_pcie_flr_req                   ),
   .axi_st_flr_rsp                 (soc_pcie_flr_rsp                   ),
   .axis_cpl_timeout               (soc_axis_cpl_timeout               ), 
   .tag_mode                       (soc_tag_mode                       )
);

//*******************************
// PMCI Subsystem
//*******************************
`ifdef INCLUDE_PMCI                                                                              
pmci_wrapper #(
     .FEAT_ID          (12'h012),
     .FEAT_VER         (4'h2),
     .NEXT_DFH_OFFSET  (fabric_width_pkg::bpf_pmci_slv_next_dfh_offset),
     .END_OF_LIST      (fabric_width_pkg::bpf_pmci_slv_eol)
   ) pmci_wrapper (
      .clk_csr                   (clk_csr                 ),                               
      .reset_csr                 (!rst_n_csr[SOC]         ),                               
      .csr_lite_slv_if           (bpf_pmci_slv_if         ),
      .csr_lite_mst_if           (bpf_pmci_mst_if         ),
      .qspi_dclk                 (qspi_dclk               ),                               
      .qspi_ncs                  (qspi_ncs                ),                               
      .qspi_data                 (qspi_data               ),                               
      .ncsi_rbt_ncsi_clk         (ncsi_rbt_ncsi_clk       ),                               
      .ncsi_rbt_ncsi_txd         (ncsi_rbt_ncsi_txd       ),                               
      .ncsi_rbt_ncsi_tx_en       (ncsi_rbt_ncsi_tx_en     ),                               
      .ncsi_rbt_ncsi_rxd         (ncsi_rbt_ncsi_rxd       ),                               
      .ncsi_rbt_ncsi_crs_dv      (ncsi_rbt_ncsi_crs_dv    ),                               
      .ncsi_rbt_ncsi_arb_in      (ncsi_rbt_ncsi_arb_in    ),                               
      .ncsi_rbt_ncsi_arb_out     (ncsi_rbt_ncsi_arb_out   ),                               
      .m10_gpio_fpga_usr_100m    (1'b0                    ),                               
      .m10_gpio_fpga_m10_hb      (m10_gpio_fpga_m10_hb    ),                               
      .m10_gpio_m10_seu_error    (1'b0                    ),                               
      .m10_gpio_fpga_therm_shdn  (m10_gpio_fpga_therm_shdn),                               
      .m10_gpio_fpga_seu_error   (m10_gpio_fpga_seu_error ),                               
      .spi_ingress_sclk          (spi_ingress_sclk        ),                               
      .spi_ingress_csn           (spi_ingress_csn         ),                               
      .spi_ingress_miso          (spi_ingress_miso        ),                               
      .spi_ingress_mosi          (spi_ingress_mosi        ),                               
      .spi_egress_mosi           (spi_egress_mosi         ),
      .spi_egress_csn            (spi_egress_csn          ),
      .spi_egress_sclk           (spi_egress_sclk         ),        
      .spi_egress_miso           (spi_egress_miso         ) 
 );

 `else
    // dummy csr slv if incase PMCI is not used
    dummy_csr #(
       .FEAT_ID          (12'h012),
       .FEAT_VER         (4'h1),
       //.NEXT_DFH_OFFSET  (24'h1000),
       .NEXT_DFH_OFFSET  (fabric_width_pkg::bpf_pmci_slv_next_dfh_offset),
       .END_OF_LIST      (fabric_width_pkg::bpf_pmci_slv_eol)
    ) pmci_dummy_csr (
       .clk         (clk_csr),
       .rst_n       (rst_n_csr[SOC]),
       .csr_lite_if (bpf_pmci_slv_if)
    );
 

   `ifdef SIM_VIP   
     // if VIP is used for simulation then bpf_pmci_mst_if will be driven by the VIP
   `else  
     always_comb
     begin  
       bpf_pmci_mst_if.awaddr   = 24'h0;
       bpf_pmci_mst_if.awprot   = 3'h0;
       bpf_pmci_mst_if.awvalid  = 1'b0;
       bpf_pmci_mst_if.wdata    = 32'h0;
       bpf_pmci_mst_if.wstrb    = 4'h0;
       bpf_pmci_mst_if.wvalid   = 1'b0;
       bpf_pmci_mst_if.bready   = 1'b0;  
       bpf_pmci_mst_if.araddr   = 24'h0;
       bpf_pmci_mst_if.arprot   = 3'h0; 
       bpf_pmci_mst_if.arvalid  = 1'b0;
       bpf_pmci_mst_if.rready   = 1'b0;
     end
   `endif
`endif

   //*******************************
   // FME
   //*******************************
   fme_top #(
      .ST2MM_MSIX_ADDR (fabric_width_pkg::apf_st2mm_slv_baseaddress + 'h10),
      .NEXT_DFH_OFFSET (fabric_width_pkg::bpf_fme_slv_next_dfh_offset)
   ) fme_top (
      .clk               (clk_csr          ),
      .rst_n             (rst_n_csr  [SOC] ),
      .pwr_good_n        (pwr_good_n [SOC] ),
      .pr_parity_error   (pr_parity_error  ),
      .axi_lite_m_if     (bpf_fme_mst_if   ),
      .axi_lite_s_if     (bpf_fme_slv_if   )
   );

  //*******************************
  // AFU
  //*******************************
   afu_top #(
      .AFU_MEM_CHANNEL (0)
   ) host_afu (
      .SYS_REFCLK          (SYS_REFCLK                ),
      .clk                 (clk_sys                   ),
      .clk_div2            (clk_sys_div2              ),
      .clk_div4            (clk_sys_div4              ),
      .clk_csr             (clk_csr                   ),
      .clk_50m             (clk_50m                   ),

      .rst_n               (rst_n_sys          [HOST] ),
      .rst_n_csr           (rst_n_csr          [HOST] ),
      .rst_n_50m           (rst_n_50m          [HOST] ),
      .pwr_good_csr_clk_n  (pwr_good_csr_clk_n [HOST] ), // power good reset synchronous to csr_clk
         
      .pcie_flr_req        (pcie_flr_req              ),
      .pcie_flr_rsp        (pcie_flr_rsp              ),
      .pr_parity_error     (                          ),
      .tag_mode            (tag_mode                  ),

      .apf_bpf_slv_if      (bpf_host_afu_apf_mst_if   ),
      .apf_bpf_mst_if      (bpf_host_apf_slv_if       ),
         
      .pcie_ss_axis_rxreq  (pcie_ss_axis_rxreq_if    ),
      .pcie_ss_axis_rx     (pcie_ss_axis_rx_if       ),
      .pcie_ss_axis_tx     (pcie_ss_axis_tx_if       ),
      .pcie_ss_axis_txreq  (pcie_ss_axis_txreq_if    )
   );

   soc_afu_top #(
      .AFU_MEM_CHANNEL (AFU_MEM_CHANNEL)
   ) soc_afu (
      .SYS_REFCLK          (SYS_REFCLK                ),
      .clk                 (clk_sys                   ),
      .clk_div2            (clk_sys_div2              ),
      .clk_div4            (clk_sys_div4              ),
      .clk_csr             (clk_csr                   ),
      .clk_50m             (clk_50m                   ),

      .rst_n               (rst_n_sys          [SOC]  ),
      .rst_n_csr           (rst_n_csr          [SOC]  ),
      .rst_n_50m           (rst_n_50m          [SOC]  ),
      .pwr_good_csr_clk_n  (pwr_good_csr_clk_n [SOC]  ), // power good reset synchronous to csr_clk
         
      .pcie_flr_req        (soc_pcie_flr_req          ),
      .pcie_flr_rsp        (soc_pcie_flr_rsp          ),
      .pr_parity_error     (                          ),
      .tag_mode            (soc_tag_mode              ),

      .apf_bpf_slv_if      (bpf_soc_apf_mst_if        ),
      .apf_bpf_mst_if      (bpf_soc_apf_slv_if        ),
         
`ifdef INCLUDE_DDR4
      .ext_mem_if          (afu_ext_mem_if),
`endif

`ifdef INCLUDE_HSSI
      .hssi_ss_st_tx        (hssi_ss_st_tx           ),
      .hssi_ss_st_rx        (hssi_ss_st_rx           ),
      .hssi_fc              (hssi_fc                 ),
      .i_hssi_clk_pll       (hssi_clk_pll            ),
`endif 
      .pcie_ss_axis_rxreq  (soc_pcie_ss_axis_rxreq_if    ),
      .pcie_ss_axis_rx     (soc_pcie_ss_axis_rx_if       ),
      .pcie_ss_axis_tx     (soc_pcie_ss_axis_tx_if       ),
      .pcie_ss_axis_txreq  (soc_pcie_ss_axis_txreq_if    )
   );
   
//*******************************
// Memory Subsystem
//*******************************
`ifdef INCLUDE_DDR4
   mem_ss_top #(
      .FEAT_ID          (12'h009),
      .FEAT_VER         (4'h1),
      .NEXT_DFH_OFFSET  (fabric_width_pkg::bpf_emif_slv_next_dfh_offset),
      .END_OF_LIST      (fabric_width_pkg::bpf_emif_slv_eol)
   ) mem_ss_top (
      .clk      (clk_sys),
      .reset    (~rst_n_sys [SOC]),

       // MEM interfaces
      .afu_mem_if  (afu_ext_mem_if),
      .ddr4_mem_if (ddr4_mem),

       // CSR interfaces
      .clk_csr     (clk_csr),
      .rst_n_csr   (rst_n_csr[SOC]),
      .csr_lite_if (bpf_emif_slv_if)
   );
`else
   // Placeholder logic if no mem_ss
   dummy_csr #(
      .FEAT_ID          (12'h009),
      .FEAT_VER         (4'h1),
      .NEXT_DFH_OFFSET  (fabric_width_pkg::bpf_emif_slv_next_dfh_offset),
      .END_OF_LIST      (fabric_width_pkg::bpf_emif_slv_eol)
   ) emif_dummy_csr (
      .clk         (clk_csr),
      .rst_n       (rst_n_csr[SOC]),
      .csr_lite_if (bpf_emif_slv_if)
   );
`endif
endmodule
