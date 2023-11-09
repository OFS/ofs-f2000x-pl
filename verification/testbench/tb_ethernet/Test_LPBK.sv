// Copyright (C) 2023 Intel Corporation
// SPDX-License-Identifier: MIT

if(MODE_25G_10G)begin
   force hssi_if[0].rx_p = mac_ethernet_if[0].tx_lane[0];
   force mac_ethernet_if[0].rx_lane[0] = hssi_if[0].tx_p;

   force hssi_if[1].rx_p = mac_ethernet_if[1].tx_lane[0];
   force mac_ethernet_if[1].rx_lane[0] = hssi_if[1].tx_p;

   force hssi_if[2].rx_p = mac_ethernet_if[2].tx_lane[0];
   force mac_ethernet_if[2].rx_lane[0] = hssi_if[2].tx_p;

   force hssi_if[3].rx_p = mac_ethernet_if[3].tx_lane[0];
   force mac_ethernet_if[3].rx_lane[0] = hssi_if[3].tx_p;

   force hssi_if[4].rx_p = mac_ethernet_if[4].tx_lane[0];
   force mac_ethernet_if[4].rx_lane[0] = hssi_if[4].tx_p;

   force hssi_if[5].rx_p = mac_ethernet_if[5].tx_lane[0];
   force mac_ethernet_if[5].rx_lane[0] = hssi_if[5].tx_p;
   
   force hssi_if[6].rx_p = mac_ethernet_if[6].tx_lane[0];
   force mac_ethernet_if[6].rx_lane[0] = hssi_if[6].tx_p;

   force hssi_if[7].rx_p = mac_ethernet_if[7].tx_lane[0];
   force mac_ethernet_if[7].rx_lane[0] = hssi_if[7].tx_p;
end 




