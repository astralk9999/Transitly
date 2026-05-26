# Plan de reparación v4 — Transitly (foco crítico: rebuild del árbol)

**Fecha:** 2026-05-26
**Autor:** Claude Code (Opus 4.7)
**Plan anterior:** `docs/historico/PLAN_REPARACION_2026_05_26_V3.md` (v3 — el factory reactivo se aplicó pero el rebuild no se propaga porque go_router cachea las páginas)

---

## TL;DR — Nuevo root cause

> **Bug crítico (causa raíz de casi todos los problemas de personalización):**
> El v3 hizo que `TransitColorScheme.of(isDark)` consulte el `ProviderContainer`
> global, pero los widgets descendientes del `MaterialApp.router` **NO se
> reconstruyen** cuando el `ThemeNotifier` notifica. Razón: `go_router` cachea
> las pantallas y solo las recrea cuando cambia la ruta. El factory devuelve
> la paleta correcta, pero los `build()` actuales no se vuelven a llamar.
>
> **Pista del usuario** ("solo se aplican las paletas al cambiar el fondo"):
> el `BackgroundWrapper` es el ÚNICO punto del árbol que hace
> `ref.watch(themeNotifierProvider)` Y envuelve `child`. Cuando cambia el
> fondo, `BackgroundWrapper` rebuilda, recompone su subárbol y los widgets
> hijos re-llaman al factory con la paleta correcta. Por eso "al cambiar
> fondo" todo se actualiza.
>
> **Solución v4:** Forzar rebuild del árbol completo en `app.dart` builder
> cuando cambia paleta, tema, dislexia, fondo, alto contraste o mapStyle.
> Usar `KeyedSubtree` con `key` derivada del estado del notifier.

Otros bugs confirmados leyendo el código:

1. **Reset config no aplica**: `reset_section.dart:71` setea `backgroundId = 'smoke'`, pero el ID correcto en el prefab es `'shaders/smoke.frag'`. Además, aunque el reset cambie valores, el árbol no rebuilda (mismo bug del rebuild).
2. **Fondos quedan en humo**: `prefab_backgrounds.dart` añadió `ProceduralBackground(softGrid)` y `topoLines`, pero `background_wrapper.dart:44-45` los pinta como un `Container(color: bgRoot)` plano sin renderizar el patrón. El usuario percibe que "no cambia" porque al elegir esos modos no se ve un patrón visible.
3. **Dislexia no va**: el `buildTransitTheme` aplica `GoogleFonts.atkinsonHyperlegible...` al `textTheme` del `ThemeData`, pero los widgets usan `TransitTypography.bodyPrimary(...)` que ignora el `Theme.of(context).textTheme`. La fuente nunca llega a aplicarse a nada visible.
4. **FAB tapado por sheet**: `MapControls` está dentro de `TransitMap.overlayWidgets` (parte del primer hijo del Stack). El `DraggableScrollableSheet` se renderiza después en el mismo Stack y al tener `initialChildSize: 0.22` (~176px en pantallas de 800px) tapa el FAB que está a `bottom:16`.
5. **Icono entrada cortado**: persiste porque el v3 dejó la imagen en `assets/branding/transitly_logo_white_padded.png` pero o no tiene padding real, o `flutter_native_splash` no se regeneró.

---

## Mapa de waves

```
WAVE 1 (5 agentes paralelos, sin solape de archivos)
├── A1  CORE: Rebuild forzado del árbol al cambiar theme/palette/dyslexia/etc
├── A2  Crash de fontScale al cambiar tamaño de letra
├── A3  Logo entrada cortado (splash nativo y Dart)
├── A4  FAB ubicación tapado por sheet + reordenar Stack
└── A5  Mapa: tema/estilo + tiles reactive (debug por qué el key no fuerza recarga)

WAVE 2 (3 agentes paralelos, depende de A1)
├── A6  Fondos procedurales con render real (softGrid, topoLines, gradient)
├── A7  Reset config con backgroundId correcto + rebuild observable
└── A8  Dislexia: aplicar fontFamily globalmente vía TransitTypography reactiva

WAVE 3 (1 agente independiente)
└── A9  Widgets nativos Android (carry-over del plan v2 — siguen sin existir)

WAVE 4 (coordinador)
└── flutter gen-l10n + analyze + tests + smoke completo
```

### Tabla de archivos por agente

| Agente | Archivos que modifica |
|--------|------------------------|
| **A1** | `lib/app.dart` (builder con KeyedSubtree), `lib/shared/providers/theme_notifier.dart` (exponer hash del estado), opcional `lib/shared/providers/active_palette_provider.dart` |
| **A2** | `lib/features/appearance/widgets/font_section.dart`, audit de widgets con `fontSize * fontScale`, archivos del culpable del crash que identifique |
| **A3** | `pubspec.yaml`, `lib/features/splash/splash_screen.dart`, `assets/branding/` |
| **A4** | `lib/features/home/tabs/map_tab.dart` (mover el FAB fuera de `TransitMap.overlayWidgets` para que esté ENCIMA del sheet) |
| **A5** | `lib/features/map/transit_map.dart`, `lib/features/home/tabs/map_tab.dart` (solo la sección de TransitMap si A4 no la toca; coordinar), `lib/features/map/map_config.dart` si necesita |
| **A6** | `lib/core/theme/backgrounds/prefab_backgrounds.dart`, `lib/shared/widgets/background_wrapper.dart`, `lib/core/theme/backgrounds/procedural_painters.dart` (NUEVO) |
| **A7** | `lib/features/appearance/widgets/reset_section.dart` |
| **A8** | `lib/core/theme/transit_typography.dart`, `lib/core/theme/transit_theme.dart` (verificar), `lib/features/appearance/widgets/font_section.dart` (coordinar con A2) |
| **A9** | `android/app/src/main/AndroidManifest.xml`, ficheros nuevos Kotlin/XML, `lib/data/widgets_native/widget_data_writer.dart`, `lib/features/widgets_native/widgets_settings_screen.dart` |

### Conflictos controlados

- **`lib/features/home/tabs/map_tab.dart`**: A4 (FAB) y A5 (TransitMap props). A4 toca el Stack del Scaffold para sacar el FAB; A5 toca la construcción de TransitMap. Son edits en zonas distintas → merge trivial. Si conflicta, el coordinador lo resuelve.
- **`lib/features/appearance/widgets/font_section.dart`**: A2 puede tocarlo si el crash sale del preview (`13 * fontScale`); A8 lo lee para verificar coherencia. A8 NO modifica este archivo salvo coordinación con A2.

---

## Contexto global (incluir en todos los briefs)

```
PROYECTO: Transitly (nexto-stop-v2) — App Flutter de transporte público para Jerez,
operador COMUJESA. Demo académica con datos mock (assets/mock/comujesa_data.json).
STACK: Flutter 3.9.2+, Riverpod 2.6.1, go_router 17.2.3, flutter_map 7.0.2,
hive 2.2.3, supabase_flutter 2.8.0, geolocator 13.0.0, home_widget 0.7.0.
DIRECTORIO: C:\Users\k\Desktop\all\clase\nexto-stop-v2
RAMA: master

REGLAS:
- Usar siempre tokens (TransitColorScheme, TransitTypography, TransitSpacing).
- 0 warnings de `flutter analyze` tras el cambio.
- Commits en español con prefijo convencional.
- NO ejecutar `flutter build apk` ni `git push` salvo si lo pide el usuario.
- Para l10n, añadir claves al final del JSON; el coordinador regenera.
- NO tocar archivos de otros agentes (ver tabla).

CONTEXTO DE LA SESIÓN:
- v1 y v2 introdujeron muchos cambios.
- v3 reescribió `TransitColorScheme.of()` con resolver global vía
  `registerResolver()` + `ProviderContainer` raíz en main.dart. Eso funciona,
  pero NO basta para que el árbol rebuilde cuando cambia el notifier.
- v4 cierra el último gap: forzar rebuild observable en cada cambio.
```

---

## WAVE 1 — Briefs

### A1 — Rebuild forzado del árbol al cambiar theme/palette/dyslexia/etc.

```text
ROL: Engineer Flutter senior, especialista en Riverpod, ChangeNotifier y
rebuilds de árboles.

CONTEXTO DEL PROYECTO: <pegar bloque "Contexto global">

PROBLEMA CRÍTICO REPORTADO:
"En personalización solo se aplican las paletas al cambiar el fondo."

Esto significa que cambiar paleta en el `ThemeNotifier` persiste el valor
y `notifyListeners()` se llama, pero el árbol descendiente del MaterialApp
NO rebuilda. Solo cuando el usuario también cambia el fondo, el
BackgroundWrapper (que sí escucha el provider y envuelve `child`) fuerza
una recomposición que llega a los descendientes y los widgets re-llaman
a `TransitColorScheme.of(isDark)` obteniendo la paleta nueva.

ROOT CAUSE:
- `app.dart` hace `ref.watch(themeNotifierProvider)` y construye
  `MaterialApp.router(...)`.
- `routerConfig: router` es un GoRouter que cachea las páginas creadas.
- Cuando notifyListeners(), MaterialApp.router se reconstruye pero los
  hijos pinta-dos por go_router (las pantallas) NO se vuelven a build
  hasta que cambian de ruta.
- Resultado: `theme:` y `darkTheme:` se reconstruyen pero ningún
  descendiente lo nota porque (a) ninguno hace ref.watch a themeNotifier
  y (b) la mayoría usa el factory `TransitColorScheme.of(isDark)` que es
  síncrono y no observable.

ARCHIVO CLAVE: lib/app.dart líneas 17-69.

OBJETIVO:
Forzar el rebuild del árbol completo cada vez que cambia un valor "visual"
del ThemeNotifier (paleta, tema, dislexia, alto contraste, fondo, mapStyle,
fontScale, colorBlindMode). Hacerlo en `app.dart` builder con KeyedSubtree
+ key compuesta.

ARCHIVOS PERMITIDOS:
- lib/app.dart
- lib/shared/providers/theme_notifier.dart (SOLO añadir un getter `visualKey`
  que devuelva un String con el hash del estado visual)
- lib/shared/providers/active_palette_provider.dart (si requieres helpers)

ARCHIVOS PROHIBIDOS:
- map_tab.dart, transit_map.dart (son de A4/A5)
- font_section.dart (es de A2)
- splash_screen.dart (es de A3)
- background_wrapper.dart, prefab_backgrounds.dart (son de A6)
- reset_section.dart (es de A7)
- transit_typography.dart, transit_theme.dart (son de A8)

═══════════════════════════════════════════════════════════════════
TAREAS CONCRETAS:
═══════════════════════════════════════════════════════════════════

T1. Getter `visualKey` en ThemeNotifier
   En lib/shared/providers/theme_notifier.dart, añade DESPUÉS de los
   getters existentes (alrededor de línea 80) un getter compuesto:

       String get visualKey {
         return [
           _paletteId,
           _backgroundId,
           _backgroundEnabled,
           _backgroundOpacity.toStringAsFixed(2),
           _fontScale.toStringAsFixed(2),
           _colorBlindMode.name,
           _dyslexiaFontEnabled,
           _reduceMotion,
           _highContrast,
           _mapStyle,
           ...List<String>.from(_customColors.entries
               .map((e) => '${e.key}:${_colorToHex(e.value)}'))
             ..sort(),
         ].join('|');
       }

   Este string cambia cada vez que cualquier propiedad visual cambia.
   Lo usarás como key del KeyedSubtree para forzar rebuild.

T2. KeyedSubtree en app.dart `builder`
   En lib/app.dart, modifica el `builder` para envolver `result` (después
   del BackgroundWrapper y antes de los ColorFiltered/MediaQuery) con
   KeyedSubtree usando el visualKey:

       builder: (context, child) {
         final themeMode = ref.watch(themeModeProvider);
         final notifier = ref.watch(themeNotifierProvider);
         final visualKey = notifier.visualKey + '|${themeMode.name}';

         Widget result = KeyedSubtree(
           key: ValueKey('visual:$visualKey'),
           child: BackgroundWrapper(child: child!),
         );

         if (notifier.colorBlindMode != ColorBlindMode.none) {
           result = ColorFiltered(
             colorFilter: ColorFilter.matrix(
               AccessibilityMatrix.forMode(notifier.colorBlindMode.name),
             ),
             child: result,
           );
         }

         final rawSystem = MediaQuery.textScalerOf(context).scale(1.0);
         final systemScale = rawSystem.isFinite && rawSystem > 0 ? rawSystem : 1.0;
         final combined = (systemScale * notifier.fontScale).clamp(0.8, 2.5);
         final mq = MediaQuery.of(context);
         return FocusTraversalGroup(
           policy: WidgetOrderTraversalPolicy(),
           child: MediaQuery(
             data: mq.copyWith(
               textScaler: TextScaler.linear(combined),
               disableAnimations:
                   notifier.reduceMotion || mq.disableAnimations,
             ),
             child: result,
           ),
         );
       }

   - El KeyedSubtree fuerza Flutter a desechar el subárbol cuando la key
     cambia y volver a crearlo. Eso recrea TODAS las pantallas, FAB,
     listas, etc. y cada widget re-llama a `TransitColorScheme.of(isDark)`
     y obtiene la paleta actualizada.
   - Trade-off: pierde estado de animaciones / scroll. Aceptable porque
     son cambios infrecuentes (tocados por el usuario manualmente).

T3. Verificación de propagación
   Tras tu cambio, smoke test:
     1. Abre la app, ve a Apariencia.
     2. Cambia paleta a "Sunrise" → toda la app (no solo el wrapper) se
        vuelve naranja. Incluye home, mapa, buscador, perfil.
     3. Cambia paleta a "Forest" → todo verde.
     4. Cambia tema a Light → todo claro.
     5. Activa Alto Contraste → cambio visible.
     6. Activa Dislexia → tipografía cambia (A8 lo completa, pero el
        rebuild debe ocurrir).
     7. Cambia mapStyle → A5 lo verifica.

T4. Test unitario (opcional pero recomendado)
   Añade test/shared/providers/theme_notifier_visual_key_test.dart:
     - Verifica que `visualKey` cambia cuando cambia cualquier campo
       relevante.
     - Verifica que NO cambia si cambias algo no-visual (ej.
       `notifIncidentResolved`).

═══════════════════════════════════════════════════════════════════
VERIFICACIÓN:
═══════════════════════════════════════════════════════════════════
- `flutter analyze` 0 warnings.
- Smoke test completo (T3).

COMMIT:
fix(theme): forzar rebuild del árbol al cambiar valores visuales

REPORTE FINAL:
- Confirma T1-T4.
- Pega el snippet del nuevo builder.
- Notas sobre regresiones observadas (ej. scroll que se reinicia al
  cambiar tema).
```

---

### A2 — Crash al cambiar el tamaño de letra (persiste tras v3)

```text
ROL: Engineer Flutter, diagnóstico de runtime crashes.

CONTEXTO DEL PROYECTO: <pegar bloque "Contexto global">

PROBLEMA REPORTADO:
"Al cambiar el tamaño de letra la app da error y se cierra."

Es la TERCERA vez que se reporta. El v3 dejó:
- theme_notifier.dart línea 141-147: clamp(0.85, 1.4) en setter.
- app.dart líneas 49-65: hardening de NaN + clamp combined (0.8, 2.5).

Pero el crash persiste. Hipótesis no investigadas en v3:
- Algún widget con `Text` dentro de un `Row` con `ConstrainedBox` o
  `width: fijo` que crashea con RenderFlex overflowed FATAL.
- GoogleFonts.atkinsonHyperlegibleTextTheme falla si activas dislexia
  cuando hay textScale alto.
- Un Slider que internamente calcula thumb size con fontSize y crashea.

OBJETIVO:
1. REPRODUCIR el crash con `flutter run` en modo debug.
2. Capturar el stack trace EXACTO.
3. Identificar el widget culpable.
4. Patchearlo con FittedBox/Flexible/Expanded.

ARCHIVOS PERMITIDOS:
- lib/features/appearance/widgets/font_section.dart (línea 75: preview)
- lib/app.dart (hardening adicional si requiere)
- archivos del culpable del crash

ARCHIVOS PROHIBIDOS:
- TODO el resto que A1, A3-A9 tocan (ver tabla principal).

═══════════════════════════════════════════════════════════════════
TAREAS CONCRETAS:
═══════════════════════════════════════════════════════════════════

T1. Reproducir el crash
   - `flutter run` en debug.
   - Va a Apariencia → Tamaño de letra.
   - Slider de 85% a 140%, observa qué valor lo crashea.
   - Si crashea inmediatamente al tocar el slider, posible culpa: el
     preview interno de font_section.dart línea 75 (`13 * fontScale`).
   - Si crashea al volver a otra pantalla, el culpable está en esa
     pantalla.
   - Captura el stack trace COMPLETO con `flutter run` verbose o desde
     DevTools.

T2. Patrones a buscar
   Si el stack apunta a:
   - `RenderFlex overflowed by N pixels` FATAL → es un `Row` rígido
     con `Text` que crece. Solución: `Flexible(child: Text(..., maxLines:1, overflow:fade))`.
   - `RangeError`: revisa cálculos con `fontScale` que pueden ir fuera
     de rango.
   - `_AssertionError` de Stack/Positioned → algún Positioned absoluto
     con coordenadas calculadas vía fontScale.
   - `Failed to load font` de GoogleFonts → caché de fuente roto.

T3. Aplicar fix mínimo
   - Si es un widget de la app de Transitly, parchéalo localmente
     (envolver con Flexible/Expanded/FittedBox).
   - Si es un widget del propio framework (ej. Slider), prueba a
     hardenear el call site sin tocar Flutter.
   - Si es GoogleFonts, considera precargar la fuente en main.dart o
     desactivar dislexia hasta resolver.

T4. Test de regresión
   - Recorre EN PERSONA estas pantallas con fontScale 140%:
     - Home (tu próximo bus, paradas cerca, mis líneas, avisos)
     - Mapa (sheet de líneas con códigos largos)
     - Buscador
     - Tarjeta NFC
     - Perfil
     - Notificaciones
     - Apariencia (autoreferencial)
   - Marca cualquier overflow no fatal (banda amarilla) para reportar al
     coordinador.

═══════════════════════════════════════════════════════════════════
VERIFICACIÓN:
═══════════════════════════════════════════════════════════════════
- Mueve el slider de 85% a 140% en cada pantalla.
- En NINGÚN caso debe crashear.
- `flutter analyze` 0 warnings.

COMMIT:
fix(a11y): crash de fontScale resuelto (<widget culpable>)

REPORTE FINAL:
- Stack trace EXACTO del crash original (pega el output).
- Widget identificado + línea exacta.
- Fix aplicado (snippet).
- Lista de pantallas verificadas con captura textual de overflows
  residuales.
```

---

### A3 — Logo entrada cortado (sigue cortado tras v3)

```text
ROL: Engineer Flutter de branding y assets.

CONTEXTO DEL PROYECTO: <pegar bloque "Contexto global">

PROBLEMA REPORTADO:
"El icono de entrada se ve atacado [sic: cortado/acotado]."

El v3 cambió pubspec.yaml para que flutter_native_splash use el PNG
padded, y splash_screen.dart para que también. PERO sigue cortado, lo
que sugiere:
- O bien la herramienta no se regeneró tras cambiar pubspec.
- O bien la imagen padded NO tiene padding real (es la misma sin padding
  con otro nombre).
- O bien Android 12+ aplica una máscara aún más restrictiva.

OBJETIVO:
1. Verificar el contenido REAL de las imágenes en assets/branding/.
2. Regenerar splash y launcher icons.
3. Si la imagen padded es insuficiente, crear una con padding del 35%.

ARCHIVOS PERMITIDOS:
- pubspec.yaml (secciones flutter_launcher_icons y flutter_native_splash)
- lib/features/splash/splash_screen.dart
- assets/branding/ (puedes generar nuevos PNG)
- android/app/src/main/res/drawable*/launch_background.xml (si la
  herramienta requiere ajustes)

═══════════════════════════════════════════════════════════════════
TAREAS CONCRETAS:
═══════════════════════════════════════════════════════════════════

T1. Inspección de imágenes
   - Lista archivos en assets/branding/:
       ls -la assets/branding/
   - Abre cada PNG y comprueba dimensiones + transparencia + cantidad de
     padding interno.
   - Si transitly_logo_white_padded.png NO tiene al menos 30% margen
     transparente alrededor, ES la causa del recorte.

T2. Generar versión con padding del 35%
   - Si tienes ImageMagick:
       convert assets/branding/transitly_logo_white.png \
           -gravity center -background none \
           -extent 150%x150% \
           assets/branding/transitly_logo_white_padded.png
   - Si no, usa Dart con package `image`:
       ```dart
       import 'package:image/image.dart' as img;
       import 'dart:io';
       void main() {
         final src = img.decodePng(File('assets/branding/transitly_logo_white.png').readAsBytesSync())!;
         final pad = (src.width * 0.5).round();
         final out = img.Image(width: src.width + pad * 2,
             height: src.height + pad * 2);
         img.fill(out, color: img.ColorUint8.rgba(0, 0, 0, 0));
         img.compositeImage(out, src, dstX: pad, dstY: pad);
         File('assets/branding/transitly_logo_white_padded.png')
           .writeAsBytesSync(img.encodePng(out));
       }
       ```
   - Verifica el resultado abriendo el PNG.

T3. Regenerar
   - `flutter pub get`
   - `dart run flutter_launcher_icons` → regenera iconos del launcher.
   - `dart run flutter_native_splash:create` → regenera splash nativo.
   - Verifica que:
     - android/app/src/main/res/mipmap-*/ic_launcher_foreground.png
       contiene el logo CENTRADO con margen.
     - android/app/src/main/res/drawable*/launch_background.xml apunta
       al PNG correcto.

T4. Splash Dart
   - Si lib/features/splash/splash_screen.dart YA usa la versión padded,
     verifica que el `Image.asset` width/height sigue siendo 240x240 o
     súbelo a 300x300 para que el logo se vea bien dentro del padding.

═══════════════════════════════════════════════════════════════════
VERIFICACIÓN:
═══════════════════════════════════════════════════════════════════
- `flutter analyze`
- `flutter build apk --debug` debe pasar.
- Instala el APK debug:
  - Splash nativo (la imagen que sale al abrir antes de Flutter
    arrancar) muestra el logo completo sin recorte.
  - Splash Dart (la pantalla con el accent y el título "TRANSITLY")
    muestra el logo completo y centrado.
  - El icono del launcher (en la lista de apps de Android) muestra el
    logo dentro de la máscara circular sin tocar bordes.
- Toma 3 screenshots y descríbelos en el reporte.

COMMIT:
fix(branding): logo de entrada centrado sin recorte (padding 35%)

REPORTE FINAL:
- Dimensiones de la imagen padded final.
- Comando exacto que ejecutaste para regenerar.
- Listado de archivos cambiados en android/ tras la regeneración.
- Descripción de los 3 screenshots.
```

---

### A4 — FAB ubicación tapado por sheet de líneas

```text
ROL: Engineer Flutter, especialista en Stack/Positioned/sheets.

CONTEXTO DEL PROYECTO: <pegar bloque "Contexto global">

PROBLEMA REPORTADO:
"El botón de ubicación es tapado por el menú donde están todas las líneas."

ROOT CAUSE (CONFIRMADO LEYENDO EL CÓDIGO):
- lib/features/home/tabs/map_tab.dart líneas 319-369:
    Scaffold(
      body: Stack(children: [
        TransitMap(
          overlayWidgets: [
            MapControls(onCenter: ..., ...) // FAB en bottom:16, right:16
          ],
        ),
        // ...offline banner
        DraggableScrollableSheet(  // initialChildSize: 0.22
          ...
        ),
      ]),
    )
- El FAB está DENTRO del primer hijo del Stack (TransitMap.overlayWidgets).
- El sheet es el ÚLTIMO hijo del Stack → se pinta encima.
- Con initialChildSize 0.22 (≈176px en pantallas estándar), el sheet
  cubre la zona del FAB (bottom:16).

OBJETIVO:
1. Mover el FAB FUERA de `TransitMap.overlayWidgets`, colocarlo como
   `Positioned` en el Stack del Scaffold DESPUÉS del sheet (para que
   quede ENCIMA).
2. Hacer que la posición vertical del FAB se ajuste al tamaño actual
   del sheet (anclarse a `currentSize` del DraggableScrollableController).

ARCHIVOS PERMITIDOS:
- lib/features/home/tabs/map_tab.dart

ARCHIVOS PROHIBIDOS: cualquier otro.

═══════════════════════════════════════════════════════════════════
TAREAS CONCRETAS:
═══════════════════════════════════════════════════════════════════

T1. Sacar MapControls de overlayWidgets
   - En map_tab.dart, busca `MapControls(...)` dentro de
     `TransitMap(overlayWidgets: [...])`.
   - Mueve esa construcción como hijo directo del Stack del Scaffold,
     DESPUÉS del DraggableScrollableSheet. Ejemplo:

       body: Stack(
         children: [
           TransitMap(
             // sin MapControls en overlayWidgets ahora; deja
             // overlayWidgets: const [] o quita el parámetro si vacío
             ...
           ),
           if (offline) Positioned(...),
           DraggableScrollableSheet(...),
           // FAB encima del sheet:
           Positioned.fill(
             child: SafeArea(
               child: _AnchoredMapControls(
                 sheetController: _sheetController,
                 isDark: isDark,
                 loadingCenter: _loadingCenter,
                 onCenter: _centerOnUser,
                 onFilter: () => showMapFilterSheet(context, ref),
                 onSearch: () => showMapSearchSheet(context, ref, _mapController),
               ),
             ),
           ),
         ],
       )

T2. Widget `_AnchoredMapControls` que escucha al sheet
   - Crea una clase local privada `_AnchoredMapControls extends StatefulWidget`.
   - Escucha al `DraggableScrollableController.addListener` para
     conocer `currentSize` (0.0..1.0) y rebuildear con un
     `AnimatedPositioned`:

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
         State<_AnchoredMapControls> createState() => _AnchoredMapControlsState();
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
           final fabBottom = screenH - sheetTop + 12; // 12px por encima del sheet

           final c = TransitColorScheme.of(widget.isDark);
           return Stack(
             children: [
               if (widget.onSearch != null)
                 Positioned(top: 16, left: 16,
                   child: _ControlButton(icon: Icons.search,
                       colors: c, onTap: widget.onSearch)),
               Positioned(top: 16, right: 16,
                 child: _ControlButton(icon: Icons.tune,
                     colors: c, onTap: widget.onFilter)),
               // FAB ubicación: anclado al borde superior del sheet
               AnimatedPositioned(
                 duration: const Duration(milliseconds: 80),
                 right: 16,
                 bottom: fabBottom,
                 child: _ControlButton(
                   icon: Icons.my_location,
                   colors: c,
                   onTap: widget.loadingCenter ? null : widget.onCenter,
                   loading: widget.loadingCenter,
                 ),
               ),
             ],
           );
         }
       }

   - Si `_ControlButton` es privado en `lib/features/map/widgets/map_controls.dart`,
     duplica la clase localmente en map_tab.dart o ahora hazlo público
     ahí. (Opción mínima: duplica en map_tab.dart con nombre `_FabButton`.
     NO toques map_controls.dart si no quieres invadir A5.)

T3. Comportamiento esperado
   - El FAB de ubicación siempre se ve, AunQue el sheet esté expandido.
   - Cuando el sheet sube, el FAB sube con él, manteniendo 12px por
     encima del borde superior del sheet.
   - Los FABs de búsqueda y filtros se quedan arriba (no se mueven).

═══════════════════════════════════════════════════════════════════
VERIFICACIÓN:
═══════════════════════════════════════════════════════════════════
- `flutter analyze` 0 warnings.
- Smoke manual: abre el mapa, expande el sheet a su tamaño máximo (75%).
  El FAB ubicación debe seguir visible y operativo en la esquina inferior
  derecha, justo encima del borde del sheet.
- Colapsa el sheet a su tamaño mínimo (12%). FAB se mueve hacia abajo
  pero sigue visible.

COMMIT:
fix(map): FAB ubicación ya no es tapado por el sheet (anclaje dinámico)

REPORTE FINAL:
- Snippet del nuevo `_AnchoredMapControls`.
- Confirmación de smoke manual.
- Si `_ControlButton` se duplicó o se hizo público, justifica la decisión.
```

---

### A5 — Mapa: estilo y tema realmente reactivos

```text
ROL: Engineer Flutter, especialista en flutter_map y caché de tiles.

CONTEXTO DEL PROYECTO: <pegar bloque "Contexto global">

PROBLEMA REPORTADO:
"El estilo de mapa no cambia da igual cual elijas además de que cuando
cambias de modo oscuro a claro el mapa tampoco se adapta."

El v3 añadió `key: ValueKey('${isDark ? "d" : "l"}-$mapStyle')` y pasó
`mapStyle:` a TransitMap. El factory de TransitMap.urlTemplate usa
`widget.mapStyle ?? (widget.isDark ? 'dark' : 'light')`. Aún así no
cambia visiblemente.

Hipótesis:
- El FMTC `tileProvider` cachea las tiles de la URL anterior y no las
  refresca aunque el TileLayer se recree. Esto pasa porque las tiles
  están guardadas en `fmtc/store` con la misma clave.
- El `key` en TransitMap solo recrea el widget pero FMTC reusa la caché.
- Tras A1 (rebuild forzado), `map_tab` se reconstruye con el key nuevo,
  pero el TileLayer sigue usando FMTCTileProvider con caché vieja.

OBJETIVO:
1. Cuando cambia el mapStyle, invalidar (o pasar por alto) la caché
   FMTC para esas tiles.
2. Verificar que el `key` recrea el TileLayer, no solo el TransitMap
   externo.
3. Documentar el comportamiento offline vs online para el coordinador.

ARCHIVOS PERMITIDOS:
- lib/features/map/transit_map.dart
- lib/features/home/tabs/map_tab.dart  ← SOLO la construcción de
  TransitMap. NO toques el FAB (es de A4).
- lib/features/map/map_config.dart si requiere ajuste de URL.
- lib/data/fmtc/fmtc_provider.dart si necesitas separar stores por
  estilo.

ARCHIVOS PROHIBIDOS:
- map_controls.dart, route_direction_arrows.dart, otros archivos no
  relacionados.

═══════════════════════════════════════════════════════════════════
TAREAS CONCRETAS:
═══════════════════════════════════════════════════════════════════

T1. Diagnosticar la caché FMTC
   - Lee `lib/data/fmtc/fmtc_provider.dart` o equivalente que provea
     `fmtcTileProviderProvider`.
   - Comprueba si crea UN solo store ('jerez' o similar) que se usa
     para todos los estilos.
   - Si es así, las tiles cacheadas tienen URL fija (la del estilo en
     el momento de guardar) y se sirven aunque el TileLayer use otra
     URL. **Esto explica el bug.**

T2. Solución por estilo
   - Crea (o adapta) `fmtcTileProviderProvider` para que sea family
     indexado por `mapStyle`:
       final fmtcTileProviderProvider =
           Provider.family<TileProvider, String>((ref, style) {
         final store = FMTCStore('jerez-$style');
         return store.getTileProvider();
       });
   - En map_tab.dart, en lugar de `ref.watch(fmtcTileProviderProvider)`
     a secas, usa `ref.watch(fmtcTileProviderProvider(mapStyle))`.
   - Eso da una caché distinta por estilo. Cambiar de estilo dispara
     descarga (online) o tiles vacíos (offline) hasta que se rellene.
   - Si tu FMTCTileProvider API no soporta `family`, alternativa más
     pragmática: si online, simplemente bypassear FMTC al cambiar estilo
     (usar NetworkTileProvider directamente, con `key` que cambia con el
     estilo).

T3. Forzar recreación del TileLayer al cambiar el `key`
   - En lib/features/map/transit_map.dart, verifica que `TileLayer(
       urlTemplate: MapConfig.tileUrl(widget.mapStyle ?? ...),
       tileProvider: widget.fmtcTileProvider,
     )` no está envuelto en algún `KeepAlive` o `AutomaticKeepAliveClientMixin`
     que evite recreación.
   - Si el TileLayer es directamente hijo del FlutterMap, el key
     externo (en TransitMap) debería recrearlo. Verifica con un
     print/log en initState.

T4. Smoke
   - Cambia estilo en Apariencia de "streets" a "dark" a "light".
   - El mapa debe cambiar de tonos al instante (online) o mostrar tiles
     vacías cargando (online la primera vez, offline a la segunda).
   - Cambia tema claro/oscuro → mapa cambia.

═══════════════════════════════════════════════════════════════════
VERIFICACIÓN:
═══════════════════════════════════════════════════════════════════
- `flutter analyze` 0 warnings.
- Smoke manual descrito en T4.

COMMIT(s):
- fix(map): tile layer reactivo al estilo y tema sin caché cruzada

REPORTE FINAL:
- Diagnóstico de FMTC: cuántos stores, claves usadas.
- Solución elegida (T2 family o T2 bypass).
- Confirmación de smoke.
- Si el cambio de estilo offline muestra tiles vacías, documenta la
  limitación.
```

---

## WAVE 2 — Briefs (despachar tras integración de Wave 1)

### A6 — Fondos procedurales con render real

```text
ROL: Engineer Flutter, especialista en CustomPainter.

CONTEXTO DEL PROYECTO: <pegar bloque "Contexto global">

PROBLEMA REPORTADO:
"Los fondos no cambian a los distintos tipos que deberian de funcionar
se queda permanentemente en el de humo."

ROOT CAUSE:
- lib/core/theme/backgrounds/prefab_backgrounds.dart líneas 11-12:
    const ProceduralBackground(ProceduralPattern.softGrid),
    const ProceduralBackground(ProceduralPattern.topoLines),
- lib/shared/widgets/background_wrapper.dart líneas 44-45:
    ProceduralBackground() =>
        Container(color: palette.scheme.bgRoot, child: child),
- El switch trata softGrid/topoLines como un Container plano sin pintar
  el patrón. El usuario al elegirlos no ve diferencia respecto al "humo"
  porque al volver al smoke (cuando vuelve a entrar a apariencia) parece
  que se quedó en humo.

OBJETIVO:
Implementar el render real de softGrid y topoLines con CustomPainter.

ARCHIVOS PERMITIDOS:
- lib/shared/widgets/background_wrapper.dart
- lib/core/theme/backgrounds/procedural_painters.dart (NUEVO)
- lib/core/theme/backgrounds/prefab_backgrounds.dart (si ajustes menores)

═══════════════════════════════════════════════════════════════════
TAREAS CONCRETAS:
═══════════════════════════════════════════════════════════════════

T1. CustomPainters
   Crea lib/core/theme/backgrounds/procedural_painters.dart con dos
   CustomPainter:

       class SoftGridPainter extends CustomPainter {
         SoftGridPainter({required this.lineColor, required this.bgColor, this.spacing = 32});
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
             old.lineColor != lineColor || old.bgColor != bgColor || old.spacing != spacing;
       }

       class TopoLinesPainter extends CustomPainter {
         TopoLinesPainter({required this.lineColor, required this.bgColor, this.seed = 42});
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
           // Curvas tipo curvas de nivel: sinusoides anidadas
           for (int i = 0; i < 20; i++) {
             final amplitude = 30.0 + rng.nextDouble() * 60;
             final frequency = 0.005 + rng.nextDouble() * 0.01;
             final phase = rng.nextDouble() * pi * 2;
             final yOffset = (size.height / 20) * i + rng.nextDouble() * 20;
             final path = Path()..moveTo(0, yOffset);
             for (double x = 0; x < size.width; x += 4) {
               path.lineTo(x, yOffset + sin(x * frequency + phase) * amplitude);
             }
             canvas.drawPath(path, paint);
           }
         }
         @override
         bool shouldRepaint(TopoLinesPainter old) =>
             old.lineColor != lineColor || old.bgColor != bgColor || old.seed != seed;
       }

T2. Wrap en BackgroundWrapper
   - En lib/shared/widgets/background_wrapper.dart, sustituye la rama
     `ProceduralBackground() => Container(color: palette.scheme.bgRoot, child: child)`
     por:
       ProceduralBackground(:final pattern) => Stack(
         fit: StackFit.expand,
         children: [
           Opacity(
             opacity: opacity,
             child: CustomPaint(
               painter: pattern == ProceduralPattern.softGrid
                   ? SoftGridPainter(
                       lineColor: palette.scheme.accent.withValues(alpha: 0.08),
                       bgColor: palette.scheme.bgRoot)
                   : TopoLinesPainter(
                       lineColor: palette.scheme.accent.withValues(alpha: 0.06),
                       bgColor: palette.scheme.bgRoot),
             ),
           ),
           child,
         ],
       ),

   - Importa `SoftGridPainter`, `TopoLinesPainter` y `dart:math` si hace
     falta.

T3. Coordinación con A1
   Tras A1, el árbol rebuildea al cambiar fondo. Tu cambio aquí asegura
   que cada fondo se PINTE correctamente.

═══════════════════════════════════════════════════════════════════
VERIFICACIÓN:
═══════════════════════════════════════════════════════════════════
- `flutter analyze` 0 warnings.
- Smoke: Apariencia → Fondo → soft_grid → se ve cuadrícula sutil de
  fondo. topo_lines → curvas tipo mapa topográfico. smoke → humo (sin
  cambio). gradient → gradiente.

COMMIT:
feat(theme): patrones procedurales reales para soft_grid y topo_lines

REPORTE FINAL:
- Snippets de los painters y del wrapper.
- Confirmación de smoke.
```

---

### A7 — Reset config con backgroundId correcto + rebuild observable

```text
ROL: Engineer Flutter, mantenimiento.

CONTEXTO DEL PROYECTO: <pegar bloque "Contexto global">

PROBLEMA REPORTADO:
"Al darle a restaurar configuraciones no va tampoco a no ser que cambie
el fondo a no ser que salga y entre."

ROOT CAUSE:
- lib/features/appearance/widgets/reset_section.dart línea 71:
    tn.backgroundId = 'smoke';
  El ID en prefab_backgrounds es `'shaders/smoke.frag'`. El reset
  asigna un ID que no existe → `backgroundFromId('smoke')` cae a
  prefabBackgrounds.first (`NoneBackground`).
- Además, antes de A1 el reset no fuerza rebuild visible — tras A1 ya
  sí (porque cualquier cambio en visualKey forzará rebuild). Confirma
  que A1 está integrado antes de probar.

OBJETIVO:
Corregir el ID del backgroundId en el reset.

ARCHIVOS PERMITIDOS:
- lib/features/appearance/widgets/reset_section.dart

═══════════════════════════════════════════════════════════════════
TAREAS CONCRETAS:
═══════════════════════════════════════════════════════════════════

T1. Fix del backgroundId
   - En reset_section.dart línea 71, cambia:
       tn.backgroundId = 'smoke';
     por:
       tn.backgroundId = 'shaders/smoke.frag';
   - Esto es el ID que existe en prefab_backgrounds.

T2. Verifica que TODOS los defaults del reset son válidos
   - paletteId = 'default' → existe (línea 296 de prefab_palettes).
   - backgroundId = 'shaders/smoke.frag' → tras T1.
   - mapStyle = 'streets' → en MapConfig.mapStyles ['streets', 'basic',
     'bright', 'dark', 'light'] sí existe.
   - Otros bool/double quedan claramente válidos.

T3. Mensaje de confirmación
   - El SnackBar al final ya está. Tras A1, el rebuild es visible.
   - Verifica que `l10n.appearanceResetDone` existe en los 3 .arb.

═══════════════════════════════════════════════════════════════════
VERIFICACIÓN:
═══════════════════════════════════════════════════════════════════
- `flutter analyze`
- Smoke: cambia paleta a "Forest", fondo a "soft_grid", fontScale a
  130%. Pulsa "Restaurar". La app vuelve INMEDIATAMENTE a paleta
  default, fondo humo, fontScale 100%. NO requiere salir/entrar.

COMMIT:
fix(theme): reset usa el ID correcto del fondo humo

REPORTE FINAL: confirma T1-T3.
```

---

### A8 — Dislexia: aplicar la fuente realmente a los widgets

```text
ROL: Engineer Flutter, especialista en design system y tipografía.

CONTEXTO DEL PROYECTO: <pegar bloque "Contexto global">

PROBLEMA REPORTADO:
"La fuente de dislexia tampoco va."

ROOT CAUSE:
- lib/core/theme/transit_theme.dart líneas 27-29:
    final textTheme = dyslexiaFontEnabled
        ? GoogleFonts.atkinsonHyperlegibleTextTheme(baseTextTheme)
        : baseTextTheme.apply(fontFamily: 'DM Sans');
  Esto aplica la fuente al `textTheme` del `ThemeData`. PERO la mayoría
  de widgets de Transitly NO usan `Theme.of(context).textTheme`; usan
  `TransitTypography.bodyPrimary(color)`, `bodySmall(color)`, etc., que
  son constructores Dart que devuelven `TextStyle` SIN consultar el
  contexto. La fuente jamás llega a aplicarse a esos estilos.

OBJETIVO:
Hacer que `TransitTypography` lea el flag `dyslexiaFontEnabled` del
provider global y elija fontFamily acorde, sin requerir migración masiva.

ARCHIVOS PERMITIDOS:
- lib/core/theme/transit_typography.dart
- lib/shared/providers/active_palette_provider.dart (helper getter)
- lib/core/theme/transit_theme.dart (verificar, no romper la aplicación
  al textTheme global)
- lib/features/appearance/widgets/font_section.dart (preview)

ARCHIVOS PROHIBIDOS:
- TODO el resto.

═══════════════════════════════════════════════════════════════════
TAREAS CONCRETAS:
═══════════════════════════════════════════════════════════════════

T1. Helper para leer dislexia desde el container global
   En active_palette_provider.dart añade:
       bool isDyslexiaEnabled() {
         final container = _appContainer;
         if (container == null) return false;
         try {
           return container.read(themeNotifierProvider).dyslexiaFontEnabled;
         } catch (_) { return false; }
       }

T2. Refactor TransitTypography
   En lib/core/theme/transit_typography.dart, busca todos los métodos
   públicos que devuelven `TextStyle(...)` con `fontFamily: 'DM Sans'`
   o similar. Para cada uno, cambia el fontFamily a un helper:

       static String get _activeFontFamily =>
           isDyslexiaEnabled() ? 'Atkinson Hyperlegible' : 'DM Sans';

   Y aplica `fontFamily: _activeFontFamily` en cada constructor.

   IMPORTANTE: los TextStyle de TransitTypography son `const` actualmente
   (probable). Para usar un getter dinámico hay que quitar el `const` y
   convertir cada método de constructor literal a una función estática
   que devuelva TextStyle no-const.

   Antes:
       static const TextStyle bodyPrimary(Color c) => TextStyle(...);
     (esto no compila con const en realidad; los métodos generan style en
     cada llamada — probablemente son `static TextStyle bodyPrimary(Color c) =>
     TextStyle(...)` ya).
   Tras:
       static TextStyle bodyPrimary(Color c) => TextStyle(
         fontFamily: _activeFontFamily,
         fontSize: 15,
         color: c,
         ...
       );

T3. Cargar la fuente Atkinson Hyperlegible
   - Si está disponible vía GoogleFonts y la app permite runtime fetching,
     usa GoogleFonts.atkinsonHyperlegible() para obtener TextStyle base.
     PERO `main.dart` línea 39 indica `allowRuntimeFetching = false`.
     Por tanto la fuente DEBE estar empaquetada como asset.
   - Comprueba si `assets/fonts/atkinson_hyperlegible/` existe. Si no,
     descarga las variantes y añade en pubspec.yaml:
       fonts:
         - family: Atkinson Hyperlegible
           fonts:
             - asset: assets/fonts/atkinson_hyperlegible/AtkinsonHyperlegible-Regular.ttf
             - asset: assets/fonts/atkinson_hyperlegible/AtkinsonHyperlegible-Bold.ttf
               weight: 700
     y `flutter pub get`.
   - Si no puedes descargar la fuente, deja un fallback honesto: usa
     `'OpenDyslexic'` si está disponible o `'DM Sans'` con peso bold y
     letter-spacing aumentado (palliativo). Documenta el fallback.

T4. Preview en FontSection
   - lib/features/appearance/widgets/font_section.dart línea 73-77:
     el preview ya usa TransitTypography.bodyPrimary que ahora respeta
     dyslexia. Solo verifica visualmente que al activar el toggle, el
     preview cambia.

═══════════════════════════════════════════════════════════════════
VERIFICACIÓN:
═══════════════════════════════════════════════════════════════════
- `flutter analyze`
- Smoke: Apariencia → Activar "Fuente para dislexia". TODA la app
  cambia de tipografía (no solo el preview). Si la fuente no está
  empaquetada y no se permite runtime, falla honesto (mensaje en la UI).

COMMIT(s):
- feat(a11y): tipografía dislexia aplicada globalmente vía TransitTypography
- chore(fonts): empaquetar Atkinson Hyperlegible (si añadiste assets)

REPORTE FINAL:
- Confirma T1-T4.
- Si tuviste que descargar/empaquetar la fuente, lista los archivos.
- Si dejaste un fallback, justifícalo.
```

---

## WAVE 3 — Brief

### A9 — Widgets nativos Android (carry-over de plan v2)

```text
ROL: Engineer Android + Flutter, especialista en home_widget y AppWidgetProvider.

CONTEXTO DEL PROYECTO: <pegar bloque "Contexto global">

PROBLEMA REPORTADO (POR TERCERA VEZ):
"Me siguen sin aparecer widgets en el móvil."

El plan v2 listó este trabajo y el v3 no lo abordó. Sigue pendiente.

EL BRIEF COMPLETO para A9 es IDÉNTICO al brief A7 del plan v2:
PLAN_REPARACION_2026_05_26_V2.md, sección "A7 — Widgets nativos Android
reales".

Resumen ultracorto:
1. Crear TransitlyNextBusWidget.kt y TransitlyMyLineWidget.kt en
   android/app/src/main/kotlin/.../widgets/ extendiendo HomeWidgetProvider.
2. Crear layouts XML widget_next_bus.xml y widget_my_line.xml en
   android/app/src/main/res/layout/.
3. Crear metadata XML widget_*_info.xml en android/app/src/main/res/xml/.
4. Registrar receivers en AndroidManifest.xml con android:exported="true".
5. Reescribir lib/data/widgets_native/widget_data_writer.dart para usar
   HomeWidget.saveWidgetData + HomeWidget.updateWidget.
6. Crear lib/shared/providers/widget_data_provider.dart que llame al
   writer cuando cambien favoritos / próxima salida.
7. Desbloquear lib/features/widgets_native/widgets_settings_screen.dart
   en release mode.

VERIFICACIÓN:
- Build debug Android pasa.
- Instalar APK debug → long-press home → Widgets → Transitly → añadir.
- Widget muestra próximo bus de la línea favorita configurada en la
  pantalla "widgets settings".

COMMIT:
feat(widgets-android): home widgets nativos para próximo bus y estado línea
```

---

## WAVE 4 — Coordinador

1. `flutter gen-l10n` si A1/A6 añadieron claves.
2. `flutter analyze` → 0 warnings.
3. `flutter test` → verde.
4. **Smoke completo, en este orden estricto:**
   - Abre la app fresca (clear app data si es posible).
   - Splash nativo → logo completo, sin recorte.
   - Splash Dart → logo completo a 240-300px.
   - Home → tarjeta de invitado → "ENTRAR" → carga /sign-in sin 404.
   - Apariencia:
     - Cambia paleta a Sunrise → TODA la app se vuelve naranja.
     - Cambia paleta a Forest → verde.
     - Cambia paleta a Ocean → cyan/azul.
     - Cambia paleta a Mono → grises.
     - Cambia tema a Light → fondo claro, mapa claro.
     - Cambia mapStyle a "dark" → tiles del mapa cambian.
     - Cambia fondo a "soft_grid" → cuadrícula visible.
     - Cambia fondo a "topo_lines" → curvas visibles.
     - Activa Alto Contraste → bordes 2px, fondos opacos.
     - Activa Dislexia → tipografía Atkinson Hyperlegible se aplica
       en TODAS las pantallas (home, mapa, perfil, etc.).
     - Activa Reducir Movimiento → al navegar entre tabs no hay slide.
     - Daltonismo → BottomSheet bonito, ColorFilter aplica.
     - Slider de fontScale al 140% → ninguna pantalla crashea.
     - Pulsa "Restaurar configuraciones" → vuelve a defaults INSTANTE
       (sin salir/entrar).
   - Mapa: expande sheet a máximo → FAB ubicación queda visible encima
     del sheet, no tapado.
   - Widgets: instala APK debug en Android, añade widget al escritorio →
     visible y muestra datos.
5. Build APK release opcional si el usuario lo pide.

---

## Errores → agentes (mapeo final)

| # | Error reportado por el usuario | Agente principal |
|---|--------------------------------|-------------------|
| 1 | "En personalización solo se aplican las paletas al cambiar el fondo" | A1 (root cause global) |
| 2 | "Al cambiar el tamaño de letra la app da error y se cierra" | A2 |
| 3 | "El estilo de mapa no cambia da igual cual elijas" | A5 |
| 4 | "Cuando cambias de modo oscuro a claro el mapa tampoco se adapta" | A5 + A1 |
| 5 | "Los fondos no cambian … se queda permanentemente en el de humo" | A6 + A1 |
| 6 | "La fuente de dislexia tampoco va" | A8 + A1 |
| 7 | "Al darle a restaurar configuraciones no va" | A7 + A1 |
| 8 | "El botón de ubicación es tapado por el menú donde están todas las líneas" | A4 |
| 9 | "Me siguen sin aparecer widgets en el móvil" | A9 |
| 10 | "El icono de entrada se ve atacado" | A3 |

---

## Riesgos

- **A1 es el punto de palanca**: si funciona, casi todos los bugs de
  personalización quedan resueltos automáticamente. Si falla (ej.
  KeyedSubtree rompe scroll/animaciones de forma inaceptable), considerar
  alternativa: `InheritedNotifier` con migración explícita de los
  callsites más usados.
- **A2 (crash fontScale)**: no se ha podido reproducir desde el repo
  porque el bug es runtime. A2 debe ejecutar la app y atrapar el stack.
- **A5 (caché FMTC)**: el cambio puede multiplicar el uso de disco
  (un store por estilo). Documentar la limitación.
- **A6 (procedural painters)**: el `repaint` se dispara cada vez que el
  scheme cambia; si el árbol entero rebuildea (gracias a A1), el painter
  se reconstruye también. No es crítico para performance.
- **A8 (fuente dislexia)**: dependencia de empaquetar fuente con un .ttf
  real. Si no está disponible, fallback documentado.
- **A9 (widgets nativos)**: requiere build Android real. Si el coordinador
  no tiene Android disponible, queda en "compila debug" sin verificación
  visual.
