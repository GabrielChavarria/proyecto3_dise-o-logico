module debounce #(//modulo para eliminar rebotes mecanicos
    parameter TICKS = 20  // ciclos de 1kHz a esperar (~20ms)
)(
    input  logic clk,
    input  logic rst_n,
    input  logic pulso,       // enable 1kHz del divisor_frecuencia
    input  logic senal_in,    // señal sincronizada del teclado
    output logic senal_out    // señal limpia sin rebote
);

    logic [$clog2(TICKS)-1:0] contador;// va contando cuantas muestras consecutivas detectan un cambio
    logic estado_actual;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            contador      <= '0;//estado inicial 1
            estado_actual <= 1'b1;  // reposo con pull-up = alto
            senal_out     <= 1'b1;//salida inicia en reposo
        end else if (pulso) begin
            if (senal_in == estado_actual) begin//¿la señal sigue igual que el estado estable actual?
                contador <= '0;// si no hay cambio, reinicia el contador
            end else begin
                if (contador == TICKS - 1) begin// ¿la señal lleva suficiente tiempo estable?
                    estado_actual <= senal_in;//actualiza el estado estable
                    senal_out     <= senal_in;//actualiza la salida 
                    contador      <= '0;
                end else begin
                    contador <= contador + 1;
                end
            end
        end
    end

endmodule
