library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.mem_pkg.all;
use work.op_pkg.all;

entity mem is
	port (
		clk           : in  std_logic;
		res_n         : in  std_logic;
		stall         : in  std_logic;
		flush         : in  std_logic;

		-- to Ctrl
		mem_busy      : out std_logic;

		-- from EXEC
		mem_op        : in  mem_op_type;
		wbop_in       : in  wb_op_type;
		pc_new_in     : in  pc_type;
		pc_old_in     : in  pc_type;
		aluresult_in  : in  data_type;
		wrdata        : in  data_type;
		zero          : in  std_logic;

		-- to EXEC (forwarding)
		reg_write     : out reg_write_type;

		-- to FETCH
		pc_new_out    : out pc_type;
		pcsrc         : out std_logic;

		-- to WB
		wbop_out      : out wb_op_type;
		pc_old_out    : out pc_type;
		aluresult_out : out data_type;
		memresult     : out data_type;

		-- memory controller interface
		mem_out       : out mem_out_type;
		mem_in        : in  mem_in_type;

		-- exceptions
		exc_load      : out std_logic;
		exc_store     : out std_logic
	);
end entity;

architecture rtl of mem is

	type mem_reg_t is
		record
		mem_op : mem_op_type;
		wbop  : wb_op_type;
		pc_new : pc_type;
		pc_old : pc_type;
		aluresult : data_type;
		wrdata : data_type;
		zero : std_logic;
	end record;

	signal curr, nxt : mem_reg_t;

begin

	--memu unit instantiaion
	memu_isnt : entity work.memu
	port map (
		op => curr.mem_op.mem,
		A => curr.aluresult,
		W => curr.wrdata,
		R => memresult,
		B => mem_busy,
		XL => exc_load,
		XS => exc_store,
		D => mem_in,
		M => mem_out
	);

	--branch decision
	pcsrc <= '1' when 	(curr.mem_op.branch = BR_BR 
					or 	(curr.mem_op.branch = BR_CND and curr.zero = '1')	
					or (curr.mem_op.branch = BR_CNDI and curr.zero = '0')) 
				else	'0';

	sync : process (clk, res_n)
	begin
		if (res_n = '0') then
			curr <= (
				mem_op => MEM_NOP,
				wbop => WB_NOP,
				pc_new => ZERO_PC,
				pc_old => ZERO_PC,
				zero => '0',
				others => (others => '0')
			);
		elsif (rising_edge(clk)) then
			curr <= nxt;
		end if;
	end process;

	memory : process (all)
	begin

		if (flush = '1') then
			nxt <= (
				mem_op => MEM_NOP,
				wbop => WB_NOP,
				pc_new => ZERO_PC,
				pc_old => ZERO_PC,
				zero => '0',
				others => (others => '0')
			);
		else 
			nxt <= (
				mem_op => mem_op,
				wbop => wbop_in,
				pc_new => pc_new_in,
				pc_old => pc_old_in,
				aluresult => aluresult_in,
				wrdata => wrdata,
				zero => zero
			);
		end if;

		if (stall = '1') then
			nxt <= curr;
			nxt.mem_op.mem.memread <= '0';
			nxt.mem_op.mem.memwrite <= '0';
		end if;


		reg_write.write <= curr.wbop.write;
		reg_write.reg <= curr.wbop.rd;

		case curr.wbop.src is
			when WBS_OPC =>
				reg_write.data <= std_logic_vector(resize(unsigned(curr.pc_old) + 4, INSTR_WIDTH));
			when WBS_ALU =>
				reg_write.data <= memresult;
			when others =>
				reg_write.data <= curr.aluresult;
		end case;
	
		wbop_out <= curr.wbop;
		pc_old_out <= curr.pc_old;
		pc_new_out <= curr.pc_new;
		aluresult_out <= curr.aluresult;
	end process;



end architecture;
