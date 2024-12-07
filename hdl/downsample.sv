module downsample (
    input logic clk,                  // Input clock signal
    input logic rst_n,                // Active-low reset
    input logic valid_in,             // Input valid signal
    input logic signed [15:0] in_signal, // 16-bit signed input signal
    output logic valid_out,           // Output valid signal
    output logic signed [15:0] out_signal // 16-bit signed downsampled output
);

    parameter int DOWNSAMPLE_FACTOR = 64; // Downsampling factor (e.g., keep every 64th sample)
    logic [$clog2(DOWNSAMPLE_FACTOR)-1:0] sample_counter; // Counter to track samples

    // Counter logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sample_counter <= 0;
        end else if (valid_in) begin // Increment counter only when input is valid
            if (sample_counter == DOWNSAMPLE_FACTOR - 1) begin
                sample_counter <= 0;
            end else begin
                sample_counter <= sample_counter + 1;
            end
        end
    end

    // Output logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_signal <= 0;
            valid_out <= 0;
        end else if (valid_in && sample_counter == 0) begin
            out_signal <= in_signal; // Capture the current sample
            valid_out <= 1;          // Output is valid for this cycle
        end else begin
            valid_out <= 0;          // Output is invalid in other cycles
        end
    end

endmodule
