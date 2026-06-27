# Metodologia del subproyecto voto_fusil

Este subproyecto analiza si los cambios electorales de 2026 se asocian mas con
eventos armados recientes o con control territorial armado de largo plazo.

## Unidad de analisis

- Unidad principal: municipio colombiano.
- Universo domestico: 1.122 municipios.
- Contraste adicional: 67 paises del voto exterior.
- Variable de resultado principal para la matriz de robustez: cambio en
  participacion electoral entre primera y segunda vuelta presidencial de 2026,
  medido en puntos porcentuales.

## Dos conceptos que no deben confundirse

### 1. Violencia reciente visible

Se construye con eventos ACLED en ventana preelectoral:

- noviembre-diciembre de 2025;
- enero-marzo de 2026;
- abril-mayo de 2026.

El indice de exposicion suma eventos de violencia politica y conflicto. La
variable `alta_exposicion` identifica municipios por encima del umbral configurado
en `scripts/00_config.R`.

Resultado: esta variable no entrega el hallazgo principal. En los modelos de
participacion con controles, la exposicion armada reciente no es robusta. Captura
el "fusil visible": eventos, choques y violencia explicita.

### 2. Control territorial estructural

Se usa la tipologia D2 del Sistema E4 importada del proyecto `conflict_armed`.
D2 clasifica municipios en cinco grupos:

- `control_armado`;
- `conflicto_activo`;
- `corredor`;
- `produccion_intensiva`;
- `periferico`.

D2 no mide un evento reciente. Mide arquitectura territorial: economias ilicitas,
presencia de grupos, corredores, homicidios, liderazgo social y violencia politica
promedio historica.

Resultado: `control_armado` es la categoria que conserva asociacion positiva y
significativa con el aumento de participacion en la matriz de robustez.

## Modelos estimados

El proyecto corre tres familias de especificaciones.

### A. Modelos con exposicion armada reciente

Formula base de voto:

```r
cambio_pp ~ alta_exposicion + ipm_dnp + ha_coca + pdet + cat_ruralidad
```

Formula base de participacion:

```r
cambio_participacion_pp ~ alta_exposicion + ipm_dnp + ha_coca + pdet + cat_ruralidad + pct22_fajardo
```

Estos modelos muestran que los eventos recientes de ACLED no explican de forma
robusta el salto de participacion. Por eso el proyecto abandona la tesis simple
del "voto fusil" entendido como intimidacion reciente visible.

### B. Modelos con tipologia territorial D2

Se agregan las categorias de D2 con `periferico` como referencia. En
especificaciones saturadas, parte de la senal queda absorbida por pobreza,
ruralidad, coca, PDET y voto historico. Este bloque sirve como diagnostico de
colinealidad y heterogeneidad territorial, no como resultado final.

### C. Matriz de robustez focal

La matriz final evalua dos tratamientos:

- `control_armado`;
- `conflicto_activo`.

Y tres referencias:

- `resto_colombia`;
- `exterior`;
- `resto_colombia + exterior`.

Con cuatro esquemas cuando aplica:

- sin controles;
- `ipm_dnp`;
- `cat_ruralidad`;
- `ipm_dnp + cat_ruralidad`.

El exterior solo se usa sin controles cuando es referencia pura, porque no tiene
IPM ni ruralidad municipal colombiana.

## Resultado central

El coeficiente de `control_armado` es positivo y significativo en 9 de 9
especificaciones de la matriz. El rango va de +1.39 a +9.81 puntos porcentuales.

El coeficiente de `conflicto_activo` es inestable. Es positivo sin controles,
pero frente al resto de Colombia cambia de signo cuando se agrega IPM:

- sin controles: +1.21 pp;
- con IPM: -0.65 pp;
- con IPM y ruralidad: -0.66 pp.

Interpretacion tecnica: el conflicto visible reciente se confunde con pobreza y
ruralidad; el control armado estructural persiste incluso al ajustar por esos
factores externos a D2.

## Limites

El diseno es observacional, municipal y agregado. No identifica decisiones
individuales, no prueba causalidad individual y no descarta episodios puntuales
de coaccion. La lectura correcta es asociacional: territorios con control armado
estructural registran aumentos de participacion mayores y robustos frente a
distintas referencias.
