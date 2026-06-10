# Proyecto corto III — Diseño digital sincrónico en HDL

## Escuela de Ingeniería Electrónica
**Curso:** EL-3307 Diseño Lógico  
**Semestre:** I Semestre 2026  
**Profesor:** Oscar Caravaca

---
## Integrantes
- Gabriel Alonso Chavarría Rodriguez
- Alberto Javier Arce Estrada

---
## Abreviaturas y definiciones
- **FPGA**: Field Programmable Gate Arrays
- **HDL**: Hardware Description Language

---
## Herramientas Utilizadas
- **Descripción Hardware**: SystemVerilog

---
## Referencias
- [1] [Open Source FPGA Environment](https://github.com/DJosueMM/open_source_fpga_environment/wiki)
- [2] [TangNano 9K Wiki](https://wiki.sipeed.com/hardware/en/tang/Tang-Nano-9K/Nano-9K.html)

---

## 1. Introducción

El presente proyecto implementa una calculadora de división de enteros sin signo sobre una FPGA Tang Nano 9k utilizando SystemVerilog como lenguaje de descripción de hardware. El sistema captura el dividendo (0–127) y el divisor (0–31) desde un teclado hexadecimal físico, ejecuta la división mediante un pipeline de N+1 ciclos de latencia y despliega el cociente o el residuo en un display de 4 dígitos de 7 segmentos. Todo el diseño opera bajo los principios del diseño digital sincrónico, empleando un único reloj de 27 MHz y divisores de frecuencia para los subsistemas que requieren operación más lenta.

---

## 2. Definición del Problema, Objetivos y Especificaciones

### Problema
Se requiere diseñar un circuito digital sincrónico capaz de capturar dos números enteros positivos desde un teclado hexadecimal mecánico, calcular su división entera sin signo mediante un algoritmo con pipeline y desplegar el cociente y el residuo en cuatro dispositivos de 7 segmentos.

### Objetivos
- Implementar un algoritmo de captura de datos desde un teclado hexadecimal con eliminación de rebote
- Diseñar una FSM que controle el ingreso secuencial del dividendo y el divisor
- Implementar la división aritmética sin signo mediante un pipeline de N+1 etapas
- Desplegar el cociente o el residuo en displays de 7 segmentos mediante multiplexeo
- Verificar el diseño mediante simulaciones RTL (pre-síntesis)

### Especificaciones
- Frecuencia de reloj: **27 MHz** (oscilador interno TangNano 9k)
- Un solo dominio de reloj en todo el sistema
- Dividendo: hasta **7 bits** (0–127)
- Divisor: hasta **5 bits** (0–31)
- Latencia del pipeline: **N+1 = 8 ciclos**
- Display: 4 dígitos de 7 segmentos, cátodo común, multiplexeo a 1 kHz
- Teclado: hexadecimal 4x4, barrido fila-columna

---

## 3. Estructura del Proyecto

```text
proyecto3_diseño-logico
├── docs
│   └── Instrucciones_Proyecto_3.pdf
├── src
│   ├── build
│   │   └── Makefile
│   ├── constr
│   │   └── constraints.cst
│   ├── design
│   │   ├── top.sv
│   │   ├── generador_reset.sv
│   │   ├── divisor_frecuencia.sv
│   │   ├── sincronizador.sv
│   │   ├── debounce.sv
│   │   ├── barrido_teclado.sv
│   │   ├── decodificador_tecla.sv
│   │   ├── fsm_entrada_datos.sv
│   │   ├── divisor_enteros.sv
│   │   ├── selector_display.sv
│   │   ├── controlador_displays.sv
│   │   └── decodificador_7seg.sv
│   └── sim
│       ├── tb_top.sv
│       ├── tb_divisor_enteros.sv
│       ├── tb_fsm_entrada_datos.sv
│       ├── tb_decodificador_tecla.sv
│       ├── tb_barrido_teclado.sv
│       ├── tb_controlador_displays.sv
│       ├── tb_divisor_frecuencia.sv
│       ├── tb_sincronizador.sv
│       └── tb_debounce.sv
├── .gitignore
└── README.md
```

---

## Constraints — Asignación de Pines

### Display 5643AS-1 (cátodo común)
| Señal | Pin FPGA | Pin Display | Descripción |
|---|---|---|---|
| anodos_out[0] | 37 | 12 | Ánodo dígito 1 |
| anodos_out[1] | 26 | 9 | Ánodo dígito 2 |
| anodos_out[2] | 27 | 8 | Ánodo dígito 3 |
| anodos_out[3] | 34 | 6 | Ánodo dígito 4 |
| segmentos_out[0] | 36 | 11 | Segmento a |
| segmentos_out[1] | 25 | 7 | Segmento b |
| segmentos_out[2] | 30 | 4 | Segmento c |
| segmentos_out[3] | 29 | 2 | Segmento d |
| segmentos_out[4] | 28 | 1 | Segmento e |
| segmentos_out[5] | 39 | 10 | Segmento f |
| segmentos_out[6] | 33 | 5 | Segmento g |

### Teclado
| Señal | Pin FPGA | Terminal | Descripción |
|---|---|---|---|
| out_fil[0] | 51 | 1 | Fila 1 (1,2,3,A) |
| out_fil[1] | 53 | 2 | Fila 2 (4,5,6,B) |
| out_fil[2] | 54 | 3 | Fila 3 (7,8,9,C) |
| out_fil[3] | 55 | 4 | Fila 4 (*,0,#,D) |
| in_col[0] | 56 | 5 | Columna 1 (1,4,7,*) |
| in_col[1] | 57 | 6 | Columna 2 (2,5,8,0) |
| in_col[2] | 68 | 7 | Columna 3 (3,6,9,#) |
| in_col[3] | 69 | 8 | Columna 4 (A,B,C,D) |

---

## 4. Módulos

### Subsistema 1 — Lectura del Teclado Hexadecimal
- 1.1 [Módulo Generador Reset](https://github.com/GabrielChavarria/proyecto3_dise-o-logico/wiki/1.1-Modulo-generador-reset)
- 1.2 [Módulo Sincronizador](https://github.com/GabrielChavarria/proyecto3_dise-o-logico/wiki/1.2-Modulo-sincronizador)
- 1.3 [Módulo Debounce](https://github.com/GabrielChavarria/proyecto3_dise-o-logico/wiki/1.3-Modulo-debounce)
- 1.4 [Módulo Barrido Teclado](https://github.com/GabrielChavarria/proyecto3_dise-o-logico/wiki/1.4-Modulo-barrido-teclado)
- 1.5 [Módulo Decodificador Tecla](https://github.com/GabrielChavarria/proyecto3_dise-o-logico/wiki/1.5-Modulo-decodificador-tecla)
- 1.6 [Módulo FSM Entrada Datos](https://github.com/GabrielChavarria/proyecto3_dise-o-logico/wiki/1.6-Modulo-FSM-entrada-datos)

### Subsistema 2 — División de Enteros
- 2\. [Módulo Divisor Enteros](https://github.com/GabrielChavarria/proyecto3_dise-o-logico/wiki/2.-Modulo-divisor-enteros)

### Subsistema 3 — Display de 7 Segmentos
- 3\. [Módulo Divisor Frecuencia](https://github.com/GabrielChavarria/proyecto3_dise-o-logico/wiki/3.-Modulo-divisor-frecuencia)
- 3.1 [Módulo Decodificador 7seg](https://github.com/GabrielChavarria/proyecto3_dise-o-logico/wiki/3.1-Modulo-decodificador-7seg)
- 3.2 [Módulo Controlador Displays](https://github.com/GabrielChavarria/proyecto3_dise-o-logico/wiki/3.2-Modulo-controlador-displays)
- 3.3 [Módulo Selector Display](https://github.com/GabrielChavarria/proyecto3_dise-o-logico/wiki/3.3-Modulo-selector-display)
