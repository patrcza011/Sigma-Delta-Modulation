module sdm_adc2 #(
	parameter int dac_bw = 16,
	// The oversampling ratio (OSR) in 2^N format
	parameter int osr = 6
)(
	input logic clk,
	input logic rst_n,
	input logic valid_in,
	input logic [15:0] din,
	output logic dout,
	output logic valid_out
);

	// This defines the midpoint value for DAC computation.
	// 'mid_val' defines the midpoint of the DAC range, accounting for bit width and oversampling ratio.
	localparam int mid_val = 2 ** (dac_bw - 1) + 2 ** (osr + 2);
	localparam int bw_ext = 2;
	localparam int bw_tot = dac_bw + bw_ext;

	logic dout_r;
	logic dac_dout;

	// The first accumulator in the modulator loop. It helps shape the noise by integrating the input signal and feedback.
	logic signed [bw_tot-1 : 0] DAC_acc_1st;
	logic signed [bw_tot-1 : 0] max_val;
	logic signed [bw_tot-1 : 0] min_val;
	logic signed [bw_tot-1 : 0] dac_val;
	logic signed [bw_tot-1 : 0] in_ext;
	logic signed [bw_tot-1 : 0] delta_s0_c0;
	// This signal represents the updated value after adding the input signal and feedback in the first stage.
	logic signed [bw_tot-1 : 0] delta_s0_c1;

	assign max_val = mid_val;
	assign min_val = -mid_val;
	assign dac_val = (!dout_r) ? max_val : min_val;
	assign in_ext = {{bw_ext{din[dac_bw - 1]}}, din};
	assign delta_s0_c0 = in_ext + dac_val;
	assign delta_s0_c1 = DAC_acc_1st + delta_s0_c0;

	// This always block resets and updates the first accumulator.
	always_ff @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			DAC_acc_1st <= '0;
		end else if (valid_in) begin
			DAC_acc_1st <= delta_s0_c1;
		end
	end

	localparam int bw_tot2 = bw_tot + osr;

	// This is the second accumulator for the second-order modulation stage.
	// The second accumulator in the modulator loop. It provides additional noise shaping for second-order behavior.
	logic signed [bw_tot2-1 : 0] DAC_acc_2nd;
	logic signed [bw_tot2-1 : 0] max_val2;
	logic signed [bw_tot2-1 : 0] min_val2;
	logic signed [bw_tot2-1 : 0] dac_val2;
	logic signed [bw_tot2-1 : 0] in_ext2;
	logic signed [bw_tot2-1 : 0] delta_s1_c0;
	// This signal represents the updated value after processing the second stage of the modulator.
	logic signed [bw_tot2-1 : 0] delta_s1_c1;

	assign max_val2 = mid_val;
	assign min_val2 = -mid_val;
	assign dac_val2 = (!dout_r) ? max_val2 : min_val2;
	assign in_ext2 = {{osr{delta_s0_c1[bw_tot - 1]}}, delta_s0_c1};
	assign delta_s1_c0 = in_ext2 + dac_val2;
	assign delta_s1_c1 = DAC_acc_2nd + delta_s1_c0;

	// This always block resets and updates the second accumulator.
	always_ff @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			DAC_acc_2nd <= '0;
		end else if (valid_in) begin
			DAC_acc_2nd <= delta_s1_c1;
		end
	end

	// This block determines the output bit based on the MSB of the second accumulator and toggles the feedback signal.
	always_ff @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			dout_r <= 1'b0;
			dac_dout <= 1'b0;
		end else if (valid_in) begin
			dout_r <= delta_s1_c1[bw_tot2-1];
			dac_dout <= ~dout_r;
		end
	end

	
	assign dout = dout_r;

	// Valid_out logic
	assign valid_out = valid_in; // Output valid follows input valid

endmodule