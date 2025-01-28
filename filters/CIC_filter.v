module CIC_filter #(
    parameter N = 64 // Wspólczynnik decymacji
) (
    input wire clk,                // Zegar
    input wire reset,              // Reset
    input wire signed [15:0] in_data, // Wejscie 16-bitowe (Q1.15)
    output reg signed [15:0] out_data // Wyjscie 16-bitowe (Q1.15)
);

    // Rejestry dla integratora
    reg signed [31:0] integrator; // Wiekszy zakres na akumulacje (Q1.31)

    // Rejestry dla decymatora
    reg [5:0] sample_count;       // Licznik próbek do decymacji
    reg signed [31:0] decimated_data; // Próbka po decymacji (Q1.31)

    // Rejestry dla rózniczkujacego
    reg signed [31:0] differentiator;
    reg signed [31:0] prev_decimated_data;

    // Etap 1: Integrator (Fs -> Fs)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            integrator <= 32'd0;
        end else begin
            integrator <= integrator + in_data; // Suma próbek
        end
    end

    // Etap 2: Dziesiatkowanie (Fs -> Fs/N)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            sample_count <= 0;
            decimated_data <= 32'd0;
        end else begin
            if (sample_count == N-2) begin
                decimated_data <= integrator; // Przechwycenie próbki co N cykli
                sample_count <= 0;
            end else begin
                sample_count <= sample_count + 1;
            end
        end
    end

    // Etap 3: Rózniczkowanie (Fs/N -> Fs/N)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            differentiator <= 32'd0;
            prev_decimated_data <= 32'd0;
        end else begin
            differentiator <= decimated_data - prev_decimated_data; // Obliczenie róznicy
            prev_decimated_data <= decimated_data; // Aktualizacja poprzedniej próbki
        end
    end

    // Wyjscie: Przyciecie do 16-bitowego formatu Q1.15
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            out_data <= 16'd0;
        end else begin
            out_data <= differentiator[30:15]; // Konwersja z Q1.31 na Q1.15
        end
    end

    // Debugowanie: Wyswietlanie wartosci wewnetrznych
    always @(posedge clk) begin
        $display("Integrator: %d, Decimated Data: %d, Differentiator: %d", integrator, decimated_data, differentiator);
    end

endmodule
