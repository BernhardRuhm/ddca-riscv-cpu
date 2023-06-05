.PHONY: all clean compile sim sim_gui

all: compile

clean:
	rm -fr work
	rm -f transcript
	rm -f *.wlf
	rm -f modelsim.ini

compile:
	@vsim -c -do "do scripts/compile.do;quit -f"

sim:
	@vsim -c -t ps work.execute_tb -quiet -do "run -all;quit -f" | grep -E "\*\*|Errors"

sim_gui:
	@vsim -t ps -voptargs=+acc work.execute_tb -quiet -do "do scripts/wave.do;run -all;wave zoom full"
