# Estado del subproyecto voto_fusil

Fecha de inicio: 2026-06-23
Estado: esqueleto creado
Proximo paso: completar 01_datos.R

## Registro de avance
- 2026-06-23 Esqueleto creado. Insumos verificados y documentados.
- 2026-06-23: Verificado que archivos ACLED largos (colombia_hrp_*) cubren hasta junio 2026. Archivos cortos (acled_*) solo llegan a enero 2026. Usar largos para el analisis.

## Decisión metodológica: ventana temporal del índice de exposición armada

Fecha: 2026-06-23
Responsable: Manfred Grautoff

### Ventana seleccionada
Noviembre 2025 – mayo 2026 (7 meses)

### Justificación política
Las elecciones internas del Pacto Histórico en noviembre 2025 definen
a Iván Cepeda como candidato oficial. Ese evento activa el ciclo electoral
relevante: los grupos armados conocen al candidato y pueden posicionarse
territorialmente antes de la campaña formal.

### Sub-períodos analíticos
- Nov–dic 2025: post-definición del candidato
- Ene–mar 2026: pre-campaña formal (incluye escalada del Catatumbo)
- Abr–may 2026: campaña activa hasta primera vuelta (25 mayo)

### Referencia contextual
El artículo de RedCheq (18 jun 2026) documenta que la narrativa del
'voto fusil' circuló con datos incompletos y mapa desactualizado de 2015.
Este análisis usa corte congelado al 99.7% de mesas y metodología
explícita para responder ese debate con rigor.

### Límite epistemológico declarado
La ventana no permite inferencia causal. El diseño es descriptivo:
mide asociación entre exposición armada pre-electoral y comportamiento
electoral, controlando por historia electoral 2018-2022.

## Registro de avance (continuación)
- 2026-06-23: 02_analisis.R corrido exitosamente.
  185 municipios alta exposicion (>p75).
  Tibú encabeza con 124 eventos — valida ventana temporal (Catatumbo ene2026).
  Validacion externa: RedCheq (18jun2026) menciona Tibú explicitamente.
  Verificado: 0 NAs nuevos introducidos por los joins (idx_exposicion y
  columnas de segunda vuelta 2026 sin NA; los unicos NA preexistentes son
  2 filas en columnas p22_* del panel historico, anteriores a este analisis.

## Numeros auditados -- generado por 03_guardar_estado.R

Fecha de generacion: 2026-06-23 18:03:36
Commit: a62246e

Panel final: 1122 filas, 119 columnas

Distribucion alta_exposicion:
  - FALSE: 937 municipios (83.5%)
  - TRUE: 185 municipios (16.5%)

Top 5 municipios por idx_exposicion:
  1. Tibú (Norte de Santander) - idx_exposicion: 124
  2. Jamundí (Valle del Cauca) - idx_exposicion: 49
  3. San José de Cúcuta (Norte de Santander) - idx_exposicion: 44
  4. Bogotá, D.C. (Cundinamarca) - idx_exposicion: 44
  5. Santiago de Cali (Valle del Cauca) - idx_exposicion: 39

Rango temporal ACLED usado: Noviembre 2025 - mayo 2026 (ver decision metodologica en este mismo ESTADO.md)
