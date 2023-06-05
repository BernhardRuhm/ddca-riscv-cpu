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

entity mem_tb is
end entity;

architecture tb of mem_tb is

	type input_t is
		record
			stall		: std_logic;
			flush		: std_logic;
			mem_op		: mem_op_type;
			wbop		: wb_op_type;
			pc_new		: pc_type;
			pc_old		: pc_type;
			aluresult	: data_type;
			wrdata		: data_type;
			zero		: std_logic;
			mem_in		: mem_in_type;
		end record;
	
		type output_t is
		record
			pcsrc 		: std_logic;
			wbop		: wb_op_type;
			pc_new		: pc_type;
			pc_old		: pc_type;
			memresult 	: data_type;
			aluresult	: data_type;
			mem_out		: mem_out_type;
			exc_load 	: std_logic;
			exc_store 	: std_logic;
		end record;

	constant CLK_PERIOD : time := 10 ns;

	signal clk : std_logic;
	signal res_n : std_logic := '0';
	signal stop : boolean := false;

	file input_file : text;
	file output_file : text;

	signal input  : input_t := (
		stall 	=> '0',
		flush 	=> '0',
		mem_op 	=> MEM_NOP,
		wbop	=> WB_NOP,
		pc_new	=> ZERO_PC,
		pc_old	=> ZERO_PC,
		zero	=> '0',
		mem_in	=> MEM_IN_NOP,
		others => (others => '0')
	);

	signal output : output_t;

	impure function read_next_input(file f : text) return input_t is
		variable l : line;
		variable result : input_t;
	begin
		result.mem_in := MEM_IN_NOP;
		result.wbop := WB_NOP;

		l := get_next_valid_line(f);
		result.stall := str_to_sl(l(1));

		l := get_next_valid_line(f);
		result.flush := str_to_sl(l(1));

		l := get_next_valid_line(f);
		result.mem_op.branch := str_to_branch(l.all);

		l := get_next_valid_line(f);
		result.mem_op.mem.memread := str_to_sl(l(1));

		l := get_next_valid_line(f);
		result.mem_op.mem.memwrite := str_to_sl(l(1));

		l := get_next_valid_line(f);
		result.mem_op.mem.memtype := str_to_mem_op(l.all);

		l := get_next_valid_line(f);
		result.wbop.src := str_to_wbs_op(l.all);

		l := get_next_valid_line(f);
		result.pc_new := hex_to_slv(l.all, PC_WIDTH);

		l := get_next_valid_line(f);
		result.pc_old := hex_to_slv(l.all, PC_WIDTH);

		l := get_next_valid_line(f);
		result.aluresult := hex_to_slv(l.all, DATA_WIDTH);

		l := get_next_valid_line(f);
		result.wrdata := hex_to_slv(l.all, DATA_WIDTH);

		l := get_next_valid_line(f);
		result.zero := str_to_sl(l(1));

		l := get_next_valid_line(f);
		result.mem_in.rddata := hex_to_slv(l.all, DATA_WIDTH);
		
		return result;
	end function;

	impure function read_next_output(file f : text) return output_t is
		variable l : line;
		variable result : output_t;
	begin

		if input.flush = '1' then
			result.wbop := WB_NOP;
			result.pc_new := ZERO_PC;
			result.pc_old := ZERO_PC;
			result.aluresult := (others => '0');
			result.mem_out.address := (others => '0');
		else
			result.wbop := input.wbop;
			result.pc_new := input.pc_new;
			result.pc_old := input.pc_old;
			result.aluresult := input.aluresult;
			result.mem_out.address := input.aluresult(15 downto 2);
		end if ;

		l := get_next_valid_line(f);
		result.pcsrc := str_to_sl(l(1));

		l := get_next_valid_line(f);
		result.memresult := hex_to_slv(l.all, DATA_WIDTH);

		l := get_next_valid_line(f);
		result.mem_out.rd := str_to_sl(l(1));

		l := get_next_valid_line(f);
		result.mem_out.wr := str_to_sl(l(1));

		l := get_next_valid_line(f);
		result.mem_out.byteena := bin_to_slv(l.all, BYTEEN_WIDTH);

		l := get_next_valid_line(f);
		result.mem_out.wrdata := hex_to_slv(l.all, DATA_WIDTH);

		l := get_next_valid_line(f);
		result.exc_load := str_to_sl(l(1));

		l := get_next_valid_line(f);
		result.exc_store := str_to_sl(l(1));

		return result;
	end function;

	procedure check_output(output_ref : output_t) is
		variable passed : boolean;
	begin
		passed := (output = output_ref);

		if passed then
			report " PASSED: "
			& " stall="					& to_string(input.stall)
			& " flush="					& to_string(input.flush)
			& " mem_op.branch=" 		& to_string(input.mem_op.branch)
			& " mem_op.mem.rd="			& to_string(input.mem_op.mem.memread)
			& " mem_op.mem.wr="			& to_string(input.mem_op.mem.memwrite)
			& " mem_op.mem.memtype=" 	& to_string(input.mem_op.mem.memtype)
			& " wbop.src="				& to_string(input.wbop.src)
			& " pc_new="				& to_hstring(input.pc_new)
			& " pc_old="				& to_hstring(input.pc_old)
			& " aluresult="   			& to_hstring(input.aluresult)
			& " wrdata="   				& to_hstring(input.wrdata)
			& " zero=" 					& to_string(input.zero) 
			& " mem_in.rddata="			& to_hstring(input.mem_in.rddata) 
			& lf
			severity note;
		else
			report "FAILED: "
			& " stall="					& to_string(input.stall)
			& " flush="					& to_string(input.flush)
			& " mem_op.branch=" 		& to_string(input.mem_op.branch)
			& " mem_op.mem.rd="			& to_string(input.mem_op.mem.memread)
			& " mem_op.mem.wr="			& to_string(input.mem_op.mem.memwrite)
			& " mem_op.mem.memtype=" 	& to_string(input.mem_op.mem.memtype)
			& " wbop.src="				& to_string(input.wbop.src)
			& " pc_new="				& to_hstring(input.pc_new)
			& " pc_old="				& to_hstring(input.pc_old)
			& " aluresult="   			& to_hstring(input.aluresult)
			& " wrdata="   				& to_hstring(input.wrdata)
			& " zero=" 					& to_string(input.zero) 
			& " mem_in.rddata="			& to_hstring(input.mem_in.rddata) 
			& lf


			-- EXPECTED
			& "** expected : "
            & "pcsrc= "      		& to_string(output_ref.pcsrc)
            & "memresult= "    		& to_hstring(output_ref.memresult) 
            -- pc_out
            & "pc_old_out= "         & to_hstring(output_ref.pc_old)
            & "pc_new_out= "         & to_hstring(output_ref.pc_new)

            -- aluresult
            & "aluresult= "          & to_hstring(output_ref.aluresult)

            -- wbop_out
            & "wbop_out.rd= "        & to_string(output_ref.wbop.rd)
            & "wbop_out.write= "     & to_string(output_ref.wbop.write)
            & "wbop_out.src= "       & to_string(output_ref.wbop.src)

			-- mem_out
			& "mem_out.address= "	& to_string(output_ref.mem_out.address)
			& "mem_out.rd= "    		& to_string(output_ref.mem_out.rd) 
			& "mem_out.wr= "    		& to_string(output_ref.mem_out.wr)
			& "mem_out.byteena= "    & to_string(output_ref.mem_out.byteena)
			& "mem_out.wrdata= "    	& to_hstring(output_ref.mem_out.wrdata)

			-- exc
			& "exc_load= "       	& to_string(output_ref.exc_load)
			& "exc_store= "       	& to_string(output_ref.exc_store)
			& lf
			-- ACTUAL
			& "**   actual : "
            & "pcsrc= "      		& to_string(output.pcsrc)
            & "memresult= "    		& to_hstring(output.memresult)
            -- pc_out
            & "pc_old_out= "         & to_hstring(output.pc_old)
            & "pc_new_out= "         & to_hstring(output.pc_new)
            -- aluresult
            & "aluresult= "          & to_hstring(output.aluresult)
            -- wbop_out
            & "wbop_out.rd= "        & to_string(output.wbop.rd)
            & "wbop_out.write= "     & to_string(output.wbop.write)
            & "wbop_out.src= "       & to_string(output.wbop.src)
			-- mem_out
			& "mem_out.address= "	& to_string(output.mem_out.address)
			& "mem_out.rd= "    		& to_string(output.mem_out.rd)
			& "mem_out.wr= "    		& to_string(output.mem_out.wr)
			& "mem_out.byteena= "    & to_string(output.mem_out.byteena)
			& "mem_out.wrdata= "    	& to_hstring(output.mem_out.wrdata)
			-- exc
			& "exc_load= "       	& to_string(output.exc_load)
			& "exc_store= "       	& to_string(output.exc_store)
			& lf

			severity error;
		end if;
	end procedure;
begin
	
	mem_inst : entity work.mem
	port map(
		clk 	 => clk,
		res_n 	 => res_n,
		stall 	 => input.stall,
		flush 	 => input.flush,

		mem_busy => open,
		mem_op 	 => input.mem_op,

		wbop_in  => input.wbop,
		pc_new_in => input.pc_new,
		pc_old_in => input.pc_old,
		aluresult_in => input.aluresult,
		wrdata => input.wrdata,
		zero => input.zero,

		reg_write => open,

		pc_new_out => output.pc_new,
		pcsrc 	 => output.pcsrc,

		wbop_out => output.wbop,
		pc_old_out => output.pc_old,
		aluresult_out => output.aluresult,
		memresult => output.memresult,

		mem_out  => output.mem_out,
		mem_in 	 => input.mem_in,

		exc_load => output.exc_load,
		exc_store => output.exc_store
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
