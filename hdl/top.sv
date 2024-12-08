module top (
    input  logic              		clk,
    input  logic              		rst_n,
    input  logic              		valid_in_dac1,  //Audio to SDM
	input  logic              		valid_in_dac2,  //Audio to SDM
    input  logic signed [15 : 0]    audio_in1,      //Audio to SDM
	input  logic signed [15 : 0]    audio_in2,      //Audio to SDM
	input  logic              		valid_in_adc1,  //SDM to Audio
	input  logic              		valid_in_adc2,  //SDM to Audio
    input  logic 						   sdm_in1,	//SDM to Audio
	input  logic 						   sdm_in2,	//SDM to Audio
    output logic              		valid_out_dac1,
	output logic              		valid_out_dac2,
    output logic              		sdm_out1,
	output logic              		sdm_out2,
	output logic              		valid_out_adc1,
	output logic              		valid_out_adc2,
    output logic signed [15 : 0]    audio_out1,
	output logic signed [15 : 0]    audio_out2
);

    sdm_modulator dac1 (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in_dac1),
        .din(audio_in1),
        .valid_out(valid_out_dac1),
        .dout(sdm_out1)
    );

	sdm_modulator dac2 (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in_dac2),
        .din(audio_in2),
        .valid_out(valid_out_dac2),
        .dout(sdm_out2)
    );

	sdm_demodulator adc1 (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in_adc1),
        .din(sdm_in1),
        .valid_out(valid_out_adc1),
        .dout(audio_out1)
    );

	sdm_demodulator adc2 (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in_adc2),
        .din(sdm_in2),
        .valid_out(valid_out_adc2),
        .dout(audio_out2)
    );

initial begin
    $dumpfile("top.vcd");
    $dumpvars(1, top);
end

endmodule