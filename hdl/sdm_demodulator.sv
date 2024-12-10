module sdm_demodulator (
    input  logic              clk,
    input  logic              rst_n,
    input  logic              valid_in,   // New valid input signal
    input  logic      			din, //SDM 
    output logic              valid_out,  // New valid output signal
    output logic signed   [15 : 0]   dout //Audio fix point
);

	logic signed [15:0] sdm_bound;
	logic signed [15:0] avg1;
	logic signed [15:0] avg2;
	logic signed [15:0] avg3;
	logic signed [15:0] avg4;
	logic signed [15:0] avg5;
	logic						valid1;
	logic						valid2;
	logic						valid3;
	logic						valid4;
	logic						valid5;
	
	 always_comb begin
        sdm_bound = (din) ? 16'sd32767 : -16'sd32767; //bind SDM to fixpoint
    end
	 
    filter inst1 (
        .clk(clk),
        .rst_n(rst_n),
        .ce(valid_in),
        .data_in(sdm_bound),
        .avg(avg1),
        .rdy(valid1)
    );
	 
	     filter inst2 (
        .clk(clk),
        .rst_n(rst_n),
        .ce(valid1),
        .data_in(avg1),
        .avg(avg2),
        .rdy(valid2)
    );
	 
	     filter inst3 (
        .clk(clk),
        .rst_n(rst_n),
        .ce(valid2),
        .data_in(avg2),
        .avg(avg3),
        .rdy(valid3)
    );
	 
	     filter inst4 (
        .clk(clk),
        .rst_n(rst_n),
        .ce(valid3),
        .data_in(avg3),
        .avg(avg4),
        .rdy(valid4)
    );
	 
	     filter inst5 (
        .clk(clk),
        .rst_n(rst_n),
        .ce(valid4),
        .data_in(avg4),
        .avg(avg5),
        .rdy(valid5)
    );
	 
	     filter inst6 (
        .clk(clk),
        .rst_n(rst_n),
        .ce(valid5),
        .data_in(avg5),
        .avg(dout),
        .rdy(valid_out)
    );

endmodule