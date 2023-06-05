onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /wb_tb/clk
add wave -noupdate /wb_tb/res_n
add wave -noupdate -expand -subitemconfig {/wb_tb/input.op -expand} /wb_tb/input
add wave -noupdate -expand /wb_tb/output
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
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
WaveRestoreZoom {0 ps} {79766 ps}
