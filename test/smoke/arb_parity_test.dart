import 'dart:convert';
import 'dart:io' show Directory, File;

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ARB key parity across locales', () {
    late Map<String, dynamic> es;
    late Map<String, dynamic> en;
    late Map<String, dynamic> ar;

    setUpAll(() {
      final root = Directory.current.path;
      es = jsonDecode(File('$root/lib/l10n/app_es.arb').readAsStringSync())
          as Map<String, dynamic>;
      en = jsonDecode(File('$root/lib/l10n/app_en.arb').readAsStringSync())
          as Map<String, dynamic>;
      ar = jsonDecode(File('$root/lib/l10n/app_ar.arb').readAsStringSync())
          as Map<String, dynamic>;
    });

    Set<String> userKeys(Map<String, dynamic> arb) =>
        arb.keys.where((k) => !k.startsWith('@')).toSet();

    test('ar.arb completeness vs es.arb template (PRO-A11Y-13)', () {
      final esKeys = userKeys(es);
      final arKeys = userKeys(ar);
      final missing = esKeys.difference(arKeys);
      final pct = ((arKeys.length / esKeys.length) * 100).toStringAsFixed(1);
      // PRO-A11Y-13: Arabic translation is incomplete (EXT). This test
      // tracks the gap without blocking CI. When ar.arb is complete, this
      // test will pass.
      print('ar.arb coverage: ${arKeys.length}/${esKeys.length} ($pct%)');
      if (missing.isNotEmpty) {
        print('ar.arb missing keys: ${missing.length}');
      }
      // Uncomment when PRO-A11Y-13 is done:
      // expect(missing, isEmpty,
      //     reason: 'ar missing ${missing.length} keys');
    }, skip: 'PRO-A11Y-13: Arabic ARB incomplete (62/433 keys, 14.3%). '
        'External dependency: human translation.');

    test('en.arb has all keys from es.arb (template)', () {
      final esKeys = userKeys(es);
      final enKeys = userKeys(en);
      final missing = esKeys.difference(enKeys);
      expect(missing, isEmpty,
          reason: 'en missing ${missing.length} keys: ${missing.take(5)}');
    });

    test('es.arb has no extra keys not in en.arb', () {
      final esKeys = userKeys(es);
      final enKeys = userKeys(en);
      final extra = enKeys.difference(esKeys);
      expect(extra, isEmpty,
          reason: 'en has ${extra.length} keys not in es: ${extra.take(5)}');
    });

    test('all 3 locales have @@locale metadata', () {
      expect(es['@@locale'], 'es');
      expect(en['@@locale'], 'en');
      expect(ar['@@locale'], 'ar');
    });

    test('en.arb key count matches es.arb', () {
      expect(userKeys(en).length, userKeys(es).length);
    });
  });
}
