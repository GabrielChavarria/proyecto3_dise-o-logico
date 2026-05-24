
`timescale 1ns/1ps

module tb_sincronizador;
    logic clk;
    logic [3:0] async_in;
    logic [3:0] sync_out;
    int errores = 0;

    // Reloj de 27 MHz (periodo aprox 37 ns)
    initial clk = 0;
    always #18 clk = ~clk;

    sincronizador #(.BITS(4)) dut (
        .clk         (clk),
        .senal_async (async_in),
        .senal_sync  (sync_out)
    );

    task verificar(input [3:0] esperado, input string nombre);
        if (sync_out !== esperado) begin
            $display("[FAIL] %s: esperado %h, obtenido %h @ %0t",
                     nombre, esperado, sync_out, $time);
            errores++;
        end else begin
            $display("[PASS] %s: %h", nombre, sync_out);
        end
    endtask

    initial begin
        $dumpfile("tb_sincronizador.vcd");
        $dumpvars(0, tb_sincronizador);

        async_in = 4'h0;
        // Esperar a que se llenen los dos flip-flops
        repeat (3) @(posedge clk);
        #1; verificar(4'h0, "valor_inicial_0");

        // Cambio a 0xA: debe aparecer 2 ciclos despues
        @(negedge clk); async_in = 4'hA;
        @(posedge clk);                    // ff1 captura A
        #1;
        if (sync_out === 4'hA) begin
            $display("[FAIL] sincronizado en 1 ciclo (no hay retardo)");
            errores++;
        end else $display("[PASS] retardo > 1 ciclo respetado");

        @(posedge clk);                    // sync_out captura A
        #1; verificar(4'hA, "valor_A");

        // Cambio a 0x5
        @(negedge clk); async_in = 4'h5;
        @(posedge clk);
        @(posedge clk);
        #1; verificar(4'h5, "valor_5");

        // Cambio a 0xF
        @(negedge clk); async_in = 4'hF;
        @(posedge clk);
        @(posedge clk);
        #1; verificar(4'hF, "valor_F");

        // Vuelta a 0
        @(negedge clk); async_in = 4'h0;
        @(posedge clk);
        @(posedge clk);
        #1; verificar(4'h0, "valor_0_final");

        // Cambio rapido: la entrada vacila pero sync debe seguir
        @(negedge clk); async_in = 4'h3;
        @(posedge clk);
        @(negedge clk); async_in = 4'hC; // cambio antes de propagar
        @(posedge clk);
        @(posedge clk);
        #1; verificar(4'hC, "cambio_rapido_C");

        $display("");
        if (errores == 0)
            $display("=== tb_sincronizador: TODOS LOS TESTS PASARON ===");
        else
            $display("=== tb_sincronizador: %0d FALLOS ===", errores);
        $finish;
    end

    // Timeout de seguridad
    initial begin
        #5000;
        $display("[TIMEOUT] tb_sincronizador excedio limite");
        $finish;
    end
endmodule