library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.mem_pkg.all;
use work.cache_pkg.all;

entity cache is
	generic (
		SETS_LD   : natural          := SETS_LD;
		WAYS_LD   : natural          := WAYS_LD;
		ADDR_MASK : mem_address_type := (others => '1')
	);
	port (
		clk   : in std_logic;
		res_n : in std_logic;

		mem_out_cpu : in  mem_out_type;
		mem_in_cpu  : out mem_in_type;
		mem_out_mem : out mem_out_type;
		mem_in_mem  : in  mem_in_type
	);
end entity;

architecture bypass of cache is --bypass cache for exIII and testing
	alias cpu_to_cache : mem_out_type is mem_out_cpu; 
	alias cache_to_cpu : mem_in_type is mem_in_cpu;   
	alias cache_to_mem : mem_out_type is mem_out_mem; 
	alias mem_to_cache : mem_in_type is mem_in_mem;   
begin
	cache_to_mem <= cpu_to_cache; 
	cache_to_cpu <= mem_to_cache; 
end architecture;

architecture impl of cache is

	alias cpu_to_cache : mem_out_type is mem_out_cpu; 
	alias cache_to_cpu : mem_in_type is mem_in_cpu;   
	alias cache_to_mem : mem_out_type is mem_out_mem; 
	alias mem_to_cache : mem_in_type is mem_in_mem;

	-- mgmt_st
	signal index : c_index_type := (others => '0');

	signal mgmt_wr : std_logic;
	signal mgmt_rd : std_logic;

	signal valid_in : std_logic;
	signal dirty_in : std_logic;
	signal tag	 	: c_tag_type;

	--not used
	signal way_out : c_way_type;

	signal valid_out : std_logic;
	signal dirty_out : std_logic;
	signal tag_out 	 : c_tag_type;
	signal hit_out 	 : std_logic;

	-- data_st
	signal data_we 	: std_logic;
	signal data_rd 	: std_logic;
	--not used
	signal way 		: c_way_type;
	signal byteena 	: mem_byteena_type;

	signal data_in 	: mem_data_type;
	signal data_out : mem_data_type;

	-- fsm
	signal fsm_busy : std_logic;
	signal masked_addr : mem_address_type;

	type fsm_state_t is (IDLE, READ_CACHE, READ_MEM_START, READ_MEM, WRITE_BACK_START, WRITE_BACK);

	type register_t is
	record 
		state 	: fsm_state_t;
		tag_out : c_tag_type;
		way_out : c_way_type;
		rddata 	: mem_data_type;
	end record;
	signal curr : register_t;
	signal nxt 	: register_t;
begin

	sync_p : process(clk, res_n)
	begin
		if res_n = '0' then
			curr <= (
				state => IDLE,
				tag_out => (others => '0'),
				way_out => (others => '0'),
				rddata 	=> (others => '0')
			);
		elsif rising_edge(clk) then
			curr <= nxt;
		end if;
	end process;

	masked_addr <= cpu_to_cache.address and ADDR_MASK;

	index <= cpu_to_cache.address(INDEX_SIZE-1 downto 0);
	tag <= cpu_to_cache.address(mem_address_type'high downto INDEX_SIZE);

	async : process(all)
	begin
		nxt <= curr;

		cache_to_cpu.busy <= fsm_busy or mem_to_cache.busy;
		cache_to_cpu.rddata <= curr.rddata;

		cache_to_mem <= (
			address => cpu_to_cache.address,
			rd => '0',
			wr => '0',
			byteena => "0000",
			wrdata => (others => '0')
		);

		--default values
		
		--mgmt_st
		mgmt_wr  <= '0';
		mgmt_rd  <= '0';
		valid_in <= '0';
		dirty_in <= '0';

		--data_st
		data_we <= '0';
		data_rd <= '0';
		byteena	<= "1111";
		way <= (others => '0');
		data_in	<= (others => '0');

		fsm_busy <= '1';

		case curr.state is
			when IDLE =>
				fsm_busy <= '0';

				--check for bypass
				if not (cpu_to_cache.address = masked_addr) then
					cache_to_mem <= cpu_to_cache; 
					cache_to_cpu <= mem_to_cache; 
				else
					mgmt_rd <= '1';
					nxt.tag_out <= tag_out;

					if cpu_to_cache.rd = '1' then
						if hit_out = '1' then
							--read hit

							nxt.state <= READ_CACHE;
						elsif dirty_out = '1' and valid_out = '1' then
							--read miss + writeback

							nxt.state <= WRITE_BACK_START;
						else 
							--read miss 

							nxt.state <= READ_MEM_START;
						end if;
					end if;

					if cpu_to_cache.wr = '1' then
						
						if hit_out = '1' then
							--write-back on hit

							--update mgmt info
							mgmt_wr <= '1';
							valid_in <= '1';
							dirty_in <= '1';

							--update data
							data_we <= '1';
							byteena	<= cpu_to_cache.byteena;
							data_in	<= cpu_to_cache.wrdata;
						else 
							--write-around on miss
							cache_to_mem <= cpu_to_cache;
						end if;
					end if;
				end if;

			when READ_CACHE =>
				nxt.state <= IDLE;

				data_rd <= '1';
				nxt.rddata 	<= data_out;

			when READ_MEM_START =>
				nxt.state <= READ_MEM;

				cache_to_mem.rd <= '1';

			when READ_MEM =>
				if mem_to_cache.busy = '0' then
					nxt.state <= IDLE;
					
					-- update mgmt info
					mgmt_wr <= '1';
					valid_in <= '1';
					dirty_in <= '0';

					-- update data
					data_we <= '1';
					data_in <= mem_to_cache.rddata;

					-- send read data to cpu
					nxt.rddata <= mem_to_cache.rddata;
				end if;

			when WRITE_BACK_START =>
				-- address is being send to data_st

				nxt.state <= WRITE_BACK;

			when WRITE_BACK =>
				data_rd <= '1';

				cache_to_mem.wr <= '1';
				cache_to_mem.address <= curr.tag_out & index;
				cache_to_mem.wrdata <= data_out;

				nxt.state <= READ_MEM_START;

		end case;

	end process;

	mgmt_st_inst : entity work.mgmt_st
	generic map (
		SETS_LD => SETS_LD
	)
	port map (
		clk   => clk,
		res_n => res_n,

		index => index,
		wr    => mgmt_wr,
		rd    => mgmt_rd,

		valid_in    => valid_in,
		dirty_in    => dirty_in,
		tag_in      => tag,

		way_out     => way_out,

		valid_out   => valid_out,
		dirty_out   => dirty_out,
		tag_out     => tag_out,
		hit_out     => hit_out
	);

	data_st_inst : entity work.data_st
	generic map (
		SETS_LD => SETS_LD
		)
	port map (
		clk        => clk,
		we         => data_we,
		rd         => data_rd,
		way        => way,
		index      => index,
		byteena    => byteena,
		data_in    => data_in,
		data_out   => data_out
	);
end architecture;
