module sdm_modulator #(
    parameter int dac_bw = 16
)(
    input  logic              clk,
    input  logic              rst_n,
    input  logic [15 : 0]     din,
    output logic              dout
);

    initial begin
        $dumpfile("sdm_modulator.vcd");
        $dumpvars(1,sdm_modulator); // Here 1 means dump signals on the design level, 0 means dump all signals below (kinda recursive)
    end
    localparam int bw_ext = 2;
    localparam int bw_tot = dac_bw + bw_ext;

    logic                    dout_r;
    logic                    dac_dout;
    logic signed [bw_tot-1:0] DAC_acc_1st;
    logic signed [bw_tot-1:0] dac_val;
    logic signed [bw_tot-1:0] in_ext;
    logic signed [bw_tot-1:0] delta_s0_c0;
    logic signed [bw_tot-1:0] delta_s0_c1;

    logic signed [bw_tot-1:0] max_val = (2 ** (dac_bw - 1)) - 1;
    logic signed [bw_tot-1:0] min_val = -(2 ** (dac_bw - 1));

    // Dynamically compute dac_val
    always_comb begin
        dac_val = (!dout_r) ? max_val : min_val;
    end

    // Dynamically compute in_ext
    always_comb begin
        in_ext = {{bw_ext{din[dac_bw - 1]}}, din};
    end

    // Compute intermediate signals
    always_comb begin
        delta_s0_c0 = in_ext + dac_val;
        delta_s0_c1 = DAC_acc_1st + delta_s0_c0;
    end

    // Update DAC accumulator
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            DAC_acc_1st <= '0;
        end else begin
            DAC_acc_1st <= delta_s0_c1;
        end
    end

    // Update output logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout_r   <= 1'b0;
            dac_dout <= 1'b0;
        end else begin
            dout_r   <= delta_s0_c1[bw_tot-1];
            dac_dout <= ~dout_r;
        end
    end

    // Assign output
    assign dout = dout_r;

endmodule
