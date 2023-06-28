library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;

library std;
use std.textio.all;

use work.mem_pkg.all;
use work.op_pkg.all;
use work.core_pkg.all;
use work.tb_util_pkg.all;

use work.cache_pkg.all;

entity cache_tb is
end entity;

architecture bench of cache_tb is
    constant CLK_PERIOD : time := 10 ns;

    constant CPU_TO_CACHE_NOP : mem_out_type := (
        address => "00000000000000",
        rd => '0',
        wr => '0',
        byteena => "0000",
        wrdata => x"00000000"
    ); 

    constant MEM_TO_CACHE_NOP : mem_in_type := (
        busy => '0',
        rddata => x"00000000"
    );

    constant MEM_TO_CACHE_BUSY : mem_in_type := (
        busy => '1',
        rddata => x"00000000"
    );

    signal clk : std_logic;
    signal res_n : std_logic;
    signal stop : boolean := false;

    signal cpu_to_cache : mem_out_type;
    signal cache_to_cpu : mem_in_type;
    signal cache_to_mem : mem_out_type;
    signal mem_to_cache : mem_in_type;
begin

    sim : process
    begin
        --default values
        cpu_to_cache <= CPU_TO_CACHE_NOP;
        mem_to_cache <= MEM_TO_CACHE_NOP;

        res_n <= '0';
        wait until rising_edge(clk);
		res_n <= '1';

        wait for CLK_PERIOD;

        --write-around on write miss (wrtie directly to mem)
        report "write-around on write miss" severity note;
        cpu_to_cache <= (
            address => "00000000000001",
            rd => '0',
            wr => '1',
            byteena => "0001",
            wrdata => x"12345678"
        );
        wait for CLK_PERIOD;

        --read miss - update cache from mem
        report "read miss" severity note;
        cpu_to_cache <= (
            address => "00000000000001",
            rd => '1',
            wr => '0',
            byteena => "0001",
            wrdata => x"00000000"
        );

        wait until cache_to_mem.rd = '1';

        mem_to_cache <= MEM_TO_CACHE_BUSY;
        wait for 3*CLK_PERIOD;

        mem_to_cache <= (
            busy => '0',
            rddata => x"00000078"
        );

        wait until cache_to_cpu.busy = '0';


        --read hit - read cache
        report "read hit" severity note;
        cpu_to_cache <= (
            address => "00000000000001",
            rd => '1',
            wr => '0',
            byteena => "0001",
            wrdata => x"00000000"
        );

        wait until cache_to_cpu.busy = '0';

        --write hit - write back only to cache
        report "write hit" severity note;
        cpu_to_cache <= (
            address => "00000000000001",
            rd => '0',
            wr => '1',
            byteena => "1111",
            wrdata => x"87654321"
        );
        wait for CLK_PERIOD;
        
        --read hit
        report "read hit" severity note;
        cpu_to_cache <= (
            address => "00000000000001",
            rd => '1',
            wr => '0',
            byteena => "1001",
            wrdata => x"00000000"
        );

        wait until cache_to_cpu.busy = '0';

        --read miss
        report "read miss" severity note;
        cpu_to_cache <= (
            address => "00000000000010",
            rd => '1',
            wr => '0',
            byteena => "1111",
            wrdata => x"00000000"
        );

        wait until cache_to_mem.rd = '1';

        mem_to_cache <= MEM_TO_CACHE_BUSY;
        wait for 3*CLK_PERIOD;
        mem_to_cache <= (
            busy => '0',
            rddata => x"0000BB00"
        );

        wait until cache_to_cpu.busy = '0';

        --read miss
        report "read miss" severity note;
        cpu_to_cache <= (
            address => "00000000000011",
            rd => '1',
            wr => '0',
            byteena => "1111",
            wrdata => x"00000000"
        );

        wait until cache_to_mem.rd = '1';

        mem_to_cache <= MEM_TO_CACHE_BUSY;
        wait for 3*CLK_PERIOD;
        mem_to_cache <= (
            busy => '0',
            rddata => x"F0F0F0F0"
        );

        wait until cache_to_cpu.busy = '0';

        cpu_to_cache <= CPU_TO_CACHE_NOP;

        wait;
    end process;

    cache_inst : entity work.cache
    generic map (
        SETS_LD   => SETS_LD,
        WAYS_LD   => WAYS_LD
    )
    port map (
        clk => clk,
        res_n => res_n,

        mem_out_cpu => cpu_to_cache,
        mem_in_cpu => cache_to_cpu,
        mem_out_mem => cache_to_mem,
        mem_in_mem => mem_to_cache
    );
    
    generate_clk : process
	begin
		clk_generate(clk, CLK_PERIOD, stop);
		wait;
	end process;

end architecture;
