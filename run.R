obtener_ruta_run <- function() {
  argumentos <- commandArgs(trailingOnly = FALSE)
  argumento_archivo <- grep("^--file=", argumentos, value = TRUE)
  if (length(argumento_archivo) == 1L) {
    return(normalizePath(sub("^--file=", "", argumento_archivo), mustWork = TRUE))
  }

  archivos_source <- vapply(sys.frames(), function(x) {
    if (is.null(x$ofile)) NA_character_ else x$ofile
  }, character(1))
  archivos_source <- archivos_source[!is.na(archivos_source)]
  if (length(archivos_source) > 0L) {
    return(normalizePath(tail(archivos_source, 1L), mustWork = TRUE))
  }

  normalizePath("subproyectos/voto_fusil/run.R", mustWork = TRUE)
}

ruta_run <- obtener_ruta_run()
dir_subproyecto <- dirname(ruta_run)
dir_proyecto <- normalizePath(file.path(dir_subproyecto, "..", ".."), mustWork = TRUE)
setwd(dir_proyecto)

archivo_subproyecto <- function(...) file.path(dir_subproyecto, ...)

source(archivo_subproyecto("scripts", "ARRANQUE_SESION.R"))
source(archivo_subproyecto("tests", "test_01_prerequisitos.R"))
source(archivo_subproyecto("scripts", "01_datos.R"))
source(archivo_subproyecto("scripts", "02_analisis.R"))
source(archivo_subproyecto("scripts", "04_visualizaciones.R"))
source(archivo_subproyecto("scripts", "05_exterior_grupo_control.R"))
source(archivo_subproyecto("scripts", "06_resumen_tabla1_tabla2.R"))
source(archivo_subproyecto("scripts", "06_mapa_control_territorial.R"))
source(archivo_subproyecto("scripts", "07_mapa_tipologia_territorial.R"))
source(archivo_subproyecto("scripts", "08_editorial_final.R"))
source(archivo_subproyecto("scripts", "09_graficas_ppt_doc.R"))
source(archivo_subproyecto("tests", "test_02_outputs.R"))
source(archivo_subproyecto("tests", "test_03_numeros.R"))
source(archivo_subproyecto("scripts", "03_guardar_estado.R"))

cat("\n=== PIPELINE voto_fusil COMPLETADO ===\n")
