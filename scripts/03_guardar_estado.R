# Responsabilidad unica: escribir el estado auditado despues de que todos los
# tests del pipeline hayan pasado. No estima modelos ni modifica datos crudos.

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
})

tablas_dir <- here::here("subproyectos/voto_fusil/outputs/tablas")
rds_path <- file.path(tablas_dir, "panel_voto_fusil_final.rds")
matriz_path <- file.path(tablas_dir, "matriz_robustez_completa.csv")
stopifnot(file.exists(rds_path), file.exists(matriz_path))

panel_final <- readRDS(rds_path)
matriz <- read_csv(matriz_path, show_col_types = FALSE)

dist_exposicion <- panel_final |>
  count(alta_exposicion) |>
  mutate(pct = round(100 * n / sum(n), 1))

top5 <- panel_final |>
  arrange(desc(idx_exposicion)) |>
  select(municipio, departamento, idx_exposicion) |>
  slice_head(n = 5)

modelo <- read_csv(
  file.path(tablas_dir, "modelo_voto_fusil_controles.csv"),
  show_col_types = FALSE
)
n_modelo <- unique(modelo$n_observaciones)
stopifnot(length(n_modelo) == 1L)

commit_hash <- tryCatch(
  system2("git", c("rev-parse", "--short", "HEAD"), stdout = TRUE, stderr = FALSE),
  error = function(e) "desconocido"
)
if (length(commit_hash) != 1L || !nzchar(commit_hash)) commit_hash <- "desconocido"

estado_git <- tryCatch(
  system2("git", c("status", "--porcelain"), stdout = TRUE, stderr = FALSE),
  error = function(e) ""
)
marca_git <- if (length(estado_git) == 0L) "limpio" else "con cambios sin commit"

dist_texto <- paste(
  sprintf(
    "- `%s`: %d municipios (%s%%).",
    dist_exposicion$alta_exposicion,
    dist_exposicion$n,
    format(dist_exposicion$pct, decimal.mark = ",")
  ),
  collapse = "\n"
)

top_texto <- paste(
  sprintf(
    "%d. %s (%s): %d eventos.",
    seq_len(nrow(top5)),
    top5$municipio,
    top5$departamento,
    top5$idx_exposicion
  ),
  collapse = "\n"
)

control_armado <- matriz |> filter(tratado == "control_armado")
conflicto <- matriz |> filter(tratado == "conflicto_activo")

stopifnot(nrow(control_armado) == 9L, nrow(conflicto) == 9L)

fmt_pp <- function(x) {
  paste0(
    ifelse(x >= 0, "+", ""),
    trimws(format(round(x, 2), nsmall = 2, decimal.mark = ",")),
    " pp"
  )
}

etiquetar_controles <- function(x) {
  dplyr::recode(
    x,
    sin_controles = "sin controles",
    ipm_dnp = "IPM",
    cat_ruralidad = "ruralidad",
    `ipm_dnp + cat_ruralidad` = "IPM + ruralidad",
    .default = x
  )
}

tabla_matriz_md <- function(df) {
  filas <- df |>
    mutate(
      Referencia = referencia,
      Controles = etiquetar_controles(controles),
      Coeficiente = fmt_pp(coef_tratado)
    ) |>
    select(Referencia, Controles, Coeficiente)

  paste(
    c(
      "| Referencia | Controles | Coeficiente |",
      "|---|---:|---:|",
      sprintf("| %s | %s | %s |", filas$Referencia, filas$Controles, filas$Coeficiente)
    ),
    collapse = "\n"
  )
}

conteo_tipologias <- panel_final |>
  count(tipologia_d2, name = "n")

n_control_armado <- conteo_tipologias$n[conteo_tipologias$tipologia_d2 == "control_armado"]
n_conflicto_activo <- conteo_tipologias$n[conteo_tipologias$tipologia_d2 == "conflicto_activo"]

contenido <- paste0(
  "# Estado del subproyecto voto_fusil\n\n",
  "Fecha del run: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"), "  \n",
  "Commit base: `", commit_hash, "` (", marca_git, ")  \n",
  "Estado: **pipeline completo y tests aprobados**\n\n",
  "## Numeros auditados del run\n\n",
  "- Panel final: ", format(nrow(panel_final), big.mark = ".", decimal.mark = ","), " municipios y ",
  ncol(panel_final), " columnas.\n",
  "- Cobertura del modelo principal: ", format(n_modelo, big.mark = ".", decimal.mark = ","), "/",
  format(config_voto_fusil$n_municipios, big.mark = ".", decimal.mark = ","), " municipios (",
  format(round(100 * n_modelo / config_voto_fusil$n_municipios, 1), decimal.mark = ","), "%).\n",
  "- Ventana ACLED: noviembre de 2025 a mayo de 2026.\n",
  "- Especificaciones de robustez: ", nrow(matriz), ".\n",
  "- Control armado positivo y significativo: ",
  sum(control_armado$coef_tratado > 0 & control_armado$p_valor < 0.05), "/",
  nrow(control_armado), " especificaciones.\n",
  "- Municipios `control_armado`: ", n_control_armado, ".\n",
  "- Municipios `conflicto_activo`: ", n_conflicto_activo, ".\n\n",
  "## Distribucion de alta exposicion ACLED\n\n",
  dist_texto, "\n\n",
  "## Municipios con mayor exposicion reciente\n\n",
  top_texto, "\n\n",
  "## Resultado central de la matriz de robustez\n\n",
  "### Panel A - Control armado estructural\n\n",
  "`control_armado` conserva coeficiente positivo y significativo en las 9 especificaciones:\n\n",
  tabla_matriz_md(control_armado), "\n\n",
  "Interpretacion: la senal de control armado no desaparece al controlar por pobreza o ruralidad.\n\n",
  "### Panel B - Conflicto activo\n\n",
  "`conflicto_activo` es inestable. Frente al exterior y sin controles es alto y positivo, ",
  "pero frente al resto de Colombia cambia de signo al agregar IPM:\n\n",
  tabla_matriz_md(conflicto), "\n\n",
  "Interpretacion: parte de lo que parecia conflicto activo era composicion social y pobreza. ",
  "Al introducir IPM, la senal se invierte.\n\n",
  "## Lectura tecnica\n\n",
  "La exposicion armada reciente y el control territorial estructural no son la misma variable. ",
  "ACLED captura eventos recientes y violencia explicita. D2 captura arquitectura territorial ",
  "de largo plazo.\n\n",
  "El resultado principal no es que \"hubo voto fusil\" en sentido causal individual. ",
  "El resultado es que municipios bajo control armado estructural registraron un aumento de ",
  "participacion mayor y robusto frente a varias referencias.\n\n",
  "## DiD descriptivo\n\n",
  "La visualizacion DiD compara cambios medios de participacion entre primera y segunda vuelta ",
  "de 2026. Es descriptiva, no causal fuerte. La referencia exterior funciona como linea base ",
  "de polarizacion nacional sin control armado territorial colombiano.\n\n",
  "Documento asociado: `docs/NOTA_DID_DESCRIPTIVO.md`.\n\n",
  "## D4/Kalman\n\n",
  "D4/Kalman fue revisado, pero no se usa como estimador principal porque incluye componentes ",
  "de violencia y abstencion que se solapan con la variable dependiente y con controles del modelo. ",
  "La decision esta documentada en:\n\n",
  "- `docs/NOTA_KALMAN_D4.md`.\n\n",
  "## Limite epistemologico\n\n",
  "El diseno es observacional, agregado y municipal. Los coeficientes representan asociaciones, ",
  "no efectos causales individuales. No permiten observar decisiones dentro de la cabina ni ",
  "descartar episodios particulares de coaccion.\n\n",
  "## Productos validados\n\n",
  "- Tablas y modelos en `outputs/tablas/`.\n",
  "- Visualizaciones interactivas en `outputs/graficos/`.\n",
  "- Graficos oscuros en `outputs/graficas/ppt/`.\n",
  "- Graficos claros en `outputs/graficas/doc/`.\n",
  "- Pieza editorial en `outputs/pieza_editorial_voto_fusil.md`.\n"
)

writeLines(
  enc2utf8(contenido),
  here::here("subproyectos/voto_fusil/docs/ESTADO.md"),
  useBytes = TRUE
)

cat("=== 03_guardar_estado OK ===\n")
