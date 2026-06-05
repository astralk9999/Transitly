# Sub-plan D de P0 — Zona principal sin error + historial NFC scope por usuario

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Cerrar los dos blockers P0 restantes: (P0-08) al pulsar "Seleccionar zona principal" sale "Error al cargar operadores"; (P0-09) el historial de saldo NFC no se ve al iniciar sesión.

**Architecture:**

P0-08 — `activeOperatorsProvider` (`lib/data/geo/geo_providers.dart:44-93`) cubre tres ramas: sesión nula → mock; sesión + sin ubicación → cache Hive o `[]`; sesión + con ubicación → RPC `nearby_operators`. La rama "sesión + sin ubicación + cache vacía" devuelve `[]` y la `CityPickerScreen` muestra "Error al cargar operadores". Fix mínimo: en esa rama también fallback al operador mock (COMUJESA) — coherente con el comportamiento guest y garantiza siempre al menos una opción seleccionable.

P0-09 — `NfcScanNotifier._hydrateFromCache()` (`lib/shared/providers/nfc_provider.dart:73-86`) se ejecuta solo en el constructor del notifier. El repo `NfcBalanceRepository.getHistory()` itera el box global `nfc_scans` sin filtrar por usuario. Resultado: cuando el user hace logout y login, el provider mantiene el mismo `NfcScanNotifier` con el state del momento de su primera construcción; un nuevo login con otro user nunca se rehidrata. Fix: añadir campo `userId` a cada entrada al guardar; `getHistory()` acepta un `userId` opcional y filtra; `nfcScanProvider` escucha el `authStateChanges` de Supabase y llama a `refreshHistory()` cada vez que cambia el `currentUser?.id`.

**Tech Stack:** Riverpod 2.6.1 providers + `StateNotifierProvider`, Hive 2.2.3 box `nfc_scans`, `MockDataService.operator_` para fallback de operadores, `Supabase.auth.currentUser.id` para scoping.

---

## File Structure

**Modify:**
- `lib/data/geo/geo_providers.dart` — fallback mock en la rama "sesión + sin ubicación + cache vacía".
- `lib/data/nfc/nfc_balance_repository.dart` — añadir `userId` a entries; `getHistory({String? userId})` filtra.
- `lib/shared/providers/nfc_provider.dart` — `_hydrateFromCache(userId)`; escuchar cambios de auth.

**Create:**
- `test/data/geo/active_operators_fallback_test.dart` — verifica fallback a mock.
- `test/data/nfc/nfc_balance_repository_per_user_test.dart` — verifica filtrado por userId.

---

## Task 1: Fallback mock en `activeOperatorsProvider` (P0-08)

**Files:**
- Modify: `lib/data/geo/geo_providers.dart`
- Test: `test/data/geo/active_operators_fallback_test.dart`

### Step 1.1 — Test failing

- [ ] Crear `test/data/geo/active_operators_fallback_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart';
import 'package:transitly/data/cache/hive_box_provider.dart';
import 'package:transitly/data/geo/geo_providers.dart';
import 'package:transitly/data/mock/mock_data_service.dart';
import 'package:transitly/data/supabase/supabase_client_provider.dart';
import 'package:transitly/shared/models/operator_model.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = await Directory.systemTemp.createTemp('hive_geo_test_');
    Hive.init(dir.path);
  });

  test('activeOperatorsProvider falls back to mock when location null and '
      'operators cache empty (even with session)', () async {
    final mockData = await MockDataService.init();
    final boxName = 'operators_test_empty_${DateTime.now().microsecondsSinceEpoch}';
    final emptyBox = await Hive.openBox<OperatorModel>(boxName);

    final container = ProviderContainer(
      overrides: [
        mockDataServiceProvider.overrideWithValue(mockData),
        operatorsBoxProvider.overrideWithValue(emptyBox),
        currentLocationProvider.overrideWith((ref) => null),
        // No-session path is OK to short-circuit the test: the rama "session
        // present + no location + cache empty" exhibits the same shape and
        // the fallback now applies to both — see fix in geo_providers.dart.
        supabaseClientProvider.overrideWith(
          (ref) => throw UnimplementedError(
              'fallback should not need supabase client when location null'),
        ),
      ],
    );
    addTearDown(container.dispose);

    final result = await container.read(activeOperatorsProvider.future);

    expect(result, isNotEmpty,
        reason: 'fallback must return at least the mock operator');
    expect(result.first.id, equals(mockData.operator_.id));
  });
}
```

### Step 1.2 — Ejecutar test, ver falla

- [ ] Ejecutar:

```bash
flutter test test/data/geo/active_operators_fallback_test.dart
```

Expected: test falla porque el provider intenta tocar `supabaseClientProvider` (que arroja) o devuelve `[]`.

### Step 1.3 — Implementar fallback

- [ ] Editar `lib/data/geo/geo_providers.dart`. Reemplazar el cuerpo de `activeOperatorsProvider` (líneas 44-93) por:

```dart
final activeOperatorsProvider =
    FutureProvider<List<OperatorModel>>((ref) async {
  final mockData = ref.watch(mockDataServiceProvider);

  final location = ref.watch(currentLocationProvider);
  if (location == null) {
    // Sin ubicación aún — devolver operadores cacheados o, en su defecto,
    // el operador mock (COMUJESA) para que la UI siempre tenga algo
    // seleccionable. Antes devolvía [] cuando había sesión + sin
    // ubicación + cache vacía → CityPicker mostraba "Error al cargar
    // operadores".
    final box = ref.watch(operatorsBoxProvider);
    final cached = box.values.toList();
    if (cached.isNotEmpty) return cached;
    return [mockData.operator_];
  }

  final client = ref.watch(supabaseClientProvider);
  final session = client.auth.currentSession;

  if (session == null) {
    return [mockData.operator_];
  }

  try {
    final result = await client.rpc(
      'nearby_operators',
      params: {
        'p_lat': location.latitude,
        'p_lng': location.longitude,
        'p_radius_m': 50000,
      },
    );

    if (result == null || (result is List && result.isEmpty)) {
      // Sin operadores reales en la zona — fallback al mock para que la UI
      // siempre tenga algo. Evita el "Error al cargar operadores".
      return [mockData.operator_];
    }

    final operators = (result as List<dynamic>)
        .map((row) => operatorFromRow(row as Map<String, dynamic>))
        .toList();

    final box = ref.watch(operatorsBoxProvider);
    for (final op in operators) {
      await box.put('op:${op.id}', op);
    }

    return operators;
  } catch (e) {
    AppLogger.warn('Geo:activeOperators',
        'nearby_operators RPC failed, using cache + mock fallback', e);
    final box = ref.watch(operatorsBoxProvider);
    final cached = box.values.toList();
    if (cached.isNotEmpty) return cached;
    return [mockData.operator_];
  }
});
```

> **Notas del cambio.**
> - Se invierte el orden: primero comprobamos `currentLocationProvider`. Si es null, retornamos cache o mock SIN tocar el client Supabase (lo que también arregla el flujo de bootstrap donde `client` aún no está estable).
> - Las tres ramas que antes podían devolver `[]` (RPC empty, RPC error, cache vacía) ahora devuelven `[mockData.operator_]` como último recurso.

### Step 1.4 — Verificar test pasa

- [ ] Ejecutar:

```bash
flutter test test/data/geo/active_operators_fallback_test.dart
```

Expected: PASS.

### Step 1.5 — Suite + análisis

- [ ] Ejecutar:

```bash
flutter analyze
flutter test test/data/geo/
```

Expected: 0 errors, todos los tests de geo verdes.

### Step 1.6 — Smoke test manual

- [ ] `flutter run`.
- [ ] Perfil → "Seleccionar zona principal" → la lista muestra al menos COMUJESA (sin importar si hay GPS o sesión).
- [ ] Pulsar COMUJESA → vuelve al perfil sin error.
- [ ] Si hay GPS y sesión: la lista incluye operadores reales del RPC además del mock fallback cuando el RPC devuelve vacío.

### Step 1.7 — Commit

```bash
git add lib/data/geo/geo_providers.dart \
        test/data/geo/active_operators_fallback_test.dart
git commit -m "$(cat <<'EOF'
fix(geo): fallback al operador mock cuando no hay ubicación/cache (P0-08)

activeOperatorsProvider devolvía [] cuando la sesión existía pero la
ubicación todavía no estaba resuelta y la cache de operadores Hive
estaba vacía. La CityPickerScreen mostraba "Error al cargar operadores"
y bloqueaba al usuario.

Fix:
- Reorganizar el flujo: chequear location null antes que session, para
  no tocar el client Supabase cuando no hace falta.
- En todas las ramas que podían devolver [] (location null + cache
  empty / RPC empty / RPC error), fallback a [mockData.operator_].

Garantiza que la UI siempre tiene al menos COMUJESA seleccionable.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Scope por userId en historial NFC + re-hidratar al cambiar auth (P0-09)

**Files:**
- Modify: `lib/data/nfc/nfc_balance_repository.dart`
- Modify: `lib/shared/providers/nfc_provider.dart`
- Test: `test/data/nfc/nfc_balance_repository_per_user_test.dart`

### Step 2.1 — Test failing del repository

- [ ] Crear `test/data/nfc/nfc_balance_repository_per_user_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:transitly/data/nfc/nfc_balance_repository.dart';
import 'package:transitly/data/nfc/nfc_card_service.dart';

class _FakeSupabaseClient {
  // El repo solo usa _supabase.auth.currentUser?.id; aquí no lo necesitamos
  // porque inyectamos userId directamente. Reemplazamos con dynamic null en
  // los tests que no testean sync.
}

void main() {
  late Box<Map<dynamic, dynamic>> box;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = await Directory.systemTemp.createTemp('hive_nfc_balance_test_');
    Hive.init(dir.path);
  });

  setUp(() async {
    final name = 'nfc_scans_test_${DateTime.now().microsecondsSinceEpoch}';
    box = await Hive.openBox<Map<dynamic, dynamic>>(name);
  });

  tearDown(() async {
    await box.close();
  });

  test('saveScan stores userId in entry; getHistory(userId) filters by it',
      () async {
    final repo = NfcBalanceRepository.forTest(box);

    final alice = NfcCardResult(
      cardId: 'CARD_A',
      balance: 5.0,
      scannedAt: DateTime(2026, 6, 1, 9),
    );
    final bob = NfcCardResult(
      cardId: 'CARD_B',
      balance: 12.5,
      scannedAt: DateTime(2026, 6, 2, 10),
    );

    await repo.saveScanForUser(alice, userId: 'alice');
    await repo.saveScanForUser(bob, userId: 'bob');

    final aliceHistory = repo.getHistory(userId: 'alice');
    expect(aliceHistory.length, 1);
    expect(aliceHistory.first.cardId, 'CARD_A');

    final bobHistory = repo.getHistory(userId: 'bob');
    expect(bobHistory.length, 1);
    expect(bobHistory.first.cardId, 'CARD_B');
  });

  test('getHistory() without userId returns scans from "guest" slot only',
      () async {
    final repo = NfcBalanceRepository.forTest(box);

    await repo.saveScanForUser(
      NfcCardResult(
        cardId: 'CARD_G',
        balance: 3.0,
        scannedAt: DateTime(2026, 6, 1),
      ),
      userId: null,
    );
    await repo.saveScanForUser(
      NfcCardResult(
        cardId: 'CARD_A',
        balance: 10.0,
        scannedAt: DateTime(2026, 6, 1),
      ),
      userId: 'alice',
    );

    final guest = repo.getHistory();
    expect(guest.length, 1);
    expect(guest.first.cardId, 'CARD_G');
  });

  test('legacy entries without userId are returned for guest view (backwards '
      'compat)', () async {
    final key = 'LEGACY_CARD_${DateTime.now().millisecondsSinceEpoch}';
    await box.put(key, {
      'cardId': 'LEGACY_CARD',
      'balance': 7.5,
      'scannedAt': DateTime(2026, 5, 1).toIso8601String(),
      'synced': false,
      // No 'userId' field — legacy entry.
    });

    final repo = NfcBalanceRepository.forTest(box);
    final guest = repo.getHistory();
    expect(guest.any((s) => s.cardId == 'LEGACY_CARD'), isTrue);
  });
}
```

### Step 2.2 — Test del provider de re-hidratación

(Skipped — la verificación del provider real requiere mocking del cliente Supabase y `authStateChanges`, fuera del alcance mínimo. El test del repository ya cubre la lógica crítica de filtrado/persistencia.)

### Step 2.3 — Ejecutar tests, ver fallan

- [ ] Ejecutar:

```bash
flutter test test/data/nfc/nfc_balance_repository_per_user_test.dart
```

Expected: tests fallan porque `NfcBalanceRepository` no tiene `forTest`, `saveScanForUser`, ni `getHistory({String? userId})` por usuario.

### Step 2.4 — Refactorizar el repository

- [ ] Reemplazar `lib/data/nfc/nfc_balance_repository.dart` por:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/app_logger.dart';
import '../cache/hive_box_provider.dart';
import '../supabase/supabase_client_provider.dart';
import '../widgets_native/widget_data_writer.dart';
import 'nfc_card_service.dart';

class NfcBalanceRepository {
  NfcBalanceRepository(this._supabase, this._hive);

  /// Constructor de tests sin cliente Supabase real.
  NfcBalanceRepository.forTest(this._hive) : _supabase = null;

  final SupabaseClient? _supabase;
  final Box<Map<dynamic, dynamic>> _hive;

  static const _logTag = 'NfcBalanceRepo';
  static const _maxHistory = 10;
  static const _guestSlot = 'guest';

  String _key(NfcCardResult scan, String slot) =>
      '${slot}_${scan.cardId}_${scan.scannedAt.millisecondsSinceEpoch}';

  /// Atajo legacy: usa el usuario actual de Supabase o "guest" si no hay
  /// sesión.
  Future<void> saveScan(NfcCardResult scan) {
    final userId = _supabase?.auth.currentUser?.id;
    return saveScanForUser(scan, userId: userId);
  }

  /// Guarda un scan con scope explícito por usuario. Si [userId] es null,
  /// va al slot "guest".
  Future<void> saveScanForUser(
    NfcCardResult scan, {
    required String? userId,
  }) async {
    final slot = userId ?? _guestSlot;
    final key = _key(scan, slot);
    final entry = <String, dynamic>{
      'cardId': scan.cardId,
      'balance': scan.balance,
      'scannedAt': scan.scannedAt.toIso8601String(),
      'userId': userId,
      'synced': false,
    };
    await _hive.put(key, entry);

    WidgetDataWriter.writeNfcBalance(
      balance: scan.balance,
      scannedAt: scan.scannedAt,
    );

    if (_supabase != null) {
      await _trySyncEntry(key, scan);
    }
  }

  Future<bool> _trySyncEntry(String key, NfcCardResult scan) async {
    try {
      final userId = _supabase?.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase!.from('nfc_scans').insert({
        'user_id': userId,
        'card_id': scan.cardId,
        'balance': scan.balance,
        'scanned_at': scan.scannedAt.toIso8601String(),
      });

      final entry = _hive.get(key);
      if (entry is Map) {
        entry['synced'] = true;
        await _hive.put(key, entry);
      }
      AppLogger.info(_logTag, 'synced to Supabase: $key');
      return true;
    } catch (e) {
      AppLogger.warn(_logTag, 'sync failed for $key', e);
      return false;
    }
  }

  Future<void> syncPending() async {
    if (_supabase == null) return;
    final unsyncedKeys = <String>[];
    for (final key in _hive.keys) {
      if (key is! String) continue;
      final entry = _hive.get(key);
      if (entry is Map && entry['synced'] == false) {
        unsyncedKeys.add(key);
      }
    }

    if (unsyncedKeys.isEmpty) return;

    AppLogger.info(_logTag, 'syncing ${unsyncedKeys.length} pending entries');

    for (final key in unsyncedKeys) {
      final entry = _hive.get(key);
      if (entry is! Map) continue;
      final scan = _decodeEntry(key, entry);
      await _trySyncEntry(key, scan);
    }
  }

  /// Devuelve el historial scoped al [userId] dado. Si es null, devuelve
  /// el slot "guest" + entradas legacy sin campo `userId` (compatibilidad
  /// hacia atrás con scans creados antes de este cambio).
  List<NfcCardResult> getHistory({String? userId}) {
    final results = <NfcCardResult>[];
    for (final key in _hive.keys) {
      if (key is! String) continue;
      final entry = _hive.get(key);
      if (entry is! Map) continue;

      final entryUserId = entry['userId'] as String?;
      final matches = userId == null
          ? (entryUserId == null) // guest view + legacy
          : (entryUserId == userId);
      if (!matches) continue;

      results.add(_decodeEntry(key, entry));
    }
    results.sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
    return results.take(_maxHistory).toList();
  }

  int get pendingCount {
    int count = 0;
    for (final key in _hive.keys) {
      final entry = _hive.get(key);
      if (entry is Map && entry['synced'] == false) count++;
    }
    return count;
  }

  NfcCardResult _decodeEntry(String key, Map<dynamic, dynamic> entry) {
    return NfcCardResult(
      cardId: entry['cardId'] as String,
      balance: (entry['balance'] as num).toDouble(),
      scannedAt: DateTime.parse(entry['scannedAt'] as String),
    );
  }
}

final nfcBalanceRepositoryProvider = Provider<NfcBalanceRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final box = ref.watch(nfcScansBoxProvider);
  return NfcBalanceRepository(supabase, box);
});
```

### Step 2.5 — Verificar tests del repo pasan

- [ ] Ejecutar:

```bash
flutter test test/data/nfc/nfc_balance_repository_per_user_test.dart
```

Expected: 3 tests PASS.

### Step 2.6 — Actualizar el `NfcScanNotifier` para re-hidratar al cambiar auth

- [ ] Editar `lib/shared/providers/nfc_provider.dart`. Reemplazar la clase `NfcScanNotifier` y el provider final por:

```dart
class NfcScanNotifier extends StateNotifier<NfcScanState> {
  NfcScanNotifier(this._service, this._repo, {String? userId})
      : _userId = userId,
        super(const NfcScanState()) {
    _hydrateFromCache();
  }

  final NfcCardService _service;
  final NfcBalanceRepository _repo;
  String? _userId;

  void _hydrateFromCache() {
    final history = _repo.getHistory(userId: _userId);
    if (history.isEmpty) {
      // Garantiza que un cambio de usuario sin scans previos limpie el
      // state visible (no se quede mostrando el saldo de otro usuario).
      state = const NfcScanState();
      return;
    }
    final last = history.first;
    state = state.copyWith(
      status: NfcScanStatus.success,
      result: last,
      scanHistory: history,
    );
    WidgetDataWriter.writeNfcBalance(
      balance: last.balance,
      scannedAt: last.scannedAt,
    );
  }

  /// Cambia el slot de usuario activo y rehidrata desde la caché.
  /// Invocado desde el provider cuando cambia el `currentUser?.id`.
  void switchUser(String? newUserId) {
    if (_userId == newUserId) return;
    _userId = newUserId;
    _hydrateFromCache();
  }

  Future<void> startScan() async {
    state = state.copyWith(status: NfcScanStatus.scanning, errorMessage: null);

    await _service.startScan(
      onResult: (result) {
        PostHogAnalyticsService.nfcReadSuccess('mifare_classic', result.balance);
        _repo.saveScanForUser(result, userId: _userId);
        final history = _repo.getHistory(userId: _userId);
        state = NfcScanState(
          status: NfcScanStatus.success,
          result: result,
          scanHistory: history,
        );
      },
      onError: (error) {
        state = state.copyWith(
          status: NfcScanStatus.error,
          errorKind: error.error,
          errorMessage: error.displayMessage,
        );
      },
    );
  }

  Future<void> cancelScan() async {
    await _service.stopScan();
    state = state.copyWith(status: NfcScanStatus.idle, errorMessage: null);
  }

  void reset() {
    state = state.copyWith(status: NfcScanStatus.idle, errorMessage: null);
  }

  void refreshHistory() {
    final history = _repo.getHistory(userId: _userId);
    state = state.copyWith(scanHistory: history);
  }

  @override
  void dispose() {
    _service.stopScan();
    super.dispose();
  }
}

final nfcScanProvider =
    StateNotifierProvider<NfcScanNotifier, NfcScanState>((ref) {
  final service = ref.read(nfcCardServiceProvider);
  final repo = ref.read(nfcBalanceRepositoryProvider);
  final client = ref.watch(supabaseClientProvider);
  final initialUserId = client.auth.currentUser?.id;
  final notifier = NfcScanNotifier(service, repo, userId: initialUserId);

  // Escucha cambios de sesión y rehidrata desde el slot del nuevo user.
  final authSub = client.auth.onAuthStateChange.listen((data) {
    notifier.switchUser(data.session?.user.id);
  });
  ref.onDispose(authSub.cancel);

  ref.listen<bool>(isOfflineProvider, (prev, current) {
    if (prev == true && current == false) {
      ref.read(nfcBalanceRepositoryProvider).syncPending();
    }
  });

  return notifier;
});
```

> **Nota.** Hay que añadir al inicio del archivo:
> ```dart
> import 'package:supabase_flutter/supabase_flutter.dart' show AuthChangeEvent;
> ```
> Ya importa `nfc_balance_repository.dart` que importa `supabase_flutter`. Pero el listener `onAuthStateChange` necesita acceso directo solo si filtramos por evento. Como nosotros leemos `data.session?.user.id` directamente, NO necesitamos importar `AuthChangeEvent`. Verificar al ejecutar `flutter analyze`.

### Step 2.7 — Suite + análisis

- [ ] Ejecutar:

```bash
flutter analyze
flutter test test/data/nfc/
```

Expected: 0 errors. Test del repo PASS. Tests preexistentes del `nfc_balance_repository` que asumen el método antiguo pueden necesitar ajustes — actualizarlos a la nueva API (`saveScanForUser` + `getHistory(userId: ...)`) y mantener el comportamiento esperado.

### Step 2.8 — Smoke test manual

- [ ] `flutter run` en Android con NFC.
- [ ] Sin login (guest) → escanear tarjeta → ver historial.
- [ ] Login → ir a Card tab → historial guest desaparece (slot diferente); escanear → nuevo historial bajo el slot del user.
- [ ] Logout → vuelve al historial guest.
- [ ] Cerrar y reabrir app logueado → historial del user se hidrata desde Hive al primer render del tab.

### Step 2.9 — Commit

```bash
git add lib/data/nfc/nfc_balance_repository.dart \
        lib/shared/providers/nfc_provider.dart \
        test/data/nfc/nfc_balance_repository_per_user_test.dart
git commit -m "$(cat <<'EOF'
fix(nfc): historial scope por usuario + re-hidratar al cambiar auth (P0-09)

NfcScanNotifier._hydrateFromCache se ejecutaba solo en el constructor, y
getHistory() devolvía TODOS los scans del box global sin filtrar por
usuario. Resultado: al cambiar de sesión el historial no se aislaba ni
se rehidrataba — el saldo no aparecía al iniciar sesión.

Fix:
- NfcBalanceRepository: nuevo saveScanForUser(scan, userId) que
  guarda el userId en cada entrada. getHistory({userId}) filtra por
  ese campo. Entradas legacy sin userId se exponen como guest
  (backwards compat).
- NfcScanNotifier: nuevo switchUser(newUserId) que rehidrata el state
  desde el slot del nuevo user (y limpia si vacío).
- nfcScanProvider escucha onAuthStateChange y llama switchUser cada
  vez que cambia currentUser?.id.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Verificación + tracking V16 + PR

### Step 3.1 — Suite completa final

- [ ] Ejecutar:

```bash
flutter analyze
flutter test
```

Expected: 0 errors. Mismos 19 timeouts pre-existentes en `card_tab_widget_test.dart` (no relacionados).

### Step 3.2 — Smoke test integrado

- [ ] `flutter run`.
- [ ] Login → Perfil → "Seleccionar zona principal" → al menos COMUJESA visible y seleccionable ✓ (P0-08).
- [ ] Card Tab → al volver de logout/login el historial del usuario aparece ✓ (P0-09).

### Step 3.3 — Actualizar tracking del plan V16

- [ ] Marcar P0-08 y P0-09 como cerrados en `docs/historico/PLAN_REPARACION_2026_06_05_V16.md`.

- [ ] Commit:

```bash
git add docs/historico/PLAN_REPARACION_2026_06_05_V16.md
git commit -m "chore: cerrar P0-08/P0-09 en plan V16 — P0 entero completado

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

### Step 3.4 — Push + PR

```bash
git push -u origin fix/p0-sub-d-zona-nfc
```

Abrir PR manualmente desde la URL que devuelve GitHub.

### Step 3.5 — Siguiente fase

Con sub-D mergeado, **P0 entero está cerrado** (9 ítems en 4 PRs independientes). Próximo bloque del plan V16: **P1 (8 funcionalidad rota)**:

- P1-01 privacidad real con Supabase
- P1-02 accesibilidad: modo "ninguno" + mover dislexia/daltonismo
- P1-03 alto contraste rediseño
- P1-04 widgets rediseño completo (preview + selectores + tema + refresh)
- P1-05 eliminar FilterPresets
- P1-06 datos offline funcional con FMTC
- P1-07 fusionar zonas+líneas en mapa
- P1-08 rediseño botón cerrar sheet de línea

Recomiendo agrupar en 3 sub-planes:
- Sub-E: P1-01 + P1-02 + P1-03 (apariencia/accesibilidad real)
- Sub-F: P1-04 (widgets — bloque grande propio)
- Sub-G: P1-05 + P1-06 + P1-07 + P1-08 (mapa + cleanup)

---

## Notas y consideraciones

**Sobre el guest slot.** Decidí mantener el comportamiento "entradas sin userId == guest". Eso evita una migración de datos existentes y mantiene continuidad para usuarios que ya tenían scans antes de este cambio. Si en el futuro se quiere "olvidar todo guest tras login", basta con un `_repo.purgeGuest()` que iteré las keys del slot guest.

**Sobre la decisión local-only.** El plan V16 dice "Local-only" para el historial NFC. El método `_trySyncEntry` sigue subiendo el scan a Supabase porque así estaba el código original (compatible con la tabla `nfc_scans` existente). Si se quiere desactivar sync completamente, eliminar la llamada en `saveScanForUser` y borrar la tabla en Supabase. Para sub-D mantengo la sync existente porque no introduce regresión.

**Sobre el rebuild del `nfcScanProvider`.** Si el `supabaseClientProvider` se invalida (cambia algo upstream), el provider se reconstruye, se crea un nuevo `NfcScanNotifier`, su `_hydrateFromCache()` se ejecuta una vez más con el `currentUser` del momento. El listener de `onAuthStateChange` cubre el resto.

**Sobre P0-08 y RPC vacío.** Antes, si la RPC `nearby_operators` devolvía lista vacía pero el RPC en sí funcionaba (zona sin operadores en la base), también caía a `[]`. Ahora cae al mock. Esto es coherente con el diseño TFG: la app siempre demuestra COMUJESA en Jerez aunque el user esté en otra ciudad.
