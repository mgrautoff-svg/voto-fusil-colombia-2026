# Responsabilidad unica: cargar los tres insumos de voto_fusil y verificar
# que tienen las dimensiones esperadas. No hace joins ni transformaciones.
# Prerequisitos: los tres archivos listados abajo deben existir.
# Ejecutar desde D:/Dropbox/Reform_UIAF/

suppressPackageStartupMessages({
  library(readr)
  library(readxl)
  library(dplyr)
})

pad_dane <- function(x) sprintf("%05d", suppressWarnings(as.integer(as.character(x))))

# --- 1. Panel electoral historico (2018-2022), ya limpio de duplicados ---
panel_path <- here::here("data_raw/electoral/base_electoral_2026_panel_limpio.csv")
stopifnot(file.exists(panel_path))
panel <- read_csv(panel_path, show_col_types = FALSE)

stopifnot(nrow(panel) == 1122L)
stopifnot(ncol(panel) == 94L)
stopifnot("cod_dane" %in% names(panel))

# --- 2. ACLED: tres archivos HDX, granularidad mensual. Hay DOS descargas
# en data_raw/acled/: "acled_*.xlsx" (2026-01-19, llega solo hasta enero 2026)
# y "colombia_hrp_*.xlsx" (2026-06-23, corte as-of-17jun2026, llega hasta
# junio 2026). Verificado con rango de Year/Month en consola (2026-06-23):
# el corto no cubre la ventana pre-electoral enero-mayo 2026 que necesita el
# indice de exposicion; el largo si. Se usa SIEMPRE "colombia_hrp_*" por esa
# razon (regla AGENTS.md de auditoria empirica de fuentes: cobertura y fecha
# de corte, no el nombre ni la jerarquia del archivo).
# La hoja de datos real (no la portada "Licensing") se detecta tomando la
# ULTIMA hoja del libro, patron tipico de los archivos HDX. Las columnas no
# se asumen: se reportan para verificacion manual antes de usarlas en 02_analisis.R.
archivos_acled <- list.files(
  here::here("data_raw/acled"), pattern = "^colombia_hrp_.*\\.xlsx$", full.names = TRUE
)
stopifnot(length(archivos_acled) == 3L)

columnas_obligatorias_acled <- c(
  "Country", "Admin1", "Admin2", "Admin2 Pcode", "Month", "Year", "Events"
)

acled_data <- list()
for (f in archivos_acled) {
  hojas <- excel_sheets(f)
  hoja_datos <- hojas[length(hojas)]
  df <- read_excel(f, sheet = hoja_datos)

  faltantes <- setdiff(columnas_obligatorias_acled, names(df))
  if (length(faltantes) > 0) {
    stop(sprintf(
      "%s no tiene las columnas obligatorias: %s",
      basename(f), paste(faltantes, collapse = ", ")
    ), call. = FALSE)
  }

  acled_data[[basename(f)]] <- df
}

# --- 3. Resultados oficiales segunda vuelta 2026 ---
seg_vuelta_path <- here::here(
  "subproyectos/electoral_2026_segunda_vuelta/outputs/supercubo/electoral_2026_segunda_vuelta_municipio.csv"
)
stopifnot(file.exists(seg_vuelta_path))
seg_vuelta <- read_csv(seg_vuelta_path, show_col_types = FALSE)

stopifnot(nrow(seg_vuelta) == 1122L)
stopifnot(ncol(seg_vuelta) == 12L)
stopifnot("codigo_municipio" %in% names(seg_vuelta))

# --- 4. Segunda vuelta 2022 (proxy de voto izquierda historico, Tabla 2) ----
# Vive en electoral_2026_primera_vuelta (no en segunda_vuelta), a nivel
# municipio, con codigo INTERNO de Registraduria (dep_cod + mun_cod), no DANE.
# Formula verificada en consola (2026-06-23): cod_municipio_registraduria =
# dep_cod * 100000 + mun_cod (confirmado con Medellin: dep=1, mun=1 -> 100001,
# que en el puente corresponde a codigo_municipio = 5001, es decir DANE 05001).
sv22_path <- here::here(
  "subproyectos/electoral_2026_primera_vuelta/outputs/puestos/tablas/segunda_vuelta_2022_municipios.csv"
)
puente_path <- here::here(
  "subproyectos/electoral_2026_segunda_vuelta/outputs/supercubo/tabla_puente_registraduria_dane.csv"
)
stopifnot(file.exists(sv22_path), file.exists(puente_path))

sv22_raw <- read_csv(sv22_path, show_col_types = FALSE)
puente <- read_csv(puente_path, show_col_types = FALSE)

stopifnot(nrow(sv22_raw) == 1122L)
stopifnot(all(c("dep_cod", "mun_cod", "s22_2v_petro", "total22_2v") %in% names(sv22_raw)))
stopifnot(all(c("cod_municipio_registraduria", "codigo_municipio") %in% names(puente)))

sv22 <- sv22_raw |>
  mutate(
    cod_municipio_registraduria = as.integer(dep_cod) * 100000L + as.integer(mun_cod)
  ) |>
  left_join(
    puente |>
      mutate(cod_municipio_registraduria = as.integer(cod_municipio_registraduria)) |>
      select(cod_municipio_registraduria, codigo_municipio),
    by = "cod_municipio_registraduria"
  ) |>
  mutate(cod_dane = pad_dane(codigo_municipio)) |>
  select(cod_dane, s22_2v_petro, s22_2v_rodolfo, total22_2v, pct22_2v_pet, pct22_2v_rod)

stopifnot(nrow(sv22) == 1122L)
stopifnot(!anyNA(sv22$cod_dane))

# --- 5. Tipologia territorial D2 (Sistema E4, conflict_armed) --------------
# Insumo externo, copiado con metadata en docs/M5_score_clasificacion_metadata.txt.
# Se usa SOLO la tipologia D2 (k-means territorial: periferico/conflicto_activo/
# corredor/control_armado/produccion_intensiva) -- NO el score completo ni D4,
# porque D4 ya incluye ACLED y abstencion, que colisionarian con idx_exposicion
# y cambio_participacion_pp que ya estan en el modelo de voto_fusil.
m5_path <- here::here("subproyectos/voto_fusil/data_raw/M5_score_clasificacion.rds")
stopifnot(file.exists(m5_path))
m5 <- readRDS(m5_path)

stopifnot(nrow(m5) == 1122L)
stopifnot("tipologia" %in% names(m5))
stopifnot("code" %in% names(m5))

# --- Resumen ---
cat("=== RESUMEN INSUMOS voto_fusil ===\n\n")

cat("1) Panel electoral 2018-2022 (limpio):\n")
cat("   Filas:", nrow(panel), "| Columnas:", ncol(panel), "\n\n")

cat("2) ACLED (granularidad mensual, columnas obligatorias verificadas):\n")
for (nombre in names(acled_data)) {
  df <- acled_data[[nombre]]
  cat("  ", nombre, "\n")
  cat("    Filas:", nrow(df), "| Columnas:", ncol(df), "\n")
}
cat("\n")

cat("3) Resultados oficiales segunda vuelta 2026:\n")
cat("   Filas:", nrow(seg_vuelta), "| Columnas:", ncol(seg_vuelta), "\n\n")

cat("4) Segunda vuelta 2022 (resuelta a codigo DANE via puente):\n")
cat("   Filas:", nrow(sv22), "| Columnas:", ncol(sv22), "\n\n")

cat("5) Tipología D2 (Sistema E4):\n")
cat("   Filas:", nrow(m5), "\n")
cat("   Distribución:\n")
print(table(m5$tipologia))

cat("\n=== 01_datos OK ===\n")
