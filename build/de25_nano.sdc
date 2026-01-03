## -*- mode: tcl; mode: font-lock; indent-tabs-mode: nil -*-
## vi: set et ts=3 sw=3 sts=3:

#**************************************************************
# This .sdc file is created by Terasic Tool.
# Users are recommended to modify this file to match users logic.
#**************************************************************

set_time_format -unit ns -decimal_places 3

#**************************************************************
# Create Clock
#**************************************************************

create_clock -period "50MHz" [get_ports CLOCK0_50]
#create_clock -period "50MHz" [get_ports CLOCK1_50]
#create_clock -period "50MHz" [get_ports CLOCK2_50]

# sourcing JTAG related SDC
source ./jtag.sdc

#**************************************************************
# Create Generated Clock
#**************************************************************

create_generated_clock -name hdmi_tx_clk \
    -source [get_pins {u_hdmi_pll|iopll_0|tennm_ph2_iopll|out_clk[0]}] \
    -invert \
    [get_ports {HDMI_TX_CLK}]

#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************
derive_clock_uncertainty


#**************************************************************
# Set Input Delay
#**************************************************************



#**************************************************************
# Set Output Delay
#**************************************************************
# max: Board Delay (Data/Cmd) - Board Delay (Clock) + tsu (External Device)
# min: Board Delay (Data/Cmd) - Board Delay (Clock) - th (External Device)
# max: 0.28(data board delay) - 0.3(clock board delay) + 1.5(tDS) = 1.48
# min: 0.27(data board delay) - 0.3(clock board delay) - 1.0(tDH) = -1.03
# max: 0.33(cmd board delay) - 0.3(clock board delay) + 1.5(tDS) = 1.53
# min: 0.28(cmd board delay) - 0.3(clock board delay) - 1.0(tDH) = -1.02

#set clk_name "hdmi_tx_clk"
#set fpga_output_ports [get_ports {HDMI_TX_D[*] HDMI_TX_DE HDMI_TX_HS HDMI_TX_VS}]
#set max_output_delay [expr {1.2 + 0.0}] ; # 1.2ns t_su + 0.0ns board_delay_max
#set min_output_delay [expr {-1.3 + 0.0}] ; # -1.3ns t_h + 0.0ns board_delay_min
#set_output_delay -clock $clk_name -max $max_output_delay $fpga_output_ports
#set_output_delay -clock $clk_name -min $min_output_delay $fpga_output_ports

#**************************************************************
# Set Clock Groups
#**************************************************************
# core_pll (clk_sys @ 250 MHz -- the Agilex5 lwhps2fpga/fpga2hps ceiling, and
# the vctrl system/CSR/scanout domain) and hdmi_pll (pixel clock @ 148.5 MHz)
# are unrelated frequencies that meet only at the vctrl line-buffer CDC.
# Declare them asynchronous so STA treats the crossing as a CDC, not a
# synchronous (and now tighter, at 250 MHz) timing path.
# Pin hierarchy mirrors the hdmi_tx_clk source above (altera_iopll_2110).
set_clock_groups -asynchronous \
    -group [get_clocks -of_objects [get_pins {u_core_pll|iopll_0|tennm_ph2_iopll|out_clk[*]}]] \
    -group [get_clocks -of_objects [get_pins {u_hdmi_pll|iopll_0|tennm_ph2_iopll|out_clk[*]}]]



#**************************************************************
# Set False Path
#**************************************************************
# FPGA IO port constraints
set_false_path -from [get_ports {KEY[*]}] -to *
set_false_path -from [get_ports {SW[*]}] -to *
set_false_path -from * -to [get_ports {LED[*]}]

###
# VGA
# False path config register values used in the pixel clock domnain as they are quasi-static
set_false_path -from [get_keepers -no_duplicates {u_vctrl_core|u_regs|ctrl*}]
set_false_path -from [get_keepers -no_duplicates {u_vctrl_core|u_regs|htim*}]
set_false_path -from [get_keepers -no_duplicates {u_vctrl_core|u_regs|vtim*}]

#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************



#**************************************************************
# Set Load
#**************************************************************
