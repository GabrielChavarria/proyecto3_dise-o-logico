`timescale 1ns/1ps

// Testbench directo del divisor de enteros con pipeline.
// Verifica que cociente y residuo son correctos tras N+1 ciclos de latencia.

module tb_divisor_enteros;

    localparam N = 7;
    localparam M = 5;
    localparam LATENCIA = N + 1;  // 8 ciclos

    logic        clk, rst_n;
    logic [N-1:0] dividendo;
    logic [M-1:0] divisor_b;
    logic         valid;
    logic [N-1:0] cociente;
    logic [M-1:0] residuo;
    logic         done;
    int           errores = 0;

    divisor_enteros #(.N(N), .M(M)) dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .dividendo (dividendo),
        .divisor_b (divisor_b),
        .valid     (valid),
        .cociente  (cociente),
        .residuo   (residuo),
        .done      (done)
    );

    initial clk = 0;
    always #18 clk = ~clk;

    // Envia operandos, espera exactamente LATENCIA+2 ciclos y verifica
    task dividir(input [N-1:0] a, input [M-1:0] b,
                 input [N-1:0] esp_coc, input [M-1:0] esp_res,
                 input string nombre);

        // Pulso valid de 1 ciclo
        @(negedge clk);
        dividendo = a;
        divisor_b = b;
        valid     = 1'b1;
        @(posedge clk);
        @(negedge clk);
        valid = 1'b0;

        // Esperar exactamente N ciclos: el resultado es valido cuando done=1
        repeat(N) @(posedge clk);
        #1;

        if (cociente !== esp_coc || residuo !== esp_res) begin
            $display("[FAIL] %0d / %0d = coc=%0d res=%0d  (esp coc=%0d res=%0d)",
                     a, b, cociente, residuo, esp_coc, esp_res);
            errores++;
        end else begin
            $display("[PASS] %0d / %0d = %0d  residuo %0d",
                     a, b, cociente, residuo);
        end
    endtask

    initial begin
        $dumpfile("tb_divisor_enteros.vcd");
        $dumpvars(0, tb_divisor_enteros);

        rst_n     = 0;
        valid     = 0;
        dividendo = 0;
        divisor_b = 0;

        repeat(4) @(posedge clk);
        @(negedge clk); rst_n = 1;
        repeat(2) @(posedge clk);

        $display("\n=== Divisor de enteros (N=%0d, M=%0d, latencia=%0d ciclos) ===\n",
                 N, M, LATENCIA);

        // Casos base
        dividir(7'd10,  5'd3,  7'd3,  5'd1,  "10  / 3");
        dividir(7'd63,  5'd7,  7'd9,  5'd0,  "63  / 7");
        dividir(7'd20,  5'd2,  7'd10, 5'd0,  "20  / 2");
        dividir(7'd1,   5'd1,  7'd1,  5'd0,  "1   / 1");
        dividir(7'd0,   5'd5,  7'd0,  5'd0,  "0   / 5");

        // Puntaje extra
        dividir(7'd127, 5'd31, 7'd4,  5'd3,  "127 / 31");
        dividir(7'd100, 5'd31, 7'd3,  5'd7,  "100 / 31");
        dividir(7'd127, 5'd1,  7'd127,5'd0,  "127 / 1");

        // Con residuo
        dividir(7'd17,  5'd5,  7'd3,  5'd2,  "17  / 5");
        dividir(7'd50,  5'd7,  7'd7,  5'd1,  "50  / 7");

        $display("");
        if (errores == 0)
            $display("=== tb_divisor_enteros: TODOS LOS TESTS PASARON ===");
        else
            $display("=== tb_divisor_enteros: %0d FALLOS ===", errores);
        $finish;
    end

    initial begin
        #100_000;
        $display("[TIMEOUT] tb_divisor_enteros");
        $finish;
    end

endmodule
