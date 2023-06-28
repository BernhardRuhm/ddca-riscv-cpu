library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.mem_pkg.all;
use work.cache_pkg.all;
use work.single_clock_rw_ram_pkg.all;

entity data_st_1w is
	generic (
		SETS_LD  : natural := SETS_LD
	);
	port (
		clk       : in std_logic;

		we        : in std_logic;
		rd        : in std_logic;
		index     : in c_index_type;
		byteena   : in mem_byteena_type;

		data_in   : in mem_data_type;
		data_out  : out mem_data_type
);
end entity;

architecture impl of data_st_1w is
	signal data : mem_data_type;
	signal we_data : mem_byteena_type;
begin
	gen_ram : for i in byteena'range
	generate

		--generate data_out and we for each byte (7 downto 0, 15 downto 8, 23 downto 16, 31 downto 24)
		data_out((i*8+7) downto i*8) <=	data((i*8+7) downto i*8) when rd = '1' else (others => '0');
		we_data(i) <= byteena(i) when we = '1' else '0';
	
		--generate ram for each byte
		single_clock_rw_ram_inst : entity work.single_clock_rw_ram

		generic map (
			ADDR_WIDTH => SETS_LD,
			DATA_WIDTH => 8
		)
		port map (
			clk           => clk,
			data_in       => data_in(((i*8)+7) downto (i*8)),
			write_address => index,
			read_address  => index,
			we            => we_data(i),
			data_out      => data(((i*8)+7) downto (i*8))
		);
	end generate;
end architecture;
