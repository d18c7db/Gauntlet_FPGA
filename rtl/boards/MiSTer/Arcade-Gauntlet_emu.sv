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

	//SDRAM interface
	output        SDRAM_CLK,
	output        SDRAM_CKE,
	output [12:0] SDRAM_A,
	output  [1:0] SDRAM_BA,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nCS,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nWE,

	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..6 - USR2..USR6
	// Set USER_OUT to 1 to read from USER_IN.
	input   [6:0] USER_IN,
	output  [6:0] USER_OUT
);

wire        clk_7M;
wire        clk_14M;
wire        clk_sys;
wire        clk_vid;
reg         ce_vid;
wire        locked;
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
wire        ioctl_wait;
wire [ 7:0] ioctl_index;
wire [24:0] ioctl_addr;
wire [ 7:0] ioctl_dout;

wire [15:0] joy0;
wire [15:0] joy1;
wire [15:0] joy2;
wire [15:0] joy3;

wire [10:0] ps2_key;

wire [21:0] gamma_bus;
wire        no_rotate = ~status[2] | direct_video;
wire        rotate_ccw = 0;

integer     slap_type = 104; // Slapstic type depends on game: 104=Gauntlet, 106=Gauntlet II, 107=2-Player Gauntlet, 118=Vindicators Part II

reg [7:0]   p1 = 8'h0;
reg [7:0]   p2 = 8'h0;
reg [7:0]   p3 = 8'h0;
reg [7:0]   p4 = 8'h0;

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

///////////////////////   CLOCKS   ///////////////////////////////
pll pll
(
	.refclk(CLK_50M),
	.rst(1'b0),
	.outclk_0(clk_7M),    //  7.15909 MHz
	.outclk_1(clk_14M),   // 14.31818 MHz
	.outclk_2(clk_vid),   // 57.27272 MHz
	.outclk_3(clk_sys),   // 93.06817 MHz
	.outclk_4(SDRAM_CLK), // 93.06817 MHz
	.locked(locked)
);

always @(posedge clk_sys) if (ioctl_wr && (ioctl_index==254) && !ioctl_addr[24:3]) sw[ioctl_addr[2:0]] <= ioctl_dout;

wire pressed = ps2_key[9];
always @(posedge clk_sys) begin
	reg old_state;
	old_state <= ps2_key[10];

	if(old_state != ps2_key[10]) begin
		if (slap_type == 118) // select controller mapping
		casex(ps2_key[8:0])
			// Vindicators tank controls
			'h023: p1[7]        <= pressed; // P1 R BACK  (D).
			'h01B: p1[6]        <= pressed; // P1 L BACK  (S).
			'h024: p1[5]        <= pressed; // P1 R FORW  (E).
			'h01D: p1[4]        <= pressed; // P1 L FORW  (W).
			'h02D: p1[3]        <= pressed; // P1 R THUMB (R)
			'h015: p1[2]        <= pressed; // P1 L THUMB (Q)
			'h02B: p1[1]        <= pressed; // P1 R TRIG  (F).
			'h01C: p1[0]        <= pressed; // P1 L TRIG  (A).

			'h042: p2[7]        <= pressed; // P2 R BACK  (K).
			'h03B: p2[6]        <= pressed; // P2 L BACK  (J).
			'h043: p2[5]        <= pressed; // P2 R FORW  (I).
			'h03C: p2[4]        <= pressed; // P2 L FORW  (U).
			'h044: p2[3]        <= pressed; // P2 R THUMB (O)
			'h035: p2[2]        <= pressed; // P2 L THUMB (Y)
			'h04B: p2[1]        <= pressed; // P2 R TRIG  (L).
			'h033: p2[0]        <= pressed; // P2 L TRIG  (H).

			'h016: p3[0]        <= pressed; // P1 START   (1).
			'h01E: p3[1]        <= pressed; // P2 START   (2)

			'h02E: m_coin1      <= pressed; // P1 COIN    (5)
			'h036: m_coin2      <= pressed; // P2 COIN    (6)
//			'h03D: m_coin3      <= pressed; // P3 COIN    (7)
//			'h03E: m_coin4      <= pressed; // P4 COIN    (8)
		endcase
		else
		casex(ps2_key[8:0])
			// Gauntlet I and II controls
			'hX75: p1[7]        <= pressed; // up    (up_arrow)
			'hX72: p1[6]        <= pressed; // down  (down_arrow)
			'hX6B: p1[5]        <= pressed; // left  (left_arrow)
			'hX74: p1[4]        <= pressed; // right (right_arrow)
			'h014: p1[1]        <= pressed; // fire  (ctrl)
			'h011: p1[0]        <= pressed; // magic (alt)

			'h02D: p2[7]        <= pressed; // up    (R)
			'h02B: p2[6]        <= pressed; // down  (F)
			'h023: p2[5]        <= pressed; // left  (D)
			'h034: p2[4]        <= pressed; // right (G)
			'h01C: p2[1]        <= pressed; // fire  (A)
			'h01B: p2[0]        <= pressed; // magic (S)

			'h02E: m_coin1      <= pressed; // coin1 (5)
			'h036: m_coin2      <= pressed; // coin2 (6)
			'h03D: m_coin3      <= pressed; // coin3 (7)
			'h03E: m_coin4      <= pressed; // coin4 (8)
		endcase
	end
end

///////////////////////////////////////////////////
always @(posedge clk_vid) begin
	reg [2:0] div;

	div <= div + 1'd1;
	ce_vid <= !div;
end

//arcade_video #(.WIDTH(262), .DW(12)) arcade_video
//(
//	.*,
//
//	.clk_video(clk_vid),
//	.ce_pix(ce_vid),
//
//	.RGB_in({r,g,b}),
//	.HBlank(~hblank),
//	.VBlank(~vblank),
//	.HSync(~hs),
//	.VSync(~vs),
//
//	.fx(status[5:3])
//);
//
//screen_rotate screen_rotate (.*);
hps_io_emu #(.STRLEN($size(CONF_STR)>>3)) hps_io
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

	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	.ioctl_wr(ioctl_wr),
	.ioctl_download(ioctl_download),
	.ioctl_index(ioctl_index),
	.ioctl_wait(ioctl_wait),

	.joystick_0(joy0),
	.joystick_1(joy1),
	.joystick_2(joy2),
	.joystick_3(joy3),
	.ps2_key(ps2_key)
);

	// convert input video from 16bit IRGB to 12 bit RGB
	RGBI RCONV (.ADDR({gvid_I,gvid_R}), .DATA(r));
	RGBI GCONV (.ADDR({gvid_I,gvid_G}), .DATA(g));
	RGBI BCONV (.ADDR({gvid_I,gvid_B}), .DATA(b));

	// ###################################################
	// # This section loads the ROM files through HPS_IO #
	// ###################################################

	wire gp_wr, mp_wr_9A_9B, mp_wr_10A_10B, mp_wr_7A_7B, mp_wr_6A_6B, mp_wr_5A_5B, mp_wr_3A_3B, ap_wr_16R, ap_wr_16S, cp_wr_6P;

	wire [15:0] ap_addr;
	wire [ 7:0] ap_data, ap_data_16R, ap_data_16S;

	wire [17:0] gp_addr;
	wire [31:0] gp_data;

	wire [18:0] mp_addr;
	wire [15:0] mp_data, mp_data_9A_9B, mp_data_10A_10B, mp_data_7A_7B, mp_data_6A_6B, mp_data_5A_5B, mp_data_3A_3B;

	wire [13:0] cp_addr;
	wire [ 7:0] cp_data;

	always @(posedge clk_sys) if (ioctl_wr && (ioctl_index==1)) slap_type <= ioctl_dout;

	// ioctl_addr 000000..01FFFF = video ROMs 2L  2A  1L  1A  (4*32KB)
	// ioctl_addr 020000..03FFFF = video ROMs 2MN 2B  1MN 1B  (4*32KB)
	// ioctl_addr 040000..05FFFF = video ROMs 2P  2C  1P  1C  (4*32KB)
	// ioctl_addr 060000..07FFFF = video ROMs 2R  2D  1R  1D  (4*32KB)
	// ioctl_addr 080000..09FFFF = video ROMs 2ST 2EF 1ST 1EF (4*32KB)
	// ioctl_addr 0A0000..0BFFFF = video ROMs 2U  2J  1U  1J  (4*32KB)
	assign gp_wr         = (ioctl_wr && !ioctl_index && ioctl_addr[24:18] < 7'h03 && ioctl_addr[1:0]==2'b11) ? 1'b1 : 1'b0;
	// ioctl_addr 0C0000..0CFFFF = CPU ROMS 9A 9B (2*32KB)
	assign mp_wr_9A_9B   = (ioctl_wr && !ioctl_index && ioctl_addr[24:16]== 9'h0C && ioctl_addr[0]==1'b1) ? 1'b1 : 1'b0;
	// ioctl_addr 0D0000..0DFFFF = NO ROM (2*32KB filler)
	// ioctl_addr 0E0000..0EFFFF = NO ROM (2*32KB filler)
	// ioctl_addr 0F0000..0F7FFF = CPU ROMS 10A 10B (2*16KB)
	assign mp_wr_10A_10B = (ioctl_wr && !ioctl_index && ioctl_addr[24:15]==10'h1E && ioctl_addr[0]==1'b1) ? 1'b1 : 1'b0;
	// ioctl_addr 0F8000..0FFFFF = NO ROMS (2*16K filler)
	// ioctl_addr 100000..10FFFF = CPU ROMS 7A 7B (2*32KB)
	assign mp_wr_7A_7B   = (ioctl_wr && !ioctl_index && ioctl_addr[24:16]== 9'h10 && ioctl_addr[0]==1'b1) ? 1'b1 : 1'b0;
	// ioctl_addr 110000..11FFFF = CPU ROMS 6A 6B (2*32KB)
	assign mp_wr_6A_6B   = (ioctl_wr && !ioctl_index && ioctl_addr[24:16]== 9'h11 && ioctl_addr[0]==1'b1) ? 1'b1 : 1'b0;
	// ioctl_addr 120000..12FFFF = CPU ROMS 5A 5B (2*32KB)
	assign mp_wr_5A_5B   = (ioctl_wr && !ioctl_index && ioctl_addr[24:16]== 9'h12 && ioctl_addr[0]==1'b1) ? 1'b1 : 1'b0;
	// ioctl_addr 130000..13FFFF = CPU ROMS 3A 3B (2*32KB)
	assign mp_wr_3A_3B   = (ioctl_wr && !ioctl_index && ioctl_addr[24:16]== 9'h13 && ioctl_addr[0]==1'b1) ? 1'b1 : 1'b0;
	// ioctl_addr 140000..147FFF = AUDIO ROM 16S (32KB)
	assign ap_wr_16S     = (ioctl_wr && !ioctl_index && ioctl_addr[24:15]==10'h28 ) ? 1'b1 : 1'b0;
	// ioctl_addr 148000..14BFFF = AUDIO ROM 16R (16KB)
	assign ap_wr_16R     = (ioctl_wr && !ioctl_index && ioctl_addr[24:14]==11'h52 ) ? 1'b1 : 1'b0;
	// ioctl_addr 14C000..14FFFF = CHAR ROM 6P (16KB)
	assign cp_wr_6P      = (ioctl_wr && !ioctl_index && ioctl_addr[24:14]==11'h53 ) ? 1'b1 : 1'b0;

	assign mp_data =
		mp_addr[18:15] == 4'b0000  ? mp_data_9A_9B :
		mp_addr[18:14] == 5'b00110 ? mp_data_10A_10B :
		mp_addr[18:15] == 4'b0100  ? mp_data_7A_7B :
		mp_addr[18:15] == 4'b0101  ? mp_data_6A_6B :
		mp_addr[18:15] == 4'b0110  ? mp_data_5A_5B :
		mp_addr[18:15] == 4'b0111  ? mp_data_3A_3B :
		{ 16'h0 };

	assign ap_data = ap_addr[15] ? ap_data_16S : ap_data_16R;

/*************************************************************/
	wire [22:0] sdram_addr;
	reg  [31:0] sdram_data=0;
	reg         sdram_we=0;
	wire        sdram_ready;
	wire        ap_en;
	wire        gp_en;
	wire        mp_en;

	// the order in which the files are listed in the .mra file determines the order in which they appear here on the HPS bus
	// some files are interleaved as DWORD, some are interleaved as WORD and some are not interleaved and appear as BYTEs
	// acc_bytes collects previous bytes so that when a WORD or DWORD is complete it is written to the RAM as appropriate
	reg [23:0] acc_bytes = 0;
	always @(posedge clk_sys)
		if (ioctl_wr && (!ioctl_index) && ioctl_download )
			acc_bytes<={acc_bytes[15:0],ioctl_dout}; // accumulate previous bytes

	always @(posedge clk_sys)
	begin
		sdram_we <= 1'b0;
		if (ioctl_wr && (!ioctl_index) && ioctl_download && ioctl_addr[1] && ioctl_addr[0])
		begin
			sdram_data = {acc_bytes,ioctl_dout};
			sdram_we <= 1'b1;
		end
	end

	assign sdram_addr = ioctl_download?ioctl_addr[24:2]:{5'd0,gp_addr};
	assign ioctl_wait = ~(locked && sdram_ready);

	sdram #(.tCK_ns(1000/93.06817)) sdram
	(
		.I_RST(~locked),
		.I_CLK(clk_sys),

		// controller interface
		.I_ADDR(sdram_addr),
		.I_DATA(sdram_data),
		.I_WE(sdram_we),
		.O_RDY(sdram_ready),
		.O_DATA(gp_data),

		// SDRAM interface
		.SDRAM_DQ(SDRAM_DQ),
		.SDRAM_A(SDRAM_A),
		.SDRAM_BA(SDRAM_BA),
		.SDRAM_DQML(SDRAM_DQML),
		.SDRAM_DQMH(SDRAM_DQMH),
		.SDRAM_CLK(),
		.SDRAM_CKE(SDRAM_CKE),
		.SDRAM_nCS(SDRAM_nCS),
		.SDRAM_nRAS(SDRAM_nRAS),
		.SDRAM_nCAS(SDRAM_nCAS),
		.SDRAM_nWE(SDRAM_nWE)
	);

/*************************************************************/
	// 256 M10K blocks
//	dpram #(16,32) gp_ram
//	(.clock_a(clk_sys    ), .enable_a(), .wren_a(gp_wr        ), .address_a(ioctl_addr[17:2]), .data_a({acc_bytes[23:0],ioctl_dout}), .q_a(               ),
//	 .clock_b(clk_sys    ), .enable_b(), .wren_b(             ), .address_b(   gp_addr[15:0]), .data_b(                            ), .q_b(gp_data        ));

	// 64 M10K blocks
	dpram #(15,16) mp_ram_9A_9B
	(.clock_a(clk_sys    ), .enable_a(), .wren_a(mp_wr_9A_9B  ), .address_a(ioctl_addr[15:1]), .data_a({acc_bytes[ 7:0],ioctl_dout}), .q_a(               ),
	 .clock_b(clk_sys    ), .enable_b(), .wren_b(             ), .address_b(   mp_addr[14:0]), .data_b(                            ), .q_b(mp_data_9A_9B   ));

	// 32 M10K blocks
	dpram #(14,16) mp_ram_10A_10B
	(.clock_a(clk_sys    ), .enable_a(), .wren_a(mp_wr_10A_10B), .address_a(ioctl_addr[14:1]), .data_a({acc_bytes[ 7:0],ioctl_dout}), .q_a(               ),
	 .clock_b(clk_sys    ), .enable_b(), .wren_b(             ), .address_b(   mp_addr[13:0]), .data_b(                            ), .q_b(mp_data_10A_10B));

	// 64 M10K blocks
	dpram #(15,16) mp_ram_7A_7B
	(.clock_a(clk_sys    ), .enable_a(), .wren_a(mp_wr_7A_7B  ), .address_a(ioctl_addr[15:1]), .data_a({acc_bytes[ 7:0],ioctl_dout}), .q_a(               ),
	 .clock_b(clk_sys    ), .enable_b(), .wren_b(             ), .address_b(   mp_addr[14:0]), .data_b(                            ), .q_b(mp_data_7A_7B  ));

	// 64 M10K blocks
	dpram #(15,16) mp_ram_6A_6B
	(.clock_a(clk_sys    ), .enable_a(), .wren_a(mp_wr_6A_6B  ), .address_a(ioctl_addr[15:1]), .data_a({acc_bytes[ 7:0],ioctl_dout}), .q_a(               ),
	 .clock_b(clk_sys    ), .enable_b(), .wren_b(             ), .address_b(   mp_addr[14:0]), .data_b(                            ), .q_b(mp_data_6A_6B  ));

	// 64 M10K blocks
	dpram #(15,16) mp_ram_5A_5B
	(.clock_a(clk_sys    ), .enable_a(), .wren_a(mp_wr_5A_5B  ), .address_a(ioctl_addr[15:1]), .data_a({acc_bytes[ 7:0],ioctl_dout}), .q_a(               ),
	 .clock_b(clk_sys    ), .enable_b(), .wren_b(             ), .address_b(   mp_addr[14:0]), .data_b(                            ), .q_b(mp_data_5A_5B  ));

	// 64 M10K blocks
	dpram #(15,16) mp_ram_3A_3B
	(.clock_a(clk_sys    ), .enable_a(), .wren_a(mp_wr_3A_3B  ), .address_a(ioctl_addr[15:1]), .data_a({acc_bytes[ 7:0],ioctl_dout}), .q_a(               ),
	 .clock_b(clk_sys    ), .enable_b(), .wren_b(             ), .address_b(   mp_addr[14:0]), .data_b(                            ), .q_b(mp_data_3A_3B  ));

	// 32 M10K blocks
	dpram #(15, 8) ap_ram_16S
	(.clock_a(clk_sys    ), .enable_a(), .wren_a(ap_wr_16S    ), .address_a(ioctl_addr[14:0]), .data_a(                 ioctl_dout ), .q_a(               ),
	 .clock_b(clk_sys    ), .enable_b(), .wren_b(             ), .address_b(   ap_addr[14:0]), .data_b(                            ), .q_b(ap_data_16S    ));

	// 16 M10K blocks
	dpram #(14, 8) ap_ram_16R
	(.clock_a(clk_sys    ), .enable_a(), .wren_a(ap_wr_16R    ), .address_a(ioctl_addr[13:0]), .data_a(                 ioctl_dout ), .q_a(               ),
	 .clock_b(clk_sys    ), .enable_b(), .wren_b(             ), .address_b(   ap_addr[13:0]), .data_b(                            ), .q_b(ap_data_16R    ));

	// 16 M10K blocks
	dpram  #(14,8) cp_ram_6P
	(.clock_a(clk_sys    ), .enable_a(), .wren_a(cp_wr_6P     ), .address_a(ioctl_addr[13:0]), .data_a(                 ioctl_dout ), .q_a(               ),
	 .clock_b(clk_sys    ), .enable_b(), .wren_b(             ), .address_b(   cp_addr[13:0]), .data_b(                            ), .q_b(cp_data        ));

	// total game dpram uses 416 of 553 M10K blocks

FPGA_GAUNTLET gauntlet
(
	.I_CLK_14M(clk_14M),
	.I_CLK_7M(clk_7M),

	.I_RESET(RESET | status[0] | buttons[1] | ioctl_download),

	//            up       down     left     right    start    button3  button2  button1
	.I_P1(~(p1 | {joy0[3], joy0[2], joy0[1], joy0[0], joy0[7], joy0[6], joy0[5], joy0[4]})),
	.I_P2(~(p2 | {joy1[3], joy1[2], joy1[1], joy1[0], joy1[7], joy1[6], joy1[5], joy1[4]})),
	.I_P3(~(p3 | {joy2[3], joy2[2], joy2[1], joy2[0], joy2[7], joy2[6], joy2[5], joy2[4]})),
	.I_P4(~(p4 | {joy3[3], joy3[2], joy3[1], joy3[0], joy3[7], joy3[6], joy3[5], joy3[4]})),
	.I_SYS({m_service, ~(m_coin1 | joy0[8]), ~(m_coin2 | joy1[8]), ~(m_coin3 | joy2[8]), ~(m_coin4 | joy3[8])}),
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

	.O_GP_EN(gp_en),
	.O_GP_ADDR(gp_addr),
	.I_GP_DATA(gp_data),

	.O_CP_ADDR(cp_addr),
	.I_CP_DATA(cp_data),

	.O_MP_EN(mp_en),
	.O_MP_ADDR(mp_addr),
	.I_MP_DATA(mp_data),

	.O_AP_EN(ap_en),
	.O_AP_ADDR(ap_addr),
	.I_AP_DATA(ap_data)
);

// pragma translate_off
	bmp_out #( "BI" ) bmp_out
	(
		.clk_i(clk_7M),
		.dat_i({r,4'b0,g,4'b0,b,4'b0}),
		.hs_i(hs),
		.vs_i(vs)
	);
// pragma translate_on
endmodule
