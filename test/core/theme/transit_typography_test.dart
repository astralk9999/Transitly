import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:transitly/core/theme/transit_typography.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  const testColor = Color(0xFF000000);

  group('TransitTypography', () {
    testWidgets('displayTime has correct font size and weight', (tester) async {
      await tester.pumpWidget(const SizedBox());
      final s = TransitTypography.displayTime(testColor);
      expect(s.fontSize, 32);
      expect(s.fontWeight, FontWeight.w700);
      expect(s.color, testColor);
    });

    testWidgets('displayNumber has correct font size and weight', (tester) async {
      await tester.pumpWidget(const SizedBox());
      final s = TransitTypography.displayNumber(testColor);
      expect(s.fontSize, 24);
      expect(s.fontWeight, FontWeight.w600);
      expect(s.color, testColor);
    });

    testWidgets('routeCode has correct font size and weight', (tester) async {
      await tester.pumpWidget(const SizedBox());
      final s = TransitTypography.routeCode(testColor);
      expect(s.fontSize, 18);
      expect(s.fontWeight, FontWeight.w700);
      expect(s.color, testColor);
    });

    testWidgets('routeName has correct font size and weight', (tester) async {
      await tester.pumpWidget(const SizedBox());
      final s = TransitTypography.routeName(testColor);
      expect(s.fontSize, 14);
      expect(s.fontWeight, FontWeight.w500);
      expect(s.color, testColor);
    });
  });
}
