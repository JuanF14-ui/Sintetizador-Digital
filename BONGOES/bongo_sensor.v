module bongo_sensor (
    input clk,                 // Reloj del sistema
    input rst,                 // Reset
    input left_sensor,         // Sensor del tambor izquierdo
    input right_sensor,        // Sensor del tambor derecho
    output reg [1:0] bongo_hit // Salida codificada: 01 = izquierdo, 10 = derecho
);

always @(posedge clk or posedge rst) begin
    if (rst) begin
        bongo_hit <= 2'b00;    // Si se resetea, no hay golpe detectado
    end else begin
        if (left_sensor)
            bongo_hit <= 2'b01; // Golpe izquierdo
        else if (right_sensor)
            bongo_hit <= 2'b10; // Golpe derecho
        else
            bongo_hit <= 2'b00; // Ningún golpe
    end
end

endmodule
