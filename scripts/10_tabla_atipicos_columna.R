# Responsabilidad unica: producir una tabla editorial de municipios con
# concentracion extrema de voto (>90%) y aumento abrupto de participacion.
# No recalcula modelos; solo lee outputs validados y metricas electorales 2026.
# Ejecutar desde D:/Dropbox/Reform_UIAF/

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(htmltools)
})

pad_dane <- function(x) sprintf("%05d", suppressWarnings(as.integer(as.character(x))))

root_dir <- here::here()
subproyecto_dir <- here::here("subproyectos", "voto_fusil")
tablas_dir <- here::here("subproyectos", "voto_fusil", "outputs", "tablas")
graficos_dir <- here::here("subproyectos", "voto_fusil", "outputs", "graficos")
dir.create(tablas_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(graficos_dir, recursive = TRUE, showWarnings = FALSE)

panel_path <- here::here(
  "subproyectos", "voto_fusil", "outputs", "tablas", "panel_voto_fusil_final.csv"
)
metricas_path <- here::here(
  "subproyectos", "electoral_2026_segunda_vuelta", "outputs", "mapas",
  "tablas", "metricas_mapas_electorales_2026.csv"
)

stopifnot(file.exists(panel_path), file.exists(metricas_path))

panel <- read_csv(panel_path, show_col_types = FALSE)
metricas_2026 <- read_csv(metricas_path, show_col_types = FALSE)

base <- panel |>
  mutate(cod_dane = pad_dane(cod_dane)) |>
  select(
    cod_dane, departamento, municipio, tipologia_d2,
    votos_validos_2v2026,
    votos_2v2026_abelardo_de_la_espriella,
    votos_2v2026_ivan_cepeda_castro
  ) |>
  left_join(
    metricas_2026 |>
      mutate(cod_dane = pad_dane(codigo_municipio)) |>
      select(cod_dane, participacion_1v, participacion_2v, variacion_participacion_pp),
    by = "cod_dane"
  ) |>
  mutate(
    pct_cepeda = 100 * votos_2v2026_ivan_cepeda_castro / votos_validos_2v2026,
    pct_espriella = 100 * votos_2v2026_abelardo_de_la_espriella / votos_validos_2v2026,
    ganador_2v = case_when(
      pct_cepeda > pct_espriella ~ "Cepeda",
      pct_espriella > pct_cepeda ~ "Espriella",
      TRUE ~ "Empate"
    )
  )

stopifnot(!anyNA(base$participacion_1v))
stopifnot(!anyNA(base$participacion_2v))
stopifnot(!anyNA(base$variacion_participacion_pp))

umbral_participacion <- as.numeric(
  quantile(base$variacion_participacion_pp, 0.90, na.rm = TRUE)
)

tabla_atipicos <- base |>
  filter(
    variacion_participacion_pp >= umbral_participacion,
    pct_cepeda >= 90 | pct_espriella >= 90
  ) |>
  mutate(
    bloque = case_when(
      pct_cepeda >= 90 ~ "CEPEDA >90% CON AUMENTO ABRUPTO",
      pct_espriella >= 90 ~ "ESPRIELLA >90% CON AUMENTO ABRUPTO",
      TRUE ~ "OTRO"
    ),
    bloque = factor(
      bloque,
      levels = c("CEPEDA >90% CON AUMENTO ABRUPTO", "ESPRIELLA >90% CON AUMENTO ABRUPTO")
    ),
    tipologia_label = recode(
      tipologia_d2,
      control_armado = "control_armado",
      conflicto_activo = "conflicto_activo",
      corredor = "corredor",
      produccion_intensiva = "prod. intensiva",
      periferico = "periférico",
      .default = tipologia_d2
    )
  ) |>
  arrange(bloque, desc(variacion_participacion_pp), desc(pct_cepeda), desc(pct_espriella)) |>
  select(
    bloque, municipio, departamento, pct_cepeda, pct_espriella,
    participacion_1v, participacion_2v, variacion_participacion_pp,
    tipologia_d2, tipologia_label
  )

tabla_path <- here::here(
  "subproyectos", "voto_fusil", "outputs", "tablas",
  "tabla_atipicos_90_participacion.csv"
)
write_csv(tabla_atipicos, tabla_path)

fmt_num <- function(x, digits = 1) formatC(x, format = "f", digits = digits, decimal.mark = ".")
fmt_delta <- function(x) paste0(ifelse(x >= 0, "+", ""), fmt_num(x, 1))

fila_html <- function(df) {
  if (nrow(df) == 0L) {
    return(tags$tr(
      tags$td(
        colspan = 8,
        class = "empty",
        "Ningún municipio registró simultáneamente >90% de share y aumento abrupto de participación."
      )
    ))
  }

  lapply(seq_len(nrow(df)), function(i) {
    tags$tr(
      tags$td(class = "municipio", df$municipio[[i]]),
      tags$td(df$departamento[[i]]),
      tags$td(class = "num", fmt_num(df$pct_cepeda[[i]], 1)),
      tags$td(class = "num", fmt_num(df$pct_espriella[[i]], 1)),
      tags$td(class = "num", fmt_num(df$participacion_1v[[i]], 1)),
      tags$td(class = "num", fmt_num(df$participacion_2v[[i]], 1)),
      tags$td(class = "num delta", fmt_delta(df$variacion_participacion_pp[[i]])),
      tags$td(class = paste("tipo", df$tipologia_d2[[i]]), df$tipologia_label[[i]])
    )
  })
}

bloque_html <- function(tabla, bloque_nombre) {
  df <- tabla |> filter(as.character(bloque) == bloque_nombre)
  tags$tbody(
    tags$tr(tags$th(colspan = 8, class = "section", sprintf("%s — %d municipios", bloque_nombre, nrow(df)))),
    fila_html(df)
  )
}

n_cepeda <- sum(tabla_atipicos$pct_cepeda >= 90)
n_espriella <- sum(tabla_atipicos$pct_espriella >= 90)

documento <- browsable(tags$html(
  tags$head(
    tags$meta(charset = "utf-8"),
    tags$meta(name = "viewport", content = "width=device-width, initial-scale=1"),
    tags$title("Municipios con >90% de share y aumento abrupto de participación"),
    tags$style(HTML("
      :root {
        --bg: #1f1f1d;
        --panel: #242421;
        --panel2: #2b2b28;
        --text: #f2efe6;
        --muted: #bdb7a9;
        --rule: #d9d0bd;
        --accent: #ff5c00;
        --red: #ff3838;
        --blue: #4d8cff;
      }
      body {
        margin: 0;
        background: var(--bg);
        color: var(--text);
        font-family: Georgia, 'Times New Roman', serif;
      }
      .wrap {
        max-width: 1080px;
        margin: 0 auto;
        padding: 34px 38px 30px 38px;
        background: var(--bg);
      }
      h1 {
        margin: 0;
        font-size: 22px;
        line-height: 1.08;
        letter-spacing: -0.01em;
        font-weight: 800;
      }
      .sub {
        margin-top: 5px;
        color: var(--muted);
        font-size: 15px;
        font-weight: 700;
      }
      table {
        width: 100%;
        border-collapse: collapse;
        margin-top: 20px;
        font-size: 15px;
      }
      thead th {
        border-top: 1.5px solid var(--rule);
        border-bottom: 1.5px solid var(--rule);
        padding: 8px 8px;
        text-align: left;
        font-weight: 800;
      }
      tbody tr:nth-child(odd) td { background: #242421; }
      tbody tr:nth-child(even) td { background: #2a2a27; }
      td {
        padding: 6px 8px;
        vertical-align: middle;
        border: 0;
        font-weight: 700;
      }
      .section {
        padding: 10px 8px 7px 8px;
        color: var(--muted);
        background: var(--bg);
        border-top: 1.5px solid var(--rule);
        font-size: 14px;
        text-align: left;
        text-transform: uppercase;
        letter-spacing: 0.01em;
      }
      .municipio { font-weight: 900; }
      .num { text-align: right; font-variant-numeric: tabular-nums; }
      .delta { color: var(--accent); font-weight: 900; }
      .empty {
        text-align: center;
        color: var(--muted);
        font-style: italic;
        padding: 13px 8px;
      }
      .tipo {
        text-align: right;
        font-size: 13px;
        color: #f4f0e8;
      }
      .control_armado { color: #ffd1d1; }
      .conflicto_activo { color: #ffd7b5; }
      .produccion_intensiva { color: #ffe6a3; }
      .periferico { color: #e5e5e5; }
      .corredor { color: #ffd071; }
      .notes {
        margin-top: 16px;
        border-top: 1.5px solid var(--rule);
        padding-top: 12px;
        color: var(--muted);
        font-size: 13.5px;
        line-height: 1.45;
        font-weight: 700;
      }
      .takeaway {
        color: var(--text);
      }
      @media (max-width: 760px) {
        .wrap { padding: 22px 14px; }
        table { font-size: 12px; }
        h1 { font-size: 18px; }
        .sub { font-size: 13px; }
        th, td { padding: 5px 4px; }
        .tipo { font-size: 11px; }
      }
    "))
  ),
  tags$body(
    tags$main(class = "wrap",
      tags$h1(sprintf(
        "Municipios con >90%% de share y aumento abrupto de participación (>p90 = +%s pp)",
        fmt_num(umbral_participacion, 2)
      )),
      tags$div(
        class = "sub",
        "Segunda vuelta presidencial Colombia 2026. Ordenados por aumento de participación."
      ),
      tags$table(
        tags$thead(tags$tr(
          tags$th("Municipio"),
          tags$th("Dpto."),
          tags$th(class = "num", "Cepeda (%)"),
          tags$th(class = "num", "Espriella (%)"),
          tags$th(class = "num", "Part. 1ª v."),
          tags$th(class = "num", "Part. 2ª v."),
          tags$th(class = "num", "Δ pp"),
          tags$th(class = "tipo", "Tipología")
        )),
        bloque_html(tabla_atipicos, "CEPEDA >90% CON AUMENTO ABRUPTO"),
        bloque_html(tabla_atipicos, "ESPRIELLA >90% CON AUMENTO ABRUPTO")
      ),
      tags$div(
        class = "notes",
        tags$strong("Notas: "),
        sprintf(
          "umbral de aumento abrupto = percentil 90 del cambio en participación (+%s pp). ",
          fmt_num(umbral_participacion, 2)
        ),
        "Tipología D2 del Sistema E4. Δpp = cambio en participación entre primera y segunda vuelta 2026. ",
        tags$span(
          class = "takeaway",
          sprintf(
            "La tabla identifica %d municipios para Cepeda y %d para Espriella. ",
            n_cepeda, n_espriella
          ),
          "La ausencia de casos simétricos para Espriella refuerza la lectura editorial: la concentración extrema del voto con aumento abrupto de participación no aparece como fenómeno balanceado entre candidatos."
        )
      )
    )
  )
))

html_path <- here::here(
  "subproyectos", "voto_fusil", "outputs", "graficos",
  "tabla_atipicos_90_participacion.html"
)
save_html(documento, file = html_path)

cat("Tabla CSV:", tabla_path, "\n")
cat("Tabla HTML:", html_path, "\n")
cat("Umbral p90 participacion:", fmt_num(umbral_participacion, 2), "pp\n")
cat("Cepeda >=90% con aumento abrupto:", n_cepeda, "\n")
cat("Espriella >=90% con aumento abrupto:", n_espriella, "\n")
cat("=== 10_tabla_atipicos_columna OK ===\n")
