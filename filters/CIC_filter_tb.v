`timescale 1ns / 1ps

module CIC_filter_tb;

    // Parametry
    parameter CLK_PERIOD = 10;        // Okres zegara w ns (100 MHz)
    parameter SAMPLES_PER_PERIOD = 100; // Liczba pr�bek na okres sinusoidy
    parameter TOTAL_PERIODS = 10;     // Liczba okres�w sinusoidy
    parameter signed [15:0] AMPLITUDE = 16'h4000; // Amplituda sinusoidy (Q1.15)

    // Sygnatury sygnal�w
    reg CLK;
    reg RST;
    reg signed [15:0] input_data;
    wire signed [15:0] output_data;

    // Instancja modulu CIC
    CIC_filter uut (
        .clk(CLK),                // Zegar
        .reset(RST),              // Reset
        .in_data(input_data),     // Wejscie 16-bitowe (Q1.15)
        .out_data(output_data)    // Wyjscie 16-bitowe (Q1.15)
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
        input_data = 16'd0;
        #(2 * CLK_PERIOD);

        // Resetowanie filtra
        RST = 0;

        // Generowanie i podawanie sygnalu sinusoidalnego
        for (i = 0; i < SAMPLES_PER_PERIOD * TOTAL_PERIODS; i = i + 1) begin
            // Obliczenie wartosci sinusoidy (w Q1.15)
            sin_val = $sin(2.0 * 3.14159265359 * (i % SAMPLES_PER_PERIOD) / SAMPLES_PER_PERIOD);
            input_data = $rtoi(sin_val * AMPLITUDE);

            // Odczekanie jednego okresu zegara
            #(CLK_PERIOD);
        end

        // Zakonczenie symulacji
        #(10 * CLK_PERIOD);
        $stop;
    end

endmodule
