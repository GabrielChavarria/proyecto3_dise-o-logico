`timescale 1ns/1ps

module tb_decodificador_tecla;
    logic [3:0] fila_cap, col_cap;
    logic [3:0] digito;
    logic       es_numero, confirmar_a, ejecutar, limpiar, seleccionar;
    int         errores = 0;

    decodificador_tecla dut (
        .fila_cap    (fila_cap),
        .col_cap     (col_cap),
        .digito      (digito),
        .es_numero   (es_numero),
        .confirmar_a (confirmar_a),
        .ejecutar    (ejecutar),
        .limpiar     (limpiar),
        .seleccionar (seleccionar)
    );

    task verificar_num(input [3:0] f, input [3:0] c, input [3:0] esp_dig,
                       input string nombre);
        fila_cap = f; col_cap = c; #1;
        if (digito !== esp_dig || es_numero !== 1'b1 ||
            confirmar_a || ejecutar || limpiar || seleccionar) begin
            $display("[FAIL] %s: dig=%0d es_num=%b cf=%b ex=%b lp=%b sel=%b",
                     nombre, digito, es_numero, confirmar_a, ejecutar, limpiar, seleccionar);
            errores++;
        end else $display("[PASS] %s -> digito %0d", nombre, digito);
    endtask

    task verificar_cmd(input [3:0] f, input [3:0] c,
                       input bit esp_cf, esp_ex, esp_lp, esp_sel,
                       input string nombre);
        fila_cap = f; col_cap = c; #1;
        if (es_numero !== 1'b0 ||
            confirmar_a !== esp_cf || ejecutar  !== esp_ex  ||
            limpiar     !== esp_lp || seleccionar !== esp_sel) begin
            $display("[FAIL] %s: es_num=%b cf=%b ex=%b lp=%b sel=%b",
                     nombre, es_numero, confirmar_a, ejecutar, limpiar, seleccionar);
            errores++;
        end else $display("[PASS] %s", nombre);
    endtask

    task verificar_inactivo(input [3:0] f, input [3:0] c, input string nombre);
        fila_cap = f; col_cap = c; #1;
        if (es_numero || confirmar_a || ejecutar || limpiar || seleccionar || digito !== 4'd0) begin
            $display("[FAIL] %s: salidas activas indebidamente", nombre);
            errores++;
        end else $display("[PASS] %s -> inactivo", nombre);
    endtask

    initial begin
        $dumpfile("tb_decodificador_tecla.vcd");
        $dumpvars(0, tb_decodificador_tecla);

        // Fila 0 (fila_cap=1110): 1, 2, 3, A
        verificar_num(4'b1110, 4'b1110, 4'd1, "tecla_1");
        verificar_num(4'b1110, 4'b1101, 4'd2, "tecla_2");
        verificar_num(4'b1110, 4'b1011, 4'd3, "tecla_3");
        verificar_cmd(4'b1110, 4'b0111, 1, 0, 0, 0, "tecla_A_(confirmar)");

        // Fila 1 (fila_cap=1101): 4, 5, 6, B
        verificar_num(4'b1101, 4'b1110, 4'd4, "tecla_4");
        verificar_num(4'b1101, 4'b1101, 4'd5, "tecla_5");
        verificar_num(4'b1101, 4'b1011, 4'd6, "tecla_6");
        verificar_cmd(4'b1101, 4'b0111, 0, 1, 0, 0, "tecla_B_(ejecutar)");

        // Fila 2 (fila_cap=1011): 7, 8, 9, C
        verificar_num(4'b1011, 4'b1110, 4'd7, "tecla_7");
        verificar_num(4'b1011, 4'b1101, 4'd8, "tecla_8");
        verificar_num(4'b1011, 4'b1011, 4'd9, "tecla_9");
        verificar_cmd(4'b1011, 4'b0111, 0, 0, 0, 1, "tecla_C_(seleccionar)");

        // Fila 3 (fila_cap=0111): *, 0, #, D
        verificar_inactivo(4'b0111, 4'b1110, "tecla_*_(sin_asignar)");
        verificar_num     (4'b0111, 4'b1101, 4'd0, "tecla_0");
        verificar_inactivo(4'b0111, 4'b1011, "tecla_#_(sin_asignar)");
        verificar_cmd     (4'b0111, 4'b0111, 0, 0, 1, 0, "tecla_D_(limpiar)");

        // Reposo y combinacion invalida
        verificar_inactivo(4'b1111, 4'b1111, "reposo_total");
        verificar_inactivo(4'b0000, 4'b0000, "todas_activas");

        $display("");
        if (errores == 0)
            $display("=== tb_decodificador_tecla: TODOS LOS TESTS PASARON ===");
        else
            $display("=== tb_decodificador_tecla: %0d FALLOS ===", errores);
        $finish;
    end

endmodule
