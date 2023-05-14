
all:
	@echo "run either \"make submission_exercise3\" or \"make submission_exercise4\""

submission_exercise3: 
	@make -C report_exercise3 1>/dev/null
	@bash check_files.sh;\
	if [ $$? -eq 0 ]; then\
		echo "Creating archive ... ";\
		tar -cf submission.tar miriv;\
		cd report_exercise3 && tar --append --file=../submission.tar report.pdf && cd .. ;\
		gzip -f submission.tar;\
		if [ $$(wc -c < submission.tar.gz) -ge 5000000 ]; then\
			echo "The archive is too large! You did not clean your Quartus and/or Questa projects! TUWEL will reject it.";\
		fi;\
	else \
		echo "------------------------------------------------------";\
		echo "The check had errors --> no archive will be generated!";\
		echo "------------------------------------------------------";\
	fi;

submission_exercise4: 
	@make -C report_exercise4 1>/dev/null
	@bash check_files.sh;\
	if [ $$? -eq 0 ]; then\
		echo "Creating archive ... ";\
		tar -cf submission.tar miriv;\
		cd report_exercise4 && tar --append --file=../submission.tar report.pdf && cd .. ;\
		gzip -f submission.tar;\
		if [ $$(wc -c < submission.tar.gz) -ge 5000000 ]; then\
			echo "The archive is too large! You did not clean your Quartus and/or Questa projects! TUWEL will reject it.";\
		fi;\
	else\
		echo "------------------------------------------------------";\
		echo "The check had errors --> no archive will be generated!";\
		echo "------------------------------------------------------";\
	fi;


clean:
	rm -fr *.tar.gz
	

.PHONY: clean
.PHONY: submission_exercise3
.PHONY: submission_exercise4


