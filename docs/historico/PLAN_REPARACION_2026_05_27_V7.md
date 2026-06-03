# Plan de reparación v7 — Transitly (errores persistentes + features)

**Fecha:** 2026-05-27
**Autor:** Claude Code (Opus 4.7)
**Plan anterior:** `PLAN_REPARACION_2026_05_27_V6.md`

---

## TL;DR — Diagnóstico de los errores reportados

| # | Error reportado | Causa raíz encontrada | Agente |
|---|------------------|------------------------|--------|
| 1 | Mapa no cambia de color (oscuro/claro/personalización) | `MapConfig.tileUrl` cae a Carto cuando `MAPTILER_API_KEY` está vacía (90% de los casos). Carto solo tiene dark/light hardcoded, todos los `mapStyle` colapsan a 2 URLs reales. Confirmado: la key NO está en `launch.json` ni `dart_defines.json`. | A2 |
| 2 | Las dos "Default" se ven iguales | `prefab_palettes.dart:283-303`: ambas paletas `'default'` y `'default-light'` tienen los MISMOS `lightScheme: TransitLightColors()` y `darkScheme: TransitDarkColors()`. Como `buildTheme(brightness)` elige por `brightness`, ignora cuál de las dos paletas está activa → producen idéntico `ThemeData`. | A1 |
| 3 | Fondo no cambia (tipos ni opacidad) | El visualKey YA incluye `_backgroundId` y `_backgroundOpacity`, así que el rebuild debería disparar. Hipótesis: `backgroundFromId(_backgroundId)` recibe un ID no registrado y cae a `prefabBackgrounds.first` (NoneBackground). Posible mismatch entre IDs del selector y los del prefab. | A3 |
| 4 | Dislexia: se activa pero no es la fuente correcta | `transit_typography.dart:8` pide `'Atkinson Hyperlegible'` y la fuente SÍ está empaquetada en `assets/fonts/atkinson_hyperlegible/`. PERO los `GoogleFonts.ibmPlexMono(…)` de líneas 12-30 NO respetan el toggle (los IBM Plex Mono se siguen usando para `routeCode`, `displayTime`, etc.). Además los TextStyle generados con `GoogleFonts.dmSans(…)` también lo ignoran. La fuente "cambia" parcialmente y eso parece "otra que no es". | A4 |
| 5 | FAB ubicación demasiado arriba del sheet | `map_tab.dart` `_AnchoredMapControls`: `fabBottom = sheetTop + 12` → el FAB queda 12 px ENCIMA del borde superior del sheet, separado visualmente. El usuario quiere pegado o con overlap mínimo. | A5 |
| 6 | Letras de cada línea deberían tener el color de la línea | `RouteCard` líneas ~74-92 actualmente usa `c.accent` para `Text(route.code, style: TransitTypography.routeCode(c.accent))`. Hay que cambiar a `route.routeColor` (campo ya existente en RouteModel:19). | A5 |
| 7 | Filtros: desactivar compañías/zonas/líneas | `MapFilterState` ya tiene `activeOperators: Set<String>` y `activeKinds: Set<String>` pero el sheet NO los expone. Falta UI jerárquica. | A6 |
| 8 | Desplegable habitual config tapado por navbar | `habitual_config_sheet.dart` line ~46: padding bottom = `24 + MediaQuery.viewInsets.bottom`. NO suma la altura del navbar (56px). El sheet se extiende debajo del navbar (Scaffold tiene `extendBody: true`). | A7 |
| 9 | Modo claro: no se puede ajustar apariencia ni se adaptan colores | Conjunto de bugs: muchos widgets de Apariencia tienen colores hardcoded para dark mode. En light mode quedan invisibles o con poco contraste. Audit + fix con tokens. | A1 |

---

## Estructura

```
WAVE 1 (5 agentes paralelos, sin solape de archivos)
├── A1  Theming: una sola Default + modo claro funcional + audit hardcodes en Apariencia
├── A2  Mapa: tiles reactivos sin depender de API key (fallback OSM con varios estilos)
├── A3  Fondos: diagnosticar y arreglar la propagación del backgroundId
├── A4  Dislexia: aplicar Atkinson Hyperlegible a TODAS las fuentes (DM Sans + IBM Plex Mono fallback)
└── A5  RouteCard color de línea + FAB pegado al sheet

WAVE 2 (2 agentes paralelos)
├── A6  Filtros jerárquicos Compañías → Zonas → Líneas
└── A7  Habitual config sheet con padding navbar

WAVE 3 (coordinador, NO agente)
└── flutter analyze + test + smoke completo
```

### Tabla de archivos por agente

| Agente | Archivos que modifica | Archivos NUEVOS |
|--------|------------------------|------------------|
| **A1** | `lib/core/theme/palettes/prefab_palettes.dart` (eliminar duplicación + variantes light reales), `lib/shared/providers/theme_notifier.dart` (auto-switch themeMode si paleta lo fuerza), `lib/features/appearance/widgets/*.dart` (audit hardcodes) | — |
| **A2** | `lib/features/map/map_config.dart` (estilos OSM/Carto reales con URLs distintas), `lib/features/map/transit_map.dart` (verificar key) | — |
| **A3** | `lib/shared/widgets/background_wrapper.dart`, `lib/features/appearance/widgets/background_selector.dart`, `lib/core/theme/backgrounds/prefab_backgrounds.dart` | — |
| **A4** | `lib/core/theme/transit_typography.dart` | — |
| **A5** | `lib/shared/widgets/route_card.dart`, `lib/features/home/tabs/map_tab.dart` (SOLO el `fabBottom` de `_AnchoredMapControls`) | — |
| **A6** | `lib/features/map/map_filter_state.dart`, `lib/features/map/map_filter_controller.dart`, `lib/features/map/widgets/map_filter_sheet.dart`, `lib/features/home/tabs/map_tab.dart` (SOLO `_filteredRoutes` para aplicar nuevos filtros) | — |
| **A7** | `lib/features/home/widgets/habitual_config_sheet.dart` | — |

### Conflictos controlados

- `lib/features/home/tabs/map_tab.dart`: A5 toca SOLO el cálculo de `fabBottom` en `_AnchoredMapControls`. A6 toca SOLO `_filteredRoutes`. Son zonas independientes; merge trivial.
- `lib/l10n/*.arb`: solo A6 añade claves nuevas (filtros). Al final del JSON.

---

## Contexto global (pegar en todos los briefs)

```
PROYECTO: Transitly (nexto-stop-v2) — App Flutter de transporte público para Jerez.
STACK: Flutter 3.9.2+, Riverpod 2.6.1, go_router 17.2.3, flutter_map 7.0.2,
hive 2.2.3, flutter_map_tile_caching 10.0.0.
DIRECTORIO: C:\Users\k\Desktop\all\clase\nexto-stop-v2
RAMA: master

REGLAS:
- 0 warnings de flutter analyze.
- Tokens del design system siempre (TransitColorScheme, TransitTypography, TransitSpacing).
- Commits en español con prefijo convencional.
- NO ejecutar flutter build apk --release ni git push salvo si lo pide el usuario.
- l10n: añadir claves al final del JSON. NO regenerar.

DECISIONES TOMADAS CON EL USUARIO (en este turno):
- Una sola paleta Default; el toggle de modo controla el brillo.
- Mapa: fallback robusto sin depender de MapTiler API key (no está configurada).
- Color de línea: SOLO en el badge del código (L1, L15-EP), no en nombre/polylines/flechas.
- Filtros: jerarquía con expansión Compañías → Zonas → Líneas.
```

---

## WAVE 1 — Briefs

### A1 — Theming: una sola Default + modo claro funcional + audit Apariencia

```text
ROL: Engineer Flutter senior, especialista en theming y design tokens.

CONTEXTO DEL PROYECTO: <pegar bloque "Contexto global">

PROBLEMAS:
1. Las dos paletas "Default oscuro" y "Default claro" se ven iguales.
   ROOT CAUSE: ambas tienen el mismo `lightScheme: TransitLightColors()` y
   `darkScheme: TransitDarkColors()`. `buildTheme(brightness)` elige por
   `brightness`, ignorando cuál paleta está activa → producen idéntico
   ThemeData.
2. Al poner el modo claro no se puede ajustar nada de Apariencia ni los
   colores que se metan se adaptan.
   HIPÓTESIS: muchos widgets de Apariencia (BackgroundSelector cards,
   PaletteCard, sliders, dropdowns) tienen valores semi-transparentes
   sobre fondo oscuro que en modo claro quedan invisibles/sin contraste.

DECISIÓN DEL USUARIO:
"Una sola Default + que el toggle de modo lo cambie."

ARCHIVOS PERMITIDOS:
- lib/core/theme/palettes/prefab_palettes.dart
- lib/shared/providers/theme_notifier.dart
- lib/features/appearance/widgets/palette_section.dart
- lib/features/appearance/widgets/background_selector.dart
- lib/features/appearance/widgets/font_section.dart
- lib/features/appearance/widgets/accessibility_section.dart
- lib/features/appearance/widgets/brightness_section.dart
- lib/features/appearance/widgets/map_style_section.dart
- lib/features/appearance/widgets/reset_section.dart
- lib/features/appearance/widgets/storage_section.dart
- lib/features/appearance/appearance_screen.dart
- lib/features/appearance/custom_palette_screen.dart

ARCHIVOS PROHIBIDOS:
- map_config.dart, transit_map.dart (es de A2)
- background_wrapper.dart, prefab_backgrounds.dart (es de A3)
- transit_typography.dart (es de A4)
- route_card.dart, map_tab.dart (es de A5)
- map_filter_*.dart (es de A6)
- habitual_config_sheet.dart (es de A7)

═══════════════════════════════════════════════════════════════════
TAREAS CONCRETAS:
═══════════════════════════════════════════════════════════════════

T1. Eliminar duplicación de Default
   En lib/core/theme/palettes/prefab_palettes.dart:
   - Elimina `defaultLightPalette` (líneas 283-291 aprox).
   - Elimina la entrada `defaultLightPalette` del array `prefabPalettes`.
   - Renombra la única paleta default:
       name: 'Default'   (en lugar de 'Default oscuro')
   - Las demás paletas (Sunrise, Forest, Midnight, Ocean, Mono) mantienen
     sus nombres.

T2. Variantes light reales por paleta
   Para que cada paleta tenga aspecto en modo claro coherente:
   - Crea clases TransitSunriseLightColors, TransitForestLightColors,
     TransitMidnightLightColors, TransitOceanLightColors,
     TransitMonoLightColors en el mismo archivo prefab_palettes.dart
     siguiendo el patrón de TransitLightColors pero con tonos pastel del
     accent de la paleta.
   - Si no tienes tiempo o no quieres diseñar 5 paletas light:
     a) Mantén `lightScheme: TransitLightColors()` en TODAS las paletas
        no-default (Sunrise, Forest, etc.) — son IGUALES en modo claro,
        pero distintos en modo oscuro. Documenta en el reporte.
     b) Más adelante alguien diseñará variantes light específicas.
   - Lo importante: que el cambio de paleta SÍ cambie el accent y los
     tonos del modo oscuro, y que el modo claro funcione coherentemente.

T3. Audit de hardcodes en Apariencia
   Ejecuta:
       rg "Color\(0xFF" lib/features/appearance/
       rg "Colors\.white" lib/features/appearance/
       rg "Colors\.black" lib/features/appearance/
   Lista cada hit. Para cada uno:
   - Si el color es semánticamente fijo (ej. un rojo de error) y se ve
     bien en ambos modos, déjalo.
   - Si es un fondo, borde, texto o accent que en modo claro queda
     invisible, sustitúyelo por el token equivalente del
     TransitColorScheme actual (consulta `c` en cada build):
       Color(0xFFXXXXXX) → c.bgSurface / c.border / c.textHi / c.accent
   - Para CADA cambio: pasa `c = TransitColorScheme.of(isDark)` al build
     del widget si no está ya disponible.

T4. Modo claro smoke test
   Tras T3, ejecuta `flutter run` y:
   - Cambia themeMode a Light en el BrightnessSection.
   - Recorre cada sección de Apariencia y comprueba que TODOS los
     toggles, sliders, dropdowns y textos son legibles, tienen contraste
     y el tap responde con feedback visible.
   - Cambia a una paleta no-default (ej. Sunrise) → el accent cambia
     incluso en modo claro.
   - Activa "+ Crear paleta personalizada" → el wizard funciona en
     light.
   - Cualquier widget invisible/sin contraste lo arreglas en T3.

═══════════════════════════════════════════════════════════════════
VERIFICACIÓN:
═══════════════════════════════════════════════════════════════════
- `flutter analyze` 0 warnings.
- Smoke: solo aparece "Default" en el grid de paletas (no "Default
  claro"/"oscuro" separadas).
- Cambiar tema en BrightnessSection cambia la app SIN necesidad de
  cambiar paleta.
- En modo claro, TODAS las opciones de Apariencia son legibles y
  funcionales.

COMMIT(s):
- fix(theme): una sola paleta Default + nombre actualizado
- fix(theme): audit y eliminar hardcodes en pantalla Apariencia

REPORTE FINAL:
- Decisión de T2 documentada (variantes light propias o TransitLightColors).
- Lista de archivos modificados por T3 con número de hardcodes fixed.
- Confirmación visual de smoke en modo claro.
```

---

### A2 — Mapa: tiles reactivos sin depender de API key

```text
ROL: Engineer Flutter, flutter_map y tile providers.

CONTEXTO DEL PROYECTO: <pegar bloque "Contexto global">

PROBLEMA REPORTADO:
"El mapa no cambia de color da igual si es modo oscuro, claro o en
personalización. Da igual lo que se haga."

ROOT CAUSE CONFIRMADO:
- lib/features/map/map_config.dart líneas 17-25:
    static String tileUrl(String style, {String? apiKey}) {
      final key = apiKey ?? Env.mapTilerApiKey;
      if (key != null && key.isNotEmpty) {
        final slug = mapStyles[style] ?? mapStyles['streets']!;
        return '$_maptilerBase/$slug/{z}/{x}/{y}@2x.png?key=$key';
      }
      return _cartoUrl(style);  ← fallback aquí cuando la key falta
    }
    static String _cartoUrl(String style) {
      final isDark = style == 'dark' || style == 'streets';
      final tilePath = isDark ? 'dark_nolabels' : 'light_nolabels';
      return 'https://{s}.basemaps.cartocdn.com/$tilePath/{z}/{x}/{y}@2x.png';
    }
- Sin MAPTILER_API_KEY (no está en launch.json), `_cartoUrl` solo tiene
  2 URLs distintas. `streets` se trata como dark; `basic`, `bright`,
  `light` se tratan como light → 5 estilos colapsan a 2.

DECISIÓN DEL USUARIO:
"Verificar API key + fallback OSM con 5 estilos reales (no depender de
MapTiler)."

OBJETIVO:
Que cambiar de mapStyle muestre tiles VISUALMENTE distintos, tanto si la
API key está como si no.

ARCHIVOS PERMITIDOS:
- lib/features/map/map_config.dart
- lib/features/map/transit_map.dart (SOLO verificar; no toques nada más)

═══════════════════════════════════════════════════════════════════
TAREAS CONCRETAS:
═══════════════════════════════════════════════════════════════════

T1. Inventario de proveedores públicos sin API key
   Estilos reales que se pueden usar sin key:
   - **standard** (OSM clásico):
       https://tile.openstreetmap.org/{z}/{x}/{y}.png
       (atribución obligatoria: © OpenStreetMap contributors)
   - **dark** (Carto dark_all):
       https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png
       (con etiquetas)
   - **light** (Carto positron):
       https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}@2x.png
   - **voyager** (Carto voyager, colores intermedios):
       https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png
   - **toner** (Stadia Toner Lite, B&N):
       https://tiles.stadiamaps.com/tiles/stamen_toner_lite/{z}/{x}/{y}@2x.png
       (gratis con atribución)
   - **terrain** (Stadia Stamen Terrain):
       https://tiles.stadiamaps.com/tiles/stamen_terrain/{z}/{x}/{y}@2x.png

   Algunos requieren `subdomains: ['a','b','c','d']` (Carto sí).

T2. Reescribir MapConfig.tileUrl
   Reemplaza el bloque actual por:

       class MapConfig {
         MapConfig._();

         // 5 estilos reales con URLs distintas (sin API key requerida).
         // Si MAPTILER_API_KEY está disponible, se usa MapTiler en lugar.
         static const mapStyles = {
           'streets':  'voyager',
           'basic':    'standard',
           'bright':   'light',
           'dark':     'dark',
           'light':    'positron',
         };

         static const _maptilerSlugs = {
           'streets': 'streets-v2',
           'basic':   'basic-v2',
           'bright':  'bright-v2',
           'dark':    'dataviz-dark',
           'light':   'dataviz-light',
         };

         static String tileUrl(String style, {String? apiKey}) {
           final key = apiKey ?? Env.mapTilerApiKey;
           if (key != null && key.isNotEmpty) {
             final slug = _maptilerSlugs[style] ?? _maptilerSlugs['streets']!;
             return 'https://api.maptiler.com/maps/$slug/{z}/{x}/{y}@2x.png?key=$key';
           }
           final fallback = mapStyles[style] ?? 'voyager';
           switch (fallback) {
             case 'standard':
               return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
             case 'dark':
               return 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png';
             case 'positron':
               return 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}@2x.png';
             case 'voyager':
               return 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png';
             case 'light':
               return 'https://{s}.basemaps.cartocdn.com/voyager_nolabels/{z}/{x}/{y}@2x.png';
             default:
               return 'https://{s}.basemaps.cartocdn.com/voyager/{z}/{x}/{y}@2x.png';
           }
         }

         static const subdomains = ['a', 'b', 'c', 'd'];

         static final defaultCenter = const LatLng(36.6850, -6.1261);
         static const defaultZoom = 13.0;
         static const minZoom = 8.0;
         static const maxZoom = 18.0;
       }

   - Decide colores según gustos del proyecto; la idea es que los 5
     estilos sean VISUALMENTE distintos.

T3. Verificar transit_map.dart
   En lib/features/map/transit_map.dart líneas 223-228:
   - El TileLayer ya usa `widget.mapStyle ?? (widget.isDark ? 'dark' : 'light')`.
   - Verifica que `subdomains: MapConfig.subdomains` está presente. Si no,
     añádelo (la API de OSM no lo necesita, pero Carto sí).
   - Verifica que la key del TransitMap en map_tab.dart cambia con
     `mapStyle` (ya está según la review).
   - NO modifiques otras zonas del archivo.

T4. Atribuciones
   El widget actual ya muestra "© MapTiler © OpenStreetMap contributors"
   (línea ~277). Cambia el texto a:
       "© OpenStreetMap contributors · © CARTO · © MapTiler"
   para cubrir las tres fuentes posibles.

═══════════════════════════════════════════════════════════════════
VERIFICACIÓN:
═══════════════════════════════════════════════════════════════════
- `flutter analyze` 0 warnings.
- Smoke MANUAL con `flutter run` (sin API key):
  1. Apariencia → Estilo de mapa → "streets" → mapa muestra Voyager
     (colores neutros con calles destacadas).
  2. Cambia a "basic" → OSM estándar (estilo Wikipedia).
  3. "bright" → Carto light alternativo.
  4. "dark" → Carto dark.
  5. "light" → Carto positron.
   Los 5 estilos son VISUALMENTE distintos.
- Cambiar themeMode dark/light también afecta porque el mapa usa el
  estilo configurado o cae al fallback dark/light según `isDark` cuando
  no hay mapStyle configurado.

COMMIT(s):
- fix(map): 5 estilos reales sin API key (OSM/Carto fallback)

REPORTE FINAL:
- Si la API key estaba o no.
- Los 5 estilos con su URL correspondiente.
- Confirmación visual de cada estilo en smoke.
```

---

### A3 — Fondos: diagnosticar propagación

```text
ROL: Engineer Flutter, debugging de providers + assets.

CONTEXTO DEL PROYECTO: <pegar bloque "Contexto global">

PROBLEMA REPORTADO:
"El fondo tampoco cambia ni en los diferentes tipos ni en opacidad ni
ninguna de las opciones."

ESTADO DEL CÓDIGO:
- `visualKey` (línea 130-150 de theme_notifier.dart) YA incluye
  `_backgroundId` y `_backgroundOpacity` → el rebuild se dispara.
- `background_wrapper.dart` YA tiene los 5 patterns implementados
  (None, Shader, Gradient, Image, Procedural).
- `prefab_backgrounds.dart` declara los IDs:
    'none'
    'shaders/smoke.frag'
    GradientBackground (id se genera dinámicamente)
    ProceduralBackground(softGrid)
    ProceduralBackground(topoLines)

HIPÓTESIS DEL BUG:
1. **IDs del selector ≠ IDs del prefab**: en `background_selector.dart`
   el switch de `_bgName` espera IDs como `'assets/bg/soft_grid.png'`,
   pero `prefabBackgrounds` los registra como `'procedural:softGrid'` o
   similar. Si los IDs no coinciden, `backgroundFromId(_backgroundId)`
   cae a `prefabBackgrounds.first` (NoneBackground) y el usuario ve
   siempre lo mismo.

2. **ImageBackground sin asset real**: si el selector ofrece
   `'assets/bg/soft_grid.png'` pero ese archivo NO existe en
   `assets/bg/`, el `Image.asset(...)` crashea silenciosamente o muestra
   placeholder.

3. **Opacity entre el painter y el child**: ya está implementado tras
   v5 (Stack con child fuera de Opacity). Pero si el wrapper devuelve
   directamente `NoneBackground` por mismatch del ID, no se ven cambios
   al mover el slider.

OBJETIVO:
1. Inventariar los IDs reales (prefab vs selector).
2. Hacer que cualquier ID válido del selector se renderice con su
   patrón.
3. Si hay assets PNG declarados pero faltantes, eliminarlos del selector
   o generarlos.

ARCHIVOS PERMITIDOS:
- lib/shared/widgets/background_wrapper.dart
- lib/features/appearance/widgets/background_selector.dart
- lib/core/theme/backgrounds/prefab_backgrounds.dart
- lib/core/theme/backgrounds/app_background.dart (verificar)

ARCHIVOS PROHIBIDOS: cualquier otro.

═══════════════════════════════════════════════════════════════════
TAREAS CONCRETAS:
═══════════════════════════════════════════════════════════════════

T1. Diagnóstico de IDs
   - Imprime los IDs reales:
       for b in prefabBackgrounds: print(b.id)
     en algún test rápido o smoke.
   - Compara con los IDs que aparecen en `background_selector.dart`:
       _bgName(id) switch contiene: 'none', 'shaders/smoke.frag',
       'gradient:*', 'assets/bg/soft_grid.png', 'assets/bg/topo_lines.png'
   - Si el ID del prefab para ProceduralBackground(softGrid) NO es
     `'assets/bg/soft_grid.png'`, hay mismatch. Lo más probable: el ID
     real es `'procedural:softGrid'` o `'softGrid'`.

T2. Alinear IDs
   Decide la fuente de verdad: los IDs son los que tiene
   `prefab_backgrounds.dart`. Cambia `background_selector.dart` para
   que el switch de `_bgName` y `_bgIcon` use los IDs reales del prefab,
   no las rutas de assets imaginarias.

   El selector debe iterar sobre `prefabBackgrounds` (ya lo hace) y
   resolver name/icon con el ID real:
       _bgName(id) → switch sobre los IDs que sí existen.

T3. Verificar AppBackground tiene un getter `id` consistente
   En lib/core/theme/backgrounds/app_background.dart:
   - Cada subtipo (None, Shader, Gradient, Image, Procedural) debe
     exponer un `String id` que sea único y serializable.
   - Si Gradient genera `id` dinámicamente con un hash de los colores,
     fija un ID legible como `'gradient:cool-mist'` para que el selector
     pueda mostrar y persistir el ID legible.
   - Lo mismo para Procedural: `'procedural:softGrid'`,
     `'procedural:topoLines'`.

T4. Eliminar referencias a PNGs que no existen
   Si `_bgName` o `_bgIcon` listan `'assets/bg/soft_grid.png'` pero ese
   archivo NO está en `assets/bg/` ni declarado en pubspec.yaml, elimina
   esa rama del switch. Reemplázala por la rama correcta del Procedural
   (que se renderiza con CustomPainter, no con Image.asset).

T5. Smoke
   Tras T1-T4:
   1. Apariencia → Fondo → "Cuadrícula" → ves el SoftGridPainter.
   2. "Topografía" → ves TopoLinesPainter.
   3. "Humo" → ves el shader.
   4. "Gradiente" → ves degradado.
   5. "Sin fondo" → fondo plano.
   6. Slider de opacidad 0% en cualquiera → el fondo desaparece pero la
      UI sigue visible (ya implementado tras v5).

═══════════════════════════════════════════════════════════════════
VERIFICACIÓN:
═══════════════════════════════════════════════════════════════════
- `flutter analyze` 0 warnings.
- Test smoke completo de T5.
- Logs limpios: si añades print/AppLogger en debug, asegúrate de
  eliminarlos antes del commit final.

COMMIT(s):
- fix(theme): IDs de fondos alineados entre selector y prefabs

REPORTE FINAL:
- Lista de IDs antes (mismatch) y después (alineados).
- Si encontraste PNGs que no existían, lista.
- Confirmación de smoke completo.
```

---

### A4 — Dislexia: aplicar Atkinson a TODAS las fuentes

```text
ROL: Engineer Flutter, typography y design system.

CONTEXTO DEL PROYECTO: <pegar bloque "Contexto global">

PROBLEMA REPORTADO:
"La fuente de dislexia no se activa correctamente y es remplazada por
otra que no es."

ROOT CAUSE:
- `lib/core/theme/transit_typography.dart` línea 8:
    static String get _bodyFontFamily =>
        isDyslexiaEnabled() ? 'Atkinson Hyperlegible' : 'DM Sans';
- PERO los TextStyle de líneas 12-30 usan `GoogleFonts.ibmPlexMono(...)`
  directamente, NO `_bodyFontFamily`:
    static TextStyle displayTime(Color c) => GoogleFonts.ibmPlexMono(...)
    static TextStyle routeCode(Color c) => GoogleFonts.ibmPlexMono(...)
    static TextStyle displayNumber(Color c) => GoogleFonts.ibmPlexMono(...)
- También hay TextStyle que usan GoogleFonts.dmSans en otros métodos
  (verificar).
- Resultado: cuando el usuario activa dislexia, SOLO los TextStyle que
  usan `_bodyFontFamily` cambian a Atkinson. El resto (displayTime,
  routeCode, displayNumber, todos los que estén con GoogleFonts.X
  directo) se quedan en su fuente original. Visualmente el usuario ve
  algunos textos cambiados (los body) y otros no → "es remplazada por
  otra que no es".

OBJETIVO:
TODOS los TextStyle de la app, cuando dislexia esté activa, deben usar
Atkinson Hyperlegible. Sin excepciones. Incluido los monoespaciados de
displayTime, routeCode, displayNumber.

(Justificación: la accesibilidad para dislexia recomienda UNA SOLA fuente
homogénea en toda la app, no mezclar. Atkinson Hyperlegible tiene
variantes mono también si se necesita, pero podemos usar Atkinson para
todo y dejar de pintar IBM Plex Mono cuando dislexia esté activada.)

ARCHIVOS PERMITIDOS:
- lib/core/theme/transit_typography.dart

ARCHIVOS PROHIBIDOS: cualquier otro.

═══════════════════════════════════════════════════════════════════
TAREAS CONCRETAS:
═══════════════════════════════════════════════════════════════════

T1. Auditar todos los TextStyle
   Lista cada método estático que devuelve TextStyle:
       displayTime, displayNumber, routeCode, sectionTitle, sectionLabel,
       heading, headingSmall, bodyPrimary, bodySecondary, bodySmall,
       stopTime, timeEstimate, routeName, etc.
   Para cada uno: ¿usa GoogleFonts.X directamente o respeta dyslexia?

T2. Refactor unificado
   Cambia TODOS los TextStyle para que su fontFamily se resuelva por un
   getter único `_activeFontFamily(monospace: bool)`:

       static String _activeFontFamily({bool monospace = false}) {
         if (isDyslexiaEnabled()) return 'Atkinson Hyperlegible';
         return monospace ? 'IBM Plex Mono' : 'DM Sans';
       }

   Y reemplaza cada `GoogleFonts.ibmPlexMono(...)` o
   `GoogleFonts.dmSans(...)` por:

       TextStyle(
         fontFamily: _activeFontFamily(monospace: true),  // o false
         fontSize: ...,
         fontWeight: ...,
         color: ...,
         letterSpacing: ...,
       )

   - Las dos familias (IBM Plex Mono y DM Sans) están empaquetadas como
     assets (verifica pubspec.yaml línea ~95-110). Atkinson Hyperlegible
     también (tras v5).
   - NO uses `GoogleFonts.X(...)` porque el package no carga assets
     locales — usa TextStyle directo con fontFamily.

T3. Casos especiales
   - `routeCode`: ahora el monoespacio se justifica visualmente. Con
     dislexia activa, todos los códigos de línea pasan a Atkinson; eso
     puede romper alineación si el código tiene 6+ caracteres. Aceptable
     porque la accesibilidad prima.
   - `displayTime` y `displayNumber`: idem.

═══════════════════════════════════════════════════════════════════
VERIFICACIÓN:
═══════════════════════════════════════════════════════════════════
- `flutter analyze` 0 warnings.
- Smoke:
  1. Modo dislexia OFF → home muestra DM Sans en body, IBM Plex Mono en
     códigos de línea y horas.
  2. Modo dislexia ON → TODO se convierte a Atkinson Hyperlegible. Los
     códigos de línea (L1, L15-EP) pasan a Atkinson; las horas (14:23)
     pasan a Atkinson; los nombres de ruta pasan a Atkinson.
  3. La fuente debe verse claramente DISTINTA (más legible, caracteres
     más diferenciados como '1'/'I'/'l'). Comparar visualmente con
     muestras online de Atkinson.

COMMIT:
fix(a11y): aplicar Atkinson Hyperlegible a TODOS los TextStyle cuando
dislexia activada

REPORTE FINAL:
- Lista de métodos refactorizados.
- Confirmación visual de smoke (con y sin dislexia).
- Si la app tenía algún uso directo de GoogleFonts fuera de
  transit_typography que también deba migrarse (lib/features/...), lista
  el archivo y déjalo para el coordinador (no toques fuera del scope).
```

---

### A5 — RouteCard color de línea + FAB pegado al sheet

```text
ROL: Engineer Flutter, UI polish.

CONTEXTO DEL PROYECTO: <pegar bloque "Contexto global">

PROBLEMAS:
1. "Cada línea en la lista del mapa, las letras y eso deberían tener el
   color de la línea que se le haya asignado por el creador."
   ROOT CAUSE: `RouteCard` (líneas ~74-92) pinta el código con
   `TransitTypography.routeCode(c.accent)` → todos los códigos en color
   accent del tema. El campo `route.routeColor` ya existe en
   `RouteModel:19` pero no se usa.

2. "El botón de ir a mi ubicación del mapa está demasiado arriba de lo
   que sería el desplegable de líneas, debería estar más cerca."
   ROOT CAUSE: `_AnchoredMapControls` (línea ~662 de map_tab.dart):
       final fabBottom = screenH - sheetTop + 12;
   El +12 deja 12px ENTRE el FAB y el borde superior del sheet. El
   usuario lo percibe como "muy arriba".

DECISIÓN DEL USUARIO:
- Color solo en el badge del código (no nombre, no polylines).

ARCHIVOS PERMITIDOS:
- lib/shared/widgets/route_card.dart  ← SOLO el badge interno del
  código de ruta (líneas ~74-92).
- lib/features/home/tabs/map_tab.dart  ← SOLO el cálculo de fabBottom
  en `_AnchoredMapControls` (línea ~662).

ARCHIVOS PROHIBIDOS:
- map_filter_*.dart (es de A6)
- otros archivos.

═══════════════════════════════════════════════════════════════════
TAREAS CONCRETAS:
═══════════════════════════════════════════════════════════════════

T1. RouteCard badge con color de línea
   En lib/shared/widgets/route_card.dart, en la zona del Container del
   código (líneas 74-92 aprox):

       // Antes:
       Container(
         constraints: const BoxConstraints(minWidth: 60, maxWidth: 96),
         margin: const EdgeInsets.all(10),
         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
         decoration: BoxDecoration(
           color: statusColor.withValues(alpha: 0.15),
           borderRadius: BorderRadius.circular(10),
           border: Border.all(
             color: statusColor.withValues(alpha: 0.30),
             width: 1,
           ),
         ),
         child: Center(
           child: FittedBox(
             fit: BoxFit.scaleDown,
             child: Text(
               route.code,
               style: TransitTypography.routeCode(c.accent),
               maxLines: 1,
               overflow: TextOverflow.fade,
             ),
           ),
         ),
       )

       // Después:
       final lineColor = route.routeColor;
       // Helper para texto contrastado sobre lineColor:
       final lineTextColor = _contrastTextFor(lineColor);
       Container(
         constraints: const BoxConstraints(minWidth: 60, maxWidth: 96),
         margin: const EdgeInsets.all(10),
         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
         decoration: BoxDecoration(
           color: lineColor.withValues(alpha: 0.18),
           borderRadius: BorderRadius.circular(10),
           border: Border.all(
             color: lineColor.withValues(alpha: 0.55),
             width: 1.5,
           ),
         ),
         child: Center(
           child: FittedBox(
             fit: BoxFit.scaleDown,
             child: Text(
               route.code,
               style: TransitTypography.routeCode(lineColor),
               maxLines: 1,
               overflow: TextOverflow.fade,
             ),
           ),
         ),
       )

   Helper privado en el mismo archivo:
       Color _contrastTextFor(Color bg) {
         // ratio contrast WCAG: si la luminancia del bg es baja → texto claro
         final l = bg.computeLuminance();
         return l > 0.5 ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
       }

   - El color del status del trip (statusColor) sigue mostrándose en el
     resto del card (badges, indicador de retraso) — solo cambias la
     coloración del BADGE del código.

T2. FAB más cerca del sheet
   En map_tab.dart `_AnchoredMapControls` `build` (línea ~662):

       // Antes:
       final fabBottom = screenH - sheetTop + 12;

       // Después:
       final fabBottom = screenH - sheetTop - 4;  // 4px overlap con sheet

   - El FAB queda LIGERAMENTE solapado con el borde superior del sheet
     (4px). Visualmente da sensación de "anclado".
   - Si el usuario prefiere pegado exacto sin overlap, usa `+ 0`.

═══════════════════════════════════════════════════════════════════
VERIFICACIÓN:
═══════════════════════════════════════════════════════════════════
- `flutter analyze` 0 warnings.
- Smoke:
  1. Abre el mapa, expande el sheet. El FAB queda PEGADO al borde
     superior del sheet, con leve overlap (4px).
  2. Mira la lista de líneas en el sheet: cada RouteCard tiene su
     badge en el color de la línea (rojos, azules, verdes, etc. según
     el campo routeColor de comujesa_data.json).
  3. Para una línea con routeColor blanco/amarillo claro, el texto del
     código se ve en negro (contraste WCAG); para colores oscuros, el
     texto va en blanco.

COMMIT(s):
- feat(map): RouteCard badge con color de línea
- fix(map): FAB ubicación pegado al sheet

REPORTE FINAL:
- Snippet del helper _contrastTextFor.
- Resultado del cálculo de fabBottom en una pantalla de 800px (debe ser
  ~172px aprox con sheetFraction 0.22).
```

---

## WAVE 2 — Briefs

### A6 — Filtros jerárquicos Compañías → Zonas → Líneas

```text
ROL: Engineer Flutter senior, Riverpod + UX de filtros.

CONTEXTO DEL PROYECTO: <pegar bloque "Contexto global">

PROBLEMA REPORTADO:
"Quiero que añadas en filtros las opcion de desactivar compañias, zonas
o lineas específicas dentro de las mismas."

DECISIÓN DEL USUARIO:
"Jerarquía con expansión: Compañías → Zonas → Líneas."

ESTADO DEL CÓDIGO:
- `lib/features/map/map_filter_state.dart` ya tiene:
    Set<String> activeOperators
    Set<String> activeKinds
  Pero el sheet UI no los expone.
- `lib/features/map/map_filter_controller.dart` ya tiene métodos
  `toggleOperator(String)` y `toggleKind(String)`.
- `lib/data/mock/mock_data_service.dart`: solo hay UN operador
  (COMUJESA). Eso es OK: la UI muestra UN nodo "COMUJESA" expandible.

OBJETIVO:
UI de filtros con expansión jerárquica:
- Nivel 1: Compañías (checkbox cascade hacia hijos)
- Nivel 2: Zonas dentro de cada compañía
- Nivel 3: Líneas dentro de cada zona
- Cada nivel tiene checkbox. Si desmarcas COMUJESA, todas sus zonas y
  líneas se desmarcan. Si marcas una zona, todas sus líneas se marcan.

ARCHIVOS PERMITIDOS:
- lib/features/map/map_filter_state.dart (extender con
  `Set<String> disabledLines`)
- lib/features/map/map_filter_controller.dart (añadir métodos
  toggleLine, setOperatorEnabled cascade, setKindEnabled cascade)
- lib/features/map/widgets/map_filter_sheet.dart (UI jerárquica)
- lib/features/home/tabs/map_tab.dart  ← SOLO `_filteredRoutes` para
  aplicar los nuevos filtros.
- lib/l10n/app_*.arb (claves al final)

═══════════════════════════════════════════════════════════════════
TAREAS CONCRETAS:
═══════════════════════════════════════════════════════════════════

T1. Extender MapFilterState
   En lib/features/map/map_filter_state.dart, añade campos al freezed:
       @Default(<String>{}) Set<String> disabledOperators,
       @Default(<String>{}) Set<String> disabledKinds,
       @Default(<String>{}) Set<String> disabledLines,
   (Renombra `activeOperators`/`activeKinds` a `disabledOperators`/
   `disabledKinds` si la semántica era inversa; la regla "default visible"
   es más intuitiva con `disabled*`. Si ya están como `active*` con
   semántica "si está en el set, está activo", déjalo y añade solo
   disabledLines.)

   Tras editar el freezed:
       dart run build_runner build --delete-conflicting-outputs

T2. Métodos en MapFilterController
   En map_filter_controller.dart:
   - `toggleLine(String routeId)`: toggle directo en disabledLines.
   - `setOperatorVisible(String opId, bool visible, {required List<String> zones, required List<String> lines})`:
     cascade — si desmarcas COMUJESA, añade su id a disabledOperators
     y TODOS sus zones a disabledKinds y TODAS sus lines a disabledLines.
   - `setKindVisible(String kind, bool visible, {required List<String> lines})`:
     cascade — desmarca la zona y todas sus líneas hijas.
   - Persistencia: actualizar el JSON serialization de
     MapFilterState para los 3 sets nuevos.

T3. UI jerárquica en map_filter_sheet
   Reemplaza la sección "Fuente" (showOfficial/showCommunity) por la
   nueva sección "Mostrar líneas":

       _SectionTitle(c: c, title: 'Mostrar líneas')
       _OperatorTree(...)  // widget custom

   `_OperatorTree` es una clase widget en el mismo archivo o un
   componente nuevo. Para cada operador en `mockData.operators` (en
   este proyecto solo hay 1, COMUJESA):

       ExpansionTile(
         leading: Checkbox(
           value: !f.disabledOperators.contains(op.id),
           onChanged: (v) => ctrl.setOperatorVisible(op.id, v ?? true,
               zones: zonesOf(op),
               lines: linesOf(op)),
         ),
         title: Text(op.name, style: TransitTypography.bodyPrimary(c.textHi)),
         children: [
           // Por cada Zone (ServiceType en este proyecto):
           for (final kind in serviceTypes)
             ExpansionTile(
               leading: Checkbox(
                 value: !f.disabledKinds.contains(kind.name),
                 onChanged: (v) => ctrl.setKindVisible(kind.name, v ?? true,
                     lines: linesOf(op, kind)),
               ),
               title: Text(kind.label),
               children: [
                 for (final route in routesOf(op, kind))
                   CheckboxListTile(
                     value: !f.disabledLines.contains(route.id),
                     onChanged: (v) => ctrl.toggleLine(route.id),
                     title: Text('${route.code} · ${route.name}'),
                     dense: true,
                   ),
               ],
             ),
         ],
       )

   - Usa los tokens TransitColorScheme. El Checkbox usa `activeColor`
     de TransitColorScheme.

T4. Aplicar filtros en _filteredRoutes
   En lib/features/home/tabs/map_tab.dart, dentro de `_filteredRoutes`,
   añade DESPUÉS de los filtros existentes:

       final f = ref.read(mapFilterControllerProvider);
       final filtered = routes.where((r) {
         if (f.disabledOperators.contains(r.operatorId)) return false;
         if (f.disabledKinds.contains(r.serviceType.name)) return false;
         if (f.disabledLines.contains(r.id)) return false;
         return true;
       }).toList();

T5. Botones del sheet
   - "Reset" → llama a `ctrl.reset()` (que vacía los 3 sets).
   - "Aplicar" → solo cierra el sheet (los cambios ya están aplicados
     en tiempo real al ser provider).

T6. Claves l10n (añadir al final)
   - app_es.arb:
       "mapFilterShowLines": "Mostrar líneas",
       "mapFilterCompanies": "Compañías",
       "mapFilterZones": "Zonas",
       "mapFilterAllLines": "Todas",
   - app_en.arb y app_ar.arb: equivalentes.

═══════════════════════════════════════════════════════════════════
VERIFICACIÓN:
═══════════════════════════════════════════════════════════════════
- `flutter analyze` 0 warnings.
- `dart run build_runner build` regenera freezed sin error.
- Smoke:
  1. Abre el mapa, FAB filtro arriba derecha → sheet con jerarquía.
  2. Desmarca "COMUJESA" → todas las líneas desaparecen del mapa y del
     sheet de líneas inferior.
  3. Marca COMUJESA, desmarca "Urbano" → solo líneas no urbanas
     visibles.
  4. Marca todo de nuevo, desmarca solo "L5" → todas menos L5.
  5. Cierra y vuelve a abrir el sheet → estado persistente (SharedPreferences).

COMMIT(s):
- feat(map): filtros jerárquicos compañías → zonas → líneas

REPORTE FINAL:
- Confirmación T1-T6.
- Cómo funciona el cascade (impl exacta).
- Claves l10n añadidas.
```

---

### A7 — Habitual config sheet con padding navbar

```text
ROL: Engineer Flutter, UI polish.

CONTEXTO DEL PROYECTO: <pegar bloque "Contexto global">

PROBLEMA REPORTADO:
"El desplegable de configuración habitual es tapado por el nav bar."

ROOT CAUSE:
- `lib/features/home/widgets/habitual_config_sheet.dart` line ~46:
    padding: EdgeInsets.fromLTRB(16, 8, 16, 24 + MediaQuery.of(ctx).viewInsets.bottom),
- El padding bottom suma `viewInsets.bottom` (teclado) pero NO suma la
  altura del bottom navbar (56px). Como Scaffold de HomeShell tiene
  `extendBody: true`, el sheet se extiende DEBAJO del navbar → los
  botones Guardar/Cancelar quedan tapados.

ARCHIVOS PERMITIDOS:
- lib/features/home/widgets/habitual_config_sheet.dart

═══════════════════════════════════════════════════════════════════
TAREAS CONCRETAS:
═══════════════════════════════════════════════════════════════════

T1. Padding bottom contemplando navbar
   En habitual_config_sheet.dart line ~46:

       // Antes:
       padding: EdgeInsets.fromLTRB(
         16, 8, 16,
         24 + MediaQuery.of(ctx).viewInsets.bottom,
       ),

       // Después:
       padding: EdgeInsets.fromLTRB(
         16, 8, 16,
         24 + 56 /* HomeBottomNav.height */
            + MediaQuery.of(ctx).viewInsets.bottom
            + MediaQuery.of(ctx).padding.bottom,
       ),

   - 56 px es la altura constante del HomeBottomNav (definida en
     `lib/features/home/widgets/home_bottom_nav.dart`).
   - Si el componente expone un `static const double height = 56`,
     impórtalo y úsalo (en lugar de literal).

T2. Verificar otros sheets similares
   Si encuentras OTROS sheets (showModalBottomSheet) en la app que
   tienen el mismo bug (botones tapados por navbar):
   - Lista los archivos en tu reporte como "trabajo similar pendiente".
   - NO los toques (fuera del scope).

═══════════════════════════════════════════════════════════════════
VERIFICACIÓN:
═══════════════════════════════════════════════════════════════════
- `flutter analyze` 0 warnings.
- Smoke:
  1. Home → "Configurar viaje habitual" → sheet sube.
  2. Botones "Cancelar"/"Guardar" deben quedar 12-16 px por encima del
     navbar inferior, visibles y tocables.
  3. Si abres el teclado al elegir línea/parada, el sheet también se
     ajusta arriba.

COMMIT:
fix(home): habitual config sheet con padding navbar

REPORTE FINAL:
- Confirmación de T1.
- Lista de otros sheets con bug similar (si los hay).
```

---

## WAVE 3 — Coordinador

1. **Generación de freezed:** (si A6 modificó MapFilterState)
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
2. **Regen l10n:** si A6 añadió claves:
   ```bash
   flutter gen-l10n
   ```
3. **Análisis y tests:**
   ```bash
   flutter analyze    # 0 warnings
   flutter test       # objetivo: todos passed
   ```
4. **Smoke completo en dispositivo Android:**
   - A1: solo aparece "Default" en grid; modo claro funcional con todas
     las opciones legibles.
   - A2: cambiar mapStyle muestra 5 tiles visualmente distintas
     (Voyager, OSM, Carto light, Carto dark, Positron).
   - A3: cada fondo (None, Smoke, Gradient, SoftGrid, TopoLines) se
     renderiza correctamente; slider opacity afecta solo al fondo.
   - A4: activar dislexia cambia TODAS las fuentes (códigos, horas,
     nombres) a Atkinson Hyperlegible.
   - A5: cada RouteCard del sheet del mapa tiene su badge en el color
     de la línea (rojos/azules/verdes según routeColor); FAB
     ubicación pegado al borde superior del sheet.
   - A6: filtros jerárquicos COMUJESA → Zonas → Líneas con checkboxes
     cascade.
   - A7: sheet de configuración habitual con botones visibles encima
     del navbar.

---

## Riesgos y notas

- **A2 (mapa)**: si el usuario tiene la API key de MapTiler, la lógica
  prioriza MapTiler. Si no, fallback OSM/Carto. Documenta cómo añadir
  la key si quiere usar MapTiler.
- **A4 (dislexia)**: cambiar TODOS los TextStyle a Atkinson puede romper
  alineaciones en mono (códigos de línea quedan en proportional).
  Aceptable porque la accesibilidad prima sobre la estética.
- **A6 (filtros)**: regenerar freezed puede modificar `.freezed.dart` y
  `.g.dart` adyacentes. Si conflicta, el coordinador resuelve.
- **A1 (variantes light)**: la opción de mantener `TransitLightColors`
  como light scheme de todas las paletas no-default es aceptable como
  primer paso. Variantes light específicas (Sunrise-light, etc.) quedan
  como trabajo futuro.
- **A5 (color de línea + contraste WCAG)**: el helper
  `_contrastTextFor` puede devolver mal contraste para colores
  medios (ej. azules medios). Si visualmente queda mal, ajusta el
  threshold 0.5 a 0.6 o 0.4.

---

## Cobertura final

| # | Error reportado | Agente |
|---|------------------|--------|
| 1 | Mapa no cambia color | A2 |
| 2 | Dos Default iguales | A1 |
| 3 | Fondo no cambia | A3 |
| 4 | Dislexia no es la fuente correcta | A4 |
| 5 | FAB demasiado arriba | A5 |
| 6 | Color de línea en lista | A5 |
| 7 | Filtros: compañías/zonas/líneas | A6 |
| 8 | Sheet habitual tapado por navbar | A7 |
| 9 | Modo claro no se ajusta nada | A1 |
