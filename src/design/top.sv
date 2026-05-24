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

    // Delay de encendido para estabilizar el reloj (15 ciclos)
    logic        rst_n_int;
    logic [3:0]  rst_cnt = 4'd0;

    always_ff @(posedge clk_27mhz) begin
        if (!(&rst_cnt))
            rst_cnt <= rst_cnt + 1;
    end
    assign rst_n_int = (&rst_cnt) & reset_n;

    // Senales internas
    logic [3:0] cols_sync;
    logic       pulso_tick;
    logic [3:0] fila_cap, col_cap;
    logic       tecla_valida;

    logic [3:0] digito;
    logic       es_numero;
    logic       confirmar_a, ejecutar, limpiar, seleccionar;

    logic [6:0] dividendo;
    logic [4:0] divisor_b;
    logic       valid;
    logic [1:0] estado_dbg;

    logic [6:0] cociente;
    logic [4:0] residuo;
    logic       done;

    logic       sel_resultado;  // 0 = cociente, 1 = residuo
    logic [6:0] segs_internos;

    // Sincronizador de columnas del teclado
    sincronizador #(.BITS(4)) sync_cols (
        .clk         (clk_27mhz),
        .senal_async (in_col),
        .senal_sync  (cols_sync)
    );

    // Divisor de frecuencia 27 MHz -> 1 kHz
    divisor_frecuencia #(.N(27000)) div_tick (
        .clk   (clk_27mhz),
        .rst_n (rst_n_int),
        .pulso (pulso_tick)
    );

    // Barrido y debounce del teclado matricial
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

    // Decodificacion de teclas a comandos
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

    // FSM de ingreso de datos
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

    // Unidad de division de enteros con pipeline (latencia N+1 = 8 ciclos)
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

    // Toggle sel_resultado con tecla C (solo activo en estado RESULTADO)
    always_ff @(posedge clk_27mhz or negedge rst_n_int) begin
        if (!rst_n_int)
            sel_resultado <= 1'b0;
        else if (tecla_valida && seleccionar)
            sel_resultado <= ~sel_resultado;
        else if (tecla_valida && limpiar)
            sel_resultado <= 1'b0;
    end

    // Seleccion del numero a mostrar segun estado de la FSM
    logic [10:0] num_display;
    logic [3:0]  d_miles, d_cientos, d_decenas, d_unidades;
    logic [15:0] numero_bcd;

    always_comb begin
        case (estado_dbg)
            2'd0:    num_display = {4'b0, dividendo};                           // ingresando dividendo
            2'd1:    num_display = {6'b0, divisor_b};                           // ingresando divisor
            2'd2:    num_display = {4'b0, dividendo};                           // calculando: mantener dividendo
            2'd3:    num_display = sel_resultado ? {6'b0, residuo}              // resultado
                                                 : {4'b0, cociente};
            default: num_display = 11'd0;
        endcase

        d_miles    =  num_display / 11'd1000;
        d_cientos  = (num_display % 11'd1000) / 11'd100;
        d_decenas  = (num_display % 11'd100)  / 11'd10;
        d_unidades =  num_display % 11'd10;
    end

    assign numero_bcd = {d_miles, d_cientos, d_decenas, d_unidades};

    // Controlador multiplexado de displays de 7 segmentos
    controlador_displays ctrl_disp (
        .clk       (clk_27mhz),
        .rst_n     (rst_n_int),
        .pulso     (pulso_tick),
        .numero    (numero_bcd),
        .segmentos (segs_internos),
        .anodos    (anodos_out)
    );

    assign segmentos_out[6:0] = segs_internos;
    assign segmentos_out[7]   = 1'b0;  // punto decimal apagado

endmodule
