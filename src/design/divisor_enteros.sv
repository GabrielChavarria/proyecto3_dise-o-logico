
// implementa el algoritmo iterativo de la seccion 5.7.2 Harris y Harris

// con un registro entre cada etapa para cortar el camino critico.

// latencia: N+1 ciclos de reloj desde valid hasta done.



module divisor_enteros #(  // el #( indica que tendra parametros configurables 

    parameter N = 6,  // define el parametro N que representa el numero de bits del dividendo, por defecto vale 6
    parameter M = 4   // define el parametro N que representa el numero de bits del divisor, por defecto es 4
)(//  comienza la lista de puertos del modulo 
    input  logic         clk,//todos los registros se actualizan en el flanco postivo de esta señal
    input  logic         rst_n,// señal de reset activo en bajo, cuando vale cero reinicia los registros
    input  logic [N-1:0] dividendo,//contiene el numero que se desea divivir
    input  logic [M-1:0] divisor_b,//entrada que contiene el divisor 
    input  logic         valid,    // señál que indica que los operandos de entrada son validos y pueden ser capturados
    output logic [N-1:0] cociente,//salida donde aparecera el cociente final de la division 
    output logic [M-1:0] residuo,//salida donde saldra el residuo final
    output logic         done      // indica que el resultrado de la division esta disponible o no 
);

    // Registros de pipeline: indice 0 = entrada registrada, indice N = salida
    //registros que almacenan 
    logic [M-1:0] r_pipe [0:N];   // residuo parcial
    logic [N-1:0] q_pipe [0:N];   // cociente acumulado
    logic [M-1:0] b_pipe [0:N];   // divisor propagado
    logic [N-1:0] a_pipe [0:N];   // dividendo propagado
    logic         v_pipe [0:N];   // valid propagado

 //primera etapa 
    
    always_ff @(posedge clk or negedge rst_n) begin//bloque secuencial que se jecuta en el flanco positivo del reloh o cuando se activa el reset 
        if (!rst_n) begin//revisa si el reset esta activo
            r_pipe[0] <= '0;// inicializa el residuo parcial de la etapa 0 a cero
            q_pipe[0] <= '0;//inicializa el cociente acumulado de cero
            b_pipe[0] <= '0;//borra el divisor alamcenado
            a_pipe[0] <= '0;//borra el dividendo almacenado
            v_pipe[0] <= 1'b0;// indica que no hay datos validos en la etapa 0
        end else begin
            r_pipe[0] <= '0;       // residuo parcial inicial = 0
            q_pipe[0] <= '0;       // cociente inicial = 0
            b_pipe[0] <= divisor_b;//guarda el divisor recibido en la primera etapa de pipeline
            a_pipe[0] <= dividendo;//guarda el dividendo recibido
            v_pipe[0] <= valid;//guarda la señal que indica si la entrada es valida 
        end
    end



// importante 
  
    genvar i;// delara una vairable de generacion lalamda i, esta solo se usa pdurante la sintesis para crear multiples copias del hardware
    generate// indica el inicio de un bloque de generacion
        for (i = 0; i < N; i++) begin : etapa// crea automaticamente N etapas del pipeline.Cada etapa procesa un bitr del dividendo 
            logic [M-1:0] r_shift;// senal temporal, alamcenara el residuo parcial despues de desplazarlo una posicion a la izquierda e insertar el siguiente bit del dividendo
            logic [M:0]   sub;//otra señal temporal para almacenar el resultado de la resta, tiene un bit adicional porque es necsario detectar si ocurrio "borrow"
            logic         q_bit;//señal que contendra el siguiente bit del cociente
            logic [M-1:0] r_next;// señal que alcenara el nuevo residuo parcial

            // corre el residuo parcial a la izquierda e inserta el bit actual del dividendo
            assign r_shift = {r_pipe[i][M-2:0], a_pipe[i][N-1-i]};

            // resta R - B; sub[M]=1 indica borrow (R < B)
            assign sub    = {1'b0, r_shift} - {1'b0, b_pipe[i]};

            // Q_i = 1 si R >= B (sin borrow), segun el algoritmo
            assign q_bit  = ~sub[M];

            // proximo residuo parcial: D si R>=B, R si R<B
            assign r_next = q_bit ? sub[M-1:0] : r_shift;

            always_ff @(posedge clk or negedge rst_n) begin// un bloque secuancial que s eejecuta cada vez que ocirre un flanco positivo del reloj 
                if (!rst_n) begin
                    r_pipe[i+1] <= '0;//limpia el residuo parcial almacenado en la etapa siguiente del pipeline
                    q_pipe[i+1] <= '0;//borra el cociente parcial de la siguiente etapa
                    b_pipe[i+1] <= '0;//borra el valor del divisor almacenado en la siguiente etapa 
                    a_pipe[i+1] <= '0;//borra el dividendo almacenado en la siguiente etapa
                    v_pipe[i+1] <= 1'b0;//indica que no hay informacion valida en la siguiente etapa del pipeline
                end else begin
                    r_pipe[i+1] <= r_next;
                    // Acumula bits del cociente: MSB primero -> queda en posicion correcta
                    q_pipe[i+1] <= {q_pipe[i][N-2:0], q_bit}; //construye el cociente de manera progresiva, 
                    //toma el cociente parcial proveniente de la etapa anterior , lo desplaza de posicion y agrega el nuevo bit del cociente calculado en esta etapa
                    b_pipe[i+1] <= b_pipe[i];//copia el divisor hacia la siguiente erapa del pipeline ya que todas las etapas necesitan usar el mismo divisor 
                    a_pipe[i+1] <= a_pipe[i];//propaga el dividendo a la siguiente etapa para que pueda extraerse el bit correspondiente en las etapas anteriores 
                    v_pipe[i+1] <= v_pipe[i];//propaga la señal de validez para indicar que datos son validos a medida que avanzan por el pipeline 
                end
            end
        end
    endgenerate

    assign cociente = q_pipe[N];
    assign residuo  = r_pipe[N];
    assign done     = v_pipe[N];

endmodule
