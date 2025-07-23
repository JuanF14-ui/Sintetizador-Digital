module top (
    input wire clk,          // Reloj de 25MHz
    input wire rst,         // Señal de reset
    input wire sensor,      // Entrada del sensor
    output wire uart_tx,    // Salida UART
    output reg [2:0] leds   // LEDs para visualización
);

    // Señales internas
    wire [31:0] contador;
    wire [2:0] codigo;
    
    // Instancia del contador de flancos
    Contador_flancos contador_inst (
        .clk(clk),
        .rst(rst),
        .sensor(sensor),
        .contador(contador),
        .codigo(codigo)
    );
    
    // Módulo de notas (simplificado para usar el código del contador)
    notas_fpga notas_inst (
        .clk(clk),
        .pulsadores(codigo), // Usamos el código del contador como entrada
        .uart_tx(uart_tx)
    );
    
    // Visualización en LEDs
    always @(posedge clk) begin
        leds <= codigo;
    end

endmodule

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

            if (temporizador >= 25_000_000 - 1) begin // 1 segundo @25MHz
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

module notas_fpga (
    input wire clk,
    input wire [2:0] pulsadores,
    output wire uart_tx
);

    // Anti-rebote básico
    reg [2:0] pulsadores_sync;
    always @(posedge clk) begin
        pulsadores_sync <= pulsadores;
    end

    // Conversión a nota musical (escala simplificada)
    reg [2:0] nota_actual;
    always @(*) begin
        case (pulsadores_sync)
            3'd2: nota_actual = 3'd0;  // Do
            3'd3: nota_actual = 3'd2;  // Mi
            3'd4: nota_actual = 3'd4;  // Sol
            default: nota_actual = 3'd0; // Do por defecto
        endcase
    end

    // Módulo UART (115200 bauds @25MHz)
    uart_tx #(
        .CLK_FREQ(25_000_000),
        .BAUD_RATE(115200)
    ) uart (
        .clk(clk),
        .tx_data({5'b0, nota_actual}),
        .tx_start(1'b1),
        .tx(uart_tx)
    );

endmodule

module uart_tx (
    input wire clk,
    input wire [7:0] tx_data,
    input wire tx_start,
    output reg tx
);
    parameter CLK_FREQ = 25_000_000;
    parameter BAUD_RATE = 115200;
    localparam BIT_TIME = CLK_FREQ / BAUD_RATE;

    reg [3:0] state = 0;
    reg [15:0] counter = 0;
    reg [7:0] shift_reg;
    
    always @(posedge clk) begin
        case(state)
            0: if (tx_start) begin  // Estado idle
                shift_reg <= tx_data;
                state <= 1;
                counter <= 0;
                tx <= 0;  // Start bit
            end
            1: if (counter == BIT_TIME-1) begin  // Fin de start bit
                counter <= 0;
                state <= 2;
                tx <= shift_reg[0];
            end else counter <= counter + 1;
            2,3,4,5,6,7,8: if (counter == BIT_TIME-1) begin  // Bits de datos
                counter <= 0;
                state <= state + 1;
                tx <= shift_reg[state-1];
            end else counter <= counter + 1;
            9: if (counter == BIT_TIME-1) begin  // Stop bit
                counter <= 0;
                state <= 0;
                tx <= 1;
            end else counter <= counter + 1;
        endcase
    end
endmodule
