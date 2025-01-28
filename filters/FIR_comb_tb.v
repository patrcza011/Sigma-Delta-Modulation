`timescale 1ns / 1ps

module FIR_comb_tb;

    // Parametry
    parameter CLK_PERIOD = 10;        // Okres zegara w ns (100 MHz)
    parameter SAMPLES_PER_PERIOD = 100; // Liczba próbek na okres sinusoidy
    parameter TOTAL_PERIODS = 10;     // Liczba okresów sinusoidy
    parameter signed [15:0] AMPLITUDE = 16'h4000; // Amplituda sinusoidy (Q1.15)

    // Sygnatury sygnalów
    reg CLK;
    reg RST;
    reg ENABLE;
    reg signed [15:0] input_data;
    wire signed [15:0] output_data;
    wire signed [15:0] sampleT;

    // Instancja modulu FIR_comb
    FIR_comb uut (
        .input_data(input_data),
        .CLK(CLK),
        .RST(RST),
        .ENABLE(ENABLE),
        .output_data(output_data),
        .sampleT(sampleT)
    );

    // Zmienna dla generowania sinusoidy
    integer i;
    real sin_val;

    // Generowanie sygnalu zegarowego
    initial begin
        CLK = 0;
        forever #(CLK_PERIOD / 2) CLK = ~CLK;
    end

    // Testbench
    initial begin
        // Inicjalizacja
        RST = 1;
        ENABLE = 0;
        input_data = 16'd0;
        #(2 * CLK_PERIOD);

        // Resetowanie filtra
        RST = 0;
        ENABLE = 1;

        // Generowanie i podawanie sygnalu sinusoidalnego
        for (i = 0; i < SAMPLES_PER_PERIOD * TOTAL_PERIODS; i = i + 1) begin
            // Obliczenie wartosci sinusoidy (w Q1.15)
            sin_val = $sin(2.0 * 3.14159265359 * (i % SAMPLES_PER_PERIOD) / SAMPLES_PER_PERIOD);
            input_data = $rtoi(sin_val * AMPLITUDE);

            // Odczekanie jednego okresu zegara
            #(CLK_PERIOD);
        end

        // Zakonczenie symulacji
        ENABLE = 0;
        #(10 * CLK_PERIOD);
        $stop;
    end

endmodule
