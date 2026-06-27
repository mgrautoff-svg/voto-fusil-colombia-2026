# Voto fusil Colombia 2026

Repositorio publico de auditoria metodologica, resultados y visualizaciones para
la columna:

**No es voto fusil. Es voto pistola con silenciador.**

El proyecto analiza si la narrativa del "voto fusil" en la segunda vuelta
presidencial de Colombia 2026 se sostiene en datos municipales. La conclusion
tecnica es mas precisa: la violencia armada reciente no presenta una senal
robusta; el control armado estructural si aparece asociado con un mayor aumento
de participacion electoral.

## Hallazgo central

La matriz de robustez separa dos mecanismos:

- **Control armado estructural:** coeficiente positivo y significativo en 9 de 9
  especificaciones, con magnitudes entre +1.39 y +9.81 puntos porcentuales.
- **Conflicto activo reciente:** senal inestable. Frente al resto de Colombia es
  positivo sin controles (+1.21 pp), pero cambia de signo al agregar pobreza
  multidimensional (-0.65 pp).

La lectura correcta no es causal individual. Es una asociacion territorial
robusta: donde el control armado se volvio institucion paralela, la participacion
aumento mas.

## Visualizaciones publicas

- [Mapa principal: control territorial y voto presidencial](https://mgrautoff-svg.github.io/voto-fusil-colombia-2026/publicacion/voto_fusil/mapa_control_territorial.html)
- [Visualizacion DiD descriptiva](https://mgrautoff-svg.github.io/voto-fusil-colombia-2026/publicacion/voto_fusil/viz_did_intuitiva.html)
- [Tabla editorial de municipios atipicos](https://mgrautoff-svg.github.io/voto-fusil-colombia-2026/publicacion/voto_fusil/tabla_atipicos_90_participacion.html)
- [Mapa de tipologia territorial](https://mgrautoff-svg.github.io/voto-fusil-colombia-2026/publicacion/voto_fusil/mapa_tipologia_territorial.html)

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

## Documentacion metodologica

- [`docs/METODOLOGIA.md`](docs/METODOLOGIA.md): diseno analitico, familias de
  modelos y resultado central.
- [`docs/NOTA_DID_DESCRIPTIVO.md`](docs/NOTA_DID_DESCRIPTIVO.md): por que el
  DiD de la visualizacion es descriptivo y no causal fuerte.
- [`docs/NOTA_KALMAN_D4.md`](docs/NOTA_KALMAN_D4.md): construccion del filtro
  Kalman/D4 y razon para no usarlo como estimador principal.
- [`docs/DICCIONARIO_VARIABLES.md`](docs/DICCIONARIO_VARIABLES.md): variables
  clave.
- [`docs/GUIA_REVISION_Q1.md`](docs/GUIA_REVISION_Q1.md): checklist de revision
  tecnica externa.
- [`docs/ESTADO.md`](docs/ESTADO.md): ultimo run documentado y numeros auditados.

## Resultados auditables

- [`outputs/tablas/matriz_robustez_completa.csv`](outputs/tablas/matriz_robustez_completa.csv)
- [`outputs/tablas/resumen_cuatro_grupos.csv`](outputs/tablas/resumen_cuatro_grupos.csv)
- [`outputs/tablas/did_cuatro_grupos.csv`](outputs/tablas/did_cuatro_grupos.csv)
- [`outputs/tablas/did_ajustado_ipm_ruralidad.csv`](outputs/tablas/did_ajustado_ipm_ruralidad.csv)
- [`outputs/pieza_editorial_voto_fusil.md`](outputs/pieza_editorial_voto_fusil.md)

## Reproduccion

El pipeline completo vive en el entorno privado original porque algunos datos
crudos no se publican en este repositorio. En el entorno de trabajo, la ejecucion
se hace desde la raiz de `D:/Dropbox/Reform_UIAF`:

```r
source("subproyectos/voto_fusil/run.R")
```

El run validado debe terminar con:

```text
=== PIPELINE voto_fusil COMPLETADO ===
```

Y pasar:

- `test_01_prerequisitos`;
- `test_02_outputs`;
- `test_03_numeros`.

## Alcance y limites

El diseno es observacional, agregado y municipal. No identifica decisiones
individuales, no prueba causalidad electoral definitiva y no descarta episodios
particulares de coaccion. El resultado debe leerse como asociacion territorial
robusta, no como prueba individual de voto coaccionado.

## Fuente y construccion

Manfred Grautoff · Sistema E4, Registraduria, ACLED, UNODC.
