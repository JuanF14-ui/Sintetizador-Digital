module perip_laser (
    input clk,
    input rst,
    input [31:0] d_in, // Valor de entrada
    input cs,
    input [31:0] addr,
    input rd,
    input wr,
    output [31:0] d_out, // Valor de salida
    input wire [3:0] laser
);
    localparam integer GETLASER = 5'h02; // C #define GETLASER 0x02
    //Leer los laser
    always @(posedge clk) begin
        if (rst) begin
        d_out = 0;
        end else begin
            if (cs && rd) begin
                if (addr[4:0] == GETLASER) begin
                    d_out <= { 28'b0,laser};
                end
            end
        end
    end
endmodule
