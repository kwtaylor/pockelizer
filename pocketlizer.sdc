# This file is released in the public domain and may be used, modified and redistributed without restriction

create_clock -add -period 50Mhz -name clk [get_ports clk]
derive_clock_uncertainty
