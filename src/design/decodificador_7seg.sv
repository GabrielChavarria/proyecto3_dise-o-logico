module decodificador_7seg (// convierte un nuero binario/BCD en señales para un display de 7 segmentos
    input  logic [3:0] bcd,//Representa un nuero decimal en "Binary Coded Decimal
    output logic [6:0] segmentos  // {g, f, e, d, c, b, a}
);

    always_comb begin// indica logica combinaiconal 
        case (bcd)
            4'd0: segmentos = 7'b0111111;
            4'd1: segmentos = 7'b0000110;
            4'd2: segmentos = 7'b1011011;
            4'd3: segmentos = 7'b1001111;
            4'd4: segmentos = 7'b1100110;
            4'd5: segmentos = 7'b1101101;
            4'd6: segmentos = 7'b1111101;
            4'd7: segmentos = 7'b0000111;
            4'd8: segmentos = 7'b1111111;
            4'd9: segmentos = 7'b1101111;
            default: segmentos = 7'b0000000; // apagado
        endcase
    end

endmodule
