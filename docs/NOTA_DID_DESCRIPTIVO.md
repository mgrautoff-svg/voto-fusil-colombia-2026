# Nota tecnica: DiD descriptivo

El proyecto usa la expresion "DiD" como abreviatura comunicativa de una
diferencia de cambios entre grupos. No debe leerse como un diseno causal fuerte
de diferencias en diferencias con tendencias paralelas verificadas.

## Que se calcula

Para cada grupo se calcula:

```text
cambio_participacion_pp = participacion_2v_2026 - participacion_1v_2026
```

Luego se comparan cambios medios:

```text
Diferencia de cambios = cambio medio del grupo tratado - cambio medio del grupo de referencia
```

Ejemplo intuitivo:

- control armado: +11.27 pp;
- conflicto activo: +8.81 pp;
- resto Colombia: +7.60 pp;
- exterior: +1.46 pp.

La barra de exterior se interpreta como linea base de polarizacion nacional pura:
sube la participacion sin estar expuesta a control territorial armado colombiano.

## Que no se afirma

No se afirma que el modelo identifique causalmente el efecto del control armado
como lo haria un experimento natural. No se prueban tendencias paralelas ni se
observan votantes individuales.

## Para que sirve

Sirve para ordenar magnitudes y comunicar un contraste: el aumento de
participacion en territorios de control armado es mucho mayor que el del exterior
y mayor que el del resto del pais. La robustez se evalua despues con OLS y
errores robustos HC1 en `outputs/tablas/matriz_robustez_completa.csv`.

## Frase recomendada

"El DiD usado en la visualizacion es descriptivo: compara cambios medios de
participacion entre grupos. La inferencia principal se apoya en la matriz de
robustez con errores robustos, no en una pretension causal fuerte."
