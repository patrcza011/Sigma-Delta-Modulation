`timescale 1ns / 1ps

module top_tb;

    // Parameters
    localparam CLK_PERIOD = 22694.4; // Clock period in ns
    localparam SAMPLE_RATE = 44100; // 44.1 kHz sampling rate
    localparam SAMPLE_PERIOD = 1_000_000_000 / SAMPLE_RATE; // Sample period in ns

    // Testbench signals
    reg clk;
    reg rst_n;
    reg valid_in_dac1;
    reg valid_in_dac2;
    reg [15:0] audio_in1;
    reg [15:0] audio_in2;
    reg valid_in_adc1;
    reg valid_in_adc2;
    wire sdm_out1;
    wire sdm_out2;
    wire valid_out_dac1;
    wire valid_out_dac2;
    wire sdm_in1;
    wire sdm_in2;
    wire valid_out_adc1;
    wire valid_out_adc2;
    wire [15:0] audio_out1;
    wire [15:0] audio_out2;

    // Instantiate the DUT (Device Under Test)
    top dut (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in_dac1(valid_in_dac1),
        .valid_in_dac2(valid_in_dac2),
        .audio_in1(audio_in1),
        .audio_in2(audio_in2),
        .valid_in_adc1(valid_in_adc1),
        .valid_in_adc2(valid_in_adc2),
        .sdm_in1(sdm_in1),
        .sdm_in2(sdm_in2),
        .valid_out_dac1(valid_out_dac1),
        .valid_out_dac2(valid_out_dac2),
        .sdm_out1(sdm_out1),
        .sdm_out2(sdm_out2),
        .valid_out_adc1(valid_out_adc1),
        .valid_out_adc2(valid_out_adc2),
        .audio_out1(audio_out1),
        .audio_out2(audio_out2)
    );

    // Connect sdm_out to sdm_in
    assign sdm_in1 = sdm_out1;
    assign sdm_in2 = sdm_out2;

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    // Generate sine wave for audio input
    real sine_wave;
    integer sample_count;

    initial begin
        sample_count = 0;
        forever begin
            #(SAMPLE_PERIOD);
            sine_wave = 32767 * $sin(2 * 3.14159 * sample_count / SAMPLE_RATE);
            audio_in1 = $rtoi(sine_wave); // Convert sine wave to 16-bit integer
            audio_in2 = $rtoi(sine_wave); // Same sine wave for both channels
            sample_count = sample_count + 1;
        end
    end

    // Test stimulus
    initial begin
        // Initialize inputs
        rst_n = 0;
        valid_in_dac1 = 0;
        valid_in_dac2 = 0;
        audio_in1 = 0;
        audio_in2 = 0;
        valid_in_adc1 = 0;
        valid_in_adc2 = 0;

        // Reset sequence
        #20;
        rst_n = 1;

        // Enable valid signals for DAC
        #10;
        valid_in_dac1 = 1;
        valid_in_dac2 = 1;

        // Enable valid signals for ADC
        #10;
        valid_in_adc1 = 1;
        valid_in_adc2 = 1;

        // Run simulation for a while
        #(19200*CLK_PERIOD);

        // End of simulation
        $stop;
    end

endmodule