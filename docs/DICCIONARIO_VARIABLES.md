# Diccionario de variables clave

## Identificacion territorial

| Variable | Descripcion |
|---|---|
| `cod_dane` | Codigo DANE municipal de cinco digitos. |
| `municipio` | Nombre del municipio. |
| `departamento` | Departamento. |

## Resultados electorales

| Variable | Descripcion |
|---|---|
| `participacion_1v` | Participacion electoral en primera vuelta presidencial 2026. |
| `participacion_2v` | Participacion electoral en segunda vuelta presidencial 2026. |
| `cambio_participacion_pp` | Diferencia en puntos porcentuales entre segunda y primera vuelta de 2026. |
| `cambio_pp` | Cambio del voto de izquierda entre segunda vuelta de 2022 y segunda vuelta de 2026. |
| `pct22_fajardo` | Voto de centro en 2022 usado como control de composicion politica previa. |

## Violencia reciente

| Variable | Descripcion |
|---|---|
| `idx_exposicion` | Suma de eventos ACLED seleccionados en ventana preelectoral 2025-2026. |
| `alta_exposicion` | Indicador de municipios con exposicion armada alta segun umbral configurado. |
| `pv_total` | Total de eventos de violencia politica ACLED en la ventana. |
| `ct_total` | Total de eventos de conflicto ACLED en la ventana. |

## Control territorial

| Variable | Descripcion |
|---|---|
| `tipologia_d2` | Categoria territorial D2 importada del Sistema E4. |
| `control_armado` | Categoria D2 de control armado consolidado. |
| `conflicto_activo` | Categoria D2 de violencia en curso sin control consolidado. |
| `corredor` | Categoria D2 de corredor estrategico. |
| `produccion_intensiva` | Categoria D2 asociada a produccion ilicita intensiva. |
| `periferico` | Categoria D2 de referencia territorial. |

## Controles socioeconomicos

| Variable | Descripcion |
|---|---|
| `ipm_dnp` | Indice de pobreza multidimensional municipal del DNP. |
| `cat_ruralidad` | Categoria de ruralidad municipal. |
| `ha_coca` | Hectareas de coca, tratadas como cero cuando la fuente indica ausencia. |
| `pdet` | Indicador de municipio PDET. |

## Matriz de robustez

| Variable | Descripcion |
|---|---|
| `tratado` | Grupo comparado: `control_armado` o `conflicto_activo`. |
| `referencia` | Grupo base de comparacion: resto Colombia, exterior o combinacion. |
| `controles` | Esquema de controles usado en la especificacion. |
| `coef_tratado` | Diferencia estimada en puntos porcentuales de participacion. |
| `se_hc1` | Error estandar robusto HC1. |
| `p_valor` | Valor p robusto asociado al coeficiente del tratamiento. |
| `n_obs` | Observaciones efectivas del modelo. |
