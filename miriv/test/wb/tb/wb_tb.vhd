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

entity wb_tb is
end entity;

architecture tb of wb_tb is

	type input_t is record
		stall		: std_logic;
		flush		: std_logic;
		op			: wb_op_type;
		pc_old		: pc_type;
		aluresult	: data_type;
		memresult	: data_type;
	end record;

	type output_t is record
		reg_write	: reg_write_type;
	end record;

	constant CLK_PERIOD : time := 10 ns;

	signal clk : std_logic;
	signal res_n : std_logic := '0';
	signal stop : boolean := false;

	file input_file : text;
	file output_file : text;

	signal input : input_t := (
		stall => '0',
		flush => '0',
		op	=> WB_NOP,
		pc_old	=> ZERO_PC,
		others => (others => '0')
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
		result.op.rd := bin_to_slv(l.all, REG_BITS);

		l := get_next_valid_line(f);
		result.op.write := str_to_sl(l(1));

		l := get_next_valid_line(f);
		result.op.src := str_to_wbs_op(l.all);

		l := get_next_valid_line(f);
		result.aluresult := hex_to_slv(l.all, DATA_WIDTH);

		l := get_next_valid_line(f);
		result.memresult := hex_to_slv(l.all, DATA_WIDTH);

		l := get_next_valid_line(f);
		result.pc_old := hex_to_slv(l.all, PC_WIDTH);

		return result;
	end function;

	impure function read_next_output(file f : text) return output_t is
		variable l : line;
		variable result : output_t;
	begin

		l := get_next_valid_line(f);
		result.reg_write.write := str_to_sl(l(1));

		l := get_next_valid_line(f);
		result.reg_write.reg := bin_to_slv(l.all, REG_BITS);

		l := get_next_valid_line(f);
		result.reg_write.data := hex_to_slv(l.all, DATA_WIDTH);

		return result;
	end function;

	procedure check_output(output_ref : output_t) is
		variable passed : boolean;
	begin
		passed := (output = output_ref);

		if passed then
			report "PASSED: "
			& " stall="					& to_string(input.stall)
			& " flush="					& to_string(input.flush)
			& " op.rd=" 				& to_string(input.op.rd)
			& " op.write="				& to_string(input.op.write)
			& " op.src="				& to_string(input.op.src)
			& " aluresult="   			& to_hstring(input.aluresult)
			& " memresult="   			& to_hstring(input.memresult)
			& " pc_old_in=" 			& to_hstring(input.pc_old) 
			& lf
			severity note;
		else
		report "FAILED: "
		& " stall="					& to_string(input.stall)
		& " flush="					& to_string(input.flush)
		& " op.rd=" 				& to_string(input.op.rd)
		& " op.write="				& to_string(input.op.write)
		& " op.src="				& to_string(input.op.src)
		& " aluresult="   			& to_hstring(input.aluresult)
		& " memresult="   			& to_hstring(input.memresult)
		& " pc_old_in=" 			& to_hstring(input.pc_old) 
		& lf
		& "** expected: reg_write.write=" 	& to_string(output_ref.reg_write.write) 
		& " reg_write.reg=" 		& to_string(output_ref.reg_write.reg) 
		& " reg_write.data=" 		& to_hstring(output_ref.reg_write.data) 
		& lf 
		& "** actual: reg_write.write="		& to_string(output.reg_write.write) 
		& " reg_write.reg=" 		& to_string(output.reg_write.reg)
		& " reg_write.data=" 		& to_hstring(output.reg_write.data) 
		& lf 

		severity error;
		end if;
	end procedure;
begin
	
	wb_inst : entity work.wb
	port map (
		clk			=> clk,
		res_n		=> res_n,
		stall		=> input.stall,
		flush 		=> input.flush,

		op			=> input.op,
		aluresult	=> input.aluresult,
		memresult	=> input.memresult,
		pc_old_in	=> input.pc_old,

		reg_write	=> output.reg_write
	);

	stimulus : process
		variable input_fstatus : file_open_status;
		variable output_fstatus : file_open_status;
		variable output_ref : output_t;
	begin
		
		res_n <= '0';
		wait until rising_edge(clk);
		res_n <= '1';
		wait until falling_edge(clk);

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
