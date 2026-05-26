# Plan de reparación v5 — Transitly (5ª iteración)

**Fecha:** 2026-05-26
**Autor:** Claude Code (Opus 4.7)
**Plan anterior:** `docs/historico/PLAN_REPARACION_2026_05_26_V4.md` (v4 — algunos fixes no se aplicaron o no resolvieron el bug subyacente)

---

## TL;DR — Estado tras v1–v4

Tras 4 planes, persisten algunos bugs de personalización y aparecen nuevos:

| Error | Análisis | Plan v5 |
|-------|----------|---------|
| Mapa no cambia con tema/estilo | El v4 propuso caché FMTC por estilo. Aplicado solo parcial. Sigue sin reaccionar | A4 |
| Botón "mi ubicación" mal colocado | El v4 propuso `_AnchoredMapControls`. NO se aplicó: el FAB sigue dentro de `TransitMap.overlayWidgets` (línea 480 de map_tab.dart) | A4 |
| No adquiere ubicación correctamente | `userLocationStreamProvider` depende del permiso. Si la primera petición falla silenciosa, el marker no aparece y "paradas cerca" usa centro hardcoded | A4 |
| **Dos "Default" en paletas** (NUEVO) | `prefab_palettes.dart` define 2 paletas con `name: 'Default'`: una dark (id `default`) y otra light (id `default-light`) | A2 |
| **Fondo "opacidad apaga toda la pantalla"** (NUEVO) | `smoke_background.dart:118-122` envuelve TODO con `Opacity(opacity, child: content)` donde `content` incluye `widget.child` (=toda la app). Esto baja la opacidad de la UI entera | A1 |
| Fondos siguen sin funcionar | El v4 propuso `CustomPainter`. No se aplicó. Sigue siendo `Container(color: bgRoot)` plano | A1 |
| Crash al cambiar tamaño de letra | 4ª vez reportado. Sin stack trace porque ningún agente lo reprodujo | A3 |
| **Dislexia "cambia pero no es contra dislexia"** | `transit_typography.dart:8` usa `'Atkinson Hyperlegible'`. PERO esa fuente NO está empaquetada en `assets/fonts/` y `main.dart:39` desactiva runtime fetching. La app cae a fuente del sistema | A5 |
| **Custom palette con nombre + cache** (NUEVO) | Hoy solo hay UNA paleta custom con id fijo `'custom'`. El usuario quiere VARIAS con nombre, guardadas en Hive | A2 |

---

## Cómo usar este plan

Idéntico a v1-v4:
1. Coordinador despacha agentes en paralelo dentro de cada wave con
   `subagent_type: general-purpose`, modo foreground.
2. Cada agente recibe **solo** su brief + el bloque `Contexto global`.
3. Tras Wave 1: integración + `flutter analyze && flutter test`.
4. Tras Wave 2 (si aplica): smoke manual completo.
5. Reglas: tokens del design system, 0 warnings, commits en español,
   NO push/build de release sin permiso del usuario, claves l10n al
   final del JSON.

---

## Contexto global (pegar en todos los briefs)

```
PROYECTO: Transitly (nexto-stop-v2) — App Flutter de transporte público para
Jerez, operador COMUJESA. Demo académica con datos mock.
STACK: Flutter 3.9.2+, Riverpod 2.6.1, go_router 17.2.3, flutter_map 7.0.2,
hive 2.2.3, supabase_flutter 2.8.0, geolocator 13.0.0, home_widget 0.7.0,
google_fonts 6.3.3 (runtime fetching DESACTIVADO en main.dart:39).
DIRECTORIO: C:\Users\k\Desktop\all\clase\nexto-stop-v2
RAMA: master

REGLAS:
- Tokens siempre (TransitColorScheme, TransitTypography, TransitSpacing).
- 0 warnings de flutter analyze.
- Commits en español con prefijo convencional.
- NO ejecutar flutter build apk ni git push salvo si lo pide el usuario.
- l10n: añadir claves al final del JSON. NO regenerar (lo hace el coordinador).

ESTADO TRAS v1-v4 (importante):
- v3 hizo `TransitColorScheme.of()` reactivo via registerResolver+ProviderContainer.
- v4 propuso KeyedSubtree con visualKey en app.dart. CONFIRMA que el visualKey
  está en theme_notifier.dart y que app.dart usa KeyedSubtree antes de tocar
  nada. Si NO está, A1 del plan v4 quedó sin aplicar — investiga y aplícalo
  como prerequisito si tu agente lo necesita para que tus cambios sean visibles.
- Algunas tareas de v4 NO se aplicaron (ej. _AnchoredMapControls). Verifica
  con git log y/o leyendo el archivo antes de duplicar trabajo.
```

---

## Mapa de waves

```
WAVE 1 (5 agentes paralelos, sin solape de archivos)
├── A1  Fondos: opacidad correcta + procedurales con render real
├── A2  Paletas: arreglar "dos Default" + custom palettes con nombre + Hive de varias
├── A3  Crash fontScale (4ª iteración, REPRODUCIR esta vez)
├── A4  Mapa: FAB anclado, ubicación, auto-center, círculo precisión, paradas cerca
└── A5  Fuente dislexia: empaquetar Atkinson Hyperlegible como asset local

WAVE 2 (coordinador, NO agente)
└── gen-l10n + analyze + tests + smoke completo
```

### Tabla de archivos por agente

| Agente | Archivos que modifica | Archivos NUEVOS |
|--------|------------------------|------------------|
| **A1** | `lib/shared/widgets/smoke_background.dart`, `lib/shared/widgets/background_wrapper.dart`, `lib/core/theme/backgrounds/prefab_backgrounds.dart` | `lib/core/theme/backgrounds/procedural_painters.dart` |
| **A2** | `lib/core/theme/palettes/prefab_palettes.dart`, `lib/shared/providers/theme_notifier.dart` (extender con `customPalettes`), `lib/features/appearance/widgets/palette_section.dart` (mostrar custom guardadas + editar), `lib/features/appearance/custom_palette_screen.dart` (añadir TextField nombre), `lib/l10n/*.arb` (claves nuevas al final) | `lib/shared/models/named_custom_palette.dart` |
| **A3** | `lib/features/appearance/widgets/font_section.dart`, `lib/app.dart` (hardening adicional si requiere), archivos del culpable identificado tras reproducir el crash | (ninguno) |
| **A4** | `lib/features/home/tabs/map_tab.dart`, `lib/features/map/widgets/map_controls.dart`, `lib/features/map/layers/user_location_layer.dart`, `lib/features/home/tabs/home_tab.dart` (paradas cerca → usar GPS real), `lib/data/fmtc/fmtc_provider.dart` (si requiere `family` por estilo) | (ninguno) |
| **A5** | `pubspec.yaml` (declarar la fuente local), `lib/core/theme/transit_typography.dart` (verificar), `lib/core/theme/transit_theme.dart` (verificar) | `assets/fonts/atkinson_hyperlegible/AtkinsonHyperlegible-Regular.ttf`, `…-Bold.ttf` (descargar de Google Fonts) |

### Conflictos controlados

- **`lib/l10n/*.arb`**: solo A2 añade claves. Regla: al final del JSON.
- **`lib/shared/providers/theme_notifier.dart`**: A2 lo extiende con
  `customPalettes`. Coordina con A1 (que NO toca el notifier) y A3 (que
  solo verifica clamp existente). Si tras Wave 1 hay merge conflicts,
  el coordinador resuelve.

---

## WAVE 1 — Briefs

### A1 — Fondos: opacidad correcta + procedurales con render real

```text
ROL: Engineer Flutter, especialista en CustomPainter y composición de capas.

CONTEXTO DEL PROYECTO: <pegar bloque "Contexto global">

PROBLEMAS REPORTADOS POR EL USUARIO:
1. "El apartado de apariencia fondo no funciona en nada."
2. "Lo de opacidad de fondo lo que hace es apagar la pantalla al completo."

ROOT CAUSE CONFIRMADO LEYENDO EL CÓDIGO:

PROBLEMA 1 (opacidad apaga toda la pantalla):
- lib/shared/widgets/smoke_background.dart líneas 109-122:
    final content = RepaintBoundary(
      child: SizedBox.expand(
        child: CustomPaint(
          painter: painter,
          child: widget.child ?? const SizedBox.expand(),
        ),
      ),
    );
    if (widget.opacity < 1.0) {
      return Opacity(opacity: widget.opacity, child: content);
    }
- El `content` incluye `widget.child` (= TODA la UI de la app). Cuando
  el usuario baja opacity del fondo, Opacity reduce TODO (fondo + UI).
- Solución: separar el painter del child con un Stack, aplicar Opacity
  SOLO al painter.

PROBLEMA 2 (fondos no funcionan):
- lib/core/theme/backgrounds/prefab_backgrounds.dart líneas 5-13 declara
  5 fondos, incluyendo ProceduralBackground(softGrid) y
  ProceduralBackground(topoLines).
- lib/shared/widgets/background_wrapper.dart línea 44-45:
    ProceduralBackground() => Container(color: palette.scheme.bgRoot, child: child),
- El switch trata los procedurales como Container plano sin pintar el
  patrón. Cualquier opción que no sea Smoke/Gradient/None se ve idéntica.
  Usuario percibe "se queda en humo" porque al cambiar no ve diferencia.

OBJETIVO:
1. Smoke/Image/Procedural backgrounds: Opacity solo sobre el painter,
   no sobre el child.
2. Render real de softGrid y topoLines con CustomPainter.
3. Verificar que Gradient ya funciona (líneas 49-75 de background_wrapper).

ARCHIVOS PERMITIDOS:
- lib/shared/widgets/smoke_background.dart (líneas 95-122)
- lib/shared/widgets/background_wrapper.dart
- lib/core/theme/backgrounds/procedural_painters.dart (NUEVO)
- lib/core/theme/backgrounds/prefab_backgrounds.dart (si necesitas
  ajustes menores)

ARCHIVOS PROHIBIDOS:
- theme_notifier.dart (es de A2)
- font_section.dart, app.dart (es de A3)
- map_tab.dart, map_controls.dart, etc. (es de A4)
- transit_typography.dart, pubspec.yaml (es de A5)

═══════════════════════════════════════════════════════════════════
TAREAS CONCRETAS:
═══════════════════════════════════════════════════════════════════

T1. SmokeBackground: opacity solo al painter
   Reemplaza lib/shared/widgets/smoke_background.dart método `build`
   líneas 95-122 por:

       @override
       Widget build(BuildContext context) {
         final painter = (!_shaderFailed && _shader != null)
             ? _SmokePainter(
                 shader: _shader!,
                 time: _time,
                 color: widget.color,
                 isDark: widget.isDark,
               )
             : _SmokeGradientPainter(
                 color: widget.color,
                 time: _time,
                 isDark: widget.isDark,
               );

         return Stack(
           fit: StackFit.expand,
           children: [
             // Capa de fondo (painter) — solo aquí se aplica opacity
             Opacity(
               opacity: widget.opacity.clamp(0.0, 1.0),
               child: RepaintBoundary(
                 child: SizedBox.expand(
                   child: CustomPaint(painter: painter),
                 ),
               ),
             ),
             // Capa de contenido (sin opacity)
             if (widget.child != null) widget.child!,
           ],
         );
       }

   - El `widget.child` queda en su propia capa del Stack, encima del
     fondo y SIN aplicar opacity.
   - Si opacity=0.0 el fondo desaparece pero la UI queda intacta.

T2. ProceduralPainters
   Crea `lib/core/theme/backgrounds/procedural_painters.dart`:

       import 'dart:math';
       import 'package:flutter/material.dart';

       class SoftGridPainter extends CustomPainter {
         SoftGridPainter({
           required this.lineColor,
           required this.bgColor,
           this.spacing = 32,
         });
         final Color lineColor;
         final Color bgColor;
         final double spacing;

         @override
         void paint(Canvas canvas, Size size) {
           canvas.drawRect(Offset.zero & size, Paint()..color = bgColor);
           final paint = Paint()
             ..color = lineColor
             ..strokeWidth = 0.5
             ..style = PaintingStyle.stroke;
           for (double x = 0; x < size.width; x += spacing) {
             canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
           }
           for (double y = 0; y < size.height; y += spacing) {
             canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
           }
         }

         @override
         bool shouldRepaint(SoftGridPainter old) =>
             old.lineColor != lineColor ||
             old.bgColor != bgColor ||
             old.spacing != spacing;
       }

       class TopoLinesPainter extends CustomPainter {
         TopoLinesPainter({
           required this.lineColor,
           required this.bgColor,
           this.seed = 42,
         });
         final Color lineColor;
         final Color bgColor;
         final int seed;

         @override
         void paint(Canvas canvas, Size size) {
           canvas.drawRect(Offset.zero & size, Paint()..color = bgColor);
           final rng = Random(seed);
           final paint = Paint()
             ..color = lineColor
             ..strokeWidth = 1.0
             ..style = PaintingStyle.stroke;

           for (int i = 0; i < 22; i++) {
             final amplitude = 30.0 + rng.nextDouble() * 60;
             final frequency = 0.005 + rng.nextDouble() * 0.01;
             final phase = rng.nextDouble() * pi * 2;
             final yOffset = (size.height / 22) * i + rng.nextDouble() * 20;
             final path = Path()..moveTo(0, yOffset);
             for (double x = 0; x < size.width; x += 4) {
               path.lineTo(x, yOffset + sin(x * frequency + phase) * amplitude);
             }
             canvas.drawPath(path, paint);
           }
         }

         @override
         bool shouldRepaint(TopoLinesPainter old) =>
             old.lineColor != lineColor ||
             old.bgColor != bgColor ||
             old.seed != seed;
       }

T3. BackgroundWrapper: usar painters reales para procedural
   En lib/shared/widgets/background_wrapper.dart sustituye la rama
   ProceduralBackground() del switch (líneas 44-45) por:

       ProceduralBackground(:final pattern) => Stack(
         fit: StackFit.expand,
         children: [
           Opacity(
             opacity: opacity.clamp(0.0, 1.0),
             child: CustomPaint(
               painter: pattern == ProceduralPattern.softGrid
                   ? SoftGridPainter(
                       lineColor: palette.scheme.accent.withValues(alpha: 0.10),
                       bgColor: palette.scheme.bgRoot,
                     )
                   : TopoLinesPainter(
                       lineColor: palette.scheme.accent.withValues(alpha: 0.08),
                       bgColor: palette.scheme.bgRoot,
                     ),
             ),
           ),
           child,
         ],
       ),

   - Añade los imports necesarios:
       import '../../core/theme/backgrounds/procedural_painters.dart';

T4. ImageBackground: misma fix de opacity (verificar)
   El método _buildImageBg (líneas 77-98) YA usa Stack + Opacity solo
   sobre el Image. Verifica que el child está fuera del Opacity.
   Si no, aplica el mismo patrón.

T5. GradientBackground: verificar
   _buildGradientBg (líneas 49-75) ya tiene Opacity sobre el gradient
   y child en otra capa del Stack. Verifica.

T6. NoneBackground: no aplica opacity
   `NoneBackground() => Container(color: palette.scheme.bgRoot, child: child)`
   está bien — el "none" no tiene capa de fondo, no necesita opacity.

═══════════════════════════════════════════════════════════════════
VERIFICACIÓN:
═══════════════════════════════════════════════════════════════════
- `flutter analyze` 0 warnings.
- Smoke manual:
  1. Apariencia → Fondo → "soft_grid" → ves cuadrícula sutil DETRÁS
     de la UI. La UI no pierde legibilidad.
  2. Selecciona "topo_lines" → ves curvas tipo topográfico.
  3. Selecciona "gradient" → ves gradiente.
  4. Selecciona "smoke" → ves humo animado.
  5. En cualquier opción, baja el slider de opacity al 0% → el fondo
     desaparece pero TODA la UI sigue visible con normalidad. NO se
     apaga la pantalla.

COMMITS:
- fix(theme): opacity de fondo no afecta a la UI
- feat(theme): patrones procedurales reales (softGrid, topoLines)

REPORTE FINAL:
- Snippet del nuevo build() de SmokeBackground.
- Confirmación de cada smoke step.
```

---

### A2 — Paletas: "dos Default" + custom con nombre + cache de varias

```text
ROL: Engineer Flutter senior, especialista en persistencia y design system.

CONTEXTO DEL PROYECTO: <pegar bloque "Contexto global">

DECISIONES TOMADAS CON EL USUARIO:
- Varias paletas custom guardadas con nombre.

PROBLEMAS REPORTADOS POR EL USUARIO:
1. "En apariencias hay dos default."
2. "Al crear paletas quiero que se le pueda poner un nombre y se guarde
   en cache."

ROOT CAUSE CONFIRMADO LEYENDO EL CÓDIGO:

PROBLEMA 1 (dos Default):
- lib/core/theme/palettes/prefab_palettes.dart líneas 283-303:
    const defaultLightPalette = AppPalette(
      id: 'default-light',
      name: 'Default',   ← MISMO NOMBRE
      isDark: false,
      ...
    );
    final prefabPalettes = <AppPalette>[
      const AppPalette(
        id: 'default',
        name: 'Default',  ← MISMO NOMBRE
        isDark: true,
        ...
      ),
      defaultLightPalette,  ← El segundo "Default"
      ...
    ];
- La grid de paletas muestra 7 prefabs: dos con "Default", luego
  Sunrise, Forest, Midnight, Ocean, Mono.

PROBLEMA 2 (custom única):
- theme_notifier.dart línea 50: `static const _customPaletteId = 'custom'`
  → solo UN slot para custom.
- theme_notifier.dart líneas 81-99: getter `palette` mira si paletteId
  == 'custom' y devuelve una AppPalette con _customColors. Solo soporta
  UNA paleta custom.
- No hay TextField de nombre en el wizard de custom palette.

OBJETIVO:
1. Renombrar las dos "Default": "Default oscuro" y "Default claro".
2. Soportar varias paletas custom con nombre, guardadas en Hive.
3. En la pantalla de custom palette, añadir un TextField para el nombre.
4. En PalettesSection, mostrar las custom guardadas junto con los
   prefabs, con un botón para eliminar cada una.

ARCHIVOS PERMITIDOS:
- lib/core/theme/palettes/prefab_palettes.dart
- lib/shared/providers/theme_notifier.dart
- lib/shared/models/named_custom_palette.dart (NUEVO)
- lib/features/appearance/widgets/palette_section.dart
- lib/features/appearance/custom_palette_screen.dart
- lib/l10n/app_es.arb, app_en.arb, app_ar.arb (claves al final del JSON)

ARCHIVOS PROHIBIDOS:
- background_wrapper.dart, smoke_background.dart (es de A1)
- font_section.dart, app.dart (es de A3)
- map_tab.dart, etc. (es de A4)
- transit_typography.dart, pubspec.yaml (es de A5)

═══════════════════════════════════════════════════════════════════
TAREAS CONCRETAS:
═══════════════════════════════════════════════════════════════════

T1. Renombrar los dos "Default"
   En lib/core/theme/palettes/prefab_palettes.dart:
   - Línea 285 (defaultLightPalette): cambia `name: 'Default'` por
     `name: 'Default claro'`.
   - Línea 297 (const AppPalette id 'default'): cambia `name: 'Default'`
     por `name: 'Default oscuro'`.
   - Si el resto de paletas tienen nombres únicos (Sunrise, Forest, …),
     déjalos.

T2. Modelo NamedCustomPalette
   Crea lib/shared/models/named_custom_palette.dart:

       import 'package:flutter/material.dart';

       class NamedCustomPalette {
         NamedCustomPalette({
           required this.id,
           required this.name,
           required this.colors,
         });

         final String id;          // ej. "custom-1730000000000"
         final String name;        // ej. "Mi paleta neón"
         final Map<String, Color> colors;  // primary, secondary, bgRoot, bgSurface, textHi

         factory NamedCustomPalette.fromHive(Map<dynamic, dynamic> raw) {
           final colorsRaw = raw['colors'] as Map<dynamic, dynamic>;
           return NamedCustomPalette(
             id: raw['id'] as String,
             name: raw['name'] as String,
             colors: colorsRaw.map((k, v) =>
                 MapEntry(k.toString(), Color(int.parse(v.toString(), radix: 16)))),
           );
         }

         Map<String, dynamic> toHive() => {
           'id': id,
           'name': name,
           'colors': colors.map((k, v) =>
               MapEntry(k, v.value.toRadixString(16).padLeft(8, '0'))),
         };
       }

T3. ThemeNotifier: lista de custom palettes
   En theme_notifier.dart:
   - Añade campo `List<NamedCustomPalette> _customPalettes = [];`
   - Getter:
       List<NamedCustomPalette> get customPalettes =>
           List.unmodifiable(_customPalettes);
   - Métodos:
       Future<void> saveCustomPalette(NamedCustomPalette p) async {
         final idx = _customPalettes.indexWhere((x) => x.id == p.id);
         if (idx >= 0) {
           _customPalettes[idx] = p;
         } else {
           _customPalettes.add(p);
         }
         notifyListeners();
         await _persistCustomPalettes();
       }

       Future<void> removeCustomPalette(String id) async {
         _customPalettes.removeWhere((x) => x.id == id);
         if (_paletteId == id) _paletteId = 'default';
         notifyListeners();
         await _persistCustomPalettes();
       }
   - Persistencia: Hive box `'custom_palettes'`. Carga en `init()` y
     `_loadGuestPrefs()`.
   - Cuando `_paletteId` empieza por `custom-`, el getter `palette`
     debe localizar la NamedCustomPalette y construir un AppPalette
     con un TransitCustomColors generado desde sus colors.

T4. CustomPaletteScreen con nombre
   En lib/features/appearance/custom_palette_screen.dart:
   - Añade al inicio del formulario un TextField con
     `decoration: InputDecoration(labelText: l10n.appearancePaletteName)`
     y un controller `_nameController`.
   - Al pulsar "Guardar":
       final id = 'custom-${DateTime.now().millisecondsSinceEpoch}';
       final p = NamedCustomPalette(
         id: id,
         name: _nameController.text.trim().isEmpty
             ? 'Mi paleta'
             : _nameController.text.trim(),
         colors: { ... },
       );
       await ref.read(themeNotifierProvider).saveCustomPalette(p);
       ref.read(themeNotifierProvider).paletteId = p.id;
       context.pop();

T5. PalettesSection: mostrar custom + permitir eliminar
   En lib/features/appearance/widgets/palette_section.dart:
   - Tras el GridView de prefabs, si `customPalettes.isNotEmpty`, añade
     una segunda sección "Mis paletas" con el mismo GridView.
   - Cada PaletteCard de una custom tiene un Icon(Icons.close) en
     esquina superior derecha que al pulsarse muestra un diálogo de
     confirmación y llama a `removeCustomPalette(id)`.

T6. Claves l10n (añadir al final del JSON)
   - app_es.arb:
       "appearancePaletteName": "Nombre de la paleta",
       "appearanceCustomPalettesSection": "Mis paletas",
       "appearanceDeletePaletteConfirm": "¿Eliminar esta paleta?",
       "appearancePaletteDefaultDark": "Default oscuro",
       "appearancePaletteDefaultLight": "Default claro",
   - app_en.arb: equivalentes en inglés.
   - app_ar.arb: equivalentes en árabe.

═══════════════════════════════════════════════════════════════════
VERIFICACIÓN:
═══════════════════════════════════════════════════════════════════
- `flutter analyze`
- `flutter test`
- Smoke:
  1. En Apariencia, la sección "Paletas" muestra "Default oscuro" y
     "Default claro" (no dos "Default").
  2. Pulsa "+ Crear paleta personalizada" → wizard con TextField de
     nombre. Escribe "Mi neón", elige colores, guarda.
  3. Vuelve a Apariencia. Ve sección "Mis paletas" con "Mi neón".
  4. Crea otra paleta "Forest oscuro". Aparece junto a Mi neón.
  5. Selecciona Mi neón → toda la app cambia. Selecciona Forest oscuro
     → cambia.
  6. Cierra/abre la app → las paletas persisten en Hive.
  7. Elimina "Mi neón" pulsando la X → desaparece. Si era la activa,
     vuelve a Default oscuro.

COMMITS:
- fix(theme): paletas Default distinguidas (claro vs oscuro)
- feat(theme): varias paletas custom con nombre persistidas en Hive

REPORTE FINAL:
- Confirma T1-T6.
- Lista de claves l10n añadidas.
- Snippets de los métodos clave (saveCustomPalette, removeCustomPalette).
```

---

### A3 — Crash al cambiar tamaño de letra (4ª iteración)

```text
ROL: Engineer Flutter, diagnóstico de runtime crashes.

CONTEXTO DEL PROYECTO: <pegar bloque "Contexto global">

PROBLEMA REPORTADO POR 4ª VEZ:
"Al cambiar el tamaño de letra la app da error y se cierra."

ESTADO ACTUAL DEL CÓDIGO:
- theme_notifier.dart líneas 141-147: clamp(0.85, 1.4) en el setter.
- app.dart líneas 49-65: hardening de NaN + clamp combined (0.8, 2.5).
- font_section.dart líneas 56-66: Slider min 0.85, max 1.4, divisions 11.
- transit_typography.dart aplica fontFamily 'Atkinson Hyperlegible' o
  'DM Sans' en cada TextStyle.

NOTA CRÍTICA SOBRE A5:
A5 va a empaquetar la fuente Atkinson Hyperlegible como asset local
(actualmente NO está en assets/fonts/ y `allowRuntimeFetching = false`).
ES POSIBLE que el crash de fontScale esté correlacionado con la fuente
faltante: cuando textScale sube, Flutter intenta resolver glifos no
disponibles en la fuente fallback y crashea con un AssertionError de
TextPainter. A3 y A5 deben coordinar: A3 reproduce el crash CON y SIN
dyslexia activado; si el crash solo ocurre con dyslexia activado, A5
lo resuelve empaquetando la fuente. Si ocurre incluso sin dyslexia,
el bug está en otro lado.

ARCHIVOS PERMITIDOS:
- lib/features/appearance/widgets/font_section.dart
- lib/app.dart
- Archivos del culpable que identifiques tras reproducir.

ARCHIVOS PROHIBIDOS:
- TODO el resto que A1, A2, A4, A5 tocan.

═══════════════════════════════════════════════════════════════════
TAREAS CONCRETAS:
═══════════════════════════════════════════════════════════════════

T1. Reproducir CON Y SIN dyslexia
   - `flutter run` en debug.
   - Desactiva dyslexia. Slider de 85% a 140% en TODAS las pantallas
     listadas en T3. Anota si crashea, dónde, con qué valor.
   - Activa dyslexia. Repite. Si solo crashea con dyslexia, **deja el
     bug a A5** (empaquetado de fuente) y marca tu trabajo como "no
     reproducido sin dyslexia".

T2. Capturar el stack trace
   - Si crashea, abre el output de `flutter run` y copia el stack
     completo. Si Sentry está activo, mira también el evento allí.
   - Identifica la pantalla actual al crashear.
   - Patrones esperables:
     - RangeError → cálculo numérico fuera de rango con fontScale.
     - RenderFlex overflowed FATAL → Row/Column rígido con Text que
       crece.
     - TextPainter assertion → glifo no encontrado en la fuente.

T3. Pantallas a verificar
   Home, Mapa (sheet de líneas), Buscador, Tarjeta NFC, Perfil,
   Notificaciones, Apariencia (autoreferencial), Ajustes,
   Pantalla de detalle de ruta, Buses cercanos.

T4. Patrones de fix por tipo de crash
   - RenderFlex overflowed → envolver Text con Flexible/Expanded.
   - Row con SizedBox(width: N) + Text → usar FittedBox(BoxFit.scaleDown).
   - Container width fijo + Text → cambiar a BoxConstraints(minWidth, maxWidth).
   - TextPainter assertion / glifo → es problema de fuente (A5).

T5. Hardening adicional (preventivo)
   En app.dart línea 53-54, ya está:
       final systemScale = rawSystem.isFinite && rawSystem > 0 ? rawSystem : 1.0;
       final combined = (systemScale * notifier.fontScale).clamp(0.8, 2.5);
   Verifica que sigue. Si quieres añadir más defensa, envuelve el
   builder con un ErrorBoundary que muestre un mensaje "fontScale
   inválido, reset" + restaure fontScale a 1.0.

═══════════════════════════════════════════════════════════════════
VERIFICACIÓN:
═══════════════════════════════════════════════════════════════════
- En cada una de las 9 pantallas listadas en T3, slider de 85% a 140%
  → ningún crash.

COMMIT(s):
- fix(a11y): crash de fontScale resuelto (<culpable encontrado>)

REPORTE FINAL:
- Stack trace EXACTO del crash original (output literal de `flutter run`).
- Pantalla concreta y widget culpable.
- Fix aplicado (snippet).
- Lista de pantallas verificadas tras fix.
- Si el bug es de fuente, deriva la responsabilidad a A5 y documéntalo.
```

---

### A4 — Mapa: FAB anclado + ubicación + auto-center + paradas cerca

```text
ROL: Engineer Flutter senior, especialista en flutter_map y geolocator.

CONTEXTO DEL PROYECTO: <pegar bloque "Contexto global">

DECISIONES TOMADAS CON EL USUARIO:
- Auto-centrar al abrir el mapa.
- Pedir permiso al primer click del FAB si no hay permiso.
- Mostrar círculo de precisión alrededor del marker de usuario.

PROBLEMAS REPORTADOS POR EL USUARIO:
1. "Siguen ocurriendo los mismos errores con el mapa, no se cambia ni nada."
2. "El botón de ir a mi ubicación está mal colocado."
3. "No adquiere mi ubicación correctamente."
4. "Paradas cerca de mi y mi ubicación no se ven bien marcadas."

ANÁLISIS PREVIO (confirmado leyendo el código):
- map_tab.dart línea 480: el FAB sigue dentro de
  `TransitMap.overlayWidgets` (el plan v4 propuso sacarlo pero no se
  aplicó). El DraggableScrollableSheet con initialChildSize 0.22 tapa
  los 176px inferiores donde está el FAB.
- userLocationStreamProvider espera al permiso y emite stream. Si el
  permiso queda en denied silencioso, el stream nunca emite y el
  marker no aparece.
- home_tab.dart líneas 25-26 todavía pueden tener `_jerezCenter`
  hardcoded para "paradas cerca de mí" (verifica tras los planes
  previos).
- user_location_layer.dart pinta un marker pero no un círculo de
  precisión.

OBJETIVO COMPLETO:
1. Sacar el FAB de `overlayWidgets` y anclarlo encima del sheet.
2. Auto-centrar al abrir el mapa si hay permiso (con timeout 4s).
3. Si no hay permiso, primer click del FAB lo solicita.
4. Marker de usuario con círculo de precisión alrededor.
5. Tile layer reactivo a tema/estilo (resolver caché FMTC por estilo).
6. Home: "paradas cerca de mí" usa la ubicación real, no Jerez.

ARCHIVOS PERMITIDOS:
- lib/features/home/tabs/map_tab.dart
- lib/features/map/widgets/map_controls.dart
- lib/features/map/layers/user_location_layer.dart
- lib/features/home/tabs/home_tab.dart
- lib/data/fmtc/fmtc_provider.dart (si necesitas family por estilo)
- lib/features/map/transit_map.dart (si requieres pasar key extra)

ARCHIVOS PROHIBIDOS:
- background_*, prefab_*, palette_*, font_section.dart, app.dart,
  pubspec.yaml, transit_typography.dart.

═══════════════════════════════════════════════════════════════════
TAREAS CONCRETAS:
═══════════════════════════════════════════════════════════════════

T1. Sacar FAB de overlayWidgets → anclar al sheet
   En map_tab.dart, reestructura el Stack del Scaffold:

       body: Stack(
         children: [
           TransitMap(
             // ya sin MapControls en overlayWidgets
             overlayWidgets: const [],
             ...
           ),
           if (offline) Positioned(...),  // banner offline
           DraggableScrollableSheet(...),
           // FAB ENCIMA del sheet:
           _AnchoredMapControls(
             sheetController: _sheetController,
             isDark: isDark,
             loadingCenter: _loadingCenter,
             onCenter: _centerOnUser,
             onFilter: () => showMapFilterSheet(context, ref),
             onSearch: () => showMapSearchSheet(context, ref, _mapController),
           ),
         ],
       )

   Crea una clase privada `_AnchoredMapControls` dentro de map_tab.dart
   o en map_controls.dart (haz pública la clase si la mueves):

       class _AnchoredMapControls extends StatefulWidget {
         const _AnchoredMapControls({
           required this.sheetController,
           required this.isDark,
           required this.loadingCenter,
           required this.onCenter,
           required this.onFilter,
           required this.onSearch,
         });
         final DraggableScrollableController sheetController;
         final bool isDark;
         final bool loadingCenter;
         final VoidCallback onCenter;
         final VoidCallback onFilter;
         final VoidCallback onSearch;

         @override
         State<_AnchoredMapControls> createState() =>
             _AnchoredMapControlsState();
       }

       class _AnchoredMapControlsState extends State<_AnchoredMapControls> {
         double _sheetFraction = 0.22;

         @override
         void initState() {
           super.initState();
           widget.sheetController.addListener(_onSheet);
         }

         void _onSheet() {
           if (!widget.sheetController.isAttached) return;
           final s = widget.sheetController.size;
           if ((s - _sheetFraction).abs() > 0.005) {
             setState(() => _sheetFraction = s);
           }
         }

         @override
         void dispose() {
           widget.sheetController.removeListener(_onSheet);
           super.dispose();
         }

         @override
         Widget build(BuildContext context) {
           final screenH = MediaQuery.of(context).size.height;
           final sheetTop = screenH * (1 - _sheetFraction);
           final fabBottom = screenH - sheetTop + 12;
           final c = TransitColorScheme.of(widget.isDark);

           return SafeArea(
             child: Stack(
               children: [
                 Positioned(top: 16, left: 16,
                   child: _ControlButton(icon: Icons.search, colors: c,
                       onTap: widget.onSearch)),
                 Positioned(top: 16, right: 16,
                   child: _ControlButton(icon: Icons.tune, colors: c,
                       onTap: widget.onFilter)),
                 AnimatedPositioned(
                   duration: const Duration(milliseconds: 80),
                   right: 16,
                   bottom: fabBottom,
                   child: _ControlButton(
                     icon: Icons.my_location, colors: c,
                     onTap: widget.loadingCenter ? () {} : widget.onCenter,
                     loading: widget.loadingCenter,
                   ),
                 ),
               ],
             ),
           );
         }
       }

   - Si `_ControlButton` es privado en map_controls.dart, duplícalo
     localmente o haz pública la clase.

T2. Auto-centrar al abrir el mapa
   En map_tab.dart, en `initState` o `_tryInitialCenter`:
   - Llama a `_requestLocationPermission()`.
   - Si el permiso se concede, espera al primer fix con timeout 4s:
       try {
         final loc = await ref.read(userLocationStreamProvider.future)
             .timeout(const Duration(seconds: 4));
         if (loc != null && mounted && !_didInitialCenter) {
           _mapController.move(loc, 15);
           _didInitialCenter = true;
         }
       } on TimeoutException { /* mantener centro Jerez */ }
   - Marca _didInitialCenter para no re-centrar si el usuario ya
     interactuó con el mapa.

T3. FAB pide permiso al primer click
   En `_centerOnUser`:
       Future<void> _centerOnUser() async {
         final loc = ref.read(userLocationStreamProvider).valueOrNull;
         if (loc != null) {
           _mapController.move(loc, 16);
           return;
         }
         setState(() => _loadingCenter = true);
         try {
           var permission = await Geolocator.checkPermission();
           if (permission == LocationPermission.denied) {
             permission = await Geolocator.requestPermission();
           }
           if (permission == LocationPermission.deniedForever) {
             if (mounted) {
               ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                 content: Text(AppLocalizations.of(context).mapLocationDeniedForever),
                 action: SnackBarAction(
                   label: AppLocalizations.of(context).actionOpenSettings,
                   onPressed: () => Geolocator.openLocationSettings(),
                 ),
               ));
             }
             return;
           }
           if (permission != LocationPermission.whileInUse &&
               permission != LocationPermission.always) return;
           final pos = await Geolocator.getCurrentPosition().timeout(
               const Duration(seconds: 10));
           if (mounted) {
             _mapController.move(LatLng(pos.latitude, pos.longitude), 16);
           }
         } catch (_) {
           // tolerar
         } finally {
           if (mounted) setState(() => _loadingCenter = false);
         }
       }
   - Añade clave l10n `mapLocationDeniedForever`: "Ubicación denegada.
     Actívala en Ajustes."

T4. Círculo de precisión en UserLocationLayer
   En lib/features/map/layers/user_location_layer.dart:
   - Cambia para recibir un Position completo (con `accuracy`) en lugar
     de solo LatLng. Pasa Position desde el provider.
   - Pinta:
     1. Círculo con radio = accuracy en metros, color
        `c.accent.withValues(alpha: 0.10)` + borde más opaco. Usa
        `CircleLayer` de flutter_map:
          CircleLayer(circles: [
            CircleMarker(
              point: position,
              radius: accuracy,  // en metros, convertir a pixels via flutter_map
              useRadiusInMeter: true,
              color: c.accent.withValues(alpha: 0.10),
              borderColor: c.accent.withValues(alpha: 0.30),
              borderStrokeWidth: 1,
            ),
          ])
     2. Marker central (lo que ya tenías).

   ALTERNATIVA si Position no propaga: amplía `userLocationStreamProvider`
   para emitir un objeto con LatLng y double accuracy.

T5. Paradas cerca de mí: usar GPS real
   En lib/features/home/tabs/home_tab.dart:
   - Localiza la línea donde se usa `_jerezCenter` (probablemente
     líneas 25-26 y 82-83).
   - Reemplázalas por:
       final userLoc = ref.watch(userLocationStreamProvider).valueOrNull;
       final center = userLoc ?? _jerezCenter; // fallback solo si no hay GPS
   - Calcula distancia con `Distance().as(LengthUnit.Meter, center, stop)`.
   - Si no hay GPS y el usuario no ha configurado parada de referencia,
     mantén Jerez como fallback con un mensaje "activa GPS para ver
     paradas reales cerca de ti".

T6. Tile layer reactivo a estilo y tema
   En map_tab.dart, donde se construye TransitMap:
   - Asegura que `key:` incluye tanto `isDark` como `mapStyle`:
       key: ValueKey('${isDark ? "d" : "l"}-$mapStyle')
   - Pasa `mapStyle: mapStyle` (debe estar ya tras v3).
   - Si la caché FMTC sirve tiles oscuras al pedir claras, separa los
     stores en fmtc_provider.dart:
       final fmtcTileProviderProvider = Provider.family<TileProvider, String>(
         (ref, style) => FMTCStore('jerez-$style').getTileProvider(),
       );
   - En map_tab.dart:
       final fmtcTp = ref.watch(fmtcTileProviderProvider(mapStyle));
   - Si la API de FMTC v10 no permite family fácilmente, alternativa
     pragmática: usar NetworkTileProvider sin caché cuando el usuario
     está online y FMTC solo cuando offline. Documenta tu decisión.

═══════════════════════════════════════════════════════════════════
VERIFICACIÓN:
═══════════════════════════════════════════════════════════════════
- `flutter analyze`
- Smoke manual:
  1. Abre el mapa con GPS encendido y permiso concedido → el mapa
     centra en mi ubicación en <4s. Marker visible con círculo de
     precisión alrededor.
  2. Expande el sheet de líneas al máximo → el FAB de ubicación queda
     visible encima del sheet, no tapado.
  3. Desinstala/reinstala la app, denegar permiso al primer prompt →
     volver a entrar al mapa, pulsar FAB → re-pide permiso. Si lo
     concedes, se centra. Si lo deniegas para siempre, SnackBar con
     "Abrir Ajustes".
  4. Cambia tema oscuro→claro → tiles del mapa cambian.
  5. Cambia mapStyle a "dark" → tiles cambian al estilo dark.
  6. En home, "paradas cerca de mí" muestra paradas cerca de mi GPS
     (no de Jerez).

COMMITS:
- fix(map): FAB anclado al sheet, ya no es tapado
- feat(map): auto-center, círculo de precisión, permiso al click
- fix(map): caché FMTC por estilo (tiles reactivos)
- fix(home): paradas cerca de mí usa GPS real

REPORTE FINAL:
- Confirma T1-T6.
- Resultado de los 6 pasos del smoke.
- Si tuviste que hacer cambios en transit_map.dart, justifícalo.
```

---

### A5 — Fuente dislexia: empaquetar Atkinson Hyperlegible

```text
ROL: Engineer Flutter, assets y typography.

CONTEXTO DEL PROYECTO: <pegar bloque "Contexto global">

DECISIÓN TOMADA CON EL USUARIO:
Empaquetar Atkinson Hyperlegible como asset local.

PROBLEMA REPORTADO:
"Lo de fuente para dislexia sí cambia la fuente pero no una contra la
dislexia."

ROOT CAUSE CONFIRMADO:
- main.dart línea 39: `GoogleFonts.config.allowRuntimeFetching = false;`
- transit_typography.dart línea 8:
    String get _bodyFontFamily =>
        isDyslexiaEnabled() ? 'Atkinson Hyperlegible' : 'DM Sans';
- La fuente "Atkinson Hyperlegible" NO está en `assets/fonts/` y
  GoogleFonts no la descarga (runtime fetching desactivado). Flutter
  resuelve a la fuente del sistema (Roboto, San Francisco, etc.). El
  usuario percibe "cambia pero no es para dislexia".

OBJETIVO:
1. Descargar las variantes Regular y Bold de Atkinson Hyperlegible
   (licencia OFL — libre uso).
2. Empaquetarlas en `assets/fonts/atkinson_hyperlegible/`.
3. Declarar en `pubspec.yaml` la familia.
4. Verificar que TransitTypography las usa correctamente.

ARCHIVOS PERMITIDOS:
- pubspec.yaml (sección fonts)
- assets/fonts/atkinson_hyperlegible/ (carpeta NUEVA con .ttf)
- lib/core/theme/transit_typography.dart (verificar)
- lib/core/theme/transit_theme.dart (línea 27-29: cambia el
  GoogleFonts.atkinsonHyperlegibleTextTheme a baseTextTheme.apply con
  fontFamily 'Atkinson Hyperlegible')

ARCHIVOS PROHIBIDOS:
- TODO el resto que A1-A4 tocan.

═══════════════════════════════════════════════════════════════════
TAREAS CONCRETAS:
═══════════════════════════════════════════════════════════════════

T1. Descargar las .ttf
   Atkinson Hyperlegible viene del Braille Institute, licencia SIL OFL.
   Variantes mínimas:
   - AtkinsonHyperlegible-Regular.ttf
   - AtkinsonHyperlegible-Bold.ttf

   Fuentes (en orden de preferencia):
   - https://fonts.google.com/specimen/Atkinson+Hyperlegible (download family)
   - https://www.brailleinstitute.org/freefont
   - O extrae los .ttf de las cachés locales si Flutter las dejó:
       ~/.flutter/cache/google_fonts/

   Coloca los archivos en:
       assets/fonts/atkinson_hyperlegible/AtkinsonHyperlegible-Regular.ttf
       assets/fonts/atkinson_hyperlegible/AtkinsonHyperlegible-Bold.ttf

   Si no tienes acceso a internet desde la sandbox y no encuentras
   cachés locales, abre un SnackBar/diálogo en pantalla Apariencia
   diciendo "Esta versión empaqueta solo DM Sans. Para fuente dislexia,
   espera próxima release." y deja la implementación lista para cuando
   el archivo se añada. Documenta esto explícitamente en tu reporte.

T2. Declarar en pubspec.yaml
   En la sección `fonts:` (línea 85+):
       fonts:
         - family: DM Sans
           fonts:
             - asset: assets/fonts/dm_sans/DMSans-Variable.ttf
         - family: IBM Plex Mono
           ...
         - family: Atkinson Hyperlegible
           fonts:
             - asset: assets/fonts/atkinson_hyperlegible/AtkinsonHyperlegible-Regular.ttf
               weight: 400
             - asset: assets/fonts/atkinson_hyperlegible/AtkinsonHyperlegible-Bold.ttf
               weight: 700

T3. Registrar la carpeta como asset
   En la sección `assets:` (línea 88+), añadir:
       - assets/fonts/atkinson_hyperlegible/
   (Solo si Flutter no la encuentra automáticamente desde `fonts:`. En
   la mayoría de los casos no hace falta porque las fuentes se declaran
   en `fonts:`).

T4. Verificar transit_typography y transit_theme
   En lib/core/theme/transit_typography.dart línea 8 ya devuelve
   `'Atkinson Hyperlegible'` cuando dyslexia activado. Tras T2, esa
   familia existe.

   En lib/core/theme/transit_theme.dart líneas 27-29:
   - Si usa `GoogleFonts.atkinsonHyperlegibleTextTheme(baseTextTheme)`,
     cámbialo a:
       final textTheme = dyslexiaFontEnabled
           ? baseTextTheme.apply(fontFamily: 'Atkinson Hyperlegible')
           : baseTextTheme.apply(fontFamily: 'DM Sans');
     porque ahora la fuente es local; no hace falta GoogleFonts.

T5. Pub get
   `flutter pub get` debe pasar.
   Build debug `flutter build apk --debug` debe pasar sin errores de
   "asset not found".

═══════════════════════════════════════════════════════════════════
VERIFICACIÓN:
═══════════════════════════════════════════════════════════════════
- `flutter analyze` 0 warnings.
- `flutter build apk --debug` pasa.
- Instala APK debug en dispositivo:
  1. Abre la app, va a Apariencia.
  2. Desactivado dyslexia → tipografía DM Sans normal.
  3. Activa dyslexia → tipografía cambia a Atkinson Hyperlegible
     (caracteres distintos: 'a' tiene una forma más abierta, 'l' tiene
     terminación distintiva, 'I' con serifs, '1' diferente del 'l',
     'rn' diferente del 'm'). Confirma visualmente comparando con
     muestras de la fuente online.
- Sin acceso a internet (modo avión), la fuente debe seguir
  funcionando porque es asset local.

COMMIT:
feat(a11y): empaquetar Atkinson Hyperlegible como asset local

REPORTE FINAL:
- Tamaño total de las dos .ttf añadidas (en KB).
- Confirmación visual de los cambios tipográficos.
- Si no pudiste obtener los .ttf, plan documentado para añadirlos en
  una iteración futura.
```

---

## WAVE 2 — Coordinador (NO agente)

1. `flutter gen-l10n` si A2 añadió claves nuevas.
2. `flutter analyze` → 0 warnings.
3. `flutter test` → verde.
4. **Smoke completo, en este orden:**
   - **A1 — Fondos**:
     - Apariencia → Fondo → "soft_grid" → ves cuadrícula sutil. UI
       sigue legible al 100%.
     - Selecciona "topo_lines" → curvas tipo topográfico.
     - Selecciona "gradient" → gradiente.
     - Selecciona "smoke" → humo animado.
     - Baja slider opacity al 0% en cualquier modo → fondo desaparece,
       UI sigue intacta SIN apagarse.
   - **A2 — Paletas**:
     - En grid de paletas, hay "Default oscuro" y "Default claro" (no
       dos "Default").
     - Pulsa "+ Crear paleta personalizada" → wizard tiene TextField
       de nombre.
     - Crea "Mi neón" → aparece en sección "Mis paletas".
     - Crea "Custom B" → ambas aparecen, ambas con cierre (X) para
       eliminar.
     - Selecciona Mi neón → toda la app cambia.
     - Cierra/abre app → las paletas persisten.
   - **A3 — fontScale**:
     - Slider 85% a 140% en cada pantalla → ningún crash.
   - **A4 — Mapa**:
     - Abre el mapa → centra en mi ubicación en 4s.
     - Marker tiene círculo de precisión.
     - Expande el sheet → FAB encima del sheet, visible.
     - Cambia tema/estilo → tiles cambian.
     - Home "paradas cerca" usa mi GPS real.
   - **A5 — Dislexia**:
     - Activa dyslexia → tipografía cambia a Atkinson Hyperlegible
       (verifica visualmente caracteres distintivos).

5. **Build APK release opcional** si el usuario lo pide.

---

## Errores → agentes (cobertura)

| Error reportado | Agente |
|------------------|--------|
| Mapa no cambia + FAB mal colocado + no adquiere ubicación + paradas cerca mal | A4 |
| Dos "Default" en apariencias | A2 |
| Apariencia fondo no funciona | A1 |
| Opacidad de fondo apaga toda la pantalla | A1 |
| Crash al cambiar tamaño de letra | A3 (+A5 si fuente) |
| Dislexia "cambia pero no es contra dislexia" | A5 |
| Crear paletas con nombre + cache | A2 |

---

## Riesgos

- **A3 (crash fontScale, 4ª iteración)**: si el agente no puede
  reproducir, debe documentarlo y derivar a A5 (correlación con
  fuente faltante). El coordinador decide si abre un plan v6 dedicado
  exclusivamente a este crash.
- **A5 (Atkinson Hyperlegible)**: requiere descargar .ttf reales. Si
  el sandbox del agente no permite internet, queda como tarea con
  instrucciones documentadas.
- **A4 (caché FMTC family)**: el cambio puede multiplicar uso de disco
  (un store por estilo). Si es un problema, alternativa: bypassear
  FMTC para tiles online.
- **A2 (paletas custom)**: requiere migración del campo `customColors`
  legacy de Hive al nuevo modelo `customPalettes`. Si encuentra el
  campo viejo, lo migra a una primera paleta con nombre "Mi paleta".
- **El KeyedSubtree de v4** (si está aplicado) reconstruye TODO el
  árbol al cambiar `visualKey`. Hay que asegurar que `visualKey` ahora
  incluye también el campo nuevo `_customPalettes.length` u otro hash
  para que añadir/eliminar paletas dispare rebuild. A2 debe ajustarlo.
