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

	function reverse_bytes(x : std_logic_vector(DATA_WIDTH-1 downto 0)) return std_logic_vector is
		variable reverse : std_logic_vector(DATA_WIDTH-1 downto 0);
	begin
		reverse := x(7 downto 0) & x(15 downto 8) & x(23 downto 16) & x(31 downto 24);
		return reverse;
	end function;

begin
	mem_access : process(all)
	begin
		R  <= (others => '0');
		B  <= '0';
		XL <= '0';
		XS <= '0';
		M  <= MEM_OUT_NOP;

		-- load or store exception
		if (((op.memtype = MEM_H or op.memtype = MEM_HU or op.memtype = MEM_W) 
				and (A(1 downto 0) = "01" or A(1 downto 0) = "11")) 
			or (op.memtype = MEM_W and A(1 downto 0) = "10")) then 		
				
				XS <= '1' when op.memwrite = '1' else '0';
				XL <= '1' when op.memread  = '1' else '0';
		else

			M.address <= A(31 downto 18);
			M.rd <= op.memread;
			M.wr <= op.memwrite;
			B <= op.memread or D.busy;	
			
			if (op.memtype = MEM_W) then

				M.byteena <= "1111";
				M.wrdata  <= reverse_bytes(W);
				R <= reverse_bytes(D.rddata);

			elsif (op.memtype = MEM_H) then

				if (A(1 downto 0) = "00" or A(1 downto 0) = "01") then
					M.byteena <= "1100";
					M.wrdata  <= (15 downto 0 => reverse_bytes(D.rddata)(DATA_WIDTH-1 downto 16), others => '-');
					R <= std_logic_vector(resize(signed(reverse_bytes(W)(15 downto 0)), DATA_WIDTH));

				elsif (A(1 downto 0) = "10" or A(1 downto 0) = "11") then
					M.byteena <= "0011";
					M.wrdata  <= (15 downto 0 => reverse_bytes(D.rddata)(DATA_WIDTH-1 downto 16),  others => '-');
					R <= std_logic_vector(resize(signed(reverse_bytes(W)(DATA_WIDTH-1 downto 16)), DATA_WIDTH));
				end if;

			elsif (op.memtype = MEM_HU) then

				if (A(1 downto 0) = "00" or A(1 downto 0) = "01") then
					M.byteena <= "1100";
					M.wrdata  <= (15 downto 0 => reverse_bytes(D.rddata)(DATA_WIDTH-1 downto 16), others => '-');
					R <= std_logic_vector(resize(unsigned(reverse_bytes(W)(15 downto 0)), DATA_WIDTH));

				elsif (A(1 downto 0) = "10" or A(1 downto 0) = "11") then
					M.byteena <= "0011";
					M.wrdata  <= (15 downto 0 => reverse_bytes(D.rddata)(DATA_WIDTH-1 downto 16),  others => '-');
					R <= std_logic_vector(resize(unsigned(reverse_bytes(W)(DATA_WIDTH-1 downto 16)), DATA_WIDTH));
				end if;

			elsif (op.memtype = MEM_B) then
				if (A(1 downto 0) = "00") then
					M.byteena <= "1000";
					M.wrdata  <= (31 downto 24 => W(7 downto 0), others => '-');
					R <= std_logic_vector(resize(signed(W(31 downto 24)), DATA_WIDTH));
				elsif (A(1 downto 0) = "01") then
					M.byteena <= "0100";
					M.wrdata  <= (23 downto 16 => W(7 downto 0), others => '-');
					R <= std_logic_vector(resize(signed(W(23 downto 16)), DATA_WIDTH));
				elsif (A(1 downto 0) = "10") then
					M.byteena <= "0010";
					M.wrdata  <= (15 downto 8 => W(7 downto 0), others => '-');
					R <= std_logic_vector(resize(signed(W(15 downto 8)), DATA_WIDTH));
				elsif (A(1 downto 0) = "11") then
					M.byteena <= "0001";
					M.wrdata  <= (7 downto 0 => W(7 downto 0), others => '-');
					R <= std_logic_vector(resize(signed(W(7 downto 0)), DATA_WIDTH));
				end if;

			elsif (op.memtype = MEM_BU) then
				if (A(1 downto 0) = "00") then
					M.byteena <= "1000";
					M.wrdata  <= (31 downto 24 => W(7 downto 0), others => '-');
					R <= std_logic_vector(resize(unsigned(W(31 downto 24)), DATA_WIDTH));
				elsif (A(1 downto 0) = "01") then
					M.byteena <= "0100";
					M.wrdata  <= (23 downto 16 => W(7 downto 0), others => '-');
					R <= std_logic_vector(resize(unsigned(W(23 downto 16)), DATA_WIDTH));
				elsif (A(1 downto 0) = "10") then
					M.byteena <= "0010";
					M.wrdata  <= (15 downto 8 => W(7 downto 0), others => '-');
					R <= std_logic_vector(resize(unsigned(W(15 downto 8)), DATA_WIDTH));
				elsif (A(1 downto 0) = "11") then
					M.byteena <= "0001";
					M.wrdata  <= (7 downto 0 => W(7 downto 0), others => '-');
					R <= std_logic_vector(resize(unsigned(W(7 downto 0)), DATA_WIDTH));
				end if;
			end if;
		end if;
	end process;	
end architecture;
