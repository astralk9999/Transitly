import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/data/auth/auth_repository.dart';
import 'package:transitly/data/mock/mock_data_service.dart';
import 'package:transitly/shared/models/user_role.dart';
import 'package:transitly/shared/providers/auth_provider.dart';
import 'package:transitly/shared/providers/user_provider.dart';

class _StubAssetBundle extends AssetBundle {
  _StubAssetBundle(this.content);
  final String content;

  @override
  Future<ByteData> load(String key) async {
    final bytes = utf8.encode(content);
    return ByteData.view(Uint8List.fromList(bytes).buffer);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async => content;
}

String _minimalJson() => jsonEncode({
      'operator': {
        'id': 'op-test',
        'name': 'Test',
        'shortName': 'T',
        'region': 'Test',
        'website': '',
        'phone': '',
      },
      'lines': [
        {
          'code': 'L1',
          'name': 'Línea 1',
          'color': '#FF0000',
          'serviceType': 'urban',
          'stops': [
            {
              'name': 'Stop A',
              'officialCode': 'SA',
              'order': 1,
              'lat': 36.685,
              'lng': -6.13,
              'municipality': 'Jerez',
            },
          ],
          'schedules': {
            'weekday': <String>[],
            'saturday': <String>[],
            'sunday_holiday': <String>[],
          },
        },
      ],
    });

void main() {
  group('redirect guards', () {
    test('auth provider defaults produce correct isAuthenticated', () {
      final container = ProviderContainer(overrides: [
        authStateProvider.overrideWith(
          (ref) => const Stream<AuthSessionState>.empty(),
        ),
        currentUserRoleProvider.overrideWithValue(UserRole.passenger),
      ]);
      addTearDown(container.dispose);

      expect(container.read(isAuthenticatedProvider), isFalse);
    });

    test('role provider override works for admin', () {
      final container = ProviderContainer(overrides: [
        currentUserRoleProvider.overrideWithValue(UserRole.admin),
      ]);
      addTearDown(container.dispose);

      expect(container.read(currentUserRoleProvider), UserRole.admin);
    });

    test('getRouteById returns null for nonexistent id', () async {
      final mock =
          await MockDataService.init(bundle: _StubAssetBundle(_minimalJson()));
      final found = mock.getRouteById('NONEXISTENT');
      expect(found, isNull);
    });
  });
}
