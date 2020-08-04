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
-- This file is a wrapper around the TG68KdotC_Kernel
-- to adapt it to the real chip pinout and signal timings

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity TG68K is
port(
	CLK           : in  std_logic;
	RST           : in  std_logic;
	clkena_ext    : in  std_logic;
	DTACK         : in  std_logic;
	VPA           : in  std_logic;
	IPL           : in  std_logic_vector( 2 downto 0);
	DI            : in  std_logic_vector(15 downto 0);

	AS            : out std_logic;
	UDS           : out std_logic;
	LDS           : out std_logic;
	WR            : out std_logic;
	FC            : out std_logic_vector( 2 downto 0);
	ADDR          : out std_logic_vector(23 downto 0);
	DO            : out std_logic_vector(15 downto 0);

	cpusel        : in  std_logic_vector( 1 downto 0);
	nRSTout       : out std_logic
);
end TG68K;

architecture logic of TG68K is
	signal clk_ena     : std_logic:='0';
	signal as_ena      : std_logic:='0';
	signal nUDS        : std_logic:='0';
	signal nLDS        : std_logic:='0';
	signal nWR         : std_logic:='0';
	signal clkena_in   : std_logic:='0';
	signal skipFetch   : std_logic:='0';
	signal phase       : std_logic_vector( 1 downto 0):=(others=>'0');
	signal busstate    : std_logic_vector( 1 downto 0):=(others=>'0');
	signal data_latch  : std_logic_vector(15 downto 0):=(others=>'0');
	signal addr_out    : std_logic_vector(31 downto 0):=(others=>'0');
	signal data_out    : std_logic_vector(15 downto 0):=(others=>'0');

begin

	ADDR <= addr_out(23 downto 0);
	DO<=data_out;
	u_TG68K : entity work.TG68KdotC_Kernel
	generic map(
		SR_Read        => 2,   --0=>user,   1=>privileged,    2=>switchable with CPU(0)
		VBR_Stackframe => 2,   --0=>no,     1=>yes/extended,  2=>switchable with CPU(0)
		extAddr_Mode   => 2,   --0=>no,     1=>yes,           2=>switchable with CPU(1)
		MUL_Mode       => 2,   --0=>16Bit,  1=>32Bit,         2=>switchable with CPU(1),  3=>no MUL,
		DIV_Mode       => 2,   --0=>16Bit,  1=>32Bit,         2=>switchable with CPU(1),  3=>no DIV,
		BitField       => 2    --0=>no,     1=>yes,           2=>switchable with CPU(1)
	)
	port map(
		clk            => CLK,
		nReset         => RST,
		clkena_in      => clkena_in,
		data_in        => data_latch,
		IPL            => IPL,
		IPL_autovector => '1',
		addr_out       => addr_out,
		data_write     => data_out,
		nWr            => nWR,
		nUDS           => nUDS,
		nLDS           => nLDS,
		nResetOut      => nRSTout,
		FC             => FC,

		CPU            => cpusel,
		busstate       => busstate,
		skipFetch      => skipFetch,
		VBR_out        => open
	);

	clkena_in <= '1' when clkena_ext='1' and (busstate="01" or clk_ena='1') else '0';

	AS  <= '1' when busstate="01" else as_ena or skipFetch;
	WR  <= '1' when busstate="01" else as_ena or nWR;
	UDS <= '1' when busstate="01" else as_ena or nUDS;
	LDS <= '1' when busstate="01" else as_ena or nLDS;

	process
	begin
		wait until rising_edge(CLK);
		if RST='0' then
			phase   <= "00";
			clk_ena <= '0';
			as_ena  <= '1';
		else
			clk_ena <= '0';
			as_ena  <= '1';
			case phase is
				when "00" =>
					if busstate/="01" then
						phase <= "01";
						as_ena <= '0';
					end if;
				when "01" =>
					phase <= "10";
					as_ena <= '0';
				when "10" =>
					if DTACK='0' or VPA='0' or skipFetch = '1' then
						phase <= "11";
						data_latch <= DI;
					else
						as_ena  <= '0';
					end if;
				when "11" =>
					phase <= "00";
					clk_ena <= '1';
				when others => null;
			end case;
		end if;
	end process;
end;
