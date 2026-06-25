# Responsabilidad unica: mapa exclusivamente de tipologia territorial D2
# (Sistema E4) -- sin resultado electoral, sin participacion, sin ACLED, sin
# circulos. Su funcion es que el lector entienda la geografia del control
# territorial ANTES de ver cualquier comparacion electoral (ver
# 06_mapa_control_territorial.R para el mapa integrado).
# No recalcula ni reclasifica nada: tipologia_d2 se lee tal cual viene de
# panel_final. Solo rediseño visual y cartografico.
# Ejecutar desde D:/Dropbox/Reform_UIAF/

suppressPackageStartupMessages({
  library(dplyr)
  library(sf)
  library(leaflet)
  library(htmlwidgets)
  library(htmltools)
})

pad_dane <- function(x) sprintf("%05d", suppressWarnings(as.integer(as.character(x))))

tablas_dir <- here::here("subproyectos/voto_fusil/outputs/tablas")
graficos_dir <- here::here("subproyectos/voto_fusil/outputs/graficos")
dir.create(graficos_dir, recursive = TRUE, showWarnings = FALSE)

panel_path <- file.path(tablas_dir, "panel_voto_fusil_final.rds")
shape_path <- here::here(
  "data_raw/electoral/Municipios_Septiembre_2025_shp/Municipios_Septiembre_2025_.shp"
)
stopifnot(file.exists(panel_path), file.exists(shape_path))

panel_final <- readRDS(panel_path)

# =============================================================================
# Diccionario visual de la tipologia -- unico lugar donde se define color y
# texto. No se muestra la sigla interna "D2" ni "D1" en ningun texto visible;
# tipologia_d2 sigue siendo el nombre de la variable (no se renombra), pero
# el lector solo ve nombres en español llano.
# =============================================================================
construir_diccionario_tipologia <- function() {
  tribble(
    ~tipologia_d2,          ~etiqueta,                        ~descripcion,                                                                  ~color,
    "control_armado",       "Control armado consolidado",     "Control territorial estructural de un grupo armado durante años.",            "#7A2333",
    "conflicto_activo",     "Conflicto activo",               "Violencia en curso, sin un control territorial consolidado.",                 "#C2622D",
    "corredor",             "Corredor estratégico",           "Ruta de movilidad para economías ilegales y grupos armados.",                  "#C9A227",
    "produccion_intensiva", "Producción ilícita intensiva",   "Alta concentración de economías ilegales (coca, minería).",                    "#5F6F33",
    "periferico",           "Sin conflicto activo",           "Sin señales relevantes de control armado o conflicto activo.",                 "#E5E0D8"
  )
}

# =============================================================================
# Construye los datos del mapa: shapefile + tipologia, sin tocar la
# clasificacion ni ningun valor de panel_final.
# =============================================================================
construir_datos_mapa <- function(panel_final, shape_path, diccionario) {
  shape <- st_read(shape_path, quiet = TRUE) |>
    st_simplify(dTolerance = 300, preserveTopology = TRUE) |>
    st_transform(4326) |>
    mutate(cod_dane = pad_dane(MpCodigo)) |>
    filter(cod_dane != "00000")

  datos_tipologia <- panel_final |>
    select(cod_dane, municipio, departamento, tipologia_d2) |>
    left_join(diccionario, by = "tipologia_d2")

  stopifnot(!anyNA(datos_tipologia$etiqueta))

  mapa_sf <- shape |> left_join(datos_tipologia, by = "cod_dane")
  stopifnot(nrow(mapa_sf) == nrow(shape))
  stopifnot(sum(is.na(mapa_sf$etiqueta)) == 0)
  mapa_sf
}

# =============================================================================
# Disuelve los municipios en limites departamentales -- solo geometria
# (st_union), no agrega ninguna variable analitica nueva.
# =============================================================================
construir_limites_departamentales <- function(mapa_sf) {
  mapa_sf |>
    group_by(departamento) |>
    summarise(geometry = st_union(geometry), .groups = "drop") |>
    st_as_sf()
}

# =============================================================================
# Leyenda HTML con conteos reales calculados desde los datos (no escritos a
# mano) -- si la distribucion de tipologia_d2 cambia, la leyenda cambia sola.
# =============================================================================
construir_leyenda_html <- function(mapa_sf, diccionario) {
  conteos <- mapa_sf |>
    st_drop_geometry() |>
    count(tipologia_d2, name = "n") |>
    right_join(diccionario, by = "tipologia_d2") |>
    mutate(n = tidyr::replace_na(n, 0))

  filas <- paste0(
    "<span style='display:inline-block;width:10px;height:10px;background:",
    conteos$color, ";margin-right:6px;border-radius:2px;'></span>",
    conteos$etiqueta, " (", conteos$n, ")"
  )

  HTML(paste0(
    "<div style='background:white;padding:10px 12px;border-radius:4px;",
    "box-shadow:0 1px 4px rgba(0,0,0,0.25);font-family:sans-serif;",
    "font-size:11.5px;line-height:1.7;max-width:230px;color:#333;'>",
    "<b style='font-size:12px;'>Tipología territorial</b><br>",
    paste(filas, collapse = "<br>"),
    "<hr style='border:none;border-top:1px solid #ddd;margin:6px 0;'>",
    "<span style='font-size:10px;color:#888;'>Clasificación territorial basada en ",
    "Sistema E4. No identifica comportamiento individual.</span>",
    "</div>"
  ))
}

# =============================================================================
# Caja titulo + boton colapsable "Como leer este mapa" (<details>, sin JS) --
# texto de maximo 70 palabras, sin tecnicismos ni referencias a resultado
# electoral.
# =============================================================================
construir_caja_titulo_html <- function() {
  HTML(paste0(
    "<div style='background:white;padding:10px 14px;border-radius:4px;",
    "box-shadow:0 1px 4px rgba(0,0,0,0.25);font-family:sans-serif;max-width:320px;'>",
    "<b style='font-size:14.5px;color:#222;'>Arquitecturas territoriales de control y conflicto</b><br>",
    "<span style='font-size:11.5px;color:#555;'>Clasificación municipal Sistema E4 · Colombia, 2026</span><br>",
    "<span style='font-size:11px;color:#777;'>Explore cómo se distribuyen las configuraciones ",
    "territoriales de control, conflicto y periferia.</span>",
    "<details style='margin-top:6px;font-size:11px;color:#444;'>",
    "<summary style='cursor:pointer;color:#1565C0;'>Cómo leer este mapa</summary>",
    "<p style='margin:6px 0 0 0;line-height:1.5;'>",
    "El color representa la tipología territorial de cada municipio según el Sistema E4: ",
    "una clasificación de la configuración histórica del control armado y la economía ",
    "ilegal en el territorio. No mide resultados electorales ni es una medida directa de ",
    "coerción sobre las personas — es una clasificación estructural, no un juicio sobre ",
    "el comportamiento de votantes individuales.",
    "</p></details></div>"
  ))
}

construir_creditos_html <- function() {
  HTML(paste0(
    "<div style='background:white;padding:3px 8px;border-radius:3px;",
    "font-family:sans-serif;font-size:9.5px;color:#999;'>",
    "Fuente y construcción: Manfred Grautoff · Sistema E4 · datos territoriales integrados",
    "</div>"
  ))
}

construir_tooltip <- function(mapa_sf) {
  with(mapa_sf, sprintf(
    paste0(
      "<b>%s</b> — %s<br>",
      "<span style='color:#555;'>Tipología: %s</span><br>",
      "<span style='font-size:11px;color:#777;'>%s</span>"
    ),
    municipio, departamento, etiqueta, descripcion
  )) |> lapply(HTML)
}

# =============================================================================
# Ensamblaje del mapa
# =============================================================================
diccionario_tipologia <- construir_diccionario_tipologia()
mapa_sf <- construir_datos_mapa(panel_final, shape_path, diccionario_tipologia)
limites_dpto <- construir_limites_departamentales(mapa_sf)

bbox_colombia <- st_bbox(mapa_sf)
margen <- 0.3  # grados; encuadre ajustado para minimizar paises vecinos y oceano
bounds_iniciales <- list(
  lng1 = bbox_colombia[["xmin"]] - margen, lat1 = bbox_colombia[["ymin"]] - margen,
  lng2 = bbox_colombia[["xmax"]] + margen, lat2 = bbox_colombia[["ymax"]] + margen
)

mapa_tipologia <- leaflet(
  mapa_sf,
  options = leafletOptions(minZoom = 5, maxZoom = 10)
) |>
  addProviderTiles("CartoDB.PositronNoLabels") |>
  fitBounds(bounds_iniciales$lng1, bounds_iniciales$lat1, bounds_iniciales$lng2, bounds_iniciales$lat2) |>
  setMaxBounds(bounds_iniciales$lng1, bounds_iniciales$lat1, bounds_iniciales$lng2, bounds_iniciales$lat2) |>
  addPolygons(
    fillColor = ~color,
    fillOpacity = 0.88,
    color = "#FAFAF8",
    weight = 0.25,
    label = construir_tooltip(mapa_sf),
    labelOptions = labelOptions(direction = "auto"),
    highlightOptions = highlightOptions(
      weight = 1.4, color = "#222222", fillOpacity = 0.97, bringToFront = TRUE
    )
  ) |>
  addPolygons(
    data = limites_dpto,
    fill = FALSE,
    color = "#8A8A8A",
    weight = 0.9,
    opacity = 0.6
  ) |>
  addControl(construir_caja_titulo_html(), position = "topright") |>
  addControl(construir_leyenda_html(mapa_sf, diccionario_tipologia), position = "bottomright") |>
  addControl(construir_creditos_html(), position = "bottomleft")

mapa_path <- file.path(graficos_dir, "mapa_tipologia_territorial.html")
resultado_mapa <- tryCatch({
  saveWidget(mapa_tipologia, mapa_path, selfcontained = TRUE)
  "selfcontained"
}, error = function(e) {
  cat("AVISO: selfcontained=TRUE fallo por memoria (pandoc). Reintentando con selfcontained=FALSE...\n")
  saveWidget(mapa_tipologia, mapa_path, selfcontained = FALSE)
  "con carpeta de dependencias (selfcontained=FALSE)"
})
cat("Mapa de tipologia guardado", resultado_mapa, "en", mapa_path, "\n")

cat("\n=== 07_mapa_tipologia OK ===\n")
