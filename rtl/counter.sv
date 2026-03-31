// 8-bit up-counter DUT
// Inputs:  clk, rst_n (active-low reset), enable
// Output:  count[7:0]
module counter (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       enable,
    output logic [7:0] count
);
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            count <= 8'h00;
        else if (enable)
            count <= count + 8'h01;
    end
endmodule
