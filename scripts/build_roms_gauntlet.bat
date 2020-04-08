@echo off
REM List of ROMs required and their sizes and checksums

REM "proms"
REM "74s472-136037-101.7u", 512 CRC(2964f76f) SHA1(da966c35557ec1b95e1c39cd950c38a19bce2d67) /* MO timing        */
REM "74s472-136037-102.5l", 512 CRC(4d4fec6c) SHA1(3541b5c6405ad5742a3121dfd6acb227933de25a) /* MO flip control  */
REM "74s287-136037-103.4r", 256 CRC(6c5ccf08) SHA1(ff5dbadd85aa2e07b383a302fa399e875db8f84f) /* MO position/size */
REM "136032.101.e3"         256               SHA1(84d422b53547271e3a07342704a05ef481db3f99)
REM "136032.102.e5"         256               SHA1(2d327e78832edd67ca3909c25b8c8c839637a1ed)
REM "136032.103.f7.bin",    235               SHA1(0a42a4816c89447b16e1f3245409591efea98a4a)

REM "maincpu" /* 68000 code */
REM "136037-1409.7a",     32768 CRC(6fb8419c) SHA1(299fee0368f6027bacbb57fb469e817e64e0e41d)
REM "136037-1410.7b",     32768 CRC(931bd2a0) SHA1(d69b45758d1c252a93dbc2263efa9de1f972f62e)
REM "136037-1307.9a",     32768 CRC(46fe8743) SHA1(d5fa19e028a2f43658330c67c10e0c811d332780)
REM "136037-1308.9b",     32768 CRC(276e15c4) SHA1(7467b2ec21b1b4fcc18ff9387ce891495f4b064c)
REM "136037-205.10a",     16384 CRC(6d99ed51) SHA1(a7bc18f32908451859ba5cdf1a5c97ecc5fe325f)
REM "136037-206.10b",     16384 CRC(545ead91) SHA1(7fad5a63c6443249bb6dad5b2a1fd08ca5f11e10)

REM "audiocpu" /* 6502 code */
REM "136037-120.16r",     16384 CRC(6ee7f3cc) SHA1(b86676340b06f07c164690862c1f6f75f30c080b)
REM "136037-119.16s",     32768 CRC(fa19861f) SHA1(7568b4ab526bd5849f7ef70dfa6d1ef1f30c0abc)

REM "gfx1" /* 27128, second half is all 0x00 */
REM "136037-104.6p",      16384 CRC(6c276a1d) SHA1(ec383a8fdcb28efb86b7f6ba4a3306fea5a09d72)

REM "gfx2"
REM "136037-111.1a",      32768 CRC(91700f33) SHA1(fac1ce700c4cd46b643307998df781d637f193aa)
REM "136037-112.1b",      32768 CRC(869330be) SHA1(5dfaaf54ee2b3c0eaf35e8c17558313db9791616)
REM "136037-113.1l",      32768 CRC(d497d0a8) SHA1(bb715bcec7f783dd04151e2e3b221a72133bf17d)
REM "136037-114.1mn",     32768 CRC(29ef9882) SHA1(91e1465af6505b35cd97434c13d2b4d40a085946)
REM "136037-115.2a",      32768 CRC(9510b898) SHA1(e6c8c7af1898d548f0f01e4ff37c2c7b22c0b5c2)
REM "136037-116.2b",      32768 CRC(11e0ac5b) SHA1(729b7561d59d94ef33874a134b97bcd37573dfa6)
REM "136037-117.2l",      32768 CRC(29a5db41) SHA1(94f4f5dd39e724570a0f54af176ad018497697fd)
REM "136037-118.2mn",     32768 CRC(8bf3b263) SHA1(683d900ab7591ee661218be2406fb375a12e435c)

set rom_path_src=..\roms\gauntlet
set rom_path=..\source\gauntlet\ROMS

mkdir %rom_path%

REM PROMS
genrom.py %rom_path_src%\74s472-136037-101.7u PROM_7U %rom_path%\PROM_7U.vhd
genrom.py %rom_path_src%\74s472-136037-102.5l PROM_5L %rom_path%\PROM_5L.vhd
genrom.py %rom_path_src%\74s287-136037-103.4r PROM_4R %rom_path%\PROM_4R.vhd
genrom.py %rom_path_src%\136032.101.e3        PROM_3E %rom_path%\PROM_3E.vhd
genrom.py %rom_path_src%\136032.102.e5        PROM_5E %rom_path%\PROM_5E.vhd

REM "maincpu" /* 8*64k for 68000 code */
genrom.py %rom_path_src%\136037-1409.7a       ROM_7A  %rom_path%\ROM_7A.vhd
genrom.py %rom_path_src%\136037-1410.7b       ROM_7B  %rom_path%\ROM_7B.vhd
genrom.py %rom_path_src%\136037-1307.9a       ROM_9A  %rom_path%\ROM_9A.vhd
genrom.py %rom_path_src%\136037-1308.9b       ROM_9B  %rom_path%\ROM_9B.vhd
genrom.py %rom_path_src%\136037-205.10a       ROM_10A %rom_path%\ROM_10A.vhd
genrom.py %rom_path_src%\136037-206.10b       ROM_10B %rom_path%\ROM_10B.vhd

REM "audiocpu" /* 64k for 6502 code */
genrom.py %rom_path_src%\136037-120.16r       ROM_16R %rom_path%\ROM_16R.vhd
genrom.py %rom_path_src%\136037-119.16s       ROM_16S %rom_path%\ROM_16S.vhd

REM "gfx1"
genrom.py %rom_path_src%\136037-104.6p        ROM_6P  %rom_path%\ROM_6P.vhd

REM "gfx2"
genrom.py %rom_path_src%\136037-111.1a        ROM_1A  %rom_path%\ROM_1A.vhd
genrom.py %rom_path_src%\136037-112.1b        ROM_1B  %rom_path%\ROM_1B.vhd
genrom.py %rom_path_src%\136037-113.1l        ROM_1L  %rom_path%\ROM_1L.vhd
genrom.py %rom_path_src%\136037-114.1mn       ROM_1MN %rom_path%\ROM_1MN.vhd
genrom.py %rom_path_src%\136037-115.2a        ROM_2A  %rom_path%\ROM_2A.vhd
genrom.py %rom_path_src%\136037-116.2b        ROM_2B  %rom_path%\ROM_2B.vhd
genrom.py %rom_path_src%\136037-117.2l        ROM_2L  %rom_path%\ROM_2L.vhd
genrom.py %rom_path_src%\136037-118.2mn       ROM_2MN %rom_path%\ROM_2MN.vhd

echo ##################################################
echo # Remember these ROMs need to be manually adjusted
echo #   3E - only 32 bytes long
echo #   4R - only 4 bit data width
echo #   5E - only 4 bit data width
echo #   5L - only 128 bytes long
echo #   6P - only 16KB long
echo ##################################################

pause
