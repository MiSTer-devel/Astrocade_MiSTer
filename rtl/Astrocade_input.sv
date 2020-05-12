// MiSTer Astrocade input handler by Kitrinx

// Key Matrix:
//                     p4  p3  p2  p1
//     x07 x06 x05 x04 x03 x02 x01 x00
// 0   c   ^   v   %   u   u   u   u  |
// 1   mr  ms  ch  /   d   d   d   d  |
// 2   7   8   9   x   l   l   l   l  |
// 3   4   5   6   -   r   r   r   r  |
// 4   1   2   3   +   t   t   t   t  |
// 5   ce  0   .   =                  |
// 6                                  |
// 7                                  |
// ====================================


module bally_input
(
	input         clk_sys,

	input  [31:0] joya,
	input  [31:0] joyb,
	input  [31:0] joyc,
	input  [31:0] joyd,

	input  [10:0] ps2_key,

	input      [7:0] col_select,
	output reg [7:0] row_data
);

wire [31:0] joy = joya | joyb | joyc | joyd;

// matrix[col][row]
reg [7:0] keyboard_matrix[8] = '{0, 0, 0, 0, 0, 0, 0, 0};
reg [7:0] joystick_matrix[8] = '{0, 0, 0, 0, 0, 0, 0, 0};

always @(posedge clk_sys) begin
	joystick_matrix[0][0] <= joya[3];
	joystick_matrix[0][1] <= joya[2];
	joystick_matrix[0][2] <= joya[1];
	joystick_matrix[0][3] <= joya[0];
	joystick_matrix[0][4] <= joya[4];

	joystick_matrix[1][0] <= joyb[3];
	joystick_matrix[1][1] <= joyb[2];
	joystick_matrix[1][2] <= joyb[1];
	joystick_matrix[1][3] <= joyb[0];
	joystick_matrix[1][4] <= joyb[4];

	joystick_matrix[2][0] <= joyc[3];
	joystick_matrix[2][1] <= joyc[2];
	joystick_matrix[2][2] <= joyc[1];
	joystick_matrix[2][3] <= joyc[0];
	joystick_matrix[2][4] <= joyc[4];

	joystick_matrix[3][0] <= joyd[3];
	joystick_matrix[3][1] <= joyd[2];
	joystick_matrix[3][2] <= joyd[1];
	joystick_matrix[3][3] <= joyd[0];
	joystick_matrix[3][4] <= joyd[4];

	joystick_matrix[6][5] <= joy[5] ; // 0
	joystick_matrix[7][4] <= joy[6] ; // 1
	joystick_matrix[6][4] <= joy[7] ; // 2
	joystick_matrix[5][4] <= joy[8] ; // 3
	joystick_matrix[7][3] <= joy[9] ; // 4
	joystick_matrix[6][3] <= joy[10]; // 5
	joystick_matrix[5][3] <= joy[11]; // 6
	joystick_matrix[7][2] <= joy[12]; // 7
	joystick_matrix[6][2] <= joy[13]; // 8
	joystick_matrix[5][2] <= joy[14]; // 9
	joystick_matrix[5][1] <= joy[15]; // space (CH)

	joystick_matrix[7][0] <= joy[16]; // enter (C)
	joystick_matrix[7][5] <= joy[17]; // backspace (CE)

	joystick_matrix[4][4] <= joy[18]; // +
	joystick_matrix[4][3] <= joy[19]; // -
	joystick_matrix[4][2] <= joy[20]; // *
	joystick_matrix[4][1] <= joy[21]; // /
	joystick_matrix[4][5] <= joy[22]; // =
	joystick_matrix[5][5] <= joy[23]; // .

	joystick_matrix[7][1] <= joy[24]; // mr
	joystick_matrix[6][1] <= joy[25]; // ms
	joystick_matrix[6][0] <= joy[26]; // prev
	joystick_matrix[5][0] <= joy[27]; // next
	joystick_matrix[4][0] <= joy[28]; // %

	case(ps2_key[7:0])
		'h16: keyboard_matrix[7][4] <= ps2_key[9]; // 1
		'h1E: keyboard_matrix[6][4] <= ps2_key[9]; // 2
		'h26: keyboard_matrix[5][4] <= ps2_key[9]; // 3
		'h25: keyboard_matrix[7][3] <= ps2_key[9]; // 4
		'h2E: keyboard_matrix[6][3] <= ps2_key[9]; // 5
		'h36: keyboard_matrix[5][3] <= ps2_key[9]; // 6
		'h3D: keyboard_matrix[7][2] <= ps2_key[9]; // 7
		'h3E: keyboard_matrix[6][2] <= ps2_key[9]; // 8
		'h46: keyboard_matrix[5][2] <= ps2_key[9]; // 9
		'h45: keyboard_matrix[6][5] <= ps2_key[9]; // 0
		'h79: keyboard_matrix[4][4] <= ps2_key[9]; // +
		'h7B: keyboard_matrix[4][3] <= ps2_key[9]; // -
		'h7C: keyboard_matrix[4][2] <= ps2_key[9]; // *
		'h4A: keyboard_matrix[4][1] <= ps2_key[9]; // /
		'h55: keyboard_matrix[4][5] <= ps2_key[9]; // =
		'h29: keyboard_matrix[5][1] <= ps2_key[9]; // space (CH)
		'h5A: keyboard_matrix[7][0] <= ps2_key[9]; // enter (C)
		'h66: keyboard_matrix[7][5] <= ps2_key[9]; // backspace (CE)
	endcase

	row_data <=
		(col_select[0] ? (joystick_matrix[0] | keyboard_matrix[0]) : 8'h00) | 
		(col_select[1] ? (joystick_matrix[1] | keyboard_matrix[1]) : 8'h00) | 
		(col_select[2] ? (joystick_matrix[2] | keyboard_matrix[2]) : 8'h00) | 
		(col_select[3] ? (joystick_matrix[3] | keyboard_matrix[3]) : 8'h00) | 
		(col_select[4] ? (joystick_matrix[4] | keyboard_matrix[4]) : 8'h00) | 
		(col_select[5] ? (joystick_matrix[5] | keyboard_matrix[5]) : 8'h00) | 
		(col_select[6] ? (joystick_matrix[6] | keyboard_matrix[6]) : 8'h00) | 
		(col_select[7] ? (joystick_matrix[7] | keyboard_matrix[7]) : 8'h00);
end

endmodule
