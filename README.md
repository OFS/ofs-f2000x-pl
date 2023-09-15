# OFS f2000x Development Directory

This is the OFS f2000x development top-level directory. 

## Cloning this repository

*NOTE:* This repository uses [Git LFS](https://git-lfs.com/) to capture large files in the history without forcing the download of historic files during a plain `clone` operation. Please follow your preferred installation method [from the project's guide](https://github.com/git-lfs/git-lfs#installing) before proceeding. After installation, run `git lfs install` once to install hooks which will transparently fetch the large files into your workspace for use.

To fetch both the `FIM` and `ofs-common` files in a single step, run the following command:

   `git clone --recurse-submodules https://github.com/OFS/ofs-f2000x-pl.git`

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

