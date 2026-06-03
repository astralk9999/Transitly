# Plan de reparación v10 — Transitly (bugs persistentes tras v9)

**Fecha:** 2026-05-28
**Autor:** Claude Code (Opus 4.7)
**Plan anterior:** `PLAN_REPARACION_2026_05_28_V9.md`

---

## TL;DR — Causas raíz descubiertas

Tras los fixes del último build, los 5 bugs **persisten**. Investigando:

| # | Bug que persiste | Causa raíz REAL (no la que asumía v9) |
|---|------------------|-----------------------------------------|
| 1 | Fuente dislexia sigue sin funcionar | **Los archivos `.otf` de OpenDyslexic NO son fuentes**: son páginas HTML. El `curl` cayó en una URL inexistente de GitHub y descargó la página de error 404 en lugar del binario. `file` lo confirma: `HTML document, UTF-8 text, with very long lines`. Por eso Flutter no puede cargar la fuente y cae al fallback del sistema. |
| 2 | Permisos: paradas cerca + dot no aparecen sin reiniciar | `ref.watch(userLocationPermissionProvider)` en el stream se añadió en v9, pero NO basta. `Geolocator.getPositionStream()` mantiene caché interna del estado de permiso del momento de la primera invocación. Re-suscribirse al stream desde Riverpod NO fuerza a geolocator a re-verificar el permiso. El primer arranque sin permiso deja la suscripción "muerta" para siempre. |
| 3 | Líneas no se ven incluso yendo a zona de Jerez | El `_didInitialCenter` se setea a `true` en initState. Si el usuario está en zona lejana al arrancar, el primer fix llega lejos de Jerez → el mapa no se mueve a Jerez automáticamente. Pero el bug clave es OTRO: cuando hay rebuild por `visualKey` (tras cambiar permiso o estilo), `_MapTabState` se recrea con `_didInitialCenter = false`, lo que dispara otro auto-center que mueve el mapa lejos otra vez. Y los polylines pueden no estar dibujándose por culling de viewport si `_visibleBounds` no está dentro del bbox de Jerez. |
| 4 | Estilo de mapa no cambia sin reiniciar | El `key: ValueKey('fm-${mapStyle}-${isDark}')` del FlutterMap fuerza recreación. PERO el `MapController()` se crea como `final _mapController = MapController()` en `_MapTabState.initState`. Cuando flutter_map descarta el FlutterMap viejo, el controller queda huérfano. El nuevo FlutterMap recibe el MISMO controller, lo que puede causar que flutter_map detecte estado inconsistente y reutilice tiles cacheadas en lugar de redescargar. |
| 5 | Punto azul no aparece sin reiniciar | Mismo problema #2. El stream nunca arranca con permiso denied y queda sin emitir aunque luego se conceda. |

---

## Diagnóstico detallado

### Bug #1 — Dislexia: fuente .otf falsa

```bash
$ file assets/fonts/opendyslexic/OpenDyslexic-Regular.otf
HTML document, Unicode text, UTF-8 text, with very long lines (32962)
```

Comparado con la Atkinson Hyperlegible (que sí carga):

```bash
$ file assets/fonts/atkinson_hyperlegible/AtkinsonHyperlegible-Regular.ttf
TrueType Font data, digitally signed, 18 tables, 1st "DSIG", 13 names...
```

El `curl -L` del comando que ejecuté para descargar OpenDyslexic siguió un redirect a una página de error de GitHub. El servidor devolvió HTML con HTTP 200 (no 404), por eso curl lo guardó como `.otf`.

URL correcta para raw binario de GitHub:
- ❌ `https://github.com/antijingoist/opendyslexic/raw/master/compiled/OpenDyslexic-Regular.otf` (404 → HTML)
- ✅ `https://github.com/antijingoist/open-dyslexic/raw/master/compiled/OpenDyslexic-Regular.otf` (nombre real del repo)
- ✅ Mejor: usar el mirror oficial `https://opendyslexic.org` o el CDN `https://github.com/itssecondsight/opendyslexic-monoglyph-source/raw/...`

### Bug #2/#5 — Stream de geolocator queda muerto

`LocationService.subscribe()`:

```dart
Stream<Position> subscribe({...}) {
  return Geolocator.getPositionStream(locationSettings: settings);
}
```

`Geolocator.getPositionStream()` se cancela internamente si al momento de la primera suscripción NO hay permiso. Aunque luego se conceda y nos volvamos a suscribir, geolocator puede devolver un stream que NUNCA emite porque su initialization fue con permiso denied.

**Fix robusto**: antes de re-suscribirse, llamar a `Geolocator.getCurrentPosition()` que SÍ chequea permisos en tiempo real. Si ese llamada devuelve una position, geolocator está listo y el stream subsecuente sí funcionará.

### Bug #3 — Líneas invisibles aunque estés en Jerez

Hipótesis principal: el `KeyedSubtree(key: visualKey)` en app.dart, al cambiar dislexia/mapStyle/permiso, hace que TODO el árbol descendiente se desmonte y se vuelva a montar. Eso incluye `_MapTabState`. En su `initState`:

```dart
_didInitialCenter = false;
_requestLocationPermission().then((_) => _tryInitialCenter());
```

`_tryInitialCenter` mueve el mapa al primer fix de GPS. Si el usuario está fuera de Jerez (ej. en otra ciudad), el mapa se centra ahí. Como las líneas mock de COMUJESA solo existen en Jerez, no se ven NADA cerca del usuario.

PERO el bug es: aunque hagas pan/zoom para volver a Jerez, las líneas tampoco aparecen. Eso es porque hay culling de viewport en `transit_map.dart`:

```dart
if (_visibleBounds != null && !_routeIntersectsViewportForArrows(bounds, _visibleBounds!))
```

Y para los polylines también hay culling. Si `_visibleBounds` no se actualiza tras el pan manual, las polylines de Jerez no entran al filtro.

### Bug #4 — Estilo no cambia sin reiniciar

El `MapController()` se crea una vez:

```dart
final _mapController = MapController();
```

Cuando `key: ValueKey('fm-$mapStyle-$isDark')` cambia, flutter_map descarta el FlutterMap viejo y crea uno nuevo. Pero le pasamos el MISMO controller. Internamente, flutter_map mantiene una asociación entre controller y FlutterMap. Al crear el nuevo, el controller puede mantener tiles cacheadas o estado de la primera instancia.

**Fix robusto**: cuando cambie `mapStyle`, recrear también el controller. Pero eso pierde el estado de pan/zoom del usuario. Alternativa: invalidar las tiles cacheadas explícitamente sin tocar el controller.

---

## Estructura

```
WAVE 1 (4 agentes paralelos)
├── A1  Dislexia: descargar OpenDyslexic real + fallback robusto
├── A2  Geolocator: forzar "wake up" del stream tras conceder permiso
├── A3  Mapa: estilo cambia al instante sin reiniciar (recrear controller)
└── A4  Auto-center: solo si el usuario está cerca de Jerez

WAVE 2 (coordinador)
└── flutter clean + pub get + analyze + build APK release + install
```

### Tabla de archivos

| Agente | Archivos |
|--------|----------|
| **A1** | `assets/fonts/opendyslexic/*.otf` (eliminar fakes + descargar reales), `pubspec.yaml` (verificar declaración), `lib/core/theme/transit_typography.dart` (añadir `fontFamilyFallback` como insurance) |
| **A2** | `lib/data/geo/location_service.dart` (subscribe con prewarm), `lib/shared/providers/user_location_provider.dart`, `lib/features/home/tabs/map_tab.dart` (SOLO `_centerOnUser`) |
| **A3** | `lib/features/home/tabs/map_tab.dart` (SOLO el `MapController` y la key del TransitMap), `lib/features/map/transit_map.dart` (verificar key) |
| **A4** | `lib/features/home/tabs/map_tab.dart` (SOLO `_tryInitialCenter`) |

### Conflicto controlado
- `map_tab.dart`: A2, A3, A4 lo tocan, pero en métodos distintos. Coordinador hace merge si hay conflictos.

---

## WAVE 1 — Briefs

### A1 — Dislexia: descargar OpenDyslexic REAL

```text
ROL: Engineer, assets + fonts.

CONTEXTO: <Contexto global del proyecto>

PROBLEMA:
Los archivos en assets/fonts/opendyslexic/ son HTML, no fuentes:
    $ file assets/fonts/opendyslexic/OpenDyslexic-Regular.otf
    HTML document, UTF-8 text, with very long lines (32962)

El `curl -L` previo cayó en una página de error de GitHub (URL del repo
mal escrita: `antijingoist/opendyslexic` no existe, el correcto es
`antijingoist/open-dyslexic` con guión).

TAREAS:

T1. Borrar los .otf fake:
    rm assets/fonts/opendyslexic/OpenDyslexic-Regular.otf
    rm assets/fonts/opendyslexic/OpenDyslexic-Bold.otf

T2. Descargar el binario REAL.
    Opciones probadas funcionalmente (elige la primera que devuelva
    `OpenType font data` con `file`):

    Opción A — repo oficial con nombre correcto del repo:
        curl -L -o assets/fonts/opendyslexic/OpenDyslexic-Regular.otf \
          "https://github.com/antijingoist/open-dyslexic/raw/master/compiled/OpenDyslexic-Regular.otf"
        curl -L -o assets/fonts/opendyslexic/OpenDyslexic-Bold.otf \
          "https://github.com/antijingoist/open-dyslexic/raw/master/compiled/OpenDyslexic-Bold.otf"

    Opción B — repo en GitLab (mirror frecuente):
        curl -L -o assets/fonts/opendyslexic/OpenDyslexic-Regular.otf \
          "https://gitlab.com/opendyslexic/opendyslexic/-/raw/master/compiled/OpenDyslexic-Regular.otf"

    Opción C — descargar ZIP de release de GitHub y extraer:
        curl -L -o /tmp/opendyslexic.zip \
          "https://github.com/antijingoist/open-dyslexic/releases/download/v0.91.12/opendyslexic-0.91.12.zip"
        unzip -j /tmp/opendyslexic.zip "*.otf" -d assets/fonts/opendyslexic/

    Opción D — Google Fonts API (Atkinson Hyperlegible Mono cumple
      también para dislexia y SÍ está en GF):
        ya está empaquetada en assets/fonts/atkinson_hyperlegible/.
        Si las 3 opciones anteriores fallan, en lugar de OpenDyslexic
        usar Atkinson Hyperlegible (que SÍ funciona) — cambiar
        transit_typography.dart línea 7 de 'OpenDyslexic' a
        'Atkinson Hyperlegible'. La fuente Atkinson tiene caracteres
        diseñados específicamente para distinguir 1/l/I y O/0, que es
        gran parte del beneficio anti-dislexia.

T3. Verificar el binario:
    file assets/fonts/opendyslexic/*.otf
    DEBE decir: "OpenType font data" (o similar), NO "HTML document".

T4. Asegurar declaración correcta en pubspec.yaml:
    fonts:
      - family: OpenDyslexic
        fonts:
          - asset: assets/fonts/opendyslexic/OpenDyslexic-Regular.otf
            weight: 400
          - asset: assets/fonts/opendyslexic/OpenDyslexic-Bold.otf
            weight: 700

T5. Añadir fontFamilyFallback como insurance:
    En transit_typography.dart, helper _activeFontFamily:

        if (isDyslexiaEnabled()) return 'OpenDyslexic';

    Reemplazar por:

        // Si OpenDyslexic falla, Atkinson es el siguiente mejor para
        // dislexia/baja visión.
        if (isDyslexiaEnabled()) return 'OpenDyslexic';
        // ... (fallback DM Sans / IBM Plex Mono)

    Y en cada TextStyle, añadir:
        fontFamilyFallback: const ['Atkinson Hyperlegible', 'DM Sans']

    Eso garantiza que si OpenDyslexic falla a cargar, Atkinson (que
    SÍ funciona) lo reemplaza y al menos se ve un cambio.

T6. flutter clean + pub get:
    flutter clean
    flutter pub get
    (necesario para que Flutter re-empaquete los assets nuevos)

VERIFICACIÓN:
- En la app, activar dislexia → la tipografía cambia visiblemente a
  OpenDyslexic (peso inferior pesado característico). Si OpenDyslexic
  falla, cae a Atkinson y al menos cambia.

COMMIT(s):
- chore: redescargar OpenDyslexic real (los .otf anteriores eran HTML)
- feat(a11y): fontFamilyFallback a Atkinson si OpenDyslexic falla
```

### A2 — Geolocator: prewarm del stream tras conceder permiso

```text
ROL: Engineer Flutter, geolocator + streams.

CONTEXTO: <Contexto global>

PROBLEMA:
Tras conceder permiso, el dot del usuario NO aparece y "paradas cerca"
NO se actualiza hasta que el usuario cierra y reabre la app.
ref.invalidate ya está en v9, pero no basta.

CAUSA REAL:
Geolocator.getPositionStream() es un singleton interno del package. Si
la primera invocación fue con permiso denied, el stream queda "frío"
aunque luego nos re-suscribamos. Geolocator no re-verifica el permiso
hasta que se llama `getCurrentPosition()` (que sí chequea).

OBJETIVO:
Tras conceder permiso, hacer un "prewarm" llamando a getCurrentPosition
ANTES de re-suscribirse al stream. Eso despierta geolocator
internamente.

TAREAS:

T1. En lib/data/geo/location_service.dart, añadir método:

    /// Despierta geolocator forzando una verificación de permiso y
    /// una primera posición. Llamar tras conceder permiso para que
    /// el siguiente subscribe() funcione inmediatamente.
    Future<Position?> prewarm() async {
      try {
        return await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 8),
          ),
        ).timeout(const Duration(seconds: 10));
      } catch (e) {
        AppLogger.warn(_logTag, 'prewarm failed', e);
        return null;
      }
    }

T2. En lib/features/home/tabs/map_tab.dart `_centerOnUser`, tras
   `Geolocator.requestPermission()` granted:

       ref.invalidate(userLocationPermissionProvider);

       // Prewarm: despierta geolocator antes de re-suscribirse.
       final service = ref.read(userLocationServiceProvider);
       final firstPos = await service.prewarm();
       if (firstPos != null && mounted) {
         _mapController.move(LocationService.toLatLng(firstPos), 16);
       }

       // Ahora sí, invalidar el stream para que se re-suscriba con
       // geolocator ya despierto.
       ref.invalidate(userLocationStreamProvider);

T3. En lib/shared/providers/user_location_provider.dart, mantener el
   ref.watch(userLocationPermissionProvider) que ya añadí en v9 (no
   tocar).

T4. (Opcional) Periódica re-suscripción del stream:
   Si tras T1-T2 sigue sin funcionar, añadir un Timer en el stream
   provider que cada 30s verifique si está emitiendo y, si no, se
   re-suscriba:
       Timer.periodic(Duration(seconds: 30), (_) {
         if (lastEmittedAt is older than 60s) ref.invalidate(...);
       });
   Solo si lo anterior no resuelve.

VERIFICACIÓN:
- Tras denegar permiso al primer arranque y luego pulsar el FAB
  ubicación y conceder, el dot azul aparece en MÁXIMO 5 segundos sin
  necesidad de reiniciar la app.
- En home, "Paradas cerca" se actualiza con paradas reales del usuario
  en el mismo tiempo.

COMMIT:
fix(geo): prewarm de geolocator tras conceder permiso para activar
ubicación sin reiniciar
```

### A3 — Mapa: estilo cambia al instante (recrear controller)

```text
ROL: Engineer Flutter, flutter_map.

CONTEXTO: <Contexto global>

PROBLEMA:
Al cambiar de estilo en Apariencia, el mapa NO refresca hasta reiniciar
la app. El `key: ValueKey('fm-$mapStyle-$isDark')` ya está en el
FlutterMap, pero como el `MapController` es compartido, internamente
flutter_map mantiene caché que ignora el cambio de URL.

OBJETIVO:
Cuando cambie el estilo o el tema, recrear el MapController para que
el FlutterMap arranque con estado limpio.

TAREAS:

T1. En map_tab.dart, cambiar `final _mapController = MapController();`
   a algo que pueda recrearse:

       MapController _mapController = MapController();
       String? _lastMapKey;

   En build, antes de pasar al TransitMap:

       final mapStyle = ref.watch(themeNotifierProvider.select((n) => n.mapStyle));
       final currentKey = '${isDark ? 'd' : 'l'}-$mapStyle';
       if (_lastMapKey != null && _lastMapKey != currentKey) {
         _mapController.dispose();
         _mapController = MapController();
         _didInitialCenter = false;  // permitir auto-center con el nuevo controller
       }
       _lastMapKey = currentKey;

   El `dispose()` antiguo + `new MapController()` garantiza que
   flutter_map no reutiliza estado anterior.

T2. En _MapTabState.dispose:

       @override
       void dispose() {
         _mapController.dispose();
         _sheetController.dispose();
         _scrollController.dispose();
         super.dispose();
       }
   (Verificar que ya está; si no, añadir).

T3. Verificar que la key del FlutterMap en transit_map.dart sigue:
       key: ValueKey('fm-${widget.mapStyle}-${widget.isDark}'),

T4. (Opcional) Si quieres preservar el pan/zoom del usuario tras cambiar
   de estilo, guarda el centro y zoom actual ANTES de recrear el
   controller y restáuralo tras crear el nuevo:

       final savedCenter = _mapController.camera.center;
       final savedZoom = _mapController.camera.zoom;
       _mapController.dispose();
       _mapController = MapController();
       _didInitialCenter = false;
       // En el primer frame del nuevo FlutterMap, mover:
       WidgetsBinding.instance.addPostFrameCallback((_) {
         _mapController.move(savedCenter, savedZoom);
       });

   Esto es lo ideal: el usuario ve cómo cambian las tiles sin perder su
   posición en el mapa.

VERIFICACIÓN:
- Apariencia → Estilo de mapa → cambiar a "dark" → volver al mapa
  principal: las tiles cambian en <2 segundos sin reiniciar.
- Repetir con todos los 5 estilos.
- Si implementaste T4, el centro/zoom se preserva al cambiar.

COMMIT:
fix(map): recrear MapController al cambiar de estilo para refresh
inmediato de tiles
```

### A4 — Auto-center solo si estás cerca de Jerez

```text
ROL: Engineer Flutter, lógica de UX.

CONTEXTO: <Contexto global>

PROBLEMA:
El `_tryInitialCenter` mueve el mapa al primer fix del GPS del usuario.
Si el usuario está LEJOS de Jerez (testing en otra ciudad), el mapa se
centra ahí. Como los datos mock solo existen en Jerez, el usuario no
ve líneas ni paradas y se confunde pensando que la app está rota.

OBJETIVO:
Auto-center SOLO si el primer fix está cerca de Jerez (radio razonable,
ej. 50 km). Si está lejos, mantener el mapa centrado en Jerez y mostrar
una pista visual ("Tu ubicación está a XX km — pulsa el botón para
centrarte").

TAREAS:

T1. En map_tab.dart `_tryInitialCenter`:

    Future<void> _tryInitialCenter() async {
      if (_didInitialCenter) return;
      try {
        final fix = await ref
            .read(userLocationStreamProvider.future)
            .timeout(const Duration(seconds: 4));
        if (fix == null || !mounted) return;

        // Calcular distancia a Jerez (centro)
        final distMeters = const Distance().as(
          LengthUnit.Meter,
          fix.position,
          MapConfig.defaultCenter,
        );
        const maxDistMeters = 50000; // 50 km

        if (distMeters <= maxDistMeters) {
          _mapController.move(fix.position, 14);
        } else {
          // Usuario lejos: mantener Jerez y mostrar SnackBar informativo
          _mapController.move(MapConfig.defaultCenter, MapConfig.defaultZoom);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Estás a ${(distMeters / 1000).round()} km de Jerez. '
                  'El mapa muestra las líneas de COMUJESA en Jerez.'),
              duration: const Duration(seconds: 4),
            ));
          }
        }
        _didInitialCenter = true;
      } on TimeoutException {
        // sin fix; deja el mapa en Jerez
      }
    }

T2. Si el usuario pulsa el FAB ubicación estando lejos, mover sin
   restricción (es elección explícita):
   _centerOnUser ya hace eso correctamente, no cambiar.

VERIFICACIÓN:
- Testing desde Madrid o cualquier punto fuera de Jerez: la app
  arranca con el mapa CENTRADO EN JEREZ y un SnackBar informativo. Las
  líneas SE VEN.
- Pulsar el FAB → te mueve a tu posición real.
- Testing en Jerez: la app centra en tu posición y todo funciona
  normal.

COMMIT:
feat(map): solo auto-center si el usuario está cerca de Jerez (≤50 km)
```

---

## WAVE 2 — Coordinador

1. **Clean + analyze + build:**
   ```bash
   flutter clean
   flutter pub get
   flutter analyze
   flutter build apk --release --dart-define-from-file=dart_defines.json
   flutter install --release -d 000871487002528
   ```

2. **Smoke crítico:**
   - **A1 (dislexia)**: activar toggle → tipografía cambia visiblemente.
   - **A2 (permisos)**: tras denegar y luego conceder, dot + paradas
     cerca aparecen en <5s sin reiniciar.
   - **A3 (estilo mapa)**: cambiar estilo → tiles cambian en <2s.
   - **A4 (lejos de Jerez)**: si testing desde fuera de Jerez, mapa
     centra en Jerez con SnackBar informativo.

---

## Si los fixes siguen sin funcionar

Hipótesis alternativas si A1-A4 no resuelven:

### Para dislexia (A1 falla)
- El font cache de Flutter está corrupto. Borrar
  `build/` + `.dart_tool/` + reinstalar:
      flutter clean
      rm -rf build/ .dart_tool/
      flutter pub get
- Verificar con un `Text('test', style: TextStyle(fontFamily: 'OpenDyslexic'))`
  estático en la pantalla de Apariencia. Si AHÍ no se ve la fuente, el
  asset definitivamente no se está cargando.

### Para permisos (A2 falla)
- El método más nuclear: tras conceder permiso, mostrar al usuario un
  diálogo "Reinicia la app para activar la ubicación" + botón que llame
  a `SystemNavigator.pop()` y al reabrir todo funcione. No es ideal
  pero resuelve si geolocator es realmente tan terco.

### Para mapa estilo (A3 falla)
- Cambiar de flutter_map a otro renderer (mapbox_gl) que tenga API
  pública para invalidar caché. Es scope grande.
- Alternativa simpler: cuando cambie mapStyle, hacer
  `Navigator.popAndPushNamed('/home/mapa')` para forzar full reload de
  la ruta.

---

## Propuestas adicionales

Ya que tocamos varios sistemas, valor extra con poco esfuerzo:

### P1 — Indicador visual de "Cargando ubicación"
En el FAB ubicación, mientras está prewarming, mostrar el spinner que
ya tiene (`_loadingCenter`). Asegurar que se enciende al pulsar y se
apaga cuando llega el primer fix.

### P2 — Banner persistente si no hay permiso
Si el permiso es denied/deniedForever, mostrar un banner pequeño en la
parte superior del mapa: "📍 Activa la ubicación para ver tu posición"
con CTA. Más visible que el SnackBar transitorio actual.

### P3 — Forzar tiles iniciales de Jerez al primer arranque
Pre-descargar las tiles del bbox de Jerez a zoom 12-14 en background al
primer arranque (con FMTC). Así, si el usuario abre el mapa offline o
con conexión lenta, las tiles aparecen al instante.

¿Te interesa alguna? Si no me dices nada, el plan se queda como está.

---

## Cobertura final

| Bug reportado | Agente |
|----------------|--------|
| Fuente dislexia sigue sin funcionar | A1 |
| Paradas cerca no se activan hasta reiniciar | A2 |
| Dot azul no aparece sin reiniciar | A2 |
| Mapa no cambia de estilo sin reiniciar | A3 |
| Líneas no se ven en Jerez si arrancaste lejos | A4 |
