`ifndef ORDER `define ORDER 5
`endif

module top #(
    parameter int DAC_ORDER = `ORDER  // 1 for first-order, 2 for second-order
) (
    input  logic              		clk,
    input  logic                  dummy_clk,
    input  logic              		rst_n,
    input  logic              		valid_in_dac,   // Audio to SDM
    input  logic signed [15 : 0]    audio_in,       // Audio to SDM
    input  logic              		valid_in_adc,   // SDM to Audio
    input  logic              		sdm_in,         // SDM to Audio
    output logic              		valid_out_dac,
    output logic              		sdm_out,
    output logic              		valid_out_adc,
    output logic signed [15 : 0]    audio_out
);
int fd;
  initial begin
    fd = $fopen ("./note.txt", "w");
      $fdisplay(fd,"DAC_ORDER: %d | `ORDER: %d", DAC_ORDER, `ORDER);
    $fclose(fd);
  end
  // Internally route DAC outputs so that only the selected DAC drives them.
  // This avoids having both modules drive the same signals at once.
  logic valid_out_dac_int;
  logic sdm_out_int;

  // Generate block to choose which DAC is instantiated
  generate
    if (DAC_ORDER == 1) begin : GEN_DAC_1ST
      sdm_dac_1st dac_1st_order (
          .clk       (clk),
          .rst_n     (rst_n),
          .valid_in  (valid_in_dac),
          .din       (audio_in),
          .valid_out (valid_out_dac_int),
          .dout      (sdm_out_int)
      );
    end
    else if (DAC_ORDER == 2) begin : GEN_DAC_2ND
      sdm_dac_2nd dac_2nd_order (
          .clk       (clk),
          .rst_n     (rst_n),
          .valid_in  (valid_in_dac),
          .din       (audio_in),
          .valid_out (valid_out_dac_int),
          .dout      (sdm_out_int)
      );
    end
  endgenerate

  // Connect the internal signals to the module outputs
  assign valid_out_dac = valid_out_dac_int;
  assign sdm_out       = sdm_out_int;

  // ADC is always instantiated (independent of DAC_ORDER)
  sdm_adc adc (
      .clk       (clk),
      .rst_n     (rst_n),
      .valid_in  (valid_in_adc),
      .din       (sdm_in),
      .valid_out (valid_out_adc),
      .dout      (audio_out)
  );

endmodule