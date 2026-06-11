import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/providers/is_dark_provider.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/gradient_text.dart';
import '../../shared/widgets/transit_app_bar.dart';

class WidgetsSettingsScreen extends ConsumerStatefulWidget {
  const WidgetsSettingsScreen({super.key});

  @override
  ConsumerState<WidgetsSettingsScreen> createState() =>
      _WidgetsSettingsScreenState();
}

class _WidgetsSettingsScreenState
    extends ConsumerState<WidgetsSettingsScreen> {
  final _stopController = TextEditingController();
  final _lineController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedConfig();
  }

  Future<void> _loadSavedConfig() async {
    final prefs = await SharedPreferences.getInstance();
    _stopController.text = prefs.getString('widget_fav_stop') ?? '';
    _lineController.text = prefs.getString('widget_fav_line') ?? '';
    setState(() {});
  }

  Future<void> _saveConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('widget_fav_stop', _stopController.text.trim());
    await prefs.setString('widget_fav_line', _lineController.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).widgetsConfigSaved),
          backgroundColor: TransitColorScheme.of(
            isDarkMode(ref, context),
          ).accent,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _stopController.dispose();
    _lineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = isDarkMode(ref, context);
    final c = TransitColorScheme.of(isDark);
    final l10n = AppLocalizations.of(context);
    final isAndroid = Platform.isAndroid;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: TransitAppBar(title: l10n.widgetsTitle, transparent: true),
      body: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _InstructionsSection(
                        l10n: l10n,
                        c: c,
                        isAndroid: isAndroid,
                      ),
                      const SizedBox(height: 16),
                      _ConfigSection(
                        l10n: l10n,
                        c: c,
                        stopController: _stopController,
                        lineController: _lineController,
                        onSave: _saveConfig,
                      ),
                      const SizedBox(height: 16),
                      _HowToAddSection(
                        l10n: l10n,
                        c: c,
                        isAndroid: isAndroid,
                      ),
                    ],
                  ),
    );
  }
}

class _InstructionsSection extends StatelessWidget {
  const _InstructionsSection({
    required this.l10n,
    required this.c,
    required this.isAndroid,
  });

  final AppLocalizations l10n;
  final TransitColorScheme c;
  final bool isAndroid;

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
            l10n.widgetsSectionInstructions,
            style: GoogleFonts.ibmPlexMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
            gradient: c.gradientAccent,
          ),
          const SizedBox(height: 12),
          Icon(
            isAndroid ? Icons.android : Icons.phone_iphone,
            size: 32,
            color: c.accent,
          ),
          const SizedBox(height: 8),
          Text(
            isAndroid
                ? l10n.widgetsInstructionsAndroid
                : l10n.widgetsInstructionsIos,
            style: TransitTypography.bodyPrimary(c.textHi),
          ),
        ],
      ),
    );
  }
}

class _ConfigSection extends StatelessWidget {
  const _ConfigSection({
    required this.l10n,
    required this.c,
    required this.stopController,
    required this.lineController,
    required this.onSave,
  });

  final AppLocalizations l10n;
  final TransitColorScheme c;
  final TextEditingController stopController;
  final TextEditingController lineController;
  final VoidCallback onSave;

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
            'CONFIGURACI\u00d3N',
            style: GoogleFonts.ibmPlexMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
            gradient: c.gradientAccent,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: stopController,
            style: TransitTypography.bodyPrimary(c.textHi),
            decoration: InputDecoration(
              labelText: l10n.widgetsFavoriteStop,
              labelStyle: TransitTypography.bodySmall(c.textMid),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: c.textLo.withValues(alpha: 0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: c.accent),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: lineController,
            style: TransitTypography.bodyPrimary(c.textHi),
            decoration: InputDecoration(
              labelText: l10n.widgetsFavoriteLine,
              labelStyle: TransitTypography.bodySmall(c.textMid),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: c.textLo.withValues(alpha: 0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: c.accent),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: c.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: onSave,
              child: Text(
                l10n.actionSave,
                style: TransitTypography.bodyPrimary(Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HowToAddSection extends StatelessWidget {
  const _HowToAddSection({
    required this.l10n,
    required this.c,
    required this.isAndroid,
  });

  final AppLocalizations l10n;
  final TransitColorScheme c;
  final bool isAndroid;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      blur: 16,
      fillOpacity: 0.05,
      borderRadius: 14,
      padding: const EdgeInsets.all(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _showHowToDialog(context),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 20, color: c.accent),
              const SizedBox(width: 10),
              Text(
                l10n.widgetsHowToAdd,
                style: TransitTypography.bodyPrimary(c.accent),
              ),
              const Spacer(),
              Icon(Icons.chevron_right, size: 20, color: c.accent),
            ],
          ),
        ),
      ),
    );
  }

  void _showHowToDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: c.bgSurface,
          title: Text(l10n.widgetsHowToAdd,
              style: TransitTypography.subheading(c.textHi)),
          content: Text(
            isAndroid
                ? l10n.widgetsInstructionsAndroid
                : l10n.widgetsInstructionsIos,
            style: TransitTypography.bodyPrimary(c.textHi),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.actionClose,
                  style: TextStyle(color: c.accent)),
            ),
          ],
        );
      },
    );
  }
}
