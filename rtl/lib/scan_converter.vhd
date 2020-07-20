--	(c) 2012 d18c7db(a)hotmail
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

--------------------------------------------------------------------------------
-- Video scan converter - works with active negative input sync signals
--

-- _____________              _____________________              ____________________
-- VIDEO (last) |____________|        VIDEO        |____________|        VIDEO (next)
-- --V----------|-F-|-S-|--B-|----------V----------|-F-|-S-|--B-|----------V---------
-- _________________|   |______________________________|   |_________________________
--  SYNC            |___|              SYNC            |___|              SYNC

------------------------------------------------------------------------------------------------------------------
-- HORIZONTAL   - Line       | Pixel      | Front     | HSYNC      | Back       | Active     | HSYNC    | Total  |
-- Resolution   - Rate       | Clock      | Porch (F) | Pulse (S)  | Porch (B)  | Video (V)  | Polarity | Pixels |
------------------------------------------------------------------------------------------------------------------
--  VGA 640x480 - 31468.75Hz | 25.175 MHz | 16 pixels |  96 pixels |  48 pixels | 640 pixels | negative | 800    |
------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------
-- VERTICAL     - Frame      | Pixel      | Front     | VSYNC      | Back       | Active     | VSYNC    | Total  |
-- Resolution   - Rate       | Clock      | Porch (F) | Pulse (S)  | Porch (B)  | Video (V)  | Polarity | Pixels |
------------------------------------------------------------------------------------------------------------------
--  VGA 640x480 - 59.94Hz    | 25.175 MHz | 10 lines  | 2 lines    | 33 lines   | 480 lines  | negative | 525    |
------------------------------------------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_unsigned.all;
	use ieee.numeric_std.all;

--pragma translate_off
	use ieee.std_logic_textio.all;
	use std.textio.all;
--pragma translate_on

library UNISIM;
	use UNISIM.Vcomponents.all;

library UNIMACRO;
	use UNIMACRO.vcomponents.all;

entity VGA_SCANCONV is
	generic (
		vstart		: integer range 0 to 1023 := 127;	-- start  of active video
		vlength		: integer range 0 to 1023 := 256;	-- length of active video

		hF				: integer range 0 to 1023 :=   8;	-- h front porch
		hS				: integer range 0 to 1023 :=  45;	-- h sync
		hB				: integer range 0 to 1023 :=  23;	-- h back porch
		hV				: integer range 0 to 1023 := 256;	-- visible video
		hpad			: integer range 0 to 1023 :=  26;	-- H black border

		vF				: integer range 0 to 1023 :=  35;	-- v front porch
		vS				: integer range 0 to 1023 :=   2;	-- v sync
		vB				: integer range 0 to 1023 :=  35;	-- v back porch
		vV				: integer range 0 to 1023 := 226;	-- visible video
		vpad			: integer range 0 to 1023 :=   0		-- V black border
	);
	port (
		I_VIDEO				: in  std_logic_vector(15 downto 0);
		I_HSYNC				: in  std_logic;
		I_VSYNC				: in  std_logic;
		--
		O_VIDEO				: out std_logic_vector(15 downto 0);
		O_HSYNC				: out std_logic;
		O_VSYNC				: out std_logic;
		O_CMPBLK_N			: out std_logic;
		--
		CLK					: in  std_logic;
		CLK_x2				: in  std_logic
	);
end;

architecture RTL of VGA_SCANCONV is
	signal
		ihsync,
		ivsync,
		ihsync_last,
		ivsync_last,
		cmpblk_n,
		alt,
		ovsync,
		ovsync_last,
		ohsync
								: std_logic := '1';
	signal
		hpos_i,
		hpos_o
								: std_logic_vector(8 downto 0) := (others => '0');
	signal
		RDADDR,
		WRADDR
								: std_logic_vector(9 downto 0) := (others => '0');
	signal
		ivideo,
		ovideo
								: std_logic_vector(15 downto 0) := (others => '0');

	signal vcnto			: integer range 0 to 1023 := 0;
	signal hcnto			: integer range 0 to 1023 := 0;
	signal hcnti			: integer range 0 to 1023 := 0;

	type RAM_ARRAY_1Kx16 is array (0 to 1023) of std_logic_vector(15 downto 0);
	signal DPRAM : RAM_ARRAY_1Kx16:=(others=>(others=>'0'));

	-- Ask synthesis tools to use block RAMs if possible
	attribute ram_style : string;
	attribute ram_style of DPRAM : signal is "block";

begin
	-- convert input video from 16bit IRGB to 12 bit RGB
	u_R : entity work.RGBI port map (ADDR(7 downto 4)=>I_VIDEO(15 downto 12), ADDR(3 downto 0)=>I_VIDEO(11 downto 8), DATA=>ivideo(11 downto 8));
	u_G : entity work.RGBI port map (ADDR(7 downto 4)=>I_VIDEO(15 downto 12), ADDR(3 downto 0)=>I_VIDEO( 7 downto 4), DATA=>ivideo( 7 downto 4));
	u_B : entity work.RGBI port map (ADDR(7 downto 4)=>I_VIDEO(15 downto 12), ADDR(3 downto 0)=>I_VIDEO( 3 downto 0), DATA=>ivideo( 3 downto 0));

	-- simple dual port RAM (read port)
	p_SDP_RAM_RD : process
	begin
		wait until falling_edge(CLK_x2);
		ovideo <= DPRAM(to_integer(unsigned(RDADDR)));
	end process;

	-- simple dual port RAM (write port)
	p_SDP_RAM_WR : process
	begin
		wait until rising_edge(CLK_x2);
		if CLK = '1' then
			DPRAM(to_integer(unsigned(WRADDR))) <= ivideo;
		end if;
	end process;

	O_VIDEO		<= ovideo;
	O_HSYNC		<= ohsync;
	O_VSYNC		<= ovsync;
	O_CMPBLK_N	<= cmpblk_n;
	RDADDR		<= (not alt) & hpos_o;
	WRADDR		<=      alt  & hpos_i;

	ihsync		<= I_HSYNC;
	ivsync		<= I_VSYNC;

	-- edge transition helper signals
	p_det_egdes : process
	begin
		wait until rising_edge(CLK_x2);
		ihsync_last <= ihsync;
		ivsync_last <= ivsync;
		ovsync_last <= ovsync;
	end process;

	-------------------------
	-- Input Video Section
	-------------------------

	-- horizontal master counter for input video, reset on falling edge of HSYNC
	p_hcounter : process
	begin
		wait until rising_edge(CLK_x2);
		if (ihsync_last = '1') and (ihsync = '0') then
			hcnti <= 0;
		elsif CLK = '0' then
			hcnti <= hcnti + 1;
		end if;
	end process;

	-- memory selector for double buffering, half the memory is written to while
	-- the other half is read out at double speed, then the two halves are swapped
	p_memsel : process
	begin
		wait until rising_edge(CLK_x2);
		-- start of active input video configurable for dumb misaligned HSYNC signals
		if CLK = '0' then
			if hcnti = 0 then
				alt <= not alt;
			end if;
		end if;
	end process;

	-- increment RAM write position during HSYNC active video portion only
	p_ram_in : process
	begin
		wait until rising_edge(CLK_x2);
		if CLK = '0' then
			if (hcnti > 0) and (hcnti < vstart) then
				hpos_i <= (others => '0');
			else
				hpos_i <= hpos_i + 1;
			end if;
		end if;
	end process;

	-------------------------
	-- Output Video Section
	-------------------------

	-- VGA H and V counters, synchronized to input frame V sync, then H sync
	p_out_ctrs : process
		variable trigger : boolean;
	begin
		wait until rising_edge(CLK_x2);
		if (ivsync_last = '1') and (ivsync = '0') then
			trigger := true;
		end if;

		if trigger and ihsync = '0' then
			trigger := false;
			hcnto <= 0;
			vcnto <= 0;
		else
			if hcnto = (hF+hS+hB+hV+hpad+hpad-1) then
				hcnto <= 0;
				vcnto <= vcnto + 1;
			else
				hcnto <= hcnto + 1;
			end if;
		end if;
	end process;

	-- generate output HSYNC
	p_gen_hsync : process
	begin
		wait until rising_edge(CLK_x2);
		-- H sync timing
		if (hcnto < hS) then
			ohsync <= '0';
		else
			ohsync <= '1';
		end if;
	end process;

	-- generate output VSYNC
	p_gen_vsync : process
	begin
		wait until rising_edge(CLK_x2);
		-- V sync timing
		if (vcnto >= vF) and (vcnto < vF+vS) then
			ovsync <= '0';
		else
			ovsync <= '1';
		end if;
	end process;

	-- generate active output video
	p_gen_active_vid : process
	begin
		wait until rising_edge(CLK_x2);
		-- if hcnto within the visible video area
		if ((hcnto >= (hF + hS + hB + hpad)) and (hcnto < (hF + hS + hB + hV + hpad))) then
			hpos_o <= hpos_o + 1;
		else
			hpos_o <= (others => '0');
		end if;
	end process;

	-- generate blanking signal including additional borders to pad the input signal to standard VGA resolution
	p_gen_blank : process
	begin
		wait until rising_edge(CLK_X2);
		-- active video area after padding with blank borders
		if ((hcnto >= (hS + hB)) and (hcnto < (hS + hB + hV + 2*hpad))) and ((vcnto > 2*(vS + vB)) and (vcnto <= 2*(vS + vB + vV + 2*vpad))) then
			cmpblk_n <= '1';
		else
			cmpblk_n <= '0';
		end if;
	end process;

-- this section below between pragma translate_off - translate_on is not synthesizeable
--	used for debuging during simulation to write .ppm format video frames to output files
--	pragma translate_off

	-- this process dumps the input of the scan converter to a .ppm file
	p_debug_in : process
		file		qfile			: TEXT open WRITE_MODE is "..\..\SIM\I3000000.ppm";
		variable	qidx			: integer := 3000000;
		variable	s				: line;
		variable ending		: boolean := false;
	begin
		wait until rising_edge(CLK_x2);
		-- if start of frame
		if (ivsync_last = '0') and (ivsync = '1') then
			ending := true;
		end if;

		-- wait for a suitable spot on the horizontal line to start new video frame
		if ending and (hcnti = vstart) then
			ending := false;
			qidx := qidx + 1;				-- frame number
			file_close(qfile);
			write(s,"..\..\SIM\I"); write(s,qidx); write(s,".ppm");
			file_open(qfile, s.all, WRITE_MODE);
			writeline(output, s);
			write(s,"P3");						writeline(qfile,s);	--	P3 means ASCII format
			write(s,"# "); write(s, now);	writeline(qfile,s);	-- sim time at start of frame
			write(s,"369 263 15");			writeline(qfile,s);	--	width height colors
		end if;

		if CLK = '1' then
			if (hpos_i /= 0) then
--				write(s, to_integer(unsigned(I_VIDEO(15 downto 12) * I_VIDEO(11 downto 8)))/15 ); write(s," ");			-- R
--				write(s, to_integer(unsigned(I_VIDEO(15 downto 12) * I_VIDEO( 7 downto 4)))/15 ); write(s," ");			-- G
--				write(s, to_integer(unsigned(I_VIDEO(15 downto 12) * I_VIDEO( 3 downto 0)))/15 ); writeline(qfile,s);	-- B
				write(s, to_integer(unsigned(ivideo(11 downto 8)))); write(s," ");			-- R
				write(s, to_integer(unsigned(ivideo( 7 downto 4)))); write(s," ");			-- G
				write(s, to_integer(unsigned(ivideo( 3 downto 0)))); writeline(qfile,s);	-- B
			end if;
		end if;
	end process;

--	-- this process dumps the output of the scan converter to a .ppm file
--	p_debug_out : process
--		file		ofile			: TEXT open WRITE_MODE is "..\..\SIM\O3000000.ppm";
--		variable	oidx			: integer := 3000000;
--		variable	s				: line;
--		variable ending		: boolean := false;
--	begin
--		wait until rising_edge(CLK_x2);
--		-- if start of frame
--		if (ovsync_last = '0') and (ovsync = '1') then
--			ending := true;
--		end if;
--
--		-- wait for a suitable spot on the horizontal line to start new video frame
--		if ending and (hcnto = (hF + hS + hB + hpad + 1)) then
--			ending := false;
--			oidx := oidx + 1;				-- frame number
--			file_close(ofile);
--			write(s,"..\..\SIM\O"); write(s,oidx); write(s,".ppm");
--			file_open(ofile, s.all, WRITE_MODE);
--			writeline(output, s);
--			write(s,"P3");						writeline(ofile,s);	--	P3 means ASCII format
--			write(s,"# "); write(s, now);	writeline(ofile,s);	-- sim time at start of frame
--			write(s,"672 526 15");			writeline(ofile,s);	--	width height colors
--		end if;
--
--		if (hpos_o /= 0) then
--			write(s, to_integer(unsigned(ovideo(11 downto 8)))); write(s," ");			-- R
--			write(s, to_integer(unsigned(ovideo( 7 downto 4)))); write(s," ");			-- G
--			write(s, to_integer(unsigned(ovideo( 3 downto 0)))); writeline(ofile,s);	-- B
--			-- to preserve aspect ratio of image with doubled lines, write each pixel twice
--			write(s, to_integer(unsigned(ovideo(11 downto 8)))); write(s," ");			-- R
--			write(s, to_integer(unsigned(ovideo( 7 downto 4)))); write(s," ");			-- G
--			write(s, to_integer(unsigned(ovideo( 3 downto 0)))); writeline(ofile,s);	-- B
--		end if;
--	end process;

--	pragma translate_on
end architecture RTL;
