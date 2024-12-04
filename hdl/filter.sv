module filter #(
    parameter int NUM_TAPS = 64,         // Number of filter taps
    parameter int DATA_WIDTH = 16       // Width of input/output data
) (
    input  logic clk,                   // Clock signal
    input  logic rst_n,                 // Active-low reset
    input  logic signed [DATA_WIDTH-1:0] din,  // Input data (s1.15)
    input  logic valid_in,              // Input valid signal
    output logic signed [DATA_WIDTH-1:0] dout, // Filtered output data (s1.15)
    output logic valid_out              // Output valid signal
);

    // Coefficients for the FIR filter
    logic signed [DATA_WIDTH-1:0] coeff[NUM_TAPS];
	 // Initialization of coefficients in s1.15 format


    // Internal registers for the shift register and accumulation
    logic signed [DATA_WIDTH-1:0] shift_reg[NUM_TAPS];
    logic signed [(DATA_WIDTH*2)-1:0] mac_result;

    // Initialization of coefficients (example values)
	initial begin
		 coeff[0]  = 16'sh38;
		 coeff[1]  = 16'sh3b;
		 coeff[2]  = 16'sh42;
		 coeff[3]  = 16'sh4c;
		 coeff[4]  = 16'sh5a;
		 coeff[5]  = 16'sh6b;
		 coeff[6]  = 16'sh81;
		 coeff[7]  = 16'sh9a;
		 coeff[8]  = 16'shb7;
		 coeff[9]  = 16'shd7;
		 coeff[10] = 16'shfb;
		 coeff[11] = 16'sh121;
		 coeff[12] = 16'sh14b;
		 coeff[13] = 16'sh176;
		 coeff[14] = 16'sh1a4;
		 coeff[15] = 16'sh1d3;
		 coeff[16] = 16'sh203;
		 coeff[17] = 16'sh233;
		 coeff[18] = 16'sh264;
		 coeff[19] = 16'sh293;
		 coeff[20] = 16'sh2c2;
		 coeff[21] = 16'sh2ef;
		 coeff[22] = 16'sh31a;
		 coeff[23] = 16'sh342;
		 coeff[24] = 16'sh368;
		 coeff[25] = 16'sh389;
		 coeff[26] = 16'sh3a7;
		 coeff[27] = 16'sh3c0;
		 coeff[28] = 16'sh3d4;
		 coeff[29] = 16'sh3e4;
		 coeff[30] = 16'sh3ee;
		 coeff[31] = 16'sh3f4;
		 coeff[32] = 16'sh3f4;
		 coeff[33] = 16'sh3ee;
		 coeff[34] = 16'sh3e4;
		 coeff[35] = 16'sh3d4;
		 coeff[36] = 16'sh3c0;
		 coeff[37] = 16'sh3a7;
		 coeff[38] = 16'sh389;
		 coeff[39] = 16'sh368;
		 coeff[40] = 16'sh342;
		 coeff[41] = 16'sh31a;
		 coeff[42] = 16'sh2ef;
		 coeff[43] = 16'sh2c2;
		 coeff[44] = 16'sh293;
		 coeff[45] = 16'sh264;
		 coeff[46] = 16'sh233;
		 coeff[47] = 16'sh203;
		 coeff[48] = 16'sh1d3;
		 coeff[49] = 16'sh1a4;
		 coeff[50] = 16'sh176;
		 coeff[51] = 16'sh14b;
		 coeff[52] = 16'sh121;
		 coeff[53] = 16'shfb;
		 coeff[54] = 16'shd7;
		 coeff[55] = 16'shb7;
		 coeff[56] = 16'sh9a;
		 coeff[57] = 16'sh81;
		 coeff[58] = 16'sh6b;
		 coeff[59] = 16'sh5a;
		 coeff[60] = 16'sh4c;
		 coeff[61] = 16'sh42;
		 coeff[62] = 16'sh3b;
		 coeff[63] = 16'sh38;
	end


    // Shift register logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < NUM_TAPS; i++) begin
                shift_reg[i] <= '0;
            end
        end else if (valid_in) begin
            shift_reg[0] <= din;
            for (int i = 1; i < NUM_TAPS; i++) begin
                shift_reg[i] <= shift_reg[i-1];
            end
        end
    end

    // Multiply-accumulate logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mac_result <= '0;
        end else if (valid_in) begin
            mac_result <= 0;
            for (int i = 0; i < NUM_TAPS; i++) begin
                mac_result <= mac_result + shift_reg[i] * coeff[i];
            end
        end
    end

    // Output logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout <= '0;
            valid_out <= 0;
        end else begin
            // Truncate and shift to fit back into s1.15 format
            dout <= mac_result[(DATA_WIDTH*2)-2:DATA_WIDTH-1]; // Keep s1.15 format
            valid_out <= valid_in;
        end
    end

endmodule
