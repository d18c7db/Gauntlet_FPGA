@echo off
REM List of ROMs required and their sizes and checksums

REM "proms"
REM "74s472-136037-101.7u",  512 CRC(2964f76f) SHA1(da966c35557ec1b95e1c39cd950c38a19bce2d67) /* MO timing        */
REM "74s472-136037-102.5l",  512 CRC(4d4fec6c) SHA1(3541b5c6405ad5742a3121dfd6acb227933de25a) /* MO flip control  */
REM "82s129-136043-1103.4r", 256 CRC(32ae1fa9) SHA1(09eb56a0798456d73015909973ce2ba9660c1164) /* MO position/size */
REM "136032.101.e3"          256               SHA1(84d422b53547271e3a07342704a05ef481db3f99)
REM "136032.102.e5"          256               SHA1(2d327e78832edd67ca3909c25b8c8c839637a1ed)
REM "136032.103.f7.bin",     235               SHA1(0a42a4816c89447b16e1f3245409591efea98a4a)

REM "maincpu" /* 68010 code */
REM "136043-1121.6a",     32768 CRC(ae301bba) SHA1(3d93236aaffe6ef692e5073b1828633e8abf0ce4)
REM "136043-1122.6b",     32768 CRC(e94aaa8a) SHA1(378c582c360440b808820bcd3be78ec6e8800c34)
REM "136043-1109.7a",     32768 CRC(58a0a9a3) SHA1(7f51184840e3c96574836b8a00bfb4a7a5f508d0)
REM "136043-1110.7b",     32768 CRC(658f0da8) SHA1(dfce027ea50188659907be698aeb26f9d8bfab23)
REM "136037-1307.9a",     32768 CRC(46fe8743) SHA1(d5fa19e028a2f43658330c67c10e0c811d332780)
REM "136037-1308.9b",     32768 CRC(276e15c4) SHA1(7467b2ec21b1b4fcc18ff9387ce891495f4b064c)
REM "136043-1105.10a",    16384 CRC(45dfda47) SHA1(a9a03150f5a0ad6ce62c5cfdffb4a9f54340590c)
REM "136043-1106.10b",    16384 CRC(343c029c) SHA1(d2df4e5b036500dcc537a1e0025abb2a8c730bdd)

REM "audiocpu" /* 6502 code */
REM "136043-1120.16r",    16384 CRC(5c731006) SHA1(045ad571db34ef870b1bf003e77eea403204f55b)
REM "136043-1119.16s",    32768 CRC(dc3591e7) SHA1(6d0d8493609974bd5a63be858b045fe4db35d8df)

REM "gfx1" second half filled with FF
REM "136043-1104.6p",      8192 CRC(1343cf6f) SHA1(4a9542bc8ede305e7e8f860eb4b47ca2f3017275)

REM "gfx2"
REM "136043-1111.1a",     32768 CRC(09df6e23) SHA1(726984275c6a338c12ec0c4cc449f92f4a7a138c)
REM "136037-112.1b",      32768 CRC(869330be) SHA1(5dfaaf54ee2b3c0eaf35e8c17558313db9791616)
REM "136043-1123.1c",     16384 CRC(e4c98f01) SHA1(a24bece3196d13c38e4acdbf62783860253ba67d)
REM "136043-1113.1l",     32768 CRC(33cb476e) SHA1(e0757ee0120de2d38be44f8dc8702972c35b87b3)
REM "136037-114.1mn",     32768 CRC(29ef9882) SHA1(91e1465af6505b35cd97434c13d2b4d40a085946)
REM "136043-1124.1p",     16384 CRC(c4857879) SHA1(3b4ce96da0d178b4bc2d05b5b51b42c7ec461113)
REM "136043-1115.2a",     32768 CRC(f71e2503) SHA1(244e108668eaef6b64c6ff733b08b9ee6b7a2d2b)
REM "136037-116.2b",      32768 CRC(11e0ac5b) SHA1(729b7561d59d94ef33874a134b97bcd37573dfa6)
REM "136043-1125.2c",     16384 CRC(d9c2c2d1) SHA1(185e38c75c06b6ca131a17ee3a46098279bfe17e)
REM "136043-1117.2l",     32768 CRC(9e30b2e9) SHA1(e9b513089eaf3bec269058b437fefe7075a3fd6f)
REM "136037-118.2mn",     32768 CRC(8bf3b263) SHA1(683d900ab7591ee661218be2406fb375a12e435c)
REM "136043-1126.2p",     16384 CRC(a32c732a) SHA1(abe801dff7bb3f2712e2189c2b91f172d941fccd)


set rom_path_src=..\roms\gaunt2
set rom_path=..\source\gauntlet\ROMS.G2

mkdir %rom_path%

REM PROMS
genrom.py %rom_path_src%\74s472-136037-101.7u  PROM_7U %rom_path%\PROM_7U.vhd
genrom.py %rom_path_src%\74s472-136037-102.5l  PROM_5L %rom_path%\PROM_5L.vhd
genrom.py %rom_path_src%\82s129-136043-1103.4r PROM_4R %rom_path%\PROM_4R.vhd
genrom.py %rom_path_src%\136032.101.e3         PROM_3E %rom_path%\PROM_3E.vhd
genrom.py %rom_path_src%\136032.102.e5         PROM_5E %rom_path%\PROM_5E.vhd

REM "maincpu" /* 8*64k for 68000 code */
genrom.py %rom_path_src%\136043-1121.6a       ROM_6A  %rom_path%\ROM_6A.vhd
genrom.py %rom_path_src%\136043-1122.6b       ROM_6B  %rom_path%\ROM_6B.vhd
genrom.py %rom_path_src%\136043-1109.7a       ROM_7A  %rom_path%\ROM_7A.vhd
genrom.py %rom_path_src%\136043-1110.7b       ROM_7B  %rom_path%\ROM_7B.vhd
genrom.py %rom_path_src%\136037-1307.9a       ROM_9A  %rom_path%\ROM_9A.vhd
genrom.py %rom_path_src%\136037-1308.9b       ROM_9B  %rom_path%\ROM_9B.vhd
genrom.py %rom_path_src%\136043-1105.10a      ROM_10A %rom_path%\ROM_10A.vhd
genrom.py %rom_path_src%\136043-1106.10b      ROM_10B %rom_path%\ROM_10B.vhd

REM "audiocpu" /* 64k for 6502 code */
genrom.py %rom_path_src%\136043-1120.16r      ROM_16R %rom_path%\ROM_16R.vhd
genrom.py %rom_path_src%\136043-1119.16s      ROM_16S %rom_path%\ROM_16S.vhd

REM "gfx1"
genrom.py %rom_path_src%\136043-1104.6p       ROM_6P  %rom_path%\ROM_6P.vhd

REM "gfx2"
genrom.py %rom_path_src%\136043-1111.1a       ROM_1A  %rom_path%\ROM_1A.vhd
genrom.py %rom_path_src%\136037-112.1b        ROM_1B  %rom_path%\ROM_1B.vhd
genrom.py %rom_path_src%\136043-1123.1c       ROM_1C  %rom_path%\ROM_1C.vhd
genrom.py %rom_path_src%\136043-1113.1l       ROM_1L  %rom_path%\ROM_1L.vhd
genrom.py %rom_path_src%\136037-114.1mn       ROM_1MN %rom_path%\ROM_1MN.vhd
genrom.py %rom_path_src%\136043-1124.1p       ROM_1P  %rom_path%\ROM_1P.vhd
genrom.py %rom_path_src%\136043-1115.2a       ROM_2A  %rom_path%\ROM_2A.vhd
genrom.py %rom_path_src%\136037-116.2b        ROM_2B  %rom_path%\ROM_2B.vhd
genrom.py %rom_path_src%\136043-1125.2c       ROM_2C  %rom_path%\ROM_2C.vhd
genrom.py %rom_path_src%\136043-1117.2l       ROM_2L  %rom_path%\ROM_2L.vhd
genrom.py %rom_path_src%\136037-118.2mn       ROM_2MN %rom_path%\ROM_2MN.vhd
genrom.py %rom_path_src%\136043-1126.2p       ROM_2P  %rom_path%\ROM_2P.vhd

echo ##################################################
echo # Remember these ROMs need to be manually adjusted
echo #   3E - only 32 bytes long
echo #   4R - only 4 bit data width
echo #   5E - only 4 bit data width
echo #   5L - only 128 bytes long
echo #   6P - only 8KB long, second 8K filled with FF
echo ##################################################

pause
