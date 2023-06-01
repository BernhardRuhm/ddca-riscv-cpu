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

entity fetch_tb is
end entity;

architecture tb of fetch_tb is

	type input_t is record
		stall 		: std_logic;
		flush 		: std_logic;
		pc_src 		: std_logic;
		pc_in 		: pc_type;
		mem_in 		: mem_in_type;
	end record;

	type output_t is record
		mem_busy 	: std_logic;
		pc_out 		: pc_type;
		instr 		: instr_type;
		mem_out 	: mem_out_type;
	end record;

	constant CLK_PERIOD : time := 10 ns;

	signal clk : std_logic;
	signal res_n : std_logic := '0';
	signal stop : boolean := false;

	file input_file : text;
	file output_file : text;

	signal input : input_t := (
		'0',
		'0',
		'0',
		16x"0",
		MEM_IN_NOP
	);

	signal output : output_t;

	impure function read_next_input(file f : text) return input_t is
		variable l : line;
		variable result : input_t;
	begin
		result.mem_in.busy := '0';

		l := get_next_valid_line(f);
		result.stall := str_to_sl(l(1));

		l := get_next_valid_line(f);
		result.flush := str_to_sl(l(1));
		
		l := get_next_valid_line(f);
		result.pc_src:= str_to_sl(l(1));

		l := get_next_valid_line(f);
		result.pc_in := hex_to_slv(l.all, PC_WIDTH);	

		l := get_next_valid_line(f);
		result.mem_in.rddata := hex_to_slv(l.all, DATA_WIDTH);
		return result;
	end function;

	impure function read_next_output(file f : text) return output_t is
		variable l : line;
		variable result : output_t;
	begin

		result.mem_out := MEM_OUT_NOP;
		result.mem_out.rd := '1';
		result.mem_busy := '0';

		l := get_next_valid_line(f);
		result.pc_out := hex_to_slv(l.all, PC_WIDTH);

		l := get_next_valid_line(f);
		result.instr := hex_to_slv(l.all, INSTR_WIDTH);

		l := get_next_valid_line(f);
		result.mem_out.address := bin_to_slv(l.all, ADDR_WIDTH);


		return result;
	end function;

	procedure check_output(output_ref : output_t) is
		variable passed : boolean;
	begin
		passed := (output = output_ref);

		if passed then
			report "PASSED: "
			& " stall = " 			& to_string(input.stall)
			& " flush = " 			& to_string(input.flush)
			& " pc_src = " 			& to_string(input.pc_src)
			& " pc_in = " 			& to_hstring(input.pc_in)
			& " mem_in.rddata = " 	& to_hstring(input.mem_in.rddata)
			& lf
			severity note;
		else
			report "FAILED: "
			& " stall = " 			& to_string(input.stall)
			& " flush = " 			& to_string(input.flush)
			& " pc_src = " 			& to_string(input.pc_src)
			& " pc_in = " 			& to_hstring(input.pc_in)
			& " mem_in.rddata = " 	& to_hstring(input.mem_in.rddata)
			& lf
			& "** expected : "
			& " pc_out = " 			& to_hstring(output_ref.pc_out) 
			& " instr = " 			& to_hstring(output_ref.instr) 	
			& " mem_out.address = " 	& to_string(output_ref.mem_out.address) 		
			& lf 
			& "** actual   : "
			& " pc_out = " 			& to_hstring(output.pc_out) 
			& " instr = " 			& to_hstring(output.instr) 	
			& " mem_out.address = " 	& to_string(output.mem_out.address) 		
			& lf
			severity error;
		end if;
	end procedure;
begin
	
	fetch_inst : entity work.fetch
	port map(
		clk 	 => clk,
		res_n 	 => res_n,
		stall 	 => input.stall,
		flush 	 => input.flush,
		mem_busy => output.mem_busy,
		pcsrc 	 => input.pc_src,
		pc_in  	 => input.pc_in,
		pc_out 	 => output.pc_out,
		instr 	 => output.instr,
		mem_out  => output.mem_out,
		mem_in 	 => input.mem_in
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
