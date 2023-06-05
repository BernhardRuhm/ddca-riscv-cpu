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

entity execute_tb is
end entity;

architecture tb of execute_tb is

	type input_t is record
		stall    : std_logic;
		flush    : std_logic;
		op 	     : exec_op_type;
		pc_in    : pc_type;
		memop_in : mem_op_type;
		wbop_in  : wb_op_type;
	end record;

	type output_t is record
		pc_old_out : pc_type;
		pc_new_out : pc_type;
		aluresult  : data_type;
		wrdata 	   : data_type;
		zero 	   : std_logic;
		memop_out  : mem_op_type;
		wbop_out   : wb_op_type;
		exec_op    : exec_op_type;
	end record;

	constant CLK_PERIOD : time := 10 ns;

	signal clk : std_logic;
	signal res_n : std_logic := '0';
	signal stop : boolean := false;

	file input_file : text;
	file output_file : text;


	signal reg_write_mem, reg_write_wr : reg_write_type;

	signal input : input_t := (
		'0',
		'0',
		EXEC_NOP,
		ZERO_PC,
		MEM_NOP,
		WB_NOP
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
		result.op.aluop := str_to_alu_op(l.all);

		l := get_next_valid_line(f);
		result.op.alusrc1 := str_to_sl(l(1));

		l := get_next_valid_line(f);
		result.op.alusrc2 := str_to_sl(l(1));

		l := get_next_valid_line(f);
		result.op.alusrc3 := str_to_sl(l(1));

		l := get_next_valid_line(f);
		result.op.rs1 := bin_to_slv(l.all, REG_BITS);

		l := get_next_valid_line(f);
		result.op.rs2 := bin_to_slv(l.all, REG_BITS);

		l := get_next_valid_line(f);
		result.op.readdata1 := hex_to_slv(l.all, DATA_WIDTH);

		l := get_next_valid_line(f);
		result.op.readdata2 := hex_to_slv(l.all, DATA_WIDTH);

		l := get_next_valid_line(f);
		result.op.imm := hex_to_slv(l.all, DATA_WIDTH);


		l := get_next_valid_line(f);
		result.pc_in := hex_to_slv(l.all, PC_WIDTH);


		l := get_next_valid_line(f);
		result.memop_in.branch := str_to_branch(l.all);

		l := get_next_valid_line(f);
		result.memop_in.mem.memread := str_to_sl(l(1));

		l := get_next_valid_line(f);
		result.memop_in.mem.memwrite := str_to_sl(l(1));

		l := get_next_valid_line(f);
		result.memop_in.mem.memtype := str_to_mem_op(l.all);


		l := get_next_valid_line(f);
		result.wbop_in.rd := bin_to_slv(l.all, REG_BITS);

		l := get_next_valid_line(f);
		result.wbop_in.write := str_to_sl(l(1));

		l := get_next_valid_line(f);
		result.wbop_in.src := str_to_wbs_op(l.all);

		return result;
	end function;

	impure function read_next_output(file f : text) return output_t is
		variable l : line;
		variable result : output_t;
	begin
		
		result.exec_op := EXEC_NOP;

		l := get_next_valid_line(f);
		result.pc_old_out := hex_to_slv(l.all, PC_WIDTH);

		l := get_next_valid_line(f);
		result.pc_new_out := hex_to_slv(l.all, PC_WIDTH);

		l := get_next_valid_line(f);
		result.aluresult := hex_to_slv(l.all, DATA_WIDTH);	

		l := get_next_valid_line(f);
		result.wrdata := hex_to_slv(l.all, DATA_WIDTH);	

		l := get_next_valid_line(f);
		result.zero := str_to_sl(l(1));


		l := get_next_valid_line(f);
		result.memop_out.branch := str_to_branch(l.all);

		l := get_next_valid_line(f);
		result.memop_out.mem.memread := str_to_sl(l(1));

		l := get_next_valid_line(f);
		result.memop_out.mem.memwrite := str_to_sl(l(1));

		l := get_next_valid_line(f);
		result.memop_out.mem.memtype := str_to_mem_op(l.all);


		l := get_next_valid_line(f);
		result.wbop_out.rd := bin_to_slv(l.all, REG_BITS);

		l := get_next_valid_line(f);
		result.wbop_out.write := str_to_sl(l(1));

		l := get_next_valid_line(f);
		result.wbop_out.src := str_to_wbs_op(l.all);

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
			& " op.aluop = " 		& to_string(input.op.aluop)
			& " op.alusrc1 = " 	& to_string(input.op.alusrc1)
			& " op.alusrc2 = " 	& to_string(input.op.alusrc2)
			& " op.alusrc3 = " 	& to_string(input.op.alusrc3) 
			& " op.rs1 = " 		& to_string(input.op.rs1)
			& " op.rs2 = " 		& to_string(input.op.rs2)
			& " op.readdata1 = " 	& to_hstring(input.op.readdata1)
			& " op.readdata2 = " 	& to_hstring(input.op.readdata2)
			& " op.imm = " 		& to_hstring(input.op.imm)
			& " pc_in = " & to_hstring(input.pc_in)
			& " memop_in.branch = " 		& to_string(input.memop_in.branch)
			& " memop_in.memread = " 		& to_string(input.memop_in.mem.memread)
			& " memop_in.memwrite = " 	& to_string(input.memop_in.mem.memwrite)
			& " memop_in.memtype = " 		& to_string(input.memop_in.mem.memtype)
			& " wbop_in.rd = " 			& to_string(input.wbop_in.rd)
			& " wbop_in.write = " 		& to_string(input.wbop_in.write)
			& " wbop_in.src = " 			& to_string(input.wbop_in.src)
			& lf
			severity note;
		else
			report "FAILED: "
			& " stall = " 			& to_string(input.stall)
			& " flush = " 			& to_string(input.flush)
			& " op.aluop = " 		& to_string(input.op.aluop)
			& " op.alusrc1 = " 	& to_string(input.op.alusrc1)
			& " op.alusrc2 = " 	& to_string(input.op.alusrc2)
			& " op.alusrc3 = " 	& to_string(input.op.alusrc3) 
			& " op.rs1 = " 		& to_string(input.op.rs1)
			& " op.rs2 = " 		& to_string(input.op.rs2)
			& " op.readdata1 = " 	& to_hstring(input.op.readdata1)
			& " op.readdata2 = " 	& to_hstring(input.op.readdata2)
			& " op.imm = " 		& to_hstring(input.op.imm)
			& " pc_in = " & to_hstring(input.pc_in)
			& " memop_in.branch = " 		& to_string(input.memop_in.branch)
			& " memop_in.memread = " 		& to_string(input.memop_in.mem.memread)
			& " memop_in.memwrite = " 	& to_string(input.memop_in.mem.memwrite)
			& " memop_in.memtype = " 		& to_string(input.memop_in.mem.memtype)
			& " wbop_in.rd = " 			& to_string(input.wbop_in.rd)
			& " wbop_in.write = " 		& to_string(input.wbop_in.write)
			& " wbop_in.src = " 			& to_string(input.wbop_in.src)
			& lf
			& "** expected : "
			& " pc_old_out = " 			& to_hstring(output_ref.pc_old_out)
			& " pc_new_out = " 			& to_hstring(output_ref.pc_new_out)
			& " aluresult = " 			& to_hstring(output_ref.aluresult)
			& " wrdata = " 				& to_hstring(output_ref.wrdata)
			& " zero = " 				& to_string(output_ref.zero)
			& " memop_out.branch = " 	& to_string(output_ref.memop_out.branch)
			& " memop_out.memread = " 	& to_string(output_ref.memop_out.mem.memread)
			& " memop_out.memwrite = " 	& to_string(output_ref.memop_out.mem.memwrite)
			& " memop_out.memtype = " 	& to_string(output_ref.memop_out.mem.memtype)
			& " wbop_out.rd = " 		& to_string(output_ref.wbop_out.rd)
			& " wbop_out.write = " 		& to_string(output_ref.wbop_out.write)
			& " wbop_out.src = " 		& to_string(output_ref.wbop_out.src)
			& " exec_op.aluop = " 		& to_string(output_ref.exec_op.aluop)
			& " exec_op.alusrc1 = " 	& to_string(output_ref.exec_op.alusrc1)
			& " exec_op.alusrc2 = " 	& to_string(output_ref.exec_op.alusrc2)
			& " exec_op.alusrc3 = " 	& to_string(output_ref.exec_op.alusrc3) 
			& " exec_op.rs1 = " 		& to_string(output_ref.exec_op.rs1)
			& " exec_op.rs2 = " 		& to_string(output_ref.exec_op.rs2)
			& " exec_op.readdata1 = " 	& to_hstring(output_ref.exec_op.readdata1)
			& " exec_op.readdata2 = " 	& to_hstring(output_ref.exec_op.readdata2)
			& " exec_op.imm = " 		& to_hstring(output_ref.exec_op.imm)
			& lf 
			& "** actual   : "
			& " pc_old_out = " 			& to_hstring(output.pc_old_out)
			& " pc_new_out = " 			& to_hstring(output.pc_new_out)
			& " aluresult = " 			& to_hstring(output.aluresult)
			& " wrdata = " 				& to_hstring(output.wrdata)
			& " zero = " 				& to_string(output.zero)
			& " memop_out.branch = " 	& to_string(output.memop_out.branch)
			& " memop_out.memread = " 	& to_string(output.memop_out.mem.memread)
			& " memop_out.memwrite = " 	& to_string(output.memop_out.mem.memwrite)
			& " memop_out.memtype = " 	& to_string(output.memop_out.mem.memtype)
			& " wbop_out.rd = " 		& to_string(output.wbop_out.rd)
			& " wbop_out.write = " 		& to_string(output.wbop_out.write)
			& " wbop_out.src = " 		& to_string(output.wbop_out.src)
			& " exec_op.aluop = " 		& to_string(output.exec_op.aluop)
			& " exec_op.alusrc1 = " 	& to_string(output.exec_op.alusrc1)
			& " exec_op.alusrc2 = " 	& to_string(output.exec_op.alusrc2)
			& " exec_op.alusrc3 = " 	& to_string(output.exec_op.alusrc3) 
			& " exec_op.rs1 = " 		& to_string(output.exec_op.rs1)
			& " exec_op.rs2 = " 		& to_string(output.exec_op.rs2)
			& " exec_op.readdata1 = " 	& to_hstring(output.exec_op.readdata1)
			& " exec_op.readdata2 = " 	& to_hstring(output.exec_op.readdata2)
			& " exec_op.imm = " 		& to_hstring(output.exec_op.imm)
			& lf
			severity error;
		end if;
	end procedure;
begin
	
	decode_inst : entity work.exec
	port map(
		clk           => clk, 
		res_n         => res_n,
		stall         => input.stall,
		flush         => input.flush,
		op            => input.op,
		pc_in         => input.pc_in,
		pc_old_out    => output.pc_old_out,
		pc_new_out    => output.pc_new_out,
		aluresult     => output.aluresult,
		wrdata        => output.wrdata, 
		zero          => output.zero, 
		memop_in      => input.memop_in, 
		memop_out     => output.memop_out, 
		wbop_in       => input.wbop_in, 
		wbop_out      => output.wbop_out,

		-- FWD
		exec_op       => output.exec_op,
		reg_write_mem => reg_write_mem,
		reg_write_wr  => reg_write_wr 
	);

	stimulus : process
		variable input_fstatus : file_open_status;
	begin
		
		res_n <= '0';
		wait until rising_edge(clk);
		res_n <= '1';
	
		timeout(1, CLK_PERIOD);

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
