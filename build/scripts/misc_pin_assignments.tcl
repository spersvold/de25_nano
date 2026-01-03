#============================================================
# CLOCK
#============================================================
set_instance_assignment -name IO_STANDARD "1.1-V" -to CLOCK0_50
set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to CLOCK1_50
set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to CLOCK2_50
set_location_assignment PIN_DJ35 -to CLOCK0_50
set_location_assignment PIN_V16  -to CLOCK1_50
set_location_assignment PIN_BF23 -to CLOCK2_50

#============================================================
# KEY
#============================================================
set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to KEY[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to KEY[1]
set_location_assignment PIN_C8   -to KEY[0]
set_location_assignment PIN_C11  -to KEY[1]

#============================================================
# SW
#============================================================
set_instance_assignment -name IO_STANDARD "1.1-V" -to SW[0]
set_instance_assignment -name IO_STANDARD "1.1-V" -to SW[1]
set_instance_assignment -name IO_STANDARD "1.1-V" -to SW[2]
set_instance_assignment -name IO_STANDARD "1.1-V" -to SW[3]
set_location_assignment PIN_DK24 -to SW[0]
set_location_assignment PIN_DD24 -to SW[1]
set_location_assignment PIN_DD27 -to SW[2]
set_location_assignment PIN_DF27 -to SW[3]

#============================================================
# LED
#============================================================
set_instance_assignment -name IO_STANDARD "1.1-V" -to LED[0]
set_instance_assignment -name IO_STANDARD "1.1-V" -to LED[1]
set_instance_assignment -name IO_STANDARD "1.1-V" -to LED[2]
set_instance_assignment -name IO_STANDARD "1.1-V" -to LED[3]
set_instance_assignment -name IO_STANDARD "1.1-V" -to LED[4]
set_instance_assignment -name IO_STANDARD "1.1-V" -to LED[5]
set_instance_assignment -name IO_STANDARD "1.1-V" -to LED[6]
set_instance_assignment -name IO_STANDARD "1.1-V" -to LED[7]
set_location_assignment PIN_DF35 -to LED[0]
set_location_assignment PIN_DJ32 -to LED[1]
set_location_assignment PIN_DN22 -to LED[2]
set_location_assignment PIN_DP23 -to LED[3]
set_location_assignment PIN_DN25 -to LED[4]
set_location_assignment PIN_DP25 -to LED[5]
set_location_assignment PIN_DJ27 -to LED[6]
set_location_assignment PIN_DP30 -to LED[7]

#============================================================
# FPGA UART
#============================================================
set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to FPGA_UART_TX
set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to FPGA_UART_RX
set_location_assignment PIN_CJ1  -to FPGA_UART_TX
set_location_assignment PIN_BR19 -to FPGA_UART_RX

#============================================================
# ADC
#============================================================
set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to ADC_SCK
set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to ADC_SDO
set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to ADC_SDI
set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to ADC_CS_n
set_location_assignment PIN_CH6  -to ADC_SCK
set_location_assignment PIN_CH19 -to ADC_SDO
set_location_assignment PIN_CR8  -to ADC_SDI
set_location_assignment PIN_CE19 -to ADC_CS_n

#============================================================
# FAN
#============================================================
set_instance_assignment -name IO_STANDARD "1.1-V" -to FAN_ALERT_n
set_location_assignment PIN_DK32 -to FAN_ALERT_n
