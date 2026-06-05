import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/models/user_preferences.dart';
import '../../shared/providers/is_dark_provider.dart';
import '../../shared/providers/locale_provider.dart';
import '../../shared/providers/theme_notifier.dart';
import '../../shared/providers/theme_provider.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/gradient_text.dart';
import '../../shared/widgets/smoke_background.dart';

class AccessibilitySettingsScreen extends ConsumerWidget {
  const AccessibilitySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = isDarkMode(ref, context);
    final c = TransitColorScheme.of(isDark);
    final mode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final highContrast = ref.watch(
        themeNotifierProvider.select((n) => n.highContrast));
    final mq = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: c.bgRoot,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.textMid),
          tooltip: AppLocalizations.of(context).actionBack,
          onPressed: () => context.pop(),
        ),
        title: Text(AppLocalizations.of(context).accessibilityTitle,
            style: TransitTypography.sectionTitle(c.textHi)),
        centerTitle: false,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: SmokeBackground(color: c.accent, isDark: isDark),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _ThemeSection(
                  mode: mode,
                  c: c,
                  highContrast: highContrast,
                  onChanged: (m) =>
                      ref.read(themeNotifierProvider).themeMode = m,
                  onHighContrastChanged: (v) =>
                      ref.read(themeNotifierProvider).highContrast = v,
                ),
                const SizedBox(height: 16),
                _SystemPreferencesSection(mq: mq, c: c),
                const SizedBox(height: 16),
                _DyslexiaSection(c: c),
                const SizedBox(height: 16),
                _ColorBlindSection(c: c),
                const SizedBox(height: 16),
                _LanguageSection(
                  locale: locale,
                  c: c,
                  onChanged: (l) =>
                      ref.read(localeProvider.notifier).state = l,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeSection extends StatelessWidget {
  const _ThemeSection({
    required this.mode,
    required this.c,
    required this.highContrast,
    required this.onChanged,
    required this.onHighContrastChanged,
  });

  final ThemeMode mode;
  final TransitColorScheme c;
  final bool highContrast;
  final ValueChanged<ThemeMode> onChanged;
  final ValueChanged<bool> onHighContrastChanged;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      blur: 16,
      fillOpacity: 0.05,
      borderRadius: 14,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientText(
            AppLocalizations.of(context).accessibilityThemeSection,
            style: GoogleFonts.ibmPlexMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
            gradient: c.gradientAccent,
          ),
          const SizedBox(height: 12),
          _ThemeOption(
            label: AppLocalizations.of(context).accessibilityThemeSystem,
            subtitle: AppLocalizations.of(context).accessibilityThemeSystemSubtitle,
            selected: mode == ThemeMode.system,
            c: c,
            onTap: () => onChanged(ThemeMode.system),
          ),
          _ThemeOption(
            label: AppLocalizations.of(context).accessibilityThemeLight,
            subtitle: AppLocalizations.of(context).accessibilityThemeLightSubtitle,
            selected: mode == ThemeMode.light,
            c: c,
            onTap: () => onChanged(ThemeMode.light),
          ),
          _ThemeOption(
            label: AppLocalizations.of(context).accessibilityThemeDark,
            subtitle: AppLocalizations.of(context).accessibilityThemeDarkSubtitle,
            selected: mode == ThemeMode.dark,
            c: c,
            onTap: () => onChanged(ThemeMode.dark),
          ),
          const Divider(height: 24),
          Semantics(
            label: AppLocalizations.of(context).accessibilityHighContrast,
            selected: highContrast,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLocalizations.of(context).accessibilityHighContrast,
                          style: TransitTypography.bodyPrimary(c.textHi)),
                      Text(AppLocalizations.of(context).appearanceHighContrastSubtitle,
                          style: TransitTypography.bodySmall(c.textLo)),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: highContrast,
                  activeTrackColor: c.accent,
                  onChanged: onHighContrastChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.c,
    required this.onTap,
  });

  final String label;
  final String subtitle;
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
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected ? c.accent : c.textMid,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TransitTypography.bodyPrimary(c.textHi)),
                    Text(subtitle,
                        style: TransitTypography.bodySmall(c.textLo)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SystemPreferencesSection extends StatelessWidget {
  const _SystemPreferencesSection({required this.mq, required this.c});

  final MediaQueryData mq;
  final TransitColorScheme c;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      blur: 16,
      fillOpacity: 0.05,
      borderRadius: 14,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientText(
            AppLocalizations.of(context).accessibilitySystemPreferencesSection,
            style: GoogleFonts.ibmPlexMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
            gradient: c.gradientAccent,
          ),
          const SizedBox(height: 12),
            _PrefRow(
            label: AppLocalizations.of(context).accessibilitySystemPrefAnimations,
            value: mq.disableAnimations
                ? AppLocalizations.of(context).accessibilitySystemPrefReduced
                : AppLocalizations.of(context).accessibilitySystemPrefEnabled,
            c: c,
          ),
          _PrefRow(
            label: AppLocalizations.of(context).accessibilitySystemPrefTextSize,
            value: '${(mq.textScaler.scale(1).toDouble() * 100).round()}%',
            c: c,
          ),
          _PrefRow(
            label: AppLocalizations.of(context).accessibilityHighContrast,
            value: mq.highContrast
                ? AppLocalizations.of(context).accessibilitySystemPrefActivated
                : AppLocalizations.of(context).accessibilitySystemPrefDeactivated,
            c: c,
          ),
          _PrefRow(
            label: AppLocalizations.of(context).accessibilitySystemPrefBoldText,
            value: mq.boldText
                ? AppLocalizations.of(context).accessibilitySystemPrefActivated
                : AppLocalizations.of(context).accessibilitySystemPrefDeactivated,
            c: c,
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).accessibilitySystemPrefFootnote,
            style: TransitTypography.bodySmall(c.textLo),
          ),
        ],
      ),
    );
  }
}

class _PrefRow extends StatelessWidget {
  const _PrefRow({required this.label, required this.value, required this.c});

  final String label;
  final String value;
  final TransitColorScheme c;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: TransitTypography.bodyPrimary(c.textMid)),
          ),
          Text(
            value,
            style: GoogleFonts.ibmPlexMono(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: c.textHi,
            ),
          ),
        ],
      ),
    );
  }
}

class _DyslexiaSection extends ConsumerWidget {
  const _DyslexiaSection({required this.c});

  final TransitColorScheme c;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final dyslexia = ref
        .watch(themeNotifierProvider.select((n) => n.dyslexiaFontEnabled));

    return GlassCard(
      blur: 16,
      fillOpacity: 0.05,
      borderRadius: 14,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientText(
            l10n.appearanceDyslexiaFont,
            style: GoogleFonts.ibmPlexMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
            gradient: c.gradientAccent,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Usa OpenDyslexic, una fuente diseñada para mejorar la '
                  'legibilidad en personas con dislexia.',
                  style: TransitTypography.bodySmall(c.textLo),
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

class _ColorBlindSection extends ConsumerWidget {
  const _ColorBlindSection({required this.c});

  final TransitColorScheme c;

  String _label(AppLocalizations l10n, ColorBlindMode mode) {
    return switch (mode) {
      ColorBlindMode.none => l10n.appearanceColorBlindNone,
      ColorBlindMode.protanopia => l10n.appearanceColorBlindProtanopia,
      ColorBlindMode.deuteranopia => l10n.appearanceColorBlindDeuteranopia,
      ColorBlindMode.tritanopia => l10n.appearanceColorBlindTritanopia,
      ColorBlindMode.protanomaly => l10n.appearanceColorBlindProtanomaly,
      ColorBlindMode.deuteranomaly => l10n.appearanceColorBlindDeuteranomaly,
      ColorBlindMode.tritanomaly => l10n.appearanceColorBlindTritanomaly,
      ColorBlindMode.achromatopsia => l10n.appearanceColorBlindAchromatopsia,
      ColorBlindMode.achromatomaly => l10n.appearanceColorBlindAchromatomaly,
    };
  }

  void _showSheet(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final cbm = ref.read(themeNotifierProvider).colorBlindMode;
    showModalBottomSheet<ColorBlindMode>(
      context: context,
      backgroundColor: c.bgRaised,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: c.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.appearanceColorBlindSheetTitle,
                    style: TransitTypography.sectionLabel(c.textHi),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: ColorBlindMode.values.map((mode) {
                    return RadioListTile<ColorBlindMode>(
                      value: mode,
                      groupValue: cbm,
                      activeColor: c.accent,
                      title: Text(
                        _label(l10n, mode),
                        style: TransitTypography.bodyPrimary(c.textHi),
                      ),
                      onChanged: (v) {
                        if (v != null) {
                          ref.read(themeNotifierProvider).colorBlindMode = v;
                        }
                        Navigator.pop(sheetContext, v);
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cbm = ref
        .watch(themeNotifierProvider.select((n) => n.colorBlindMode));

    return GlassCard(
      blur: 16,
      fillOpacity: 0.05,
      borderRadius: 14,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientText(
            l10n.appearanceColorBlindMode,
            style: GoogleFonts.ibmPlexMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
            gradient: c.gradientAccent,
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _showSheet(context, ref, l10n),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _label(l10n, cbm),
                    style: TransitTypography.bodyPrimary(c.textHi),
                  ),
                ),
                Icon(Icons.unfold_more, size: 18, color: c.textMid),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageSection extends StatelessWidget {
  const _LanguageSection({
    required this.locale,
    required this.c,
    required this.onChanged,
  });

  final Locale? locale;
  final TransitColorScheme c;
  final ValueChanged<Locale?> onChanged;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      blur: 16,
      fillOpacity: 0.05,
      borderRadius: 14,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientText(
            AppLocalizations.of(context).accessibilityLanguageSection,
            style: GoogleFonts.ibmPlexMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
            gradient: c.gradientAccent,
          ),
          const SizedBox(height: 12),
          _ThemeOption(
            label: AppLocalizations.of(context).accessibilityThemeSystem,
            subtitle: AppLocalizations.of(context).accessibilityLanguageSystemSubtitle,
            selected: locale == null,
            c: c,
            onTap: () => onChanged(null),
          ),
          _ThemeOption(
            label: AppLocalizations.of(context).accessibilityLanguageEs,
            subtitle: AppLocalizations.of(context).accessibilityLanguageEsSubtitle,
            selected: locale?.languageCode == 'es',
            c: c,
            onTap: () => onChanged(const Locale('es')),
          ),
          _ThemeOption(
            label: AppLocalizations.of(context).accessibilityLanguageEn,
            subtitle: AppLocalizations.of(context).accessibilityLanguageEnSubtitle,
            selected: locale?.languageCode == 'en',
            c: c,
            onTap: () => onChanged(const Locale('en')),
          ),
          _ThemeOption(
            label: AppLocalizations.of(context).accessibilityLanguageAr,
            subtitle: AppLocalizations.of(context).accessibilityLanguageArSubtitle,
            selected: locale?.languageCode == 'ar',
            c: c,
            onTap: () => onChanged(const Locale('ar')),
          ),
        ],
      ),
    );
  }
}
