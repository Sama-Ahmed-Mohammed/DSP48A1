module reg_mux #(
    parameter REGE = 1, //enable reg
    parameter RSTTYPE = "SYNC",
    parameter WIDTH = 18 //width of input/output signals
)
(
    input CE, //clk enable
    input clk, //clk
    input RST, //reset
    input [WIDTH - 1 : 0] in,
    output reg [WIDTH - 1 : 0] out
);
    generate
        if (REGE == 0) begin : no_register
            always @(*) begin
                if (RST)
                    out = 0;
                else
                    out = in;
            end
        end 
        else begin : registered_output
            if (RSTTYPE == "SYNC") begin : sync_reset
                always @(posedge clk) begin
                     if (RST)
                        out <= 0;
                    else if (CE)
                        out <= in;
                end
            end 
            else begin : async_reset
                always @(posedge clk or posedge RST) begin
                    if (RST)
                        out <= 0;
                    else if (CE)
                        out <= in;
                end
            end
        end
    endgenerate
endmodule