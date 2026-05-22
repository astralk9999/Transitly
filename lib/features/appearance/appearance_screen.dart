import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/providers/is_dark_provider.dart';
import '../../shared/providers/theme_provider.dart';
import '../../shared/widgets/smoke_background.dart';
import 'widgets/accessibility_section.dart';
import 'widgets/background_selector.dart';
import 'widgets/brightness_section.dart';
import 'widgets/font_section.dart';
import 'widgets/map_style_section.dart';
import 'widgets/palette_section.dart';
import 'widgets/reset_section.dart';
import 'widgets/storage_section.dart';

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
          tooltip: 'Volver',
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
                  PalettesSection(c: c, l10n: l10n),
                  const SizedBox(height: 16),
                  MapStyleSection(c: c, l10n: l10n),
                  const SizedBox(height: 16),
                  BrightnessSection(c: c, l10n: l10n, mode: mode),
                  const SizedBox(height: 16),
                  BackgroundSection(c: c, l10n: l10n),
                  const SizedBox(height: 16),
                  FontSection(c: c, l10n: l10n),
                  const SizedBox(height: 16),
                  AccessibilitySection(c: c, l10n: l10n),
                  const SizedBox(height: 16),
                  ResetSection(c: c, l10n: l10n),
                  const SizedBox(height: 16),
                  StorageSection(c: c, l10n: l10n),
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
