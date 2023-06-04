onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /decode_tb/clk
add wave -noupdate -expand /decode_tb/decode_inst/reg_write
add wave -noupdate /decode_tb/decode_inst/reg_file_inst/reg_access/reg_mem
add wave -noupdate /decode_tb/decode_inst/reg_file_inst/rdaddr1
add wave -noupdate /decode_tb/decode_inst/reg_file_inst/rddata1
add wave -noupdate /decode_tb/decode_inst/reg_file_inst/rdaddr2
add wave -noupdate /decode_tb/decode_inst/reg_file_inst/rddata2
add wave -noupdate /decode_tb/decode_inst/reg_file_inst/regwrite
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {12269 ps} 0}
quietly wave cursor active 1
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
WaveRestoreZoom {125 ps} {52625 ps}
