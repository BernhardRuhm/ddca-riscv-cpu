library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.mem_pkg.all;
use work.core_pkg.all;
use work.op_pkg.all;

entity memu is
	port (
		-- to mem
		op   : in  memu_op_type;
		A    : in  data_type;
		W    : in  data_type;
		R    : out data_type := (others => '0');

		B    : out std_logic := '0';
		XL   : out std_logic := '0';
		XS   : out std_logic := '0';

		-- to memory controller
		D    : in  mem_in_type;
		M    : out mem_out_type := MEM_OUT_NOP
	);
end entity;

architecture rtl of memu is

begin
	mem_access : process(all)
	begin
		R  <= (ohters => '0');
		B  <= '0';
		XL <= '0';
		XS <= '0';
		M  <= MEM_OUT_NOP;

		-- load or store exception
		if (((op.memtype = MEM_H or op.memtype = MEM_HU or op.memtype = MEM_W) 
				and (A(1 downto 0) = "01" or A(1 downto 0) = "11")) 
			or (op.memtype = MEM-W and A(1 downto 0) = "10")) then 		
				
				XS <= '1' when op.memwrite = '1' else '0';
				XL <= '1' when op.memread  = '1' else '0';
		else

			M.adress <= A;
			M.rd <= op.memread;
			M.wr <= op.memwrite;
			B <= D.busy;	

		-- write access
			if (op.memwrite = '1') then 
				if (op.memtype = MEM_W) then
					M.byteena <= "1111";
					M.wrdata  <= W(7 downto 0) & W(15 downto 8) & W(23 downto 16) & W(31 downto 24);
				elsif (op.memtype = MEM_H or op.memtype = MEM_HU) then
					if (A(1 downto 0) = "00" or A(1 downto 0) = "01") then
						M.byteena <= "1100";
						M.wrdata  <= ((31 downto 16) => (W(7 downto 0) & W(15 downto 8)),  others => '-');
					elsif (A(1 downto 0) = "10" or A(1 downto 0) = "11") then
						M.byteena <= "0011";
						M.wrdata  <= ((23 downto 0) => (W(7 downto 0) & W(15 downto 8)),  others => '-');
					end if;
				elsif (op.memtype = MEM_B or op.memtype = MEM_BU) then
					if (A(1 downto 0) = "00") then
						M.byteena <= "1000";
						M.wrdata  <= ((31 downto 24) => W(7 downto 0), others => '-');
					elsif (A(1 downto 0) = "01") then
						M.byteena <= "0100";
						M.wrdata  <= ((23 downto 16) => W(7 downto 0), others => '-');
					elsif (A(1 downto 0) = "10") then
						M.byteena <= "0010";
						M.wrdata  <= ((15 downto 8) => W(7 downto 0), others => '-');
					elsif (A(1 downto 0) = "11") then
						M.byteena <= "0001";
						M.wrdata  <= ((7 downto 0) => W(7 downto 0), others => '-');
					end if;
				end if;
			end if;

		-- read access
			if (op.memread = '1') then

			end if;
		end if;
			
	begin
	end process;	
end architecture;
