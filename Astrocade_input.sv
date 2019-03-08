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
	input  [15:0] joya,
	input  [15:0] joyb,
	input  [7:0] joya_paddle,
	input  [7:0] joyb_paddle,

	input  [10:0] ps2_key,
	input  [3:0]  pot_select,
	output [7:0]  pot_data,

	input  [7:0]  col_select,
	output [7:0]  row_data
);

// matrix[col][row]
reg [7:0] keyboard_matrix[8] = '{0, 0, 0, 0, 0, 0, 0, 0};
reg [7:0] joystick_matrix[8] = '{0, 0, 0, 0, 0, 0, 0, 0};

reg [7:0] pots[2];

reg [7:0] ps2_col_row = 0;
reg ps2_state;

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

	joystick_matrix[6][5] <= (joya[5] | joyb[5]); // 0
	joystick_matrix[7][4] <= (joya[6] | joyb[6]); // 1
	joystick_matrix[6][4] <= (joya[7] | joyb[7]); // 2
	joystick_matrix[5][4] <= (joya[8] | joyb[8]); // 3
	joystick_matrix[7][3] <= (joya[9] | joyb[9]); // 4
	joystick_matrix[6][3] <= (joya[10] | joyb[10]); // 5
	joystick_matrix[5][3] <= (joya[11] | joyb[11]); // 6
	joystick_matrix[7][2] <= (joya[12] | joyb[12]); // 7
	joystick_matrix[6][2] <= (joya[13] | joyb[13]); // 8
	joystick_matrix[5][2] <= (joya[14] | joyb[14]); // 9
	joystick_matrix[5][1] <= (joya[15] | joyb[15]); // Cr

	case(ps2_key[7:0])
		'h16: ps2_col_row <= 8'h74; // 1
		'h1E: ps2_col_row <= 8'h64; // 2
		'h26: ps2_col_row <= 8'h54; // 3
		'h25: ps2_col_row <= 8'h73; // 4
		'h2E: ps2_col_row <= 8'h63; // 5
		'h36: ps2_col_row <= 8'h53; // 6
		'h3D: ps2_col_row <= 8'h72; // 7
		'h3E: ps2_col_row <= 8'h62; // 8
		'h46: ps2_col_row <= 8'h52; // 9
		'h45: ps2_col_row <= 8'h65; // 0

		'h79: ps2_col_row <= 8'h44; // +
		'h7B: ps2_col_row <= 8'h43; // -
		'h7C: ps2_col_row <= 8'h42; // *
		'h4A: ps2_col_row <= 8'h41; // /
		'h55: ps2_col_row <= 8'h45; // =

		'h29: ps2_col_row <= 8'h51; // space (CH)

		'h5A: ps2_col_row <= 8'd70; // enter (C)
		'h66: ps2_col_row <= 8'd75; // backspace (CE)
		default: ps2_col_row <= 8'h00;
	endcase

	ps2_state <= ps2_key[9];
	keyboard_matrix[ps2_col_row[7:4]][ps2_col_row[3:0]] <= ps2_state;
end

always @(*) begin
	case (col_select)
		8'h01: row_data = (joystick_matrix[0] | keyboard_matrix[0]);
		8'h02: row_data = (joystick_matrix[1] | keyboard_matrix[1]);
		8'h04: row_data = (joystick_matrix[2] | keyboard_matrix[2]);
		8'h08: row_data = (joystick_matrix[3] | keyboard_matrix[3]);
		8'h10: row_data = (joystick_matrix[4] | keyboard_matrix[4]);
		8'h20: row_data = (joystick_matrix[5] | keyboard_matrix[5]);
		8'h40: row_data = (joystick_matrix[6] | keyboard_matrix[6]);
		8'h80: row_data = (joystick_matrix[7] | keyboard_matrix[7]);
		default: row_data = (joystick_matrix[0] | keyboard_matrix[0]);
	endcase

	case (pot_select)
		4'h1: pot_data = joya_paddle;
		4'h2: pot_data = joyb_paddle;
		4'h4: pot_data = 8'hFF;
		4'h8: pot_data = 8'hFF;
		default: pot_data = 8'hFF;
	endcase
end

endmodule