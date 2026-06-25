# Responsabilidad: ensamblar Tabla 1 (DiD limpio, con exterior, sin
# controles) y Tabla 2 (DiD ajustado, sin exterior, con controles) a partir
# de resultados YA calculados en 05_exterior_grupo_control.R y 02_analisis.R.
# No corre ningun modelo nuevo -- solo lee y presenta.
# Ejecutar desde D:/Dropbox/Reform_UIAF/

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(writexl)
})

out_dir <- here::here("subproyectos/voto_fusil/outputs/tablas")

# --- Tabla 1: DiD limpio (control_armado vs. exterior, sin controles) ------
did_path <- file.path(out_dir, "did_cuatro_grupos.csv")
stopifnot(file.exists(did_path))

tabla1 <- read_csv(did_path, show_col_types = FALSE) |>
  filter(comparacion %in% c("control_armado vs. exterior", "exterior vs. control_armado"))
stopifnot(nrow(tabla1) == 1L)

tabla1_presentacion <- tibble(
  especificacion = "Tabla 1 -- DiD limpio (sin controles, exterior como grupo de control)",
  comparacion = tabla1$comparacion[1],
  diferencia_pp = round(tabla1$diferencia_medias[1], 3),
  ic95 = sprintf("[%.2f, %.2f]", tabla1$ic95_inferior[1], tabla1$ic95_superior[1]),
  p_valor = round(tabla1$p_valor[1], 4),
  sig = tabla1$sig[1],
  n_tratado = tabla1$n1[1],
  n_control = tabla1$n2[1]
)

# --- Tabla 2: DiD ajustado (control_armado vs. resto Colombia, con controles) ---
modelo_part_d2_path <- file.path(out_dir, "modelo_participacion_D2.csv")
stopifnot(file.exists(modelo_part_d2_path))

modelo_part_d2 <- read_csv(modelo_part_d2_path, show_col_types = FALSE)
fila_tabla2 <- modelo_part_d2 |> filter(termino == "tipologia_d2control_armado")
stopifnot(nrow(fila_tabla2) == 1L)

tabla2_presentacion <- tibble(
  especificacion = "Tabla 2 -- DiD ajustado (con controles: ipm_dnp, ha_coca, pdet, cat_ruralidad; sin exterior)",
  comparacion = "control_armado vs. periferico (categoria de referencia D2, ajustado por controles)",
  diferencia_pp = round(fila_tabla2$estimacion[1], 3),
  ic95 = sprintf(
    "[%.2f, %.2f]",
    fila_tabla2$estimacion[1] - 1.96 * fila_tabla2$error_estandar_hc1[1],
    fila_tabla2$estimacion[1] + 1.96 * fila_tabla2$error_estandar_hc1[1]
  ),
  p_valor = round(fila_tabla2$p_valor[1], 4),
  sig = case_when(
    fila_tabla2$p_valor[1] < 0.001 ~ "***",
    fila_tabla2$p_valor[1] < 0.01 ~ "**",
    fila_tabla2$p_valor[1] < 0.05 ~ "*",
    TRUE ~ ""
  ),
  n_tratado = fila_tabla2$n_observaciones[1],
  n_control = NA_integer_
)

tablas_combinadas <- bind_rows(tabla1_presentacion, tabla2_presentacion)

cat("=== TABLA 1 Y TABLA 2: DiD LIMPIO vs. DiD AJUSTADO ===\n\n")
print(as.data.frame(tablas_combinadas), row.names = FALSE, right = FALSE)
cat("\n*** p<0.001, ** p<0.01, * p<0.05\n")

cat("\nLectura: si ambas tablas apuntan en la misma direccion y magnitud similar,\n")
cat("el resultado es robusto a la inclusion de controles y al grupo de comparacion.\n")
cat("Si difieren mucho, los controles (pobreza, ruralidad, coca, PDET) estan\n")
cat("absorbiendo gran parte de lo que el DiD limpio le atribuye al tratamiento.\n")

write.csv(
  tablas_combinadas,
  file.path(out_dir, "tabla1_tabla2_did_resumen.csv"),
  row.names = FALSE
)

write_xlsx(
  list("Tabla 1 y 2" = tablas_combinadas),
  file.path(out_dir, "tabla1_tabla2_did_resumen.xlsx")
)

cat("\n=== 06_resumen_tabla1_tabla2 OK ===\n")
