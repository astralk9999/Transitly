# Plan de acción — 8 bugs reportados (home, sesión, NFC, favoritos)

**Fecha del plan:** 2026-06-02
**Autor:** Claude Code (Opus 4.7)
**Estado:** propuesto, pendiente de aprobación
**Alcance:** 8 bugs acotados, sin tocar arquitectura. Auditoría hecha leyendo el código en disco. Cada bug lleva causa raíz con `archivo:línea`.

---

## 1. Resumen ejecutivo

8 bugs en 6 áreas distintas. Los agrupo así:

| Grupo | Bugs | Riesgo |
|-------|------|--------|
| **A — UI Home** | 1 (saludo pequeño), 2 (selector "Jerez"), 8 (snackbar favorito) | Bajo, cambios visuales |
| **B — Habitual config sheet** | 3 (tapado por navbar), 4 (selector líneas/paradas incómodo) | Medio, UX importante |
| **C — Saldo NFC** | 5 (404 al tocar widget), 6 (no persiste invitado) | Medio, requiere diagnóstico |
| **D — Sesión** | 7 (logout al reabrir) | **Alto** — bloquea uso normal |

Tiempo estimado total: **~6 h**. Ejecutar en una sesión si quieres todo, o priorizar grupo D primero porque rompe el caso de uso de "abrir la app".

---

## 2. Auditoría de cada bug (causa raíz)

### Bug 1 — Saludo demasiado pequeño

**Causa:** `lib/features/home/tabs/home_tab.dart:170-173`
```dart
return Text(
  greetingText,
  style: TransitTypography.bodySecondary(c.textMid),  // ← ~14-15 sp
);
```

`bodySecondary` es el estilo de subtítulos secundarios. Para un saludo destacado en el home queremos algo cerca de `heading` o un nuevo `greeting` token.

---

### Bug 2 — "Jerez de la Frontera" (selector operador) sobra

**Causa:** `lib/features/home/tabs/home_tab.dart:176-200`
```dart
Tooltip(
  message: l10n.homeChangeCityTooltip,
  child: GestureDetector(
    onTap: () => context.push('/city-picker'),
    child: Row(
      children: [
        Flexible(child: Text(
          ref.watch(activeOperatorProvider)?.name ?? l10n.homeDefaultCity,
          ...
        )),
        Icon(Icons.arrow_drop_down, ...),
      ],
    ),
  ),
)
```

Decisión del usuario: eliminar este bloque completamente. La app de momento solo soporta COMUJESA/Jerez, así que el selector no aporta valor y ensucia el header.

Cuidado: hay que decidir qué hacer con la ruta `/city-picker`. Opciones:
- (a) **Recomendada:** dejar la ruta y la pantalla intactas (por si se reactiva en el futuro), solo quitar el botón de acceso desde el home. Cero riesgo.
- (b) Eliminar también la ruta `/city-picker` y la pantalla `lib/features/city_picker/...`. Más limpieza pero requiere más auditoría.

---

### Bug 3 — Sheet "configurar viaje habitual" tapado por la nav bar

**Causa:** `lib/features/home/widgets/habitual_config_sheet.dart:42-48`
```dart
return Padding(
  padding: EdgeInsets.fromLTRB(
    16,
    8,
    16,
    24 + MediaQuery.of(ctx).viewInsets.bottom,  // ← solo cuenta el TECLADO
  ),
  ...
)
```

`MediaQuery.viewInsets.bottom` SOLO contempla el teclado abierto, no la safe area del sistema ni la BottomNavigationBar de la app. El sheet por tanto se renderiza con su borde inferior pegado al final del viewport, y los botones de "Guardar" + el segundo dropdown caen detrás del nav bar.

`showModalBottomSheet` por defecto tampoco respeta la safe area (`useSafeArea: false`).

---

### Bug 4 — Selector de líneas/paradas incómodo

**Síntomas:**
- (4a) El dropdown de líneas muestra las 19 sin buscador → desplazarse es lento.
- (4b) "Hay paradas incompatibles" cuando seleccionas línea.

**Causas:**

**4a — sin búsqueda:** `lib/features/home/widgets/habitual_config_sheet.dart:69-99` usa `DropdownButtonFormField<RouteModel>` con `items: routes.map(...)`. Es un dropdown nativo plano sin filtro. Con 19 líneas es manejable, pero la UX es mala (no se ven todas a la vez en móvil, hay que scrollear el dropdown).

**4b — paradas duplicadas o de sentido contrario:** `lib/data/mock/mock_data_service.dart:332-341`:
```dart
List<StopModel> getStopsForRoute(String routeId) {
  final rs = routeStops[routeId];
  if (rs == null) return [];
  final ordered = List<RouteStopModel>.from(rs)
    ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  return ordered
      .map((rs) => getStopById(rs.stopId))
      .whereType<StopModel>()
      .toList();
}
```

`RouteStopModel` tiene un campo `direction` (verificado en `lib/shared/models/route_stop_model.dart:15` → `@Default(RouteDirection.outbound) RouteDirection direction`). Pero `getStopsForRoute` **NO filtra por dirección** — devuelve TODAS las paradas de la ruta tanto en sentido ida como vuelta. Por eso aparecen "incompatibles" o duplicadas.

---

### Bug 5 — Click widget NFC → error 404 (y no refleja saldo)

**Causa potencial 1 (404):** `lib/main.dart:188-193`
```dart
final launchUri = await HomeWidget.initiallyLaunchedFromHomeWidget();
if (launchUri != null) {
  final deepPath = '/${launchUri.host}${launchUri.path}';
  setWidgetLaunchPath(deepPath);
  ...
}
```

Y `lib/core/router/app_router.dart:73-76`:
```dart
final routerInitialLocationProvider = Provider<String>((ref) {
  if (_widgetLaunchPath != null) return _widgetLaunchPath!;
  return '/splash';
});
```

El widget NFC envía `transitly://home/tarjeta` (verificado en `NfcBalanceWidgetProvider.kt:62`), y el deep path se construye correctamente como `/home/tarjeta`. La ruta `/home/tarjeta` SÍ existe (verificado en `app_router.dart:150`).

**Hipótesis del 404:**
- (a) `routerInitialLocationProvider` se evalúa una vez. Si el provider se lee ANTES de `setWidgetLaunchPath`, devuelve `/splash` y luego nunca se re-evalúa. Es un bug de orden.
- (b) El path `'/${launchUri.host}${launchUri.path}'` cuando `host` es null y `path` es `/home/tarjeta` produce `'//home/tarjeta'` (doble slash) → 404 en GoRouter.
- (c) En cold start, el `redirect` se ejecuta antes de que `authStateProvider` haya emitido su primer estado (queda `AsyncLoading`), y el flujo cae en un sitio inesperado.

**Causa del "no refleja saldo":** `CardTab` muestra el resultado del último escaneo (`nfcScanProvider` en `nfc_provider.dart`). Si el último escaneo fue guardado en sesión previa y NfcScanNotifier no carga del Hive al arrancar, queda vacío. Hay que verificar la implementación de `NfcScanNotifier.initState()`. Lo desarrollo en el Bug 6.

---

### Bug 6 — Saldo NFC no se guarda en cache para invitados

**Causa raíz a confirmar.** Las pistas que tengo de la auditoría:

**Lo que SÍ funciona:** `lib/data/nfc/nfc_balance_repository.dart:23-39`
```dart
Future<void> saveScan(NfcCardResult scan) async {
  ...
  await _hive.put(key, entry);  // ← guarda SIEMPRE
  WidgetDataWriter.writeNfcBalance(...);
  await _trySyncEntry(key, scan);  // ← intenta Supabase solo si user no es null
}
```
El Hive box `nfc_scans` se abre globalmente (no por usuario, verificado en `hive_init.dart:96`). Por tanto el saldo SE GUARDA aunque seas invitado.

**Lo que probablemente NO funciona:** la UI no LEE el último escaneo al arrancar. `lib/shared/providers/nfc_provider.dart` (NfcScanNotifier) probablemente mantiene `scanHistory` solo en memoria y no hidrata desde Hive en `initState()`. Por tanto al cerrar y abrir la app, el state empieza vacío y parece que el saldo se perdió.

**Para confirmar la causa exacta:** leer `nfc_provider.dart` completo y verificar si llama `_repository.getHistory()` al construirse o no.

---

### Bug 7 — Sesión se cierra al cerrar y reabrir la app (CRÍTICO)

**Causa potencial:** `lib/main.dart:71-74`
```dart
await Supabase.initialize(
  url: Env.supabaseUrl,
  anonKey: Env.supabaseAnonKey,
);
```

Por defecto `supabase_flutter 2.x` tiene `persistSession: true`. **PERO** el almacenamiento de la sesión depende de:
- El plugin `flutter_secure_storage` para tokens (debería estar en deps por transitividad).
- Que `authFlowType` sea consistente entre runs.

**Hipótesis a verificar:**
- (a) `flutter_secure_storage` no está disponible o falla silenciosamente en algunos dispositivos. En ese caso Supabase persiste a SharedPreferences (menos seguro pero funcional). Si NINGUNO funciona, la sesión NO persiste.
- (b) El token expira y el refresh falla → `signedOut` event. Esto pasaría todos los días o cada hora, no "siempre al reabrir".
- (c) Hay un `signOut()` involuntario en algún `initState` de pantalla auth. Buscar específicamente.
- (d) `_widgetBackgroundCallback` (en `main.dart:270+`) crea un `ProviderContainer` nuevo y dispara `authRepositoryProvider`, que llama `repo.init()`. **Esto NO debería cerrar sesión** pero hay que confirmar que `init()` no resetee algún flag.

**Para diagnóstico necesitamos logs reales del usuario:** al reabrir la app, ¿qué dice `AppLogger` en `Auth` y `Sentry`?

---

### Bug 8 — Snackbar "añadir línea a favoritos" mal colocado

**Causa:** `lib/features/route_detail/route_detail_screen.dart:173-179`
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(isFavorite ? favoriteRemoved : favoriteAdded),
  ),
);
```

Configuración default → SnackBar `fixed` (no floating) → se adhiere al borde inferior del Scaffold. Si la pantalla está dentro de un Stack con elementos sobrepuestos (FAB, bottom sheets parciales, navbar de fondo), queda tapada o flota mal.

Faltan al menos: `behavior: SnackBarBehavior.floating`, `margin: EdgeInsets.fromLTRB(16, 16, 16, X)` y `duration` corta.

Pista extra: `RouteDetailScreen` no tiene bottom nav propia (es una pantalla pushed), pero si se llega desde el home con el shell, el SnackBar del scope del shell tiene la navbar tapando.

---

## 3. Tareas y plan de ejecución

### Tarea A — Quick fixes UI (1 h, sin riesgo)

#### A.1 — Aumentar saludo (Bug 1)
- En `home_tab.dart:170-173`, sustituir `TransitTypography.bodySecondary(c.textMid)` por:
  ```dart
  TextStyle(
    fontFamily: 'IBM Plex Mono',
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: c.textHi,
    height: 1.2,
  )
  ```
  O mejor: añadir un nuevo token `TransitTypography.greeting()` en `transit_typography.dart` y usarlo. Justificación memoria [[feedback-design-tokens]]: nunca inline TextStyle.
- Actualizar el margen `SizedBox(height: 6)` → `12` para respirar más.

**Decisión a tomar:** ¿Token nuevo o `TransitTypography.heading` con `fontSize` override? Recomiendo **token nuevo** porque es el patrón establecido del proyecto.

#### A.2 — Quitar selector operador (Bug 2)
- En `home_tab.dart:176-200`, eliminar el `Tooltip > GestureDetector > Row` entero.
- El `SizedBox(height: 4)` previo también sobra → ajustar a un único `SizedBox(height: 16)` antes del CTA del viaje habitual.
- Opción (a) recomendada: **NO** tocar `lib/features/city_picker/` ni la ruta `/city-picker` — pueden quedar dormidos.

#### A.3 — Arreglar SnackBar favorito (Bug 8)
- En `route_detail_screen.dart:173-179`, añadir:
  ```dart
  SnackBar(
    content: Text(...),
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    duration: const Duration(seconds: 2),
    backgroundColor: c.bgRaised,
  )
  ```
- Verificar si hay más `showSnackBar(SnackBar(...))` sin floating en el proyecto. **Audit con grep + fix global recomendado.**

**Entregable:** smoke visual en el A142P. 0 cambios funcionales, solo estético.

---

### Tarea B — Habitual config sheet (1.5 h)

#### B.1 — Padding correcto debajo del nav bar (Bug 3)
Dos opciones que se pueden combinar:

**Opción 1 (mínima):** en `habitual_config_sheet.dart:26`, añadir `useSafeArea: true` a `showModalBottomSheet`. Eso ya cuenta con la safe area del sistema. Sigue sin contar la navbar de la app.

**Opción 2 (completa, recomendada):** cambiar el `padding.bottom` por:
```dart
final mq = MediaQuery.of(ctx);
final navBarHeight = 80.0; // o leerlo de un token
final bottomPadding = 24 + mq.viewInsets.bottom + mq.padding.bottom + navBarHeight;
```

Y además poner `useSafeArea: true`.

**Recomendación:** opción 2 + medir la altura real del `HomeBottomNav` (probablemente expone una constante; si no, añadirla como `static const double height = 80`).

#### B.2 — Selector de línea con búsqueda (Bug 4a)
Reemplazar el `DropdownButtonFormField` por uno de los dos patrones:
- (a) `Autocomplete<RouteModel>` con `TextEditingController` y `optionsBuilder` que filtra por `code` o `name`.
- (b) Diálogo separado con `ListView` + buscador arriba (similar a iOS / Material 3 search). Más trabajo pero mejor UX en móvil.

Con 19 líneas (a) es suficiente. Si la app crece a más operadores con cientos de líneas, refactor a (b).

**Recomendación:** (a) `Autocomplete` por simplicidad.

#### B.3 — Filtro de paradas por dirección (Bug 4b)
Modificar `mock_data_service.dart:332-341`:
```dart
List<StopModel> getStopsForRoute(String routeId, {RouteDirection? direction}) {
  final rs = routeStops[routeId];
  if (rs == null) return [];
  final filtered = direction == null
      ? rs
      : rs.where((rs) => rs.direction == direction);
  final ordered = List<RouteStopModel>.from(filtered)
    ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  return ordered
      .map((rs) => getStopById(rs.stopId))
      .whereType<StopModel>()
      .toSet()  // dedupe en caso de paradas circulares
      .toList();
}
```

Pero hay que ajustar el sheet para que el usuario elija dirección. Dos opciones:

**Opción A (rápida):** mostrar las paradas únicas (deduplicadas con `Set<String>` por stopId), ignorando dirección. Para el caso "guardar mi parada habitual" no importa el sentido — el usuario probablemente quiere "Plaza del Caballo" sin distinguir ida/vuelta.

**Opción B (correcta):** añadir un toggle "Ida / Vuelta" entre los dos dropdowns. Más complejo pero exacto.

**Recomendación:** **Opción A** — dedupe por stopId. El widget "Próximo bus" mostrará las próximas N salidas para esa parada en cualquier dirección de esa línea. Es lo que el usuario espera intuitivamente.

Tareas concretas:
- `mock_data_service.dart`: añadir `getUniqueStopsForRoute(routeId)` que deduplica.
- `habitual_config_sheet.dart:37`: usar el nuevo método.

**Entregable:** sheet visible completo, dropdown de líneas con búsqueda, dropdown de paradas sin duplicados.

---

### Tarea C — Saldo NFC (1.5 h)

#### C.1 — Diagnosticar y resolver 404 del widget (Bug 5)

Paso 1 — **medir**: añadir un log en `main.dart` antes y después de `setWidgetLaunchPath`:
```dart
AppLogger.info('Startup', 'launchUri raw: scheme=${launchUri.scheme} host=${launchUri.host} path=${launchUri.path}');
AppLogger.info('Startup', 'deepPath computed: $deepPath');
```
Y otro log en `routerInitialLocationProvider`:
```dart
AppLogger.info('Router', '_widgetLaunchPath=$_widgetLaunchPath initial=$initial');
```

Paso 2 — buildear, conectar `adb logcat` y tocar el widget NFC. Mirar los logs:
- ¿`launchUri` es null? Entonces el widget no está pasando el URI bien (problema Kotlin).
- ¿`launchUri.host` es null? Entonces el formato `transitly://home/tarjeta` no se está parseando como esperamos.
- ¿`deepPath` es `/home/tarjeta` correctamente, pero igual 404? Entonces es un problema en GoRouter (redirect o initialLocation timing).

Paso 3 — **fix probable A:** si `host` es null y `path` es `/home/tarjeta`, el `deepPath` queda `'//home/tarjeta'`. Fix:
```dart
final segments = <String>[
  if (launchUri.host?.isNotEmpty == true) launchUri.host!,
  ...launchUri.pathSegments,
];
final deepPath = '/' + segments.join('/');
```

Paso 4 — **fix probable B:** si `_widgetLaunchPath` se setea TARDE (después de que `routerProvider` ya leyó `routerInitialLocationProvider`), forzar `ref.invalidate(routerProvider)` o cambiar la lógica para leerlo dinámicamente.

#### C.2 — Hidratar último escaneo desde Hive al arrancar (Bug 6)

Leer `lib/shared/providers/nfc_provider.dart` completo (mi auditoría no lo terminó, solo confirmé el repo). Si `NfcScanNotifier` no llama `repository.getHistory()` al construirse:

```dart
class NfcScanNotifier extends StateNotifier<NfcScanState> {
  NfcScanNotifier(this._repository) : super(NfcScanState.idle()) {
    _hydrateFromCache();  // ← NUEVO
  }

  Future<void> _hydrateFromCache() async {
    final history = _repository.getHistory();
    if (history.isNotEmpty) {
      state = NfcScanState.success(history.first, history);
    }
  }
}
```

Esto resuelve "saldo no se ve al reabrir como invitado".

#### C.3 — Test manual end-to-end
- Como invitado: escanear NFC → ver saldo → cerrar app → reabrir → debe verse el mismo saldo.
- Como invitado: tocar widget NFC → debe abrir `/home/tarjeta` con el último saldo visible.

---

### Tarea D — Sesión se cierra al reabrir (Bug 7 — CRÍTICO) (2 h)

#### D.1 — Recolectar evidencia
Esta es la única tarea donde necesito información del usuario antes de implementar fix:

- (a) ¿La sesión se cierra **cada vez** que reabres, o solo a veces?
- (b) ¿Usas Google Sign-In o email/password?
- (c) Reproducir y mirar `adb logcat | grep -E "Auth|Sentry|Supabase"` durante el reinicio.

Mientras esperamos esos logs, **acciones preventivas** posibles:

#### D.2 — Forzar persistencia explícita
En `main.dart:71`, cambiar:
```dart
await Supabase.initialize(
  url: Env.supabaseUrl,
  anonKey: Env.supabaseAnonKey,
);
```
por:
```dart
await Supabase.initialize(
  url: Env.supabaseUrl,
  anonKey: Env.supabaseAnonKey,
  authOptions: const FlutterAuthClientOptions(
    authFlowType: AuthFlowType.pkce,
    autoRefreshToken: true,
  ),
);
```

PKCE es el flow recomendado y `autoRefreshToken: true` es el default, pero explicitarlo cierra una posible fuente de inconsistencia.

#### D.3 — Verificar que `_widgetBackgroundCallback` no rompe sesión
En `main.dart:270+`, el callback crea un `ProviderContainer` nuevo. Si por error lee `authRepositoryProvider` y dispara `init()` con un client nuevo, podría desincronizar tokens. **Acción:** auditar el callback y asegurarse de que SOLO lee providers de mockData/widgets, nada de auth ni Supabase REST.

#### D.4 — Añadir logs detallados
```dart
AppLogger.info('Startup', 'currentSession exists=${session != null} userId=${session?.user.id?.substring(0,8) ?? "null"}');
AppLogger.info('Startup', 'accessToken expires at ${session?.expiresAt}');
```

Si el accessToken está vencido y el refresh falla en silencio, vemos exactamente cuándo.

#### D.5 — Test manual
- Login con email → cerrar app (no logout) → reabrir → debe seguir autenticado.
- Login con Google → cerrar app → reabrir → debe seguir autenticado.
- Esperar 1 h (token expira) → reabrir → debe refrescar y seguir autenticado.

---

## 4. Archivos a modificar (resumen)

### Cambios en Dart
- `lib/features/home/tabs/home_tab.dart` (saludo + quitar operator picker)
- `lib/features/home/widgets/habitual_config_sheet.dart` (padding + Autocomplete + dedupe)
- `lib/features/route_detail/route_detail_screen.dart` (SnackBar floating)
- `lib/core/theme/transit_typography.dart` (nuevo token `greeting()`)
- `lib/data/mock/mock_data_service.dart` (`getUniqueStopsForRoute`)
- `lib/shared/providers/nfc_provider.dart` (hidratar desde Hive en construct)
- `lib/main.dart` (logs + opciones Supabase explícitas + fix deep path)
- `lib/core/router/app_router.dart` (logs en `routerInitialLocationProvider`)

### Sin tocar
- Layer Android nativo (los widgets ya funcionan estructuralmente)
- AndroidManifest
- Providers Kotlin de widget
- Layer de auth Supabase (excepto opciones de init)

### Quizá tocar (depende de diagnóstico)
- `lib/data/auth/auth_repository_supabase.dart` (si encontramos el signOut involuntario)
- `lib/features/city_picker/...` (solo si opción B del Bug 2 — no recomendada)

---

## 5. Estimación de tiempo

| Tarea | Tiempo | Acumulado | Prioridad |
|-------|--------|-----------|-----------|
| A — Quick fixes UI (1, 2, 8) | 1 h | 1 h | Baja |
| B — Habitual config sheet (3, 4) | 1.5 h | 2.5 h | Media |
| C — Saldo NFC (5, 6) | 1.5 h | 4 h | Media |
| D — Sesión (7) | 2 h | 6 h | **Alta** (bloquea uso) |
| **Total** | **~6 h** | | 1 sesión larga o 2 cortas |

---

## 6. Orden recomendado

1. **Tarea D primero** porque es lo único que rompe el flujo normal del usuario. Pero antes de implementar fix, **necesito que me digas:**
   - Pasa siempre o solo a veces?
   - Usuario con Google o email/password?
   - Si puedes, un `adb logcat -d | grep -i "auth\|supabase"` después de reproducir.

   Si no quieres dar logs, aplico D.2-D.4 a ciegas (mitigaciones preventivas) y veremos en el siguiente test si se arregló.

2. **Tarea C** porque también afecta funcionalidad (el widget NFC no es usable hasta resolverla).

3. **Tarea B** porque mejora dramáticamente el flujo principal del home.

4. **Tarea A** al final, fixes estéticos.

---

## 7. Decisiones a confirmar antes de empezar

| # | Decisión | Recomendación |
|---|----------|----------------|
| D1 | Token nuevo `greeting()` o `heading` con override | **Token nuevo** (sigue convención del proyecto) |
| D2 | Eliminar también ruta /city-picker o solo el botón | **Solo el botón** (cero riesgo) |
| D3 | Selector línea: Autocomplete inline o dialog separado | **Autocomplete** (19 líneas son pocas) |
| D4 | Paradas: dedupe ignorando dirección o toggle ida/vuelta | **Dedupe** (es lo que el usuario espera) |
| D5 | SnackBar floating en ESTE caso o en TODA la app | **En toda la app** (audit global rápido + fix) |
| D6 | Fix Bug 7 con diagnóstico previo o mitigaciones preventivas a ciegas | **Diagnóstico previo si puedes dar logs**; si no, mitigaciones |

---

## 8. Riesgos identificados

- **R1: Cambiar `padding.bottom` del sheet puede romper en landscape o iPad.** Verificar en al menos un emulador de tablet.
- **R2: Autocomplete con 19 items podría tener scroll molesto en pantalla pequeña.** Mitigación: limitar altura del dropdown a `200dp` con `maxOptionsHeight`.
- **R3: Dedupe de paradas puede ocultar paradas reales con mismo nombre (en otras líneas).** En realidad el dedupe es solo dentro de UNA ruta; si dos rutas tienen "Plaza" como nombre, ambas aparecerán cuando se elija cada ruta por separado. Cero riesgo en este caso.
- **R4: `Supabase.initialize` con `authOptions` puede comportarse distinto en runs previos** (PKCE vs implicit). Mitigación: probar tras reinstalar la app (clear data).
- **R5: Hidratar desde Hive al construir el provider puede tardar y mostrar saldo viejo unos ms.** Mitigación: badge "actualizado: hace X" o spinner si todavía hidratando.
- **R6: Logs extra suben tamaño de logcat.** Solo en debug, irrelevante en release.

---

## 9. Criterios de aceptación (smoke test final)

1. **Saludo grande:** se ve a unos 22 sp, no eclipsa el título "TRANSITLY".
2. **Sin "Jerez de la Frontera"** en el home; el header tiene solo título + saludo.
3. **Sheet habitual visible al 100%:** botón "Guardar" se ve por encima de la navbar y de la safe area.
4. **Buscar línea:** escribir "L1" en el campo línea filtra solo las que empiezan por L1.
5. **Paradas sin duplicados** al elegir una línea (ej. L8 muestra las paradas únicas, no dos veces "Plaza del Caballo").
6. **Widget NFC click cold start:** cerrar app, tocar widget → abre directamente `/home/tarjeta` sin 404.
7. **Saldo NFC persistente invitado:** escanear como invitado → cerrar app → reabrir → saldo sigue visible.
8. **Sesión persistente:** login → cerrar app → reabrir → sigue autenticado (caso a confirmar con logs).
9. **SnackBar favorito flotante:** marcar línea como favorita desde detalle → snackbar visible 2s con margen, no tapado por nada.

---

## 10. Próximos pasos

Cuando apruebes:

- **"arranca tarea D"** → primero la crítica (sesión). Empiezo pidiéndote los logs.
- **"arranca A + B"** → fixes visuales primero (rápido, baja-riesgo).
- **"arranca todo en orden"** → D → C → B → A en una sola sesión larga (~6 h).

Si quieres modificar alguna decisión (D1-D6) o pedirme que profundice en algún punto antes de codear, dímelo.

---

## Changelog

- **2026-06-02** — Plan inicial creado tras auditoría. 8 bugs identificados con `archivo:línea` exactos. 6 decisiones a confirmar. Tareas A/B/C/D agrupadas por dominio.
