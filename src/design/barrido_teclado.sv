module barrido_teclado (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       pulso,        // tick ~1 kHz del divisor_frecuencia
    input  logic [3:0] cols_sync,    // columnas sincronizadas (entradas, pull-up)
    output logic [3:0] filas,        // filas hacia el teclado (una activa en bajo)
    output logic [3:0] fila_cap,     // fila activa al detectar tecla (one-hot, activo bajo)
    output logic [3:0] col_cap,      // columna presionada     (one-hot, activo bajo)
    output logic       tecla_valida  // pulso de 1 ciclo: nueva tecla detectada
);

       // Señales internas
    logic [3:0] cols_db;
    logic       tecla_liberada;


    debounce #(.TICKS(20)) db_col0 (
        .clk      (clk),
        .rst_n    (rst_n),
        .pulso    (pulso),
        .senal_in (cols_sync[0]),
        .senal_out(cols_db[0])
    );

    debounce #(.TICKS(20)) db_col1 (
        .clk      (clk),
        .rst_n    (rst_n),
        .pulso    (pulso),
        .senal_in (cols_sync[1]),
        .senal_out(cols_db[1])
    );

    debounce #(.TICKS(20)) db_col2 (
        .clk      (clk),
        .rst_n    (rst_n),
        .pulso    (pulso),
        .senal_in (cols_sync[2]),
        .senal_out(cols_db[2])
    );

    debounce #(.TICKS(20)) db_col3 (
        .clk      (clk),
        .rst_n    (rst_n),
        .pulso    (pulso),
        .senal_in (cols_sync[3]),
        .senal_out(cols_db[3])
    );

    
    logic [1:0] estado_fil;
    localparam PULSES_PER_ROW = 50;
    logic [5:0] sub_cnt;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            estado_fil <= 2'd0;
            sub_cnt    <= 5'd0;
        end else if (pulso) begin
            if (sub_cnt == PULSES_PER_ROW - 1) begin
                sub_cnt    <= 5'd0;
                estado_fil <= estado_fil + 1;
            end else
                sub_cnt <= sub_cnt + 1;
        end
    end

    always_comb begin
        case (estado_fil)
            2'd0: filas = 4'b1110;
            2'd1: filas = 4'b1101;
            2'd2: filas = 4'b1011;
            2'd3: filas = 4'b0111;
            default: filas = 4'b1111;
        endcase
    end

    
    logic captura_en;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            captura_en <= 1'b0;
        else
            captura_en <= pulso && (sub_cnt == PULSES_PER_ROW - 2);
    end

    
    logic [5:0] release_cnt;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fila_cap       <= 4'hF;
            col_cap        <= 4'hF;
            tecla_valida   <= 1'b0;
            tecla_liberada <= 1'b1;
            release_cnt    <= 6'd0;
        end else begin
            tecla_valida <= 1'b0;

            // Contar pulsos donde la fila capturada esta activa y cols en reposo
            if (pulso) begin
                if ((filas == fila_cap) && (cols_db == 4'hF))
                    release_cnt <= release_cnt + 1;
                else
                    release_cnt <= 6'd0;
            end

            // Solo liberar despues de 25 pulsos estables (debounce completado)
            if (release_cnt >= 6'd25)
                tecla_liberada <= 1'b1;

            if (captura_en && (cols_db != 4'hF) && tecla_liberada) begin
                fila_cap       <= filas;
                col_cap        <= cols_db;
                tecla_valida   <= 1'b1;
                tecla_liberada <= 1'b0;
                release_cnt    <= 6'd0;
            end
        end
    end

endmodule