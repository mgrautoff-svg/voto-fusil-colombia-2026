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
  list(archivo = "tabla_forero_participacion.csv", filas = 2L, tipo = "csv"),
  list(archivo = "modelo_participacion_controles.csv", filas = 9L, tipo = "csv"),
  list(archivo = "modelo_voto_fusil_D2.csv", filas = 12L, tipo = "csv"),
  list(archivo = "modelo_participacion_D2.csv", filas = 13L, tipo = "csv"),
  list(archivo = "resumen_cuatro_grupos.csv", filas = 4L, tipo = "csv"),
  list(archivo = "did_cuatro_grupos.csv", filas = 6L, tipo = "csv"),
  list(archivo = "did_ajustado_ipm_ruralidad.csv", filas = 6L, tipo = "csv"),
  list(archivo = "matriz_robustez_completa.csv", filas = 18L, tipo = "csv"),
  list(archivo = "tabla1_tabla2_did_resumen.csv", filas = 2L, tipo = "csv")
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

archivos_finales <- c(
  here::here("subproyectos/voto_fusil/outputs/pieza_editorial_voto_fusil.md"),
  file.path(here::here("subproyectos/voto_fusil/outputs/graficos"), c(
    "viz_01_mapa_exposicion.html", "viz_02_gradiente_ruralidad.html",
    "viz_03_panel_coeficientes.html", "viz_04_forero_bruto_vs_controlado.html",
    "viz_did_intuitiva.html",
    "mapa_control_territorial.html", "mapa_tipologia_territorial.html"
  ))
)

for (ruta in archivos_finales) {
  if (!file.exists(ruta) || file.info(ruta)$size < 100L) {
    stop("Output final ausente o vacio: ", ruta, call. = FALSE)
  }
}

nombres_graficas <- sprintf("%02d_%s.png", 1:4, c(
  "cambio_participacion_grupos", "robustez_tipologias",
  "exposicion_reciente_modelos", "mapa_tipologia_territorial"
))
for (variante in c("ppt", "doc")) {
  rutas <- file.path(
    here::here("subproyectos/voto_fusil/outputs/graficas", variante),
    nombres_graficas
  )
  if (any(!file.exists(rutas)) || any(file.info(rutas)$size < 10000L)) {
    stop("Faltan graficas validas en variante ", variante, call. = FALSE)
  }
}

cat("OK: productos editoriales, interactivos y 8 graficas PPT/DOC verificados.\n")

cat("\n=== test_02_outputs PASSED ===\n")
