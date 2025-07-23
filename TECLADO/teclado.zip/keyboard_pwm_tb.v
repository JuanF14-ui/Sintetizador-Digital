`timescale 1ns/1ps

module keyboard_pwm_tb;

    // ---------------- Parámetros ----------------
    localparam CLK_HZ  = 25_000_000;
    localparam CLK_PER = 40; // ns

    localparam DIV_DO = 23860;
    localparam DIV_RE = 21302;
    localparam DIV_MI = 18977;
    localparam DIV_FA = 17906;

    // ------------- Señales DUT ------------------
    reg        clk     = 0;
    reg [3:0]  btn_raw = 4'b0000;
    wire       pwm_out;
    wire [31:0] note_counter;
    wire [3:0]  btn_stable;
    wire [31:0] note_div_out;

    // ------------- Instancia DUT ----------------
    keyboard_pwm #(
        .CLK_HZ      (CLK_HZ),
        .DEBOUNCE_MS (1),
        .DIV_DO      (DIV_DO),
        .DIV_RE      (DIV_RE),
        .DIV_MI      (DIV_MI),
        .DIV_FA      (DIV_FA)
    ) dut (
        .clk           (clk),
        .btn_raw       (btn_raw),
        .pwm_out       (pwm_out),
        .note_counter  (note_counter),
        .btn_stable    (btn_stable),
        .note_div_out  (note_div_out)
    );

    // ---------------- Clock ---------------------
    always #(CLK_PER/2) clk = ~clk;

    // ------------- Utilidades -------------------
    integer h,l;
    integer do_h,do_l,re_h,re_l,mi_h,mi_l,fa_h,fa_l;

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

    task measure_cycle(output integer high_cnt, output integer low_cnt);
        integer timeout;
        begin
            timeout = 0;
            // Espera posedge pwm_out con watchdog
            while (pwm_out !== 1'b1) begin
                @(posedge clk);
                timeout = timeout + 1;
                if (timeout > 1_000_000) begin
                    $display("ERROR: Timeout esperando posedge pwm_out");
                    $finish;
                end
            end

            high_cnt = 0; low_cnt = 0;

            while (pwm_out) begin
                @(posedge clk);
                high_cnt = high_cnt + 1;
            end
            while (!pwm_out) begin
                @(posedge clk);
                low_cnt = low_cnt + 1;
            end
        end
    endtask

    task press_and_check(input [3:0] key, input [31:0] expected_div,
                         output integer hh, output integer ll);
        begin
            // silencio previo para ver cambio claro
            btn_raw = 4'b0000;
            wait_ms(2);
            wait_cycles(50);

            // presiona
            btn_raw = key;
            wait_ms(2);        // debounce
            wait_cycles(50);   // estabilización

            // mide
            measure_cycle(hh, ll);
            $display("Nota %b -> high=%0d low=%0d (esp=%0d)", key, hh, ll, expected_div);
            if (hh!=expected_div || ll!=expected_div) begin
                $display("ERROR: divisor incorrecto (esperado=%0d)", expected_div);
                $finish;
            end
        end
    endtask

    // Watchdog global
    initial begin
        #100_000_000; // 100 ms sim time
        $display("ERROR: Watchdog global, sim demasiado larga");
        $finish;
    end

    // ----------------- TEST ---------------------
    initial begin
        $dumpfile("keyboard_pwm_tb.vcd");
        $dumpvars(0, keyboard_pwm_tb);
        $dumpvars(0, dut.note_counter);

        // DO
        press_and_check(4'b0001, DIV_DO, do_h, do_l);
        // RE
        press_and_check(4'b0010, DIV_RE, re_h, re_l);
        // MI
        press_and_check(4'b0100, DIV_MI, mi_h, mi_l);
        // FA
        press_and_check(4'b1000, DIV_FA, fa_h, fa_l);

        // Comparar que todos sean distintos
        if ((do_h==re_h)&&(do_l==re_l)) begin $display("ERROR: DO y RE iguales"); $finish; end
        if ((do_h==mi_h)&&(do_l==mi_l)) begin $display("ERROR: DO y MI iguales"); $finish; end
        if ((do_h==fa_h)&&(do_l==fa_l)) begin $display("ERROR: DO y FA iguales"); $finish; end
        if ((re_h==mi_h)&&(re_l==mi_l)) begin $display("ERROR: RE y MI iguales"); $finish; end
        if ((re_h==fa_h)&&(re_l==fa_l)) begin $display("ERROR: RE y FA iguales"); $finish; end
        if ((mi_h==fa_h)&&(mi_l==fa_l)) begin $display("ERROR: MI y FA iguales"); $finish; end

        $display("OK: Cada tecla produce un PWM distinto y el test terminó.");
        $finish;
    end

endmodule

