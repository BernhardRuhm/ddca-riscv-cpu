#!/bin/bash

dirs_with_no_vhdl_files="
.
miriv
"

dirs_that_must_exist="
miriv/sim
miriv/quartus
miriv/vhdl
miriv/vhdl/cache
miriv/test
miriv/software
miriv/software/c
miriv/software/asm
"

if [ "$(echo $1)" == "ex2" ]; then
modules_with_makefiles="$modules_with_makefiles vbs_graphics_controller" 
ipcores="$ipcores vbs_graphics_controller gfx_util"
fi;

error_counter=0
warning_counter=0

if [ ! -d miriv ]; then 
	echo "Error: miriv directory missing"; 
	let "error_counter++"
fi;

for i in $dirs_with_no_vhdl_files; do 
	for f in $i/*.vhd; do 
		if [ -e "$f" ]; then
			echo "Error: [$f] -- The folder [$i] MUST NOT contain VHDL files."; 
			let "error_counter++"
		fi;
		break;
	done;
done;

for d in $dirs_that_must_exist; do 
	if [ ! -d "$d" ]; then
		echo "Error: The folder [$d] does not exist."; 
		let "error_counter++"
	fi;
done;


python - $(ls miriv/vhdl) << EOF
import sys
expected = set('''alu.vhd
cache
core_pkg.vhd
core.vhd
ctrl.vhd
decode.vhd
exec.vhd
fetch.vhd
fwd.vhd
mem_pkg.vhd
memu.vhd
mem.vhd
op_pkg.vhd
pipeline.vhd
regfile.vhd
wb.vhd'''.split())

actual = set(sys.argv[1:])

if (expected != actual):
	for x in (expected-actual):
		print("Error: File [" + str(x) + "] is missing in the miriv/vhdl directory")

	for x in (actual-expected):
		print("Error: Superfluous file [" + str(x) + "] found in the miriv/vhdl directory! Don't add any new files!")
	
	exit(1)
EOF

if [ $? -ne 0 ]
then
	let "error_counter++"
fi

exit $error_counter

