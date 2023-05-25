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
	type reg_mem_t is array (REG_COUNT-1 downto 0) of data_type;	
begin

<<<<<<< HEAD
	mem_access : process(all)
=======
	reg_access : process(clk)
>>>>>>> 29873595eb7d802a2627f5c7eaae0ae4badde75d
		variable reg_mem : reg_mem_t;
		variable last_raddr1, last_raddr2 : reg_adr_type;
	begin
		if (res_n = '0') then
			reg_mem := (others => (others => '0'));
			last_raddr1 := ZERO_REG;
			last_raddr2 := ZERO_REG;
		elsif rising_edge(clk) then
			if (stall = '1') then
				rddata1 <= reg_mem(to_integer(unsigned(last_raddr1)));
				rddata2 <= reg_mem(to_integer(unsigned(last_raddr2)));
			else 
				if (regwrite = '1' and wraddr /= ZERO_REG) then
					reg_mem(to_integer(unsigned(wraddr))) := wrdata;
				end if;
				
				if (wraddr = rdaddr1 and wraddr /= ZERO_REG and regwrite = '1') then
					rddata1 <= wrdata;
				else 
					rddata1 <= reg_mem(to_integer(unsigned(rdaddr1)));
				end if;

				if (wraddr = rdaddr2 and wraddr /= ZERO_REG and regwrite = '1') then
					rddata2 <= wrdata;
				else 
					rddata2 <= reg_mem(to_integer(unsigned(rdaddr2)));
				end if;

				last_raddr1 := rdaddr1;
				last_raddr2 := rdaddr2;
			end if;
		end if;
	end process;
end architecture;
