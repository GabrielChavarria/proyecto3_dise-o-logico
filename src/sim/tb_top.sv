`timescale 1ns/1ps

// Testbench de integracion del sistema completo de division de enteros.
// Emula el teclado matricial y verifica cociente, residuo y display.
//
// Mapa de teclas usado:
//   Numeros: fila/col segun decodificador_tecla.sv
//   A (confirmar dividendo): fila=1110, col=0111
//   B (ejecutar division):   fila=1101, col=0111
//   C (alternar resultado):  fila=1011, col=0111
//   D (limpiar):             fila=0111, col=0111

module tb_top;

    logic clk_27mhz;
    logic reset_n;
    logic [3:0] in_col;
    logic [3:0] out_fil;
    logic [7:0] segmentos_out;
    logic [3:0] anodos_out;
    int         errores = 0;

    // Emulacion del teclado: cuando out_fil coincide con la fila presionada,
    // devuelve la columna correspondiente. Si no hay tecla, devuelve 4'hF.
    logic [3:0] tecla_fila;
    logic [3:0] tecla_col;

    assign in_col = (tecla_fila == 4'hF) ? 4'hF :
                    (out_fil == tecla_fila) ? tecla_col : 4'hF;

    top dut (
        .clk_27mhz     (clk_27mhz),
        .reset_n       (reset_n),
        .in_col        (in_col),
        .out_fil       (out_fil),
        .segmentos_out (segmentos_out),
        .anodos_out    (anodos_out)
    );

    // Acelerar simulacion: divisor 27000->27 ciclos, debounce 20->5 pulsos
    defparam dut.div_tick.N            = 27;
    defparam dut.barrido.db_col0.TICKS = 5;
    defparam dut.barrido.db_col1.TICKS = 5;
    defparam dut.barrido.db_col2.TICKS = 5;
    defparam dut.barrido.db_col3.TICKS = 5;

    initial clk_27mhz = 0;
    always #18 clk_27mhz = ~clk_27mhz;

    // Presiona y suelta una tecla, espera confirmacion de tecla_valida
    task presionar(input [3:0] fila, input [3:0] col, input string nombre);
        int timeout_cnt;
        @(negedge clk_27mhz);
        tecla_fila  = fila;
        tecla_col   = col;
        timeout_cnt = 0;
        while (!dut.tecla_valida && timeout_cnt < 30000) begin
            @(posedge clk_27mhz);
            timeout_cnt++;
        end
        if (!dut.tecla_valida) begin
            $display("[FAIL] %s: timeout esperando tecla_valida", nombre);
            errores++;
        end else
            $display("[PASS] %s detectada @ %0t us", nombre, $time / 1000);
        @(posedge clk_27mhz);
        @(negedge clk_27mhz);
        tecla_fila = 4'hF;
        tecla_col  = 4'hF;
        repeat(15000) @(posedge clk_27mhz);  // esperar liberacion
    endtask

    // Espera hasta que done pulse o timeout
    task esperar_resultado;
        int timeout_cnt;
        timeout_cnt = 0;
        while (dut.estado_dbg !== 2'd3 && timeout_cnt < 1000) begin
            @(posedge clk_27mhz);
            timeout_cnt++;
        end
        if (dut.estado_dbg !== 2'd3) begin
            $display("[FAIL] timeout esperando RESULTADO"); errores++;
        end else
            $display("[PASS] RESULTADO alcanzado @ %0t us", $time / 1000);
    endtask

    initial begin
        $dumpfile("tb_top.vcd");
        $dumpvars(0, tb_top);

        reset_n    = 0;
        tecla_fila = 4'hF;
        tecla_col  = 4'hF;

        repeat(50) @(posedge clk_27mhz);
        @(negedge clk_27mhz); reset_n = 1;
        repeat(100) @(posedge clk_27mhz);

        // =====================================================================
        // Test 1: 63 / 7 = 9 residuo 0
        // =====================================================================
        $display("\n============================================================");
        $display("  Test 1: 63 / 7 = 9  residuo 0");
        $display("============================================================");

        presionar(4'b1101, 4'b1011, "tecla_6");  // 6
        presionar(4'b1110, 4'b1011, "tecla_3");  // 3

        if (dut.dividendo !== 7'd63) begin
            $display("[FAIL] dividendo=%0d (esp 63)", dut.dividendo); errores++;
        end else $display("[PASS] dividendo = 63");

        presionar(4'b1110, 4'b0111, "tecla_A");  // confirmar

        if (dut.estado_dbg !== 2'd1) begin
            $display("[FAIL] no paso a INGRESO_B, estado=%0d", dut.estado_dbg); errores++;
        end else $display("[PASS] paso a INGRESO_B");

        presionar(4'b1011, 4'b1110, "tecla_7");  // 7

        if (dut.divisor_b !== 5'd7) begin
            $display("[FAIL] divisor_b=%0d (esp 7)", dut.divisor_b); errores++;
        end else $display("[PASS] divisor_b = 7");

        presionar(4'b1101, 4'b0111, "tecla_B");  // ejecutar
        // CALCULANDO dura solo 8 ciclos de reloj, ya paso a RESULTADO
        esperar_resultado;

        if (dut.cociente !== 7'd9) begin
            $display("[FAIL] cociente=%0d (esp 9)", dut.cociente); errores++;
        end else $display("[PASS] cociente = 9");

        if (dut.residuo !== 5'd0) begin
            $display("[FAIL] residuo=%0d (esp 0)", dut.residuo); errores++;
        end else $display("[PASS] residuo = 0");

        if (anodos_out === 4'hF || anodos_out === 4'h0) begin
            $display("[FAIL] display inactivo: anodos=%b", anodos_out); errores++;
        end else $display("[PASS] display activo: anodos=%b", anodos_out);

        // Alternar con tecla C: cociente -> residuo -> cociente
        presionar(4'b1011, 4'b0111, "tecla_C (sel=residuo)");
        if (dut.sel_disp.sel_resultado !== 1'b1) begin
            $display("[FAIL] sel_resultado no cambio a 1"); errores++;
        end else $display("[PASS] sel_resultado = 1 (mostrando residuo)");

        presionar(4'b1011, 4'b0111, "tecla_C (sel=cociente)");
        if (dut.sel_disp.sel_resultado !== 1'b0) begin
            $display("[FAIL] sel_resultado no volvio a 0"); errores++;
        end else $display("[PASS] sel_resultado = 0 (mostrando cociente)");

        presionar(4'b0111, 4'b0111, "tecla_D (limpiar)");
        if (dut.estado_dbg !== 2'd0) begin
            $display("[FAIL] no volvio a INGRESO_A, estado=%0d", dut.estado_dbg); errores++;
        end else $display("[PASS] volvio a INGRESO_A");

        // =====================================================================
        // Test 2: 127 / 31 = 4 residuo 3  (puntaje extra)
        // =====================================================================
        $display("\n============================================================");
        $display("  Test 2: 127 / 31 = 4  residuo 3  (puntaje extra)");
        $display("============================================================");

        presionar(4'b1110, 4'b1110, "tecla_1");  // 1
        presionar(4'b1110, 4'b1101, "tecla_2");  // 2
        presionar(4'b1011, 4'b1110, "tecla_7");  // 7

        if (dut.dividendo !== 7'd127) begin
            $display("[FAIL] dividendo=%0d (esp 127)", dut.dividendo); errores++;
        end else $display("[PASS] dividendo = 127");

        presionar(4'b1110, 4'b0111, "tecla_A");

        presionar(4'b1110, 4'b1011, "tecla_3");  // 3
        presionar(4'b1110, 4'b1110, "tecla_1");  // 1

        if (dut.divisor_b !== 5'd31) begin
            $display("[FAIL] divisor_b=%0d (esp 31)", dut.divisor_b); errores++;
        end else $display("[PASS] divisor_b = 31");

        presionar(4'b1101, 4'b0111, "tecla_B");
        esperar_resultado;

        if (dut.cociente !== 7'd4) begin
            $display("[FAIL] cociente=%0d (esp 4)", dut.cociente); errores++;
        end else $display("[PASS] cociente = 4");

        if (dut.residuo !== 5'd3) begin
            $display("[FAIL] residuo=%0d (esp 3)", dut.residuo); errores++;
        end else $display("[PASS] residuo = 3");

        presionar(4'b0111, 4'b0111, "tecla_D (limpiar)");

        // =====================================================================
        // Test 3: 10 / 3 = 3 residuo 1
        // =====================================================================
        $display("\n============================================================");
        $display("  Test 3: 10 / 3 = 3  residuo 1");
        $display("============================================================");

        presionar(4'b1110, 4'b1110, "tecla_1");  // 1
        presionar(4'b0111, 4'b1101, "tecla_0");  // 0
        presionar(4'b1110, 4'b0111, "tecla_A");
        presionar(4'b1110, 4'b1011, "tecla_3");  // 3
        presionar(4'b1101, 4'b0111, "tecla_B");
        esperar_resultado;

        if (dut.cociente !== 7'd3) begin
            $display("[FAIL] 10/3: cociente=%0d (esp 3)", dut.cociente); errores++;
        end else $display("[PASS] 10/3: cociente = 3");

        if (dut.residuo !== 5'd1) begin
            $display("[FAIL] 10/3: residuo=%0d (esp 1)", dut.residuo); errores++;
        end else $display("[PASS] 10/3: residuo = 1");

        $display("\n============================================================");
        if (errores == 0)
            $display("  tb_top: TODOS LOS TESTS PASARON");
        else
            $display("  tb_top: %0d FALLOS", errores);
        $display("============================================================");
        $finish;
    end

    initial begin
        #500_000_000;
        $display("[TIMEOUT] tb_top - excedio tiempo limite");
        $finish;
    end

endmodule
