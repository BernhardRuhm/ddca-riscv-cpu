library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.op_pkg.all;

entity exec is
	port (
		clk           : in  std_logic;
		res_n         : in  std_logic;
		stall         : in  std_logic;
		flush         : in  std_logic;

		-- from DEC
		op            : in  exec_op_type;
		pc_in         : in  pc_type;

		-- to MEM
		pc_old_out    : out pc_type;
		pc_new_out    : out pc_type;
		aluresult     : out data_type;
		wrdata        : out data_type;
		zero          : out std_logic;

		memop_in      : in  mem_op_type;
		memop_out     : out mem_op_type;
		wbop_in       : in  wb_op_type;
		wbop_out      : out wb_op_type;

		-- FWD
		exec_op       : out exec_op_type;
		reg_write_mem : in  reg_write_type;
		reg_write_wr  : in  reg_write_type
	);
end entity;

architecture rtl of exec is

	signal aluA, aluB : data_type;
	
	signal pc_reg, pc_reg_next   : pc_type;
	signal op_reg, op_reg_next   : exec_op_type;
	signal mem_reg, mem_reg_next : mem_op_type;
	signal wb_reg, wb_reg_next   : wb_op_type;
	
	-- fwd
	signal fwd1, fwd2 : std_logic;
	signal fwd1_val, fwd2_val : data_type;

	function get_operand_B(op : exec_op_type; fwd : std_logic; fwd_val : data_type) return data_type is
		variable B : data_type;
		variable alusrc : std_logic_vector(2 downto 0);
	begin 
		alusrc := op.alusrc3 & op.alusrc2 & op.alusrc1;
		
		if (fwd = '1') then
			return fwd_val;
		else 
			case alusrc is
				when "000" | "010" 	=> B := op.readdata2;
				when "001" 		=> B := op.imm;	
				when others 		=> B := ZERO_DATA; 
			end case;
	
			return B;
		end if;
	end function;

	function calculate_pc(pc : pc_type; op : exec_op_type) return pc_type is 
		variable alusrc : std_logic_vector(2 downto 0);
		variable pc_new : pc_type;
		variable sum : integer;
	begin
		alusrc :=  op.alusrc3 & op.alusrc2 & op.alusrc1;

		if (alusrc = "010" or alusrc = "100") then
			sum := to_integer(unsigned(pc)) + to_integer(signed(op.imm));
			pc_new  := std_logic_vector(to_unsigned(sum, PC_WIDTH));
		elsif (alusrc = "011") then 
			sum := to_integer(signed(op.readdata1)) + to_integer(signed(op.imm));
			pc_new  := std_logic_vector(to_unsigned(sum, PC_WIDTH));
		else 
			pc_new := pc;
		end if;

		return pc_new;
	end function;
begin

	alu_inst : entity work.alu
	port map(
		op 	=> op_reg.aluop,    
		A 	=> aluA, 
		B 	=> aluB,
		R  	=> aluresult,
		Z  	=> zero
	);
	
	sync : process(all)
	begin
		if (res_n = '0') then
			pc_reg  <= ZERO_PC;
			op_reg  <= EXEC_NOP;
			mem_reg <= MEM_NOP;
			wb_reg  <= WB_NOP;
		elsif (rising_edge(clk)) then


			if (stall = '0') then
				pc_reg  <= pc_in;
				op_reg  <= op;
				mem_reg <= memop_in;
				wb_reg  <= wbop_in;
			end if;

			if (flush = '1') then
			pc_reg  <= ZERO_PC;
			op_reg  <= EXEC_NOP;
			mem_reg <= MEM_NOP;
			wb_reg  <= WB_NOP;
			end if;
		end if;
	end process;

	aluA <= fwd1_val when fwd1 = '1' else op_reg.readdata1;
	aluB <= get_operand_B(op_reg, fwd2, fwd2_val); -- second alu operand
	pc_old_out <= pc_reg;
	pc_new_out <= calculate_pc(pc_reg, op_reg);
	wrdata 	   <= op_reg.readdata2 when mem_reg.mem.memwrite = '1' else ZERO_DATA;
	memop_out  <= mem_reg;
	wbop_out   <= wb_reg;
	exec_op    <= op_reg; 

	fwd_1_inst : entity work.fwd
	port map(
		-- from Mem
		reg_write_mem => reg_write_mem, 
		-- from WB
		reg_write_wb => reg_write_wr, 
		-- from/to EXEC
		reg => op_reg.rs1,      
		val => fwd1_val,     
		do_fwd => fwd1  
	);


	fwd_2_inst : entity work.fwd
	port map(
		-- from Mem
		reg_write_mem => reg_write_mem, 
		-- from WB
		reg_write_wb => reg_write_wr, 
		-- from/to EXEC
		reg => op_reg.rs2,      
		val => fwd2_val,     
		do_fwd => fwd2  
	);

end architecture;
