
`timescale 1ns/1ps

module tb_barrido_teclado;
    logic clk, rst_n, pulso;
    logic [3:0] cols_sync;
    logic [3:0] filas;
    logic [3:0] fila_cap, col_cap;
    logic tecla_valida;
    int errores = 0;
    int eventos_tecla = 0;

   
    logic [3:0] tecla_fila;   // 4'hF = nada presionada
    logic [3:0] tecla_col;

    assign cols_sync = (tecla_fila == 4'hF) ? 4'hF :
                       (filas == tecla_fila) ? tecla_col : 4'hF;

    barrido_teclado dut (
        .clk          (clk),
        .rst_n        (rst_n),
        .pulso        (pulso),
        .cols_sync    (cols_sync),
        .filas        (filas),
        .fila_cap     (fila_cap),
        .col_cap      (col_cap),
        .tecla_valida (tecla_valida)
    );

    initial clk = 0;
    always #18 clk = ~clk;

    // Generador rapido de pulso: 1 ciclo de cada 2 (acelera la simulacion)
    int div_pulso = 0;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            div_pulso <= 0;
            pulso     <= 1'b0;
        end else if (div_pulso == 1) begin
            div_pulso <= 0;
            pulso     <= 1'b1;
        end else begin
            div_pulso <= div_pulso + 1;
            pulso     <= 1'b0;
        end
    end

    // Contador de eventos tecla_valida
    always @(posedge tecla_valida) eventos_tecla++;

    // Tarea para presionar una tecla y esperar la captura
    task presionar(input [3:0] fila, input [3:0] col,
                   input [3:0] esp_fila, input [3:0] esp_col,
                   input string nombre);
        int t_max;
        int eventos_antes;
        eventos_antes = eventos_tecla;

        @(negedge clk);
        tecla_fila = fila;
        tecla_col  = col;

        // Esperar a que se detecte la tecla
        t_max = 0;
        while (eventos_tecla == eventos_antes && t_max < 5000) begin
            @(posedge clk);
            t_max++;
        end

        if (eventos_tecla == eventos_antes) begin
            $display("[FAIL] %s: timeout esperando tecla_valida", nombre);
            errores++;
        end else if (fila_cap !== esp_fila || col_cap !== esp_col) begin
            $display("[FAIL] %s: fila_cap=%b col_cap=%b (esp %b, %b)",
                     nombre, fila_cap, col_cap, esp_fila, esp_col);
            errores++;
        end else begin
            $display("[PASS] %s: fila=%b col=%b", nombre, fila_cap, col_cap);
        end

        // Soltar la tecla y esperar tiempo de liberacion
        @(negedge clk);
        tecla_fila = 4'hF;
        tecla_col  = 4'hF;
        repeat (400) @(posedge clk);
    endtask

    // Verificar que el barrido de filas funciona correctamente
    task verificar_barrido;
        logic [3:0] secuencia_esperada [0:3];
        logic visto [0:3];
        secuencia_esperada[0] = 4'b1110;
        secuencia_esperada[1] = 4'b1101;
        secuencia_esperada[2] = 4'b1011;
        secuencia_esperada[3] = 4'b0111;
        for (int i = 0; i < 4; i++) visto[i] = 0;

        // Observar las filas durante un barrido completo
        for (int j = 0; j < 1000; j++) begin
            @(posedge clk);
            for (int i = 0; i < 4; i++)
                if (filas == secuencia_esperada[i]) visto[i] = 1;
        end

        for (int i = 0; i < 4; i++) begin
            if (!visto[i]) begin
                $display("[FAIL] fila %b nunca aparecio", secuencia_esperada[i]);
                errores++;
            end
        end
        if (visto[0] && visto[1] && visto[2] && visto[3])
            $display("[PASS] las 4 filas aparecen en el barrido");
    endtask

    initial begin
        $dumpfile("tb_barrido_teclado.vcd");
        $dumpvars(0, tb_barrido_teclado);

        rst_n = 0;
        tecla_fila = 4'hF;
        tecla_col  = 4'hF;
        repeat (10) @(posedge clk);
        @(negedge clk); rst_n = 1;

        // Tras reset, verificar fila inicial
        #1;
        if (filas !== 4'b1110) begin
            $display("[FAIL] fila inicial: %b (esp 1110)", filas);
            errores++;
        end else $display("[PASS] fila inicial = 1110");

        // Verificar que las 4 filas se ciclan
        verificar_barrido();

        // ===== Test de teclas en cada esquina del teclado =====
        $display("");
        $display("--- Presiones en distintas posiciones ---");

        // Tecla 1: fila 0, col 0
        presionar(4'b1110, 4'b1110, 4'b1110, 4'b1110, "tecla_1_(0,0)");

        // Tecla 6: fila 1, col 2
        presionar(4'b1101, 4'b1011, 4'b1101, 4'b1011, "tecla_6_(1,2)");

        // Tecla 9: fila 2, col 2
        presionar(4'b1011, 4'b1011, 4'b1011, 4'b1011, "tecla_9_(2,2)");

        // Tecla D: fila 3, col 3
        presionar(4'b0111, 4'b0111, 4'b0111, 4'b0111, "tecla_D_(3,3)");

        // Tecla A: fila 0, col 3
        presionar(4'b1110, 4'b0111, 4'b1110, 4'b0111, "tecla_A_(0,3)");

        // Tecla 5: fila 1, col 1 (centro)
        presionar(4'b1101, 4'b1101, 4'b1101, 4'b1101, "tecla_5_(1,1)");

        // ===== Test: tecla_valida es de un solo ciclo =====
        $display("");
        $display("--- Test tecla_valida = pulso unico ---");
        @(negedge clk);
        tecla_fila = 4'b1110;
        tecla_col  = 4'b1110;
        @(posedge tecla_valida);
        @(posedge clk);
        #1;
        if (tecla_valida !== 1'b0) begin
            $display("[FAIL] tecla_valida no es pulso unico");
            errores++;
        end else $display("[PASS] tecla_valida es pulso de 1 ciclo");

        // Soltar
        tecla_fila = 4'hF;
        tecla_col  = 4'hF;
        repeat (400) @(posedge clk);

        // ===== Test: tecla mantenida no genera multiples eventos rapidos =====
        $display("");
        $display("--- Test antirepeticion ---");
        eventos_tecla = 0;
        @(negedge clk);
        tecla_fila = 4'b1101;
        tecla_col  = 4'b1110;
        repeat (1500) @(posedge clk);   // mantener presionada largo rato
        #1;
        if (eventos_tecla !== 1) begin
            $display("[FAIL] tecla mantenida genero %0d eventos (esp 1)",
                     eventos_tecla);
            errores++;
        end else $display("[PASS] tecla mantenida = 1 evento");

        $display("");
        if (errores == 0)
            $display("=== tb_barrido_teclado: TODOS LOS TESTS PASARON ===");
        else
            $display("=== tb_barrido_teclado: %0d FALLOS ===", errores);
        $finish;
    end

    initial begin
        #5_000_000;
        $display("[TIMEOUT] tb_barrido_teclado");
        $finish;
    end
endmodule