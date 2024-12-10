module filter (
    input  logic          clk,        // Clock signal
    input  logic          rst_n,      // Active-low reset signal
    input  logic          ce,         // Clock enable signal
    input  logic signed [15:0] data_in, // Input Q15 fixed-point data
    output logic signed [15:0] avg,    // Output average Q15 fixed-point
    output logic          rdy         // Ready signal asserted every 2 cycles
);

    // Register to store the previous value
    logic signed [15:0] previous;

    // Intermediate 32-bit signed variable for summation
    logic signed [31:0] sum;

    // Counter for rdy signal
    logic [0:0] cycle_toggle; // 1-bit counter to alternate every clock cycle

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all internal states
            previous <= 16'sd0;
            avg <= 16'sd0;
            rdy <= 1'b0;
            cycle_toggle <= 1'b0; // Reset the cycle toggle
        end else if (ce) begin
            // Perform the operation only when CE is asserted
            sum = previous + data_in; // Use 32-bit addition to prevent overflow
            avg <= sum >>> 1;         // Divide by 2 with a right shift
            previous <= data_in;      // Update previous with the current input

            // Toggle the ready signal every 2 clock cycles
            if (cycle_toggle == 1'b1) begin
                rdy <= 1'b1; // Assert ready every second clock cycle
            end else begin
                rdy <= 1'b0; // Deassert ready on alternate cycles
            end
            cycle_toggle <= ~cycle_toggle; // Toggle the cycle bit
        end else begin
            rdy <= 1'b0; // Output is not valid when CE is deasserted
        end
    end

endmodule
