------------------------------------------------------------------------------
------------------------------------------------------------------------------
--                                                                          --
-- This is the TOP-Level for TG68K.C to generate 68K Bus signals            --
--                                                                          --
-- Copyright (c) 2021 Tobias Gubener <tobiflex@opencores.org>               -- 
--                                                                          --
-- This source file is free software: you can redistribute it and/or modify --
-- it under the terms of the GNU Lesser General Public License as published --
-- by the Free Software Foundation, either version 3 of the License, or     --
-- (at your option) any later version.                                      --
--                                                                          --
-- This source file is distributed in the hope that it will be useful,      --
-- but WITHOUT ANY WARRANTY; without even the implied warranty of           --
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            --
-- GNU General Public License for more details.                             --
--                                                                          --
-- You should have received a copy of the GNU General Public License        --
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.    --
--                                                                          --
------------------------------------------------------------------------------
------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity TG68K is
generic(
	CPU           : std_logic_vector(1 downto 0):="01"  -- 00->68000  01->68010  11->68020
);
port(
	CLK           : in  std_logic;
	RESET         : in  std_logic;
	HALT          : in  std_logic;
	BERR          : in  std_logic;     -- only 68000 Stackpointer dummy for Atari ST core
	IPL           : in  std_logic_vector( 2 downto 0):="111";
	ADDR          : out std_logic_vector(31 downto 0);
	FC            : out std_logic_vector( 2 downto 0);
	DATAI         : in  std_logic_vector(15 downto 0);
	DATAO         : out std_logic_vector(15 downto 0);

---- bus controll
--	BG            : out std_logic;
--	BR            : in  std_logic := '1';
--	BGACK         : in  std_logic := '1';
-- async interface
	AS            : out std_logic;
	UDS           : out std_logic;
	LDS           : out std_logic;
	RW            : out std_logic;
	DTACK         : in  std_logic;
-- sync interface
	E             : out std_logic;
	VPA           : in  std_logic;
	VMA           : out std_logic
);
end TG68K;

architecture logic of TG68K is

signal data_write  : std_logic_vector(15 downto 0);
signal r_data      : std_logic_vector(15 downto 0);
signal cpuIPL      : std_logic_vector( 2 downto 0);
signal data_akt_s  : std_logic;
signal data_akt_e  : std_logic;
signal as_s        : std_logic;
signal as_e        : std_logic;
signal uds_s       : std_logic;
signal uds_e       : std_logic;
signal lds_s       : std_logic;
signal lds_e       : std_logic;
signal rw_s        : std_logic;
signal rw_e        : std_logic;
signal vpad        : std_logic;
signal waitm       : std_logic;
signal clkena_e    : std_logic;
signal S_state     : std_logic_vector( 1 downto 0);
signal decode      : std_logic;
signal wr          : std_logic;
signal uds_in      : std_logic;
signal lds_in      : std_logic;
signal state       : std_logic_vector( 1 downto 0);
signal clkena      : std_logic;
signal skipFetch   : std_logic;
signal nResetOut   : std_logic;
signal autovector  : std_logic;
signal cpu1reset   : std_logic;

type sync_state_t is (sync0, sync1, sync2, sync3, sync4, sync5, sync6, sync7, sync8, sync9);
signal sync_state : sync_state_t;

begin
	DATAO <= data_write; --  when data_akt_e='1' or data_akt_s='1' else "ZZZZZZZZZZZZZZZZ";
	AS    <= as_s  and as_e;
	RW    <= rw_s  and rw_e;
	UDS   <= uds_s and uds_e;
	LDS   <= lds_s and lds_e;

--	RESET <= '0' when nResetOut='0' else 'Z';
--	HALT  <= '0' when nResetOut='0' else 'Z';
	cpu1reset <= RESET or HALT;

	cpu1 : entity work.TG68KdotC_Kernel
	generic map(
		SR_Read        => 2, --0=>user,   1=>privileged,    2=>switchable with CPU(0)
		VBR_Stackframe => 2, --0=>no,     1=>yes/extended,  2=>switchable with CPU(0)
		extAddr_Mode   => 2, --0=>no,     1=>yes,           2=>switchable with CPU(1)
		MUL_Mode       => 2, --0=>16Bit,  1=>32Bit,         2=>switchable with CPU(1),  3=>no MUL,
		DIV_Mode       => 2, --0=>16Bit,  1=>32Bit,         2=>switchable with CPU(1),  3=>no DIV,
		BitField       => 2, --0=>no,     1=>yes,           2=>switchable with CPU(1)

		BarrelShifter  => 1, --0=>no,     1=>yes,           2=>switchable with CPU(1)  
		MUL_Hardware   => 1  --0=>no,     1=>yes,  
	)
	port map(
		CPU            => CPU,        -- : in std_logic_vector(1 downto 0):="01";  -- 00->68000  01->68010  11->68020
		clk            => CLK,        -- : in std_logic;
		nReset         => cpu1reset,  -- : in std_logic:='1';       --low active
		clkena_in      => clkena,     -- : in std_logic:='1';
		data_in        => r_data,     -- : in std_logic_vector(15 downto 0);
		IPL            => cpuIPL,     -- : in std_logic_vector(2 downto 0):="111";
		IPL_autovector => '1',
		addr_out       => ADDR,       -- : buffer std_logic_vector(31 downto 0);
		berr           => BERR,       -- : in std_logic:='0';     -- only 68000 Stackpointer dummy for Atari ST core
		FC             => FC,         -- : out std_logic_vector(2 downto 0);
		data_write     => data_write, -- : out std_logic_vector(15 downto 0);
		busstate       => state,      -- : buffer std_logic_vector(1 downto 0);
		nWr            => wr,         -- : out std_logic;
		nUDS           => uds_in,     -- : out std_logic;
		nLDS           => lds_in,     -- : out std_logic;
		nResetOut      => nResetOut,  -- : out std_logic;
		skipFetch      => skipFetch   -- : out std_logic
	);

process (CLK)
begin
	if falling_edge(CLK) then
		if sync_state=sync5 then
			E <= '1';
		end if;
		if sync_state=sync9 then
			E <= '0';
		end if;
	end if;

	if rising_edge(CLK) then
		case sync_state IS
		when sync0  => sync_state <= sync1;
		when sync1  => sync_state <= sync2;
		when sync2  => sync_state <= sync3;
		when sync3  => sync_state <= sync4;
				VMA <= VPA;
				vpad <= VPA;
				autovector <= not VPA;
		when sync4  => sync_state <= sync5;
		when sync5  => sync_state <= sync6;
		when sync6  => sync_state <= sync7;
		when sync7  => sync_state <= sync8;
		when sync8  => sync_state <= sync9;
		when others => sync_state <= sync0;
						VMA <= '1';
		end case;
	end if;
end process;

process (state, clkena_e, skipFetch)
begin
	if state="01" or clkena_e='1' or skipFetch='1' then
		clkena <= '1';
	else 
		clkena <= '0';
	end if;
end process;

process (CLK, RESET, state, as_s, as_e, rw_s, rw_e, uds_s, uds_e, lds_s, lds_e)
begin
	if RESET='0' then
		S_state   <= "11";
		as_s  <= '1';
		rw_s  <= '1';
		uds_s <= '1';
		lds_s <= '1';
		data_akt_s <= '0';
	elsif rising_edge(CLK) then
		as_s  <= '1';
		rw_s  <= '1';
		uds_s <= '1';
		lds_s <= '1';
		data_akt_s <= '0';
		case S_state is
		when "00" =>
			if state/="01" and skipFetch='0' then
				if wr='1' then
					uds_s <= uds_in;
					lds_s <= lds_in;
				end if;
				as_s    <= '0';
				rw_s    <= wr;
				S_state <= "01";
			end if;
		when "01" =>
			as_s    <= '0';
			rw_s    <= wr;
			uds_s   <= uds_in;
			lds_s   <= lds_in;
			S_state <= "10";
		when "10" =>
			data_akt_s <= not wr;
			r_data <= DATAI;
			if waitm='0' or (vpad='0' and sync_state=sync9) then
				S_state <= "11";
			else
				as_s  <= '0';
				rw_s  <= wr;
				uds_s <= uds_in;
				lds_s <= lds_in;
			end if;
		when "11" =>
			S_state <= "00";
		when others => null;
		end case;
	end if;

	if RESET='0' then
		as_e       <= '1';
		rw_e       <= '1';
		uds_e      <= '1';
		lds_e      <= '1';
		clkena_e   <= '0';
		data_akt_e <= '0';
	elsif falling_edge(CLK) then
		as_e       <= '1';
		rw_e       <= '1';
		uds_e      <= '1';
		lds_e      <= '1';
		clkena_e   <= '0';
		data_akt_e <= '0';
		case S_state is
		when "00" =>
			cpuIPL     <= IPL; --for HALT command
		when "01" =>
			data_akt_e <= not wr;
			as_e       <= '0';
			rw_e       <= wr;
			uds_e      <= uds_in;
			lds_e      <= lds_in;
		when "10" =>
			rw_e       <= wr;
			data_akt_e <= not wr;
			cpuIPL     <= IPL;
			waitm      <= DTACK;
		when others =>
			clkena_e   <= '1';
		end case;
	end if;
end process;
end;
