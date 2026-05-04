import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transitly/shared/providers/local_feedback_provider.dart';

LocalFeedbackEntry _entry({
  String id = 'e1',
  String routeId = 'L1',
  FeedbackCategory category = FeedbackCategory.stops,
  String description = 'desc',
}) =>
    LocalFeedbackEntry(
      id: id,
      routeId: routeId,
      category: category,
      description: description,
      createdAt: DateTime.utc(2026, 5, 5, 12, 0),
    );

Future<void> _flushHydrate() async {
  // Da el ciclo de microtask al `_hydrate` que dispara el constructor.
  await Future<void>.delayed(Duration.zero);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LocalFeedbackEntry serialization', () {
    test('toJson/fromJson roundtrip preserva campos', () {
      final original = _entry();
      final decoded = LocalFeedbackEntry.fromJson(original.toJson());
      expect(decoded.id, original.id);
      expect(decoded.routeId, original.routeId);
      expect(decoded.category, original.category);
      expect(decoded.description, original.description);
      expect(decoded.createdAt, original.createdAt);
    });

    test('categoría desconocida cae a info', () {
      final json = _entry().toJson();
      json['category'] = 'unknown_value';
      final decoded =
          LocalFeedbackEntry.fromJson(Map<String, dynamic>.from(json));
      expect(decoded.category, FeedbackCategory.info);
    });
  });

  group('LocalFeedbackNotifier', () {
    test('estado inicial vacío sin entradas previas', () async {
      final notifier = LocalFeedbackNotifier();
      addTearDown(notifier.dispose);
      await _flushHydrate();
      expect(notifier.state, isEmpty);
    });

    test('add() actualiza estado y persiste en shared_preferences',
        () async {
      final notifier = LocalFeedbackNotifier();
      addTearDown(notifier.dispose);
      await _flushHydrate();

      await notifier.add(_entry());
      expect(notifier.state.length, 1);

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(localFeedbackPrefsKey);
      expect(raw, isNotNull);
      final decoded = jsonDecode(raw!) as List<dynamic>;
      expect(decoded.length, 1);
      expect((decoded.first as Map<String, dynamic>)['id'], 'e1');
    });

    test('hydrate carga entradas existentes en shared_preferences',
        () async {
      final seed = [
        _entry(id: 'a', routeId: 'L1', category: FeedbackCategory.route),
        _entry(id: 'b', routeId: 'L3', category: FeedbackCategory.suggestion),
      ];
      SharedPreferences.setMockInitialValues({
        localFeedbackPrefsKey:
            jsonEncode(seed.map((e) => e.toJson()).toList()),
      });

      final notifier = LocalFeedbackNotifier();
      addTearDown(notifier.dispose);
      await _flushHydrate();

      expect(notifier.state.length, 2);
      expect(notifier.state.first.id, 'a');
      expect(notifier.state.last.category, FeedbackCategory.suggestion);
    });

    test('clearAll vacía el estado y el storage', () async {
      final notifier = LocalFeedbackNotifier();
      addTearDown(notifier.dispose);
      await _flushHydrate();
      await notifier.add(_entry());
      expect(notifier.state, isNotEmpty);

      await notifier.clearAll();
      expect(notifier.state, isEmpty);
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(localFeedbackPrefsKey);
      expect(jsonDecode(raw!), isEmpty);
    });
  });
}
