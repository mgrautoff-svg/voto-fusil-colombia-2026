# Responsabilidad: construir el indice de exposicion armada pre-electoral
# (ventana nov2025-may2026, ver docs/ESTADO.md) y cruzarlo con el panel
# electoral 2018-2022 y los resultados de segunda vuelta 2026.
# No vuelve a leer archivos crudos: carga los objetos ya verificados por
# 01_datos.R. Ejecutar desde D:/Dropbox/Reform_UIAF/

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(stringr)
  library(sandwich)
})

# --- Paso 1: recibir insumos ya verificados ----------------------------------
objetos_requeridos <- c("panel", "acled_data", "seg_vuelta", "sv22", "m5")
objetos_faltantes <- objetos_requeridos[
  !vapply(objetos_requeridos, exists, logical(1), inherits = TRUE)
]
if (length(objetos_faltantes) > 0L) {
  stop(
    "02_analisis.R requiere ejecutar 01_datos.R antes. Faltan: ",
    paste(objetos_faltantes, collapse = ", "),
    call. = FALSE
  )
}

pad_dane <- function(x) sprintf("%05d", suppressWarnings(as.integer(as.character(x))))

# --- Paso 2: indice de exposicion armada -------------------------------------
ventana_meses <- list(
  subperiodo_1 = list(anio = 2025, meses = 11:12),
  subperiodo_2 = list(anio = 2026, meses = 1:3),
  subperiodo_3 = list(anio = 2026, meses = 4:5)
)

asignar_subperiodo <- function(anio, mes) {
  case_when(
    anio == 2025 & mes %in% 11:12 ~ "subperiodo_1",
    anio == 2026 & mes %in% 1:3   ~ "subperiodo_2",
    anio == 2026 & mes %in% 4:5   ~ "subperiodo_3",
    TRUE ~ NA_character_
  )
}

fuente_por_archivo <- setNames(names(config_voto_fusil$fuentes_acled), config_voto_fusil$fuentes_acled)

agregados_por_fuente <- list()
for (nombre_archivo in names(acled_data)) {
  prefijo <- fuente_por_archivo[[nombre_archivo]]
  stopifnot(!is.null(prefijo))

  df <- acled_data[[nombre_archivo]]

  # Year llega como texto numerico ("2018"); Month como nombre de mes en
  # ingles ("January"). Se convierten explicitamente, sin asumir formato,
  # y se verifica que la conversion no produzca NA (typo o mes no reconocido).
  df <- df |>
    mutate(
      anio_num = as.integer(Year),
      mes_num = match(Month, month.name)
    )
  stopifnot(!anyNA(df$anio_num), !anyNA(df$mes_num))

  df <- df |>
    mutate(
      cod_dane = pad_dane(str_remove(`Admin2 Pcode`, "^CO")),
      subperiodo = asignar_subperiodo(anio_num, mes_num)
    ) |>
    filter(!is.na(subperiodo))

  agregado <- df |>
    group_by(cod_dane, subperiodo) |>
    summarise(eventos = sum(Events, na.rm = TRUE), .groups = "drop") |>
    pivot_wider(
      names_from = subperiodo, values_from = eventos,
      names_prefix = paste0(prefijo, "_"), values_fill = 0
    ) |>
    mutate(!!paste0(prefijo, "_total") := rowSums(across(starts_with(prefijo)), na.rm = TRUE))

  agregados_por_fuente[[prefijo]] <- agregado
}

universo_municipios <- tibble(cod_dane = pad_dane(panel$cod_dane)) |> distinct()

indice_exposicion <- universo_municipios |>
  left_join(agregados_por_fuente[["pv"]], by = "cod_dane") |>
  left_join(agregados_por_fuente[["ct"]], by = "cod_dane") |>
  left_join(agregados_por_fuente[["dm"]], by = "cod_dane") |>
  mutate(across(-cod_dane, ~ replace_na(.x, 0))) |>
  mutate(
    idx_exposicion = pv_total + ct_total,
    alta_exposicion = idx_exposicion > quantile(
      idx_exposicion, config_voto_fusil$cuantil_alta_exposicion, na.rm = TRUE
    )
  )

stopifnot(nrow(indice_exposicion) == n_distinct(universo_municipios$cod_dane))
stopifnot(!anyNA(indice_exposicion$idx_exposicion))

# --- Paso 3: join triple ------------------------------------------------------
panel_cod <- panel |> mutate(cod_dane = pad_dane(cod_dane))
seg_vuelta_cod <- seg_vuelta |> rename(cod_dane = codigo_municipio) |> mutate(cod_dane = pad_dane(cod_dane))

panel_final <- panel_cod |>
  left_join(indice_exposicion, by = "cod_dane")
stopifnot(nrow(panel_final) == nrow(panel_cod))

panel_final <- panel_final |>
  left_join(seg_vuelta_cod, by = "cod_dane")
stopifnot(nrow(panel_final) == nrow(panel_cod))

# Tipologia D2 (Sistema E4) -- ya cargada y verificada en 01_datos.R como `m5`.
m5_join <- m5 |>
  mutate(cod_dane = pad_dane(code)) |>
  select(cod_dane, tipologia) |>
  rename(tipologia_d2 = tipologia)

n_antes_m5 <- nrow(panel_final)
panel_final <- panel_final |>
  left_join(m5_join, by = "cod_dane")
stopifnot(nrow(panel_final) == n_antes_m5)
stopifnot(!anyNA(panel_final$tipologia_d2))

# --- Paso 4: verificacion de integridad --------------------------------------
stopifnot(nrow(panel_final) == config_voto_fusil$n_municipios)

cat("=== DISTRIBUCION alta_exposicion ===\n")
print(table(panel_final$alta_exposicion))

cat("\n=== TOP 10 MUNICIPIOS POR idx_exposicion ===\n")
panel_final |>
  select(cod_dane, municipio, departamento, idx_exposicion, pv_total, ct_total) |>
  arrange(desc(idx_exposicion)) |>
  slice_head(n = 10) |>
  print(n = 10)

# --- Paso 5: guardar -----------------------------------------------------
out_dir <- here::here("subproyectos/voto_fusil/outputs/tablas")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

write.csv(
  panel_final,
  file.path(out_dir, "panel_voto_fusil_final.csv"),
  row.names = FALSE
)
saveRDS(panel_final, file.path(out_dir, "panel_voto_fusil_final.rds"))

# --- Bloque descriptivo: heterogeneidad por exposicion armada ---------------

# Tabla 1: resultado electoral por nivel de exposicion
tabla_descriptiva_exposicion <- panel_final |>
  mutate(
    pct_cepeda = 100 * votos_2v2026_ivan_cepeda_castro / votos_validos_2v2026,
    pct_espriella = 100 * votos_2v2026_abelardo_de_la_espriella / votos_validos_2v2026,
    gana_cepeda = votos_2v2026_ivan_cepeda_castro > votos_2v2026_abelardo_de_la_espriella,
    gana_espriella = votos_2v2026_abelardo_de_la_espriella > votos_2v2026_ivan_cepeda_castro
  ) |>
  group_by(alta_exposicion) |>
  summarise(
    n_municipios = n(),
    pct_cepeda_media = mean(pct_cepeda, na.rm = TRUE),
    pct_espriella_media = mean(pct_espriella, na.rm = TRUE),
    n_gana_cepeda = sum(gana_cepeda, na.rm = TRUE),
    n_gana_espriella = sum(gana_espriella, na.rm = TRUE),
    .groups = "drop"
  )

cat("\n=== TABLA 1: RESULTADO ELECTORAL POR NIVEL DE EXPOSICION ===\n")
print(tabla_descriptiva_exposicion)

write.csv(
  tabla_descriptiva_exposicion,
  file.path(out_dir, "tabla_descriptiva_exposicion.csv"),
  row.names = FALSE
)

# Tabla 2: cambio entre segunda vuelta 2022 (proxy: s22_2v_petro) y segunda
# vuelta 2026 (Cepeda), en puntos porcentuales, por grupo de exposicion.
# s22_2v_petro/total22_2v no estan en panel_final (no vienen en el panel
# base): se unen aqui desde sv22, ya resuelto a cod_dane en 01_datos.R via
# el puente Registraduria-DANE.
n_antes_sv22 <- nrow(panel_final)
panel_con_sv22 <- panel_final |> left_join(sv22, by = "cod_dane")
stopifnot(nrow(panel_con_sv22) == n_antes_sv22)
stopifnot(!anyNA(panel_con_sv22$s22_2v_petro), !anyNA(panel_con_sv22$total22_2v))

datos_cambio <- panel_con_sv22 |>
  mutate(
    pct22_2v_petro = 100 * s22_2v_petro / total22_2v,
    pct26_cepeda = 100 * votos_2v2026_ivan_cepeda_castro / votos_validos_2v2026,
    cambio_pp = pct26_cepeda - pct22_2v_petro
  )

tabla_cambio_voto_exposicion <- datos_cambio |>
  group_by(alta_exposicion) |>
  summarise(
    n_municipios = n(),
    pct22_2v_petro_media = mean(pct22_2v_petro, na.rm = TRUE),
    pct26_cepeda_media = mean(pct26_cepeda, na.rm = TRUE),
    cambio_pp_medio = mean(cambio_pp, na.rm = TRUE),
    .groups = "drop"
  )

cat("\n=== TABLA 2: CAMBIO DE VOTO IZQUIERDA (s22_2v_petro -> cepeda 2v2026) POR EXPOSICION ===\n")
print(tabla_cambio_voto_exposicion)

write.csv(
  tabla_cambio_voto_exposicion,
  file.path(out_dir, "tabla_cambio_voto_exposicion.csv"),
  row.names = FALSE
)

# --- Bloque B: test estadistico (Welch) sobre cambio_pp -------------------
grupo_alta <- datos_cambio$cambio_pp[datos_cambio$alta_exposicion]
grupo_baja <- datos_cambio$cambio_pp[!datos_cambio$alta_exposicion]

test_welch <- t.test(grupo_alta, grupo_baja, var.equal = FALSE)

tabla_test_welch <- tibble(
  diferencia_medias = unname(test_welch$estimate[1] - test_welch$estimate[2]),
  ic95_inferior = test_welch$conf.int[1],
  ic95_superior = test_welch$conf.int[2],
  p_valor = test_welch$p.value,
  n_alta = length(grupo_alta),
  n_baja = length(grupo_baja)
)

cat("\n=== BLOQUE B: TEST DE WELCH (cambio_pp, alta vs baja exposicion) ===\n")
print(tabla_test_welch)

write.csv(
  tabla_test_welch,
  file.path(out_dir, "test_diferencia_cambio_pp.csv"),
  row.names = FALSE
)

# --- Bloque C: regresion OLS con controles, errores robustos HC1 ----------
# ipm_dnp, ha_coca, pdet, cat_ruralidad NO estan en ningun insumo de
# voto_fusil; se leen del supercubo central (data_clean/supercubo_municipio_anio_v3.rds),
# mismo patron y mismo corte (anio == 2023, "ultimo corte preelectoral") que
# usa subproyectos/electoral_2026_segunda_vuelta/scripts/05_migracion_regresion_ecologica.R.
# Es una LECTURA del supercubo hacia electoral (permitida); el supercubo no se
# modifica ni recibe nada de voto_fusil.
supercubo_path <- here::here(config_voto_fusil$rutas$supercubo)
stopifnot(file.exists(supercubo_path))

controles <- readRDS(supercubo_path) |>
  filter(anio == 2023) |>
  mutate(
    cod_dane = pad_dane(codigo_municipio),
    # ha_coca es "structural zero": NA en la fuente cruda significa que el
    # municipio no reporto cultivo, no que falte el dato. Mismo tratamiento
    # que 05_migracion_regresion_ecologica.R (coalesce a 0). Sin esto, 792 de
    # 1122 municipios se perdian del modelo por un NA que en realidad es 0.
    ha_coca = coalesce(ha_coca, 0)
  ) |>
  distinct(cod_dane, .keep_all = TRUE) |>
  select(cod_dane, ipm_dnp, ha_coca, pdet, cat_ruralidad)

n_antes_controles <- nrow(datos_cambio)
datos_modelo <- datos_cambio |> left_join(controles, by = "cod_dane")
stopifnot(nrow(datos_modelo) == n_antes_controles)

modelo_voto_fusil <- lm(
  cambio_pp ~ alta_exposicion + ipm_dnp + ha_coca + pdet + cat_ruralidad,
  data = datos_modelo
)

# Aviso de cobertura: si el modelo descarta muchas filas por NA en los
# controles (p.ej. ipm_dnp/pdet/cat_ruralidad faltantes para municipios
# nuevos o sin match), el resultado deja de ser representativo del pais.
cobertura_modelo <- nobs(modelo_voto_fusil) / nrow(datos_modelo)
if (cobertura_modelo < 0.9) {
  cat(sprintf(
    "\nAVISO: el modelo solo usa %d de %d municipios (%.1f%% de cobertura) -- revisar NAs en los controles antes de interpretar el resultado como representativo.\n",
    nobs(modelo_voto_fusil), nrow(datos_modelo), 100 * cobertura_modelo
  ))
}

vc_hc1 <- sandwich::vcovHC(modelo_voto_fusil, type = "HC1")
b <- coef(modelo_voto_fusil)
se_robusto <- sqrt(diag(vc_hc1))

tabla_modelo <- tibble(
  termino = names(b),
  estimacion = unname(b),
  error_estandar_hc1 = se_robusto,
  estadistico_t = unname(b) / se_robusto,
  p_valor = 2 * pnorm(abs(unname(b) / se_robusto), lower.tail = FALSE),
  n_observaciones = nobs(modelo_voto_fusil)
)

cat("\n=== BLOQUE C: REGRESION OLS CON CONTROLES (errores robustos HC1) ===\n")
print(tabla_modelo, n = Inf)

write.csv(
  tabla_modelo,
  file.path(out_dir, "modelo_voto_fusil_controles.csv"),
  row.names = FALSE
)

# --- Bloque D: tabla Forero (cambio de participacion 1v->2v 2026) ---------
# participacion_1v, participacion_2v y variacion_participacion_pp YA estan
# calculadas y validadas en el pipeline de la columna anterior; no se
# reconstruyen aqui desde votantes/censo (el panel limpio NO tiene datos de
# primera vuelta 2026 -- verificado, son solo 2018/2022).
metricas_path <- here::here(config_voto_fusil$rutas$metricas_2026)
stopifnot(file.exists(metricas_path))

metricas_2026 <- read_csv(metricas_path, show_col_types = FALSE) |>
  mutate(cod_dane = pad_dane(codigo_municipio)) |>
  select(cod_dane, participacion_1v, participacion_2v, variacion_participacion_pp) |>
  rename(cambio_participacion_pp = variacion_participacion_pp)

n_antes_forero <- nrow(panel_final)
datos_forero <- panel_final |>
  select(cod_dane, alta_exposicion) |>
  left_join(metricas_2026, by = "cod_dane")
stopifnot(nrow(datos_forero) == n_antes_forero)
stopifnot(!anyNA(datos_forero$cambio_participacion_pp))

tabla_forero_participacion <- datos_forero |>
  group_by(alta_exposicion) |>
  summarise(
    n_municipios = n(),
    participacion_1v_media = mean(participacion_1v, na.rm = TRUE),
    participacion_2v_media = mean(participacion_2v, na.rm = TRUE),
    cambio_participacion_pp_medio = mean(cambio_participacion_pp, na.rm = TRUE),
    .groups = "drop"
  )

cat("\n=== BLOQUE D: TABLA FORERO (cambio participacion 1v->2v 2026) POR EXPOSICION ===\n")
print(tabla_forero_participacion)

write.csv(
  tabla_forero_participacion,
  file.path(out_dir, "tabla_forero_participacion.csv"),
  row.names = FALSE
)

# --- Bloque D2: test de Welch sobre cambio_participacion_pp ----------------
grupo_alta_part <- datos_forero$cambio_participacion_pp[datos_forero$alta_exposicion]
grupo_baja_part <- datos_forero$cambio_participacion_pp[!datos_forero$alta_exposicion]

test_welch_part <- t.test(grupo_alta_part, grupo_baja_part, var.equal = FALSE)

tabla_test_welch_participacion <- tibble(
  diferencia_medias = unname(test_welch_part$estimate[1] - test_welch_part$estimate[2]),
  ic95_inferior = test_welch_part$conf.int[1],
  ic95_superior = test_welch_part$conf.int[2],
  p_valor = test_welch_part$p.value,
  n_alta = length(grupo_alta_part),
  n_baja = length(grupo_baja_part)
)

cat("\n=== BLOQUE D2: TEST DE WELCH (participacion, alta vs baja exposicion) ===\n")
print(tabla_test_welch_participacion)

write.csv(
  tabla_test_welch_participacion,
  file.path(out_dir, "test_diferencia_participacion.csv"),
  row.names = FALSE
)

# --- Bloque E: regresion de participacion con controles -------------------
# Reusa datos_modelo (Bloque C: ya tiene controles ipm_dnp/ha_coca/pdet/
# cat_ruralidad con el ha_coca corregido) y le pega cambio_participacion_pp
# (ya calculado en Bloque D) y p22_fajardo/p22_votos_totales (proxy de voto
# centro 2022, presentes en el panel limpio original).
n_antes_participacion <- nrow(datos_modelo)
datos_participacion <- datos_modelo |>
  left_join(metricas_2026 |> select(cod_dane, cambio_participacion_pp), by = "cod_dane") |>
  mutate(pct22_fajardo = 100 * p22_fajardo / p22_votos_totales)
stopifnot(nrow(datos_participacion) == n_antes_participacion)
stopifnot(!anyNA(datos_participacion$cambio_participacion_pp))

modelo_participacion <- lm(
  cambio_participacion_pp ~ alta_exposicion + ipm_dnp + ha_coca + pdet + cat_ruralidad + pct22_fajardo,
  data = datos_participacion
)

cobertura_participacion <- nobs(modelo_participacion) / nrow(datos_participacion)
if (cobertura_participacion < 0.9) {
  cat(sprintf(
    "\nAVISO: el modelo de participacion solo usa %d de %d municipios (%.1f%% de cobertura) -- revisar NAs antes de interpretar.\n",
    nobs(modelo_participacion), nrow(datos_participacion), 100 * cobertura_participacion
  ))
}

vc_hc1_part <- sandwich::vcovHC(modelo_participacion, type = "HC1")
b_part <- coef(modelo_participacion)
se_robusto_part <- sqrt(diag(vc_hc1_part))

tabla_modelo_participacion <- tibble(
  termino = names(b_part),
  estimacion = unname(b_part),
  error_estandar_hc1 = se_robusto_part,
  estadistico_t = unname(b_part) / se_robusto_part,
  p_valor = 2 * pnorm(abs(unname(b_part) / se_robusto_part), lower.tail = FALSE),
  n_observaciones = nobs(modelo_participacion)
)

cat("\n=== BLOQUE E: REGRESION DE PARTICIPACION CON CONTROLES (errores robustos HC1) ===\n")
print(tabla_modelo_participacion, n = Inf)

write.csv(
  tabla_modelo_participacion,
  file.path(out_dir, "modelo_participacion_controles.csv"),
  row.names = FALSE
)

# --- Bloque F: agregar tipologia D2 (Sistema E4) a ambos modelos -----------
# "periferico" como referencia explicita (no es el primer nivel alfabetico,
# que seria "conflicto_activo" -- hay que fijarlo a mano con relevel()).
fijar_referencia_periferico <- function(df) {
  df |> mutate(tipologia_d2 = relevel(factor(tipologia_d2), ref = "periferico"))
}

construir_tabla_coef <- function(modelo) {
  vc <- sandwich::vcovHC(modelo, type = "HC1")
  b <- coef(modelo)
  se <- sqrt(diag(vc))
  tibble(
    termino = names(b),
    estimacion = unname(b),
    error_estandar_hc1 = se,
    estadistico_t = unname(b) / se,
    p_valor = 2 * pnorm(abs(unname(b) / se), lower.tail = FALSE),
    n_observaciones = nobs(modelo)
  )
}

# Bloque F1: voto, mismo modelo del Bloque C + tipologia_d2
datos_f1 <- datos_modelo |> fijar_referencia_periferico()
modelo_f1 <- lm(
  cambio_pp ~ alta_exposicion + ipm_dnp + ha_coca + pdet + cat_ruralidad + tipologia_d2,
  data = datos_f1
)
tabla_f1 <- construir_tabla_coef(modelo_f1)

cat("\n=== BLOQUE F1: MODELO DE VOTO + TIPOLOGIA D2 (errores robustos HC1) ===\n")
print(tabla_f1, n = Inf)

fila_control_armado_f1 <- tabla_f1 |> filter(termino == "tipologia_d2control_armado")
if (nrow(fila_control_armado_f1) == 1 && fila_control_armado_f1$p_valor[1] < 0.05) {
  cat(sprintf(
    "\n*** control_armado ES significativo en el modelo de VOTO (estimacion=%.3f, p=%.4f) ***\n",
    fila_control_armado_f1$estimacion[1], fila_control_armado_f1$p_valor[1]
  ))
} else {
  cat("\ncontrol_armado NO es significativo en el modelo de voto.\n")
}

write.csv(tabla_f1, file.path(out_dir, "modelo_voto_fusil_D2.csv"), row.names = FALSE)

# Bloque F2: participacion, mismo modelo del Bloque E + tipologia_d2
datos_f2 <- datos_participacion |> fijar_referencia_periferico()
modelo_f2 <- lm(
  cambio_participacion_pp ~ alta_exposicion + ipm_dnp + ha_coca + pdet + cat_ruralidad + pct22_fajardo + tipologia_d2,
  data = datos_f2
)
tabla_f2 <- construir_tabla_coef(modelo_f2)

cat("\n=== BLOQUE F2: MODELO DE PARTICIPACION + TIPOLOGIA D2 (errores robustos HC1) ===\n")
print(tabla_f2, n = Inf)

fila_control_armado_f2 <- tabla_f2 |> filter(termino == "tipologia_d2control_armado")
if (nrow(fila_control_armado_f2) == 1 && fila_control_armado_f2$p_valor[1] < 0.05) {
  cat(sprintf(
    "\n*** control_armado ES significativo en el modelo de PARTICIPACION (estimacion=%.3f, p=%.4f) ***\n",
    fila_control_armado_f2$estimacion[1], fila_control_armado_f2$p_valor[1]
  ))
} else {
  cat("\ncontrol_armado NO es significativo en el modelo de participacion.\n")
}

write.csv(tabla_f2, file.path(out_dir, "modelo_participacion_D2.csv"), row.names = FALSE)

cat("\n=== 02_analisis OK ===\n")
