# PROJECT NOT UNDER ACTIVE MANAGEMENT #  
This project will no longer be maintained by Intel.  
Intel has ceased development and contributions including, but not limited to, maintenance, bug fixes, new releases, or updates, to this project.  
Intel no longer accepts patches to this project.  
 If you have an ongoing need to use this project, are interested in independently developing it, or would like to maintain patches for the open source software community, please create your own fork of this project.  
  
# OFS f2000x Development Directory

This is the OFS f2000x development top-level directory. 

## Board
* f2000x 
   - Default .ip parameters are based on f2000x design
    ```bash
        ./ofs-common/scripts/common/syn/build_top.sh -p --ofss tools/ofss_config/f2000x.ofss,tools/ofss_config/hssi/hssi_8x25.ofss f2000x work_f2000x
    ```
   - Additionally, f2000x fim supports reconfiguring the .ip via .ofss flow. For
     example to change hssi config, pass the .ofss files below. 
    ```bash
        # f2000x with 2x100G 
        ./ofs-common/scripts/common/syn/build_top.sh -p --ofss tools/ofss_config/f2000x_base.ofss,tools/ofss_config/hssi/hssi_2x100.ofss f2000x work_f2000x_2x100

    ```

