# Plan de acción — 8 items para cerrar el plan 21-bugs + 3 mejoras

**Fecha:** 2026-06-03
**Autor:** Claude Code (Opus 4.7)
**Estado:** propuesto
**Continuación de:** `PLAN_21_BUGS_MAPA_PERFIL_2026_06_02.md` (16/21 items completados en 4 commits; auditoría en revisión previa)
**Goal:** Cerrar los 5 items pendientes del plan anterior + 3 bugs derivados detectados en auditoría. Resultado: app fluida, filtros jerárquicos, widgets configurables desde perfil, alto contraste con override.
**Arquitectura:** Cambios incrementales aislados — cada tarea modifica un dominio distinto, paralelizable si se reparte.
**Stack:** Flutter 3.9.2 + Riverpod + flutter_map 7 + FMTC v10 + Hive.

---

## 1. Items del plan

| ID | Item | Tipo | Tiempo | Severidad |
|----|------|------|--------|-----------|
| **A** | P1.A — Tile pre-warming Jerez en primer arranque | Pendiente | 1 h | Alta (perf) |
| **B** | P1.C — RepaintBoundary auditado | Pendiente | 30 min | Media (perf) |
| **C** | M4 — Filtros jerárquicos árbol expandible | Pendiente | 2 h | Alta (UX) |
| **D** | PR1 — Pantallas config widgets con preview | Pendiente | 2.5 h | Alta (feature) |
| **E** | F1.bis — Fondo configurable en rama landscape/tablet/rail | Bug del fix anterior | 20 min | Alta |
| **F** | M1.bis — Umbral dinámico de click en línea según zoom | Mejora | 15 min | Baja |
| **G** | HC.bis — Toggle "respetar accent de paleta" en alto contraste | Mejora | 30 min | Media |
| **H** | A3 — Documentar setup manual de Supabase Dashboard | Manual | 15 min | Baja |

Total: **~7 h** en una sesión larga o dos cortas.

---

## 2. Tareas detalladas

### Tarea A — Tile pre-warming de Jerez (1 h)

**Goal:** que la primera vez que el usuario abre el mapa, los tiles del centro de Jerez ya estén descargados. En segundas aperturas sin red, debe funcionar offline.

**Archivos:**
- New: `lib/data/fmtc/tile_prewarmer.dart`
- Modify: `lib/main.dart` (lanzar pre-warming tras Hive bootstrap)

**Steps:**

- [ ] **Paso 1**: Crear `TilePrewarmer` con API simple e idempotente:
```dart
import 'dart:async';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart';

import '../../core/env.dart';
import '../../core/utils/app_logger.dart';
import '../../features/map/map_config.dart';

class TilePrewarmer {
  static const _logTag = 'TilePrewarmer';
  static const _jerezBbox = LatLngBounds(
    LatLng(36.6500, -6.1700), // SW
    LatLng(36.7100, -6.0700), // NE
  );
  static const _minZoom = 13;
  static const _maxZoom = 15;
  static const _minTilesToConsiderWarm = 50;

  /// Idempotente: si el store ya tiene > N tiles, no hace nada.
  /// Lanzar con `unawaited(...)` desde main para no bloquear boot.
  static Future<void> prewarmJerezOnce({String style = 'streets'}) async {
    try {
      final store = FMTCStore('default');
      final stats = await store.stats.toMap();
      final tileCount = stats['tilesAvailable'] as int? ?? 0;
      if (tileCount >= _minTilesToConsiderWarm) {
        AppLogger.info(_logTag, 'skip: store has $tileCount tiles');
        return;
      }
      AppLogger.info(_logTag, 'starting prewarm jerez ($_minZoom-$_maxZoom)');
      final region = RectangleRegion(_jerezBbox);
      final result = store.download.startForeground(
        region: region.toDownloadable(
          minZoom: _minZoom,
          maxZoom: _maxZoom,
          options: TileLayer(
            urlTemplate: MapConfig.tileUrl(style, apiKey: Env.mapTilerApiKey),
            userAgentPackageName: 'com.transitly.transitly',
          ),
        ),
        instance: 'jerez-prewarm',
      );
      var done = 0;
      result.tileEvents.listen(
        (_) => done++,
        onDone: () => AppLogger.info(_logTag, 'prewarm complete: $done tiles'),
        onError: (e) => AppLogger.warn(_logTag, 'prewarm error', e),
      );
    } catch (e, st) {
      AppLogger.warn(_logTag, 'prewarm failed silently', e, st);
    }
  }
}
```

- [ ] **Paso 2**: En `main.dart`, **después** de Hive bootstrap y **antes** de `runApp`:
```dart
unawaited(TilePrewarmer.prewarmJerezOnce());
```
NO usar await — el pre-warming corre en background y no debe bloquear boot.

- [ ] **Paso 3**: Verificar con `flutter pub deps | grep flutter_map_tile_caching` que la API actual de FMTC coincide. Si la versión 10.x cambió `RectangleRegion.toDownloadable` → ajustar.

- [ ] **Paso 4**: Smoke test:
  1. `adb shell pm clear com.transitly.transitly` (limpia store).
  2. Abrir app con wifi.
  3. Esperar 30s.
  4. Modo avión.
  5. Abrir mapa → tiles de Jerez visibles.

**Criterio de aceptación**: tras primer arranque con red, el mapa carga sin red en la siguiente apertura.

---

### Tarea B — RepaintBoundary auditado (30 min)

**Goal:** aislar repintados costosos (mapa, background shader) del resto del árbol para reducir jank.

**Archivos:**
- Modify: `lib/shared/widgets/background_wrapper.dart` (verificar/añadir RepaintBoundary)
- Modify: `lib/features/map/transit_map.dart` (envoltorio del FlutterMap)
- Modify: `lib/features/home/home_shell.dart` (separar nav bar del body)

**Steps:**

- [ ] **Paso 1**: En `background_wrapper.dart`, envolver el `BackgroundWrapper` interno en `RepaintBoundary`:
```dart
return RepaintBoundary(
  child: Stack(
    children: [
      _buildBackground(...),
      child, // contenido de la pantalla
    ],
  ),
);
```
Esto evita que el background se repinte cuando solo cambia un widget interno del child.

- [ ] **Paso 2**: En `transit_map.dart` (línea ~235), verificar que el `FlutterMap` ya está dentro de `RepaintBoundary`. Si no:
```dart
return RepaintBoundary(child: FlutterMap(...));
```

- [ ] **Paso 3**: En `home_shell.dart`, separar el `bottomNavigationBar` con su propio `RepaintBoundary`:
```dart
bottomNavigationBar: RepaintBoundary(
  child: HomeBottomNav(...),
),
```
El nav bar tiene la pill animada — sin boundary, cada frame de animación dispara repintado del body.

- [ ] **Paso 4**: Smoke test con DevTools Performance:
  1. `flutter run --profile`.
  2. Abrir DevTools → Performance tab.
  3. Navegar entre pestañas + animar.
  4. Verificar que los "repaint rainbow" están aislados al área que cambia.

**Criterio**: menos frames "skipped" durante navegación normal (medible).

---

### Tarea C — Filtros jerárquicos árbol expandible (2 h)

**Goal:** sustituir los chips planos de zonas por un árbol Zona → Compañías → Líneas con checkboxes tri-state.

**Archivos:**
- New: `lib/features/map/widgets/zone_company_line_tree.dart`
- Modify: `lib/features/map/widgets/map_filter_sheet.dart` (reemplazar sección zonas)
- Modify: `lib/features/map/map_filter_controller.dart` (añadir `disabledRouteIds`)

**Steps:**

- [ ] **Paso 1**: Extender `MapFilterController` con set `disabledRouteIds`:
```dart
class MapFilterState {
  final Set<String> disabledOperators;
  final Set<String> disabledKinds;
  final Set<String> disabledZones;
  final Set<String> disabledRouteIds; // ← NUEVO
  // ... resto igual
}
```
Y métodos: `toggleRoute(routeId)`, `setRoutesEnabled(routeIds, enabled)`.

- [ ] **Paso 2**: En `_filteredRoutes` de `map_tab.dart`, añadir filtro:
```dart
if (f.disabledRouteIds.isNotEmpty) {
  filtered = filtered.where((r) => !f.disabledRouteIds.contains(r.id)).toList();
}
```

- [ ] **Paso 3**: Crear `ZoneCompanyLineTree` widget:
```dart
class ZoneCompanyLineTree extends ConsumerWidget {
  // Estructura:
  //   Zona "Jerez" (derivada del operatorId del mock)
  //   └─ COMUJESA (ExpansionTile)
  //      ├─ L1 - Norte
  //      ├─ L2 - Sur
  //      └─ ...
  //
  // Cada nivel tiene checkbox tri-state:
  //   - todos enabled → ✓ checked
  //   - todos disabled → ☐ unchecked
  //   - mixed → ⬛ indeterminate (TristateCheckbox)
  //
  // Tap en checkbox de operador: marca/desmarca todas sus rutas en `disabledRouteIds`.
  // Tap en checkbox de zona: marca/desmarca todas las rutas de todas sus compañías.
}
```

- [ ] **Paso 4**: Componentes a usar (memoria [[feedback-design-tokens]]):
  - `ExpansionTile` con `iconColor: c.accent`.
  - `Checkbox` con `tristate: true` y `activeColor: c.accent`.
  - `TransitTypography.bodyPrimary(c.textHi)` para labels.
  - Sin colores hardcoded.

- [ ] **Paso 5**: Pseudo-tri-state derivación:
```dart
bool? _zoneCheckedState(MockOperatorModel op, MapFilterState f, MockDataService data) {
  final routesOfOp = data.routes.where((r) => r.operatorId == op.id).toList();
  if (routesOfOp.isEmpty) return false;
  final disabledCount = routesOfOp.where((r) => f.disabledRouteIds.contains(r.id)).length;
  if (disabledCount == 0) return true;
  if (disabledCount == routesOfOp.length) return false;
  return null; // indeterminate
}
```

- [ ] **Paso 6**: En `map_filter_sheet.dart`, reemplazar la sección de chips por:
```dart
const SizedBox(height: 16),
GradientText('Líneas por compañía', ...),
const SizedBox(height: 8),
const ZoneCompanyLineTree(),
```

- [ ] **Paso 7**: Smoke test:
  1. Abrir filtros → ver "Jerez" expandido.
  2. Tap "COMUJESA" → marca todas sus 19 líneas como disabled.
  3. Mapa: 0 polylines visibles.
  4. Expandir COMUJESA → tap L8 individual → solo L8 visible.

**Criterio**: filtros granulares por línea individual.

---

### Tarea D — Pantallas config widgets con preview (2.5 h)

**Goal:** sustituir el "submenu inerte" de Widgets en perfil por 3 pantallas configurables con preview y botón "probar".

**Archivos:**
- New: `lib/features/widgets_config/widgets_config_screen.dart` (lista de los 3)
- New: `lib/features/widgets_config/widget_next_bus_config_screen.dart`
- New: `lib/features/widgets_config/widget_my_line_config_screen.dart`
- New: `lib/features/widgets_config/widget_nfc_balance_config_screen.dart`
- New: `lib/features/widgets_config/widgets/widget_preview_card.dart` (preview visual reusable)
- Modify: `lib/core/router/app_router.dart` (4 rutas nuevas)
- Modify: `lib/features/home/widgets/profile_about_section.dart` (o donde apunta "Widgets") — enlace a `/widgets-config`

**Steps:**

- [ ] **Paso 1**: Rutas en router:
```dart
GoRoute(path: '/widgets-config', builder: (_, __) => const WidgetsConfigScreen()),
GoRoute(path: '/widgets-config/next-bus', builder: (_, __) => const WidgetNextBusConfigScreen()),
GoRoute(path: '/widgets-config/my-line', builder: (_, __) => const WidgetMyLineConfigScreen()),
GoRoute(path: '/widgets-config/nfc-balance', builder: (_, __) => const WidgetNfcBalanceConfigScreen()),
```

- [ ] **Paso 2**: `WidgetPreviewCard` — replica visual del widget Android en Dart:
```dart
class WidgetPreviewCard extends StatelessWidget {
  final String routeCode;
  final String nextTime;
  final String stopName;
  final String summary;
  final Color accentColor;
  // Layout que imita widget_next_bus.xml: badge cuadrado + columna textos
  // Visualmente similar al render real Android, NO usa RemoteViews
}
```

- [ ] **Paso 3**: `WidgetNextBusConfigScreen`:
  ```
  ┌─ Próximo bus ──────────────────────┐
  │ Vista previa:                       │
  │ [WidgetPreviewCard con datos reales]│
  │                                     │
  │ ┌─ Configuración ──────────────┐    │
  │ │ Línea: [Autocomplete RouteModel]│
  │ │ Parada: [Dropdown unique stops] │
  │ └──────────────────────────────┘    │
  │                                     │
  │ [TransitButton: "Probar widget"]    │
  │ [TransitButton: "Guardar"]          │
  └─────────────────────────────────────┘
  ```
  - Reusar `Autocomplete` + dedupe del sheet habitual.
  - Botón "Probar" → llama `WidgetDataWriter.writeNextBus(...)` con datos del form + `HomeWidget.updateWidget(...)`.
  - Botón "Guardar" → actualiza `homeHabitualConfigProvider` + sync.

- [ ] **Paso 4**: `WidgetMyLineConfigScreen`:
  - Dropdown de líneas favoritas (de `userFavoritesProvider`).
  - Preview muestra próximas 3 salidas de esa línea.
  - "Probar" + "Guardar".

- [ ] **Paso 5**: `WidgetNfcBalanceConfigScreen`:
  - SIN form (el saldo viene del último escaneo NFC).
  - Preview muestra el último saldo del Hive.
  - Botón "Escanear tarjeta ahora" → `context.go('/home/tarjeta')`.

- [ ] **Paso 6**: `WidgetsConfigScreen` (lista):
  ```
  ┌─ Mis widgets ──────────────────────┐
  │ [Card] Próximo bus       →         │
  │ [Card] Mi línea          →         │
  │ [Card] Saldo bonobús     →         │
  └─────────────────────────────────────┘
  ```
  Cada card con icono + nombre + estado ("Configurado" / "Pendiente").

- [ ] **Paso 7**: Localización ES/EN/AR:
  - `widgetConfigTitle`, `widgetConfigPreview`, `widgetConfigTryButton`, etc.

- [ ] **Paso 8**: Smoke test:
  1. Perfil → Widgets → lista de 3.
  2. Tap "Próximo bus" → ver preview live + form.
  3. Cambiar línea → preview se actualiza.
  4. "Probar" → notif Android del widget actualizado.

**Criterio**: usuario puede configurar widgets sin salir de la app.

---

### Tarea E — Fondo configurable en rama landscape/rail (20 min)

**Goal:** el `BackgroundWrapper` actualmente solo envuelve la rama portrait. En landscape, tablet o desktop (`useRail = true`, `home_shell.dart:92-144`) solo hay `SmokeBackground` hardcoded.

**Archivos:**
- Modify: `lib/features/home/home_shell.dart:101-105`

**Steps:**

- [ ] **Paso 1**: En la rama `useRail`, reemplazar el `Positioned.fill(child: SmokeBackground(...))` por `BackgroundWrapper`:
```dart
// Antes (línea 101-105):
body: Stack(
  children: [
    Positioned.fill(
      child: SmokeBackground(color: c.accent, isDark: isDark),
    ),
    Row(children: [...]),
  ],
),

// Después:
body: BackgroundWrapper(
  child: Row(
    children: [
      HomeSideNav(...),
      Expanded(child: Stack(...)),
    ],
  ),
),
```

- [ ] **Paso 2**: Eliminar el `import` de `SmokeBackground` si ya no se usa.

- [ ] **Paso 3**: Smoke test:
  1. Rotar móvil a landscape.
  2. Ir a Apariencia → cambiar fondo a Aurora.
  3. Volver a Home → fondo Aurora visible.

**Criterio**: fondo respetado en landscape/tablet/desktop.

---

### Tarea F — Umbral dinámico click línea según zoom (15 min)

**Goal:** a zoom alto (15+) ser más estricto con el tap; a zoom bajo (12-13) más permisivo.

**Archivos:**
- Modify: `lib/features/home/tabs/map_tab.dart:180-200` (función `_findClosestRoute`)

**Steps:**

- [ ] **Paso 1**: Reemplazar la constante:
```dart
// Antes:
const thresholdDeg = 0.003;

// Después:
final z = _currentZoom;
// Escala con zoom: a z=12 ~ 0.005 deg, a z=15 ~ 0.001 deg, a z=17 ~ 0.0003
final thresholdDeg = (0.05 / (z * z)).clamp(0.0003, 0.005);
```

- [ ] **Paso 2**: Smoke test:
  1. Zoom out (city level) → tap cerca de polyline → selecciona (umbral grande).
  2. Zoom in (street level) → tap en otra calle → NO selecciona (umbral pequeño).

**Criterio**: tap preciso en zoom alto.

---

### Tarea G — HC con opción "respetar accent de paleta" (30 min)

**Goal:** `HighContrastSchemeWrapper` actualmente sustituye el accent por amarillo/azul rígido. Algunos usuarios quieren mantener el accent de su paleta (ej. Sunset = naranja) con el resto en alto contraste.

**Archivos:**
- Modify: `lib/core/theme/high_contrast_scheme.dart` (constructor opcional `preserveAccent`)
- Modify: `lib/shared/providers/theme_notifier.dart` (nueva pref `_hcPreserveAccent`)
- Modify: `lib/features/appearance/widgets/accessibility_section.dart` (toggle sub-opción cuando HC on)

**Steps:**

- [ ] **Paso 1**: En `HighContrastSchemeWrapper`, añadir param:
```dart
HighContrastSchemeWrapper(this._base, this._isDark, {bool preserveAccent = false})
  : _preserveAccent = preserveAccent;

@override Color get accent => _preserveAccent
  ? _base.accent
  : (_isDark ? const Color(0xFFFFFF00) : const Color(0xFF0000FF));
```

- [ ] **Paso 2**: `theme_notifier.dart`:
  - Añadir `bool _hcPreserveAccent = false`.
  - Persistir en Hive.
  - Setter con `notifyListeners()`.

- [ ] **Paso 3**: En `active_palette_provider.dart`:
```dart
if (notifier.highContrast) {
  scheme = HighContrastSchemeWrapper(
    scheme, isDark,
    preserveAccent: notifier.hcPreserveAccent,
  );
}
```

- [ ] **Paso 4**: En `accessibility_section.dart`, cuando `highContrast == true`, mostrar sub-toggle:
```dart
if (highContrast)
  SwitchListTile(
    title: Text(l10n.appearanceHcPreserveAccent), // 'Mantener color de paleta'
    subtitle: Text(l10n.appearanceHcPreserveAccentHint), // 'Aplica HC solo a texto y fondo'
    value: hcPreserveAccent,
    onChanged: (v) => themeNotifier.hcPreserveAccent = v,
  ),
```

- [ ] **Paso 5**: Localización ES/EN/AR.

- [ ] **Paso 6**: Smoke test:
  1. Paleta Sunset (accent naranja) + HC ON: accent = amarillo (default).
  2. Activar "preserve accent": accent = naranja Sunset.

**Criterio**: HC respeta accent del usuario si lo elige.

---

### Tarea H — Documentar setup Supabase Dashboard (15 min)

**Goal:** dejar pasos exactos para que el equipo (o futuros agentes) configuren el Site URL y email templates.

**Archivos:**
- New: `docs/SUPABASE_SETUP.md`

**Steps:**

- [ ] **Paso 1**: Crear `docs/SUPABASE_SETUP.md` con:
```markdown
# Setup Supabase Dashboard — Transitly

## 1. URL Configuration

Authentication → URL Configuration:
- Site URL: `https://transitly-app.web.app/auth/verify`
  - (Alternativa: `transitly://auth/verified` si la app es la única que abre el link)
- Redirect URLs: añadir `transitly://auth/verified`

## 2. Email Templates

Authentication → Email Templates → Confirm signup:
- Subject: "Verifica tu cuenta de Transitly"
- Body: usar `{{ .ConfirmationURL }}` que apuntará al Site URL.
- Alternativa con dominio propio: crear página estática que haga JS redirect a `transitly://auth/verified?token={token}`.

## 3. Google OAuth Provider

Authentication → Providers → Google:
- Client ID (Web): `464091574199-r4gq1pgi09t1q0k93mjlqoru1hc29v13.apps.googleusercontent.com`
- Client Secret: (en secreto)
- Authorized redirect URIs: `https://<project>.supabase.co/auth/v1/callback`

## 4. Verificación

- Crear cuenta de prueba.
- Verificar email recibido tiene link correcto (no `localhost`).
- Tap en el link en móvil → app abre verificada.
```

- [ ] **Paso 2**: Añadir referencia desde `README.md` o `docs/historico/INDEX.md`.

**Criterio**: cualquier futuro contributor sabe configurar Supabase para auth funcional.

---

## 3. Resumen de archivos modificados

### Nuevos (7)
- `lib/data/fmtc/tile_prewarmer.dart`
- `lib/features/map/widgets/zone_company_line_tree.dart`
- `lib/features/widgets_config/widgets_config_screen.dart`
- `lib/features/widgets_config/widget_next_bus_config_screen.dart`
- `lib/features/widgets_config/widget_my_line_config_screen.dart`
- `lib/features/widgets_config/widget_nfc_balance_config_screen.dart`
- `lib/features/widgets_config/widgets/widget_preview_card.dart`
- `docs/SUPABASE_SETUP.md`

### Modificados (10)
- `lib/main.dart` (unawaited prewarm)
- `lib/shared/widgets/background_wrapper.dart` (RepaintBoundary)
- `lib/features/map/transit_map.dart` (RepaintBoundary si falta)
- `lib/features/home/home_shell.dart` (RepaintBoundary nav + BackgroundWrapper en rail branch)
- `lib/features/map/map_filter_controller.dart` (disabledRouteIds + métodos)
- `lib/features/map/widgets/map_filter_sheet.dart` (reemplazar chips por tree)
- `lib/features/home/tabs/map_tab.dart` (umbral dinámico + filtro routes)
- `lib/core/theme/high_contrast_scheme.dart` (preserveAccent)
- `lib/shared/providers/theme_notifier.dart` (hcPreserveAccent)
- `lib/shared/providers/active_palette_provider.dart` (pasar flag)
- `lib/features/appearance/widgets/accessibility_section.dart` (sub-toggle)
- `lib/core/router/app_router.dart` (4 rutas widgets_config)
- `lib/features/home/widgets/profile_about_section.dart` (enlace a /widgets-config)
- `lib/l10n/app_es.arb` + `app_en.arb` + `app_ar.arb` (claves nuevas)

---

## 4. Plan de ejecución

### Sesión única (7 h)
Orden recomendado por dependencias:

1. **A (1 h)** — Pre-warming (independiente, lanzar primero porque tarda en compilar).
2. **E (20 min)** — Fondo rail (cambio mínimo, lo aprovechamos mientras compila A).
3. **B (30 min)** — RepaintBoundary.
4. **F (15 min)** — Umbral dinámico.
5. **G (30 min)** — HC preserve accent.
6. **H (15 min)** — Doc Supabase (paralelizable).
7. **C (2 h)** — Árbol expandible.
8. **D (2.5 h)** — Widgets config.
9. Build + smoke test final (45 min).

### Dividido en 2 sesiones cortas
- **Sesión 1 (3.5 h)**: A + B + E + F + G + H (perf + theming + doc).
- **Sesión 2 (3.5 h)**: C + D (UX features grandes).

---

## 5. Riesgos

- **R1: FMTC v10 API puede haber cambiado.** Mitigación: leer `pubspec.lock` antes de implementar A, ajustar si necesario.
- **R2: Pre-warming Jerez puede descargar ~500-1000 tiles (~20-50 MB).** Mitigación: limitar minZoom=13, maxZoom=15 (no 16+).
- **R3: RepaintBoundary mal puesto puede empeorar.** Mitigación: verificar con DevTools que las regiones de repaint son las esperadas, no más amplias.
- **R4: Árbol expandible con 19 líneas en 1 operador es trivial; pero si la app crece a N operadores, considerar buscador.** Mitigación: añadir TextField search dentro del árbol como mejora futura.
- **R5: WidgetPreviewCard puede divergir visualmente del render real Android.** Mitigación: aceptable — el preview ES aproximado, no pixel-perfect.
- **R6: HC preserve accent puede dar contrastes WCAG malos con accent saturado.** Mitigación: warning visual al activar si el contraste accent vs bg cae bajo 4.5:1.

---

## 6. Criterios de aceptación finales

1. Primer arranque con red → segunda apertura sin red: mapa funciona.
2. DevTools Performance: menos repaint rainbows fuera de áreas que cambian.
3. Filtros: tap "COMUJESA" en el árbol desmarca todas sus líneas; tap L8 desmarca solo L8.
4. Perfil → Widgets → tap "Próximo bus" → pantalla con preview + form funcionales.
5. Rotar móvil a landscape: fondo configurable visible.
6. Zoom out + tap → polyline lejana selecciona; zoom in + tap → solo polyline muy cerca.
7. HC + paleta Sunset + "preserve accent" ON: accent naranja, resto contraste puro.
8. `docs/SUPABASE_SETUP.md` existe y tiene los 4 pasos.

---

## 7. Próximos pasos

Cuando apruebes:
- **"arranca todo en orden"** → sesión única (~7 h).
- **"arranca sesión 1"** → A + B + E + F + G + H (~3.5 h, perf + theming).
- **"arranca sesión 2"** → C + D (~3.5 h, UX grandes).
- **"solo perf"** → A + B + E + F (~2 h, mapa fluido).
- **"solo features"** → C + D (~4.5 h, árbol + widgets).

Recomendado **"arranca sesión 1" primero** porque las mejoras de perf benefician al resto del trabajo.

---

## Changelog

- **2026-06-03** — Plan creado tras auditoría del plan 21-bugs (16/21 completados). Cierra los 5 pendientes + 3 bugs derivados (F1.bis, M1.bis, HC.bis). Tiempo total 7 h.
