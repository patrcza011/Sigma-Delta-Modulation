// FIR DECIMATOR VERSION FOR ICARUS
module fir_decimator #(
    parameter COEFF_WIDTH = 16,
    parameter DATA_WIDTH = 16,
    parameter TAPS = 17,
    parameter DECIMATION_FACTOR = 4
)(
    input  wire clk,
    input  wire rst_n,
    input  wire valid_in,                     // Input valid signal
    input  wire signed [DATA_WIDTH-1:0] data_in, // Input data
    output reg valid_out,                    // Output valid signal
    output reg signed [DATA_WIDTH-1:0] data_out // Output data
);

    // Define the filter coefficients (low-pass anti-aliasing filter)
    reg signed [COEFF_WIDTH-1:0] coeff [0:TAPS-1];
    initial begin
        coeff[0]  = -119;
        coeff[1]  = 197;
        coeff[2]  = 692;
        coeff[3]  = 0;
        coeff[4]  = -2613;
        coeff[5]  = -2855;
        coeff[6]  = 5177;
        coeff[7]  = 18681;
        coeff[8]  = 25580;
        coeff[9]  = 18681;
        coeff[10] = 5177;
        coeff[11] = -2855;
        coeff[12] = -2613;
        coeff[13] = 0;
        coeff[14] = 692;
        coeff[15] = 197;
        coeff[16] = -119;
    end

    // Delay line for the input data
    reg signed [DATA_WIDTH-1:0] delay_line [0:TAPS-1];

    // Valid signal pipeline (to align with the delay line)
    reg valid_pipeline [0:TAPS-1];

    // Multiply-accumulate result
    reg signed [DATA_WIDTH+COEFF_WIDTH-1:0] mac_result;

    // Counter to track decimation
    reg [1:0] decimation_counter;

    // Initialize the delay line, valid pipeline, and counter
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < TAPS; i = i + 1) begin
                delay_line[i] <= 0;
                valid_pipeline[i] <= 0;
            end
            decimation_counter <= 0;
        end else begin
            if (valid_in) begin
                // Shift the delay line and valid pipeline
                for (i = TAPS-1; i > 0; i = i - 1) begin
                    delay_line[i] <= delay_line[i-1];
                    valid_pipeline[i] <= valid_pipeline[i-1];
                end
                delay_line[0] <= data_in;
                valid_pipeline[0] <= 1;

                // Increment the decimation counter
                decimation_counter <= decimation_counter + 1;

                // Decimation logic: process only every DECIMATION_FACTOR-th sample
                if (decimation_counter == DECIMATION_FACTOR - 1) begin
                    decimation_counter <= 0;
                end else begin
                    valid_pipeline[0] <= 0; // Suppress output for non-decimated samples
                end
            end else begin
                // If valid_in is low, reset the valid pipeline
                valid_pipeline[0] <= 0;
            end
        end
    end

    // Perform the multiply-accumulate operation
    always @(*) begin
        mac_result = 0;
        for (i = 0; i < TAPS; i = i + 1) begin
            mac_result = mac_result + delay_line[i] * coeff[i];
        end
    end

    // Assign the output
    always @(*) begin
        data_out = mac_result[DATA_WIDTH+COEFF_WIDTH-1:COEFF_WIDTH];
    end

    // Output valid signal is asserted only when the decimated output is ready
    always @(*) begin
        valid_out = (decimation_counter == DECIMATION_FACTOR - 1);
    end

endmodule