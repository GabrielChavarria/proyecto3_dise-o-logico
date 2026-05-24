
`timescale 1ns/1ps

module tb_decodificador_7seg;
    logic [3:0] bcd;
    logic [6:0] segmentos;
    int errores = 0;

    decodificador_7seg dut (
        .bcd       (bcd),
        .segmentos (segmentos)
    );

    // Patrones esperados (segun el case del modulo)
    logic [6:0] esperados [0:9];

    initial begin
        esperados[0] = 7'b0111111;
        esperados[1] = 7'b0000110;
        esperados[2] = 7'b1011011;
        esperados[3] = 7'b1001111;
        esperados[4] = 7'b1100110;
        esperados[5] = 7'b1101101;
        esperados[6] = 7'b1111101;
        esperados[7] = 7'b0000111;
        esperados[8] = 7'b1111111;
        esperados[9] = 7'b1101111;
    end

    task verificar(input [3:0] d, input [6:0] esp);
        bcd = d;
        #1;
        if (segmentos !== esp) begin
            $display("[FAIL] dig=%0d: esperado %b, obtenido %b", d, esp, segmentos);
            errores++;
        end else begin
            $display("[PASS] dig=%0d -> %b", d, segmentos);
        end
    endtask

    initial begin
        $dumpfile("tb_decodificador_7seg.vcd");
        $dumpvars(0, tb_decodificador_7seg);

        // Valores validos 0..9
        for (int i = 0; i <= 9; i++)
            verificar(i, esperados[i]);

        // Valores invalidos 10..15: deben apagar el display
        for (int i = 10; i <= 15; i++) begin
            bcd = i;
            #1;
            if (segmentos !== 7'b0000000) begin
                $display("[FAIL] dig=%0d (invalido): esperado apagado, obtenido %b",
                         i, segmentos);
                errores++;
            end else begin
                $display("[PASS] dig=%0d (invalido) -> apagado", i);
            end
        end

        $display("");
        if (errores == 0)
            $display("=== tb_decodificador_7seg: TODOS LOS TESTS PASARON ===");
        else
            $display("=== tb_decodificador_7seg: %0d FALLOS ===", errores);
        $finish;
    end
endmodule