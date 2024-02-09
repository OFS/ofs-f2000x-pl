# Copyright (C) 2020 Intel Corporation.
# SPDX-License-Identifier: MIT

#
# Description
#-----------------------------------------------------------------------------
#
# Memory pin and location assignments
#
#-----------------------------------------------------------------------------
set_instance_assignment -name IO_STANDARD "TRUE DIFFERENTIAL SIGNALING" -to ddr4_mem[0].ref_clk -entity top
set_instance_assignment -name IO_STANDARD "TRUE DIFFERENTIAL SIGNALING" -to ddr4_mem[1].ref_clk -entity top
set_instance_assignment -name IO_STANDARD "TRUE DIFFERENTIAL SIGNALING" -to ddr4_mem[2].ref_clk -entity top
set_instance_assignment -name IO_STANDARD "TRUE DIFFERENTIAL SIGNALING" -to ddr4_mem[3].ref_clk -entity top

#-----------------------------------------------------------------------------
# EMIF CH0
#-----------------------------------------------------------------------------
set_location_assignment PIN_C26 -to ddr4_mem[0].ref_clk
set_location_assignment PIN_A27 -to "ddr4_mem[0].ref_clk(n)"
set_location_assignment PIN_G26 -to ddr4_mem[0].oct_rzqin

set_location_assignment PIN_L32 -to ddr4_mem[0].a[0]
set_location_assignment PIN_N33 -to ddr4_mem[0].a[1]
set_location_assignment PIN_W32 -to ddr4_mem[0].a[2]
set_location_assignment PIN_U33 -to ddr4_mem[0].a[3]
set_location_assignment PIN_L30 -to ddr4_mem[0].a[4]
set_location_assignment PIN_N31 -to ddr4_mem[0].a[5]
set_location_assignment PIN_W30 -to ddr4_mem[0].a[6]
set_location_assignment PIN_U31 -to ddr4_mem[0].a[7]
set_location_assignment PIN_L28 -to ddr4_mem[0].a[8]
set_location_assignment PIN_N29 -to ddr4_mem[0].a[9]
set_location_assignment PIN_W28 -to ddr4_mem[0].a[10]
set_location_assignment PIN_U29 -to ddr4_mem[0].a[11]
set_location_assignment PIN_J27 -to ddr4_mem[0].a[12]
set_location_assignment PIN_C24 -to ddr4_mem[0].a[13]
set_location_assignment PIN_A25 -to ddr4_mem[0].a[14]
set_location_assignment PIN_G24 -to ddr4_mem[0].a[15]
set_location_assignment PIN_J25 -to ddr4_mem[0].a[16]
set_location_assignment PIN_A23 -to ddr4_mem[0].ba[0]
set_location_assignment PIN_G22 -to ddr4_mem[0].ba[1]
set_location_assignment PIN_J23 -to ddr4_mem[0].bg[0]

set_location_assignment PIN_J33 -to ddr4_mem[0].act_n
set_location_assignment PIN_C22 -to ddr4_mem[0].alert_n
set_location_assignment PIN_C30 -to ddr4_mem[0].odt
set_location_assignment PIN_J29 -to ddr4_mem[0].par
set_location_assignment PIN_A33 -to ddr4_mem[0].reset_n
set_location_assignment PIN_G30 -to ddr4_mem[0].cke
set_location_assignment PIN_G32 -to ddr4_mem[0].cs_n[0]
set_location_assignment PIN_C28 -to ddr4_mem[0].ck
set_location_assignment PIN_A29 -to ddr4_mem[0].ck_n

# CH0 DQS0
set_location_assignment PIN_U27 -to ddr4_mem[0].dq[0]
set_location_assignment PIN_N23 -to ddr4_mem[0].dq[1]
set_location_assignment PIN_W26 -to ddr4_mem[0].dq[2]
set_location_assignment PIN_L22 -to ddr4_mem[0].dq[3]
set_location_assignment PIN_L26 -to ddr4_mem[0].dq[4]
set_location_assignment PIN_W22 -to ddr4_mem[0].dq[5]
set_location_assignment PIN_N27 -to ddr4_mem[0].dq[6]
set_location_assignment PIN_U23 -to ddr4_mem[0].dq[7]
set_location_assignment PIN_L24 -to ddr4_mem[0].dqs[0]
set_location_assignment PIN_N25 -to ddr4_mem[0].dqs_n[0]
set_location_assignment PIN_W24 -to ddr4_mem[0].dbi_n[0]

# CH0 DQS1
set_location_assignment PIN_AF26 -to ddr4_mem[0].dq[8]
set_location_assignment PIN_AH23 -to ddr4_mem[0].dq[9]
set_location_assignment PIN_AC26 -to ddr4_mem[0].dq[10]
set_location_assignment PIN_AF22 -to ddr4_mem[0].dq[11]
set_location_assignment PIN_AA27 -to ddr4_mem[0].dq[12]
set_location_assignment PIN_AA23 -to ddr4_mem[0].dq[13]
set_location_assignment PIN_AH27 -to ddr4_mem[0].dq[14]
set_location_assignment PIN_AC22 -to ddr4_mem[0].dq[15]
set_location_assignment PIN_AC24 -to ddr4_mem[0].dqs[1]
set_location_assignment PIN_AA25 -to ddr4_mem[0].dqs_n[1]
set_location_assignment PIN_AF24 -to ddr4_mem[0].dbi_n[1]

# CH0 DQS2
set_location_assignment PIN_AT27 -to ddr4_mem[0].dq[16]
set_location_assignment PIN_AK22 -to ddr4_mem[0].dq[17]
set_location_assignment PIN_AM27 -to ddr4_mem[0].dq[18]
set_location_assignment PIN_AT23 -to ddr4_mem[0].dq[19]
set_location_assignment PIN_AV26 -to ddr4_mem[0].dq[20]
set_location_assignment PIN_AV22 -to ddr4_mem[0].dq[21]
set_location_assignment PIN_AK26 -to ddr4_mem[0].dq[22]
set_location_assignment PIN_AM23 -to ddr4_mem[0].dq[23]
set_location_assignment PIN_AK24 -to ddr4_mem[0].dqs[2]
set_location_assignment PIN_AM25 -to ddr4_mem[0].dqs_n[2]
set_location_assignment PIN_AV24 -to ddr4_mem[0].dbi_n[2]

# CH0 DQS3
set_location_assignment PIN_AK32 -to ddr4_mem[0].dq[24]
set_location_assignment PIN_AT29 -to ddr4_mem[0].dq[25]
set_location_assignment PIN_AM33 -to ddr4_mem[0].dq[26]
set_location_assignment PIN_AV28 -to ddr4_mem[0].dq[27]
set_location_assignment PIN_AT33 -to ddr4_mem[0].dq[28]
set_location_assignment PIN_AM29 -to ddr4_mem[0].dq[29]
set_location_assignment PIN_AV32 -to ddr4_mem[0].dq[30]
set_location_assignment PIN_AK28 -to ddr4_mem[0].dq[31]
set_location_assignment PIN_AK30 -to ddr4_mem[0].dqs[3]
set_location_assignment PIN_AM31 -to ddr4_mem[0].dqs_n[3]
set_location_assignment PIN_AV30 -to ddr4_mem[0].dbi_n[3]

# # CH0 DQS4 (ECC)
# set_location_assignment PIN_A39 -to ddr4_mem[0].dq[32]
# set_location_assignment PIN_J35 -to ddr4_mem[0].dq[33]
# set_location_assignment PIN_C38 -to ddr4_mem[0].dq[34]
# set_location_assignment PIN_G34 -to ddr4_mem[0].dq[35]
# set_location_assignment PIN_G38 -to ddr4_mem[0].dq[36]
# set_location_assignment PIN_C34 -to ddr4_mem[0].dq[37]
# set_location_assignment PIN_J39 -to ddr4_mem[0].dq[38]
# set_location_assignment PIN_A35 -to ddr4_mem[0].dq[39]
# set_location_assignment PIN_C36 -to ddr4_mem[0].dqs[4]
# set_location_assignment PIN_A37 -to ddr4_mem[0].dqs_n[4]
# set_location_assignment PIN_G36 -to ddr4_mem[0].dbi_n[4]

#-----------------------------------------------------------------------------
# EMIF CH1
#-----------------------------------------------------------------------------
set_location_assignment PIN_C12 -to ddr4_mem[1].ref_clk
set_location_assignment PIN_A14 -to "ddr4_mem[1].ref_clk(n)"
set_location_assignment PIN_G12 -to ddr4_mem[1].oct_rzqin

set_location_assignment PIN_L20 -to ddr4_mem[1].a[0]
set_location_assignment PIN_N21 -to ddr4_mem[1].a[1]
set_location_assignment PIN_W20 -to ddr4_mem[1].a[2]
set_location_assignment PIN_U21 -to ddr4_mem[1].a[3]
set_location_assignment PIN_L18 -to ddr4_mem[1].a[4]
set_location_assignment PIN_N19 -to ddr4_mem[1].a[5]
set_location_assignment PIN_W18 -to ddr4_mem[1].a[6]
set_location_assignment PIN_U19 -to ddr4_mem[1].a[7]
set_location_assignment PIN_L15 -to ddr4_mem[1].a[8]
set_location_assignment PIN_N17 -to ddr4_mem[1].a[9]
set_location_assignment PIN_W15 -to ddr4_mem[1].a[10]
set_location_assignment PIN_U17 -to ddr4_mem[1].a[11]
set_location_assignment PIN_J14 -to ddr4_mem[1].a[12]
set_location_assignment PIN_C9  -to ddr4_mem[1].a[13]
set_location_assignment PIN_A10 -to ddr4_mem[1].a[14]
set_location_assignment PIN_G9  -to ddr4_mem[1].a[15]
set_location_assignment PIN_J10 -to ddr4_mem[1].a[16]
set_location_assignment PIN_E5  -to ddr4_mem[1].ba[0]
set_location_assignment PIN_G6  -to ddr4_mem[1].ba[1]
set_location_assignment PIN_J7  -to ddr4_mem[1].bg[0]

set_location_assignment PIN_J21 -to ddr4_mem[1].act_n
set_location_assignment PIN_G3  -to ddr4_mem[1].alert_n
set_location_assignment PIN_C18 -to ddr4_mem[1].odt
set_location_assignment PIN_J17 -to ddr4_mem[1].par
set_location_assignment PIN_A21 -to ddr4_mem[1].reset_n
set_location_assignment PIN_G18 -to ddr4_mem[1].cke
set_location_assignment PIN_G20 -to ddr4_mem[1].cs_n[0]
set_location_assignment PIN_C15 -to ddr4_mem[1].ck
set_location_assignment PIN_A17 -to ddr4_mem[1].ck_n

# CH1 DQS0
set_location_assignment PIN_AA17 -to ddr4_mem[1].dq[0]
set_location_assignment PIN_AC20 -to ddr4_mem[1].dq[1]
set_location_assignment PIN_AH17 -to ddr4_mem[1].dq[2]
set_location_assignment PIN_AF20 -to ddr4_mem[1].dq[3]
set_location_assignment PIN_AC15 -to ddr4_mem[1].dq[4]
set_location_assignment PIN_AH21 -to ddr4_mem[1].dq[5]
set_location_assignment PIN_AF15 -to ddr4_mem[1].dq[6]
set_location_assignment PIN_AA21 -to ddr4_mem[1].dq[7]
set_location_assignment PIN_AC18 -to ddr4_mem[1].dqs[0]
set_location_assignment PIN_AA19 -to ddr4_mem[1].dqs_n[0]
set_location_assignment PIN_AF18 -to ddr4_mem[1].dbi_n[0]

# CH1 DQS1
set_location_assignment PIN_AT17 -to ddr4_mem[1].dq[8]
set_location_assignment PIN_AT21 -to ddr4_mem[1].dq[9]
set_location_assignment PIN_AV15 -to ddr4_mem[1].dq[10]
set_location_assignment PIN_AV20 -to ddr4_mem[1].dq[11]
set_location_assignment PIN_AM17 -to ddr4_mem[1].dq[12]
set_location_assignment PIN_AK20 -to ddr4_mem[1].dq[13]
set_location_assignment PIN_AK15 -to ddr4_mem[1].dq[14]
set_location_assignment PIN_AM21 -to ddr4_mem[1].dq[15]
set_location_assignment PIN_AK18 -to ddr4_mem[1].dqs[1]
set_location_assignment PIN_AM19 -to ddr4_mem[1].dqs_n[1]
set_location_assignment PIN_AV18 -to ddr4_mem[1].dbi_n[1]

# CH1 DQS2
set_location_assignment PIN_AV6  -to ddr4_mem[1].dq[16]
set_location_assignment PIN_AK12 -to ddr4_mem[1].dq[17]
set_location_assignment PIN_AT7  -to ddr4_mem[1].dq[18]
set_location_assignment PIN_AK6  -to ddr4_mem[1].dq[19]
set_location_assignment PIN_AV12 -to ddr4_mem[1].dq[20]
set_location_assignment PIN_AM14 -to ddr4_mem[1].dq[21]
set_location_assignment PIN_AT14 -to ddr4_mem[1].dq[22]
set_location_assignment PIN_AM7  -to ddr4_mem[1].dq[23]
set_location_assignment PIN_AK9  -to ddr4_mem[1].dqs[2]
set_location_assignment PIN_AM10 -to ddr4_mem[1].dqs_n[2]
set_location_assignment PIN_AV9  -to ddr4_mem[1].dbi_n[2]

# CH1 DQS3
set_location_assignment PIN_AA7  -to ddr4_mem[1].dq[24]
set_location_assignment PIN_AH14 -to ddr4_mem[1].dq[25]
set_location_assignment PIN_AC6  -to ddr4_mem[1].dq[26]
set_location_assignment PIN_AF12 -to ddr4_mem[1].dq[27]
set_location_assignment PIN_AH7  -to ddr4_mem[1].dq[28]
set_location_assignment PIN_AC12 -to ddr4_mem[1].dq[29]
set_location_assignment PIN_AF6  -to ddr4_mem[1].dq[30]
set_location_assignment PIN_AA14 -to ddr4_mem[1].dq[31]
set_location_assignment PIN_AC9  -to ddr4_mem[1].dqs[3]
set_location_assignment PIN_AA10 -to ddr4_mem[1].dqs_n[3]
set_location_assignment PIN_AF9  -to ddr4_mem[1].dbi_n[3]

# # CH1 DQS4 (ECC)
# set_location_assignment PIN_N7  -to ddr4_mem[1].dq[32]
# set_location_assignment PIN_L12 -to ddr4_mem[1].dq[33]
# set_location_assignment PIN_L6  -to ddr4_mem[1].dq[34]
# set_location_assignment PIN_U14 -to ddr4_mem[1].dq[35]
# set_location_assignment PIN_U7  -to ddr4_mem[1].dq[36]
# set_location_assignment PIN_W12 -to ddr4_mem[1].dq[37]
# set_location_assignment PIN_W6  -to ddr4_mem[1].dq[38]
# set_location_assignment PIN_N14 -to ddr4_mem[1].dq[39]
# set_location_assignment PIN_L9  -to ddr4_mem[1].dqs[4]
# set_location_assignment PIN_N10 -to ddr4_mem[1].dqs_n[4]
# set_location_assignment PIN_G12 -to ddr4_mem[1].dbi_n[4]

#-----------------------------------------------------------------------------
# EMIF CH2
#-----------------------------------------------------------------------------
set_location_assignment PIN_HF35 -to ddr4_mem[2].ref_clk
set_location_assignment PIN_HH34 -to "ddr4_mem[2].ref_clk(n)"
set_location_assignment PIN_HB35 -to ddr4_mem[2].oct_rzqin

set_location_assignment PIN_GU41 -to ddr4_mem[2].a[0]
set_location_assignment PIN_GP40 -to ddr4_mem[2].a[1]
set_location_assignment PIN_GG41 -to ddr4_mem[2].a[2]
set_location_assignment PIN_GJ40 -to ddr4_mem[2].a[3]
set_location_assignment PIN_GU39 -to ddr4_mem[2].a[4]
set_location_assignment PIN_GP38 -to ddr4_mem[2].a[5]
set_location_assignment PIN_GG39 -to ddr4_mem[2].a[6]
set_location_assignment PIN_GJ38 -to ddr4_mem[2].a[7]
set_location_assignment PIN_GU37 -to ddr4_mem[2].a[8]
set_location_assignment PIN_GP36 -to ddr4_mem[2].a[9]
set_location_assignment PIN_GG37 -to ddr4_mem[2].a[10]
set_location_assignment PIN_GJ36 -to ddr4_mem[2].a[11]
set_location_assignment PIN_GW34 -to ddr4_mem[2].a[12]
set_location_assignment PIN_HF33 -to ddr4_mem[2].a[13]
set_location_assignment PIN_HH32 -to ddr4_mem[2].a[14]
set_location_assignment PIN_HB33 -to ddr4_mem[2].a[15]
set_location_assignment PIN_GW32 -to ddr4_mem[2].a[16]
set_location_assignment PIN_HH30 -to ddr4_mem[2].ba[0]
set_location_assignment PIN_HB31 -to ddr4_mem[2].ba[1]
set_location_assignment PIN_GW30 -to ddr4_mem[2].bg[0]

set_location_assignment PIN_GW40 -to ddr4_mem[2].act_n
set_location_assignment PIN_HF31 -to ddr4_mem[2].alert_n
set_location_assignment PIN_HF39 -to ddr4_mem[2].odt
set_location_assignment PIN_GW36 -to ddr4_mem[2].par
set_location_assignment PIN_HH40 -to ddr4_mem[2].reset_n
set_location_assignment PIN_HB39 -to ddr4_mem[2].cke
set_location_assignment PIN_HB41 -to ddr4_mem[2].cs_n[0]
set_location_assignment PIN_HF37 -to ddr4_mem[2].ck
set_location_assignment PIN_HH36 -to ddr4_mem[2].ck_n

# CH2 DQS0
set_location_assignment PIN_FK30 -to ddr4_mem[2].dq[0]
set_location_assignment PIN_FT35 -to ddr4_mem[2].dq[1]
set_location_assignment PIN_FP30 -to ddr4_mem[2].dq[2]
set_location_assignment PIN_FP34 -to ddr4_mem[2].dq[3]
set_location_assignment PIN_FH31 -to ddr4_mem[2].dq[4]
set_location_assignment PIN_FK34 -to ddr4_mem[2].dq[5]
set_location_assignment PIN_FT31 -to ddr4_mem[2].dq[6]
set_location_assignment PIN_FH35 -to ddr4_mem[2].dq[7]
set_location_assignment PIN_FT33 -to ddr4_mem[2].dqs[0]
set_location_assignment PIN_FP32 -to ddr4_mem[2].dqs_n[0]
set_location_assignment PIN_FH33 -to ddr4_mem[2].dbi_n[0]

# CH2 DQS1
set_location_assignment PIN_FY31 -to ddr4_mem[2].dq[8]
set_location_assignment PIN_FV34 -to ddr4_mem[2].dq[9]
set_location_assignment PIN_GE30 -to ddr4_mem[2].dq[10]
set_location_assignment PIN_GE34 -to ddr4_mem[2].dq[11]
set_location_assignment PIN_GC31 -to ddr4_mem[2].dq[12]
set_location_assignment PIN_FY35 -to ddr4_mem[2].dq[13]
set_location_assignment PIN_FV30 -to ddr4_mem[2].dq[14]
set_location_assignment PIN_GC35 -to ddr4_mem[2].dq[15]
set_location_assignment PIN_GC33 -to ddr4_mem[2].dqs[1]
set_location_assignment PIN_GE32 -to ddr4_mem[2].dqs_n[1]
set_location_assignment PIN_FY33 -to ddr4_mem[2].dbi_n[1]

# CH2 DQS2
set_location_assignment PIN_GP30 -to ddr4_mem[2].dq[16]
set_location_assignment PIN_GU35 -to ddr4_mem[2].dq[17]
set_location_assignment PIN_GU31 -to ddr4_mem[2].dq[18]
set_location_assignment PIN_GP34 -to ddr4_mem[2].dq[19]
set_location_assignment PIN_GG31 -to ddr4_mem[2].dq[20]
set_location_assignment PIN_GG35 -to ddr4_mem[2].dq[21]
set_location_assignment PIN_GJ30 -to ddr4_mem[2].dq[22]
set_location_assignment PIN_GJ34 -to ddr4_mem[2].dq[23]
set_location_assignment PIN_GU33 -to ddr4_mem[2].dqs[2]
set_location_assignment PIN_GP32 -to ddr4_mem[2].dqs_n[2]
set_location_assignment PIN_GG33 -to ddr4_mem[2].dbi_n[2]

# CH2 DQS3
set_location_assignment PIN_FH37 -to ddr4_mem[2].dq[24]
set_location_assignment PIN_FK40 -to ddr4_mem[2].dq[25]
set_location_assignment PIN_FK36 -to ddr4_mem[2].dq[26]
set_location_assignment PIN_FP40 -to ddr4_mem[2].dq[27]
set_location_assignment PIN_FT37 -to ddr4_mem[2].dq[28]
set_location_assignment PIN_FH41 -to ddr4_mem[2].dq[29]
set_location_assignment PIN_FP36 -to ddr4_mem[2].dq[30]
set_location_assignment PIN_FT41 -to ddr4_mem[2].dq[31]
set_location_assignment PIN_FT39 -to ddr4_mem[2].dqs[3]
set_location_assignment PIN_FP38 -to ddr4_mem[2].dqs_n[3]
set_location_assignment PIN_FH39 -to ddr4_mem[2].dbi_n[3]

# CH2 DQS4 (ECC)
set_location_assignment PIN_GC37 -to ddr4_mem[2].dq[32]
set_location_assignment PIN_GC41 -to ddr4_mem[2].dq[33]
set_location_assignment PIN_FY37 -to ddr4_mem[2].dq[34]
set_location_assignment PIN_GE40 -to ddr4_mem[2].dq[35]
set_location_assignment PIN_FV36 -to ddr4_mem[2].dq[36]
set_location_assignment PIN_FY41 -to ddr4_mem[2].dq[37]
set_location_assignment PIN_GE36 -to ddr4_mem[2].dq[38]
set_location_assignment PIN_FV40 -to ddr4_mem[2].dq[39]
set_location_assignment PIN_GE38 -to ddr4_mem[2].dqs[4]
set_location_assignment PIN_GC39 -to ddr4_mem[2].dqs_n[4]
set_location_assignment PIN_FV38 -to ddr4_mem[2].dbi_n[4]

#-----------------------------------------------------------------------------
# EMIF CH3
#-----------------------------------------------------------------------------
set_location_assignment PIN_HH48 -to ddr4_mem[3].ref_clk
set_location_assignment PIN_HF49 -to "ddr4_mem[3].ref_clk(n)"
set_location_assignment PIN_GW48 -to ddr4_mem[3].oct_rzqin

set_location_assignment PIN_GP42 -to ddr4_mem[3].a[0]
set_location_assignment PIN_GU43 -to ddr4_mem[3].a[1]
set_location_assignment PIN_GJ42 -to ddr4_mem[3].a[2]
set_location_assignment PIN_GG43 -to ddr4_mem[3].a[3]
set_location_assignment PIN_GP44 -to ddr4_mem[3].a[4]
set_location_assignment PIN_GU45 -to ddr4_mem[3].a[5]
set_location_assignment PIN_GJ44 -to ddr4_mem[3].a[6]
set_location_assignment PIN_GG45 -to ddr4_mem[3].a[7]
set_location_assignment PIN_GP46 -to ddr4_mem[3].a[8]
set_location_assignment PIN_GU47 -to ddr4_mem[3].a[9]
set_location_assignment PIN_GJ46 -to ddr4_mem[3].a[10]
set_location_assignment PIN_GG47 -to ddr4_mem[3].a[11]
set_location_assignment PIN_HB49 -to ddr4_mem[3].a[12]
set_location_assignment PIN_HH50 -to ddr4_mem[3].a[13]
set_location_assignment PIN_HF51 -to ddr4_mem[3].a[14]
set_location_assignment PIN_GW50 -to ddr4_mem[3].a[15]
set_location_assignment PIN_HB51 -to ddr4_mem[3].a[16]
set_location_assignment PIN_HF53 -to ddr4_mem[3].ba[0]
set_location_assignment PIN_GW52 -to ddr4_mem[3].ba[1]
set_location_assignment PIN_HB53 -to ddr4_mem[3].bg[0]

set_location_assignment PIN_HB43 -to ddr4_mem[3].act_n
set_location_assignment PIN_HH52 -to ddr4_mem[3].alert_n
set_location_assignment PIN_HH44 -to ddr4_mem[3].odt
set_location_assignment PIN_HB47 -to ddr4_mem[3].par
set_location_assignment PIN_HF43 -to ddr4_mem[3].reset_n
set_location_assignment PIN_GW44 -to ddr4_mem[3].cke
set_location_assignment PIN_GW42 -to ddr4_mem[3].cs_n[0]
set_location_assignment PIN_HH46 -to ddr4_mem[3].ck
set_location_assignment PIN_HF47 -to ddr4_mem[3].ck_n

# CH3 DQS0
set_location_assignment PIN_FH53 -to ddr4_mem[3].dq[0]
set_location_assignment PIN_FH49 -to ddr4_mem[3].dq[1]
set_location_assignment PIN_FK52 -to ddr4_mem[3].dq[2]
set_location_assignment PIN_FT49 -to ddr4_mem[3].dq[3]
set_location_assignment PIN_FP52 -to ddr4_mem[3].dq[4]
set_location_assignment PIN_FK48 -to ddr4_mem[3].dq[5]
set_location_assignment PIN_FT53 -to ddr4_mem[3].dq[6]
set_location_assignment PIN_FP48 -to ddr4_mem[3].dq[7]
set_location_assignment PIN_FP50 -to ddr4_mem[3].dqs[0]
set_location_assignment PIN_FT51 -to ddr4_mem[3].dqs_n[0]
set_location_assignment PIN_FK50 -to ddr4_mem[3].dbi_n[0]

# CH3 DQS1
set_location_assignment PIN_GC53 -to ddr4_mem[3].dq[8]
set_location_assignment PIN_FY49 -to ddr4_mem[3].dq[9]
set_location_assignment PIN_GE52 -to ddr4_mem[3].dq[10]
set_location_assignment PIN_FV48 -to ddr4_mem[3].dq[11]
set_location_assignment PIN_FY53 -to ddr4_mem[3].dq[12]
set_location_assignment PIN_GC49 -to ddr4_mem[3].dq[13]
set_location_assignment PIN_FV52 -to ddr4_mem[3].dq[14]
set_location_assignment PIN_GE48 -to ddr4_mem[3].dq[15]
set_location_assignment PIN_GE50 -to ddr4_mem[3].dqs[1]
set_location_assignment PIN_GC51 -to ddr4_mem[3].dqs_n[1]
set_location_assignment PIN_FV50 -to ddr4_mem[3].dbi_n[1]

# CH3 DQS2
set_location_assignment PIN_GC47 -to ddr4_mem[3].dq[16]
set_location_assignment PIN_GC43 -to ddr4_mem[3].dq[17]
set_location_assignment PIN_GE46 -to ddr4_mem[3].dq[18]
set_location_assignment PIN_FY43 -to ddr4_mem[3].dq[19]
set_location_assignment PIN_FV46 -to ddr4_mem[3].dq[20]
set_location_assignment PIN_GE42 -to ddr4_mem[3].dq[21]
set_location_assignment PIN_FY47 -to ddr4_mem[3].dq[22]
set_location_assignment PIN_FV42 -to ddr4_mem[3].dq[23]
set_location_assignment PIN_GE44 -to ddr4_mem[3].dqs[2]
set_location_assignment PIN_GC45 -to ddr4_mem[3].dqs_n[2]
set_location_assignment PIN_FV44 -to ddr4_mem[3].dbi_n[2]

# CH3 DQS3
set_location_assignment PIN_GU53 -to ddr4_mem[3].dq[24]
set_location_assignment PIN_GG49 -to ddr4_mem[3].dq[25]
set_location_assignment PIN_GP52 -to ddr4_mem[3].dq[26]
set_location_assignment PIN_GJ48 -to ddr4_mem[3].dq[27]
set_location_assignment PIN_GG53 -to ddr4_mem[3].dq[28]
set_location_assignment PIN_GU49 -to ddr4_mem[3].dq[29]
set_location_assignment PIN_GJ52 -to ddr4_mem[3].dq[30]
set_location_assignment PIN_GP48 -to ddr4_mem[3].dq[31]
set_location_assignment PIN_GP50 -to ddr4_mem[3].dqs[3]
set_location_assignment PIN_GU51 -to ddr4_mem[3].dqs_n[3]
set_location_assignment PIN_GJ50 -to ddr4_mem[3].dbi_n[3]

# # CH3 DQS4 (ECC)
# set_location_assignment PIN_FP46 -to ddr4_mem[3].dq[32]
# set_location_assignment PIN_FT43 -to ddr4_mem[3].dq[33]
# set_location_assignment PIN_FH47 -to ddr4_mem[3].dq[34]
# set_location_assignment PIN_FP42 -to ddr4_mem[3].dq[35]
# set_location_assignment PIN_FT47 -to ddr4_mem[3].dq[36]
# set_location_assignment PIN_FH43 -to ddr4_mem[3].dq[37]
# set_location_assignment PIN_FK46 -to ddr4_mem[3].dq[38]
# set_location_assignment PIN_FK42 -to ddr4_mem[3].dq[39]
# set_location_assignment PIN_FP44 -to ddr4_mem[3].dqs[4]
# set_location_assignment PIN_FT45 -to ddr4_mem[3].dqs_n[4]
# set_location_assignment PIN_FK44 -to ddr4_mem[3].dbi_n[4]
