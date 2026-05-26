# Plan de despacho paralelo v2 — Reparación Transitly (segunda iteración)

> **Formato:** este plan reparte 17 errores reportados (segunda ronda, tras el primer plan v1) entre 8 agentes en 3 olas paralelas. Cada agente recibe un brief autónomo (no comparte contexto con los demás). Las olas están diseñadas para evitar conflictos de archivos: dentro de una misma ola, ningún agente toca el mismo fichero crítico que otro agente de esa ola.

**Fecha del plan:** 2026-05-26
**Autor:** Claude Code (Opus 4.7)
**Estado:** aprobado por el usuario, pendiente de ejecución
**Plan anterior:** `docs/historico/PLAN_REPARACION_2026_05_26.md` (v1 — algunos fixes quedaron incompletos; este v2 los completa)

---

## Cómo usar este plan

### Quién es quién

- **Coordinador** = el agente principal que lanza este plan.
- **A1..A8** = sub-agentes despachados con `subagent_type: general-purpose` en modo foreground dentro de una sola wave, en paralelo.
- Cada sub-agente recibe **solo** su brief + el bloque `Contexto global del proyecto`. No comparte el resto del documento.

### Receta de despacho

1. **Antes de Wave 1**: `git status` limpio, `flutter analyze && flutter test` para baseline. Crear rama `fix/reparacion-v2` opcional.
2. **Wave 1**: despachar A1..A5 en paralelo (un solo mensaje del coordinador con 5 `Agent` tool calls). Modelo: `sonnet` para todos, `opus` solo para A1 (es el más complejo).
3. **Wave 2**: despachar A6..A8 en paralelo tras integrar Wave 1 y resolver conflictos triviales.
4. **Wave 3**: NO hay agentes; el coordinador hace verificación integral.

### Reglas de oro

- Ningún agente toca código fuera de su tabla de "archivos permitidos".
- `flutter analyze` debe quedar en 0 warnings tras cada commit.
- Cualquier conflicto de merge entre agentes lo resuelve el coordinador en la integración.
- Usar siempre tokens en `lib/core/theme/` y widgets en `lib/shared/widgets/`.
- NO ejecutar `flutter build apk` ni `git push` salvo que el usuario lo pida.

---

## Contexto global del proyecto (incluir en TODOS los briefs)

```
PROYECTO: Transitly (nexto-stop-v2)
DESCRIPCIÓN: App Flutter de transporte público para Jerez (operador COMUJESA, 19
  líneas, 598 paradas geocodificadas reales). Demo académica con datos mock desde
  assets/mock/comujesa_data.json.
STACK: Flutter 3.9.2+, Riverpod 2.6.1, go_router 17.2.3, flutter_map 7.0.2,
  flutter_map_tile_caching 10.0.0, nfc_manager 3.5.0, supabase_flutter 2.8.0,
  hive 2.2.3, geolocator 13.0.0, home_widget 0.7.0.
DIRECTORIO: C:\Users\k\Desktop\all\clase\nexto-stop-v2
RAMA: master (o fix/reparacion-v2 si el coordinador la crea)

REGLAS OBLIGATORIAS:
1. Usar SIEMPRE tokens existentes (TransitColorScheme, TransitTypography,
   TransitSpacing, TransitAnimations) — nunca colores/spacing inline.
2. Reusar widgets compartidos (Pressable, StaggerList, GlassCard, TransitButton,
   RouteCard, StopListItem, etc.).
3. `flutter analyze` debe quedar 0 warnings tras tu cambio.
4. Commits en español con prefijo convencional (feat/fix/refactor/chore).
5. NO ejecutar build de release ni push al remoto.
6. Si necesitas añadir claves de l10n, añadirlas SIEMPRE al final del JSON
   de cada `.arb` (es/en/ar). NO ejecutes `flutter gen-l10n` — eso lo hace
   el coordinador en Wave 3.
```

---

## Mapa de waves

```
WAVE 1 (5 agentes paralelos, sin solape de archivos críticos)
├── A1  Theming + tipografía + personalización         [mapa claro, paletas, mapStyle, fondo, fontScale crash, dislexia, alto contraste, dropdown daltonismo]
├── A2  Mapa: flechas + buses fantasma                 [flechas solo en línea seleccionada con distancia uniforme + eliminar trips JSON]
├── A3  Buscador: chip "Usar mi ubicación" más pequeño
├── A4  Avisos georeferenciados                         [modelo + provider, sin tocar home_tab]
└── A5  Pantalla "Buses cercanos" renombrada + GPS     [renombrar feature + filtrar por distancia + arreglar overflow]

WAVE 2 (3 agentes paralelos; tras integrar Wave 1)
├── A6  Integración en home_tab.dart                    [label "Buses cercanos" + render de avisos geo]
├── A7  Widgets nativos Android reales                  [Kotlin + AppWidgetProvider + Manifest + cableado Dart]
└── A8  Region download offline con FMTC                [fórmula correcta + integración real con flutter_map_tile_caching]

WAVE 3 (coordinador, NO agente)
└── flutter gen-l10n + flutter analyze + flutter test + smoke manual
```

### Tabla de archivos por agente

| Agente | Archivos que modifica | Archivos NUEVOS |
|--------|------------------------|------------------|
| A1 | `lib/shared/providers/theme_notifier.dart`, `lib/core/theme/transit_theme.dart`, `lib/core/theme/high_contrast_theme.dart`, `lib/core/theme/backgrounds/prefab_backgrounds.dart`, `lib/features/appearance/widgets/palette_section.dart`, `lib/features/appearance/widgets/map_style_section.dart`, `lib/features/appearance/widgets/background_selector.dart`, `lib/features/appearance/widgets/font_section.dart`, `lib/features/appearance/widgets/accessibility_section.dart`, `lib/app.dart`, `lib/features/home/tabs/map_tab.dart` (SOLO la línea `TransitMap(...)` para pasar `mapStyle` y `key`), `lib/l10n/*.arb` (al final) | (ninguno) |
| A2 | `lib/features/map/layers/route_direction_arrows.dart`, `lib/features/map/transit_map.dart` (SOLO `_buildDirectionArrows`), `lib/data/mock/mock_realtime_service.dart` (si requiere ajuste), `assets/mock/comujesa_data.json` (eliminar 4 trips de `activeTrips`) | (ninguno) |
| A3 | `lib/shared/widgets/route_search_bar.dart` (SOLO `_buildLocationChip`) | (ninguno) |
| A4 | `lib/shared/models/alert_model.dart`, `lib/data/mock/mock_data_service.dart` (extender `getAlertsForRoute` con filtro geo opcional), `lib/shared/providers/derived/home_providers.dart` (filtrar por proximidad), `lib/features/home/widgets/home_alert_item.dart` (mostrar zona), `assets/mock/comujesa_data.json` (añadir `lat`/`lng`/`radiusMeters` a cada alert) | (ninguno) |
| A5 | `lib/features/nearby_buses/nearby_buses_screen.dart` (renombrado desde `lib/features/accessible_buses/accessible_buses_screen.dart`), `lib/core/router/app_router.dart` (ruta), `lib/l10n/*.arb` (claves nuevas) | renombrar carpeta `accessible_buses/` → `nearby_buses/` |
| A6 | `lib/features/home/tabs/home_tab.dart` | (ninguno) |
| A7 | `android/app/src/main/AndroidManifest.xml`, `lib/data/widgets_native/widget_data_writer.dart`, `lib/features/widgets_native/widgets_settings_screen.dart`, `lib/shared/providers/widget_data_provider.dart` (NUEVO), `pubspec.yaml` (si requiere `home_widget` config) | `android/app/src/main/kotlin/.../widgets/TransitlyNextBusWidget.kt`, `android/app/src/main/kotlin/.../widgets/TransitlyMyLineWidget.kt`, `android/app/src/main/res/xml/widget_next_bus_info.xml`, `android/app/src/main/res/xml/widget_my_line_info.xml`, `android/app/src/main/res/layout/widget_next_bus.xml`, `android/app/src/main/res/layout/widget_my_line.xml` |
| A8 | `lib/features/offline/widgets/region_download_sheet.dart`, `lib/data/fmtc/fmtc_region_downloader.dart` (NUEVO si hace falta), `lib/features/appearance/widgets/storage_section.dart` | (eventual) |

### Conflictos controlados

- **`assets/mock/comujesa_data.json`**: A2 elimina entries del array `activeTrips`. A4 añade campos `lat`/`lng`/`radiusMeters` a cada entry del array `alerts`. Son secciones diferentes del JSON → merge trivial. **Regla**: ambos editan secciones independientes, no toquen la otra.
- **`lib/l10n/*.arb`**: A1, A4 y A5 añaden claves nuevas. **Regla**: añadir SIEMPRE al final del JSON, justo antes del `}` final. El coordinador regenera l10n en Wave 3.
- **`lib/data/mock/mock_data_service.dart`**: solo A4 lo toca; A2 NO.
- **`lib/features/home/tabs/home_tab.dart`**: NO se toca en Wave 1. Wave 2 (A6) lo modifica con todas las integraciones acumuladas.

---

## WAVE 1 — Briefs (despachar en paralelo)

### A1 — Theming + tipografía + personalización (el más cargado)

```text
ROL: Engineer Flutter senior, especialista en theming, design tokens y a11y.

CONTEXTO DEL PROYECTO: <pegar bloque "Contexto global">

PROBLEMAS REPORTADOS POR EL USUARIO:
- "El modo claro no cambia el color del mapa."
- "En personalización las paletas no cambian nada el estilo de mapa tampoco
  el brillo si va, el apartado de fondo tampoco funciona correctamente."
- "El de tamaño de texto hace que la app se cierre."
- "El de fuente para dislexia no va."
- "El modo de daltonismo si va pero el desplegable es un poco feo."
- "El modo contraste no hace nada."

ANÁLISIS PREVIO (estado actual confirmado):

A. MAPA CLARO/OSCURO:
   - lib/features/map/transit_map.dart líneas 248-251: TileLayer.urlTemplate
     usa `widget.mapStyle ?? (widget.isDark ? 'dark' : 'light')`.
   - lib/features/home/tabs/map_tab.dart línea ~322: `TransitMap(isDark: isDark, ...)`
     se construye SIN parámetro `mapStyle` y SIN key. Cuando cambias el tema en
     vivo, isDark cambia pero flutter_map cachea las tiles. La URL nueva no se
     aplica porque el TileLayer no se reconstruye.

B. PALETAS:
   - lib/shared/providers/theme_notifier.dart líneas 103-109: el setter
     `paletteId` actualiza _paletteId y notifica. Pero `buildTheme(Brightness)`
     en líneas 240-253 NO consulta la paleta seleccionada; usa los colores
     base de TransitColorScheme directamente.
   - Resultado: cambiar paleta persiste el ID pero no afecta el ThemeData.

C. ESTILO DE MAPA (MapStyleSection):
   - lib/shared/providers/theme_notifier.dart líneas 174-179: setter mapStyle
     actualiza _mapStyle y notifica.
   - map_tab.dart NO pasa themeNotifier.mapStyle a TransitMap. El TransitMap
     siempre usa el fallback (dark/light).

D. FONDO (BackgroundSelector):
   - lib/features/appearance/widgets/background_selector.dart líneas 18-27:
     lista IDs ['none', 'shaders/smoke.frag', 'assets/bg/soft_grid.png',
     'assets/bg/topo_lines.png'].
   - lib/core/theme/backgrounds/prefab_backgrounds.dart líneas 5-11: solo
     registra NoneBackground, ShaderBackground('shaders/smoke.frag'),
     GradientBackground.
   - Resultado: opciones soft_grid y topo_lines no se renderizan; quedan en
     "none" silenciosamente.

E. FONT SCALE CRASH:
   - lib/features/appearance/widgets/font_section.dart líneas 56-66: Slider
     min 0.85, max 1.4, divisions 11.
   - lib/app.dart líneas 49-65: combina systemScale * fontScale, clamp [0.8, 2.5].
   - El crash probable es: si `MediaQuery.textScalerOf(context).scale(1.0)`
     devuelve NaN o un valor extremo, el clamp con (0.8, 2.5) puede no
     prevenir un RangeError en TextScaler.linear. Otra causa: alguna pantalla
     con `RenderFlex overflowed` no fatal acaba siendo fatal por algún
     ConstrainedBox down-the-line. Investigar el crash log si está disponible
     (Sentry está instalado).

F. DISLEXIA:
   - lib/core/theme/transit_theme.dart líneas 27-29: si dyslexiaFontEnabled,
     usa GoogleFonts.atkinsonHyperlegibleTextTheme(baseTextTheme).
   - Probable: el toggle alterna el bool pero el `buildTheme` no se reconstruye
     porque MaterialApp.theme/darkTheme no son `key`-dependientes del flag.

G. DROPDOWN DALTONISMO:
   - lib/features/appearance/widgets/accessibility_section.dart líneas 64-89:
     DropdownButton<ColorBlindMode> con 9 opciones, labels largos como
     "Deuteranomalía". El dropdown es pequeño y feo visualmente.

H. ALTO CONTRASTE:
   - lib/core/theme/high_contrast_theme.dart líneas 1-119: el método apply()
     copia el ThemeData pero NO cambia colores, contraste de texto, ni grosor
     de bordes. El usuario activa el toggle y no nota diferencia.

OBJETIVO:
Hacer que cada toggle/control de Apariencia + Accesibilidad tenga efecto visible
y consistente en TODA la app.

ARCHIVOS PERMITIDOS:
- lib/shared/providers/theme_notifier.dart
- lib/core/theme/transit_theme.dart
- lib/core/theme/high_contrast_theme.dart
- lib/core/theme/backgrounds/prefab_backgrounds.dart
- lib/features/appearance/widgets/palette_section.dart
- lib/features/appearance/widgets/map_style_section.dart
- lib/features/appearance/widgets/background_selector.dart
- lib/features/appearance/widgets/font_section.dart
- lib/features/appearance/widgets/accessibility_section.dart
- lib/app.dart
- lib/features/home/tabs/map_tab.dart  ← SOLO modifica la construcción
  `TransitMap(...)` para añadir `mapStyle:` y `key:`. NO toques otras zonas.
- lib/l10n/app_es.arb, app_en.arb, app_ar.arb (añadir claves al FINAL del JSON)

ARCHIVOS PROHIBIDOS:
- transit_map.dart (es de A2)
- route_direction_arrows.dart (es de A2)
- home_tab.dart (es de A6 en Wave 2)
- accessible_buses_screen.dart / nearby_buses_screen.dart (es de A5)

TAREAS CONCRETAS:

T1. Mapa cambia color con tema/estilo
   - En map_tab.dart, lee `ref.watch(themeNotifierProvider).mapStyle` y
     `themeMode`. Pasa a TransitMap:
       TransitMap(
         key: ValueKey('${isDark ? "d" : "l"}-$mapStyle'),
         isDark: isDark,
         mapStyle: mapStyle,
         ...
       )
   - El key fuerza al TileLayer a reconstruirse cuando cambia el tema o el
     estilo, refrescando la URL de tiles.

T2. Paletas aplican al ThemeData
   - En theme_notifier.dart, modifica buildTheme(Brightness b) para que use
     la paleta seleccionada:
       final palette = paletteFromId(_paletteId);
       final scheme = b == Brightness.dark
           ? palette.darkScheme ?? TransitDarkColors()
           : palette.lightScheme ?? TransitLightColors();
   - Si paletteFromId no existe o no expone darkScheme/lightScheme, crea
     una API mínima en lib/core/theme/palettes.dart (NUEVO si lo necesitas)
     o extiende la existente. Documenta tu decisión.
   - El método buildTheme debe pasar `scheme` a `buildTransitTheme(c: scheme)`
     en transit_theme.dart.

T3. Estilo de mapa funciona
   - Cubierto por T1 (map_tab.dart ya pasa mapStyle).
   - Verifica que MapConfig.mapStyles mapea los 5 estilos a slugs MapTiler
     válidos (streets/basic/bright/dark/light).

T4. Fondo coherente entre UI y prefabs
   - En prefab_backgrounds.dart, AÑADE las opciones que faltan:
       ImageBackground('assets/bg/soft_grid.png')
       ImageBackground('assets/bg/topo_lines.png')
     (si el modelo ImageBackground no existe, créalo siguiendo el patrón de
     NoneBackground/GradientBackground; debe poder cargarse vía Image.asset
     y NO requiere conexión).
   - Si los PNGs no existen en assets/, créalos como gradient generativo en
     el código (es más simple que añadir binarios). Documenta tu decisión.
   - Verifica que `backgroundFromId(id)` devuelve la implementación correcta
     para cada ID listado en background_selector.dart.

T5. Font scale no crashea
   - En theme_notifier.dart, añade clamp en el setter:
       set fontScale(double v) {
         _fontScale = v.clamp(0.85, 1.4);
         _persist();
         notifyListeners();
       }
   - En app.dart línea 52-53, hardenea el cálculo:
       final rawSystem = MediaQuery.textScalerOf(context).scale(1.0);
       final systemScale = rawSystem.isFinite && rawSystem > 0 ? rawSystem : 1.0;
       final combined = (systemScale * themeNotifier.fontScale).clamp(0.8, 2.5);
   - Si el crash persiste, busca pantallas con RenderFlex overflowed y
     envuélvelas con `Flexible` o `Expanded` donde proceda.
   - DOCUMENTA en tu reporte si encontraste el RangeError exacto en el stack
     trace (Sentry o `flutter run` con verbose).

T6. Dislexia aplica de verdad
   - El problema es que MaterialApp.theme/darkTheme se calcula UNA VEZ en el
     build. Cuando dyslexiaFontEnabled cambia, themeNotifier notifica pero
     `theme:` y `darkTheme:` se recalculan correctamente porque están
     dentro del build de ConsumerWidget que escucha themeNotifierProvider.
   - Verifica que en app.dart, `themeNotifier.buildTheme(b)` se llama dentro
     del build (sí lo está). Si NO funciona, comprueba que en
     transit_theme.dart las líneas 27-29 realmente reciben el bool actualizado.
   - Si tras T2 el bug persiste, fuerza un `key:` en MaterialApp.router con
     un valor derivado: `key: ValueKey('${dyslexia}-${highContrast}-${paletteId}')`.

T7. Dropdown daltonismo más bonito
   - Reemplaza el DropdownButton<ColorBlindMode> por un BottomSheet selector
     con título "Modo daltonismo" y 9 opciones tipo radio list.
     - Disparador: GestureDetector(child: Container(...)) que muestre el modo
       actual + chevron.
     - Al pulsar: showModalBottomSheet con ListView de RadioListTile (estilo
       Material) usando tokens del design system.
   - Asegura que el texto de cada opción no se trunca y respeta el theme.

T8. Alto contraste con efecto perceptible
   - Reescribe HighContrastTheme.apply para que:
       - bgRoot/bgSurface/bgRaised → opacos 100%, sin glass.
       - border → grosor 2 px en bordes claves.
       - textHi → Color blanco puro (#FFFFFF) en dark, negro puro (#000000) en light.
       - accent → más saturado.
       - cardTheme/inputDecorationTheme → bordes 2 px visibles.
   - Aplícalo dentro de buildTheme cuando highContrast == true (línea 249-251).
   - El usuario debe notar IMMEDIATAMENTE la diferencia al activar el toggle.

T9. Claves de l10n
   - Añade al FINAL de los 3 .arb (sin tocar otras claves):
       "appearanceColorBlindSheetTitle": "Modo daltonismo" / "Color blindness mode" / "وضع عمى الألوان"
   - NO ejecutes flutter gen-l10n.

CONSTRAINTS DUROS:
- NO toques transit_map.dart (es de A2).
- NO toques route_direction_arrows.dart (es de A2).
- NO toques home_tab.dart (es de A6).
- NO toques accessible_buses/ ni nearby_buses/ (es de A5).
- En map_tab.dart, SOLO toca la construcción de TransitMap(...) para añadir
  parámetros y key. NO toques nada más de map_tab.dart.

VERIFICACIÓN:
- `flutter analyze` → 0 warnings.
- `flutter test` → verde.
- Smoke manual: cambia el modo a Claro → el mapa pasa de tiles oscuros a claros
  en < 1s. Cambia paleta → toda la app cambia accent. Cambia mapStyle → tiles
  cambian al estilo elegido. Activa fuente dislexia → tipografía cambia en
  todas las pantallas. Cambia font scale → no crashea. Activa alto contraste
  → bordes y textos saltan a máxima legibilidad.

COMMIT(s) sugerido(s):
- fix(theme): mapa reacciona a cambios de tema y estilo via key+mapStyle
- fix(theme): paletas afectan al ThemeData global
- feat(theme): backgrounds y dislexia aplicados correctamente
- fix(a11y): font scale clamp + alto contraste con efecto + dropdown a bottom sheet

REPORTE FINAL:
- Confirma T1-T9.
- Diagnóstico del crash de fontScale (si encontraste stacktrace, pégalo).
- Listado de archivos modificados.
- Claves arb añadidas.
```

---

### A2 — Mapa: flechas direccionales + buses fantasma

```text
ROL: Engineer Flutter, especialista en flutter_map y datos mock.

CONTEXTO DEL PROYECTO: <pegar bloque "Contexto global">

PROBLEMAS REPORTADOS POR EL USUARIO:
- "Las líneas L5 L1 L3 se ven permanentemente y aparecen buses en movimiento
  que no existen."
- "Las líneas de dirección aparecen aleatoriamente y no en todas las líneas
  quiero que aparezcan exclusivamente en las líneas cada cierta distancia y
  que aparezcan al hacer click en la ruta."

DECISIONES TOMADAS CON EL USUARIO:
- Buses fantasma: eliminar trips fijos del JSON. Que el realtime service
  no genere trips por defecto. La app arranca con la flota vacía hasta que
  el realtime service simule alguno (si simula).
- Flechas direccionales: solo en la línea seleccionada, distancia uniforme.

ANÁLISIS PREVIO:

A. FLECHAS:
   - lib/features/map/layers/route_direction_arrows.dart líneas 1-69.
     La función build recibe `routeIds` y dibuja flechas en TODAS las rutas
     pasadas. La separación uniforme falla: línea 39 reinicia accumulated a 0
     tras cada flecha, pero el primer segmento siempre dibuja (`i == 0`),
     causando flechas no uniformes al principio.
   - lib/features/map/transit_map.dart líneas 134-164: _buildDirectionArrows
     calcula visibleIds incluyendo TODAS las rutas visibles (line 152), no
     solo la seleccionada. El usuario quiere SOLO la seleccionada.

B. BUSES FANTASMA:
   - assets/mock/comujesa_data.json líneas ~57670-57753: hay 4 trips activos
     fijos:
       trip-001 → lineCode L1, status inRoute
       trip-002 → lineCode L3, status inRoute (5 min retraso)
       trip-003 → lineCode L5, status inRoute
       trip-004 → lineCode L8, status cancelled
   - lib/data/mock/mock_realtime_service.dart línea 34: carga
     `_currentTrips = List.from(_mockData.activeTrips)`.
   - Resultado: L1/L3/L5 tienen polylines remarcadas (las activas tienen
     opacity 0.6 en route_polylines.dart, vs 0.15 las inactivas). Por eso
     parecen "permanentes". Y los buses (markers) aparecen mientras una
     ruta esté seleccionada y tenga trip activo.

OBJETIVO:
1. Flechas solo en la línea seleccionada por el usuario, repartidas con
   separación uniforme cada N metros, INDEPENDIENTEMENTE de la geometría.
2. Eliminar los 4 trips hardcoded del JSON. La flota arranca vacía.

ARCHIVOS PERMITIDOS:
- lib/features/map/layers/route_direction_arrows.dart
- lib/features/map/transit_map.dart  ← SOLO la función _buildDirectionArrows
  (líneas 134-164). NO toques otras zonas.
- lib/data/mock/mock_realtime_service.dart  ← si necesitas ajustar el
  comportamiento al haber 0 trips iniciales (debe seguir funcionando sin
  crashear y emitir lista vacía).
- assets/mock/comujesa_data.json  ← SOLO el array `activeTrips`. NO toques
  `lines`, `stops`, `alerts` ni otros arrays (son de otros agentes o
  permanecen intactos).

ARCHIVOS PROHIBIDOS:
- map_tab.dart (es de A1)
- mock_data_service.dart (es de A4)
- cualquier otro fuera de la tabla.

TAREAS CONCRETAS:

T1. Flechas con distancia uniforme real
   - Reescribe route_direction_arrows.dart para usar interpolación a lo
     largo del polyline:
       1. Calcula la longitud total del polyline acumulando segmentos.
       2. Determina cuántas flechas N caben: floor(total / spacingMeters),
          cap a maxArrows.
       3. Para cada k en [1..N], encuentra la posición a `k * spacingMeters`
          metros desde el inicio (interpolación lineal entre dos puntos
          consecutivos cuya distancia acumulada cruza ese umbral).
       4. Calcula el ángulo del segmento donde cae la flecha.
       5. Crea un Marker con Transform.rotate.
   - Esto garantiza separación uniforme, sin "saltos" en segmentos largos.
   - Mantén `spacingMeters = 400.0`, `maxArrows = 50`, `minZoom = 14`.

T2. Flechas solo en línea seleccionada
   - En transit_map.dart líneas 134-164, cambia _buildDirectionArrows:
       List<MarkerLayer> _buildDirectionArrows(TransitColorScheme c) {
         final selectedId = widget.selectedRouteId;
         if (selectedId == null) return [];
         final zoom = _currentZoom.round();
         if (zoom < 14) return [];

         final arrows = RouteDirectionArrows.build(
           routePathsLod: widget.routePathsLod,
           routeIds: [selectedId],
           zoom: zoom,
           color: c.accent.withValues(alpha: 0.85),
         );

         if (arrows.isEmpty) return [];
         return [MarkerLayer(markers: arrows)];
       }
   - Sustituye la llamada en línea 263: `..._buildDirectionArrows(c)`
     (sin pasar activeRouteIds).

T3. Eliminar trips hardcoded del JSON
   - En assets/mock/comujesa_data.json, localiza el array `activeTrips`:
       "activeTrips": [
         { "id": "trip-001", ... },
         { "id": "trip-002", ... },
         { "id": "trip-003", ... },
         { "id": "trip-004", ... }
       ]
   - Cámbialo a:
       "activeTrips": []
   - Cuida no romper el JSON (comas, llaves). Verifica con `python -m json.tool`
     o similar tras editar.

T4. Ajustar mock_realtime_service si rompe con flota vacía
   - Lee mock_realtime_service.dart y comprueba que init() y _tick() no asumen
     que activeTrips tenga al menos un elemento. Si hay assert o index access
     que crashearía, hardenéalo con if (currentTrips.isEmpty) return; en _tick.
   - El stream debe emitir [] inicialmente y seguir emitiendo [] cada 15s
     hasta que (en el futuro) el service genere trips sintéticos.

CONSTRAINTS DUROS:
- NO toques map_tab.dart ni nada fuera de transit_map.dart líneas 134-164.
- NO toques mock_data_service.dart (es de A4).
- NO toques otros arrays del JSON (alerts, lines, stops, schedules, etc.).

VERIFICACIÓN:
- `flutter analyze`
- `flutter test` (si hay tests del realtime service, deben seguir verdes).
- Smoke manual: abre el mapa → no aparecen buses sobre L1/L3/L5; las
  polylines no tienen opacity más alta sobre esas líneas. Selecciona una
  línea → ves flechas direccionales repartidas cada ~400m sobre el polyline,
  uniformes. Cambia a otra línea → flechas se reposicionan a la nueva.

COMMIT(s) sugerido(s):
- fix(map): flechas direccionales con distancia uniforme y solo en línea seleccionada
- chore(mock): eliminar trips activos hardcoded de comujesa_data.json

REPORTE FINAL:
- Algoritmo de interpolación implementado (snippet o pseudocódigo).
- Confirmación de cambios en transit_map.dart y JSON.
- Test que validaste manualmente con la app.
```

---

### A3 — Buscador: chip "Usar mi ubicación" más pequeño

```text
ROL: Engineer Flutter de UI, especialista en spacing y tokens.

CONTEXTO DEL PROYECTO: <pegar bloque "Contexto global">

PROBLEMA REPORTADO POR EL USUARIO:
"En buscar quiero que el botón de usar mi ubicación sea más pequeño ya que
es molesto que ocupe tanto de la parte superior."

ANÁLISIS PREVIO:
- lib/shared/widgets/route_search_bar.dart líneas 276-346: método
  _buildLocationChip().
- Padding actual: horizontal 12dp, vertical 8dp. Icono 18dp. Spacing 8dp.
  Border radius 20dp. Texto bodySecondary.
- Altura total ≈ 34dp. Toma ancho completo + padding => visualmente prominente.

OBJETIVO:
Reducir el tamaño del chip "Usar mi ubicación" a algo más discreto pero
todavía táctil (≥36×36 touch target via inkwell expandido si es necesario,
manteniendo el visible más pequeño).

ARCHIVOS PERMITIDOS:
- lib/shared/widgets/route_search_bar.dart  ← SOLO el método
  _buildLocationChip() y, si necesario, su llamada. NO toques los TextField
  "Desde..." / "Hasta..." ni otros widgets.

ARCHIVOS PROHIBIDOS: cualquier otro.

TAREAS CONCRETAS:

T1. Reducir visualmente el chip
   - Reemplaza el contenido de _buildLocationChip por algo más sutil:
       - Padding: EdgeInsets.symmetric(horizontal: TransitSpacing.space8,
         vertical: TransitSpacing.space4) (= 8/4).
       - Icon size: 14 (en lugar de 18).
       - SizedBox width: TransitSpacing.space4 (= 4).
       - Text con TransitTypography.bodySmall (en lugar de bodySecondary).
       - Border radius: TransitSpacing.radiusM (= 12) en lugar de 20.
   - Color del fondo: c.bgRaised.withValues(alpha: 0.6) con borde 0.5px
     c.border; al estar `_useMyLocation == true`, fondo c.accent.withValues(
     alpha: 0.15) y borde c.accent.

T2. Mantener touch target ≥ 36dp
   - Envuelve el chip en un InkResponse con containedInkWell + radius
     extendido para que el área táctil siga siendo cómoda aunque el
     visible sea más pequeño.

T3. Alineación
   - Asegura que el chip se renderiza alineado a la izquierda, no centrado;
     si está dentro de un Row, ya debería estarlo. Si actualmente está
     centrado u ocupa todo el ancho, cambia a `mainAxisSize: MainAxisSize.min`.

CONSTRAINTS DUROS:
- NO toques nada fuera de _buildLocationChip.
- Usa siempre TransitSpacing tokens (NO números mágicos).

VERIFICACIÓN:
- `flutter analyze`
- Smoke manual: pestaña Search → el chip "Usar mi ubicación" se ve
  pequeño/discreto, alineado a la izquierda, no domina la parte superior.
  Al pulsarlo, sigue cambiando el estado del campo "Desde".

COMMIT al final:
fix(search): chip "Usar mi ubicación" más discreto

REPORTE FINAL:
- Snippet del nuevo _buildLocationChip.
- Antes/después aproximado (altura y padding).
```

---

### A4 — Avisos georeferenciados

```text
ROL: Engineer Flutter senior, especialista en modelos de datos y providers.

CONTEXTO DEL PROYECTO: <pegar bloque "Contexto global">

PROBLEMA REPORTADO POR EL USUARIO:
"Los avisos no funcionan como dije los avisos solo tienen que ir en zonas
marcadas en un radio."

DECISIÓN TOMADA CON EL USUARIO:
Avisos georeferenciados con lat/lng/radiusMeters. Solo se muestran si la
ubicación del usuario está dentro del radio, o si la ruta favorita tiene
parte de su recorrido dentro del radio (lo más simple y útil).

ANÁLISIS PREVIO:
- lib/shared/models/alert_model.dart líneas 1-46: el modelo AlertModel tiene
  `id`, `operatorId`, `routeId`, `severity`, `title`, `body`, `activeFrom`,
  `activeUntil`. NO tiene lat/lng/radiusMeters.
- lib/data/mock/mock_data_service.dart líneas 413-414:
    List<AlertModel> getAlertsForRoute(String routeId) =>
        alerts.where((a) => a.routeId == routeId).toList();
  Sin filtro geográfico.
- lib/shared/providers/derived/home_providers.dart líneas 54-62:
    homeFavAlertsProvider combina favoritas con getAlertsForRoute. Muestra
    TODAS las alertas de las líneas favoritas indiscriminadamente.
- lib/features/home/widgets/home_alert_item.dart: muestra title + body, sin
  contexto de zona.
- assets/mock/comujesa_data.json contiene un array `alerts` (busca exactamente
  dónde y qué campos tiene).

OBJETIVO:
1. Añadir lat/lng/radiusMeters al modelo y al JSON.
2. Filtrar el provider para mostrar solo alertas cuya zona afecta al usuario.
3. Mostrar en el item de aviso la información de zona ("Afecta a 800m de
   Plaza del Arenal" o similar).

ARCHIVOS PERMITIDOS:
- lib/shared/models/alert_model.dart
- lib/data/mock/mock_data_service.dart (extender método o crear nuevo)
- lib/shared/providers/derived/home_providers.dart
- lib/features/home/widgets/home_alert_item.dart
- assets/mock/comujesa_data.json  ← SOLO el array `alerts`. NO toques
  `activeTrips` (es de A2) ni otros arrays.

ARCHIVOS PROHIBIDOS:
- home_tab.dart (es de A6 en Wave 2)
- nada más.

TAREAS CONCRETAS:

T1. Extender AlertModel
   - Añade campos opcionales:
       final double? lat;
       final double? lng;
       final double? radiusMeters;  // null = sin restricción geográfica
   - Actualiza el constructor y fromJson para mapear los nuevos campos.
   - Mantén compat: si el JSON no incluye lat/lng/radiusMeters, los campos
     quedan null y la alerta se comporta como sin restricción (legacy).

T2. Filtro geográfico en MockDataService
   - Añade:
       List<AlertModel> getAlertsAffecting({
         LatLng? userLocation,
         List<String> favoriteRouteIds = const [],
         List<String>? routeStopIds,  // opcional: paradas de rutas favoritas
       }) {
         return alerts.where((a) {
           // 1) sin restricción → mostrar siempre
           if (a.lat == null || a.lng == null || a.radiusMeters == null) {
             // mantén el comportamiento legacy: filtra por routeId si es
             // favorita
             return favoriteRouteIds.contains(a.routeId);
           }
           // 2) con restricción → ver si usuario está dentro
           if (userLocation != null) {
             final d = const Distance().as(LengthUnit.Meter,
                 userLocation, LatLng(a.lat!, a.lng!));
             if (d <= a.radiusMeters!) return true;
           }
           // 3) o si alguna parada de ruta favorita está dentro
           if (routeStopIds != null) {
             for (final stopId in routeStopIds) {
               final stop = stops.firstWhereOrNull((s) => s.id == stopId);
               if (stop == null) continue;
               final d = const Distance().as(LengthUnit.Meter,
                   LatLng(stop.lat, stop.lng), LatLng(a.lat!, a.lng!));
               if (d <= a.radiusMeters!) return true;
             }
           }
           return false;
         }).toList();
       }

T3. Actualizar provider
   - En home_providers.dart, reescribe homeFavAlertsProvider para usar
     getAlertsAffecting con:
       - userLocation: lee userLocationStreamProvider.valueOrNull
       - favoriteRouteIds: igual que ahora
       - routeStopIds: agrega todos los stop.ids de cada ruta favorita
         usando mockData.getStopsForRoute(routeId).

T4. UI mejorada en HomeAlertItem
   - Si la alerta tiene lat/lng/radius, muestra debajo del body:
       Row(
         children: [
           Icon(Icons.location_on, size: 12, color: c.textMid),
           SizedBox(width: 4),
           Text("${radiusMeters.toInt()}m alrededor de zona",
                style: TransitTypography.bodySmall(c.textMid)),
         ],
       )
   - Si no hay zona, no muestres ese Row (compat legacy).

T5. Datos mock en JSON
   - Añade lat/lng/radiusMeters a CADA alerta del array `alerts` del JSON.
     Usa coordenadas realistas dentro del bbox de Jerez:
       - Lat: entre 36.65 y 36.71
       - Lng: entre -6.15 y -6.10
     - radiusMeters entre 200 y 1500 según severidad.
   - Si hay 5 alertas, asegúrate de que al menos 2 cubran zonas céntricas
     (Plaza del Arenal aprox 36.6852, -6.1366) y otras 3 zonas distintas.

CONSTRAINTS DUROS:
- NO toques activeTrips del JSON (es de A2).
- NO toques home_tab.dart (es de A6).
- Mantén compat legacy: alertas sin lat/lng siguen funcionando.

VERIFICACIÓN:
- `flutter analyze`
- `flutter test` (añade test que verifique getAlertsAffecting con casos:
  alerta sin restricción + favorita = se muestra; alerta con restricción
  fuera del radio = no se muestra; dentro del radio = se muestra).
- Smoke manual: en home, con GPS apagado, las alertas no relevantes
  desaparecen. Activa GPS cerca del centro → la alerta de "Plaza del Arenal"
  aparece con su nota de zona.

COMMIT(s) sugerido(s):
- feat(alerts): modelo geo-referenciado + filtrado por proximidad
- chore(mock): añadir lat/lng/radiusMeters a alertas mock

REPORTE FINAL:
- Esquema actualizado de AlertModel.
- Listado de las N alertas con sus nuevas coordenadas.
- Test añadido.
```

---

### A5 — Pantalla "Buses cercanos" renombrada + filtrado por GPS + overflow

```text
ROL: Engineer Flutter, refactor de features.

CONTEXTO DEL PROYECTO: <pegar bloque "Contexto global">

PROBLEMAS REPORTADOS POR EL USUARIO:
- "En el apartado de accesibilidad (que no se porque se llama asi) en la
  lista de buses en buses cercanos (que tampoco están ni cerca) aparecen
  los buses antes mencionados que no existen) aparece un overflow en el
  botón."

DECISIÓN TOMADA CON EL USUARIO:
- Renombrar archivo/feature a "nearby_buses" (sin etiqueta de accesibilidad).
- Cambiar etiqueta en home a "BUSES CERCANOS" (eso lo hará A6 en Wave 2 —
  tú solo cambias el archivo, la ruta del router y las claves arb).
- Filtrar buses por distancia real (≤5 km del usuario o parada de referencia).
- Arreglar el RenderFlex overflowed.

ANÁLISIS PREVIO:
- Archivo actual: lib/features/accessible_buses/accessible_buses_screen.dart
  - línea 106: TransitAppBar(title: l10n.accessibleBusesTitle).
  - clave arb "accessibleBusesTitle": "Buses cercanos".
  - líneas 47-51: filtra trips por status != cancelled/completed. Sin
    filtro de distancia.
  - línea 206-223: el trailing ListTile tiene ConstrainedBox(maxWidth: 80) +
    Column. El RenderFlex overflowed proviene de un Row con Text largo (nombre
    de la ruta) sin Expanded/Flexible alrededor.
- Ruta del router: probablemente `/accessible-buses`. Busca en app_router.dart.

OBJETIVO:
1. Renombrar carpeta y archivo a `nearby_buses/nearby_buses_screen.dart`
   con clase `NearbyBusesScreen`.
2. Renombrar ruta del router a `/nearby-buses`.
3. Renombrar claves arb (accessibleBusesTitle → nearbyBusesTitle) y añadir
   nuevas claves para filtros/UX.
4. Filtrar trips por proximidad (distancia ≤ 5 km).
5. Arreglar el RenderFlex overflowed.

NOTA SOBRE A2: Si A2 elimina los trips fijos del JSON (sí lo hará), esta
pantalla mostrará lista vacía la mayoría del tiempo. Eso está bien —
mostrar empty state "No hay buses cerca ahora mismo".

ARCHIVOS PERMITIDOS:
- lib/features/accessible_buses/ → renombrar a lib/features/nearby_buses/
- lib/features/accessible_buses/accessible_buses_screen.dart → renombrar a
  lib/features/nearby_buses/nearby_buses_screen.dart
- lib/core/router/app_router.dart (cambiar ruta y referencia)
- lib/l10n/app_es.arb, app_en.arb, app_ar.arb (renombrar/añadir claves al
  FINAL del JSON)

ARCHIVOS PROHIBIDOS:
- home_tab.dart (es de A6 — A6 cambiará la etiqueta del menú en Wave 2)
- mock_data_service.dart (es de A4)
- nada más fuera de la tabla.

TAREAS CONCRETAS:

T1. Renombrar carpeta y archivo
   - `git mv lib/features/accessible_buses lib/features/nearby_buses`
   - `git mv lib/features/nearby_buses/accessible_buses_screen.dart
            lib/features/nearby_buses/nearby_buses_screen.dart`
   - En el archivo: renombrar la clase `AccessibleBusesScreen` a
     `NearbyBusesScreen`. Cambiar imports en el router.

T2. Filtrado por proximidad
   - El widget pasa a ConsumerWidget (si no lo es ya).
   - Lee `final userLoc = ref.watch(userLocationStreamProvider).valueOrNull;`
   - Lee `final refStop = ref.watch(homeReferenceStopProvider);` (debe existir
     tras Wave 1 v1; si no existe, usa null y cae a centro de Jerez como
     último fallback).
   - center =
       userLoc ?? (refStop != null ? LatLng(refStop.lat, refStop.lng) : MapConfig.defaultCenter)
   - Filtra trips:
       final filtered = trips.where((t) {
         final route = mockData.getRouteById(t.routeId);
         if (route == null) return false;
         final stops = mockData.getStopsForRoute(route.id);
         if (stops.isEmpty) return false;
         final pos = LatLng(t.currentLat ?? stops.first.lat,
                            t.currentLng ?? stops.first.lng);
         final d = const Distance().as(LengthUnit.Meter, center, pos);
         return d <= 5000;
       }).toList();
   - Si no encuentras campos currentLat/currentLng en ActiveTripModel, usa
     la primera parada de la ruta.

T3. Empty state
   - Si filtered.isEmpty, muestra EmptyState con:
     - icono: Icons.directions_bus_outlined
     - title: l10n.nearbyBusesEmptyTitle ("No hay buses cerca")
     - subtitle: l10n.nearbyBusesEmptySubtitle ("Activa la ubicación para
       ver los buses operando cerca de ti.")
     - actionLabel: "Activar GPS" si no hay permiso (Geolocator.openLocationSettings)

T4. Arreglar overflow del ListTile
   - En el ListTile/Row del trailing (líneas 206-223 del original):
     - Envuelve el `Text` del título (route name) en `Expanded` o `Flexible`.
     - Asegura maxLines:1 + overflow:TextOverflow.ellipsis.
     - El trailing con ConstrainedBox(maxWidth: 80) está bien si el contenido
       interno tampoco overflowea — verifica el `Text` de minutos: si es
       "120 min retraso" puede ser largo. Usa FittedBox(fit: BoxFit.scaleDown).

T5. Router
   - En app_router.dart, cambia:
       path: '/accessible-buses' → '/nearby-buses'
       builder: ... AccessibleBusesScreen() → NearbyBusesScreen()

T6. l10n
   - Renombra clave en los 3 .arb: `accessibleBusesTitle` → `nearbyBusesTitle`
     (manteniendo valor "Buses cercanos" / "Nearby buses" / "حافلات قريبة").
   - Añade claves nuevas al FINAL del JSON:
       "nearbyBusesEmptyTitle": "No hay buses cerca" / "No nearby buses" / "..."
       "nearbyBusesEmptySubtitle": "Activa la ubicación para ver los buses
         operando cerca de ti." / ... / "..."
   - Si la clave `accessibleBusesTitle` está usada en otros sitios (busca
     usages), añade alias temporal o documenta dónde más hay que cambiar
     (en tu reporte). A6 puede limpiar.

CONSTRAINTS DUROS:
- NO toques home_tab.dart (es de A6 — A6 cambiará el menú).
- Mantén el comportamiento de la pantalla salvo filtros y overflow.

VERIFICACIÓN:
- `flutter analyze`
- `flutter test` (si hay tests específicos de accessible_buses, renómbralos
  también y verifica que pasan).
- Smoke manual: navega a la pantalla (desde el menú del home tras integración
  de A6, o directamente con `context.push('/nearby-buses')` en debug).
  Verifica:
    - Título dice "Buses cercanos" (no "Accesibilidad").
    - Sin trips activos (tras A2), aparece empty state.
    - Si hay trips dentro de 5 km, aparecen. Si están más lejos, no.

COMMIT(s) sugerido(s):
- refactor(nearby): renombrar accessible_buses a nearby_buses
- feat(nearby): filtrar buses por proximidad y empty state
- fix(nearby): RenderFlex overflowed en ListTile

REPORTE FINAL:
- Confirma renames hechos vía git mv.
- Lista de cambios en router y arb.
- Pendiente para A6: cambiar etiqueta en home_tab.dart.
```

---

## WAVE 2 — Briefs (despachar tras integración de Wave 1)

### A6 — Integración en home_tab.dart

```text
ROL: Engineer Flutter, integrador de cambios cross-feature.

CONTEXTO DEL PROYECTO: <pegar bloque "Contexto global">

DEPENDENCIAS:
- A4 ya hizo que homeFavAlertsProvider filtre por geo. No tienes que cambiar
  el provider; solo el render del item respeta esa lógica.
- A5 ya renombró la pantalla a NearbyBusesScreen con ruta /nearby-buses.
  Aquí cambias la etiqueta del menú y la navegación.

OBJETIVO:
1. Cambiar la etiqueta del menú en home_tab.dart que decía "ACCESIBILIDAD"
   (línea 303-304 aproximadamente) por "BUSES CERCANOS".
2. Asegurar que el navigation lleva a `/nearby-buses` (no `/accessible-buses`).
3. Verificar que las alertas mostradas son las del provider actualizado por A4
   (si A4 cambió la API o el shape, ajustar).

ARCHIVOS PERMITIDOS:
- lib/features/home/tabs/home_tab.dart

ARCHIVOS PROHIBIDOS: cualquier otro.

TAREAS CONCRETAS:

T1. Etiqueta y navegación del menú "buses cercanos"
   - Localiza la sección donde se renderiza el botón/menú "ACCESIBILIDAD"
     (línea ~303-304: usa `l10n.profileSectionAccessibility`).
   - Cámbiala por una nueva clave l10n.homeNearbyBusesSection ("BUSES
     CERCANOS"). Si no existe, añádela al final de los 3 .arb (es/en/ar).
   - Cambia el onTap para navegar a `/nearby-buses`.

T2. Render de alertas
   - Localiza dónde se renderiza la sección de avisos (línea ~289-299).
   - El homeFavAlertsProvider tras Wave 1 ya devuelve solo alertas que afectan
     al usuario. Tu trabajo es solo asegurar que HomeAlertItem se construye
     con los nuevos campos del modelo (lat/lng/radius) y muestra la info de
     zona si la tiene. Esto debería ser transparente si A4 ya ajustó
     HomeAlertItem. Verifica.

T3. Si A1 añadió cosas nuevas en la sección de "Tu próximo bus" o
   "Mis paradas" que requieren ajustes aquí, hazlos. Lee el resumen de A1
   en el reporte de Wave 1 (te lo pasará el coordinador).

CONSTRAINTS DUROS:
- NO toques cualquier otro archivo.

VERIFICACIÓN:
- `flutter analyze`
- Smoke manual: home → el menú dice "BUSES CERCANOS" no "ACCESIBILIDAD".
  Pulsar lleva a /nearby-buses. Si hay alertas, se ven correctamente.

COMMIT:
fix(home): etiqueta "Buses cercanos" + navegación + integración alertas geo

REPORTE FINAL: confirma T1-T3.
```

---

### A7 — Widgets nativos Android reales

```text
ROL: Engineer Android + Flutter, especialista en home_widget package y
AppWidgetProvider.

CONTEXTO DEL PROYECTO: <pegar bloque "Contexto global">

PROBLEMA REPORTADO POR EL USUARIO:
"Los widgets no aparecen en la app."

DECISIÓN TOMADA CON EL USUARIO:
Implementar widgets nativos Android reales: AppWidgetProvider en Kotlin,
registro en AndroidManifest, layouts XML, y cableado desde Dart con
home_widget package para actualizar datos en tiempo real.

ANÁLISIS PREVIO:
- pubspec.yaml línea 32: home_widget: ^0.7.0 ya instalado.
- lib/data/widgets_native/widget_data_writer.dart: tiene
  writeNextBus(routeCode, payload) y writeMyLineStatus(routeCode, payload)
  pero NUNCA se invocan desde el código de la app.
- lib/features/widgets_native/widgets_settings_screen.dart líneas 91-101:
  en release mode muestra "Coming Soon".
- AndroidManifest.xml NO registra ningún <receiver> para widgets.
- NO existe android/app/src/main/res/xml/widget_*.xml ni layouts.
- docs/HOME_WIDGETS.md decía "NOT implementing" — esa decisión se revierte
  con este plan.

OBJETIVO:
Crear dos widgets nativos Android funcionales:
  1. "Próximo bus" → muestra próxima salida de la parada favorita configurada.
  2. "Estado de mi línea" → muestra estado de servicio de la línea favorita
     configurada.

Los widgets se actualizan cada N minutos (15 por defecto del sistema) y
cuando la app escribe nuevos datos via WidgetDataWriter.

ARCHIVOS PERMITIDOS:
- android/app/src/main/AndroidManifest.xml
- android/app/src/main/kotlin/<package>/widgets/TransitlyNextBusWidget.kt (NUEVO)
- android/app/src/main/kotlin/<package>/widgets/TransitlyMyLineWidget.kt (NUEVO)
- android/app/src/main/res/xml/widget_next_bus_info.xml (NUEVO)
- android/app/src/main/res/xml/widget_my_line_info.xml (NUEVO)
- android/app/src/main/res/layout/widget_next_bus.xml (NUEVO)
- android/app/src/main/res/layout/widget_my_line.xml (NUEVO)
- android/app/src/main/res/drawable/widget_bg.xml (NUEVO si lo necesitas)
- lib/data/widgets_native/widget_data_writer.dart (cableado real con
  HomeWidget.saveWidgetData + HomeWidget.updateWidget).
- lib/shared/providers/widget_data_provider.dart (NUEVO)
- lib/features/widgets_native/widgets_settings_screen.dart (quitar el
  bloqueo de release, conectar provider).
- pubspec.yaml (NO debería ser necesario; home_widget ya está).

ARCHIVOS PROHIBIDOS: cualquier otro.

TAREAS CONCRETAS:

T1. AppWidgetProvider para "Próximo bus" (Kotlin)
   - Crea TransitlyNextBusWidget.kt:
       class TransitlyNextBusWidget : HomeWidgetProvider() {
         override fun onUpdate(context: Context, manager: AppWidgetManager,
             ids: IntArray, prefs: SharedPreferences) {
           ids.forEach { id ->
             val views = RemoteViews(context.packageName, R.layout.widget_next_bus)
             val routeCode = prefs.getString("widget_fav_line", "L1") ?: "L1"
             val nextBusJson = prefs.getString("next_bus_$routeCode", null)
             // parse JSON, fill views
             views.setTextViewText(R.id.widget_route_code, routeCode)
             views.setTextViewText(R.id.widget_next_time, parseTime(nextBusJson))
             // PendingIntent para abrir la app al pulsar
             val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                 context, MainActivity::class.java)
             views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
             manager.updateAppWidget(id, views)
           }
         }
       }
   - El package import es `es.antonyoung.home_widget.HomeWidgetProvider` (o
     similar; verifica la API del package home_widget 0.7.0 en su README).

T2. Layout XML del widget próximo bus
   - widget_next_bus.xml:
       <LinearLayout orientation="vertical" background="@drawable/widget_bg"
           padding="8dp">
         <TextView id="widget_route_code" textSize="20sp" textStyle="bold"/>
         <TextView id="widget_next_time" textSize="14sp"/>
         <TextView id="widget_stop_name" textSize="12sp"/>
       </LinearLayout>
   - widget_bg.xml en drawable: shape rounded #08081A con border.

T3. Metadata XML del widget
   - widget_next_bus_info.xml en res/xml/:
       <appwidget-provider
           minWidth="180dp" minHeight="80dp"
           updatePeriodMillis="900000"  <!-- 15 min -->
           initialLayout="@layout/widget_next_bus"
           previewImage="@mipmap/ic_launcher"
           resizeMode="horizontal|vertical"
           widgetCategory="home_screen"/>

T4. Repetir T1-T3 para TransitlyMyLineWidget (estado de línea).

T5. AndroidManifest
   - Dentro de <application>, añade dos <receiver>:
       <receiver android:name=".widgets.TransitlyNextBusWidget"
                 android:exported="true">
         <intent-filter>
           <action android:name="android.appwidget.action.APPWIDGET_UPDATE"/>
         </intent-filter>
         <meta-data
             android:name="android.appwidget.provider"
             android:resource="@xml/widget_next_bus_info"/>
       </receiver>
       <receiver android:name=".widgets.TransitlyMyLineWidget"
                 android:exported="true">
         ...
       </receiver>

T6. Dart: WidgetDataWriter cableado
   - Reescribe widget_data_writer.dart para usar HomeWidget package:
       class WidgetDataWriter {
         static Future<void> writeNextBus(String routeCode,
             Map<String, dynamic> payload) async {
           await HomeWidget.saveWidgetData('widget_fav_line', routeCode);
           await HomeWidget.saveWidgetData('next_bus_$routeCode',
               jsonEncode(payload));
           await HomeWidget.updateWidget(
               name: 'TransitlyNextBusWidget',
               androidName: 'TransitlyNextBusWidget');
         }
         static Future<void> writeMyLineStatus(...) async { ... }
       }
   - Verifica la API exacta de home_widget 0.7.0.

T7. Provider que llama al writer
   - Crea widget_data_provider.dart:
       Riverpod Provider que escucha mock_realtime + favoritos + estado del
       service, y cuando el "próximo bus" de la línea favorita cambia llama
       a WidgetDataWriter.writeNextBus(...). Mismo para myLineStatus.

T8. Settings screen
   - Quita el bloqueo de release en widgets_settings_screen.dart líneas
     91-101. Que muestre la UI siempre.

CONSTRAINTS DUROS:
- NO toques nada fuera de tu tabla de archivos.
- El receiver Android debe tener `android:exported="true"` para Android 12+
  (S = API 31) o build falla.
- Mantén compatibilidad con minSdk 21 (declarado en pubspec /
  app/build.gradle).

VERIFICACIÓN:
- `flutter analyze`
- Build debug: `flutter build apk --debug` debe pasar sin errores nativos.
- Smoke manual: instala el APK debug, configura widget en pantalla home de
  Android (long-press en escritorio → Widgets → Transitly), verifica que
  aparece y muestra "Próxima salida".
- Si no tienes dispositivo Android disponible, al menos confirma que la
  build debug compila y que el receiver aparece en `adb shell dumpsys
  appwidget` (en dev).

COMMIT(s):
- feat(widgets-android): native home widget for next bus
- feat(widgets-android): native home widget for line status
- feat(widgets): wire WidgetDataWriter to Riverpod providers

REPORTE FINAL:
- Confirma cada T1-T8.
- Si encontraste limitaciones del package home_widget 0.7.0 que requieren
  workarounds, documéntalas.
- Si la build debug pasa, conform.
```

---

### A8 — Region download offline con FMTC

```text
ROL: Engineer Flutter senior, especialista en flutter_map_tile_caching.

CONTEXTO DEL PROYECTO: <pegar bloque "Contexto global">

PROBLEMA REPORTADO POR EL USUARIO:
"El apartado de añadir región no va correctamente y el tamaño estimado y
demás va muy mal."

ANÁLISIS PREVIO:
- lib/features/offline/widgets/region_download_sheet.dart líneas 45-65:
  fórmula errada de tamaño estimado. `_estimatedTileCount` usa `1 << z` que
  es lineal (no cuadrático). Para 5 niveles de zoom da números absurdos.
- líneas 100-110: llama a `client.rpc('export_region_data', ...)` (Supabase
  RPC) para "descargar" — NO usa flutter_map_tile_caching realmente.
- pubspec.yaml línea 23: `flutter_map_tile_caching: ^10.0.0` instalado pero
  sin uso real para descarga.
- lib/features/appearance/widgets/storage_section.dart líneas 83-96:
  computeFmtcSize funciona y suma directorio fmtc/store.

OBJETIVO:
1. Calcular tamaño estimado correctamente (fórmula cuadrática por área).
2. Implementar descarga real usando FMTC v10 (download API).
3. Mostrar progreso en tiempo real y manejar errores visibles.

ARCHIVOS PERMITIDOS:
- lib/features/offline/widgets/region_download_sheet.dart
- lib/data/fmtc/fmtc_region_downloader.dart (NUEVO, opcional)
- lib/features/appearance/widgets/storage_section.dart (si necesitas ajustes
  en visualización; opcional)

ARCHIVOS PROHIBIDOS: cualquier otro.

TAREAS CONCRETAS:

T1. Fórmula de tamaño correcta
   - Reemplaza _estimatedTileCount con un cálculo cuadrático por bbox y zoom:
     ```dart
     int _tilesInRange(LatLng nw, LatLng se, int z) {
       final n = pow(2, z).toInt();
       int latToY(double lat) => ((1 - log(tan(lat * pi / 180) +
           1 / cos(lat * pi / 180)) / pi) / 2 * n).floor();
       int lngToX(double lng) => ((lng + 180) / 360 * n).floor();
       final x1 = lngToX(nw.longitude);
       final x2 = lngToX(se.longitude);
       final y1 = latToY(nw.latitude);
       final y2 = latToY(se.latitude);
       return ((x2 - x1).abs() + 1) * ((y2 - y1).abs() + 1);
     }
     ```
   - `_estimatedTileCount` = suma de `_tilesInRange(nw, se, z)` para cada
     zoom en [minZoom..maxZoom].
   - `_estimatedSize` = tilesCount * 15 KB (heurística estándar para PNG
     256x256 retina).
   - Para una región pequeña (5x5 km en Jerez) a zoom 10-16, debería dar
     entre 5 MB y 80 MB (orden de magnitud realista).

T2. Descarga real con FMTC
   - Sustituye la llamada a Supabase RPC por uso de FMTC v10:
     ```dart
     final store = FMTCStore('jerez');
     await store.manage.create();
     final region = RectangleRegion(
       LatLngBounds(LatLng(swLat, swLng), LatLng(neLat, neLng)),
     ).toDownloadable(
       minZoom: minZoom,
       maxZoom: maxZoom,
       options: TileLayer(
         urlTemplate: MapConfig.tileUrl(currentMapStyle,
             apiKey: Env.mapTilerApiKey),
         subdomains: MapConfig.subdomains,
         userAgentPackageName: 'com.transitly.transitly',
       ),
     );
     final stream = const FMTCStore('jerez').download.startForeground(
         region: region);
     await for (final progress in stream) {
       setState(() {
         _progress = progress.percentageProgress;
         _tilesDone = progress.successfulTiles;
       });
     }
     ```
   - Verifica la API exacta de flutter_map_tile_caching 10.0.0 (cambió
     entre v9 y v10; consulta su README/CHANGELOG).

T3. UI de progreso y errores visibles
   - Mientras descarga: barra de progreso LinearProgressIndicator + texto
     "$tilesDone / $totalTiles".
   - Si falla: SnackBar con mensaje de error legible (no solo log).
   - Botón "Cancelar" que llama a `store.download.cancel()`.

T4. Gestión de regiones
   - Persiste la región descargada en Hive (id, nombre, bbox, zoom range,
     fecha, tamaño real ocupado).
   - En storage_section.dart verifica que `_computeFmtcSize` sigue funcionando
     con el nuevo store; ajusta el path si FMTC v10 lo cambió.

CONSTRAINTS DUROS:
- NO toques otros archivos.
- Mantén la compat con regiones existentes (si hubo descargas previas con
  la lógica Supabase RPC, ignóralas — quedan obsoletas; A8 las puede listar
  como "regiones legacy" sin error).

VERIFICACIÓN:
- `flutter analyze`
- Smoke manual: ir a Apariencia → Almacenamiento → Añadir región. Selecciona
  una zona pequeña en el mapa. Verifica que el tamaño estimado es realista
  (5-80 MB). Inicia descarga → barra de progreso avanza. Tras completar,
  el tamaño en storage_section aumenta acorde.
- Verifica offline: pon avión, abre el mapa, navega a la zona descargada →
  las tiles aparecen sin internet.

COMMIT(s):
- fix(offline): fórmula correcta de tamaño estimado
- feat(offline): descarga real de regiones con FMTC v10

REPORTE FINAL:
- Confirma T1-T4.
- Tamaño antes/después para una región de muestra (cuántos tiles, MB).
- Smoke offline verificado o pendiente.
```

---

## WAVE 3 — Verificación final (coordinador, NO agente)

1. **Regenerar l10n:**
   ```bash
   flutter gen-l10n
   ```
   Confirma que las claves añadidas por A1, A4, A5 y A6 están en
   `lib/l10n/generated/app_localizations_*.dart`.

2. **Análisis estático y tests:**
   ```bash
   flutter analyze     # 0 warnings
   flutter test        # 100% verde
   ```

3. **Resolución de conflictos pendientes:**
   - Si A1 reportó cambios extra fuera de su scope, aplicarlos manualmente.
   - Si A5 dejó usages legacy de `accessibleBusesTitle` en otros sitios,
     limpiarlos.

4. **Smoke test manual** (priorizar errores reportados):
   - Modo claro → mapa cambia tiles.
   - Cambia paleta → toda la UI cambia.
   - Cambia mapStyle → tiles cambian.
   - Selecciona fondo "soft grid" o "topo lines" → se renderiza.
   - Slider de font scale → la app no crashea en ningún valor del rango.
   - Activa fuente dislexia → tipografía cambia.
   - Activa daltonismo → dropdown rediseñado abre bottomsheet bonito.
   - Activa alto contraste → bordes 2px, fondos opacos, texto máx contraste.
   - Añadir región offline → tamaño estimado razonable + descarga real.
   - Widgets Android: instala APK debug en un dispositivo y añade widget al
     escritorio → muestra próximo bus de la línea favorita.
   - Mapa: no aparecen L1/L3/L5 con buses fantasma al abrir.
   - Selecciona una línea → flechas direccionales se ven, uniformes, solo
     en esa línea.
   - Pestaña Search: chip "Usar mi ubicación" pequeño.
   - Home: avisos solo aparecen si el GPS está dentro de la zona o la ruta
     favorita atraviesa la zona.
   - Home: el menú dice "BUSES CERCANOS"; al pulsar abre la pantalla, que
     filtra por proximidad y muestra empty state cuando no hay buses cerca.
   - "Buses cercanos": no overflow en ListTile.

5. **Build release opcional** (sólo si el usuario lo pide):
   ```bash
   flutter build apk --release
   ```

---

## Cobertura de errores → agentes

| # | Error reportado por el usuario | Agente |
|---|--------------------------------|--------|
| 1 | Modo claro no cambia el color del mapa | A1 (key + mapStyle en TransitMap) |
| 2 | Paletas no cambian nada | A1 (buildTheme respeta paleta) |
| 3 | Estilo de mapa no cambia | A1 (mapStyle se pasa a TransitMap) |
| 4 | Brillo sí va | (sin acción) |
| 5 | Fondo no funciona correctamente | A1 (prefab_backgrounds completo + IDs alineados) |
| 6 | Tamaño de texto cierra la app | A1 (clamp + hardening del cálculo) |
| 7 | Fuente para dislexia no va | A1 (rebuild de MaterialApp con key) |
| 8 | Daltonismo: dropdown feo | A1 (BottomSheet selector) |
| 9 | Alto contraste no hace nada | A1 (HighContrastTheme.apply con efecto real) |
| 10 | Añadir región va mal; tamaño estimado mal | A8 (FMTC v10 + fórmula correcta) |
| 11 | Widgets no aparecen en la app | A7 (Kotlin AppWidgetProvider + manifest) |
| 12 | L1/L3/L5 fijas con buses fantasma | A2 (eliminar trips JSON) |
| 13 | Flechas dirección aleatorias en todas las líneas | A2 (solo seleccionada + distancia uniforme) |
| 14 | Avisos sin restricción geográfica | A4 (modelo + provider + filtro) |
| 15 | Pantalla "accesibilidad" con buses mal nombrada | A5 (rename + filtrar GPS) + A6 (label home) |
| 16 | Overflow en botón | A5 (Expanded + maxLines) |
| 17 | "Usar mi ubicación" muy grande | A3 (chip pequeño con tokens) |

---

## Riesgos y notas

- **A1 es el agente con más carga** (9 sub-tareas, 12+ archivos). Si tarda
  o falla, el coordinador puede subdividirlo en A1a (theming) + A1b
  (a11y) — pero NO recomendado, theming y a11y se entrelazan.
- **A7 (widgets nativos)** requiere build Android y verificación en dispositivo
  físico. Si el coordinador no tiene Android disponible, se queda en
  "compila debug" sin smoke real.
- **A8 (FMTC)** depende de la API de flutter_map_tile_caching v10. Si la API
  cambió respecto a v9 (probable), el agente debe consultar el README del
  package — incluir referencia URL en su brief si está disponible offline.
- **Conflictos en `comujesa_data.json` entre A2 y A4**: A2 vacía
  `activeTrips`. A4 modifica `alerts`. Si ambos editan al mismo tiempo en
  archivos locales sin VCS lock, el coordinador resuelve haciendo merge
  manual (ambas son secciones disjuntas).
- **Decisión revertida en docs/HOME_WIDGETS.md**: el documento dice
  "NOT implementing". Tras A7, el coordinador debe actualizar el doc para
  reflejar que ahora SÍ se implementa, con instrucciones de uso.
- **Plan v1 ya tocó algunas áreas** (theming, alto contraste, flechas, etc.)
  pero los fixes quedaron incompletos. Este plan v2 los completa. Verifica
  el reporte de v1 antes de tocar zonas conflictivas si dudas.
