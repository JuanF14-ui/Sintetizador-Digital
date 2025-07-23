// ---------------------------------------------
// keyboard_pwm.v  (teclado 4 notas -> PWM)
// Mejoras: sync + debounce, contador de notas, parámetros claros
// ---------------------------------------------
module keyboard_pwm #(
    parameter integer CLK_HZ       = 25_000_000,
    parameter integer DEBOUNCE_MS  = 10,

    // Divisores (mitad de período) para DO/RE/MI/FA con CLK_HZ dado
    parameter integer DIV_DO       = 23860,  // ~523 Hz
    parameter integer DIV_RE       = 21302,  // ~587 Hz
    parameter integer DIV_MI       = 18977,  // ~659 Hz
    parameter integer DIV_FA       = 17906   // ~698 Hz
)(
    input  wire        clk,
    input  wire [3:0]  btn_raw,        // botones físicos
    output wire        pwm_out,        // salida PWM (audio)
    output reg  [31:0] note_counter,   // opcional: incrementa en cada nueva pulsación
    output wire [3:0]  btn_stable,     // botones ya filtrados
    output reg  [31:0] note_div_out    // divisor actual (lectura/debug)
);

    // ===== 1) Sincronización + debounce =====
    // 2 FFs para sincronizar
    reg [3:0] sync1, sync2;
    always @(posedge clk) begin
        sync1 <= btn_raw;
        sync2 <= sync1;
    end

    // Debounce por bit
    localparam integer CNT_MAX = (CLK_HZ/1000)*DEBOUNCE_MS;
    localparam integer CNT_W   = $clog2(CNT_MAX+1);
    reg [CNT_W-1:0] cnt [3:0];
    reg [3:0] stable = 4'b0000;

    integer i;
    always @(posedge clk) begin
        for (i=0; i<4; i=i+1) begin
            if (sync2[i] == stable[i]) begin
                cnt[i] <= 0;
            end else begin
                if (cnt[i] == CNT_MAX) begin
                    stable[i] <= sync2[i];
                    cnt[i]    <= 0;
                end else begin
                    cnt[i] <= cnt[i] + 1;
                end
            end
        end
    end
    assign btn_stable = stable;

    // ===== 2) Selección de nota (prioridad simple) =====
    reg [31:0] note_div;
    always @(*) begin
        if      (btn_stable[0]) note_div = DIV_DO;
        else if (btn_stable[1]) note_div = DIV_RE;
        else if (btn_stable[2]) note_div = DIV_MI;
        else if (btn_stable[3]) note_div = DIV_FA;
        else                    note_div = 32'd0;
    end

    // ===== 3) Contador de notas (flanco de subida de cualquier botón) =====
    reg [3:0] btn_prev;
    always @(posedge clk) begin
        btn_prev <= btn_stable;
        if ( (btn_stable & ~btn_prev) != 4'b0000 )
            note_counter <= note_counter + 1;
    end

    // Para exponer el divisor actual por fuera
    always @(posedge clk) begin
        note_div_out <= note_div;
    end

    // ===== 4) Generador PWM =====
    led_pwm pwm_gen (
        .clk (clk),
        .freq(note_div),
        .pwm (pwm_out)
    );

endmodule

