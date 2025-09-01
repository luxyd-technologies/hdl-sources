# XDC pinout constraints
# part: XC7K325T-2FFG676

#####################################################################################################
### General configuration
#####################################################################################################
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.UNUSEDPIN Pullup [current_design]
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

#####################################################################################################
### general_io
#####################################################################################################
#set_property IOSTANDARD LVCMOS33 [get_ports osc_50mhz]
#set_property PACKAGE_PIN G22 [get_ports osc_50mhz]

set_property IOSTANDARD LVCMOS33 [get_ports user_resetn]
set_property PACKAGE_PIN A12 [get_ports user_resetn]
#set_property PACKAGE_PIN D26 [get_ports user_resetn]

set_property PACKAGE_PIN A23 [get_ports {user_led[0]}]
set_property PACKAGE_PIN A24 [get_ports {user_led[1]}]
set_property PACKAGE_PIN D23 [get_ports {user_led[2]}]
set_property PACKAGE_PIN C24 [get_ports {user_led[3]}]
set_property PACKAGE_PIN C26 [get_ports {user_led[4]}]
set_property PACKAGE_PIN D24 [get_ports {user_led[5]}]
set_property PACKAGE_PIN D25 [get_ports {user_led[6]}]
set_property PACKAGE_PIN E25 [get_ports {user_led[7]}]

set_property IOSTANDARD LVCMOS33 [get_ports {user_led[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {user_led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {user_led[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {user_led[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {user_led[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {user_led[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {user_led[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {user_led[7]}]

#####################################################################################################
### pcie
#####################################################################################################
set_property PACKAGE_PIN K6 [get_ports {pcie_ref_clkp}]
set_property PACKAGE_PIN J4 [get_ports {pcie_mgt_rxp[0]}]
set_property PACKAGE_PIN L4 [get_ports {pcie_mgt_rxp[1]}]
set_property PACKAGE_PIN N4 [get_ports {pcie_mgt_rxp[2]}]
set_property PACKAGE_PIN R4 [get_ports {pcie_mgt_rxp[3]}]

#####################################################################################################
### timing
#####################################################################################################

