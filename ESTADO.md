# Estado del subproyecto voto_fusil

Fecha del run: 2026-06-24 19:23:02 -05  
Commit base: `c57ed0a` (con cambios sin commit)  
Estado: **pipeline completo y tests aprobados**

## Números auditados

- Panel final: 1122 filas y 120 columnas.
- Cobertura del modelo principal: 1102/1122 municipios (98.2%).
- Ventana ACLED: noviembre de 2025 a mayo de 2026.
- Especificaciones de robustez: 18.
- Control armado positivo y significativo: 9/9.

### Distribución de alta exposición

- `FALSE`: 937 municipios (83.5%)
- `TRUE`: 185 municipios (16.5%)

### Municipios con mayor exposición

1. Tibú (Norte de Santander): 124 eventos
2. Jamundí (Valle del Cauca): 49 eventos
3. San José de Cúcuta (Norte de Santander): 44 eventos
4. Bogotá, D.C. (Cundinamarca): 44 eventos
5. Santiago de Cali (Valle del Cauca): 39 eventos

## Interpretación

La exposición armada reciente y el control territorial estructural no son la misma variable. El primer indicador no presenta una asociación robusta en los modelos ajustados. El control armado estructural conserva una asociación positiva con el aumento de participación en 9 especificaciones. Conflicto activo presenta coeficientes entre -0.66 y 7.35 puntos porcentuales, lo que evidencia sensibilidad a controles y grupos de referencia.

## Límite epistemológico

El diseño es observacional, agregado y municipal. Los coeficientes representan asociaciones, no efectos causales. No permiten identificar decisiones individuales ni descartar episodios particulares de coacción.

## Productos validados

- Tablas y modelos en `outputs/tablas/`.
- Visualizaciones interactivas en `outputs/graficos/`.
- Cuatro gráficos oscuros en `outputs/graficas/ppt/`.
- Cuatro gráficos claros en `outputs/graficas/doc/`.
- Pieza editorial en `outputs/pieza_editorial_voto_fusil.md`.

