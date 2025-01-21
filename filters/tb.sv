// Testbench for CIC Decimation Filter and FIR Filter
module tb;

    // Parameters for the testbench
    localparam CLK_PERIOD = 10;  // Clock period in time units
    localparam SAMPLE_COUNT = 256;  // Number of input samples

    // Signals
    logic clk;
    logic rst_n;
    logic valid_in;
    logic signed [15:0] din;
    logic valid_out;
    logic signed [15:0] dout;

    // Instantiate the CIC Decimation Filter
    logic valid_cic;
    logic signed [15:0] cic_out;

    cic_decimation_filter #(
        .N(8),  // Decimation factor
        .STAGES(4)  // Number of CIC stages
    ) cic_inst (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .din(din),
        .valid_out(valid_cic),
        .dout(cic_out)
    );

    // Instantiate the FIR Filter
    fir_filter fir_inst (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_cic),
        .din(cic_out),
        .valid_out(valid_out),
        .dout(dout)
    );

    // Clock generation
    always begin
        clk = 1;
        #(CLK_PERIOD / 2);
        clk = 0;
        #(CLK_PERIOD / 2);
    end

    // Test procedure
    initial begin
        // Initialization
        rst_n = 0;
        valid_in = 0;
        din = 0;

        // Apply reset
        #CLK_PERIOD;
        rst_n = 1;
        
        // Generate input samples: random -1 or 1
        for (int i = 0; i < SAMPLE_COUNT; i++) begin
            @(posedge clk);
            valid_in = 1;
            din = ($random % 2) ? 16'sd32767 : -16'sd32767;  // Generate -1 or 1 scaled to fixed-point
        end

        // Stop valid input after generating all samples
        @(posedge clk);
        valid_in = 0;

        // Wait for processing to complete
        repeat (50) @(posedge clk);

        // End simulation
        $stop;
    end

    // Monitor output
    initial begin
        forever begin
            @(posedge clk);
            if (valid_out) begin
                $display("%0t\t%b\t%d", $time, valid_out, dout);
            end
        end
    end

endmodule
