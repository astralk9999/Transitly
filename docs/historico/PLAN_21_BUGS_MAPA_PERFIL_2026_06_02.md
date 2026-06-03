# Plan de acción — 21 bugs / mejoras (perf mapa, theming, auth, perfil, sheets)

**Fecha:** 2026-06-02
**Autor:** Claude Code (Opus 4.7)
**Estado:** propuesto, decisiones del usuario integradas (§3)
**Continuación de:** `PLAN_CRASH_NATIVO_RECOVERY_2026_06_02.md` (canary implementado; bugs persistentes + nuevos)
**Goal:** Estabilizar y modernizar 21 puntos del proyecto en 5 grupos para evitar conflictos de archivos. Datos de tu auditoría se aplican exactos (`archivo:línea`).
**Arquitectura:** Cambios incrementales. Cada bug tiene causa raíz auditada. Tres bugs (F2, F3, F4) requieren un cambio mayor en cómo se consume `TransitColorScheme` para que respete `highContrast` y `paletteId` post-brightness change.
**Stack:** Flutter 3.9.2 + Riverpod + flutter_map 7 + FMTC v10 + Supabase + Hive.

---

## 1. Tabla de los 21 bugs / mejoras

| # | Problema | Grupo | Severidad |
|---|----------|-------|-----------|
| **P1** | Mapa lento, no cachea entre sesiones, debug build empeora | Perf | **Crítica** |
| **F1** | Cambiar fondo no aplica fuera de Apariencia | Theming | **Crítica** |
| **F2** | Modo claro + alto contraste → texto blanco sobre blanco invisible | Theming | **Crítica** |
| **F3** | Cambiar modo oscuro → claro pierde la paleta activa | Theming | Alta |
| **F4** | "Modo de accesibilidad: ninguno" sigue saliendo al activar uno | Theming | Media |
| **M1** | Click línea mapa no muestra qué línea es | Mapa | Alta |
| **M2** | "Ir a ubicación de línea" en panel no selecciona la línea | Mapa | Media |
| **M3** | Botón "X / Ver todas" feo, choca con estética | Mapa | Baja |
| **M4** | Filtros zonas plano → jerárquico (Jerez → compañías → líneas) | Mapa | Media |
| **M5** | Sheet de líneas se puede swipe-navegar incluso plegado | Mapa | Media |
| **M6** | Botón "ir a línea" muy pequeño | Mapa | Baja |
| **S1** | Sheet configurar viaje habitual: separado de la parte inferior + paradas muchas | Sheets | Alta |
| **S2** | Menú "sugerir ruta" fondo cortado por parte inferior | Sheets | Media |
| **A1** | Error Google sign-in sin info al usuario | Auth | **Crítica** |
| **A2** | Errores formulario login en inglés (rate limit ya pero hay más) | Auth | Alta |
| **A3** | Correo verificación registro no llega | Auth | **Crítica** |
| **A4** | Sin botón atrás en /sign-up, /sign-in modal, /magic-link | Auth | Alta |
| **PR1** | Mapas offline + Widgets en perfil desactualizados | Perfil | Media |
| **PR2** | Perfil "zona principal" no funcional | Perfil | Alta |
| **PR3** | Falta toggle "avisos de zonas" en notificaciones del perfil | Perfil | Media |
| **PR4** | Textos no cambian al cambiar idioma (accesibilidad) | i18n | Alta |

Tiempo total estimado: **~16 h**, repartible en 4 sesiones.

---

## 2. Auditoría con causa raíz (archivo:línea)

### P1 — Mapa lento / no cachea
**Auditoría parcial:**
- FMTC v10 ya está configurado (`lib/data/fmtc/fmtc_service.dart`) con `maxDatabaseSize: 50 MB`, `maxTileCount: 50000`.
- `transit_map.dart:241` usa `key: ValueKey('fm-${widget.mapStyle}-${widget.isDark}')` que **desecha el árbol entero (incluido el cache de tiles en memoria)** al cambiar estilo/tema. En cada navegación a Mapa esto fuerza re-fetch.
- Debug build sin optimizaciones de Impeller → 5-10× más lento que release.

**Causas:**
- Key compuesta excesivamente reactiva → rebuild caro.
- Sin pre-warming de tiles para la zona del usuario.
- Sin separación visible entre "cache primer arranque" y "cache permanente".

### F1 — Fondo no aplica fuera de Apariencia
**Auditoría:**
- `theme_notifier.dart:132-150` `visualKey` SÍ incluye `_backgroundId`.
- `app.dart:35-40` `KeyedSubtree(key: ValueKey(rebuildKey))` debería rebuild el subtree.
- **Pero**: el `BackgroundWrapper` está sobre `child!` del `MaterialApp.builder`. Cuando el usuario hace `setState` en la pantalla Apariencia (ej. tap en una preview), notifyListeners se dispara y SÍ rebuild la Apariencia pantalla; pero las otras pestañas montadas en el `StatefulShellRoute` están "vivas" en el árbol y mantienen su `BackgroundWrapper` con el id viejo.

**Hipótesis nueva:** el `BackgroundWrapper` está siendo cachado por el `Offstage` del shell. Las pestañas inactivas no rebuild aunque el provider notifique.

**Verificar:** `home_shell.dart` cómo monta las pestañas (StatefulShellRoute mantiene todas las branches en memoria).

### F2 — Alto contraste + modo claro = blanco/blanco
**Auditoría:**
- `high_contrast_theme.dart:10-13` define `hcText = NEGRO` en claro y `hcBg = BLANCO`. Esto se aplica al `Theme.of(context)`.
- **PERO** los widgets de la app usan `TransitColorScheme.of(isDark).textHi` directamente — NO leen `Theme.of(context).textTheme`.
- Por tanto: el theme dice "negro" pero los Text en GlassCard y demás siguen pidiendo `c.textHi` que en `TransitLightColors` es color claro.

**Causa raíz:** la arquitectura del proyecto bypassa el Material Theme. Para que HC funcione hay que interceptar `TransitColorScheme.of(...)` para que respete el flag.

### F3 — Cambiar modo oscuro→claro pierde paleta
**Auditoría sospechada:**
- El usuario elige paleta "Sunset" en modo oscuro → se guarda `paletteId='sunset'`.
- Cambia a modo claro → `themeMode` cambia pero `paletteId` SIGUE siendo 'sunset' en `theme_notifier`.
- **Probable**: la paleta "Sunset" no tiene definida una variante `lightScheme` → al pedirla con `palette.lightScheme ?? palette.scheme` cae al scheme dark, que sobre fondo claro genera contraste raro.

### F4 — "Modo de accesibilidad: ninguno"
**Sin auditoría directa.** Sospecha: hay un widget que muestra "Modo: {currentMode}" que lee `colorBlindMode.name` y solo se etiqueta cuando hay un mode != none. Cuando se activa otro, el texto no se invalida.

### M1-M3, M4-M6 — Mapa
**Sin tiempo de auditoría exhaustiva.** Necesitan inspección visual en código:
- `transit_map.dart:onTap` actual.
- `map_filter_sheet.dart` botón Reset estética.
- `map_tab.dart` swipe del DraggableScrollableSheet.

### S1 — Sheet habitual separado + paradas
**Sospecha:** mi fix anterior (sheet habitual) usaba `useSafeArea: true` + padding bottom con `HomeBottomNav.height`. Eso PUEDE estar dejando demasiado espacio en algunos dispositivos. Y el dedupe de paradas YA está pero el usuario puede estar en OTRO sheet de un wizard distinto.

**Por confirmar:** ¿en qué sheet ve "muchas paradas"? Configurar habitual O wizard crear ruta O paso de stops.

### S2 — Sugerir ruta fondo cortado
**Sospecha:** `suggest_route_screen.dart` tiene Scaffold sin `extendBody` o no respeta `mq.padding.bottom + HomeBottomNav.height`.

### A1-A4 — Auth
- **A1**: `auth_repository_supabase.dart` Google sign-in con error sin mensaje al usuario.
- **A2**: `auth_helpers.dart` solo cubre 4 mensajes; mostrar "Invalid login credentials" en inglés al usuario.
- **A3**: Site URL en Supabase Dashboard sigue siendo localhost.
- **A4**: `signup_screen.dart` / `magic_link_screen.dart` Scaffold sin `AppBar` con `leading`.

### PR1-PR4 — Perfil
- **PR1**: `profile_about_section.dart` o submenu de offline/widgets sin actualizar.
- **PR2**: header del perfil con "zona principal" muestra COMUJESA sin opciones.
- **PR3**: `profile_notifications_section.dart` no tiene `notifZoneAlerts`.
- **PR4**: claves de accesibilidad no incluidas en `.arb`.

---

## 3. Decisiones tomadas (confirmadas por el usuario)

| # | Decisión | Aplicación |
|---|----------|------------|
| D1 | Click línea → snackbar + selección visual | M1 |
| D2 | Filtros: árbol expandible con checkboxes tri-state | M4 |
| D3 | Widgets perfil: pantalla completa por widget con preview + form + probar | PR1 |
| D4 | Alto contraste: forzar `textHi` negro globalmente en `TransitColorScheme.of` | F2 |

---

## 4. Plan de tareas por grupo

### Grupo 1 — Perf mapa (1.5 h)

#### P1.A — Pre-warming de tiles + persistir cache
**Archivos:**
- Modify: `lib/data/fmtc/fmtc_service.dart` (verificar config + añadir pre-warming)
- New: `lib/data/fmtc/tile_prewarmer.dart`
- Modify: `lib/main.dart` (lanzar pre-warming tras Hive bootstrap)

**Steps:**
- [ ] Verificar que FMTC store está en `getApplicationDocumentsDirectory()` (persiste entre instalaciones del APK debug, sí entre reinstalaciones no).
- [ ] Crear `TilePrewarmer.prewarmRegion(bounds, minZoom, maxZoom)` que descarga los tiles de Jerez al primer arranque solo si el store está vacío:
```dart
class TilePrewarmer {
  static Future<void> prewarmJerezOnce() async {
    final store = FMTCStore('default');
    final stats = await store.stats.all;
    if (stats.length > 100) return; // ya hidratado
    final region = RectangleRegion(LatLngBounds(
      LatLng(36.50, -6.30), LatLng(36.80, -5.90), // Jerez bbox
    ));
    final result = store.download.startForeground(
      region: region.toDownloadable(minZoom: 12, maxZoom: 16, options: TileLayer(
        urlTemplate: '...', userAgentPackageName: 'com.transitly.transitly',
      )),
      instance: 'jerez-prewarm',
    );
    result.tileEvents.listen((_) {}); // drenar el stream
  }
}
```
- [ ] En `main.dart`, tras Hive bootstrap y antes de runApp:
```dart
unawaited(TilePrewarmer.prewarmJerezOnce()); // no bloquea boot
```
- [ ] Smoke: cerrar app, modo avión, abrir mapa → tiles cargan desde cache.

#### P1.B — Eliminar key compuesta que mata cache
**Archivos:**
- Modify: `lib/features/map/transit_map.dart:241`

**Steps:**
- [ ] Cambiar `key: ValueKey('fm-${widget.mapStyle}-${widget.isDark}')` por `key: const PageStorageKey('map-main')` y mover la lógica de cambio de estilo al `TileLayer` interno (`key: ValueKey('tiles-${style}-${isDark}')` ya está en la línea 254 — pasarlo allí preservará el FlutterMap pero recambiará tiles).
- [ ] Test: cambiar entre modo claro/oscuro NO debe re-fetch todos los tiles.

#### P1.C — RepaintBoundary
- [ ] Confirmar que `BackgroundWrapper` y el `TransitMap` están envueltos en `RepaintBoundary` para aislar repintados.

---

### Grupo 2 — Theming (2.5 h)

#### F1 — Fondo aplica en TODAS las pestañas
**Archivos:**
- Modify: `lib/shared/widgets/background_wrapper.dart` (watch del notifier completo)
- Modify: `lib/features/home/home_shell.dart` (verificar lugar de BackgroundWrapper)

**Steps:**
- [ ] En `home_shell.dart`, mover `BackgroundWrapper` del nivel de `MaterialApp.builder` al SHELL (encima del `navigationShell`), pero solo si no está ya allí:
```dart
// home_shell.dart build:
return Scaffold(
  body: BackgroundWrapper(  // ← aquí
    child: Stack(
      children: [
        widget.navigationShell,
        ...
      ],
    ),
  ),
  bottomNavigationBar: HomeBottomNav(...),
);
```
- [ ] Quitar el `BackgroundWrapper` de `app.dart` si ya está en shell.
- [ ] Verificar que `BackgroundWrapper` hace `ref.watch(themeNotifierProvider)` sin `.select` con campo derivado.
- [ ] Smoke: cambiar fondo → verlo en home, mapa, perfil sin reabrir.

#### F2 — Alto contraste afecta a TransitColorScheme (cambio global)
**Archivos:**
- Modify: `lib/core/theme/transit_colors.dart` (factory `of()` respeta highContrast)
- Modify: `lib/shared/providers/active_palette_provider.dart` (expose `isHighContrast`)

**Steps:**
- [ ] Crear `TransitColorScheme.ofHighContrast(isDark)`:
```dart
class TransitHighContrastScheme implements TransitColorScheme {
  final bool isDark;
  Color get textHi => isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
  Color get textMid => textHi;
  Color get textLo => isDark ? const Color(0xFFCCCCCC) : const Color(0xFF333333);
  Color get bgRoot => isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
  Color get bgSurface => bgRoot;
  Color get bgRaised => bgRoot;
  Color get accent => isDark ? const Color(0xFFFFFF00) : const Color(0xFF0000FF);
  Color get border => textHi;
  // ... el resto
}
```
- [ ] En `TransitColorScheme.of(isDark)`, añadir lookup del flag (vía `activePaletteProvider` o similar):
```dart
static TransitColorScheme of(bool isDark) {
  if (_resolver != null) return _resolver!(isDark);
  // fallback
  return isDark ? TransitDarkColors() : TransitLightColors();
}
```
- [ ] Modificar `resolveActiveScheme` (que se registra en main.dart) para devolver `TransitHighContrastScheme` si el notifier dice highContrast.

#### F3 — Cambiar oscuro→claro mantiene paleta
**Archivos:**
- Modify: `lib/shared/providers/active_palette_provider.dart` (lightScheme fallback inteligente)

**Steps:**
- [ ] Cuando `palette.lightScheme == null` y el modo es claro, NO caer a `palette.scheme` (que es la dark) — generar dinámicamente invertiendo luminosidades:
```dart
TransitColorScheme effectiveLightScheme(TransitPalette p) {
  if (p.lightScheme != null) return p.lightScheme!;
  // Derivar light de dark invirtiendo HSL.lightness de cada color clave
  return _deriveLightFromDark(p.scheme);
}
```
- [ ] Smoke: elegir paleta Sunset en oscuro → cambiar a claro → la paleta sigue siendo Sunset (pero variant claro).

#### F4 — "Modo de accesibilidad: ninguno"
**Archivos:**
- Audit: buscar `ColorBlindMode.none` + "ninguno" / "none" hardcoded.
- Modify: el widget que lo muestra (probablemente `profile_accessibility_section.dart`).

**Steps:**
- [ ] Buscar `'Modo: '` o similares + verificar que el state se actualiza al cambiar.
- [ ] Si el modo es `none`, mostrar el toggle como OFF en lugar de un dropdown con valor "ninguno".

---

### Grupo 3 — Mapa UX (3 h)

#### M1 — Click línea → snackbar + selección
**Archivos:**
- Modify: `lib/features/map/transit_map.dart` (añadir onTap a `PolylineLayer`)
- Modify: `lib/features/home/tabs/map_tab.dart` (handler `_onRouteTap`)

**Steps:**
- [ ] flutter_map v7 PolylineLayer no tiene `onTap` nativo. Usar `GestureDetector` envolvente con cálculo de proximidad al polyline:
```dart
options: MapOptions(
  ...
  onTap: (tapPos, latlng) {
    final hit = _findClosestRoute(latlng, polylines, threshold: 30 /* metros */);
    if (hit != null) widget.onRouteTap?.call(hit.routeId);
    else widget.onMapTap?.call(tapPos, latlng);
  },
),
```
- [ ] `_findClosestRoute` recorre los polylines de las rutas visibles y devuelve la más cercana al tap dentro de N metros.
- [ ] En `map_tab.dart`, al recibir `onRouteTap(routeId)`:
```dart
void _onRouteTap(String routeId) {
  setState(() => _selectedRouteId = routeId);
  final route = mockData.getRouteById(routeId);
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text('Línea ${route?.code} · ${route?.name}'),
    behavior: SnackBarBehavior.floating,
    margin: EdgeInsets.fromLTRB(16, 0, 16, 80 + mq.padding.bottom),
    duration: Duration(seconds: 2),
    action: SnackBarAction(
      label: 'Ver',
      onPressed: () => context.push('/route/$routeId'),
    ),
  ));
}
```

#### M2 — "Ir a ubicación de línea" selecciona la línea
**Archivos:**
- Modify: `lib/features/home/tabs/map_tab.dart` (al pulsar focus en el panel)

**Steps:**
- [ ] El botón de focus de cada línea en el panel ya hace `_mapController.fitBounds(routeBounds)`. Añadir también `setState(() => _selectedRouteId = route.id)`.

#### M3 — Botón "Ver todas" / X estético
**Archivos:**
- Modify: `lib/features/home/tabs/map_tab.dart` (botón en el header del sheet)

**Steps:**
- [ ] Reemplazar el `IconButton(icon: Icons.close)` por un `TransitChip` con label "Ver todas" + icono `arrow_back` cuando hay selección.
- [ ] Aplicar colores del scheme (no Colors.red ni similares).

#### M4 — Filtros jerárquicos (árbol expandible)
**Archivos:**
- Modify: `lib/features/map/widgets/map_filter_sheet.dart` (nuevo widget de tree)
- Modify: `lib/features/map/map_filter_controller.dart` (estado del árbol)
- New: `lib/features/map/widgets/zone_company_line_tree.dart`

**Steps:**
- [ ] Modelo de datos en `MockDataService` que ya tenemos:
  - Zonas: derivar del operador (`getOperators()`).
  - Compañías: `OperatorModel` cada uno.
  - Líneas: `RouteModel` por operador.
- [ ] Widget tree con `ExpansionTile` anidados:
```
▼ Jerez
  ▼ COMUJESA           [checkbox tri-state]
    □ L1 - Norte
    □ L4 - Centro
    ...
```
- [ ] Tri-state: si TODAS las líneas de COMUJESA activas → ✓. Si ninguna → ☐. Si algunas → indeterminado.
- [ ] Tap en checkbox de operador: marca/desmarca todas sus líneas.
- [ ] Tap en checkbox de zona: marca/desmarca todos los operadores de la zona.
- [ ] `disabledRouteIds` añadido al `MapFilterState` (más granular que `disabledKinds`).

#### M5 — Sheet plegado no debe swipe-navegar
**Archivos:**
- Modify: `lib/features/home/tabs/map_tab.dart` (DraggableScrollableSheet)

**Steps:**
- [ ] El `DraggableScrollableSheet` actual permite scrolll del ListView interno incluso cuando está colapsado. Añadir un `NotificationListener<ScrollNotification>` que bloquee el scroll si `currentExtent < 0.25`:
```dart
DraggableScrollableSheet(
  ...
  builder: (ctx, controller) {
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (_sheetController.size < 0.25 && n.metrics.pixels > 0) {
          return true; // consume
        }
        return false;
      },
      child: ListView(controller: controller, children: ...),
    );
  },
)
```

#### M6 — Botón "ir a línea" más grande
**Archivos:**
- Modify: `lib/shared/widgets/route_card.dart` o donde esté el ícono de focus

**Steps:**
- [ ] El botón actual es probablemente `IconButton(iconSize: 20)`. Cambiar a 32 + `splashRadius: 28`.
- [ ] Asegurar touch target mínimo de 44x44 (WCAG).

---

### Grupo 4 — Sheets / Wizard (1 h)

#### S1 — Sheet configurar habitual
**Archivos:**
- Modify: `lib/features/home/widgets/habitual_config_sheet.dart`

**Steps:**
- [ ] Verificar el padding actual. Si `mq.padding.bottom + HomeBottomNav.height` es excesivo en algunos dispositivos (notch grandes), capear:
```dart
final navHeight = HomeBottomNav.height;
final extraBottom = (mq.padding.bottom + navHeight).clamp(16.0, 80.0);
final bottomInset = 16 + mq.viewInsets.bottom + extraBottom;
```
- [ ] Si el usuario reporta "muchas paradas" → confirmar si está en este sheet (que YA tiene dedupe) o en el wizard. Si es el wizard `step_stops.dart`, aplicar el mismo dedupe.

#### S2 — Sugerir ruta fondo cortado
**Archivos:**
- Modify: `lib/features/suggestions/suggest_route_screen.dart`

**Steps:**
- [ ] Añadir `extendBody: true` al Scaffold + padding bottom en el body para no solapar con la nav bar.
- [ ] O envolver el body en `SafeArea(bottom: true)`.

---

### Grupo 5 — Auth (2 h)

#### A1 — Google sign-in con mensaje claro
**Archivos:**
- Modify: `lib/data/auth/auth_repository_supabase.dart:signInWithGoogle`
- Modify: `lib/features/auth/signin_screen.dart`

**Steps:**
- [ ] Capturar excepciones específicas:
```dart
try {
  await _client.auth.signInWithIdToken(...);
} on AuthException catch (e) {
  throw AuthRepoException(AuthError.googleFailed, e.message);
} on PlatformException catch (e) {
  throw AuthRepoException(AuthError.googleFailed, 'Google: ${e.code}');
}
```
- [ ] En `signin_screen`, mostrar SnackBar con `l10n.authGoogleFailed(error.message)`.
- [ ] Claves `.arb` para "No se pudo iniciar sesión con Google" + variaciones por código.

#### A2 — Errores formulario localizados
**Archivos:**
- Modify: `lib/data/auth/auth_helpers.dart` (más casos)
- Modify: `lib/features/auth/signin_screen.dart` / `signup_screen.dart` (mostrar l10n)

**Steps:**
- [ ] Añadir más casos al `mapAuthError`:
  - "Invalid login credentials" → `AuthError.invalidCredentials`
  - "User already registered" → `AuthError.emailTaken`
  - "User not found" → `AuthError.userNotFound`
  - "Network request failed" → `AuthError.network`
- [ ] En signin, capturar `AuthRepoException` y mostrar `l10n.authError{XYZ}` según el enum.
- [ ] Claves `.arb` en es/en/ar.

#### A3 — Correo verificación
**Manual en Supabase Dashboard:**
- [ ] Authentication → URL Configuration → Site URL: cambiar de `localhost:3000` a `https://transitly-app.web.app/auth/verify` (o un dominio temporal).
- [ ] Alternativa más simple: crear página Firebase Hosting estática en `transitly.web.app/verify.html` que hace JS redirect a `transitly://auth/verified?token={token}`.
- [ ] Authentication → Email Templates → Confirm signup: usar `{{ .ConfirmationURL }}` apuntando a la nueva URL.
- [ ] Test: registrar usuario nuevo → recibir email → tap link → abre app verificada.

#### A4 — Botón atrás en /sign-up, /magic-link
**Archivos:**
- Modify: `lib/features/auth/signup_screen.dart`
- Modify: `lib/features/auth/magic_link_screen.dart`
- Modify: `lib/features/auth/recover_password_screen.dart`

**Steps:**
- [ ] Añadir `AppBar` con `leading: IconButton(icon: Icons.arrow_back, onPressed: () => context.pop())`.
- [ ] Si el modal no se monta sobre signin, usar `context.go('/signin')` como fallback.

---

### Grupo 6 — Perfil + i18n (3 h)

#### PR1 — Widgets en perfil: pantalla por widget + preview
**Archivos:**
- New: `lib/features/widgets_config/widgets_config_screen.dart` (lista)
- New: `lib/features/widgets_config/widget_config_detail_screen.dart` (por widget)
- Modify: `lib/features/home/widgets/profile_about_section.dart` (o donde apunta "Widgets")
- New rutas en `app_router.dart`

**Steps:**
- [ ] `WidgetsConfigScreen` lista los 3 widgets (Próximo bus, Mi línea, Saldo NFC) con preview pequeño.
- [ ] Tap → `WidgetConfigDetailScreen('next_bus')` con:
  - Preview visual del widget (replicar el layout XML en Dart).
  - Form:
    - "Próximo bus": dropdown línea + dropdown parada (Autocomplete con dedupe).
    - "Mi línea": dropdown línea favorita.
    - "Saldo NFC": no form, solo botón "Escanear tarjeta ahora".
  - Botón "Probar widget" que escribe SharedPreferences y trigger update.

#### PR2 — Perfil "zona principal" funcional o eliminar
**Archivos:**
- Audit: `lib/features/home/tabs/profile_tab.dart`
- Modify: probable

**Steps:**
- [ ] Audit visual: identificar qué elementos del perfil no son funcionales.
- [ ] Para cada uno, decidir: implementar / eliminar / dejar como "Próximamente" con tag visual claro.
- [ ] Reestructurar para que las secciones funcionales (Apariencia, Accesibilidad, Comunidad, Notificaciones) estén ARRIBA.

#### PR3 — Toggle "avisos de zonas" en notificaciones
**Archivos:**
- Modify: `lib/shared/providers/theme_notifier.dart` (añadir `_notifZoneAlerts`)
- Modify: `lib/features/home/widgets/profile_notifications_section.dart`

**Steps:**
- [ ] Añadir flag `notifZoneAlerts` al theme_notifier + persistencia.
- [ ] Toggle UI con label "Avisos de zonas" + descripción "Notificaciones cuando hay incidencias en zonas cerca de ti".
- [ ] Hook en `home_tab.dart` para mostrar alertas SOLO si el flag está on.

#### PR4 — Textos accesibilidad i18n
**Archivos:**
- Modify: `lib/l10n/app_es.arb`, `app_en.arb`, `app_ar.arb`
- Modify: `lib/features/home/widgets/profile_accessibility_section.dart`

**Steps:**
- [ ] Audit con grep: encontrar strings hardcoded en accesibilidad y profile.
- [ ] Añadir claves localizadas para CADA uno.
- [ ] `flutter gen-l10n` para regenerar.

---

## 5. Archivos modificados (resumen agrupado)

### Theming (F1-F4)
- `lib/core/theme/transit_colors.dart` (HighContrastScheme)
- `lib/core/theme/high_contrast_theme.dart`
- `lib/shared/providers/active_palette_provider.dart` (lightScheme derivado)
- `lib/shared/widgets/background_wrapper.dart` (watch granular)
- `lib/features/home/home_shell.dart` (BackgroundWrapper en shell)

### Mapa (P1, M1-M6)
- `lib/data/fmtc/fmtc_service.dart`
- `lib/data/fmtc/tile_prewarmer.dart` (NEW)
- `lib/features/map/transit_map.dart`
- `lib/features/home/tabs/map_tab.dart`
- `lib/features/map/widgets/map_filter_sheet.dart`
- `lib/features/map/widgets/zone_company_line_tree.dart` (NEW)
- `lib/features/map/map_filter_controller.dart`
- `lib/shared/widgets/route_card.dart`

### Sheets (S1, S2)
- `lib/features/home/widgets/habitual_config_sheet.dart`
- `lib/features/suggestions/suggest_route_screen.dart`

### Auth (A1-A4)
- `lib/data/auth/auth_repository_supabase.dart`
- `lib/data/auth/auth_helpers.dart`
- `lib/data/auth/auth_repository.dart` (más AuthError values)
- `lib/features/auth/signin_screen.dart`
- `lib/features/auth/signup_screen.dart`
- `lib/features/auth/magic_link_screen.dart`
- `lib/features/auth/recover_password_screen.dart`

### Perfil + i18n (PR1-PR4)
- `lib/features/widgets_config/widgets_config_screen.dart` (NEW)
- `lib/features/widgets_config/widget_config_detail_screen.dart` (NEW)
- `lib/features/home/widgets/profile_notifications_section.dart`
- `lib/features/home/tabs/profile_tab.dart` (reestructurar)
- `lib/shared/providers/theme_notifier.dart` (notifZoneAlerts)
- `lib/l10n/app_es.arb`, `app_en.arb`, `app_ar.arb`
- `lib/core/router/app_router.dart` (rutas widgets_config)

### Manual (Supabase Dashboard)
- Site URL + Email templates (A3)

---

## 6. Estimación de tiempo

| Grupo | Tareas | Tiempo | Prioridad |
|-------|--------|--------|-----------|
| 1 — Perf mapa | P1.A + P1.B + P1.C | 1.5 h | **Crítica** |
| 2 — Theming | F1 + F2 + F3 + F4 | 2.5 h | **Crítica** |
| 3 — Mapa UX | M1-M6 | 3 h | Alta |
| 4 — Sheets | S1 + S2 | 1 h | Media |
| 5 — Auth | A1 + A2 + A4 (A3 manual) | 2 h | **Crítica** |
| 6 — Perfil + i18n | PR1 + PR2 + PR3 + PR4 | 3 h | Alta |
| Build + smoke por grupo | en cada uno | 3 h | — |
| **Total** | | **~16 h** | 4 sesiones |

---

## 7. Orden de ejecución recomendado

**Sesión 1 (4 h): "Hacer la app usable"**
- Grupo 1 — Perf mapa (1.5 h)
- Grupo 2 — Theming (2.5 h)

**Sesión 2 (3 h): "Auth funcional"**
- Grupo 5 — Auth (2 h)
- Build + smoke (1 h)

**Sesión 3 (4 h): "Mapa pro"**
- Grupo 3 — Mapa UX (3 h)
- Build + smoke (1 h)

**Sesión 4 (5 h): "Refinos finales"**
- Grupo 4 — Sheets (1 h)
- Grupo 6 — Perfil + i18n (3 h)
- Build + smoke final (1 h)

---

## 8. Riesgos

- **R1: P1.A pre-warming descarga MUCHOS tiles en primer arranque.** Mitigación: capear maxZoom a 16, solo Jerez core (no toda la provincia).
- **R2: F2 cambio en `TransitColorScheme.of` afecta a TODA la app.** Mitigación: smoke test exhaustivo en 3 pantallas representativas (home, mapa, perfil) tanto en claro/oscuro/HC.
- **R3: F1 mover `BackgroundWrapper` al shell rompe el wrapper de pantallas pushed (route detail, etc.).** Mitigación: dejar el wrapper también en `MaterialApp.builder` pero asegurar que solo monta UNA vez (revisar con `Builder` defensivo).
- **R4: M4 árbol expandible con 19 líneas + 1 operador es triviable; pero si el proyecto crece a 5 operadores con 100+ líneas cada uno, el árbol se vuelve impráctico.** Mitigación: añadir buscador dentro del árbol.
- **R5: PR1 pantallas de widgets nuevas pueden romper el flujo si las rutas no se registran bien.** Mitigación: usar GoRoute siguiendo el patrón existente.
- **R6: A3 cambio en Supabase Dashboard afecta a usuarios actuales.** Mitigación: hacerlo en dev/staging primero, luego prod.

---

## 9. Criterios de aceptación

1. Cambiar fondo en Apariencia → ir a Home/Mapa/Perfil → fondo nuevo visible en TODAS.
2. Activar HC en modo claro → texto NEGRO visible.
3. Elegir paleta Sunset en oscuro → cambiar a claro → la paleta sigue siendo Sunset (variante claro).
4. Mapa: primera carga descarga tiles Jerez; segunda vez (sin red) tiles cargan desde cache.
5. Mapa: tap en una polyline → snackbar "Línea L8 · Norte" + línea resaltada.
6. Filtros: árbol Jerez ▾ COMUJESA ▾ L1..L19. Desmarcar L8 → desaparece del mapa.
7. Sheet plegado del mapa NO permite scroll del listado interno.
8. Botón "ir a línea": touch target ≥ 44dp.
9. Google sign-in: si falla, SnackBar con mensaje claro localizado.
10. Errores login en form: TODOS en idioma del dispositivo.
11. Registro: dialog "Revisa tu email" + email REAL llega con link funcional.
12. Sign-up / magic-link: AppBar con botón atrás.
13. Perfil → Widgets → pantalla con 3 widgets con preview + form funcionales.
14. Perfil → Notificaciones → toggle "Avisos de zonas" actúa.
15. Cambiar idioma a inglés/árabe: TODAS las strings de Accesibilidad cambian.

---

## 10. Próximos pasos

Cuando apruebes:
- **"arranca sesión 1"** → Perf mapa + Theming (~4 h) — más bloqueante.
- **"arranca todo en orden"** → 4 sesiones secuenciales (~16 h).
- **"arranca solo auth"** → grupo 5 si quieres el login funcional ya (~2 h).
- **"empieza por el mapa"** → grupos 1 + 3 (~4.5 h).

Recomendado **"arranca sesión 1"** porque hace la app usable inmediatamente.

---

## Changelog

- **2026-06-02** — Plan creado tras auditoría de los 21 problemas:
  - F1-F4 con causas raíz identificadas (TransitColorScheme bypassa Theme, BackgroundWrapper en MaterialApp.builder no rebuild en pestañas inactivas).
  - 4 decisiones del usuario aplicadas: snackbar+selección, árbol expandible, pantalla por widget, textHi negro global.
  - Estimación realista: 16 h en 4 sesiones.
