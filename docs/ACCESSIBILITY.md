# Transitly — Dossier de accesibilidad (WCAG 2.2 AA · diseño inclusivo)

> Evaluado para **todo el mundo en producción**: personas ciegas, baja visión,
> motoras, cognitivas, sordas, mayores, dispositivos modestos y conexiones
> lentas. Estado: `master @ 6f26725`. **Supera y reemplaza** a
> `docs/A11Y_AUDIT.md` (que pasa a histórico).
> `[R]` = verificado en pasadas previas de esta revisión · `[?]` = a confirmar
> con auditoría asistida (TalkBack/VoiceOver + analizador de contraste).

## Veredicto: el reclamo "WCAG 2.1 AA parcial" está **sobre-reclamado**

Hay esfuerzo real y multidimensional (alto contraste, daltonismo, dislexia,
reduce-motion, validador de contraste de paletas) — eso es **encomiable**.
Pero para producción inclusiva la nota honesta es **5,5/10** y el nivel real
es **"A con trabajo hacia AA", no "AA"**: sin un solo paso verificado con
lector de pantalla, el mapa (función central) es inaccesible, y hay barreras
estructurales (texto, idioma del lector, objetivos táctiles) que excluyen a
usuarios reales hoy.

---

## Hallazgos por criterio WCAG

### Perceptible

- 🔴 **1.1.1 / 1.3.1 — Mapa sin alternativa accesible.** `[R]`
  `lib/features/map/transit_map.dart` y `markers/*` no tienen `Semantics`
  ni `semanticLabel`. La función nuclear "ver buses/rutas" es invisible para
  lectores de pantalla. `AccessibleBusesScreen` existe pero **no es
  equivalente** (no cubre rutas/mapa interactivo). *Remediación:* capa
  semántica con resúmenes ("Línea 3, próximo bus 4 min, parada X") + vista
  lista equivalente y enlazada como alternativa primaria.
- 🟠 **1.3.1 / 4.1.2 — `Semantics` en español hardcodeado.** `[R]` con la app
  en inglés el lector anuncia en español: `home_tab.dart:101,241,347`,
  `card_tab.dart:269`, `accessibility_settings_screen.dart:136`,
  `stop_detail_screen.dart:294`, `capacity_indicator.dart:31`,
  `reputation_badge.dart:86`, `route_card.dart:53` ("Linea" sin tilde).
  *Remediación:* todos los labels semánticos vía l10n.
- 🟠 **1.4.4 — El texto no escala con el sistema.** `[R]` `app.dart:45-49`
  reemplaza `MediaQuery.textScaler` del SO por la escala in-app; un usuario
  con "texto grande" del sistema lo pierde. *Remediación:* componer
  (SO × ajuste app) con clamp; verificar 200 % sin overflow.
- 🟡 **1.4.3 / 1.4.11 — Contraste sin verificar.** `[?]` hay validador para
  paletas custom, pero los **tokens base** (`transit_colors.dart`) no tienen
  ratios verificados con herramienta; texto secundario/`textLo` y estados
  sobre superficies translúcidas (`GlassCard`) son sospechosos.
- 🟡 **1.4.1 — Color como único indicador.** `status_badge`,
  `capacity_indicator` `[R]` transmiten estado por color; añadir
  icono/forma/texto redundante.
- 🟠 **1.4.12 / texto por red.** `[R]` `_fontsBundled=false`
  (`main.dart:22`) → fuentes desde Google en runtime: sin red la tipografía
  degrada (afecta legibilidad) y hay fuga de IP (privacidad). Empaquetar
  fuentes (F26).

### Operable

- 🔴 **2.5.5 / 2.5.8 — Objetivos táctiles < 48 dp.** `[R]`
  `lib/shared/widgets/pressable.dart` (GestureDetector `opaque`) **no impone
  mínimo**; chips, iconos y switches pequeños quedan por debajo. Excluye a
  usuarios con dificultad motora y a mayores. *Remediación:* `ConstrainedBox`
  con `kMinInteractiveDimension` en `Pressable`.
- 🟠 **2.4.3 / 2.4.7 — Orden y visibilidad de foco.** `[?]` sin
  `FocusTraversalGroup` ni gestión explícita de foco; foco visible no
  garantizado en navegación por teclado/switch.
- 🟡 **2.2.1 — Tiempos.** Snackbars/auto-dismiss y posibles timeouts sin
  control del usuario `[?]`.
- 🟢 **2.3.3 — Movimiento.** `reduceMotion` honrado en `SmokeBackground` y
  `StaggerList` `[R]` (bien); verificar que cubre TODAS las transiciones.

### Comprensible

- 🟠 **3.3.1 / 3.3.3 — Errores no accesibles ni claros.** `[R]` pantallas
  exponen `e.toString()` crudo (`route_feedback_sheet`, `report_incident_sheet`,
  `*_screen` de operador) → mensajes técnicos, no sugerencias; no asociados
  programáticamente al campo. *Remediación:* mensajes l10n claros + `Semantics`
  de error + foco al error.
- 🟠 **3.1.1 / 3.1.2 — Idioma.** Solo es/en; **sin RTL** (árabe — colectivo
  relevante en transporte público español), sin lenguaje claro/lectura fácil;
  editor de conductor solo `es`. Localización de números/fechas/moneda a
  revisar.
- 🟡 **3.2 — Consistencia/carga cognitiva** `[?]`: revisar consistencia de
  navegación y reducir pasos en flujos críticos (comprar/consultar saldo,
  próximo bus).

### Robusto

- 🟠 **4.1.2 — Nombre/rol/valor.** Controles custom (`Pressable`,
  toggles, sliders de accesibilidad) sin `Semantics` completos
  (rol/estado) en varios puntos `[?]`.
- 🔴 **Sin verificación real con producto de apoyo.** `[R]` no hay paso
  documentado con TalkBack/VoiceOver/Switch Access; sin esto, "AA" no es
  defendible. *Remediación:* checklist de pruebas con lector + grabaciones.

### Inclusión de dispositivo y red (más allá de WCAG)

- 🟠 **APK 73 MB + fuentes por red.** `[R]/[V]` excluye gama baja y datos
  limitados; primer arranque sin Wi-Fi degrada tipografía. *Remediación:*
  app bundle + splits ABI, fuentes locales, modo bajo consumo de datos.
- 🟡 **Offline real limitado:** caché de tiles y datos mock, pero la
  experiencia sin red no está diseñada/anunciada como modo de primera clase.

---

## Top-10 barreras de accesibilidad (priorizadas)

1. 🔴 Mapa inaccesible → alternativa lista equivalente + semántica del mapa.
2. 🔴 `Pressable` sin 48 dp (motor/mayores).
3. 🔴 Verificación real con lector de pantalla (sin ella no hay "AA").
4. 🟠 `Semantics` ES hardcodeado → l10n.
5. 🟠 `textScaler` que ignora el SO.
6. 🟠 Errores accesibles y claros (no `e.toString()`).
7. 🟠 Contraste de tokens base verificado con herramienta.
8. 🟠 Fuentes locales (F26) + tamaño APK.
9. 🟠 Foco: orden, visibilidad, traversal por teclado/switch.
10. 🟡 i18n inclusivo: RTL + lectura fácil + localización completa.

---

## Cómo declarar la accesibilidad honestamente

- **No** afirmar "WCAG 2.1 AA". Usar: *"Accesibilidad en progreso: base sólida
  (contraste configurable, daltonismo, dislexia, reduce-motion); pendientes
  conocidos: lector de pantalla, mapa, objetivos táctiles, escalado del SO
  — ver `docs/ACCESSIBILITY.md`"*.
- Mantener una **matriz de conformidad** por criterio (Pasa/Parcial/Falla)
  actualizada con cada release y verificada con producto de apoyo real.

> Ítems incorporados al plan como bloque **A11Y** en
> `docs/PLAN_ACCION_REMEDIACION.md`.
