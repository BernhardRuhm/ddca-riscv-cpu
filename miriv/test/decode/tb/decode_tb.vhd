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
		wb_op 	: wb_op_type;
		exc_dec : std_logic;
	end record;

	constant CLK_PERIOD : time := 10 ns;

	signal clk : std_logic;
	signal res_n : std_logic := '0';
	signal stop : boolean := false;
	signal finished_writing : boolean := false;

	file input_file : text;
	file output_file : text;

	signal input : input_t := (
		stall => '0',
		flush => '0',
		pc_in => ZERO_PC,
		instr => NOP_INST,
		reg_write => REG_WRITE_NOP 
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
		result.reg_write.write := str_to_sl(l(1));

		l := get_next_valid_line(f);
		result.reg_write.reg := bin_to_slv(l.all, REG_BITS);	

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
		result.exec_op.aluop := str_to_alu_op(l.all);

		l := get_next_valid_line(f);
		result.exec_op.alusrc1 := str_to_sl(l(1));

		l := get_next_valid_line(f);
		result.exec_op.alusrc2 := str_to_sl(l(1));

		l := get_next_valid_line(f);
		result.exec_op.alusrc3 := str_to_sl(l(1));

		l := get_next_valid_line(f);
		result.exec_op.rs1 := bin_to_slv(l.all, REG_BITS);

		l := get_next_valid_line(f);
		result.exec_op.rs2 := bin_to_slv(l.all, REG_BITS);

		l := get_next_valid_line(f);
		result.exec_op.readdata1 := hex_to_slv(l.all, DATA_WIDTH);

		l := get_next_valid_line(f);
		result.exec_op.readdata2 := hex_to_slv(l.all, DATA_WIDTH);

		l := get_next_valid_line(f);
		result.exec_op.imm := hex_to_slv(l.all, DATA_WIDTH);


		l := get_next_valid_line(f);
		result.mem_op.branch := str_to_branch(l.all);

		l := get_next_valid_line(f);
		result.mem_op.mem.memread := str_to_sl(l(1));

		l := get_next_valid_line(f);
		result.mem_op.mem.memwrite := str_to_sl(l(1));

		l := get_next_valid_line(f);
		result.mem_op.mem.memtype := str_to_mem_op(l.all);


		l := get_next_valid_line(f);
		result.wb_op.rd := bin_to_slv(l.all, REG_BITS);

		l := get_next_valid_line(f);
		result.wb_op.write := str_to_sl(l(1));

		l := get_next_valid_line(f);
		result.wb_op.src := str_to_wbs_op(l.all);


		l := get_next_valid_line(f);
		result.exc_dec:= str_to_sl(l(1));

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
			& " pc_in = " 			& to_string(input.pc_in)
			& " instr = " 			& to_hstring(input.instr)
			& " reg_write.write = " & to_string(input.reg_write.write)
			& " reg_write.reg = " 	& to_string(input.reg_write.reg)
			& " reg_write.data = "  & to_hstring(input.reg_write.data)
			& lf
			severity note;
		else
			report "FAILED: "
			& " stall = " 			& to_string(input.stall)
			& " flush = " 			& to_string(input.flush)
			& " pc_in = " 			& to_string(input.pc_in)
			& " instr = " 			& to_hstring(input.instr)
			& " reg_write.write = " & to_string(input.reg_write.write)
			& " reg_write.reg = " 	& to_string(input.reg_write.reg)
			& " reg_write.data = "  & to_hstring(input.reg_write.data)
			& lf
			& "** expected : "
			& " pc_out = " 				& to_hstring(output_ref.pc_out)
			& " exec_op.aluop = " 		& to_string(output_ref.exec_op.aluop)
			& " exec_op.alusrc1 = " 	& to_string(output_ref.exec_op.alusrc1)
			& " exec_op.alusrc2 = " 	& to_string(output_ref.exec_op.alusrc2)
			& " exec_op.alusrc3 = " 	& to_string(output_ref.exec_op.alusrc3) 
			& " exec_op.rs1 = " 		& to_string(output_ref.exec_op.rs1)
			& " exec_op.rs2 = " 		& to_string(output_ref.exec_op.rs2)
			& " exec_op.readdata1 = " 	& to_hstring(output_ref.exec_op.readdata1)
			& " exec_op.readdata2 = " 	& to_hstring(output_ref.exec_op.readdata2)
			& " exec_op.imm = " 		& to_hstring(output_ref.exec_op.imm)
			& " mem_op.branch = " 		& to_string(output_ref.mem_op.branch)
			& " mem_op.memread = " 		& to_string(output_ref.mem_op.mem.memread)
			& " mem_op.memwrite = " 	& to_string(output_ref.mem_op.mem.memwrite)
			& " mem_op.memtype = " 		& to_string(output_ref.mem_op.mem.memtype)
			& " wb_op.rd = " 			& to_string(output_ref.wb_op.rd)
			& " wb_op.write = " 		& to_string(output_ref.wb_op.write)
			& " wb_op.src = " 			& to_string(output_ref.wb_op.src)
			& " exc_dec = " 			& to_string(output_ref.exc_dec)
			& lf 
			& "** actual   : "
			& " pc_out = " 				& to_hstring(output.pc_out)
			& " exec_op.aluop = " 		& to_string(output.exec_op.aluop)
			& " exec_op.alusrc1 = " 	& to_string(output.exec_op.alusrc1)
			& " exec_op.alusrc2 = " 	& to_string(output.exec_op.alusrc2)
			& " exec_op.alusrc3 = " 	& to_string(output.exec_op.alusrc3) 
			& " exec_op.rs1 = " 		& to_string(output.exec_op.rs1)
			& " exec_op.rs2 = " 		& to_string(output.exec_op.rs2)
			& " exec_op.readdata1 = " 	& to_hstring(output.exec_op.readdata1)
			& " exec_op.readdata2 = " 	& to_hstring(output.exec_op.readdata2)
			& " exec_op.imm = " 		& to_hstring(output.exec_op.imm)
			& " mem_op.branch = " 		& to_string(output.mem_op.branch)
			& " mem_op.memread = " 		& to_string(output.mem_op.mem.memread)
			& " mem_op.memwrite = " 	& to_string(output.mem_op.mem.memwrite)
			& " mem_op.memtype = " 		& to_string(output.mem_op.mem.memtype)
			& " wb_op.rd = " 			& to_string(output.wb_op.rd)
			& " wb_op.write = " 		& to_string(output.wb_op.write)
			& " wb_op.src = " 			& to_string(output.wb_op.src)
			& " exc_dec = " 			& to_string(output.exc_dec)
			& lf
			severity error;
		end if;
	end procedure;
begin
	
	decode_inst : entity work.decode
	port map(
		clk       	=> clk,  
		res_n     	=> res_n,
		stall      	=> input.stall,
		flush      	=> input.flush,
		pc_in     	=> input.pc_in,
		instr     	=> input.instr,
		reg_write 	=> input.reg_write,
		pc_out    	=> output.pc_out,
		exec_op   	=> output.exec_op,
		mem_op    	=> output.mem_op,
		wb_op   	=> output.wb_op,
		exc_dec 	=> output.exc_dec
	);

	stimulus : process
		variable input_fstatus : file_open_status;
	begin
		
		res_n <= '0';
		wait until rising_edge(clk);
		res_n <= '1';
	
	-- write to regfile
		timeout(1, CLK_PERIOD);
		input.reg_write <= ('1', "00001", x"00000001");
		timeout(1, CLK_PERIOD);

		input.reg_write <= ('1', "00010", x"00000002");
		timeout(1, CLK_PERIOD);

		finished_writing <= true;

		file_open(input_fstatus, input_file, "testdata/input.txt", READ_MODE);

		while not endfile(input_file) loop
			input <= read_next_input(input_file);
			timeout(1, CLK_PERIOD);
		end loop;

		wait;
	end process;

	output_checker : process
		variable output_fstatus : file_open_status;
		variable output_ref : output_t;
	begin 

		file_open(output_fstatus, output_file, "testdata/output.txt", READ_MODE);

		wait until res_n = '1';
		wait until finished_writing =  true;
		timeout(1, CLK_PERIOD);

		while not endfile(output_file) loop
			output_ref := read_next_output(output_file);	
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
