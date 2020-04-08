--	(c) 2020 d18c7db(a)hotmail
--
--	This program is free software; you can redistribute it and/or modify it under
--	the terms of the GNU General Public License version 3 or, at your option,
--	any later version as published by the Free Software Foundation.
--
--	This program is distributed in the hope that it will be useful,
--	but WITHOUT ANY WARRANTY; without even the implied warranty of
--	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
--
-- For full details, see the GNU General Public License at www.gnu.org/licenses
--

library ieee;
	use ieee.std_logic_1164.all;

-- ROMs organized as 512K x 16
entity ROMS_EXT is
	port(
		CLK		: in	std_logic;
		ENA		: in	std_logic;
		ADDR		: in	std_logic_vector(18 downto 0);
		DATA		: out	std_logic_vector(15 downto 0)
	);
end ROMS_EXT;

architecture RTL of ROMS_EXT is
	signal
		slv_ROM_1A,
		slv_ROM_1L,
		slv_ROM_2A,
		slv_ROM_2L,
		slv_ROM_1B,
		slv_ROM_1MN,
		slv_ROM_2B,
		slv_ROM_2MN,
		slv_ROM_7A,
		slv_ROM_7B,
		slv_ROM_9A,
		slv_ROM_9B,
		slv_ROM_10A,
		slv_ROM_10B,
		slv_ROM_16R,
		slv_ROM_16S
								: std_logic_vector( 7 downto 0) := (others=>'0');
begin
		-- top 4 address bits map each ROM into external memory space
	DATA <=
		slv_ROM_1L  & slv_ROM_1A  when ADDR(18 downto 15)=x"0" and ENA = '1' else -- 00000-07FFF 32K-32K
		slv_ROM_1MN & slv_ROM_1B  when ADDR(18 downto 15)=x"1" and ENA = '1' else -- 08000-0FFFF 32K-32K
		slv_ROM_2L  & slv_ROM_2A  when ADDR(18 downto 15)=x"2" and ENA = '1' else -- 10000-17FFF 32K-32K
		slv_ROM_2MN & slv_ROM_2B  when ADDR(18 downto 15)=x"3" and ENA = '1' else -- 18000-1FFFF 32K-32K

		slv_ROM_7A  & slv_ROM_7B  when ADDR(18 downto 15)=x"4" and ENA = '1' else -- 20000-27FFF 32K-32K
		slv_ROM_9A  & slv_ROM_9B  when ADDR(18 downto 15)=x"5" and ENA = '1' else -- 28000-2FFFF 32K-32K
		slv_ROM_10A & slv_ROM_10B when ADDR(18 downto 15)=x"6" and ENA = '1' else -- 30000-33FFF 16K-16K

		slv_ROM_16R & slv_ROM_16S when ADDR(18 downto 15)=x"7" and ENA = '1' else -- 34000-3BFFF 16K-32K
		(others=>'1');

	-- VIDEO ROMS
	ROM_1A  : entity work.ROM_1A  port map ( CLK=>CLK, DATA=>slv_ROM_1A , ADDR=>ADDR(14 downto 0) );
	ROM_1L  : entity work.ROM_1L  port map ( CLK=>CLK, DATA=>slv_ROM_1L , ADDR=>ADDR(14 downto 0) );
	ROM_1B  : entity work.ROM_1B  port map ( CLK=>CLK, DATA=>slv_ROM_1B , ADDR=>ADDR(14 downto 0) );
	ROM_1MN : entity work.ROM_1MN port map ( CLK=>CLK, DATA=>slv_ROM_1MN, ADDR=>ADDR(14 downto 0) );
	ROM_2A  : entity work.ROM_2A  port map ( CLK=>CLK, DATA=>slv_ROM_2A , ADDR=>ADDR(14 downto 0) );
	ROM_2L  : entity work.ROM_2L  port map ( CLK=>CLK, DATA=>slv_ROM_2L , ADDR=>ADDR(14 downto 0) );
	ROM_2B  : entity work.ROM_2B  port map ( CLK=>CLK, DATA=>slv_ROM_2B , ADDR=>ADDR(14 downto 0) );
	ROM_2MN : entity work.ROM_2MN port map ( CLK=>CLK, DATA=>slv_ROM_2MN, ADDR=>ADDR(14 downto 0) );

	-- MAIN 68K ROMS
	ROM_7A  : entity work.ROM_7A  port map ( CLK=>CLK, DATA=>slv_ROM_7A,  ADDR=>ADDR(14 downto 0) );
	ROM_7B  : entity work.ROM_7B  port map ( CLK=>CLK, DATA=>slv_ROM_7B,  ADDR=>ADDR(14 downto 0) );
	ROM_9A  : entity work.ROM_9A  port map ( CLK=>CLK, DATA=>slv_ROM_9A,  ADDR=>ADDR(14 downto 0) );
	ROM_9B  : entity work.ROM_9B  port map ( CLK=>CLK, DATA=>slv_ROM_9B,  ADDR=>ADDR(14 downto 0) );
	ROM_10A : entity work.ROM_10A port map ( CLK=>CLK, DATA=>slv_ROM_10A, ADDR=>ADDR(13 downto 0) );
	ROM_10B : entity work.ROM_10B port map ( CLK=>CLK, DATA=>slv_ROM_10B, ADDR=>ADDR(13 downto 0) );

	-- AUDIO 6502 ROMS
	ROM_16R : entity work.ROM_16R port map ( CLK=>CLK, DATA=>slv_ROM_16R, ADDR=>ADDR(13 downto 0) );
	ROM_16S : entity work.ROM_16S port map ( CLK=>CLK, DATA=>slv_ROM_16S, ADDR=>ADDR(14 downto 0) );
end RTL;
