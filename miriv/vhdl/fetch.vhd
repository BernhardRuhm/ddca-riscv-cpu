library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.op_pkg.all;
use work.mem_pkg.all;

entity fetch is
	port (
		clk        : in  std_logic;
		res_n      : in  std_logic;
		stall      : in  std_logic;
		flush      : in  std_logic;

		-- to control
		mem_busy   : out std_logic;

		pcsrc      : in  std_logic;
		pc_in      : in  pc_type;
		pc_out     : out pc_type := (others => '0');
		instr      : out instr_type;

		-- memory controller interface
		mem_out   : out mem_out_type;
		mem_in    : in  mem_in_type
	);
end entity;

architecture rtl of fetch is

	signal pc, pc_next : pc_type;

begin

	pc_next <= pc_in when pcsrc = '1' else std_logic_vector(unsigned(pc) + 4); 

	fetch_instr : process(all)
	begin
		
		mem_out <= MEM_OUT_NOP;
		mem_out.rd <= '1';

		if (stall = '0') then
			mem_out.address <= pc_next(PC_WIDTH-1 downto 2);
		else 
			mem_out.address <= pc(PC_WIDTH-1 downto 2);
		end if;

		mem_busy <= mem_in.busy;
		pc_out <= pc;

		if (flush = '1') then
			instr <= NOP_INST;
		else
			instr <= reverse_bytes(mem_in.rddata);
		end if;

		if (res_n = '0') then
			pc <= (1 downto 0 => '0', others => '1');
		elsif (rising_edge(clk)) then
			if (stall = '0') then
				pc <= pc_next;
			end if;
		end if;
	end process;

end architecture;
