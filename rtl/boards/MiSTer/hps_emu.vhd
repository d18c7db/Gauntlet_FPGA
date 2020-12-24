library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_unsigned.all;

entity hps_io_emu is
generic (
	STRLEN : natural:=0; PS2DIV : natural:=0; WIDE : natural:=0; VDNUM : natural:=1; PS2WE : natural:=0);
port (
	clk_sys                  : in  std_logic;
	HPS_BUS                  : inout std_logic_vector(45 downto 0);
	EXT_BUS                  : inout std_logic_vector(35 downto 0);
	gamma_bus                : inout std_logic_vector(21 downto 0);

	conf_str                 : in  std_logic_vector(1903 downto 0);
	forced_scandoubler       : out std_logic;

	buttons                  : out std_logic_vector( 1 downto 0);
	status                   : out std_logic_vector(31 downto 0);
	status_menumask          : in  std_logic_vector( 1 downto 0);
	direct_video             : out std_logic;

	ioctl_download           : out std_logic;
	ioctl_wr                 : out std_logic;
	ioctl_addr               : out std_logic_vector(24 downto 0) := (others=>'0');
	ioctl_dout               : out std_logic_vector( 7 downto 0) := (others=>'0');
	ioctl_index              : out std_logic_vector( 7 downto 0);
	ioctl_wait               : in  std_logic;

	joystick_0               : out std_logic_vector(15 downto 0);
	joystick_1               : out std_logic_vector(15 downto 0);
	joystick_2               : out std_logic_vector(15 downto 0);
	joystick_3               : out std_logic_vector(15 downto 0);
	ps2_key                  : out std_logic_vector(10 downto 0)
);

end hps_io_emu;
architecture arch of hps_io_emu is
	constant max_delay : integer := 220000 / (1000 / 10 / 2);
	constant CLK1M_period : TIME := 1000 ns / 10; -- 1MHz
	signal download     : std_logic := '0';
	signal ioctl_wr_next: std_logic := '0';
	signal clk_1m       : std_logic := '0';
	signal clk_1m_last  : std_logic := '0';
	signal addr         : std_logic_vector(31 downto 0) := (others=>'1');
	signal data         : std_logic_vector( 7 downto 0) := (others=>'0');
	signal delay        : integer range 0 to 32767 := 0;
	signal
		slv_data_1A, slv_data_1B, slv_data_1L, slv_data_1MN,
		slv_data_2A, slv_data_2B, slv_data_2L, slv_data_2MN,
		slv_data_7A, slv_data_9A, slv_data_10A,
		slv_data_7B, slv_data_9B, slv_data_10B,
		slv_data_6P, slv_data_16R, slv_data_16S
	: std_logic_vector( 7 downto 0);

begin
	-- VIDEO ROMS
	ROM_2L  : entity work.ROM_2L  port map(CLK => clk_sys, DATA => slv_data_2L , ADDR => addr(16 downto 2));
	ROM_2A  : entity work.ROM_2A  port map(CLK => clk_sys, DATA => slv_data_2A , ADDR => addr(16 downto 2));
	ROM_1L  : entity work.ROM_1L  port map(CLK => clk_sys, DATA => slv_data_1L , ADDR => addr(16 downto 2));
	ROM_1A  : entity work.ROM_1A  port map(CLK => clk_sys, DATA => slv_data_1A , ADDR => addr(16 downto 2));
	ROM_2MN : entity work.ROM_2MN port map(CLK => clk_sys, DATA => slv_data_2MN, ADDR => addr(16 downto 2));
	ROM_2B  : entity work.ROM_2B  port map(CLK => clk_sys, DATA => slv_data_2B , ADDR => addr(16 downto 2));
	ROM_1MN : entity work.ROM_1MN port map(CLK => clk_sys, DATA => slv_data_1MN, ADDR => addr(16 downto 2));
	ROM_1B  : entity work.ROM_1B  port map(CLK => clk_sys, DATA => slv_data_1B , ADDR => addr(16 downto 2));

	-- 68K directly connected ROMS
	ROM_9A  : entity work.ROM_9A  port map(CLK => clk_sys, DATA => slv_data_9A , ADDR => addr(15 downto 1)); -- ROM0
	ROM_9B  : entity work.ROM_9B  port map(CLK => clk_sys, DATA => slv_data_9B , ADDR => addr(15 downto 1)); -- ROM0
	ROM_10A : entity work.ROM_10A port map(CLK => clk_sys, DATA => slv_data_10A, ADDR => addr(14 downto 1)); -- SLAP
	ROM_10B : entity work.ROM_10B port map(CLK => clk_sys, DATA => slv_data_10B, ADDR => addr(14 downto 1)); -- SLAP
	ROM_7A  : entity work.ROM_7A  port map(CLK => clk_sys, DATA => slv_data_7A , ADDR => addr(15 downto 1)); -- ROM1
	ROM_7B  : entity work.ROM_7B  port map(CLK => clk_sys, DATA => slv_data_7B , ADDR => addr(15 downto 1)); -- ROM1
--	ROM_6A  : entity work.ROM_6A  port map(CLK => clk_sys, DATA => slv_data_6A , ADDR => addr(15 downto 1)); -- ROM2
--	ROM_6B  : entity work.ROM_6B  port map(CLK => clk_sys, DATA => slv_data_6B , ADDR => addr(15 downto 1)); -- ROM2
--	ROM_5A  : entity work.ROM_5A  port map(CLK => clk_sys, DATA => slv_data_5A , ADDR => addr(15 downto 1)); -- ROM3
--	ROM_5B  : entity work.ROM_5B  port map(CLK => clk_sys, DATA => slv_data_5B , ADDR => addr(15 downto 1)); -- ROM3
--	ROM_3A  : entity work.ROM_3A  port map(CLK => clk_sys, DATA => slv_data_3A , ADDR => addr(15 downto 1)); -- ROM4
--	ROM_3B  : entity work.ROM_3B  port map(CLK => clk_sys, DATA => slv_data_3B , ADDR => addr(15 downto 1)); -- ROM4

	-- 6502 directly connected ROMS
	ROM_16R : entity work.ROM_16R port map(CLK => clk_sys, DATA => slv_data_16R, ADDR => addr(13 downto 0));
	ROM_16S : entity work.ROM_16S port map(CLK => clk_sys, DATA => slv_data_16S, ADDR => addr(14 downto 0));

	-- CHAR ROM
	ROM_6P  : entity work.ROM_6P  port map(CLK => clk_sys, DATA => slv_data_6P , ADDR => addr(13 downto 0));

	HPS_BUS            <= (others=>'Z');
	EXT_BUS            <= (others=>'Z');
	gamma_bus          <= (others=>'Z');

	forced_scandoubler <= '0';
	buttons            <= (others=>'0');
	status             <= (others=>'0');
	direct_video       <= '0';

	joystick_0         <= (others=>'0');
	joystick_1         <= (others=>'0');
	joystick_2         <= (others=>'0');
	joystick_3         <= (others=>'0');
	ps2_key            <= (others=>'0');

	ioctl_addr         <= addr(24 downto 0);
	ioctl_dout         <= data;
	ioctl_download     <= download;
	ioctl_index        <= (others=>'0');
	download           <= '1' when ( ((addr < x"00150000") or (addr = x"FFFFFFFF")) and delay = max_delay) else '0';

	data <=
	-- video ROMs interleaved
	-- 2L 2A 1L 1A
	slv_data_2L  when (addr(24 downto 17)="00000000"    ) and addr(1 downto 0)="00" else -- 00000 0000 0xxx xxxx xxxx xxxx
	slv_data_2A  when (addr(24 downto 17)="00000000"    ) and addr(1 downto 0)="01" else
	slv_data_1L  when (addr(24 downto 17)="00000000"    ) and addr(1 downto 0)="10" else
	slv_data_1A  when (addr(24 downto 17)="00000000"    ) and addr(1 downto 0)="11" else

	-- 2MN 2B  1MN 1B
	slv_data_2MN when (addr(24 downto 17)="00000001"    ) and addr(1 downto 0)="00" else -- 00000 0010 0xxx xxxx xxxx xxxx
	slv_data_2B  when (addr(24 downto 17)="00000001"    ) and addr(1 downto 0)="01" else
	slv_data_1MN when (addr(24 downto 17)="00000001"    ) and addr(1 downto 0)="10" else
	slv_data_1B  when (addr(24 downto 17)="00000001"    ) and addr(1 downto 0)="11" else

	-- 2P 2C 1P 1C
	x"00"        when (addr(24 downto 17)="00000010"    ) and addr(1 downto 0)="00" else -- 00000 0100 0xxx xxxx xxxx xxxx
	x"00"        when (addr(24 downto 17)="00000010"    ) and addr(1 downto 0)="01" else
	x"00"        when (addr(24 downto 17)="00000010"    ) and addr(1 downto 0)="10" else
	x"00"        when (addr(24 downto 17)="00000010"    ) and addr(1 downto 0)="11" else

	-- 2R 2D 1R1D
	x"00"        when (addr(24 downto 17)="00000011"    ) and addr(1 downto 0)="00" else -- 00000 0110 0xxx xxxx xxxx xxxx
	x"00"        when (addr(24 downto 17)="00000011"    ) and addr(1 downto 0)="01" else
	x"00"        when (addr(24 downto 17)="00000011"    ) and addr(1 downto 0)="10" else
	x"00"        when (addr(24 downto 17)="00000011"    ) and addr(1 downto 0)="11" else

	-- 2S 2E 1S 1E
	x"00"        when (addr(24 downto 17)="00000100"    ) and addr(1 downto 0)="00" else -- 00000 1000 0xxx xxxx xxxx xxxx
	x"00"        when (addr(24 downto 17)="00000100"    ) and addr(1 downto 0)="01" else
	x"00"        when (addr(24 downto 17)="00000100"    ) and addr(1 downto 0)="10" else
	x"00"        when (addr(24 downto 17)="00000100"    ) and addr(1 downto 0)="11" else

	-- 2U 2J 1U 1J
	x"00"        when (addr(24 downto 17)="00000101"    ) and addr(1 downto 0)="00" else -- 00000 1010 0xxx xxxx xxxx xxxx
	x"00"        when (addr(24 downto 17)="00000101"    ) and addr(1 downto 0)="01" else
	x"00"        when (addr(24 downto 17)="00000101"    ) and addr(1 downto 0)="10" else
	x"00"        when (addr(24 downto 17)="00000101"    ) and addr(1 downto 0)="11" else

	-- 68K ROMs interleaved
	slv_data_9A  when (addr(24 downto 16)="000001100"   ) and addr(0)='0' else -- ROM0 32K 00000 1100 0xxx xxxx xxxx xxxx
	slv_data_9B  when (addr(24 downto 16)="000001100"   ) and addr(0)='1' else -- ROM0 32K
	x"00"        when (addr(24 downto 16)="000001101"   ) and addr(0)='0' else -- x    32K 00000 1101 0xxx xxxx xxxx xxxx
	x"00"        when (addr(24 downto 16)="000001101"   ) and addr(0)='1' else -- x    32K
	x"00"        when (addr(24 downto 16)="000001110"   ) and addr(0)='0' else -- x    32K 00000 1110 0xxx xxxx xxxx xxxx
	x"00"        when (addr(24 downto 16)="000001110"   ) and addr(0)='1' else -- x    32K
	slv_data_10A when (addr(24 downto 15)="0000011110"  ) and addr(0)='0' else -- SLAP 16K 00000 1111 00xx xxxx xxxx xxxx
	slv_data_10B when (addr(24 downto 15)="0000011110"  ) and addr(0)='1' else -- SLAP 16K
	x"00"        when (addr(24 downto 16)="0000011111"  ) and addr(0)='0' else -- x    16K
	x"00"        when (addr(24 downto 16)="0000011111"  ) and addr(0)='1' else -- x    16K
	slv_data_7A  when (addr(24 downto 16)="000010000"   ) and addr(0)='0' else -- ROM1 32K 00001 0000 0xxx xxxx xxxx xxxx
	slv_data_7B  when (addr(24 downto 16)="000010000"   ) and addr(0)='1' else -- ROM1 32K
	x"00"        when (addr(24 downto 16)="000010001"   ) and addr(0)='0' else -- ROM2 32K 00001 0001 0xxx xxxx xxxx xxxx
	x"00"        when (addr(24 downto 16)="000010001"   ) and addr(0)='1' else -- ROM2 32K
	x"00"        when (addr(24 downto 16)="000010010"   ) and addr(0)='0' else -- ROM3 32K 00001 0010 0xxx xxxx xxxx xxxx
	x"00"        when (addr(24 downto 16)="000010010"   ) and addr(0)='1' else -- ROM3 32K
	x"00"        when (addr(24 downto 16)="000010011"   ) and addr(0)='0' else -- ROM4 32K 00001 0011 0xxx xxxx xxxx xxxx
	x"00"        when (addr(24 downto 16)="000010011"   ) and addr(0)='1' else -- ROM4 32K
	-- 6502 ROM
	slv_data_16S when (addr(24 downto 15)="0000101000"  ) else -- 32K
	slv_data_16R when (addr(24 downto 14)="00001010010" ) else -- 16K
	-- CHAR ROM
	slv_data_6P  when (addr(24 downto 13)="000010100110") else -- 16K
	(others=>'0');

	p_clk : process
	begin
		wait for CLK1M_period/2;
		clk_1M <= not clk_1M;
		if delay < max_delay then delay <= delay + 1; end if;
	end process;

	p_addr : process
	begin
		wait until rising_edge(clk_sys);
		clk_1M_last <= clk_1M;
		ioctl_wr <= ioctl_wr_next;
		if (ioctl_wait = '0' and download = '1' and clk_1M_last = '0' and clk_1M = '1') then
			ioctl_wr_next <= '1';
			addr <= addr + 1;
		else
			ioctl_wr_next <= '0';
		end if;
	end process;
end architecture arch;
