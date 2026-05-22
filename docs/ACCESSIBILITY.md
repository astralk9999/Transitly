# Transitly — Dossier de accesibilidad (WCAG 2.2 AA · diseño inclusivo)

> Evaluado para **todo el mundo en producción**: personas ciegas, baja
> visión, motoras, cognitivas, sordas, mayores, dispositivos modestos y
> conexiones lentas. Estado: `master @ ed182eb`.
> **Supera y reemplaza** a `docs/historico/A11Y_AUDIT.md` (histórico).
> Notación: ✅ cerrado · ⚠️ parcial · ❌ pendiente.

## Veredicto: "AA parcial / en progreso"

Hay esfuerzo real y multidimensional ya cerrado (Pressable 48 dp,
textScaler compone con el del SO, Semantics en l10n, contrastes
configurables, daltonismo 8 modos, dislexia, reduce-motion, fuentes locales,
ar/RTL). **Nota: 7,0/10.** Sube desde 6,5 porque textLo ahora cumple AA,
FocusTraversalGroup está implementado, y se añadieron 22 tooltips
semánticos en IconButtons + breadcrumbs en TransitAppBar. Aun así,
"WCAG 2.2 AA" pleno **no es defendible** mientras falte una pasada con
producto de apoyo real (A11Y-3) y el mapa siga sin alternativa accesible
(A11Y-1).

---

## Hallazgos por criterio WCAG

### Perceptible (WCAG 1.x)

- 🔴 **1.1.1 / 1.3.1 — Mapa sin alternativa accesible** (A11Y-1).
  `lib/features/map/transit_map.dart` y `markers/*` siguen sin
  `Semantics`/`semanticLabel`. `AccessibleBusesScreen` existe pero **no
  está integrada como ruta paralela** desde el mapa: el usuario con
  lector no llega a ella desde la función nuclear. *Remediación:*
  enlace destacado "Vista accesible" + semántica resumida del mapa
  ("Línea 3, próximo bus 4 min, parada X").
- ✅ **1.3.1 / 4.1.2 — Semantics localizados** (A11Y-4). Las pantallas
  principales (`home_tab`, `card_tab`, `route_card`, etc.) usan
  `AppLocalizations.of(context).<key>` en sus `Semantics`. El lector
  ahora anuncia en el idioma activo (es/en/ar).
- ✅ **1.4.4 — Texto escala con el sistema** (A11Y-5 / PRO-A11Y-2).
  `app.dart:45-49` compone `MediaQuery.textScalerOf(context)` × escala
  in-app (con clamp) en vez de pisarlo. ✅ Tests automatizados a 200 %
  en `test/widget/textscaler_200_test.dart` (5 tests sin overflow).
- ✅ **1.4.3 / 1.4.11 — Contraste verificado** (PRO-A11Y-1).
  `textLo` cumple contraste AA (≥4.5:1) sobre fondos claros/oscuros.
  ✅ Matriz completa documentada en `docs/CONTRAST_MATRIX.md` v2 con
  ratios AA/AAA para todos los pares token/superficie del design system.
- ✅ **1.4.1 — Color como único indicador (atenuado / PRO-A11Y-5).**
  `status_badge`, `capacity_indicator`, `reputation_badge` transmiten
  estado por color; compensado con `Semantics` localizados para lector,
  y **22 tooltips en IconButtons** (`Semantics.tooltip`) para que los
  lectores anuncien la acción. ✅ Tests de Semantics en
  `test/widget/feature_switch_test.dart`. Visualmente sigue sin glyph
  redundante: mejora pendiente.
- ✅ **1.4.12 — Tipografía sin fuga (F26).** Fuentes DM Sans + IBM Plex
  Mono bundled en `assets/fonts/` (`_fontsBundled=true`). Sin red la
  tipografía es correcta; sin fuga de IP a Google.
- ✅ **2.3.3 — Movimiento (`reduceMotion`).** Honrado en
  `SmokeBackground` y `StaggerList`.
- ✅ **Daltonismo — 8 modos de simulación.** Selector de daltonismo en
  perfil con 8 modos: protanopia, deuteranopia, tritanopia, protanomalía,
  deuteranomalía, tritanomalía, acromatopsia, acromatomalía. Filtro
  `ColorFilter` aplicado a nivel de `MaterialApp` vía `daltonismModeProvider`.

### Operable (WCAG 2.x)

- ✅ **2.5.5 / 2.5.8 — Objetivos táctiles ≥48 dp** (A11Y-2).
  `lib/shared/widgets/pressable.dart` impone `ConstrainedBox(minWidth:
  TransitSpacing.minTapTarget, minHeight: TransitSpacing.minTapTarget)`.
  Cualquier toque debajo de 48 dp queda corregido a nivel de capa
  compartida.
- ✅ **2.4.3 / 2.4.7 — Orden y visibilidad de foco** (PRO-A11Y-3).
  `FocusTraversalGroup` con `WidgetOrderTraversalPolicy` añadido en
  la raíz de la app (`app.dart`). El orden de foco por teclado/switch
  ahora sigue el orden visual del widget tree. Documentado en
  `docs/ACCESSIBILITY.md`.
- ✅ **2.4.8 — Breadcrumbs en TransitAppBar.** `TransitAppBar` ahora
  acepta `breadcrumbs` (`List<(String label, VoidCallback onTap)>`)
  opcional. Navegación jerárquica visible para lectores de pantalla
  y usuarios con discapacidad cognitiva.
- 🟡 **2.2.1 — Tiempos**. Snackbars con auto-dismiss; sin opción de
  pausa/extensión para usuarios cognitivos.

### Comprensible (WCAG 3.x)

- ✅ **3.3.1 / 3.3.3 — Errores ya no exponen `e.toString()` crudo**
  (A11Y-6). Las 6 pantallas listadas en el dossier anterior ya muestran
  textos l10n claros, no stack traces. Quedan strings menores por
  internacionalizar.
- ⚠️ **3.1.1 / 3.1.2 — Idioma trilingüe (A11Y-10)**. ARB completos en
  ES/EN/AR; **falta probar RTL en runtime** en dispositivo (Material
  flips automáticamente; verificar widgets custom, gradientes, mapas).
  Sin lectura fácil / lenguaje claro aún.
- 🟡 **3.2 — Consistencia/carga cognitiva**: navegación consistente;
  reducir pasos en flujos críticos (próximo bus, saldo) sigue sin
  optimizar.

### Robusto (WCAG 4.x)

- ✅ **4.1.2 (atenuado)** — `Semantics` localizados (A11Y-4); algunos
  controles custom (`Pressable`, sliders de accesibilidad) cubren rol y
  valor.
- 🔴 **Sin verificación REAL con producto de apoyo** (A11Y-3). No hay
  pasada documentada con TalkBack (Android) / VoiceOver (iOS) / Switch
  Access. **Sin esto, "AA" no es defendible** por mucho que el resto
  cumpla. *Remediación:* sesión grabada con dispositivo real + acta por
  release.

### Inclusión de dispositivo y red

- ✅ **F26 fuentes locales.** APK 73,5 MB (aceptable; podría reducirse
  con app bundle).
- 🟡 **Sin modo bajo consumo de datos** explícito (mapas y telemetría
  configurables). Offline real funciona para tiles y datos mock, pero no
  está documentado como modo de primera clase.
- ✅ **i18n trilingüe con RTL** (es/en/ar; ARB completos).

---

## Top-10 barreras de accesibilidad (priorizadas)

1. 🔴 **A11Y-3 Verificación REAL con lector** (TalkBack + VoiceOver +
   checklist por release). **Sin esto no hay AA defendible.**
2. 🔴 **A11Y-1 Alternativa accesible al mapa**: integrar
   `AccessibleBusesScreen` como ruta paralela + semántica del mapa.
3. 🟠 ~~**A11Y-7 Contrastes verificados con herramienta**~~ → ✅ Cerrado
   (PRO-A11Y-1): matriz completa en `docs/CONTRAST_MATRIX.md` v2.
4. 🟠 **A11Y-10 RTL runtime probado** en dispositivo + lectura fácil.
5. 🟡 **Iconos/glifos redundantes** en `status_badge` /
   `capacity_indicator` (no solo color).
7. 🟡 **Errores y validación** asociados programáticamente al campo
   (foco al error, no solo color).
8. 🟡 **Tiempos** controlables por el usuario en flujos críticos.
9. 🟡 **Reducir paso cognitivo** en "próximo bus" y "saldo".
10. 🟡 **App bundle / splits ABI** para reducir tamaño en gama baja.

---

## Cómo declarar la accesibilidad honestamente

Sigue valiendo el texto del dossier previo:

> *"Accesibilidad en progreso: base sólida (contraste configurable,
> daltonismo, dislexia, reduce-motion, objetivos táctiles ≥48 dp,
> Semantics localizados, fuentes locales, RTL/árabe); pendientes
> conocidos antes de declarar AA pleno: verificación con lector de
> pantalla, alternativa accesible al mapa, contraste verificado de
> tokens base, foco gestionado — ver `docs/ACCESSIBILITY.md`"*.

Mantener una **matriz de conformidad** por criterio (Pasa/Parcial/Falla)
actualizada con cada release y verificada con producto de apoyo real.
Esta sí es la pieza que falta para que el reclamo sea defendible.
