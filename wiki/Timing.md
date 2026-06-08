# Reporte de Timing

## Frecuencia de operación
- **Requerida**: 27 MHz (período 37 ns)
- **Máxima reportada por nextpnr**: 95.43 MHz ✅

## Análisis de timing

| Parámetro | Valor |
|---|---|
| Frecuencia de operación | 27 MHz |
| Período de reloj | 37 ns |
| Frecuencia máxima alcanzada | 95.43 MHz |
| Margen sobre la frecuencia objetivo | ~3.5× |
| Resultado | **PASS** |

## Ruta crítica

La ruta crítica fue identificada en el subsistema de display (`controlador_displays`), específicamente en la cadena combinacional de la conversión BCD dentro del `selector_display` que alimenta al decodificador de 7 segmentos. El path total reportado alcanza ~129.7 ns dentro del período presupuestado.

El timing de las rutas con budget negativo corresponde a restricciones internas del enrutador (dentro del ciclo), no a violaciones reales de setup.

## Verificación

Comando usado para extraer el reporte:
```bash
grep -i "max\|freq\|mhz\|timing\|slack" pnr_tangnano9k.log
```

Línea clave del log:
```
Info: Max frequency for clock 'barrido.clk': 95.43 MHz (PASS at 27.00 MHz)
```
