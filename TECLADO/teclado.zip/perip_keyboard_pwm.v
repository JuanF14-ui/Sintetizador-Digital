module perip_keyboard_pwm #(
    parameter integer CLK_HZ = 25_000_000,
    // Direcciones (byte address dentro del bloque)
    parameter [4:0] ADDR_NOTE_FREQ_WRITE = 5'h00,
    parameter [4:0] ADDR_BTN_READ_STATUS = 5'h04
)(
    input  wire        clk,
    input  wire        reset,          // activo en alto
    // Bus
    input  wire [31:0] d_in,
    input  wire        cs,
    input  wire [31:0] addr,
    input  wire        rd,
    input  wire        wr,
    output reg  [31:0] d_out,
    // IO
    input  wire [3:0]  buttons_in,     // ya debounced
    output wire        pwm
);

    // ---- Frecuencias: ajustadas a CLK_HZ ----
    localparam integer NOTE_C4_FREQ = (CLK_HZ / (2*262)); // aprox
    localparam integer NOTE_D4_FREQ = (CLK_HZ / (2*294));
    localparam integer NOTE_E4_FREQ = (CLK_HZ / (2*330));
    localparam integer NOTE_F4_FREQ = (CLK_HZ / (2*349));

    // ---- Registros internos ----
    reg [31:0] note_freq_from_buttons;
    reg [31:0] note_freq_from_soc;

    // Selección botones (prioridad one-hot)
    always @(*) begin
        case (buttons_in)
            4'b0001: note_freq_from_buttons = NOTE_C4_FREQ;
            4'b0010: note_freq_from_buttons = NOTE_D4_FREQ;
            4'b0100: note_freq_from_buttons = NOTE_E4_FREQ;
            4'b1000: note_freq_from_buttons = NOTE_F4_FREQ;
            default: note_freq_from_buttons = 32'd0;
        endcase
    end

    // Escrituras (sin más registros por ahora)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            note_freq_from_soc <= 32'd0;
        end else if (cs && wr) begin
            case (addr[4:0])
                ADDR_NOTE_FREQ_WRITE: note_freq_from_soc <= d_in;
                default: ;
            endcase
        end
    end

    // Lecturas (sin pipeline: combinacional, pero entregada en siguiente ciclo por el mux superior)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            d_out <= 32'd0;
        end else if (cs && rd) begin
            case (addr[4:0])
                ADDR_BTN_READ_STATUS:   d_out <= {28'b0, buttons_in};
                ADDR_NOTE_FREQ_WRITE:   d_out <= note_freq_from_soc;
                default:                d_out <= 32'd0;
            endcase
        end else begin
            d_out <= 32'd0;
        end
    end

    // Selección final (SoC > botones si escribió algo distinto de 0)
    wire [31:0] final_pwm_freq = (note_freq_from_soc != 0) ? note_freq_from_soc
                                                           : note_freq_from_buttons;

    // Instancia PWM
    led_pwm pwm_gen (
        .clk (clk),
        .freq(final_pwm_freq),
        .pwm (pwm)
    );

endmodule

