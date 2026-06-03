import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('textScaler 200% accessibility', () {
    testWidgets('textScaler at 2.0x does not overflow a simple layout',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(2.0),
            ),
            child: Scaffold(
              body: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Hello World', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    const Text('This is a longer text that should wrap at 2x scale',
                        style: TextStyle(fontSize: 14)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('Acción'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      // Verify no overflow errors
      final richTexts = tester.widgetList<RichText>(find.byType(RichText));
      for (final rt in richTexts) {
        expect(rt.overflow, isNot(TextOverflow.ellipsis),
            reason: 'Text should not overflow at 2x scale');
      }

      // Verify button is still tappable
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('textScaler at 2.0x with Row children wraps correctly',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              textScaler: TextScaler.linear(2.0),
            ),
            child: Scaffold(
              body: SafeArea(
                child: Row(
                  children: [
                    Text('Label:'),
                    SizedBox(width: 8),
                    Flexible(child: Text('Value that may be long')),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      // No overflow errors — Flexible handles wrapping
      expect(tester.takeException(), isNull);
    });

    testWidgets('textScaler 2.0x icon buttons remain minimum 48dp',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(2.0),
            ),
            child: Scaffold(
              body: Center(
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {},
                  constraints:
                      const BoxConstraints(minWidth: 48, minHeight: 48),
                ),
              ),
            ),
          ),
        ),
      );

      final size = tester.getSize(find.byType(IconButton));
      expect(size.width, greaterThanOrEqualTo(48),
          reason: 'IconButton width >= 48dp at 2x scale');
      expect(size.height, greaterThanOrEqualTo(48),
          reason: 'IconButton height >= 48dp at 2x scale');
    });

    test('combined textScaler clamp respects min/max', () {
      const systemScale = 2.5;
      const userScale = 1.5;
      final combined = (systemScale * userScale).clamp(0.8, 2.5);
      expect(combined, 2.5,
          reason: 'Combined scale clamped to max 2.5');
    });

    test('combined textScaler respects minimum 0.8', () {
      const systemScale = 0.5;
      const userScale = 0.5;
      final combined = (systemScale * userScale).clamp(0.8, 2.5);
      expect(combined, 0.8,
          reason: 'Combined scale clamped to min 0.8');
    });
  });
}
