library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;

entity regfile is
	port (
		clk              : in  std_logic;
		res_n            : in  std_logic;
		stall            : in  std_logic;
		rdaddr1, rdaddr2 : in  reg_adr_type;
		rddata1, rddata2 : out data_type;
		wraddr           : in  reg_adr_type;
		wrdata           : in  data_type;
		regwrite         : in  std_logic
	);
end entity;

architecture rtl of regfile is

	type register_t is array (REG_COUNT - 1 downto 0) of data_type;

	type state_t is record
		reg : register_t;
		last_rdaddr1 : reg_adr_type;
		last_rdaddr2 : reg_adr_type;
	end record;
	signal curr : state_t;
	signal nxt : state_t;

	function get_reg_ind(reg_addr : reg_adr_type) return integer is
		variable unsig_addr : unsigned(reg_adr_type'length - 1 downto 0) := (others => '0');
		variable ret_val : integer;
	begin
		for i in 0 to reg_adr_type'length - 1 loop
			if reg_addr(i) = '1' then
				unsig_addr(i) := '1';
			else
				unsig_addr(i) := '0';
			end if;
			ret_val := to_integer(unsig_addr);
		end loop;
		return ret_val;
	end function;

begin

	sync_p : process(clk, res_n)
	begin
		if res_n = '0' then
			curr <= (
				reg => (others => (others => '0')),
				last_rdaddr1 => (others => '0'),
				last_rdaddr2 => (others => '0')
			);
		elsif rising_edge(clk) then
			curr <= nxt;
		end if;
	end process;

	register_func_p : process(all)
	begin
		rddata1 <= (others => '0');
		rddata2 <= (others => '0');

		nxt <= curr;
		nxt.reg(0) <= (others => '0');

		if stall = '1' then
			rddata1 <= curr.reg(get_reg_ind(curr.last_rdaddr1));
			rddata2 <= curr.reg(get_reg_ind(curr.last_rdaddr2));
		else
			-- rddata1 logic
			if (regwrite = '1') and (wraddr = rdaddr1) and not(wraddr = ZERO_REG)then
				rddata1 <= wrdata;
			else
				rddata1 <= curr.reg(get_reg_ind(rdaddr1));
			end if;

			-- rddata2 logic
			if (regwrite = '1') and (wraddr = rdaddr2) and not(wraddr = ZERO_REG)then
				rddata2 <= wrdata;
			else
				rddata2 <= curr.reg(get_reg_ind(rdaddr2));
			end if;

			-- write logic
			if (regwrite = '1') and not(wraddr = ZERO_REG) then
				nxt.reg(get_reg_ind(wraddr)) <= wrdata;
			end if;

			-- address management for stalling
			if not (rdaddr1 = curr.last_rdaddr1) then
				nxt.last_rdaddr1 <= rdaddr1;
			end if;
			if not (rdaddr2 = curr.last_rdaddr2) then
				nxt.last_rdaddr2 <= rdaddr2;
			end if;
			
		end if;
	end process;
end architecture;

