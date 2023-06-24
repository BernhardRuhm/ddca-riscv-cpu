library ieee;
use ieee.std_logic_1164.all;

use work.core_pkg.all;
use work.mem_pkg.all;
use work.op_pkg.all;

entity pipeline is
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

architecture impl of pipeline is

	signal stall, flush : std_logic;
	signal mem_busy_fetch, mem_busy_mem : std_logic;

-- fetch out signals	
	signal instr_fetch 	: data_type;
	signal pc_out_fetch : pc_type;

-- decode out signals
	signal pc_out_dec 	: pc_type;
	signal exec_op_dec 	: exec_op_type;
	signal mem_op_dec 	: mem_op_type;
	signal wb_op_dec 	: wb_op_type;
	signal exc_dec 		: std_logic;

-- execute out signals
	signal pc_old_out_exec 	: pc_type;
	signal pc_new_out_exec 	: pc_type;
	signal aluresult_exec 	: data_type;
	signal zero_exec 		: std_logic;
	signal wrdata_exec 		: data_type;
	signal mem_op_exec 		: mem_op_type;
	signal wb_op_exec 		: wb_op_type;
	signal exec_op 			: exec_op_type;

-- mem out signals
	signal pcsrc_mem 		: std_logic;
	signal pc_new_out_mem 	: pc_type;
	signal wb_op_mem 		: wb_op_type;
	signal pc_old_out_mem 	: pc_type;
	signal aluresult_mem 	: data_type;
	signal memresult_mem 	: data_type;
	signal reg_write_mem 	: reg_write_type;
	signal exc_load 		: std_logic;
	signal exc_store 		: std_logic;

-- wb out signals 
	signal reg_write_wb : reg_write_type;

-- fwd signals 
	signal stall_fetch 		: std_logic; 
	signal stall_dec 		: std_logic; 	
	signal stall_exec     	: std_logic; 	
	signal stall_mem 		: std_logic; 	
	signal stall_wb 		: std_logic; 	

	signal flush_fetch 		: std_logic;
	signal flush_dec 		: std_logic; 	
	signal flush_exec 		: std_logic; 	
	signal flush_mem 		: std_logic; 	
	signal flush_wb 		: std_logic; 	


begin

	stall <= mem_busy_fetch or mem_busy_mem;
	flush <= '0';

	fetch_inst : entity work.fetch
	port map(
		clk   => clk,
		res_n => res_n,
		stall => stall_fetch,
		flush => flush_fetch,

		-- to control
		mem_busy => mem_busy_fetch,

		pcsrc 	 => pcsrc_mem,
		pc_in 	 => pc_new_out_mem,
		pc_out 	 => pc_out_fetch, 
		instr 	 => instr_fetch,

		-- memory controller interface
		mem_out	=> mem_i_out,
		mem_in 	=> mem_i_in
	);

	decode_inst : entity work.decode
	port map(
		clk   => clk, 
		res_n => res_n, 
		stall => stall_dec, 
		flush => flush_dec, 

		-- from fetch
		pc_in => pc_out_fetch,
		instr => instr_fetch,

		-- from writeback
		reg_write => reg_write_wb,

		-- towards next stages
		pc_out 	=> pc_out_dec,
		exec_op => exec_op_dec,
		mem_op 	=> mem_op_dec,
		wb_op 	=> wb_op_dec,

		-- exceptions
		exc_dec => exc_dec
	);

	execute_inst : entity work.exec
	port map(
		clk   => clk,
		res_n => res_n,
		stall => stall_exec,
		flush => flush_exec,

		-- from DEC
		op 	  => exec_op_dec,
		pc_in => pc_out_dec,

		-- to MEM
		pc_old_out => pc_old_out_exec,
		pc_new_out => pc_new_out_exec,
		aluresult  => aluresult_exec,
		wrdata 	   => wrdata_exec,
		zero 	   => zero_exec,
		memop_in   => mem_op_dec,
		memop_out  => mem_op_exec,
		wbop_in    => wb_op_dec,
		wbop_out   => wb_op_exec,

		-- FWD
		exec_op 	  => exec_op,       
		reg_write_mem => reg_write_mem, 
		reg_write_wr  => reg_write_wb
	);

	memory_inst: entity work.mem
	port map(
		clk   => clk,
		res_n => res_n,
		stall => stall_mem,
		flush => flush_mem,

		-- to Ctrl
		mem_busy => mem_busy_mem,

		-- from EXEC
		mem_op 		 => mem_op_exec,
		wbop_in 	 => wb_op_exec,
		pc_new_in 	 => pc_new_out_exec,
		pc_old_in 	 => pc_old_out_exec,
		aluresult_in => aluresult_exec,
		wrdata 		 => wrdata_exec,
		zero 		 => zero_exec,

		-- to EXEC (forwarding)
		reg_write => reg_write_mem,

		-- to FETCH
		pc_new_out => pc_new_out_mem,
		pcsrc 	   => pcsrc_mem,

		-- to WB
		wbop_out 	  => wb_op_mem,
		pc_old_out 	  => pc_old_out_mem,
		aluresult_out => aluresult_mem,
		memresult 	  => memresult_mem,

		-- memory controller interface
		mem_out => mem_d_out,
		mem_in 	=> mem_d_in,

		-- exceptions
		exc_load  => exc_load,
		exc_store => exc_store
	);


	writeback_inst : entity work.wb
	port map(
		clk   => clk,
		res_n => res_n,
		stall => stall_wb,
		flush => flush_wb,

		-- from MEM
		op 		  => wb_op_mem,
		aluresult => aluresult_mem,
		memresult => memresult_mem,
		pc_old_in => pc_old_out_mem,

		-- to FWD and DEC
		reg_write => reg_write_wb
	);

	ctrl_inst : entity work.ctrl
	port map(
		clk   => clk,
		res_n => res_n,
		stall => stall,

		stall_fetch => stall_fetch,
		stall_dec 	=> stall_dec,
		stall_exec 	=> stall_exec,
		stall_mem 	=> stall_mem,
		stall_wb 	=> stall_wb,

		flush_fetch => flush_fetch,
		flush_dec 	=> flush_dec,
		flush_exec 	=> flush_exec,
		flush_mem 	=> flush_mem,
		flush_wb 	=> flush_wb,

		-- from FWD
		wb_op_exec 	=> wb_op_mem,
		exec_op_dec => exec_op,

		pcsrc_in 	=> pcsrc_mem, 
		pcsrc_out 	=> open
	);
end architecture;
