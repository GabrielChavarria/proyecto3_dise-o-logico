module divisor_frecuencia #(
    parameter N = 27000  // divide 27MHz entre N -> 1kHz por defecto
)(
    input  logic clk,
    input  logic rst_n,
    output logic pulso//salida del divisor 
);

    logic [$clog2(N)-1:0] contador;// registro contador 

    always_ff @(posedge clk or negedge rst_n) begin// logica secuencial, se ejecuta en flanco positivo o en reset
        if (!rst_n) begin//si reset activo
            contador <= '0;//reinicia el contador
            pulso    <= 1'b0;// y el pulso en apagado
        end else if (contador == N - 1) begin// ¿el contador ya llegó al límite?
            contador <= '0;// renicia el contador 
            pulso    <= 1'b1;// genera un pulso que dura un solo ciclo 
        end else begin// so todavia no llega al limite
            contador <= contador + 1;//incrementar contador 
            pulso    <= 1'b0;//pulso apagado
        end
    end

endmodule
