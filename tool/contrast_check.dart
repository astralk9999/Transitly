/// Contrast ratio checker for Transitly color tokens.
///
/// Computes WCAG 2.2 relative-luminance contrast ratios for critical text/bg
/// pairs in both dark and light themes. Ratios are sourced directly from
/// lib/core/theme/transit_colors.dart.
///
/// Run: dart run tool/contrast_check.dart
///   exit 0 = all checks pass
///   exit 1 = at least one pair fails the threshold
library;

import 'dart:io';
import 'dart:math';

/// Hex color value wrapper with manual sRGB → relative-luminance.
final class LumColor {
  const LumColor(this.hex, [this.label = '']);
  final int hex;
  final String label;

  double get r => ((hex >> 16) & 0xFF) / 255.0;
  double get g => ((hex >> 8) & 0xFF) / 255.0;
  double get b => (hex & 0xFF) / 255.0;

  double luminance() {
    double linearize(double c) =>
        c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4).toDouble();
    return 0.2126 * linearize(r) +
        0.7152 * linearize(g) +
        0.0722 * linearize(b);
  }

  String toHex() =>
      '#${hex.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

double contrast(LumColor a, LumColor b) {
  final l1 = a.luminance();
  final l2 = b.luminance();
  final lighter = max(l1, l2);
  final darker = min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

/// Pair to check: (label, fg-color, bg-color, minimum-ratio).
typedef Check = (String, LumColor, LumColor, double);

String grade(double ratio, double min) {
  if (ratio >= 7.0) return 'AAA';
  if (ratio >= 4.5) return 'AA';
  if (ratio >= 3.0) return 'AA-large';
  return 'FAIL';
}

void main(List<String> args) {
  // ── Dark theme colors from TransitDarkColors ──
  const darkTextHi = LumColor(0xF0F0FA, 'textHi(dark)');
  const darkTextMid = LumColor(0x8888A8, 'textMid(dark)');
  const darkTextLo = LumColor(0x8A87A5, 'textLo(dark)');
  const darkAccent = LumColor(0x977DDF, 'accent(dark)');
  const darkBgRoot = LumColor(0x08081A, 'bgRoot(dark)');
  const darkBgSurface = LumColor(0x10102A, 'bgSurface(dark)');

  // ── Light theme colors from TransitLightColors ──
  const lightTextHi = LumColor(0x111118, 'textHi(light)');
  const lightTextMid = LumColor(0x555568, 'textMid(light)');
  const lightTextLo = LumColor(0x8888A0, 'textLo(light)');
  const lightAccent = LumColor(0x7B64C0, 'accent(light)');
  const lightBgRoot = LumColor(0xF4F4FB, 'bgRoot(light)');
  const lightBgSurface = LumColor(0xFFFEFF, 'bgSurface(light)');

  // State colors
  const stateOnRoute = LumColor(0x00A0FF, 'stateOnRoute');
  const stateOnTime = LumColor(0xB0FF00, 'stateOnTime');
  const stateDelay = LumColor(0xFF8C00, 'stateDelay');
  const stateCancelled = LumColor(0xFF3B3B, 'stateCancelled');

  final checks = <Check>[
    // ─── Dark theme ───
    ('textHi on bgRoot (dark)', darkTextHi, darkBgRoot, 4.5),
    ('textHi on bgSurface (dark)', darkTextHi, darkBgSurface, 4.5),
    ('textMid on bgRoot (dark)', darkTextMid, darkBgRoot, 4.5),
    ('textMid on bgSurface (dark)', darkTextMid, darkBgSurface, 4.5),
    ('textLo on bgRoot (dark)', darkTextLo, darkBgRoot, 3.0),
    ('textLo on bgSurface (dark)', darkTextLo, darkBgSurface, 4.5),
    ('accent on bgRoot (dark)', darkAccent, darkBgRoot, 4.5),
    ('accent on bgSurface (dark)', darkAccent, darkBgSurface, 4.5),

    // ─── Light theme ───
    ('textHi on bgRoot (light)', lightTextHi, lightBgRoot, 4.5),
    ('textMid on bgRoot (light)', lightTextMid, lightBgRoot, 4.5),
    ('textLo on bgRoot (light)', lightTextLo, lightBgRoot, 3.0),
    ('accent on bgRoot (light)', lightAccent, lightBgRoot, 4.5),

    // ─── State tokens on dark bgRoot ───
    ('stateOnRoute on bgRoot (dark)', stateOnRoute, darkBgRoot, 3.0),
    ('stateOnTime on bgRoot (dark)', stateOnTime, darkBgRoot, 3.0),
    ('stateDelay on bgRoot (dark)', stateDelay, darkBgRoot, 3.0),
    ('stateCancelled on bgRoot (dark)', stateCancelled, darkBgRoot, 3.0),
  ];

  final bool verbose = args.contains('--verbose') || args.contains('-v');
  var failures = 0;
  var total = 0;

  stdout.writeln('Transitly contrast check — WCAG 2.2 relative luminance');
  stdout.writeln('─' * 62);

  for (final (label, fg, bg, min) in checks) {
    total++;
    final ratio = contrast(fg, bg);
    final ok = ratio >= min;
    if (!ok) failures++;

    final g = grade(ratio, min);
    final mark = ok ? '\x1B[32mPASS\x1B[0m' : '\x1B[31mFAIL\x1B[0m';
    stdout.write(
      '${label.padRight(38)} ${ratio.toStringAsFixed(1).padLeft(4)}:1 '
      '[${g.padRight(8)}] $mark  (min ${min.toStringAsFixed(1)}:1)',
    );
    if (verbose) {
      stdout.write('  fg=${fg.toHex()} bg=${bg.toHex()}');
    }
    stdout.writeln();
  }

  stdout.writeln('─' * 62);
  if (failures == 0) {
    stdout.writeln('\x1B[32mAll $total checks passed.\x1B[0m');
  } else {
    stdout.writeln(
      '\x1B[31m$failures/$total checks FAILED.\x1B[0m',
    );
  }

  exit(failures == 0 ? 0 : 1);
}
