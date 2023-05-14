library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;

library std; -- for Printing
use std.textio.all;

use work.mem_pkg.all;
use work.op_pkg.all;
use work.core_pkg.all;
use work.tb_util_pkg.all;

entity tb is
end entity;

architecture bench of tb is
	constant CLK_PERIOD : time := 10 ns;

	signal clk : std_logic;
	signal res_n : std_logic := '0';
	signal stop : boolean := false;
	
	file input_file : text;
	file output_ref_file : text;

	subtype addr is std_logic_vector(REG_BITS-1 downto 0);
	subtype data is std_logic_vector(DATA_WIDTH-1 downto 0);

	type input_t is
	record
		stall     : std_logic;
		rdaddr1   : addr;
		rdaddr2   : addr;
		wraddr    : addr;
		wrdata    : data;
		regwrite  : std_logic;
	end record;

	type output_t is
	record
		rddata1 : data;
		rddata2 : data;
	end record;

	signal inp  : input_t := (
		'0',
		(others => '0'),
		(others => '0'),
		(others => '0'),
		(others => '0'),
		'0'
	);
	signal outp : output_t;

	impure function read_next_input(file f : text) return input_t is
		variable l : line;
		variable result : input_t;
	begin
		l := get_next_valid_line(f);
		result.stall := str_to_sl(l(1));

		l := get_next_valid_line(f);
		result.rdaddr1 := bin_to_slv(l.all, REG_BITS);

		l := get_next_valid_line(f);
		result.rdaddr2 := bin_to_slv(l.all, REG_BITS);

		l := get_next_valid_line(f);
		result.wraddr := bin_to_slv(l.all, REG_BITS);

		l := get_next_valid_line(f);
		result.wrdata := bin_to_slv(l.all, DATA_WIDTH);

		l := get_next_valid_line(f);
		result.regwrite := str_to_sl(l(1));

		return result;
	end function;

	impure function read_next_output(file f : text) return output_t is
		variable l : line;
		variable result : output_t;
	begin
		l := get_next_valid_line(f);
		result.rddata1 := bin_to_slv(l.all, DATA_WIDTH);

		l := get_next_valid_line(f);
		result.rddata2 := bin_to_slv(l.all, DATA_WIDTH);
		return result;
	end function;

	procedure check_output(output_ref : output_t) is
		variable passed : boolean;
	begin
		passed := (outp = output_ref);

		if passed then
			report " PASSED: "
			& "stall="     & to_string(inp.stall)
			& " rdaddr1="  & to_string(inp.rdaddr1)
			& " rdaddr2="  & to_string(inp.rdaddr2)
			& " wraddr="   & to_string(inp.wraddr)
			& " wrdata="   & to_string(inp.wrdata)
			& " regwrite=" & to_string(inp.regwrite) & lf
			severity note;
		else
			report "FAILED: "
			& "stall="     & to_string(inp.stall)
			& " rdaddr1="  & to_string(inp.rdaddr1)
			& " rdaddr2="  & to_string(inp.rdaddr2)
			& " wraddr="   & to_string(inp.wraddr)
			& " wrdata="   & to_string(inp.wrdata)
			& " regwrite=" & to_string(inp.regwrite) & lf
			& "**     expected: rddata1=" & to_string(output_ref.rddata1) & " rddata2=" & to_string(output_ref.rddata2) & lf
			& "**     actual:   rddata1=" & to_string(outp.rddata1)       & " rddata2=" & to_string(outp.rddata2) & lf
			severity error;
		end if;
	end procedure;

begin

	regfile_inst : entity work.regfile
	port map (
		clk       => clk,
		res_n     => res_n,
		stall     => inp.stall,
		rdaddr1   => inp.rdaddr1,
		rdaddr2   => inp.rdaddr2,
		rddata1   => outp.rddata1,
		rddata2   => outp.rddata2,
		wraddr    => inp.wraddr,
		wrdata    => inp.wrdata,
		regwrite  => inp.regwrite
	);

	stimulus : process
		variable fstatus: file_open_status;
	begin
		res_n <= '0';
		wait until rising_edge(clk);
		res_n <= '1';
		
		file_open(fstatus, input_file, "testdata/input.txt", READ_MODE);
		
		timeout(1, CLK_PERIOD);

		while not endfile(input_file) loop
			inp <= read_next_input(input_file);
			timeout(1, CLK_PERIOD);
		end loop;
		
		wait;
	end process;

	output_checker : process
		variable fstatus: file_open_status;
		variable output_ref : output_t;
	begin
		file_open(fstatus, output_ref_file, "testdata/output.txt", READ_MODE);

		wait until res_n = '1';
		timeout(1, CLK_PERIOD);

		while not endfile(output_ref_file) loop
			output_ref := read_next_output(output_ref_file);

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
