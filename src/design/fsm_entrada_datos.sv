// FSM de entrada de datos para la calculadora de division de enteros.
// Controla el ingreso del dividendo (max 63, 6 bits) y el divisor (max 15, 4 bits).
// Flujo: ingresar dividendo → tecla A → ingresar divisor → tecla B → esperar done → mostrar resultado.

module fsm_entrada_datos (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       tecla_valida,
    input  logic [3:0] digito,
    input  logic       es_numero,
    input  logic       confirmar_a,   // A: confirma dividendo, pasa a ingresar divisor
    input  logic       ejecutar,      // B: inicia la division
    input  logic       limpiar,       // D: reinicia
    input  logic       done,          // del divisor_enteros: resultado listo
    output logic [6:0] dividendo,
    output logic [4:0] divisor_b,
    output logic       valid,         // pulso de 1 ciclo para arrancar divisor_enteros
    output logic [1:0] estado_dbg
);

    typedef enum logic [1:0] {
        INGRESO_A  = 2'd0,  // ingresando dividendo
        INGRESO_B  = 2'd1,  // ingresando divisor
        CALCULANDO = 2'd2,  // esperando resultado del pipeline
        RESULTADO  = 2'd3   // mostrando cociente o residuo
    } estado_t;

    estado_t estado, estado_sig;

    logic [7:0] reg_a;   // temporal mayor para validar antes de guardar (max 199)
    logic [5:0] reg_b;   // temporal mayor para validar antes de guardar (max 39)
    logic       valid_next;
    

    // Valores candidatos al agregar un nuevo digito
    logic [10:0] nuevo_a;  // reg_a*10 + digito (evita overflow en la comparacion)
    logic [8:0]  nuevo_b;

    assign nuevo_a = {3'b0, reg_a} * 11'd10 + {7'b0, digito};
    assign nuevo_b = {3'b0, reg_b} * 9'd10  + {5'b0, digito};

    // Logica secuencial
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            estado  <= INGRESO_A;
            reg_a   <= 7'd0;
            reg_b   <= 5'd0;
            valid   <= 1'b0;
        end else begin
            valid  <= valid_next;
            estado <= estado_sig;

            if (tecla_valida) begin
                if (limpiar) begin
                    reg_a <= 7'd0;
                    reg_b <= 5'd0;
                end else begin
                    case (estado)
                        INGRESO_A: begin
                            if (es_numero && nuevo_a <= 11'd127)
                                reg_a <= nuevo_a[7:0];
                            if (confirmar_a)
                                reg_b <= 6'd0;
                        end
                        INGRESO_B: begin
                            if (es_numero && nuevo_b <= 9'd31)
                                reg_b <= nuevo_b[5:0];
                        end
                        default: ;
                    endcase
                end
            end
        end
    end

    // Logica combinacional de siguiente estado
    always_comb begin
        estado_sig  = estado;
        valid_next  = 1'b0;

        // Transicion por done (independiente del teclado)
        if (estado == CALCULANDO && done)
            estado_sig = RESULTADO;

        if (tecla_valida) begin
            if (limpiar) begin
                estado_sig = INGRESO_A;
            end else begin
                case (estado)
                    INGRESO_A: if (confirmar_a) estado_sig = INGRESO_B;
                    INGRESO_B: if (ejecutar) begin
                        estado_sig = CALCULANDO;
                        valid_next = 1'b1;
                    end
                    default: ;
                endcase
            end
        end
    end

    assign dividendo  = reg_a[6:0];
    assign divisor_b  = reg_b[4:0];
    assign estado_dbg = estado;

endmodule
