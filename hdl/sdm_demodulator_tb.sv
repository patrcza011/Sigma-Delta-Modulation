`timescale 1ns / 1ps
module sdm_demodulator_tb;

    // Testbench signals
    logic clk;
    logic rst_n;
    logic valid_in;
    logic din;
    logic valid_out;
    logic [15:0] dout;

    // Instantiate the DUT (Device Under Test)
    sdm_demodulator dut (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .din(din),
        .valid_out(valid_out),
        .dout(dout)
    );

    // Clock generation: 2.8224 MHz
    initial begin
        clk = 0;
        forever #177.3 clk = ~clk; // 2.8224 MHz clock (354.6 ns period)
    end

    // Reset logic
    initial begin
        rst_n = 0;
        valid_in = 0;
        din = 0;
        #500;  // Allow 500 ns for reset
        rst_n = 1;  // Release reset
    end

    // Generate 1 clock cycle high, 3 clock cycles low
    initial begin
        valid_in = 1;
        forever begin
            din = 1;  // High for 1 clock cycle
            @(posedge clk); // Wait for 1 clock cycle
            din = 0;  // Low for 3 clock cycles
            @(posedge clk); // Wait for 3 clock cycles
            @(posedge clk);
            @(posedge clk);
				@(posedge clk);
				@(posedge clk);
				@(posedge clk);
				@(posedge clk);
        end
    end

    // Monitor outputs
    initial begin
        $monitor("Time: %0t | din: %b | dout: %0d | valid_out: %b", $time, din, dout, valid_out);
    end

    // End simulation after some time
    initial begin
        #500000;  // Run simulation for 50,000 ns (50 µs)
        $finish;
    end

endmodule

