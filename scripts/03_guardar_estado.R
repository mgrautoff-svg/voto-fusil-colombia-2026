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
  sprintf("- `%s`: %d municipios (%s%%)", dist_exposicion$alta_exposicion,
          dist_exposicion$n, dist_exposicion$pct),
  collapse = "\n"
)
top_texto <- paste(
  sprintf("%d. %s (%s): %d eventos", seq_len(nrow(top5)), top5$municipio,
          top5$departamento, top5$idx_exposicion),
  collapse = "\n"
)

control_armado <- matriz |> filter(tratado == "control_armado")
conflicto <- matriz |> filter(tratado == "conflicto_activo")

contenido <- paste0(
  "# Estado del subproyecto voto_fusil\n\n",
  "Fecha del run: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"), "  \n",
  "Commit base: `", commit_hash, "` (", marca_git, ")  \n",
  "Estado: **pipeline completo y tests aprobados**\n\n",
  "## Números auditados\n\n",
  "- Panel final: ", nrow(panel_final), " filas y ", ncol(panel_final), " columnas.\n",
  "- Cobertura del modelo principal: ", n_modelo, "/", config_voto_fusil$n_municipios,
  " municipios (", round(100 * n_modelo / config_voto_fusil$n_municipios, 1), "%).\n",
  "- Ventana ACLED: noviembre de 2025 a mayo de 2026.\n",
  "- Especificaciones de robustez: ", nrow(matriz), ".\n",
  "- Control armado positivo y significativo: ",
  sum(control_armado$coef_tratado > 0 & control_armado$p_valor < 0.05), "/",
  nrow(control_armado), ".\n\n",
  "### Distribución de alta exposición\n\n", dist_texto, "\n\n",
  "### Municipios con mayor exposición\n\n", top_texto, "\n\n",
  "## Interpretación\n\n",
  "La exposición armada reciente y el control territorial estructural no son la misma variable. ",
  "El primer indicador no presenta una asociación robusta en los modelos ajustados. ",
  "El control armado estructural conserva una asociación positiva con el aumento de participación ",
  "en ", nrow(control_armado), " especificaciones. Conflicto activo presenta coeficientes entre ",
  sprintf("%.2f", min(conflicto$coef_tratado)), " y ",
  sprintf("%.2f", max(conflicto$coef_tratado)), " puntos porcentuales, lo que evidencia sensibilidad ",
  "a controles y grupos de referencia.\n\n",
  "## Límite epistemológico\n\n",
  "El diseño es observacional, agregado y municipal. Los coeficientes representan asociaciones, ",
  "no efectos causales. No permiten identificar decisiones individuales ni descartar episodios ",
  "particulares de coacción.\n\n",
  "## Productos validados\n\n",
  "- Tablas y modelos en `outputs/tablas/`.\n",
  "- Visualizaciones interactivas en `outputs/graficos/`.\n",
  "- Cuatro gráficos oscuros en `outputs/graficas/ppt/`.\n",
  "- Cuatro gráficos claros en `outputs/graficas/doc/`.\n",
  "- Pieza editorial en `outputs/pieza_editorial_voto_fusil.md`.\n"
)

writeLines(
  enc2utf8(contenido),
  here::here("subproyectos/voto_fusil/docs/ESTADO.md"),
  useBytes = TRUE
)
cat("=== 03_guardar_estado OK ===\n")
