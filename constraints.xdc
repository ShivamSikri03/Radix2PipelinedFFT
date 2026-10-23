# Primary System Clock: 250 MHz (4.0 ns period)
create_clock -period 4.000 -name clk -waveform {0.000 2.000} [get_ports clk]

# Set I/O Delays
set_input_delay -clock clk -max 1.000 [get_ports {in_valid x*_re* x*_im*}]
set_input_delay -clock clk -min 0.200 [get_ports {in_valid x*_re* x*_im*}]

set_output_delay -clock clk -max 1.000 [get_ports {out_valid X*_re* X*_im*}]
set_output_delay -clock clk -min 0.200 [get_ports {out_valid X*_re* X*_im*}]
