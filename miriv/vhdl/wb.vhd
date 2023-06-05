library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.op_pkg.all;

entity wb is
	port (
		clk        : in  std_logic;
		res_n      : in  std_logic;
		stall      : in  std_logic;
		flush      : in  std_logic;

		-- from MEM
		op         : in  wb_op_type;
		aluresult  : in  data_type;
		memresult  : in  data_type;
		pc_old_in  : in  pc_type;

		-- to FWD and DEC
		reg_write  : out reg_write_type
	);
end entity;

architecture rtl of wb is
	type wb_reg_t is
		record
			op        : wb_op_type;
			aluresult : data_type;
			memresult : data_type;
			pc_old    : pc_type;
		end record;

	signal curr, nxt : wb_reg_t;

begin

	sync : process (clk)
	begin
		if res_n = '0' then
			curr <= (
				op        => WB_NOP,
				pc_old    => ZERO_PC,
				others    => (others => '0')
			);
		elsif rising_edge(clk) then
			curr <= nxt;
		end if;
	end process;

	wb : process (all)
	begin
		
		if (flush = '1') then
			nxt <= (
				op        => WB_NOP,
				pc_old    => ZERO_PC,
				others    => (others => '0')
			);
		else
			nxt <= (
				op        => op,
				aluresult => aluresult,
				memresult => memresult,
				pc_old    => pc_old_in
			);
		end if;

		if (stall = '1') then
			nxt <= curr;
		end if;

	end process;

		reg_write.write <= curr.op.write;
		reg_write.reg <= curr.op.rd;

		reg_write.data <= 	curr.memresult when (curr.op.src = WBS_MEM) else
							curr.aluresult when (curr.op.src = WBS_ALU) else
			std_logic_vector(resize(unsigned(curr.pc_old) + 4, INSTR_WIDTH));

end architecture;
