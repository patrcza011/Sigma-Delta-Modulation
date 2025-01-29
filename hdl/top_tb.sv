`timescale 1fs / 1fs

module top_tb;


    // Clock and sample rate parameters
    localparam real CLK_PERIOD   = 22694.4; // Clock period in ns
    localparam int  SAMPLE_RATE  = 44100;   // 44.1 kHz sampling rate
    localparam real SAMPLE_PERIOD= 1_000_000_000 / SAMPLE_RATE; // in ns

    //----------------------------------------------------------------------
    // Testbench Signals
    //----------------------------------------------------------------------
    reg  clk;
    reg  rst_n;

    // DAC side
    reg         valid_in_dac;
    reg  [15:0] audio_in;
    wire        valid_out_dac;
    wire        sdm_out;

    // ADC side
    reg         valid_in_adc;
    reg         sdm_in;       // This will be driven by sdm_out in the TB
    wire        valid_out_adc;
    wire [15:0] audio_out;

    //----------------------------------------------------------------------
    // Instantiate the TOP Module with parameter
    //----------------------------------------------------------------------
    top dut (
        .clk           (clk),
        .rst_n         (rst_n),
        .valid_in_dac  (valid_in_dac),
        .audio_in      (audio_in),
        .valid_in_adc  (valid_in_adc),
        .sdm_in        (sdm_in),
        .valid_out_dac (valid_out_dac),
        .sdm_out       (sdm_out),
        .valid_out_adc (valid_out_adc),
        .audio_out     (audio_out)
    );

    //----------------------------------------------------------------------
    // Clock Generation
    //----------------------------------------------------------------------
    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    //----------------------------------------------------------------------
    // Drive SDM input from SDM output (loopback for testing)
    //----------------------------------------------------------------------
    assign sdm_in = sdm_out;

    //----------------------------------------------------------------------
    // Generate a Sine Wave for audio_in
    //----------------------------------------------------------------------
    real sine_wave;
    integer sample_count;

    initial begin
        sample_count = 0;
        forever begin
            #(SAMPLE_PERIOD);
            sine_wave = 32767 * $sin(2.0 * 3.14159 * sample_count / SAMPLE_RATE);
            audio_in = $rtoi(sine_wave); // Convert sine wave to 16-bit integer
            sample_count++;
        end
    end

    //----------------------------------------------------------------------
    // Test Stimulus
    //----------------------------------------------------------------------
    initial begin
        // Initialize inputs
        rst_n        = 0;
        valid_in_dac = 0;
        valid_in_adc = 0;
        audio_in     = 0;

        // Reset sequence
        #20;
        rst_n = 1;

        // After reset deassertion, enable 'valid_in_dac'
        #10;
        valid_in_dac = 1;

        // Enable 'valid_in_adc'
        #10;
        valid_in_adc = 1;

        // Let the simulation run for a while
        #(19200 * CLK_PERIOD);

        // End simulation
        $stop;
    end

endmodule
