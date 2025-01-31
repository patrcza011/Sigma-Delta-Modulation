module comb_decimator #(
    parameter DECIMATION_FACTOR = 16 // Decimation factor (R)
)(
    input  logic clk,              // Clock signal
    input  logic reset,            // Reset signal
    input  logic valid_in,         // Input valid signal
    input  logic signed [15:0] data_in, // Q15 fixed-point input
    output logic valid_out,        // Output valid signal
    output logic signed [15:0] data_out // Q15 fixed-point output
);

    // Internal signals
    logic signed [31:0] integrator_reg; // Integrator register
    logic signed [31:0] decimated_reg;  // Decimated register
    logic signed [31:0] comb_reg;       // Comb filter register
    logic [3:0] sample_count;           // Counter for decimation factor
    logic valid_decimate;               // Valid signal for decimation

    // Integrator stage
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            integrator_reg <= 32'd0;
        end else if (valid_in) begin
            integrator_reg <= integrator_reg + data_in;
        end
    end

    // Decimation stage
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            sample_count <= 4'd0;
            decimated_reg <= 32'd0;
            valid_decimate <= 1'b0;
        end else if (valid_in) begin
            if (sample_count == DECIMATION_FACTOR - 1) begin
                decimated_reg <= integrator_reg; // Sample the integrator output
                valid_decimate <= 1'b1;         // Assert valid signal
                sample_count <= 4'd0;           // Reset counter
            end else begin
                sample_count <= sample_count + 4'd1;
                valid_decimate <= 1'b0;
            end
        end
    end

    // Comb stage (differentiator)
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            comb_reg <= 32'd0;
            data_out <= 16'd0;
            valid_out <= 1'b0;
        end else if (valid_decimate) begin
            // Differentiate: y[n] = x[n] - x[n-1]
            data_out <= (decimated_reg - comb_reg) >>> 4; // Scale back to Q15
            comb_reg <= decimated_reg; // Update comb register
            valid_out <= 1'b1;        // Assert output valid signal
        end else begin
            valid_out <= 1'b0;
        end
    end

endmodule