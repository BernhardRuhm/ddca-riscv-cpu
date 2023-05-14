library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.op_pkg.all;

-- ATTENTION: zero flag is only valid on SUB and SLT(U)

entity alu is
	port (
		op   : in  alu_op_type;
		A, B : in  data_type;
		R    : out data_type := (others => '0');
		Z    : out std_logic := '0'
	);
end alu;

architecture rtl of alu is
begin

	Z <= '1' when (op = ALU_SUB and A = B)  else
		 '0' when (op = ALU_SUB and A /= B) else 
		 not R(0) when (op = ALU_SLT or op = ALU_SLTU) else
		 '-';

	calculation : process(all)
	begin
		if (res_n = '0') then
			R <= ohters( => '0');
			Z <= '-';
		elsif (rising_edge(clk)) then
			case op is
				when ALU_NOP =>
					R <= B;
				when ALU_SLT =>
					R <= (0 => '1', others => '0') when signed(A) < signed(B) else (others => '0');
				when ALU_SLTU =>
					R <= (0 => '1', others => '0') when unsigned(A) < unsigned(B) else (others => '0');
				when ALU_SLL =>
					R <= shift_left(unsigned(A), to_integer(unsigned(B(4 downto 0))));
				when ALU_SRL =>
					R <= shift_right(unsigned(A), to_integer(unsigned(B(4 downto 0))));
				when ALU_SRA =>
					R <= shift_right(signed(A), to_integer(unsigned(B(4 downto 0))));
				when ALU_ADD =>
					R <= std_logic_vector(signed(A) + signed(B));
				when ALU_SUB =>
					R <= std_logic_vector(signed(A) - signed(B));
				when ALU_AND => 
					R <= A and B;
				when ALU_OR =>
					R <= A or B;
				when ALU_XOR =>
					R <= A xor B;
			end op;
		end if;
	end process;
end architecture;
