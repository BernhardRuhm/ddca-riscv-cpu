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

	signal rdaddr1 : reg_adr_type;
	signal rddata1 : data_type;

	signal rdaddr2 : reg_adr_type;
	signal rddata2 : data_type;

	-- IF/ID register
	type register_t is 
	record
		pc_in 	  : pc_type;
		instr 	  : instr_type;
	end record;
	signal curr : register_t;
	signal nxt 	: register_t;

	signal wrdata : data_type;

	signal stall_reg : std_logic;

begin

	stall_reg <= '0';

	sync_p : process(clk, res_n)
	begin
		if res_n = '0' then
			curr <= (
				pc_in => (others => '0'),
				instr => (others => '0')
			);
		elsif rising_edge(clk) then
			curr <= nxt;
		end if;
	end process;

	decode_p : process(all)
		variable curr_opc : std_logic_vector(6 downto 0);
		variable rd 	  : std_logic_vector(4 downto 0);
		variable rs1 	  : std_logic_vector(4 downto 0);
		variable rs2 	  : std_logic_vector(4 downto 0);
		variable funct3   : std_logic_vector(2 downto 0);
		variable funct7   : std_logic_vector(6 downto 0);
		
		impure function get_imm return std_logic_vector is
			variable ret_val : data_type;
			variable tmp : std_logic_vector(12 downto 0);
			variable tmp_j : std_logic_vector(20 downto 0);
		begin
			tmp := (others => '0');
			tmp_j := (others => '0');
			ret_val := (others => '0');

			case curr_opc is
				-- S-type
				when OPC_STORE =>
					tmp := curr.instr(31) & curr.instr(31 downto 25) & curr.instr(11 downto 7); -- Value 31 is used twice? "Because tmp is 13 Bit long"
					ret_val := std_logic_vector(resize(signed(tmp), ret_val'length));

				--B-type 
				when OPC_BRANCH =>
					tmp := curr.instr(31) & curr.instr(7) & curr.instr(30 downto 25) & curr.instr(11 downto 8) & '0';
					ret_val := std_logic_vector(resize(signed(tmp), ret_val'length));

				-- U-type
				when OPC_LUI =>
					ret_val := curr.instr(31 downto 12) & x"000";
				when OPC_AUIPC =>
					ret_val := curr.instr(31 downto 12) & x"000";

				-- J-type
				when OPC_JAL =>
					tmp_j := curr.instr(31) & curr.instr(19 downto 12) & curr.instr(20) & curr.instr(30 downto 25) & curr.instr(24 downto 21) & '0';
					ret_val := std_logic_vector(resize(signed(tmp_j), ret_val'length));

				-- R-type
				when OPC_OP =>
					ret_val := (others => '0');

				-- I-type
				when others =>
					tmp := curr.instr(31) & curr.instr(31 downto 20); -- 31 wird doppelt genommen? Wieso nicht 31 downto 20 und dann sign extenden? "Because tmp is 13 Bit long"
					ret_val := std_logic_vector(resize(signed(tmp), ret_val'length));

			end case;

			return ret_val;
		end function;
		
	begin

		-- write to IF/ID register
		if stall = '0' then
			if flush = '1' then
				nxt <= (
					pc_in => pc_in,
					instr => NOP_INST
				);
			else
				nxt <= (
					pc_in => pc_in,
					instr => instr
				);
			end if;
		else 
			nxt <= curr;
		end if;
		
		-- default output values
		exec_op <= EXEC_NOP;
		mem_op 	<= MEM_NOP;
		wb_op 	<= WB_NOP;
		exc_dec <= '0';
		pc_out 	<= curr.pc_in;

		-- decode of current instruction
		curr_opc := curr.instr(6 downto 0);
		rd 		 := curr.instr(11 downto 7);
		rs1 	 := curr.instr(19 downto 15);
		rs2 	 := curr.instr(24 downto 20);
		funct3 	 := curr.instr(14 downto 12);
		funct7 	 := curr.instr(31 downto 25);

		-- rs1
		rdaddr1 		  <= rs1; -- default, besides in LUI, AUIPC and JAL
		exec_op.readdata1 <= rddata1;

		-- rs2
		rdaddr2 		  <= (others => '0'); -- default, besides in R-, S- and B-Type instructions
		exec_op.readdata2 <= (others => '0');

		-- immediate
		exec_op.imm <= get_imm;
		
		-- R-type
		if (curr_opc = OPC_OP) then

			exec_op.alusrc3 <= '0';
			exec_op.alusrc2 <= '0';
			exec_op.alusrc1 <= '0';

			exec_op.rs2 	<= rs2;
			exec_op.rs1 	<= rs1;

			rdaddr2 		  <= rs2;
			exec_op.readdata2 <= rddata2;

			wb_op <= (
				rd => rd,
				write => '1',
				src => WBS_ALU
			);

			case funct3 is
				when "000" =>
					if funct7 = "0000000" then
						exec_op.aluop <= ALU_ADD;						
					else
						exec_op.aluop <= ALU_SUB;
					end if;

				when "001" => exec_op.aluop <= ALU_SLL;

				when "010" => exec_op.aluop <= ALU_SLT;

				when "011" => exec_op.aluop <= ALU_SLTU;

				when "100" => exec_op.aluop <= ALU_XOR;

				when "101" =>
					if funct7 = "0000000" then
						exec_op.aluop <= ALU_SRL;
					else
						exec_op.aluop <= ALU_SRA;
					end if;

				when "110" => exec_op.aluop <= ALU_OR;

				when "111" => exec_op.aluop <= ALU_AND;

				when others => exec_op.aluop <= ALU_NOP;
			end case;
		
		-- I-type
		elsif (curr_opc = OPC_JALR) or (curr_opc = OPC_LOAD) or (curr_opc = OPC_OP_IMM) then
			
			exec_op.alusrc3 <= '0';
			exec_op.alusrc2 <= '0';
			exec_op.alusrc1 <= '1';

			exec_op.rs1 	<= rs1;

			wb_op.rd <= rd;
			wb_op.write <= '1';

			if curr_opc = OPC_JALR then
				if funct3 = "000" then -- JALR
					exec_op.alusrc3 <= '1';
					exec_op.aluop <= ALU_ADD;
					
					mem_op.branch <= BR_BR;

					wb_op.src <= WBS_OPC;
				else 
					exc_dec <= '1';
				end if;

			elsif curr_opc = OPC_LOAD then

				exec_op.aluop <= ALU_ADD;

				mem_op.mem.memread 	<= '1';

				wb_op.src <= WBS_MEM;

				case funct3 is
					when "000" => mem_op.mem.memtype <= MEM_B;  -- LB

					when "001" => mem_op.mem.memtype <= MEM_H;  -- LH

					when "010" => mem_op.mem.memtype <= MEM_W;  -- LW

					when "100" => mem_op.mem.memtype <= MEM_BU; -- LBU

					when "101" => mem_op.mem.memtype <= MEM_HU; -- LHU

					when others => exc_dec <= '1';
				end case;
			else -- OPC_OP_IMM

				wb_op.src <= WBS_ALU;  -- nicht notwendig da WB_NOP

				case funct3 is
					when "000" => exec_op.aluop <= ALU_ADD;

					when "001" => exec_op.aluop <= ALU_SLL;

					when "010" => exec_op.aluop <= ALU_SLT;

					when "011" => exec_op.aluop <= ALU_SLTU;

					when "100" => exec_op.aluop <= ALU_XOR;

					when "101" =>
						if exec_op.imm(10) = '0' then
							exec_op.aluop <= ALU_SRL;
						else
							exec_op.aluop <= ALU_SRA;
						end if;

					when "110" => exec_op.aluop <= ALU_OR;

					when "111" => exec_op.aluop <= ALU_AND;

					when others => exec_op.aluop <= ALU_NOP;
				end case;
			end if;
			

		-- S-type
		elsif (curr_opc = OPC_STORE) then

			exec_op.aluop <= ALU_ADD;

			exec_op.alusrc3 <= '0';
			exec_op.alusrc2 <= '0';
			exec_op.alusrc1 <= '1';

			exec_op.rs2 	<= rs2;
			exec_op.rs1 	<= rs1;

			rdaddr2 		  <= rs2;
			exec_op.readdata2 <= rddata2;

			mem_op.mem.memwrite <= '1';

			case funct3 is
				when "000" => mem_op.mem.memtype <= MEM_B; -- SB

				when "001" => mem_op.mem.memtype <= MEM_H; -- SH

				when "010" => mem_op.mem.memtype <= MEM_W; -- SW

				when others => exc_dec <= '1';
			end case;


		--B-type 
		elsif (curr_opc = OPC_BRANCH) then

			exec_op.alusrc3 <= '1';
			exec_op.alusrc2 <= '0';
			exec_op.alusrc1 <= '0';

			exec_op.rs2 	<= rs2;
			exec_op.rs1 	<= rs1;

			rdaddr2 		  <= rs2;
			exec_op.readdata2 <= rddata2;
			
			case funct3 is
				when "000" => -- BEQ
					exec_op.aluop <= ALU_SUB; -- ALU-zero-bit = 1 when equal
					mem_op.branch <= BR_CND;

				when "001" => -- BNE
					exec_op.aluop <= ALU_SUB;
					mem_op.branch <= BR_CNDI;

				when "100" => -- BLT
					exec_op.aluop <= ALU_SLT;
					mem_op.branch <= BR_CNDI; -- if A < B = T then Z = '0'

				when "101" => -- BGE
					exec_op.aluop <= ALU_SLT;
					mem_op.branch <= BR_CND; -- if A < B = F then Z = '1'

				when "110" => -- BLTU
					exec_op.aluop <= ALU_SLTU;
					mem_op.branch <= BR_CNDI;

				when "111" => -- BGEU
					exec_op.aluop <= ALU_SLTU;
					mem_op.branch <= BR_CND;

				when others => exc_dec <= '1';
			end case;


		-- U-type
		elsif (curr_opc = OPC_LUI) or (curr_opc = OPC_AUIPC) then

			rdaddr1 		  <= (others => '0');
			exec_op.readdata1 <= (others => '0');

			exec_op.aluop 	<= ALU_ADD;
			
			wb_op <= (
				rd    => rd,
				write => '1',
				src   => WBS_ALU
			);

			if curr_opc = OPC_LUI then -- LUI		
				exec_op.alusrc3 <= '0';
				exec_op.alusrc2 <= '1';
				exec_op.alusrc1 <= '0';

			else -- AUIPC
				exec_op.alusrc3 <= '0';
				exec_op.alusrc2 <= '1';
				exec_op.alusrc1 <= '1';
			end if;


		-- J-type
		elsif (curr_opc = OPC_JAL) then -- JAL

			exec_op.aluop <= ALU_ADD;
			exec_op.alusrc3 <= '1';
			exec_op.alusrc2 <= '1';
			exec_op.alusrc1 <= '0';

			rdaddr1 		  <= (others => '0');
			exec_op.readdata1 <= (others => '0');
			
			mem_op.branch <= BR_BR;
			
			wb_op <= (
				rd 	  => rd,
				write => '1',
				src   => WBS_OPC
			);

		--NOP
		elsif (curr_opc = OPC_NOP) then
			if funct3 = "000" then -- NOP
				-- FENCE instruction
				mem_op <= MEM_NOP;
				wb_op 	<= WB_NOP;
				exec_op <= EXEC_NOP;
			else 
				exc_dec <= '1';
			end if;

		else
			exc_dec <= '1';
		end if;

	end process;

	wrdata <= reg_write.data when not(reg_write.reg = "00000") else ZERO_DATA;

	regfile_inst : entity work.regfile
	port map (
		clk => clk,
		res_n => res_n,
		stall => stall_reg,
		rdaddr1 => rdaddr1,
		rddata1 => rddata1,
		rdaddr2 => rdaddr2,
		rddata2 => rddata2,
		-- automatic writing to regfile
		wraddr => reg_write.reg,
		wrdata => wrdata,
		regwrite => reg_write.write
	);
end architecture;
