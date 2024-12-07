`timescale 1ns / 1ps
module downsample_tb;
    logic clk;
    logic rst_n;
    logic valid_in;
    logic signed [15:0] in_signal;
    logic valid_out;
    logic signed [15:0] out_signal;

    // Instantiate downsample module
    downsample uut (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .in_signal(in_signal),
        .valid_out(valid_out),
        .out_signal(out_signal)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Test logic
    initial begin
        clk = 0;
        rst_n = 0;
        valid_in = 0;
        in_signal = 0;

        // Release reset
        #20 rst_n = 1;

        // Provide valid input signal
        for (int i = 0; i < 16; i++) begin
            #10 valid_in = 1;
            in_signal = $signed(i); // Incrementing input signal
        end

        #10 valid_in = 0; // Simulate a period of invalid inputs

        // Provide additional input
        for (int i = 16; i < 20; i++) begin
            #10 valid_in = 1;
            in_signal = $signed(i);
        end

        #100 $stop;
    end
endmodule
