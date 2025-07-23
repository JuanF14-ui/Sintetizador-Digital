module perip_led_pwm(
    input clk,
    input reset,
    input [31:0] d_in,
    input cs,
    input [31:0] addr,
    input rd,
    input wr,
    output reg [31:0] d_out,
    output pwm
);

    reg [31:0] duty_register = 0;
    localparam integer REG_OFFSET_FREQ = 5'h00;

    // Lógica de Escritura desde el Bus (CPU)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            duty_register <= 0;
        end else if (cs && wr) begin
            case (addr[4:0])
                REG_OFFSET_FREQ: begin
                    duty_register <= d_in;
                end
                default: begin
                    // Dirección de escritura no válida, ignorar
                end
            endcase
        end
    end

    // Lógica de Lectura para el Bus (CPU)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            d_out <= 0;
        end else if (cs && rd) begin
            case (addr[4:0])
                REG_OFFSET_FREQ: begin
                    d_out <= duty_register;
                end
                default: begin
                    d_out <= 32'b0;
                end
            endcase
        end else begin
            d_out <= 0;
        end
    end

    // Instancia del Generador PWM
    led_pwm led_pwm0 (
        .clk(clk),
        .freq(duty_register),
        .pwm(pwm)
    );

endmodule
