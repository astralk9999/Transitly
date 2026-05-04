import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/app_logger.dart';

/// Categoría de un feedback local. Mapea 1:1 con las opciones del menú
/// de [FeedbackScreen].
enum FeedbackCategory {
  route('El recorrido en el mapa'),
  stops('Una parada (falta, sobra o está mal)'),
  schedules('Los horarios'),
  info('Información general'),
  suggestion('Tengo una sugerencia');

  const FeedbackCategory(this.label);
  final String label;
}

/// Entrada de feedback enviada por el usuario y persistida localmente.
///
/// Esta es una solución intermedia mientras no exista backend. F15
/// migrará el contenido de `localFeedbackProvider` al
/// `RouteFeedbackRepository` real con su cola de `pending_actions`.
class LocalFeedbackEntry {
  const LocalFeedbackEntry({
    required this.id,
    required this.routeId,
    required this.category,
    required this.description,
    required this.createdAt,
  });

  final String id;
  final String routeId;
  final FeedbackCategory category;
  final String description;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'routeId': routeId,
        'category': category.name,
        'description': description,
        'createdAt': createdAt.toIso8601String(),
      };

  factory LocalFeedbackEntry.fromJson(Map<String, dynamic> j) =>
      LocalFeedbackEntry(
        id: j['id'] as String,
        routeId: j['routeId'] as String,
        category: FeedbackCategory.values.firstWhere(
          (c) => c.name == (j['category'] as String),
          orElse: () => FeedbackCategory.info,
        ),
        description: j['description'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}

/// Clave en `shared_preferences`. Una sola entrada con el array completo
/// (las listas serán cortas durante v2; cuando crezca, F3 las migra a Hive).
const String localFeedbackPrefsKey = 'local_feedback_drafts';

const String _logTag = 'LocalFeedback';

/// Notifier que mantiene la lista de feedbacks locales del usuario y la
/// sincroniza con `shared_preferences` en cada mutación.
class LocalFeedbackNotifier extends StateNotifier<List<LocalFeedbackEntry>> {
  LocalFeedbackNotifier() : super(const []) {
    _hydrate();
  }

  Future<void> _hydrate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(localFeedbackPrefsKey);
      if (raw == null) return;
      final decoded = jsonDecode(raw) as List<dynamic>;
      state = decoded
          .map((e) => LocalFeedbackEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      AppLogger.info(_logTag, 'hydrated (${state.length} entries)');
    } catch (e, st) {
      AppLogger.error(_logTag, 'hydrate failed', e, st);
    }
  }

  /// Añade una entrada al estado y la persiste. Devuelve cuando la
  /// escritura a disco ha terminado para que la UI pueda confirmar el
  /// envío con seguridad.
  Future<void> add(LocalFeedbackEntry entry) async {
    state = [...state, entry];
    await _persist();
  }

  /// Solo para tests: vacía el estado y limpia el storage.
  Future<void> clearAll() async {
    state = const [];
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded =
          jsonEncode(state.map((e) => e.toJson()).toList(growable: false));
      await prefs.setString(localFeedbackPrefsKey, encoded);
    } catch (e, st) {
      AppLogger.error(_logTag, 'persist failed', e, st);
    }
  }
}

final localFeedbackProvider =
    StateNotifierProvider<LocalFeedbackNotifier, List<LocalFeedbackEntry>>(
        (ref) => LocalFeedbackNotifier());
