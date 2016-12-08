library ieee;
use ieee.std_logic_1164.all;
use work.eecs361.all;
use work.eecs361_gates.all;

entity CPU_pipelined is
	generic (
		data_file : string
  	);
port (clk : in std_logic;
      pc_init: in std_logic);
end CPU_pipelined;

architecture structure of CPU_pipelined is

component alu_32 is 
	port (a : in std_logic_vector(31 downto 0);
		b : in std_logic_vector(31 downto 0);
		op : in std_logic_vector(5 downto 0);
		shamt : in std_logic_vector (4 downto 0);
		result : out std_logic_vector(31 downto 0);
		carryout : out std_logic;
		overflow : out std_logic;
		zero : out std_logic
		);
end component alu_32;

component fetch_pipe is 
generic (
	mem_file : string
  );
port( 
	clk 	: in std_logic;
	pc : in std_logic_vector (31 downto 0);
	instruction : out std_logic_vector (31 downto 0));
end component;

component syncram is
  generic (
	mem_file : string
  );
  port (
	clk	: in std_logic;
	cs	  : in	std_logic;
	oe	  :	in	std_logic;
	we	  :	in	std_logic;
	addr  : in	std_logic_vector(31 downto 0);
	din	  :	in	std_logic_vector(31 downto 0);
	dout  :	out std_logic_vector(31 downto 0)
  );
end component;

component sram is
  generic (
	mem_file : string
  );
  port (
	cs	  : in	std_logic;
	oe	  :	in	std_logic;
	we	  :	in	std_logic;
	addr  : in	std_logic_vector(31 downto 0);
	din	  :	in	std_logic_vector(31 downto 0);
	dout  :	out std_logic_vector(31 downto 0)
  );
end component;

component register_32bit_32 is
port(
clk :in std_logic;
we: in std_logic;
rw : in std_logic_vector(4 downto 0);
ra : in std_logic_vector(4 downto 0);
rb : in std_logic_vector(4 downto 0);
busw : in  std_logic_vector(31 downto 0);
busa : out  std_logic_vector(31 downto 0);
busb : out  std_logic_vector(31 downto 0));
end component;

component extender is
port ( x: in std_logic_vector (15 downto 0);
	op :in std_logic;
	z: out std_logic_vector (31 downto 0));
end component;


component NAL_pipelined is
port(pc_in, instruction : in std_logic_vector (31 downto 0);
busA, busB : in std_logic_vector (31 downto 0);
pc_out: out std_logic_vector (31 downto 0);
pc_init : in std_logic);
end component;

component mux_32 is
  port (
	sel   : in  std_logic;
	src0  : in  std_logic_vector(31 downto 0);
	src1  : in  std_logic_vector(31 downto 0);
	z	    : out std_logic_vector(31 downto 0)
  );
end component;

component register_32bit is
port (clk, we  : in std_logic;
din: in std_logic_vector (31 downto 0);
dout  : out std_logic_vector (31 downto 0));
end component;

component ID is
port(instruction : in std_logic_vector (31 downto 0);
control : out std_logic_vector (7 downto 0);
ALUop : out std_logic_vector (5 downto 0));
end component;


-- START OF ANY CHANGES FROM SINGLE CYLCE ------------------------------------ 

component Reg_IF_ID is
port(
clk : in std_logic;
pc_4_in :in std_logic_vector(31 downto 0);
instruction_in : in std_logic_vector(31 downto 0);
pc_4_out :out std_logic_vector(31 downto 0);
instruction_out : out std_logic_vector (31 downto 0));
end component;

component mux_8 is
  port (
	sel   : in  std_logic;
	src0  : in  std_logic_vector(7 downto 0);
	src1  : in  std_logic_vector(7 downto 0);
	z	    : out std_logic_vector(7 downto 0)
  );
end component;



component Reg_ID_EX is
port(
clk : in std_logic;
shamt_in : in std_logic_vector (4 downto 0);
imm16_in : in std_logic_vector(15 downto 0);
control_in : in std_logic_vector (7 downto 0);
ALUop_in :in std_logic_vector (5 downto 0);
shamt_out : out std_logic_vector (4 downto 0);
imm16_out : out std_logic_vector(15 downto 0);
control_out : out std_logic_vector (7 downto 0);
ALUop_out : out std_logic_vector (5 downto 0);
ID_busA, ID_busB : in std_logic_vector (31 downto 0);
EX_busA, EX_busB : out std_logic_vector(31 downto 0);
instruction_in : in std_logic_vector (31 downto 0);
instruction_out : out std_logic_vector (31 downto 0));
end component;

component Reg_EX_MEM is
port(
clk : in std_logic;
busB_in : std_logic_vector (31 downto 0);
ALUresult_in : in std_logic_vector (31 downto 0);
control_in : in std_logic_vector (7 downto 0);
busB_out: out std_logic_vector (31 downto 0);
ALUresult_out : out std_logic_vector (31 downto 0);
control_out : out std_logic_vector (7 downto 0);
instruction_in : in std_logic_vector (31 downto 0);
instruction_out : out std_logic_vector (31 downto 0));
end component;

component Reg_MEM_WB is
port(
clk : in std_logic;
dout_in, ALUresult_in: in std_logic_vector (31 downto 0);
control_in : std_logic_vector (7 downto 0);
dout_out, ALUresult_out : out std_logic_vector (31 downto 0);
control_out : out std_logic_vector (7 downto 0);
instruction_in : in std_logic_vector (31 downto 0);
instruction_out : out std_logic_vector (31 downto 0));
end component;

component forwarding_unit is
	port (id_ex_rs, id_ex_rt, ex_mem_rd, mem_wb_rd : in std_logic_vector (4 downto 0);
		ex_mem_we, mem_wb_we : in std_logic;
		forwardA, forwardB : out std_logic_vector(1 downto 0)
	);
end component;

-------- IFetch Stage Signals ------------------------------------
signal clk_not : std_logic;
signal pc_reg, pc_nal, pc_reg_temp, IF_PC: std_logic_vector (31 downto 0);
signal pc_next_temp, pc_next, pc_four : std_logic_vector(31 downto 0);
signal IF_instruction, ID_instruction : std_logic_vector (31 downto 0);



---------------- Decode/Reg Stage SIGNALS-------------------------------

signal ID_PC : std_logic_vector (31 downto 0);
signal Rw_out, Rt_in, Rs_in, Rd_in, Rt_out, Rs_out, Rd_out : std_logic_vector(4 downto 0);
signal shamt_in, shamt_out : std_logic_vector (4 downto 0);
signal imm16_in, imm16_out : std_logic_vector (15 downto 0);
signal ID_control, control_temp : std_logic_vector(7 downto 0);



 ----------- EX Stage SIGNALS ---------------
signal ID_ALUop, EX_ALUop, ALUop_temp: std_logic_vector(5 downto 0);
signal EX_control : std_logic_vector (7 downto 0);
signal EX_busB, ID_busB : std_logic_vector(31 downto 0);
signal carryout, overflow, zero : std_logic;
signal  ID_busA, ID_busA_NAL, EX_busA, instrExt, aluB : std_logic_vector (31 downto 0);
signal  MEM_busW : std_logic_vector (31 downto 0);
signal EX_ALUresult, MEM_ALUresult : std_logic_vector (31 downto 0);
signal EX_instruction : std_logic_vector (31 downto 0);

------------------------ Mem Stage SIGNALS -------------------------------------

signal not_WE : std_logic;
signal MEM_control : std_logic_vector (7 downto 0);
signal MEM_dout, WB_din : std_logic_vector(31 downto 0);
signal WB_busW : std_logic_vector(31 downto 0);
signal MEM_busB : std_logic_vector (31 downto 0);
signal MEM_instruction : std_logic_vector (31 downto 0);


-----------WB STAGE SIGNALS ---------------------------
signal WB_control : std_logic_vector (7 downto 0);
signal WB_ALUresult : std_logic_vector (31 downto 0);
signal WB_instruction : std_logic_vector (31 downto 0);

signal forwardA, forwardB : std_logic_vector(1 downto 0);

begin

-- START OF IFETCH PHASE --------------------------------------------------------------------------------------------------------------------------------
	NOT_CLK_GEN : not_gate port map(clk, clk_not); -- create not of clock for reg signals
	
	--M0: mux_32 port map(pc_init, pc_next_temp, X"00400024", pc_nal);

	PC_NEXT_CALC: alu_32 port map (ID_PC, X"00000004", "100000", "XXXXX", pc_next); -- get pc_next
	
	--M0: mux_32 port map(pc_init, pc_next_temp, pc_four, pc_next);

	PC_Initialization: mux_32 port map(pc_init, pc_next, X"00400020", pc_reg_temp); -- choose between X"00400020" or calcualted next PC

	M1: mux_32 port map(pc_init, pc_reg_temp, X"00400024", pc_reg);

	PC_Register : register_32bit port map(clk, '1', pc_reg, IF_pc);-- register latch to hold next pc

	IFETCH: fetch_pipe generic map(data_file) 
	port map(clk, IF_pc, IF_instruction); -- instruction fetch


-- END OF IFETCH PHASE --
	R0: Reg_IF_ID port map(clk_not, IF_pc, IF_instruction, ID_pc, ID_instruction);
-- START OF REG/DEC Phase--

	I0: Rs_in <= ID_instruction(25 downto 21);
	I1: Rt_in <= ID_instruction(20 downto 16);
	I2: Rd_in <= ID_instruction(15 downto 11);
	I3: shamt_in <= ID_instruction(10 downto 6);
	I5: imm16_in <= ID_instruction(15 downto 0);
	

	CONTROL_GENERATE: ID port map(ID_instruction, control_temp, ID_ALUop); -- generate control signals
	-- order is RegDst, ALUSrc, MemReg, RegWr, MemWr, Branch, Jump, Extop

	MUX2: mux_8 port map(pc_init, control_temp, "XXXXXXXX", ID_control);
	
	MUX1: mux_n 
		generic map (n => 5)
		port map (ID_control(7), Rt_in, Rd_in, Rw_out);  -- choose between Rt and Rd for Rw, which is Rd


	REG: register_32bit_32 port map (clk, ID_control(4), Rw_out, Rs_in, Rt_in, WB_busW, ID_busA, ID_busB); -- 32 bit register, MemReg

	ID_busA_NAL <= ID_busA;

	NextAddress: NAL_pipelined port map(IF_pc, ID_instruction, ID_busA_NAL, ID_busB, pc_next_temp, pc_init); -- next address logic

	


-- END OF REG/DEC PHASE --
	R1: Reg_ID_EX port map(clk_not, shamt_in, imm16_in, ID_control, ID_ALUop, shamt_out, imm16_out, EX_control, EX_ALUop, ID_busA, ID_busB, EX_busA, EX_busB, ID_instruction, EX_instruction);

	FORWARD: forwarding_unit port map(Rs_in, Rt_in, EX_instruction(15 downto 11), MEM_instruction(15 downto 11), EX_control(4), MEM_control(4), forwardA, forwardB);



-- START OF EX PHASE --
	
	
	EXT: extender port map (imm16_out, EX_control(0), instrExt); -- extender for imm16 field

	MUX4: mux_32 port map (EX_control(6), EX_busB, instrExt, aluB); --select ALUSrc from imm16 or busb, control is ALUSrc

	ALU: alu_32 port map (EX_busA, aluB, EX_ALUop, shamt_out, EX_ALUresult, carryout, overflow, zero); -- perform ALU op


-- END OF EX PHASE -- 
	R2 : Reg_EX_MEM port map (clk_not, EX_busB, EX_ALUresult, EX_control, MEM_busB, MEM_ALUresult, MEM_control, EX_instruction, MEM_instruction);


-- START OF MEM PHASE --
	NOT_WE_GENERATE : not_gate port map(MEM_control(3), not_WE); -- make WE and OE opposites
	DMEM: syncram
		generic map (data_file)
		port map( clk, '1', not_WE, MEM_control(3), MEM_ALUresult, MEM_busB, MEM_dout);  -- data memory, control is MemWrite

-- END OF MEM PHASE 

	R3: Reg_MEM_WB port map (clk_not, MEM_dout, MEM_ALUresult, MEM_control, MEM_busW, WB_ALUresult, WB_control, MEM_instruction, WB_instruction);

-- START OF WB PHASE --


	MUX3: mux_32 port map (WB_control(5), WB_ALUresult, MEM_busW, WB_busW);  -- select ALU_out or Mem_out, control is MemReg
	

end structure;
