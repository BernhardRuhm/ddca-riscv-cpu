vlib work
vmap work work

vcom -work work -2008 ../../vhdl/mem_pkg.vhd
vcom -work work -2008 ../../vhdl/cache/cache_pkg.vhd
vcom -work work -2008 ../../vhdl/core_pkg.vhd
vcom -work work -2008 ../../vhdl/op_pkg.vhd
vcom -work work -2008 ../../vhdl/cache/ram/single_clock_rw_ram_pkg.vhd
vcom -work work -2008 ../../vhdl/cache/ram/single_clock_rw_ram.vhd
vcom -work work -2008 ../../vhdl/cache/data_st_1w.vhd
vcom -work work -2008 ../../vhdl/cache/data_st.vhd
vcom -work work -2008 ../../vhdl/cache/mgmt_st_1w.vhd
vcom -work work -2008 ../../vhdl/cache/mgmt_st.vhd
vcom -work work -2008 ../../vhdl/cache/cache.vhd

# compile testbench ad utility package
vcom -work work -2008 ../tb_util_pkg.vhd
vcom -work work -2008 tb/cache_tb.vhd
