`timescale 1ns/1ps

// Testbench de la FSM de entrada de datos para el divisor de enteros.
// Prueba: ingreso de dividendo (max 127) y divisor (max 31), limites,
// rechazo de digitos excedentes, pulso valid y transicion por done.

module tb_fsm_entrada_datos;

    logic       clk;
    logic       rst_n;
    logic       tecla_valida;
    logic [3:0] digito;
    logic       es_numero, confirmar_a, ejecutar, limpiar;
    logic       done;
    logic [6:0] dividendo;
    logic [4:0] divisor_b;
    logic       valid;
    logic [1:0] estado_dbg;
    int         errores = 0;

    localparam INGRESO_A  = 2'd0;
    localparam INGRESO_B  = 2'd1;
    localparam CALCULANDO = 2'd2;
    localparam RESULTADO  = 2'd3;

    fsm_entrada_datos dut (
        .clk          (clk),
        .rst_n        (rst_n),
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

    initial clk = 0;
    always #18 clk = ~clk;  // ~27 MHz

    // Presiona una tecla numerica durante un ciclo
    task enviar_digito(input [3:0] d);
        @(negedge clk);
        digito = d; es_numero = 1; tecla_valida = 1;
        @(posedge clk);
        @(negedge clk);
        tecla_valida = 0; es_numero = 0;
    endtask

    // Envia un comando (confirmar/ejecutar/limpiar) durante un ciclo
    task enviar_cmd(input bit cf, ex, lp);
        @(negedge clk);
        confirmar_a = cf; ejecutar = ex; limpiar = lp; tecla_valida = 1;
        @(posedge clk);
        @(negedge clk);
        tecla_valida = 0; confirmar_a = 0; ejecutar = 0; limpiar = 0;
    endtask

    // Simula pulso done de un ciclo (como lo daria divisor_enteros)
    task simular_done;
        @(negedge clk);
        done = 1;
        @(posedge clk);
        @(negedge clk);
        done = 0;
    endtask

    task check_estado(input [1:0] esp, input string nombre);
        if (estado_dbg !== esp) begin
            $display("[FAIL] %s: estado=%0d (esp %0d)", nombre, estado_dbg, esp);
            errores++;
        end else $display("[PASS] %s", nombre);
    endtask

    initial begin
        $dumpfile("tb_fsm_entrada_datos.vcd");
        $dumpvars(0, tb_fsm_entrada_datos);

        rst_n = 0; done = 0;
        tecla_valida = 0; digito = 0; es_numero = 0;
        confirmar_a  = 0; ejecutar = 0; limpiar   = 0;

        repeat(3) @(posedge clk); #1;
        check_estado(INGRESO_A, "reset -> INGRESO_A");
        if (dividendo !== 0 || divisor_b !== 0) begin
            $display("[FAIL] reset: operandos no en 0"); errores++;
        end else $display("[PASS] reset: dividendo=0, divisor_b=0");

        @(negedge clk); rst_n = 1;

        // =====================================================================
        // Test 1: 63 / 7 = 9 residuo 0
        // =====================================================================
        $display("\n--- Test 1: ingreso 63 / 7 ---");

        enviar_digito(6);
        #1;
        if (dividendo !== 7'd6) begin
            $display("[FAIL] dividendo=%0d (esp 6)", dividendo); errores++;
        end else $display("[PASS] dividendo = 6");

        enviar_digito(3);
        #1;
        if (dividendo !== 7'd63) begin
            $display("[FAIL] dividendo=%0d (esp 63)", dividendo); errores++;
        end else $display("[PASS] dividendo = 63");
        check_estado(INGRESO_A, "sigue en INGRESO_A");

        // 63*10+5 = 635 > 127 -> debe rechazarse
        enviar_digito(5);
        #1;
        if (dividendo !== 7'd63) begin
            $display("[FAIL] digito excedente aceptado: dividendo=%0d (esp 63)", dividendo); errores++;
        end else $display("[PASS] digito excedente rechazado, dividendo=63");

        enviar_cmd(1, 0, 0);  // confirmar A
        #1;
        check_estado(INGRESO_B, "tras A -> INGRESO_B");

        enviar_digito(7);
        #1;
        if (divisor_b !== 5'd7) begin
            $display("[FAIL] divisor_b=%0d (esp 7)", divisor_b); errores++;
        end else $display("[PASS] divisor_b = 7");

        // Ejecutar B: valid debe activarse 1 ciclo y pasar a CALCULANDO
        enviar_cmd(0, 1, 0);
        // En este punto: posedge ya ocurrio, valid=1, estado=CALCULANDO
        #1;
        check_estado(CALCULANDO, "tras B -> CALCULANDO");
        if (valid !== 1'b1) begin
            $display("[FAIL] valid no se activo al ejecutar"); errores++;
        end else $display("[PASS] valid = 1 (pulso activo)");

        @(posedge clk); #1;
        if (valid !== 1'b0) begin
            $display("[FAIL] valid no volvio a 0"); errores++;
        end else $display("[PASS] valid = 0 (pulso de 1 ciclo correcto)");

        simular_done;
        #1;
        check_estado(RESULTADO, "tras done -> RESULTADO");

        // =====================================================================
        // Test 2: rechazo de divisor > 31
        // =====================================================================
        $display("\n--- Test 2: rechazo divisor > 31 ---");

        enviar_cmd(0, 0, 1);  // limpiar
        #1;
        check_estado(INGRESO_A, "limpiar -> INGRESO_A");
        if (dividendo !== 0 || divisor_b !== 0) begin
            $display("[FAIL] limpiar no borro operandos"); errores++;
        end else $display("[PASS] limpiar borro operandos");

        enviar_digito(1); enviar_digito(0);  // dividendo = 10
        enviar_cmd(1, 0, 0);

        enviar_digito(3); enviar_digito(1);  // divisor = 31
        #1;
        if (divisor_b !== 5'd31) begin
            $display("[FAIL] divisor_b=%0d (esp 31)", divisor_b); errores++;
        end else $display("[PASS] divisor_b = 31 (maximo puntaje extra)");

        // 31*10+2 = 312 > 31 -> debe rechazarse
        enviar_digito(2);
        #1;
        if (divisor_b !== 5'd31) begin
            $display("[FAIL] divisor excedente aceptado: divisor_b=%0d (esp 31)", divisor_b); errores++;
        end else $display("[PASS] divisor excedente rechazado, divisor_b=31");

        // =====================================================================
        // Test 3: dividendo maximo 127 (puntaje extra)
        // =====================================================================
        $display("\n--- Test 3: dividendo maximo 127 (puntaje extra) ---");

        enviar_cmd(0, 0, 1);  // limpiar
        enviar_digito(1); enviar_digito(2); enviar_digito(7);  // 127
        #1;
        if (dividendo !== 7'd127) begin
            $display("[FAIL] dividendo=%0d (esp 127)", dividendo); errores++;
        end else $display("[PASS] dividendo = 127 (maximo puntaje extra)");

        // 127*10+1 = 1271 > 127 -> rechazado
        enviar_digito(1);
        #1;
        if (dividendo !== 7'd127) begin
            $display("[FAIL] digito excedente aceptado tras 127"); errores++;
        end else $display("[PASS] digito excedente rechazado tras 127");

        enviar_cmd(1, 0, 0);
        enviar_digito(3); enviar_digito(1);  // divisor = 31
        enviar_cmd(0, 1, 0);
        #1;
        check_estado(CALCULANDO, "127/31 -> CALCULANDO");
        simular_done;
        #1;
        check_estado(RESULTADO, "127/31 -> RESULTADO");

        // =====================================================================
        // Test 4: limpiar desde INGRESO_B
        // =====================================================================
        $display("\n--- Test 4: limpiar desde INGRESO_B ---");

        enviar_cmd(0, 0, 1);
        enviar_digito(5);
        enviar_cmd(1, 0, 0);
        check_estado(INGRESO_B, "en INGRESO_B antes de limpiar");
        enviar_cmd(0, 0, 1);
        #1;
        check_estado(INGRESO_A, "limpiar desde INGRESO_B -> INGRESO_A");
        if (dividendo !== 0 || divisor_b !== 0) begin
            $display("[FAIL] limpiar no borro operandos desde INGRESO_B"); errores++;
        end else $display("[PASS] operandos borrados correctamente");

        // =====================================================================
        // Test 5: tecla_valida=0 no causa cambios
        // =====================================================================
        $display("\n--- Test 5: tecla_valida=0 no causa cambios ---");

        @(negedge clk);
        digito = 9; es_numero = 1; tecla_valida = 0;
        repeat(5) @(posedge clk);
        #1;
        check_estado(INGRESO_A, "sin tecla_valida sigue en INGRESO_A");
        if (dividendo !== 0) begin
            $display("[FAIL] cambio sin tecla_valida"); errores++;
        end else $display("[PASS] sin tecla_valida, dividendo no cambia");
        @(negedge clk); es_numero = 0;

        $display("");
        if (errores == 0)
            $display("=== tb_fsm_entrada_datos: TODOS LOS TESTS PASARON ===");
        else
            $display("=== tb_fsm_entrada_datos: %0d FALLOS ===", errores);
        $finish;
    end

    initial begin
        #200_000;
        $display("[TIMEOUT] tb_fsm_entrada_datos");
        $finish;
    end

endmodule
