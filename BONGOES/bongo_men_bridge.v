module bongo_men_bridge (
    input clk,
    input rst,
    input [31:0] addr,
    input [31:0] d_in,
    input wr,
    input rd,
    output [31:0] d_out,

    input [1:0] bongo_hit
);
    reg [31:0] reg_bongo;
    reg [31:0] dout_reg;

    always @(posedge clk) begin
        if (rst) begin
            reg_bongo <= 0;
            dout_reg <= 0;
        end else begin
            // Guarda el valor del golpe recibido (bit izquierdo y derecho)
            reg_bongo <= {30'b0, bongo_hit};

            // Si se lee desde el CPU
            if (rd)
                dout_reg <= reg_bongo;
        end
    end

    assign d_out = dout_reg;

endmodule
