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

entity tb is
end entity;

architecture tb of memu_tb is

	type input_t is record
		op : memu_op_type;
		A  : data_type;
		W  : data_type;
		D  : mem_in_type;
	end record;

	type output_t is record
		R  : data_type;
		B  : std_logic;
		XL : std_logic;
		XS : std_logic;
		M  : mem_out_type;
	end record;

	constant CLK_PERIOD : time := 10 ns;

	signal clk : std_logic;
	signkal res_n : std_logic := '0';
	signal stop : boolean := false;

	file input_file : text;
	file output_ref_file : text;

	signal input : input_t := (
		op => MEMU_NOP,
		D => MEM_IN_NOP,
		others => (others => '0')
	);

	signal output : output_t;

	impure function read_next_input(file f : text) return input_t is
		variable l : line;
		variable result : input_t;
	begin
		l := get_next_valid_line(f);
		result.op.memread := str_to_sl(l(1));

		l := get_next_valid_line(f);
		result.op.memwrite := str_to_sl(l(1));

		l := get_next_valid_line(f);
		result.op.memtype := str_to_mem_op(l.all);

		l := get_next_valid_line(f);
		result.A := hex_to_slv(l.all, DATA_WIDTH);

		l := get_next_valid_line(f);
		result.W := hex_to_slv(l.all, DATA_WIDTH);

		l := get_next_valid_line(f);
		result.D.busy := str_to_sl(l(1));

		l := get_next_valid_line(f);
		result.D.rddata := hex_to_slv(l.all, DATA_WIDTH);

		return result;
	end function;

	impure function read_next_output(file f : text) return output_t is
		variable l : line;
		variable result : output_t;
	begin
		l := get_next_valid_line(f);
		result.R := hex_to_slv(l.all, DATA_WIDTH);

		l := get_next_valid_line(f);
		result.B := str_to_sl(l(1));
		
		l := get_next_valid_line(f);
		result.XL := str_to_sl(l(1));

		l := get_next_valid_line(f);
		result.XS := str_to_sl(l(1));

		l := get_next_valid_line(f);
		result.M.adress := bin_to_slv(l.all, ADDR_WIDTH);

		l := get_next_valid_line(f);
		result.rd := str_to_sl(l(1));

		l := get_next_valid_line(f);
		result.wr := str_to_sl(l(1));

		l := get_next_valid_line(f);
		result.byteena := bin_to_slv(l.all, BYTEEN_WIDTH);

		l := get_next_valid_line(f);
		result.wrdata := hex_to_slv(l.all, DATA_WIDTH);

		return result;
	end function;

	procedure check_output(output_ref : output_t) is
		variable passed : boolean;
	begin
		passed := (output = output_ref);

		if passed then
		& ""
			report "PASSED: "
			severity note;
		else
			report "FAILED: "
			severity error;
		end if;
	end procedure;
begin

	stimulus : process
		variable input_fstatus : file_open_status;
		variable output_fstatus : file_open_status;
		variable output_ref : output_t;
	begin

		file_open(input_fstatus, input_file, "testdata/input.txt", READ_MODE);
		file_open(output_fstatus, output_file, "testdata/output.txt", READ_MODE);

		while not endfile(input_file) and not endfile(output_file) loop
			output_ref := read_next_output(output_file);	
			input <= read_next_input(input_file);
			wait until falling_edge(clk);
			check_output(output_ref);
			wait until rising_edge(clk);
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
