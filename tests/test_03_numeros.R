# Verifica que los numeros clave del hallazgo de voto_fusil no cambiaron
# silenciosamente en una corrida nueva. No verifica dimensiones de archivo
# (eso es test_02_outputs.R) sino los valores que sostienen la conclusion.
# Tolerancias generosas (no exactas) porque ACLED se actualiza con el tiempo
# y el indice de exposicion puede moverse levemente entre corridas.
# Ejecutar desde D:/Dropbox/Reform_UIAF/

suppressPackageStartupMessages(library(readr))

cat("=== TEST: NUMEROS CLAVE voto_fusil ===\n")

out_dir <- here::here("subproyectos/voto_fusil/outputs/tablas")

# --- Distribucion alta_exposicion: debe seguir siendo ~25% del pais ---------
panel_final <- readRDS(file.path(out_dir, "panel_voto_fusil_final.rds"))
pct_alta <- 100 * mean(panel_final$alta_exposicion, na.rm = TRUE)

if (pct_alta < 10 || pct_alta > 40) {
  stop(sprintf(
    "alta_exposicion = %.1f%% de los municipios, fuera del rango esperado (10-40%%) -- revisar quantile(0.75) o el indice.",
    pct_alta
  ), call. = FALSE)
}
cat(sprintf("OK: alta_exposicion = %.1f%% de los municipios (esperado: 10-40%%).\n", pct_alta))

# --- Tabla 2: el cambio de voto NO debe ser positivo y grande en ningun
# grupo (si el hallazgo de "sin evidencia de voto fusil" se invierte, debe
# fallar aqui, no pasar desapercibido) -------------------------------------
tabla_cambio <- read_csv(file.path(out_dir, "tabla_cambio_voto_exposicion.csv"), show_col_types = FALSE)

if (any(abs(tabla_cambio$cambio_pp_medio) > 10)) {
  stop(sprintf(
    "cambio_pp_medio fuera de un rango plausible (>10pp en algun grupo): %s",
    paste(round(tabla_cambio$cambio_pp_medio, 2), collapse = ", ")
  ), call. = FALSE)
}
cat("OK: cambio_pp_medio en ambos grupos dentro de un rango plausible (<=10pp).\n")

# --- Bloque B: el test de Welch debe seguir corriendo sobre los mismos
# tamanos de grupo (185 alta / 937 baja) ------------------------------------
test_welch <- read_csv(file.path(out_dir, "test_diferencia_cambio_pp.csv"), show_col_types = FALSE)

if (test_welch$n_alta[1] + test_welch$n_baja[1] != 1122L) {
  stop(sprintf(
    "El test de Welch no cubre los 1122 municipios (n_alta=%d, n_baja=%d).",
    test_welch$n_alta[1], test_welch$n_baja[1]
  ), call. = FALSE)
}
cat("OK: test de Welch cubre los 1122 municipios.\n")

# --- Bloque C: cobertura del modelo no debe volver a caer (ver bug de
# ha_coca NA resuelto en commit c590ee0: bajo a 316/1122 antes de la
# correccion). Umbral: al menos 90% de cobertura ---------------------------
modelo <- read_csv(file.path(out_dir, "modelo_voto_fusil_controles.csv"), show_col_types = FALSE)
n_obs_modelo <- unique(modelo$n_observaciones)

if (length(n_obs_modelo) != 1L) {
  stop("modelo_voto_fusil_controles.csv tiene mas de un valor distinto de n_observaciones (deberia ser uno solo).", call. = FALSE)
}
cobertura <- n_obs_modelo / 1122
if (cobertura < 0.9) {
  stop(sprintf(
    "Cobertura del modelo = %.1f%% (n=%d/1122) -- por debajo del 90%%. Revisar NAs en ipm_dnp/ha_coca/pdet/cat_ruralidad (ver bug resuelto en commit c590ee0).",
    100 * cobertura, n_obs_modelo
  ), call. = FALSE)
}
cat(sprintf("OK: cobertura del modelo = %.1f%% (n=%d/1122).\n", 100 * cobertura, n_obs_modelo))

# --- Robustez de la distincion analitica -----------------------------------
matriz <- read_csv(file.path(out_dir, "matriz_robustez_completa.csv"), show_col_types = FALSE)
if (nrow(matriz) != 18L || sum(matriz$tratado == "control_armado") != 9L) {
  stop("La matriz de robustez no conserva sus 18 especificaciones (9 de control armado).", call. = FALSE)
}

control_armado <- matriz[matriz$tratado == "control_armado", ]
if (any(control_armado$coef_tratado <= 0) || any(control_armado$p_valor >= 0.05)) {
  stop("El patron de control armado dejo de ser positivo y significativo en alguna especificacion.", call. = FALSE)
}

conflicto <- matriz[matriz$tratado == "conflicto_activo" & matriz$referencia == "resto_colombia", ]
if (!any(conflicto$coef_tratado > 0) || !any(conflicto$coef_tratado < 0)) {
  stop("Conflicto activo ya no cambia de signo entre especificaciones; revisar la lectura editorial.", call. = FALSE)
}
cat("OK: distincion entre exposicion reciente y control territorial validada en 18 especificaciones.\n")

cat("\n=== test_03_numeros PASSED ===\n")
