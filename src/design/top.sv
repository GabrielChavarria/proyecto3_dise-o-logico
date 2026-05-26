// Top level: calculadora de division de enteros sin signo.
// Dividendo: max 63 (6 bits). Divisor: max 15 (4 bits).
// Teclas: A = confirmar dividendo, B = ejecutar, C = alternar cociente/residuo, D = limpiar.

module top (
    input  logic        clk_27mhz,
    input  logic        reset_n,

    input  logic [3:0]  in_col,
    output logic [3:0]  out_fil,

    output logic [7:0]  segmentos_out,
    output logic [3:0]  anodos_out
);

    logic        rst_n_int;
    logic [3:0]  cols_sync;
    logic        pulso_tick;
    logic [3:0]  fila_cap, col_cap;
    logic        tecla_valida;

    logic [3:0]  digito;
    logic        es_numero;
    logic        confirmar_a, ejecutar, limpiar, seleccionar;

    logic [6:0]  dividendo;
    logic [4:0]  divisor_b;
    logic        valid;
    logic [1:0]  estado_dbg;

    logic [6:0]  cociente;
    logic [4:0]  residuo;
    logic        done;

    logic [15:0] numero_bcd;

    generador_reset gen_rst (
        .clk      (clk_27mhz),
        .reset_n  (reset_n),
        .rst_n_int (rst_n_int)
    );

    sincronizador #(.BITS(4)) sync_cols (
        .clk         (clk_27mhz),
        .senal_async (in_col),
        .senal_sync  (cols_sync)
    );

    divisor_frecuencia #(.N(27000)) div_tick (
        .clk   (clk_27mhz),
        .rst_n (rst_n_int),
        .pulso (pulso_tick)
    );

    barrido_teclado barrido (
        .clk          (clk_27mhz),
        .rst_n        (rst_n_int),
        .pulso        (pulso_tick),
        .cols_sync    (cols_sync),
        .filas        (out_fil),
        .fila_cap     (fila_cap),
        .col_cap      (col_cap),
        .tecla_valida (tecla_valida)
    );

    decodificador_tecla deco_tecla (
        .fila_cap    (fila_cap),
        .col_cap     (col_cap),
        .digito      (digito),
        .es_numero   (es_numero),
        .confirmar_a (confirmar_a),
        .ejecutar    (ejecutar),
        .limpiar     (limpiar),
        .seleccionar (seleccionar)
    );

    fsm_entrada_datos fsm (
        .clk          (clk_27mhz),
        .rst_n        (rst_n_int),
        .tecla_valida (tecla_valida),
        .digito       (digito),
        .es_numero    (es_numero),
        .confirmar_a  (confirmar_a),
        .ejecutar     (ejecutar),
        .limpiar      (limpiar),
        .done         (done),
        .dividendo    (dividendo),
        .divisor_b    (divisor_b),
        .valid        (valid),
        .estado_dbg   (estado_dbg)
    );

    divisor_enteros #(.N(7), .M(5)) div_int (
        .clk       (clk_27mhz),
        .rst_n     (rst_n_int),
        .dividendo (dividendo),
        .divisor_b (divisor_b),
        .valid     (valid),
        .cociente  (cociente),
        .residuo   (residuo),
        .done      (done)
    );

    selector_display sel_disp (
        .clk          (clk_27mhz),
        .rst_n        (rst_n_int),
        .tecla_valida (tecla_valida),
        .seleccionar  (seleccionar),
        .limpiar      (limpiar),
        .estado_dbg   (estado_dbg),
        .dividendo    (dividendo),
        .divisor_b    (divisor_b),
        .cociente     (cociente),
        .residuo      (residuo),
        .numero_bcd   (numero_bcd)
    );

    controlador_displays ctrl_disp (
        .clk       (clk_27mhz),
        .rst_n     (rst_n_int),
        .pulso     (pulso_tick),
        .numero    (numero_bcd),
        .segmentos (segmentos_out[6:0]),
        .anodos    (anodos_out)
    );

    assign segmentos_out[7] = 1'b0;

endmodule
