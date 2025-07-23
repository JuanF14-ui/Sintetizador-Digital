module contador_simple (
    input clk,
    input reset,
    input [3:0] key_state,        // Entradas de botones (estado actual)
    output reg [3:0] count0,      // Contador para tecla 0 (DO)
    output reg [3:0] count1,      // Contador para tecla 1 (RE)
    output reg [3:0] count2,      // Contador para tecla 2 (MI)
    output reg [3:0] count3       // Contador para tecla 3 (FA)
);

    // Estado anterior de cada tecla para detectar flancos
    reg [3:0] key_prev;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            key_prev <= 4'b0000;
            count0 <= 4'b0000;
            count1 <= 4'b0000;
            count2 <= 4'b0000;
            count3 <= 4'b0000;
        end else begin
            // Detectar flancos de subida y contar
            if (~key_prev[0] & key_state[0]) count0 <= count0 + 1;
            if (~key_prev[1] & key_state[1]) count1 <= count1 + 1;
            if (~key_prev[2] & key_state[2]) count2 <= count2 + 1;
            if (~key_prev[3] & key_state[3]) count3 <= count3 + 1;

            // Actualizar estado previo
            key_prev <= key_state;
        end
    end

endmodule

