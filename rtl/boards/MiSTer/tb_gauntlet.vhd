--------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date:   00:00:00 01/01/2020
-- Design Name:
-- Module Name:   tb_gauntlet.vhd
-- Project Name:  gauntlet_top
-- Target Device:
-- Tool versions:
-- Description:
--
-- VHDL Test Bench Created by ISE for module: GAUNTLET_TOP
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes:
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation
-- simulation model.
--------------------------------------------------------------------------------
library ieee;
	use ieee.std_logic_1164.all;

entity tb_gauntlet is
end tb_gauntlet;

architecture RTL of tb_gauntlet is
	constant CLK14_period  : TIME := 1000 ns / 14;
	constant CLK7_period   : TIME := 1000 ns / 7;

	signal I_RESET			: std_logic := '0';
	signal I_CLK_14M		: std_logic := '0';
	signal I_CLK_7M		: std_logic := '1';
	signal i,r,g,b			: std_logic_vector(3 downto 0);
	signal hs,vs			: std_logic;

	signal
		slv_ROM_1A,
		slv_ROM_1B,
		slv_ROM_2A,
		slv_ROM_2B,
		slv_ROM_1L,
		slv_ROM_1MN,
		slv_ROM_2L,
		slv_ROM_2MN,
		slv_ROM_7A,
		slv_ROM_7B,
		slv_ROM_9A,
		slv_ROM_9B,
		slv_ROM_10A,
		slv_ROM_10B,
		slv_ROM_16R,
		slv_ROM_16S
								: std_logic_vector( 7 downto 0) := (others=>'1');

		signal slv_GP_ADDR	: std_logic_vector(17 downto 0);
		signal slv_GP_DATA	: std_logic_vector(31 downto 0);
		signal slv_MP_ADDR	: std_logic_vector(18 downto 0);
		signal slv_MP_DATA	: std_logic_vector(15 downto 0);
		signal slv_AP_ADDR	: std_logic_vector(15 downto 0);
		signal slv_AP_DATA	: std_logic_vector( 7 downto 0);
		signal slv_CP_ADDR	: std_logic_vector(13 downto 0);
		signal slv_CP_DATA	: std_logic_vector( 7 downto 0);

begin
	DUT : entity work.FPGA_GAUNTLET
	generic map (slap_type=>104)
	port map(
		-- System Clock
		I_CLK_14M => I_CLK_14M,
		I_CLK_7M  => I_CLK_7M,

		-- Active high reset
		I_RESET   => I_RESET,

		-- player 1 controls, active low
		I_P1  => x"FF",
		I_P2  => x"FF",
		I_P3  => x"FF",
		I_P4  => x"FF",
		I_SYS => "11111", -- sys, coin 4,3,2,1

		O_LEDS		=> open,

		-- Audio out
		O_AUDIO_L	=> open,
		O_AUDIO_R	=> open,

		-- VGA monitor output
		O_VIDEO_I	=> i,
		O_VIDEO_R	=> r,
		O_VIDEO_G	=> g,
		O_VIDEO_B	=> b,
		O_HSYNC		=> hs,
		O_VSYNC		=> vs,
		O_CSYNC		=> open,
		O_HBLANK		=> open,
		O_VBLANK		=> open,

		-- Access to external ROMs
		-- GFX ROMs
		O_GP_EN		=> open,  -- active high (GPEN)
		O_GP_ADDR	=> slv_GP_ADDR,
		I_GP_DATA	=> slv_GP_DATA,
		-- CHAR ROM
		O_CP_ADDR	=> slv_CP_ADDR,
		I_CP_DATA	=> slv_CP_DATA,
		-- Main Program ROMs
		O_MP_EN		=> open,  -- active high (AS)
		O_MP_ADDR	=> slv_MP_ADDR,
		I_MP_DATA	=> slv_MP_DATA,
		-- Audio Program ROMs
		O_AP_EN		=> open,  -- active high (CPUENA)
		O_AP_ADDR	=> slv_AP_ADDR,
		I_AP_DATA	=> slv_AP_DATA
	);

-- pragma translate_off
	p_bmp_in : entity work.bmp_out
	generic map ( FILENAME => "BI" )
	port map (
		clk_i               => I_CLK_7M,
		dat_i(23 downto 20) => r,
		dat_i(19 downto 16) => x"0",
		dat_i(15 downto 12) => g,
		dat_i(11 downto  8) => x"0",
		dat_i( 7 downto  4) => b,
		dat_i( 3 downto  0) => x"0",
		hs_i            => hs,
		vs_i            => vs
	);
-- pragma translate_on

	p_clk14 : process
		begin
		wait for CLK14_period/2;
		I_CLK_14M <= not I_CLK_14M;
	end process;

	p_clk7 : process
		begin
		wait for CLK7_period/2;
		I_CLK_7M <= not I_CLK_7M;
	end process;

	p_rst : process
	begin
		I_RESET <= '1';
		wait for CLK7_period*32;
		I_RESET <= '0';
		wait;
	end process;

	-- ################################################################################
	-- # Directly connected ROMs, this sections should be replaced with external ROMs #
	-- ################################################################################

	-- 6502 directly connected ROMS
	ROM_16R : entity work.ROM_16R port map ( CLK=>I_CLK_14M, DATA=>slv_ROM_16R, ADDR=>slv_AP_ADDR(13 downto 0) );	-- @4000-7FFF
	ROM_16S : entity work.ROM_16S port map ( CLK=>I_CLK_14M, DATA=>slv_ROM_16S, ADDR=>slv_AP_ADDR(14 downto 0) );	-- @8000-FFFF
	slv_AP_DATA <= slv_ROM_16S when slv_AP_ADDR(15)='1' else slv_ROM_16R;

	-- 68K directly connected ROMS
	ROM_9A  : entity work.ROM_9A  port map ( CLK=>I_CLK_14M, DATA=>slv_ROM_9A,  ADDR=>slv_MP_ADDR(14 downto 0) );
	ROM_9B  : entity work.ROM_9B  port map ( CLK=>I_CLK_14M, DATA=>slv_ROM_9B,  ADDR=>slv_MP_ADDR(14 downto 0) );
	ROM_10A : entity work.ROM_10A port map ( CLK=>I_CLK_14M, DATA=>slv_ROM_10A, ADDR=>slv_MP_ADDR(13 downto 0) );
	ROM_10B : entity work.ROM_10B port map ( CLK=>I_CLK_14M, DATA=>slv_ROM_10B, ADDR=>slv_MP_ADDR(13 downto 0) );
	ROM_7A  : entity work.ROM_7A  port map ( CLK=>I_CLK_14M, DATA=>slv_ROM_7A,  ADDR=>slv_MP_ADDR(14 downto 0) );
	ROM_7B  : entity work.ROM_7B  port map ( CLK=>I_CLK_14M, DATA=>slv_ROM_7B,  ADDR=>slv_MP_ADDR(14 downto 0) );
--	ROM_6A  : entity work.ROM_6A  port map ( CLK=>I_CLK_14M, DATA=>slv_ROM_6A,  ADDR=>slv_MP_ADDR(14 downto 0) );
--	ROM_6B  : entity work.ROM_6B  port map ( CLK=>I_CLK_14M, DATA=>slv_ROM_6B,  ADDR=>slv_MP_ADDR(14 downto 0) );
--	ROM_5A  : entity work.ROM_5A  port map ( CLK=>I_CLK_14M, DATA=>slv_ROM_5A,  ADDR=>slv_MP_ADDR(14 downto 0) );
--	ROM_5B  : entity work.ROM_5B  port map ( CLK=>I_CLK_14M, DATA=>slv_ROM_5B,  ADDR=>slv_MP_ADDR(14 downto 0) );
--	ROM_3A  : entity work.ROM_3A  port map ( CLK=>I_CLK_14M, DATA=>slv_ROM_3A,  ADDR=>slv_MP_ADDR(14 downto 0) );
--	ROM_3B  : entity work.ROM_3B  port map ( CLK=>I_CLK_14M, DATA=>slv_ROM_3B,  ADDR=>slv_MP_ADDR(14 downto 0) );
	slv_MP_DATA <=
		slv_ROM_9A  & slv_ROM_9B  when slv_MP_ADDR(18 downto 15)="0000" else -- /ROM0 00000
		slv_ROM_10A & slv_ROM_10B when slv_MP_ADDR(18 downto 15)="0011" else -- /SLAP 38000
		slv_ROM_7A  & slv_ROM_7B  when slv_MP_ADDR(18 downto 15)="0100" else -- /ROM1 40000
--		slv_ROM_6A  & slv_ROM_6B  when slv_MP_ADDR(18 downto 15)="0101" else -- /ROM2 50000
--		slv_ROM_5A  & slv_ROM_5B  when slv_MP_ADDR(18 downto 15)="0110" else -- /ROM3 60000
--		slv_ROM_3A  & slv_ROM_3B  when slv_MP_ADDR(18 downto 15)="0111" else -- /ROM4 70000
		(others=>'1');

	-- VIDEO ROMS
	ROM_1A  : entity work.ROM_1A  port map ( CLK=>I_CLK_14M, DATA=>slv_ROM_1A , ADDR=>slv_GP_ADDR(14 downto 0) );
	ROM_1B  : entity work.ROM_1B  port map ( CLK=>I_CLK_14M, DATA=>slv_ROM_1B , ADDR=>slv_GP_ADDR(14 downto 0) );
	ROM_1L  : entity work.ROM_1L  port map ( CLK=>I_CLK_14M, DATA=>slv_ROM_1L , ADDR=>slv_GP_ADDR(14 downto 0) );
	ROM_1MN : entity work.ROM_1MN port map ( CLK=>I_CLK_14M, DATA=>slv_ROM_1MN, ADDR=>slv_GP_ADDR(14 downto 0) );
	ROM_2A  : entity work.ROM_2A  port map ( CLK=>I_CLK_14M, DATA=>slv_ROM_2A , ADDR=>slv_GP_ADDR(14 downto 0) );
	ROM_2B  : entity work.ROM_2B  port map ( CLK=>I_CLK_14M, DATA=>slv_ROM_2B , ADDR=>slv_GP_ADDR(14 downto 0) );
	ROM_2L  : entity work.ROM_2L  port map ( CLK=>I_CLK_14M, DATA=>slv_ROM_2L , ADDR=>slv_GP_ADDR(14 downto 0) );
	ROM_2MN : entity work.ROM_2MN port map ( CLK=>I_CLK_14M, DATA=>slv_ROM_2MN, ADDR=>slv_GP_ADDR(14 downto 0) );

	slv_GP_DATA <=
		slv_ROM_2L  & slv_ROM_2A & slv_ROM_1L  & slv_ROM_1A  when slv_GP_ADDR(17 downto 15)="000" else -- GS0 plane 3, 2, 1, 0
		slv_ROM_2MN & slv_ROM_2B & slv_ROM_1MN & slv_ROM_1B  when slv_GP_ADDR(17 downto 15)="001" else -- GS1 plane 3, 2, 1, 0
		(others=>'1');

	ROM_6P  : entity work.ROM_6P  port map ( CLK=>I_CLK_14M, DATA=>slv_CP_DATA , ADDR=>slv_CP_ADDR);
end RTL;
