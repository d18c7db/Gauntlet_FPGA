library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;

entity VRAM is
port (
	CK : in  std_logic;
	WE : in  std_logic;
	CE : in  std_logic;
	AD : in  std_logic_vector(11 downto 0);
	DI : in  std_logic_vector( 7 downto 0);
	DO : out std_logic_vector( 7 downto 0)
	);
end entity;

-- TEST RAM
architecture RTL of VRAM is
	type RAM_ARRAY is array (0 to 4095	) of std_logic_vector(7 downto 0);
	signal RAM : RAM_ARRAY:=(others=>(others=>'0'));
	attribute ram_style : string;
	attribute ram_style of RAM : signal is "auto";
begin
	mem_proc_w : process
	begin
		wait until rising_edge(CK);
		if CE = '1' then
			if WE = '1' then
				RAM(to_integer(unsigned(AD))) <= DI;
				DO <= DI;
			else
				DO <= RAM(to_integer(unsigned(AD)));
			end if;
		end if;
	end process;
end RTL;
