module fir_filter(
    input  logic              clk,
    input  logic              rst_n,
    input  logic              valid_in,
    input  logic signed [15:0] din,
    output logic              valid_out,
    output logic signed [15:0] dout
);

    // Example FIR coefficients
    localparam signed [15:0] COEFF [0:7] = '{16'sd1, 16'sd2, 16'sd3, 16'sd4, 16'sd4, 16'sd3, 16'sd2, 16'sd1};

    logic signed [15:0] shift_reg [0:7];
    logic signed [31:0] acc;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            foreach (shift_reg[i]) shift_reg[i] <= 16'sd0;
            acc <= 32'sd0;
            dout <= 16'sd0;
            valid_out <= 1'b0;
        end else if (valid_in) begin
            // Shift register for input samples
            shift_reg[0] <= din;
            for (int i = 1; i < 8; i++)
                shift_reg[i] <= shift_reg[i-1];

            // FIR accumulation
            acc = 32'sd0;
            for (int i = 0; i < 8; i++)
                acc += shift_reg[i] * COEFF[i];

            dout <= acc[30:15]; // Scale down to 16 bits
            valid_out <= 1'b1;
        end else begin
            valid_out <= 1'b0;
        end
    end

endmodule