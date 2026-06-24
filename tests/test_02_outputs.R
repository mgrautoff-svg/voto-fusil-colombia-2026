# Verifica que los outputs de 02_analisis.R existen con las dimensiones
# correctas. Ejecutar desde D:/Dropbox/Reform_UIAF/

suppressPackageStartupMessages(library(readr))

cat("=== TEST: OUTPUTS voto_fusil ===\n")

out_dir <- here::here("subproyectos/voto_fusil/outputs/tablas")

archivos_esperados <- list(
  list(archivo = "panel_voto_fusil_final.csv", filas = 1122L, tipo = "csv"),
  list(archivo = "panel_voto_fusil_final.rds", filas = 1122L, tipo = "rds"),
  list(archivo = "tabla_descriptiva_exposicion.csv", filas = 2L, tipo = "csv"),
  list(archivo = "tabla_cambio_voto_exposicion.csv", filas = 2L, tipo = "csv"),
  list(archivo = "test_diferencia_cambio_pp.csv", filas = 1L, tipo = "csv"),
  list(archivo = "modelo_voto_fusil_controles.csv", filas = 8L, tipo = "csv"),
  list(archivo = "tabla_forero_participacion.csv", filas = 2L, tipo = "csv")
)

for (esp in archivos_esperados) {
  ruta <- file.path(out_dir, esp$archivo)

  if (!file.exists(ruta)) {
    stop(sprintf("Falta el archivo: %s", esp$archivo), call. = FALSE)
  }

  df <- if (esp$tipo == "rds") readRDS(ruta) else read_csv(ruta, show_col_types = FALSE)

  if (nrow(df) != esp$filas) {
    stop(sprintf(
      "%s: se esperaban %d filas, hay %d", esp$archivo, esp$filas, nrow(df)
    ), call. = FALSE)
  }

  cat(sprintf("OK: %s (%d filas)\n", esp$archivo, nrow(df)))
}

cat("\n=== test_02_outputs PASSED ===\n")
