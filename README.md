# OFS f2000x Development Directory

This is the OFS f2000x development top-level directory. 

## Board
* f2000x 
   - Default .ip parameters are based on f2000x design
    ```bash
        ./ofs-common/scripts/common/syn/build_top.sh -p f2000x work_f2000x
    ```
   - Additionally, f2000x fim supports reconfiguring the .ip via .ofss flow. For
     example to change hssi config, pass the .ofss files below. 
    ```bash
        # f2000x with 2x100G 
        ./ofs-common/scripts/common/syn/build_top.sh -p --ofss tools/ofss_config/f2000x_base.ofss,tools/ofss_config/hssi/hssi_2x100.ofss f2000x work_f2000x_2x100

    ```

