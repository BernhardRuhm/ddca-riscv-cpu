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
	type register_t is 
	record
		op 			  : exec_op_type;
		pc_in 		  : pc_type;
		memop_in 	  : mem_op_type;
		wbop_in 	  : wb_op_type;
	end record;
	signal curr : register_t;
	signal nxt 	: register_t;

	signal alusrc_21 	: std_logic_vector(1 downto 0);
	signal alu_input_a 	: data_type;
	signal alu_input_b 	: data_type;

	signal fwd1_val		: data_type;
	signal fwd2_val		: data_type;
	signal do_fwd1		: std_logic;
	signal do_fwd2		: std_logic;

	function get_jalr_pc(readdata : data_type; imm : data_type) return std_logic_vector is
		variable ret_val : pc_type;
		variable sum : signed(data_type'length - 1 downto 0);
	begin
		sum := signed(imm) + signed(readdata);
		ret_val:= std_logic_vector(resize(sum, ret_val'length));
		ret_val(0) := '0';
		return ret_val;
	end function;

	function get_new_pc(pc : pc_type; imm : data_type) return std_logic_vector is
		variable ret_val : pc_type;
		variable sum_int : integer;
	begin
		sum_int := to_integer(unsigned(pc)) + to_integer(signed(imm));
		ret_val := std_logic_vector(to_unsigned(sum_int, ret_val'length));
		return ret_val;
	end function;

begin

	sync_p : process(clk, res_n)
	begin
		if res_n = '0' then
			curr <= (
				op => EXEC_NOP,
				pc_in => ZERO_PC,
				memop_in => MEM_NOP,
				wbop_in => WB_NOP
			);
		elsif rising_edge(clk) then
			curr <= nxt;
		end if;
	end process;

	exec_p : process(all)
	begin
		-- default output values 
		pc_old_out <= curr.pc_in;
		memop_out <= curr.memop_in;
		wbop_out <= curr.wbop_in;
		exec_op <= curr.op;

		-- write to IF/ID register
		if stall = '0' then
			if flush = '1' then
				nxt <= (
					op => EXEC_NOP,
					pc_in => ZERO_PC,
					memop_in => MEM_NOP,
					wbop_in => WB_NOP
				);
			else
				nxt <= (
					op => op,
					pc_in => pc_in,
					memop_in => memop_in,
					wbop_in => wbop_in
				);
			end if;
		else
			nxt <= curr;
		end if;
	end process;

	-- alusrc-table for exec_op
	-- +───+───+───++─────+─────────+
	-- |   alusrc  ||   ALU-inputs  |
	-- +───+───+───++─────+─────────+
	-- | 3 | 2 | 1 ||  A  |    B    |
	-- +───+───+───++─────+─────────+
	-- | 0 | 0 | 0 || rs1 | rs2     | ◄─ R-type
	-- | 0 | 0 | 1 || rs1 | imm     | ◄─ I-type + S-type (also for DMEM address calc ─► use aluresult as address for wr/rd operation on DMEM in mem-stage)
	-- | 0 | 1 | 0 || 0   | U-imm   | ◄─ LUI (imm<<12 is part of U-type-imm)
	-- | 0 | 1 | 1 || pc  | U-imm   | ◄─ AUIPC (imm<<12 is part of U-type-imm)
	-- | - | - | - || --- | ------- | ---------------------------------
	-- | 1 | 0 | 0 || rs1 | rs2     | ◄─ B-type(WBS_NOP, pc=pc+B-imm)
	-- | 1 | 0 | 1 || pc  | 4       | ◄─ JALR (WBS_OPC + pc[0]='0')
	-- | 1 | 1 | 0 || pc  | 4	    | ◄─ JAL(WBS_OPC, imm<<1 is part of J-type-imm) 
	-- | 1 | 1 | 1 || x   | x       |
	-- +───+───+───++─────+─────────+

	alusrc_21 <= curr.op.alusrc2 & curr.op.alusrc1;
	-- 
	pc_new_out	<= 	get_new_pc(pc => curr.pc_in, imm => curr.op.imm) when ((alusrc_21 = "10" or alusrc_21 = "00") and curr.op.alusrc3 = '1')  else
					get_jalr_pc(imm => curr.op.imm, readdata => curr.op.readdata1) when (alusrc_21 = "01" and curr.op.alusrc3 = '1') else
					ZERO_PC;

	wrdata 		<= 	fwd2_val when do_fwd2 = '1' and (alusrc_21 = "01" and curr.op.alusrc3 = '0') else
					curr.op.readdata2 when (alusrc_21 = "01" and curr.op.alusrc3 = '0') else
					ZERO_DATA;

	alu_input_a <= 	fwd1_val when (do_fwd1 = '1') and ((alusrc_21 = "00") or (alusrc_21 = "01" and curr.op.alusrc3 = '0')) else
					curr.op.readdata1 when (alusrc_21 = "00") or (alusrc_21 = "01" and curr.op.alusrc3 = '0') else
					ZERO_DATA;

	alu_input_b <= 	fwd2_val when (do_fwd2 = '1') and (alusrc_21 = "00") else
					curr.op.readdata2 when (alusrc_21 = "00") else
					curr.op.imm;

	alu_inst : entity work.alu
	port map (
		op => curr.op.aluop,
		A => alu_input_a,
		B => alu_input_b,
		R => aluresult,
		Z => zero
	);

	fwd1_inst : entity work.fwd
	port map (
		reg_write_mem => reg_write_mem,
		reg_write_wb => reg_write_wr,

		reg 	=> curr.op.rs1,
		val 	=> fwd1_val,
		do_fwd 	=> do_fwd1
	);

	fwd2_inst : entity work.fwd
	port map (
		reg_write_mem => reg_write_mem,
		reg_write_wb => reg_write_wr,

		reg 	=> curr.op.rs2,
		val 	=> fwd2_val,
		do_fwd 	=> do_fwd2
	);
end architecture;
