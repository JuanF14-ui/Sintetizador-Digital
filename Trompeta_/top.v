// top.v
`timescale 1ns/1ps

// -------------------------------------------------------------
//  MÓDULO DE DEBOUNCE (uno por botón)
// -------------------------------------------------------------
module debounce (
    input  clk,
    input  btn_in,
    output reg btn_out
);
    reg [15:0] cnt = 0;
    reg         sync = 0;

    always @(posedge clk) begin
        sync <= btn_in;
        if (sync == btn_out)
            cnt <= 0;
        else begin
            cnt <= cnt + 1;
            if (&cnt) begin     // cuando todos los bits de cnt sean 1
                btn_out <= sync;
                cnt <= 0;
            end
        end
    end
endmodule

// -------------------------------------------------------------
//  MÓDULO UART_TX (115200 baud, clk 12 MHz)
// -------------------------------------------------------------
module uart_tx (
    input        clk,
    input        send,
    input  [7:0] data,
    output reg   tx,
    output reg   busy
);
    localparam CLK_FREQ    = 12_000_000;
    localparam BAUD        = 115_200;
    localparam CLKS_PER_BIT = CLK_FREQ/BAUD;

    reg [3:0]  bit_idx = 0;
    reg [13:0] clk_cnt = 0;
    reg [9:0]  shift_reg = 10'b1111111111;
    reg        sending = 0;

    always @(posedge clk) begin
        if (send && !sending) begin
            // cargar start(0), data[7:0], stop(1)
            shift_reg <= {1'b1, data, 1'b0};
            sending   <= 1;
            bit_idx   <= 0;
            clk_cnt   <= 0;
            busy      <= 1;
        end else if (sending) begin
            if (clk_cnt == CLKS_PER_BIT-1) begin
                clk_cnt <= 0;
                tx      <= shift_reg[bit_idx];
                bit_idx <= bit_idx + 1;
                if (bit_idx == 9) begin
                    sending <= 0;
                    busy    <= 0;
                end
            end else begin
                clk_cnt <= clk_cnt + 1;
            end
        end else begin
            tx <= 1;  // línea idle
        end
    end
endmodule

// -------------------------------------------------------------
//  MÓDULO TOP (3 botones → ASCII '0'..'7' por UART)
// -------------------------------------------------------------
module top (
    input        clk,         // pad 35, oscilador onboard 12 MHz
    input        btn0_raw,    // pad 9
    input        btn1_raw,    // pad 17
    input        btn2_raw,    // pad 18
    output       tx           // pad 16
);
    // Debounce
    wire b0, b1, b2;
    debounce db0(.clk(clk), .btn_in(btn0_raw), .btn_out(b0));
    debounce db1(.clk(clk), .btn_in(btn1_raw), .btn_out(b1));
    debounce db2(.clk(clk), .btn_in(btn2_raw), .btn_out(b2));

    // Vector de botones
    wire [2:0] botones = {b2, b1, b0};

    // Generar envío UART al cambiar
    reg  [2:0] last = 3'bxxx;
    reg        send = 0;
    reg  [7:0] data = 8'd0;
    wire       busy;

    always @(posedge clk) begin
        if (!busy && botones != last) begin
            last <= botones;
            data <= "0" + botones;  // ASCII '0'..'7'
            send <= 1;
        end else begin
            send <= 0;
        end
    end

    uart_tx u0 (
        .clk  (clk),
        .send (send),
        .data (data),
        .tx   (tx),
        .busy (busy)
    );
endmodule
