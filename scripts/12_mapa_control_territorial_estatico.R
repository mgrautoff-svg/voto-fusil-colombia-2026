# Responsabilidad unica: generar un mapa estatico editorial del mapa integrado
# de control territorial y saltos atipicos de participacion.
# No recalcula modelos. Lee outputs ya auditados y exporta PNG para columna.
# Ejecutar desde D:/Dropbox/Reform_UIAF/ con:
# source("subproyectos/voto_fusil/scripts/12_mapa_control_territorial_estatico.R")

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(sf)
  library(ggplot2)
  library(ggrepel)
  library(here)
})

pad_dane <- function(x) sprintf("%05d", suppressWarnings(as.integer(as.character(x))))

tablas_dir <- here::here("subproyectos/voto_fusil/outputs/tablas")
out_dir <- here::here("subproyectos/voto_fusil/outputs/graficas/doc")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

panel_path <- file.path(tablas_dir, "panel_voto_fusil_final.rds")
metricas_path <- here::here(
  "subproyectos/electoral_2026_segunda_vuelta/outputs/mapas/tablas/metricas_mapas_electorales_2026.csv"
)
shape_path <- here::here(
  "data_raw/electoral/Municipios_Septiembre_2025_shp/Municipios_Septiembre_2025_.shp"
)

stopifnot(file.exists(panel_path), file.exists(metricas_path), file.exists(shape_path))

panel_final <- readRDS(panel_path) |>
  select(cod_dane, municipio, departamento, tipologia_d2) |>
  mutate(cod_dane = pad_dane(cod_dane))

metricas_2026 <- read_csv(metricas_path, show_col_types = FALSE) |>
  mutate(cod_dane = pad_dane(codigo_municipio)) |>
  select(
    cod_dane, ganador_2v, pct_2v_cepeda, pct_2v_espriella,
    participacion_1v, participacion_2v, variacion_participacion_pp
  )

etiquetas_tipologia <- tibble::tribble(
  ~tipologia_d2,          ~tipologia_label,
  "control_armado",       "Control armado",
  "conflicto_activo",     "Conflicto activo",
  "corredor",             "Corredor estratégico",
  "produccion_intensiva", "Producción intensiva",
  "periferico",           "Sin conflicto activo"
)

datos_mapa <- panel_final |>
  inner_join(metricas_2026, by = "cod_dane") |>
  left_join(etiquetas_tipologia, by = "tipologia_d2") |>
  rename(cambio_participacion_pp = variacion_participacion_pp) |>
  mutate(
    ganador_2v = factor(ganador_2v, levels = c("Cepeda", "Espriella")),
    cepeda_90 = pct_2v_cepeda >= 90,
    espriella_90 = pct_2v_espriella >= 90,
    voto_90 = cepeda_90 | espriella_90
  )

stopifnot(!anyNA(datos_mapa$tipologia_label))
stopifnot(!anyNA(datos_mapa$cambio_participacion_pp))
stopifnot(all(datos_mapa$pct_2v_cepeda >= 0 & datos_mapa$pct_2v_cepeda <= 100))
stopifnot(all(datos_mapa$pct_2v_espriella >= 0 & datos_mapa$pct_2v_espriella <= 100))

shape <- st_read(shape_path, quiet = TRUE) |>
  st_transform(4326) |>
  st_simplify(dTolerance = 1200, preserveTopology = TRUE) |>
  mutate(cod_dane = pad_dane(MpCodigo)) |>
  filter(cod_dane != "00000")

mapa_sf <- shape |>
  left_join(datos_mapa, by = "cod_dane")

stopifnot(nrow(mapa_sf) == nrow(shape))
stopifnot(sum(is.na(mapa_sf$tipologia_label)) == 0)

umbral_p90 <- as.numeric(
  quantile(mapa_sf$cambio_participacion_pp, 0.90, na.rm = TRUE)
)

centroides <- suppressWarnings(
  mapa_sf |>
    filter(cambio_participacion_pp >= umbral_p90) |>
    st_transform(3857) |>
    st_point_on_surface() |>
    st_transform(4326) |>
    mutate(
      tipo_bola = case_when(
        cepeda_90 ~ "Cepeda >90% + salto abrupto",
        espriella_90 ~ "Espriella >90% + salto abrupto",
        TRUE ~ "Otros saltos p90"
      ),
      etiqueta = if_else(
        voto_90,
        paste0(municipio, " · ", sprintf("%+.1f pp", cambio_participacion_pp)),
        NA_character_
      )
    )
)

centroides_label <- centroides |>
  filter(!is.na(etiqueta)) |>
  arrange(desc(cambio_participacion_pp)) |>
  slice_head(n = 9)

colores_tipologia <- c(
  "Control armado" = "#8B0000",
  "Conflicto activo" = "#E05C00",
  "Corredor estratégico" = "#F5A623",
  "Producción intensiva" = "#F5D87A",
  "Sin conflicto activo" = "#E9E5DC"
)

colores_bolas <- c(
  "Cepeda >90% + salto abrupto" = "#D71920",
  "Espriella >90% + salto abrupto" = "#1565C0",
  "Otros saltos p90" = "#FFFFFF"
)

caption_mapa <- paste(
  strwrap(
    paste0(
      "Nota: los círculos no marcan fraude ni conducta individual; resaltan municipios donde la participación ",
      "subió de forma abrupta entre primera y segunda vuelta. Las etiquetas muestran los mayores casos con voto ",
      "superior al 90% por un candidato. Fuente y construcción: Manfred Grautoff · Sistema E4, Registraduría, ACLED."
    ),
    width = 155
  ),
  collapse = "\n"
)

mapa <- ggplot() +
  geom_sf(
    data = mapa_sf,
    aes(fill = tipologia_label),
    color = "white",
    linewidth = 0.035
  ) +
  geom_sf(
    data = centroides,
    aes(size = cambio_participacion_pp, fill = tipo_bola),
    shape = 21,
    color = "#202124",
    stroke = 0.28,
    alpha = 0.82,
    show.legend = TRUE
  ) +
  ggrepel::geom_label_repel(
    data = centroides_label |> mutate(x = st_coordinates(geometry)[, 1], y = st_coordinates(geometry)[, 2]),
    aes(x = x, y = y, label = etiqueta),
    size = 2.65,
    family = "sans",
    color = "#202124",
    fill = alpha("#FFFFFF", 0.86),
    label.size = 0,
    label.padding = unit(0.12, "lines"),
    lineheight = 0.9,
    box.padding = 0.28,
    point.padding = 0.18,
    min.segment.length = 0,
    segment.color = "#666666",
    segment.linewidth = 0.25,
    max.overlaps = Inf
  ) +
  scale_fill_manual(
    values = c(colores_tipologia, colores_bolas),
    breaks = c(names(colores_tipologia), names(colores_bolas)),
    name = NULL
  ) +
  scale_size_continuous(
    range = c(1.3, 5.8),
    breaks = c(13, 20, 28),
    name = "Aumento de participación"
  ) +
  coord_sf(datum = NA) +
  labs(
    title = "Los saltos atípicos no se repartieron al azar",
    subtitle = paste0(
      "Color: arquitectura territorial · círculo: salto de participación sobre p90 (+",
      sprintf("%.2f", umbral_p90), " pp) · rojo: Cepeda >90%"
    ),
    caption = caption_mapa
  ) +
  theme_void(base_size = 12) +
  theme(
    plot.background = element_rect(fill = "#FFFFFF", color = NA),
    panel.background = element_rect(fill = "#FFFFFF", color = NA),
    plot.title = element_text(face = "bold", size = 21, color = "#202124", margin = margin(b = 4)),
    plot.subtitle = element_text(size = 10.5, color = "#4A4A4A", margin = margin(b = 10)),
    plot.caption = element_text(size = 8.2, color = "#555555", hjust = 0, margin = margin(t = 10)),
    legend.position = "right",
    legend.title = element_text(face = "bold", size = 10, color = "#202124"),
    legend.text = element_text(size = 9, color = "#202124"),
    legend.key = element_rect(fill = "#FFFFFF", color = NA),
    legend.background = element_rect(fill = "#FFFFFF", color = NA),
    plot.margin = margin(18, 18, 18, 18)
  ) +
  guides(
    fill = guide_legend(
      override.aes = list(size = 4, color = c(rep(NA, 5), rep("#202124", 3))),
      order = 1
    ),
    size = guide_legend(order = 2)
  )

out_path <- file.path(out_dir, "06_mapa_control_territorial_atipicos.png")
ggsave(out_path, mapa, width = 11.8, height = 8.4, dpi = 220, bg = "#FFFFFF")

cat("Mapa estatico guardado en:", out_path, "\n")
cat("Umbral p90 cambio participacion:", sprintf("%.2f", umbral_p90), "pp\n")
cat("Municipios con circulo:", nrow(centroides), "\n")
cat("Municipios etiquetados:", nrow(centroides_label), "\n")
cat("=== 12_mapa_control_territorial_estatico OK ===\n")
