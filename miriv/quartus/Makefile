#NANO_BOARD=TRUE

ifeq ($(NANO_BOARD),TRUE)
	PROJECT_NAME=miriv_de0-nano
else
	PROJECT_NAME=miriv
endif

LOG_FILE=BUILD_$(shell date '+%d.%m.%y-%H_%M_%S').log
PROJECT_DIR=$(shell pwd)

SOF_FILE=output_files/$(PROJECT_NAME).sof
QXP_FILE=output_files/$(PROJECT_NAME).qxp

SOURCEFILES=$(shell grep VHDL_FILE $(PROJECT_NAME).qsf | grep -v "^\#" | sed 's/.*VHDL_FILE//g')

RPA_SHELL=../../../rpa_tools/rpa_shell.py

all: $(SOF_FILE)
pack: $(QXP_FILE)

# starts the quartus GUI and loads the quartus project
quartus_gui:
	quartus --64bit $(PROJECT_NAME).qpf &

$(SOF_FILE): $(PROJECT_NAME).qsf $(PROJECT_NAME).qpf $(SOURCEFILES)
	@echo ""
	@echo "---------------------------------------------" >> $(LOG_FILE)
	@echo "-                  QUARTUS                  -" >> $(LOG_FILE)
	@echo "---------------------------------------------" >> $(LOG_FILE)
	quartus_sh --flow compile $(PROJECT_NAME) 2>&1 | tee -a $(LOG_FILE)
	$(PROJECT_DIR)/check-warnings.sh $(LOG_FILE)

$(QXP_FILE): $(SOF_FILE)
	quartus_cdb temp -c $(PROJECT_NAME) --incremental_compilation_export=$(QXP_FILE) --incremental_compilation_export_partition_name=Top --incremental_compilation_export_post_synth=on --incremental_compilation_export_post_fit=off --incremental_compilation_export_routing=on --incremental_compilation_export_flatten=on


download:
	quartus_pgm -m jtag -o"p;$(SOF_FILE)"

run:
	quartus_stp -t bootloader.tcl $(DMEM) $(IMEM)

minicom:
	minicom -D /dev/ttyUSB0 -o -b 115200

run_helloworld:
	make -C ../software/c/
	make run IMEM=../software/c/helloworld.imem.mif DMEM=../software/c/helloworld.dmem.mif

ifneq ($(NANO_BOARD),TRUE)
remote_download:
	$(RPA_SHELL) -p $(SOF_FILE) -n

remote_run:
	$(RPA_SHELL) --scp $(DMEM) .rpa_shell/dmem
	$(RPA_SHELL) --scp $(IMEM) .rpa_shell/imem
	$(RPA_SHELL) --scp bootloader.tcl .rpa_shell
	$(RPA_SHELL) "quartus_stp -t .rpa_shell/bootloader.tcl .rpa_shell/dmem .rpa_shell/imem"

remote_minicom:
	$(RPA_SHELL) "minicom -D /dev/ttyUSB0 -o -b 115200"

remote_run_helloworld:
	make -C ../software/c/
	make remote_run IMEM=../software/c/helloworld.imem.mif DMEM=../software/c/helloworld.dmem.mif
endif

clean:
	rm -f $(PROJECT_NAME).sopcinfo
	rm -f $(PROJECT_NAME).html
	rm -f $(PROJECT_NAME).cmp
	rm -f *.rpt
	rm -f *.qws
	rm -fr output_files
	rm -fr db
	rm -f *.bsf
	rm -f *.dpf
	rm -f *.srf
	rm -fr incremental_db
	rm -f *.jdi
	rm -f *.html
	rm -f *.smsg
	rm -f *.summary
	rm -f *.qdf
	rm -f *.qws
	rm -f *.qarlog

.PHONY: all quartus_gui download clean pack
