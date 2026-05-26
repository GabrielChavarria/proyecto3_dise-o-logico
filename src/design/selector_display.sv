module selector_display (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        tecla_valida,
    input  logic        seleccionar,
    input  logic        limpiar,
    input  logic [1:0]  estado_dbg,
    input  logic [6:0]  dividendo,
    input  logic [4:0]  divisor_b,
    input  logic [6:0]  cociente,
    input  logic [4:0]  residuo,
    output logic [15:0] numero_bcd
);
    logic        sel_resultado;
    logic [10:0] num_display;
    logic [3:0]  d_miles, d_cientos, d_decenas, d_unidades;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            sel_resultado <= 1'b0;
        else if (tecla_valida && seleccionar)
            sel_resultado <= ~sel_resultado;
        else if (tecla_valida && limpiar)
            sel_resultado <= 1'b0;
    end

    always_comb begin
        case (estado_dbg)
            2'd0:    num_display = {4'b0, dividendo};
            2'd1:    num_display = {6'b0, divisor_b};
            2'd2:    num_display = {4'b0, dividendo};
            2'd3:    num_display = sel_resultado ? {6'b0, residuo}
                                                 : {4'b0, cociente};
            default: num_display = 11'd0;
        endcase

        d_miles    =  num_display / 11'd1000;
        d_cientos  = (num_display % 11'd1000) / 11'd100;
        d_decenas  = (num_display % 11'd100)  / 11'd10;
        d_unidades =  num_display % 11'd10;
    end

    assign numero_bcd = {d_miles, d_cientos, d_decenas, d_unidades};

endmodule
