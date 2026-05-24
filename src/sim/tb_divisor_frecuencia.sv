
`timescale 1ns/1ps

module tb_divisor_frecuencia;
    logic clk;
    logic rst_n;
    logic pulso;
    int errores = 0;
    int pulse_count = 0;

    // Reloj de 27 MHz
    initial clk = 0;
    always #18 clk = ~clk;

    divisor_frecuencia #(.N(10)) dut (
        .clk   (clk),
        .rst_n (rst_n),
        .pulso (pulso)
    );

    // Contador automatico de pulsos (sobre flanco de subida del pulso, evita race)
    always @(posedge pulso) pulse_count++;

    initial begin
        $dumpfile("tb_divisor_frecuencia.vcd");
        $dumpvars(0, tb_divisor_frecuencia);

        rst_n = 0;
        repeat (3) @(posedge clk);
        #1;
        if (pulso !== 1'b0) begin
            $display("[FAIL] pulso debe ser 0 en reset, es %b", pulso);
            errores++;
        end else $display("[PASS] pulso = 0 durante reset");

        @(negedge clk);
        rst_n = 1;

        // Verificar que el pulso no aparece antes de tiempo
        for (int i = 0; i < 9; i++) begin
            @(posedge clk);
            #1;
            if (pulso) begin
                $display("[FAIL] pulso temprano en ciclo %0d", i+1);
                errores++;
            end
        end

        // Ciclo 10 -> debe aparecer pulso
        @(posedge clk);
        #1;
        if (!pulso) begin
            $display("[FAIL] pulso no aparecio en ciclo N=10");
            errores++;
        end else $display("[PASS] pulso aparecio en ciclo N=10");

        // Verificar que dura un solo ciclo
        @(posedge clk);
        #1;
        if (pulso) begin
            $display("[FAIL] pulso dura mas de un ciclo");
            errores++;
        end else $display("[PASS] pulso de exactamente 1 ciclo");

        // Contar pulsos en 100 ciclos: debe haber 10
        pulse_count = 0;
        repeat (100) @(posedge clk);
        #1;
        if (pulse_count != 10) begin
            $display("[FAIL] esperado 10 pulsos en 100 ciclos, obtenido %0d", pulse_count);
            errores++;
        end else $display("[PASS] 10 pulsos en 100 ciclos");

        // Reset en medio: pulso debe bajar
        @(negedge clk); rst_n = 0;
        @(posedge clk);
        #1;
        if (pulso !== 1'b0) begin
            $display("[FAIL] pulso no se limpio con reset");
            errores++;
        end else $display("[PASS] reset asincronico limpia pulso");

        @(negedge clk); rst_n = 1;

        // Tras el reset, contar otra vez
        pulse_count = 0;
        repeat (50) @(posedge clk);
        #1;
        if (pulse_count != 5) begin
            $display("[FAIL] esperado 5 pulsos en 50 ciclos tras reset, obtenido %0d", pulse_count);
            errores++;
        end else $display("[PASS] 5 pulsos en 50 ciclos tras reset");

        $display("");
        if (errores == 0)
            $display("=== tb_divisor_frecuencia: TODOS LOS TESTS PASARON ===");
        else
            $display("=== tb_divisor_frecuencia: %0d FALLOS ===", errores);
        $finish;
    end

    initial begin
        #50000;
        $display("[TIMEOUT] tb_divisor_frecuencia");
        $finish;
    end
endmodule