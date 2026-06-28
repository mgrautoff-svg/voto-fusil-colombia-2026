# Voto Fusil — Colombia 2026 / voto-fusil-colombia-2026

Español | English

## Resumen

Este subproyecto acompaña el análisis periodístico "Voto fusil vs. voto pistola" publicado en La Silla Vacía: https://www.lasillavacia.com/red-de-expertos/red-de-la-paz/voto-fusil-colombia-2026/.

Propuesta: reproducir el pipeline de análisis y las visualizaciones utilizadas en la pieza. Este repositorio contiene los scripts R del subproyecto, los outputs (tablas, mapas, gráficos) y pruebas que validan resultados básicos.

## Summary

This subproject reproduces the analysis and visualizations for the journalistic piece “Voto fusil vs. voto pistola” (La Silla Vacía). It contains the R scripts, outputs (tables, maps, plots) and lightweight tests used to validate the pipeline.

## Estado de datos / Data status

- Los datos originales NO están incluidos en este repositorio por restricciones de publicación.
- No se han añadido datos ficticios.
- Para ejecutar el pipeline es necesario proveer los archivos listados en `scripts/00_config.R` (sección Rutas). A continuación se enumeran las rutas clave que el pipeline espera:
  - `data_raw/electoral/base_electoral_2026_panel_limpio.csv`
  - `subproyectos/electoral_2026_segunda_vuelta/outputs/supercubo/electoral_2026_segunda_vuelta_municipio.csv`
  - `subproyectos/electoral_2026_primera_vuelta/outputs/puestos/tablas/segunda_vuelta_2022_municipios.csv`
  - `subproyectos/electoral_2026_segunda_vuelta/outputs/supercubo/tabla_puente_registraduria_dane.csv`
  - `subproyectos/voto_fusil/data_raw/M5_score_clasificacion.rds`
  - `data_clean/supercubo_municipio_anio_v3.rds`
  - `subproyectos/electoral_2026_segunda_vuelta/outputs/mapas/tablas/metricas_mapas_electorales_2026.csv`
  - `data_raw/electoral/Municipios_Septiembre_2025_shp/Municipios_Septiembre_2025_.shp`

Si no dispone de estos archivos, el pipeline fallará. Documente la procedencia y las condiciones de compartición de cada fuente en un ISSUE si necesita ayuda para reproducir resultados.

## Requisitos / Requirements

Se recomienda usar R >= 4.0.0. Paquetes R requeridos (ver `scripts/ARRANQUE_SESION.R`):

- dplyr, gt, here, htmltools, htmlwidgets, leaflet, plotly,
- readr, readxl, sandwich, scales, sf, stringr, tibble, tidyr, writexl,
- ggplot2

Instalación mínima (ejecutar en R):

```r
install.packages(c("dplyr","gt","here","htmltools","htmlwidgets","leaflet","plotly","readr","readxl","sandwich","scales","sf","stringr","tibble","tidyr","writexl","ggplot2"))
```

Nota: el paquete `sf` requiere dependencias del sistema (GDAL/proj). En Linux/WSL/Mac instale las librerías del sistema antes de instalar el paquete.

## Cómo ejecutar / How to run

1) Desde la raíz del repositorio (recomendado) ejecute en la terminal:

```
Rscript run.R
```

2) Alternativa en RStudio: abra `run.R` y haga "Source" (asegúrese de que el working directory sea la raíz del repo o ajuste según sea necesario).

`run.R` es el orquestador: ejecuta `ARRANQUE_SESION.R`, varios scripts de datos y análisis en `scripts/` y las pruebas en `tests/`. Al completar con éxito mostrará:

```
=== PIPELINE voto_fusil COMPLETADO ===
```

Nota sobre rutas: este subproyecto fue diseñado para integrarse en una estructura mayor de subproyectos. Si encuentra errores de rutas (`normalizePath` / `mustWork`), verifique que las rutas configuradas en `scripts/00_config.R` existen localmente o adapte las rutas a su copia local.

## Contenido principal

- `run.R` — orquestador principal (arranque, ejecución de scripts y pruebas)
- `scripts/00_config.R` — rutas y configuración estática
- `scripts/01_datos.R` — carga y limpieza de datos
- `scripts/02_analisis.R` — modelos y métricas principales
- `scripts/03_guardar_estado.R` — persistencia de estado intermedio
- `scripts/04_visualizaciones.R` — generación de gráficos interactivos/estáticos
- `scripts/05_exterior_grupo_control.R` — análisis de grupo de control exterior
- `scripts/06_* … 12_*` — scripts adicionales para mapas, tablas y visualizaciones
- `tests/` — pruebas unitarias / comprobaciones de outputs
- `outputs/` — carpeta de salida (tablas, mapas, gráficos)

## Salidas esperadas

Las salidas se guardan en `outputs/` (subcarpetas: `tablas`, `mapas`, `graficos`, `graficas/ppt`, `graficas/doc`). Si ejecuta el pipeline en orden, los gráficos y tablas principales deben aparecer aquí.

## Contribuir / Contributing

- Abra un ISSUE para discutir datos, reproducibilidad o errores.
- Use Pull Requests para cambios en scripts o documentación.
- Etiquetas sugeridas para issues: `reproducibility`, `data-request`, `bug`, `enhancement`.

## Citar / How to cite

Si usa estos scripts en trabajo académico o periodístico, cite la pieza periodística y, si lo considera útil, enlace al repositorio. Artículo en La Silla Vacía: https://www.lasillavacia.com/red-de-expertos/red-de-la-paz/voto-fusil-colombia-2026/.

## Licencia / License

Este repositorio usará la licencia MIT. Incluya un archivo LICENSE si aún no existe.

## Contacto

Repositorio: https://github.com/mgrautoff-svg/voto-fusil-colombia-2026
Autor / mantenedor: @mgrautoff-svg

----

## Notas técnicas rápidas

- `run.R` invoca scripts en `scripts/` y `tests/`. `ARRANQUE_SESION.R` revisa la presencia de paquetes y crea las carpetas `outputs/`.
- Si necesita ayuda para adaptar rutas (por ejemplo cuando usa este subproyecto de forma aislada), abra un ISSUE y describa el error y su estructura local de carpetas.
