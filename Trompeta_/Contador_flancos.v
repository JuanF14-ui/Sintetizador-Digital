module Contador_flancos (
    input wire clk,
    input wire rst,
    input wire sensor,
    output reg [31:0] contador,
    output reg [2:0] codigo
);

    reg [31:0] temporizador;
    reg sensor_prev;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sensor_prev   <= 1;
            temporizador  <= 0;
            contador      <= 0;
            codigo        <= 0;
        end else begin
            sensor_prev <= sensor;

            if (temporizador >= 25_000_000 - 1) begin
                temporizador <= 0;

                // Asignación del código según el rango
                if (contador <= 15)
                    codigo <= 2;
                else if (contador <= 30)
                    codigo <= 3;
                else
                    codigo <= 4;

                contador <= 0; // Reinicio del contador cada segundo
            end else begin
                temporizador <= temporizador + 1;

                if (sensor_prev == 1 && sensor == 0)
                    contador <= contador + 1;
            end
        end
    end

endmodule

