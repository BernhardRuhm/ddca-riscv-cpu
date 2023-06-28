onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /fetch_tb/clk
add wave -noupdate /fetch_tb/res_n
add wave -noupdate /fetch_tb/stop
add wave -noupdate -expand /fetch_tb/input
add wave -noupdate -subitemconfig {/fetch_tb/output.mem_out -expand} /fetch_tb/output
add wave -noupdate /fetch_tb/CLK_PERIOD
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {24979 ps} 0}
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
WaveRestoreZoom {0 ps} {73500 ps}
