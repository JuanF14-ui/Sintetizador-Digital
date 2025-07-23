module uart_midi (
    input wire clk,
    input wire uart_rx,
    output reg [6:0] volumen,  // 7 bits (0-127)
    output reg [6:0] nota,
    output reg note_on
);
    parameter CLK_FREQ = 25_000_000;
    parameter BAUD_RATE = 31250;  // Estándar MIDI
    
    reg [2:0] bit_count = 0;
    reg [7:0] shift_reg;
    reg [1:0] state = 0;
    reg [15:0] baud_counter = 0;
    reg midi_rx;
    
    // Sincronización de la entrada UART
    always @(posedge clk) begin
        midi_rx <= uart_rx;
        
        if (baud_counter == (CLK_FREQ/BAUD_RATE)-1) begin
            baud_counter <= 0;
            case(state)
                0: if (!midi_rx) state <= 1;  // Detecta start bit
                1: begin  // Recibe bits de datos
                    shift_reg <= {midi_rx, shift_reg[7:1]};
                    if (bit_count == 7) begin
                        state <= 2;
                        bit_count <= 0;
                    end else begin
                        bit_count <= bit_count + 1;
                    end
                end
                2: state <= 0;  // Stop bit
            endcase
        end else begin
            baud_counter <= baud_counter + 1;
        end
    end
    
    // Procesamiento de mensajes MIDI
    always @(posedge clk) begin
        if (state == 2 && bit_count == 0) begin  // Byte completo recibido
            if (shift_reg[7]) begin  // Es un comando
                case (shift_reg[7:4])
                    4'b1001: note_on <= 1;  // Note On
                    4'b1000: note_on <= 0;  // Note Off
                    4'b1011: ;  // Control Change (usaremos para volumen)
                endcase
            end else begin  // Es un dato
                if (note_on) begin
                    nota <= shift_reg[6:0];  // 7 bits para nota
                end else begin
                    volumen <= shift_reg[6:0];  // 7 bits para volumen
                end
            end
        end
    end
endmodule
