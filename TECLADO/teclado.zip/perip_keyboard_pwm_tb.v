`timescale 1ns / 1ps

module perip_keyboard_pwm_tb;

  // Señales de prueba
  reg clk = 0;
  reg reset = 1;
  reg [31:0] d_in = 0;
  reg cs = 0;
  reg [31:0] addr = 0;
  reg rd = 0;
  reg wr = 0;
  wire [31:0] d_out;
  wire pwm;

  // Señal de botones de entrada
  reg [3:0] buttons_in;

  // Clock de 50 MHz
  always #10 clk = ~clk;

  // Instancia del DUT (Device Under Test)
  perip_keyboard_pwm uut (
    .clk(clk),
    .reset(reset),
    .d_in(d_in),
    .cs(cs),
    .addr(addr),
    .rd(rd),
    .wr(wr),
    .d_out(d_out),
    .pwm(pwm),
    .buttons_in(buttons_in)  // <-- Usamos señal intermedia
  );

  // Proceso de prueba
  initial begin
    $dumpfile("perip_keyboard_pwm_tb.vcd");
    $dumpvars(0, perip_keyboard_pwm_tb);

    // Etapa 1: Reset
    #20;
    reset = 0;

    // Etapa 2: No hay tecla presionada
    buttons_in = 4'b0000;
    #200;

    // Etapa 3: Presionar tecla DO (botón 0)
    buttons_in = 4'b0001;
    #500;

    // Etapa 4: Presionar tecla RE (botón 1)
    buttons_in = 4'b0010;
    #500;

    // Etapa 5: Presionar tecla MI (botón 2)
    buttons_in = 4'b0100;
    #500;

    // Etapa 6: Presionar tecla FA (botón 3)
    buttons_in = 4'b1000;
    #500;

    // Etapa 7: Ninguna tecla presionada
    buttons_in = 4'b0000;
    #500;

    $finish;
  end

endmodule

