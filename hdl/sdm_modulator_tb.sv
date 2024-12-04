`timescale 1ns / 1ps
module sdm_modulator_tb;

    // Parameters
    parameter int dac_bw = 16;

    // Clock and Reset
    logic clk;
    logic rst_n;

    // Inputs and Outputs
    logic [15:0] din;
    logic dout;

    // Clock generation: 2.8224 MHz
    initial begin
        clk = 0;
        forever #177.3 clk = ~clk; // 2.8224 MHz clock (354.6 ns period)
    end

    // Reset generation
    initial begin
        rst_n = 0;
        #500 rst_n = 1; // Release reset after 500 ns
    end

    // Input stimulus
    initial begin
        // Set input to -16384 (two's complement representation)
        din = -16'sd16384;
    end

    // Instantiate the DUT
    sdm_modulator dut (
        .clk(clk),
        .rst_n(rst_n),
        .din(din),
        .dout(dout)
    );

    // Monitor
    initial begin
        $monitor("Time: %0t ns | Reset: %b | Din: %d | Dout: %b", $time, rst_n, din, dout);
        #500000 $finish; // Run simulation for 5000 ns
    end

endmodule
