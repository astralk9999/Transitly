import 'package:flutter/material.dart';

import 'app_palette.dart';
import '../transit_colors.dart';

// ── Sunrise (warm oranges / pinks) ────────────────────────────────

class TransitSunriseColors implements TransitColorScheme {
  const TransitSunriseColors();

  @override Color get bgRoot => const Color(0xFF1A1410);
  @override Color get bgSidebar => const Color(0xFF1A1410);
  @override Color get bgSurface => const Color(0xFF241A14);
  @override Color get bgRaised => const Color(0xFF2E2018);
  @override Color get bgInput => const Color(0xFF1E1612);
  @override Color get bgElevated => const Color(0xFF281C16);

  @override Color get border => const Color(0xFF3A2A1E);
  @override Color get borderFocus => const Color(0xFF5A4030);
  @override Color get divider => const Color(0xFF281C16);

  @override Color get accent => const Color(0xFFE8885A);
  @override Color get accentBg => const Color(0xFF1E1410);
  @override Color get accentMuted => const Color(0x33E8885A);

  @override Color get neonCyan => const Color(0xFFFFB84D);
  @override Color get neonMagenta => const Color(0xFFFF5E7A);
  @override Color get neonPurple => const Color(0xFFC77DFF);
  @override Color get neonBlue => const Color(0xFF4DA6FF);

  @override LinearGradient get gradientAccent => const LinearGradient(
        colors: [Color(0xFFE8885A), Color(0xFFF0AA7A)],
      );
  @override LinearGradient get gradientNeon => const LinearGradient(
        colors: [Color(0xFFC77DFF), Color(0xFFFF5E7A)],
      );
  @override LinearGradient get gradientWarm => const LinearGradient(
        colors: [Color(0xFFFF5E7A), Color(0xFFFFB84D)],
      );
  @override LinearGradient get gradientCard => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0x1AE8885A), Color(0x0DC77DFF)],
      );

  @override Color get stateOnRoute => const Color(0xFF00A0FF);
  @override Color get stateOnTime => const Color(0xFFB0FF00);
  @override Color get stateDelay => const Color(0xFFFF8C00);
  @override Color get stateCancelled => const Color(0xFFFF3B3B);
  @override Color get stateIdle => const Color(0xFF3A2A1E);

  @override Color get textHi => const Color(0xFFF0EDE8);
  @override Color get textMid => const Color(0xFFA89888);
  @override Color get textLo => const Color(0xFF5A4A40);
  @override Color get textDisabled => const Color(0xFF3A2A20);

  @override Color get glassBg => const Color(0x22FFFFFF);
  @override Color get glassBorder => const Color(0x2DFFFFFF);
}

// ── Forest (deep greens) ───────────────────────────────────

class TransitForestColors implements TransitColorScheme {
  const TransitForestColors();

  @override Color get bgRoot => const Color(0xFF0A1A10);
  @override Color get bgSidebar => const Color(0xFF0A1A10);
  @override Color get bgSurface => const Color(0xFF0E2216);
  @override Color get bgRaised => const Color(0xFF142A1C);
  @override Color get bgInput => const Color(0xFF0C1E12);
  @override Color get bgElevated => const Color(0xFF122418);

  @override Color get border => const Color(0xFF1A3020);
  @override Color get borderFocus => const Color(0xFF2A4A32);
  @override Color get divider => const Color(0xFF122418);

  @override Color get accent => const Color(0xFF5AAA6E);
  @override Color get accentBg => const Color(0xFF0A1410);
  @override Color get accentMuted => const Color(0x335AAA6E);

  @override Color get neonCyan => const Color(0xFF4AEEBC);
  @override Color get neonMagenta => const Color(0xFFFF5E9A);
  @override Color get neonPurple => const Color(0xFF9966FF);
  @override Color get neonBlue => const Color(0xFF4DA6FF);

  @override LinearGradient get gradientAccent => const LinearGradient(
        colors: [Color(0xFF5AAA6E), Color(0xFF7ACC90)],
      );
  @override LinearGradient get gradientNeon => const LinearGradient(
        colors: [Color(0xFF4AEEBC), Color(0xFF4DA6FF)],
      );
  @override LinearGradient get gradientWarm => const LinearGradient(
        colors: [Color(0xFF5AAA6E), Color(0xFFB0FF00)],
      );
  @override LinearGradient get gradientCard => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0x1A5AAA6E), Color(0x0D4AEEBC)],
      );

  @override Color get stateOnRoute => const Color(0xFF00CC66);
  @override Color get stateOnTime => const Color(0xFFB0FF00);
  @override Color get stateDelay => const Color(0xFFFFB84D);
  @override Color get stateCancelled => const Color(0xFFFF3B3B);
  @override Color get stateIdle => const Color(0xFF1A3020);

  @override Color get textHi => const Color(0xFFE8F0E8);
  @override Color get textMid => const Color(0xFF88A88A);
  @override Color get textLo => const Color(0xFF4A5A4C);
  @override Color get textDisabled => const Color(0xFF2A3A2C);

  @override Color get glassBg => const Color(0x22FFFFFF);
  @override Color get glassBorder => const Color(0x2DFFFFFF);
}

// ── Midnight (dark violet / black) ─────────────────────────

class TransitMidnightColors implements TransitColorScheme {
  const TransitMidnightColors();

  @override Color get bgRoot => const Color(0xFF0A0A1E);
  @override Color get bgSidebar => const Color(0xFF0A0A1E);
  @override Color get bgSurface => const Color(0xFF10102A);
  @override Color get bgRaised => const Color(0xFF181838);
  @override Color get bgInput => const Color(0xFF0C0C20);
  @override Color get bgElevated => const Color(0xFF141430);

  @override Color get border => const Color(0xFF1E1E3A);
  @override Color get borderFocus => const Color(0xFF3A3A60);
  @override Color get divider => const Color(0xFF141430);

  @override Color get accent => const Color(0xFF9966FF);
  @override Color get accentBg => const Color(0xFF0E0A1E);
  @override Color get accentMuted => const Color(0x339966FF);

  @override Color get neonCyan => const Color(0xFF66D9FF);
  @override Color get neonMagenta => const Color(0xFFFF66B2);
  @override Color get neonPurple => const Color(0xFFB366FF);
  @override Color get neonBlue => const Color(0xFF6688FF);

  @override LinearGradient get gradientAccent => const LinearGradient(
        colors: [Color(0xFF9966FF), Color(0xFFBB88FF)],
      );
  @override LinearGradient get gradientNeon => const LinearGradient(
        colors: [Color(0xFFB366FF), Color(0xFFFF66B2)],
      );
  @override LinearGradient get gradientWarm => const LinearGradient(
        colors: [Color(0xFFFF66B2), Color(0xFF66D9FF)],
      );
  @override LinearGradient get gradientCard => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0x1A9966FF), Color(0x0DB366FF)],
      );

  @override Color get stateOnRoute => const Color(0xFF6699FF);
  @override Color get stateOnTime => const Color(0xFF99FF66);
  @override Color get stateDelay => const Color(0xFFFFB366);
  @override Color get stateCancelled => const Color(0xFFFF4D4D);
  @override Color get stateIdle => const Color(0xFF2A2A50);

  @override Color get textHi => const Color(0xFFEEE8FF);
  @override Color get textMid => const Color(0xFF9999CC);
  @override Color get textLo => const Color(0xFF55557A);
  @override Color get textDisabled => const Color(0xFF303050);

  @override Color get glassBg => const Color(0x22FFFFFF);
  @override Color get glassBorder => const Color(0x2DFFFFFF);
}

// ── Ocean (blues / cyan) ───────────────────────────────────

class TransitOceanColors implements TransitColorScheme {
  const TransitOceanColors();

  @override Color get bgRoot => const Color(0xFF0A141E);
  @override Color get bgSidebar => const Color(0xFF0A141E);
  @override Color get bgSurface => const Color(0xFF0E1A28);
  @override Color get bgRaised => const Color(0xFF142232);
  @override Color get bgInput => const Color(0xFF0C1622);
  @override Color get bgElevated => const Color(0xFF101E2C);

  @override Color get border => const Color(0xFF1A2A3A);
  @override Color get borderFocus => const Color(0xFF2A405A);
  @override Color get divider => const Color(0xFF141E2C);

  @override Color get accent => const Color(0xFF4AAAD2);
  @override Color get accentBg => const Color(0xFF081420);
  @override Color get accentMuted => const Color(0x334AAAD2);

  @override Color get neonCyan => const Color(0xFF4AEECC);
  @override Color get neonMagenta => const Color(0xFFFF5EAA);
  @override Color get neonPurple => const Color(0xFF8066FF);
  @override Color get neonBlue => const Color(0xFF4DAAFF);

  @override LinearGradient get gradientAccent => const LinearGradient(
        colors: [Color(0xFF4AAAD2), Color(0xFF6CCCF0)],
      );
  @override LinearGradient get gradientNeon => const LinearGradient(
        colors: [Color(0xFF4AEECC), Color(0xFF4DAAFF)],
      );
  @override LinearGradient get gradientWarm => const LinearGradient(
        colors: [Color(0xFF4DAAFF), Color(0xFF8066FF)],
      );
  @override LinearGradient get gradientCard => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0x1A4AAAD2), Color(0x0D4AEECC)],
      );

  @override Color get stateOnRoute => const Color(0xFF00AADD);
  @override Color get stateOnTime => const Color(0xFF00DDAA);
  @override Color get stateDelay => const Color(0xFFFFA64D);
  @override Color get stateCancelled => const Color(0xFFFF4D6A);
  @override Color get stateIdle => const Color(0xFF1A2A3A);

  @override Color get textHi => const Color(0xFFE8F0F8);
  @override Color get textMid => const Color(0xFF88A8C0);
  @override Color get textLo => const Color(0xFF4A6880);
  @override Color get textDisabled => const Color(0xFF2A4060);

  @override Color get glassBg => const Color(0x22FFFFFF);
  @override Color get glassBorder => const Color(0x2DFFFFFF);
}

// ── Mono (grayscale + silver accent) ───────────────────────

class TransitMonoColors implements TransitColorScheme {
  const TransitMonoColors();

  @override Color get bgRoot => const Color(0xFF141414);
  @override Color get bgSidebar => const Color(0xFF141414);
  @override Color get bgSurface => const Color(0xFF1A1A1A);
  @override Color get bgRaised => const Color(0xFF242424);
  @override Color get bgInput => const Color(0xFF181818);
  @override Color get bgElevated => const Color(0xFF202020);

  @override Color get border => const Color(0xFF2A2A2A);
  @override Color get borderFocus => const Color(0xFF404040);
  @override Color get divider => const Color(0xFF202020);

  @override Color get accent => const Color(0xFFAAAAAA);
  @override Color get accentBg => const Color(0xFF101010);
  @override Color get accentMuted => const Color(0x33AAAAAA);

  @override Color get neonCyan => const Color(0xFF66CCCC);
  @override Color get neonMagenta => const Color(0xFFCC6688);
  @override Color get neonPurple => const Color(0xFF8866CC);
  @override Color get neonBlue => const Color(0xFF6688CC);

  @override LinearGradient get gradientAccent => const LinearGradient(
        colors: [Color(0xFFAAAAAA), Color(0xFFCCCCCC)],
      );
  @override LinearGradient get gradientNeon => const LinearGradient(
        colors: [Color(0xFF6688CC), Color(0xFFCC6688)],
      );
  @override LinearGradient get gradientWarm => const LinearGradient(
        colors: [Color(0xFFCCCCCC), Color(0xFF888888)],
      );
  @override LinearGradient get gradientCard => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0x1AAAAAAA), Color(0x0D888888)],
      );

  @override Color get stateOnRoute => const Color(0xFF88AACC);
  @override Color get stateOnTime => const Color(0xFFAACC88);
  @override Color get stateDelay => const Color(0xFFCCAA66);
  @override Color get stateCancelled => const Color(0xFFCC6666);
  @override Color get stateIdle => const Color(0xFF2A2A2A);

  @override Color get textHi => const Color(0xFFEEEEEE);
  @override Color get textMid => const Color(0xFF999999);
  @override Color get textLo => const Color(0xFF555555);
  @override Color get textDisabled => const Color(0xFF303030);

  @override Color get glassBg => const Color(0x22FFFFFF);
  @override Color get glassBorder => const Color(0x2DFFFFFF);
}

// ── Prefab list ────────────────────────────────────────────

final prefabPalettes = <AppPalette>[
  const AppPalette(
    id: 'default',
    name: 'Default',
    isDark: true,
    scheme: TransitDarkColors(),
    lightScheme: TransitLightColors(),
    darkScheme: TransitDarkColors(),
  ),
  // NOTA: las paletas de color no-default DEJAN lightScheme = null
  // a propósito. Con lightScheme=TransitLightColors() (genérico claro)
  // al cambiar a modo claro perdíamos la paleta seleccionada (Sunrise,
  // Forest, etc.). Sin lightScheme, el fallback `_deriveLightFromDark`
  // invierte luminosidades del darkScheme y mantiene el accent + matiz
  // de la paleta también en claro.
  const AppPalette(
    id: 'sunrise',
    name: 'Sunrise',
    isDark: true,
    scheme: TransitSunriseColors(),
    darkScheme: TransitSunriseColors(),
  ),
  const AppPalette(
    id: 'forest',
    name: 'Forest',
    isDark: true,
    scheme: TransitForestColors(),
    darkScheme: TransitForestColors(),
  ),
  const AppPalette(
    id: 'midnight',
    name: 'Midnight',
    isDark: true,
    scheme: TransitMidnightColors(),
    darkScheme: TransitMidnightColors(),
  ),
  const AppPalette(
    id: 'ocean',
    name: 'Ocean',
    isDark: true,
    scheme: TransitOceanColors(),
    darkScheme: TransitOceanColors(),
  ),
  const AppPalette(
    id: 'mono',
    name: 'Mono',
    isDark: true,
    scheme: TransitMonoColors(),
    darkScheme: TransitMonoColors(),
  ),
];

AppPalette paletteFromId(String id) =>
    prefabPalettes.firstWhere(
      (p) => p.id == id,
      orElse: () => prefabPalettes.first,
    );
