# Responsabilidad unica: preparar una sesion reproducible y fallar temprano.

source(file.path(dir_subproyecto, "scripts", "00_config.R"))

paquetes_requeridos <- c(
  "dplyr", "gt", "here", "htmltools", "htmlwidgets", "leaflet", "plotly",
  "readr", "readxl", "sandwich", "scales", "sf", "stringr", "tibble", "tidyr", "writexl",
  "ggplot2"
)
paquetes_faltantes <- paquetes_requeridos[
  !vapply(paquetes_requeridos, requireNamespace, logical(1), quietly = TRUE)
]
if (length(paquetes_faltantes) > 0L) {
  stop(
    "Faltan paquetes requeridos: ", paste(paquetes_faltantes, collapse = ", "),
    call. = FALSE
  )
}

directorios_salida <- c(
  "outputs/tablas", "outputs/mapas", "outputs/graficos",
  "outputs/graficas/ppt", "outputs/graficas/doc"
)
invisible(lapply(
  file.path(dir_subproyecto, directorios_salida),
  dir.create,
  recursive = TRUE,
  showWarnings = FALSE
))

options(stringsAsFactors = FALSE, scipen = 999)
Sys.setenv(TZ = "America/Bogota")
cat("=== ARRANQUE_SESION voto_fusil OK ===\n")
