vlib work
vmap work work

vcom -work work -2008 ../../vhdl/mem_pkg.vhd
vcom -work work -2008 ../../vhdl/core_pkg.vhd
vcom -work work -2008 ../../vhdl/op_pkg.vhd
vcom -work work -2008 ../../vhdl/regfile.vhd
vcom -work work -2008 ../../vhdl/decode.vhd

# compile testbench ad utility package
vcom -work work -2008 ../tb_util_pkg.vhd
vcom -work work -2008 tb/decode_tb.vhd
