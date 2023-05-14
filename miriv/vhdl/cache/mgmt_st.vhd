library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.mem_pkg.all;
use work.cache_pkg.all;

entity mgmt_st is
	generic (
		SETS_LD  : natural := SETS_LD;
		WAYS_LD  : natural := WAYS_LD
	);
	port (
		clk   : in std_logic;
		res_n : in std_logic;

		index : in c_index_type;
		wr    : in std_logic;
		rd    : in std_logic;

		valid_in    : in std_logic;
		dirty_in    : in std_logic;
		tag_in      : in c_tag_type;
		way_out     : out c_way_type;
		valid_out   : out std_logic;
		dirty_out   : out std_logic;
		tag_out     : out c_tag_type;
		hit_out     : out std_logic
	);
end entity;

architecture impl of mgmt_st is
begin
end architecture;
