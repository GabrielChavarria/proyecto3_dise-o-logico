
//convierte señales del taclado en comandos utilies 
// recibe fila detctada
//columna detectada
//y produce, numero, ejecutar, limpiar, confirmar 
module decodificador_tecla (
    input  logic [3:0] fila_cap,
    input  logic [3:0] col_cap,
    output logic [3:0] digito,
    output logic       es_numero,
    output logic       confirmar_a,  // A = confirmar dividendo
    output logic       ejecutar,     // B = ejecutar division
    output logic       limpiar,      // D = reset
    output logic       seleccionar   // C = alternar cociente/residuo
);
    logic [7:0] tecla;
    assign tecla = {fila_cap, col_cap}; // concatancion, forma un patron de 8 bits de forma [fila][columna]
 
    always_comb begin// indica que usa logica combinacional, o sea sin flip-flops
        digito      = 4'd0;
        es_numero   = 1'b0;
        confirmar_a = 1'b0;
        ejecutar    = 1'b0;
        limpiar     = 1'b0;
        seleccionar = 1'b0;
 
        case (tecla)
            // Fila 0 (fila_cap=1110): 1, 2, 3, A(+)
            8'b1110_1110: begin digito = 4'd1; es_numero = 1'b1; end
            8'b1110_1101: begin digito = 4'd2; es_numero = 1'b1; end
            8'b1110_1011: begin digito = 4'd3; es_numero = 1'b1; end
            8'b1110_0111: begin confirmar_a = 1'b1; end            // A (+)
 
            // Fila 1 (fila_cap=1101): 4, 5, 6, B(=)
            8'b1101_1110: begin digito = 4'd4; es_numero = 1'b1; end
            8'b1101_1101: begin digito = 4'd5; es_numero = 1'b1; end
            8'b1101_1011: begin digito = 4'd6; es_numero = 1'b1; end
            8'b1101_0111: begin ejecutar = 1'b1; end               // B (=)
 
            // Fila 2 (fila_cap=1011): 7, 8, 9, C(alternar cociente/residuo)
            8'b1011_1110: begin digito = 4'd7; es_numero = 1'b1; end
            8'b1011_1101: begin digito = 4'd8; es_numero = 1'b1; end
            8'b1011_1011: begin digito = 4'd9; es_numero = 1'b1; end
            8'b1011_0111: begin seleccionar = 1'b1; end              // C
 
            // Fila 3 (fila_cap=0111): *, 0, #, D
            8'b0111_1101: begin digito = 4'd0; es_numero = 1'b1; end
            8'b0111_0111: begin limpiar = 1'b1; end                // D
 
            default: ;
        endcase
    end
endmodule
