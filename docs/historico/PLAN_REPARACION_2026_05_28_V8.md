# Plan de reparación v8 — Transitly (logo, mapa, splash, preview)

**Fecha:** 2026-05-28
**Autor:** Claude Code (Opus 4.7)
**Plan anterior:** `PLAN_REPARACION_2026_05_27_V7.md`

---

## TL;DR — Diagnóstico

| # | Error reportado | Causa raíz exacta | Agente |
|---|------------------|---------------------|--------|
| 1 | Logo de entrada se ve cortado y aplastado | `assets/branding/transitly_logo_white_padded.png` mide **1805 × 1445** (ratio 1.249, NO cuadrado). El splash Dart fuerza a 280×280 → aplasta verticalmente. El splash nativo también renderiza distorsionado en algunos launchers. | A1 |
| 2 | Animación de entrada pobre | `splash_screen.dart` tiene solo `FadeTransition + ScaleTransition 0.85→1.0` para el logo + slide básico del título. Plano y "barato". | A4 |
| 3 | Estilo de mapa nunca cambia visualmente | FMTC tiene caché único compartido para todos los estilos. Los stores por estilo se crean pero las tiles cacheadas del estilo viejo se reutilizan. Además `fmtc_service.dart` usa `const store = FMTCStore(storeName)` con un nombre único, no por estilo. | A2 |
| 4 | Ajustes no se guardan al salir/entrar | El setter `mapStyle` llama `_persist()` (correcto), pero `_persist()` se aborta si `_initialized == false`. Si el usuario cambia el estilo ANTES de que termine la carga inicial, el cambio NO se persiste. Además, el flujo guest vs auth puede no llamar `loadGuest()` en algunos paths. | A2 |
| 5 | Preview del estilo de mapa solo muestra un círculo de color | `map_style_section.dart:42-51` usa `_stylePreviewColor` con un color plano por estilo, no una imagen real del mapa. | A3 |

---

## Decisiones tomadas contigo

- **Logo**: regenerar PNG cuadrado con padding 35% + actualizar splash nativo + icon launcher.
- **Preview mapa**: mini FlutterMap real con tiles vivas (uno por estilo).
- **Animación**: estilo premium con stagger + particles + glow pulsante.
- **Mapa**: ambos bugs simultáneos (no cambia + no persiste). A2 los aborda juntos.

---

## Estructura

```
WAVE 1 (4 agentes paralelos, sin solape de archivos)
├── A1  Logo cuadrado + splash nativo + icon launcher regen
├── A2  Mapa: estilo se aplica al instante + persiste tras reinicio
├── A3  Preview de mapa: mini FlutterMap real por estilo
└── A4  Splash Dart animación premium (stagger + particles + glow)

WAVE 2 (coordinador, NO agente)
└── flutter analyze + flutter test + smoke completo + build APK debug
```

### Tabla de archivos por agente

| Agente | Archivos que modifica | Archivos NUEVOS |
|--------|------------------------|------------------|
| **A1** | `pubspec.yaml` (config flutter_native_splash + flutter_launcher_icons), `assets/branding/` (regenerar PNG cuadrado), `android/app/src/main/res/drawable*/`, `android/app/src/main/res/mipmap*/`, `ios/Runner/Assets.xcassets/AppIcon.appiconset/`, `ios/Runner/Assets.xcassets/LaunchImage.imageset/` (regenerados por herramientas) | `assets/branding/transitly_logo_white_square.png` |
| **A2** | `lib/shared/providers/theme_notifier.dart` (hardenear `_persist` + asegurar `_loadGuestPrefs` se llama al arranque), `lib/data/fmtc/fmtc_service.dart` (crear store por estilo, no único), `lib/data/fmtc/fmtc_provider.dart` (verificar family), `lib/main.dart` (asegurar `loadGuest` se llama si no hay auth) | — |
| **A3** | `lib/features/appearance/widgets/map_style_section.dart` | — |
| **A4** | `lib/features/splash/splash_screen.dart` | `lib/features/splash/particles_painter.dart` |

### Conflictos controlados

- `assets/branding/`: solo A1 toca esta carpeta.
- `pubspec.yaml`: solo A1 toca (secciones de splash/icons).
- Sin otros solapes.

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
- Tokens del design system (TransitColorScheme, TransitTypography, TransitSpacing).
- Commits en español con prefijo convencional.
- NO ejecutar flutter build apk --release ni git push salvo si lo pide el usuario.

ESTADO PREVIO:
- Tras v7: 5 estilos OSM/Carto reales en map_config.dart, paletas
  consolidadas, Atkinson Hyperlegible empaquetada, RouteCard con
  color de línea, FAB anclado al sheet, filtros jerárquicos en sheet.
- v8 cierra los 4 problemas reportados: logo aplastado, mapa que no
  cambia ni persiste, falta preview de mapa, animación pobre.
```

---

## WAVE 1 — Briefs

### A1 — Logo cuadrado + splash nativo + icon launcher regen

```text
ROL: Engineer Flutter, branding y assets.

CONTEXTO DEL PROYECTO: <pegar bloque "Contexto global">

PROBLEMA REPORTADO:
"El icono/logo que aparece al entrar a la aplicación se ve cortado y
aplastado."

ROOT CAUSE CONFIRMADO:
- assets/branding/transitly_logo_white_padded.png mide 1805 × 1445
  → aspect ratio 1.249. NO es cuadrado.
- splash_screen.dart línea 122-127: `Image.asset(..., width: 280, height: 280)`
  fuerza a 280×280 → el aspect ratio 1.249 se aplasta a 1.0 → distorsión
  visual evidente.
- flutter_native_splash y flutter_launcher_icons también usan ese mismo
  PNG, por lo que el splash nativo y los iconos del launcher salen
  igualmente distorsionados.

DECISIÓN DEL USUARIO:
"Generar PNG cuadrado + actualizar splash nativo + icon launcher."

OBJETIVO:
1. Generar `transitly_logo_white_square.png` cuadrado (2048×2048) con
   el logo CENTRADO y padding transparente del 35% alrededor.
2. Actualizar pubspec.yaml (flutter_native_splash + flutter_launcher_icons)
   para usar el PNG cuadrado.
3. Regenerar todos los assets generados (android/, ios/).
4. Actualizar splash_screen.dart para usar el nuevo PNG.

ARCHIVOS PERMITIDOS:
- pubspec.yaml
- assets/branding/ (añadir el nuevo PNG)
- android/app/src/main/res/drawable*/ (regenerado)
- android/app/src/main/res/mipmap*/ (regenerado)
- ios/Runner/Assets.xcassets/AppIcon.appiconset/ (regenerado)
- ios/Runner/Assets.xcassets/LaunchImage.imageset/ (regenerado)
- lib/features/splash/splash_screen.dart  ← SOLO la línea
  `Image.asset(...)` (línea 122-127). NO toques la animación (es de A4).

ARCHIVOS PROHIBIDOS:
- Cualquier otra parte de splash_screen.dart (animación es de A4)
- theme_notifier.dart, fmtc_*.dart (es de A2)
- map_style_section.dart (es de A3)

═══════════════════════════════════════════════════════════════════
TAREAS CONCRETAS:
═══════════════════════════════════════════════════════════════════

T1. Generar PNG cuadrado con padding 35%
   Usa el script Python siguiente (PIL ya está instalado en el sistema
   del usuario; lo verifiqué). Crear el archivo cuadrado:

       from PIL import Image
       src = Image.open('assets/branding/transitly_logo_white.png').convert('RGBA')
       # Target: 2048×2048 con el logo centrado al 65% del tamaño
       target_size = 2048
       margin_ratio = 0.35  # 35% margin around the logo
       inner = int(target_size * (1 - margin_ratio))  # 1331 px
       # Scale src to fit `inner` while preserving aspect ratio
       w, h = src.size
       scale = inner / max(w, h)
       new_w, new_h = int(w * scale), int(h * scale)
       resized = src.resize((new_w, new_h), Image.LANCZOS)
       canvas = Image.new('RGBA', (target_size, target_size), (0, 0, 0, 0))
       x = (target_size - new_w) // 2
       y = (target_size - new_h) // 2
       canvas.paste(resized, (x, y), resized)
       canvas.save('assets/branding/transitly_logo_white_square.png', 'PNG')
       print(f'Saved {target_size}x{target_size} with logo {new_w}x{new_h}')

   Ejecuta el script una sola vez. Verifica que se creó el archivo y
   abre para confirmar visualmente que el logo se ve completo y
   centrado.

T2. Actualizar pubspec.yaml — flutter_launcher_icons
   En la sección flutter_launcher_icons:
       flutter_launcher_icons:
         android: "ic_launcher"
         ios: true
         image_path: "assets/branding/transitly_logo_white_square.png"
         adaptive_icon_background: "#08081A"
         adaptive_icon_foreground: "assets/branding/transitly_logo_white_square.png"
         adaptive_icon_foreground_inset: 0   # PNG ya tiene padding interno
         min_sdk_android: 21
         remove_alpha_ios: true

T3. Actualizar pubspec.yaml — flutter_native_splash
   En la sección flutter_native_splash:
       flutter_native_splash:
         color: "#08081A"
         image: assets/branding/transitly_logo_white_square.png
         android_12:
           icon_background_color: "#08081A"
           image: assets/branding/transitly_logo_white_square.png
         fullscreen: false

T4. Regenerar
   Ejecuta secuencialmente:
       flutter pub get
       dart run flutter_launcher_icons
       dart run flutter_native_splash:create

   Verifica que:
   - android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_foreground.png
     existe y NO tiene distorsión.
   - android/app/src/main/res/drawable-xxxhdpi/splash.png idem.
   - ios/Runner/Assets.xcassets/AppIcon.appiconset/ tiene las variantes.

T5. Actualizar splash_screen.dart (cambio mínimo)
   En lib/features/splash/splash_screen.dart línea 122-127:
   Cambia SOLO el path del asset:
       // Antes:
       child: Image.asset(
         'assets/branding/transitly_logo_white_padded.png',
         width: 280,
         height: 280,
         filterQuality: FilterQuality.high,
       ),
       // Después:
       child: Image.asset(
         'assets/branding/transitly_logo_white_square.png',
         width: 280,
         height: 280,
         filterQuality: FilterQuality.high,
       ),
   - NO toques otros aspectos del widget (FadeTransition, ScaleTransition,
     Column, etc.). Eso es jurisdicción de A4.

T6. Verificar pubspec.yaml assets
   En la sección `flutter > assets:` confirma que
   `- assets/branding/` está listado. Si no, añádelo:
       flutter:
         assets:
           - assets/branding/

═══════════════════════════════════════════════════════════════════
VERIFICACIÓN:
═══════════════════════════════════════════════════════════════════
- `flutter analyze` 0 warnings.
- `flutter build apk --debug` debe pasar (no ejecutes el de release).
- Instala el APK debug en un dispositivo Android:
  1. Al abrir la app, el splash NATIVO muestra el logo completo,
     centrado, SIN aplastar ni recortar.
  2. Cuando aparece el splash Dart (más tarde), el logo se ve a
     280×280 con sus proporciones correctas (las del PNG cuadrado).
  3. Long-press en el home de Android → ver el icono de la app: el
     logo está completo dentro de la máscara adaptive.

COMMIT(s):
- fix(branding): logo cuadrado sin aplastamiento (2048×2048 padding 35%)
- chore(branding): regenerar splash nativo + launcher icons

REPORTE FINAL:
- Tamaño del PNG generado y aspect ratio.
- Comandos ejecutados y output relevante.
- Confirmación visual de los 3 puntos del smoke.
```

---

### A2 — Mapa: estilo se aplica + persiste

```text
ROL: Engineer Flutter senior, Riverpod + Hive + flutter_map_tile_caching.

CONTEXTO DEL PROYECTO: <pegar bloque "Contexto global">

PROBLEMAS REPORTADOS:
1. "Al cambiar el mapa no carga el mapa."
2. "Si salgo y entro los ajustes no se guardan."

ROOT CAUSE 1 (no carga):
- lib/data/fmtc/fmtc_provider.dart línea 7-8:
    final fmtcTileProviderProvider =
        Provider.family<FMTCTileProvider?, String>((ref, style) { ... });
  El provider es family, OK. Devuelve un FMTCTileProvider.
- lib/data/fmtc/fmtc_service.dart línea 59:
    const store = FMTCStore(storeName);
  El `storeName` es una constante única ("jerez" probablemente),
  compartida por todos los estilos. Resultado: cuando cambias mapStyle,
  el TileLayer pide la URL nueva, pero FMTC sirve las tiles cacheadas
  del estilo viejo porque el store es el mismo y la URL de cache key
  no incluye el estilo.

ROOT CAUSE 2 (no persiste):
- lib/shared/providers/theme_notifier.dart líneas 374-411 (`_persist()`):
    Future<void> _persist() async {
      if (!_initialized) return;  ← guard
      ...
    }
- Si el usuario cambia `mapStyle` ANTES de que `init()` o `loadGuest()`
  hayan completado (race condition al arranque), el setter cambia el
  valor en memoria pero NO lo persiste.
- Además, hay que confirmar que `loadGuest()` se llama al arranque
  cuando el usuario está sin auth. Si nadie lo llama, `_initialized`
  queda en false toda la sesión.

OBJETIVO:
1. Que cambiar mapStyle muestre INSTANTÁNEAMENTE tiles nuevas.
2. Que el mapStyle persista entre sesiones (incluso para invitados).

ARCHIVOS PERMITIDOS:
- lib/shared/providers/theme_notifier.dart
- lib/data/fmtc/fmtc_service.dart
- lib/data/fmtc/fmtc_provider.dart
- lib/main.dart  ← SOLO para asegurar que `loadGuest()` se llama si
  no hay sesión auth al arranque

ARCHIVOS PROHIBIDOS:
- splash_screen.dart, pubspec.yaml (es de A1)
- map_style_section.dart (es de A3)
- particles_painter.dart (es de A4)

═══════════════════════════════════════════════════════════════════
TAREAS CONCRETAS:
═══════════════════════════════════════════════════════════════════

T1. Diagnóstico de fmtc_service.dart
   Lee el archivo completo. Identifica:
   - `storeName` (const o variable)
   - Función `getTileProvider(style)` si existe, o `getTileProvider()`
     sin params
   - Inicialización: ¿crea UN store o UNO por estilo?

T2. Stores por estilo
   Refactoriza fmtc_service.dart para que cree y gestione un store por
   cada estilo en MapConfig.mapStyles:

       class FmtcService {
         static const _storePrefix = 'jerez';
         static const _styleKeys = ['streets', 'basic', 'bright', 'dark', 'light'];

         static String storeName(String style) => '${_storePrefix}-$style';

         static FMTCStore storeFor(String style) =>
             FMTCStore(storeName(style));

         static Future<void> initialise({
           required int maxDatabaseSize,
           required int maxTileCount,
         }) async {
           await FMTCObjectBoxBackend().initialise();
           for (final s in _styleKeys) {
             final store = storeFor(s);
             if (!(await store.manage.ready)) {
               await store.manage.create();
             }
           }
         }

         static Future<int> totalSizeKb() async {
           int total = 0;
           for (final s in _styleKeys) {
             final stats = await storeFor(s).stats.size;
             total += stats.toInt();
           }
           return total;
         }

         static Future<void> clearAll() async {
           for (final s in _styleKeys) {
             await storeFor(s).manage.reset();
           }
         }
       }

   - Verifica la API real de flutter_map_tile_caching 10.0.0 en el
     archivo: los nombres de métodos (`manage.create`, `stats.size`,
     `manage.reset`) varían entre versiones. Ajusta a la API real.

T3. fmtc_provider.dart family por estilo
   Reescribe el provider:

       final fmtcTileProviderProvider =
           Provider.family<FMTCTileProvider?, String>((ref, style) {
         try {
           final store = FmtcService.storeFor(style);
           return FMTCTileProvider(stores: {storeName: BrowseStoreStrategy.readUpdateCreate});
           // NOTA: la API exacta de la v10 puede variar. Probable:
           //   return store.getTileProvider();
         } catch (e) {
           return null;
         }
       });

   - Si el provider FAMILY ya existía, solo asegúrate de que invoca
     `FmtcService.storeFor(style)` y devuelve un tile provider distinto
     por estilo.

T4. Hardenear _persist en theme_notifier
   En lib/shared/providers/theme_notifier.dart líneas 374-411:

       // Antes:
       Future<void> _persist() async {
         if (!_initialized) return;
         ...
       }

       // Después:
       Future<void> _persist() async {
         // Si todavía no se ha hecho init/loadGuest, dispara loadGuest
         // primero para tener un baseline conocido y luego persistir el
         // cambio que el usuario acaba de hacer.
         if (!_initialized) {
           await _loadGuestPrefs();
           // _loadGuestPrefs marca _initialized = true al final.
         }
         try {
           final uid = _authUserId;
           if (uid != null) {
             await _prefsRepo.update(toPreferences(uid));
             return;
           }
         } on UserPreferencesRepositoryException {
           // fall through a Hive
         }
         try {
           _guestBox ??= await _openGuestBox();
           await _guestBox!.put('prefs', _toHiveMap());
         } catch (e) {
           AppLogger.warn(_logTag, 'guest prefs persist failed', e);
         }
       }

   - Añade un helper privado `_toHiveMap()` que devuelve el Map<String, dynamic>
     con todos los campos persistidos (extrae del bloque actual en
     líneas ~387-410).

T5. Asegurar loadGuest al arranque
   En lib/main.dart, después de inicializar Supabase pero antes de
   runApp:
       final session = Supabase.instance.client.auth.currentSession;
       if (session?.user == null) {
         // Pre-carga prefs de invitado para que mapStyle, paleta, etc.
         // estén disponibles cuando MaterialApp construya.
         await container.read(themeNotifierProvider).loadGuest();
       }

   - Si ya existe lógica similar, déjala. Si no, añade el bloque.

T6. Smoke test del flujo
   Tras T1-T5:
   1. Arranca la app fresca (clear data en Android).
   2. Sin login, ve a Apariencia → Estilo de mapa → cambia a "dark".
   3. Vuelve al mapa: las tiles cambian INSTANTÁNEAMENTE a dark.
   4. Cierra la app COMPLETAMENTE (swipe en multitarea).
   5. Reabre la app. El mapa debe abrirse en estilo "dark", no en
      el default "streets".

═══════════════════════════════════════════════════════════════════
VERIFICACIÓN:
═══════════════════════════════════════════════════════════════════
- `flutter analyze` 0 warnings.
- Tests existentes pasan: `flutter test`.
- Smoke completo de T6 (los 5 pasos).

COMMIT(s):
- fix(map): FMTC stores separados por estilo (tiles reactivas al cambio)
- fix(theme): persistencia mapStyle robusta al arranque
- fix(main): cargar prefs guest al arrancar sin sesión auth

REPORTE FINAL:
- Confirmación de T1-T6.
- API real de FMTCStore que usaste (puede variar entre versiones).
- Si pre-existían stores únicos con tiles cacheadas, deja claro que el
  usuario perderá la caché vieja la primera vez tras este cambio.
```

---

### A3 — Preview de mapa: mini FlutterMap real

```text
ROL: Engineer Flutter, UI con FlutterMap embebido.

CONTEXTO DEL PROYECTO: <pegar bloque "Contexto global">

PROBLEMA REPORTADO:
"Quiero que en el apartado de apariencia de estilo de mapa se pueda ver
una preview de cómo se vería el mapa."

ESTADO ACTUAL:
- lib/features/appearance/widgets/map_style_section.dart línea 145-156
  muestra un círculo de color sólido por estilo. No es representativo.

DECISIÓN DEL USUARIO:
"Mini FlutterMap real (tiles vivas)."

OBJETIVO:
Cada chip de estilo es un FlutterMap miniatura no interactivo que
renderiza tiles REALES de Jerez con el estilo correspondiente. Tamaño
~72×72 px, sin gestos, zoom fijo, centrado en Plaza del Arenal.

ARCHIVOS PERMITIDOS:
- lib/features/appearance/widgets/map_style_section.dart

ARCHIVOS PROHIBIDOS:
- map_config.dart, transit_map.dart (no lo necesitas — solo lees de
  MapConfig.tileUrl)
- splash_screen.dart, fmtc_*.dart (es de A1/A2/A4)

═══════════════════════════════════════════════════════════════════
TAREAS CONCRETAS:
═══════════════════════════════════════════════════════════════════

T1. Refactor MapStylePreview a mini FlutterMap
   Reemplaza el contenido visual de `MapStylePreview` (líneas 102-171
   aprox) por:

       class MapStylePreview extends StatelessWidget {
         const MapStylePreview({
           required this.styleKey,
           required this.label,
           required this.selected,
           required this.c,
           required this.onTap,
           super.key,
         });

         final String styleKey;
         final String label;
         final bool selected;
         final TransitColorScheme c;
         final VoidCallback onTap;

         static const LatLng _jerezCenter = LatLng(36.6852, -6.1366);
         static const double _previewSize = 72;

         @override
         Widget build(BuildContext context) {
           return Semantics(
             button: true,
             selected: selected,
             label: label,
             child: InkWell(
               borderRadius: BorderRadius.circular(10),
               onTap: onTap,
               child: SizedBox(
                 width: _previewSize + 8,
                 child: Column(
                   children: [
                     // Mini mapa con tiles reales
                     Container(
                       width: _previewSize,
                       height: _previewSize,
                       decoration: BoxDecoration(
                         borderRadius: BorderRadius.circular(10),
                         border: Border.all(
                           color: selected ? c.accent : c.border,
                           width: selected ? 2 : 1,
                         ),
                       ),
                       clipBehavior: Clip.antiAlias,
                       child: IgnorePointer(
                         child: FlutterMap(
                           options: const MapOptions(
                             initialCenter: _jerezCenter,
                             initialZoom: 13.0,
                             // Sin interacción:
                             interactionOptions: InteractionOptions(
                               flags: InteractiveFlag.none,
                             ),
                           ),
                           children: [
                             TileLayer(
                               urlTemplate: MapConfig.tileUrl(styleKey),
                               subdomains: MapConfig.subdomains,
                               userAgentPackageName: 'com.transitly.transitly',
                               tileProvider: NetworkTileProvider(),
                             ),
                           ],
                         ),
                       ),
                     ),
                     const SizedBox(height: 6),
                     Text(label,
                         style: TransitTypography.bodySmall(
                           selected ? c.accent : c.textMid,
                         ),
                         maxLines: 1,
                         overflow: TextOverflow.ellipsis),
                   ],
                 ),
               ),
             ),
           );
         }
       }

   - Imports necesarios al inicio del archivo:
       import 'package:flutter_map/flutter_map.dart';
       import 'package:latlong2/latlong.dart';
   - Elimina los helpers `_styleIcon`, `_stylePreviewColor` y los
     parámetros `icon`/`previewColor` de la clase. Ya no son necesarios.
   - Actualiza la llamada en `MapStyleSection.build` para no pasar
     icon ni previewColor.

T2. Performance
   - 5 mini FlutterMaps activos pesan ~5×64 KB de RAM + descargan 5
     tiles. Es aceptable porque la pantalla de Apariencia no está
     siempre abierta.
   - Usa `NetworkTileProvider()` directamente (no FMTC) para evitar
     race conditions con los stores de A2. Las previews son online-only.
   - Si el usuario está offline al primer abrir, las previews quedarán
     en gris. Acepta esto: añade un placeholder simple
     `Container(color: c.bgRaised)` que aparezca si TileLayer dispara
     un error. Opcionalmente usa `errorTileCallback` de TileLayer.

T3. Atribución
   El mini mapa no requiere widget de atribución (mostrar atribución
   en preview pequeñísimo es redundante y choca visualmente). La
   pantalla principal del mapa ya tiene su atribución legal.

═══════════════════════════════════════════════════════════════════
VERIFICACIÓN:
═══════════════════════════════════════════════════════════════════
- `flutter analyze` 0 warnings.
- Smoke:
  1. Abre Apariencia → sección Estilo de mapa.
  2. Ves 5 miniaturas de Jerez con cada estilo aplicado. Visualmente
     distinguibles: streets (Voyager) tiene colores, basic (OSM) gris
     pastel, dark Carto oscuro, light Carto claro, bright Voyager
     no-labels o similar.
  3. Pulsar una miniatura selecciona el estilo y el mapa principal lo
     refleja al instante (A2).
  4. Sin internet, las miniaturas quedan en gris o vacías sin crashear.

COMMIT:
feat(appearance): preview real de mini mapa por estilo

REPORTE FINAL:
- Confirmación de T1-T3.
- Si encontraste que la API de InteractionOptions de flutter_map 7.0.2
  requiere otros flags, deja constancia.
- Performance observada: ¿hay lag al abrir Apariencia?
```

---

### A4 — Splash Dart: animación premium (stagger + particles + glow)

```text
ROL: Engineer Flutter senior, animaciones avanzadas.

CONTEXTO DEL PROYECTO: <pegar bloque "Contexto global">

PROBLEMA REPORTADO:
"Mejores la animación de entrada de la app."

ESTADO ACTUAL:
- lib/features/splash/splash_screen.dart tiene una animación básica:
    FadeTransition + ScaleTransition (0.85→1.0) para logo
    FadeTransition + SlideTransition para título
    FadeTransition para subtítulo
  Duración: 1400ms + hold 400ms.
- Sensación: plana, poco memorable.

DECISIÓN DEL USUARIO:
"Estilo premium: stagger + particles + glow."

OBJETIVO:
Animación de entrada premium que evoca sensación Apple/Stripe/Linear:
1. Partículas de accent flotando suavemente de fondo.
2. Logo aparece con scale-up + glow pulsante.
3. Título aparece con stagger letra por letra.
4. Subtítulo desliza con leve fade.
5. Todo respeta `reduceMotion`.

ARCHIVOS PERMITIDOS:
- lib/features/splash/splash_screen.dart  ← TODO salvo la línea
  `Image.asset(...)` (es de A1). Si necesitas tocar el Image.asset
  también, coordínalo con A1 vía el reporte.
- lib/features/splash/particles_painter.dart (NUEVO)

ARCHIVOS PROHIBIDOS:
- pubspec.yaml, assets/branding/ (es de A1)
- theme_notifier.dart, fmtc_*.dart (es de A2)
- map_style_section.dart (es de A3)

═══════════════════════════════════════════════════════════════════
TAREAS CONCRETAS:
═══════════════════════════════════════════════════════════════════

T1. ParticlesPainter
   Crea lib/features/splash/particles_painter.dart:

       import 'dart:math';
       import 'package:flutter/material.dart';

       class ParticlesPainter extends CustomPainter {
         ParticlesPainter({
           required this.progress,
           required this.color,
           required this.particles,
         }) : super(repaint: progress);

         final Animation<double> progress;
         final Color color;
         final List<_Particle> particles;

         @override
         void paint(Canvas canvas, Size size) {
           final t = progress.value;
           final paint = Paint();
           for (final p in particles) {
             final phase = (t + p.phaseOffset) % 1.0;
             final dx = (p.x + sin(phase * pi * 2) * 0.02) * size.width;
             final dy = (p.y + (phase - 0.5) * p.drift) * size.height;
             final radius = p.radius * (0.6 + 0.4 * sin(phase * pi * 2));
             final alpha = (0.15 + 0.25 * sin(phase * pi * 2)).clamp(0.0, 1.0);
             paint.color = color.withValues(alpha: alpha);
             canvas.drawCircle(Offset(dx, dy), radius, paint);
           }
         }

         @override
         bool shouldRepaint(ParticlesPainter old) => false;
       }

       class _Particle {
         final double x, y, radius, drift, phaseOffset;
         _Particle({
           required this.x,
           required this.y,
           required this.radius,
           required this.drift,
           required this.phaseOffset,
         });
       }

       List<_Particle> generateParticles(int count, {int seed = 42}) {
         final rng = Random(seed);
         return List.generate(count, (_) => _Particle(
           x: rng.nextDouble(),
           y: rng.nextDouble(),
           radius: 1.5 + rng.nextDouble() * 3.5,
           drift: 0.1 + rng.nextDouble() * 0.15,
           phaseOffset: rng.nextDouble(),
         ));
       }

   - Exporta `_Particle` como `Particle` (sin underscore) para que
     pueda usarse desde splash_screen.dart.

T2. Reescribir splash_screen.dart
   Estructura del nuevo build:

       Stack(
         alignment: Alignment.center,
         children: [
           // 1) Background gradient radial (igual que ahora)
           Container(decoration: RadialGradient(...)),

           // 2) Partículas (CustomPaint con AnimationController)
           if (TransitAnimations.shouldAnimate(context))
             AnimatedBuilder(
               animation: _particlesCtrl,
               builder: (_, __) => CustomPaint(
                 painter: ParticlesPainter(
                   progress: _particlesCtrl,
                   color: c.accent,
                   particles: _particles,
                 ),
                 size: Size.infinite,
               ),
             ),

           // 3) Glow pulsante detrás del logo (RadialGradient animado)
           ScaleTransition(
             scale: _glowScale,
             child: FadeTransition(
               opacity: _glowFade,
               child: Container(
                 width: 360, height: 360,
                 decoration: BoxDecoration(
                   shape: BoxShape.circle,
                   gradient: RadialGradient(
                     colors: [
                       c.accent.withValues(alpha: 0.35),
                       c.accent.withValues(alpha: 0.0),
                     ],
                   ),
                 ),
               ),
             ),
           ),

           // 4) Logo + título + subtítulo con stagger
           Column(
             mainAxisSize: MainAxisSize.min,
             children: [
               // Logo (mantén el Image.asset que A1 dejó)
               ScaleTransition(
                 scale: _logoScale,
                 child: FadeTransition(
                   opacity: _logoFade,
                   child: Image.asset(
                     'assets/branding/transitly_logo_white_square.png',
                     width: 280, height: 280,
                     filterQuality: FilterQuality.high,
                   ),
                 ),
               ),
               const SizedBox(height: 24),
               // Título con stagger letra por letra
               _StaggeredTitle(
                 text: AppLocalizations.of(context).appTitle.toUpperCase(),
                 progress: _titleCtrl,
                 color: c.accent,
               ),
               const SizedBox(height: 12),
               // Subtítulo: slide + fade
               SlideTransition(
                 position: _subSlide,
                 child: FadeTransition(
                   opacity: _subFade,
                   child: Text(/* tagline */),
                 ),
               ),
             ],
           ),
         ],
       )

T3. Controllers
   Necesitas 3 AnimationControllers (cambia de
   `SingleTickerProviderStateMixin` a `TickerProviderStateMixin`):
   - `_mainCtrl` (1600 ms) → controla logoFade/Scale, glowFade/Scale,
     subFade/Slide, todos con `Interval(...)` para crear el stagger.
   - `_titleCtrl` (800 ms, delay 600 ms tras _mainCtrl.forward) →
     anima cada letra del título con un fade individual.
   - `_particlesCtrl` (8000 ms, looping con `.repeat()`) → progresa
     las partículas continuamente. Solo activo si
     `TransitAnimations.shouldAnimate(context) == true`.

   Glow Tween:
   - `_glowFade`: Tween 0.0 → 0.7 → 0.5 (con TweenSequence) durante
     [0.0, 0.7] del _mainCtrl. Glow pulsante suave.
   - `_glowScale`: Tween 1.0 → 1.1 → 1.0 en bucle (combinar con
     RepeatingAnimation o usar TweenSequence).

   Logo:
   - `_logoFade`: Interval(0.0, 0.5).
   - `_logoScale`: Tween(0.7, 1.0) con `Curves.elasticOut` (overshoot
     suave), Interval(0.0, 0.6).

   Subtítulo:
   - `_subFade`: Interval(0.7, 1.0).
   - `_subSlide`: Tween(Offset(0, 0.5), Offset.zero), Interval(0.7, 1.0).

T4. _StaggeredTitle widget
   Implementa dentro del mismo archivo:

       class _StaggeredTitle extends StatelessWidget {
         const _StaggeredTitle({
           required this.text, required this.progress, required this.color,
         });
         final String text;
         final Animation<double> progress;
         final Color color;

         @override
         Widget build(BuildContext context) {
           return AnimatedBuilder(
             animation: progress,
             builder: (_, __) {
               final letters = text.split('');
               final total = letters.length;
               return Row(
                 mainAxisSize: MainAxisSize.min,
                 children: List.generate(total, (i) {
                   final letterStart = i / total * 0.6;  // último arranca a 60%
                   final letterEnd = letterStart + 0.4;
                   final t = ((progress.value - letterStart) / (letterEnd - letterStart))
                       .clamp(0.0, 1.0);
                   return Opacity(
                     opacity: t,
                     child: Transform.translate(
                       offset: Offset(0, (1 - t) * 8),
                       child: Text(
                         letters[i],
                         style: GoogleFonts.ibmPlexMono(
                           fontSize: 36,
                           fontWeight: FontWeight.w900,
                           letterSpacing: 4,
                           color: color,
                         ),
                       ),
                     ),
                   );
                 }),
               );
             },
           );
         }
       }

T5. Respeto a reduceMotion
   En `_start`:
       if (TransitAnimations.shouldAnimate(context)) {
         _mainCtrl.forward();
         Future.delayed(const Duration(milliseconds: 600), () {
           if (mounted) _titleCtrl.forward();
         });
         _particlesCtrl.repeat();
       } else {
         _mainCtrl.value = 1.0;
         _titleCtrl.value = 1.0;
         // _particlesCtrl no se inicia → partículas no se ven
       }

T6. Dispose
   En dispose(), libera los 3 controllers + cancela el navTimer.
   Ya hay un dispose básico — añade `_titleCtrl.dispose()` y
   `_particlesCtrl.dispose()`.

T7. Inicialización de partículas
   Inicialízalas una sola vez en initState:
       late final List<Particle> _particles = generateParticles(40);

═══════════════════════════════════════════════════════════════════
VERIFICACIÓN:
═══════════════════════════════════════════════════════════════════
- `flutter analyze` 0 warnings.
- Smoke:
  1. Arranca la app fresca. El splash Dart muestra:
     - Partículas de accent flotando suavemente de fondo.
     - Glow pulsante detrás del logo.
     - Logo entra con scale elastic y fade.
     - Título "TRANSITLY" entra letra por letra (stagger).
     - Subtítulo desliza al final.
  2. Activa "Reducir movimiento" en Apariencia, fuerza-cierra app,
     reabre → splash sin partículas ni animación, todo aparece
     instantáneo.

COMMIT(s):
- feat(splash): animación premium con stagger + particles + glow
- feat(splash): respeto a reduceMotion en todas las capas

REPORTE FINAL:
- Confirmación T1-T7.
- Si tu implementación usa otra estructura razonable, justifica.
- Resultado del smoke (con y sin reduceMotion).
```

---

## WAVE 2 — Coordinador

1. **Análisis y tests:**
   ```bash
   flutter analyze     # 0 warnings
   flutter test        # tests existentes deben seguir verdes
   ```

2. **Build APK debug** (no release):
   ```bash
   flutter build apk --debug
   ```
   Verificar que pasa sin errores nativos tras los regen de A1.

3. **Smoke completo en dispositivo Android:**
   - **A1 — Logo:**
     - Splash NATIVO (al abrir): logo centrado, no aplastado.
     - Splash DART (después): logo a 280×280 respetando proporciones.
     - Icono del launcher: logo dentro de la máscara adaptive, sin
       recorte ni distorsión.
   - **A2 — Mapa:**
     - Cambiar estilo desde Apariencia → tiles del mapa cambian al
       instante.
     - Cerrar app, reabrir → el estilo seleccionado persiste.
   - **A3 — Preview:**
     - En Apariencia → Estilo de mapa, ves 5 miniaturas con tiles
       reales distintas de Jerez.
   - **A4 — Splash animación:**
     - Partículas + glow + stagger en arranque.
     - Con reduceMotion, todo instantáneo.

4. **Si todo OK, build APK release (solo si el usuario lo pide):**
   ```bash
   flutter build apk --release
   ```

---

## Riesgos y notas

- **A1 (regen iconos)**: tras regenerar, los assets en `android/` y
  `ios/` cambian (commits voluminosos). El usuario debe aceptar el
  diff grande de PNGs binarios.
- **A2 (FMTC stores)**: cambiar de un store único a 5 stores por
  estilo invalida la caché previa. La primera vez tras el cambio el
  usuario verá tiles cargándose en cada estilo. Tras la primera
  navegación, las tiles quedan cacheadas.
- **A2 (loadGuest al arranque)**: si el usuario tiene una sesión auth
  válida, NO se llama a loadGuest (correcto). Si la sesión expira en
  mid-runtime y vuelve a invitado, hay que llamar `loadGuest` ahí —
  fuera del scope de v8.
- **A3 (5 mini FlutterMaps)**: si la pantalla Apariencia se renderiza
  muchas veces (ej. cada vez que cambias paleta por el visualKey), las
  miniaturas se desmontan/remontan. Cada remount dispara descarga de
  tiles. Documenta este coste en el reporte.
- **A4 (particles 40 unidades)**: el ParticlesPainter dibuja 40 círculos
  por frame. En dispositivos muy bajos puede dar lag. Reduce a 20 si
  notas problemas.

---

## Cobertura final

| # | Error reportado | Agente |
|---|------------------|--------|
| 1 | Logo cortado y aplastado | A1 |
| 2 | Mapa no carga al cambiar estilo | A2 |
| 3 | Ajustes no se guardan al salir/entrar | A2 |
| 4 | Quiero preview del mapa por estilo | A3 |
| 5 | Mejorar animación de entrada | A4 |
