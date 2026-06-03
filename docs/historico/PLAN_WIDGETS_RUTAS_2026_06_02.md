# Plan de acción — Widgets con datos correctos + acceso a crear rutas

**Fecha:** 2026-06-02
**Autor:** Claude Code (Opus 4.7)
**Estado:** propuesto
**Continuación de:** `PLAN_WIDGETS_FIXES_2026_06_02.md` (preview, descripciones y deep link ya arreglados).

---

## 1. Resumen ejecutivo

6 bugs en 2 áreas. Causa raíz auditada con `archivo:línea` exacto:

| # | Bug | Causa raíz | Severidad |
|---|-----|------------|-----------|
| **1** | Widget Próximo bus: ETA "-1048 min" | `main.dart:305` → `int.tryParse(parts[0])` toma SOLO las horas, ignora los minutos | **Alta** |
| **2** | Widget Mi línea: "En servicio" sin info | `MyLineWidgetProvider.kt:42-50` muestra `status` literal + `updatedAt` ISO crudo; **NO** muestra el array `upcoming` con las próximas salidas | **Alta** |
| **3** | Widgets muy grandes para el texto | `xml/widget_*_info.xml` minHeight=80dp para 3 líneas pequeñas + layout `vertical` con mucho padding | Media |
| **4** | Saldo NFC no se refleja | `WidgetDataWriter.writeNfcBalance` SOLO se llama al escanear (`saveScan`), NO al hidratar desde Hive en `_hydrateFromCache()` | **Alta** |
| **5** | Widget NFC: 404 intermitente | `_widgetLaunchPath` global estático nunca se limpia; entre cold/warm starts queda colgado | Media |
| **6** | No hay acceso a crear rutas | Las rutas `/create-route`, `/community`, `/my-routes` existen y las pantallas también, pero **NINGÚN tab/menú las enlaza** | **Alta** |

Tiempo total: **~5 h**. Ejecutables en una sesión.

---

## 2. Auditoría detallada

### Bug 1 — ETA negativo "-1048 min"

**Archivo:** `lib/main.dart:303-307`

```dart
final parts = first.departureTime.split(':');     // "18:30" → ["18", "30"]
final depMinutes = int.tryParse(parts[0]) ?? 0;   // ← solo coge "18" (horas)
final nowMinutes = now.hour * 60 + now.minute;    // ej. 17*60 + 45 = 1065
final eta = depMinutes - nowMinutes;              // 18 - 1065 = -1047 min
```

**Causa exacta:**
- `departureTime` viene en formato `"HH:MM"`.
- `parts[0]` son las HORAS, no los minutos del día.
- Hay que computar `int(parts[0]) * 60 + int(parts[1])`.

**Caso especial:** si la salida es ANTES de "ahora" (ej. último bus del día ya pasó), `eta` debe contemplar el siguiente día o devolver "Sin servicio". Para mock data se puede asumir que `getNextDepartures` ya filtra pasadas; verificar.

---

### Bug 2 — Widget Mi línea sin info real

**Archivo Kotlin:** `MyLineWidgetProvider.kt:38-50`

```kotlin
val data = JSONObject(jsonStr)
val status = data.optString("status", "Sin datos")     // "En servicio"
val updatedAt = data.optString("updatedAt", "")        // ISO crudo: "2026-06-02T17:45:00Z"
views.setTextViewText(R.id.widget_line_status, status)
views.setTextViewText(R.id.widget_line_updated, "Actualizado: $updatedAt")  // ← ilegible
```

**Causa:**
- El JSON guardado en `WidgetDataWriter.writeMyLineStatus` (`widget_data_writer.dart:50-81`) incluye `'upcoming': [{'time': '18:30'}, {'time': '18:45'}, ...]` con todas las próximas salidas.
- El provider Kotlin **ignora** ese array y muestra solo `status` (que es "En servicio" o "Sin datos" siempre, sin contenido útil) y `updatedAt` (ISO crudo).
- El layout XML (`widget_my_line.xml:24-30`) tiene espacio para "Próximos: 3, 18, 27 min" (texto de ejemplo del `tools:text`), pero el código Kotlin nunca lo rellena.

**Fix:** parsear `upcoming` array y formatearlo como "Próximos: 18:30 · 18:45 · 19:00" o "Próximas: 3, 18, 27 min" (relativos).

---

### Bug 3 — Widgets demasiado grandes

**Archivos:** los 3 `xml/widget_*_info.xml`:

```xml
<!-- widget_next_bus_info.xml + widget_my_line_info.xml -->
android:minWidth="180dp"
android:minHeight="80dp"

<!-- widget_nfc_balance_info.xml -->
android:minWidth="110dp"
android:minHeight="80dp"
```

Y los layouts (`widget_next_bus.xml`, etc.) tienen `padding="12dp"` + 3 TextViews con margenes (6+2 = 8dp) → contenido real ~64dp en alto. El widget reclama 80dp + margen del launcher (~10dp por lado) = ~110dp visibles. Resultado: mucho aire arriba/abajo.

**Fixes posibles:**
- Reducir `minHeight` a `60dp` (más ajustado al contenido).
- Reducir padding interno a `8dp`.
- O **rellenar** el espacio con info útil (recomendado): añadir línea extra ("Próximos: 8, 18 min" en Next bus) que ya tenemos en datos.

---

### Bug 4 — Saldo NFC no se refleja

**Archivos:** `lib/data/nfc/nfc_balance_repository.dart:23-39` + `lib/shared/providers/nfc_provider.dart:62-75` (hidrate añadido en sesión previa).

**Causa:**
- `_repository.saveScan()` SÍ llama `WidgetDataWriter.writeNfcBalance()` (línea 33-36).
- `NfcScanNotifier._hydrateFromCache()` lee del Hive al construir, pero **NO** llama a `WidgetDataWriter.writeNfcBalance()` con el último saldo. Por tanto si la app se reinstala o limpia datos del widget, el saldo queda vacío en SharedPreferences aunque exista en Hive.
- Adicionalmente: al ARRANCAR la app (sin escaneo nuevo), no se publica el saldo del Hive al widget. El widget muestra el último valor escrito antes del cierre, que puede estar desactualizado.

**Fix:** en `_hydrateFromCache`, si hay historia, llamar también:
```dart
final last = history.first;
WidgetDataWriter.writeNfcBalance(balance: last.balance, scannedAt: last.scannedAt);
```

---

### Bug 5 — 404 intermitente en widget NFC

**Archivos:** `lib/main.dart:188-200` + `lib/core/router/app_router.dart:73-82`

**Causa:**
- `_widgetLaunchPath` es global `String?`, no se limpia nunca.
- Sequence problemática:
  1. Cold start primera vez con widget NFC → `setWidgetLaunchPath('/home/tarjeta')` → app abre en `/home/tarjeta` ✓
  2. Usuario navega manualmente al perfil → background.
  3. Cold start segunda vez con widget Next bus → `setWidgetLaunchPath('/home/inicio')` → OK.
  4. PERO si el proceso se mantiene en background y solo hace warm start, `setWidgetLaunchPath` no se llama; el listener `widgetClicked` del `WidgetDeepLinkService` SÍ se dispara y enruta bien.
- El "404 a veces" probablemente ocurre cuando:
  - El widget se toca **mientras la app YA está abierta en otra pestaña**: el listener navega bien, no debería dar 404.
  - O cuando `GoRouter.initialLocation` se evaluó antes del `setWidgetLaunchPath` (race).

**Fix recomendado:**
- Limpiar `_widgetLaunchPath` después de consumirlo (`setWidgetLaunchPath(null)` tras el primer build de GoRouter).
- Forzar que el listener de `widgetClicked` SIEMPRE haga `go()` aunque la app esté abierta (en lugar de depender del initialLocation).
- Asegurar el fallback a `/home/inicio` en `_validPaths` también dentro del `errorBuilder` de GoRouter.

---

### Bug 6 — No hay punto de entrada para crear rutas

**Auditoría:**
- Rutas declaradas en `app_router.dart:237, 242, 273, ...`:
  - `/create-route` → `CreateRouteWizard` (existe)
  - `/create-route/:routeId` → editar
  - `/community` → `CommunityRoutesScreen` (existe)
  - `/community/route/:id` → detalle
  - `/my-routes` (probable) → `MyRoutesScreen` (existe)
- **Búsqueda exhaustiva** en `home_tab.dart`, `map_tab.dart`, `profile_tab.dart`, `search_tab.dart`, `card_tab.dart`: **0 referencias** a estas rutas.
- Solo se accede desde detalles internos (`community_routes_screen.dart:313` → tap a una ruta abre su detalle).

**Causa:** el plan v14 dejó la infraestructura pero nadie expuso el botón. El usuario no puede llegar.

**Fixes posibles:**
- (a) Añadir CTA "Crear ruta" en el perfil ("Mis rutas y comunidad" → submenu con "Mis rutas", "Comunidad", "Crear nueva ruta").
- (b) Añadir tab "Rutas" en bottom nav (cambio mayor, no recomendado).
- (c) Añadir FAB "Crear ruta" en el mapa (similar a apps de mapas que dejan añadir POI).

---

## 3. Plan dividido en 4 tareas

### Tarea A — Fix ETA + Mi línea data (1 h)

#### A.1. Fix ETA correcto
`lib/main.dart:303-315`. Reemplazar el cálculo de `eta`:
```dart
final parts = first.departureTime.split(':');
final depHour = int.tryParse(parts[0]) ?? 0;
final depMin = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
final depMinutes = depHour * 60 + depMin;
final nowMinutes = now.hour * 60 + now.minute;
var eta = depMinutes - nowMinutes;
if (eta < 0) eta += 24 * 60;  // próximo día
```

#### A.2. Llenar widget Mi línea con info real
Dos cambios:

**Dart** — `lib/data/widgets_native/widget_data_writer.dart:50-81`, cambiar el JSON para incluir "summary" pre-formateado para evitar parsing en Kotlin:
```dart
final summary = upcoming.isEmpty
    ? 'Sin servicio ahora'
    : 'Próximos: ' + upcoming.take(3).map((d) => d['time']).join(' · ');
final status = upcoming.isNotEmpty ? 'En servicio' : 'Sin servicio';
final payload = jsonEncode({
  'routeCode': routeCode,
  'status': status,
  'summary': summary,       // NUEVO
  'updatedAt': ...,
  'upcoming': upcoming,
});
```

**Kotlin** — `MyLineWidgetProvider.kt:40-50`:
```kotlin
val status = data.optString("status", "Sin datos")
val summary = data.optString("summary", "")
val updatedAt = data.optString("updatedAt", "")
views.setTextViewText(R.id.widget_line_code, routeCode)
views.setTextViewText(R.id.widget_line_status, status)
val displayLine = if (summary.isNotEmpty()) summary else "Actualizado: ${friendlyTime(updatedAt)}"
views.setTextViewText(R.id.widget_line_updated, displayLine)
```

Añadir helper `friendlyTime(iso: String): String` que convierta ISO a "hace X min" usando `java.time.Instant`.

---

### Tarea B — Reducir tamaño widgets + densidad de info (45 min)

#### B.1. Layouts más compactos
Los 3 XML `widget_*.xml`:
- Reducir `padding="12dp"` → `10dp`.
- `widget_route_code`: `textSize=22sp` → `18sp` (es código, no necesita ser tan grande).
- `widget_next_time`: añadir línea adicional con la 2ª y 3ª próximas (ej. "4 min · luego 12, 21 min").

#### B.2. minHeight reducido
Los 3 XML `widget_*_info.xml`: `android:minHeight="80dp"` → `60dp`. Y `targetCellHeight="1"` para Android 12+.

#### B.3. Widget Next bus: mostrar también próximas 2-3
Aprovechar que ya tenemos `deps` con 4 salidas en `_widgetBackgroundCallback`. Pasarlas todas en el JSON:
```dart
final summary = deps.take(3).map(...).join(' · ');
WidgetDataWriter.writeNextBus(
  ...
  etaMinutes: eta,
  summary: summary,  // NUEVO
);
```
Y el provider Kotlin lo muestra en una 4ª línea o sustituye `widget_next_time` por una línea más rica.

---

### Tarea C — Saldo NFC + 404 (45 min)

#### C.1. Hidratar widget al arrancar
`lib/shared/providers/nfc_provider.dart:_hydrateFromCache()`:
```dart
void _hydrateFromCache() {
  final history = _repo.getHistory();
  if (history.isEmpty) return;
  final last = history.first;
  state = state.copyWith(
    status: NfcScanStatus.success,
    result: last,
    scanHistory: history,
  );
  // NUEVO: publicar al widget para que vea el saldo persistido
  WidgetDataWriter.writeNfcBalance(
    balance: last.balance,
    scannedAt: last.scannedAt,
  );
}
```

#### C.2. Limpiar `_widgetLaunchPath` tras consumo
`lib/core/router/app_router.dart:73-82`:
```dart
final routerInitialLocationProvider = Provider<String>((ref) {
  final path = _widgetLaunchPath;
  if (path != null) {
    _widgetLaunchPath = null;  // consumido, no reusar en próximos provider rebuilds
    return path;
  }
  return '/splash';
});
```

#### C.3. Listener garantiza navegación en warm start
`lib/shared/services/widget_deep_link_service.dart:_route()` añadir un pequeño debounce + `WidgetsBinding.instance.addPostFrameCallback` para evitar race con GoRouter no montado:
```dart
void _route(Uri uri) {
  final path = '/${uri.host}${uri.path}';
  final target = _validPaths.contains(path) ? path : '/home/inicio';
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _goRouter.go(target);
  });
}
```

---

### Tarea D — Acceso a crear rutas (1.5 h)

#### D.1. Sección "Comunidad" en el perfil
Añadir un bloque nuevo en `lib/features/home/tabs/profile_tab.dart`, similar al de "Mis contribuciones":
```
┌─ Comunidad ────────────────────────────────┐
│ 🛣  Mis rutas             → /my-routes     │
│ 🌐  Explorar comunidad     → /community     │
│ ➕  Crear nueva ruta       → /create-route  │
└─────────────────────────────────────────────┘
```

Componentes:
- `GlassCard` con título "Comunidad".
- 3 `ListTile` con icono, label, trailing chevron.
- Tap → `context.push(ruta)`.

#### D.2. CTA destacado en el home
Si la sesión es invitado → no se muestra (no pueden crear).
Si está autenticado y NO tiene rutas creadas → tarjeta CTA:
```
┌─ ¿Conoces una ruta no oficial? ────────────┐
│ Compártela con la comunidad de Transitly   │
│           [ Crear ruta ➜ ]                  │
└─────────────────────────────────────────────┘
```

Implementación: añadir un `_BuildCreateRouteCta(c, l10n)` en `home_tab.dart` que aparezca solo si `userCreatedRoutesCount == 0`.

#### D.3. FAB en mapa (opcional)
En `map_tab.dart` añadir un FAB pequeño junto al de "mi ubicación" con icono `Icons.add_location_alt` que abra `/create-route`. Esto permite crear ruta directamente desde donde el usuario está mirando.

**Recomendación:** D.1 + D.2 (sin D.3) por ahora. El FAB en mapa puede confundir.

#### D.4. Localización
Nuevas claves en los 3 `.arb`:
```
profileCommunityTitle, profileMyRoutes, profileExploreCommunity, profileCreateRoute,
homeCreateRouteCtaTitle, homeCreateRouteCtaSubtitle, homeCreateRouteCtaAction
```
Traducciones es / en / ar.

#### D.5. Verificación
- Cold start como usuario autenticado → home muestra CTA "Crear ruta".
- Perfil → sección Comunidad → 3 enlaces visibles.
- Tap "Crear ruta" → abre wizard.
- Como invitado → CTA no aparece; sección Comunidad del perfil tampoco (o solo con "Explorar" y CTA de login para crear).

---

## 4. Archivos a modificar (resumen)

### Dart
- `lib/main.dart` (fix ETA + limpieza de `_widgetLaunchPath` consumido)
- `lib/data/widgets_native/widget_data_writer.dart` (campo `summary` en JSON)
- `lib/shared/providers/nfc_provider.dart` (publicar saldo al hidratar)
- `lib/shared/services/widget_deep_link_service.dart` (postFrameCallback)
- `lib/core/router/app_router.dart` (consumir `_widgetLaunchPath`)
- `lib/features/home/tabs/profile_tab.dart` (sección Comunidad)
- `lib/features/home/tabs/home_tab.dart` (CTA crear ruta condicional)
- `lib/l10n/app_es.arb`, `app_en.arb`, `app_ar.arb` (6 claves)

### Android nativo (Kotlin + XML)
- `android/app/src/main/kotlin/com/transitly/transitly/widgets/MyLineWidgetProvider.kt` (mostrar `summary`)
- `android/app/src/main/kotlin/com/transitly/transitly/widgets/NextBusWidgetProvider.kt` (mostrar línea de "próximas")
- `android/app/src/main/res/layout/widget_next_bus.xml` (línea extra "próximas")
- `android/app/src/main/res/layout/widget_my_line.xml` (línea extra "próximas")
- `android/app/src/main/res/xml/widget_*_info.xml` (minHeight 80→60)

### Sin tocar
- AndroidManifest, gradle, providers Kotlin de NFC, capa Hive, repos.

---

## 5. Estimación de tiempo

| Tarea | Tiempo | Prioridad |
|-------|--------|-----------|
| A — ETA + Mi línea data | 1 h | **Alta** (datos incorrectos visibles) |
| B — Tamaño + densidad | 45 min | Media |
| C — NFC saldo + 404 | 45 min | **Alta** |
| D — Acceso crear rutas | 1.5 h | **Alta** (feature inalcanzable) |
| Build + smoke | 30 min | — |
| **Total** | **~4.5 h** | una sesión |

---

## 6. Orden de ejecución recomendado

1. **A.1 (ETA)** primero: 10 min, fix más visible.
2. **C.1 (NFC saldo)**: 15 min, completa la trilogía de bugs de datos.
3. **A.2 (Mi línea summary)**: 30 min, requiere tocar Kotlin.
4. **B (tamaño)**: 45 min, cambios solo en XML.
5. **C.2 + C.3 (404)**: 30 min.
6. **D (crear rutas)**: 1.5 h al final, más alcance.
7. Build APK + install + smoke completo: 30 min.

---

## 7. Decisiones tomadas (no requieren confirmación)

Igual que en planes anteriores, decido las opciones "más eficientes y efectivas":

| # | Decisión | Por qué |
|---|----------|---------|
| D1 | Campo `summary` pre-formateado en JSON, no parsing en Kotlin | Menos código nativo, fácil de cambiar formato sin re-deploy |
| D2 | `minHeight 60dp` (no 50) | Compromiso: cabe en 1 fila de cells y sigue legible |
| D3 | Acceso a crear rutas: perfil (D.1) + CTA condicional en home (D.2), sin FAB de mapa | Descubrible sin invasivo |
| D4 | Si invitado: perfil muestra solo "Explorar comunidad" + texto "Inicia sesión para crear rutas" | Respeta `userFavoritesProvider` patterns existentes |
| D5 | `_widgetLaunchPath` se limpia tras primer consumo | Evita race conditions entre cold/warm starts |
| D6 | Mostrar próximas 2-3 salidas (no solo 1) en widgets A y B | Más útil con poco espacio extra |

---

## 8. Riesgos

- **R1: Cambiar layouts XML afecta widgets ya colocados.** Android puede no actualizar el preview hasta que se quita y reañade el widget. Documentar en smoke test.
- **R2: `friendlyTime()` ISO→relative en Kotlin requiere `java.time` (API 26+).** Verificar `minSdkVersion`. Si es <26, usar `SimpleDateFormat` legacy.
- **R3: Cambio en `routerInitialLocationProvider` (limpiar path tras consumo) puede romper hot reload.** Probar `flutter run` y reloads múltiples.
- **R4: CTA "Crear ruta" en home puede aparecer hasta que el usuario tenga 1+ ruta.** Necesita un provider que cuente `userCreatedRoutes`. Si no existe, crearlo es trabajo extra. **Mitigación:** si no existe, mostrar el CTA siempre (autenticado) y dejar para más adelante el contador.
- **R5: 3 `.arb` con claves nuevas pueden no regenerarse si `gen-l10n` falla.** Ejecutar `flutter gen-l10n` y verificar.

---

## 9. Criterios de aceptación (smoke test)

1. **Widget Next bus**: muestra "4 min" correcto, nunca negativo. Ejemplo: si bus pasa a 18:30 y son las 18:15, muestra "15 min".
2. **Widget Mi línea**: muestra "Próximos: 18:30 · 18:45 · 19:00" (no solo "En servicio").
3. **Widgets compactos**: cada uno cabe en 1 fila de cells del launcher sin huecos enormes.
4. **Saldo NFC**: escaneo → cerrar app → reabrir → widget sigue mostrando el saldo correcto.
5. **404 NFC widget**: tap repetidas veces (cold + warm) → siempre abre `/home/tarjeta`, nunca 404.
6. **Perfil → Comunidad**: 3 enlaces visibles (Mis rutas, Explorar, Crear nueva).
7. **Home autenticado**: tarjeta "Crear ruta" visible.
8. **Crear wizard**: tap CTA → abre `/create-route` con el wizard de pasos.
9. **Como invitado**: perfil muestra "Explorar comunidad" pero NO "Crear" (CTA de login).
10. **i18n**: cambiar idioma a inglés → labels traducidos.

---

## 10. Próximos pasos

Cuando apruebes:
- **"arranca A+C primero"** → fix bugs de datos críticos (1.5 h).
- **"arranca todo en orden"** → 4.5 h en una sesión, A→C→B→D.
- **"solo D"** → si los widgets te dan igual de momento, abrir acceso a crear rutas (1.5 h).

Recomiendo **"arranca todo en orden"** porque las tareas tocan archivos diferentes y se complementan.

---

## Changelog

- **2026-06-02** — Plan creado tras auditoría:
  - ETA negativo: bug en `main.dart:305` parseando solo horas.
  - Mi línea sin info: provider Kotlin ignora array `upcoming`.
  - Saldo NFC: hidrate no publica al widget.
  - 404 intermitente: `_widgetLaunchPath` no se limpia.
  - Crear rutas: rutas + pantallas existen, sin puntos de entrada en tabs.
