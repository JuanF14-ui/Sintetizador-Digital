`timescale 1ns/1ps

module led_pwm_tb;

    // Parámetros del clock
    localparam CLK_HZ  = 25_000_000;
    localparam CLK_PER = 40; // ns (25 MHz)

    // Señales DUT
    reg        clk  = 0;
    reg [31:0] freq = 0;
    wire       pwm;

    // Instancia del DUT
    led_pwm dut (
        .clk (clk),
        .freq(freq),
        .pwm (pwm)
    );

    // Generador de clock
    always #(CLK_PER/2) clk = ~clk;

    // Variables para medición
    integer h, l;

    // ---- Tarea: mide un ciclo completo (alto + bajo)
    task measure_cycle;
        output integer high_cnt;
        output integer low_cnt;
        begin
            // Espera flanco de subida para iniciar medición
            @(posedge pwm);
            high_cnt = 0;
            low_cnt  = 0;

            // Cuenta mientras pwm=1
            while (pwm) begin
                @(posedge clk);
                high_cnt = high_cnt + 1;
            end

            // Cuenta mientras pwm=0
            while (!pwm) begin
                @(posedge clk);
                low_cnt = low_cnt + 1;
            end
        end
    endtask

    // ---- Tarea: prueba un valor de freq y hace checks
    task test_freq;
        input [31:0] f;
        integer expected;
        begin
            freq = f;

            // Espera a que el DUT estabilice
            repeat (10) @(posedge clk);

            if (f == 0) begin
                // Silencio esperado
                repeat (200) @(posedge clk);
                if (pwm !== 1'b0) begin
                    $display("ERROR: freq=0 -> pwm no es 0");
                    $finish;
                end
                else $display("OK  : freq=0 -> silencio correcto");
            end else begin
                // Mide un ciclo
                measure_cycle(h, l);
                expected = f;

                if ( (h != expected) || (l != expected) ) begin
                    $display("ERROR: f=%0d -> high=%0d low=%0d (esp=%0d/%0d)",
                              f, h, l, expected, expected);
                    $finish;
                end else begin
                    $display("OK  : f=%0d -> high=%0d low=%0d", f, h, l);
                end
            end
        end
    endtask

    initial begin
        $dumpfile("led_pwm_tb.vcd");
        $dumpvars(0, led_pwm_tb);

        // Pruebas
        test_freq(32'd0);       // silencio
        test_freq(32'd23860);   // DO5  ~523 Hz aprox.
        test_freq(32'd21302);   // RE5
        test_freq(32'd18977);   // MI5
        test_freq(32'd17906);   // FA5

        // Cambio dinámico de frecuencia (DO→RE)
        freq = 32'd23860;
        repeat (1000) @(posedge clk);
        freq = 32'd21302;
        repeat (10) @(posedge clk); // descarta transitorio
        measure_cycle(h, l);
        if (h != 21302 || l != 21302) begin
            $display("ERROR: cambio dinámico -> h=%0d l=%0d esp=21302", h, l);
            $finish;
        end else begin
            $display("OK  : cambio dinámico correcto");
        end

        $display("==== TODAS LAS PRUEBAS PASARON ====");
        $finish;
    end
endmodule

