import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../shared/providers/is_dark_provider.dart';
import '../../shared/providers/locale_provider.dart';
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
    final mq = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: c.bgRoot,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.textMid),
          onPressed: () => context.pop(),
        ),
        title: Text('ACCESIBILIDAD',
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
                  onChanged: (m) =>
                      ref.read(themeModeProvider.notifier).state = m,
                ),
                const SizedBox(height: 16),
                _SystemPreferencesSection(mq: mq, c: c),
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
    required this.onChanged,
  });

  final ThemeMode mode;
  final TransitColorScheme c;
  final ValueChanged<ThemeMode> onChanged;

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
            'TEMA',
            style: GoogleFonts.ibmPlexMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
            gradient: c.gradientAccent,
          ),
          const SizedBox(height: 12),
          _ThemeOption(
            label: 'Sistema',
            subtitle: 'Sigue la configuración del dispositivo',
            selected: mode == ThemeMode.system,
            c: c,
            onTap: () => onChanged(ThemeMode.system),
          ),
          _ThemeOption(
            label: 'Claro',
            subtitle: 'Fondo luminoso, alto contraste diurno',
            selected: mode == ThemeMode.light,
            c: c,
            onTap: () => onChanged(ThemeMode.light),
          ),
          _ThemeOption(
            label: 'Oscuro',
            subtitle: 'Fondo oscuro, menor consumo en OLED',
            selected: mode == ThemeMode.dark,
            c: c,
            onTap: () => onChanged(ThemeMode.dark),
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
            'PREFERENCIAS DEL SISTEMA',
            style: GoogleFonts.ibmPlexMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
            gradient: c.gradientAccent,
          ),
          const SizedBox(height: 12),
          _PrefRow(
            label: 'Animaciones',
            value: mq.disableAnimations ? 'Reducidas' : 'Habilitadas',
            c: c,
          ),
          _PrefRow(
            label: 'Tamaño de texto',
            value: '${(mq.textScaler.scale(1).toDouble() * 100).round()}%',
            c: c,
          ),
          _PrefRow(
            label: 'Alto contraste',
            value: mq.highContrast ? 'Activado' : 'Desactivado',
            c: c,
          ),
          _PrefRow(
            label: 'Texto en negrita',
            value: mq.boldText ? 'Activado' : 'Desactivado',
            c: c,
          ),
          const SizedBox(height: 8),
          Text(
            'Estos ajustes se leen del sistema operativo. Cámbialos desde los '
            'ajustes del dispositivo para que la app responda.',
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
            'IDIOMA',
            style: GoogleFonts.ibmPlexMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
            gradient: c.gradientAccent,
          ),
          const SizedBox(height: 12),
          _ThemeOption(
            label: 'Sistema',
            subtitle: 'Sigue el idioma del dispositivo',
            selected: locale == null,
            c: c,
            onTap: () => onChanged(null),
          ),
          _ThemeOption(
            label: 'Español',
            subtitle: 'Forzar idioma en español',
            selected: locale?.languageCode == 'es',
            c: c,
            onTap: () => onChanged(const Locale('es')),
          ),
          _ThemeOption(
            label: 'English',
            subtitle: 'Force English language',
            selected: locale?.languageCode == 'en',
            c: c,
            onTap: () => onChanged(const Locale('en')),
          ),
        ],
      ),
    );
  }
}
