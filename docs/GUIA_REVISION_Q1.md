# Guia para revision tecnica externa

Esta guia resume como auditar el subproyecto `voto_fusil` sin depender de la
pieza editorial.

## Archivos fuente de verdad

- `README.md`: resumen del proyecto y flujo reproducible.
- `docs/METODOLOGIA.md`: diseño analitico, familias de modelos y limites.
- `docs/NOTA_DID_DESCRIPTIVO.md`: alcance exacto de la diferencia de cambios.
- `docs/NOTA_KALMAN_D4.md`: decision de no usar D4/Kalman como estimador principal.
- `docs/M5_score_clasificacion_metadata.txt`: origen y composicion de D2.
- `outputs/tablas/matriz_robustez_completa.csv`: resultado focal.
- `scripts/05_exterior_grupo_control.R`: construccion de la matriz de robustez.
- `tests/test_03_numeros.R`: invariantes numericos del hallazgo central.

## Checklist de reproduccion

Desde la raiz de `D:/Dropbox/Reform_UIAF`:

```r
source("subproyectos/voto_fusil/run.R")
```

El run debe terminar con:

```text
=== PIPELINE voto_fusil COMPLETADO ===
```

Y los tests deben reportar:

- `test_01_prerequisitos PASSED`;
- `test_02_outputs PASSED`;
- `test_03_numeros PASSED`.

## Checklist de resultados

En `outputs/tablas/matriz_robustez_completa.csv` verificar:

- 18 especificaciones.
- 9 filas con `tratado == "control_armado"`.
- Todas las filas de `control_armado` con `coef_tratado > 0`.
- Todas las filas de `control_armado` con `p_valor < 0.05`.
- `conflicto_activo` cambia de signo cuando entra `ipm_dnp` frente a
  `resto_colombia`.

## Lectura correcta

El hallazgo tecnico es asociacional:

> Los municipios bajo control armado estructural registran aumentos de
> participacion mayores y robustos frente a varias referencias.

No se afirma:

- causalidad individual;
- prueba directa de coercion dentro de la cabina;
- que todo municipio con control armado haya votado por orden armada;
- que eventos recientes ACLED sean el mecanismo principal.

## Criterio de calidad

El repositorio es aceptable para revision externa si:

1. el pipeline corre sin errores;
2. los tests pasan;
3. la matriz conserva el patron 9/9 de `control_armado`;
4. el README y las notas metodologicas diferencian claramente entre
   visualizacion descriptiva, asociacion estadistica y argumento editorial.
