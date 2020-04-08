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

library unisim;
	use unisim.vcomponents.all;

library unimacro;
	use unimacro.vcomponents.all;

entity VRAMS is
	port(
		I_CK					: in	std_logic;
		I_VRAMWE				: in	std_logic;
		I_SELB				: in	std_logic;
		I_SELA				: in	std_logic;
		I_UDSn				: in	std_logic;
		I_LDSn				: in	std_logic;
		I_VRA					: in	std_logic_vector(11 downto 0);
		I_VRD					: in	std_logic_vector(15 downto 0);
		O_VRD					: out	std_logic_vector(15 downto 0)
	);
end VRAMS;

architecture RTL of VRAMS is
	signal
		sl_PF_HI,
		sl_MO_HI,
		sl_AL_HI,
		sl_PF_LO,
		sl_MO_LO,
		sl_AL_LO,
		sl_PF_CSn,
		sl_MO_CSn,
		sl_AL_CSn
								: std_logic := '1';
	signal
		sl_VRAMWE
								: std_logic_vector( 0 downto 0) := (others=>'0');
	signal
		slv_PF,
		slv_MO,
		slv_AL
								: std_logic_vector(15 downto 0) := (others=>'0');
begin
	-------------------------
	-- sheet 9 RAM decoder --
	-------------------------
	-- 9C decoders
	sl_PF_CSn <= (     I_SELB ) or (     I_SELA );
	sl_MO_CSn <= (     I_SELB ) or ( not I_SELA );
	sl_AL_CSn <= ( not I_SELB ) or (     I_SELA );

	-- Xilinx Block RAM chip selects
	sl_PF_HI <= not (I_UDSn or sl_PF_CSn);
	sl_MO_HI <= not (I_UDSn or sl_MO_CSn);
	sl_AL_HI <= not (I_UDSn or sl_AL_CSn);

	sl_PF_LO <= not (I_LDSn or sl_PF_CSn);
	sl_MO_LO <= not (I_LDSn or sl_MO_CSn);
	sl_AL_LO <= not (I_LDSn or sl_AL_CSn);

	-----------------------
	-- sheet 8 RAM banks --
	-----------------------
	sl_VRAMWE(0) <= I_VRAMWE;

	O_VRD <=
		slv_PF when sl_PF_CSn = '0' else
		slv_MO when sl_MO_CSn = '0' else
		slv_AL when sl_AL_CSn = '0' else
--		slv_AL when sl_AL_CSn = '0' and (I_VRA < x"800" or I_VRA > x"F69") else 	-- disables reads from alphanumerics range 905000-905BB0
		(others=>'Z'); -- floating

	-- BRAM_SINGLE_MACRO: Single Port RAM Spartan-6
	-- Xilinx HDL Language Template, version 14.7
	-- Note - This Unimacro model assumes the port directions to be "downto".
	-----------------------------------------------------------------------
	--  BRAM_SIZE | RW DATA WIDTH | RW Depth | RW ADDR Width | WE Width
	-- ===========|===============|==========|===============|=========
	--   "18Kb"   |     19-36     |    512   |      9-bit    |   4-bit
	--    "9Kb"   |     10-18     |    512   |      9-bit    |   2-bit
	--   "18Kb"   |     10-18     |   1024   |     10-bit    |   2-bit
	--    "9Kb"   |      5-9      |   1024   |     10-bit    |   1-bit
	--   "18Kb"   |      5-9      |   2048   |     11-bit    |   1-bit
	--    "9Kb"   |      3-4      |   2048   |     11-bit    |   1-bit
	--   "18Kb"   |      3-4      |   4096   |     12-bit    |   1-bit
	--   " 9Kb"   |        2      |   4096   |     12-bit    |   1-bit
	--   "18Kb"   |        2      |   8192   |     13-bit    |   1-bit
	--    "9Kb"   |        1      |   8192   |     13-bit    |   1-bit
	--   "18Kb"   |        1      |  16384   |     14-bit    |   1-bit
	-------------------------------------------------------------------

	-- PF video RAMs 6D, 7D, 6J, 7J
	p_7J_RAM : BRAM_SINGLE_MACRO
	generic map (
		BRAM_SIZE	=> "18Kb",					-- Target BRAM, "9Kb" or "18Kb"
		DEVICE		=> "SPARTAN6",				-- Target Device: "VIRTEX5", "VIRTEX6", "SPARTAN6"
		READ_WIDTH	=> 4,							-- Valid values are 1-36 (19-36 only valid when BRAM_SIZE="18Kb")
		WRITE_WIDTH => 4,							-- Valid values are 1-36 (19-36 only valid when BRAM_SIZE="18Kb")
		DO_REG		=> 0,							-- Optional output register (0 or 1)
		SRVAL			=> x"000000000",			-- Set/Reset value for port output
		INIT			=> x"000000000",			-- Initial values on output port
		INIT_FILE	=> "NONE",
		WRITE_MODE	=> "WRITE_FIRST"			-- "WRITE_FIRST", "READ_FIRST" or "NO_CHANGE"
	)

	port map (
		DO				=> slv_PF(3 downto 0),	-- Output data, width defined by READ_WIDTH parameter
		ADDR			=> I_VRA,					-- Input address, width defined by read/write port depth
		CLK			=> I_CK,						-- 1-bit input clock
		DI				=> I_VRD(3 downto 0),	-- Input data port, width defined by WRITE_WIDTH parameter
		EN				=> sl_PF_LO,				-- 1-bit input RAM enable
		REGCE			=> '0',						-- 1-bit input output register enable
		RST			=> '0',						-- 1-bit input reset
		WE				=> sl_VRAMWE				-- Input write enable, width defined by write port depth
	);

	p_6J_RAM : BRAM_SINGLE_MACRO
	generic map (
		BRAM_SIZE	=> "18Kb",					-- Target BRAM, "9Kb" or "18Kb"
		DEVICE		=> "SPARTAN6",				-- Target Device: "VIRTEX5", "VIRTEX6", "SPARTAN6"
		READ_WIDTH	=> 4,							-- Valid values are 1-36 (19-36 only valid when BRAM_SIZE="18Kb")
		WRITE_WIDTH => 4,							-- Valid values are 1-36 (19-36 only valid when BRAM_SIZE="18Kb")
		DO_REG		=> 0,							-- Optional output register (0 or 1)
		SRVAL			=> x"000000000",			-- Set/Reset value for port output
		INIT			=> x"000000000",			-- Initial values on output port
		INIT_FILE	=> "NONE",
		WRITE_MODE	=> "WRITE_FIRST"			-- "WRITE_FIRST", "READ_FIRST" or "NO_CHANGE"
	)

	port map (
		DO				=> slv_PF(7 downto 4),	-- Output data, width defined by READ_WIDTH parameter
		ADDR			=> I_VRA,					-- Input address, width defined by read/write port depth
		CLK			=> I_CK,						-- 1-bit input clock
		DI				=> I_VRD(7 downto 4),	-- Input data port, width defined by WRITE_WIDTH parameter
		EN				=> sl_PF_LO,				-- 1-bit input RAM enable
		REGCE			=> '0',						-- 1-bit input output register enable
		RST			=> '0',						-- 1-bit input reset
		WE				=> sl_VRAMWE				-- Input write enable, width defined by write port depth
	);

	p_7D_RAM : BRAM_SINGLE_MACRO
	generic map (
		BRAM_SIZE	=> "18Kb",					-- Target BRAM, "9Kb" or "18Kb"
		DEVICE		=> "SPARTAN6",				-- Target Device: "VIRTEX5", "VIRTEX6", "SPARTAN6"
		READ_WIDTH	=> 4,							-- Valid values are 1-36 (19-36 only valid when BRAM_SIZE="18Kb")
		WRITE_WIDTH => 4,							-- Valid values are 1-36 (19-36 only valid when BRAM_SIZE="18Kb")
		DO_REG		=> 0,							-- Optional output register (0 or 1)
		SRVAL			=> x"000000000",			-- Set/Reset value for port output
		INIT			=> x"000000000",			-- Initial values on output port
		INIT_FILE	=> "NONE",
		WRITE_MODE	=> "WRITE_FIRST"			-- "WRITE_FIRST", "READ_FIRST" or "NO_CHANGE"
	)

	port map (
		DO				=> slv_PF(11 downto 8),	-- Output data, width defined by READ_WIDTH parameter
		ADDR			=> I_VRA,					-- Input address, width defined by read/write port depth
		CLK			=> I_CK,						-- 1-bit input clock
		DI				=> I_VRD(11 downto 8),	-- Input data port, width defined by WRITE_WIDTH parameter
		EN				=> sl_PF_HI,				-- 1-bit input RAM enable
		REGCE			=> '0',						-- 1-bit input output register enable
		RST			=> '0',						-- 1-bit input reset
		WE				=> sl_VRAMWE				-- Input write enable, width defined by write port depth
	);

	p_6D_RAM : BRAM_SINGLE_MACRO
	generic map (
		BRAM_SIZE	=> "18Kb",					-- Target BRAM, "9Kb" or "18Kb"
		DEVICE		=> "SPARTAN6",				-- Target Device: "VIRTEX5", "VIRTEX6", "SPARTAN6"
		READ_WIDTH	=> 4,							-- Valid values are 1-36 (19-36 only valid when BRAM_SIZE="18Kb")
		WRITE_WIDTH => 4,							-- Valid values are 1-36 (19-36 only valid when BRAM_SIZE="18Kb")
		DO_REG		=> 0,							-- Optional output register (0 or 1)
		SRVAL			=> x"000000000",			-- Set/Reset value for port output
		INIT			=> x"000000000",			-- Initial values on output port
		INIT_FILE	=> "NONE",
		WRITE_MODE	=> "WRITE_FIRST"			-- "WRITE_FIRST", "READ_FIRST" or "NO_CHANGE"
	)

	port map (
		DO				=> slv_PF(15 downto 12),-- Output data, width defined by READ_WIDTH parameter
		ADDR			=> I_VRA,					-- Input address, width defined by read/write port depth
		CLK			=> I_CK,						-- 1-bit input clock
		DI				=> I_VRD(15 downto 12),	-- Input data port, width defined by WRITE_WIDTH parameter
		EN				=> sl_PF_HI,				-- 1-bit input RAM enable
		REGCE			=> '0',						-- 1-bit input output register enable
		RST			=> '0',						-- 1-bit input reset
		WE				=> sl_VRAMWE				-- Input write enable, width defined by write port depth
	);

	-- MO video RAMs 6C, 7C, 6F, 7F
	p_7F_RAM : BRAM_SINGLE_MACRO
	generic map (
		BRAM_SIZE	=> "18Kb",					-- Target BRAM, "9Kb" or "18Kb"
		DEVICE		=> "SPARTAN6",				-- Target Device: "VIRTEX5", "VIRTEX6", "SPARTAN6"
		READ_WIDTH	=> 4,							-- Valid values are 1-36 (19-36 only valid when BRAM_SIZE="18Kb")
		WRITE_WIDTH => 4,							-- Valid values are 1-36 (19-36 only valid when BRAM_SIZE="18Kb")
		DO_REG		=> 0,							-- Optional output register (0 or 1)
		SRVAL			=> x"000000000",			-- Set/Reset value for port output
		INIT			=> x"000000000",			-- Initial values on output port
		INIT_FILE	=> "NONE",
		WRITE_MODE	=> "WRITE_FIRST"			-- "WRITE_FIRST", "READ_FIRST" or "NO_CHANGE"
	)

	port map (
		DO				=> slv_MO(3 downto 0),	-- Output data, width defined by READ_WIDTH parameter
		ADDR			=> I_VRA,					-- Input address, width defined by read/write port depth
		CLK			=> I_CK,						-- 1-bit input clock
		DI				=> I_VRD(3 downto 0),	-- Input data port, width defined by WRITE_WIDTH parameter
		EN				=> sl_MO_LO,				-- 1-bit input RAM enable
		REGCE			=> '0',						-- 1-bit input output register enable
		RST			=> '0',						-- 1-bit input reset
		WE				=> sl_VRAMWE				-- Input write enable, width defined by write port depth
	);

	p_6F_RAM : BRAM_SINGLE_MACRO
	generic map (
		BRAM_SIZE	=> "18Kb",					-- Target BRAM, "9Kb" or "18Kb"
		DEVICE		=> "SPARTAN6",				-- Target Device: "VIRTEX5", "VIRTEX6", "SPARTAN6"
		READ_WIDTH	=> 4,							-- Valid values are 1-36 (19-36 only valid when BRAM_SIZE="18Kb")
		WRITE_WIDTH => 4,							-- Valid values are 1-36 (19-36 only valid when BRAM_SIZE="18Kb")
		DO_REG		=> 0,							-- Optional output register (0 or 1)
		SRVAL			=> x"000000000",			-- Set/Reset value for port output
		INIT			=> x"000000000",			-- Initial values on output port
		INIT_FILE	=> "NONE",
		WRITE_MODE	=> "WRITE_FIRST"			-- "WRITE_FIRST", "READ_FIRST" or "NO_CHANGE"
	)

	port map (
		DO				=> slv_MO(7 downto 4),	-- Output data, width defined by READ_WIDTH parameter
		ADDR			=> I_VRA,					-- Input address, width defined by read/write port depth
		CLK			=> I_CK,						-- 1-bit input clock
		DI				=> I_VRD(7 downto 4),	-- Input data port, width defined by WRITE_WIDTH parameter
		EN				=> sl_MO_LO,				-- 1-bit input RAM enable
		REGCE			=> '0',						-- 1-bit input output register enable
		RST			=> '0',						-- 1-bit input reset
		WE				=> sl_VRAMWE				-- Input write enable, width defined by write port depth
	);

	p_7C_RAM : BRAM_SINGLE_MACRO
	generic map (
		BRAM_SIZE	=> "18Kb",					-- Target BRAM, "9Kb" or "18Kb"
		DEVICE		=> "SPARTAN6",				-- Target Device: "VIRTEX5", "VIRTEX6", "SPARTAN6"
		READ_WIDTH	=> 4,							-- Valid values are 1-36 (19-36 only valid when BRAM_SIZE="18Kb")
		WRITE_WIDTH => 4,							-- Valid values are 1-36 (19-36 only valid when BRAM_SIZE="18Kb")
		DO_REG		=> 0,							-- Optional output register (0 or 1)
		SRVAL			=> x"000000000",			-- Set/Reset value for port output
		INIT			=> x"000000000",			-- Initial values on output port
		INIT_FILE	=> "NONE",
		WRITE_MODE	=> "WRITE_FIRST"			-- "WRITE_FIRST", "READ_FIRST" or "NO_CHANGE"
	)

	port map (
		DO				=> slv_MO(11 downto 8),	-- Output data, width defined by READ_WIDTH parameter
		ADDR			=> I_VRA,					-- Input address, width defined by read/write port depth
		CLK			=> I_CK,						-- 1-bit input clock
		DI				=> I_VRD(11 downto 8),	-- Input data port, width defined by WRITE_WIDTH parameter
		EN				=> sl_MO_HI,				-- 1-bit input RAM enable
		REGCE			=> '0',						-- 1-bit input output register enable
		RST			=> '0',						-- 1-bit input reset
		WE				=> sl_VRAMWE				-- Input write enable, width defined by write port depth
	);

	p_6C_RAM : BRAM_SINGLE_MACRO
	generic map (
		BRAM_SIZE	=> "18Kb",					-- Target BRAM, "9Kb" or "18Kb"
		DEVICE		=> "SPARTAN6",				-- Target Device: "VIRTEX5", "VIRTEX6", "SPARTAN6"
		READ_WIDTH	=> 4,							-- Valid values are 1-36 (19-36 only valid when BRAM_SIZE="18Kb")
		WRITE_WIDTH => 4,							-- Valid values are 1-36 (19-36 only valid when BRAM_SIZE="18Kb")
		DO_REG		=> 0,							-- Optional output register (0 or 1)
		SRVAL			=> x"000000000",			-- Set/Reset value for port output
		INIT			=> x"000000000",			-- Initial values on output port
		INIT_FILE	=> "NONE",
		WRITE_MODE	=> "WRITE_FIRST"			-- "WRITE_FIRST", "READ_FIRST" or "NO_CHANGE"
	)

	port map (
		DO				=> slv_MO(15 downto 12),-- Output data, width defined by READ_WIDTH parameter
		ADDR			=> I_VRA,					-- Input address, width defined by read/write port depth
		CLK			=> I_CK,						-- 1-bit input clock
		DI				=> I_VRD(15 downto 12),	-- Input data port, width defined by WRITE_WIDTH parameter
		EN				=> sl_MO_HI,				-- 1-bit input RAM enable
		REGCE			=> '0',						-- 1-bit input output register enable
		RST			=> '0',						-- 1-bit input reset
		WE				=> sl_VRAMWE				-- Input write enable, width defined by write port depth
	);

	-- AL video RAMs 6E, 7E, 6K, 7K
	p_7K_RAM : BRAM_SINGLE_MACRO
	generic map (
		BRAM_SIZE	=> "18Kb",					-- Target BRAM, "9Kb" or "18Kb"
		DEVICE		=> "SPARTAN6",				-- Target Device: "VIRTEX5", "VIRTEX6", "SPARTAN6"
		READ_WIDTH	=> 4,							-- Valid values are 1-36 (19-36 only valid when BRAM_SIZE="18Kb")
		WRITE_WIDTH => 4,							-- Valid values are 1-36 (19-36 only valid when BRAM_SIZE="18Kb")
		DO_REG		=> 0,							-- Optional output register (0 or 1)
		SRVAL			=> x"000000000",			-- Set/Reset value for port output
		INIT			=> x"000000000",			-- Initial values on output port
		INIT_FILE	=> "NONE",
		WRITE_MODE	=> "WRITE_FIRST"			-- "WRITE_FIRST", "READ_FIRST" or "NO_CHANGE"
	)

	port map (
		DO				=> slv_AL(3 downto 0),	-- Output data, width defined by READ_WIDTH parameter
		ADDR			=> I_VRA,					-- Input address, width defined by read/write port depth
		CLK			=> I_CK,						-- 1-bit input clock
		DI				=> I_VRD(3 downto 0),	-- Input data port, width defined by WRITE_WIDTH parameter
		EN				=> sl_AL_LO,				-- 1-bit input RAM enable
		REGCE			=> '0',						-- 1-bit input output register enable
		RST			=> '0',						-- 1-bit input reset
		WE				=> sl_VRAMWE				-- Input write enable, width defined by write port depth
	);

	p_6K_RAM : BRAM_SINGLE_MACRO
	generic map (
		BRAM_SIZE	=> "18Kb",					-- Target BRAM, "9Kb" or "18Kb"
		DEVICE		=> "SPARTAN6",				-- Target Device: "VIRTEX5", "VIRTEX6", "SPARTAN6"
		READ_WIDTH	=> 4,							-- Valid values are 1-36 (19-36 only valid when BRAM_SIZE="18Kb")
		WRITE_WIDTH => 4,							-- Valid values are 1-36 (19-36 only valid when BRAM_SIZE="18Kb")
		DO_REG		=> 0,							-- Optional output register (0 or 1)
		SRVAL			=> x"000000000",			-- Set/Reset value for port output
		INIT			=> x"000000000",			-- Initial values on output port
		INIT_FILE	=> "NONE",
		WRITE_MODE	=> "WRITE_FIRST"			-- "WRITE_FIRST", "READ_FIRST" or "NO_CHANGE"
	)

	port map (
		DO				=> slv_AL(7 downto 4),	-- Output data, width defined by READ_WIDTH parameter
		ADDR			=> I_VRA,					-- Input address, width defined by read/write port depth
		CLK			=> I_CK,						-- 1-bit input clock
		DI				=> I_VRD(7 downto 4),	-- Input data port, width defined by WRITE_WIDTH parameter
		EN				=> sl_AL_LO,				-- 1-bit input RAM enable
		REGCE			=> '0',						-- 1-bit input output register enable
		RST			=> '0',						-- 1-bit input reset
		WE				=> sl_VRAMWE				-- Input write enable, width defined by write port depth
	);

	p_7E_RAM : BRAM_SINGLE_MACRO
	generic map (
		BRAM_SIZE	=> "18Kb",					-- Target BRAM, "9Kb" or "18Kb"
		DEVICE		=> "SPARTAN6",				-- Target Device: "VIRTEX5", "VIRTEX6", "SPARTAN6"
		READ_WIDTH	=> 4,							-- Valid values are 1-36 (19-36 only valid when BRAM_SIZE="18Kb")
		WRITE_WIDTH => 4,							-- Valid values are 1-36 (19-36 only valid when BRAM_SIZE="18Kb")
		DO_REG		=> 0,							-- Optional output register (0 or 1)
		SRVAL			=> x"000000000",			-- Set/Reset value for port output
		INIT			=> x"000000000",			-- Initial values on output port
		INIT_FILE	=> "NONE",
		WRITE_MODE	=> "WRITE_FIRST"			-- "WRITE_FIRST", "READ_FIRST" or "NO_CHANGE"
	)

	port map (
		DO				=> slv_AL(11 downto 8),	-- Output data, width defined by READ_WIDTH parameter
		ADDR			=> I_VRA,					-- Input address, width defined by read/write port depth
		CLK			=> I_CK,						-- 1-bit input clock
		DI				=> I_VRD(11 downto 8),	-- Input data port, width defined by WRITE_WIDTH parameter
		EN				=> sl_AL_HI,				-- 1-bit input RAM enable
		REGCE			=> '0',						-- 1-bit input output register enable
		RST			=> '0',						-- 1-bit input reset
		WE				=> sl_VRAMWE				-- Input write enable, width defined by write port depth
	);

	p_6E_RAM : BRAM_SINGLE_MACRO
	generic map (
		BRAM_SIZE	=> "18Kb",					-- Target BRAM, "9Kb" or "18Kb"
		DEVICE		=> "SPARTAN6",				-- Target Device: "VIRTEX5", "VIRTEX6", "SPARTAN6"
		READ_WIDTH	=> 4,							-- Valid values are 1-36 (19-36 only valid when BRAM_SIZE="18Kb")
		WRITE_WIDTH => 4,							-- Valid values are 1-36 (19-36 only valid when BRAM_SIZE="18Kb")
		DO_REG		=> 0,							-- Optional output register (0 or 1)
		SRVAL			=> x"000000000",			-- Set/Reset value for port output
		INIT			=> x"000000000",			-- Initial values on output port
		INIT_FILE	=> "NONE",
		WRITE_MODE	=> "WRITE_FIRST"			-- "WRITE_FIRST", "READ_FIRST" or "NO_CHANGE"
	)

	port map (
		DO				=> slv_AL(15 downto 12),-- Output data, width defined by READ_WIDTH parameter
		ADDR			=> I_VRA,					-- Input address, width defined by read/write port depth
		CLK			=> I_CK,						-- 1-bit input clock
		DI				=> I_VRD(15 downto 12),	-- Input data port, width defined by WRITE_WIDTH parameter
		EN				=> sl_AL_HI,				-- 1-bit input RAM enable
		REGCE			=> '0',						-- 1-bit input output register enable
		RST			=> '0',						-- 1-bit input reset
		WE				=> sl_VRAMWE				-- Input write enable, width defined by write port depth
	);
end RTL;
