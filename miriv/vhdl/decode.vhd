library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.op_pkg.all;

entity decode is
	port (
		clk        : in  std_logic;
		res_n      : in  std_logic;
		stall      : in  std_logic;
		flush      : in  std_logic;

		-- from fetch
		pc_in      : in  pc_type;
		instr      : in  instr_type;

		-- from writeback
		reg_write  : in reg_write_type;

		-- towards next stages
		pc_out     : out pc_type;
		exec_op    : out exec_op_type;
		mem_op     : out mem_op_type;
		wb_op      : out wb_op_type;

		-- exceptions
		exc_dec    : out std_logic
	);
end entity;

architecture rtl of decode is

	signal pc_reg : pc_type;
	signal instr_reg : instr_type;

	signal rddata1, rddata2 : data_type;

	function generate_immediate(opcode : opcode_type; instr : instr_type) return data_type is
		variable imm : data_type;
	begin
		case opcode is

			when OPC_JALR | OPC_LOAD | OPC_OP_IMM => -- I-type
				imm := (31 downto 11 => instr(31)) & instr(30 downto 25) & instr(24 downto 21) & instr(20);

			when OPC_STORE =>  -- S-type 
				imm := (31 downto 11 => instr(31)) & instr(30 downto 25) & instr(11 downto 8) & instr(7);

			when OPC_BRANCH => -- B-type
				imm := (31 downto 12 => instr(31)) & instr(7) & instr(30 downto 25) & instr(11 downto 8) & '0'; 

			when OPC_LUI | OPC_AUIPC => -- U-type
				imm := instr(31) & instr(30 downto 20) & instr(19 downto 12) & (11 downto 0 => '0');

			when OPC_JAL => 
				imm := (31 downto 20 => instr(31)) & instr(19 downto 12) & instr(20) & instr(30 downto 25) & instr(24 downto 21) & '0';
			when others =>
				imm := (others => '0');
		end case;
		return imm;
	end function;

	function get_alu_op(funct3 : std_logic_vector(FUNCT3_WIDTH-1 downto 0);
					    funct7 : std_logic_vector(FUNCT7_WIDTH-1 downto 0)) return alu_op_type is
		variable aluop : alu_op_type;
	begin 
		case funct3 is
			when "000" 	=>
				if funct7 = "0000000" then
					aluop := ALU_ADD;
				else 
					aluop := ALU_SUB;
				end if;
			when "001" 	=> aluop := ALU_SLL; 
			when "010" 	=> aluop := ALU_SLT;
			when "011" 	=> aluop := ALU_SLTU;
			when "100" 	=> aluop := ALU_XOR;
			when "101" 	=> 
				if funct7 = "0000000" then
					aluop := ALU_SRL;
				else 
					aluop := ALU_SRA;
				end if;
			when "110" 	=> aluop := ALU_OR;
			when "111" 	=> aluop := ALU_AND;
			when others => aluop := ALU_NOP;
		end case;
		return aluop;
	end function;

begin

	pc_out <= pc_reg;

	reg_file_inst : entity work.regfile
	port map(
		clk       => clk,
		res_n     => res_n,
		stall     => stall,
		rdaddr1   => instr(19 downto 15), -- write rs1 directly, otherwise regfile is delayed by 1 cycle
		rdaddr2   => instr(24 downto 20), -- write rs2 directly, otherwise regfile is delayed by 1 cycle
		rddata1   => rddata1,
		rddata2   => rddata2,
		wraddr    => reg_write.reg,
		wrdata    => reg_write.data,
		regwrite  => reg_write.write
	);

	sync : process(clk, res_n)
	begin
		if (res_n = '0') then
			pc_reg <= ZERO_PC;
			instr_reg <= NOP_INST;
		elsif (rising_edge(clk)) then
			if (stall = '0') then
				pc_reg <= pc_in;
				instr_reg <= instr;
			end if;

			if (flush = '1') then
				instr_reg <= NOP_INST;
			end if;
		end if;
	end process;


	decode_instr : process(all)

		variable opcode : opcode_type;
		variable rd, rs1, rs2 : std_logic_vector(REG_BITS-1 downto 0); 
		variable funct3 : std_logic_vector(FUNCT3_WIDTH-1 downto 0);
		variable funct7 : std_logic_vector(FUNCT7_WIDTH-1 downto 0);
		variable alu_src : std_logic_vector(2 downto 0);

		procedure decode_nop is
		begin

			exec_op.rs1 <= ZERO_REG;
			exec_op.rs2 <= ZERO_REG;
			exec_op.readdata2 <= ZERO_DATA;
			wb_op   <= WB_NOP;
			exec_op.readdata1 <= ZERO_DATA;
			alu_src := "000";
		end procedure;

		procedure decode_R_type_instr is 
		begin
			exec_op.aluop <= get_alu_op(funct3, funct7);
			alu_src := "000";
			wb_op <= (rd => rd, write => '1', src => WBS_ALU);
		end procedure;

		procedure decode_imm_instr is 
		begin
			if (instr_reg = NOP_INST) then
				decode_nop;	
			else 	
				exec_op.rs2 <= ZERO_REG;
				exec_op.readdata2 <= ZERO_DATA;
				exec_op.aluop <= get_alu_op(funct3, funct7);
				alu_src := "001";
				wb_op <= (rd => rd, write => '1', src => WBS_ALU);
			end if;
		end procedure;
		
		procedure decode_load_instr is 
		begin

			case funct3 is
				when "000" 	=> mem_op.mem.memtype <= MEM_B;
				when "001" 	=> mem_op.mem.memtype <= MEM_H;
				when "010"  => mem_op.mem.memtype <= MEM_W;
				when "100" 	=> mem_op.mem.memtype <= MEM_BU;
				when "101" 	=> mem_op.mem.memtype <= MEM_HU;
				when others => exc_dec <= '1';
			end case;

			exec_op.rs2 <= ZERO_REG;
			exec_op.readdata2 <= ZERO_DATA;
			exec_op.aluop <= ALU_ADD;
			mem_op.mem.memread <= '1';
			wb_op <= (rd => rd, write => '1', src => WBS_MEM);
			alu_src := "001";
		end procedure;

		procedure decode_jalr_instr is
		begin 

			exec_op.rs2 <= ZERO_REG;
			exec_op.readdata2 <= ZERO_DATA;
			mem_op.branch <= BR_BR;
			wb_op <=(rd => rd, write => '1', src => WBS_OPC);
			alu_src := "011";
		end procedure;

		procedure decode_S_type_instr is 
		begin

			case funct3 is
				when "000" 	=> mem_op.mem.memtype <= MEM_B;
				when "001" 	=> mem_op.mem.memtype <= MEM_H;
				when "010"  => mem_op.mem.memtype <= MEM_W;
				when others => exc_dec <= '1';
			end case;

			mem_op.mem.memwrite <= '1';
			exec_op.aluop <= ALU_ADD;
			alu_src := "001";
		end procedure;

		procedure decode_B_type_instr is
		begin
			case funct3 is
				when "000"  => 
					exec_op.aluop <= ALU_SUB;
					mem_op.branch <= BR_CND;
				when "001"  => 
					exec_op.aluop <= ALU_SUB; 
					mem_op.branch <= BR_CNDI;
				when "100"  => 
					exec_op.aluop <= ALU_SLT;
					mem_op.branch <= BR_CNDI;
				when "101"  => 
					exec_op.aluop <= ALU_SLT;
					mem_op.branch <= BR_CND;
				when "110"  => 
					exec_op.aluop <= ALU_SLTU;
					mem_op.branch <= BR_CNDI;
				when "111"  => 
					exec_op.aluop <= ALU_SLTU;
					mem_op.branch <= BR_CND;
				when others => exc_dec <= '1';
			end case;

			alu_src := "010";
		end procedure;

		procedure decode_J_type_instr is
		begin

			exec_op.rs1 <= ZERO_REG;
			exec_op.rs2 <= ZERO_REG;
			exec_op.readdata1 <= ZERO_DATA;
			exec_op.readdata2 <= ZERO_DATA;
			mem_op.branch <= BR_BR;
			wb_op <=(rd => rd, write => '1', src => WBS_OPC);
			alu_src := "100";
		end procedure;

		procedure decode_lui_instr is 
		begin

			exec_op.rs1 <= ZERO_REG;
			exec_op.rs2 <= ZERO_REG;
			exec_op.readdata2 <= ZERO_DATA;
			exec_op.readdata1 <= ZERO_DATA;
			alu_src := "110";
			wb_op <=(rd => rd, write => '1', src => WBS_ALU);
		end procedure;

		procedure decode_auipc_instr is 
		begin

			exec_op.rs1 <= ZERO_REG;
			exec_op.rs2 <= ZERO_REG;
			exec_op.readdata2 <= ZERO_DATA;
			exec_op.readdata1 <= ZERO_DATA;
			alu_src := "101";
			wb_op <=(rd => rd, write => '1', src => WBS_ALU);
		end procedure;

	begin



	-- extract operands from instruction
		opcode 	:= instr_reg(6 downto 0);	
		rd 	:= instr_reg(11 downto 7);
		funct3  := instr_reg(14 downto 12);
		rs1 	:= instr_reg(19 downto 15);
		rs2 	:= instr_reg(24 downto 20);
		funct7  := instr_reg(31 downto 25);

		exec_op <= EXEC_NOP;
		mem_op  <= MEM_NOP;
		wb_op   <= WB_NOP;

	--default outputs
		alu_src := "000";
		exec_op.rs1 <= rs1;  
		exec_op.rs2 <= rs2;  
		exec_op.readdata1 <= rddata1;
		exec_op.readdata2 <= rddata2;
		exec_op.imm <= generate_immediate(opcode, instr_reg); -- directly connected to exec_op

		
		exc_dec <= '0';

		case opcode is
			when OPC_OP 	=> decode_R_type_instr;
			when OPC_OP_IMM => decode_imm_instr;
			when OPC_LOAD   => decode_load_instr;
			when OPC_JALR   => decode_jalr_instr;
			when OPC_STORE  => decode_S_type_instr;
			when OPC_BRANCH => decode_B_type_instr;
			when OPC_JAL 	=> decode_J_type_instr;
			when OPC_LUI 	=> decode_lui_instr;
			when OPC_AUIPC 	=> decode_auipc_instr;
		--	when OPC_NOP 	=> 
		--		if (funct3 = "000") then
	--				decode_nop;
		 
	--				exc_dec <= '1';
	--			end if;
			when others 	=> exc_dec <= '1';
		end case;
		
		exec_op.alusrc1 <= alu_src(0);	
		exec_op.alusrc2 <= alu_src(1);	
		exec_op.alusrc3 <= alu_src(2);	

	end process;
end architecture;
