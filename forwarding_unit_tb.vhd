library ieee;
use ieee.std_logic_1164.all;
use work.eecs361.all;
use work.eecs361_gates.all;

entity forwarding_unit_tb is 
end entity;

architecture behav of forwarding_unit_tb is

component forwarding_unit is
	port (id_ex_rs, id_ex_rt, ex_mem_rd, mem_wb_rd : in std_logic_vector (4 downto 0);
		ex_mem_we, mem_wb_we : in std_logic;
		forwardA, forwardB : out std_logic_vector(1 downto 0)
	);
end component forwarding_unit;

signal id_ex_rs_tb, id_ex_rt_tb, ex_mem_rd_tb, mem_wb_rd_tb : std_logic_vector (4 downto 0);
signal ex_mem_we_tb, mem_wb_we_tb : std_logic;
signal forwardA_tb, forwardB_tb : std_logic_vector(1 downto 0);

begin

dut: forwarding_unit port map (id_ex_rs_tb, id_ex_rt_tb, ex_mem_rd_tb, mem_wb_rd_tb, ex_mem_we_tb, mem_wb_we_tb, forwardA_tb, forwardB_tb);
testbench: process
begin

id_ex_rs_tb <= "00000";
id_ex_rt_tb <= "00000";
ex_mem_rd_tb <= "00000"; 
mem_wb_rd_tb <= "00000";
ex_mem_we_tb <= '0';
mem_wb_we_tb <= '0';

wait for 1 ns;

mem_wb_we_tb <= '1';
ex_mem_we_tb <= '1';
ex_mem_rd_tb <= "00000";
id_ex_rs_tb <= "10000";
id_ex_rt_tb <= "10000";

wait for 1 ns;

ex_mem_rd_tb <= "10000";

wait for 1 ns;

mem_wb_rd_tb <= "10001";
id_ex_rs_tb <= "10001";
id_ex_rt_tb <= "10001";

wait for 1 ns;

ex_mem_rd_tb <= "10001";

wait for 1 ns;

ex_mem_we_tb <= '0';

wait for 1 ns;

end process;
end behav;