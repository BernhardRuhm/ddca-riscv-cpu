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

	signal pc_reg, pc_reg_next : pc_type;
	signal instr_reg, instr_reg_next : instr_type;

	signal rdaddr1, rdaddr2 : reg_adr_type;
	signal rddata1, rddata2 : data_type;

	function generate_immediate(opcode : opcode_type; instr : instr_type) return data_type is
		variable imm : data_type;
	begin
		case opcode is

			when OPC_JALR | OPC_LOAD | OPC_OP_IMM => -- I-type
				imm := (0 			=> instr(20), 
						4 downto 1 	=> instr(24 downto 21), 
						10 downto 5 => instr(30 downto 25),
						others 		=> instr(31));

			when OPC_STORE =>  -- S-type 
				imm := (0 			=> instr(7), 
						4 downto 1 	=> instr(11 downto 8), 
						10 downto 5 => instr(30 downto 25),
						others 		=> instr(31));

			when OPC_BRANCH => -- B-type
				imm := (0 			=> '0', 
						4 downto 1 	=> instr(11 downto 8), 
						10 downto 5 => instr(30 downto 25),
						11 			=> instr(7),
						others 		=> instr(31));

			when OPC_LUI | OPC_AUIPC => -- U-type
				imm := (31 			 => instr(31), 
						30 downto 20 => instr(30 downto 20), 
						19 downto 12 => instr(19 downto 12),
						others 		 => '0');

			when OPC_JAL => 
				imm := (0 		     => '0', 
						4 downto 1 	 => instr(24 downto 21), 
						10 downto 5  => instr(30 downto 25),
						11 			 => instr(20), 
						19 downto 12 => instr(19 downto 12),
						others 		 => instr(31));

			when others =>
				imm := (others => '0');
		end case;
		return imm;
	end function;



begin

	reg_file_inst : entity work.regfile
	port map(
		clk       => clk,
		res_n     => res_n,
		stall     => stall,
		rdaddr1   => rdaddr1,
		rdaddr2   => rdaddr2,
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
			pc_reg <= pc_reg_next;
			instr_reg <= instr_reg_next; 
		end if;
	end process;


	decode_instr : process(all)

		variable opcode : opcode_type;
		variable rd, rs1, rs2 : std_logic_vector(REG_BITS-1 downto 0); 
		variable funct3 : std_logic_vector(FUNCT3_WIDTH-1 downto 0);
		variable funct7 : std_logic_vector(FUNCT7_WIDTH-1 downto 0);
		variable alu_src : std_logic_vector(2 downto 0);

		procedure decode_R_type_instr is 
		begin

		-- set exec_op.aluop
			case funct3 is
				when "000" 	=>
					if funct7 = "0000000" then
						exec_op.aluop <= ALU_ADD;
					else 
						exec_op.aluop <= ALU_SUB;
					end if;
				when "001" 	=> exec_op.aluop <= ALU_SLL; 
				when "010" 	=> exec_op.aluop <= ALU_SLT;
				when "011" 	=> exec_op.aluop <= ALU_SLTU;
				when "100" 	=> exec_op.aluop <= ALU_XOR;
				when "101" 	=> 
					if funct7 = "0000000" then
						exec_op.aluop <= ALU_SRL;
					else 
						exec_op.aluop <= ALU_SRA;
					end if;
				when "110" 	=> exec_op.aluop <= ALU_OR;
				when "111" 	=> exec_op.aluop <= ALU_AND;
				when others => exec_op.aluop <= ALU_NOP;
			end case;

		-- set alusrc
			alu_src := "000";

		-- set wb_op
			wb_op <= (rd => rd, write => '1', src => WBS_ALU);
		end procedure;

	begin

	-- register pc and instr according to flush and stall

		if (stall = '1') then
			pc_reg_next <= pc_reg;
			instr_reg_next <= instr_reg;
		else 
			pc_reg_next <= pc_in;
			instr_reg_next <= instr;
		end if;

		if (flush = '1') then
			instr_reg_next <= NOP_INST;
		else
			instr_reg_next <= instr;
		end if;

	-- extract operands from instruction
		opcode 	:= instr(6 downto 0);	
		rd 		:= instr(11 downto 7);
		funct3  := instr(14 downto 12);
		rs1 	:= instr(19 downto 15);
		rs2 	:= instr(24 downto 20);
		funct7  := instr(31 downto 25);

		exec_op.imm <= generate_immediate(opcode, instr); -- directly connected to exec_op

		rdaddr1 <= rs1;

		rdaddr2 <= rs2;

	--default outputs
		exec_op <= EXEC_NOP;
		mem_op  <= MEM_NOP;
		wb_op   <= WB_NOP;

		exec_op.rs1 <= rs1; -- R-type
		exec_op.rs2 <= rs2; -- R-type
		exec_op.readdata1 <= rddata1;
		exec_op.readdata2 <= rddata2;

		pc_out <= pc_reg;
		
		exc_dec <= '0';

		case opcode is
			when OPC_OP => 
				decode_R_type_instr;
			when others => exc_dec <= '0';
		end case;
		
		exec_op.alusrc1 <= alu_src(0);	
		exec_op.alusrc2 <= alu_src(1);	
		exec_op.alusrc2 <= alu_src(2);	

	end process;
end architecture;
