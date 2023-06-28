onerror {resume}
quietly virtual signal -install /cache_tb {/cache_tb/cpu_to_cache  } g
quietly WaveActivateNextPane {} 0
add wave -noupdate /cache_tb/clk
add wave -noupdate /cache_tb/res_n
add wave -noupdate -divider {mem signals}
add wave -noupdate -childformat {{/cache_tb/cpu_to_cache.byteena -radix binary}} -subitemconfig {/cache_tb/cpu_to_cache.byteena {-height 17 -radix binary}} /cache_tb/cpu_to_cache
add wave -noupdate -divider -height 30 <NULL>
add wave -noupdate /cache_tb/cache_to_cpu
add wave -noupdate -divider -height 30 <NULL>
add wave -noupdate /cache_tb/cache_to_mem
add wave -noupdate -divider -height 30 <NULL>
add wave -noupdate /cache_tb/mem_to_cache
add wave -noupdate -divider cache
add wave -noupdate /cache_tb/cache_inst/curr.state
add wave -noupdate -radix binary -childformat {{/cache_tb/cache_inst/index(2) -radix binary} {/cache_tb/cache_inst/index(1) -radix binary} {/cache_tb/cache_inst/index(0) -radix binary}} -subitemconfig {/cache_tb/cache_inst/index(2) {-height 17 -radix binary} /cache_tb/cache_inst/index(1) {-height 17 -radix binary} /cache_tb/cache_inst/index(0) {-height 17 -radix binary}} /cache_tb/cache_inst/index
add wave -noupdate -divider mgmt_st
add wave -noupdate /cache_tb/cache_inst/mgmt_wr
add wave -noupdate /cache_tb/cache_inst/mgmt_rd
add wave -noupdate /cache_tb/cache_inst/valid_in
add wave -noupdate /cache_tb/cache_inst/dirty_in
add wave -noupdate -radix binary /cache_tb/cache_inst/tag
add wave -noupdate /cache_tb/cache_inst/valid_out
add wave -noupdate /cache_tb/cache_inst/dirty_out
add wave -noupdate -radix binary /cache_tb/cache_inst/tag_out
add wave -noupdate /cache_tb/cache_inst/hit_out
add wave -noupdate -divider data_st
add wave -noupdate /cache_tb/cache_inst/data_we
add wave -noupdate /cache_tb/cache_inst/data_rd
add wave -noupdate /cache_tb/cache_inst/byteena
add wave -noupdate /cache_tb/cache_inst/data_in
add wave -noupdate /cache_tb/cache_inst/data_out
add wave -noupdate -divider ram
add wave -noupdate /cache_tb/cache_inst/data_st_inst/data_st_1w_inst/generate_ram(3)/single_clock_rw_ram_inst/ram
add wave -noupdate /cache_tb/cache_inst/data_st_inst/data_st_1w_inst/generate_ram(2)/single_clock_rw_ram_inst/ram
add wave -noupdate /cache_tb/cache_inst/data_st_inst/data_st_1w_inst/generate_ram(1)/single_clock_rw_ram_inst/ram
add wave -noupdate /cache_tb/cache_inst/data_st_inst/data_st_1w_inst/generate_ram(0)/single_clock_rw_ram_inst/ram
TreeUpdate [SetDefaultTree]
WaveRestoreCursors
quietly wave cursor active 0
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {262500 ps}
