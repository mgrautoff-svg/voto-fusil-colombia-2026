# Verifica que todos los insumos de voto_fusil existen y tienen las
# dimensiones/columnas correctas, antes de permitir correr el analisis.
# Ejecutar desde D:/Dropbox/Reform_UIAF/

suppressPackageStartupMessages({
  library(readr)
  library(readxl)
})

cat("=== TEST: PREREQUISITOS voto_fusil ===\n")

archivos_requeridos <- c(
  panel = "data_raw/electoral/base_electoral_2026_panel_limpio.csv",
  acled_pv = "data_raw/acled/colombia_hrp_political_violence_events_and_fatalities_by_month-year_as-of-17jun2026.xlsx",
  acled_ct = "data_raw/acled/colombia_hrp_civilian_targeting_events_and_fatalities_by_month-year_as-of-17jun2026.xlsx",
  acled_dm = "data_raw/acled/colombia_hrp_demonstration_events_by_month-year_as-of-17jun2026.xlsx",
  seg_vuelta = "subproyectos/electoral_2026_segunda_vuelta/outputs/supercubo/electoral_2026_segunda_vuelta_municipio.csv",
  sv22 = "subproyectos/electoral_2026_primera_vuelta/outputs/puestos/tablas/segunda_vuelta_2022_municipios.csv",
  puente = "subproyectos/electoral_2026_segunda_vuelta/outputs/supercubo/tabla_puente_registraduria_dane.csv"
)

for (nombre in names(archivos_requeridos)) {
  ruta <- here::here(archivos_requeridos[[nombre]])
  if (!file.exists(ruta)) {
    stop(sprintf("Falta el archivo requerido (%s): %s", nombre, archivos_requeridos[[nombre]]), call. = FALSE)
  }
}
cat("OK: los 7 archivos requeridos existen.\n")

# --- Panel electoral limpio ---------------------------------------------------
panel <- read_csv(here::here(archivos_requeridos[["panel"]]), show_col_types = FALSE)

if (nrow(panel) != 1122L) {
  stop(sprintf("Panel limpio: se esperaban 1122 filas, hay %d", nrow(panel)), call. = FALSE)
}
if (ncol(panel) != 94L) {
  stop(sprintf("Panel limpio: se esperaban 94 columnas, hay %d", ncol(panel)), call. = FALSE)
}
if (!"cod_dane" %in% names(panel)) {
  stop("Panel limpio: falta la columna 'cod_dane'", call. = FALSE)
}
cat("OK: panel limpio con 1122 filas, 94 columnas y columna 'cod_dane'.\n")

# --- Segunda vuelta 2026 ------------------------------------------------------
seg_vuelta <- read_csv(here::here(archivos_requeridos[["seg_vuelta"]]), show_col_types = FALSE)

if (nrow(seg_vuelta) != 1122L) {
  stop(sprintf("Segunda vuelta 2026: se esperaban 1122 filas, hay %d", nrow(seg_vuelta)), call. = FALSE)
}
if (ncol(seg_vuelta) != 12L) {
  stop(sprintf("Segunda vuelta 2026: se esperaban 12 columnas, hay %d", ncol(seg_vuelta)), call. = FALSE)
}
if (!"codigo_municipio" %in% names(seg_vuelta)) {
  stop("Segunda vuelta 2026: falta la columna 'codigo_municipio'", call. = FALSE)
}
cat("OK: segunda vuelta 2026 con 1122 filas, 12 columnas y columna 'codigo_municipio'.\n")

# --- ACLED (los tres archivos, columnas obligatorias) ------------------------
columnas_obligatorias_acled <- c("Admin2 Pcode", "Month", "Year", "Events")

for (nombre in c("acled_pv", "acled_ct", "acled_dm")) {
  ruta <- here::here(archivos_requeridos[[nombre]])
  hojas <- excel_sheets(ruta)
  hoja_datos <- hojas[length(hojas)]
  df <- read_excel(ruta, sheet = hoja_datos)

  faltantes <- setdiff(columnas_obligatorias_acled, names(df))
  if (length(faltantes) > 0) {
    stop(sprintf(
      "%s: faltan columnas obligatorias: %s",
      basename(ruta), paste(faltantes, collapse = ", ")
    ), call. = FALSE)
  }
}
cat("OK: los tres archivos ACLED tienen las columnas obligatorias (Admin2 Pcode, Month, Year, Events).\n")

# --- Segunda vuelta 2022 (proxy historico Tabla 2) y puente Registraduria-DANE ---
sv22 <- read_csv(here::here(archivos_requeridos[["sv22"]]), show_col_types = FALSE)
puente <- read_csv(here::here(archivos_requeridos[["puente"]]), show_col_types = FALSE)

if (nrow(sv22) != 1122L) {
  stop(sprintf("Segunda vuelta 2022: se esperaban 1122 filas, hay %d", nrow(sv22)), call. = FALSE)
}
faltantes_sv22 <- setdiff(c("dep_cod", "mun_cod", "s22_2v_petro", "total22_2v"), names(sv22))
if (length(faltantes_sv22) > 0) {
  stop(sprintf("Segunda vuelta 2022: faltan columnas: %s", paste(faltantes_sv22, collapse = ", ")), call. = FALSE)
}
faltantes_puente <- setdiff(c("cod_municipio_registraduria", "codigo_municipio"), names(puente))
if (length(faltantes_puente) > 0) {
  stop(sprintf("Puente Registraduria-DANE: faltan columnas: %s", paste(faltantes_puente, collapse = ", ")), call. = FALSE)
}
cat("OK: segunda vuelta 2022 (1122 filas, columnas dep_cod/mun_cod/s22_2v_petro/total22_2v) y puente verificados.\n")

cat("=== test_01_prerequisitos PASSED ===\n")
