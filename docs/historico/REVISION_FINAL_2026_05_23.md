# REVISIÓN FINAL — App móvil Transitly (post plan v2)

**Fecha:** 2026-05-23
**HEAD verificado:** `master @ 85b81a1`
**Auditor:** Claude con 3 sub-agentes Explore paralelos (foco "very thorough", solo lectura)
**Alcance:** código Flutter (`lib/`) + configuración plataformas + verificación blockers release
**Excluido:** backend Supabase remoto (sin MCP en esta sesión), ejecución real de `flutter test`/`flutter build` (solo grep + lectura estática)
**Predecesores:** `docs/historico/AUDIT_2026_05_22.md` (auditoría inicial), `docs/historico/PLAN_ACCION_REMEDIACION_v2.md` (plan ejecutado por agente paralelo)

---

## A. RESUMEN EJECUTIVO (1 página)

### Veredicto en una línea

> **Funcionalmente demo-ready con 9 bugs visibles aún vivos; no release-ready (10 blockers de plataforma).**

### Comparación con auditoría 2026-05-22

| Métrica | Auditoría 2026-05-22 | Estado 2026-05-23 | Delta |
|---------|----------------------|-------------------|------:|
| Scorecard medio | 5,4/10 | **≈7,5/10** (estimado) | +2,1 |
| Tests pasando (declarado en commits) | 304 + 1 skipped | **620** | +316 |
| Mega plan cerrado | 100/190 (52,6%) verificado | **171/190 (90,0%)** declarado | +71 |
| Migraciones SQL | 15 con colisiones | **14 consecutivas** (001-013, 016) | reconciliado |
| Edge Functions desplegadas | 0 | **4** locales (delete_user, import_gtfs, purge_old_data, send_notification) | +4 |
| Bugs P0 vivos en UI | 10 | **4** | -6 |
| Bugs P1 vivos en UI | 8 | **4** | -4 |

**El plan v2 fue genuinamente exitoso.** No es marketing: el 60-70% de los bugs concretos de la auditoría se resolvieron en commits trazables. Lo que queda son **9 bugs UI específicos** + **5 inconsistencias docs↔código** + **10 blockers de plataforma release**.

### Top 3 a arreglar antes de la defensa TFG

Si el tribunal abre la app y toca botones, se topará con uno de estos tres. Todos < 30 min cada uno:

1. **B1** UUID hardcoded `00000000-…` en operator_admin (×2 sitios) — la generación/revocación de códigos de invitación intentaría escribir contra un operador inexistente.
2. **B2** Mensaje de error literal `'e'` en `admin_users_screen` — si algo falla cargando usuarios, el usuario ve "e" en la pantalla.
3. **B3** Botón "AÑADIR A MIS LÍNEAS" en detalle de ruta muestra SnackBar "Funcionalidad disponible en próxima versión" en vez de añadir a favoritos.

Plan ejecutable P0 en Sección F. Tiempo total estimado: ~2 horas + 30 min de smoke-test manual.

---

## B. LO QUE SÍ FUNCIONA AHORA (reconocer el progreso)

Tabla de bugs concretos de la auditoría 2026-05-22 → **arreglados verificados** con archivo:línea y referencia a commit:

| # | Bug original | Estado actual | Evidencia |
|---|--------------|---------------|-----------|
| 1 | `'COMUJESA · Ana Martín'` hardcoded en driver_panel:54 | **ARREGLADO** | `lib/features/driver/driver_panel.dart:57` ahora `ref.watch(currentUserProvider).name` |
| 2 | `'VIAJERO' 450` hardcoded en achievements_screen:95 | **ARREGLADO** | `lib/features/profile/achievements_screen.dart:96` ahora `l10n.achievementsLevel(...)` con parámetro dinámico |
| 3 | freshness `DateTime.now().subtract(Duration(days:2))` en route_detail_header:100 | **ARREGLADO** | `lib/features/route_detail/widgets/route_detail_header.dart:99-102` lee `route.lastUpdatedAt!` |
| 4 | Búsqueda con 3 resultados fake hardcoded en search_tab:104-189 | **ARREGLADO** | `lib/features/home/tabs/search_tab.dart:67-87` ahora `EmptyState` con `l10n.searchUnderConstructionTitle` honesto |
| 5 | `ReputationBadge(ReputationLevel.contributor)` literal en my_contributions:121 | **ARREGLADO** | `lib/features/contributions/my_contributions_screen.dart:124` lee del `currentUserProvider` |
| 6 | Splash siempre va a `/onboarding` sin persistencia (splash_screen:73) | **ARREGLADO** | `lib/features/splash/splash_screen.dart:74-81` lee `hasSeenOnboarding` de `SharedPreferences` y bifurca a `/home/inicio` o `/onboarding` |
| 7 | `/debug/showcase` accesible en release (app_router:391) | **ARREGLADO** | `lib/core/router/app_router.dart` ahora condiciona la ruta con `if (!kReleaseMode)` |
| 8 | Acceso directo Supabase desde route_share_sheet:78-94 | **ARREGLADO** | Encapsulado vía `ref.read(supabaseClientProvider)` en estilo de repositorio |
| 9 | Acceso directo Supabase desde route_officialize_modal:68 | **ARREGLADO** | Mismo patrón aplicado |
| 10 | Feedback exception silencioso (feedback_screen:89-91) | **ARREGLADO** | Cambiado a swallow explícito con comentario `/* Feedback already persisted locally */` + fallback local que sí funciona |
| 11 | Map filters decorativos sin persistencia | **ARREGLADO** | `map_filter_controller.dart` setter llama `_saveToPrefs()`, los cambios persisten en SharedPreferences |
| 12 | Drift documental (5 cifras tests distintas) | **PARCIALMENTE ARREGLADO** | Existe `tool/verify_state.sh` y bloque autogenerado en `00_MAESTRO.md`; algunos docs aún citan cifras viejas (deuda menor) |

**Adicionalmente arreglados (no estaban en auditoría pero el plan v2 los tocó):**
- Migraciones SQL: 15 archivos con colisiones → 14 consecutivas.
- Edge Functions: 0 desplegadas localmente → 4 carpetas (`send_notification`, `import_gtfs`, `delete_user`, `purge_old_data`).
- Locales ES/EN/AR: 343 claves → 846 claves ARB.
- AndroidManifest: canal FCM declarado (`transitly_notifications`), permiso `POST_NOTIFICATIONS` añadido.
- `PrivacyInfo.xcprivacy` presente en `ios/Runner/`.
- ABI splits + minify + shrinkResources en `android/app/build.gradle.kts:53-65`.

---

## C. BUGS VIVOS DETECTADOS (9, con plan de fix detallado)

### P0 — Bugs visibles para tribunal en demo (4)

#### B1. UUID hardcoded `00000000-0000-0000-0000-000000000000` en operator_admin (×2 sitios)

**Archivos:**
- `lib/features/operator_admin/invitation_codes_screen.dart:78`
- `lib/features/operator_admin/drivers_screen.dart:106`

**Código actual (verificado):**
```dart
// invitation_codes_screen.dart:77-80
final result = await client.rpc('create_invitation_code', params: {
  'p_operator_id': '00000000-0000-0000-0000-000000000000',
  'p_max_uses': maxUses,
});

// drivers_screen.dart:104-107
await client.rpc('revoke_driver', params: {
  'p_driver_id': driverId,
  'p_operator_id': '00000000-0000-0000-0000-000000000000',
});
```

**Por qué importa:** si el tribunal demuestra el modo administrador y pulsa "Generar código" o "Revocar conductor", la RPC enviará un UUID inválido. Con RLS activado, Supabase devolverá 42501 o similar; sin RLS, escribirá registros huérfanos.

**Fix propuesto:** obtener el `operator_id` real del provider de operador activo o de la sesión del usuario admin.
```dart
// Solución concreta — añadir arriba del método:
final session = client.auth.currentSession;
if (session == null) return;
final operatorId = (await client.from('profiles')
    .select('operator_id').eq('id', session.user.id).maybeSingle())?['operator_id'];
if (operatorId == null) {
  // mostrar SnackBar con error y abortar
  return;
}
// luego usar operatorId en el params
'p_operator_id': operatorId,
```

Alternativa más limpia si ya existe `activeOperatorProvider`:
```dart
final operatorId = ref.read(activeOperatorProvider).id;
```

**Verificación:** `grep -rn "00000000-0000-0000-0000-000000000000" lib/` → 0 hits.
**Severidad:** P0 · **Esfuerzo:** S (30 min) · **Riesgo build:** 🟢

---

#### B2. Mensaje de error literal `'e'` en admin_users_screen

**Archivo:** `lib/features/admin/admin_users_screen.dart:99`

**Código actual (verificado):**
```dart
} catch (e) {
  setState(() {
    _loading = false;
    _error = 'e';   // ← BUG: string literal en vez de e.toString()
  });
}
```

**Por qué importa:** si la carga de usuarios falla (sin sesión, sin red, error RLS), la UI muestra literalmente la letra "e" como mensaje de error. El tribunal lo verá en cuanto pruebe el modo offline o sin autenticación.

**Fix propuesto:**
```dart
} catch (e) {
  AppLogger.warn('admin_users_screen: load failed', error: e);
  setState(() {
    _loading = false;
    _error = AppLocalizations.of(context).adminUsersLoadError;
  });
}
```

Y añadir la clave a `lib/l10n/app_es.arb`, `app_en.arb`, `app_ar.arb`:
```json
"adminUsersLoadError": "No se pudo cargar la lista de usuarios. Inténtalo de nuevo.",
"@adminUsersLoadError": {"description": "Error genérico al cargar admin/users"}
```
Regenerar con `flutter gen-l10n`.

**Verificación:** `grep -n "_error = 'e'" lib/features/admin/admin_users_screen.dart` → 0 hits.
**Severidad:** P0 · **Esfuerzo:** S (10 min) · **Riesgo build:** 🟢

---

#### B3. Botón "AÑADIR A MIS LÍNEAS" cosmético

**Archivo:** `lib/features/route_detail/route_detail_screen.dart:144-158`

**Código actual (verificado):**
```dart
TransitButton(
  label: isFavorite
      ? 'EN MIS LÍNEAS ✓'
      : 'AÑADIR A MIS LÍNEAS ★',
  isPrimary: true,
  onPressed: isFavorite
      ? null
      : () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).featureComingSoon),
            ),
          );
        },
),
```

**Por qué importa:** es la acción **más visible** del detalle de ruta. La auditoría 2026-05-22 ya lo marcó como bug bloqueante. Se cambió de `() {}` literal a SnackBar con `featureComingSoon`, lo cual es más honesto pero igual de inutil. Como TFG demo, si el tribunal pulsa este botón se ve marketing falso.

**Fix propuesto:** cablear a un notifier real de favoritos. Si no existe ya, crearlo con persistencia Hive.

**Opción A (si existe `userFavoritesProvider`):**
```dart
onPressed: () async {
  if (isFavorite) {
    await ref.read(userFavoritesProvider.notifier).removeLine(route.id);
  } else {
    await ref.read(userFavoritesProvider.notifier).addLine(route.id);
  }
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(isFavorite
      ? AppLocalizations.of(context).favoriteRemoved
      : AppLocalizations.of(context).favoriteAdded),
  ));
},
```

**Opción B (si no existe el provider):** crearlo en `lib/shared/providers/user_favorites_provider.dart` con persistencia en Hive box `userFavorites`. ~50 líneas, 30 min.

Las claves `favoriteRemoved` y `favoriteAdded` ya existen en `app_*.arb` o son fáciles de añadir.

**Verificación:** `grep -n "featureComingSoon" lib/features/route_detail/route_detail_screen.dart` → 0 hits.
**Severidad:** P0 · **Esfuerzo:** S (30-45 min) · **Riesgo build:** 🟢

---

#### B4. `substring(0, 2)` sin guard en city_picker

**Archivo:** `lib/features/city_picker/city_picker_screen.dart:111`

**Código actual (verificado):**
```dart
child: Text(
  operator.shortName.substring(0, 2).toUpperCase(),
  ...
),
```

**Por qué importa:** si algún operador tiene `shortName` de longitud < 2 (ej. "X"), la app crashea con `RangeError`. La demo podría tropezar con cualquier dato de prueba mal formado.

**Fix propuesto:**
```dart
child: Text(
  operator.shortName.length >= 2
      ? operator.shortName.substring(0, 2).toUpperCase()
      : operator.shortName.padRight(2, ' ').substring(0, 2).toUpperCase(),
  ...
),
```

O extraer a helper privado `_safeBadge(String s) => s.padRight(2).substring(0, 2).toUpperCase();`.

**Verificación:** test unitario en `test/features/city_picker/city_picker_safe_badge_test.dart` con casos `''`, `'X'`, `'XY'`, `'XYZ'`.
**Severidad:** P0 · **Esfuerzo:** XS (5 min) · **Riesgo build:** 🟢

---

### P1 — UX visible pero no crash (4)

#### B5. `getNextDepartures` ignora `stopId`

**Archivo:** `lib/data/mock/mock_data_service.dart:359-379`

**Código actual (verificado):**
```dart
List<ScheduleModel> getNextDepartures(
    String routeId, String stopId, int count) {
  final now = DateTime.now();
  // ... usa now, routeId, dayType — pero NUNCA usa stopId
  final all = getSchedulesForRoute(routeId, dayType: dayType);
  final future = all.where(...).toList()..sort(...);
  return future.take(count).toList();
}
```

**Por qué importa:** todas las paradas de una misma línea muestran la misma hora de próxima llegada. Visible en `home_tab`, `stop_detail_screen`, `stop_info_sheet`. Para una demo de "transporte público en tiempo real", es un fallo conceptual.

**Fix propuesto:** desplazar las salidas según el offset entre la cabecera y la parada (mock realista):
```dart
List<ScheduleModel> getNextDepartures(
    String routeId, String stopId, int count) {
  final route = getRouteById(routeId);
  if (route == null) return [];
  final stopIndex = route.stops.indexOf(stopId);
  if (stopIndex < 0) return [];

  // mock realista: cada parada está 2 minutos después de la anterior
  final offsetMinutes = stopIndex * 2;

  final now = DateTime.now();
  final nowMinutes = now.hour * 60 + now.minute - offsetMinutes;
  final dayType = _dayTypeOf(now);

  final all = getSchedulesForRoute(routeId, dayType: dayType);
  final future = all.where((s) {
    final parts = s.departureTime.split(':');
    final m = int.parse(parts[0]) * 60 + int.parse(parts[1]);
    return m + offsetMinutes >= now.hour * 60 + now.minute;
  }).toList()
    ..sort((a, b) => a.departureTime.compareTo(b.departureTime));

  return future.take(count).toList();
}
```

**Verificación:** test unitario que verifica que la primera parada y la quinta de una misma línea devuelven horarios distintos.
**Severidad:** P1 · **Esfuerzo:** S (45 min) · **Riesgo build:** 🟢

---

#### B6. ETA "--" en active_route_screen

**Archivo:** `lib/features/driver/active_route_screen.dart:172, 181`

**Código actual (verificado):**
```dart
Text(
  '--',
  style: GoogleFonts.ibmPlexMono(fontSize: 18, color: c.textMid),
),
// ...
Center(
  child: Text(
    '--',
    style: GoogleFonts.ibmPlexMono(fontSize: 32, fontWeight: FontWeight.w700, color: c.accent),
  ),
),
```

**Por qué importa:** el conductor activo nunca ve la ETA real ni la distancia. Es la pantalla principal del modo conductor. La auditoría 2026-05-22 documentó que antes había ETA fake aleatoria; el "fix" fue dejarlo como "--" pero **el cableado real al `MockRealtimeService` nunca se hizo**.

**Fix propuesto:** leer del provider de realtime:
```dart
Consumer(builder: (ctx, ref, _) {
  final trip = ref.watch(currentTripProvider(routeId));
  return trip.maybeWhen(
    data: (t) => Text(
      t.nextStopEtaMinutes != null ? '${t.nextStopEtaMinutes} min' : '--',
      style: GoogleFonts.ibmPlexMono(fontSize: 32, fontWeight: FontWeight.w700, color: c.accent),
    ),
    orElse: () => Text('--', style: ...),
  );
}),
```

Si `currentTripProvider` y `nextStopEtaMinutes` no existen aún, añadirlos a `MockRealtimeService` (ya hay infraestructura, falta exponer la ETA del próximo stop).

**Verificación:** demo manual con conductor activo → la cifra cambia con el tiempo.
**Severidad:** P1 · **Esfuerzo:** M (1-2 h) · **Riesgo build:** 🟡

---

#### B7. "GUARDAR LOCAL (prototipo)" solo SnackBar

**Archivo:** `lib/features/driver/route_editor/post_recording_editor.dart:273-282`

**Código actual (verificado):**
```dart
Expanded(
  child: TransitButton(
    label: 'GUARDAR LOCAL (prototipo)',
    onPressed: () {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ruta publicada')),
      );
      context.go('/home/mapa');
    },
  ),
),
```

**Por qué importa:** el nombre del botón es honesto ("prototipo") pero el SnackBar dice "Ruta publicada" — contradicción visible. Y nada se persiste; las rutas grabadas se pierden al cerrar la pantalla.

**Fix propuesto:** persistir el draft en Hive box `editorDrafts` (ya existe) y mostrarlo en `my_contributions_screen`:
```dart
Expanded(
  child: TransitButton(
    label: AppLocalizations.of(context).editorSaveLocalDraft,
    onPressed: () async {
      final box = await Hive.openBox('editorDrafts');
      await box.put(_draftId, {
        'recorded_at': DateTime.now().toIso8601String(),
        'name': _nameController.text,
        'stops': _stops.map((s) => s.toJson()).toList(),
        // ...
      });
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context).editorDraftSaved),
      ));
      context.go('/home/perfil/mis-contribuciones');
    },
  ),
),
```

Añadir claves `editorSaveLocalDraft` y `editorDraftSaved` a ARB. En `my_contributions_screen`, leer la box y mostrar la lista.

**Verificación:** guardar un draft → cerrar app → abrir `Mis Contribuciones` → el draft aparece.
**Severidad:** P1 · **Esfuerzo:** M (1-2 h) · **Riesgo build:** 🟢

---

#### B8. `region_download_sheet` con bbox Jerez hardcoded

**Archivo:** `lib/features/offline/widgets/region_download_sheet.dart:76-81`

**Código actual (verificado):**
```dart
final bounds = const OfflineRegionBounds(
  northLat: 36.70,
  southLat: 36.67,
  eastLng: -6.10,
  westLng: -6.15,
);
```

**Por qué importa:** el usuario no puede elegir qué región descargar — siempre se descargan tiles de Jerez. Para una **demo TFG** es aceptable (el caso de estudio ES Jerez), pero la UI promete genéricamente "descargar región" sin etiqueta.

**Fix propuesto (TFG):** mantener el bbox pero etiquetar honestamente:
```dart
// Encima del bloque OfflineRegionBounds, en la UI:
Container(
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: c.accent.withValues(alpha: 0.1),
    borderRadius: BorderRadius.circular(8),
  ),
  child: Text(
    AppLocalizations.of(context).offlineRegionDemoLimitation,
    style: TextStyle(color: c.textMid, fontSize: 12),
  ),
),
```

Añadir clave a ARB:
```json
"offlineRegionDemoLimitation": "Versión demo: solo se puede descargar la región de Jerez de la Frontera. Selección libre de región disponible en próximas versiones."
```

**Fix completo (post-TFG):** integrar un `MapPicker` real con `flutter_map` + `LatLngBounds`.

**Verificación:** abrir sheet de descarga → ver banner de limitación.
**Severidad:** P1 · **Esfuerzo:** S (30 min) para etiqueta · **Riesgo build:** 🟢

---

### P2 — Limpieza (1)

#### B9. `Future.delayed(Duration(...))` simulando carga falsa

**Archivos:** `home_tab.dart:53`, `search_tab.dart:50`, y 3 sitios más detectados por el agente.

**Por qué importa:** introduce jank artificial. En la auditoría pasada y el plan v2 no se trataron.

**Fix propuesto:** eliminar los `await Future.delayed(...)` o conectar a un refresh real del provider.

**Severidad:** P2 · **Esfuerzo:** S (15 min total) · **Riesgo build:** 🟢

---

## D. INCONSISTENCIAS DOCS↔CÓDIGO (deuda explícita)

El usuario decidió **marcar deuda + añadir TODO en docs originales** (no completar implementaciones ahora ni reescribir docs).

### I1. Sentry spans (1 de 6 implementados)

- **Doc afirma:** `docs/SENTRY_SPANS.md` cataloga 6 spans (auth.signIn, map.initial_render, nfc.read, network.fetch_routes, push.send, auth.refresh).
- **Código real:** `grep -rn "startTransaction" lib/` devuelve **1 hit** (`lib/core/utils/sentry_setup.dart:90`, función wrapper genérica). Cero llamadas reales desde features.
- **Acción de deuda:** añadir al inicio de `docs/SENTRY_SPANS.md`:
  ```markdown
  > **Estado actual (2026-05-23):** 1 de 6 spans operativos. Solo el wrapper genérico `Sentry.startTransaction(name, op)` en `lib/core/utils/sentry_setup.dart:90` está disponible. Los 6 spans del catálogo (auth.signIn, map.initial_render, nfc.read, network.fetch_routes, push.send, auth.refresh) no se invocan desde el código de features. Plan post-TFG: instrumentar los 5 puntos restantes (fase F4.1 del plan v2).
  ```

### I2. PostHog eventos (0 de 17 invocados desde features)

- **Doc afirma:** `docs/POSTHOG_EVENTS.md` cataloga 17 eventos (signup_completed, route_viewed, incident_reported, etc.).
- **Código real:** `grep -rn "^import 'package:posthog_flutter" lib/features` → solo `privacy_screen.dart`. Los métodos `track()` están definidos en `lib/data/analytics/posthog_service.dart` (verificado por agente), pero ningún feature los invoca.
- **Acción de deuda:** añadir al inicio de `docs/POSTHOG_EVENTS.md`:
  ```markdown
  > **Estado actual (2026-05-23):** servicio cableado, 17 eventos definidos como métodos en `lib/data/analytics/posthog_service.dart`, **0 invocaciones desde `lib/features/`**. La revocación de consentimiento (privacy_screen) sí funciona; el envío real de eventos no. Plan post-TFG: invocar `analyticsService.track('<evento>', {...})` en cada feature según catálogo (fase F4.4 del plan v2).
  ```

### I3. `lib/data/_shared/repository_factory.dart` no existe

- **Doc afirma:** plan v2 paso F5.5 anuncia un helper `repositoryWithSessionFallback<T>` para eliminar la duplicación mock/remote en 12 providers.
- **Código real:** archivo no existe. Los 12 providers siguen con bloque duplicado `if (session == null) return MockRepository(...)`.
- **Acción de deuda:** editar `docs/historico/PLAN_ACCION_REMEDIACION_v2.md` paso F5.5 marcando estado:
  ```markdown
  **F5.5 · Helper repository factory** — **PENDIENTE (2026-05-23)**. No implementado. Aceptable para TFG (la duplicación es cosmética); recomendado post-defensa.
  ```

### I4. `integration_test/` carpeta no existe

- **Doc afirma:** plan v2 paso F6.1 prometía 3 happy paths (signup/login, search, report incident).
- **Código real:** carpeta no existe.
- **Acción de deuda:** marcar paso F6.1 como **PENDIENTE**. Aceptable para defensa TFG (la rúbrica no exige integration tests).

### I5. `lib/firebase_options.dart` no existe

- **Doc afirma:** plan v2 paso F3.1 dice generarlo con `flutterfire configure`.
- **Código real:** archivo no existe. `main.dart` llama `await FirebaseSetup.init()` que internamente hace `Firebase.initializeApp()` **sin opciones**, dependiendo de `google-services.json` (también ausente).
- **Acción de deuda:** marcar paso F3.1 como **PENDIENTE**. Sin esto, push notifications no funcionan en device real (en demo TFG sobre emulador, FCM no se demuestra de todos modos). Bloqueador release pero no TFG.

---

## E. BLOQUEADORES RELEASE (10, no urgentes para TFG)

Para release a Play Store / App Store hace falta lo siguiente. **Ninguno es necesario para defensa TFG** (la rúbrica no exige app publicada en stores).

| # | Blocker | Archivo/ubicación | Severidad release | Acción | Esfuerzo |
|---|---------|-------------------|-------------------|--------|---------:|
| R1 | Android keystore ausente | `android/key.properties` | P0 release | Generar con `keytool`, subir a GitHub Secrets como base64 | M |
| R2 | Firebase config Android ausente | `android/app/google-services.json` | P0 release | Descargar de Firebase Console, subir como GitHub Secret | S |
| R3 | Firebase config iOS ausente | `ios/Runner/GoogleService-Info.plist` | P0 release | Descargar de Firebase Console, subir como GitHub Secret | S |
| R4 | iOS entitlements ausentes | `ios/Runner/Runner.entitlements` | P0 release iOS | Crear con `aps-environment` + capability Push en Xcode | S |
| R5 | `UIBackgroundModes` faltante en `Info.plist` | `ios/Runner/Info.plist` | P0 release iOS | Añadir `<key>UIBackgroundModes</key><array><string>remote-notification</string></array>` | XS |
| R6 | CI sin job iOS | `.github/workflows/` | P1 release iOS | Crear workflow con macOS runner + Fastlane | L |
| R7 | Push handlers incompletos | `lib/data/push/push_service.dart` | P1 release | Añadir `onMessageOpenedApp.listen()` y `getInitialMessage()` para deeplinks | S |
| R8 | Legal docs (ToS + Privacy) ausentes | `assets/legal/` | P0 release | Crear 6 .md tri-idioma + ruta `/legal/<tipo>` en router + WebView/markdown viewer | M |
| R9 | Deep links no declarados en Manifest | `android/app/src/main/AndroidManifest.xml` | P1 release | Añadir `<intent-filter>` con VIEW + BROWSABLE + scheme `transitly` o https `transitly.app` con `android:autoVerify="true"` | S |
| R10 | `targetSdk = 34` (Play Store 2025 exige 35) | `android/app/build.gradle.kts:28` | P2 release | Cambiar a 35, testar | XS |

**Tiempo total estimado para release-ready:** 4-6 días de un dev sénior + configuración manual de cuentas (Firebase, Apple Developer, Play Console).

---

## F. PLAN EJECUTABLE P0 (≈2-3 horas antes de defensa TFG)

Para el demo TFG basta con cerrar **B1-B4** (los 4 bugs visibles que un tribunal toparía si pulsa botones). El resto son aceptables tras la deuda explícita documentada.

### F.0 · Pre-requisitos

```bash
# Working tree limpio
git status
# Si hay cambios en docs/tfg/, commitearlos antes
```

### F.1 · Fix B1 (UUIDs en operator_admin) — 30 min

**Decisión arquitectónica:** los dos screens necesitan el `operator_id` del admin activo. Asumimos que la tabla `profiles` tiene columna `operator_id` para usuarios con rol `operator_admin`. Si no, se necesita migración previa.

**Pasos:**

1. **Verificar el modelo:** abrir `lib/shared/models/user_model.dart`, confirmar que `UserModel` tiene `operatorId`. Si no, añadirlo.

2. **Edit en `invitation_codes_screen.dart`:**
```dart
// Reemplazar el bloque actual:
final result = await client.rpc('create_invitation_code', params: {
  'p_operator_id': '00000000-0000-0000-0000-000000000000',
  'p_max_uses': maxUses,
});

// Por:
final user = ref.read(currentUserProvider);
if (user.operatorId == null) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(AppLocalizations.of(context).operatorAdminMissingOperator),
  ));
  return;
}
final result = await client.rpc('create_invitation_code', params: {
  'p_operator_id': user.operatorId,
  'p_max_uses': maxUses,
});
```

3. **Edit en `drivers_screen.dart`** (idéntico patrón):
```dart
await client.rpc('revoke_driver', params: {
  'p_driver_id': driverId,
  'p_operator_id': user.operatorId,  // antes: '00000000-...'
});
```

4. **Añadir clave ARB** `operatorAdminMissingOperator` en `app_es.arb`, `app_en.arb`, `app_ar.arb`. Regenerar con `flutter gen-l10n`.

5. **Verificación:**
```bash
grep -rn "00000000-0000-0000-0000-000000000000" lib/
# Debería devolver 0 hits
```

6. **Commit:**
```bash
git add -A
git commit -m "fix(operator_admin): replace UUID placeholder with currentUser.operatorId

Previously create_invitation_code and revoke_driver RPCs were called
with a hardcoded '00000000-...' operator_id, breaking server-side
validation. Now we read the operator_id from currentUserProvider and
fail gracefully if absent."
```

### F.2 · Fix B2 (`_error = 'e'`) — 10 min

**Edit en `admin_users_screen.dart:99`:**

```dart
// Reemplazar:
_error = 'e';

// Por:
AppLogger.warn('admin_users_screen: load failed', error: e);
_error = AppLocalizations.of(context).adminUsersLoadError;
```

**Añadir clave ARB:**
```json
"adminUsersLoadError": "No se pudo cargar la lista de usuarios. Inténtalo de nuevo.",
"@adminUsersLoadError": {"description": "Error genérico al cargar admin/users"}
```

Regenerar con `flutter gen-l10n`.

**Verificación:**
```bash
grep -n "_error = 'e'" lib/features/admin/admin_users_screen.dart
# 0 hits
```

**Commit:**
```bash
git commit -am "fix(admin_users): replace literal 'e' error with localized message + AppLogger.warn"
```

### F.3 · Fix B3 (botón AÑADIR A MIS LÍNEAS) — 30-45 min

**Paso 1:** verificar si existe `userFavoritesProvider`.

```bash
grep -rn "userFavoritesProvider\|FavoritesNotifier" lib/shared/providers/
```

Si NO existe, crearlo en `lib/shared/providers/user_favorites_provider.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

class UserFavoritesNotifier extends StateNotifier<Set<String>> {
  UserFavoritesNotifier() : super(<String>{}) {
    _load();
  }

  static const _boxName = 'userFavorites';
  static const _key = 'lines';

  Future<void> _load() async {
    final box = await Hive.openBox(_boxName);
    final raw = box.get(_key, defaultValue: <String>[]);
    state = Set<String>.from(raw as List);
  }

  Future<void> addLine(String routeId) async {
    state = {...state, routeId};
    final box = await Hive.openBox(_boxName);
    await box.put(_key, state.toList());
  }

  Future<void> removeLine(String routeId) async {
    state = {...state}..remove(routeId);
    final box = await Hive.openBox(_boxName);
    await box.put(_key, state.toList());
  }

  bool isFavorite(String routeId) => state.contains(routeId);
}

final userFavoritesProvider =
    StateNotifierProvider<UserFavoritesNotifier, Set<String>>(
        (ref) => UserFavoritesNotifier());
```

Y registrar la box en `lib/data/cache/hive_init.dart`: añadir `await Hive.openBox('userFavorites');`.

**Paso 2:** edit `route_detail_screen.dart:144-158`:

```dart
final isFavorite = ref.watch(userFavoritesProvider).contains(route.id);

TransitButton(
  label: isFavorite
      ? AppLocalizations.of(context).routeDetailRemoveFavorite
      : AppLocalizations.of(context).routeDetailAddFavorite,
  isPrimary: !isFavorite,
  onPressed: () async {
    final notifier = ref.read(userFavoritesProvider.notifier);
    if (isFavorite) {
      await notifier.removeLine(route.id);
    } else {
      await notifier.addLine(route.id);
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(isFavorite
          ? AppLocalizations.of(context).favoriteRemoved
          : AppLocalizations.of(context).favoriteAdded),
    ));
  },
),
```

**Paso 3:** añadir claves ARB:
- `routeDetailRemoveFavorite`: "EN MIS LÍNEAS ✓"
- `routeDetailAddFavorite`: "AÑADIR A MIS LÍNEAS ★"
- `favoriteAdded`: "Línea añadida a tus favoritas"
- `favoriteRemoved`: "Línea eliminada de tus favoritas"

**Verificación:**
```bash
grep -n "featureComingSoon" lib/features/route_detail/route_detail_screen.dart
# 0 hits
```

Manual: añadir línea L1 → cerrar app → abrir Perfil → "Mis líneas" debería listar L1.

**Commit:**
```bash
git commit -am "feat(route_detail): wire 'Añadir a mis líneas' button to userFavoritesProvider with Hive persistence"
```

### F.4 · Fix B4 (substring sin guard) — 5 min

**Edit en `city_picker_screen.dart:111`:**

```dart
// Reemplazar:
operator.shortName.substring(0, 2).toUpperCase(),

// Por:
_safeBadge(operator.shortName),
```

Añadir al final de la clase:
```dart
String _safeBadge(String s) {
  if (s.isEmpty) return '··';
  if (s.length == 1) return '${s.toUpperCase()}·';
  return s.substring(0, 2).toUpperCase();
}
```

**Test (opcional, recomendado):**
Crear `test/features/city_picker/city_picker_safe_badge_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Si _safeBadge es privado, extraerlo a top-level o a un helper público

  test('safeBadge handles empty', () { ... });
  test('safeBadge handles length 1', () { ... });
  test('safeBadge handles length >= 2', () { ... });
}
```

**Commit:**
```bash
git commit -am "fix(city_picker): guard substring(0,2) against shortName < 2 chars"
```

### F.5 · Verificación final

```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter analyze         # 0 errors esperado
flutter test            # 620+ verde esperado
flutter build apk --debug
```

**Smoke test manual (30 min):**

1. Abrir app en emulador.
2. Crear cuenta → completar onboarding (no debe volver a aparecer al reabrir).
3. Pulsar línea L1 en home → detalle → "Añadir a mis líneas" → toast confirmando.
4. Cerrar app, reabrir → la línea sigue añadida.
5. Probar buscador → ver "Buscador en construcción" (no resultados fake).
6. Modo conductor: panel muestra tu nombre real (no "Ana Martín").
7. Si tienes rol admin: ir a "Gestionar usuarios" → ver lista (no "e" como error).
8. Si tienes rol operator_admin: "Generar código" → si tienes operator_id válido, código generado; si no, ver mensaje de error claro.
9. City picker: verificar que operadores con nombre corto no crashean.

### F.6 · Inconsistencias docs (marcar deuda)

Después de F.1-F.4, añadir los 5 banners de deuda en:
1. `docs/SENTRY_SPANS.md` (al inicio)
2. `docs/POSTHOG_EVENTS.md` (al inicio)
3. `docs/historico/PLAN_ACCION_REMEDIACION_v2.md` paso F5.5 (marcar PENDIENTE)
4. `docs/historico/PLAN_ACCION_REMEDIACION_v2.md` paso F6.1 (marcar PENDIENTE)
5. `docs/historico/PLAN_ACCION_REMEDIACION_v2.md` paso F3.1 (marcar PENDIENTE — firebase_options)

Ver Sección D para textos exactos.

**Commit:**
```bash
git commit -am "docs: mark debt — Sentry 1/6 spans, PostHog 0/17 invocations, F5.5/F6.1/F3.1 pending"
```

### F.7 · Tiempos estimados

| Paso | Esfuerzo |
|------|---------:|
| F.1 B1 UUIDs | 30 min |
| F.2 B2 error string | 10 min |
| F.3 B3 favoritos | 45 min |
| F.4 B4 substring | 5 min |
| F.5 verificación | 30 min |
| F.6 deuda docs | 20 min |
| **Total** | **~2h 20min** |

---

## G. VEREDICTO FINAL

### ¿La app está lista para demo TFG hoy?

**Casi, con reservas concretas.** Si se ejecuta el plan P0 (B1-B4, ≈2h 20min), **SÍ**. Sin él, el tribunal puede topar con:

1. Mensaje literal "e" al cargar usuarios admin.
2. Botón "AÑADIR A MIS LÍNEAS" que no añade nada.
3. Operator admin que invoca RPCs con UUID inválido.
4. Crash potencial en city_picker con nombres cortos.

Ninguno es catastrófico (la app no peta, la mayoría del tiempo funciona), pero son **fácilmente detectables en 5 minutos de uso real**.

### ¿La app está lista para release?

**NO.** Faltan 10 blockers de plataforma (Sección E). Estimación 4-6 días sénior.

### ¿El plan v2 fue exitoso?

**SÍ, sustantivamente.** 90% del mega plan declarado cerrado, 12 bugs concretos verificados como arreglados, tests de 304 → 620, migraciones reconciliadas, 4 Edge Functions creadas localmente, locales completos.

**Pero hay un patrón:** algunos cierres del plan v2 son **infraestructura sin cableado** — el ejemplo más claro es PostHog (17 métodos definidos, 0 invocaciones) y Sentry (1 wrapper, 0 spans específicos). Esto es **deuda honesta** una vez documentada en los banners propuestos en Sección D, pero hay que llamarla por su nombre: el plan v2 cerró la infraestructura pero no siempre la integración final.

### Recomendaciones cara a defensa

1. **Ejecutar plan P0 hoy** (Sección F, ~2h).
2. **Añadir banners de deuda** (Sección D).
3. **Hacer smoke-test manual de 30 min** siguiendo el guion de F.5.
4. **Preparar respuestas honestas** para el tribunal si pregunta por:
   - "¿Por qué Sentry no captura métricas de auth?" → "El catálogo está documentado, la instrumentación específica queda como trabajo post-TFG (planificada en F4.1)".
   - "¿Por qué los eventos PostHog no aparecen en el dashboard?" → "El servicio está cableado y el consent funciona, pero los eventos de features no se invocan aún; documentado como deuda".
   - "¿La aplicación está en stores?" → "No, hay 10 blockers de release documentados en `docs/historico/REVISION_FINAL_2026_05_23.md`. Defensa académica primero, release después".

---

## H. ÍNDICE RÁPIDO

| Sección | Tema |
|---------|------|
| A | Resumen ejecutivo |
| B | Lo que funciona (12 bugs arreglados) |
| C | 9 bugs vivos con fix detallado (B1-B9) |
| D | 5 inconsistencias docs↔código (I1-I5) |
| E | 10 blockers release (R1-R10) |
| F | Plan ejecutable P0 (≈2h 20min) |
| G | Veredicto final |
| H | Este índice |

---

**FIN DEL INFORME**

> Documento generado el 2026-05-23 tras revisión independiente con 3 sub-agentes Explore en paralelo. Cada bug "vivo" verificado mediante lectura puntual del archivo:línea citado. Cada arreglo "confirmado" verificado vía `grep` o `Read`. Plan P0 testado mentalmente como secuencia atómica de commits.
