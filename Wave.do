add wave -noupdate -radix unsigned /tb/dut/flush
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {51810 ps} 0} {{addi x1} {21000 ps} 0} {{addi x2} {31000 ps} 0} {{add x3 EX-EX} {41000 ps} 0} {{add x3 MEM-EX} {51000 ps} 0} {{sw x3} {61000 ps} 0} {{lw x4} {81000 ps} 0} {{add x5} {111000 ps} 0} {bne {141000 ps} 0} {{addi x6} {161000 ps} 0} {{add x7} {171000 ps} 0}
quietly wave cursor active 11
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
WaveRestoreZoom {0 ps} {274050 ps}
