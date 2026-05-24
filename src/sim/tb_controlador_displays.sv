
`timescale 1ns/1ps

module tb_controlador_displays;
    logic clk, rst_n, pulso;
    logic [15:0] numero;
    logic [6:0]  segmentos;
    logic [3:0]  anodos;
    int errores = 0;

    controlador_displays dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .pulso     (pulso),
        .numero    (numero),
        .segmentos (segmentos),
        .anodos    (anodos)
    );

    initial clk = 0;
    always #18 clk = ~clk;

    // Patrones esperados del decodificador
    logic [6:0] segs_esperados [0:9];

    initial begin
        segs_esperados[0] = 7'b0111111;
        segs_esperados[1] = 7'b0000110;
        segs_esperados[2] = 7'b1011011;
        segs_esperados[3] = 7'b1001111;
        segs_esperados[4] = 7'b1100110;
        segs_esperados[5] = 7'b1101101;
        segs_esperados[6] = 7'b1111101;
        segs_esperados[7] = 7'b0000111;
        segs_esperados[8] = 7'b1111111;
        segs_esperados[9] = 7'b1101111;
    end

    task tick;
        @(negedge clk); pulso = 1;
        @(negedge clk); pulso = 0;
    endtask

    task verificar_digito(input [3:0] anodo_esp, input [3:0] bcd_esp,
                          input string nombre);
        #1;
        if (anodos !== anodo_esp) begin
            $display("[FAIL] %s: anodos=%b (esp %b)", nombre, anodos, anodo_esp);
            errores++;
        end else if (segmentos !== segs_esperados[bcd_esp]) begin
            $display("[FAIL] %s: segmentos=%b (esp %b para BCD=%0d)",
                     nombre, segmentos, segs_esperados[bcd_esp], bcd_esp);
            errores++;
        end else begin
            $display("[PASS] %s: anodo %b, BCD %0d", nombre, anodos, bcd_esp);
        end
    endtask

    initial begin
        $dumpfile("tb_controlador_displays.vcd");
        $dumpvars(0, tb_controlador_displays);

        rst_n = 0;
        pulso = 0;
        // Numero 1234: miles=1, cientos=2, decenas=3, unidades=4
        numero = 16'h1234;
        repeat (3) @(posedge clk);
        @(negedge clk); rst_n = 1;
        @(posedge clk);

        // Tras reset: digito_activo=0 -> muestra miles (1) en anodo 1110
        verificar_digito(4'b1110, 4'd1, "post_reset_miles");

        // Avanza a digito 1: cientos (2) en anodo 1101
        tick();
        verificar_digito(4'b1101, 4'd2, "cientos");

        // Avanza a digito 2: decenas (3) en anodo 1011
        tick();
        verificar_digito(4'b1011, 4'd3, "decenas");

        // Avanza a digito 3: unidades (4) en anodo 0111
        tick();
        verificar_digito(4'b0111, 4'd4, "unidades");

        // Wrap-around: vuelve a miles
        tick();
        verificar_digito(4'b1110, 4'd1, "wrap_a_miles");

        // Cambio dinamico del numero a 9876
        numero = 16'h9876;
        tick();  // cientos = 8
        verificar_digito(4'b1101, 4'd8, "cambio_numero_cientos_8");

        tick();  // decenas = 7
        verificar_digito(4'b1011, 4'd7, "cambio_numero_decenas_7");

        tick();  // unidades = 6
        verificar_digito(4'b0111, 4'd6, "cambio_numero_unidades_6");

        tick();  // wrap a miles = 9
        verificar_digito(4'b1110, 4'd9, "cambio_numero_miles_9");

        // Numero con ceros y con valores invalidos (>= 10) en BCD
        numero = 16'h0007;  // solo unidades, resto en 0
        repeat (3) tick();  // ciclar de miles (0) a unidades (3)

        #1;
        if (anodos !== 4'b0111) begin
            $display("[FAIL] unidades_solo: anodos=%b", anodos); errores++;
        end else if (segmentos !== segs_esperados[7]) begin
            $display("[FAIL] unidades_solo: segmentos no muestran 7"); errores++;
        end else $display("[PASS] numero 0007: unidades muestran 7");

        // Sin pulso, no debe avanzar
        pulso = 0;
        repeat (20) @(posedge clk);
        #1;
        if (anodos !== 4'b0111) begin
            $display("[FAIL] sin pulso, anodos cambiaron: %b", anodos);
            errores++;
        end else $display("[PASS] sin pulso, digito_activo se mantiene");

        $display("");
        if (errores == 0)
            $display("=== tb_controlador_displays: TODOS LOS TESTS PASARON ===");
        else
            $display("=== tb_controlador_displays: %0d FALLOS ===", errores);
        $finish;
    end

    initial begin
        #100000;
        $display("[TIMEOUT] tb_controlador_displays");
        $finish;
    end
endmodule