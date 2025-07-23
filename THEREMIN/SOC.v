// Top-level SoC para Theremin digital
module soc (
    input        clk,
    input        rst,
    output       tx,
    output       trigger1,
    input        echo1,
    output       trigger2,
    input        echo2
);

    wire [15:0] dist_tone;
    wire        ready_tone;
    wire [15:0] dist_vol;
    wire        ready_vol;
    wire [7:0]  midi_byte;
    wire        midi_send;
    wire        tx_busy;

    // Sensor ultrasónico para tono
    ultrasonic_sensor u_tone (
        .clk(clk),
        .rst(rst),
        .trigger(trigger1),
        .echo(echo1),
        .distance_cm(dist_tone),
        .distance_ready(ready_tone)
    );

    // Sensor ultrasónico para volumen
    ultrasonic_sensor u_vol (
        .clk(clk),
        .rst(rst),
        .trigger(trigger2),
        .echo(echo2),
        .distance_cm(dist_vol),
        .distance_ready(ready_vol)
    );

    // Generador de nota MIDI según distancia del primer sensor
    midi_note_sender m_tone (
        .clk(clk),
        .rst(rst),
        .distance_cm(dist_tone),
        .distance_ready(ready_tone),
        .midi_byte(midi_byte),
        .midi_send(midi_send),
        .uart_ready(!tx_busy)
    );

    // Generador de volumen MIDI según distancia del segundo sensor
    midi_volume_sender m_vol (
        .clk(clk),
        .rst(rst),
        .distance_cm(dist_vol),
        .distance_ready(ready_vol),
        .midi_byte(midi_byte),
        .midi_send(midi_send),
        .uart_ready(!tx_busy)
    );

    // Transmisor UART para enviar bytes MIDI
    uart_tx #(
        .CLK_FREQ(50000000),
        .BAUD_RATE(31250)
    ) uart_inst (
        .clk(clk),
        .rst(rst),
        .tx_data(midi_byte),
        .tx_start(midi_send),
        .tx_serial(tx),
        .tx_busy(tx_busy)
    );

endmodule

