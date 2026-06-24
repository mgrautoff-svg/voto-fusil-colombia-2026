# Responsabilidad unica: serializar/auditar el resultado ya producido por
# 02_analisis.R. No hace joins ni transformaciones, no toca nada fuera de
# subproyectos/voto_fusil/. Ejecutar desde D:/Dropbox/Reform_UIAF/

suppressPackageStartupMessages(library(dplyr))

# --- Paso 1: verificar prerequisito ------------------------------------------
rds_path <- here::here("subproyectos/voto_fusil/outputs/tablas/panel_voto_fusil_final.rds")
if (!file.exists(rds_path)) {
  stop("Correr 02_analisis.R primero", call. = FALSE)
}

# --- Paso 2: leer y auditar ---------------------------------------------------
panel_final <- readRDS(rds_path)

n_filas <- nrow(panel_final)
n_columnas <- ncol(panel_final)

dist_exposicion <- panel_final |>
  count(alta_exposicion) |>
  mutate(pct = round(100 * n / sum(n), 1))

top5 <- panel_final |>
  arrange(desc(idx_exposicion)) |>
  select(municipio, departamento, idx_exposicion) |>
  slice_head(n = 5)

rango_acled <- "Noviembre 2025 - mayo 2026 (ver decision metodologica en este mismo ESTADO.md)"
fecha_generacion <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")

commit_hash <- tryCatch(
  system("git rev-parse --short HEAD", intern = TRUE, ignore.stderr = TRUE),
  error = function(e) "desconocido",
  warning = function(w) "desconocido"
)
if (length(commit_hash) == 0 || identical(commit_hash, "")) commit_hash <- "desconocido"

# --- Paso 3: escribir bloque auditado en ESTADO.md (solo agregar, nunca sobreescribir) ---
estado_path <- here::here("subproyectos/voto_fusil/docs/ESTADO.md")

dist_texto <- paste(
  sprintf("  - %s: %d municipios (%s%%)", dist_exposicion$alta_exposicion,
          dist_exposicion$n, dist_exposicion$pct),
  collapse = "\n"
)

top5_texto <- paste(
  sprintf("  %d. %s (%s) - idx_exposicion: %d",
          seq_len(nrow(top5)), top5$municipio, top5$departamento, top5$idx_exposicion),
  collapse = "\n"
)

bloque <- paste0(
  "\n## Numeros auditados -- generado por 03_guardar_estado.R\n\n",
  "Fecha de generacion: ", fecha_generacion, "\n",
  "Commit: ", commit_hash, "\n\n",
  "Panel final: ", n_filas, " filas, ", n_columnas, " columnas\n\n",
  "Distribucion alta_exposicion:\n", dist_texto, "\n\n",
  "Top 5 municipios por idx_exposicion:\n", top5_texto, "\n\n",
  "Rango temporal ACLED usado: ", rango_acled, "\n"
)

cat(bloque, file = estado_path, append = TRUE)

# --- Paso 4 ---
cat("=== 03_guardar_estado OK ===\n")
