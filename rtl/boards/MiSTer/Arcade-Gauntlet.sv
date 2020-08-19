//============================================================================
//  Arcade: Gauntlet
//
//  Port to MiSTer
//  Copyright (C) 2020 d18c7db
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//
//============================================================================

module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [45:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	output  [7:0] VIDEO_ARX,
	output  [7:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,

	// Use framebuffer from DDRAM (USE_FB=1 in qsf)
	// FB_FORMAT:
	//    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
	//    [3]   : 0=16bits 565 1=16bits 1555
	//    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
	//
	// FB_STRIDE either 0 (rounded to 256 bytes) or multiple of 16 bytes.

	output        FB_EN,
	output  [4:0] FB_FORMAT,
	output [11:0] FB_WIDTH,
	output [11:0] FB_HEIGHT,
	output [31:0] FB_BASE,
	output [13:0] FB_STRIDE,
	input         FB_VBL,
	input         FB_LL,

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	input         CLK_AUDIO, // 24.576 MHz
	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S,    // 1 - signed audio samples, 0 - unsigned

	//High latency DDR3 RAM interface
	//Use for non-critical time purposes
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,

	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..6 - USR2..USR6
	// Set USER_OUT to 1 to read from USER_IN.
	input   [6:0] USER_IN,
	output  [6:0] USER_OUT
);

wire        clk_57m2, clk_28m6, clk_14m3, clk_7m1;
wire        clk_sys = clk_14m3;
wire        clk_vid = clk_57m2;
reg         ce_vid;
wire        hblank, vblank;
wire        hs, vs;
reg  [ 7:0] sw[8];
wire [ 3:0] r,g,b, gvid_I, gvid_R, gvid_G, gvid_B;
wire [15:0] aud_l, aud_r;
wire [31:0] status;
wire [ 1:0] buttons;
wire        forced_scandoubler;
wire        direct_video;
wire        ioctl_download;
wire        ioctl_wr;
wire [ 7:0] ioctl_index;
wire [24:0] ioctl_addr;
wire [ 7:0] ioctl_dout;

wire [15:0] joystick_0;
wire [15:0] joystick_1;
wire [15:0] joystick_2;
wire [15:0] joystick_3;

wire [10:0] ps2_key;

wire [21:0] gamma_bus;
wire        no_rotate = ~status[2] | direct_video;
wire        rotate_ccw = 0;

reg         m_up1     = 1'b0;
reg         m_down1   = 1'b0;
reg         m_left1   = 1'b0;
reg         m_right1  = 1'b0;
reg         m_fire1   = 1'b0;
reg         m_magic1  = 1'b0;

reg         m_up2     = 1'b0;
reg         m_down2   = 1'b0;
reg         m_left2   = 1'b0;
reg         m_right2  = 1'b0;
reg         m_fire2   = 1'b0;
reg         m_magic2  = 1'b0;

reg         m_coin1   = 1'b0;
reg         m_coin2   = 1'b0;
reg         m_coin3   = 1'b0;
reg         m_coin4   = 1'b0;
wire        m_service = ~status[7];

assign VGA_F1    = 0;
assign USER_OUT  = '1;
assign LED_USER  = ioctl_download;
assign LED_POWER = 0;
assign LED_DISK  = 0;

assign VIDEO_ARX = status[1] ? 8'd16 : status[2] ? 8'd3 : 8'd4;
assign VIDEO_ARY = status[1] ? 8'd9  : status[2] ? 8'd4 : 8'd3;

assign AUDIO_L = aud_l;
assign AUDIO_R = aud_r;
assign AUDIO_S = 1'b1; // signed samples

`include "build_id.v"
localparam CONF_STR = {
	"A.GAUNTLET;;",
	"-;",
	"H0O1,Aspect Ratio,Original,Wide;",
	"H1H0O2,Orientation,Vert,Horz;",
	"O35,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",
	"-;",
	"DIP;",
	"-;",
	"O7,Service,Off,On;",
	"R0,Reset;",
	"J1,Fire,Magic/Start,Coin;",
	"jn,A,Start,Select,R,L;",
	"V,v",`BUILD_DATE
};

///////////////////////////////////////////////////
hps_io #(.STRLEN($size(CONF_STR)>>3)) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),
	.EXT_BUS(),
	.gamma_bus(gamma_bus),

	.conf_str(CONF_STR),
	.forced_scandoubler(forced_scandoubler),

	.buttons(buttons),
	.status(status),
	.status_menumask({1'b0,direct_video}),
	.direct_video(direct_video),

	.ioctl_download(ioctl_download),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	.ioctl_index(ioctl_index),

	.joystick_0(joystick_0),
	.joystick_1(joystick_1),
	.joystick_2(joystick_2),
	.joystick_3(joystick_3),
	.ps2_key(ps2_key)
);

///////////////////////   CLOCKS   ///////////////////////////////

pll pll
(
	.refclk(CLK_50M),
	.rst(0),
	.outclk_0(clk_7m1),
	.outclk_1(clk_14m3),
	.outclk_2(clk_28m6),
	.outclk_3(clk_57m2),
	.locked()
);

always @(posedge clk_sys) if (ioctl_wr && (ioctl_index==254) && !ioctl_addr[24:3]) sw[ioctl_addr[2:0]] <= ioctl_dout;

wire pressed = ps2_key[9];
always @(posedge clk_sys) begin
	reg old_state;
	old_state <= ps2_key[10];
	
	if(old_state != ps2_key[10]) begin
		casex(ps2_key[8:0])
		
			'hX75: m_up1        <= pressed; // up
			'hX72: m_down1      <= pressed; // down
			'hX6B: m_left1      <= pressed; // left
			'hX74: m_right1     <= pressed; // right

			'h02D: m_up2        <= pressed; // R
			'h02B: m_down2      <= pressed; // F
			'h023: m_left2      <= pressed; // D
			'h034: m_right2     <= pressed; // G

			'h014: m_fire1      <= pressed; // ctrl
			'h011: m_magic1     <= pressed; // alt

			'h01C: m_fire2      <= pressed; // A
			'h01B: m_magic2     <= pressed; // S

			'h02E: m_coin1      <= pressed; // 5
			'h036: m_coin2      <= pressed; // 6
			'h03D: m_coin3      <= pressed; // 7
			'h03E: m_coin4      <= pressed; // 8

		endcase
	end
end

///////////////////////////////////////////////////
always @(posedge clk_vid) begin
	reg [2:0] div;

	div <= div + 1'd1;
	ce_vid <= !div;
end

arcade_video #(240,12) arcade_video
(
	.*,

	.clk_video(clk_vid),
	.ce_pix(ce_vid),

	.RGB_in({r,g,b}),
	.HBlank(~hblank),
	.VBlank(~vblank),
	.HSync(~hs),
	.VSync(~vs),

	.fx(status[5:3])
);

 screen_rotate screen_rotate (.*);

	// convert input video from 16bit IRGB to 12 bit RGB
	RGBI RCONV (.ADDR({gvid_I,gvid_R}), .DATA(r));
	RGBI GCONV (.ADDR({gvid_I,gvid_G}), .DATA(g));
	RGBI BCONV (.ADDR({gvid_I,gvid_B}), .DATA(b));

	// ###################################################
	// # This section loads the ROM files through HPS_IO #
	// ###################################################

	wire local_reset;
	wire gp_wr, mp_wr_7A_7B, mp_wr_9A_9B, mp_wr_10A_10B, ap_wr_16R, ap_wr_16S, cp_wr_6P;

	wire [15:0] ap_addr;
	wire [ 7:0] ap_data, ap_data_16R, ap_data_16S;

	wire [17:0] gp_addr;
	wire [31:0] gp_data;

	wire [18:0] mp_addr;
	wire [15:0] mp_data, mp_data_7A_7B, mp_data_9A_9B, mp_data_10A_10B;

	wire [13:0] cp_addr;
	wire [ 7:0] cp_data, cp_data_6P;

	// hold arcade core in reset while ROMs are being downloaded
	assign local_reset = (!ioctl_index && ioctl_addr < 24'h77FFF) ? 1'b1 : 1'b0;

	integer slap_type = 102;
	always @(posedge clk_sys) if (ioctl_wr && (ioctl_index==1)) slap_type <= ioctl_dout;

	// the order in which the files are listed in the .mra file determines the order in which they appear here on the HPS bus
	// some files are interleaved as DWORD, some are interleaved as WORD and some are not interleaved and appear as BYTEs
	// mux_bytes collects previous bytes so that when a WORD or DWORD is complete it is written to the dpram as appropriate
	reg [23:0] mux_bytes = 0;
	always @(posedge clk_sys)
		if (ioctl_wr && (!ioctl_index) && local_reset )
			mux_bytes<={mux_bytes[15:0],ioctl_dout}; // accumulate previous bytes

	// video ROMS 2L  2A  1L  1A  (4*32KB)
	// video ROMS 2MN 2B  1MN 1B  (4*32KB)
	// generate DWORD write signal for GFX memory when ioctl_addr 000000...03FFFF (0 0000 00xx xxxx xxxx xxxx xxxx)
	assign gp_wr  = (ioctl_wr && !ioctl_index && ioctl_addr[24:18]==7'h00 && ioctl_addr[1:0]==2'b11) ? 1'b1 : 1'b0;

	// CPU ROMS 7A 7B (2*32KB)
	// generate WORD write signal for 68K memory when ioctl_addr 040000...04FFFF (0 0000 0100 xxxx xxxx xxxx xxxx)
	assign mp_wr_7A_7B = (ioctl_wr && !ioctl_index && ioctl_addr[24:16]==11'h04 && ioctl_addr[0]==1'b1) ? 1'b1 : 1'b0;
	// CPU ROMS 9A 9B (2*32KB)
	// generate WORD write signal for 68K memory when ioctl_addr 050000...05FFFF (0 0000 0101 xxxx xxxx xxxx xxxx)
	assign mp_wr_9A_9B = (ioctl_wr && !ioctl_index && ioctl_addr[24:16]==11'h05 && ioctl_addr[0]==1'b1) ? 1'b1 : 1'b0;
	// CPU ROMS 10A 10B (2*16KB)
	// generate WORD write signal for 68K memory when ioctl_addr 060000...067FFF (0 0000 0110 0xxx xxxx xxxx xxxx)
	assign mp_wr_10A_10B = (ioctl_wr && !ioctl_index && ioctl_addr[24:15]==10'h0C && ioctl_addr[0]==1'b1) ? 1'b1 : 1'b0;

	assign mp_data =
		mp_addr[18:15] == 4'b0000 ? mp_data_9A_9B :
		mp_addr[18:15] == 4'b0011 ? mp_data_10A_10B :
		mp_addr[18:15] == 4'b0100 ? mp_data_7A_7B :
//		mp_addr[18:15] == 4'b0101 ? mp_data_6A_6B :
//		mp_addr[18:15] == 4'b0110 ? mp_data_5A_5B :
//		mp_addr[18:15] == 4'b0111 ? mp_data_3A_3B :
		{ 16'hFFFF };

	// AUDIO ROM 16S (32KB)
	// generate BYTE write signal for 6502 memory when ioctl_addr 068000...06FFFF (0 0000 0110 1xxx xxxx xxxx xxxx)
	assign ap_wr_16S = (ioctl_wr && !ioctl_index && ioctl_addr[24:15]==11'h0D ) ? 1'b1 : 1'b0;
	// AUDIO ROM 16R (16KB)
	// generate BYTE write signal for 6502 memory when ioctl_addr 070000...073FFF (0 0000 0111 00xx xxxx xxxx xxxx)
	assign ap_wr_16R = (ioctl_wr && !ioctl_index && ioctl_addr[24:14]==11'h1C ) ? 1'b1 : 1'b0;

	assign ap_data = ap_addr[15] ? ap_data_16S : ap_data_16R;

	// CHAR ROM 6P (16KB)
	// generate BYTE write signal for CHAR memory when ioctl_addr 074000...075FFF (0 0000 0111 010x xxxx xxxx xxxx)
	assign cp_wr_6P = (ioctl_wr && !ioctl_index && ioctl_addr[24:13]==10'h3A ) ? 1'b1 : 1'b0;
	// this ROM is 16K but only first 8K have data, last 8K are all zero
	assign cp_data = cp_addr[13] ? 8'b0 : cp_data_6P;

	// 256 M10K blocks
	dpram #(16,32) gp_ram (
		.clock_a(clk_sys), .wren_a(gp_wr), .address_a(ioctl_addr[17:2]), .data_a({mux_bytes[23:0],ioctl_dout}),
		.clock_b(clk_sys), .address_b(gp_addr), .q_b(gp_data)
	);

	// 64 M10K blocks
	dpram #(15,16) mp_ram_7A_7B (
		.clock_a(clk_sys), .wren_a(mp_wr_7A_7B),   .address_a(ioctl_addr[15:1]), .data_a({mux_bytes[7:0],ioctl_dout}),
		.clock_b(clk_sys), .address_b(mp_addr), .q_b(mp_data_7A_7B)
	);

	// 64 M10K blocks
	dpram #(15,16) mp_ram_9A_9B (
		.clock_a(clk_sys), .wren_a(mp_wr_9A_9B),   .address_a(ioctl_addr[15:1]), .data_a({mux_bytes[7:0],ioctl_dout}),
		.clock_b(clk_sys), .address_b(mp_addr), .q_b(mp_data_9A_9B)
	);

	// 32 M10K blocks
	dpram #(14,16) mp_ram_10A_10B (
		.clock_a(clk_sys), .wren_a(mp_wr_10A_10B), .address_a(ioctl_addr[14:1]), .data_a({mux_bytes[7:0],ioctl_dout}),
		.clock_b(clk_sys), .address_b(mp_addr), .q_b(mp_data_10A_10B)
	);

	// 32 M10K blocks
	dpram #(15,8) ap_ram_16S (
		.clock_a(clk_sys), .wren_a(ap_wr_16S), .address_a(ioctl_addr[24:0]), .data_a(ioctl_dout),
		.clock_b(clk_sys), .address_b(ap_addr), .q_b(ap_data_16S)
	);

	// 16 M10K blocks
	dpram #(14,8) ap_ram_16R (
		.clock_a(clk_sys), .wren_a(ap_wr_16R), .address_a(ioctl_addr[24:0]), .data_a(ioctl_dout),
		.clock_b(clk_sys), .address_b(ap_addr), .q_b(ap_data_16R)
	);

	// 8 M10K blocks
	dpram  #(13,8) cp_ram_6P (
		.clock_a(clk_sys), .wren_a(cp_wr_6P), .address_a(ioctl_addr[12:0]), .data_a(ioctl_dout),
		.clock_b(clk_sys), .address_b(cp_addr), .q_b(cp_data_6P)
	);

	// total game dpram uses 472 of 553 M10K blocks

FPGA_GAUNTLET gauntlet
(
	.I_CLK_14M(clk_14m3),
	.I_CLK_7M(clk_7m1),

	.I_RESET(RESET | status[0] | buttons[1] | local_reset),

	// FIXME all these need assignment
	.I_P1({~(m_up1 | joystick_0[3]), ~(m_down1 | joystick_0[2]), ~(m_left1 | joystick_0[1]), ~(m_right1 | joystick_0[0]), 1'b1, 1'b1, ~(m_fire1 | joystick_0[4]), ~(m_magic1 | joystick_0[5])}),
	.I_P2({~(m_up2 | joystick_1[3]), ~(m_down2 | joystick_1[2]), ~(m_left2 | joystick_1[1]), ~(m_right2 | joystick_1[0]), 1'b1, 1'b1, ~(m_fire2 | joystick_1[4]), ~(m_magic2 | joystick_1[5])}),
	.I_P3({~(joystick_2[3]), ~(joystick_2[2]), ~(joystick_2[1]), ~(joystick_2[0]), 1'b1, 1'b1, ~(joystick_2[4]), ~(joystick_2[5])}),
	.I_P4({~(joystick_3[3]), ~(joystick_3[2]), ~(joystick_3[1]), ~(joystick_3[0]), 1'b1, 1'b1, ~(joystick_3[4]), ~(joystick_3[5])}),
	.I_SYS({m_service, ~(m_coin1 | joystick_0[6]), ~(m_coin2 | joystick_1[6]), ~(m_coin3 | joystick_2[6]), ~(m_coin4 | joystick_3[6])}),
	.I_SLAP_TYPE(slap_type),

	.O_LEDS(),

	.O_AUDIO_L(aud_l),
	.O_AUDIO_R(aud_r),

	.O_VIDEO_I(gvid_I),
	.O_VIDEO_R(gvid_R),
	.O_VIDEO_G(gvid_G),
	.O_VIDEO_B(gvid_B),
	.O_HSYNC(hs),
	.O_VSYNC(vs),
	.O_CSYNC(),
	.O_HBLANK(hblank),
	.O_VBLANK(vblank),

	.O_GP_EN(),
	.O_GP_ADDR(gp_addr),
	.I_GP_DATA(gp_data),

	.O_CP_ADDR(cp_addr),
	.I_CP_DATA(cp_data),

	.O_MP_EN(),
	.O_MP_ADDR(mp_addr),
	.I_MP_DATA(mp_data),

	.O_AP_EN(),
	.O_AP_ADDR(ap_addr),
	.I_AP_DATA(ap_data)
);

// pragma translate_off
	bmp_out #( "BI" ) bmp_out
	(
		.clk_i(clk_7m1),
		.dat_i({r,4'b0,g,4'b0,b,4'b0}),
		.hs_i(hs),
		.vs_i(vs)
	);
// pragma translate_on
endmodule
