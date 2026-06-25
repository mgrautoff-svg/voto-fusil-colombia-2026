# Responsabilidad unica: decisiones y rutas estables del subproyecto.
# No lee datos, no ejecuta modelos y no genera outputs.

config_voto_fusil <- list(
  n_municipios = 1122L,
  ventana_inicio = as.Date("2025-11-01"),
  ventana_fin = as.Date("2026-05-31"),
  cuantil_alta_exposicion = 0.75,
  fuentes_acled = c(
    pv = "colombia_hrp_political_violence_events_and_fatalities_by_month-year_as-of-17jun2026.xlsx",
    ct = "colombia_hrp_civilian_targeting_events_and_fatalities_by_month-year_as-of-17jun2026.xlsx",
    dm = "colombia_hrp_demonstration_events_by_month-year_as-of-17jun2026.xlsx"
  ),
  rutas = list(
    panel_electoral = "data_raw/electoral/base_electoral_2026_panel_limpio.csv",
    acled = "data_raw/acled",
    segunda_vuelta_2026 = "subproyectos/electoral_2026_segunda_vuelta/outputs/supercubo/electoral_2026_segunda_vuelta_municipio.csv",
    segunda_vuelta_2022 = "subproyectos/electoral_2026_primera_vuelta/outputs/puestos/tablas/segunda_vuelta_2022_municipios.csv",
    puente_dane = "subproyectos/electoral_2026_segunda_vuelta/outputs/supercubo/tabla_puente_registraduria_dane.csv",
    tipologia_d2 = "subproyectos/voto_fusil/data_raw/M5_score_clasificacion.rds",
    supercubo = "data_clean/supercubo_municipio_anio_v3.rds",
    metricas_2026 = "subproyectos/electoral_2026_segunda_vuelta/outputs/mapas/tablas/metricas_mapas_electorales_2026.csv",
    shape_municipal = "data_raw/electoral/Municipios_Septiembre_2025_shp/Municipios_Septiembre_2025_.shp"
  )
)
