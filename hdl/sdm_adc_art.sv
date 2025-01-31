module sdm_adc_art (
    input  logic              clk,
    input  logic              rst_n,
    input  logic              valid_in,   //valid input signal
    input  logic      			din, //SDM 
    output logic              valid_out,  //valid output signal
    output logic signed   [15 : 0]   dout //Audio fix point
);

	logic signed [15:0] sdm_bound;
	logic signed [15:0] avg;
	logic						valid;

	
	 always_comb begin
        sdm_bound = (din) ? 16'sd32767 : -16'sd32767; //bind SDM to fixpoint
    end
	 
    comb_decimator inst1 (
        .clk(clk),
        .reset(!rst_n),
        .valid_in(valid_in),
        .data_in(sdm_bound),
		  .valid_out(valid),
        .data_out(avg)
    );
	  
	 fir_decimator inst2 (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid),
        .data_in(avg),
		  .valid_out(valid_out),
        .data_out(dout)
    );

endmodule