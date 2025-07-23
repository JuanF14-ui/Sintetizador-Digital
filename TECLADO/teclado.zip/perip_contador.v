module perip_contador #(
    parameter integer WIDTH = 32
)(
    input  wire        clk,
    input  wire        reset,      // activo en alto

    // Bus
    input  wire        cs,
    input  wire [3:0]  addr,       // 16 registros max
    input  wire        rd,
    output reg [31:0]  rdata,

    // Entradas de teclas (debounced, alto activo)
    input  wire [3:0]  key_state
);

    reg [3:0]  key_prev;
    reg [WIDTH-1:0] count0, count1, count2, count3;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            key_prev <= 4'd0;
            count0   <= 0;
            count1   <= 0;
            count2   <= 0;
            count3   <= 0;
        end else begin
            // flanco subida
            if (~key_prev[0] & key_state[0]) count0 <= count0 + 1;
            if (~key_prev[1] & key_state[1]) count1 <= count1 + 1;
            if (~key_prev[2] & key_state[2]) count2 <= count2 + 1;
            if (~key_prev[3] & key_state[3]) count3 <= count3 + 1;
            key_prev <= key_state;
        end
    end

    always @(*) begin
        if (cs && rd) begin
            case (addr)
                4'h0: rdata = count0;
                4'h1: rdata = count1;
                4'h2: rdata = count2;
                4'h3: rdata = count3;
                default: rdata = 32'hDEADBEEF;
            endcase
        end else begin
            rdata = 32'h0000_0000;
        end
    end

endmodule

