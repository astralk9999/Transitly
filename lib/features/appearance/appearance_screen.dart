import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/transit_colors.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/providers/is_dark_provider.dart';
import '../../shared/providers/theme_provider.dart';
import '../../shared/widgets/responsive_scaffold.dart';
import '../../shared/widgets/transit_app_bar.dart';
import 'widgets/accessibility_section.dart';
import 'widgets/background_selector.dart';
import 'widgets/brightness_section.dart';
import 'widgets/font_section.dart';
import 'widgets/map_style_section.dart';
import 'widgets/palette_section.dart';
import 'widgets/reset_section.dart';
import 'widgets/storage_section.dart';

class AppearanceScreen extends ConsumerStatefulWidget {
  const AppearanceScreen({super.key});

  @override
  ConsumerState<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends ConsumerState<AppearanceScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enterCtrl;
  late final Animation<double> _enterFade;
  late final Animation<Offset> _enterSlide;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _enterFade = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutCubic);
    _enterSlide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(_enterFade);
    // El primer frame queda con el BackgroundWrapper ya pintado; al
    // arrancar la animacion el body entra con fade+slide suave y no se
    // ve la superposicion previa del shader/scaffold debajo.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _enterCtrl.forward();
    });
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = isDarkMode(ref, context);
    final c = TransitColorScheme.of(isDark);
    final mode = ref.watch(themeModeProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: TransitAppBar(title: l10n.appearanceTitle, transparent: true),
      body: FadeTransition(
        opacity: _enterFade,
        child: SlideTransition(
          position: _enterSlide,
          child: SafeArea(
            top: false,
            child: ContentConstraints(
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
          ),
        ),
      ),
    );
  }
}
