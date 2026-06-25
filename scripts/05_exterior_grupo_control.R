# Responsabilidad: comparar cambio de participacion (1v->2v 2026) entre tres
# grupos: control armado consolidado (D2), resto de Colombia, y exterior
# (grupo de control limpio: cero exposicion armada, cero tipologia D2 por
# construccion -- no hay territorio colombiano fuera de Colombia).
# No recalcula nada de 02_analisis.R; lee panel_final ya guardado y agrega
# el exterior por pais desde los capilares crudos de 1v y 2v.
# Ejecutar desde D:/Dropbox/Reform_UIAF/

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(writexl)
})

out_dir <- here::here("subproyectos/voto_fusil/outputs/tablas")
panel_final <- readRDS(file.path(out_dir, "panel_voto_fusil_final.rds"))

# --- Exterior, primera vuelta: censo/votantes por pais ----------------------
capilar_1v_path <- here::here(
  "subproyectos/electoral_2026_primera_vuelta/outputs/tablas/resultados_capilar.csv"
)
capilar_2v_path <- here::here(
  "subproyectos/electoral_2026_segunda_vuelta/outputs/tablas/resultados_capilar.csv"
)
stopifnot(file.exists(capilar_1v_path), file.exists(capilar_2v_path))

leer_exterior_pais <- function(ruta) {
  read_csv(ruta, show_col_types = FALSE) |>
    filter(padre_codigo == "88") |>
    distinct(codigo, nombre_territorio, censo, votantes) |>
    mutate(participacion = 100 * votantes / censo)
}

ext_1v <- leer_exterior_pais(capilar_1v_path) |> rename(participacion_1v = participacion)
ext_2v <- leer_exterior_pais(capilar_2v_path) |> rename(participacion_2v = participacion)

stopifnot(n_distinct(ext_1v$codigo) == 67L, n_distinct(ext_2v$codigo) == 67L)

exterior_cambio <- ext_1v |>
  select(codigo, nombre_territorio, participacion_1v) |>
  inner_join(ext_2v |> select(codigo, participacion_2v), by = "codigo") |>
  mutate(cambio_participacion_pp = participacion_2v - participacion_1v, grupo = "exterior")

stopifnot(nrow(exterior_cambio) == 67L)
stopifnot(!anyNA(exterior_cambio$cambio_participacion_pp))

# --- Verificacion contra el agregado nacional (calculado a mano antes) -----
agregado_1v <- sum(ext_1v$votantes) / sum(ext_1v$censo) * 100
agregado_2v <- sum(ext_2v$votantes) / sum(ext_2v$censo) * 100
cat(sprintf(
  "Verificacion agregado exterior: 1v=%.2f%% 2v=%.2f%% cambio=%.2fpp (esperado ~41.70, ~43.41, ~1.71)\n",
  agregado_1v, agregado_2v, agregado_2v - agregado_1v
))

# --- Grupos domesticos: control_armado vs resto -----------------------------
metricas_path <- here::here(
  "subproyectos/electoral_2026_segunda_vuelta/outputs/mapas/tablas/metricas_mapas_electorales_2026.csv"
)
stopifnot(file.exists(metricas_path))

metricas_2026 <- read_csv(metricas_path, show_col_types = FALSE) |>
  mutate(cod_dane = sprintf("%05d", suppressWarnings(as.integer(codigo_municipio)))) |>
  select(cod_dane, participacion_1v, participacion_2v, variacion_participacion_pp)

domestico_cambio <- panel_final |>
  select(cod_dane, tipologia_d2) |>
  inner_join(metricas_2026, by = "cod_dane") |>
  rename(cambio_participacion_pp = variacion_participacion_pp) |>
  mutate(grupo = if_else(tipologia_d2 == "control_armado", "control_armado", "resto_colombia"))

stopifnot(nrow(domestico_cambio) == 1122L)
stopifnot(!anyNA(domestico_cambio$cambio_participacion_pp))
stopifnot(sum(domestico_cambio$grupo == "control_armado") == 85L)

# --- Combinar los tres grupos -----------------------------------------------
tres_grupos <- bind_rows(
  domestico_cambio |> select(grupo, participacion_1v, participacion_2v, cambio_participacion_pp),
  exterior_cambio |> select(grupo, participacion_1v, participacion_2v, cambio_participacion_pp)
)

# --- Tabla resumen estilo paper (Grupo | N | Part. 1v | Part. 2v | Cambio) --
etiquetas_grupo <- c(
  control_armado = "Control armado consolidado (D2)",
  resto_colombia = "Resto de Colombia",
  exterior = "Exterior (67 paises, grupo de control)"
)

tabla_resumen_grupos <- tres_grupos |>
  group_by(grupo) |>
  summarise(
    n = n(),
    participacion_1v_pct = round(mean(participacion_1v, na.rm = TRUE), 2),
    participacion_2v_pct = round(mean(participacion_2v, na.rm = TRUE), 2),
    cambio_pp = round(mean(cambio_participacion_pp, na.rm = TRUE), 2),
    de_cambio_pp = round(sd(cambio_participacion_pp, na.rm = TRUE), 2),
    .groups = "drop"
  ) |>
  mutate(grupo_label = etiquetas_grupo[grupo]) |>
  arrange(match(grupo, names(etiquetas_grupo))) |>
  select(Grupo = grupo_label, N = n,
         `Participación 1ª vuelta (%)` = participacion_1v_pct,
         `Participación 2ª vuelta (%)` = participacion_2v_pct,
         `Cambio (pp)` = cambio_pp,
         `DE del cambio` = de_cambio_pp)

cat("\n=== TABLA 1: PARTICIPACION POR GRUPO (1ra y 2da vuelta 2026) ===\n")
print(as.data.frame(tabla_resumen_grupos), row.names = FALSE, right = FALSE)

# --- Comparaciones pareadas (Welch) -----------------------------------------
# Parametrizada con `datos` para poder reusarla tanto con tres_grupos (abajo)
# como con panel_cuatro_grupos (Bloque H) sin duplicar la funcion.
hacer_welch <- function(g1, g2, datos) {
  x <- datos$cambio_participacion_pp[datos$grupo == g1]
  y <- datos$cambio_participacion_pp[datos$grupo == g2]
  stopifnot(length(x) >= 2, length(y) >= 2)
  t <- t.test(x, y, var.equal = FALSE)
  tibble(
    grupo_1 = g1, grupo_2 = g2,
    diferencia_medias = unname(t$estimate[1] - t$estimate[2]),
    ic95_inferior = t$conf.int[1], ic95_superior = t$conf.int[2],
    p_valor = t$p.value, n1 = length(x), n2 = length(y)
  )
}

asteriscos <- function(p) {
  case_when(p < 0.001 ~ "***", p < 0.01 ~ "**", p < 0.05 ~ "*", TRUE ~ "")
}

tabla_tres_grupos <- bind_rows(
  hacer_welch("control_armado", "exterior", tres_grupos),
  hacer_welch("control_armado", "resto_colombia", tres_grupos),
  hacer_welch("resto_colombia", "exterior", tres_grupos)
) |>
  mutate(
    comparacion = paste(grupo_1, "vs.", grupo_2),
    sig = asteriscos(p_valor)
  ) |>
  select(comparacion, diferencia_medias, ic95_inferior, ic95_superior, p_valor, sig, n1, n2)

cat("\n=== TABLA 2: WELCH PAREADO ENTRE LOS TRES GRUPOS ===\n")
print(as.data.frame(tabla_tres_grupos), row.names = FALSE, right = FALSE)
cat("*** p<0.001, ** p<0.01, * p<0.05\n")

write.csv(
  tabla_tres_grupos,
  file.path(out_dir, "test_tres_grupos_participacion.csv"),
  row.names = FALSE
)

write_xlsx(
  list(
    "Resumen por grupo" = tabla_resumen_grupos,
    "Welch pareado" = tabla_tres_grupos
  ),
  file.path(out_dir, "tabla_tres_grupos_participacion.xlsx")
)

# === BLOQUE H: CUATRO GRUPOS, SEIS COMPARACIONES PAREADAS ===================
# Separa control_armado (D2) de conflicto_activo (D2) -- "pistola silenciosa"
# (control estructural consolidado) vs "fusil activo" (violencia en curso sin
# control consolidado). Reusa domestico_cambio (aun tiene tipologia_d2
# completa) y exterior_cambio (ya construidos arriba, no se recalculan).

panel_cuatro_grupos <- bind_rows(
  domestico_cambio |>
    mutate(grupo = case_when(
      tipologia_d2 == "control_armado"   ~ "control_armado",
      tipologia_d2 == "conflicto_activo" ~ "conflicto_activo",
      TRUE                                ~ "resto_colombia"
    )) |>
    select(grupo, participacion_1v, participacion_2v, cambio_participacion_pp),
  exterior_cambio |>
    mutate(grupo = "exterior") |>
    select(grupo, participacion_1v, participacion_2v, cambio_participacion_pp)
)

stopifnot(nrow(panel_cuatro_grupos) == 1122L + 67L)
stopifnot(setequal(unique(panel_cuatro_grupos$grupo),
                    c("control_armado", "conflicto_activo", "resto_colombia", "exterior")))

# --- Tabla resumen de los 4 grupos, ordenada de mayor a menor cambio --------
tabla_cuatro_grupos <- panel_cuatro_grupos |>
  group_by(grupo) |>
  summarise(
    n = n(),
    media_cambio_pp = round(mean(cambio_participacion_pp, na.rm = TRUE), 2),
    de_cambio_pp = round(sd(cambio_participacion_pp, na.rm = TRUE), 2),
    .groups = "drop"
  ) |>
  arrange(desc(media_cambio_pp))

cat("\n=== TABLA 3: CUATRO GRUPOS, CAMBIO DE PARTICIPACION (orden descendente) ===\n")
print(as.data.frame(tabla_cuatro_grupos), row.names = FALSE, right = FALSE)

write.csv(
  tabla_cuatro_grupos,
  file.path(out_dir, "resumen_cuatro_grupos.csv"),
  row.names = FALSE
)

# --- Los 6 pares posibles, generados con combn() (no a mano, para no omitir ninguno) ---
grupos4 <- c("control_armado", "conflicto_activo", "resto_colombia", "exterior")
pares4 <- combn(grupos4, 2, simplify = FALSE)
stopifnot(length(pares4) == 6L)

tabla_did_cuatro_grupos <- bind_rows(lapply(pares4, function(par) hacer_welch(par[1], par[2], panel_cuatro_grupos))) |>
  mutate(
    comparacion = paste(grupo_1, "vs.", grupo_2),
    sig = asteriscos(p_valor)
  ) |>
  select(comparacion, diferencia_medias, ic95_inferior, ic95_superior, p_valor, sig, n1, n2)

cat("\n=== TABLA 4: WELCH PAREADO, LOS 6 PARES DE LOS 4 GRUPOS ===\n")
print(as.data.frame(tabla_did_cuatro_grupos), row.names = FALSE, right = FALSE)
cat("*** p<0.001, ** p<0.01, * p<0.05\n")

fila_clave <- tabla_did_cuatro_grupos |>
  filter(comparacion %in% c("control_armado vs. conflicto_activo", "conflicto_activo vs. control_armado"))
cat("\n--- Par clave: control_armado (pistola silenciosa) vs. conflicto_activo (fusil activo) ---\n")
print(as.data.frame(fila_clave), row.names = FALSE, right = FALSE)

write.csv(
  tabla_did_cuatro_grupos,
  file.path(out_dir, "did_cuatro_grupos.csv"),
  row.names = FALSE
)

# === BLOQUE I-PRELIMINAR: DiD AJUSTADO, SOLO CONTROLES EXTERNOS A D2 ========
# Caso particular de la matriz de robustez completa (ver BLOQUE I mas abajo,
# fila tratado=control_armado / referencia=resto_colombia / controles=
# "ipm_dnp + cat_ruralidad"). Se deja aqui por separado porque ya estaba
# escrito antes de la matriz y no aporta correr dos veces el mismo modelo.
# ipm_dnp y cat_ruralidad son los UNICOS controles confirmados como externos
# a las 14 variables de D2 (ver docs/M5_score_clasificacion_metadata.txt).
# ha_coca y pdet se excluyen aqui porque son redundantes/sospechosos de
# colinealidad con tipologia_d2 (coca_ha_media y ga_FARC_r estan dentro de D2).
# Solo Colombia (sin exterior): tratado = control_armado vs el resto del pais.
suppressPackageStartupMessages(library(sandwich))

supercubo_path <- here::here("data_clean/supercubo_municipio_anio_v3.rds")
stopifnot(file.exists(supercubo_path))

controles_externos <- readRDS(supercubo_path) |>
  filter(anio == 2023) |>
  mutate(cod_dane = sprintf("%05d", suppressWarnings(as.integer(codigo_municipio)))) |>
  distinct(cod_dane, .keep_all = TRUE) |>
  select(cod_dane, ipm_dnp, cat_ruralidad)

n_antes_controles_ext <- nrow(domestico_cambio)
datos_did_ajustado <- domestico_cambio |>
  mutate(tratado = if_else(tipologia_d2 == "control_armado", 1L, 0L)) |>
  left_join(controles_externos, by = "cod_dane")
stopifnot(nrow(datos_did_ajustado) == n_antes_controles_ext)

modelo_did_ajustado <- lm(
  cambio_participacion_pp ~ tratado + ipm_dnp + cat_ruralidad,
  data = datos_did_ajustado
)

cobertura_did <- nobs(modelo_did_ajustado) / nrow(datos_did_ajustado)
cat(sprintf(
  "\nCobertura modelo DiD ajustado: %d de %d municipios (%.1f%%)\n",
  nobs(modelo_did_ajustado), nrow(datos_did_ajustado), 100 * cobertura_did
))
if (cobertura_did < 0.9) {
  cat("AVISO: cobertura por debajo del 90%% -- revisar NAs en ipm_dnp/cat_ruralidad.\n")
}

vc_did <- sandwich::vcovHC(modelo_did_ajustado, type = "HC1")
b_did <- coef(modelo_did_ajustado)
se_did <- sqrt(diag(vc_did))

tabla_did_ajustado <- tibble(
  termino = names(b_did),
  estimacion = unname(b_did),
  error_estandar_hc1 = se_did,
  estadistico_t = unname(b_did) / se_did,
  p_valor = 2 * pnorm(abs(unname(b_did) / se_did), lower.tail = FALSE),
  n_observaciones = nobs(modelo_did_ajustado)
) |>
  mutate(sig = asteriscos(p_valor))

cat("\n=== TABLA 5: DiD AJUSTADO (cambio_participacion ~ tratado + ipm_dnp + cat_ruralidad, HC1) ===\n")
print(as.data.frame(tabla_did_ajustado), row.names = FALSE, right = FALSE)
cat("*** p<0.001, ** p<0.01, * p<0.05\n")

write.csv(
  tabla_did_ajustado,
  file.path(out_dir, "did_ajustado_ipm_ruralidad.csv"),
  row.names = FALSE
)

# === BLOQUE I: MATRIZ DE ROBUSTEZ COMPLETA ==================================
# 6 pares tratado/referencia x hasta 4 combinaciones de controles. Cuando el
# exterior entra como grupo de referencia "puro" (control_armado vs exterior,
# conflicto_activo vs exterior) solo corre la especificacion sin controles
# -- el exterior no tiene ipm_dnp ni cat_ruralidad. Para los pares con
# referencia combinada ("resto_colombia + exterior") SI se permiten los 4
# controles: lm() descarta automaticamente las filas de exterior cuando el
# control es NA, asi que esas especificaciones terminan comparando tratado
# vs. solo resto_colombia (se documenta en n_obs, no se oculta).

base_domestico <- datos_did_ajustado |>
  mutate(grupo4 = case_when(
    tipologia_d2 == "control_armado"   ~ "control_armado",
    tipologia_d2 == "conflicto_activo" ~ "conflicto_activo",
    TRUE                                ~ "resto_colombia"
  )) |>
  select(grupo = grupo4, cambio_participacion_pp, ipm_dnp, cat_ruralidad)

base_exterior <- exterior_cambio |>
  mutate(grupo = "exterior", ipm_dnp = NA_real_, cat_ruralidad = NA_character_) |>
  select(grupo, cambio_participacion_pp, ipm_dnp, cat_ruralidad)

base_matriz <- bind_rows(base_domestico, base_exterior)
stopifnot(nrow(base_matriz) == 1122L + 67L)

pares_spec <- list(
  list(tratado = "control_armado",   referencia = "resto_colombia",                solo_sin_controles = FALSE),
  list(tratado = "control_armado",   referencia = "exterior",                       solo_sin_controles = TRUE),
  list(tratado = "control_armado",   referencia = c("resto_colombia", "exterior"),  solo_sin_controles = FALSE),
  list(tratado = "conflicto_activo", referencia = "resto_colombia",                solo_sin_controles = FALSE),
  list(tratado = "conflicto_activo", referencia = "exterior",                       solo_sin_controles = TRUE),
  list(tratado = "conflicto_activo", referencia = c("resto_colombia", "exterior"),  solo_sin_controles = FALSE)
)

controles_spec <- list(
  list(nombre = "sin_controles",         vars = character(0)),
  list(nombre = "ipm_dnp",               vars = "ipm_dnp"),
  list(nombre = "cat_ruralidad",         vars = "cat_ruralidad"),
  list(nombre = "ipm_dnp + cat_ruralidad", vars = c("ipm_dnp", "cat_ruralidad"))
)

correr_especificacion <- function(tratado_grupos, referencia_grupos, vars_control) {
  datos_spec <- base_matriz |>
    filter(grupo %in% c(tratado_grupos, referencia_grupos)) |>
    mutate(tratado = if_else(grupo %in% tratado_grupos, 1L, 0L))

  formula_str <- paste(
    "cambio_participacion_pp ~ tratado",
    if (length(vars_control) > 0) paste("+", paste(vars_control, collapse = " + ")) else ""
  )
  modelo <- lm(as.formula(formula_str), data = datos_spec)

  stopifnot(nobs(modelo) >= 50)

  vc <- sandwich::vcovHC(modelo, type = "HC1")
  b <- coef(modelo)["tratado"]
  se <- sqrt(diag(vc))["tratado"]
  p <- 2 * pnorm(abs(b / se), lower.tail = FALSE)

  tibble(
    tratado = paste(tratado_grupos, collapse = " + "),
    referencia = paste(referencia_grupos, collapse = " + "),
    coef_tratado = unname(b),
    se_hc1 = unname(se),
    ic95_inf = unname(b - 1.96 * se),
    ic95_sup = unname(b + 1.96 * se),
    p_valor = unname(p),
    n_obs = nobs(modelo),
    r2_adj = summary(modelo)$adj.r.squared
  )
}

filas_matriz <- list()
for (par in pares_spec) {
  controles_a_correr <- if (par$solo_sin_controles) controles_spec[1] else controles_spec
  for (ctrl in controles_a_correr) {
    fila <- correr_especificacion(par$tratado, par$referencia, ctrl$vars)
    fila$controles <- ctrl$nombre
    filas_matriz[[length(filas_matriz) + 1]] <- fila
  }
}

matriz_robustez <- bind_rows(filas_matriz) |>
  mutate(sig = asteriscos(p_valor)) |>
  select(tratado, referencia, controles, coef_tratado, se_hc1, ic95_inf, ic95_sup,
         p_valor, sig, n_obs, r2_adj) |>
  arrange(tratado, referencia)

stopifnot(nrow(matriz_robustez) == 18L)

cat("\n=== TABLA 6: MATRIZ DE ROBUSTEZ COMPLETA (18 especificaciones) ===\n")
print(as.data.frame(matriz_robustez), row.names = FALSE, right = FALSE)
cat("*** p<0.001, ** p<0.01, * p<0.05\n")

write.csv(
  matriz_robustez,
  here::here("subproyectos/voto_fusil/outputs/tablas/matriz_robustez_completa.csv"),
  row.names = FALSE
)

cat("\n=== 05_exterior OK ===\n")
