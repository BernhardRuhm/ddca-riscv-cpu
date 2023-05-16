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

	calculation : process(all)
	begin
		Z <= '1' when (op = ALU_SUB and A = B)  else
			 '0' when (op = ALU_SUB and A /= B) else 
			 not R(0) when (op = ALU_SLT or op = ALU_SLTU) else
			 '-';

		case op is
			when ALU_NOP =>
				R <= B;
			when ALU_SLT =>
				R <= (0 => '1', others => '0') when signed(A) < signed(B) else (others => '0');
			when ALU_SLTU =>
				R <= (0 => '1', others => '0') when unsigned(A) < unsigned(B) else (others => '0');
			when ALU_SLL =>
				R <= std_logic_vector(shift_left(unsigned(A), to_integer(unsigned(B(4 downto 0)))));
			when ALU_SRL =>
				R <= std_logic_vector(shift_right(unsigned(A), to_integer(unsigned(B(4 downto 0)))));
			when ALU_SRA =>
				R <= std_logic_vector(shift_right(signed(A), to_integer(unsigned(B(4 downto 0)))));
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
		end case;
	end process;
end architecture;
