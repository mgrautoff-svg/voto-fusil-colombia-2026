# Responsabilidad unica: generar los 4 artefactos HTML standalone de
# visualizacion a partir de los CSV/RDS ya producidos por 02_analisis.R.
# No recalcula nada del modelo; solo lee y visualiza. Sin datos hardcodeados.
# Ejecutar desde D:/Dropbox/Reform_UIAF/

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(sf)
  library(leaflet)
  library(plotly)
  library(htmlwidgets)
})

pad_dane <- function(x) sprintf("%05d", suppressWarnings(as.integer(as.character(x))))

tablas_dir <- here::here("subproyectos/voto_fusil/outputs/tablas")
graficos_dir <- here::here("subproyectos/voto_fusil/outputs/graficos")
dir.create(graficos_dir, recursive = TRUE, showWarnings = FALSE)

# --- Insumos (todos ya producidos por 02_analisis.R; ninguno se recalcula) --
panel_path <- file.path(tablas_dir, "panel_voto_fusil_final.rds")
modelo_voto_path <- file.path(tablas_dir, "modelo_voto_fusil_controles.csv")
modelo_part_path <- file.path(tablas_dir, "modelo_participacion_controles.csv")
forero_path <- file.path(tablas_dir, "tabla_forero_participacion.csv")
welch_part_path <- file.path(tablas_dir, "test_diferencia_participacion.csv")
shape_path <- here::here(
  "data_raw/Municipios_Septiembre_2025_shp/Municipio, Distrito y Area no municipalizada.shp"
)

stopifnot(file.exists(panel_path), file.exists(modelo_voto_path),
          file.exists(modelo_part_path), file.exists(forero_path),
          file.exists(welch_part_path), file.exists(shape_path))

panel_final <- readRDS(panel_path)
modelo_voto <- read_csv(modelo_voto_path, show_col_types = FALSE)
modelo_part <- read_csv(modelo_part_path, show_col_types = FALSE)
forero <- read_csv(forero_path, show_col_types = FALSE)
welch_part <- read_csv(welch_part_path, show_col_types = FALSE)

# =============================================================================
# Artefacto 1: mapa coropletico de exposicion armada
# =============================================================================
shape <- st_read(shape_path, quiet = TRUE) |>
  # Simplificar ANTES de transformar (tolerancia en metros, CRS original
  # proyectado). Sin esto, los 1.122 poligonos de alta resolucion hacen que
  # el HTML autocontenido sea demasiado pesado para que pandoc lo empaquete
  # (falla por memoria virtual insuficiente en Windows). 300m es imperceptible
  # a escala nacional.
  st_simplify(dTolerance = 300, preserveTopology = TRUE) |>
  st_transform(4326) |>  # MAGNA-SIRGAS -> WGS84, lo que leaflet necesita
  mutate(cod_dane = pad_dane(MpCodigo)) |>
  filter(cod_dane != "00000")

mapa_datos <- panel_final |>
  mutate(
    ganador_2v2026 = if_else(
      votos_2v2026_ivan_cepeda_castro > votos_2v2026_abelardo_de_la_espriella,
      "Cepeda", "Espriella"
    )
  ) |>
  select(cod_dane, municipio, departamento, idx_exposicion, ganador_2v2026)

mapa_sf <- shape |> left_join(mapa_datos, by = "cod_dane")
stopifnot(nrow(mapa_sf) == nrow(shape))
stopifnot(sum(is.na(mapa_sf$idx_exposicion)) == 0)

paleta <- colorNumeric(palette = "YlOrRd", domain = mapa_sf$idx_exposicion)
es_tibu <- mapa_sf$cod_dane == "54810"
bbox_colombia <- st_bbox(mapa_sf)

mapa_leaflet <- leaflet(mapa_sf, options = leafletOptions(minZoom = 4)) |>
  addProviderTiles("CartoDB.Positron") |>
  fitBounds(
    lng1 = bbox_colombia[["xmin"]], lat1 = bbox_colombia[["ymin"]],
    lng2 = bbox_colombia[["xmax"]], lat2 = bbox_colombia[["ymax"]]
  ) |>
  addPolygons(
    fillColor = ~paleta(idx_exposicion),
    fillOpacity = 0.85,
    color = ifelse(es_tibu, "#000000", "#999999"),
    weight = ifelse(es_tibu, 3, 0.4),
    label = ~sprintf(
      "%s (%s)<br>Exposición armada: %d eventos<br>Gana 2ª vuelta 2026: %s",
      municipio, departamento, idx_exposicion, ganador_2v2026
    ) |> lapply(htmltools::HTML),
    highlightOptions = highlightOptions(weight = 3, color = "#000", bringToFront = TRUE)
  ) |>
  addLegend(pal = paleta, values = ~idx_exposicion, title = "Índice de exposición armada\n(nov 2025 - may 2026)")

# selfcontained=TRUE usa pandoc para empaquetar todo en un solo HTML; con
# 1.122 poligonos puede agotar la memoria virtual disponible en Windows (ya
# ha pasado antes en esta maquina). Si falla, se cae a selfcontained=FALSE
# (genera el HTML + una carpeta de dependencias al lado) en vez de detener
# todo el script -- mejor un artefacto que funcione con una carpeta extra
# que ningun artefacto.
mapa_path <- file.path(graficos_dir, "viz_01_mapa_exposicion.html")
resultado_mapa <- tryCatch({
  saveWidget(mapa_leaflet, mapa_path, selfcontained = TRUE)
  "selfcontained"
}, error = function(e) {
  cat("AVISO: selfcontained=TRUE fallo por memoria (pandoc). Reintentando con selfcontained=FALSE...\n")
  saveWidget(mapa_leaflet, mapa_path, selfcontained = FALSE)
  "con carpeta de dependencias (selfcontained=FALSE)"
})
cat("Mapa guardado", resultado_mapa, "\n")

# =============================================================================
# Artefacto 2: gradiente de ruralidad (modelo de voto)
# =============================================================================
construir_datos_coef <- function(modelo, mapa_etiquetas) {
  modelo |>
    inner_join(mapa_etiquetas, by = "termino") |>
    mutate(
      low = estimacion - 1.96 * error_estandar_hc1,
      high = estimacion + 1.96 * error_estandar_hc1,
      significativo = !(low <= 0 & high >= 0),
      color = if_else(significativo, "#1a7a4c", "#8a8a8a")
    ) |>
    arrange(match(termino, mapa_etiquetas$termino))
}

etiquetas_ruralidad <- tribble(
  ~termino, ~label,
  "cat_ruralidadRural disperso", "Rural disperso",
  "cat_ruralidadRural", "Rural",
  "cat_ruralidadIntermedio", "Intermedio"
)

datos_ruralidad <- construir_datos_coef(modelo_voto, etiquetas_ruralidad)
stopifnot(nrow(datos_ruralidad) == nrow(etiquetas_ruralidad))

fig_ruralidad <- plot_ly(
  datos_ruralidad,
  x = ~estimacion, y = ~label, type = "scatter", mode = "markers",
  error_x = list(array = ~(high - estimacion), arrayminus = ~(estimacion - low), color = ~color),
  marker = list(size = 12, color = ~color)
) |>
  layout(
    title = "Gradiente de ruralidad: efecto sobre el cambio de voto",
    xaxis = list(title = "Cambio en puntos porcentuales", zeroline = TRUE),
    yaxis = list(title = "", categoryorder = "array", categoryarray = rev(datos_ruralidad$label)),
    shapes = list(list(type = "line", x0 = 0, x1 = 0, y0 = -1, y1 = nrow(datos_ruralidad),
                       line = list(dash = "dot", color = "#aaa")))
  )

saveWidget(fig_ruralidad, file.path(graficos_dir, "viz_02_gradiente_ruralidad.html"), selfcontained = TRUE)

# =============================================================================
# Artefacto 3: panel doble (modelo voto vs modelo participacion)
# =============================================================================
etiquetas_voto <- tribble(
  ~termino, ~label,
  "cat_ruralidadRural disperso", "Rural disperso",
  "cat_ruralidadRural", "Rural",
  "cat_ruralidadIntermedio", "Intermedio",
  "pdet", "PDET",
  "alta_exposicionTRUE", "Exposición armada"
)
etiquetas_part <- tribble(
  ~termino, ~label,
  "ipm_dnp", "Pobreza (IPM)",
  "pdet", "PDET",
  "cat_ruralidadRural disperso", "Rural disperso",
  "pct22_fajardo", "Voto centro 2022",
  "alta_exposicionTRUE", "Exposición armada"
)

resaltar_alta <- function(df) {
  df |> mutate(color = if_else(termino == "alta_exposicionTRUE", "#c0392b", color))
}

datos_voto_panel <- construir_datos_coef(modelo_voto, etiquetas_voto) |> resaltar_alta()
datos_part_panel <- construir_datos_coef(modelo_part, etiquetas_part) |> resaltar_alta()

trace_voto <- plot_ly(
  datos_voto_panel, x = ~estimacion, y = ~label, type = "scatter", mode = "markers",
  error_x = list(array = ~(high - estimacion), arrayminus = ~(estimacion - low), color = ~color),
  marker = list(size = 11, color = ~color), showlegend = FALSE
)
trace_part <- plot_ly(
  datos_part_panel, x = ~estimacion, y = ~label, type = "scatter", mode = "markers",
  error_x = list(array = ~(high - estimacion), arrayminus = ~(estimacion - low), color = ~color),
  marker = list(size = 11, color = ~color), showlegend = FALSE
)

panel_coeficientes <- subplot(trace_voto, trace_part, nrows = 1, margin = 0.08, titleX = TRUE) |>
  layout(
    title = "Modelo de voto vs. modelo de participación: la exposición armada (rojo) no es significativa en ninguno",
    annotations = list(
      list(x = 0.18, y = 1.05, text = "Cambio de voto", showarrow = FALSE, xref = "paper", yref = "paper"),
      list(x = 0.82, y = 1.05, text = "Cambio de participación", showarrow = FALSE, xref = "paper", yref = "paper")
    )
  )

saveWidget(panel_coeficientes, file.path(graficos_dir, "viz_03_panel_coeficientes.html"), selfcontained = TRUE)

# =============================================================================
# Artefacto 4: Forero, bruto vs controlado
# =============================================================================
fila_alta_part <- modelo_part |> filter(termino == "alta_exposicionTRUE")
stopifnot(nrow(fila_alta_part) == 1L)

datos_forero_comparacion <- tibble(
  escenario = c("Diferencia bruta\n(sin controles)", "Diferencia controlada\n(pobreza + PDET)"),
  diferencia = c(welch_part$diferencia_medias[1], fila_alta_part$estimacion[1]),
  p_valor = c(welch_part$p_valor[1], fila_alta_part$p_valor[1])
) |>
  mutate(
    etiqueta = sprintf("%.2f pp\n(p=%.3f)", diferencia, p_valor),
    color = if_else(p_valor < 0.05, "#c0392b", "#8a8a8a")
  )

fig_forero <- plot_ly(
  datos_forero_comparacion,
  x = ~escenario, y = ~diferencia, type = "bar",
  marker = list(color = ~color),
  text = ~etiqueta, textposition = "outside"
) |>
  layout(
    title = "El mismo punto porcentual, dos interpretaciones",
    xaxis = list(title = ""),
    yaxis = list(title = "Diferencia en participación (pp)", zeroline = TRUE)
  )

saveWidget(fig_forero, file.path(graficos_dir, "viz_04_forero_bruto_vs_controlado.html"), selfcontained = TRUE)

cat("Artefactos generados en", graficos_dir, "\n")
cat("=== 04_visualizaciones OK ===\n")
