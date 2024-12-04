`timescale 1ns / 1ps

module filter_tb;

    // Parameters
    localparam int DATA_WIDTH = 16;
    localparam int NUM_TAPS = 64;
    localparam real CLK_FREQ = 2.8224e6; // Clock frequency in Hz
    localparam real CLK_PERIOD = 1.0e9 / CLK_FREQ; // Clock period in ns
    localparam real SINE_FREQ_1 = 15e3;  // Sine wave 1 frequency (15 kHz)
    localparam real SINE_FREQ_2 = 100e3; // Sine wave 2 frequency (100 kHz)

    // DUT (Device Under Test) ports
    logic clk;
    logic rst_n;
    logic signed [DATA_WIDTH-1:0] din;
    logic valid_in;
    logic signed [DATA_WIDTH-1:0] dout;
    logic valid_out;

    // Clock generation
    initial clk = 0;
    always #(CLK_PERIOD / 2) clk = ~clk; // Generate clock with 2.8224 MHz frequency

    // DUT instantiation
    filter dut (
        .clk(clk),
        .rst_n(rst_n),
        .din(din),
        .valid_in(valid_in),
        .dout(dout),
        .valid_out(valid_out)
    );

    // Sine wave generation
    real time_ns;
    real sine_wave_1;
    real sine_wave_2;

    initial begin
        // Initialize
        time_ns = 0;
        sine_wave_1 = 0;
        sine_wave_2 = 0;
    end

	always @(posedge clk) begin
    // Update simulation time
		 time_ns = time_ns + CLK_PERIOD;

		 // Generate sine waves (scale to s1.15 format)
		 sine_wave_1 = $sin(2.0 * 3.141592653589 * SINE_FREQ_1 * (time_ns * 1e-9));
		 sine_wave_2 = $sin(2.0 * 3.141592653589 * SINE_FREQ_2 * (time_ns * 1e-9));
		 din = $signed(integer'( (sine_wave_2) * (2 ** 15 - 1) )); // Combine and scale
	end


    // Reset and valid signal
    initial begin
        rst_n = 0;
        valid_in = 0;
        #1000; // Reset for 1000 ns
        rst_n = 1;
        valid_in = 1;
        #10000000; // Run simulation for 100 us
        valid_in = 0;

        // End simulation
        $stop;
    end

    // Monitor outputs
    initial begin
        $monitor("Time: %0t ns, Input: %0d, Output: %0d, Valid_out: %b",
                 $time, din, dout, valid_out);
    end

endmodule
