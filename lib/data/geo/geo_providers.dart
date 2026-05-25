import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart';

import '../../core/utils/app_logger.dart';
import '../../shared/models/operator_model.dart';
import '../cache/hive_box_provider.dart';
import '../mock/mock_data_service.dart';
import '../operator/operator_helpers.dart';
import '../supabase/supabase_client_provider.dart';
import 'location_service.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// Última posición conocida del usuario. Null si no hay permiso o
/// el GPS está desactivado. Actualizado bajo demanda con
/// [requestLocationProvider].
final currentLocationProvider = StateProvider<LatLng?>((ref) => null);

/// Lanza la petición de permiso + posición actual. El resultado se
/// guarda en [currentLocationProvider].
final requestLocationProvider = FutureProvider<LatLng?>((ref) async {
  final service = ref.watch(locationServiceProvider);
  try {
    await service.ensurePermission();
    final pos = await service.getCurrent();
    if (pos != null) {
      final loc = LocationService.toLatLng(pos);
      ref.read(currentLocationProvider.notifier).state = loc;
      return loc;
    }
  } on LocationServiceException catch (e) {
    AppLogger.warn('Geo:Bootstrap', 'location request failed', e);
  }
  return null;
});

/// Operadores cercanos a la posición actual del usuario. Usa la
/// RPC `nearby_operators` cuando hay sesión; en modo invitado cae
/// al operador mock (COMUJESA). F8 introduce el lazy loading, F7+
/// poblará la tabla operators con datos reales.
final activeOperatorsProvider =
    FutureProvider<List<OperatorModel>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final session = client.auth.currentSession;

  if (session == null) {
    final mockData = ref.watch(mockDataServiceProvider);
    return [mockData.operator_];
  }

  final location = ref.watch(currentLocationProvider);
  if (location == null) {
    // Sin ubicación aún — devolver operadores cacheados o vacío.
    final box = ref.watch(operatorsBoxProvider);
    final cached = box.values.toList();
    if (cached.isNotEmpty) return cached;
    return [];
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
      return [];
    }

    final operators = (result as List<dynamic>)
        .map((row) => operatorFromRow(row as Map<String, dynamic>))
        .toList();

    // Cachear en Hive.
    final box = ref.watch(operatorsBoxProvider);
    for (final op in operators) {
      await box.put('op:${op.id}', op);
    }

    return operators;
  } catch (e) {
    AppLogger.warn('Geo:activeOperators', 'nearby_operators RPC failed, using cache', e);
    final box = ref.watch(operatorsBoxProvider);
    return box.values.toList();
  }
});

/// Operador activo actual (seleccionado manual o detectado).
/// Default: primer operador de activeOperatorsProvider.
final activeOperatorProvider = StateProvider<OperatorModel?>((ref) => null);

const _activeOperatorHiveKey = 'geo:active_operator_id';

void persistActiveOperatorId(String operatorId) {
  try {
    final box = Hive.box<Map<dynamic, dynamic>>('guest_theme_prefs');
    box.put(_activeOperatorHiveKey, operatorId);
  } catch (_) {}
}

String? _loadPersistedOperatorId() {
  try {
    if (!Hive.isBoxOpen('guest_theme_prefs')) return null;
    final box = Hive.box<Map<dynamic, dynamic>>('guest_theme_prefs');
    return box.get(_activeOperatorHiveKey) as String?;
  } catch (_) {
    return null;
  }
}

/// Provider que se dispara tras el bootstrap para obtener la
/// ubicación y precargar los operadores cercanos. El resultado
/// se consume en splash_screen o home_tab.
final geoBootstrapProvider = FutureProvider<void>((ref) async {
  // Solicitar ubicación (no bloqueante si el usuario rechaza).
  await ref.watch(requestLocationProvider.future);

  // Precargar operadores cercanos.
  final operators = await ref.watch(activeOperatorsProvider.future);

  // Restaurar operador activo persistido.
  final persistedId = _loadPersistedOperatorId();
  if (persistedId != null) {
    final match = operators.where((op) => op.id == persistedId).firstOrNull;
    if (match != null) {
      ref.read(activeOperatorProvider.notifier).state = match;
      return;
    }
  }
  // Sin selección previa: usar el primero.
  if (operators.isNotEmpty) {
    ref.read(activeOperatorProvider.notifier).state = operators.first;
  }
});
