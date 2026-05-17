import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';

import '../../core/theme/backgrounds/prefab_backgrounds.dart';
import '../../core/theme/palettes/prefab_palettes.dart';
import '../../core/utils/app_logger.dart';
import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../data/cache/hive_init.dart';
import '../../features/map/map_config.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/models/offline_region.dart';
import '../../shared/models/user_preferences.dart';
import '../../shared/providers/is_dark_provider.dart';
import '../../shared/providers/theme_notifier.dart';
import '../../shared/providers/theme_provider.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/gradient_text.dart';
import '../../shared/widgets/smoke_background.dart';

class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = isDarkMode(ref, context);
    final c = TransitColorScheme.of(isDark);
    final mode = ref.watch(themeModeProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: c.bgRoot,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.textMid),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.appearanceTitle,
            style: TransitTypography.sectionTitle(c.textHi)),
        centerTitle: false,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: SmokeBackground(color: c.accent, isDark: isDark),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PalettesSection(c: c, l10n: l10n),
                  const SizedBox(height: 16),
                  _MapStyleSection(c: c, l10n: l10n),
                  const SizedBox(height: 16),
                  _BrightnessSection(c: c, l10n: l10n, mode: mode),
                  const SizedBox(height: 16),
                  _BackgroundSection(c: c, l10n: l10n),
                  const SizedBox(height: 16),
                  _TextSection(c: c, l10n: l10n),
                  const SizedBox(height: 16),
                  _AccessibilitySection(c: c, l10n: l10n),
                  const SizedBox(height: 16),
                  _ResetSection(c: c, l10n: l10n),
                  const SizedBox(height: 16),
                  _StorageSection(c: c, l10n: l10n),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section: Palettes ───────────────────────────────────────

class _PalettesSection extends ConsumerWidget {
  const _PalettesSection({required this.c, required this.l10n});

  final TransitColorScheme c;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paletteId = ref.watch(
        themeNotifierProvider.select((n) => n.paletteId));

    return GlassCard(
      blur: 16,
      fillOpacity: 0.05,
      borderRadius: 14,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientText(
            l10n.appearancePalettesSection,
            style: GoogleFonts.ibmPlexMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
            gradient: c.gradientAccent,
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.2,
            ),
            itemCount: prefabPalettes.length,
            itemBuilder: (_, i) {
              final p = prefabPalettes[i];
              final selected = p.id == paletteId;
              return _PaletteCard(
                palette: p,
                selected: selected,
                c: c,
                onTap: () {
                  ref.read(themeNotifierProvider).paletteId = p.id;
                },
              );
            },
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/appearance/custom'),
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.appearanceCustomPaletteAdd,
                  style: TransitTypography.bodyPrimary(c.accent)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: c.accent.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaletteCard extends StatelessWidget {
  const _PaletteCard({
    required this.palette,
    required this.selected,
    required this.c,
    required this.onTap,
  });

  final dynamic palette;
  final bool selected;
  final TransitColorScheme c;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accentColor = (palette.scheme as TransitColorScheme).accent;

    return Semantics(
      button: true,
      selected: selected,
      label: palette.name.toString(),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: accentColor.withValues(alpha: 0.10),
            border: Border.all(
              color: selected ? accentColor : accentColor.withValues(alpha: 0.25),
              width: selected ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                palette.name.toString(),
                style: TransitTypography.bodyPrimary(
                  selected ? accentColor : c.textHi,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section: Map Style ──────────────────────────────────────

class _MapStyleSection extends ConsumerWidget {
  const _MapStyleSection({required this.c, required this.l10n});

  final TransitColorScheme c;
  final AppLocalizations l10n;

  String _styleLabel(String key) {
    return switch (key) {
      'streets' => l10n.mapStyleStreets,
      'basic' => l10n.mapStyleBasic,
      'bright' => l10n.mapStyleBright,
      'dark' => l10n.mapStyleDark,
      'light' => l10n.mapStyleLight,
      _ => key,
    };
  }

  IconData _styleIcon(String key) {
    return switch (key) {
      'streets' => Icons.map,
      'basic' => Icons.map_outlined,
      'bright' => Icons.wb_sunny,
      'dark' => Icons.nightlight_round,
      'light' => Icons.light_mode,
      _ => Icons.map,
    };
  }

  Color _stylePreviewColor(String key) {
    return switch (key) {
      'streets' => const Color(0xFF4A90D9),
      'basic' => const Color(0xFF7B9EBD),
      'bright' => const Color(0xFFF5A623),
      'dark' => const Color(0xFF1C1C2E),
      'light' => const Color(0xFFF0F0F0),
      _ => c.accent,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapStyle = ref.watch(
        themeNotifierProvider.select((n) => n.mapStyle));
    final styleKeys = MapConfig.mapStyles.keys.toList();

    return GlassCard(
      blur: 16,
      fillOpacity: 0.05,
      borderRadius: 14,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientText(
            l10n.appearanceMapStyleSection,
            style: GoogleFonts.ibmPlexMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
            gradient: c.gradientAccent,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: styleKeys.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final key = styleKeys[i];
                final selected = key == mapStyle;
                return _MapStylePreview(
                  styleKey: key,
                  label: _styleLabel(key),
                  icon: _styleIcon(key),
                  previewColor: _stylePreviewColor(key),
                  selected: selected,
                  c: c,
                  onTap: () {
                    ref.read(themeNotifierProvider).mapStyle = key;
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MapStylePreview extends StatelessWidget {
  const _MapStylePreview({
    required this.styleKey,
    required this.label,
    required this.icon,
    required this.previewColor,
    required this.selected,
    required this.c,
    required this.onTap,
  });

  final String styleKey;
  final String label;
  final IconData icon;
  final Color previewColor;
  final bool selected;
  final TransitColorScheme c;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          width: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: selected
                ? c.accent.withValues(alpha: 0.15)
                : c.bgRaised,
            border: Border.all(
              color: selected ? c.accent : c.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: previewColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? c.accent : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Icon(icon, size: 14, color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text(label,
                  style: TransitTypography.bodySmall(
                    selected ? c.accent : c.textMid,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section: Brightness ─────────────────────────────────────

class _BrightnessSection extends ConsumerWidget {
  const _BrightnessSection({
    required this.c,
    required this.l10n,
    required this.mode,
  });

  final TransitColorScheme c;
  final AppLocalizations l10n;
  final ThemeMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassCard(
      blur: 16,
      fillOpacity: 0.05,
      borderRadius: 14,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientText(
            l10n.appearanceBrightnessSection,
            style: GoogleFonts.ibmPlexMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
            gradient: c.gradientAccent,
          ),
          const SizedBox(height: 12),
          SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment<ThemeMode>(
                value: ThemeMode.system,
                label: Text(l10n.appearanceBrightnessSystem,
                    style: TransitTypography.bodySmall(c.textHi)),
              ),
              ButtonSegment<ThemeMode>(
                value: ThemeMode.light,
                label: Text(l10n.appearanceBrightnessLight,
                    style: TransitTypography.bodySmall(c.textHi)),
              ),
              ButtonSegment<ThemeMode>(
                value: ThemeMode.dark,
                label: Text(l10n.appearanceBrightnessDark,
                    style: TransitTypography.bodySmall(c.textHi)),
              ),
            ],
            selected: {mode},
            onSelectionChanged: (newMode) {
              ref.read(themeModeProvider.notifier).state = newMode.first;
            },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return c.accent;
                return c.bgRaised;
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return c.textMid;
              }),
              side: WidgetStateProperty.all(
                BorderSide(color: c.border, width: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section: Background ─────────────────────────────────────

class _BackgroundSection extends ConsumerWidget {
  const _BackgroundSection({required this.c, required this.l10n});

  final TransitColorScheme c;
  final AppLocalizations l10n;

  String _bgName(String id) {
    return switch (id) {
      'none' => l10n.appearanceBgNone,
      'shaders/smoke.frag' => l10n.appearanceBgSmoke,
      _ when id.startsWith('gradient:') => l10n.appearanceBgGradient,
      'assets/bg/soft_grid.png' => l10n.appearanceBgGrid,
      'assets/bg/topo_lines.png' => l10n.appearanceBgTopo,
      _ => id,
    };
  }

  IconData _bgIcon(String id) {
    return switch (id) {
      'none' => Icons.block,
      'shaders/smoke.frag' => Icons.blur_on,
      _ when id.startsWith('gradient:') => Icons.gradient,
      'assets/bg/soft_grid.png' => Icons.grid_4x4,
      'assets/bg/topo_lines.png' => Icons.show_chart,
      _ => Icons.wallpaper,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bgId = ref.watch(
        themeNotifierProvider.select((n) => n.backgroundId));
    final bgEnabled = ref.watch(
        themeNotifierProvider.select((n) => n.backgroundEnabled));
    final bgOpacity = ref.watch(
        themeNotifierProvider.select((n) => n.backgroundOpacity));

    return GlassCard(
      blur: 16,
      fillOpacity: 0.05,
      borderRadius: 14,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientText(
            l10n.appearanceBackgroundSection,
            style: GoogleFonts.ibmPlexMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
            gradient: c.gradientAccent,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.appearanceShowBackground,
                  style: TransitTypography.bodyPrimary(c.textHi),
                ),
              ),
              Switch.adaptive(
                value: bgEnabled,
                activeTrackColor: c.accent,
                onChanged: (v) {
                  ref.read(themeNotifierProvider).backgroundEnabled = v;
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: prefabBackgrounds.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final bg = prefabBackgrounds[i];
                final selected = bg.id == bgId;
                return _BgPreview(
                  id: bg.id,
                  name: _bgName(bg.id),
                  icon: _bgIcon(bg.id),
                  selected: selected,
                  c: c,
                  onTap: () {
                    ref.read(themeNotifierProvider).backgroundId = bg.id;
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 140,
                child: Text(
                  l10n.appearanceBackgroundOpacity,
                  style: TransitTypography.bodySmall(c.textMid),
                ),
              ),
              Expanded(
                child: Slider(
                  value: bgOpacity,
                  min: 0.0,
                  max: 1.0,
                  divisions: 20,
                  activeColor: c.accent,
                  inactiveColor: c.bgRaised,
                  onChanged: (v) {
                    ref.read(themeNotifierProvider).backgroundOpacity = v;
                  },
                ),
              ),
              SizedBox(
                width: 40,
                child: Text(
                  '${(bgOpacity * 100).round()}%',
                  style: TransitTypography.bodySmall(c.textMid),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BgPreview extends StatelessWidget {
  const _BgPreview({
    required this.id,
    required this.name,
    required this.icon,
    required this.selected,
    required this.c,
    required this.onTap,
  });

  final String id;
  final String name;
  final IconData icon;
  final bool selected;
  final TransitColorScheme c;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: name,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          width: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: selected
                ? c.accent.withValues(alpha: 0.15)
                : c.bgRaised,
            border: Border.all(
              color: selected ? c.accent : c.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22,
                  color: selected ? c.accent : c.textMid),
              const SizedBox(height: 4),
              Text(name,
                  style: TransitTypography.bodySmall(
                    selected ? c.accent : c.textMid,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section: Text ───────────────────────────────────────────

class _TextSection extends ConsumerWidget {
  const _TextSection({required this.c, required this.l10n});

  final TransitColorScheme c;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontScale = ref.watch(
        themeNotifierProvider.select((n) => n.fontScale));
    final dyslexia = ref.watch(
        themeNotifierProvider.select((n) => n.dyslexiaFontEnabled));

    return GlassCard(
      blur: 16,
      fillOpacity: 0.05,
      borderRadius: 14,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientText(
            l10n.appearanceTextSection,
            style: GoogleFonts.ibmPlexMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
            gradient: c.gradientAccent,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.appearanceFontScale,
                  style: TransitTypography.bodyPrimary(c.textHi),
                ),
              ),
              SizedBox(
                width: 44,
                child: Text(
                  '${(fontScale * 100).round()}%',
                  style: TransitTypography.bodySmall(c.textMid),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          Slider(
            value: fontScale,
            min: 0.85,
            max: 1.4,
            divisions: 11,
            activeColor: c.accent,
            inactiveColor: c.bgRaised,
            onChanged: (v) {
              ref.read(themeNotifierProvider).fontScale = v;
            },
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.bgRaised,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              l10n.appearanceTextPreview,
              style: GoogleFonts.dmSans(
                fontSize: 13 * fontScale,
                fontWeight: FontWeight.w300,
                height: 1.5,
                color: c.textHi,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.appearanceDyslexiaFont,
                  style: TransitTypography.bodyPrimary(c.textHi),
                ),
              ),
              Switch.adaptive(
                value: dyslexia,
                activeTrackColor: c.accent,
                onChanged: (v) {
                  ref.read(themeNotifierProvider).dyslexiaFontEnabled = v;
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Section: Visual Accessibility ───────────────────────────

class _AccessibilitySection extends ConsumerWidget {
  const _AccessibilitySection({required this.c, required this.l10n});

  final TransitColorScheme c;
  final AppLocalizations l10n;

  String _cbmLabel(ColorBlindMode mode) {
    return switch (mode) {
      ColorBlindMode.none => l10n.appearanceColorBlindNone,
      ColorBlindMode.protanopia => l10n.appearanceColorBlindProtanopia,
      ColorBlindMode.deuteranopia => l10n.appearanceColorBlindDeuteranopia,
      ColorBlindMode.tritanopia => l10n.appearanceColorBlindTritanopia,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cbm = ref.watch(
        themeNotifierProvider.select((n) => n.colorBlindMode));
    final reduceMotion = ref.watch(
        themeNotifierProvider.select((n) => n.reduceMotion));
    final highContrast = ref.watch(
        themeNotifierProvider.select((n) => n.highContrast));

    return GlassCard(
      blur: 16,
      fillOpacity: 0.05,
      borderRadius: 14,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientText(
            l10n.appearanceAccessibilitySection,
            style: GoogleFonts.ibmPlexMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
            gradient: c.gradientAccent,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.appearanceColorBlindMode,
                  style: TransitTypography.bodyPrimary(c.textHi),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<ColorBlindMode>(
                value: cbm,
                underline: const SizedBox.shrink(),
                dropdownColor: c.bgRaised,
                style: TransitTypography.bodySmall(c.textHi),
                icon: Icon(Icons.expand_more, color: c.textMid, size: 20),
                selectedItemBuilder: (_) => ColorBlindMode.values
                    .map((m) => Align(
                          alignment: Alignment.centerRight,
                          child: Text(_cbmLabel(m),
                              style:
                                  TransitTypography.bodySmall(c.textHi)),
                        ))
                    .toList(),
                items: ColorBlindMode.values
                    .map((m) => DropdownMenuItem(
                          value: m,
                          child: Text(_cbmLabel(m)),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    ref.read(themeNotifierProvider).colorBlindMode = v;
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.appearanceReduceMotion,
                  style: TransitTypography.bodyPrimary(c.textHi),
                ),
              ),
              Switch.adaptive(
                value: reduceMotion,
                activeTrackColor: c.accent,
                onChanged: (v) {
                  ref.read(themeNotifierProvider).reduceMotion = v;
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.appearanceHighContrast,
                      style: TransitTypography.bodyPrimary(c.textHi),
                    ),
                    Text(
                      l10n.appearanceHighContrastSubtitle,
                      style: TransitTypography.bodySmall(c.textLo),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: highContrast,
                activeTrackColor: c.accent,
                onChanged: (v) {
                  ref.read(themeNotifierProvider).highContrast = v;
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Section: Reset ──────────────────────────────────────────

class _ResetSection extends ConsumerWidget {
  const _ResetSection({required this.c, required this.l10n});

  final TransitColorScheme c;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassCard(
      blur: 16,
      fillOpacity: 0.05,
      borderRadius: 14,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: () => _confirmReset(context, ref),
            icon: Icon(Icons.restore, color: c.textMid, size: 18),
            label: Text(
              l10n.appearanceResetButton,
              style: TransitTypography.bodyPrimary(c.textMid),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: c.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.bgSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: c.border, width: 1),
        ),
        title: Text(l10n.appearanceResetButton,
            style: TransitTypography.heading(c.textHi)),
        content: Text(l10n.appearanceResetConfirm,
            style: TransitTypography.bodyPrimary(c.textMid)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.actionCancel,
                style: TransitTypography.bodyPrimary(c.textMid)),
          ),
          TextButton(
            onPressed: () {
              final tn = ref.read(themeNotifierProvider);
              tn.paletteId = 'default';
              tn.backgroundId = 'smoke';
              tn.backgroundEnabled = true;
              tn.backgroundOpacity = 1.0;
              tn.fontScale = 1.0;
              tn.colorBlindMode = ColorBlindMode.none;
              tn.dyslexiaFontEnabled = false;
              tn.reduceMotion = false;
              tn.highContrast = false;
              tn.mapStyle = 'streets';
              ref.read(themeModeProvider.notifier).state = ThemeMode.dark;
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.appearanceResetDone),
                  backgroundColor: c.bgRaised,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            child: Text(l10n.appearanceResetButton,
                style: TransitTypography.bodyPrimary(c.accent)),
          ),
        ],
      ),
    );
  }
}

// ── Section: Storage ─────────────────────────────────────────

class _StorageSection extends ConsumerWidget {
  const _StorageSection({required this.c, required this.l10n});

  final TransitColorScheme c;
  final AppLocalizations l10n;

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  static int _fileSize(String boxName) {
    try {
      final path = Hive.box(boxName).path;
      if (path != null) return File(path).lengthSync();
    } catch (e) {
      AppLogger.warn('Appearance', 'file size unavailable for $boxName', e);
    }
    return 0;
  }

  static int _directorySize(Directory dir) {
    var total = 0;
    try {
      if (!dir.existsSync()) return 0;
      for (final entity in dir.listSync(recursive: true)) {
        if (entity is File) total += entity.lengthSync();
      }
    } catch (e) {
      AppLogger.warn('Appearance', 'directory size scan failed', e);
    }
    return total;
  }

  int _computeHiveSize() {
    var total = 0;
    const boxNames = [
      HiveBoxes.routes,
      HiveBoxes.stops,
      HiveBoxes.schedules,
      HiveBoxes.operators,
      HiveBoxes.userPreferences,
      HiveBoxes.offlineRegions,
      HiveBoxes.alerts,
      HiveBoxes.incidents,
      HiveBoxes.routeFeedback,
      HiveBoxes.routeSuggestions,
      HiveBoxes.featureRequests,
      HiveBoxes.notifications,
      HiveBoxes.editorDrafts,
      HiveBoxes.authSessionMeta,
    ];
    for (final name in boxNames) {
      total += _fileSize(name);
    }
    return total;
  }

  int _computePendingSize() {
    var total = 0;
    for (final name in [HiveBoxes.pendingActions, HiveBoxes.deadLetterActions]) {
      total += _fileSize(name);
    }
    return total;
  }

  ({int sizeBytes, bool available}) _computeFmtcSize() {
    try {
      final hivePath = Hive.box(HiveBoxes.routes).path;
      if (hivePath == null) return (sizeBytes: 0, available: false);
      final appDir = File(hivePath).parent;
      final fmtcDir = Directory('${appDir.path}${Platform.pathSeparator}fmtc${Platform.pathSeparator}store');
      if (!fmtcDir.existsSync()) return (sizeBytes: 0, available: false);
      return (sizeBytes: _directorySize(fmtcDir), available: true);
    } catch (e) {
      AppLogger.warn('Appearance', 'FMTC size unavailable', e);
      return (sizeBytes: 0, available: false);
    }
  }

  Future<void> _clearCache(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.bgSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: c.border, width: 1),
        ),
        title: Text(l10n.appearanceStorageClearCache,
            style: TransitTypography.heading(c.textHi)),
        content: Text(l10n.appearanceStorageClearCacheConfirm,
            style: TransitTypography.bodyPrimary(c.textMid)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.actionCancel,
                style: TransitTypography.bodyPrimary(c.textMid)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.appearanceStorageClearCache,
                style: TransitTypography.bodyPrimary(c.accent)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await Hive.box<OfflineRegion>(HiveBoxes.offlineRegions).clear();
    } catch (e) {
      AppLogger.warn('Appearance', 'offline regions box clear failed', e);
    }

    try {
      final hivePath = Hive.box(HiveBoxes.routes).path;
      if (hivePath != null) {
        final appDir = File(hivePath).parent;
        final fmtcDir = Directory(
            '${appDir.path}${Platform.pathSeparator}fmtc${Platform.pathSeparator}store');
        if (fmtcDir.existsSync()) {
          await fmtcDir.delete(recursive: true);
        }
      }
    } catch (e) {
      AppLogger.warn('Appearance', 'FMTC cache delete failed', e);
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.appearanceStorageClearCacheDone),
          backgroundColor: c.bgRaised,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hiveSize = _computeHiveSize();
    final pendingSize = _computePendingSize();
    final fmtc = _computeFmtcSize();
    final totalSize = hiveSize + pendingSize + fmtc.sizeBytes;

    return GlassCard(
      blur: 16,
      fillOpacity: 0.05,
      borderRadius: 14,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientText(
            l10n.appearanceStorageSection,
            style: GoogleFonts.ibmPlexMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
            gradient: c.gradientAccent,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(l10n.appearanceStorageTotal,
                    style: TransitTypography.bodyPrimary(c.textHi)),
              ),
              Text(_formatBytes(totalSize),
                  style: TransitTypography.bodyPrimary(c.accent)),
            ],
          ),
          const SizedBox(height: 8),
          if (fmtc.available)
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(l10n.appearanceStorageFmtc,
                        style: TransitTypography.bodySmall(c.textMid)),
                  ),
                  Text(_formatBytes(fmtc.sizeBytes),
                      style: TransitTypography.bodySmall(c.textMid)),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(l10n.appearanceStorageHive,
                      style: TransitTypography.bodySmall(c.textMid)),
                ),
                Text(_formatBytes(hiveSize),
                    style: TransitTypography.bodySmall(c.textMid)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(l10n.appearanceStoragePending,
                      style: TransitTypography.bodySmall(c.textMid)),
                ),
                Text(_formatBytes(pendingSize),
                    style: TransitTypography.bodySmall(c.textMid)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(l10n.appearanceStorageMaxInfo,
              style: TransitTypography.bodySmall(c.textLo)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _clearCache(context),
              icon: Icon(Icons.delete_sweep, color: c.textMid, size: 18),
              label: Text(l10n.appearanceStorageClearCache,
                  style: TransitTypography.bodyPrimary(c.textMid)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: c.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
