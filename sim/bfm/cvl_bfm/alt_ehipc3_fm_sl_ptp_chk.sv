// Copyright (C) 2020 Intel Corporation.
// SPDX-License-Identifier: MIT


`timescale 1 ps / 1 ps

module alt_ehipc3_fm_sl_ptp_chk
(
    // Clock and reset
    input    logic          i_ptp_clk,
    input    logic          i_ptp_rst_n,
    
    // EHIP datapath signals
    input   logic           i_tx_valid,
    input   logic           i_tx_startofpacket,
    input   logic           i_rx_valid,
    input   logic           i_rx_startofpacket,
    
    // User TX 2-step timestamp request
    input   logic           i_ptp_ts_req,
    input   logic   [7:0]   i_ptp_fp,
    
    // EHIP TX 2-step timestamp
    input   logic           i_ptp_ets_valid,
    input   logic   [95:0]  i_ptp_ets,
    input   logic   [7:0]   i_ptp_ets_fp,
    
    // EHIP RX timestamp
    input   logic   [95:0]  i_ptp_rx_its,
    
    // Maximum allowable timestamp differences
    input   logic   [95:0]  i_txrx_ts_diff_thres,
    
    // Statistics
    output  logic   [31:0]  o_tx_ts_req_cnt,
    output  logic   [31:0]  o_tx_ets_cnt,
    output  logic   [31:0]  o_rx_its_cnt,
    output  logic   [31:0]  o_tx_fp_err_cnt,
    output  logic   [31:0]  o_txrx_ts_diff_err_cnt,
    output  logic           o_txrx_ts_diff_min_sign,
    output  logic   [95:0]  o_txrx_ts_diff_min,
    output  logic           o_txrx_ts_diff_max_sign,
    output  logic   [95:0]  o_txrx_ts_diff_max
);
    
    localparam BILLION = 48'h3B9ACA000000;
    
    // Capture TX 2-step user input
    logic                   tx_user_ts_ff_in_valid;
    logic                   tx_user_ts_ff_out_valid;
    logic                   ff_tx_ts_req;
    logic   [7:0]           ff_tx_fp;
    
    // TX 2-step timestamp
    logic                   tx_ets_valid;
    logic   [95:0]          tx_ets;
    logic   [7:0]           tx_ets_fp;
    
    // RX timestamp
    logic                   rx_its_valid;
    logic   [95:0]          rx_its;
    
    // Check TX and RX timestamp differences
    logic                   ff_tx_ets_valid;
    logic   [95:0]          ff_tx_ets;
    logic   [7:0]           ff_tx_ets_fp;
    logic                   ff_rx_its_valid;
    logic                   ff_rx_its_valid_r;
    logic   [95:0]          ff_rx_its;
    logic                   diff_valid;
    logic                   first_diff;
    logic                   txrx_ts_diff_sign;
    logic   [95:0]          txrx_ts_diff;
    logic                   txrx_ts_diff_min_sign;
    logic   [95:0]          txrx_ts_diff_min;
    logic                   txrx_ts_diff_max_sign;
    logic   [95:0]          txrx_ts_diff_max;
    logic   [31:0]          txrx_ts_err_cnt;
    logic                   tx_fp_diff;
    logic   [31:0]          tx_fp_err_cnt;
    
    // Statistics of checks
    logic   [31:0]          tx_ts_req_cnt;
    logic   [31:0]          tx_ets_cnt;
    logic   [31:0]          rx_its_cnt;
    
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Capture TX 2-step user input
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
    assign  tx_user_ts_ff_in_valid  =   i_tx_startofpacket && i_tx_valid;
    
    altera_avalon_sc_fifo #(
        .SYMBOLS_PER_BEAT       (1),
        .BITS_PER_SYMBOL        (8+1), // Fingerprint + request
        .FIFO_DEPTH             (32),
        .CHANNEL_WIDTH          (0),
        .ERROR_WIDTH            (0),
        .USE_PACKETS            (0),
        .USE_FILL_LEVEL         (0),
        .USE_STORE_FORWARD      (0),
        .USE_ALMOST_FULL_IF     (0),
        .USE_ALMOST_EMPTY_IF    (0),
        .EMPTY_LATENCY          (0),
        .USE_MEMORY_BLOCKS      (0)
    ) tx_user_ts_ff (
        .clk                    (i_ptp_clk),
        .reset                  (~i_ptp_rst_n),
        
        .in_data                ({i_ptp_ts_req, i_ptp_fp}),
        .in_valid               (tx_user_ts_ff_in_valid),
        .in_startofpacket       (1'b0),
        .in_endofpacket         (1'b0),
        .in_empty               (1'b0),
        .in_error               (1'b0),
        .in_channel             (1'b0),
        .in_ready               (),
        
        .out_data               ({ff_tx_ts_req, ff_tx_fp}),
        .out_valid              (tx_user_ts_ff_out_valid),
        .out_startofpacket      (),
        .out_endofpacket        (),
        .out_empty              (),
        .out_error              (),
        .out_channel            (),
        .out_ready              (ff_rx_its_valid),
        
        .csr_address            (2'h0),
        .csr_write              (1'b0),
        .csr_read               (1'b0),
        .csr_writedata          (32'h0),
        .csr_readdata           (),
        
        .almost_full_data       (),
        .almost_empty_data      ()
    );

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
// TX 2-step timestamp
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
    assign tx_ets_valid = i_ptp_ets_valid;
    assign tx_ets = i_ptp_ets;
    assign tx_ets_fp = i_ptp_ets_fp;
    
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
// RX timestamp
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
    assign  rx_its_valid = i_rx_startofpacket && i_rx_valid;
    assign  rx_its = i_ptp_rx_its;
    
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Check TX and RX timestamp differences
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    altera_avalon_sc_fifo #(
        .SYMBOLS_PER_BEAT       (1),
        .BITS_PER_SYMBOL        (96+8),
        .FIFO_DEPTH             (32),
        .CHANNEL_WIDTH          (0),
        .ERROR_WIDTH            (0),
        .USE_PACKETS            (0),
        .USE_FILL_LEVEL         (0),
        .USE_STORE_FORWARD      (0),
        .USE_ALMOST_FULL_IF     (0),
        .USE_ALMOST_EMPTY_IF    (0),
        .EMPTY_LATENCY          (0),
        .USE_MEMORY_BLOCKS      (0)
    ) tx_ts_ff (
        .clk                    (i_ptp_clk),
        .reset                  (~i_ptp_rst_n),
        
        .in_data                ({tx_ets_fp, tx_ets}),
        .in_valid               (tx_ets_valid),
        .in_startofpacket       (1'b0),
        .in_endofpacket         (1'b0),
        .in_empty               (1'b0),
        .in_error               (1'b0),
        .in_channel             (1'b0),
        .in_ready               (),
        
        .out_data               ({ff_tx_ets_fp, ff_tx_ets}),
        .out_valid              (ff_tx_ets_valid),
        .out_startofpacket      (),
        .out_endofpacket        (),
        .out_empty              (),
        .out_error              (),
        .out_channel            (),
        .out_ready              (ff_rx_its_valid && ff_tx_ts_req),
        
        .csr_address            (2'h0),
        .csr_write              (1'b0),
        .csr_read               (1'b0),
        .csr_writedata          (32'h0),
        .csr_readdata           (),
        
        .almost_full_data       (),
        .almost_empty_data      ()
    );
    
    altera_avalon_sc_fifo #(
        .SYMBOLS_PER_BEAT       (1),
        .BITS_PER_SYMBOL        (96),
        .FIFO_DEPTH             (32),
        .CHANNEL_WIDTH          (0),
        .ERROR_WIDTH            (0),
        .USE_PACKETS            (0),
        .USE_FILL_LEVEL         (0),
        .USE_STORE_FORWARD      (0),
        .USE_ALMOST_FULL_IF     (0),
        .USE_ALMOST_EMPTY_IF    (0),
        .EMPTY_LATENCY          (0),
        .USE_MEMORY_BLOCKS      (0)
    ) rx_ts_ff (
        .clk                    (i_ptp_clk),
        .reset                  (~i_ptp_rst_n),
        
        .in_data                (rx_its),
        .in_valid               (rx_its_valid),
        .in_startofpacket       (1'b0),
        .in_endofpacket         (1'b0),
        .in_empty               (1'b0),
        .in_error               (1'b0),
        .in_channel             (1'b0),
        .in_ready               (),
        
        .out_data               (ff_rx_its),
        .out_valid              (ff_rx_its_valid),
        .out_startofpacket      (),
        .out_endofpacket        (),
        .out_empty              (),
        .out_error              (),
        .out_channel            (),
        .out_ready              (1'b1),
        
        .csr_address            (2'h0),
        .csr_write              (1'b0),
        .csr_read               (1'b0),
        .csr_writedata          (32'h0),
        .csr_readdata           (),
        
        .almost_full_data       (),
        .almost_empty_data      ()
    );
    
    always @ (posedge i_ptp_clk or negedge i_ptp_rst_n) begin
        if (~i_ptp_rst_n) begin
            first_diff              <= 1'b1;
            txrx_ts_diff_sign       <= 1'b0;
            txrx_ts_diff            <= 96'h0;
            txrx_ts_diff_min_sign   <= 1'b0;
            txrx_ts_diff_min        <= 96'h0;
            txrx_ts_diff_max_sign   <= 1'b0;
            txrx_ts_diff_max        <= 96'h0;
            txrx_ts_err_cnt         <= 32'h0;
            ff_rx_its_valid_r       <= 1'b0;
            tx_fp_diff              <= 1'b0;
            tx_fp_err_cnt           <= 32'h0;
        end else begin
            ff_rx_its_valid_r       <= ff_rx_its_valid;
            if(ff_rx_its_valid) begin
                diff_valid          <= ff_tx_ts_req;
                txrx_ts_diff_sign   <= ff_tx_ts_req? (ff_rx_its >= ff_tx_ets)? 1'b0:
                                                                               1'b1:
                                                     1'b0;
                txrx_ts_diff        <= ff_tx_ts_req? (ff_rx_its >= ff_tx_ets)? ts_subtract(ff_rx_its, ff_tx_ets):
                                                                               ts_subtract(ff_tx_ets, ff_rx_its):
                                                     96'h0;
                tx_fp_diff          <= ff_tx_ts_req? (ff_tx_fp != ff_tx_ets_fp): 1'b0;
            end
            
            if(ff_rx_its_valid_r && diff_valid) begin
                txrx_ts_err_cnt <= (&txrx_ts_err_cnt)                   ? txrx_ts_err_cnt:
                                   (txrx_ts_diff > i_txrx_ts_diff_thres)? txrx_ts_err_cnt + 1'd1:
                                                                          txrx_ts_err_cnt;
                tx_fp_err_cnt   <= (&tx_fp_err_cnt)              ? tx_fp_err_cnt:
                                   tx_fp_diff                    ? tx_fp_err_cnt + 1'd1:
                                                                   tx_fp_err_cnt;
                
                if(first_diff) begin
                    first_diff              <= 1'b0;
                    
                    txrx_ts_diff_min_sign   <= txrx_ts_diff_sign;
                    txrx_ts_diff_min        <= txrx_ts_diff;
                    
                    txrx_ts_diff_max_sign   <= txrx_ts_diff_sign;
                    txrx_ts_diff_max        <= txrx_ts_diff;
                end
                else begin
                    if(txrx_ts_diff_max_sign == 1'b0) begin
                        if((txrx_ts_diff_sign == 1'b0) && (txrx_ts_diff > txrx_ts_diff_max)) begin
                            txrx_ts_diff_max_sign <= txrx_ts_diff_sign;
                            txrx_ts_diff_max <= txrx_ts_diff;
                        end
                    end
                    else if(txrx_ts_diff_max_sign == 1'b1) begin
                        if(txrx_ts_diff_sign == 1'b0) begin
                            txrx_ts_diff_max_sign <= txrx_ts_diff_sign;
                            txrx_ts_diff_max <= txrx_ts_diff;
                        end
                        else if((txrx_ts_diff_sign == 1'b1) && (txrx_ts_diff < txrx_ts_diff_max)) begin
                            txrx_ts_diff_max_sign <= txrx_ts_diff_sign;
                            txrx_ts_diff_max <= txrx_ts_diff;
                        end
                    end
                    
                    if(txrx_ts_diff_min_sign == 1'b1) begin
                        if((txrx_ts_diff_sign == 1'b1) && (txrx_ts_diff > txrx_ts_diff_min)) begin
                            txrx_ts_diff_min_sign <= txrx_ts_diff_sign;
                            txrx_ts_diff_min <= txrx_ts_diff;
                        end
                    end
                    else if(txrx_ts_diff_min_sign == 1'b0) begin
                        if(txrx_ts_diff_sign == 1'b1) begin
                            txrx_ts_diff_min_sign <= txrx_ts_diff_sign;
                            txrx_ts_diff_min <= txrx_ts_diff;
                        end
                        else if((txrx_ts_diff_sign == 1'b0) && (txrx_ts_diff < txrx_ts_diff_min)) begin
                            txrx_ts_diff_min_sign <= txrx_ts_diff_sign;
                            txrx_ts_diff_min <= txrx_ts_diff;
                        end
                    end
                end
            end
        end
    end
    
    assign o_tx_fp_err_cnt          = tx_fp_err_cnt;
    assign o_txrx_ts_diff_err_cnt   = txrx_ts_err_cnt;
    assign o_txrx_ts_diff_min_sign  = txrx_ts_diff_min_sign;
    assign o_txrx_ts_diff_min       = txrx_ts_diff_min;
    assign o_txrx_ts_diff_max_sign  = txrx_ts_diff_max_sign;
    assign o_txrx_ts_diff_max       = txrx_ts_diff_max;
    
    always @ (posedge i_ptp_clk or negedge i_ptp_rst_n) begin
        if (~i_ptp_rst_n) begin
            tx_ets_cnt      <= 32'h0;
            rx_its_cnt      <= 32'h0;
        end else begin
            if(tx_ets_valid) begin
                tx_ets_cnt <= tx_ets_cnt + 1'b1;
            end
            if(rx_its_valid) begin
                rx_its_cnt <= rx_its_cnt + 1'b1;
            end
        end
    end
    
    always @ (negedge i_ptp_clk or negedge i_ptp_rst_n) begin
        if (~i_ptp_rst_n) begin
            tx_ts_req_cnt   <= 32'h0;
        end else begin
            if(tx_user_ts_ff_in_valid & i_ptp_ts_req) begin
            tx_ts_req_cnt <= tx_ts_req_cnt + 1'b1;
            end
        end
    end
    
    assign o_tx_ts_req_cnt = tx_ts_req_cnt;
    assign o_tx_ets_cnt    = tx_ets_cnt;
    assign o_rx_its_cnt    = rx_its_cnt;
    
    function logic [95:0] ts_subtract (input logic [95:0] ts_1, input logic [95:0] ts_2);
        logic [47:0] ts_1_s;
        logic [47:0] ts_1_ns_fns;
        logic [47:0] ts_2_s;
        logic [47:0] ts_2_ns_fns;
        logic [47:0] diff_s;
        logic [47:0] diff_ns_fns;
        
        ts_1_s = ts_1[95:48];
        ts_1_ns_fns = ts_1[47:0];
        
        ts_2_s = ts_2[95:48];
        ts_2_ns_fns = ts_2[47:0];
        
        diff_ns_fns = (ts_1_ns_fns > ts_2_ns_fns) ? (ts_1_ns_fns - ts_2_ns_fns) : (ts_1_ns_fns - ts_2_ns_fns) + BILLION;
        diff_s = (ts_1_ns_fns > ts_2_ns_fns) ? (ts_1_s - ts_2_s) : (ts_1_s - ts_2_s) - 1'b1;
        
        ts_subtract = {diff_s, diff_ns_fns};
    endfunction

endmodule
