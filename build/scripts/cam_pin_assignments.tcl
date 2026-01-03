#============================================================
# CAM
#============================================================
set_instance_assignment -name IO_STANDARD "DPHY" -to CAM_CLK_p
set_instance_assignment -name IO_STANDARD "DPHY" -to CAM_CLK_n
set_instance_assignment -name IO_STANDARD "DPHY" -to CAM_D_p[0]
set_instance_assignment -name IO_STANDARD "DPHY" -to CAM_D_p[1]
set_instance_assignment -name IO_STANDARD "DPHY" -to CAM_D_n[0]
set_instance_assignment -name IO_STANDARD "DPHY" -to CAM_D_n[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to CAM_I2C_SCL
set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to CAM_I2C_SDA
set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to CAM_GPIO
set_instance_assignment -name IO_STANDARD "1.1-V" -to CAM_RZQ1
set_location_assignment PIN_DP33 -to CAM_CLK_p
set_location_assignment PIN_DN30 -to CAM_CLK_n
set_location_assignment PIN_DP36 -to CAM_D_p[0]
set_location_assignment PIN_DP38 -to CAM_D_p[1]
set_location_assignment PIN_DN33 -to CAM_D_n[0]
set_location_assignment PIN_DN38 -to CAM_D_n[1]
set_location_assignment PIN_BP2  -to CAM_I2C_SCL
set_location_assignment PIN_BP1  -to CAM_I2C_SDA
set_location_assignment PIN_BR8  -to CAM_GPIO
set_location_assignment PIN_DD35 -to CAM_RZQ1
