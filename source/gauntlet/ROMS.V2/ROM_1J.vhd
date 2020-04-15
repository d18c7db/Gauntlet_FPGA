library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;

entity ROM_1J is
port (
	CLK  : in  std_logic;
	ADDR : in  std_logic_vector(14 downto 0);
	DATA : out std_logic_vector(7 downto 0) := (others=>'0')
	);
end entity;

architecture RTL of ROM_1J is
	type ROM_ARRAY is array (0 to 32767) of std_logic_vector(7 downto 0);
	signal ROM : ROM_ARRAY := (
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
		## Atari intellectual property. Please generate this data from your own legally obtained ROMs ##
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00"
	);

	attribute ram_style : string;
	attribute ram_style of ROM : signal is "auto";
begin
	mem_proc : process
	begin
		wait until rising_edge(CLK);
		DATA <= ROM(to_integer(unsigned(ADDR)));
	end process;
end RTL;
