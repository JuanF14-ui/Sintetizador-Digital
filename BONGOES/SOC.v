module SOC (
    input             clk,          // system clock
    input             resetn,       // reset button
    output wire [0:0] LEDS,         // system LEDs
    input             RXD,          // UART receive
    output            TXD,          // UART transmit
    input             left_sensor,  // sensor izquierdo
    input             right_sensor  // sensor derecho
);

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
  wire cs_uart = cs[0];
  wire cs_bongo = cs[1];  // Nuevo: chipselect para bongo_mem_bridge
  wire cs_mult = cs[2];
  wire cs_chip3 = cs[3];
  wire cs_chip4 = cs[4];
  wire cs_chip5 = cs[5];
  wire cs_ram  = cs[6];

  wire [31:0] uart_dout;
  wire [31:0] bongo_dout;
  wire [31:0] mult_dout;
  wire [31:0] RAM_rdata;

  chip_select chip_select (
      .mem_addr(mem_addr),
      .chip0_dout(uart_dout),
      .chip1_dout(bongo_dout),  // Ahora conectamos la salida del bridge
      .chip2_dout(mult_dout),
      .chip3_dout(),
      .chip4_dout(),
      .chip5_dout(),
      .chip6_dout(RAM_rdata),
      .cs(cs),
      .mem_rdata(mem_rdata)
  );

  //##########################
  //### DESCRIPCIÓN DE RAM ###
  //##########################
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

  //##############################################
  //### PERIFÉRICO SENSOR Y PUENTE DE MEMORIA ####
  //##############################################
  wire [1:0] bongo_hit;

  bongo_sensor sensor (
      .clk(clk),
      .rst(!resetn),
      .left_sensor(left_sensor),
      .right_sensor(right_sensor),
      .bongo_hit(bongo_hit)
  );

  bongo_men_bridge bridge (
      .clk(clk),
      .rst(!resetn),
      .addr(mem_addr),
      .d_in(mem_wdata),
      .wr(wr & cs_bongo),
      .rd(rd & cs_bongo),
      .bongo_hit(bongo_hit),
      .d_out(bongo_dout)
  );

  //######################################
  //### DESCRIPCIÓN DE PERIFERICO CHUCK ##
  //######################################
  chuck chuck1 (
      .clk(clk),
      .rst(!resetn),
      .bongo_hit(bongo_hit),
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
