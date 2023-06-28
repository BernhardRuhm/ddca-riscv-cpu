library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.mem_pkg.all;
use work.cache_pkg.all;

entity mgmt_st_1w is
	generic (
		SETS_LD  : natural := SETS_LD
	);
	port (
		clk     : in std_logic;
		res_n   : in std_logic;

		index   : in c_index_type;
		we      : in std_logic;
		we_repl	: in std_logic;

		mgmt_info_in  : in c_mgmt_info;
		mgmt_info_out : out c_mgmt_info
	);
end entity;

architecture impl of mgmt_st_1w is
	type mgmt_arr_t is array (0 to 2**SETS_LD-1) of c_mgmt_info;
	signal mgmt_curr, mgmt_next : mgmt_arr_t;

begin
	sync : process(clk, res_n, mgmt_curr)
	begin
		if (res_n = '0') then
			for i in 0 to 2**SETS_LD-1 loop
				mgmt_curr(i) <= (valid => '0', dirty => '0', replace => '0', tag => (others => '0'));
			end loop;
		elsif (rising_edge(clk)) then
			mgmt_curr <= mgmt_next;
		end if;
	end process;

	async : process(all)
	begin
		mgmt_next <= mgmt_curr;
		--update mgmt info
		if (we = '1') then
			mgmt_next(to_integer(unsigned(index))) <= mgmt_info_in;
		end if;
		
		--not in use for direct mapped cache
		mgmt_next(to_integer(unsigned(index))).replace <= we_repl;

		mgmt_info_out <= mgmt_curr(to_integer(unsigned(index)));
	end process;
end architecture;
