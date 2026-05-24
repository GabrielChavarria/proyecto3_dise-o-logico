// Unidad de division de enteros sin signo con pipeline
// Implementa el algoritmo iterativo de la seccion 5.7.2 (Harris & Harris)
// con un registro entre cada etapa para cortar el camino critico.
//
// Latencia: N+1 ciclos de reloj desde valid hasta done.
// Para puntaje extra: instanciar con N=7, M=5.

module divisor_enteros #(
    parameter N = 6,  // bits del dividendo (base: max 63, extra: N=7 max 127)
    parameter M = 4   // bits del divisor   (base: max 15, extra: M=5 max 31)
)(
    input  logic         clk,
    input  logic         rst_n,
    input  logic [N-1:0] dividendo,
    input  logic [M-1:0] divisor_b,
    input  logic         valid,    // pulso de 1 ciclo: operandos listos
    output logic [N-1:0] cociente,
    output logic [M-1:0] residuo,
    output logic         done      // pulso de 1 ciclo: resultado listo
);

    // Registros de pipeline: indice 0 = entrada registrada, indice N = salida
    logic [M-1:0] r_pipe [0:N];   // residuo parcial
    logic [N-1:0] q_pipe [0:N];   // cociente acumulado
    logic [M-1:0] b_pipe [0:N];   // divisor propagado
    logic [N-1:0] a_pipe [0:N];   // dividendo propagado
    logic         v_pipe [0:N];   // valid propagado

    // Etapa de entrada: captura los operandos al llegar valid
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_pipe[0] <= '0;
            q_pipe[0] <= '0;
            b_pipe[0] <= '0;
            a_pipe[0] <= '0;
            v_pipe[0] <= 1'b0;
        end else begin
            r_pipe[0] <= '0;       // residuo parcial inicial = 0
            q_pipe[0] <= '0;       // cociente inicial = 0
            b_pipe[0] <= divisor_b;
            a_pipe[0] <= dividendo;
            v_pipe[0] <= valid;
        end
    end

    // N etapas de pipeline, una por bit del dividendo (de MSB a LSB)
    genvar i;
    generate
        for (i = 0; i < N; i++) begin : etapa
            logic [M-1:0] r_shift;
            logic [M:0]   sub;
            logic         q_bit;
            logic [M-1:0] r_next;

            // Corre el residuo parcial a la izquierda e inserta el bit actual del dividendo
            assign r_shift = {r_pipe[i][M-2:0], a_pipe[i][N-1-i]};

            // Resta R - B; sub[M]=1 indica borrow (R < B)
            assign sub    = {1'b0, r_shift} - {1'b0, b_pipe[i]};

            // Q_i = 1 si R >= B (sin borrow), segun el algoritmo
            assign q_bit  = ~sub[M];

            // Proximo residuo parcial: D si R>=B, R si R<B
            assign r_next = q_bit ? sub[M-1:0] : r_shift;

            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    r_pipe[i+1] <= '0;
                    q_pipe[i+1] <= '0;
                    b_pipe[i+1] <= '0;
                    a_pipe[i+1] <= '0;
                    v_pipe[i+1] <= 1'b0;
                end else begin
                    r_pipe[i+1] <= r_next;
                    // Acumula bits del cociente: MSB primero -> queda en posicion correcta
                    q_pipe[i+1] <= {q_pipe[i][N-2:0], q_bit};
                    b_pipe[i+1] <= b_pipe[i];
                    a_pipe[i+1] <= a_pipe[i];
                    v_pipe[i+1] <= v_pipe[i];
                end
            end
        end
    endgenerate

    assign cociente = q_pipe[N];
    assign residuo  = r_pipe[N];
    assign done     = v_pipe[N];

endmodule
