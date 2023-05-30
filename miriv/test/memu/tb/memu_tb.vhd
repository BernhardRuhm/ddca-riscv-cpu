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

entity memu_tb is
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
	signal res_n : std_logic := '0';
	signal stop : boolean := false;

	file input_file : text;
	file output_file : text;

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
		result.M.address := bin_to_slv(l.all, ADDR_WIDTH);

		l := get_next_valid_line(f);
		result.M.rd := str_to_sl(l(1));

		l := get_next_valid_line(f);
		result.M.wr := str_to_sl(l(1));

		l := get_next_valid_line(f);
		result.M.byteena := bin_to_slv(l.all, BYTEEN_WIDTH);

		l := get_next_valid_line(f);
		result.M.wrdata := hex_to_slv(l.all, DATA_WIDTH);

		return result;
	end function;

	procedure check_output(output_ref : output_t) is
		variable passed : boolean;
	begin
		passed := (output = output_ref);

		if passed then
			report "PASSED: "
		& " op.memread = " & to_string(input.op.memread)
		& " op.memwrite = " & to_string(input.op.memwrite)
		& " op.memtype = " & to_string(input.op.memtype)
		& " A = " & to_hstring(input.A)
		& " W = " & to_hstring(input.W)
		& " D.busy = " & to_string(input.D.busy)
		& " D.rddata = " & to_hstring(input.D.rddata)
		& lf
			severity note;
		else
			report "FAILED: "
		& " op.memread = " & to_string(input.op.memread)
		& " op.memwrite = " & to_string(input.op.memwrite)
		& " op.memtype = " & to_string(input.op.memtype)
		& " A = " & to_hstring(input.A)
		& " W = " & to_hstring(input.W)
		& " D.busy = " & to_string(input.D.busy)
		& " D.rddata = " & to_hstring(input.D.rddata)
		& lf
		& "** expected: R = " & to_hstring(output_ref.R)
		& " B = " & to_string(output_ref.B)
		& " XL = " & to_string(output_ref.XL)
		& " XS = " & to_string(output_ref.XS)
		& " M.adress = " & to_hstring(output_ref.M.address)
		& " M.rd = " & to_string(output_ref.M.rd)
		& " M.wr = " & to_string(output_ref.M.wr)
		& " M.byteena = " & to_string(output_ref.M.byteena)
		& " M.wrdata = " & to_hstring(output_ref.M.wrdata)
		& lf
		& "** actual:   R = " & to_hstring(output.R)
		& " B = " & to_string(output.B)
		& " XL = " & to_string(output.XL)
		& " XS = " & to_string(output.XS)
		& " M.adress = " & to_hstring(output.M.address)
		& " M.rd = " & to_string(output.M.rd)
		& " M.wr = " & to_string(output.M.wr)
		& " M.byteena = " & to_string(output.M.byteena)
		& " M.wrdata = " & to_hstring(output.M.wrdata)
		& lf
			severity error;
		end if;
	end procedure;

begin

	memu_inst : entity work.memu
	port map(
		op => input.op,
		A  => input.A,
		W  => input.W,
		R  => output.R, 
		B  => output.B, 
		XL => output.XL, 
		XS => output.XS,
		D  => input.D, 
		M  => output.M
	);

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
