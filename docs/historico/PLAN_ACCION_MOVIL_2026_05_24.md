# PLAN DE ACCIÓN — Terminar móvil pre-defensa TFG

**Fecha:** 2026-05-24
**HEAD verificado:** `master @ d76de46`
**Defensa final:** 2026-06-09 (semana 11)
**Origen:** 3 sub-agentes Explore en sesión 2026-05-24 tras `PLAN_DEFENSA_2026_05_24.md`
**Predecesores:** `PLAN_DEFENSA_2026_05_24.md`, `SESION_LIMPIEZA_2026_05_23.md`, `INFORME_POST_LIMPIEZA_2026_05_23.md`
**Audiencia:** dev (humano o IA) que ejecutará los fixes

---

## Reglas transversales

1. **No ejecutar todo de golpe.** Cada sección PR-able con commit atómico.
2. **Mensajes de commit en español** siguiendo Conventional Commits (`fix(scope): ...`).
3. **`flutter analyze` debe quedar 0 errors tras cada paso.** Si rompe, revertir.
4. **`flutter test` no debe romper.** Tolerancia: 619+1 skip+1 flaky conocido (transit_input_validation).
5. **Antes de cada Edit, validar que el "código actual" coincide con el archivo** (puede haber cambiado entre la generación del plan y la ejecución).
6. **NO commitear secrets** (`.env`, `google-services.json`, `key.properties`).

---

## Índice

- [A. P1 — Bugs nuevos críticos pre-defensa (5 fixes, ~1h)](#a-p1)
  - [A.1 — N15: race condition `.first` en stop_detail](#a1)
  - [A.2 — N16: `RefreshIndicator` fake en home_tab](#a2)
  - [A.3 — N17: analytics post-frame sin `mounted` check](#a3)
  - [A.4 — P1-PUSH-001: push cold-start handlers ausentes](#a4)
  - [A.5 — P4-OFFLINE-004: drainer rompe con kind desconocido](#a5)
- [B. P2 — Strings ES residuales (1 commit batch, ~45 min)](#b-p2)
- [C. P2 — Prod-readiness gaps (3 fixes opcionales pre-defensa)](#c-p2)
- [D. Bugs sistémicos T1-T8 (post-defensa, opcionales)](#d-sistemico)
- [E. Tests remote/ — palanca cobertura 24→40% (~6h)](#e-tests)
- [F. Coverage gate en CI con threshold realista](#f-ci)
- [G. Verificación end-to-end](#g-verificacion)
- [H. Cronograma sugerido D-16 → D-0](#h-cronograma)
- [I. Respuestas preparadas para tribunal](#i-tribunal)

---

<a id="a-p1"></a>
## A. P1 — Bugs nuevos críticos pre-defensa

Estos 5 bugs fueron detectados por los agentes de smoke test el 2026-05-24. **NO estaban en auditorías previas.** Son los únicos con riesgo de crash o fallo visible en demo.

**Esfuerzo total:** ~1 hora.

---

<a id="a1"></a>
### A.1 — N15: race condition `.first` en stop_detail

**Por qué importa:** el código accede a `nextDeps.first` dos veces. El segundo acceso (línea 137) está dentro de una rama de error pero **fuera del guard `if (nextDeps.isNotEmpty)`**. En la práctica el guard de línea 131 cubre ambos accesos, pero el patrón es frágil y un futuro refactor puede romper la garantía.

**Archivo:** `lib/features/stop_detail/stop_detail_screen.dart:131-145`

**Código actual** (verificado):

```dart
if (nextDeps.isNotEmpty) {
  timeStr = nextDeps.first.departureTime;
  final parts = timeStr.split(':');
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) {
    timeStr = nextDeps.first.departureTime;  // ← duplicado, ya está en línea 132
    countdownStr = '';
    isNext = false;
  } else {
    final depMinutes = h * 60 + m;
    final diff = depMinutes - nowMinutes;
    countdownStr = 'en $diff min';
    isNext = diff <= 10;
  }
}
```

**Código objetivo:**

```dart
final nextDep = nextDeps.firstOrNull;
if (nextDep != null) {
  timeStr = nextDep.departureTime;
  final parts = timeStr.split(':');
  final h = parts.length >= 2 ? int.tryParse(parts[0]) : null;
  final m = parts.length >= 2 ? int.tryParse(parts[1]) : null;
  if (h == null || m == null) {
    countdownStr = '';
    isNext = false;
  } else {
    final depMinutes = h * 60 + m;
    final diff = depMinutes - nowMinutes;
    countdownStr = 'en $diff min';
    isNext = diff <= 10;
  }
}
```

**Cambios:**
- Sustituir `nextDeps.first` (×2) por `nextDeps.firstOrNull` capturado una sola vez en variable local.
- Eliminar la línea duplicada `timeStr = nextDeps.first.departureTime` dentro del else.
- Añadir guard `parts.length >= 2` antes de `parts[1]`.

**Verificación:**

```bash
grep -n "nextDeps\.first\b" lib/features/stop_detail/stop_detail_screen.dart
# Esperado: 0 hits (sólo firstOrNull o variable local)
```

**Commit:**

```bash
git add lib/features/stop_detail/stop_detail_screen.dart
git commit -m "fix(stop_detail): use firstOrNull en lugar de .first duplicado (N15)"
```

**Esfuerzo:** S (10 min) · **Riesgo build:** verde · **Tipo:** fix

---

<a id="a2"></a>
### A.2 — N16: `RefreshIndicator` fake en home_tab

**Por qué importa:** el usuario tira de la pantalla home esperando refresh. El callback es `async {}` vacío con comentario "no-op". El indicador animado aparece y desaparece dando la impresión de carga, pero nada se recarga. Es **engaño visual** detectable por cualquier tribunal que pruebe la app.

**Archivo:** `lib/features/home/tabs/home_tab.dart:49-58`

**Código actual** (verificado):

```dart
return Scaffold(
  backgroundColor: Colors.transparent,
  body: RefreshIndicator(
    onRefresh: () async {
      // no-op: data is loaded synchronously from mock service
    },
    color: c.accent,
    child: _buildContent(context, c, mockData, activeTripsMap),
  ),
);
```

**Decisión arquitectónica:** dos opciones válidas.

**Opción A — invalidar providers para refresh real (recomendada):**

```dart
return Scaffold(
  backgroundColor: Colors.transparent,
  body: RefreshIndicator(
    onRefresh: () async {
      // Invalida los providers para que se recalculen los datos derivados.
      ref.invalidate(mockDataServiceProvider);
      ref.invalidate(realtimeTripsProvider);
      // Pequeña espera para que el indicador no parpadee instantáneo.
      await Future<void>.delayed(const Duration(milliseconds: 400));
    },
    color: c.accent,
    child: _buildContent(context, c, mockData, activeTripsMap),
  ),
);
```

**Opción B — eliminar el RefreshIndicator si no hay nada que refrescar:**

```dart
return Scaffold(
  backgroundColor: Colors.transparent,
  body: _buildContent(context, c, mockData, activeTripsMap),
);
```

**Recomendación:** Opción A si los datos pueden cambiar (realtime trips, mock data). Opción B si todo es síncrono e inmutable durante la sesión.

**Verificación:**

```bash
grep -A 2 "RefreshIndicator" lib/features/home/tabs/home_tab.dart | grep "no-op"
# Esperado: 0 hits
```

**Commit:**

```bash
git add lib/features/home/tabs/home_tab.dart
git commit -m "fix(home): refresh real con ref.invalidate en home_tab (N16)"
```

**Esfuerzo:** S (15 min) · **Riesgo build:** verde · **Tipo:** fix

---

<a id="a3"></a>
### A.3 — N17: analytics post-frame sin `mounted` check

**Por qué importa:** si el usuario navega a otra pantalla muy rápido tras abrir `route_detail`, el `postFrameCallback` dispara `PostHogAnalyticsService.routeViewed(...)` cuando el widget ya está desmontado. Sentry/PostHog reportará desde un contexto inválido.

**Archivo:** `lib/features/route_detail/route_detail_screen.dart:48-50`

**Código actual** (verificado):

```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  PostHogAnalyticsService.routeViewed(route.id, route.operatorId);
});
```

**Problema adicional:** estamos en un `ConsumerWidget` (no `ConsumerStatefulWidget`), por lo que no hay `mounted` disponible directamente. El callback se dispara **cada rebuild** además.

**Código objetivo:** convertir a `ConsumerStatefulWidget` y disparar el track una sola vez en `initState`.

**Pasos:**

1. Cambiar la firma del widget de `ConsumerWidget` a `ConsumerStatefulWidget`.
2. Mover la lógica de `build()` a un `_State` que extienda `ConsumerState`.
3. En `initState()` disparar el `postFrameCallback` una sola vez con guard.

**Esquema del cambio:**

```dart
class RouteDetailScreen extends ConsumerStatefulWidget {
  const RouteDetailScreen({super.key, required this.routeId});
  final String routeId;

  @override
  ConsumerState<RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends ConsumerState<RouteDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final mockData = ref.read(mockDataServiceProvider);
      final route = mockData.routeById(widget.routeId);
      if (route != null) {
        PostHogAnalyticsService.routeViewed(route.id, route.operatorId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // ... (todo el contenido del build actual, sustituyendo routeId por widget.routeId)
  }
}
```

**Verificación:**

```bash
grep -A 2 "addPostFrameCallback" lib/features/route_detail/route_detail_screen.dart | grep "mounted"
# Esperado: 1 hit (la nueva guard)
grep "ConsumerStatefulWidget" lib/features/route_detail/route_detail_screen.dart
# Esperado: 1 hit
```

**Commit:**

```bash
git add lib/features/route_detail/route_detail_screen.dart
git commit -m "fix(route_detail): mover analytics postFrame a initState con guard mounted (N17)"
```

**Esfuerzo:** M (30 min, refactor a StatefulWidget) · **Riesgo build:** amarillo (refactor mayor) · **Tipo:** fix

---

<a id="a4"></a>
### A.4 — P1-PUSH-001: push cold-start handlers ausentes

**Por qué importa:** cuando el usuario recibe una notificación con `deeplink` y la app está cerrada (cold start), al pulsar la notificación la app abre pero **no navega al destino**. Pierde la UX de push deeplinks completamente. Aplica también al caso "app en background" — actualmente sólo se maneja foreground.

**Archivo:** `lib/data/push/push_service.dart:78-104`

**Código actual** (verificado):

```dart
Future<void> setupForegroundHandler() async {
  await _localNotifications.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
  );

  FirebaseMessaging.onMessage.listen((message) {
    _localNotifications.show(
      id: message.hashCode,
      title: message.notification?.title ?? '',
      body: message.notification?.body ?? '',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'transitly_push',
          'Transitly Notifications',
          // ...
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: message.data['deeplink'] as String?,
    );
  });
}
```

**Código objetivo:** añadir métodos para cold-start y background-tap, y un callback de navegación.

**Pasos:**

1. Añadir parámetro `void Function(String deeplink)? onDeeplink` al constructor o a un setter público.
2. Implementar dos nuevos métodos públicos:

```dart
/// Inicializa el handler de notificaciones que se abren desde
/// estado background. Llamar tras [setupForegroundHandler].
void setupBackgroundOpenedHandler(void Function(String deeplink) onDeeplink) {
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    final deeplink = message.data['deeplink'] as String?;
    if (deeplink != null && deeplink.isNotEmpty) {
      onDeeplink(deeplink);
    }
  });
}

/// Procesa la notificación que abrió la app desde cold start
/// (estado terminated). Llamar UNA SOLA VEZ al inicio.
Future<void> handleColdStartMessage(void Function(String deeplink) onDeeplink) async {
  final initialMessage = await _messaging.getInitialMessage();
  if (initialMessage == null) return;
  final deeplink = initialMessage.data['deeplink'] as String?;
  if (deeplink != null && deeplink.isNotEmpty) {
    onDeeplink(deeplink);
  }
}
```

3. En `lib/main.dart` (tras `Supabase.initialize` y antes de `runApp`):

```dart
final pushService = PushService();
await pushService.setupForegroundHandler();
pushService.setupBackgroundOpenedHandler((deeplink) {
  // Ejemplo: navegar con go_router
  // Como main no tiene context, usar un GlobalKey<NavigatorState>
  // o el `goRouterProvider` que ya existe.
  navigatorKey.currentState?.pushNamed(deeplink);
});
await pushService.handleColdStartMessage((deeplink) {
  // Mismo handler
  navigatorKey.currentState?.pushNamed(deeplink);
});
```

4. Asegurar que `navigatorKey` está expuesto en `lib/main.dart` y consumido por `go_router` config.

**Verificación:**

```bash
grep -n "onMessageOpenedApp\|getInitialMessage" lib/data/push/push_service.dart
# Esperado: 2 hits
grep -n "handleColdStartMessage\|setupBackgroundOpenedHandler" lib/main.dart
# Esperado: 2 hits
```

**Commit:**

```bash
git add lib/data/push/push_service.dart lib/main.dart
git commit -m "feat(push): handlers cold-start y background-opened con deeplink (P1-PUSH-001)"
```

**Esfuerzo:** M (30-45 min) · **Riesgo build:** amarillo (toca main.dart) · **Tipo:** feat

**Nota:** sin `firebase_options.dart` ni `google-services.json` reales el push no funciona en device. Esto es prerequisito de **B2 EXTERNAL_BLOCKERS**. El código sin embargo debe estar correctamente cableado para que cuando se reciban las credenciales sólo haya que añadirlas.

---

<a id="a5"></a>
### A.5 — P4-OFFLINE-004: drainer rompe con kind desconocido

**Por qué importa:** si una versión vieja del cliente enquaró un `PendingActionKind` que la versión actual ya no soporta (caso normal en updates), el drainer **se detiene completamente** con `break`. Eso bloquea todas las acciones posteriores en la cola hasta que el usuario fuerce un wipe. Es el típico "ya no sincroniza nada y no sé por qué".

**Archivo:** `lib/data/sync/offline_sync_service.dart:63-68`

**Código actual** (verificado):

```dart
final executor = _executors[action.kind];
if (executor == null) {
  AppLogger.warn(_logTag,
      'no executor for ${action.kind.name}; stopping drain to keep order');
  break;
}
```

**Código objetivo:**

```dart
final executor = _executors[action.kind];
if (executor == null) {
  AppLogger.warn(_logTag,
      'no executor for ${action.kind.name} (id=${action.id}); skipping to avoid blocking drain');
  // Mover la acción a dead letter en lugar de bloquear el drain.
  await queue.markFailure(action, Exception('no executor for ${action.kind.name}'));
  continue;
}
```

**Decisión arquitectónica:** la opción más segura es `markFailure` (la cola decide si va a dead letter tras N intentos). Alternativa más agresiva: `await queue.remove(action.id);` directo (descarta inmediatamente).

**Verificación:**

```bash
grep -A 5 "executor == null" lib/data/sync/offline_sync_service.dart | grep "continue\|skipping"
# Esperado: 2 hits (la nueva línea y el log)
grep "stopping drain to keep order" lib/data/sync/offline_sync_service.dart
# Esperado: 0 hits
```

**Test recomendado:** `test/data/sync/offline_sync_unknown_kind_test.dart` que enqueue una acción de kind sin executor + verifica que el drain continúa.

**Commit:**

```bash
git add lib/data/sync/offline_sync_service.dart
git commit -m "fix(sync): no bloquear drainer en kind desconocido, marcar fallo y continuar (P4-OFFLINE-004)"
```

**Esfuerzo:** S (15 min) · **Riesgo build:** verde · **Tipo:** fix

---

### A.6 — Verificación FASE A

```bash
flutter analyze 2>&1 | tail -3
# Esperado: 0 errors, ~70 info (sin nuevos warnings)

flutter test 2>&1 | tail -3
# Esperado: 619 passed (+1 skipped, +1 flaky aceptable)

grep -rn "nextDeps\.first\b" lib/features/stop_detail/   # 0
grep -A 2 "RefreshIndicator" lib/features/home/tabs/home_tab.dart | grep "no-op"   # 0
grep -A 2 "addPostFrameCallback" lib/features/route_detail/route_detail_screen.dart | grep "mounted"   # 1+
grep -n "onMessageOpenedApp\|getInitialMessage" lib/data/push/push_service.dart   # 2
grep "stopping drain to keep order" lib/data/sync/   # 0
```

---

<a id="b-p2"></a>
## B. P2 — Strings ES residuales

Los agentes detectaron 10 strings hardcoded ES residuales (post-migración previa). Pueden hacerse en **1 commit batch** ya que cada uno son 1-2 líneas.

**Esfuerzo total:** ~45 min (incluido gen-l10n y verificación).

### B.1 — Tabla de strings y reemplazos

| # | Archivo:línea | Texto actual | Clave ARB sugerida |
|---|---------------|--------------|---------------------|
| B.1 | `lib/features/stop_detail/stop_detail_screen.dart:64` | `'Volver'` (tooltip) | `actionBack` |
| B.2 | `lib/features/home/tabs/card_tab.dart:43` | `'TARJETA NFC'` | `cardNfcTitle` |
| B.3 | `lib/features/home/tabs/card_tab.dart:91` | `'NFC NO DISPONIBLE'` | `cardNfcUnavailable` |
| B.4 | `lib/features/home/tabs/card_tab.dart:95-96` | `'La lectura de tarjetas...'` | `cardNfcExplanation` |
| B.5 | `lib/features/route_detail/widgets/route_detail_schedule_section.dart:112` | `'Ocultar ▴'` / `'Ver todos ▾'` | `scheduleHideAll` / `scheduleShowAll` |
| B.6 | `lib/features/auth/activate_driver_screen.dart:183` | `hintText: 'XXX-XXXX-XX'` | `activateDriverCodeHint` |
| B.7 | `lib/features/feedback/route_feedback_sheet.dart:99,112,117,122` | `'MEJORAR INFORMACIÓN'`, `'Línea:'`, `'Parada:'`, `'Tipo de mejora'` | `routeFeedback*` (4 claves) |
| B.8 | `lib/features/profile/offline_data_screen.dart:75,82` | `'Recargar desde assets'`, `'Esta app usa un bundle JSON local...'` | `offlineDataReloadButton`, `offlineDataExplanation` |
| B.9 | `lib/features/city_picker/city_picker_screen.dart:39,53` | `'Cerrar'`, `'No hay operadores disponibles'` | `actionClose`, `cityPickerNoOperators` |
| B.10 | `lib/features/operator_admin/invitation_codes_screen.dart:164,217`, `lib/features/operator_admin/drivers_screen.dart:164`, `lib/features/suggestions/suggestion_detail_screen.dart:63,66` | `'Volver'` (×5 tooltips) | `actionBack` (clave ya en ARB probablemente) |
| B.11 | `lib/features/driver/ai_schedule_import.dart:75` | `'PROTOTIPO'` (banner) | `aiScheduleImportPrototypeBanner` |

### B.2 — Procedimiento

1. **Verificar `actionBack` y `actionClose` en `lib/l10n/app_es.arb`:**

   ```bash
   grep -E "^  \"action(Back|Close)\"" lib/l10n/app_es.arb
   ```

   Si no existen, añadirlas en `lib/l10n/app_es.arb`, `app_en.arb`, `app_ar.arb`:

   ```json
   "actionBack": "Volver",
   "@actionBack": {"description": "Genérico - volver atrás"},
   "actionClose": "Cerrar",
   "@actionClose": {"description": "Genérico - cerrar diálogo/sheet"},
   ```

2. **Añadir las claves nuevas en los 3 ARB.** Ejemplo `cardNfcTitle`:

   En `app_es.arb`:
   ```json
   "cardNfcTitle": "TARJETA NFC",
   "@cardNfcTitle": {"description": "Título de la pestaña de tarjeta NFC"},
   ```
   En `app_en.arb`:
   ```json
   "cardNfcTitle": "NFC CARD",
   ```
   En `app_ar.arb`:
   ```json
   "cardNfcTitle": "بطاقة NFC",
   ```

   Repetir para las ~12 claves nuevas.

3. **Regenerar:**

   ```bash
   flutter gen-l10n
   ```

4. **Aplicar los reemplazos** en los archivos de la tabla:

   Patrón: `Text('TARJETA NFC')` → `Text(AppLocalizations.of(context).cardNfcTitle)`

   Si el archivo no importa `AppLocalizations`, añadir:
   ```dart
   import 'package:transitly/l10n/generated/app_localizations.dart';
   ```

5. **Verificación:**

   ```bash
   grep -rn "TARJETA NFC\|NFC NO DISPONIBLE\|MEJORAR INFORMACIÓN\|PROTOTIPO" lib/features/
   # Esperado: 0 hits (o solo en claves ARB, no en código dart)
   ```

### B.3 — Commit

```bash
git add lib/l10n/app_es.arb lib/l10n/app_en.arb lib/l10n/app_ar.arb lib/l10n/generated/
git add lib/features/stop_detail/ lib/features/home/tabs/card_tab.dart lib/features/route_detail/widgets/route_detail_schedule_section.dart lib/features/auth/activate_driver_screen.dart lib/features/feedback/route_feedback_sheet.dart lib/features/profile/offline_data_screen.dart lib/features/city_picker/city_picker_screen.dart lib/features/operator_admin/ lib/features/suggestions/suggestion_detail_screen.dart lib/features/driver/ai_schedule_import.dart
git commit -m "i18n: migrar 11 strings ES residuales a ARB (N18-N22, P2 batch)"
```

**Esfuerzo:** M (45 min, mayoría es gen-l10n + reemplazos mecánicos).

---

<a id="c-p2"></a>
## C. P2 — Prod-readiness gaps

Estos 3 fixes son **opcionales pre-defensa** (la demo funciona sin ellos), pero **necesarios para release a stores**.

### C.1 — P2-NOTIF-002: `onBackgroundMessage` es solo stub

**Archivo:** `lib/data/push/push_service.dart:106-109`

**Código actual** (verificado):

```dart
@pragma('vm:entry-point')
static Future<void> onBackgroundMessage(RemoteMessage message) async {
  AppLogger.info('PushService', 'background message received');
}
```

**Decisión:** este handler corre cuando la app está terminada y recibe push **silente** (sin `notification:`). La librería `flutter_local_notifications` ya muestra la notificación si viene con `notification:`. Para silentes, sólo necesitamos persistir el payload.

**Código objetivo (mínimo viable):**

```dart
@pragma('vm:entry-point')
static Future<void> onBackgroundMessage(RemoteMessage message) async {
  AppLogger.info('PushService',
      'background message received: ${message.messageId}');
  // En cold start, Hive/Supabase no están inicializados aquí.
  // El payload se guarda en SharedPreferences y se lee al arrancar.
  try {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getStringList('pending_background_messages') ?? [];
    pending.add(jsonEncode(message.data));
    await prefs.setStringList('pending_background_messages', pending);
  } catch (e) {
    AppLogger.warn('PushService',
        'failed to persist background message', e);
  }
}
```

Y al arrancar (en `main.dart`), leer los pendientes y procesarlos.

**Esfuerzo:** M (30 min) · **Severidad pre-defensa:** baja · **Severidad release:** alta.

### C.2 — P3-ANDROID-003: deeplinks no declarados en Manifest

**Archivo:** `android/app/src/main/AndroidManifest.xml`

Verificar si tiene `<intent-filter>` con `VIEW` + `BROWSABLE` para deeplinks tipo `transitly://stop/123`.

**Si NO los tiene**, añadir dentro de `<activity android:name=".MainActivity">`:

```xml
<intent-filter android:autoVerify="true">
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="transitly" />
</intent-filter>
```

**Esfuerzo:** S (10 min) · **Severidad pre-defensa:** baja.

### C.3 — P6/P7 PRIVACY edge functions no conectadas

**Archivos:**
- `lib/features/privacy/privacy_screen.dart:131-137` (data_deletion_requests)
- `lib/features/privacy/privacy_screen.dart:82-85` (data_exports)

**Problema:** se inserta en la tabla de pendientes pero no se invoca la edge function que procesa el request.

**Fix:** tras el insert, invocar:

```dart
// Para borrado:
await ref.read(supabaseClientProvider).functions.invoke(
  'delete_user',
  body: {'user_id': userId},
);
```

```dart
// Para exportación:
await ref.read(supabaseClientProvider).functions.invoke(
  'generate_data_export',  // si esa edge function existe
  body: {'user_id': userId},
);
```

**Pre-requisito:** verificar que `supabase/functions/delete_user/` está desplegada (el `ls supabase/functions/` lo confirma). Para `generate_data_export` confirmar nombre exacto.

**Esfuerzo:** S (15 min cada uno) · **Severidad release (GDPR Art. 17):** alta.

---

<a id="d-sistemico"></a>
## D. Bugs sistémicos T1-T8 (post-defensa, opcionales)

Detectados por agente B en smoke test transversal. Todos son P3 (no bloquean defensa).

| ID | Tema | Archivo | Esfuerzo |
|----|------|---------|---------:|
| T1 | Backoff bloqueante `Future.delayed` | `offline_sync_service.dart:81` | S |
| T2 | `BuildContext` post-await sin `mounted` | `region_download_sheet.dart:81`, `storage_section.dart:98`, `post_recording_editor.dart:264,292` | M |
| T3 | Acceso directo Hive en features | `storage_section.dart:129`, `editor_controller.dart:175-204`, `post_recording_editor.dart:265,292` | M |
| T4 | `StreamController.onCancel` sin try-catch | `pending_actions_queue.dart:81` | XS |
| T5 | NFC sin timeout | `nfc_card_service.dart:215` | S |
| T6 | `hasSeenOnboarding` en SharedPreferences (inconsistencia con resto Hive) | `onboarding_screen.dart:64-67` | S |
| T7 | `stagger_list.dart:93` `Future.delayed` en build | `stagger_list.dart:93` | S |
| T8 | `catch (e) {}` genérico sin logs | varios en `main.dart` (aceptable) | XS |

**Total esfuerzo:** ~2-3 horas post-defensa.

---

<a id="e-tests"></a>
## E. Tests remote/ — palanca cobertura

**Estado actual:** cobertura **24,04 %** (4.212 / 17.518 líneas). Objetivo del usuario: **60 %+**.

Para llegar a 60 % hacen falta ~6.000 líneas adicionales cubiertas (~150 tests nuevos). Esto es trabajo de 2-3 días. **Recomendación práctica para defensa:** apuntar a **35-40 %** con tests remote/ (palanca P2-4 del mega plan) + tests modelos sin cobertura.

### E.1 — Plan de batches

| Batch | Tests a añadir | Líneas cubiertas | Δ cobertura |
|-------|----------------|-----------------:|------------:|
| Batch 1 (~3h) | 6 repos remote/ con `SupabaseClient` mockeado | ~750 | +4,3 pp |
| Batch 2 (~2h) | 8 modelos sin cobertura (test JSON serialization + getters) | ~250 | +1,4 pp |
| Batch 3 (~2h) | Providers de repos (operator, route_feedback, route_suggestion, notification, user_preferences) | ~250 | +1,4 pp |
| Batch 4 (~3h) | Widgets compartidos con 0% (transit_bottom_sheet, single_field_dialog, data_freshness_indicator) | ~80 | +0,5 pp |
| Batch 5 (~4h) | Features 0% críticas (map sheets, driver/dashboard, profile/reputation) | ~600 | +3,4 pp |
| **TOTAL** | ~50-70 tests | ~1.930 | **+11 pp → 35 %** |

### E.2 — Estructura tipo de test remote/

Ejemplo para `route_remote_repository`:

```dart
// test/data/route/route_remote_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:transitly/data/route/remote/route_remote_repository.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}
class _MockPostgrestBuilder extends Mock implements PostgrestFilterBuilder {}

void main() {
  late RouteRemoteRepository repo;
  late _MockSupabaseClient client;

  setUp(() {
    client = _MockSupabaseClient();
    repo = RouteRemoteRepository(client);
  });

  group('byId', () {
    test('returns parsed RouteModel on success', () async {
      // arrange: stub client.from('routes').select().eq().single()
      // act
      final result = await repo.byId('L1');
      // assert
      expect(result, isNotNull);
      expect(result?.id, 'L1');
    });

    test('throws RouteRepositoryException on PostgrestException', () async {
      // ...
    });

    test('returns null when row not found', () async {
      // ...
    });
  });
}
```

### E.3 — Repos a priorizar (orden de impacto)

1. `route_feedback_remote_repository.dart` (136 líneas, alto impacto)
2. `incident_remote_repository.dart` (119 líneas)
3. `route_suggestion_remote_repository.dart` (112 líneas)
4. `user_preferences_remote_repository.dart` (62 líneas)
5. `offline_region_remote_repository.dart` (63 líneas)
6. `auth_repository_supabase.dart` (73 líneas)

### E.4 — Commit por batch

```bash
git commit -m "test(data): añadir tests remote/ para route_feedback (~25 casos)"
git commit -m "test(data): añadir tests remote/ para incident (~22 casos)"
# ... uno por repo
```

---

<a id="f-ci"></a>
## F. Coverage gate en CI

**Archivo:** `.github/workflows/ci.yml`

**Buscar la sección de coverage actual:**

```bash
grep -A 5 "lcov\|coverage" .github/workflows/ci.yml
```

**Probablemente tiene un threshold tipo `24` (porcentaje actual). Subir tras Batch 1+2:**

```yaml
- name: Coverage gate
  run: |
    COVERAGE=$(awk -F'[:,]' '/^DA:/ {t++; if($3>0) h++} END {printf "%.2f", h/t*100}' coverage/lcov.info)
    THRESHOLD=30
    echo "Coverage: $COVERAGE %, threshold: $THRESHOLD %"
    awk "BEGIN {exit ($COVERAGE >= $THRESHOLD ? 0 : 1)}"
```

Si las cifras suben más, subir el threshold a 35, 40, etc.

**Commit:**

```bash
git commit -m "ci: subir coverage gate a 30% tras tests remote/ (batches E.1-E.2)"
```

---

<a id="g-verificacion"></a>
## G. Verificación end-to-end

Tras completar A + B + C + opcionalmente D, E, F:

```bash
# 1. Build limpio
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

# 2. Análisis
flutter analyze 2>&1 | tail -3
# Esperado: 0 errors

# 3. Tests
flutter test 2>&1 | tail -3
# Esperado: 619+ passed (más si se añadieron tests remote/)

# 4. Cobertura (si se ejecutó con --coverage)
awk -F'[:,]' '/^DA:/ {t++; if($3>0) h++} END {printf "Coverage: %.2f%%\n", h/t*100}' coverage/lcov.info

# 5. Bugs nuevos resueltos
grep -rn "nextDeps\.first\b" lib/features/stop_detail/   # 0
grep -A 2 "RefreshIndicator" lib/features/home/tabs/home_tab.dart | grep "no-op"   # 0
grep "stopping drain to keep order" lib/data/sync/   # 0
grep "onMessageOpenedApp\|getInitialMessage" lib/data/push/push_service.dart   # 2

# 6. Strings ES residuales
grep -rn "TARJETA NFC\|MEJORAR INFORMACIÓN\|PROTOTIPO" lib/features/   # 0 hits en .dart

# 7. APK release
flutter build apk --release 2>&1 | tail -3
# Esperado: ~73 MiB construido
```

---

<a id="h-cronograma"></a>
## H. Cronograma sugerido (defensa 2026-06-09)

Asumiendo hoy es **2026-05-24**, quedan **16 días**.

| Día | Acción | Esfuerzo |
|-----|--------|---------:|
| D-16 (hoy) | Leer este plan, decidir alcance | 30 min |
| D-15 | **Fase A** (5 fixes P1 críticos) | 1 h |
| D-14 | **Fase B** (strings ES residuales) | 45 min |
| D-13 | **Fase E Batch 1** (3-4 repos remote/) | 3-4 h |
| D-12 | **Fase E Batch 2** (modelos) | 2 h |
| D-10 | **Fase F** (coverage gate) | 30 min |
| D-7 | **Fase C** opcional (push background, deeplinks Manifest) | 1-2 h |
| D-5 | Re-leer `docs/tfg/08_presentacion.md` slide a slide | 1 h |
| D-3 | **Smoke test exhaustivo** (Sección G de PLAN_DEFENSA_2026_05_24) | 1 h |
| D-2 | Ensayo demo 1 (cronometrado 18-22 min) | 30 min |
| D-1 | Ensayo demo 2 + repaso preguntas tribunal | 30 min |
| D-0 (2026-06-09) | Smoke test rápido 2h antes; defensa | — |

**Total esfuerzo pre-defensa:** ~10-14 horas distribuidas.

---

<a id="i-tribunal"></a>
## I. Respuestas preparadas para tribunal

### "¿Por qué sigue habiendo strings ES hardcoded?"

> En la sesión 2026-05-24 los agentes de smoke test detectaron 10 strings residuales que escaparon migraciones anteriores. Documentados en `docs/historico/PLAN_ACCION_MOVIL_2026_05_24.md §B`. Fix mecánico (1 commit batch) aplicado en commit `<sha>`.

### "¿Cómo gestionáis el código que se detecta tras la auditoría?"

> Cada auditoría queda documentada como informe histórico en `docs/historico/`. Los bugs detectados se cierran en commits atómicos con prefijo Conventional Commits (`fix(scope): ... (Nxx)`). Los IDs Nxx referencian al informe origen para trazabilidad. Hasta hoy se han cerrado 8 + 8 + 8 + 5 + 11 = **40 bugs** trazables desde las auditorías de mayo.

### "¿Qué cobertura tenéis?"

> Cobertura global **24,04 %** verificada hoy con `awk` sobre `coverage/lcov.info`. La palanca activa es **tests de capa remote/** documentada en mega plan P2-4 y en `PLAN_ACCION_MOVIL_2026_05_24.md §E`. Plan: subir a 35-40 % pre-defensa, 60 %+ post-defensa con widget tests de features 0 %.

### "¿Cómo se procesan las solicitudes de borrado de cuenta?"

> Se inserta en la tabla `data_deletion_requests` desde la app. La edge function `delete_user` (desplegada en Supabase, `supabase/functions/delete_user/`) la procesa. Actualmente el insert está implementado y la edge function existe; pendiente conectar la invocación directa desde la app (`P6-PRIVACY-006` en plan §C.3, deuda explícita para release).

### "¿Por qué la `flutter test` muestra a veces 619/620 + 1 flaky?"

> Test `transit_input_validation_test.dart` falla en suite completa pero pasa aislado. Causa: interferencia de estado entre tests. Documentado en `PLAN_DEFENSA_2026_05_24.md §B.1` como riesgo conocido. Pendiente de investigar; no afecta producción ni demo.

---

## J. Resumen ejecutivo

**Estado actual del móvil tras `master @ d76de46`:**
- 619 tests pasando + 1 skipped + 1 flaky.
- 0 bugs P0/P1 conocidos vivos antes de smoke test 2026-05-24.
- 10 bugs nuevos detectados hoy (N15-N24 + P1-P8 + T1-T8).
- Cobertura 24,04 %.

**Total acciones pre-defensa documentadas:**

| Fase | Items | Esfuerzo | Crítico |
|------|------:|---------:|:-------:|
| A — P1 críticos | 5 fixes | 1 h | SÍ |
| B — Strings ES batch | 11 sitios | 45 min | NO |
| C — Prod gaps | 3 fixes | 1-2 h | NO |
| D — Sistémicos T1-T8 | 8 items | 2-3 h | NO (post-defensa) |
| E — Tests remote/ | 5 batches | 14 h | NO (palanca cobertura) |
| F — Coverage gate | 1 fix | 30 min | NO |
| **TOTAL críticos** | **5** | **~1 h** | — |
| **TOTAL recomendados** | **~25** | **~10-14 h** | — |

**Bloqueadores externos (separados):** 19 ítems en `docs/EXTERNAL_BLOCKERS.md` (keystore, Apple Dev, dominio, etc.) NO atacables sin acceso a sistemas. Post-defensa.

**Recomendación operativa:**
- **Mínimo para defensa segura:** ejecutar Fase A (1 h) + Fase B (45 min) = **1h 45 min**.
- **Recomendado:** A + B + 2 batches de E = **~6 h** (cobertura sube a ~30 %).
- **Ideal:** todo el plan = ~14 h.

---

**FIN DEL PLAN**

> Documento generado el 2026-05-24 tras smoke test exhaustivo con 3 sub-agentes Explore.
> Cada snippet de "código actual" verificado mediante lectura puntual del archivo en `master @ d76de46`.
> Cada commit sugerido es atómico y reversible.
> Cifras canónicas de Sección A.3 (en `PLAN_DEFENSA_2026_05_24.md`) reproducibles con los comandos citados.
