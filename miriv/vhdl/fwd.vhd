library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.op_pkg.all;

entity fwd is
	port (
		-- from Mem
		reg_write_mem : in reg_write_type;

		-- from WB
		reg_write_wb  : in reg_write_type;

		-- from/to EXEC
		reg    : in  reg_adr_type;
		val    : out data_type;
		do_fwd : out std_logic
	);
end entity;

architecture rtl of fwd is
begin

	do_fwd <= '0' when reg = ZERO_REG else
			  '1' when (reg = reg_write_mem.reg and reg_write_mem.write = '1') else
			  '1' when (reg = reg_write_wb.reg and reg_write_wb.write = '1') else
			  '0';
	
	val <= reg_write_mem.data when (reg = reg_write_mem.reg and reg_write_mem.write = '1')  else
		   reg_write_wb.data when (reg = reg_write_wb.reg and reg_write_wb.write = '1')  else
		   (others => '0');

end architecture;
