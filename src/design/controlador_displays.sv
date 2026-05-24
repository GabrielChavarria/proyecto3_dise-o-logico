module controlador_displays (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        pulso,        // a 1kHz del divisor_frecuencia
    input  logic [15:0] numero,       // {digito3, digito2, digito1, digito0} en BCD
    output logic [6:0]  segmentos,    // {g,f,e,d,c,b,a} al display
    output logic [3:0]  anodos        // un bit por digito, activo en bajo (catodo comun)
);

    logic [1:0] digito_activo;
    logic [3:0] bcd_actual;
    logic [3:0] digitos [0:3];

    // separar los 4 digitos BCD
    assign digitos[0] = numero[15:12];
    assign digitos[1] = numero[11:8];
    assign digitos[2] = numero[7:4];
    assign digitos[3] = numero[3:0];

    // contador de digito activo
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            digito_activo <= 2'd0;
        else if (pulso)
            digito_activo <= digito_activo + 1;
    end

    // seleccion del digito BCD a mostrar
    assign bcd_actual = digitos[digito_activo];

    // activacion del catodo correspondiente (activo en bajo para catodo comun)
    always_comb begin
        case (digito_activo)
            2'd0: anodos = 4'b1110; // digito 1 activo
            2'd1: anodos = 4'b1101; // digito 2 activo
            2'd2: anodos = 4'b1011; // digito 3 activo
            2'd3: anodos = 4'b0111; // digito 4 activo
            default: anodos = 4'b1111; // todos apagados
        endcase
    end

    // instancia del decodificador
    decodificador_7seg dec (
        .bcd      (bcd_actual),//
        .segmentos(segmentos)
    );

endmodule
