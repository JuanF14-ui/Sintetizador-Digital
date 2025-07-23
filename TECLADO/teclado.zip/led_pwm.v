// ---------------------------------------------
// Generador de onda cuadrada 50% duty
// freq = ciclos de reloj para la MITAD del período
// Mejores prácticas añadidas:
//  - Latch de freq al inicio del ciclo para evitar glitches
//  - Protección de overflow en 2*freq usando 33 bits
// ---------------------------------------------
module led_pwm (
    input  wire        clk,
    input  wire [31:0] freq,   // mitad del período, en ciclos de clk
    output reg         pwm
);
    reg [31:0] counter      = 32'd0;
    reg [31:0] freq_latched = 32'd0;

    wire [32:0] twice = {1'b0, freq_latched} << 1; // 2*freq seguro

    always @(posedge clk) begin
        if (freq == 0) begin
            pwm          <= 1'b0;
            counter      <= 32'd0;
            freq_latched <= 32'd0;
        end else begin
            // Latch de frecuencia sólo al inicio del ciclo
            if (counter == 0)
                freq_latched <= freq;

            // Contador
            if (counter >= (twice - 1))
                counter <= 32'd0;
            else
                counter <= counter + 1;

            // 50% duty
            pwm <= (counter < freq_latched) ? 1'b1 : 1'b0;
        end
    end
endmodule

