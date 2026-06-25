# Responsabilidad unica: crear una visual estatica editorial para columna
# sobre municipios con >90% de share y aumento abrupto de participacion.
# Lee la tabla producida por 10_tabla_atipicos_columna.R y exporta PNG.

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(readr)
  library(stringr)
})

tabla_path <- here::here(
  "subproyectos", "voto_fusil", "outputs", "tablas",
  "tabla_atipicos_90_participacion.csv"
)

if (!file.exists(tabla_path)) {
  stop(
    "No existe tabla_atipicos_90_participacion.csv. ",
    "Ejecute antes scripts/10_tabla_atipicos_columna.R.",
    call. = FALSE
  )
}

salida_dir <- here::here("subproyectos", "voto_fusil", "outputs", "graficas", "doc")
dir.create(salida_dir, recursive = TRUE, showWarnings = FALSE)

tabla <- read_csv(tabla_path, show_col_types = FALSE)

umbral_p90 <- 12.98
n_cepeda <- sum(tabla$pct_cepeda >= 90, na.rm = TRUE)
n_espriella <- sum(tabla$pct_espriella >= 90, na.rm = TRUE)

datos_plot <- tabla |>
  filter(pct_cepeda >= 90) |>
  arrange(variacion_participacion_pp) |>
  mutate(
    municipio_label = paste0(municipio, " · ", departamento),
    municipio_label = factor(municipio_label, levels = municipio_label),
    etiqueta_valor = paste0(
      sprintf("%.1f", pct_cepeda), "% Cepeda",
      "  ·  +", sprintf("%.1f", variacion_participacion_pp), " pp"
    ),
    tipologia_label = recode(
      tipologia_d2,
      control_armado = "Control armado",
      conflicto_activo = "Conflicto activo",
      corredor = "Corredor",
      produccion_intensiva = "Producción intensiva",
      periferico = "Periférico",
      .default = tipologia_d2
    )
  )

stopifnot(nrow(datos_plot) > 0L)

colores_tipologia <- c(
  "Control armado" = "#8B0000",
  "Conflicto activo" = "#E05C00",
  "Corredor" = "#F5A623",
  "Producción intensiva" = "#C9A227",
  "Periférico" = "#7A7A7A"
)

fondo <- "#1f1f1d"
panel <- "#242421"
texto <- "#F4EFE6"
muted <- "#BDB7A9"
acento <- "#FF6A00"

visual <- ggplot(
  datos_plot,
  aes(x = variacion_participacion_pp, y = municipio_label, fill = tipologia_label)
) +
  geom_col(width = 0.72, alpha = 0.96) +
  geom_vline(
    xintercept = umbral_p90,
    color = muted,
    linewidth = 0.45,
    linetype = "dashed"
  ) +
  geom_text(
    aes(label = etiqueta_valor),
    x = 0.45,
    hjust = 0,
    color = texto,
    size = 3.55,
    fontface = "bold"
  ) +
  annotate(
    "text",
    x = umbral_p90,
    y = Inf,
    label = "umbral p90",
    vjust = 1.7,
    hjust = -0.08,
    color = muted,
    size = 3.25,
    fontface = "bold"
  ) +
  scale_fill_manual(values = colores_tipologia, drop = FALSE) +
  scale_x_continuous(
    limits = c(0, max(datos_plot$variacion_participacion_pp, na.rm = TRUE) + 1.7),
    breaks = seq(0, 30, 5),
    labels = function(x) paste0("+", x, " pp"),
    expand = expansion(mult = c(0, 0))
  ) +
  labs(
    title = "Concentración extrema y salto de participación",
    subtitle = str_wrap(
      paste0(
        "Municipios con más de 90% para un candidato y participación por encima del p90",
        " · Cepeda: ", n_cepeda, " · Espriella: ", n_espriella
      ),
      width = 96
    ),
    x = "Aumento de participación entre primera y segunda vuelta de 2026",
    y = NULL,
    fill = NULL,
    caption = str_wrap(
      paste0(
        "Fuente y construcción: Manfred Grautoff · Sistema E4, Registraduría, ACLED. ",
        "Umbral abrupto: p90 = +", sprintf("%.2f", umbral_p90), " pp. ",
        "La visual no prueba coerción individual; muestra concentración territorial extrema con movilización simultánea."
      ),
      width = 135
    )
  ) +
  theme_minimal(base_family = "serif", base_size = 12) +
  theme(
    plot.background = element_rect(fill = fondo, color = NA),
    panel.background = element_rect(fill = fondo, color = NA),
    legend.background = element_rect(fill = fondo, color = NA),
    legend.key = element_rect(fill = fondo, color = NA),
    plot.title = element_text(
      color = texto, size = 24, face = "bold", margin = margin(b = 6)
    ),
    plot.subtitle = element_text(
      color = muted, size = 12.6, face = "bold", margin = margin(b = 18),
      lineheight = 1.05
    ),
    plot.caption = element_text(
      color = muted, size = 10.2, hjust = 0, margin = margin(t = 14),
      lineheight = 1.15
    ),
    axis.title.x = element_text(color = muted, size = 11, face = "bold", margin = margin(t = 10)),
    axis.text.x = element_text(color = muted, size = 10),
    axis.text.y = element_text(color = texto, size = 11.5, face = "bold"),
    panel.grid.major.y = element_blank(),
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_line(color = "#3A3A36", linewidth = 0.28),
    legend.position = "bottom",
    legend.text = element_text(color = texto, size = 10.5, face = "bold"),
    plot.margin = margin(28, 34, 24, 28)
  ) +
  guides(fill = guide_legend(nrow = 1, byrow = TRUE))

png_path <- here::here(
  "subproyectos", "voto_fusil", "outputs", "graficas", "doc",
  "05_visual_atipicos_90_participacion.png"
)

ggsave(
  filename = png_path,
  plot = visual,
  width = 12.8,
  height = 8.6,
  dpi = 240,
  bg = fondo
)

cat("Visual estatica:", png_path, "\n")
cat("Cepeda >=90% con aumento abrupto:", n_cepeda, "\n")
cat("Espriella >=90% con aumento abrupto:", n_espriella, "\n")
cat("=== 11_visual_atipicos_columna OK ===\n")
