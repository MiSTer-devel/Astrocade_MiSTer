// FPGA Videopac
//-----------------------------------------------------------------------------
//
// Copyright (c) 2007, Arnim Laeuger (arnim.laeuger@gmx.net)
//
// All rights reserved
//
// Redistribution and use in source and synthezised forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// Redistributions of source code must retain the above copyright notice,
// this list of conditions and the following disclaimer.
//
// Redistributions in synthesized form must reproduce the above copyright
// notice, this list of conditions and the following disclaimer in the
// documentation and/or other materials provided with the distribution.
//
// Neither the name of the author nor the names of other contributors may
// be used to endorse or promote products derived from this software without
// specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
// THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
// PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
//
// Please report bugs to the author, but before you do so, please
// make sure that this is not a derivative work and that
// you have the latest version of this file.
//
// Based off MiST port by wsoltys in 2014.
//
// Adapted for MiSTer by Kitrinx in 2018

module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [48:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	//if VIDEO_ARX[12] or VIDEO_ARY[12] is set then [11:0] contains scaled size instead of aspect ratio.
	output [12:0] VIDEO_ARX,
	output [12:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,
	output        VGA_SCALER, // Force VGA scaler

	input  [11:0] HDMI_WIDTH,
	input  [11:0] HDMI_HEIGHT,
	output        HDMI_FREEZE,

`ifdef MISTER_FB
	// Use framebuffer in DDRAM (USE_FB=1 in qsf)
	// FB_FORMAT:
	//    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
	//    [3]   : 0=16bits 565 1=16bits 1555
	//    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
	//
	// FB_STRIDE either 0 (rounded to 256 bytes) or multiple of pixel size (in bytes)
	output        FB_EN,
	output  [4:0] FB_FORMAT,
	output [11:0] FB_WIDTH,
	output [11:0] FB_HEIGHT,
	output [31:0] FB_BASE,
	output [13:0] FB_STRIDE,
	input         FB_VBL,
	input         FB_LL,
	output        FB_FORCE_BLANK,

`ifdef MISTER_FB_PALETTE
	// Palette control for 8bit modes.
	// Ignored for other video modes.
	output        FB_PAL_CLK,
	output  [7:0] FB_PAL_ADDR,
	output [23:0] FB_PAL_DOUT,
	input  [23:0] FB_PAL_DIN,
	output        FB_PAL_WR,
`endif
`endif

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	// I/O board button press simulation (active high)
	// b[1]: user button
	// b[0]: osd button
	output  [1:0] BUTTONS,

	input         CLK_AUDIO, // 24.576 MHz
	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned
	output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

	//ADC
	inout   [3:0] ADC_BUS,

	//SD-SPI
	output        SD_SCK,
	output        SD_MOSI,
	input         SD_MISO,
	output        SD_CS,
	input         SD_CD,

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

	//SDRAM interface with lower latency
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

`ifdef MISTER_DUAL_SDRAM
	//Secondary SDRAM
	//Set all output SDRAM_* signals to Z ASAP if SDRAM2_EN is 0
	input         SDRAM2_EN,
	output        SDRAM2_CLK,
	output [12:0] SDRAM2_A,
	output  [1:0] SDRAM2_BA,
	inout  [15:0] SDRAM2_DQ,
	output        SDRAM2_nCS,
	output        SDRAM2_nCAS,
	output        SDRAM2_nRAS,
	output        SDRAM2_nWE,
`endif

	input         UART_CTS,
	output        UART_RTS,
	input         UART_RXD,
	output        UART_TXD,
	output        UART_DTR,
	input         UART_DSR,

	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..6 - USR2..USR6
	// Set USER_OUT to 1 to read from USER_IN.
	input   [6:0] USER_IN,
	output  [6:0] USER_OUT,

	input         OSD_STATUS
);

///////// Default values for ports not used in this core /////////

assign ADC_BUS  = 'Z;
assign USER_OUT = '1;
assign {UART_RTS, UART_TXD, UART_DTR} = 0;
assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;
assign {SDRAM_DQ, SDRAM_A, SDRAM_BA, SDRAM_CKE, SDRAM_CLK, SDRAM_DQML, SDRAM_DQMH, SDRAM_nWE, SDRAM_nCAS, SDRAM_nRAS, SDRAM_nCS} = 'Z;
assign {DDRAM_CLK, DDRAM_BURSTCNT, DDRAM_ADDR, DDRAM_DIN, DDRAM_BE, DDRAM_RD, DDRAM_WE} = '0;
assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;

assign VGA_F1      = 0;
assign VGA_SCALER  = 0;
assign HDMI_FREEZE = 0;

assign AUDIO_S   = 0;
assign AUDIO_MIX = 0;

assign LED_DISK  = 0;
assign LED_POWER = 0;
assign BUTTONS   = 0;

//////////////////////////////////////////////////////////////////

assign LED_USER  = ioctl_download;

reg en216p;
always @(posedge CLK_VIDEO) begin
	en216p <= ((HDMI_WIDTH == 1920) && (HDMI_HEIGHT == 1080) && !forced_scandoubler && !scale);
end

wire [1:0] ar = status[13:12];
wire vcrop_en = status[16];
wire vga_de;
video_freak video_freak
(
	.*,
	.VGA_DE_IN(vga_de),

	.ARX((!ar) ? 12'd4 : (ar - 1'd1)),
	.ARY((!ar) ? 12'd3 : 12'd0),
	.CROP_SIZE((en216p & vcrop_en) ? 10'd216 : 10'd0),
	.CROP_OFF(-5'd8),
	.SCALE(status[15:14])
);


////////////////////////////  HPS I/O  //////////////////////////////////

// Status Bit Map:
//              Upper                          Lower
// 0         1         2         3          4         5         6
// 01234567890123456789012345678901 23456789012345678901234567890123
// 0123456789ABCDEFGHIJKLMNOPQRSTUV 0123456789ABCDEFGHIJKLMNOPQRSTUV
// X      X XXXXXXXX

`include "build_id.v"
parameter CONF_STR = {
	"Astrocade;;",
	"-;",
	"F,BIN;",
	"-;",
	"OCD,Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
	"O9B,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",
	"-;",
	"d0OG,Vertical Crop,No,Yes;",
	"OEF,Scale,Normal,V-Integer,Narrower HV-Integer,Wider HV-Integer;",
	"-;",
	"O7,Swap Joysticks,No,Yes;",
	"-;",
	"R0,Reset;",
	"J1,Fire,0,1,2,3,4,5,6,7,8,9,CH,C,CE,Plus,Minus,Mul,Div,=,.,MR,MS,Prev,Next,%;",
	"V,v",`BUILD_DATE
};

wire  [1:0] buttons;
wire [31:0] status;
wire        forced_scandoubler;
wire [21:0] gamma_bus;

wire        ioctl_download;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire        ioctl_wait;
wire        ioctl_wr;

wire [31:0] joystick_0,joystick_1,joyc,joyd;
wire  [7:0] pd_0,pd_1,pdc,pdd;
wire [24:0] ps2_mouse;
wire  [7:0] ioctl_index;

hps_io #(.CONF_STR(CONF_STR)) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),

	.ioctl_download(ioctl_download),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	.ioctl_wait(ioctl_wait),
	.ioctl_index(ioctl_index),

	.forced_scandoubler(forced_scandoubler),
	.gamma_bus(gamma_bus),

	.buttons(buttons),
	.status(status),
	.status_menumask({en216p}),

	.joystick_0(joystick_0),
	.joystick_1(joystick_1),
	.joystick_2(joyc),
	.joystick_3(joyd),

	.paddle_0(pd_0),
	.paddle_1(pd_1),
	.paddle_2(pdc),
	.paddle_3(pdd),

	.ps2_key(ps2_key)
);

wire       joy_swap = status[7];

wire [31:0] joya = joy_swap ? joystick_1 : joystick_0;
wire [31:0] joyb = joy_swap ? joystick_0 : joystick_1;
wire  [7:0] pda  = joy_swap ? pd_1 : pd_0;
wire  [7:0] pdb  = joy_swap ? pd_0 : pd_1;

///////////////////////  CLOCK/RESET  ///////////////////////////////////

// The original uses a 7.159090 MHz clock
// give us 14.2857MHz (7.1428)

wire clk_sys;

pll pll
(
	.refclk(CLK_50M),
	.rst(0),
	.outclk_0(clk_sys),
	.outclk_1(CLK_VIDEO)
);

reg [1:0] clk_cpu_ct;

always @(posedge clk_sys or posedge reset) begin
	if (reset)
		clk_cpu_ct <= 2'd0;
	else
		clk_cpu_ct <= clk_cpu_ct + 2'd1;
end

wire clk_cpu_en = clk_cpu_ct[0];

wire reset = RESET | buttons[1] | status[0] | ioctl_download;

////////////////////////////  SYSTEM  ///////////////////////////////////

BALLY bally
(
	// Audio
	.O_AUDIO        (audio), //    : out   std_logic_vector(7 downto 0);

	// Video
	.O_VIDEO_R      (R), //    : out   std_logic_vector(3 downto 0);
	.O_VIDEO_G      (G), //    : out   std_logic_vector(3 downto 0);
	.O_VIDEO_B      (B), //    : out   std_logic_vector(3 downto 0);
	.O_CE_PIX       (),
	.O_HBLANK_V     (),
	.O_VBLANK_V     (),
	.O_HSYNC        (hs), //    : out   std_logic;
	.O_VSYNC        (vs), //    : out   std_logic;
	.O_COMP_SYNC_L  (), //    : out   std_logic;
	.O_FPSYNC       (), //    : out   std_logic;

	// Cart
	.O_CAS_ADDR     (cart_addr), //    : out   std_logic_vector(12 downto 0);
	.O_CAS_DATA     (cart_di), //    : out   std_logic_vector( 7 downto 0);
	.I_CAS_DATA     (cart_do), //    : in    std_logic_vector( 7 downto 0);
	.O_CAS_CS_L     (cart_rd), //    : out   std_logic;

	// BIOS
	.O_BIOS_ADDR    (bios_addr),
	.O_BIOS_CS_L    (bios_rd),
	.I_BIOS_DATA    (bios_do),

	// Expansion cart
	.O_EXP_ADDR     (), //    : out   std_logic_vector(15 downto 0);
	.O_EXP_DATA     (8'hFF), //    : out   std_logic_vector( 7 downto 0);
	.I_EXP_DATA     (), //    : in    std_logic_vector( 7 downto 0);
	.I_EXP_OE_L     (1'b1), //    : in    std_logic; -- expansion slot driving data bus
	.O_EXP_M1_L     (), //    : out   std_logic;
	.O_EXP_MREQ_L   (), //    : out   std_logic;
	.O_EXP_IORQ_L   (), //    : out   std_logic;
	.O_EXP_WR_L     (), //    : out   std_logic;
	.O_EXP_RD_L     (), //    : out   std_logic;

	// Input
	.O_SWITCH_COL   (col_select), //    : out   std_logic_vector(7 downto 0);
	.I_SWITCH_ROW   (row_data), //    : in    std_logic_vector(7 downto 0);
	.O_POT          (pot_select),
	.I_POT          (pot_data),

	// System
	.I_RESET_L      (~reset), //    : in    std_logic;
	.ENA            (clk_cpu_en), //    : in    std_logic;
	.CLK            (clk_sys) //    : in    std_logic
);


////////////////////////////  SOUND  ////////////////////////////////////

wire [7:0] audio;
wire cart_wr_n;
wire [7:0] cart_di;

wire [15:0] audio_out = {audio, audio};

assign AUDIO_L = audio_out;
assign AUDIO_R = audio_out;


////////////////////////////  VIDEO  ////////////////////////////////////


wire [3:0] R, G, B;
wire hs,vs;

reg  HSync;
reg  VSync;
wire VBlank = ((vsync_ct < 25) || (vsync_ct > 254));
wire HBlank = ((hsync_ct >= 214) || (hsync_ct < 34));

assign VGA_SL = sl[1:0];


//actual: 0-225, 0-238
//quoted: 160/320, 102/204
wire [2:0] scale = status[11:9];
wire [2:0] sl = scale ? scale - 1'd1 : 3'd0;

reg [15:0] vsync_ct;
reg [15:0] hsync_ct;

reg ce_pix;
always @(posedge CLK_VIDEO) begin
	reg [3:0] pix;
	
	pix <= pix + 1'd1;

	ce_pix <= 0;
	if(&pix) begin
		hsync_ct <= hsync_ct + 1'd1;
		ce_pix <= 1;

		HSync <= hs;
		if (~HSync & hs) begin
			vsync_ct <= vsync_ct + 1'd1;
			hsync_ct <= 0;
			VSync <= vs;
			if (~VSync & vs) vsync_ct <= 0;
		end
	end
end


video_mixer #(455, 1, 1) video_mixer
(
	.*,
	.scandoubler(scale || forced_scandoubler),
	.hq2x(scale==1),
	.VGA_DE(vga_de),
	.freeze_sync()
);


////////////////////////////  INPUT  ////////////////////////////////////

wire [10:0] ps2_key;
wire  [7:0] col_select;
wire  [7:0] row_data;
wire  [3:0] pot_select;

wire [7:0] pot_data = 
   (pot_select[0] ? pda : 8'hFF) & 
   (pot_select[1] ? pdb : 8'hFF) & 
   (pot_select[2] ? pdc : 8'hFF) & 
   (pot_select[3] ? pdd : 8'hFF);

bally_input bally_input (.*);

////////////////////////////  MEMORY  ///////////////////////////////////


wire [12:0] cart_addr;
wire [7:0] cart_do;
wire cart_rd;

wire [12:0] bios_addr;
wire [7:0] bios_do;
wire bios_rd;

wire cart_bank_0;
wire cart_bank_1;
wire cart_rd_n;
reg [15:0] cart_size;

dpram #(13) rom
(
	.clock(clk_sys),
	.address_a(ioctl_download ? ioctl_addr[12:0] : cart_addr),
	.data_a(ioctl_dout),
	.wren_a(ioctl_wr && (ioctl_index == 8'd1)),
	.q_a(cart_do)
);

dpram #(13) bios
(
	.clock(clk_sys),
	.address_a(ioctl_download ? ioctl_addr[12:0] : bios_addr),
	.data_a(ioctl_dout),
	.wren_a(ioctl_wr && (ioctl_index == 8'd0)),
	.q_a(bios_do)
);


endmodule