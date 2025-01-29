module FIR_comb (
    input signed [15:0] input_data,  // Wejsciowa pr�bka filtra
    input CLK,                      // Zegar do propagacji danych
    input RST,                      // Resetuje stan filtra
    input ENABLE,                   // Wlacza filtr
    output reg signed [15:0] output_data, // Wyjsciowa pr�bka filtra
    output reg signed [15:0] sampleT      // Debug - pr�bkowanie danych wejsciowych
);

    // Wsp�lczynniki filtra (15-tap FIR)
    reg signed [15:0] COEFF [0:14] = {
        16'hFC9C, 16'h0000, 16'h05A5, 16'h0000, 16'hF40C,
        16'h0000, 16'h282D, 16'h4000, 16'h282D, 16'h0000,
        16'hF40C, 16'h0000, 16'h05A5, 16'h0000, 16'hFC9C
    };

    // Rejestry do przechowywania pr�bek i wynik�w
    reg signed [15:0] buffer [0:14];   // Bufor pr�bek
    reg signed [31:0] products [0:14]; // Wyniki mnozenia
    reg signed [31:0] accum_stage [0:6]; // Etapy akumulacji

    integer i;

    always @(posedge CLK or posedge RST) begin
        if (RST) begin
            // Resetowanie bufor�w i wyjscia
            for (i = 0; i < 15; i = i + 1) begin
                buffer[i] <= 16'd0;
                products[i] <= 32'd0;
            end
            for (i = 0; i < 7; i = i + 1) begin
                accum_stage[i] <= 32'd0;
            end
            output_data <= 16'd0;
            sampleT <= 16'd0;
        end else if (ENABLE) begin
            // Debug: Przekazywanie danych wejsciowych
            sampleT <= input_data;

            // Przesuniecie bufora i wczytanie nowej pr�bki
            buffer[0] <= input_data;
            for (i = 1; i < 15; i = i + 1) begin
                buffer[i] <= buffer[i-1];
            end

            // Etap mnozenia (r�wnolegly)
            for (i = 0; i < 15; i = i + 1) begin
                products[i] <= buffer[i] * COEFF[i];
            end

            // Etap akumulacji (potokowy)
            accum_stage[0] <= products[0] + products[1];
            accum_stage[1] <= products[2] + products[3];
            accum_stage[2] <= products[4] + products[5];
            accum_stage[3] <= products[6] + products[7];
            accum_stage[4] <= products[8] + products[9];
            accum_stage[5] <= products[10] + products[11];
            accum_stage[6] <= products[12] + products[13];

            // Ostateczna akumulacja
            output_data <= (accum_stage[0] + accum_stage[1] + accum_stage[2] +
                           accum_stage[3] + accum_stage[4] + accum_stage[5] +
                           accum_stage[6] + products[14]) >>> 15; // Normalizacja do Q1.15
        end
    end
endmodule
