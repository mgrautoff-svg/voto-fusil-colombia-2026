# Responsabilidad: producir la visualizacion DiD para lector general y
# actualizar la pieza editorial usando resultados ya calculados.
# Prerequisitos: ejecutar antes 05_exterior_grupo_control.R.

suppressPackageStartupMessages({
  library(dplyr)
  library(htmlwidgets)
  library(plotly)
  library(readr)
})

matriz_path <- here::here(
  "subproyectos", "voto_fusil", "outputs", "tablas",
  "matriz_robustez_completa.csv"
)
resumen_path <- here::here(
  "subproyectos", "voto_fusil", "outputs", "tablas",
  "resumen_cuatro_grupos.csv"
)
did_ajustado_path <- here::here(
  "subproyectos", "voto_fusil", "outputs", "tablas",
  "did_ajustado_ipm_ruralidad.csv"
)
visualizacion_path <- here::here(
  "subproyectos", "voto_fusil", "outputs", "graficos",
  "viz_did_intuitiva.html"
)
editorial_path <- here::here(
  "subproyectos", "voto_fusil", "outputs",
  "pieza_editorial_voto_fusil.md"
)

rutas_requeridas <- c(matriz_path, resumen_path, did_ajustado_path)
if (any(!file.exists(rutas_requeridas))) {
  stop(
    "Faltan resultados previos: ",
    paste(rutas_requeridas[!file.exists(rutas_requeridas)], collapse = ", "),
    call. = FALSE
  )
}

dir.create(dirname(visualizacion_path), recursive = TRUE, showWarnings = FALSE)

matriz <- read_csv(matriz_path, show_col_types = FALSE)
resumen <- read_csv(resumen_path, show_col_types = FALSE)
did_ajustado <- read_csv(did_ajustado_path, show_col_types = FALSE)

# TAREA 1 — Visualizacion DiD intuitiva --------------------------------------
# La matriz guarda diferencias frente al grupo de referencia, no las medias
# absolutas. Por eso las barras usan resumen_cuatro_grupos.csv y se auditan
# contra las filas sin controles frente al exterior de la matriz.
contrastes_exterior <- matriz |>
  filter(
    controles == "sin_controles",
    referencia == "exterior",
    tratado %in% c("control_armado", "conflicto_activo")
  ) |>
  select(tratado, coef_tratado)

if (nrow(contrastes_exterior) != 2L) {
  stop("La matriz no contiene los dos contrastes sin controles frente al exterior.", call. = FALSE)
}

grupos_requeridos <- c(
  "control_armado", "conflicto_activo", "resto_colombia", "exterior"
)
if (!setequal(resumen$grupo, grupos_requeridos)) {
  stop("resumen_cuatro_grupos.csv no contiene exactamente los cuatro grupos esperados.", call. = FALSE)
}

media_exterior <- resumen$media_cambio_pp[resumen$grupo == "exterior"]
for (grupo_actual in c("control_armado", "conflicto_activo")) {
  media_grupo <- resumen$media_cambio_pp[resumen$grupo == grupo_actual]
  contraste <- contrastes_exterior$coef_tratado[
    contrastes_exterior$tratado == grupo_actual
  ]
  if (abs((media_grupo - media_exterior) - contraste) > 0.02) {
    stop("La matriz y el resumen no coinciden para ", grupo_actual, call. = FALSE)
  }
}

diccionario_grupos <- tibble::tribble(
  ~grupo,             ~etiqueta,          ~descripcion,                                                   ~color,
  "control_armado",  "Control armado",  "Orden territorial consolidado durante años",                  "#8B0000",
  "conflicto_activo", "Conflicto activo", "Violencia reciente sin control territorial estable",          "#E05C00",
  "resto_colombia",  "Resto Colombia",  "Municipios fuera de las dos tipologías armadas principales",   "#888888",
  "exterior",        "Exterior",        "Voto sin exposición territorial a grupos armados colombianos", "#CCCCCC"
)

datos_barras <- resumen |>
  select(grupo, media_cambio_pp) |>
  inner_join(diccionario_grupos, by = "grupo") |>
  arrange(media_cambio_pp) |>
  mutate(
    etiqueta_eje = paste0(
      "<b>", etiqueta, "</b><br>",
      "<span style='font-size:10px;color:#666666'>", descripcion, "</span>"
    ),
    etiqueta_numero = sprintf("<b>+%.2f pp</b>", media_cambio_pp)
  )

orden_eje <- datos_barras$etiqueta_eje
linea_base <- media_exterior

fig_did <- plot_ly(
  datos_barras,
  x = ~media_cambio_pp,
  y = ~etiqueta_eje,
  type = "bar",
  orientation = "h",
  marker = list(color = ~color),
  text = ~etiqueta_numero,
  textposition = "outside",
  textfont = list(family = "Arial, sans-serif", size = 14, color = "#222222"),
  hovertemplate = "%{y}<br>Cambio: %{x:.2f} pp<extra></extra>"
) |>
  layout(
    title = list(
      text = paste0(
        "<b>No es voto fusil. Es voto pistola con silenciador.</b><br>",
        "<span style='font-size:16px;font-weight:normal'>",
        "Cambio en participación electoral entre primera y segunda vuelta 2026",
        "</span>"
      ),
      x = 0.02,
      xanchor = "left"
    ),
    font = list(family = "Arial, sans-serif", color = "#222222"),
    paper_bgcolor = "#FFFFFF",
    plot_bgcolor = "#FFFFFF",
    showlegend = FALSE,
    margin = list(l = 245, r = 95, t = 105, b = 90),
    xaxis = list(
      title = "",
      showticklabels = FALSE,
      showgrid = FALSE,
      zeroline = FALSE,
      range = c(0, max(datos_barras$media_cambio_pp) * 1.18),
      fixedrange = TRUE
    ),
    yaxis = list(
      title = "",
      categoryorder = "array",
      categoryarray = orden_eje,
      showgrid = FALSE,
      fixedrange = TRUE
    ),
    shapes = list(list(
      type = "line",
      x0 = linea_base,
      x1 = linea_base,
      y0 = -0.5,
      y1 = 3.5,
      line = list(color = "#555555", width = 1.5, dash = "dot")
    )),
    annotations = list(
      list(
        x = linea_base,
        y = 1.06,
        xref = "x",
        yref = "paper",
        text = "Línea base: polarización nacional pura",
        showarrow = FALSE,
        xanchor = "left",
        font = list(size = 11, color = "#555555")
      ),
      list(
        x = 0,
        y = -0.20,
        xref = "paper",
        yref = "paper",
        text = paste0(
          "Fuente y construcción: Manfred Grautoff · Sistema E4, Registraduría, ACLED · ",
          "github.com/mgrautoff-svg/voto-fusil-colombia-2026"
        ),
        showarrow = FALSE,
        xanchor = "left",
        font = list(size = 10, color = "#666666")
      )
    )
  ) |>
  config(displayModeBar = FALSE, responsive = TRUE)

saveWidget(fig_did, visualizacion_path, selfcontained = TRUE)

# TAREA 2 — Pieza editorial --------------------------------------------------
control_armado <- matriz |> filter(tratado == "control_armado")
conflicto_activo <- matriz |> filter(tratado == "conflicto_activo")
fila_did_ajustado <- did_ajustado |> filter(termino == "tratado")
fila_did_limpio <- matriz |>
  filter(
    tratado == "control_armado",
    referencia == "resto_colombia",
    controles == "sin_controles"
  )

if (
  nrow(control_armado) != 9L ||
  sum(control_armado$coef_tratado > 0 & control_armado$p_valor < 0.05) != 9L ||
  nrow(fila_did_ajustado) != 1L ||
  nrow(fila_did_limpio) != 1L
) {
  stop("Los resultados no sostienen los numeros requeridos por la pieza editorial.", call. = FALSE)
}

conflicto_resto <- conflicto_activo |> filter(referencia == "resto_colombia")
if (!any(conflicto_resto$coef_tratado > 0) || !any(conflicto_resto$coef_tratado < 0)) {
  stop("Conflicto activo no cambia de signo frente al resto de Colombia.", call. = FALSE)
}
conflicto_sin_controles <- conflicto_resto |> filter(controles == "sin_controles")
conflicto_ipm <- conflicto_resto |> filter(controles == "ipm_dnp")
if (nrow(conflicto_sin_controles) != 1L || nrow(conflicto_ipm) != 1L) {
  stop("Faltan especificaciones clave de conflicto activo frente al resto de Colombia.", call. = FALSE)
}

pieza <- sprintf(
'# No es voto fusil. Es voto pistola con silenciador.

## 1. La acusación

La acusación era demasiado perfecta: en municipios con presencia histórica de grupos armados, Iván Cepeda aumentó votos y participación; por tanto, alguien con fusil habría ordenado votar. La frase llegó lista para circular: “voto fusil”. Un hombre armado, una instrucción y una urna. El mapa parecía cerrar el caso antes de abrirlo.

El problema es que una coincidencia municipal no prueba una historia causal. Por eso cruzamos los 1.122 municipios con eventos armados de ACLED entre noviembre de 2025 y mayo de 2026, resultados electorales de 2018 a 2026, controles de pobreza, ruralidad, coca y municipios PDET, y el exterior como contraste sin control territorial colombiano.

La primera conclusión incomoda a ambos bandos. Los datos municipales no miran dentro de cada cabina ni descartan episodios particulares de coacción. Pero tampoco muestran el patrón agregado que necesitaría la tesis simple del “voto fusil”: violencia reciente, orden reciente, voto reciente. Cuando se agregan controles territoriales, esa señal coyuntural se vuelve inestable.

## 2. El hallazgo

La historia cambia cuando se separa el fusil visible de la pistola silenciosa. La tipología del Sistema E4 distingue municipios con conflicto activo —donde hay violencia reciente— de territorios con control armado consolidado, donde un actor ilegal lleva años administrando reglas, castigos, rentas y autoridad cotidiana.

Panel A: control armado. El coeficiente es positivo y estadísticamente significativo en las nueve especificaciones. Sin excepción. No depende de escoger una referencia cómoda: sobrevive frente al resto de Colombia, frente al exterior y frente a ambos grupos combinados. La magnitud cae cuando entran pobreza y ruralidad, pero la señal no desaparece. El rango va de +%.2f a +%.2f puntos porcentuales.

Panel B: conflicto activo. Ahí pasa lo contrario. Sin controles, frente al resto de Colombia, el coeficiente es positivo: +%.2f puntos. Pero cuando entra el índice de pobreza multidimensional cambia de signo y cae a %.2f puntos. El fusil visible parece movilizar porque está parado sobre municipios más pobres. Una vez se compara con territorios parecidos en pobreza, deja de parecer motor electoral.

## 3. La explicación

Ana Arjona llama “rebelocracia” a los lugares donde una organización armada no se limita a combatir: impone reglas, resuelve disputas, cobra, castiga y organiza intercambios. Acemoglu y Robinson han mostrado, en otros contextos, que las instituciones pueden dejar efectos persistentes mucho después de su creación. El Estado ausente no deja un vacío limpio. Alguien ocupa ese espacio y convierte su autoridad en rutina.

Esa perspectiva ofrece una interpretación más seria que la caricatura de un guerrillero acompañando al votante. El control consolidado puede moldear redes, expectativas, permisos, silencios y formas de coordinación política sin aparecer el domingo de elecciones. También puede convivir con pobreza, economías ilegales y preferencias históricas. La regresión municipal no permite escoger definitivamente entre esos mecanismos. Sí permite observar algo más estrecho: el patrón estructural persiste; la violencia reciente no.

Por eso sería un error decir que los datos demuestran cómo votó cada habitante o prueban coerción individual. Este no es un diseño causal de diferencias en diferencias. Es una comparación descriptiva de cambios, con pruebas de Welch y OLS con errores robustos. La evidencia debe leerse como asociación territorial robusta: donde el control armado está consolidado, el aumento de participación fue mayor incluso después de controles centrales.

## 4. La paradoja

Cepeda perdió dentro de Colombia por 0,29 puntos porcentuales. En ese contexto, una comparación ajustada de +%.2f puntos y una diferencia simple de aumentos de +%.2f puntos no son una curiosidad menor. Son magnitudes electoralmente relevantes. No pueden convertirse mecánicamente en votos “causados” ni demostrar que decidieron el resultado, pero tampoco pueden barrerse como ruido.

La paradoja es política. El territorio que el Estado perdió aumentó más su participación cuando apareció un candidato que prometía recuperarlo. No sabemos si actuaron memoria institucional, redes locales, esperanza, presión o una mezcla de todas. Sabemos que esos municipios no fueron electoralmente inmóviles: salieron a votar en masa.

La acusación de “voto fusil” reduce décadas de construcción territorial a una orden dominical. La evidencia apunta a algo más profundo y menos cómodo. No es el evento armado reciente el que sobrevive a la matriz de robustez. Es el orden armado convertido en institución paralela.

La pregunta para el nuevo gobierno no es únicamente quién presionó a quién el día de la elección. Es si va a gobernar esos territorios con instituciones legítimas o seguirá administrando una ausencia cuyos efectos políticos ya son visibles.

*Datos, código y metodología: github.com/mgrautoff-svg/voto-fusil-colombia-2026*

---

Fuente y construcción: Manfred Grautoff · Sistema E4, Registraduría, ACLED, UNODC
',
  min(control_armado$coef_tratado),
  max(control_armado$coef_tratado),
  conflicto_sin_controles$coef_tratado,
  conflicto_ipm$coef_tratado,
  fila_did_ajustado$estimacion,
  fila_did_limpio$coef_tratado
)

palabras <- strsplit(
  trimws(gsub("[#*_—–¿?¡!.,:;()“”\\\"]", " ", pieza)),
  "\\s+"
)[[1]]
n_palabras <- sum(nzchar(palabras))
if (n_palabras < 750L || n_palabras > 800L) {
  stop(
    sprintf("La pieza editorial tiene %d palabras; se requieren entre 750 y 800.", n_palabras),
    call. = FALSE
  )
}

writeLines(enc2utf8(pieza), editorial_path, useBytes = TRUE)

cat("=== 08_editorial_final OK ===\n")
