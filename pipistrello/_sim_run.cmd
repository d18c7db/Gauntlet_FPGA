@ECHO OFF

SET TOPLEVEL=tb_gauntlet

mkdir iseconfig\build
cd iseconfig\build

echo verilog work "C:/Xilinx/14.7/ISE_DS/ISE//verilog/src/glbl.v" 1>%TOPLEVEL%_isim_beh.prj
echo verilog work "../../../../lib/debug/async_transmitter.v" 1>>%TOPLEVEL%_isim_beh.prj
echo verilog work "../../../../lib/debug/async_receiver.v" 1>>%TOPLEVEL%_isim_beh.prj
echo verilog work "../../../../lib/jt51/jt51_sh.v" 1>>%TOPLEVEL%_isim_beh.prj
echo verilog work "../../../../lib/jt51/jt51_mod.v" 1>>%TOPLEVEL%_isim_beh.prj
echo verilog work "../../../../lib/jt51/jt51_kon.v" 1>>%TOPLEVEL%_isim_beh.prj
echo verilog work "../../../../lib/jt51/jt51_csr_op.v" 1>>%TOPLEVEL%_isim_beh.prj
echo verilog work "../../../../lib/jt51/jt51_csr_ch.v" 1>>%TOPLEVEL%_isim_beh.prj
echo verilog work "../../../../lib/jt51/jt51_reg.v" 1>>%TOPLEVEL%_isim_beh.prj
echo verilog work "../../../../lib/jt51/jt51_pm.v" 1>>%TOPLEVEL%_isim_beh.prj
echo verilog work "../../../../lib/jt51/jt51_phrom.v" 1>>%TOPLEVEL%_isim_beh.prj
echo verilog work "../../../../lib/jt51/jt51_phinc_rom.v" 1>>%TOPLEVEL%_isim_beh.prj
echo verilog work "../../../../lib/jt51/jt51_noise_lfsr.v" 1>>%TOPLEVEL%_isim_beh.prj
echo verilog work "../../../../lib/jt51/jt51_lin2exp.v" 1>>%TOPLEVEL%_isim_beh.prj
echo verilog work "../../../../lib/jt51/jt51_lfo_lfsr.v" 1>>%TOPLEVEL%_isim_beh.prj
echo verilog work "../../../../lib/jt51/jt51_exprom.v" 1>>%TOPLEVEL%_isim_beh.prj
echo verilog work "../../../../lib/jt51/jt51_exp2lin.v" 1>>%TOPLEVEL%_isim_beh.prj
echo verilog work "../../../../lib/jt51/jt51_timers.v" 1>>%TOPLEVEL%_isim_beh.prj
echo verilog work "../../../../lib/jt51/jt51_pg.v" 1>>%TOPLEVEL%_isim_beh.prj
echo verilog work "../../../../lib/jt51/jt51_op.v" 1>>%TOPLEVEL%_isim_beh.prj
echo verilog work "../../../../lib/jt51/jt51_noise.v" 1>>%TOPLEVEL%_isim_beh.prj
echo verilog work "../../../../lib/jt51/jt51_mmr.v" 1>>%TOPLEVEL%_isim_beh.prj
echo verilog work "../../../../lib/jt51/jt51_lfo.v" 1>>%TOPLEVEL%_isim_beh.prj
echo verilog work "../../../../lib/jt51/jt51_eg.v" 1>>%TOPLEVEL%_isim_beh.prj
echo verilog work "../../../../lib/jt51/jt51_acc.v" 1>>%TOPLEVEL%_isim_beh.prj
echo verilog work "../../../../lib/jt51/jt51.v" 1>>%TOPLEVEL%_isim_beh.prj
echo vhdl work "../../../../lib/debug/debug.vhd" 1>>%TOPLEVEL%_isim_beh.prj
echo vhdl work "../../../../lib/TG68K/TG68K_Pack.vhd" 1>>%TOPLEVEL%_isim_beh.prj
echo vhdl work "../../../../lib/TG68K/TG68K_ALU.vhd" 1>>%TOPLEVEL%_isim_beh.prj
echo vhdl work "../../../../lib/T65/T65_Pack.vhd" 1>>%TOPLEVEL%_isim_beh.prj
echo vhdl work "../../../../lib/TG68K/TG68KdotC_Kernel.vhd" 1>>%TOPLEVEL%_isim_beh.prj
echo vhdl work "../../../../lib/T65/T65_MCode.vhd" 1>>%TOPLEVEL%_isim_beh.prj
echo vhdl work "../../../../lib/T65/T65_ALU.vhd" 1>>%TOPLEVEL%_isim_beh.prj
echo vhdl work "../../../../gauntlet/ROMS.G1/PROM_5E.vhd" 1>>%TOPLEVEL%_isim_beh.prj
echo vhdl work "../../../../gauntlet/LS299.vhd" 1>>%TOPLEVEL%_isim_beh.prj
echo vhdl work "../../../../gauntlet/LINEBUF.vhd" 1>>%TOPLEVEL%_isim_beh.prj
echo vhdl work "../../../../lib/T65/T65.vhd" 1>>%TOPLEVEL%_isim_beh.prj
echo vhdl work "../../../../lib/POKEY.vhd" 1>>%TOPLEVEL%_isim_beh.prj
echo vhdl work "../../../../lib/bitmap/bmp_pkg.vhd" 1>>%TOPLEVEL%_isim_beh.prj
echo vhdl work "../../../../gauntlet/VRAMS.vhd" 1>>%TOPLEVEL%_isim_beh.prj
echo vhdl work "../../../../gauntlet/TMS5220.vhd" 1>>%TOPLEVEL%_isim_beh.prj
echo vhdl work "../../../../gauntlet/TG68K.vhd" 1>>%TOPLEVEL%_isim_beh.prj
echo vhdl work "../../../../gauntlet/SYNGEN.vhd" 1>>%TOPLEVEL%_isim_beh.prj
echo vhdl work "../../../../gauntlet/SLAPSTIC.vhd" 1>>%TOPLEVEL%_isim_beh.prj
echo vhdl work "../../../../gauntlet/SLAGS.vhd" 1>>%TOPLEVEL%_isim_beh.prj
echo vhdl work "../../../../gauntlet/ROMS.G1/ROM_6P.vhd" 1>>%TOPLEVEL%_isim_beh.prj
echo vhdl work "../../../../gauntlet/ROMS.G1/PROM_5L.vhd" 1>>%TOPLEVEL%_isim_beh.prj
echo vhdl work "../../../../gauntlet/ROMS.G1/PROM_4R.vhd" 1>>%TOPLEVEL%_isim_beh.prj
echo vhdl work "../../../../gauntlet/ROMS.G1/EEP_14A.vhd" 1>>%TOPLEVEL%_isim_beh.prj
echo vhdl work "../../../../gauntlet/RAM_2K8.vhd" 1>>%TOPLEVEL%_isim_beh.prj
echo vhdl work "../../../../gauntlet/PFHS.vhd" 1>>%TOPLEVEL%_isim_beh.prj
echo vhdl work "../../../../gauntlet/MOHLB.vhd" 1>>%TOPLEVEL%_isim_beh.prj
echo vhdl work "../../../../gauntlet/GPC.vhd" 1>>%TOPLEVEL%_isim_beh.prj
echo vhdl work "../../../../gauntlet/CRAMS.vhd" 1>>%TOPLEVEL%_isim_beh.prj
echo vhdl work "../../../../lib/tmds_encoder.vhd" 1>>%TOPLEVEL%_isim_beh.prj
echo vhdl work "../../../../lib/spi_flash.vhd" 1>>%TOPLEVEL%_isim_beh.prj
echo vhdl work "../../../../lib/bitmap/bmp_out.vhd" 1>>%TOPLEVEL%_isim_beh.prj
echo vhdl work "../../../../gauntlet/VIDEO.vhd" 1>>%TOPLEVEL%_isim_beh.prj
echo vhdl work "../../../../gauntlet/RGBI.vhd" 1>>%TOPLEVEL%_isim_beh.prj
echo vhdl work "../../../../gauntlet/MAIN.vhd" 1>>%TOPLEVEL%_isim_beh.prj
echo vhdl work "../../../../gauntlet/AUDIO.vhd" 1>>%TOPLEVEL%_isim_beh.prj
echo vhdl work "../../../../lib/scan_converter.vhd" 1>>%TOPLEVEL%_isim_beh.prj
echo vhdl work "../../../../lib/gamecube/gamecube.vhd" 1>>%TOPLEVEL%_isim_beh.prj
echo vhdl work "../../../../lib/dvid.vhd" 1>>%TOPLEVEL%_isim_beh.prj
echo vhdl work "../../../../lib/dac.vhd" 1>>%TOPLEVEL%_isim_beh.prj
echo vhdl work "../../../../lib/bootstrap.vhd" 1>>%TOPLEVEL%_isim_beh.prj
echo vhdl work "../../../../gauntlet/ROMS.G1/ROM_9B.vhd" 1>>%TOPLEVEL%_isim_beh.prj
echo vhdl work "../../../../gauntlet/ROMS.G1/ROM_9A.vhd" 1>>%TOPLEVEL%_isim_beh.prj
echo vhdl work "../../../../gauntlet/ROMS.G1/ROM_7B.vhd" 1>>%TOPLEVEL%_isim_beh.prj
echo vhdl work "../../../../gauntlet/ROMS.G1/ROM_7A.vhd" 1>>%TOPLEVEL%_isim_beh.prj
echo vhdl work "../../../../gauntlet/ROMS.G1/ROM_2MN.vhd" 1>>%TOPLEVEL%_isim_beh.prj
echo vhdl work "../../../../gauntlet/ROMS.G1/ROM_2L.vhd" 1>>%TOPLEVEL%_isim_beh.prj
echo vhdl work "../../../../gauntlet/ROMS.G1/ROM_2B.vhd" 1>>%TOPLEVEL%_isim_beh.prj
echo vhdl work "../../../../gauntlet/ROMS.G1/ROM_2A.vhd" 1>>%TOPLEVEL%_isim_beh.prj
echo vhdl work "../../../../gauntlet/ROMS.G1/ROM_1MN.vhd" 1>>%TOPLEVEL%_isim_beh.prj
echo vhdl work "../../../../gauntlet/ROMS.G1/ROM_1L.vhd" 1>>%TOPLEVEL%_isim_beh.prj
echo vhdl work "../../../../gauntlet/ROMS.G1/ROM_1B.vhd" 1>>%TOPLEVEL%_isim_beh.prj
echo vhdl work "../../../../gauntlet/ROMS.G1/ROM_1A.vhd" 1>>%TOPLEVEL%_isim_beh.prj
echo vhdl work "../../../../gauntlet/ROMS.G1/ROM_16S.vhd" 1>>%TOPLEVEL%_isim_beh.prj
echo vhdl work "../../../../gauntlet/ROMS.G1/ROM_16R.vhd" 1>>%TOPLEVEL%_isim_beh.prj
echo vhdl work "../../../../gauntlet/ROMS.G1/ROM_10B.vhd" 1>>%TOPLEVEL%_isim_beh.prj
echo vhdl work "../../../../gauntlet/ROMS.G1/ROM_10A.vhd" 1>>%TOPLEVEL%_isim_beh.prj
echo vhdl work "../../../../gauntlet/GAUNTLET.vhd" 1>>%TOPLEVEL%_isim_beh.prj
echo vhdl work "../../../../boards/pipistrello/xilinx_pll.vhd" 1>>%TOPLEVEL%_isim_beh.prj
echo vhdl work "../../../../boards/pipistrello/testbed/ROMS_EXT_G1.vhd" 1>>%TOPLEVEL%_isim_beh.prj
echo vhdl work "../../../../boards/pipistrello/gauntlet_top.vhd" 1>>%TOPLEVEL%_isim_beh.prj
echo vhdl work "../../../../boards/pipistrello/testbed/tb_gauntlet.vhd" 1>>%TOPLEVEL%_isim_beh.prj

echo onerror {resume} 1> isim.cmd
echo wcfg open ../../_wave.wcfg 1>>isim.cmd
echo run 10 ns 1>> isim.cmd

call C:\Xilinx\14.7\ISE_DS\ISE\.settings64.bat
C:\Xilinx\14.7\ISE_DS\ISE\bin\nt64\unwrapped\fuse.exe -intstyle ise -incremental -lib secureip -o %TOPLEVEL%_isim_beh.exe -prj %TOPLEVEL%_isim_beh.prj work.%TOPLEVEL% work.glbl
%TOPLEVEL%_isim_beh.exe -intstyle ise -gui -tclbatch isim.cmd  -wdb %TOPLEVEL%_isim_beh.wdb

cls
ECHO ################################
ECHO # Delete simulation directory? #
ECHO ################################
cd ..\..\
rmdir /s iseconfig
