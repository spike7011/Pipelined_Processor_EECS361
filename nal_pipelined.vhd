
library ieee;
use ieee.std_logic_1164.all;
use work.eecs361.all;
use work.eecs361_gates.all;

entity NAL_pipelined is
port(pc_in, instruction : in std_logic_vector (31 downto 0);
busA, busB : in std_logic_vector (31 downto 0);
pc_out: out std_logic_vector (31 downto 0);
pc_init : in std_logic);
end entity;


architecture struct of NAL_pipelined is

component nor_gate_32_1 is
port (x : in std_logic_vector (31 downto 0);
z : out std_logic_vector (31 downto 0));
end component;


component alu_32 is 
	port (a, b : in std_logic_vector(31 downto 0);
		op : in std_logic_vector(5 downto 0);
		shamt: in std_logic_vector (4 downto 0);
		result : out std_logic_vector(31 downto 0);
		carryout : out std_logic;
		overflow : out std_logic;
		zero : out std_logic
		);
end component;


component shifter 
	port(
		a : in std_logic_vector (31 downto 0);
		b : in std_logic_vector (4 downto 0);
		direction : in std_logic;
		result : out std_logic_vector (31 downto 0)
		);
end component shifter;

component mux32_4_1 is 
  port (
	sel	  : in	std_logic_vector (1 downto 0);
	src0,src1,src2,src3 :	in	std_logic_vector (31 downto 0);
	z : out std_logic_vector (31 downto 0)
  );
end component;

component mux_32 is 

  port (
	sel	  : in	std_logic;
	src0,src1:	in	std_logic_vector (31 downto 0);
	z : out std_logic_vector (31 downto 0)
  );
end component;

component xor_gate_3 is
  port (
    x   : in  std_logic_vector(2 downto 0);
    y   : in  std_logic_vector(2 downto 0);
    z   : out std_logic_vector(2 downto 0)
  );
end component;

component and_gate_3_1 is
port( x: in std_logic_vector (2 downto 0);
z : out std_logic);
end component;

component mux_2 is
  port (
	sel   : in  std_logic;
	src0  : in  std_logic_vector(1 downto 0);
	src1  : in  std_logic_vector(1 downto 0);
	z	    : out std_logic_vector(1 downto 0)
  );
end component;


component mux is
  port (
	sel   : in  std_logic;
	src0  : in  std_logic;
	src1  : in  std_logic;
	z	    : out std_logic
  );
end component;


component xor_gate is
  port (
    x   : in  std_logic;
    y   : in  std_logic;
    z   : out std_logic
  );
end component;

component mux_4_1 is
  port (
	sel	  : in	std_logic_vector (1 downto 0);
	src0,src1,src2,src3 :	in	std_logic;
	z : out std_logic
  );
end component;


signal op_add:  std_logic_vector (5 downto 0);
signal branch : std_logic;
signal address_out, address_temp: std_logic_vector (31 downto 0);
signal pc_branch_temp, pc_branch, pc_four, pc_four1, pc_out_temp, pc_out_temp1, pc_out_temp2 : std_logic_vector(31 downto 0);
signal sel, sel_counter : std_logic_vector (1 downto 0);
signal bgtz, bne, beq : std_logic;
signal beq_temp, bne_temp, bgtz_temp : std_logic_vector (2 downto 0);
signal lower_op : std_logic_vector (2 downto 0);
signal mux_out, mux_out1, mux_out2 : std_logic_vector(31 downto 0);
signal zero, carryout, overflow : std_logic;
signal bus_result : std_logic_vector ( 31 downto 0);
signal counter_last, counter_out : std_logic_vector (31 downto 0);
signal stall, stall_sel, stall_last : std_logic;
signal carryout1, zero1 : std_logic;

begin

op_add <= "100000";
lower_op <= instruction(28 downto 26);


G0:for i in 0 to 31 generate begin


I0: if i < 16  generate begin
address_temp(i) <= instruction(i);
end generate;

I1: if i >= 16 generate begin
address_temp(i) <= instruction(15);  -- sign extension of immm
end generate;


end generate;



S0: shifter port map(address_temp, "00010", '0', address_out); -- address*4


C0: alu_32 port map(pc_in, x"00000004", op_add, "00000", pc_four);  -- PC <= PC + 4
pc_four1 <= pc_four;
C2: alu_32 port map(pc_in, x"00000004", op_add, "00000", pc_branch_temp); -- 1. PC_Branch <= PC + 4
C1: alu_32 port map(pc_branch_temp, address_out , op_add, "00000", pc_branch);  -- 2. PC <= PC + 4+  (ADDRESS*4)


-- zero is output of alu
--carryout is also output of alu
C3: alu_32 port map(busA, busB, "100010", "00000", bus_result, carryout, overflow, zero);


sel(0) <= zero;
sel(1) <= carryout;

A0: xor_gate_3 port map(lower_op, "011", beq_temp);
A1: and_gate_3_1 port map(beq_temp, beq);  -- check if beq

A2: xor_gate_3 port map(lower_op, "010", bne_temp);
A3: and_gate_3_1 port map(bne_temp, bne); -- check if bne 

A4: xor_gate_3 port map(lower_op, "000", bgtz_temp);
A5: and_gate_3_1 port map(bgtz_temp, bgtz); -- check if bgtz


M0: mux_32 port map(beq, pc_four, pc_branch,mux_out2 );
M1: mux_32 port map(bne, pc_four, pc_branch,  mux_out);
M2: mux_32 port map(bgtz, pc_four, pc_branch, mux_out1 );


C6: mux32_4_1 port map(sel, mux_out, pc_four1, mux_out1, mux_out2, pc_out_temp);
branch <= instruction(28);

C4: mux_32 port map(branch, pc_four, pc_out_temp, pc_out_temp1);

C5: mux_32 port map(pc_init, pc_out_temp1, X"00400024", pc_out_temp2);

------ add HW Stall logic, check if branch then delay by 3, check if load-r_type then delay by 1  -------
------ set pc_out to pc_in  for number of cycles necessary
----- branches have opcode(2) = 1, loads have opcode(5) = 1 and opcode(2) = 0 -----------------

--sel_counter(1) <= instruction (31);
--sel_counter(0) <= instruction (28);

--XOR2: xor_gate port map(sel_counter(1), sel_counter(0), stall_sel);

--mux4: mux port map(stall_last, stall_sel, '1', stall);

--mux3: mux_32 port map(stall_sel, counter_out, X"00000003", counter_last) ;

--ALUcounter: alu_32 port map(counter_last, X"00000001","100010", "XXXXX", counter_out, carryout1, zero1);


--mux2: mux_4_1 port map(counter_out(1 downto 0),  '0', '1', '1', '1', stall_last);    -- if counter is zero set stall trigger back to zero
--mux1: mux_32 port map(zero1, pc_in, pc_out_temp2, pc_out);  -- if counter is zero then output the next pc, if not then hold pc_in


end struct;



