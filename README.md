# Voto fusil Colombia 2026

Repositorio público de auditoría, resultados y visualizaciones para la columna:

**No es voto fusil. Es voto pistola con silenciador.**

El análisis estudia si la narrativa del “voto fusil” en la segunda vuelta presidencial de Colombia 2026 se sostiene en datos municipales. La conclusión central es más precisa: la violencia armada reciente no presenta una señal robusta, mientras el control armado consolidado sí aparece asociado con un mayor aumento de participación electoral.

## Hallazgo central

La matriz de robustez separa dos mecanismos:

- **Control armado consolidado:** coeficiente positivo y significativo en 9 de 9 especificaciones, con magnitudes entre +1.39 y +9.81 puntos porcentuales.
- **Conflicto activo reciente:** señal inestable. Frente al resto de Colombia es positivo sin controles (+1.21 pp), pero cambia de signo al agregar pobreza multidimensional (-0.65 pp).

La lectura correcta no es causal dura ni individual. Es una asociación territorial robusta: donde el control armado se volvió institución paralela, la participación aumentó más.

## Visualizaciones públicas

Si GitHub Pages está activo, las visualizaciones estarán disponibles en:

- [`docs/publicacion/voto_fusil/`](docs/publicacion/voto_fusil/)
- [`mapa_control_territorial.html`](docs/publicacion/voto_fusil/mapa_control_territorial.html)
- [`viz_did_intuitiva.html`](docs/publicacion/voto_fusil/viz_did_intuitiva.html)
- [`tabla_atipicos_90_participacion.html`](docs/publicacion/voto_fusil/tabla_atipicos_90_participacion.html)
- [`mapa_tipologia_territorial.html`](docs/publicacion/voto_fusil/mapa_tipologia_territorial.html)

Iframe sugerido para WordPress:

```html
<iframe
  src="https://mgrautoff-svg.github.io/voto-fusil-colombia-2026/publicacion/voto_fusil/mapa_control_territorial.html"
  width="100%"
  height="720"
  style="border:0;"
  loading="lazy">
</iframe>
```

## Columna

La pieza editorial está en:

- [`outputs/pieza_editorial_voto_fusil.md`](outputs/pieza_editorial_voto_fusil.md)

## Resultados auditables

Las tablas principales están en:

- [`outputs/tablas/matriz_robustez_completa.csv`](outputs/tablas/matriz_robustez_completa.csv)
- [`outputs/tablas/resumen_cuatro_grupos.csv`](outputs/tablas/resumen_cuatro_grupos.csv)
- [`outputs/tablas/did_cuatro_grupos.csv`](outputs/tablas/did_cuatro_grupos.csv)
- [`outputs/tablas/did_ajustado_ipm_ruralidad.csv`](outputs/tablas/did_ajustado_ipm_ruralidad.csv)

## Alcance metodológico

Este repositorio publica código, resultados y visualizaciones para auditoría. No contiene todos los datos crudos ni pretende ser un pipeline autónomo fuera del entorno original.

El diseño es observacional y agregado:

- compara cambios de participación entre grupos territoriales;
- usa pruebas de Welch;
- usa modelos OLS con errores robustos HC1;
- controla por pobreza, ruralidad y otras condiciones territoriales según especificación.

No identifica coerción individual ni prueba causalidad electoral definitiva.

## Fuente y construcción

Manfred Grautoff · Sistema E4, Registraduría, ACLED, UNODC.
