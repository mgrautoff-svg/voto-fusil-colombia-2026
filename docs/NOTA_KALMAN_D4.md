# Nota tecnica: D4/Kalman

El proyecto reviso el filtro de Kalman importado desde `conflict_armed`, pero no
lo usa como estimador principal de participacion electoral.

## Origen

El proceso fuente esta en el proyecto `conflict_armed`, script:

```text
scripts/03_clasificacion_territorial/03_coercion_territorial.R
```

El objeto resultante usado como referencia fue:

```text
data/intermediate/modelos/M4_coercion_D4.rds
```

## Como se construyo el componente Kalman

Se construyo un panel mensual 2018-2023 y se suavizaron series municipales con
KFAS:

```r
SSModel(serie ~ SSMtrend(1, Q = NA), H = NA)
fitSSM(..., method = "BFGS")
KFS(...)
```

Las variables suavizadas fueron:

- `homicidios`;
- `acled_fat_pt`;
- `amenazas`;
- `secuestro`;
- `terrorismo`.

Despues se agregaron promedios anuales y se normalizaron componentes.

## Formula documentada

El componente de violencia suavizada fue:

```text
kalman_violencia =
  0.35 * homicidios normalizados +
  0.30 * fatalidades ACLED normalizadas +
  0.20 * amenazas normalizadas +
  0.10 * secuestro normalizado +
  0.05 * terrorismo normalizado
```

El indice D4 de coercion territorial combino:

- `kalman_violencia`: 0.28;
- `targeting_letalidad`: 0.18;
- `targeting_frecuencia`: 0.07;
- `tasa_lideres`: 0.15;
- `tasa_firmantes`: 0.15;
- `abstencion`: 0.17.

## Por que no es estimador principal aqui

D4/Kalman es conceptualmente atractivo, pero para este subproyecto tiene tres
problemas:

1. Incluye ACLED, que ya entra por otra via como exposicion armada reciente.
2. Incluye abstencion, que se solapa con la variable de participacion electoral.
3. Se correlaciona con pobreza, ruralidad, coca, PDET y control territorial.

Al correrlo contra participacion y luego agregar controles, la senal queda
absorbida. Eso no significa que D4 este mal construido; significa que no es limpio
para responder esta pregunta concreta sin circularidad.

## Decision metodologica

Se descarta D4/Kalman como variable principal y se usa D2 como tipologia
territorial. D2 permite separar mejor control estructural, conflicto activo,
corredores, produccion intensiva y periferia.

Frase recomendada:

"D4/Kalman fue usado como exploracion de coercion territorial, pero no como
estimador principal porque incorpora componentes de violencia y abstencion que
generan solapamiento con la variable dependiente y con controles del modelo."
