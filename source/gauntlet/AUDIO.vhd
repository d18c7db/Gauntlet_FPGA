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

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_unsigned.all;
	use ieee.numeric_std.all;

library unimacro;
	use unimacro.vcomponents.all;

entity AUDIO is
	port(
		I_MCKR				: in	std_logic;	-- 7.14MHz

		I_1H					: in	std_logic;	-- 3.58MHz
		I_2H					: in	std_logic;	-- 1.79MHz
		I_32V					: in	std_logic;
		I_VBLANKn			: in	std_logic;

		I_SNDNMIn			: in	std_logic;
		I_SNDINTn			: in	std_logic;
		I_SNDRESn			: in	std_logic;

		I_SELFTESTn			: in	std_logic;
		I_COIN				: in	std_logic_vector( 3 downto 0); -- 1L, 2, 3, 4R

		I_SBD					: in	std_logic_vector( 7 downto 0);
		O_SBD					: out std_logic_vector( 7 downto 0) := (others=>'1');
		O_WR68K				: out std_logic;
		O_RD68K				: out std_logic;

		O_CCTR1n				: out	std_logic;
		O_CCTR2n				: out	std_logic;
		O_AUDIO_L			: out	std_logic_vector( 7 downto 0) := (others=>'1');
		O_AUDIO_R			: out	std_logic_vector( 7 downto 0) := (others=>'1');

		-- ROMs are external
		O_AP_EN	 			: out std_logic;
		O_AP_AD				: out	std_logic_vector(15 downto 0) := (others=>'1');
		I_AP_DI				: in 	std_logic_vector( 7 downto 0)
	);
end AUDIO;

architecture RTL of AUDIO is
	signal
		sl_COINn,
		sl_MIXn,
		sl_MIXn_last,
		sl_MUSICn,
		sl_POKEYn,
		sl_RD68kn,
		sl_SBR_Wn,
		sl_SBW_Rn,
		sl_SIORDn,
		sl_SIOWRn,
		sl_SIRQACKn,
		sl_SNDIRQn,
		sl_SPHRDYn,
		sl_SPHRESn,
		sl_SPHWRRn,
		sl_SPHWRn,
		sl_SQUEAKn,
		sl_SRDn,
		sl_SWRn,
		sl_VOICEn,
		sl_VOICEn_last,
		sl_WR68kn,
		sl_YAMRESn,
		sl_POKEY_cs
								: std_logic := '0';
	signal
		sl_SYNC,
		sl_MCKF,
		sl_PHI2,
		sl_CPU_ena,
		sl_13L4,
		sl_13L5,
		sl_14L4,
		sl_14P4,
		sl_14P5,
		sl_14P6,
		sl_14P7,
		sl_1H_last,
		sl_32V_last,
		sl_B02,
		sl_YAMRES,
		sl_ROM_CS,
		sl_RAM_16M_cs,
		sl_RAM_16N_cs,
		sl_ROM_16R_cs,
		sl_ROM_16S_cs
								: std_logic := '1';
	signal
		sl_SWR
								: std_logic_vector( 0 downto 0) := (others => '0');
	signal
		slv_YM_vol,
		slv_PM_vol,
		slv_SM_vol
								: std_logic_vector( 2 downto 0) := (others => '0');
	signal
		sph_ctr
								: std_logic_vector( 3 downto 0) := (others => '0');
	signal
		slv_12P,
		slv_IO,
		slv_16R_ROM_data,
		slv_16S_ROM_data,
		slv_16N_RAM_data,
		slv_16M_RAM_data,
		slv_SBDI,
		slv_SBDO,
		slv_TMS_data,
		slv_YM_data,
		slv_POKEY_data
								: std_logic_vector( 7 downto 0) := (others => '0');
	signal
		s_TMS_out,
		s_POK_out
								: signed( 7 downto 0) := (others => '0');
	signal
		s_audio_TMS,
		s_audio_POK,
		s_audio_YML,
		s_audio_YMR
								: signed(11 downto 0) := (others => '0');
	signal
		s_chan_l,
		s_chan_r
								: signed(13 downto 0) := (others => '0');
	signal
		s_YML_out,
		s_YMR_out
								: signed(15 downto 0) := (others => '0');
	signal
		slv_SBA
								: std_logic_vector(23 downto 0) := (others => '0');
begin
	O_RD68K <= sl_RD68Kn;

-- Delay CPU enable to create an artificial PHI2 clock enable, PHI1 is not used
	p_cpuena : process
	begin
		wait until falling_edge(I_MCKR);
		-- use 1H and 2H to create a short clock enable for the 7MHz master clock
		sl_CPU_ena <= I_1H and (not I_2H);
		sl_PHI2 <= sl_CPU_ena;
	end process;

	sl_MCKF <= not I_MCKR;

	O_WR68K <= sl_WR68kn;
	-------------
	-- sheet 5 --
	-------------
	u_15_16L : entity work.T65
	port map (
		MODE		=> "00",					-- "00" => 6502, "01" => 65C02, "10" => 65C816
		Enable	=> sl_CPU_ena,			-- clock enable to run at 1.7MHz

		CLK		=> I_MCKR,				-- in, system clock 7MHz
		IRQ_n		=> sl_SNDIRQn,			-- in, active low irq
		NMI_n		=> I_SNDNMIn,			-- in, active low nmi
		RES_n		=> I_SNDRESn,			-- in, active low reset
		RDY		=> '1',					-- in, ready
		SO_n		=> '1',					-- in, set overflow
		DI			=> slv_SBDI,			-- in, data

		A			=> slv_SBA,				-- out, address
		DO			=> slv_SBDO,			-- out, data
		R_W_n		=> sl_SBR_Wn,			-- out, read /write
		SYNC		=> sl_SYNC				-- out, sync
	);

	O_SBD   <= slv_SBDO;
	O_AP_EN <= (sl_CPU_ena or sl_PHI2) and sl_ROM_CS and sl_SBR_Wn; -- when reading from ROM range
	O_AP_AD <= slv_SBA(15 downto 0);

	-- 15P, 16K, 16L are just buffers
	p_cpubus : process
	begin
		wait until rising_edge(I_MCKR);
		if sl_PHI2 = '1' then
			-- CPU input data bus mux
			   if sl_SBR_Wn = '1' and sl_ROM_CS = '1'     then slv_SBDI <= I_AP_DI;							-- @4000-FFFF
			elsif sl_SRDn   = '0' and sl_RAM_16M_CS = '1' then slv_SBDI <= slv_16M_RAM_data;				-- @0000-07FF
			elsif sl_SRDn   = '0' and sl_RAM_16N_CS = '1' then slv_SBDI <= slv_16N_RAM_data;				-- @0800-0FFF
			elsif sl_SBR_Wn = '1' and sl_POKEYn = '0'	    then slv_SBDI <= slv_POKEY_data;				-- @1800
			elsif sl_SBR_Wn = '1' and sl_MUSICn = '0'	    then slv_SBDI <= slv_YM_data;					-- @1810
			elsif sl_SBR_Wn = '1' and sl_RD68Kn = '0'     then slv_SBDI <= I_SBD;							-- @1010
			elsif sl_SBR_Wn = '1' and (sl_COINn = '0' or sl_SIORDn = '0') then slv_SBDI <= slv_12P;	-- @1020, @1030
			else slv_SBDI <= (others=>'Z'); -- FIXME
			end if;
		end if;
	end process;

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

	-- 16N RAM
	p_16N  : BRAM_SINGLE_MACRO
	generic map (
		BRAM_SIZE	=> "18Kb",					-- Target BRAM, "9Kb" or "18Kb"
		DEVICE		=> "SPARTAN6",				-- Target Device: "VIRTEX5", "VIRTEX6", "SPARTAN6"
		READ_WIDTH	=> 8,							-- Valid values are 1-36 (19-36 only valid when BRAM_SIZE="18Kb")
		WRITE_WIDTH => 8,							-- Valid values are 1-36 (19-36 only valid when BRAM_SIZE="18Kb")
		DO_REG		=> 0,							-- Optional output register (0 or 1)
		SRVAL			=> x"000000000",			-- Set/Reset value for port output
		INIT			=> x"000000000",			-- Initial values on output port
		INIT_FILE	=> "NONE",
		WRITE_MODE	=> "WRITE_FIRST"			-- "WRITE_FIRST", "READ_FIRST" or "NO_CHANGE"
	)

	port map (
		DO				=> slv_16N_RAM_data,		-- Output data, width defined by READ_WIDTH parameter
		ADDR			=> slv_SBA(10 downto 0),-- Input address, width defined by read/write port depth
		CLK			=> sl_MCKF,					-- 1-bit input clock
		DI				=> slv_SBDO,				-- Input data port, width defined by WRITE_WIDTH parameter
		EN				=> sl_RAM_16N_CS,			-- 1-bit input RAM enable
		REGCE			=> '0',						-- 1-bit input output register enable
		RST			=> '0',						-- 1-bit input reset
		WE				=> sl_SWR					-- Input write enable, width defined by write port depth
	);

	-- 16M RAM
	p_16M  : BRAM_SINGLE_MACRO
	generic map (
		BRAM_SIZE	=> "18Kb",					-- Target BRAM, "9Kb" or "18Kb"
		DEVICE		=> "SPARTAN6",				-- Target Device: "VIRTEX5", "VIRTEX6", "SPARTAN6"
		READ_WIDTH	=> 8,							-- Valid values are 1-36 (19-36 only valid when BRAM_SIZE="18Kb")
		WRITE_WIDTH => 8,							-- Valid values are 1-36 (19-36 only valid when BRAM_SIZE="18Kb")
		DO_REG		=> 0,							-- Optional output register (0 or 1)
		SRVAL			=> x"000000000",			-- Set/Reset value for port output
		INIT			=> x"000000000",			-- Initial values on output port
		INIT_FILE	=> "NONE",
		WRITE_MODE	=> "WRITE_FIRST"			-- "WRITE_FIRST", "READ_FIRST" or "NO_CHANGE"
	)

	port map (
		DO				=> slv_16M_RAM_data,		-- Output data, width defined by READ_WIDTH parameter
		ADDR			=> slv_SBA(10 downto 0),-- Input address, width defined by read/write port depth
		CLK			=> sl_MCKF,					-- 1-bit input clock
		DI				=> slv_SBDO,				-- Input data port, width defined by WRITE_WIDTH parameter
		EN				=> sl_RAM_16M_CS,			-- 1-bit input RAM enable
		REGCE			=> '0',						-- 1-bit input output register enable
		RST			=> '0',						-- 1-bit input reset
		WE				=> sl_SWR					-- Input write enable, width defined by write port depth
	);

	-- Xilinx Block RAMs are active high, so inverted from schematic
	sl_ROM_16S_CS	<= not sl_14L4;	-- @8000-FFFF
	sl_ROM_16R_CS	<= not sl_13L5;	-- @4000-7FFF
	sl_RAM_16N_CS	<= not sl_14P5;	-- @0800-0FFF
	sl_RAM_16M_CS	<= not sl_14P4;	-- @0000-07FF
	sl_ROM_CS      <= sl_ROM_16S_CS or sl_ROM_16R_CS;

	-- Address Decoding

	-- 14L
	sl_14L4			<= ( not slv_SBA(15));	-- @8000-FFFF

	-- 13L
	sl_13L5			<= (     slv_SBA(15)) or ( not slv_SBA(14)); -- Y1 @4000-7FFF
	sl_13L4			<= (     slv_SBA(15)) or (     slv_SBA(14)); -- Y0 @0000-3FFF

	-- 14P
	sl_14P7			<= sl_13L4 or ( not slv_SBA(12)) or ( not slv_SBA(11)); -- Y3 @1800-1FFF
	sl_14P6			<= sl_13L4 or ( not slv_SBA(12)) or (     slv_SBA(11)); -- Y2 @1000-17FF
	sl_14P5			<= sl_13L4 or (     slv_SBA(12)) or ( not slv_SBA(11)); -- Y1 @0800-0FFF
	sl_14P4			<= sl_13L4 or (     slv_SBA(12)) or (     slv_SBA(11)); -- Y0 @0000-07FF

	sl_SIRQACKn		<= sl_14P7 or ( not slv_SBA(5))  or ( not slv_SBA(4)); -- Y3 @1830
	sl_VOICEn		<= sl_14P7 or ( not slv_SBA(5))  or (     slv_SBA(4)); -- Y2 @1820
	sl_MUSICn		<= sl_14P7 or (     slv_SBA(5))  or ( not slv_SBA(4)); -- Y1 @1810
	sl_POKEYn		<= sl_14P7 or (     slv_SBA(5))  or (     slv_SBA(4)); -- Y0 @1800

	sl_POKEY_cs		<= not sl_POKEYn;

	-- 12R
	sl_SIORDn		<= (not sl_B02) or sl_14P6 or ( not slv_SBA(5)) or ( not slv_SBA(4) or ( not sl_SBR_Wn )); -- Y7 @1030 RD
	sl_SIOWRn		<= (not sl_B02) or sl_14P6 or ( not slv_SBA(5)) or ( not slv_SBA(4) or (     sl_SBR_Wn )); -- Y6 @1030 WR
	sl_COINn			<= (not sl_B02) or sl_14P6 or ( not slv_SBA(5)) or (     slv_SBA(4) or ( not sl_SBR_Wn )); -- Y5 @1020 RD
	sl_MIXn			<= (not sl_B02) or sl_14P6 or ( not slv_SBA(5)) or (     slv_SBA(4) or (     sl_SBR_Wn )); -- Y4 @1020 WR
	sl_RD68Kn		<= (not sl_B02) or sl_14P6 or (     slv_SBA(5)) or ( not slv_SBA(4) or ( not sl_SBR_Wn )); -- Y3 @1010 RD
--	sl_12R13			<= (not sl_B02) or sl_14P6 or (     slv_SBA(5)) or ( not slv_SBA(4) or (     sl_SBR_Wn )); -- Y2
--	sl_12R14			<= (not sl_B02) or sl_14P6 or (     slv_SBA(5)) or (     slv_SBA(4) or ( not sl_SBR_Wn )); -- Y1
	sl_WR68Kn		<= (not sl_B02) or sl_14P6 or (     slv_SBA(5)) or (     slv_SBA(4) or (     sl_SBR_Wn )); -- Y0 @1000 WR

	-- 14M F/F
	p_14M : process
	begin
		wait until rising_edge(I_MCKR);
		sl_32V_last <= I_32V;
		if sl_SIRQACKn = '0' then
			sl_SNDIRQn <= '1';
		elsif sl_32V_last = '0' and I_32V = '1' then
			sl_SNDIRQn <= not I_VBLANKn;
		end if;
	end process;

	-- 16T/U simplified addressable latch
	p_16T_U : process
	begin
		wait until rising_edge(sl_MCKF);
		if I_SNDRESn = '0' then
			sl_YAMRESn		<= '0';
			sl_SPHWRRn		<= '0';
			sl_SPHRESn		<= '0';
			sl_SQUEAKn		<= '0';
			O_CCTR1n			<= '0';
			O_CCTR2n			<= '0';
		else
			if sl_SIOWRn = '0' then
				case slv_SBA(2 downto 0) is
					when "000" => sl_YAMRESn	<=     slv_SBDO(7); -- @1030
					when "001" => sl_SPHWRRn	<=     slv_SBDO(7); -- @1031
					when "010" => sl_SPHRESn	<=     slv_SBDO(7); -- @1032
					when "011" => sl_SQUEAKn	<=     slv_SBDO(7); -- @1033
					when "100" => O_CCTR1n		<= not slv_SBDO(7); -- @1034 (inverted by Q17)
					when "101" => O_CCTR2n		<= not slv_SBDO(7); -- @1035 (inverted by Q18)
					when others => null;
				end case;
			end if;
		end if;
	end process;

	-- gate 14N
	sl_SPHWRn	<= sl_SPHWRRn and sl_SPHRESn;

	-- gates 12S
	sl_SWRn		<= not (sl_B02 and sl_SBW_Rn);
	sl_SRDn	 	<= not (sl_B02 and sl_SBR_Wn);
	sl_SWR(0)	<= not sl_SWRn; -- inverted for Xilinx Block RAM
	sl_SBW_Rn	<= not sl_SBR_Wn;
	sl_B02		<= sl_PHI2;

	-------------
	-- sheet 6 --
	-------------

	-- 14S counter is clocked by 1H = 3.5795MHz and provides TMS5220 clock
	-- when SQUEAK is 0 counter is preset with 5, else 7 then counts up to F before being preset again
	--	divide by 11 gives 325.4KHz, divide by 9 gives 397.7KHz
	p_14S : process
	begin
		wait until rising_edge(I_MCKR);
		if I_1H = '0' then
			if sph_ctr = "1111" then
				sph_ctr <= "01" & sl_SQUEAKn & '1';
			else
				sph_ctr <= sph_ctr + 1;
			end if;
		end if;
	end process;

	-- 13P
	p_13P : process
	begin
		wait until rising_edge(I_MCKR);
		sl_VOICEn_last <= sl_VOICEn;
		if sl_VOICEn_last = '0' and sl_VOICEn = '1' then
			slv_TMS_data <= slv_SBDO;
		end if;
	end process;

	-- 15S latch - 3 bit volume control
	p_15S : process(I_SNDRESn, I_MCKR)
	begin
		if I_SNDRESn = '0' then
			slv_SM_vol <= "000";
			slv_PM_vol <= "000";
			slv_YM_vol <= "000";
		elsif rising_edge(I_MCKR) then
			sl_MIXn_last <= sl_MIXn;
			if sl_MIXn_last = '0' and sl_MIXn = '1' then
				slv_SM_vol <= slv_SBDO(7 downto 5);
				slv_PM_vol <= slv_SBDO(4 downto 3) & slv_SBDO(3); -- PM0 and PM1 are connected together by R132
				slv_YM_vol <= slv_SBDO(2 downto 0);
			end if;
		end if;
	end process;

	sl_YAMRES <= not sl_YAMRESn;

	-- YM2151 sound
	u_15R : entity work.JT51
	port map(
		-- inputs
		rst		=> sl_YAMRES,	-- active high reset
		clk		=> I_1H,			-- FIXME
		cen		=> '1',
		cen_p1	=> I_2H,
		a0			=> slv_SBA(0),
		wr_n		=> sl_SWRn,
		cs_n		=> sl_MUSICn,
		din		=> slv_SBDO,

		-- outputs
		dout		=> slv_YM_data,
		irq_n		=> open,

		ct1		=> open,
		ct2		=> open,

		--	 Low resolution outputs (same as real chip)
		sample	=> open,	-- marks new output sample
		left		=> open,	-- std_logic_vector(15 downto 0)
		right		=> open,	-- std_logic_vector(15 downto 0)

		--	 Full resolution outputs
		xleft		=> s_YML_out,	-- std_logic_vector(15 downto 0)
		xright	=> s_YMR_out,	-- std_logic_vector(15 downto 0)
		dacleft	=> open,
		dacright	=> open
	);

--	-- YM3012 DAC - not used becase YM2151 core outputs parallel sound data
--	u_15T : entity work.YM3012
--	generic map (signed_data => false)
--	port map (
--		PHI0     => clk,
--		ICL      => reset,
--		SDATA    => ym_sd,
--		SAM1     => ym_sam1,
--		SAM2     => ym_sam2,
--		CH1      => open,
--		Ch2      => open
--	);

	--	POKEY sound (Atari custom chip 137430-001)
	u_15L : entity work.POKEY
	port map (
		ADDR      		=> slv_SBA(3 downto 0),
		DIN       		=> slv_SBDO,
		DOUT      		=> slv_POKEY_data,
		DOUT_OE_L 		=> open,
		RW_L      		=> sl_SBR_Wn,
		CS        		=> sl_POKEY_cs,
		CS_L      		=> '0',

		AUDIO_OUT 		=> s_POK_out,

		PIN       		=> x"00",
		ENA       		=> sl_CPU_ena,
		CLK       		=> I_MCKR
	);

	-- TMS5220 Voice Synthesis
	u_13R : entity work.TMS5220
	port map (
		I_OSC			=> sph_ctr(2),
		I_WSn			=> sl_SPHWRn,
		I_RSn			=> sl_SPHRESn,
		I_DATA		=> '1',
		I_TEST		=> '1',
		I_DBUS		=> slv_TMS_data,

		O_DBUS		=> open,
		O_RDYn		=> sl_SPHRDYn,
		O_INTn		=> open,
		O_M0			=> open,
		O_M1			=> open,
		O_ADD8		=> open,
		O_ADD4		=> open,
		O_ADD2		=> open,
		O_ADD1		=> open,
		O_ROMCLK		=> open,
		O_T11			=> open,
		O_IO			=> open,
		O_PRMOUT		=> open,
		O_SPKR		=> s_TMS_out
	);

	-- FIXME this mixing isn't ideal, sound volume ends up too low
	-- Pokey sounds OK, but YM seems a bit distorted, try and do better
	p_volmux : process
	begin
		wait until rising_edge(I_MCKR);

		-- volume control applied to signed outputs
		s_audio_TMS <= signed('0' & slv_SM_vol) * signed(s_TMS_out);
		s_audio_POK <= signed('0' & slv_PM_vol) * signed(s_POK_out);
		s_audio_YML <= signed('0' & slv_YM_vol) * signed(s_YML_out(15 downto 8));
		s_audio_YMR <= signed('0' & slv_YM_vol) * signed(s_YMR_out(15 downto 8));

		-- sign extend to 14 bits and add all outputs together as signed integers
		s_chan_l <=  signed(s_audio_YML(11) & s_audio_YML(11) & s_audio_YML)
					+ ( signed(s_audio_POK(11) & s_audio_POK(11) & s_audio_POK)
					+   signed(s_audio_TMS(11) & s_audio_TMS(11) & s_audio_TMS) );
		s_chan_r <=  signed(s_audio_YMR(11) & s_audio_YMR(11) & s_audio_YMR)
					+ ( signed(s_audio_POK(11) & s_audio_POK(11) & s_audio_POK)
					+   signed(s_audio_TMS(11) & s_audio_TMS(11) & s_audio_TMS) );

		-- convert output back to unsigned for DAC usage
		O_AUDIO_L <= std_logic_vector(not s_chan_l(13) & s_chan_l(12 downto 6));
		O_AUDIO_R <= std_logic_vector(not s_chan_r(13) & s_chan_r(12 downto 6));
	end process;

	-------------
	-- sheet 7 --
	-------------

	-- 12P buffer
	slv_12P	<= (not I_SNDNMIn) & (not I_SNDINTn) & sl_SPHRDYn & I_SELFTESTn & I_COIN;
end RTL;
