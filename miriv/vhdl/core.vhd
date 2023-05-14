library ieee;
use ieee.std_logic_1164.all;

use work.core_pkg.all;
use work.mem_pkg.all;
use work.op_pkg.all;

entity core is
	port (
		clk    : in  std_logic;
		res_n  : in  std_logic;

		-- instruction interface
		mem_i_out    : out mem_out_type;
		mem_i_in     : in  mem_in_type;

		-- data interface
		mem_d_out    : out mem_out_type;
		mem_d_in     : in  mem_in_type
	);
end entity;

architecture impl of core is

	signal mem_d_out_s : mem_out_type;
	signal mem_d_in_s : mem_in_type;

begin

	pipeline_inst : entity work.pipeline
	port map (
		clk => clk,
		res_n => res_n,
		mem_i_out => mem_i_out,
		mem_i_in  => mem_i_in,
		mem_d_out => mem_d_out_s,
		mem_d_in  => mem_d_in_s
	);

	--cache_inst : entity work.cache(impl) --including the cache implementation
	cache_inst : entity work.cache(bypass) --bypassing the cache
	generic map (
		ADDR_MASK => 14x"0FFF"
	)
	port map (
		clk    => clk,
		res_n  => res_n,

		mem_out_cpu  => mem_d_out_s,
		mem_in_cpu   => mem_d_in_s,
		mem_out_mem  => mem_d_out,
		mem_in_mem   => mem_d_in
	);

end architecture;
