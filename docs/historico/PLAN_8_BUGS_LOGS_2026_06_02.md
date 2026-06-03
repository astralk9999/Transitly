# Plan de acción — 8 bugs (crash dislexia, fondo en otras pestañas, logs Hive, tap parada cerca, perf, accesibilidad)

**Fecha:** 2026-06-02
**Autor:** Claude Code (Opus 4.7)
**Estado:** propuesto
**Continuación de:** `PLAN_15_BUGS_2026_06_02.md` (parcialmente ejecutado; este plan añade los bugs descubiertos en logs y los reportados por usuario)
**Goal:** Estabilizar comportamiento de la app — eliminar el crash bloqueante al cambiar fuente/accesibilidad, limpiar spam de logs, hacer que el fondo aplique en TODAS las pestañas, y conectar el tap de "Paradas cerca" con el mapa.
**Arquitectura:** Fixes incrementales, sin refactor. Todos los bugs tienen causa raíz auditada con `archivo:línea`.
**Stack:** Flutter 3.9.2 + Riverpod 2.6.1 + Hive 2.2.

---

## 1. Bugs reportados (con severidad)

| # | Bug | Origen | Severidad |
|---|-----|--------|-----------|
| **1** | Cambiar fuente dislexia / tamaño / accesibilidad → app CRASHEA y no se puede reabrir | usuario | **CRÍTICA — bloqueante total** |
| **2** | Modo claro + alto contraste a la vez → texto invisible | usuario | Alta |
| **3** | Cambiar fondo solo se aplica en pestaña Apariencia, no en home/mapa/etc. | usuario | Alta |
| **4** | "Paradas cerca de ti" — al tocar una parada no pasa nada (debería abrir mapa centrado en ella) | usuario | Media |
| **5** | Spam de logs `[WARN][StorageRepo] file size unavailable ... HiveError: box is already open` × 17 boxes cada navegación | logs | Media (ruido) |
| **6** | Warning Android: `OnBackInvokedCallback is not enabled` | logs | Baja |
| **7** | `Choreographer: Skipped 103 frames!` — jank significativo | logs | Media |
| **8** | (Continúa pendiente del plan anterior) | — | — |

Tiempo total estimado: **~4 h** (crash es ~1.5 h, resto rápido).

---

## 2. Auditoría con causa raíz (archivo:línea)

### Bug 1 — Crash al cambiar dislexia/tamaño + persistencia tóxica

**Sospechas múltiples auditadas:**

**1.A.** `lib/core/theme/transit_typography.dart:6-22`:
```dart
static String _activeFontFamily({bool monospace = false}) {
  if (isDyslexiaEnabled()) return 'OpenDyslexic';
  return monospace ? 'IBM Plex Mono' : 'DM Sans';
}
static List<String>? _fallback() {
  if (isDyslexiaEnabled()) {
    return const ['Atkinson Hyperlegible', 'DM Sans'];
  }
  return null;
}
```
OpenDyslexic SÍ está en `pubspec.yaml:113-118` con Regular(400) + Bold(700). Pesos 500/600 NO están registrados → si algún `TextStyle` los pide, Flutter intenta sintetizar y puede fallar con el OTF.

**1.B.** `lib/app.dart:52-56`:
```dart
final rawSystem = MediaQuery.textScalerOf(context).scale(1.0);
final systemScale = rawSystem.isFinite && rawSystem > 0 ? rawSystem : 1.0;
final combined = (systemScale * themeNotifier.fontScale).clamp(0.8, 2.5);
```
El clamp es defensivo, pero si `fontScale` viene de prefs como `NaN` o `Infinity` (corrupción de Hive), `systemScale * NaN = NaN` y aunque `.clamp` lo devuelve, el `TextScaler.linear(NaN)` crashea.

**1.C. Persistencia tóxica:** este es el problema más crítico. Cuando el usuario cambia algo y crashea, ese valor TÓXICO queda guardado en Hive (`guest_prefs` o `user_preferences`). Al reabrir, `_loadGuestPrefs()` (`theme_notifier.dart:451+`) lo carga y vuelve a crashear → **app brickeada hasta clear data**.

**Sin protección try/catch alrededor de `_loadGuestPrefs()` ni `init()`**, ni mecanismo de "reset si load falla".

### Bug 2 — Modo claro + alto contraste invisible
**Archivo:** `lib/core/theme/high_contrast_theme.dart:11`
```dart
final solidScheme = TransitColorScheme.of(isDark);
```
NO fuerza `textHi` a blanco/negro puro. En modo claro queda gris-medio sobre fondo blanco → invisible. Mismo bug que el plan anterior pero el usuario lo recalca con énfasis.

### Bug 3 — Fondo solo aplica en Apariencia
**Auditoría inicial:**
- `BackgroundWrapper` se monta en `app.dart:35-40` envolviendo TODO el child del `MaterialApp.builder`.
- Por tanto está presente en todas las pestañas en teoría.

**Hipótesis:**
- El `KeyedSubtree(key: ValueKey(rebuildKey))` con `rebuildKey = '${themeNotifier.visualKey}|${themeMode.name}'` causa un rebuild del subárbol al cambiar la paleta o modo. PERO si solo cambia `backgroundId` y `visualKey` NO lo incluye, el wrapper sigue mostrando el background viejo en el mounted subtree.
- O el `background_wrapper.dart` usa `ref.watch(themeNotifierProvider.select((n) => n.background))` que con `backgroundFromId` crea instancias nuevas → equality falla → no rebuild en otras pestañas (solo en Apariencia donde el provider se watches directamente para preview).

**Verificable:** leer `theme_notifier.dart:visualKey` y ver si incluye `backgroundId`.

### Bug 4 — Tap en parada cerca no hace nada
**Archivo:** `lib/features/home/tabs/home_tab.dart:583-612`
```dart
Widget _buildNearbyStop(BuildContext context, ...) {
  return GlassCard(
    ...
    child: Column(...),
  );
}
```
**El GlassCard NO tiene `onTap`** ni está envuelto en `Pressable` / `InkWell`. Por eso es inerte.

Comparar con `_buildHabitualTripConfigured` que sí tiene navegación.

### Bug 5 — Spam HiveError "already open"
**Archivo:** `lib/data/cache/storage_repository.dart:14-33`
```dart
if (!Hive.isBoxOpen(boxName)) return 0;
final box = Hive.box(boxName);  // ← sin tipo
final path = box.path;
```
`Hive.box(boxName)` sin tipo intenta `Box<dynamic>`. Pero la box ya está abierta como `Box<RouteModel>` etc. → lanza `HiveError: "is already open and of type Box<RouteModel>"` → cae en el `catch` → log warn.

**Esto ocurre cada vez que el repo intenta calcular tamaño** (debug overlay, stats, etc.). En cada navegación se llama → 17 warns + box path × N → spam masivo en logs y obliga al log subsystem a flushear constantemente (puede contribuir al jank del Bug 7).

### Bug 6 — OnBackInvokedCallback
Android 13+ (API 33) introduce el back predictivo. Falta opt-in:
```xml
<application android:enableOnBackInvokedCallback="true" ...>
```
en `android/app/src/main/AndroidManifest.xml:11+`.

Sin efecto visible pero ruido en logs.

### Bug 7 — 103 frames skipped
Sin profiling detallado no puedo identificar la causa exacta. Pero candidatos:
- El log spam del Bug 5 (escribir a `print` 17+ veces × N navegaciones es caro).
- Builds excesivos del `BackgroundWrapper` por cambios en `visualKey`.
- `MediaQuery` rebuild en cada cambio.

Mitigar Bug 5 primero y medir de nuevo.

---

## 3. Plan de tareas

### Tarea A — Crash dislexia + safety reset (1.5 h) — CRÍTICA

**Goal:** la app NUNCA debe quedar brickeada por una preferencia tóxica. Aunque el usuario fuerce un valor inválido, al reabrir debe arrancar con defaults.

#### A.1 — Safety reset en carga de prefs
**Archivos:**
- Modify: `lib/shared/providers/theme_notifier.dart` (envolver `_loadGuestPrefs` y `_loadAuthPrefs` en try/catch + reset a defaults si falla)

**Steps:**
- [ ] En `_loadGuestPrefs()`, envolver TODO en try/catch + log error + aplicar defaults:
```dart
Future<void> _loadGuestPrefs() async {
  try {
    _guestBox ??= await _openGuestBox();
    final data = _guestBox!.get('prefs');
    if (data != null) {
      _paletteId = _safeString(data['paletteId'], 'default');
      _backgroundId = _safeString(data['backgroundId'], 'shaders/smoke.frag');
      _backgroundEnabled = data['backgroundEnabled'] as bool? ?? true;
      _backgroundOpacity = _safeDouble(data['backgroundOpacity'], 1.0);
      _fontScale = _safeDouble(data['fontScale'], 1.0).clamp(0.8, 2.5);
      _colorBlindMode = _parseColorBlindMode(data['colorBlindMode'] as String?);
      _dyslexiaFont = data['dyslexiaFont'] as bool? ?? false;
      _highContrast = data['highContrast'] as bool? ?? false;
      _reduceMotion = data['reduceMotion'] as bool? ?? false;
    }
    _initialized = true;
  } catch (e, st) {
    AppLogger.error(_logTag, 'guest prefs corrupted, resetting to defaults', e, st);
    _resetToDefaults();
    await _persistGuest(); // sobreescribe lo tóxico
    _initialized = true;
  }
}

double _safeDouble(dynamic v, double fallback) {
  if (v is num && v.isFinite) return v.toDouble();
  return fallback;
}
String _safeString(dynamic v, String fallback) {
  return v is String && v.isNotEmpty ? v : fallback;
}
void _resetToDefaults() {
  _paletteId = 'default';
  _backgroundId = 'shaders/smoke.frag';
  _backgroundEnabled = true;
  _backgroundOpacity = 1.0;
  _fontScale = 1.0;
  _colorBlindMode = ColorBlindMode.none;
  _dyslexiaFont = false;
  _highContrast = false;
  _reduceMotion = false;
}
```
- [ ] Replicar lo mismo en `_loadAuthPrefs` (línea ~420+).
- [ ] Test manual: corromper Hive manualmente (`adb shell` + escribir basura en la box) → reabrir → app arranca con defaults.

#### A.2 — Validar fontScale en runtime
**Archivos:**
- Modify: `lib/app.dart:52-69`

**Steps:**
- [ ] En el builder, antes de aplicar el `textScaler`, validar:
```dart
final rawSystem = MediaQuery.textScalerOf(context).scale(1.0);
final systemScale = rawSystem.isFinite && rawSystem > 0 ? rawSystem : 1.0;
final notifierScale = themeNotifier.fontScale.isFinite
    && themeNotifier.fontScale > 0
    ? themeNotifier.fontScale
    : 1.0;
final combined = (systemScale * notifierScale).clamp(0.8, 2.5);
if (!combined.isFinite || combined <= 0) return result; // bypass MediaQuery
```

#### A.3 — Fallback safe en OpenDyslexic
**Archivos:**
- Modify: `lib/core/theme/transit_typography.dart` (fallback más robusto)

**Steps:**
- [ ] Cambiar `_fallback` para SIEMPRE incluir fuentes registradas:
```dart
static List<String>? _fallback() {
  if (isDyslexiaEnabled()) {
    return const ['Atkinson Hyperlegible', 'DM Sans', 'sans-serif'];
  }
  return const ['DM Sans', 'sans-serif'];
}
```
- [ ] Si algún `TextStyle` usa peso `w500/w600` que OpenDyslexic no tiene → caerá al fallback. Verificar todos los uso de `_activeFontFamily()` y considerar usar solo `w400/w700`.

#### A.4 — Verificación
- [ ] Build + activar dislexia + cambiar fontScale a max + alto contraste + color blind protanopia → NO crashea.
- [ ] Forzar prefs corruptas (escribir un `fontScale: "abc"` en Hive) → reabrir → defaults aplicados.

---

### Tarea B — Modo claro + alto contraste visible (30 min)

**Archivos:**
- Modify: `lib/core/theme/high_contrast_theme.dart`

**Steps:**
- [ ] Reescribir `apply()`:
```dart
static ThemeData apply(ThemeData base, TransitColorScheme scheme) {
  final isDark = base.colorScheme.brightness == Brightness.dark;
  final pureText = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
  final pureBg = isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
  final accentHC = isDark ? const Color(0xFFFFEB3B) : const Color(0xFF1565C0);
  return base.copyWith(
    scaffoldBackgroundColor: pureBg,
    canvasColor: pureBg,
    colorScheme: base.colorScheme.copyWith(
      surface: pureBg,
      onSurface: pureText,
      primary: accentHC,
      onPrimary: pureBg,
    ),
    textTheme: base.textTheme.apply(bodyColor: pureText, displayColor: pureText),
    iconTheme: base.iconTheme.copyWith(color: pureText),
    appBarTheme: base.appBarTheme.copyWith(
      backgroundColor: pureBg,
      foregroundColor: pureText,
      iconTheme: IconThemeData(color: pureText),
    ),
    // ... cardTheme, inputDecoration, etc con bordes 2px y mismos colores puros
  );
}
```
- [ ] Smoke test: home + perfil + mapa con modo claro + alto contraste → todo el texto en NEGRO PURO legible.

---

### Tarea C — Fondo aplica en TODAS las pestañas (45 min)

#### C.1 — Verificar `visualKey`
**Archivos:**
- Read: `lib/shared/providers/theme_notifier.dart` (buscar `get visualKey`)
- Modify si no incluye `backgroundId`

**Steps:**
- [ ] Buscar `visualKey` y confirmar que incluye `backgroundId` + `backgroundEnabled` + `backgroundOpacity`:
```dart
String get visualKey =>
    '$_paletteId|$_backgroundId|$_backgroundEnabled|$_backgroundOpacity|'
    '$_fontScale|${_colorBlindMode.name}|$_dyslexiaFont|$_highContrast';
```
- [ ] Si faltan, añadir. Esto fuerza al `KeyedSubtree` a desechar+remontar el subárbol al cambiar fondo.

#### C.2 — Watch del background en wrapper
**Archivos:**
- Modify: `lib/shared/widgets/background_wrapper.dart`

**Steps:**
- [ ] Verificar que el wrapper hace `ref.watch(themeNotifierProvider)` (sin `select` con campo derivado).
- [ ] Si usa `.select((n) => n.background)` que crea instancias → cambiar a `.select((n) => n.backgroundId)` (string comparable directamente).
- [ ] Hot reload + cambiar fondo en Apariencia + ir a otra pestaña → background nuevo visible.

---

### Tarea D — Tap "Paradas cerca" → mapa centrado (30 min)

**Archivos:**
- Modify: `lib/features/home/tabs/home_tab.dart:583+` (envolver con onTap)
- Modify: `lib/features/home/tabs/map_tab.dart` (leer parámetro `centerOnStopId` y mover el mapa)

**Steps:**
- [ ] En `_buildNearbyStop`, envolver el `GlassCard` con `InkWell` o usar el componente `Pressable`:
```dart
return Pressable(
  onTap: () {
    context.go('/home/mapa', extra: {'centerOnStopId': stop.id});
  },
  child: GlassCard(
    ...
  ),
);
```
- [ ] En `map_tab.dart`, leer el extra al construir:
```dart
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  final state = GoRouterState.of(context);
  final extra = state.extra;
  if (extra is Map && extra['centerOnStopId'] is String) {
    final stopId = extra['centerOnStopId'] as String;
    final mockData = ref.read(mockDataServiceProvider);
    final stop = mockData.getStopById(stopId);
    if (stop != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(LatLng(stop.lat, stop.lng), 17);
      });
    }
  }
}
```
- [ ] Smoke: tap en parada cerca → mapa abre centrado en esa parada + marker visible.

---

### Tarea E — Eliminar spam HiveError (15 min)

**Archivos:**
- Modify: `lib/data/cache/storage_repository.dart:14-33`

**Steps:**
- [ ] Cambiar a `Hive.box<dynamic>(boxName)` no resuelve (sigue dando error si el tipo no es exactamente `dynamic`). Mejor: usar reflexión sobre el tipo correcto con un `try/catch` SILENCIOSO (debug-only):
```dart
Future<int> fileSizeFor(String boxName) async {
  if (!Hive.isBoxOpen(boxName)) return 0;
  try {
    // Intentamos varios tipos comunes — si no, devolvemos 0 sin warn.
    final path = _tryGetPath(boxName);
    if (path != null) return File(path).lengthSync();
  } catch (_) {
    // silencioso: este info es solo para overlay de debug
  }
  return 0;
}

String? _tryGetPath(String boxName) {
  // En lugar de Hive.box(boxName) genérico, accedemos al filesystem directamente.
  // Los nombres de archivo de Hive son `<boxName>.hive` en applicationDocumentsDirectory.
  // Si la app no nos permite leer, devolvemos null.
  return null; // simplificación: omitimos info de tamaño que no es crítica
}
```
- [ ] Alternativa más simple: bajar el log de `warn` a `debug` para que no aparezca en logcat por defecto:
```dart
AppLogger.debug(_logTag, 'file size unavailable for $boxName (already open as typed box)');
```
- [ ] Test: navegación general → cero líneas `[WARN][StorageRepo]` en logcat.

---

### Tarea F — OnBackInvokedCallback + Choreographer (20 min)

#### F.1 — Habilitar back predictivo
**Archivos:**
- Modify: `android/app/src/main/AndroidManifest.xml`

**Steps:**
- [ ] Añadir al `<application>`:
```xml
<application
    android:label="transitly"
    android:name="${applicationName}"
    android:icon="@mipmap/ic_launcher"
    android:enableOnBackInvokedCallback="true">
```
- [ ] Build + verificar que el warning desaparece.

#### F.2 — Reducir jank
**Steps:**
- [ ] Tarea E debería eliminar la mayor fuente de jank (spam de logs).
- [ ] Después, si sigue habiendo jank, profile con `flutter run --profile` + DevTools Performance tab.
- [ ] Posible optimización: añadir `RepaintBoundary` al `BackgroundWrapper` para aislar pintado del fondo del resto del árbol.

---

## 4. Archivos modificados (resumen)

### Dart
- `lib/shared/providers/theme_notifier.dart` (safety load + reset to defaults)
- `lib/core/theme/transit_typography.dart` (fallback más robusto)
- `lib/core/theme/high_contrast_theme.dart` (texto + bg puros)
- `lib/app.dart` (validación fontScale)
- `lib/shared/widgets/background_wrapper.dart` (watch granular)
- `lib/features/home/tabs/home_tab.dart` (onTap en parada cerca)
- `lib/features/home/tabs/map_tab.dart` (lee centerOnStopId)
- `lib/data/cache/storage_repository.dart` (silenciar logs)

### Android
- `android/app/src/main/AndroidManifest.xml` (enableOnBackInvokedCallback)

### Sin tocar
- Wizard crear ruta, widgets, auth, providers de favoritos.

---

## 5. Estimación de tiempo

| Tarea | Tiempo | Acumulado | Prioridad |
|-------|--------|-----------|-----------|
| A — Crash dislexia + safety reset | 1.5 h | 1.5 h | **CRÍTICA — bloqueante** |
| B — Alto contraste claro visible | 30 min | 2 h | Alta |
| C — Fondo en todas pestañas | 45 min | 2.75 h | Alta |
| D — Tap parada cerca → mapa | 30 min | 3.25 h | Media |
| E — Logs Hive limpio | 15 min | 3.5 h | Media (perf) |
| F — Back invoked + perf | 20 min | 3.75 h | Baja |
| Build + smoke | 30 min | 4.25 h | — |
| **Total** | **~4 h** | | 1 sesión |

---

## 6. Orden recomendado

1. **A primero** (1.5 h): es el ÚNICO bug bloqueante. Sin esto el usuario no puede usar Apariencia con confianza.
2. **E** (15 min): elimina el ruido para poder leer logs útiles en los siguientes pasos.
3. **B + C** (1.25 h): los dos bugs visuales que el usuario nota constantemente.
4. **D** (30 min): mejora UX importante pero no crítica.
5. **F** (20 min): polish final.

---

## 7. Riesgos

- **R1: Safety reset puede borrar prefs válidas si hay un bug en el try/catch.** Mitigación: log explícito de qué prefs estaban corruptas + permitir al usuario re-aplicarlas desde Apariencia.
- **R2: Cambiar `visualKey` fuerza rebuild de TODO el árbol al cambiar fondo.** Mitigación: aceptable (es lo esperado al cambiar tema visual).
- **R3: `enableOnBackInvokedCallback=true` puede romper navigation existente.** Mitigación: probar el back físico en cada pestaña tras el cambio.
- **R4: Silenciar HiveError oculta posibles bugs reales de Hive.** Mitigación: en lugar de catch silencioso, log a debug-level que no aparece en logcat default.
- **R5: Mover `_mapController` desde `didChangeDependencies` puede provocar move durante build.** Mitigación: `addPostFrameCallback` envuelve el move.

---

## 8. Criterios de aceptación

1. Activar fuente dislexia + subir fontScale al max + activar alto contraste + color blind: **NO crashea**.
2. Si la app crashea por cualquier prefs corruptas, al reabrir arranca con defaults sin loop infinito.
3. Modo claro + alto contraste: texto NEGRO PURO sobre fondo BLANCO PURO visible.
4. Cambiar fondo en Apariencia → ir a Home / Mapa / Tarjeta → fondo nuevo aplicado.
5. Home → "Paradas cerca de ti" → tap en una → abre mapa centrado en ella (zoom 17).
6. `flutter run` y navegar varias pestañas: **CERO líneas** `[WARN][StorageRepo]`.
7. Warning `OnBackInvokedCallback not enabled` desaparece.
8. Performance: no más de 10 frames skipped en navegación típica (medible con DevTools).

---

## 9. Próximos pasos

Cuando apruebes:
- **"arranca todo en orden"** → A → E → B+C → D → F (~4 h).
- **"solo A"** → fix solo el crash bloqueante (~1.5 h) y continuar el plan anterior.
- **"A+B+C"** → los 3 críticos visuales (~2.75 h).

Recomiendo **"arranca todo en orden"** porque son 4 h totales y todos están relacionados con el estado visual del usuario.

---

## Changelog

- **2026-06-02** — Plan creado tras auditoría de bugs nuevos + logs:
  - Bug 1 (crash dislexia): causa raíz = persistencia tóxica sin safety reset.
  - Bug 3 (fondo): probable `visualKey` sin `backgroundId`.
  - Bug 4 (tap parada): GlassCard sin onTap envolvente.
  - Bug 5 (logs): `Hive.box(name)` sin tipo en `storage_repository.dart:16`.
  - Bug 6 (back invoked): falta atributo en AndroidManifest.
  - Bug 7 (jank): probable consecuencia de Bug 5 → fix en cascada.
