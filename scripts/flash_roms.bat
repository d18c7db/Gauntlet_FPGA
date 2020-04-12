@ECHO OFF

REM All ROMs are 32K except 10A, 10B, 16R which are 16K
SET ROMS=..\roms\gauntlet

REM Layout of ROMs in 16 bit wide RAM
REM               D15-D8 D7-D0
REM  00000-07FFF  1L     1A   32K-32K
REM  08000-0FFFF  1MN    1B   32K-32K
REM  10000-17FFF  2L     2A   32K-32K
REM  18000-1FFFF  2MN    2B   32K-32K
REM  20000-27FFF  7A     7B   32K-32K
REM  28000-2FFFF  9A     9B   32K-32K
REM  30000-33FFF  10A    10B  16K-16K
REM  34000-3BFFF  16R    16S  16K-32K

REM video ROMS
SET SOURCES=            %ROMS%\136037-111.1A
SET SOURCES=%SOURCES% + %ROMS%\136037-112.1B
SET SOURCES=%SOURCES% + %ROMS%\136037-115.2A
SET SOURCES=%SOURCES% + %ROMS%\136037-116.2B
REM 68K main audio program ROMS
SET SOURCES=%SOURCES% + %ROMS%\136037-1410.7B
SET SOURCES=%SOURCES% + %ROMS%\136037-1308.9B
SET SOURCES=%SOURCES% + %ROMS%\136037-206.10B
REM 6502 audio program ROMS
SET SOURCES=%SOURCES% + %ROMS%\136037-119.16S

REM video ROMS
SET SOURCES=%SOURCES% + %ROMS%\136037-113.1L
SET SOURCES=%SOURCES% + %ROMS%\136037-114.1MN
SET SOURCES=%SOURCES% + %ROMS%\136037-117.2L
SET SOURCES=%SOURCES% + %ROMS%\136037-118.2MN
REM 68K main program ROMS
SET SOURCES=%SOURCES% + %ROMS%\136037-1409.7A
SET SOURCES=%SOURCES% + %ROMS%\136037-1307.9A
SET SOURCES=%SOURCES% + %ROMS%\136037-205.10A
REM 6502 audio program ROMS
SET SOURCES=%SOURCES% + %ROMS%\136037-120.16R

COPY/B %SOURCES% ROMS.BIN >NUL

REM Write bitstream and ROMS to flash
..\..\papilio-prog.exe -b ..\..\pipistrello_bscan_spi_6slx45csg324.bit -f ..\iseconfig\build\gauntlet_top.bit -a 200000:ROMS.BIN -v
REM DEL ROMS.BIN
PAUSE