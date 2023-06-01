library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;


library std; 
use std.textio.all;

use work.mem_pkg.all;
use work.core_pkg.all;
use work.op_pkg.all;
use work.tb_util_pkg.all;

entity decode_tb is
end entity;

architecture tb of decode_tb is

	type input_t is record
		stall 	  : std_logic;
		flush 	  : std_logic;
		pc_in 	  : pc_type;
		instr 	  : instr_type;
		reg_write : reg_write_type;
	end record;

	type output_t is record
		pc_out 	: pc_type;
		exec_op : exec_op_type;
		mem_op 	: mem_op_type;
		wb_ob 	: wb_ob_type;
		exc_dec : std_logic;
	end record;

	constant CLK_PERIOD : time := 10 ns;

	signal clk : std_logic;
	signal res_n : std_logic := '0';
	signal stop : boolean := false;

	file input_file : text;
	file output_file : text;

	signal input : input_t := (
		instr <= NOP_INSTR,
		others => '0'
	);

	signal output : output_t;
	

	impure function read_next_input(file f : text) return input_t is
		variable l : line;
		variable result : input_t;
	begin
		l := get_next_valid_line(f);
		result.stall := str_to_sl(l(1));

		l := get_next_valid_line(f);
		result.flush := str_to_sl(l(1));
		
		l := get_next_valid_line(f);
		result.pc_in := hex_to_slv(l.all, PC_WIDTH);

		l := get_next_valid_line(f);
		result.instr := hex_to_slv(l.all, INSTR_WIDTH);

		l := get_next_valid_line(f);
		result.reg_write.write := str_to_slv(l(1));

		l := get_next_valid_line(f);
		result.reg_write.reg := hex_to_slv(l.all, REG_COUNT);	

		l := get_next_valid_line(f);
		result.reg_write.data := hex_to_slv(l.all, DATA_WIDTH);

		return result;
	end function;

	impure function read_next_output(file f : text) return output_t is
		variable l : line;
		variable result : output_t;
	begin

		l := get_next_valid_line(f);
		result.pc_out := hex_to_slv(l.all, PC_WIDTH);

		l := get_next_valid_line(f);
		result.exec_op.aluop := str_to_alupo(l.all);

		l := get_next_valid_line(f);
		result.exec_op.alusrc1 := str_to_bin(l(1));

		l := get_next_valid_line(f);
		result.exec_op.alusrc2 := str_to_bin(l(1));

		l := get_next_valid_line(f);
		result.exec_op.alusrc3 := str_to_bin(l(1));

		l := get_next_valid_line(f);
		result.exec_op.rs1 := hex_to_slv(l.all, REG_COUNT);

		l := get_next_valid_line(f);
		result.exec_op.rs2 := hex_to_slv(l.all, REG_COUNT);

		l := get_next_valid_line(f);
		result.exec_op.readdata1 := hex_to_slv(l.all, DATA_WIDTH);

		l := get_next_valid_line(f);
		result.exec_op.readdata2 := hex_to_slv(l.all, DATA_WIDTH);

		l := get_next_valid_line(f);
		result.exec_op.imm := hex_to_slv(l.all, DATA_WIDTH);

		l := get_next_valid_line(f);
		l := get_next_valid_line(f);
		l := get_next_valid_line(f);
		l := get_next_valid_line(f);


		return result;
	end function;

	procedure check_output(output_ref : output_t) is
		variable passed : boolean;
	begin
		passed := (output = output_ref);

		if passed then
			report "PASSED: "
			& lf
			severity note;
		else
			report "FAILED: "
			& lf
			& "** expected : "
			& lf 
			& "** actual   : "
			& lf
			severity error;
		end if;
	end procedure;
begin
	
	decode_inst : entity work.fetch
	port map(
	);

	stimulus : process
		variable input_fstatus : file_open_status;
		variable output_fstatus : file_open_status;
		variable output_ref : output_t;
	begin
		
		res_n <= '0';
		wait until rising_edge(clk);
		res_n <= '1';

		file_open(input_fstatus, input_file, "testdata/input.txt", READ_MODE);
		file_open(output_fstatus, output_file, "testdata/output.txt", READ_MODE);

		while not endfile(input_file) and not endfile(output_file) loop
			input <= read_next_input(input_file);
			wait until falling_edge(clk);
			output_ref := read_next_output(output_file);	
			check_output(output_ref);
		end loop;

		stop <= true;
		wait;
	end process;


	generate_clk : process
	begin
		clk_generate(clk, CLK_PERIOD, stop);
		wait;
	end process;

end architecture;
