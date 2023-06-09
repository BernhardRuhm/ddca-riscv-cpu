library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pkg.all;
use work.op_pkg.all;

entity ctrl is
	port (
		clk         : in std_logic;
		res_n       : in std_logic;
		stall       : in std_logic;

		stall_fetch : out std_logic;
		stall_dec   : out std_logic;
		stall_exec  : out std_logic;
		stall_mem   : out std_logic;
		stall_wb    : out std_logic;

		flush_fetch : out std_logic;
		flush_dec   : out std_logic;
		flush_exec  : out std_logic;
		flush_mem   : out std_logic;
		flush_wb    : out std_logic;

		-- from FWD
		wb_op_exec  : in  wb_op_type;
		exec_op_dec : in  exec_op_type;

		pcsrc_in : in std_logic;
		pcsrc_out : out std_logic
	);
end entity;

architecture rtl of ctrl is
begin

	flush_fetch <= pcsrc_in; 
	flush_dec   <= pcsrc_in;
	flush_exec  <= pcsrc_in;
	flush_mem   <= pcsrc_in;   
	flush_wb   	<= '0'; -- no flush needed

	stall_fetch <= stall;
	stall_dec   <= stall;
	stall_exec  <= stall;
	stall_mem   <= stall;
	stall_wb    <= stall;
	
	pcsrc_out <= pcsrc_in;

end architecture;
