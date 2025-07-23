`timescale 1ns/1ps

module tb_contador_flancos;

    reg        clk    = 0;
    reg        rst    = 1;
    reg        sensor = 1;
    wire [31:0] contador;
    wire [2:0]  codigo;

    // Instanciar el módulo bajo prueba
    Contador_flancos uut (
        .clk(clk),
        .rst(rst),
        .sensor(sensor),
        .contador(contador),
        .codigo(codigo)
    );

    // Reloj de 25 MHz → periodo = 40 ns
    always #20 clk = ~clk;

    initial begin
        $dumpfile("test.vcd");
        $dumpvars(1, tb_contador_flancos.clk,
                     tb_contador_flancos.sensor,
                     tb_contador_flancos.contador,
                     tb_contador_flancos.codigo);

        // Reset breve
        #100 rst = 0;

        // --- Primer segundo: 10 flancos
        repeat (10) begin
            #1_000_000 sensor = 0;  // flanco de bajada
            #100       sensor = 1;
        end

        // Esperar 1 segundo completo
        #1_000_000_000;
        $display("1er segundo terminado - contador=%0d, codigo=%0d",
                 contador, codigo);

        // --- Segundo segundo: 20 flancos
        repeat (10) begin
            #500_000 sensor = 0;
            #100     sensor = 1;
        end

        #1_000_000_000;
        $display("2do segundo terminado - contador=%0d, codigo=%0d",
                 contador, codigo);

        // --- Tercer segundo: 35 flancos
        repeat (35) begin
            #285_000 sensor = 0;
            #100     sensor = 1;
        end

        #1_000_000_000;
        $display("3er segundo terminado - contador=%0d, codigo=%0d",
                 contador, codigo);

        $finish;
    end

endmodule


