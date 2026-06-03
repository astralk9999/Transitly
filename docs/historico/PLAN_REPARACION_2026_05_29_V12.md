# Plan de reparación v12 — Transitly (bugs duros + features grandes)

**Fecha:** 2026-05-29
**Autor:** Claude Code (Opus 4.7)
**Plan anterior:** `PLAN_REPARACION_2026_05_28_V11.md`

---

## TL;DR

### BUGS PERSISTENTES (5)
| # | Bug | Causa raíz |
|---|-----|-------------|
| 1 | Mapa NO cambia de estilo sin reiniciar (4ª iteración) | El `MapController` se recrea, pero **FMTC `Provider.family<FMTCTileProvider?, String>` mantiene los stores entre estilos**. La caché interna sirve tiles del estilo viejo aunque el TileLayer pida URL nueva. Hay que **bypassear FMTC** al cambiar de estilo y usar `NetworkTileProvider()` directo durante el período de transición. |
| 2 | Al ir a mi ubicación, las líneas se desactivan y no se reactivan sin reiniciar | El `_centerOnUser` llama `ref.invalidate(userLocationPermissionProvider)` + `ref.invalidate(userLocationStreamProvider)`. Esto **reconstruye `mapFilterControllerProvider` si tiene dependencias indirectas**. Más probable: el `userLocationStreamProvider` con `autoDispose` se desuscribe → `mapFilterControllerProvider` (también autoDispose si lo es) se recrea y ejecuta `_loadFromPrefs()` async — durante el async load, el state es default `MapFilterState()` con todos los flags por defecto, **PERO ALGUNAS** flags por defecto excluyen líneas (`showOfficial:true`/`showCommunity:true` deberían ser inclusive). El bug crítico: `_filteredRoutes` línea 71-75 hace `r.status == RouteStatus.official` cuando `!showCommunity`. Si BOTH son true por defecto pero después load_from_prefs marca uno como false, durante el reload temporal **AMBOS pueden quedar false** → resultado vacío. |
| 3 | Al rotar pantalla, nav menu inutilizable | El `HomeBottomNav` está dentro de un Scaffold sin manejo de orientación. En landscape, el bottom nav ocupa demasiado alto + los chips/labels se cortan. |
| 4 | Dislexia: textos de animación de entrada se descolocan | El `_StaggeredTitle` del splash usa caracteres con `GoogleFonts.ibmPlexMono` fijo (ignora dislexia). Cuando dislexia activa, otros textos cambian a OpenDyslexic pero ese título sigue en Plex Mono → desalineación visual. |
| 5 | Filtros desplegable: al pasar de "Todas" a "Urbano" desaparecen TODAS y no vuelven | Mismo origen que bug #2. El `_filteredRoutes` línea 71-75 invierte la lógica de `showCommunity`: si comunidad está OFF, EXIGE que status sea official. Cuando el usuario cambia chip a "Urbano", el `_serviceTypeFilter = ServiceType.urban` se setea, pero algún otro filtro entra en conflicto temporalmente. |

### MEJORAS PEDIDAS (9)
| # | Mejora |
|---|--------|
| 6 | Mejorar animación de inicio |
| 7 | Sincronizar filtros mapa ↔ desplegable de líneas (deseleccionar línea = quitarla del mapa) |
| 8 | Anti-flicker al abrir Apariencia (se superpone unos segundos) |
| 9 | Mapas offline FUNCIONALES (FMTC download region real) |
| 10 | Login con Google (google_sign_in nativo + Supabase signInWithIdToken) |
| 11 | Mejorar UI login + validación inline + modo invitado destacado |
| 12 | Logo claro en modo oscuro / logo oscuro en modo claro |
| 13 | Botón "ir a ubicación de la línea" en desplegable (centrar bbox) |
| 14 | 7 fondos tipo React-bits implementados en Flutter (Aurora, Beams, Balatro, ColorBends, Dither, DotField, FloatingLines) |

---

## Decisiones tomadas contigo

- **Fondos**: implementar los 7 equivalentes Flutter (no son comandos JS reales, los reemplazamos con CustomPainter/FragmentShader).
- **Google Sign-In**: plugin nativo `google_sign_in` + `signInWithIdToken` a Supabase (UX más pulida que webview).
- **Botón línea**: centrar el mapa en el **bbox** de la línea (muestra todo el polyline).
- **Login UX**: diseño visual + validación inline + modo invitado destacado.

---

## Estructura del plan

```
WAVE 1 (5 agentes paralelos — BUGS críticos)
├── A1  Mapa: bypass FMTC al cambiar estilo (resolución bug #1, 4ª iter)
├── A2  Filtros: causa raíz de líneas que se desactivan (bugs #2 y #5)
├── A3  Rotación pantalla + dislexia en splash (bugs #3 y #4)
├── A4  Anti-flicker Apariencia + logo dinámico claro/oscuro (mejoras #8 y #12)
└── A5  Filtros sync desplegable + botón ir a línea (mejoras #7 y #13)

WAVE 2 (4 agentes paralelos — FEATURES)
├── A6  Mapas offline funcionales (FMTC download region)
├── A7  Login con Google + UX login mejorada (mejoras #10 y #11)
├── A8  Animación de inicio premium (mejora #6)
└── A9  7 fondos React-bits equivalentes Flutter (mejora #14)

WAVE 3 (coordinador)
└── flutter clean + pub get + analyze + build APK + install
```

### Tabla de archivos por agente

| Agente | Archivos clave |
|--------|----------------|
| **A1** | `lib/data/fmtc/fmtc_provider.dart`, `lib/features/map/transit_map.dart` |
| **A2** | `lib/features/home/tabs/map_tab.dart` (`_filteredRoutes`), `lib/features/map/map_filter_controller.dart`, `lib/features/home/tabs/map_tab.dart` (`_centerOnUser`) |
| **A3** | `lib/features/splash/splash_screen.dart` (`_StaggeredTitle`), `lib/features/home/home_shell.dart` o `home_bottom_nav.dart` (orientation handling) |
| **A4** | `lib/features/appearance/appearance_screen.dart` (anti-flicker con `pushReplacement` o `FadeTransition`), `lib/features/splash/splash_screen.dart` (logo dinámico), `lib/features/home/widgets/profile_header_card.dart` (logo dinámico) |
| **A5** | `lib/features/map/widgets/map_filter_sheet.dart` (sync inverso), `lib/features/home/tabs/map_tab.dart` (sheet de líneas: handler de deselección + botón GPS), `lib/shared/widgets/route_card.dart` (botón nuevo) |
| **A6** | `lib/features/offline/widgets/region_download_sheet.dart`, `lib/data/fmtc/fmtc_region_service.dart` (NUEVO) |
| **A7** | `pubspec.yaml` (añadir `google_sign_in`), `lib/features/auth/signin_screen.dart` (rediseño + Google), `lib/features/auth/signup_screen.dart` (idem), `lib/data/auth/auth_repository_supabase.dart` (método nuevo) |
| **A8** | `lib/features/splash/splash_screen.dart` (animación premium con stagger + particles + glow ya estaba, mejorar fluidez) |
| **A9** | `lib/core/theme/backgrounds/app_background.dart` (registrar 7 nuevos), `lib/core/theme/backgrounds/prefab_backgrounds.dart`, `lib/shared/widgets/background_wrapper.dart`, 7 archivos `lib/core/theme/backgrounds/painters/*.dart` (NUEVOS) |

### Conflictos controlados

- `lib/features/home/tabs/map_tab.dart`: A2 toca `_centerOnUser` y `_filteredRoutes`. A5 toca el sheet de líneas. Coordinador resuelve si hay conflicto trivial.
- `lib/features/splash/splash_screen.dart`: A3 (dislexia) + A4 (logo dinámico) + A8 (animación premium). Coordinar entre ellos via reportes.
- `lib/core/theme/backgrounds/*.dart`: A9 reescribe ampliamente, no solapa con nadie.

---

## WAVE 1 — Briefs

### A1 — Mapa: bypass FMTC al cambiar estilo

```text
ROL: Engineer Flutter senior, flutter_map + flutter_map_tile_caching.

PROBLEMA (4ª iteración):
El mapa NO cambia de estilo sin reiniciar la app, a pesar de:
- v9: key explícita en TileLayer
- v10: key compuesta en FlutterMap
- v11: MapController recreable

CAUSA RAÍZ (verificada ahora):
- lib/data/fmtc/fmtc_provider.dart:
    final fmtcTileProviderProvider =
        Provider.family<FMTCTileProvider?, String>((ref, style) {...});
  Cada estilo tiene su store FMTC. Cuando cambias de "streets" a "dark":
  1. El FlutterMap se recrea con la nueva key.
  2. El TileLayer pide URL del estilo "dark".
  3. Pero el `fmtcTileProvider` del store "jerez-dark" SIRVE tiles que ya
     tenía cacheadas con la URL VIEJA (porque la URL es parte del request
     pero FMTC indexa por z/x/y, ignorando query strings).
  4. Resultado: el mapa muestra tiles del estilo viejo o, peor, mezcla
     de varios estilos hasta que se invalide el store.

SOLUCIÓN: usar NetworkTileProvider() durante un periodo de transición
(2 segundos) cuando se detecta cambio de estilo. Eso fuerza al TileLayer
a descargar tiles frescas. Tras el periodo, vuelve a usar FMTC.

ARCHIVOS:
- lib/features/map/transit_map.dart (lógica de bypass temporal)
- lib/features/home/tabs/map_tab.dart (pasar a TransitMap el bypass flag)

TAREAS:

T1. En map_tab.dart, en build:
    final mapStyle = ref.watch(themeNotifierProvider.select((n) => n.mapStyle));
    final currentMapKey = '${isDark ? "d" : "l"}-$mapStyle';
    final bool bypassFmtc;
    if (_lastMapKey != null && _lastMapKey != currentMapKey) {
      // Cambio de estilo detectado → bypass FMTC por 2 segundos
      _bypassFmtcUntil = DateTime.now().add(const Duration(seconds: 2));
      bypassFmtc = true;
      // Resto del recreate del MapController (ya está)
      ...
    } else {
      bypassFmtc = _bypassFmtcUntil != null &&
          DateTime.now().isBefore(_bypassFmtcUntil!);
    }

T2. Añadir campo:
    DateTime? _bypassFmtcUntil;

T3. Pasar a TransitMap:
    TransitMap(
      ...
      fmtcTileProvider: bypassFmtc ? null : fmtcTp,
    )

T4. En transit_map.dart, asegurar que si `widget.fmtcTileProvider == null`,
    el TileLayer usa NetworkTileProvider() explícito:
    TileLayer(
      ...
      tileProvider: widget.fmtcTileProvider ?? NetworkTileProvider(),
      ...
    )

T5. (Alternativa más simple) Si T1-T4 no resuelve, invalidar el store FMTC
    al cambiar estilo:
    if (_lastMapKey != null && _lastMapKey != currentMapKey) {
      // Limpiar store del estilo nuevo (descarga frescas)
      unawaited(FMTCStore('jerez-$mapStyle').manage.reset());
      ...
    }

VERIFICACIÓN:
- Apariencia → Estilo de mapa → seleccionar "dark" → volver al mapa.
  Las tiles cambian a dark en <3s.
- Repetir con los 5 estilos.
- En NINGÚN momento reiniciar la app.

COMMIT:
fix(map): bypass FMTC temporalmente al cambiar estilo (resolución 4ª iter)
```

---

### A2 — Filtros: líneas se desactivan al ir a ubicación

```text
ROL: Engineer Flutter senior, debugging filtros + providers.

PROBLEMAS:
1. Al pulsar FAB ubicación, todas las líneas desaparecen del desplegable.
2. Al cambiar chip de "Todas" a "Urbano", desaparecen todas.

CAUSA RAÍZ A INVESTIGAR:
- _filteredRoutes (líneas 56-125) lee `ref.read(mapFilterControllerProvider)`.
  No es `ref.watch` → si los filtros cambian fuera del rebuild trigger,
  no se re-ejecuta. PERO en el build, sí se re-ejecuta porque el provider
  changes → rebuild → re-ejecuta.

- Líneas 66-75 tienen lógica INVERSA peligrosa:
    if (!f.showOfficial) → excluye los official (.where(status != official))
    if (!f.showCommunity) → INCLUYE solo official (.where(status == official))
  Si BOTH son false, filtered = vacío (status != official AND status == official).

- Hipótesis: `mapFilterControllerProvider._loadFromPrefs()` async load. Durante
  el primer microsegundo, state es `MapFilterState()` default (showOfficial:true,
  showCommunity:true). Luego se carga de prefs. Si los prefs tienen "showCommunity:
  false" guardado de antes, queda false. Si además algún flag pone showOfficial
  en false, todas las líneas se filtran fuera.

ARCHIVOS:
- lib/features/home/tabs/map_tab.dart (`_filteredRoutes` y `_centerOnUser`)
- lib/features/map/map_filter_controller.dart

TAREAS:

T1. Hardening de _filteredRoutes lines 66-75:
    // Antes:
    if (!f.showOfficial) {
      filtered = filtered.where((r) => r.status != RouteStatus.official).toList();
    }
    if (!f.showCommunity) {
      filtered = filtered.where((r) => r.status == RouteStatus.official).toList();
    }

    // Después (lógica defensiva):
    if (!f.showOfficial && !f.showCommunity) {
      // Si AMBOS están desactivados, no aplicar filtro (mostrar todo) y log warning
      AppLogger.warn('Filter', 'showOfficial AND showCommunity both false; ignoring');
    } else {
      if (!f.showOfficial) {
        filtered = filtered.where((r) => r.status != RouteStatus.official).toList();
      }
      if (!f.showCommunity) {
        filtered = filtered.where((r) => r.status == RouteStatus.official).toList();
      }
    }

T2. Usar `ref.watch` en lugar de `ref.read` en _filteredRoutes
   para asegurar que el filtro reacciona a cambios:
   final f = ref.watch(mapFilterControllerProvider);

T3. Si `_centerOnUser` está disparando algún reload de filter:
   En map_tab.dart en _centerOnUser, después del invalidate de location
   providers, NO invalidar nada del filter. Verificar que no hay
   ref.invalidate(mapFilterControllerProvider) accidental en la cadena.

T4. Logs de debug temporal para ver state del filter:
   En _filteredRoutes inicio, AppLogger.debug('Filter',
   'showOfficial=${f.showOfficial}, showCommunity=${f.showCommunity}, '
   'disabledLines=${f.disabledLines.length}, '
   'total=${all.length}, filtered=${filtered.length}');
   Eliminar tras debug.

T5. Persistencia robusta:
   En map_filter_controller.dart, asegurar que `_loadFromPrefs` NO
   sobrescribe el state si el JSON está corrupto. Catch ya está,
   verificar que keep defaults si parse falla.

VERIFICACIÓN:
- Reset filtros (botón Reset en sheet).
- Pulsar FAB ubicación → las líneas siguen visibles.
- Cambiar chip "Todas" → "Urbano" → solo se filtran a urbanas, NO todas
  desaparecen.
- Cerrar/abrir app → los filtros persisten.

COMMIT:
fix(map): lógica defensiva en _filteredRoutes para no vaciar la lista
fix(map): usar ref.watch en _filteredRoutes
```

---

### A3 — Rotación pantalla + dislexia en splash

```text
ROL: Engineer Flutter, layouts responsive + typography.

PROBLEMAS:
1. Al rotar pantalla, nav menu inutilizable.
2. Dislexia: textos de animación de entrada se descolocan.

CAUSAS:
1. HomeShell tiene MediaQuery breakpoint para mobile/tablet/desktop pero
   probablemente no handle landscape específicamente. En landscape, el
   bottom nav ocupa demasiado alto verticalmente.
2. _StaggeredTitle en splash usa fontFamily fijo 'IBM Plex Mono' sin
   respetar el toggle de dislexia → cuando otros textos cambian a
   OpenDyslexic, el título sigue Plex Mono → desalineación.

ARCHIVOS:
- lib/features/home/home_shell.dart o widgets/home_bottom_nav.dart
- lib/features/splash/splash_screen.dart (_StaggeredTitle)

TAREAS:

T1. Orientation landscape: forzar portrait en HomeShell
   (más simple y razonable porque la app es de transporte público móvil):

   En main.dart, tras WidgetsFlutterBinding.ensureInitialized():
       SystemChrome.setPreferredOrientations([
         DeviceOrientation.portraitUp,
         DeviceOrientation.portraitDown,
       ]);

   Esto bloquea landscape completamente. Aceptable para app de mapa móvil.

   Si quieres support landscape: en home_shell.dart, detectar
   MediaQuery.of(context).orientation == Orientation.landscape y
   cambiar a un layout de NavigationRail lateral en lugar de bottom nav.

T2. Dislexia en splash:
   En splash_screen.dart _StaggeredTitle, cambiar el TextStyle de cada
   letra:
       // Antes:
       style: GoogleFonts.ibmPlexMono(...)
       // Después:
       style: TransitTypography.statusBadge(color).copyWith(
         fontSize: 36,
         letterSpacing: 4,
         fontWeight: FontWeight.w900,
       )
   Eso asegura que el title respeta dislexia (usa _activeFontFamily).

T3. Anti-descoloque: el stagger de cada letra usa width medido del
   GoogleFonts. Si la fuente cambia a OpenDyslexic (más ancha), los
   caracteres pueden solapar. Cambiar de Row a Wrap con runSpacing 0
   o usar IntrinsicWidth alrededor de cada letra para que se midan
   correctamente.

VERIFICACIÓN:
- Rotar el móvil → si T1 bloquea landscape, la app se mantiene en portrait
  siempre. Si implementaste landscape support, el rail lateral funciona.
- Activar dislexia → el title "TRANSITLY" del splash mantiene
  alineación correcta y cambia a OpenDyslexic.

COMMIT(s):
- fix(home): bloquear landscape en main para evitar nav roto
- fix(splash): título respeta toggle de dislexia
```

---

### A4 — Anti-flicker Apariencia + Logo dinámico claro/oscuro

```text
ROL: Engineer Flutter, navegación + branding.

PROBLEMAS:
1. Al darle a "Personalizar apariencia" se superpone la pestaña por unos
   segundos antes de quedar fija.
2. Logo: usar logo CLARO (transitly_logo_white_square.png) en modo
   oscuro, y logo COLOR/OSCURO (transitly_logo.png) en modo claro.

ARCHIVOS:
- lib/features/appearance/appearance_screen.dart (transición)
- lib/features/splash/splash_screen.dart (logo dinámico)
- lib/features/home/widgets/profile_header_card.dart (logo en header)

TAREAS:

T1. Anti-flicker en Apariencia:
   El problema es que el Scaffold de Apariencia se construye con
   `backgroundColor: Colors.transparent` (en v8/v9). Mientras el
   BackgroundWrapper renderiza el fondo, hay un flash.
   Solución: añadir un Container con `c.bgRoot` durante los primeros
   200ms (FadeTransition):

       AnimatedSwitcher(
         duration: const Duration(milliseconds: 250),
         child: KeyedSubtree(
           key: ValueKey('appearance-body'),
           child: SafeArea(...),
         ),
       )

   O simpler: usar Hero animation con tag desde el botón "Apariencia"
   del menú al título de la pantalla.

T2. Logo dinámico:
   Crear un helper en `lib/shared/widgets/transitly_logo.dart`:

       String transitlyLogoAsset(bool isDark) {
         return isDark
             ? 'assets/branding/transitly_logo_white_square.png'
             : 'assets/branding/transitly_logo.png';
       }

   Aplicar en:
   - splash_screen.dart: Image.asset(transitlyLogoAsset(isDark), ...)
   - profile_header_card.dart: idem si hay logo
   - cualquier otro sitio con logo fijo

VERIFICACIÓN:
- Abrir Apariencia → no hay flash visible, transición fluida.
- Cambiar tema a claro → el logo del splash al reiniciar es la versión
  color/oscura.
- Cambiar a oscuro → logo claro/blanco.

COMMIT(s):
- fix(appearance): anti-flicker al abrir con FadeTransition
- feat(branding): logo adaptado al modo claro/oscuro
```

---

### A5 — Filtros sync desplegable + botón ir a línea

```text
ROL: Engineer Flutter, sync entre UIs.

PROBLEMAS:
1. Cuando deselecciono una línea en el sheet de filtros (Mostrar líneas),
   debería desaparecer también del desplegable del mapa (sheet inferior).
2. Botón "ir a ubicación de la línea" en el desplegable del mapa:
   centra el mapa en bbox de la línea.

ARCHIVOS:
- lib/features/home/tabs/map_tab.dart (sheet de líneas inferior usa
  filteredRoutes; ya debería estar sincronizado tras A2)
- lib/shared/widgets/route_card.dart (añadir botón GPS al lado derecho)
- lib/features/home/tabs/map_tab.dart (handler del botón)

TAREAS:

T1. Sync filtros con desplegable (validar que ya funciona):
   Tras A2, `_filteredRoutes` usa `ref.watch(mapFilterControllerProvider)`
   y los `disabledLines` se aplican. El sheet inferior debe respetar el
   filtro. Verificar:
   - Desactivar una línea en el sheet de filtros (icono filter del mapa).
   - Esa línea desaparece también del desplegable (sheet inferior).
   Si no, ajustar el itemCount/itemBuilder del sheet inferior.

T2. Botón "ir a ubicación de la línea":
   En route_card.dart, añadir un IconButton en el trailing:

       trailing: Row(
         mainAxisSize: MainAxisSize.min,
         children: [
           if (estimatedMinutes != null) Text(estimatedMinutes!, ...),
           IconButton(
             icon: Icon(Icons.gps_fixed, size: 18, color: c.accent),
             tooltip: 'Ir a la línea',
             onPressed: onGoToLine,
           ),
         ],
       ),

   Añadir parámetro `VoidCallback? onGoToLine` al RouteCard.

T3. Handler en map_tab.dart:
   Al construir el RouteCard, pasar:

       onGoToLine: () {
         final cache = ref.read(mapDataCacheProvider);
         final bounds = cache.routeBounds[route.id];
         if (bounds != null && bounds.length == 4) {
           // bounds = [north, east, south, west]
           final swCorner = LatLng(bounds[2], bounds[3]);
           final neCorner = LatLng(bounds[0], bounds[1]);
           _mapController.fitCamera(
             CameraFit.bounds(
               bounds: LatLngBounds(swCorner, neCorner),
               padding: const EdgeInsets.all(40),
             ),
           );
           // Colapsar el sheet para que se vea el mapa
           _sheetController.animateTo(0.12,
               duration: const Duration(milliseconds: 250),
               curve: Curves.easeInOut);
         }
       },

VERIFICACIÓN:
- En el sheet inferior, pulsar el icono GPS de la línea L1 → el mapa
  centra y hace zoom para mostrar todo el recorrido de L1.

COMMIT:
feat(map): botón ir a línea en RouteCard del desplegable
```

---

## WAVE 2 — Briefs

### A6 — Mapas offline FUNCIONALES

```text
ROL: Engineer Flutter senior, flutter_map_tile_caching v10.

PROBLEMA:
El apartado de "Añadir región offline" actualmente no descarga tiles
reales. Hace una RPC a Supabase (mock).

OBJETIVO:
1. Permitir al usuario seleccionar un bbox del mapa (rectángulo).
2. Descargar las tiles del estilo activo para zoom 10-16 (~1000-50000 tiles).
3. Mostrar progreso en tiempo real.
4. Persistir en FMTC store local.

ARCHIVOS:
- lib/features/offline/widgets/region_download_sheet.dart
- lib/data/fmtc/fmtc_region_service.dart (NUEVO)

TAREAS:

T1. fmtc_region_service.dart:
    class FmtcRegionService {
      Future<Stream<DownloadProgress>> downloadRegion({
        required String storeName,
        required LatLngBounds bounds,
        required int minZoom,
        required int maxZoom,
        required String urlTemplate,
      }) async {
        final store = FMTCStore(storeName);
        await store.manage.create();

        final region = RectangleRegion(bounds);
        final downloadable = region.toDownloadable(
          minZoom: minZoom,
          maxZoom: maxZoom,
          options: TileLayer(
            urlTemplate: urlTemplate,
            subdomains: MapConfig.subdomains,
            userAgentPackageName: 'com.transitly.transitly',
          ),
        );

        return store.download.startForeground(region: downloadable);
      }
    }

T2. UI del sheet:
   - Bbox selector: el usuario hace pan/zoom y un overlay rectangular
     marca el área a descargar (LatLngBounds del viewport actual).
   - Slider para zoom max (10-16).
   - Cálculo previsto de tamaño (regla heurística: 15 KB/tile).
   - Botón "Descargar".
   - Mientras descarga: LinearProgressIndicator + texto "X/Y tiles".
   - Botón cancelar.

T3. Listado de regiones descargadas:
   - Mostrar en el sheet con nombre, tamaño, estilo, fecha.
   - Botón eliminar por región.

T4. Indicador "offline" en el mapa cuando estás dentro de bbox descargado:
   Pequeño badge en una esquina indicando "📦 Offline".

VERIFICACIÓN:
- Descargar región de centro de Jerez a zoom 14, ~50 MB.
- Activar modo avión.
- Abrir mapa, navegar por la zona descargada → tiles aparecen.
- Salir del bbox → tiles no aparecen (gris).

COMMIT(s):
- feat(offline): descarga real de regiones con FMTC
- feat(offline): listado y eliminación de regiones
```

---

### A7 — Google Sign-In + UX login mejorada

```text
ROL: Engineer Flutter senior, OAuth + UI design.

DECISIONES:
- google_sign_in plugin nativo + signInWithIdToken a Supabase.
- Login UX: visual pulido + validación inline + modo invitado destacado.

ARCHIVOS:
- pubspec.yaml: añadir google_sign_in: ^6.2.1
- lib/features/auth/signin_screen.dart (rediseño)
- lib/features/auth/signup_screen.dart (rediseño)
- lib/data/auth/auth_repository_supabase.dart (método nuevo)
- android/app/build.gradle.kts (configuración Google Sign In)
- android/app/src/main/AndroidManifest.xml (verificar)

TAREAS:

T1. Añadir dependencia:
    google_sign_in: ^6.2.1

T2. Configurar OAuth en Google Cloud Console (DOCUMENTAR para usuario):
    El usuario debe:
    1) Ir a Google Cloud Console → APIs & Services → Credentials.
    2) Crear OAuth 2.0 Client ID para Android.
    3) Añadir SHA-1 del keystore.
    4) Anotar el client ID.
    5) En Supabase Dashboard → Authentication → Providers → Google →
       activar y pegar el client ID.

T3. Método de auth:
    En auth_repository_supabase.dart:

        Future<void> signInWithGoogle() async {
          final googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
          final user = await googleSignIn.signIn();
          if (user == null) throw 'Google sign-in cancelled';
          final googleAuth = await user.authentication;
          final idToken = googleAuth.idToken;
          if (idToken == null) throw 'No ID token from Google';
          await Supabase.instance.client.auth.signInWithIdToken(
            provider: OAuthProvider.google,
            idToken: idToken,
            accessToken: googleAuth.accessToken,
          );
        }

T4. UI rediseñada:
    - Hero card con gradiente accent en el top (180px alto).
    - Logo Transitly grande centrado.
    - Campos email/password con animaciones de focus.
    - Validación inline: mensajes de error bajo cada campo en tiempo real
      (formato email, longitud password mínima 8, etc.).
    - Botón "Continuar con Google" arriba (full width, color blanco con
      icono G de Google).
    - Separador "o" con líneas a los lados.
    - Botón "Continuar con email" o formulario directo.
    - Al fondo destacado: "¿Quieres explorar primero? Continuar como
      invitado" como link textual grande.

T5. Validación inline:
    Usar TextFormField con validator + AutovalidateMode.onUserInteraction.
    Mensajes:
    - Email: "Email no válido"
    - Password: "Mínimo 8 caracteres" / "Sin números"
    - Confirmar password (signup): "No coinciden"

VERIFICACIÓN:
- Pulsar "Continuar con Google" → popup nativo de Google → seleccionar
  cuenta → vuelve a la app autenticado.
- Errores de validación aparecen mientras escribes (no al pulsar submit).
- Botón "Continuar como invitado" lleva directamente al home sin auth.

COMMIT(s):
- feat(auth): Google Sign-In con google_sign_in nativo + Supabase
- feat(auth): rediseño UI signin/signup con validación inline + guest mode
```

---

### A8 — Animación de inicio premium (refinamiento)

```text
ROL: Engineer Flutter, animaciones.

CONTEXTO:
El plan v8 ya implementó stagger + particles + glow. El usuario quiere
mejorarla más.

ARCHIVOS:
- lib/features/splash/splash_screen.dart
- lib/features/splash/particles_painter.dart (verificar/extender)

TAREAS:

T1. Curvas más naturales:
    Usar Curves.easeInOutQuint para fade del logo.
    Usar Curves.elasticOut para scale.
    Curva personalizada para slide del título (overshoot 5%).

T2. Glow pulsante continuo:
    Mientras la app permanece en splash (waiting), el glow detrás del
    logo pulsa suavemente con un Tween en bucle. Sensación "viva".

T3. Onda de partículas explosiva:
    Al aparecer el logo, emitir una onda radial de partículas desde el
    centro hacia fuera (no solo las flotantes de fondo).

T4. Transición de salida:
    Al navegar a /home o /onboarding, hacer fade out en lugar de hard
    cut. Usar PageRouteBuilder con FadeTransition.

T5. Coordinar con A3 (dislexia) y A4 (logo dinámico):
    - El título usa _activeFontFamily ahora (no Plex Mono fijo).
    - El logo usa el helper transitlyLogoAsset(isDark).

VERIFICACIÓN:
- Reiniciar app → animación fluida y memorable.
- Si tienes reduceMotion ON → todo aparece instantáneo (ya existía).

COMMIT:
feat(splash): refinamiento animación con curvas naturales + onda particles
```

---

### A9 — 7 fondos React-bits equivalentes Flutter

```text
ROL: Engineer Flutter, CustomPainter + FragmentShader.

CONTEXTO:
El usuario quiere 7 fondos inspirados en react-bits:
- Aurora (luces aurora boreal)
- Beams (haces de luz)
- Balatro (glitch psicodélico)
- ColorBends (gradientes flow)
- Dither (pixel art)
- DotField (campo de puntos)
- FloatingLines (líneas flotantes)

Los comandos `npx shadcn` no aplican porque son JS/React. Hay que
implementar en Flutter.

ARCHIVOS:
- lib/core/theme/backgrounds/painters/aurora_painter.dart (NUEVO)
- lib/core/theme/backgrounds/painters/beams_painter.dart (NUEVO)
- lib/core/theme/backgrounds/painters/balatro_painter.dart (NUEVO)
- lib/core/theme/backgrounds/painters/color_bends_painter.dart (NUEVO)
- lib/core/theme/backgrounds/painters/dither_painter.dart (NUEVO)
- lib/core/theme/backgrounds/painters/dot_field_painter.dart (NUEVO)
- lib/core/theme/backgrounds/painters/floating_lines_painter.dart (NUEVO)
- lib/core/theme/backgrounds/app_background.dart (añadir 7 patterns)
- lib/core/theme/backgrounds/prefab_backgrounds.dart (registrar)
- lib/shared/widgets/background_wrapper.dart (añadir 7 ramas al switch)

TAREAS:

T1. Para cada painter, usar un AnimationController con repeat() y un
   Animation<double> que se pase como `repaint:` del CustomPainter.

T2. Aurora:
    Capas de gradientes radiales animados que se desplazan suavemente.
    3-4 capas con colores accent y variantes. Modo aditivo (BlendMode.plus).

T3. Beams:
    Líneas diagonales largas con gradiente accent → transparente. Rotan
    lentamente. Stack de 6-8 beams con phase offset.

T4. Balatro (glitch psicodélico):
    Patrón circular concéntrico con glitch (offset aleatorio en X).
    Inspirado en el menú del videojuego Balatro. Colores accent + neon.

T5. ColorBends:
    Stack de Sin/Cos waves en gradiente. Fluido orgánico.

T6. Dither:
    Patrón retro de pixels en gradiente. Bayer 4×4 matrix dithering.

T7. DotField:
    Grid de puntos con tamaño variable según noise field 2D.

T8. FloatingLines:
    Líneas verticales/horizontales que se desplazan suavemente, con
    fade en/out al alcanzar los bordes.

T9. En prefab_backgrounds.dart:
    final prefabBackgrounds = <AppBackground>[
      const NoneBackground(),
      const ShaderBackground('shaders/smoke.frag', Colors.purple),
      const GradientBackground([...]),
      const ProceduralBackground(ProceduralPattern.softGrid),
      const ProceduralBackground(ProceduralPattern.topoLines),
      const ProceduralBackground(ProceduralPattern.aurora),  // NUEVO
      const ProceduralBackground(ProceduralPattern.beams),
      const ProceduralBackground(ProceduralPattern.balatro),
      const ProceduralBackground(ProceduralPattern.colorBends),
      const ProceduralBackground(ProceduralPattern.dither),
      const ProceduralBackground(ProceduralPattern.dotField),
      const ProceduralBackground(ProceduralPattern.floatingLines),
    ];

T10. background_wrapper.dart: extender el switch para usar los painters
    nuevos (similar a softGrid/topoLines pero con su painter respectivo).

VERIFICACIÓN:
- Apariencia → Fondo: lista crece a 12 opciones.
- Seleccionar cada una → renderiza correctamente con animación.
- Slider de opacidad afecta solo al fondo.
- En dispositivo bajo (testing), no causa lag > 60 FPS.

COMMIT(s):
- feat(theme): 7 fondos procedurales inspirados en react-bits
- feat(theme): registrar Aurora, Beams, Balatro, ColorBends, Dither,
  DotField, FloatingLines
```

---

## WAVE 3 — Coordinador

1. **Clean + analyze + build + install:**
   ```bash
   flutter clean
   flutter pub get
   flutter analyze
   flutter build apk --release --dart-define-from-file=dart_defines.json
   flutter install --release -d 000871487002528
   ```

2. **Smoke crítico (en orden):**
   - **A1 (mapa estilo)**: cambiar entre 5 estilos → tiles cambian sin reiniciar.
   - **A2 (filtros)**: pulsar FAB ubicación → líneas siguen visibles. Cambiar chip a "Urbano" → solo urbanas.
   - **A3 (rotación)**: rotar el móvil → app sigue en portrait. Dislexia: título splash alineado.
   - **A4 (apariencia)**: abrir Apariencia → sin flash. Logo cambia según tema.
   - **A5 (filtros sync)**: deseleccionar línea en filter sheet → desaparece del desplegable. Pulsar GPS icon en RouteCard → mapa centra en bbox.
   - **A6 (offline)**: descargar región de Jerez → activar modo avión → tiles aparecen offline.
   - **A7 (Google + login)**: pulsar Google → autenticado en Supabase. Validación inline funciona.
   - **A8 (splash)**: animación más fluida y memorable.
   - **A9 (fondos)**: 7 fondos nuevos seleccionables en Apariencia.

---

## Riesgos y notas

- **A1 (FMTC bypass)**: si el bypass no resuelve, alternativa: `store.manage.reset()` al cambiar estilo. Pierde caché de ese estilo pero garantiza tiles frescas.
- **A2 (filtros)**: el bug puede ser de persistence corrupto. El reset (botón) lo arregla. Hardening defensivo del filtered es la prioridad.
- **A6 (offline FMTC v10)**: la API real puede haber cambiado entre v9 y v10. Documentar diferencias en el reporte.
- **A7 (Google Sign-In)**: requiere configuración manual del usuario en Google Cloud Console y Supabase. Documentado.
- **A9 (7 fondos)**: cada painter es ~50-100 líneas. Mucho código pero aislado.

---

## Cobertura

| # | Item reportado | Agente |
|---|------------------|--------|
| 1 | Mapa no cambia sin reiniciar | A1 |
| 2 | Líneas se desactivan al ir ubicación | A2 |
| 3 | Rotación rompe nav | A3 |
| 4 | Dislexia descoloca splash | A3 |
| 5 | Filtros "Todas → Urbano" vacía | A2 |
| 6 | Mejorar animación inicio | A8 |
| 7 | Sync filtros ↔ desplegable | A5 |
| 8 | Anti-flicker apariencia | A4 |
| 9 | Mapas offline funcional | A6 |
| 10 | Login Google | A7 |
| 11 | Mejorar UI login | A7 |
| 12 | Logo dinámico claro/oscuro | A4 |
| 13 | Botón ir a línea en sheet | A5 |
| 14 | 7 fondos react-bits | A9 |
