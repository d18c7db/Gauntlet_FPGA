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

entity TMS5220 is
	port (
		-- inputs
		I_OSC			: in	std_logic;	--	pin 6	typ 640KHz
		I_WSn			: in	std_logic;	--	pin 27	Write Select
		I_RSn			: in	std_logic;	--	pin 28	Read Select
		I_DATA		: in	std_logic;	--	pin 21	Serial Data In (alt function)
		I_TEST		: in	std_logic;	--	pin 20	Test use only
		I_DBUS		: in	std_logic_vector(7 downto 0);	--	pins 1,26,24,22,19,12,13,14
		-- outputs
		O_DBUS		: out	std_logic_vector(7 downto 0);	--	pins 1,26,24,22,19,12,13,14
		O_RDYn		: out	std_logic;	--	pin 18	Transfer cycle complete
		O_INTn		: out	std_logic;	--	pin 17	Interrupt

		O_M0			: out	std_logic;	--	pin 15	VSM command bit 0
		O_M1			: out	std_logic;	--	pin 16	VSM command bit 1
		O_ADD8		: out	std_logic;	--	pin 21	VSM Addr	(alt function)
		O_ADD4		: out	std_logic;	--	pin 23	VSM Addr
		O_ADD2		: out	std_logic;	--	pin 25	VSM Addr
		O_ADD1		: out	std_logic;	--	pin 2		VSM Addr
		O_ROMCLK		: out	std_logic;	--	pin 3		VSM clock

		O_T11			: out	std_logic;	--	pin 7		Sync
		O_IO			: out	std_logic;	--	pin 9		Serial Data Out
		O_PRMOUT		: out	std_logic;	--	pin 10	Test use only
		O_SPKR		: out	signed(7 downto 0)	--	pin 8		Audio Output
	);
end entity;

architecture RTL of TMS5220 is
	signal rdy		: std_logic := '0';
	signal int_n	: std_logic := '1';
	signal dbus		: std_logic_vector( 7 downto 0) := (others=>'0');

begin
	-- FIXME implement TMS5220 core

	O_DBUS	<= dbus;
	O_RDYn	<= rdy;
	O_INTn	<= int_n;

	O_SPKR	<= (others=>'0');	-- speaker out

	-- VSM memory bus driver (not implemented)
	O_M0		<= '0';
	O_M1		<= '0';
	O_ADD8	<= '0';
	O_ADD4	<= '0';
	O_ADD2	<= '0';
	O_ADD1	<= '0';
	O_ROMCLK	<= '0';

	O_T11		<= '0';	-- sync
	O_IO		<= '0';	-- serial out
	O_PRMOUT	<= '0';	-- test use

end architecture;
