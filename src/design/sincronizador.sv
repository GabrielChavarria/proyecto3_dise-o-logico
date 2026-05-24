module sincronizador #(
    parameter BITS = 4// parametro que permite cambiar facilmente el ancho del bus 
)(
    input  logic             clk,//señal de relog
    input  logic [BITS-1:0]  senal_async,//entrada asincronica 
    output logic [BITS-1:0]  senal_sync// salida sincronica
);

    logic [BITS-1:0] ff1;// primera etapa del sincronizador

    always_ff @(posedge clk) begin//indica que se ejecuta en cada flanco de subida del relog
        ff1        <= senal_async;//captura la señal asincrona 
        senal_sync <= ff1;//segundo flip-flop toma la salida del primero de un ciclo despues, para reducir la probabilidad de metasbilidad  
    end

endmodule
