module perip_led_pwm(
    input clk,
    input reset,
    input [31:0] d_in,      //lo que llega de la CPU, tambien hare que sea de 8 bits LBS
    input cs,               //chip_select
    input [31:0] addr,      //direccionamiento
    input rd,               //lectura de los registros de control
    input wr,               //escritura de los registros de control
    output reg [31:0] d_out,    //
    output pwm
);

reg [16:0] duty = 0;
localparam integer SETDUTY = 5'h01;  //  algo de 5 bits en hex(h)01, En C SETDUTY 0X01

//escribir registros
always @(posedge clk) begin
    if(reset) begin
        duty <= 0;
       //operacion normal
    end else begin   //si esto sucede el chip esta habilitado
        if (cs && wr) begin
            if(addr[4:0] == SETDUTY) begin   //si se tiene una direccion de tal tamaño,
                                             //si me pide setearlo y escriba,
                                             //set duty se va a comparar con tal direccion (un valor const)
                duty <= {d_in[7:0], 9'b0};
            end
        end      //si chip select esta activo y ademas esta en modo de escritura de registros
    end
end

//escribir registros
//always @(posedge clk) begin end

led_pwm led_pwm0(
    .clk(clk),
    .duty(duty),
    .freq(100000),
    .pwm(pwm)
);


endmodule
