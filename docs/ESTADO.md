# Estado del subproyecto voto_fusil

Fecha del run: 2026-06-27 16:40:46 -05  
Commit base: `d700fd6` (con cambios sin commit)  
Estado: **pipeline completo y tests aprobados**

## Numeros auditados del run

- Panel final: 1.122 municipios y 120 columnas.
- Cobertura del modelo principal: 1.102/1.122 municipios (98,2%).
- Ventana ACLED: noviembre de 2025 a mayo de 2026.
- Especificaciones de robustez: 18.
- Control armado positivo y significativo: 9/9 especificaciones.
- Municipios `control_armado`: 85.
- Municipios `conflicto_activo`: 223.

## Distribucion de alta exposicion ACLED

- `FALSE`: 937 municipios (83,5%).
- `TRUE`: 185 municipios (16,5%).

## Municipios con mayor exposicion reciente

1. Tibú (Norte de Santander): 124 eventos.
2. Jamundí (Valle del Cauca): 49 eventos.
3. San José de Cúcuta (Norte de Santander): 44 eventos.
4. Bogotá, D.C. (Cundinamarca): 44 eventos.
5. Santiago de Cali (Valle del Cauca): 39 eventos.

## Resultado central de la matriz de robustez

### Panel A - Control armado estructural

`control_armado` conserva coeficiente positivo y significativo en las 9 especificaciones:

| Referencia | Controles | Coeficiente |
|---|---:|---:|
| exterior | sin controles | +9,81 pp |
| resto_colombia | sin controles | +3,67 pp |
| resto_colombia | IPM | +1,39 pp |
| resto_colombia | ruralidad | +2,95 pp |
| resto_colombia | IPM + ruralidad | +1,49 pp |
| resto_colombia + exterior | sin controles | +4,14 pp |
| resto_colombia + exterior | IPM | +1,39 pp |
| resto_colombia + exterior | ruralidad | +2,95 pp |
| resto_colombia + exterior | IPM + ruralidad | +1,49 pp |

Interpretacion: la senal de control armado no desaparece al controlar por pobreza o ruralidad.

### Panel B - Conflicto activo

`conflicto_activo` es inestable. Frente al exterior y sin controles es alto y positivo, pero frente al resto de Colombia cambia de signo al agregar IPM:

| Referencia | Controles | Coeficiente |
|---|---:|---:|
| exterior | sin controles | +7,35 pp |
| resto_colombia | sin controles | +1,21 pp |
| resto_colombia | IPM | -0,65 pp |
| resto_colombia | ruralidad | +0,79 pp |
| resto_colombia | IPM + ruralidad | -0,66 pp |
| resto_colombia + exterior | sin controles | +1,68 pp |
| resto_colombia + exterior | IPM | -0,65 pp |
| resto_colombia + exterior | ruralidad | +0,79 pp |
| resto_colombia + exterior | IPM + ruralidad | -0,66 pp |

Interpretacion: parte de lo que parecia conflicto activo era composicion social y pobreza. Al introducir IPM, la senal se invierte.

## Lectura tecnica

La exposicion armada reciente y el control territorial estructural no son la misma variable. ACLED captura eventos recientes y violencia explicita. D2 captura arquitectura territorial de largo plazo.

El resultado principal no es que "hubo voto fusil" en sentido causal individual. El resultado es que municipios bajo control armado estructural registraron un aumento de participacion mayor y robusto frente a varias referencias.

## DiD descriptivo

La visualizacion DiD compara cambios medios de participacion entre primera y segunda vuelta de 2026. Es descriptiva, no causal fuerte. La referencia exterior funciona como linea base de polarizacion nacional sin control armado territorial colombiano.

Documento asociado: `docs/NOTA_DID_DESCRIPTIVO.md`.

## D4/Kalman

D4/Kalman fue revisado, pero no se usa como estimador principal porque incluye componentes de violencia y abstencion que se solapan con la variable dependiente y con controles del modelo. La decision esta documentada en:

- `docs/NOTA_KALMAN_D4.md`.

## Limite epistemologico

El diseno es observacional, agregado y municipal. Los coeficientes representan asociaciones, no efectos causales individuales. No permiten observar decisiones dentro de la cabina ni descartar episodios particulares de coaccion.

## Productos validados

- Tablas y modelos en `outputs/tablas/`.
- Visualizaciones interactivas en `outputs/graficos/`.
- Graficos oscuros en `outputs/graficas/ppt/`.
- Graficos claros en `outputs/graficas/doc/`.
- Pieza editorial en `outputs/pieza_editorial_voto_fusil.md`.

