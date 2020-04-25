# Atari Gauntlet FPGA Arcade

## About
This is an FPGA implementation of Atari's arcade game "Gauntlet" from 1985, based on the SP-284 schematic circuit diagram.  
It successfully runs all three games Gauntlet, Gauntlet II and Vindicators II that were used on the original arcade.  

[![Gauntlet Tile](doc/images/MAME_G1.png)](doc/images/MAME_G1.png)  
[![Gauntlet 2 Title](doc/images/MAME_G2.png)](doc/images/MAME_G2.png)  
[![Vindicators II Tile](doc/images/MAME_V2.png)](doc/images/MAME_V2.png)  

The videos below show some of the problems encountered earlier in the development.

Youtube video of Gauntlet:  
[![Gauntlet running on FPGA](https://img.youtube.com/vi/7A2k7wLUSUU/0.jpg)](https://www.youtube.com/watch?v=7A2k7wLUSUU)

Additional video of FPGA running Gauntlet II ROMs  
[![Gauntlet II running on FPGA](https://img.youtube.com/vi/HNHAjOb2i3s/0.jpg)](https://www.youtube.com/watch?v=HNHAjOb2i3s)

The implementation is functional right now, can coin up and start game, known problems are as follows:

* The TMS5220 speech synth is not implemented
* Audio mixing is not ideal, sound quality needs improvement.
* Game EPROM is implemented as RAM so game settings are lost on power off.
* Some game ROMs are stored external to FPGA, multiplexing may need improvement.
* Only player 1 controls are connected (minor).
