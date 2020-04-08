library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;

entity PROM_3E is
port (
	CLK  : in  std_logic;
	ADDR : in  std_logic_vector(7 downto 0);
	DATA : out std_logic_vector(3 downto 0) := (others=>'0')
	);
end entity;

architecture RTL of PROM_3E is
	type ROM_ARRAY is array (0 to 31) of std_logic_vector(3 downto 0);
	signal ROM : ROM_ARRAY := (
		x"A",x"A",x"5",x"A",x"F",x"F",x"5",x"5",x"A",x"A",x"5",x"A",x"F",x"F",x"5",x"5", -- 0x0000
		x"A",x"A",x"5",x"A",x"F",x"F",x"5",x"5",x"A",x"A",x"A",x"A",x"A",x"A",x"A",x"A"  -- 0x0010
	);
	attribute ram_style : string;
	attribute ram_style of ROM : signal is "distributed";
begin
	mem_proc : process
	begin
		wait until rising_edge(CLK);
		if ADDR(7 downto 5) = "000" then
			DATA <= ROM(to_integer(unsigned(ADDR(4 downto 0))));
		else
			DATA <= (others=>'0');
		end if;
	end process;
end RTL;
