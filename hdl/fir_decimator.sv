// FIR DECIMATOR VERSION FOR QUARTUS AND VIVADO
module fir_decimator #(
    parameter COEFF_WIDTH = 16,
    parameter DATA_WIDTH = 16,
    parameter TAPS = 17,
    parameter DECIMATION_FACTOR = 4
)(
    input  logic clk,
    input  logic rst_n,
    input  logic valid_in,                     // Input valid signal
    input  logic signed [DATA_WIDTH-1:0] data_in, // Input data
    output logic valid_out,                    // Output valid signal
    output logic signed [DATA_WIDTH-1:0] data_out // Output data
);

    // Define the filter coefficients (low-pass anti-aliasing filter)
    localparam logic signed [COEFF_WIDTH-1:0] coeff [TAPS] = '{
         -16'sd119, 16'sd197, 16'sd692, 16'sd0,
         -16'sd2613, -16'sd2855, 16'sd5177, 16'sd18681,
         16'sd25580, 16'sd18681, 16'sd5177, -16'sd2855,
         -16'sd2613, 16'sd0, 16'sd692, 16'sd197, -16'sd119
    };

    // Delay line for the input data
    logic signed [DATA_WIDTH-1:0] delay_line [TAPS-1:0];

    // Valid signal pipeline (to align with the delay line)
    logic valid_pipeline [TAPS-1:0];

    // Multiply-accumulate result
    logic signed [DATA_WIDTH+COEFF_WIDTH-1:0] mac_result;

    // Counter to track decimation
    logic [1:0] decimation_counter;

    // Initialize the delay line, valid pipeline, and counter
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < TAPS; i++) begin
                delay_line[i] <= '0;
                valid_pipeline[i] <= 1'b0;
            end
            decimation_counter <= 2'b00;
        end else begin
            if (valid_in) begin
                // Shift the delay line and valid pipeline
                for (int i = TAPS-1; i > 0; i--) begin
                    delay_line[i] <= delay_line[i-1];
                    valid_pipeline[i] <= valid_pipeline[i-1];
                end
                delay_line[0] <= data_in;
                valid_pipeline[0] <= 1'b1;

                // Increment the decimation counter
                decimation_counter <= decimation_counter + 1;

                // Decimation logic: process only every DECIMATION_FACTOR-th sample
                if (decimation_counter == DECIMATION_FACTOR - 1) begin
                    decimation_counter <= 2'b00;
                end else begin
                    valid_pipeline[0] <= 1'b0; // Suppress output for non-decimated samples
                end
            end else begin
                // If valid_in is low, reset the valid pipeline
                valid_pipeline[0] <= 1'b0;
            end
        end
    end

    // Perform the multiply-accumulate operation
    always_comb begin
        mac_result = '0;
        for (int i = 0; i < TAPS; i++) begin
            mac_result = mac_result + delay_line[i] * coeff[i];
        end
    end

    // Assign the output
    assign data_out = mac_result[DATA_WIDTH+COEFF_WIDTH-1:COEFF_WIDTH];

    // Output valid signal is asserted only when the decimated output is ready
    assign valid_out = (decimation_counter == DECIMATION_FACTOR - 1);

endmodule