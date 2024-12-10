`timescale 1ns / 1ps
module filter_tb;

    logic          clk;        // Testbench clock
    logic          rst_n;      // Testbench active-low reset
    logic          ce;         // Testbench clock enable
    logic signed [15:0] data_in; // Test input Q15 data
    logic signed [15:0] avg;     // Test output Q15 average
    logic          rdy;         // Test output ready signal

    // Instantiate the module
    filter uut (
        .clk(clk),
        .rst_n(rst_n),
        .ce(ce),
        .data_in(data_in),
        .avg(avg),
        .rdy(rdy)
    );

    // Clock generation: 10ns period
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        // Initialize signals
        rst_n = 0; // Apply reset
        ce = 0;
        data_in = 16'sd0;
        #10;

        // Deassert reset
        rst_n = 1;

        // Apply test data with clock enable
        ce = 1;
        data_in = 16'sd16384;  // 0.5 in Q15
        #10;
        data_in = 16'sd8192;   // 0.25 in Q15
        #10;
        data_in = 16'sd0;      // 0.0 in Q15
        #10;
        data_in = -16'sd32768; // -1.0 in Q15
        #10;

        $stop;
    end

    initial begin
        $monitor("Time: %0t | rst_n: %b | CE: %b | Data In: %d | Avg: %d | RDY: %b", 
                 $time, rst_n, ce, data_in, avg, rdy);
    end

endmodule
