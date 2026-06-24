# Voto fusil — ¿la exposición armada explica el cambio de voto en la segunda vuelta 2026?

Código, tablas de resultados y metodología del análisis publicado en la columna
**"Ni guerrilleros ni víctimas: el voto armado que nadie quiere explicar"**
(ver [`outputs/pieza_editorial_voto_fusil.md`](outputs/pieza_editorial_voto_fusil.md)).

## Pregunta

¿La narrativa del "voto fusil" —que los grupos armados habrían inclinado la
segunda vuelta presidencial 2026 en los territorios donde tienen presencia—
se sostiene con los datos disponibles?

## Hallazgo central

No, no como evento electoral del 21 de junio. La exposición armada **reciente**
(eventos ACLED de noviembre 2025 a mayo 2026) no explica el cambio de voto ni
de participación una vez se controla por pobreza, ruralidad, coca y PDET.

Lo que sí es significativo es una medida de **control armado estructural
histórico** (tipología territorial, construida con datos 2018-2023, no con el
índice de exposición reciente): los municipios de control armado consolidado
muestran más voto hacia Cepeda, pero **no** más participación — un patrón
consistente con persistencia institucional (Arjona, Acemoglu y Robinson), no
con coacción electoral puntual.

## Estructura

- `scripts/01_datos.R` — carga y verifica 5 insumos (panel electoral histórico,
  3 archivos ACLED, resultados 2026, segunda vuelta 2022, tipología territorial
  del Sistema E4 de `conflict_armed`).
- `scripts/02_analisis.R` — índice de exposición armada, joins, y los modelos
  (Welch, OLS con errores robustos HC1, con y sin tipología territorial).
- `scripts/03_guardar_estado.R` — audita y registra los números clave en `docs/ESTADO.md`.
- `scripts/04_visualizaciones.R` — mapa coroplético (Leaflet) y gráficos de
  coeficientes (Plotly), todos HTML standalone.
- `tests/` — verificación de insumos, outputs y números clave.
- `outputs/tablas/` — resultados de cada bloque de análisis (CSV).
- `docs/` — bitácora de decisiones metodológicas y fuentes.

## Reproducibilidad

Este repo contiene el **código y los resultados**, no los datos crudos (ACLED,
panel electoral histórico, archivo de tipología territorial) ni el repositorio
privado de la columna electoral del que depende para los resultados oficiales
de segunda vuelta — esos viven en repos privados por contener insumos de
terceros o de otros proyectos. Por eso `run.R` no correrá de forma autónoma
fuera del entorno original; se publica para auditoría y transparencia
metodológica, no como pipeline ejecutable de extremo a extremo.

## Autor

Manfred Grautoff
