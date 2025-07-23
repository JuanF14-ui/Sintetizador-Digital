module music_keyboard(
    input clk,          // Reloj del sistema
    input reset,        // Reset
    input key1,         // Tecla 1 (bit 0)
    input key2,         // Tecla 2 (bit 1)
    input key3,         // Tecla 3 (bit 2)
    output reg audio_out // Salida de audio
);

// Registro para el estado de las teclas
reg [2:0] key_state;

// Frecuencias de notas musicales (en divisores de reloj)
parameter DO = 191112;   // 261.63 Hz
parameter RE = 170267;   // 293.66 Hz
parameter MI = 151682;   // 329.63 Hz
parameter FA = 143172;   // 349.23 Hz
parameter SOL = 127552;  // 392.00 Hz
parameter LA = 113636;   // 440.00 Hz
parameter SI = 101238;   // 493.88 Hz
parameter DO2 = 95451;   // 523.25 Hz

// Contador para generación de tono
reg [31:0] tone_counter;
reg [31:0] tone_limit;

// Lógica combinacional para seleccionar la nota
always @(*) begin
    case(key_state)
        3'b000: tone_limit = DO;    // 000 - Do
        3'b001: tone_limit = RE;    // 001 - Re
        3'b010: tone_limit = MI;    // 010 - Mi
        3'b011: tone_limit = FA;    // 011 - Fa
        3'b100: tone_limit = SOL;   // 100 - Sol
        3'b101: tone_limit = LA;    // 101 - La
        3'b110: tone_limit = SI;    // 110 - Si
        3'b111: tone_limit = DO2;   // 111 - Do alto
        default: tone_limit = 0;   // Silencio
    endcase
end

// Actualización del estado de las teclas
always @(posedge clk or posedge reset) begin
    if (reset) begin
        key_state <= 3'b000;
    end else begin
        key_state <= {key3, key2, key1};
    end
end

// Generación del tono
always @(posedge clk or posedge reset) begin
    if (reset) begin
        tone_counter <= 0;
        audio_out <= 0;
    end else begin
        if (tone_counter >= tone_limit) begin
            tone_counter <= 0;
            audio_out <= ~audio_out;
        end else begin
            tone_counter <= tone_counter + 1;
        end
    end
end

endmodule
