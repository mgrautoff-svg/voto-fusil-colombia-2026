# Responsabilidad unica: exportar graficas finales estaticas en versiones
# oscura (PPT) y clara (DOC), usando exclusivamente resultados ya calculados.

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(readr)
  library(sf)
})

tablas_dir <- here::here("subproyectos/voto_fusil/outputs/tablas")
dir_ppt <- here::here("subproyectos/voto_fusil/outputs/graficas/ppt")
dir_doc <- here::here("subproyectos/voto_fusil/outputs/graficas/doc")
dir.create(dir_ppt, recursive = TRUE, showWarnings = FALSE)
dir.create(dir_doc, recursive = TRUE, showWarnings = FALSE)

tema_voto_fusil <- function(oscuro = FALSE) {
  fondo <- if (oscuro) "#101418" else "#FFFFFF"
  texto <- if (oscuro) "#F2F2F2" else "#202124"
  grilla <- if (oscuro) "#394149" else "#E6E6E6"
  theme_minimal(base_size = 12) +
    theme(
      plot.background = element_rect(fill = fondo, color = NA),
      panel.background = element_rect(fill = fondo, color = NA),
      legend.background = element_rect(fill = fondo, color = NA),
      legend.key = element_rect(fill = fondo, color = NA),
      text = element_text(color = texto),
      axis.text = element_text(color = texto),
      plot.title = element_text(face = "bold", size = 17),
      plot.subtitle = element_text(color = texto),
      panel.grid.major = element_line(color = grilla, linewidth = 0.25),
      panel.grid.minor = element_blank(),
      plot.caption = element_text(color = texto, hjust = 0)
    )
}

guardar_doble <- function(construir, nombre, ancho = 10, alto = 6) {
  for (oscuro in c(TRUE, FALSE)) {
    grafica <- construir(oscuro)
    destino <- if (oscuro) dir_ppt else dir_doc
    fondo <- if (oscuro) "#101418" else "#FFFFFF"
    ggsave(
      file.path(destino, paste0(nombre, ".png")), grafica,
      width = ancho, height = alto, dpi = 180, bg = fondo
    )
  }
}

resumen <- read_csv(file.path(tablas_dir, "resumen_cuatro_grupos.csv"), show_col_types = FALSE) |>
  mutate(
    grupo = factor(
      grupo,
      levels = c("exterior", "resto_colombia", "conflicto_activo", "control_armado"),
      labels = c("Exterior", "Resto de Colombia", "Conflicto activo", "Control armado")
    )
  )

guardar_doble(function(oscuro) {
  ggplot(resumen, aes(grupo, media_cambio_pp, fill = grupo)) +
    geom_col(width = 0.68, show.legend = FALSE) +
    geom_text(
      aes(label = sprintf("%.2f pp", media_cambio_pp)),
      vjust = -0.5, color = if (oscuro) "#F2F2F2" else "#202124", fontface = "bold"
    ) +
    scale_fill_manual(values = c("#73808C", "#477998", "#D68C45", "#8E2F45")) +
    scale_y_continuous(expand = expansion(mult = c(0, 0.14))) +
    labs(
      title = "Cambio de participación entre vueltas",
      subtitle = "Promedio municipal o por país, según grupo territorial",
      x = NULL, y = "Puntos porcentuales",
      caption = "Asociaciones descriptivas; no identifican un efecto causal."
    ) + tema_voto_fusil(oscuro)
}, "01_cambio_participacion_grupos")

matriz <- read_csv(file.path(tablas_dir, "matriz_robustez_completa.csv"), show_col_types = FALSE) |>
  filter(referencia != "exterior") |>
  mutate(
    tratado = recode(tratado, control_armado = "Control armado", conflicto_activo = "Conflicto activo"),
    especificacion = paste(referencia, controles, sep = " · ")
  )

guardar_doble(function(oscuro) {
  ggplot(matriz, aes(coef_tratado, reorder(especificacion, coef_tratado), color = tratado)) +
    geom_vline(xintercept = 0, color = if (oscuro) "#D0D0D0" else "#555555", linetype = 2) +
    geom_errorbar(
      aes(xmin = ic95_inf, xmax = ic95_sup),
      orientation = "y", width = 0.15, linewidth = 0.7
    ) +
    geom_point(size = 2.5) +
    facet_wrap(~tratado, scales = "free_y") +
    scale_color_manual(values = c("Conflicto activo" = "#D68C45", "Control armado" = "#B83B5E")) +
    labs(
      title = "La estabilidad depende de la definición territorial",
      subtitle = "Coeficientes e intervalos de confianza del 95% frente a referencias domésticas",
      x = "Cambio asociado en participación (pp)", y = NULL, color = NULL,
      caption = "OLS con errores robustos HC1. IPM y ruralidad según especificación."
    ) + tema_voto_fusil(oscuro) + theme(legend.position = "none")
}, "02_robustez_tipologias", ancho = 11, alto = 7)

modelo_voto <- read_csv(file.path(tablas_dir, "modelo_voto_fusil_controles.csv"), show_col_types = FALSE) |>
  filter(termino == "alta_exposicionTRUE") |>
  mutate(resultado = "Cambio de voto")
modelo_part <- read_csv(file.path(tablas_dir, "modelo_participacion_controles.csv"), show_col_types = FALSE) |>
  filter(termino == "alta_exposicionTRUE") |>
  mutate(resultado = "Cambio de participación")
modelos_exposicion <- bind_rows(modelo_voto, modelo_part) |>
  mutate(
    ic95_inf = estimacion - 1.96 * error_estandar_hc1,
    ic95_sup = estimacion + 1.96 * error_estandar_hc1
  )

guardar_doble(function(oscuro) {
  ggplot(modelos_exposicion, aes(estimacion, resultado)) +
    geom_vline(xintercept = 0, color = if (oscuro) "#D0D0D0" else "#555555", linetype = 2) +
    geom_errorbar(
      aes(xmin = ic95_inf, xmax = ic95_sup),
      orientation = "y", width = 0.12, color = "#D75A4A"
    ) +
    geom_point(size = 3, color = "#D75A4A") +
    labs(
      title = "La exposición armada reciente no presenta asociación robusta",
      subtitle = "Indicador sobre percentil 75, con controles territoriales",
      x = "Coeficiente e intervalo de confianza del 95%", y = NULL,
      caption = "La ausencia de asociación estadística no prueba ausencia de coerción individual."
    ) + tema_voto_fusil(oscuro)
}, "03_exposicion_reciente_modelos", ancho = 9, alto = 5)

panel_final <- readRDS(file.path(tablas_dir, "panel_voto_fusil_final.rds"))
shape <- st_read(here::here(config_voto_fusil$rutas$shape_municipal), quiet = TRUE) |>
  mutate(cod_dane = sprintf("%05d", as.integer(MpCodigo))) |>
  filter(cod_dane != "00000") |>
  left_join(panel_final |> select(cod_dane, tipologia_d2), by = "cod_dane")
municipios_sin_tipologia <- shape |>
  st_drop_geometry() |>
  filter(is.na(tipologia_d2)) |>
  select(cod_dane) |>
  distinct()
if (nrow(municipios_sin_tipologia) > 0L) {
  stop(
    "Municipios del shapefile sin tipologia_d2 en panel_voto_fusil_final: ",
    paste(municipios_sin_tipologia$cod_dane, collapse = ", "),
    call. = FALSE
  )
}

guardar_doble(function(oscuro) {
  ggplot(shape) +
    geom_sf(aes(fill = tipologia_d2), color = if (oscuro) "#30363C" else "#FFFFFF", linewidth = 0.05) +
    scale_fill_manual(
      values = c(
        control_armado = "#8E2F45", conflicto_activo = "#D06B32", corredor = "#C9A227",
        produccion_intensiva = "#63783C", periferico = if (oscuro) "#5A6066" else "#DDD8CF"
      ),
      labels = c(
        control_armado = "Control armado", conflicto_activo = "Conflicto activo",
        corredor = "Corredor estratégico", produccion_intensiva = "Producción intensiva",
        periferico = "Sin conflicto activo"
      )
    ) +
    coord_sf(datum = NA) +
    labs(
      title = "Arquitecturas territoriales de control y conflicto",
      subtitle = "Tipología municipal estructural del Sistema E4",
      fill = NULL,
      caption = "La tipología describe territorios; no identifica conducta individual."
    ) + tema_voto_fusil(oscuro) +
    theme(axis.text = element_blank(), axis.title = element_blank(), panel.grid = element_blank())
}, "04_mapa_tipologia_territorial", ancho = 8, alto = 8)

cat("=== 09_graficas_ppt_doc OK ===\n")
