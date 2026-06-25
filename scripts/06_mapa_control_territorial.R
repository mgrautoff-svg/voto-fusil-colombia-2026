# Responsabilidad unica: mapa integrado (control territorial + resultado
# electoral + cambio de participacion) para publicacion. No recalcula ningun
# modelo; solo lee panel_final, metricas electorales 2026 y el shapefile.
# Ejecutar desde D:/Dropbox/Reform_UIAF/

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(sf)
  library(leaflet)
  library(htmlwidgets)
})

pad_dane <- function(x) sprintf("%05d", suppressWarnings(as.integer(as.character(x))))

tablas_dir <- here::here("subproyectos/voto_fusil/outputs/tablas")
graficos_dir <- here::here("subproyectos/voto_fusil/outputs/graficos")
dir.create(graficos_dir, recursive = TRUE, showWarnings = FALSE)

panel_path <- here::here("subproyectos/voto_fusil/outputs/tablas/panel_voto_fusil_final.rds")
metricas_path <- here::here(
  "subproyectos/electoral_2026_segunda_vuelta/outputs/mapas/tablas/metricas_mapas_electorales_2026.csv"
)
shape_path <- here::here(
  "data_raw/electoral/Municipios_Septiembre_2025_shp/Municipios_Septiembre_2025_.shp"
)

stopifnot(file.exists(panel_path), file.exists(metricas_path), file.exists(shape_path))

panel_final <- readRDS(panel_path)
metricas_2026 <- read_csv(metricas_path, show_col_types = FALSE) |>
  mutate(cod_dane = pad_dane(codigo_municipio)) |>
  select(
    cod_dane, ganador_2v, pct_2v_cepeda, pct_2v_espriella,
    participacion_1v, participacion_2v, variacion_participacion_pp
  )

# --- Datos base: tipologia D2 + resultado 2026 + cambio participacion ------
etiquetas_tipologia <- tibble::tribble(
  ~tipologia_d2,          ~tipologia_label,                      ~color_tipologia,
  "control_armado",       "Control armado consolidado",          "#8B0000",
  "conflicto_activo",     "Conflicto activo",                    "#E05C00",
  "corredor",             "Corredor estrategico",                "#F5A623",
  "produccion_intensiva", "Produccion ilicita intensiva",        "#F5D87A",
  "periferico",           "Sin conflicto activo",                "#EEEEEE"
)

datos_mapa <- panel_final |>
  select(cod_dane, municipio, departamento, tipologia_d2) |>
  inner_join(metricas_2026, by = "cod_dane") |>
  left_join(etiquetas_tipologia, by = "tipologia_d2") |>
  rename(cambio_participacion_pp = variacion_participacion_pp)

stopifnot(!anyNA(datos_mapa$tipologia_label))
stopifnot(!anyNA(datos_mapa$cambio_participacion_pp))
stopifnot(all(datos_mapa$pct_2v_cepeda >= 0 & datos_mapa$pct_2v_cepeda <= 100))
stopifnot(all(datos_mapa$pct_2v_espriella >= 0 & datos_mapa$pct_2v_espriella <= 100))
stopifnot(all(datos_mapa$participacion_1v >= 0 & datos_mapa$participacion_1v <= 100))
stopifnot(all(datos_mapa$participacion_2v >= 0 & datos_mapa$participacion_2v <= 100))
stopifnot(all(unique(datos_mapa$ganador_2v) %in% c("Cepeda", "Espriella")))

# --- Shapefile -------------------------------------------------------------
# dTolerance alto: este mapa es editorial/interactivo, no cartografia legal.
# La simplificacion baja peso del HTML y evita que el navegador se ahogue.
shape <- st_read(shape_path, quiet = TRUE) |>
  st_simplify(dTolerance = 1500, preserveTopology = TRUE) |>
  st_transform(4326) |>
  mutate(cod_dane = pad_dane(MpCodigo)) |>
  filter(cod_dane != "00000")

mapa_sf <- shape |> left_join(datos_mapa, by = "cod_dane")
stopifnot(nrow(mapa_sf) == nrow(shape))
stopifnot(sum(is.na(mapa_sf$tipologia_label)) == 0)

# --- Estilo electoral y popup ---------------------------------------------
mapa_sf <- mapa_sf |>
  mutate(
    color_borde = case_when(
      ganador_2v == "Cepeda" ~ "#D71920",
      ganador_2v == "Espriella" ~ "#1565C0",
      TRUE ~ "#777777"
    ),
    voto_atipico = case_when(
      pct_2v_cepeda > 75 ~ "Si: Cepeda supero el 75%",
      pct_2v_espriella > 75 ~ "Si: De la Espriella supero el 75%",
      TRUE ~ "No: ningun candidato supero el 75%"
    ),
    popup_html = sprintf(
      paste0(
        "<div style='font-family:sans-serif;min-width:245px;line-height:1.45;'>",
        "<b style='font-size:15px;'>%s</b><br>",
        "<span style='color:#666;'>%s</span><hr style='margin:6px 0;'>",
        "<b>Segunda vuelta presidencial</b><br>",
        "Ivan Cepeda: <b>%.1f%%</b><br>",
        "Abelardo de la Espriella: <b>%.1f%%</b><br>",
        "Ganador municipal: <b>%s</b><br>",
        "Votacion atipica (&gt;75%%): <b>%s</b><hr style='margin:6px 0;'>",
        "<b>Participacion electoral</b><br>",
        "Primera vuelta: %.1f%%<br>",
        "Segunda vuelta: %.1f%%<br>",
        "Cambio entre vueltas: <b>%+.1f puntos porcentuales</b><hr style='margin:6px 0;'>",
        "Control territorial: %s",
        "</div>"
      ),
      municipio, departamento, pct_2v_cepeda, pct_2v_espriella,
      ganador_2v, voto_atipico, participacion_1v, participacion_2v,
      cambio_participacion_pp, tipologia_label
    )
  )

popup_municipio <- lapply(mapa_sf$popup_html, htmltools::HTML)
tooltip_municipio <- with(mapa_sf, sprintf(
  "%s — Cepeda %.1f%% · De la Espriella %.1f%% · participacion %+.1f pp",
  municipio, pct_2v_cepeda, pct_2v_espriella, cambio_participacion_pp
)) |>
  lapply(htmltools::HTML)

# --- Capa liviana de circulos ---------------------------------------------
# Antes se pintaba todo el percentil 75: era correcto, pero visualmente pesado.
# Para publicacion dejamos solo los municipios extremos: percentil 90 y maximo
# 80 puntos. El dato completo sigue disponible en el popup de cada municipio.
umbral_p90 <- quantile(mapa_sf$cambio_participacion_pp, 0.90, na.rm = TRUE)
mapa_circulos <- mapa_sf |>
  st_drop_geometry() |>
  filter(cambio_participacion_pp >= umbral_p90) |>
  arrange(desc(cambio_participacion_pp)) |>
  slice_head(n = 80) |>
  select(cod_dane)

centroides <- suppressWarnings(
  mapa_sf |>
    semi_join(mapa_circulos, by = "cod_dane") |>
    st_transform(3857) |>
    st_point_on_surface() |>
    st_transform(4326)
)

radio_circulos <- scales::rescale(
  centroides$cambio_participacion_pp,
  to = c(3, 8)
)

cat(sprintf(
  "Percentil 90 de cambio de participacion: %.2fpp -- %d municipios en la capa de circulos\n",
  umbral_p90, nrow(centroides)
))

# --- Controles HTML --------------------------------------------------------
bbox_colombia <- st_bbox(mapa_sf)
titulo_html <- htmltools::HTML(
  "<div style='background:white;padding:8px 12px;border-radius:4px;",
  "box-shadow:0 1px 4px rgba(0,0,0,0.25);font-family:sans-serif;max-width:320px;'>",
  "<b style='font-size:14px;'>Control territorial y voto presidencial — Colombia 2026</b><br>",
  "<span style='font-size:11px;color:#555;'>Color: control armado · Borde: ganador municipal · ",
  "Circulo: mayor salto de participacion</span>",
  "</div>"
)

fuente_html <- htmltools::HTML(
  "<div style='background:white;padding:4px 8px;border-radius:4px;",
  "font-family:sans-serif;font-size:10px;color:#555;'>",
  "Fuente y construccion: Manfred Grautoff · Sistema E4, Registraduria, ACLED",
  "</div>"
)

metodologia_html <- htmltools::HTML(
  "<div style='background:white;padding:8px 10px;border-radius:4px;",
  "box-shadow:0 1px 4px rgba(0,0,0,0.25);font-family:sans-serif;font-size:11px;",
  "line-height:1.45;max-width:285px;color:#444;'>",
  "<b>Como leer este mapa</b><br>",
  "El color muestra el tipo de control territorial. El borde dice quien gano ",
  "la segunda vuelta en el municipio. Los circulos solo resaltan los mayores ",
  "saltos de participacion. Haga clic para ver porcentajes de Cepeda y De la ",
  "Espriella, participacion primera/segunda vuelta y alerta de votacion &gt;75%.",
  "</div>"
)

leyenda_html <- htmltools::HTML(
  "<div style='background:white;padding:8px 10px;border-radius:4px;",
  "box-shadow:0 1px 4px rgba(0,0,0,0.25);font-family:sans-serif;font-size:11px;line-height:1.55;'>",
  "<span style='color:#8B0000;'>■</span> Control armado consolidado<br>",
  "<span style='color:#E05C00;'>■</span> Conflicto activo<br>",
  "<span style='color:#F5A623;'>■</span> Corredor estrategico<br>",
  "<span style='color:#F5D87A;'>■</span> Produccion ilicita intensiva<br>",
  "<span style='color:#999999;'>■</span> Sin conflicto activo<br>",
  "<span style='color:#D71920;'>━</span> Gano Cepeda<br>",
  "<span style='color:#1565C0;'>━</span> Gano De la Espriella<br>",
  "○ Mayor aumento de participacion",
  "</div>"
)

# --- Mapa -----------------------------------------------------------------
mapa_leaflet <- leaflet(
  mapa_sf,
  options = leafletOptions(minZoom = 4, preferCanvas = TRUE)
) |>
  addProviderTiles("CartoDB.Positron") |>
  fitBounds(
    lng1 = bbox_colombia[["xmin"]], lat1 = bbox_colombia[["ymin"]],
    lng2 = bbox_colombia[["xmax"]], lat2 = bbox_colombia[["ymax"]]
  ) |>
  addPolygons(
    fillColor = ~color_tipologia,
    fillOpacity = 0.82,
    color = ~color_borde,
    opacity = 0.7,
    weight = 0.55,
    smoothFactor = 1.2,
    label = tooltip_municipio,
    popup = popup_municipio,
    highlightOptions = highlightOptions(weight = 2.2, bringToFront = TRUE)
  ) |>
  addCircleMarkers(
    data = centroides,
    radius = radio_circulos,
    color = "#333333",
    weight = 0.8,
    fillColor = "#FFFFFF",
    fillOpacity = 0.65,
    label = ~sprintf("%s: %+.1f pp de participacion", municipio, cambio_participacion_pp) |>
      lapply(htmltools::HTML),
    popup = ~lapply(popup_html, htmltools::HTML)
  ) |>
  addControl(titulo_html, position = "topright") |>
  addControl(metodologia_html, position = "topleft") |>
  addControl(leyenda_html, position = "bottomright") |>
  addControl(fuente_html, position = "bottomleft")

mapa_path <- here::here("subproyectos/voto_fusil/outputs/graficos/mapa_control_territorial.html")

# selfcontained = FALSE deja el mapa mucho mas liviano para abrir y compartir
# durante iteracion. Si luego se necesita un unico HTML embebido, cambiar a TRUE.
saveWidget(mapa_leaflet, mapa_path, selfcontained = FALSE)
cat("Mapa guardado liviano en", mapa_path, "\n")

cat("\n=== 06_mapa OK ===\n")
