library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;

library std; -- for Printing
use std.env.all;
use std.textio.all;

library bootloader;
use bootloader.dev_pkg.all;

use work.mem_pkg.all;

entity tb_cpu is
	generic (
		IMEM : string := "imem.mif";
		DMEM : string := "dmem.mif"
	);
end entity;

architecture bench of tb_cpu is

	constant CLK_PERIOD : time := 10 ns;

	signal clk : std_logic := '0';
	signal res_n : std_logic := '0';

	signal mem_i_in,  mem_d_in  : mem_in_type;
	signal mem_i_out, mem_d_out : mem_out_type;

	component core is
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
	end component;

begin

	dut : core
	port map (
		clk   => clk,
		res_n => res_n,

		mem_i_out => mem_i_out,
		mem_i_in  => mem_i_in,

		mem_d_out => mem_d_out,
		mem_d_in  => mem_d_in
	);

	dev_inst : dev
	generic map (
		IMEM_FILE => IMEM,
		DMEM_FILE => DMEM,
		IMEM_DELAY => 0,
		DMEM_DELAY => 0
	)
	port map (
		clk => clk,
		res_n => res_n,

		mem_i_out => to_std_logic_vector(mem_i_out),
		to_mem_in_type(mem_i_in) => mem_i_in,

		mem_d_out => to_std_logic_vector(mem_d_out),
		to_mem_in_type(mem_d_in) => mem_d_in
	);

	generate_clk : process
	begin
		clk <= '0';
		wait for CLK_PERIOD/2;
		clk <= '1';
		wait for CLK_PERIOD/2;
	end process;

	generate_reset : process
	begin
		res_n <= '0';
		wait for CLK_PERIOD;
		res_n <= '1';
		wait;
	end process;

end architecture;
