--Based on https://www.intel.com/content/dam/www/programmable/us/en/pdfs/literature/hb/qts/qts_qii51007.pdf
--VHDL Single-Clock Simple Dual-Port Synchronous RAM with New Data Read-During-Write Behavior

LIBRARY ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity single_clock_rw_ram is
	generic (
		ADDR_WIDTH : integer;
		DATA_WIDTH : integer
	);
	port (
		clk           : in std_logic;
		data_in       : in std_logic_vector(DATA_WIDTH-1 downto 0);
		write_address : in std_logic_vector(ADDR_WIDTH-1 downto 0);
		read_address  : in std_logic_vector(ADDR_WIDTH-1 downto 0);
		we            : in std_logic;
		data_out      : out std_logic_vector(DATA_WIDTH-1 downto 0)
	);
end entity;

architecture rtl of single_clock_rw_ram is
	type MEM is array(0 TO (2**ADDR_WIDTH)-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
	signal ram : MEM := (others => (others => '0'));
	signal read_address_reg : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others =>'0');
begin
	process(clk)
	begin
		if rising_edge(clk) then
			if (we='1') then
				ram(to_integer(unsigned(write_address)))<=data_in;
			end if;
			read_address_reg<=read_address;
		end if;
	end process;
	data_out<=ram(to_integer(unsigned(read_address_reg)));
end architecture;
