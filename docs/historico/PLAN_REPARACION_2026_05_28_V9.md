# Plan de reparación v9 — Transitly (mapa, filtros, permisos, dislexia)

**Fecha:** 2026-05-28
**Autor:** Claude Code (Opus 4.7)
**Plan anterior:** `PLAN_REPARACION_2026_05_28_V8.md`

---

## TL;DR — Diagnóstico

| # | Error reportado | Causa raíz | Agente |
|---|------------------|--------------|--------|
| 1 | Paradas cerca + dot del mapa no se activan hasta reiniciar tras dar permisos | `userLocationPermissionProvider` es FutureProvider, se evalúa UNA vez y no se invalida cuando Android devuelve "granted". `userLocationStreamProvider` lee del service pero NO observa cambios de permiso en runtime. Solución: tras pulsar el FAB y conceder permiso, invalidar el provider. | A1 |
| 2 | Fuente dislexia sigue sin funcionar | OpenDyslexic empaquetada, `_activeFontFamily` la pide, pero `visualKey` puede no estar disparando rebuild O la fuente no carga (caché de Flutter). Hipótesis: `flutter clean && pub get` no se ejecutó tras añadir las fuentes nuevas. | A2 |
| 3 | Preview de estilo: quiero chips arriba + recuadro grande abajo | El v8 puso un mini mapa por chip (5 mapas activos pesados). Refactor: chips compactos solo con icono+label arriba, **un solo recuadro grande abajo** mostrando el estilo seleccionado. | A3 |
| 4 | Mapa no cambia al cambiar estilo o tarda en hacerlo | El `TileLayer` se reconstruye pero el `FMTCTileProvider` puede estar cacheando agresivamente con clave compartida. Forzar invalidación de tiles + key compuesta. | A3 |
| 5 | Checkboxes urbano y COMUJESA "no van bien" | `_OperatorTree` usa una mezcla de `activeOperators`/`activeKinds` (set vacío = todos visibles) con `disabledLines` (set vacío = todos visibles). Semántica inconsistente confunde. Refactor a `disabled*` para todos. | A4 |
| 6 | Falta botón "Seleccionar todas/ninguna" | Feature nueva. Texto link al lado del título de sección con cascade. | A4 |
| 7 | Rutas desactivadas siguen clicables y muestran paradas | `_filteredRoutes` en map_tab filtra el listado del sheet pero NO se pasa al `transit_map.dart` que dibuja polylines/markers de TODAS las routes. | A5 |
| 8 | Toggle "Mostrar paradas" sin clicar ruta | Feature nueva. `MapFilterState.showAllStops: bool`. En transit_map, si `true` → mostrar paradas de TODAS las rutas visibles. | A5 |

---

## Decisiones tomadas contigo

- **Preview mapa**: chips compactos arriba + recuadro grande del mapa abajo (un solo mapa que cambia con la selección).
- **Botón seleccionar todas**: link texto "Todas / Ninguna" al lado del título de cada sección.
- **Paradas independientes**: toggle "Mostrar paradas" dentro del sheet de filtros.
- **Rutas desactivadas**: invisibles e inclicables (polylines, markers, paradas — todo desaparece).

---

## Estructura

```
WAVE 1 (5 agentes paralelos, sin solape de archivos)
├── A1  Permisos de ubicación: invalidate sin reiniciar app
├── A2  Dislexia: verificar y forzar uso de OpenDyslexic
├── A3  Map style: chips arriba + recuadro grande abajo + tile cache fix
├── A4  Filtros: semántica consistente + "Todas/Ninguna" + tri-state
└── A5  Rutas desactivadas invisibles + toggle "Mostrar paradas"

WAVE 2 (coordinador)
└── flutter clean + pub get + analyze + build APK release + install
```

### Tabla de archivos por agente

| Agente | Archivos que modifica |
|--------|------------------------|
| **A1** | `lib/shared/providers/user_location_provider.dart`, `lib/features/home/tabs/map_tab.dart` (SOLO `_centerOnUser` y cleanup invalidate), `lib/features/home/tabs/home_tab.dart` (paradas cerca: invalidar provider tras permiso) |
| **A2** | `pubspec.yaml` (verificar fonts), `lib/core/theme/transit_typography.dart` (verificar), `lib/shared/providers/active_palette_provider.dart` (verificar isDyslexiaEnabled), añadir log de debug temporal si requiere |
| **A3** | `lib/features/appearance/widgets/map_style_section.dart` (refactor visual), `lib/features/map/transit_map.dart` (SOLO TileLayer key), `lib/features/home/tabs/map_tab.dart` (SOLO la key del TransitMap), `lib/data/fmtc/fmtc_provider.dart` (verificar family por estilo) |
| **A4** | `lib/features/map/map_filter_state.dart` (renombrar a `disabled*` everywhere), `lib/features/map/map_filter_controller.dart` (métodos `selectAllX`/`clearAllX`), `lib/features/map/widgets/map_filter_sheet.dart` (UI con botones Todas/Ninguna + tri-state checkboxes), `lib/features/home/tabs/map_tab.dart` (SOLO `_filteredRoutes` con nueva semántica) |
| **A5** | `lib/features/map/map_filter_state.dart` (añadir `showAllStops`), `lib/features/map/map_filter_controller.dart` (setter), `lib/features/map/widgets/map_filter_sheet.dart` (toggle UI), `lib/features/map/transit_map.dart` (lógica de mostrar paradas + filtrar polylines/markers desactivados), `lib/features/home/tabs/map_tab.dart` (pasar filteredRoutes a TransitMap) |

### Conflictos controlados

- `map_tab.dart`: A1 (centerOnUser), A3 (key TransitMap), A4 (_filteredRoutes), A5 (pasar filteredRoutes). 4 agentes tocan el archivo. Estrategia: edits puntuales en zonas no solapadas. El coordinador hace merge si hay conflictos.
- `map_filter_state.dart`: A4 (renombrar) y A5 (añadir showAllStops). A4 ejecuta primero, A5 hace `set showAllStops` sobre la base ya renombrada. Coordinar.
- `map_filter_sheet.dart`: A4 (botones Todas/Ninguna + tri-state) y A5 (toggle showAllStops). Son secciones distintas del sheet. Sin solape real.
- `map_filter_controller.dart`: A4 (selectAll/clearAll) y A5 (setShowAllStops). Sin solape.

**Si A4 y A5 entran simultáneos** y los freezed regenerados conflictan: el coordinador hace `dart run build_runner build --delete-conflicting-outputs` al final.

---

## Contexto global (pegar en todos los briefs)

```
PROYECTO: Transitly (nexto-stop-v2) — App Flutter de transporte público para Jerez.
STACK: Flutter 3.9.2+, Riverpod 2.6.1, flutter_map 7.0.2,
flutter_map_tile_caching 10.0.0, hive 2.2.3, geolocator 13.0.0.
DIRECTORIO: C:\Users\k\Desktop\all\clase\nexto-stop-v2
RAMA: master
APK INSTALADO: app-release con dart-defines (Supabase URL/Anon Key, PostHog).

REGLAS:
- 0 warnings de flutter analyze.
- Tokens del design system (TransitColorScheme, TransitTypography, TransitSpacing).
- Commits en español con prefijo convencional.
- NO ejecutar flutter build apk --release ni git push salvo si lo pide el usuario.

ESTADO PREVIO TRAS v8:
- OpenDyslexic empaquetada en assets/fonts/opendyslexic/.
- transit_typography pide 'OpenDyslexic' cuando dislexia activada.
- map_style_section tiene preview con icono + mini mapa por cada chip.
- background_wrapper con opacidades subidas y Scaffold de Apariencia transparente.
- KeyedSubtree con visualKey en app.dart para forzar rebuild del árbol.
```

---

## WAVE 1 — Briefs

### A1 — Permisos de ubicación: actualizar sin reiniciar app

```text
ROL: Engineer Flutter, Riverpod async + geolocator.

CONTEXTO DEL PROYECTO: <pegar bloque "Contexto global">

PROBLEMA REPORTADO:
"Lo de paradas cerca de ti y el dot del mapa al darle permisos de
ubicación no se activan hasta reiniciar la app."

ROOT CAUSE:
- lib/shared/providers/user_location_provider.dart:
    final userLocationPermissionProvider =
        FutureProvider<LocationPermission>((ref) async {
      final service = ref.read(userLocationServiceProvider);
      return service.ensurePermission();
    });
  Este FutureProvider se evalúa UNA vez. Si el usuario deniega y luego
  concede, NO se re-evalúa hasta que algo invalide el provider.
- userLocationStreamProvider escucha geolocator pero solo arranca con
  el primer fix tras permiso concedido. Si arrancó con permiso denied,
  el stream queda vacío.
- map_tab.dart _centerOnUser pide permiso con `Geolocator.requestPermission()`
  pero NO invalida los providers tras conceder → la app sigue viendo
  el estado viejo.
- home_tab.dart "Paradas cerca de ti" lee userLocationStreamProvider que
  está vacío → sigue mostrando "sin GPS" hasta restart.

OBJETIVO:
Tras conceder permiso (desde el FAB de ubicación o desde Ajustes del
sistema), la app debe arrancar el stream INMEDIATAMENTE sin requerir
reinicio. Tanto el dot del mapa como "paradas cerca" deben aparecer.

ARCHIVOS PERMITIDOS:
- lib/shared/providers/user_location_provider.dart
- lib/features/home/tabs/map_tab.dart  ← SOLO `_centerOnUser` y cleanup
  de invalidación tras permiso. NO toques otros métodos.
- lib/features/home/tabs/home_tab.dart  ← SOLO el bloque de "paradas
  cerca" si requiere invalidación.

═══════════════════════════════════════════════════════════════════
TAREAS:
═══════════════════════════════════════════════════════════════════

T1. Invalidar providers tras conceder permiso
   En map_tab.dart `_centerOnUser`, tras
   `Geolocator.requestPermission()`:
       if (permission == LocationPermission.whileInUse ||
           permission == LocationPermission.always) {
         // Permiso concedido en runtime → reiniciar providers
         ref.invalidate(userLocationPermissionProvider);
         ref.invalidate(userLocationStreamProvider);
         // Esperar al primer fix
         try {
           await ref.read(userLocationStreamProvider.future)
               .timeout(const Duration(seconds: 6));
         } on TimeoutException {
           // sin fix todavía; fallback a getCurrentPosition
         }
       }

T2. Listener en autoDispose del stream con re-check al resume
   En lib/shared/providers/user_location_provider.dart:
   - El `userLocationStreamProvider` es `autoDispose`. Si nadie escucha,
     se cierra. Eso está bien.
   - Pero si el usuario sale a Ajustes del sistema y vuelve concediendo
     permiso, el `WidgetsBindingObserver.didChangeAppLifecycleState`
     en `_TransitlyAppWithLifecycle` (main.dart) puede invalidar los
     providers en resume.
   - Añade el invalidate dentro del observer existente:

     En main.dart (sólo añade, no rompas el existente):
         @override
         void didChangeAppLifecycleState(AppLifecycleState state) {
           final container = ProviderScope.containerOf(context);
           final service = container.read(mockRealtimeServiceProvider);
           if (state == AppLifecycleState.paused) {
             service.pause();
           } else if (state == AppLifecycleState.resumed) {
             service.resume();
             // Re-evaluar permisos por si el usuario volvió desde Ajustes
             container.invalidate(userLocationPermissionProvider);
             container.invalidate(userLocationStreamProvider);
           }
         }

   Si main.dart está fuera de tu scope: documenta este cambio para que
   el coordinador lo aplique. NO toques main.dart si te lo prohíbe la
   tabla de archivos.

T3. home_tab.dart "paradas cerca": refrescar al ganar permiso
   En home_tab.dart, en el bloque que decide qué center usar para
   `getNearbyStops`:
   - Si `userLocationFix` viene vacío, mostrar EmptyState con CTA
     "Activar ubicación" que llame a `_centerOnUser`-equivalente
     (Geolocator.requestPermission + invalidate).
   - Si ya viene un fix tras invalidate, las paradas cercanas aparecen
     en el próximo build (porque watch del provider rebuildea).

═══════════════════════════════════════════════════════════════════
VERIFICACIÓN:
═══════════════════════════════════════════════════════════════════
- Smoke:
  1. Fresh install. Abrir app. Al primer prompt de permiso, DENEGAR.
  2. Ir al mapa → no hay dot. Ir a home → no hay paradas cerca.
  3. Pulsar el FAB ubicación del mapa → prompt aparece. CONCEDER.
  4. INSTANTÁNEAMENTE el dot aparece. Volver a home → "paradas cerca"
     aparece con tus paradas reales.
  5. (Bonus) Cerrar app (no swipe, solo background), ir a Ajustes
     del sistema, denegar permiso, volver a la app. El dot debe
     desaparecer. Volver a conceder → reaparece tras unos segundos.

COMMIT:
fix(geo): invalidar providers de ubicación tras permiso para que se
active sin reiniciar app
```

---

### A2 — Dislexia: verificar y forzar uso de OpenDyslexic

```text
ROL: Engineer Flutter, debug de assets y typography.

CONTEXTO DEL PROYECTO: <pegar bloque "Contexto global">

PROBLEMA REPORTADO:
"La fuente de dislexia no va."

Esto se ha reportado 6 veces en planes anteriores. v8 empaquetó
OpenDyslexic. Si SIGUE sin funcionar, posibles causas no descartadas:

HIPÓTESIS A — la fuente no se carga (asset path mal):
- pubspec.yaml declara `family: OpenDyslexic` con assets
  `OpenDyslexic-Regular.otf` y `-Bold.otf`. Los archivos existen
  (verificado en assets/fonts/opendyslexic/).
- Si Flutter no carga el asset, los Text caen al fallback del sistema
  silenciosamente → el usuario percibe que NO cambia la fuente.

HIPÓTESIS B — el rebuild no se dispara al cambiar el toggle:
- `visualKey` debe incluir `_dyslexiaFontEnabled`. Verifica en
  theme_notifier.dart línea ~144 que sí esté incluido.
- KeyedSubtree con visualKey en app.dart debe forzar rebuild del árbol.

HIPÓTESIS C — TextStyle se cachea en algún widget:
- Algún widget hace `late final TextStyle _x = TransitTypography.bodyPrimary(...)`
  → el style se evalúa una vez y no cambia.

OBJETIVO:
Que al activar el toggle de dislexia en Apariencia, INMEDIATAMENTE todas
las letras de la app cambien a OpenDyslexic (la fuente con peso inferior
pesado, claramente distintiva).

ARCHIVOS PERMITIDOS:
- pubspec.yaml (verificar)
- lib/core/theme/transit_typography.dart
- lib/shared/providers/active_palette_provider.dart (verificar
  isDyslexiaEnabled)
- lib/shared/providers/theme_notifier.dart (SOLO verificar que
  visualKey incluye dyslexiaFontEnabled)

═══════════════════════════════════════════════════════════════════
TAREAS:
═══════════════════════════════════════════════════════════════════

T1. Verificar el asset realmente se carga
   - Lee pubspec.yaml líneas ~106-117. Confirma:
       family: OpenDyslexic
       fonts:
         - asset: assets/fonts/opendyslexic/OpenDyslexic-Regular.otf
         - asset: assets/fonts/opendyslexic/OpenDyslexic-Bold.otf
   - Ejecuta: `ls assets/fonts/opendyslexic/` → debe listar los .otf.
   - Ejecuta: `flutter clean && flutter pub get` para forzar recarga
     del asset bundle.

T2. Smoke test directo de la fuente
   Crea un test temporal o un check inline en la app para visualizar
   directamente la fuente:
   - Añade en `appearance_screen.dart` (debajo de FontSection) un
     `Text('Vista previa dislexia: 1l Iio bd pq', style: TextStyle(
       fontFamily: 'OpenDyslexic', fontSize: 18))` ESTÁTICO (sin
     condicional). Si AHÍ se ve la fuente OpenDyslexic con su
     característica visual, la fuente está bien cargada y el bug está
     en otra capa. Si AHÍ no se ve, el asset no carga.
   - Borra el Text temporal al confirmar.

T3. Si la fuente carga pero el toggle no la activa
   Verifica:
   - active_palette_provider.dart `isDyslexiaEnabled()`: ¿está bien
     leyendo del container?
   - theme_notifier.dart visualKey: contiene `_dyslexiaFontEnabled` →
     correcto.
   - transit_typography.dart `_activeFontFamily`: devuelve
     `'OpenDyslexic'` cuando dyslexia activa.

   Si todo eso es correcto pero los widgets siguen sin cambiar, AÑADE
   un parámetro forzado: cambia el getter `_activeFontFamily` a método
   normal que devuelve siempre el mismo string en cada llamada:

       static String _activeFontFamily({bool monospace = false}) {
         try {
           if (isDyslexiaEnabled()) return 'OpenDyslexic';
         } catch (_) {}
         return monospace ? 'IBM Plex Mono' : 'DM Sans';
       }

   (ya está así). Verifica que el try/catch no esté tragando un error.

T4. Forzar carga al inicio (preload)
   En main.dart (si no fuera de tu scope, documenta para el
   coordinador), tras `WidgetsFlutterBinding.ensureInitialized()`:
       await FontLoader('OpenDyslexic').load();
   Esto fuerza a Flutter a registrar la familia en el motor. NO debería
   ser necesario porque pubspec lo hace, pero en algunas versiones de
   Flutter ayuda como insurance.

T5. Si todo lo anterior falla
   Cambia la estrategia: en lugar de pintar TextStyle con `fontFamily:
   'OpenDyslexic'`, fuerza `fontFamilyFallback: ['OpenDyslexic', 'DM Sans']`
   junto con el fontFamily. Flutter usa el primero disponible.

═══════════════════════════════════════════════════════════════════
VERIFICACIÓN:
═══════════════════════════════════════════════════════════════════
- Smoke: tras `flutter clean && flutter pub get && flutter run`:
  1. Abre Apariencia → activa "Fuente para dislexia".
  2. Mira el título "TRANSITLY", los nombres de paradas, los códigos
     de línea. TODOS deben cambiar a OpenDyslexic (letras con peso
     inferior pesado característico).
  3. Las letras `b`, `d`, `p`, `q` se distinguen claramente entre sí.
     `1`, `I`, `l` son inconfundibles.

COMMIT:
fix(a11y): forzar carga de OpenDyslexic al arranque + verificación
```

---

### A3 — Map style: chips arriba + recuadro grande abajo + tile cache fix

```text
ROL: Engineer Flutter, UI + flutter_map.

CONTEXTO DEL PROYECTO: <pegar bloque "Contexto global">

PROBLEMAS REPORTADOS:
1. "En lo de estilo de mapa quiero que en vez de cada estilo se vea,
   haya un recuadro que vaya cambiando si seleccionas los diferentes
   tipos."
2. "El mapa no cambia si cambias el estilo de mapa o lo cambia al de
   mucho rato o al reiniciar a veces."

DECISIÓN DEL USUARIO:
"Chips compactos arriba + recuadro grande del mapa abajo (un solo mapa
que cambia con la selección)."

ESTADO ACTUAL:
- lib/features/appearance/widgets/map_style_section.dart muestra 5
  chips, cada uno con su PROPIO mini FlutterMap (5 mapas activos).
- transit_map.dart usa `widget.mapStyle ?? (widget.isDark ? 'dark' :
  'light')` en TileLayer.urlTemplate.
- map_tab.dart pasa `key: ValueKey('${isDark}-$mapStyle')` al TransitMap.

OBJETIVO:
1. Reemplazar 5 mini mapas por 5 chips compactos arriba + UN solo
   recuadro grande abajo (200×140) que muestra el estilo seleccionado.
2. El mapa principal del mapa debe cambiar INSTANTÁNEAMENTE al cambiar
   de estilo, sin tardanza ni necesidad de reinicio.

ARCHIVOS PERMITIDOS:
- lib/features/appearance/widgets/map_style_section.dart (refactor)
- lib/features/map/transit_map.dart (SOLO el TileLayer y su key)
- lib/features/home/tabs/map_tab.dart (SOLO la key de TransitMap)
- lib/data/fmtc/fmtc_provider.dart (verificar family por estilo)

═══════════════════════════════════════════════════════════════════
TAREAS:
═══════════════════════════════════════════════════════════════════

T1. Refactor MapStyleSection (chips arriba + 1 recuadro abajo)
   Reescribe lib/features/appearance/widgets/map_style_section.dart:

       class MapStyleSection extends ConsumerWidget {
         // ... constructor ...
         static const _jerezCenter = LatLng(36.6852, -6.1366);

         @override
         Widget build(BuildContext context, WidgetRef ref) {
           final mapStyle = ref.watch(themeNotifierProvider.select((n) => n.mapStyle));
           final styleKeys = MapConfig.mapStyles.keys.toList();

           return GlassCard(
             blur: 16,
             fillOpacity: 0.05,
             borderRadius: 14,
             padding: const EdgeInsets.all(16),
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 GradientText(/* ... título ... */),
                 const SizedBox(height: 12),
                 // 1) Chips compactos arriba (horizontal scroll si no caben)
                 SizedBox(
                   height: 64,
                   child: ListView.separated(
                     scrollDirection: Axis.horizontal,
                     itemCount: styleKeys.length,
                     separatorBuilder: (_, __) => const SizedBox(width: 8),
                     itemBuilder: (_, i) {
                       final key = styleKeys[i];
                       final selected = key == mapStyle;
                       return _StyleChip(
                         styleKey: key,
                         label: _styleLabel(key),
                         icon: _styleIcon(key),
                         styleAccent: _styleAccent(key),
                         selected: selected,
                         c: c,
                         onTap: () =>
                             ref.read(themeNotifierProvider).mapStyle = key,
                       );
                     },
                   ),
                 ),
                 const SizedBox(height: 12),
                 // 2) Recuadro grande del mapa abajo
                 ClipRRect(
                   borderRadius: BorderRadius.circular(12),
                   child: SizedBox(
                     width: double.infinity,
                     height: 160,
                     child: IgnorePointer(
                       child: FlutterMap(
                         key: ValueKey('preview-$mapStyle'),
                         options: const MapOptions(
                           initialCenter: _jerezCenter,
                           initialZoom: 13.5,
                           interactionOptions: InteractionOptions(
                             flags: InteractiveFlag.none,
                           ),
                         ),
                         children: [
                           TileLayer(
                             urlTemplate: MapConfig.tileUrl(mapStyle),
                             subdomains: MapConfig.subdomains,
                             userAgentPackageName: 'com.transitly.transitly',
                             tileProvider: NetworkTileProvider(),
                           ),
                         ],
                       ),
                     ),
                   ),
                 ),
               ],
             ),
           );
         }
       }

       class _StyleChip extends StatelessWidget {
         // Chip pequeño con icono + label, sin mini mapa.
         // Estructura: Container redondeado con padding 8, Column
         // (Icon 18 + SizedBox 4 + Text 11sp). Bordes accent si selected.
       }

T2. Tile cache fix en el mapa principal
   El bug "no cambia el estilo" tiene varias capas. Combina TODO:

   a) En map_tab.dart, la key de TransitMap ya incluye mapStyle. Verifica
      que sigue así:
         key: ValueKey('${isDark ? 'd' : 'l'}-$mapStyle')

   b) En transit_map.dart, dentro del FlutterMap, el TileLayer:
         TileLayer(
           key: ValueKey('tiles-$mapStyle-${isDark}'),  // ← AÑADIR ESTA KEY
           urlTemplate: MapConfig.tileUrl(
             widget.mapStyle ?? (widget.isDark ? 'dark' : 'light'),
           ),
           subdomains: MapConfig.subdomains,
           tileProvider: widget.fmtcTileProvider,
           userAgentPackageName: 'com.transitly.transitly',
           tileDisplay: const TileDisplay.fadeIn(
             duration: Duration(milliseconds: 200),
           ),
         )
      La key explícita en TileLayer fuerza a flutter_map a desechar las
      tiles cacheadas en memoria al cambiar el estilo.

   c) FMTC family por estilo: verifica que
      lib/data/fmtc/fmtc_provider.dart sigue siendo
      `Provider.family<FMTCTileProvider?, String>` y que map_tab.dart
      lo lee como:
         final mapStyle = ref.watch(themeNotifierProvider.select((n) => n.mapStyle));
         final fmtcTp = ref.watch(fmtcTileProviderProvider(mapStyle));
      Si no es así, ajústalo.

═══════════════════════════════════════════════════════════════════
VERIFICACIÓN:
═══════════════════════════════════════════════════════════════════
- Smoke:
  1. Apariencia → Estilo de mapa: ves chips compactos arriba (5
     iconos+labels) y un recuadro grande abajo con el mapa del estilo
     seleccionado.
  2. Pulsa un chip → el recuadro grande cambia INMEDIATAMENTE al nuevo
     estilo.
  3. Vuelve al mapa principal (Inicio → Mapa) → el mapa también cambió
     al estilo nuevo.
  4. Repite con todos los estilos. En cada cambio, el mapa principal
     refresca en < 2 segundos.

COMMIT(s):
- refactor(appearance): preview de mapa con chips arriba y recuadro abajo
- fix(map): tile layer reactivo con key explícita por estilo
```

---

### A4 — Filtros: semántica consistente + "Todas/Ninguna" + tri-state

```text
ROL: Engineer Flutter senior, Riverpod + UX de filtros.

CONTEXTO DEL PROYECTO: <pegar bloque "Contexto global">

PROBLEMAS REPORTADOS:
1. "Los checkboxes de filtros de mapa de urbano y COMUJESA no van bien."
2. "Para cada sección haya un botón o algo para seleccionar todas."

ROOT CAUSE:
- map_filter_state.dart mezcla semánticas:
    Set<String> activeOperators  → set vacío = TODOS activos (legacy)
    Set<String> activeKinds      → ídem
    Set<String> disabledLines    → set vacío = TODOS activos (disable opt-in)
  La UI usa `f.activeOperators.isEmpty || f.activeOperators.contains(opId)`
  para determinar si está visible. Esa lógica es ambigua y produce
  comportamientos raros al marcar/desmarcar.

DECISIÓN DEL USUARIO:
"Botón texto 'Todas / Ninguna' al lado del título de sección."

OBJETIVO:
1. Renombrar `activeOperators`/`activeKinds` a `disabledOperators`/
   `disabledKinds` para semántica consistente (vacío = todos visibles,
   en set = oculto).
2. Añadir botones link "Todas" y "Ninguna" al lado del título de cada
   sección expandible.
3. Checkbox del padre con tri-state visual (vacío / mixto / lleno).

ARCHIVOS PERMITIDOS:
- lib/features/map/map_filter_state.dart (renombrar campos)
- lib/features/map/map_filter_controller.dart (métodos selectAll/clearAll/setOperatorVisible)
- lib/features/map/widgets/map_filter_sheet.dart (UI nueva)
- lib/features/home/tabs/map_tab.dart  ← SOLO `_filteredRoutes` para
  usar la nueva semántica.

═══════════════════════════════════════════════════════════════════
TAREAS:
═══════════════════════════════════════════════════════════════════

T1. Renombrar en MapFilterState
   En lib/features/map/map_filter_state.dart, refactoriza:
       // Antes:
       @Default(<String>{}) Set<String> activeOperators,
       @Default(<String>{}) Set<String> activeKinds,
       @Default(<String>{}) Set<String> disabledLines,

       // Después (todos con la misma semántica "vacío = ver todo"):
       @Default(<String>{}) Set<String> disabledOperators,
       @Default(<String>{}) Set<String> disabledKinds,
       @Default(<String>{}) Set<String> disabledLines,

   Regenerar:
       dart run build_runner build --delete-conflicting-outputs

T2. Métodos en el controller
   En map_filter_controller.dart:
       void toggleOperator(String opId) {
         final s = Set<String>.from(state.disabledOperators);
         if (s.contains(opId)) s.remove(opId); else s.add(opId);
         state = state.copyWith(disabledOperators: s);
       }
       // Idem para toggleKind y toggleLine.

       void selectAllOperators(List<String> allIds) {
         state = state.copyWith(disabledOperators: const {});
       }
       void clearAllOperators(List<String> allIds) {
         state = state.copyWith(disabledOperators: allIds.toSet());
       }
       // Idem para kinds y lines.

       /// Para tri-state: dado un padre (operador o zona) y sus hijos,
       /// devuelve 'all' / 'none' / 'mixed' según cuántos hijos están
       /// disabled.
       String childrenState({
         required List<String> childIds,
         required Set<String> disabledSet,
       }) {
         final disabledCount =
             childIds.where(disabledSet.contains).length;
         if (disabledCount == 0) return 'all';
         if (disabledCount == childIds.length) return 'none';
         return 'mixed';
       }

T3. UI con botones "Todas/Ninguna" + tri-state
   En map_filter_sheet.dart, en `_OperatorTree`:

   - Reemplaza el ExpansionTile del operador por:
       Column(
         children: [
           Row(
             children: [
               // Tri-state checkbox del operador
               Checkbox(
                 tristate: true,
                 value: _triStateOf(opState),  // null = mixed, true = all, false = none
                 onChanged: (_) {
                   if (opState == 'all') {
                     ctrl.clearAllLines(allOpLineIds);  // ahora deshabilitar todas
                   } else {
                     ctrl.selectAllLines(allOpLineIds);  // habilitar todas
                   }
                 },
               ),
               Expanded(child: Text(opName, ...)),
               // Botón texto Todas / Ninguna
               TextButton(
                 onPressed: () => ctrl.selectAllLines(allOpLineIds),
                 child: Text('Todas',
                     style: TransitTypography.bodySmall(c.accent)),
               ),
               TextButton(
                 onPressed: () => ctrl.clearAllLines(allOpLineIds),
                 child: Text('Ninguna',
                     style: TransitTypography.bodySmall(c.textMid)),
               ),
             ],
           ),
           // Sub-secciones (zones) con la misma estructura
           for (final kind in serviceTypes)
             _KindBlock(
               kind: kind,
               kindLines: routes.where((r) => r.serviceType == kind).toList(),
               disabledLines: f.disabledLines,
               c: c,
               ctrl: ctrl,
             ),
         ],
       )

   - `_KindBlock` es un widget análogo con su checkbox tri-state y
     botones Todas/Ninguna sobre las líneas hijas.
   - Las líneas individuales: `CheckboxListTile` cuyo `value` es
     `!f.disabledLines.contains(route.id)` y `onChanged` llama a
     `ctrl.toggleLine(route.id)`.

   - Helper:
       bool? _triStateOf(String state) {
         switch (state) {
           case 'all': return true;
           case 'none': return false;
           case 'mixed': return null;
           default: return true;
         }
       }

T4. Aplicar nueva semántica en _filteredRoutes
   En lib/features/home/tabs/map_tab.dart `_filteredRoutes`:
       final f = ref.read(mapFilterControllerProvider);
       final visible = routes.where((r) {
         if (f.disabledOperators.contains(r.operatorId)) return false;
         if (f.disabledKinds.contains(r.serviceType.name)) return false;
         if (f.disabledLines.contains(r.id)) return false;
         return true;
       }).toList();

═══════════════════════════════════════════════════════════════════
VERIFICACIÓN:
═══════════════════════════════════════════════════════════════════
- `flutter analyze` 0 warnings.
- Smoke:
  1. Abre filtros. Ves COMUJESA con checkbox tri-state, "Todas/Ninguna",
     y zonas expandibles.
  2. Pulsa "Ninguna" → todas las líneas se ocultan del mapa + del sheet.
  3. Pulsa "Todas" → reaparecen.
  4. Desmarca solo "Urbano" → COMUJESA pasa a tri-state mixto, todas
     las urbanas desaparecen, las demás siguen visibles.
  5. Desmarca solo "L5" individual → COMUJESA y Urbano pasan a mixto.

COMMIT(s):
- refactor(map): semántica consistente disabled* en filtros
- feat(map): botones Todas/Ninguna + checkbox tri-state en filtros
```

---

### A5 — Rutas desactivadas invisibles + toggle "Mostrar paradas"

```text
ROL: Engineer Flutter, flutter_map y filtros.

CONTEXTO DEL PROYECTO: <pegar bloque "Contexto global">

PROBLEMAS REPORTADOS:
1. "Se pueden hacer click en las rutas a pesar de que estén desactivadas
   y se ven las paradas y direcciones, cosa que no debería."
2. "Quiero que en el filtro se pueda activar y desactivar para ver las
   ubicaciones de las paradas sin tener que hacer click en la ruta."

DECISIONES DEL USUARIO:
- "Desactivadas = invisibles e inclicables."
- "Toggle 'Mostrar todas las paradas' en filtros."

ROOT CAUSE:
- map_tab.dart `_filteredRoutes` filtra el LISTADO del sheet inferior,
  pero pasa `routes: routes` (todas) al TransitMap → polylines y markers
  se dibujan para TODAS las rutas, incluidas las desactivadas.
- transit_map.dart `selectedRouteId` se establece al pulsar el polyline
  de cualquier ruta — sin verificar si está filtrada.

OBJETIVO:
1. Que TransitMap reciba solo las rutas no desactivadas.
2. Toggle "Mostrar paradas" en filtros que, si está ON, muestre todas
   las paradas de rutas visibles independientemente de selección.

ARCHIVOS PERMITIDOS:
- lib/features/map/map_filter_state.dart (añadir `showAllStops`)
- lib/features/map/map_filter_controller.dart (setter)
- lib/features/map/widgets/map_filter_sheet.dart (toggle UI)
- lib/features/map/transit_map.dart (lógica de stops + filtrar)
- lib/features/home/tabs/map_tab.dart (SOLO pasar filteredRoutes a
  TransitMap)

NOTA: A4 está renombrando `activeOperators` a `disabledOperators` y
añadiendo `selectAll/clearAll`. Si A4 entró primero, usa la API nueva.
Si entró después, coordina con A4 vía el coordinador.

═══════════════════════════════════════════════════════════════════
TAREAS:
═══════════════════════════════════════════════════════════════════

T1. Campo showAllStops en MapFilterState
   En map_filter_state.dart añade:
       @Default(false) bool showAllStops,

   Regenera freezed.

T2. Setter en controller
   En map_filter_controller.dart:
       void setShowAllStops(bool v) {
         state = state.copyWith(showAllStops: v);
       }

T3. Toggle en filter_sheet
   En map_filter_sheet.dart, añade una nueva sección antes de "Reset/Apply":
       _SectionTitle(c: c, title: 'Paradas'),
       Row(
         children: [
           Expanded(
             child: Text(
               'Mostrar paradas',
               style: TransitTypography.bodyPrimary(c.textHi),
             ),
           ),
           Switch.adaptive(
             value: f.showAllStops,
             activeTrackColor: c.accent,
             onChanged: (v) => ctrl.setShowAllStops(v),
           ),
         ],
       ),

T4. TransitMap: filtrar polylines y mostrar paradas globalmente
   En map_tab.dart, al construir TransitMap, pasa solo las rutas
   visibles:
       TransitMap(
         routes: filteredRoutes,  // ya filtradas por _filteredRoutes
         showAllStops: ref.watch(
             mapFilterControllerProvider.select((s) => s.showAllStops)),
         ...
       )

   Si `showAllStops` no existe como parámetro en TransitMap, añádelo:

       class TransitMap extends StatefulWidget {
         // ...
         final bool showAllStops;
         // ...
       }

   En la lógica de markers de paradas (en transit_map.dart):
       // Antes (simplificado):
       final visibleStops = selectedId == null
           ? const <StopModel>[]
           : (widget.routeStopsMap[selectedId] ?? const <StopModel>[]);

       // Después:
       final List<StopModel> visibleStops;
       if (widget.showAllStops) {
         // Unión de paradas de todas las rutas visibles.
         final set = <String, StopModel>{};
         for (final route in widget.routes) {
           for (final s in widget.routeStopsMap[route.id] ?? <StopModel>[]) {
             set[s.id] = s;
           }
         }
         visibleStops = set.values.toList();
       } else if (selectedId != null) {
         visibleStops = widget.routeStopsMap[selectedId] ?? const <StopModel>[];
       } else {
         visibleStops = const <StopModel>[];
       }

   - Las rutas desactivadas YA no llegan a TransitMap (porque filteredRoutes
     las excluye), así que sus polylines no se dibujan y no son
     clicables. Bug resuelto.
   - Las flechas direccionales solo se dibujan para la ruta seleccionada
     (ya pasaba); pero verifica que también filtran por rutas visibles.

T5. Documentar la unión de paradas
   Si `showAllStops == true` con TODAS las líneas activas, son 598
   paradas en el mapa. Performance: flutter_map maneja eso bien hasta
   cierto zoom. Si notas lag, añade culling por viewport (solo paradas
   dentro del bbox visible).

═══════════════════════════════════════════════════════════════════
VERIFICACIÓN:
═══════════════════════════════════════════════════════════════════
- Smoke:
  1. En filtros, desmarca COMUJESA → todas las líneas desaparecen del
     mapa. Intenta pulsar donde antes había una línea → no responde.
  2. Vuelve a activar todas. Activa el toggle "Mostrar paradas" →
     aparecen TODAS las paradas (598 en Jerez) sin necesidad de pulsar
     ninguna ruta.
  3. Desactiva el toggle → las paradas desaparecen.
  4. Selecciona una ruta (tap) → solo aparecen las paradas de esa ruta
     (comportamiento original).
  5. Vuelve a activar el toggle → paradas globales reaparecen.

COMMIT(s):
- fix(map): rutas desactivadas invisibles e inclicables
- feat(map): toggle "Mostrar paradas" en filtros
```

---

## WAVE 2 — Coordinador

1. **Generar freezed:**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
2. **Clean + análisis:**
   ```bash
   flutter clean
   flutter pub get
   flutter analyze
   flutter test
   ```
3. **Build APK release:**
   ```bash
   flutter build apk --release --dart-define-from-file=dart_defines.json
   ```
4. **Instalar en A142P:**
   ```bash
   flutter install --release -d 000871487002528
   ```
5. **Smoke completo en dispositivo:**
   - **A1**: tras denegar y luego conceder permisos, dot y "paradas
     cerca" aparecen sin reiniciar.
   - **A2**: activar dislexia → todas las letras cambian a OpenDyslexic.
   - **A3**: Apariencia → Estilo de mapa: chips arriba, recuadro grande
     abajo. Cambiar de estilo refresca tanto el preview como el mapa
     principal.
   - **A4**: filtros con botones Todas/Ninguna + tri-state.
   - **A5**: rutas desactivadas invisibles, toggle Mostrar paradas
     funcional.

---

## Propuestas adicionales (mejoras opcionales)

Aprovechando que tocamos filtros y mapa, aquí mejoras que añadirían
mucho valor con poco esfuerzo. **No incluidas en el plan principal
salvo que las apruebes:**

### P1 — Persistir `showAllStops`
Hoy los filtros se persisten en SharedPreferences. Asegurar que
`showAllStops` también se persiste para que el usuario lo recupere al
reabrir la app.

### P2 — Contador de líneas visibles en el sheet
Al lado del título "Mostrar líneas" en el filter_sheet, mostrar
`(12/19)` indicando cuántas de las 19 líneas están visibles. Da
feedback inmediato del estado del filtro.

### P3 — Filtro rápido: chips de estado en la cabecera del sheet del mapa
Encima del listado de líneas en el sheet inferior del mapa, fila de
chips: `Todas (19)` · `Solo favoritas (3)` · `Solo con buses ahora (2)`.
Filtros rápidos sin abrir el modal completo.

### P4 — Memoria del último estilo de mapa
Mostrar en una esquina del recuadro grande de preview el nombre del
estilo activo en pequeño ("Streets · MapTiler" o "OSM · Carto"), para
que el usuario sepa qué proveedor está usando.

### P5 — Indicador visual de permiso ubicación
Si no hay permiso, mostrar un banner pequeño arriba del mapa: "📍
Activa la ubicación para ver tu posición y paradas cercanas" con CTA
que abre Ajustes del sistema directamente.

### P6 — Refrescar dot al cambiar de tab
Cuando el usuario cambia de Home → Mapa y vuelve, invalidar el stream
para forzar un fix nuevo si el GPS ha mejorado de señal (cuando se
mueva).

¿Te interesa alguna? Si me dices "incluye P1, P2, P5", las añado al
plan como tareas separadas para los agentes correspondientes.

---

## Cobertura final

| # | Problema reportado | Agente |
|---|---------------------|--------|
| 1 | Permisos no se activan hasta reiniciar | A1 |
| 2 | Fuente dislexia no va | A2 |
| 3 | Preview de mapa: chips arriba + recuadro abajo | A3 |
| 4 | Mapa no cambia con estilo o tarda mucho | A3 |
| 5 | Checkboxes filtros mal | A4 |
| 6 | Falta botón Todas/Ninguna | A4 |
| 7 | Rutas desactivadas siguen clicables | A5 |
| 8 | Toggle Mostrar paradas | A5 |
