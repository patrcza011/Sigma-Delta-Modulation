module sdm_demodulator (
    input  logic              clk,
    input  logic              rst_n,
    input  logic              valid_in,   // New valid input signal
    input  logic      			din, //SDM 
    output logic              valid_out,  // New valid output signal
    output logic   [15 : 0]   dout //Audio fix point
);

	logic signed [15:0] sdm_bound;
	logic signed [15:0] filtered;
	logic						valid;
	
	 always_comb begin
        sdm_bound = (din) ? 16'sd32767 : -16'sd32767; //bind SDM to fixpoint
    end
	 
	filter inst (
        .clk(clk),
        .rst_n(rst_n),
        .din(sdm_bound),
        .valid_in(valid_in),
        .dout(filtered),
        .valid_out(valid)
    );
	 
	 downsample inst2 (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid),
        .in_signal(filtered),
        .valid_out(valid_out),
        .out_signal(dout)
    );

endmodule