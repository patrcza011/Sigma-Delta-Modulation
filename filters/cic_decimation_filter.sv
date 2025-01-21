// CIC Decimation Filter Module
module cic_decimation_filter #(
    parameter N = 16, // Decimation factor
    parameter STAGES = 4 // Number of CIC stages
) (
    input  logic              clk,
    input  logic              rst_n,
    input  logic              valid_in,
    input  logic signed [15:0] din,
    output logic              valid_out,
    output logic signed [15:0] dout
);

    logic signed [15:0] integrators [0:STAGES-1];
    logic signed [15:0] combs [0:STAGES-1];
    logic [3:0]         counter;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
            foreach (integrators[i]) integrators[i] <= 16'sd0;
            foreach (combs[i]) combs[i] <= 16'sd0;
        end else if (valid_in) begin
            // Integrator stages
            integrators[0] <= integrators[0] + din;
            for (int i = 1; i < STAGES; i++)
                integrators[i] <= integrators[i] + integrators[i-1];

            // Down-sampling by N
            if (counter == (N-1)) begin
                counter <= 0;
                combs[0] <= integrators[STAGES-1];

                // Comb stages
                for (int i = 1; i < STAGES; i++)
                    combs[i] <= combs[i-1] - combs[i];

                dout <= combs[STAGES-1];
                valid_out <= 1'b1;
            end else begin
                counter <= counter + 1;
                valid_out <= 1'b0;
            end
        end
    end

endmodule