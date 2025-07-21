module midi_note_sender (
    input clk,
    input rst,
    input [15:0] distance_cm,
    input distance_ready,
    output reg [7:0] midi_byte,
    output reg midi_send,
    input uart_ready
);
    reg [1:0] state;
    localparam IDLE = 2'b00,
               SEND1 = 2'b01,
               SEND2 = 2'b10,
               SEND3 = 2'b11;

    reg [7:0] note;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            midi_byte <= 0;
            midi_send <= 0;
        end else begin
            midi_send <= 0;
            case (state)
                IDLE: begin
                    if (distance_ready) begin
                        note <= (distance_cm < 5) ? 80 :
                                (distance_cm > 60) ? 50 :
                                80 - ((distance_cm - 5) * 30 / 55);
                        state <= SEND1;
                    end
                end
                SEND1: if (uart_ready) begin midi_byte <= 8'h90; midi_send <= 1; state <= SEND2; end
                SEND2: if (uart_ready) begin midi_byte <= note;  midi_send <= 1; state <= SEND3; end
                SEND3: if (uart_ready) begin midi_byte <= 8'd100; midi_send <= 1; state <= IDLE; end
            endcase
        end
    end
endmodule
