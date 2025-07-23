`timescale 1ns / 1ps

module contador_tb;

    reg clk;
    reg reset;
    reg [3:0] key_state;
    wire [3:0] count0, count1, count2, count3;

    // Instancia del módulo a probar
    contador_simple uut (
        .clk(clk),
        .reset(reset),
        .key_state(key_state),
        .count0(count0),
        .count1(count1),
        .count2(count2),
        .count3(count3)
    );

    // Generación de reloj (100 MHz -> periodo = 10ns)
    initial clk = 0;
    always #5 clk = ~clk;

    // Simulación
    initial begin
        $display("Inicio de la simulación");
        $dumpfile("contador_tb.vcd");
        $dumpvars(0, contador_tb);

        // Inicialización
        key_state = 4'b0000;
        reset = 1;

        #20 reset = 0;

        // Pulsación de tecla 0 (DO)
        #10 key_state[0] = 1;  // flanco de subida
        #10 key_state[0] = 0;  // flanco de bajada

        // Pulsación de tecla 1 (RE)
        #10 key_state[1] = 1;
        #10 key_state[1] = 0;

        // Repetir tecla 0 (DO)
        #10 key_state[0] = 1;
        #10 key_state[0] = 0;

        // Pulsación simultánea de tecla 2 y 3 (MI y FA)
        #10 key_state = 4'b1100;
        #10 key_state = 4'b0000;

        // Esperar para observar
        #20;

        // Verificación básica
        $display("count0 = %d (esperado: 2)", count0);
        $display("count1 = %d (esperado: 1)", count1);
        $display("count2 = %d (esperado: 1)", count2);
        $display("count3 = %d (esperado: 1)", count3);

        $finish;
    end

endmodule

