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

entity alu_tb is
end entity;

architecture tb of alu_tb is

	type input_t is record
		op : alu_op_type;
		A  : data_type;
		B  : data_type;
	end record;

	type output_t is record
		R : data_type;
		Z : std_logic;
	end record;

	file input_file : text;
	file output_file : text;

	signal input : input_t := (
		ALU_NOP,
		(others => '0'),
		(others => '0')
	);

	signal output : output_t := (
		(others => '0'),
		'0'
	);

	impure function read_next_input(file f : text) return input_t is
		variable l : line;
		variable result : input_t;
	begin
		l := get_next_valid_line(f);
		result.op := str_to_alu_op(l.all);

		l := get_next_valid_line(f);
		result.A := bin_to_slv(l.all, DATA_WIDTH); 

		l := get_next_valid_line(f);
		result.B := bin_to_slv(l.all, DATA_WIDTH); 

		return result;
	end function;

	impure function read_next_output(file f : text) return output_t is
		variable l : line;
		variable result : output_t;
	begin
		l := get_next_valid_line(f);
		result.Z := str_to_sl(l(1));

		l := get_next_valid_line(f);
		result.R := bin_to_slv(l.all, DATA_WIDTH);

		return result;
	end function;

	procedure check_output(output_ref : output_t) is
		variable passed : boolean;
	begin
		passed := (output = output_ref);

		if passed then
			report "PASSED: "
			& "op = " & to_string(input.op)
			& " A = "  & to_string(input.A)
			& " B = "  & to_string(input.B) & lf
			severity note;
		else
			report "FAILED: "
			& " op = " & to_string(input.op)
			& " A = "  & to_string(input.A)
			& " B = "  & to_string(input.B) & lf
			& "**    expected: Z = " & to_string(output_ref.Z)
			& " R = " & to_string(output_ref.R) & lf
			& "**    actual  : Z = " & to_string(output.Z)
			& " R = " & to_string(output.R) &lf
			severity error;
		end if;
	end procedure;

begin

	alu_inst : entity work.alu
	port map(
		op => input.op,
		A => input.A,
		B => input.B,
		R => output.R,
		Z => output.Z
	);

	stimulus : process
		variable fstatus : file_open_status;
		variable output_ref : output_t;
	begin
		
		file_open(fstatus, input_file, "testdata/input.txt", READ_MODE);
		file_open(fstatus, output_file, "testdata/output.txt", READ_MODE);

		while not endfile(input_file) loop
			output_ref := read_next_output(output_file);	
			input <= read_next_input(input_file);
			wait for 1 ns;
			check_output(output_ref);
		end loop;

		wait;
	end process;
end architecture;





















