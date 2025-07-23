module SOC (
    input             clk,     // system clock
    input             resetn,  // reset button
    output wire [0:0] LEDS,    // system LEDs
    input             RXD,     // UART receive
    output            TXD,    // UART transmit
    output PWM_LED_OUT,
    output PWM_AUDIO_OUT,
    input wire [3:0]    BUTTONS_IN
);
  

    wire [3:0] buttons_active_high;
    assign buttons_active_high = ~BUTTONS_IN;



  //##########################
  //### DESCRIPCIÓN DE CPU ###
  //##########################
  wire [31:0] mem_addr;
  wire [31:0] mem_rdata;
  wire mem_rstrb;
  wire [31:0] mem_wdata;
  wire [3:0] mem_wmask;
  FemtoRV32 CPU (
      .clk(clk),
      .reset(resetn),
      .mem_addr(mem_addr),
      .mem_rdata(mem_rdata),
      .mem_rstrb(mem_rstrb),
      .mem_wdata(mem_wdata),
      .mem_wmask(mem_wmask),
      .mem_rbusy(1'b0),
      .mem_wbusy(1'b0)
  );

  //#################################
  //### DESCRIPCIÓN DE CHIPSELECT ###
  //#################################
  wire [6:0] cs;
  wire cs_uart = cs[0];  // cs_chip0
  wire cs_led_pwm = cs[1];  // cs_chip1
  wire cs_mult = cs[2];  // cs_chip2
  wire cs_keyboard_pwm = cs[3];  // cs_chip3
  wire cs_contador = cs[4];  // cs_chip4
  wire cs_chip5 = cs[5];  // cs_chip5
  wire cs_ram = cs[6];  // cs_chip6
  chip_select chip_select (
      .mem_addr(mem_addr),
      .chip0_dout(uart_dout),  // 0x00400000
      .chip1_dout(led_pwm_dout),  // 0x00410000
      .chip2_dout(mult_dout),  // 0x00420000
      .chip3_dout(keyboard_pwm_dout),  // 0x00430000
      .chip4_dout(contador_dout),  // 0x00440000
      .chip5_dout(),  // 0x00450000
      .chip6_dout(RAM_rdata),  // default
      .cs(cs),
      .mem_rdata(mem_rdata)
  );

  //##########################
  //### DESCRIPCIÓN DE RAM ###
  //##########################
  wire [31:0] RAM_rdata;
  wire wr = |mem_wmask;
  wire rd = mem_rstrb;
  Memory RAM (
      .clk(clk),
      .mem_addr(mem_addr),
      .mem_rdata(RAM_rdata),
      .mem_rstrb(cs_ram & rd),
      .mem_wdata(mem_wdata),
      .mem_wmask({4{cs_ram}} & mem_wmask)
  );

  //######################################
  //### DESCRIPCIÓN DE PERIFERICO UART ###
  //######################################
  wire [31:0] uart_dout;
  peripheral_uart #(
      .clk_freq(25000000),
      .baud    (57600)
  ) per_uart (
      .clk(clk),
      .rst(!resetn),
      .d_in(mem_wdata),
      .cs(cs_uart),
      .addr(mem_addr),
      .rd(rd),
      .wr(wr),
      .d_out(uart_dout),
      .uart_tx(TXD),
      .uart_rx(RXD),
      .ledout(LEDS[0])
  );

  //######################################
  //### DESCRIPCIÓN DE PERIFERICO MULT ###
  //######################################
  wire [31:0] mult_dout;
  peripheral_mult mult1 (
      .clk(clk),
      .reset(!resetn),
      .d_in(mem_wdata),
      .cs(cs_mult),
      .addr(mem_addr),
      .rd(rd),
      .wr(wr),
      .d_out(mult_dout)
  );

  //######################################
  //### DESCRIPCIÓN DE PERIFERICO DPRAM ###
  //######################################
  // wire [31:0] dpram_dout;
  //
  // peripheral_dpram dpram_p0 (
  //     .clk(clk),
  //     .reset(!resetn),
  //     .d_in(mem_wdata[15:0]),
  //     .cs(cs[6]),
  //     .addr(mem_addr[15:0]),
  //     .rd(rd),
  //     .wr(wr),
  //     .d_out(dpram_dout)
  // );
//######################################
  //### DESCRIPCIÓN DE PERIFERICO PWM_LED ###
  //######################################
  wire [31:0] led_pwm_dout;
  perip_led_pwm per_led_pwm_(
      .clk(clk),
      .reset(!resetn),
      .d_in(mem_wdata),
      .cs(cs_led_pwm),
      .addr(mem_addr),
      .rd(rd),
      .wr(wr),
      .d_out(led_pwm_dout),
      .pwm(PWM_LED_OUT)
   );
//##########################################
    //### DESCRIPCIÓN DE PERIFERICO KEYBOARD_PWM ###
    //##########################################
    wire [31:0] keyboard_pwm_dout; // Salida de datos de lectura del teclado
    perip_keyboard_pwm per_keyboard_pwm_(
        .clk(clk),
        .reset(!resetn), // Conectamos el reset activo en alto
        .d_in(mem_wdata), // Datos de escritura del CPU
        .cs(cs_keyboard_pwm), // Chip Select específico para el teclado
        .addr(mem_addr),      // Dirección del bus
        .rd(rd),              // Señal de lectura del bus
        .wr(wr),              // Señal de escritura del bus
        .d_out(keyboard_pwm_dout), // Datos de lectura para el CPU (estado de botones)
        .buttons_in(buttons_active_high), // Conectamos los botones físicos de la FPGA
        .pwm(PWM_AUDIO_OUT)            // Conectamos la salida PWM del teclado a la salida global 'PWM'
                               // Esto IMPLICA que el perip_led_pwm_ debe usar otra salida si ambos necesitan PWM.
                               // Si solo quieres una, el último que se asigne a 'PWM' gana.
                               // Si per_led_pwm_ también necesita una salida física, su puerto '.pwm' debería llamarse diferente.
   );
//##########################################
    //### DESCRIPCIÓN DE PERIFERICO CONTADOR ###
    //##########################################
    
     wire [31:0] contador_dout;
     perip_contador perip_contador_(
      .clk(clk),
      .reset(!resetn),
      .cs(cs_contador),
      .addr(mem_addr[3:0]),  // Usamos solo 4 bits para direccionar 4 registros
      .rd(rd),
      .rdata(contador_dout),
      .key_state(keyboard_pwm_dout[3:0]) // suponiendo que d_out del teclado trae los e

);


`ifdef BENCH
  always @(posedge clk) begin
    if (cs[5] & wr) begin
      $write("%c", mem_wdata[7:0]);
      $fflush(32'h8000_0001);
    end
  end
`endif
endmodule
