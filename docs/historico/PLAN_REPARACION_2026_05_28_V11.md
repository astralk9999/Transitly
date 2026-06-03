# Plan de reparación v11 — Transitly (3 bugs duros)

**Fecha:** 2026-05-28
**Autor:** Claude Code (Opus 4.7)
**Plan anterior:** `PLAN_REPARACION_2026_05_28_V10.md`

---

## TL;DR — Causas raíz EXACTAS verificadas en el repo HOY

| # | Bug | Causa raíz CONFIRMADA |
|---|-----|------------------------|
| 1 | Fuente dislexia no funciona | **La carpeta `assets/fonts/opendyslexic/` está vacía** y **`OpenDyslexic` ya NO aparece en pubspec.yaml**. Pero `transit_typography.dart:7` sigue pidiendo `'OpenDyslexic'`. Flutter no encuentra la fuente → cae al sistema → cero cambio visible. |
| 2 | Dot azul + paradas cerca no aparecen hasta reiniciar | El stream provider hace `ref.watch(userLocationPermissionProvider)` para reaccionar al permiso, pero **NO espera al resultado**: arranca `service.subscribe()` (Geolocator) **antes** de confirmar que el permiso es granted. Si el primer build ocurre con permiso loading o denied, geolocator devuelve un stream que NUNCA emite. Aunque luego invalidemos el provider, la nueva suscripción puede llegar antes de que geolocator esté listo. |
| 3 | Mapa no cambia de estilo sin reiniciar | El `KeyedSubtree` con `visualKey` SÍ incluye `mapStyle`, así que el árbol debería desecharse cuando el usuario cambia el estilo. Pero **el `MapController` se crea como campo `final` en `_MapTabState`** y se mantiene entre rebuilds. flutter_map asocia caché de tiles al controller; el nuevo `FlutterMap` con la key nueva reutiliza el controller y muestra tiles cacheadas viejas. |

---

## Verificación en el repo

```bash
$ ls assets/fonts/opendyslexic/
(directorio vacío)

$ grep "OpenDyslexic" pubspec.yaml
(0 coincidencias — la declaración se perdió)

$ grep "OpenDyslexic" lib/core/theme/transit_typography.dart
7:    if (isDyslexiaEnabled()) return 'OpenDyslexic';   ← pide una fuente fantasma
```

```dart
// lib/shared/providers/user_location_provider.dart
final userLocationStreamProvider =
    StreamProvider.autoDispose<UserLocationFix?>((ref) {
  ref.watch(userLocationPermissionProvider);   // observa cambios, NO espera
  final service = ref.read(userLocationServiceProvider);
  // Llama subscribe() sin confirmar que el permiso es granted:
  positionStream = service.subscribe(...);
  // Si permission no está granted aún, este stream queda muerto.
});
```

```dart
// lib/features/home/tabs/map_tab.dart
class _MapTabState extends ConsumerState<MapTab> {
  final _mapController = MapController();   // ← NUNCA se recrea
}
```

---

## Estructura

```
WAVE 1 (3 agentes paralelos)
├── A1  Dislexia: re-descargar OpenDyslexic real + restaurar pubspec
├── A2  Stream de ubicación: espera al permiso ANTES de suscribirse
└── A3  Mapa: recrear MapController al cambiar estilo

WAVE 2 (coordinador)
└── flutter clean + pub get + analyze + build APK release + install
```

### Tabla de archivos

| Agente | Archivos |
|--------|----------|
| **A1** | `assets/fonts/opendyslexic/OpenDyslexic-Regular.otf` (NUEVO), `OpenDyslexic-Bold.otf` (NUEVO), `pubspec.yaml` (restaurar declaración) |
| **A2** | `lib/shared/providers/user_location_provider.dart` (re-arquitectura: usar AsyncNotifier que awaite permiso) |
| **A3** | `lib/features/home/tabs/map_tab.dart` (MapController gestionado, recreación al cambiar estilo) |

Sin solape entre los 3.

---

## WAVE 1 — Briefs

### A1 — Dislexia: re-descargar OpenDyslexic real

```text
ROL: Engineer, assets + fonts.

PROBLEMA:
- assets/fonts/opendyslexic/ está vacío.
- pubspec.yaml ya no declara OpenDyslexic.
- transit_typography.dart:7 pide 'OpenDyslexic' → Flutter no encuentra
  la fuente → cae al sistema → 0 cambio visible al activar dislexia.

TAREAS:

T1. Descargar OpenDyslexic REAL.
   Los .otf reales DEBEN dar este output al hacer `file`:
       OpenType font data
   NO debe decir "HTML document".

   Probar URLs en este orden, parar al primer éxito:

   Opción A — Mirror jsDelivr (CDN estable, no GitHub):
     curl -L -o assets/fonts/opendyslexic/OpenDyslexic-Regular.otf \
       "https://cdn.jsdelivr.net/gh/antijingoist/opendyslexic@master/compiled/OpenDyslexic-Regular.otf"
     curl -L -o assets/fonts/opendyslexic/OpenDyslexic-Bold.otf \
       "https://cdn.jsdelivr.net/gh/antijingoist/opendyslexic@master/compiled/OpenDyslexic-Bold.otf"

   Opción B — Web oficial opendyslexic.org:
     curl -L -o assets/fonts/opendyslexic/OpenDyslexic-Regular.otf \
       "https://github.com/antijingoist/open-dyslexic/raw/master/compiled/OpenDyslexic-Regular.otf"
     curl -L -o assets/fonts/opendyslexic/OpenDyslexic-Bold.otf \
       "https://github.com/antijingoist/open-dyslexic/raw/master/compiled/OpenDyslexic-Bold.otf"

   Opción C — Descargar zip de releases:
     curl -L -o /tmp/od.zip \
       "https://github.com/antijingoist/open-dyslexic/archive/refs/heads/master.zip"
     unzip -j /tmp/od.zip "*/compiled/OpenDyslexic-Regular.otf" \
       "*/compiled/OpenDyslexic-Bold.otf" \
       -d assets/fonts/opendyslexic/

   VERIFICAR siempre:
     file assets/fonts/opendyslexic/*.otf
     DEBE decir: "OpenType font data, ..."
     Y el tamaño DEBE ser >50 KB (los reales son ~300 KB).
     Si dice "HTML document" o pesa <10 KB, la URL es mala — probar la
     siguiente opción.

   PLAN B SI TODAS LAS URLS FALLAN:
     Volver a Atkinson Hyperlegible (que SÍ está empaquetada y
     funciona). En transit_typography.dart línea 7:
         if (isDyslexiaEnabled()) return 'Atkinson Hyperlegible';
     Y documentar que OpenDyslexic queda como trabajo futuro.
     Atkinson Hyperlegible es la fuente del Braille Institute,
     específicamente diseñada para distinguir 1/l/I, b/d/p/q y O/0;
     es válida como fuente anti-dislexia aunque visualmente menos
     distintiva que OpenDyslexic clásica.

T2. Restaurar declaración en pubspec.yaml.
   En la sección `fonts:`, AÑADIR (después de Atkinson Hyperlegible):

       - family: OpenDyslexic
         fonts:
           - asset: assets/fonts/opendyslexic/OpenDyslexic-Regular.otf
             weight: 400
           - asset: assets/fonts/opendyslexic/OpenDyslexic-Bold.otf
             weight: 700

T3. Mantener fontFamilyFallback en typography (insurance):
   En lib/core/theme/transit_typography.dart, asegurar que cada
   TextStyle incluye:
       fontFamilyFallback: const ['Atkinson Hyperlegible', 'DM Sans'],

   Eso garantiza que si la carga de OpenDyslexic falla por cualquier
   motivo, Atkinson la sustituye.

T4. flutter clean + pub get OBLIGATORIO:
   flutter clean
   flutter pub get

   Sin esto, Flutter no re-empaqueta los assets nuevos y la fuente
   sigue sin existir en el APK.

VERIFICACIÓN:
- `file assets/fonts/opendyslexic/*.otf` dice "OpenType font data".
- Tamaño de cada .otf >100 KB.
- Tras build+install, activar dislexia → tipografía cambia. Si es
  OpenDyslexic, las letras tienen peso inferior pesado característico.
  Si cae a Atkinson (por fallback), también cambia visiblemente.

COMMIT(s):
- chore(fonts): re-descargar OpenDyslexic real y restaurar declaración
- feat(a11y): fontFamilyFallback con Atkinson Hyperlegible como respaldo
```

---

### A2 — Stream de ubicación: esperar al permiso ANTES de suscribir

```text
ROL: Engineer Flutter senior, Riverpod async + geolocator.

PROBLEMA:
- El stream provider hace `ref.watch(userLocationPermissionProvider)`
  para reaccionar a cambios. Pero NO espera a que el permiso se
  resuelva.
- Llama a `service.subscribe()` (Geolocator) inmediatamente. Si el
  permiso aún no es granted, geolocator devuelve un stream que NUNCA
  emite, aunque luego se conceda.
- Resultado: el dot azul + paradas cerca no aparecen sin reiniciar la
  app, donde el nuevo arranque sí tiene permiso granted desde el
  inicio.

CAUSA TÉCNICA EXACTA:
StreamProvider.autoDispose<T>((ref) { ... }) NO puede ser async; tiene
que devolver Stream<T> sincronamente. Por eso el código actual no
puede hacer `await ref.watch(permission.future)` antes de subscribe.
Es necesario re-arquitectar.

SOLUCIÓN: Usar StreamProvider que devuelve un Stream construido vía
async generator (`async*`) que SÍ puede awaitear:

ARCHIVO PERMITIDO:
- lib/shared/providers/user_location_provider.dart

TAREAS:

T1. Reescribir userLocationStreamProvider:

    final userLocationStreamProvider =
        StreamProvider.autoDispose<UserLocationFix?>((ref) {
      // Yields async para poder await del permiso ANTES de suscribir.
      return _locationStream(ref);
    });

    Stream<UserLocationFix?> _locationStream(Ref ref) async* {
      // 1. Esperar al permiso (puede tardar si está en runtime prompt)
      final LocationPermission permission;
      try {
        permission = await ref.watch(
            userLocationPermissionProvider.future);
      } catch (e) {
        AppLogger.warn(_logTag, 'permission resolve failed', e);
        yield null;
        return;
      }

      // 2. Si NO granted, emitir null y salir.
      //    Cuando el usuario conceda permiso después, ref.invalidate
      //    del permission provider hará que este stream se re-construya.
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        yield null;
        return;
      }

      // 3. Permiso granted: AHORA suscribirse a geolocator.
      final service = ref.read(userLocationServiceProvider);
      Stream<Position> positionStream;
      try {
        positionStream = service.subscribe(
          settings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5,
          ),
        );
      } catch (e) {
        AppLogger.warn(_logTag, 'position stream failed', e);
        yield null;
        return;
      }

      // 4. Re-emitir cada posición como UserLocationFix.
      await for (final pos in positionStream) {
        yield UserLocationFix(
          position: LocationService.toLatLng(pos),
          accuracy: pos.accuracy,
        );
      }
    }

T2. En map_tab.dart `_centerOnUser`, tras request granted:
    // El stream provider se reinicia automáticamente cuando invalidamos
    // el permission provider. El nuevo stream awaitará el permiso ahora
    // granted y arrancará geolocator.
    ref.invalidate(userLocationPermissionProvider);

    // Esperar al primer fix (timeout 8s razonable).
    try {
      final fix = await ref
          .read(userLocationStreamProvider.future)
          .timeout(const Duration(seconds: 8));
      if (fix != null && mounted) {
        _mapController.move(fix.position, 16);
        setState(() => _loadingCenter = false);
        return;
      }
    } on TimeoutException {
      // fallback a getCurrentPosition
    }

T3. (Bonus) Forzar un primer fix sintético con getCurrentPosition:
    Después del permiso granted, ANTES de invalidate, llamar
    Geolocator.getCurrentPosition para "despertar" geolocator. A veces
    el getPositionStream sin un getCurrentPosition previo queda
    dormido en Android:

        final firstPos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high))
            .timeout(const Duration(seconds: 10));
        if (firstPos != null && mounted) {
          _mapController.move(LocationService.toLatLng(firstPos), 16);
        }
        ref.invalidate(userLocationPermissionProvider);

VERIFICACIÓN:
- Tras instalar el APK fresh: arrancar app y DENEGAR permiso al primer
  prompt.
- Ir al mapa → no hay dot.
- Pulsar el FAB ubicación → prompt aparece → CONCEDER.
- Esperar máximo 8s → dot azul aparece sin necesidad de reiniciar.
- Ir a home → "Paradas cerca" muestra paradas reales del usuario.

COMMIT:
fix(geo): stream espera al permiso antes de suscribir geolocator
(activación sin reiniciar la app)
```

---

### A3 — Mapa: recrear MapController al cambiar estilo

```text
ROL: Engineer Flutter, flutter_map.

PROBLEMA:
El `key: ValueKey('fm-${mapStyle}-${isDark}')` en FlutterMap fuerza
recreación del widget, PERO el `MapController _mapController` se crea
como campo `final` en `_MapTabState` y NUNCA se recrea. flutter_map
asocia tiles cacheadas al controller; al pasar el MISMO controller al
FlutterMap nuevo, sirve las tiles viejas del estilo anterior.

SOLUCIÓN: gestionar el MapController para que se recree cuando cambie
el estilo o el tema.

ARCHIVO PERMITIDO:
- lib/features/home/tabs/map_tab.dart

TAREAS:

T1. Cambiar `final _mapController` a mutable y añadir tracking:

    // Antes:
    final _mapController = MapController();

    // Después:
    MapController _mapController = MapController();
    String? _activeMapKey;  // ('isDark|mapStyle') de la última build

T2. En `build()`, antes de construir TransitMap, comprobar cambio:

    final mapStyle =
        ref.watch(themeNotifierProvider.select((n) => n.mapStyle));
    final currentMapKey = '${isDark ? 'd' : 'l'}|$mapStyle';

    if (_activeMapKey != null && _activeMapKey != currentMapKey) {
      // Guardar centro y zoom actuales antes de recrear
      final savedCenter = _mapController.camera.center;
      final savedZoom = _mapController.camera.zoom;
      // Desechar el controller viejo (libera tiles cacheadas)
      _mapController.dispose();
      _mapController = MapController();
      // Restaurar posición en el siguiente frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _mapController.move(savedCenter, savedZoom);
      });
    }
    _activeMapKey = currentMapKey;

T3. Asegurar dispose final:

    @override
    void dispose() {
      _mapController.dispose();
      _sheetController.dispose();
      _scrollController.dispose();
      super.dispose();
    }

T4. La key del TransitMap ya está bien. NO la toques:

    TransitMap(
      key: ValueKey('${isDark ? 'd' : 'l'}-$mapStyle'),
      ...
    )

T5. Verificar que `_centerOnUser` también funciona tras un cambio de
   estilo. Tras recrear el controller, el `_mapController.move()` debe
   funcionar normalmente.

VERIFICACIÓN:
- Apariencia → Estilo de mapa → cambiar a "dark" → ir al mapa → tiles
  cambian a dark en <2 segundos.
- Repetir con todos los estilos (streets/basic/bright/dark/light).
  TODOS cambian al instante.
- El centro/zoom del mapa se preserva al cambiar de estilo (el usuario
  no pierde su posición).
- Sin reiniciar la app en NINGÚN momento.

COMMIT:
fix(map): recrear MapController al cambiar estilo o tema (tiles cambian
al instante sin reiniciar)
```

---

## WAVE 2 — Coordinador

1. **Clean + analyze:**
   ```bash
   flutter clean
   flutter pub get
   flutter analyze
   ```

2. **Build APK release + install:**
   ```bash
   flutter build apk --release --dart-define-from-file=dart_defines.json
   flutter install --release -d 000871487002528
   ```

3. **Smoke crítico (en orden):**
   - **Dislexia**: arrancar app, ir a Apariencia → activar "Fuente para
     dislexia". La tipografía debe cambiar VISIBLEMENTE. Mirar el
     título "TRANSITLY", los códigos de línea, los nombres de paradas.
   - **Permisos**: si tienes permiso ya concedido al instalar, ir a
     Ajustes del sistema → revocar permiso de ubicación de Transitly.
     Volver a la app. Ir al mapa → no hay dot. Pulsar FAB ubicación →
     prompt → conceder. Dot azul aparece en <8s sin reiniciar.
   - **Estilo mapa**: Apariencia → Estilo de mapa → cambiar a dark →
     volver al mapa → tiles cambian al instante sin reiniciar. Repetir
     con los 5 estilos.

---

## Si los fixes siguen sin funcionar

### Dislexia (A1 falla)
- Verificar con `file` que los .otf son binarios reales.
- Probar fontFamilyFallback con `'Atkinson Hyperlegible'` para que al
  menos cambie a esa fuente.
- Como último recurso: usar el TextStyle directamente con
  `fontFamilyFallback`, sin depender del helper.

### Permisos (A2 falla)
- El método nuclear: mostrar al usuario un diálogo "Permiso
  actualizado, pulsa OK para refrescar" que llame a
  `SystemNavigator.pop()` y al reabrir todo funcione. Documentado como
  workaround temporal.

### Mapa (A3 falla)
- Alternativa: hacer `Navigator.popAndPushNamed('/home/mapa')` cuando
  cambie el mapStyle. Eso destruye y recrea la pantalla del mapa entera
  con todos sus widgets desde cero.
- O probar con `flutter_map: 7.0.2` → upgrade a la última versión
  estable, que puede tener fixes de gestión de caché.

---

## Cobertura final

| Bug | Agente | Resultado esperado |
|-----|--------|---------------------|
| Dislexia sigue sin funcionar | A1 | Fuente cambia a OpenDyslexic (o Atkinson como fallback) |
| Dot azul no aparece sin reiniciar | A2 | Aparece en <8s tras conceder permiso |
| Paradas cerca no se actualizan sin reiniciar | A2 | Se actualizan junto con el dot |
| Mapa no cambia estilo sin reiniciar | A3 | Tiles cambian al instante al seleccionar nuevo estilo |
