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
	use ieee.std_logic_unsigned.all;

library unimacro;
	use unimacro.vcomponents.all;

entity CRAMS is
	port(
		I_MCKR				: in	std_logic;
		I_UDSn				: in	std_logic;
		I_LDSn				: in	std_logic;
		I_CRAMn				: in	std_logic;
		I_BR_Wn				: in	std_logic;
		I_CRA					: in	std_logic_vector( 9 downto 0);
		I_DB					: in	std_logic_vector(15 downto 0);
		O_DB					: out	std_logic_vector(15 downto 0)
	);
end CRAMS;

architecture RTL of CRAMS is
	signal
		sl_CRAM_CS,
		sl_CRAMWRn
								: std_logic := '1';
	signal
		slv_CRAM_WE
								: std_logic_vector(1 downto 0) := (others=>'0');
begin
	------------------------
	-- sheet 15 Color RAM --
	------------------------

	-- BRAM_SINGLE_MACRO: Single Port RAM Spartan-6
	-- Xilinx HDL Language Template, version 14.7
	-- Note - This Unimacro model assumes the port directions to be "downto".
	-----------------------------------------------------------------------
	--  BRAM_SIZE | RW DATA WIDTH | RW Depth | RW ADDR Width | WE Width
	-- ===========|===============|==========|===============|=========
	--   "18Kb"   |     19-36     |    512   |      9-bit    |   4-bit
	--   "18Kb"   |     10-18     |   1024   |     10-bit    |   2-bit
	--    "9Kb"   |     10-18     |    512   |      9-bit    |   2-bit
	--   "18Kb"   |      5-9      |   2048   |     11-bit    |   1-bit
	--    "9Kb"   |      5-9      |   1024   |     10-bit    |   1-bit
	--   "18Kb"   |      3-4      |   4096   |     12-bit    |   1-bit
	--    "9Kb"   |      3-4      |   2048   |     11-bit    |   1-bit
	--   "18Kb"   |        2      |   8192   |     13-bit    |   1-bit
	--   " 9Kb"   |        2      |   4096   |     12-bit    |   1-bit
	--   "18Kb"   |        1      |  16384   |     14-bit    |   1-bit
	--    "9Kb"   |        1      |   8192   |     13-bit    |   1-bit
	-------------------------------------------------------------------

	-- 9L, 9M, 10L, 10M RAM
	p_9L_9M_10L_10M  : BRAM_SINGLE_MACRO
	generic map (
		BRAM_SIZE	=> "18Kb",				-- Target BRAM, "9Kb" or "18Kb"
		DEVICE		=> "SPARTAN6",			-- Target Device: "VIRTEX5", "VIRTEX6", "SPARTAN6"
		READ_WIDTH	=> 16,					-- Valid values are 1-36 (19-36 only valid when BRAM_SIZE="18Kb")
		WRITE_WIDTH => 16,					-- Valid values are 1-36 (19-36 only valid when BRAM_SIZE="18Kb")
		DO_REG		=> 0,						-- Optional output register (0 or 1)
		SRVAL			=> x"000000000",		-- Set/Reset value for port output
		INIT			=> x"000000000",		-- Initial values on output port
		INIT_FILE	=> "NONE",
		WRITE_MODE	=> "WRITE_FIRST"		-- "WRITE_FIRST", "READ_FIRST" or "NO_CHANGE"
	)

	port map (
		DO				=> O_DB,						-- Output data, width defined by READ_WIDTH parameter
		ADDR			=> I_CRA(9 downto 0),		-- Input address, width defined by read/write port depth
		CLK			=> I_MCKR,						-- 1-bit input clock
		DI				=> I_DB,							-- Input data port, width defined by WRITE_WIDTH parameter
		EN				=> sl_CRAM_CS,					-- 1-bit input RAM enable
		REGCE			=> '0',							-- 1-bit input output register enable
		RST			=> '0',							-- 1-bit input reset
		WE				=> slv_CRAM_WE					-- Input write enable, width defined by write port depth
	);

	slv_CRAM_WE <= not (
		(((not I_CRAMn) and I_UDSn) or sl_CRAMWRn) &
		(((not I_CRAMn) and I_LDSn) or sl_CRAMWRn)
	);

	-- gates 7W, 11P
	sl_CRAM_CS	<= not (I_UDSn and I_LDSn and (not I_CRAMn));

	-- gate 7X
	sl_CRAMWRn	<= I_CRAMn or I_BR_Wn;
end RTL;
