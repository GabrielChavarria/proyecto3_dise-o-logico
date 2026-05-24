
`timescale 1ns/1ps

module tb_debounce;
    logic clk, rst_n, pulso, senal_in, senal_out;
    int errores = 0;

    debounce #(.TICKS(5)) dut (
        .clk      (clk),
        .rst_n    (rst_n),
        .pulso    (pulso),
        .senal_in (senal_in),
        .senal_out(senal_out)
    );

    initial clk = 0;
    always #18 clk = ~clk;

    // Genera un pulso de 1 ciclo de reloj
    task tick;
        @(negedge clk); pulso = 1;
        @(negedge clk); pulso = 0;
    endtask

    initial begin
        $dumpfile("tb_debounce.vcd");
        $dumpvars(0, tb_debounce);

        rst_n = 0; pulso = 0; senal_in = 1;
        repeat (3) @(posedge clk);
        #1;
        if (senal_out !== 1'b1) begin
            $display("[FAIL] estado inicial: senal_out=%b (esp 1)", senal_out);
            errores++;
        end else $display("[PASS] estado inicial = 1 (reposo)");

        @(negedge clk); rst_n = 1;

        // ----------- Test 1: presion estable (baja por 5 ticks) -----------
        senal_in = 0;
        repeat (5) tick();
        @(posedge clk); #1;
        if (senal_out !== 1'b0) begin
            $display("[FAIL] no detecto presion tras 5 pulsos. senal_out=%b", senal_out);
            errores++;
        end else $display("[PASS] presion detectada tras 5 pulsos");

        // ----------- Test 2: liberacion estable (sube por 5 ticks) -----------
        senal_in = 1;
        repeat (5) tick();
        @(posedge clk); #1;
        if (senal_out !== 1'b1) begin
            $display("[FAIL] no detecto liberacion tras 5 pulsos. senal_out=%b", senal_out);
            errores++;
        end else $display("[PASS] liberacion detectada tras 5 pulsos");

        // ----------- Test 3: glitch corto (rechazado) -----------
        senal_in = 0;
        repeat (3) tick();          // 3 < TICKS, aun no debe cambiar
        #1;
        if (senal_out !== 1'b1) begin
            $display("[FAIL] cambio con glitch de 3 pulsos. senal_out=%b", senal_out);
            errores++;
        end else $display("[PASS] glitch de 3 pulsos rechazado");

        // El glitch desaparece (vuelve a 1) antes de TICKS
        senal_in = 1;
        repeat (2) tick();
        #1;
        if (senal_out !== 1'b1) begin
            $display("[FAIL] cambio durante glitch corrupto"); errores++;
        end else $display("[PASS] salida estable ante glitch");

        // ----------- Test 4: presion con interrupcion intermedia -----------
        senal_in = 0;
        repeat (3) tick();
        senal_in = 1;               // interrupcion
        tick();
        senal_in = 0;               // vuelve a bajar, contador reinicia
        repeat (4) tick();          // todavia faltan
        #1;
        if (senal_out !== 1'b1) begin
            $display("[FAIL] cambio con interrupciones"); errores++;
        end else $display("[PASS] interrupciones reinician el contador");

        repeat (1) tick();          // 5to pulso estable, ahora si cambia
        @(posedge clk); #1;
        if (senal_out !== 1'b0) begin
            $display("[FAIL] no detecto presion tras estabilizacion"); errores++;
        end else $display("[PASS] presion detectada tras estabilizar");

        // ----------- Test 5: sin pulsos, no debe haber cambios -----------
        senal_in = 1;
        pulso = 0;
        repeat (50) @(posedge clk);   // muchos ciclos pero sin pulso
        #1;
        if (senal_out !== 1'b0) begin
            $display("[FAIL] cambio sin pulso"); errores++;
        end else $display("[PASS] sin pulso, sin cambio");

        $display("");
        if (errores == 0)
            $display("=== tb_debounce: TODOS LOS TESTS PASARON ===");
        else
            $display("=== tb_debounce: %0d FALLOS ===", errores);
        $finish;
    end

    initial begin
        #100000;
        $display("[TIMEOUT] tb_debounce");
        $finish;
    end
endmodule