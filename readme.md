# Atari Gauntlet FPGA Arcade

## About
This is an FPGA implementation of Atari's arcade game "Gauntlet" from 1985, based on the SP-284 schematic circuit diagram.  
It successfully runs all three games Gauntlet, Gauntlet II and Vindicators II that were used on the original arcade.  
All sounds are implemeted, Pokey, YM2151 and TMS5220 Speech Synthesizer.  

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

## Building

### Pipistrello
The project files are under `rtl/boards/pipistrello` and are setup for Xilinx ISE 14.7  
NOTE: Pipistrello needs an additional custom SRAM board for this project since the FPGA doesn't have enough internal memory. See https://oshpark.com/profiles/d18c7db  

### MiSTer
The project files are under `rtl/boards/miSTer` and are setup for Quartus 17  
*WARNING:* some MiSTer files in `sys` have been customized to allow the project to fully synthesize without errors due to the fitter being unable to fully place all memories.

To play on MiSTer, place the gauntlet.zip ROM files in the folder `rtl/boards/miSTer/_Arcade/mame`, then copy the folder `_Arcade` as is to the MiSTer SD card root.  
At this stage only Gauntlet can be played on MiSTer due to the ROM sizes only just barely fitting in FPGA bram, perhaps with more effort the ROMs can be placed in external memory.  
