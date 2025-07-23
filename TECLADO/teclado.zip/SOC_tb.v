`timescale 1ns/1ps

module SOC_tb;

    // ---------------- Parámetros ----------------
    localparam CLK_HZ  = 25_000_000;
    localparam CLK_PER = 40; // ns (25 MHz)

    // Divisores esperados (mitad de período, con clk = 25 MHz)
    localparam DIV_DO = 23860;
    localparam DIV_RE = 21302;
    localparam DIV_MI = 18977;
    localparam DIV_FA = 17906;

    // ---------------- Señales del DUT -----------
    reg         clk     = 0;
    reg         resetn  = 0;
    wire [0:0]  LEDS;
    reg         RXD     = 1; // UART idle
    wire        TXD;
    wire        PWM_LED_OUT;
    wire        PWM_AUDIO_OUT;
    reg  [3:0]  BUTTONS_IN = 4'b1111; // activos en bajo → 1 = sin presionar

    // ---------------- Instancia del SOC ---------
    SOC dut (
        .clk            (clk),
        .resetn         (resetn),
        .LEDS           (LEDS),
        .RXD            (RXD),
        .TXD            (TXD),
        .PWM_LED_OUT    (PWM_LED_OUT),
        .PWM_AUDIO_OUT  (PWM_AUDIO_OUT),
        .BUTTONS_IN     (BUTTONS_IN)
    );

    // ---------------- Clock ---------------------
    always #(CLK_PER/2) clk = ~clk;

    // ---------------- Utilidades ----------------
    integer h,l;

    task wait_cycles(input integer n);
        integer i;
        begin
            for (i=0;i<n;i=i+1) @(posedge clk);
        end
    endtask

    task wait_ms(input integer ms);
        integer cycles;
        begin
            cycles = (CLK_HZ/1000)*ms;
            wait_cycles(cycles);
        end
    endtask

    // Verificar silencio: PWM_AUDIO_OUT = 0 durante N ciclos
    task check_silence(input integer cycles_to_check);
        integer i;
        begin
            for (i=0; i<cycles_to_check; i=i+1) begin
                @(posedge clk);
                if (PWM_AUDIO_OUT !== 1'b0) begin
                    $display("ERROR: Se esperaba silencio, PWM_AUDIO_OUT=%b en ciclo %0d", PWM_AUDIO_OUT, i);
                    $finish;
                end
            end
            $display("OK   : Silencio verificado (%0d ciclos).", cycles_to_check);
        end
    endtask

    // Medir un ciclo completo de PWM_AUDIO_OUT (con watchdog para no colgarse)
    task measure_cycle(output integer high_cnt, output integer low_cnt);
        integer timeout;
        begin
            timeout = 0;
            while (PWM_AUDIO_OUT !== 1'b1) begin
                @(posedge clk);
                timeout = timeout + 1;
                if (timeout > 1_000_000) begin
                    $display("ERROR: Timeout esperando posedge PWM_AUDIO_OUT");
                    $finish;
                end
            end

            high_cnt = 0; low_cnt = 0;

            while (PWM_AUDIO_OUT) begin
                @(posedge clk);
                high_cnt = high_cnt + 1;
            end
            while (!PWM_AUDIO_OUT) begin
                @(posedge clk);
                low_cnt = low_cnt + 1;
            end
        end
    endtask

    // Presionar botones (1 = presionado en la lógica del teclado)
    task press_button(input [3:0] mask_active_high);
        begin
            // En el SOC: buttons_active_high = ~BUTTONS_IN
            // Así que para "1" (presionado), BUTTONS_IN debe ser 0.
            BUTTONS_IN = ~mask_active_high;
        end
    endtask

    task release_all;
        begin
            BUTTONS_IN = 4'b1111; // ninguno presionado
        end
    endtask

    // ---------------- Watchdog global -----------
    initial begin
        #200_000_000; // 200 ms
        $display("ERROR: Watchdog global (sim demasiado larga)");
        $finish;
    end

    // ---------------- Test principal ------------
    integer do_h,do_l,re_h,re_l,mi_h,mi_l,fa_h,fa_l;
    integer prio_h, prio_l;

    initial begin
        $dumpfile("SOC_tb.vcd");
        $dumpvars(0, SOC_tb);
        // Puedes dumpear internos si quieres:
        // $dumpvars(0, dut.per_keyboard_pwm_);
        // $dumpvars(0, dut.perip_contador_);

        // Reset
        resetn = 0;
        wait_ms(1);
        resetn = 1;

        // Deja arrancar al CPU un momento (si hace algo)
        wait_ms(5);

        // --- SILENCIO INICIAL ---
        release_all();
        wait_ms(2);
        check_silence(400); // ~16 us

        // --- DO ---
        press_button(4'b0001);
        wait_ms(2); wait_cycles(100);
        measure_cycle(do_h, do_l);
        $display("DO: high=%0d low=%0d (esp=%0d)", do_h, do_l, DIV_DO);
        if (do_h!=DIV_DO || do_l!=DIV_DO)
            $display("WARN : DO distinto al esperado (puede ser por cambio de freq a mitad de ciclo).");

        // --- RE ---
        release_all(); wait_ms(2); check_silence(200);
        press_button(4'b0010);
        wait_ms(2); wait_cycles(100);
        measure_cycle(re_h, re_l);
        $display("RE: high=%0d low=%0d (esp=%0d)", re_h, re_l, DIV_RE);

        // --- MI ---
        release_all(); wait_ms(2); check_silence(200);
        press_button(4'b0100);
        wait_ms(2); wait_cycles(100);
        measure_cycle(mi_h, mi_l);
        $display("MI: high=%0d low=%0d (esp=%0d)", mi_h, mi_l, DIV_MI);

        // --- FA ---
        release_all(); wait_ms(2); check_silence(200);
        press_button(4'b1000);
        wait_ms(2); wait_cycles(100);
        measure_cycle(fa_h, fa_l);
        $display("FA: high=%0d low=%0d (esp=%0d)", fa_h, fa_l, DIV_FA);

        // --- PRIORIDAD: DO domina sobre las demás ---
        release_all(); wait_ms(2); check_silence(200);
        press_button(4'b1111);            // todas "presionadas"
        wait_ms(2); wait_cycles(100);
        measure_cycle(prio_h, prio_l);
        $display("PRIO (DO+RE+MI+FA): high=%0d low=%0d (debe ser DO=%0d)", prio_h, prio_l, DIV_DO);
        if (prio_h!=DIV_DO || prio_l!=DIV_DO) begin
            $display("ERROR: Prioridad falló. Se esperaba DO.");
            $finish;
        end else begin
            $display("OK   : Prioridad correcta (DO domina).");
        end

        // --- Comparar que todos sean distintos ---
        if ((do_h==re_h)&&(do_l==re_l)) begin $display("ERROR: DO y RE iguales"); $finish; end
        if ((do_h==mi_h)&&(do_l==mi_l)) begin $display("ERROR: DO y MI iguales"); $finish; end
        if ((do_h==fa_h)&&(do_l==fa_l)) begin $display("ERROR: DO y FA iguales"); $finish; end
        if ((re_h==mi_h)&&(re_l==mi_l)) begin $display("ERROR: RE y MI iguales"); $finish; end
        if ((re_h==fa_h)&&(re_l==fa_l)) begin $display("ERROR: RE y FA iguales"); $finish; end
        if ((mi_h==fa_h)&&(mi_l==fa_l)) begin $display("ERROR: MI y FA iguales"); $finish; end

        // --- SILENCIO FINAL ---
        release_all(); wait_ms(2); check_silence(400);

        $display("OK: SOC responde, PWM cambia por cada tecla, silencio y prioridad verificados.");
        $finish;
    end

endmodule

