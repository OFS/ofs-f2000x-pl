# OFSS Config Tool: PCIe 

## Overview
- This directory contains example PCIe OFSS Configuration Files
- For detailed description on how to run this tool, please refer to ofs-common/tools/ofss_config/README.md

### Board Specific Recommendations
 - PFs must be consecutive

Agilex F2000x PCIe Host  | |
------------- | -------------
Min # of PFs  | 1
Max # of PFs  | 8
Min # of VFs | 0
Max # of VFs | 2000 distributed across all PFs
Consecutive PFs | True  


Agilex F2000x PCIe SoC | |
------------- | -------------
Min # of PFs  | 1
Max # of PFs  | 8
Min # of VFs | 1 on PF0
Max # of VFs | 2000 distributed across all PFs
Consecutive PFs | True  


### Examples

|  F2000x Default  | Host  | SoC |
| ------------- |---------------| -----|
| \# of PFs     | 2 (PF0, PF1) | 1 (PF0) |
| \# of VFs    | 0        |   3 on PF0 |

## Configurable Parameters
- `[pf*]`: integer
- `num_vfs`: integer
- `bar0_address_width`: integer
- `bar4_address_width`: integer
- `vf_bar0_address_width`: integer
- `ats_cap_enable`: 0 or 1
- `prs_ext_cap_able`: 0 or 1
- `pasid_cap_enable`: 0 or 1

```
# pcie_host.ofss
[ip]
type = pcie

[settings]
output_name = pcie_ss

[pf0]
bar0_address_width = 21

[pf1]
```

```
# pcie_soc.ofss

[ip]
type = pcie

[settings]
output_name = soc_pcie_ss

[pf0]
num_vfs = 3
bar0_address_width = 21
vf_bar0_address_width = 21

```



