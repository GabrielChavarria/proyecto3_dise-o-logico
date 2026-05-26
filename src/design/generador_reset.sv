module generador_reset (
    input  logic clk,
    input  logic reset_n,
    output logic rst_n_int
);
    logic [3:0] rst_cnt = 4'd0;

    always_ff @(posedge clk) begin
        if (!(&rst_cnt))
            rst_cnt <= rst_cnt + 1;
    end

    assign rst_n_int = (&rst_cnt) & reset_n;

endmodule
