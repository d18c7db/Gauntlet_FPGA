--------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date:   00:00:00 01/01/2020
-- Design Name:
-- Module Name:   tb_gauntlet.vhd
-- Project Name:  gauntlet
-- Target Device:
-- Tool versions:
-- Description:
--
-- VHDL Test Bench Created by ISE for module: emu
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
	use ieee.std_logic_arith.all;
	use ieee.std_logic_unsigned.all;

entity tb_gauntlet is
end tb_gauntlet;

architecture RTL of tb_gauntlet is
	constant CLK50_period : TIME := 1000 ns / 50;
	constant SDRAM_CLOCK  : real := 114.5454;

	signal VGA_R          : std_logic_vector( 7 downto 0);
	signal VGA_G          : std_logic_vector( 7 downto 0);
	signal VGA_B          : std_logic_vector( 7 downto 0);
	signal VGA_HS         : std_logic;
	signal VGA_VS         : std_logic;

	-- SDRAM
	signal SDRAM_A        : std_logic_vector(12 downto 0) := (others=>'0');
	signal SDRAM_BA       : std_logic_vector( 1 downto 0) := (others=>'0');
	signal SDRAM_DQ       : std_logic_vector(15 downto 0) := (others=>'0');
	signal
		SDRAM_CLK,
		SDRAM_CKE,
		SDRAM_DQML,
		SDRAM_DQMH,
		SDRAM_nCS,
		SDRAM_nCAS,
		SDRAM_nRAS,
		SDRAM_nWE          : std_logic := '0';

	-- HPS_IO
	signal HPS_BUS        : std_logic_vector(45 downto  0) := (others=>'0');
	signal io_din         : std_logic_vector(31 downto 16) := (others=>'0');
	signal io_dout        : std_logic_vector(15 downto  0) := (others=>'0');
	signal cmd            : std_logic_vector(15 downto  0) := (others=>'0');
	signal
		f1,
		vs_hdmi,
		clk_100,
		clk_vid,
		ce_pix,
		de,
		hsync,
		vsync,
		ioctl_wait,
		clk_sys,
		fp_enable,
		io_enable,
		io_strobe,
		io_wide        : std_logic := '0';

	signal RESET, CLK_50M : std_logic := '0';

	component emu
	port (
		CLK_50M          : in    std_logic;
		RESET            : in    std_logic;
		HPS_BUS          : inout std_logic_vector(45 downto 0);
		CLK_VIDEO        : out   std_logic;
		CE_PIXEL         : out   std_logic;
		VIDEO_ARX        : out   std_logic_vector( 7 downto 0);
		VIDEO_ARY        : out   std_logic_vector( 7 downto 0);
		VGA_R            : out   std_logic_vector( 7 downto 0);
		VGA_G            : out   std_logic_vector( 7 downto 0);
		VGA_B            : out   std_logic_vector( 7 downto 0);
		VGA_HS           : out   std_logic;
		VGA_VS           : out   std_logic;
		VGA_DE           : out   std_logic;
		VGA_F1           : out   std_logic;
		VGA_SL           : out   std_logic_vector( 1 downto 0);
		FB_EN            : out   std_logic;
		FB_FORMAT        : out   std_logic_vector( 4 downto 0);
		FB_WIDTH         : out   std_logic_vector(11 downto 0);
		FB_HEIGHT        : out   std_logic_vector(11 downto 0);
		FB_BASE          : out   std_logic_vector(31 downto 0);
		FB_STRIDE        : out   std_logic_vector(13 downto 0);
		FB_VBL           : in    std_logic;
		FB_LL            : in    std_logic;
		LED_USER         : out   std_logic;
		LED_POWER        : out   std_logic_vector( 1 downto 0);
		LED_DISK         : out   std_logic_vector( 1 downto 0);
		CLK_AUDIO        : in    std_logic;
		AUDIO_L          : out   std_logic_vector(15 downto 0);
		AUDIO_R          : out   std_logic_vector(15 downto 0);
		AUDIO_S          : out   std_logic;
		DDRAM_CLK        : out   std_logic;
		DDRAM_BUSY       : in    std_logic;
		DDRAM_BURSTCNT   : out   std_logic_vector( 7 downto 0);
		DDRAM_ADDR       : out   std_logic_vector(28 downto 0);
		DDRAM_DOUT       : in    std_logic_vector(63 downto 0);
		DDRAM_DOUT_READY : in    std_logic;
		DDRAM_RD         : out   std_logic;
		DDRAM_DIN        : out   std_logic_vector(63 downto 0);
		DDRAM_BE         : out   std_logic_vector( 7 downto 0);
		DDRAM_WE         : out   std_logic;

		SDRAM_CLK        : in std_logic;
		SDRAM_CKE        : in std_logic;
		SDRAM_A          : in std_logic_vector(13 downto 0);
		SDRAM_BA         : in std_logic_vector( 1 downto 0);
		SDRAM_DQ         : inout std_logic_vector(15 downto 0);
		SDRAM_DQML       : in std_logic;
		SDRAM_DQMH       : in std_logic;
		SDRAM_nCS        : in std_logic;
		SDRAM_nCAS       : in std_logic;
		SDRAM_nRAS       : in std_logic;
		SDRAM_nWE        : in std_logic;

		USER_IN          : in    std_logic_vector( 6 downto 0);
		USER_OUT         : out   std_logic_vector( 6 downto 0)
	);
	end component;

begin
	-- simulation model of SDRAM
	u_sdram : entity work.mt48lc16m16a2
	port map (
		clk    => SDRAM_CLK,
		cke    => SDRAM_CKE,
		addr   => SDRAM_A,
		ba     => SDRAM_BA,
		dq     => SDRAM_DQ,
		dqm(1) => SDRAM_DQMH,
		dqm(0) => SDRAM_DQML,
		cs_n   => SDRAM_nCS,
		cas_n  => SDRAM_nCAS,
		ras_n  => SDRAM_nRAS,
		we_n   => SDRAM_nWE
	);

	DUT : entity work.emu
	port map (
		CLK_50M          => CLK_50M,
		RESET            => RESET,
		HPS_BUS          => HPS_BUS,
		CLK_VIDEO        => open,
		CE_PIXEL         => open,
		VIDEO_ARX        => open,
		VIDEO_ARY        => open,

		VGA_R            => VGA_R,
		VGA_G            => VGA_G,
		VGA_B            => VGA_B,
		VGA_HS           => VGA_HS,
		VGA_VS           => VGA_VS,
		VGA_DE           => open,
		VGA_F1           => open,
		VGA_SL           => open,

		FB_EN            => open,
		FB_FORMAT        => open,
		FB_WIDTH         => open,
		FB_HEIGHT        => open,
		FB_BASE          => open,
		FB_STRIDE        => open,
		FB_VBL           => '0',
		FB_LL            => '0',
		LED_USER         => open,
		LED_POWER        => open,
		LED_DISK         => open,
		CLK_AUDIO        => '0',
		AUDIO_L          => open,
		AUDIO_R          => open,
		AUDIO_S          => open,

		DDRAM_CLK        => open,
		DDRAM_BUSY       => '1',
		DDRAM_BURSTCNT   => open,
		DDRAM_ADDR       => open,
		DDRAM_DOUT       => (others=>'0'),
		DDRAM_DOUT_READY => '1',
		DDRAM_RD         => open,
		DDRAM_DIN        => open,
		DDRAM_BE         => open,
		DDRAM_WE         => open,

		SDRAM_CLK        => SDRAM_CLK,
		SDRAM_CKE        => SDRAM_CKE,
		SDRAM_A          => SDRAM_A,
		SDRAM_BA         => SDRAM_BA,
		SDRAM_DQ         => SDRAM_DQ,
		SDRAM_DQML       => SDRAM_DQML,
		SDRAM_DQMH       => SDRAM_DQMH,
		SDRAM_nCS        => SDRAM_nCS,
		SDRAM_nCAS       => SDRAM_nCAS,
		SDRAM_nRAS       => SDRAM_nRAS,
		SDRAM_nWE        => SDRAM_nWE,

		USER_IN          => (others=>'0'),
		USER_OUT         => open
	);

	p_clk50 : process
	begin
		wait for CLK50_period/2;
		CLK_50M <= not CLK_50M;
	end process;

	p_rst : process
	begin
		RESET <= '1';
		wait for CLK50_period*64;
		RESET <= '0';
		wait;
	end process;
end RTL;
