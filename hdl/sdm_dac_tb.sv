`timescale 1ns / 1ps
module sdm_dac_tb;

    // Parameters
    parameter int dac_bw = 16;

    // Clock and Reset
    logic clk;
    logic rst_n;

    // Inputs and Outputs
    logic [15:0] din;
    logic dout;
    logic valid_in;
    logic valid_out;

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

    // Input stimulus: Single transaction with -16384
    initial begin
        // Initial values
        din = 16'sd0;
        valid_in = 1'b0;

        // Wait for reset deassertion
        @(posedge rst_n);

        // Perform a single transaction
        #1000 valid_in = 1'b1; // Assert valid_in
        din = 16'h01A4;     // Set input to -16384
		  #22694.4 din = 16'hC000;

        // Finish simulation after observing results
        #500000 $finish;
    end

    // Instantiate the DUT
    sdm_dac_1st dut (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .din(din),
        .valid_out(valid_out),
        .dout(dout)
    );

    // Monitor
    initial begin
        $monitor("Time: %0t ns | Reset: %b | Valid_In: %b | Din: %d | Valid_Out: %b | Dout: %b", 
                 $time, rst_n, valid_in, din, valid_out, dout);
    end

endmodule
