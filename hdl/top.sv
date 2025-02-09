`ifndef ORDER
`define ORDER 1
`endif

`ifndef ADC_TYPE
`define ADC_TYPE 1
`endif

module top #(
    parameter int DAC_ORDER = `ORDER,  // 1 for first-order, 2 for second-order
    parameter int ADC_TYPE  = `ADC_TYPE   // 0 for adc_avg, 1 for adc_art
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

  // w zasadzie to nie jest poprawne nazewnictwo - nie ma tu żadnego DAC ani ADC bo nie ma sygnału analogowego. jest sygnał PCM i SDM

  // Internally route DAC outputs so that only the selected DAC drives them.
  // This avoids having both modules drive the same signals at once.
  logic valid_out_dac_int;
  logic sdm_out_int;
  logic valid_out_adc_int;
  logic signed [15 : 0] audio_out_int;

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
  assign valid_out_adc = valid_out_adc_int;
  assign audio_out     = audio_out_int;

  // Generate block to choose which ADC is instantiated
    // to jest niejasne dlaczego są dwa różne zestawy filtrów i co one właściwie robią - jest to też nieopisane w dokumentacji. A oczekiwałbym np. charakterystyk filtrów i schematu (gdzie decymacja etc.)
  generate
    if (ADC_TYPE == 0) begin : GEN_ADC_AVG
      sdm_adc_avg adc_avg (
          .clk       (clk),
          .rst_n     (rst_n),
          .valid_in  (valid_in_adc),
          .din       (sdm_in),
          .valid_out (valid_out_adc_int),
          .dout      (audio_out_int)
      );
    end
    else if (ADC_TYPE == 1) begin : GEN_ADC_ART
      sdm_adc_art adc_art (
          .clk       (clk),
          .rst_n     (rst_n),
          .valid_in  (valid_in_adc),
          .din       (sdm_in),
          .valid_out (valid_out_adc_int),
          .dout      (audio_out_int)
      );
    end
  endgenerate

endmodule
