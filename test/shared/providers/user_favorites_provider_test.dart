import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:transitly/shared/providers/user_favorites_provider.dart';

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
      final notifier = UserFavoritesNotifier();
      expect(notifier.state, isEmpty);
    });

    test('addLine adds a route id synchronously', () {
      final notifier = UserFavoritesNotifier();
      notifier.addLine('L1');
      expect(notifier.state, contains('L1'));
    });

    test('removeLine removes a route id synchronously', () {
      final notifier = UserFavoritesNotifier();
      notifier.addLine('L1');
      notifier.removeLine('L1');
      expect(notifier.state, isNot(contains('L1')));
    });

    test('isFavorite returns false for unknown route', () {
      final notifier = UserFavoritesNotifier();
      expect(notifier.isFavorite('L99'), isFalse);
    });

    test('isFavorite returns true after add', () {
      final notifier = UserFavoritesNotifier();
      notifier.addLine('L2');
      expect(notifier.isFavorite('L2'), isTrue);
    });
  });

  group('UserFavoriteStopsNotifier', () {
    test('initial state is empty', () {
      final notifier = UserFavoriteStopsNotifier();
      expect(notifier.state, isEmpty);
    });

    test('addStop adds a stop id synchronously', () {
      final notifier = UserFavoriteStopsNotifier();
      notifier.addStop('stop-1');
      expect(notifier.state, contains('stop-1'));
    });

    test('removeStop removes a stop id synchronously', () {
      final notifier = UserFavoriteStopsNotifier();
      notifier.addStop('stop-1');
      notifier.removeStop('stop-1');
      expect(notifier.state, isNot(contains('stop-1')));
    });

    test('toggleStop adds if not present', () {
      final notifier = UserFavoriteStopsNotifier();
      notifier.toggleStop('stop-2');
      expect(notifier.state, contains('stop-2'));
    });

    test('toggleStop removes if present', () {
      final notifier = UserFavoriteStopsNotifier();
      notifier.addStop('stop-2');
      notifier.toggleStop('stop-2');
      expect(notifier.state, isNot(contains('stop-2')));
    });

    test('isStopFavorite returns false for unknown stop', () {
      final notifier = UserFavoriteStopsNotifier();
      expect(notifier.isStopFavorite('stop-99'), isFalse);
    });

    test('isStopFavorite returns true after add', () {
      final notifier = UserFavoriteStopsNotifier();
      notifier.addStop('stop-3');
      expect(notifier.isStopFavorite('stop-3'), isTrue);
    });

    test('lines and stops state are independent', () {
      final lineNotifier = UserFavoritesNotifier();
      final stopNotifier = UserFavoriteStopsNotifier();

      lineNotifier.addLine('LA');
      stopNotifier.addStop('stopA');

      expect(lineNotifier.state, contains('LA'));
      expect(stopNotifier.state, contains('stopA'));
      expect(lineNotifier.state, isNot(contains('stopA')));
      expect(stopNotifier.state, isNot(contains('LA')));
    });
  });
}
