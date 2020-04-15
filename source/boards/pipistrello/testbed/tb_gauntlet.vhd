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
library std;
	use std.textio.all;

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_textio.all;

entity tb_gauntlet is
end tb_gauntlet;

architecture RTL of tb_gauntlet is
	--Inputs
	signal I_RESET			: std_logic := '0';
	signal CLK				: std_logic := '0';
	signal CLKS				: std_logic := '0';
	signal MEM_CK			: std_logic := '0';

	--Outputs
	signal MEM_A			: std_logic_vector(20 downto 0);
	signal MEM_D			: std_logic_vector(15 downto 0);

	constant CLK_period  : TIME := 1000 ns / 50;		-- 50MHz external clock

begin
	u_ROMS_EXT : entity work.ROMS_EXT
	port map (
		CLK			=>	CLKS,
		ENA			=>	'1',
		ADDR			=>	MEM_A,
		DATA			=>	MEM_D
	);

	-- Unit Under Test (uut)
	u_GAUNTLET_TOP : entity work.GAUNTLET_TOP
	PORT MAP (
		-- FLASH
		FLASH_MOSI	=> open,
		FLASH_SCK	=> open,
		FLASH_MISO	=> 'Z',
		FLASH_WPn	=> open,
		FLASH_HOLDn	=> open,

		-- SRAM
		MEM_A			=> MEM_A,
		MEM_D			=> MEM_D,
		SRAM_nCS		=> open,
		FLASH_nCE	=> open,
		MEM_nWE		=> open,
		MEM_nOE		=> open,
		MEM_nBHE		=> open,
		MEM_nBLE		=> open,
		MEM_CK		=> MEM_CK,

		-- Video output
		TMDS_P		=> open,
		TMDS_N		=> open,

		-- Sound out
		O_AUDIO_L	=> open,
		O_AUDIO_R	=> open,

		-- External controls
		PMOD1_IO		=> "1111",
		PMOD2_IO		=> "1111",

		I_RESET		=> I_RESET,
		CLK_IN		=> CLK
	);

	-- Clock process definitions
	p_clk : process
		begin
		wait for CLK_period/2;
		CLK <= not CLK;
	end process;

	CLKS <= MEM_CK after 10ns; -- simulate 10ns access time SRAM

	-- Stimulus process
	p_stim : process
	begin
		I_RESET <= '1';
		wait for CLK_period*32;
		I_RESET <= '0';
		wait;
	end process;
end RTL;
