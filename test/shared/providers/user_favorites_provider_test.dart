import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:transitly/shared/providers/user_favorites_provider.dart';

// Dobles de modo invitado: con usuario null los notifiers jamás invocan el
// cliente, así que el thunk del cliente puede lanzar sin riesgo.
UserFavoritesNotifier _lineNotifier() => UserFavoritesNotifier(
      () => throw StateError('Supabase no disponible en tests'),
      () => null,
    );

UserFavoriteStopsNotifier _stopNotifier() => UserFavoriteStopsNotifier(
      () => throw StateError('Supabase no disponible en tests'),
      () => null,
    );

void main() {
  setUpAll(() async {
    await Directory('test/.hive_test_fav').create(recursive: true);
    Hive.init('test/.hive_test_fav');
  });

  tearDownAll(() async {
    await Hive.close();
  });

  group('UserFavoritesNotifier', () {
    test('initial state is empty', () {
      final notifier = _lineNotifier();
      expect(notifier.state, isEmpty);
    });

    test('addLine adds a route id synchronously', () {
      final notifier = _lineNotifier();
      notifier.addLine('L1');
      expect(notifier.state, contains('L1'));
    });

    test('removeLine removes a route id synchronously', () {
      final notifier = _lineNotifier();
      notifier.addLine('L1');
      notifier.removeLine('L1');
      expect(notifier.state, isNot(contains('L1')));
    });

    test('isFavorite returns false for unknown route', () {
      final notifier = _lineNotifier();
      expect(notifier.isFavorite('L99'), isFalse);
    });

    test('isFavorite returns true after add', () {
      final notifier = _lineNotifier();
      notifier.addLine('L2');
      expect(notifier.isFavorite('L2'), isTrue);
    });
  });

  group('UserFavoriteStopsNotifier', () {
    test('initial state is empty', () {
      final notifier = _stopNotifier();
      expect(notifier.state, isEmpty);
    });

    test('addStop adds a stop id synchronously', () {
      final notifier = _stopNotifier();
      notifier.addStop('stop-1');
      expect(notifier.state, contains('stop-1'));
    });

    test('removeStop removes a stop id synchronously', () {
      final notifier = _stopNotifier();
      notifier.addStop('stop-1');
      notifier.removeStop('stop-1');
      expect(notifier.state, isNot(contains('stop-1')));
    });

    test('toggleStop adds if not present', () {
      final notifier = _stopNotifier();
      notifier.toggleStop('stop-2');
      expect(notifier.state, contains('stop-2'));
    });

    test('toggleStop removes if present', () {
      final notifier = _stopNotifier();
      notifier.addStop('stop-2');
      notifier.toggleStop('stop-2');
      expect(notifier.state, isNot(contains('stop-2')));
    });

    test('isStopFavorite returns false for unknown stop', () {
      final notifier = _stopNotifier();
      expect(notifier.isStopFavorite('stop-99'), isFalse);
    });

    test('isStopFavorite returns true after add', () {
      final notifier = _stopNotifier();
      notifier.addStop('stop-3');
      expect(notifier.isStopFavorite('stop-3'), isTrue);
    });

    test('lines and stops state are independent', () {
      final lineNotifier = _lineNotifier();
      final stopNotifier = _stopNotifier();

      lineNotifier.addLine('LA');
      stopNotifier.addStop('stopA');

      expect(lineNotifier.state, contains('LA'));
      expect(stopNotifier.state, contains('stopA'));
      expect(lineNotifier.state, isNot(contains('stopA')));
      expect(stopNotifier.state, isNot(contains('LA')));
    });
  });
}
