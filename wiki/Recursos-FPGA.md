# Recursos FPGA

## Herramientas
- **Síntesis**: Yosys 0.26+1
- **Place and Route**: nextpnr-gowin
- **Dispositivo**: GW1NR-LV9QN88PC6/I5 (TangNano 9k)

## Consumo de recursos (síntesis)

### LUTs y MUX

| Tipo | Cantidad |
|---|---|
| LUT1 | 1084 |
| LUT2 | 262 |
| LUT3 | 240 |
| LUT4 | 72 |
| MUX2\_LUT5 | 615 |
| MUX2\_LUT6 | 298 |
| MUX2\_LUT7 | 143 |
| MUX2\_LUT8 | 63 |
| **Total LUT/MUX** | **2777** |

### Otros recursos

| Recurso | Utilizado | Disponible | Porcentaje |
|---|---|---|---|
| DFF (total) | 227 | 6693 | ~3.4% |
| BSRAM | 0 | 26 | 0% |
| DSP | 0 | 20 | 0% |
| Wires | 2773 | — | — |
| Celdas totales | 3758 | — | — |

> **Nota:** El total de DFFs incluye: DFF(8) + DFFC(150) + DFFCE(51) + DFFE(4) + DFFP(1) + DFFPE(13) = 227.
> El alto número de DFFs y LUTs respecto al Proyecto 2 se debe principalmente al pipeline del `divisor_enteros` (N+1 = 8 etapas × múltiples registros por etapa).

## Distribución de pines utilizados

| Grupo | Pines |
|---|---|
| Display segmentos | 8 (7 seg + punto decimal) |
| Display ánodos | 4 |
| Teclado filas | 4 |
| Teclado columnas | 4 |
| Reloj | 1 |
| Reset (S1) | 1 |
| **Total** | **22** |
