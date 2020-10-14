# Atari Gauntlet FPGA Arcade

## About
This is an FPGA implementation of Atari's arcade game "Gauntlet" from 1985, based on the SP-284 schematic circuit diagram.  

On a [Pipistrello](http://pipistrello.saanlima.com/index.php?title=Welcome_to_Pipistrello) FPGA board with a [SRAM expansion](https://oshpark.com/profiles/d18c7db) daughterboard it successfully runs all three games Gauntlet, Gauntlet II and Vindicators II that run on the original arcade. All sounds are implemeted, Pokey, YM2151 and TMS5220 Voice Synthesis Processor (see my [TMS5220 repository](https://github.com/d18c7db/TMS5220_FPGA) for more details on the VSP).  

[![Gauntlet Tile](doc/images/MAME_G1.png)](doc/images/MAME_G1.png)
[![Gauntlet 2 Title](doc/images/MAME_G2.png)](doc/images/MAME_G2.png)
[![Vindicators II Tile](doc/images/MAME_V2.png)](doc/images/MAME_V2.png)  

The videos below show some of the problems encountered earlier in the development.  

Youtube video of Gauntlet:  
[![Gauntlet running on FPGA](https://img.youtube.com/vi/7A2k7wLUSUU/0.jpg)](https://www.youtube.com/watch?v=7A2k7wLUSUU)

Additional video of FPGA running Gauntlet II ROMs  
[![Gauntlet II running on FPGA](https://img.youtube.com/vi/HNHAjOb2i3s/0.jpg)](https://www.youtube.com/watch?v=HNHAjOb2i3s)

The implementation is functional right now, can coin up and start game, known problems are as follows:

* Game EPROM is implemented as RAM so game settings are lost on power off.

## MiSTer Install
This repository follows the standard folder structure for distributing MiSTer files.

ROMs are not included. In order to use this arcade, you need to provide the
correct gauntlet.zip ROM.

To simplify the process .mra files are provided in the releases folder, that
specifies the required ROMs with checksums. The ROMs .zip filename refers to the
corresponding file of the M.A.M.E. project.

Please refer to https://github.com/MiSTer-devel/Main_MiSTer/wiki/Arcade-Roms for
information on how to setup and use the environment.

Quickreference for folders and file placement:

/_Arcade/<game name>.mra
/_Arcade/cores/<game rbf>.rbf
/_Arcade/mame/<mame rom>.zip
/_Arcade/hbmame/<hbmame rom>.zip

Gauntlet currently supports up to 4 joysticks for 4 players. (up, down, left, right, fire, start/magic, coin)
mame keys layout is available for player 1 (up, down left, right, ctrl, alt, 5) and player 2 (R, F, D, G, A, S, 6)
for player 3 and 4, only remains coins keys (7, and 8)

## Building

### Pipistrello
The project files are under `rtl/boards/pipistrello` and are setup for Xilinx ISE 14.7  
NOTE: Pipistrello needs an additional custom SRAM board for this project since the FPGA doesn't have enough internal memory. See https://oshpark.com/profiles/d18c7db  

### MiSTer

The project files are under `rtl/boards/miSTer` and are setup for Quartus 17  
*WARNING:* some MiSTer files in `sys` have been customized to allow the project to fully synthesize without errors due to the fitter being unable to fully place all memories.

At this stage only Gauntlet can be played on MiSTer due to the ROM sizes only just barely fitting in FPGA bram, perhaps with more effort the ROMs can be placed in external memory.  
