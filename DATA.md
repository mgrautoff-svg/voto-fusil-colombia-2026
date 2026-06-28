# DATA.md

Español
-------

Este archivo describe las fuentes de datos externas necesarias para ejecutar el pipeline de este subproyecto y las recomendaciones para organizarlas localmente cuando no es posible publicar los datos por restricciones.

Archivos requeridos (según `scripts/00_config.R`):

- `data_raw/electoral/base_electoral_2026_panel_limpio.csv`
- `subproyectos/electoral_2026_segunda_vuelta/outputs/supercubo/electoral_2026_segunda_vuelta_municipio.csv`
- `subproyectos/electoral_2026_primera_vuelta/outputs/puestos/tablas/segunda_vuelta_2022_municipios.csv`
- `subproyectos/electoral_2026_segunda_vuelta/outputs/supercubo/tabla_puente_registraduria_dane.csv`
- `subproyectos/voto_fusil/data_raw/M5_score_clasificacion.rds`
- `data_clean/supercubo_municipio_anio_v3.rds`
- `subproyectos/electoral_2026_segunda_vuelta/outputs/mapas/tablas/metricas_mapas_electorales_2026.csv`
- `data_raw/electoral/Municipios_Septiembre_2025_shp/Municipios_Septiembre_2025_.shp` (shapefile — asegúrese de incluir todos los archivos asociados: .shp, .shx, .dbf, .prj, etc.)

Organización local recomendada
-----------------------------

Clone el repositorio y, en la raíz, cree las carpetas faltantes con:

```bash
mkdir -p data_raw/electoral data_clean subproyectos/voto_fusil/data_raw \ 
  subproyectos/electoral_2026_segunda_vuelta/outputs/supercubo \ 
  subproyectos/electoral_2026_primera_vuelta/outputs/puestos/tablas \ 
  subproyectos/electoral_2026_segunda_vuelta/outputs/mapas/tablas
```

Coloque los archivos en las rutas exactas que enumera `scripts/00_config.R`. El pipeline depende de estas rutas (`normalizePath(..., mustWork = TRUE)`), por lo que las rutas deben existir o deberá adaptar `scripts/00_config.R`.

Si prefiere mantener los datos en una ubicación diferente, edite `scripts/00_config.R` y actualice `config_voto_fusil$rutas` con las rutas absolutas o relativas de su entorno.

Proveedores y condiciones de uso
--------------------------------

Para cada archivo documente en un ISSUE su procedencia y las condiciones de uso (por ejemplo: datos públicos, datos bajo licencia, datos que requieren acuerdo). Ejemplos que conviene mencionar:

- Registraduría / Fuente electoral: si los datos provienen de registros oficiales, indique la URL y la versión del archivo.
- ACLED / UNODC u otros proveedores: anote la fecha de extracción y la versión del dataset.
- Shapefiles: incluya la fuente y la proyección esperada (EPSG).

Solicitud de acceso a datos
--------------------------

Si necesita que el autor provea archivos o un subset autorizado para reproducir (cuando la licencia lo permite), abra un ISSUE con la etiqueta `data-request` y describa:

- Qué archivo(s) necesita
- Propósito (reproducibilidad, revisión, enseñanza)
- Si acepta un subset anonimizado o agregado (por ejemplo, por municipio en vez de puesto)

Buenas prácticas para compartir datos restringidos
------------------------------------------------

- Prefiera compartir muestras (subsets) que permitan ejecutar el pipeline sin violar acuerdos.
- Use formatos tabulares comunes (CSV, RDS) y nombre consistentemente las columnas.
- Para shapefiles, incluya todos los archivos (.shp, .shx, .dbf, .prj).
- Documente transformaciones reproducibles (scripts en `scripts/01_datos.R`).

Contacto
--------

Si necesita ayuda para reproducir los resultados o adaptar rutas, abra un ISSUE o contacte al mantenedor: @mgrautoff-svg.

---

English
-------

This file documents the external data sources required to run the pipeline and recommendations for organizing them locally when the data cannot be published.

Required files (as per `scripts/00_config.R`):

- `data_raw/electoral/base_electoral_2026_panel_limpio.csv`
- `subproyectos/electoral_2026_segunda_vuelta/outputs/supercubo/electoral_2026_segunda_vuelta_municipio.csv`
- `subproyectos/electoral_2026_primera_vuelta/outputs/puestos/tablas/segunda_vuelta_2022_municipios.csv`
- `subproyectos/electoral_2026_segunda_vuelta/outputs/supercubo/tabla_puente_registraduria_dane.csv`
- `subproyectos/voto_fusil/data_raw/M5_score_clasificacion.rds`
- `data_clean/supercubo_municipio_anio_v3.rds`
- `subproyectos/electoral_2026_segunda_vuelta/outputs/mapas/tablas/metricas_mapas_electorales_2026.csv`
- `data_raw/electoral/Municipios_Septiembre_2025_shp/Municipios_Septiembre_2025_.shp` (shapefile — include all associated files: .shp, .shx, .dbf, .prj, etc.)

Local organization recommendations
----------------------------------

Clone the repo and create the missing folders at the root:

```bash
mkdir -p data_raw/electoral data_clean subproyectos/voto_fusil/data_raw \ 
  subproyectos/electoral_2026_segunda_vuelta/outputs/supercubo \ 
  subproyectos/electoral_2026_primera_vuelta/outputs/puestos/tablas \ 
  subproyectos/electoral_2026_segunda_vuelta/outputs/mapas/tablas
```

Place the files in the exact paths listed in `scripts/00_config.R`. The pipeline uses `normalizePath(..., mustWork = TRUE)`, so the paths must exist or you should adapt `scripts/00_config.R`.

If you prefer to keep data elsewhere, edit `scripts/00_config.R` and update `config_voto_fusil$rutas` with the absolute or relative paths used in your environment.

Provenance and licensing
------------------------

For each file, document its source and license/terms in an ISSUE (e.g., public registry data, ACLED download, or restricted dataset). Include extraction date and version when possible.

Requesting access
-----------------

If you need the author to provide files or an authorized subset, open an ISSUE with the `data-request` label and explain:

- Which file(s) you need
- Purpose (reproducibility, review, teaching)
- Whether a subset or aggregated version is acceptable

Best practices for sharing restricted data
-----------------------------------------

- Share samples (subsets) that allow reproducing the pipeline without breaching agreements.
- Use common tabular formats (CSV, RDS) and consistent column names.
- For shapefiles, include all related files (.shp, .shx, .dbf, .prj).
- Document transformations in `scripts/01_datos.R`.

Contact
-------

If you need help reproducing results or adapting paths, open an ISSUE or contact the maintainer: @mgrautoff-svg.

---

How to add the suggested GitHub Topics (if you want me to, I can provide the exact `gh` command):

Web UI (recommended):
1. Open the repository page: https://github.com/mgrautoff-svg/voto-fusil-colombia-2026
2. Click the gear icon next to "About" (right column) or the Topics field.
3. Add: Colombia, elecciones-2026, seguridad, voto-fusil, periodismo-datos, reproducibilidad

GitHub CLI:

```bash
gh repo edit mgrautoff-svg/voto-fusil-colombia-2026 --add-topic Colombia --add-topic elecciones-2026 --add-topic seguridad --add-topic voto-fusil --add-topic periodismo-datos --add-topic reproducibilidad
```

