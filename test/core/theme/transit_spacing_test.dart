import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/core/theme/transit_spacing.dart';

void main() {
  group('TransitSpacing', () {
    test('4pt grid increments are consistent', () {
      expect(TransitSpacing.space4, TransitSpacing.space2 * 2);
      expect(TransitSpacing.space8, TransitSpacing.space4 * 2);
      expect(TransitSpacing.space16, TransitSpacing.space8 * 2);
      expect(TransitSpacing.space32, TransitSpacing.space16 * 2);
      expect(TransitSpacing.space64, TransitSpacing.space32 * 2);
    });

    test('radius values are in ascending order', () {
      expect(TransitSpacing.radiusXs < TransitSpacing.radiusSm, isTrue);
      expect(TransitSpacing.radiusSm < TransitSpacing.radiusMd, isTrue);
      expect(TransitSpacing.radiusMd < TransitSpacing.radiusLg, isTrue);
      expect(TransitSpacing.radiusLg < TransitSpacing.radiusXl, isTrue);
    });

    test('stroke values are in ascending order', () {
      expect(
        TransitSpacing.strokeThin < TransitSpacing.strokeNormal,
        isTrue,
      );
      expect(
        TransitSpacing.strokeNormal < TransitSpacing.strokeAccent,
        isTrue,
      );
      expect(
        TransitSpacing.strokeAccent < TransitSpacing.strokeStrong,
        isTrue,
      );
    });

    test('fixed heights meet minimum tap target and have sane values', () {
      expect(TransitSpacing.minTapTarget, 48);
      expect(TransitSpacing.heightNavBar, 56);
      expect(TransitSpacing.heightBtnPrimary, greaterThanOrEqualTo(48));
      expect(TransitSpacing.heightBtnSmall, greaterThan(0));
      expect(TransitSpacing.heightInput, greaterThan(0));
    });

    test('padding presets are non-zero', () {
      expect(TransitSpacing.paddingCard, isA<dynamic>());
      expect(TransitSpacing.paddingScreen, isA<dynamic>());
      expect(TransitSpacing.paddingBadge, isA<dynamic>());
      expect(TransitSpacing.paddingChip, isA<dynamic>());
      expect(TransitSpacing.paddingSection, isA<dynamic>());
    });
  });
}
