import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/contrast_utils.dart';
import '../../core/theme/palettes/custom_colors.dart';
import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/providers/theme_notifier.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/transit_app_bar.dart';
import '../../shared/widgets/transit_button.dart';
import 'widgets/palette_color_picker.dart';

class CustomPaletteScreen extends ConsumerStatefulWidget {
  const CustomPaletteScreen({super.key});

  @override
  ConsumerState<CustomPaletteScreen> createState() =>
      _CustomPaletteScreenState();
}

class _CustomPaletteScreenState extends ConsumerState<CustomPaletteScreen> {
  late Color _primary;
  late Color _secondary;
  late Color _bgRoot;
  late Color _bgSurface;
  late Color _textHi;
  bool _saving = false;

  final _colorKeys = const ['primary', 'secondary', 'bgRoot', 'bgSurface', 'textHi'];

  @override
  void initState() {
    super.initState();
    final tn = ref.read(themeNotifierProvider);
    if (tn.isCustomPalette) {
      final cc = tn.customColors;
      _primary = cc['primary'] ?? const Color(0xFF977DDF);
      _secondary = cc['secondary'] ?? const Color(0xFF6C63FF);
      _bgRoot = cc['bgRoot'] ?? const Color(0xFF08081A);
      _bgSurface = cc['bgSurface'] ?? const Color(0xFF10102A);
      _textHi = cc['textHi'] ?? const Color(0xFFF0F0FA);
    } else {
      final scheme = tn.palette.scheme;
      _primary = scheme.accent;
      _secondary = scheme.neonPurple;
      _bgRoot = scheme.bgRoot;
      _bgSurface = scheme.bgSurface;
      _textHi = scheme.textHi;
    }
  }

  TransitColorScheme _buildScheme() => TransitCustomColors(
        primary: _primary,
        secondary: _secondary,
        bgRoot: _bgRoot,
        bgSurface: _bgSurface,
        textHi: _textHi,
      );

  Future<void> _pickColor(String key, Color current) async {
    final picked = await showColorPickerDialog(
      context,
      current,
      title: Text(_labelForKey(key), style: TransitTypography.subheading(current)),
      pickersEnabled: const {
        ColorPickerType.wheel: true,
        ColorPickerType.primary: true,
        ColorPickerType.accent: true,
        ColorPickerType.custom: true,
      },
      showRecentColors: false,
      showMaterialName: false,
      showColorName: false,
      showColorCode: true,
      copyPasteBehavior: const ColorPickerCopyPasteBehavior(
        copyFormat: ColorPickerCopyFormat.hexAARRGGBB,
      ),
    );
    if (!mounted) return;
    setState(() {
      switch (key) {
        case 'primary':
          _primary = picked;
        case 'secondary':
          _secondary = picked;
        case 'bgRoot':
          _bgRoot = picked;
        case 'bgSurface':
          _bgSurface = picked;
        case 'textHi':
          _textHi = picked;
      }
    });
  }

  String _labelForKey(String key) {
    return switch (key) {
      'primary' => l10n.appearanceCustomPalettePrimary,
      'secondary' => l10n.appearanceCustomPaletteSecondary,
      'bgRoot' => l10n.appearanceCustomPaletteBgRoot,
      'bgSurface' => l10n.appearanceCustomPaletteBgSurface,
      'textHi' => l10n.appearanceCustomPaletteTextHi,
      _ => key,
    };
  }

  Color _colorForKey(String key) {
    return switch (key) {
      'primary' => _primary,
      'secondary' => _secondary,
      'bgRoot' => _bgRoot,
      'bgSurface' => _bgSurface,
      'textHi' => _textHi,
      _ => _primary,
    };
  }

  Future<void> _onSave() async {
    setState(() => _saving = true);
    try {
      ref.read(themeNotifierProvider).setCustomPalette({
        'primary': _primary,
        'secondary': _secondary,
        'bgRoot': _bgRoot,
        'bgSurface': _bgSurface,
        'textHi': _textHi,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.appearanceCustomPaletteSaved),
            backgroundColor: _bgSurface,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  AppLocalizations get l10n => AppLocalizations.of(context);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final scheme = _buildScheme();
    final ratio = contrastRatio(scheme.textHi, scheme.bgSurface);
    final passesAA = ratio >= 4.5;

    return Scaffold(
      backgroundColor: c.bgRoot,
      body: Column(
        children: [
          TransitAppBar(
            title: l10n.appearanceCustomPaletteTitle,
            showBack: true,
            actions: [
              TransitButton(
                label: l10n.actionSave,
                isSmall: true,
                isPrimary: true,
                isLoading: _saving,
                onPressed: _onSave,
              ),
              const SizedBox(width: 8),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SectionLabel(
                      label: l10n.appearancePalettesSection, scheme: scheme),
                  const SizedBox(height: 12),
                  GlassCard(
                    blur: 16,
                    fillOpacity: 0.05,
                    borderRadius: 14,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: _colorKeys.map((key) {
                        return Padding(
                          padding: EdgeInsets.only(
                              bottom: key == _colorKeys.last ? 0 : 12),
                          child: PaletteColorField(
                            label: _labelForKey(key),
                            color: _colorForKey(key),
                            onTap: () => _pickColor(key, _colorForKey(key)),
                            scheme: scheme,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionLabel(
                      label: l10n.appearanceCustomPalettePreview,
                      scheme: scheme),
                  const SizedBox(height: 12),
                  _PreviewCard(scheme: scheme),
                  const SizedBox(height: 16),
                  _ContrastBadge(
                      ratio: ratio, passesAA: passesAA, scheme: scheme),
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.scheme});

  final String label;
  final TransitColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TransitTypography.sectionLabel(scheme.accent),
    );
  }
}


class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.scheme});

  final TransitColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      blur: 16,
      fillOpacity: 0.05,
      borderRadius: 14,
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: scheme.bgSurface,
          border: Border.all(color: scheme.border),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: scheme.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.directions_bus,
                      color: scheme.accent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Route 9A',
                          style: TransitTypography.routeCode(scheme.textHi)),
                      const SizedBox(height: 2),
                      Text('Centro → La Granja',
                          style:
                              TransitTypography.bodySmall(scheme.textMid)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: scheme.accentBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: scheme.accentMuted),
                  ),
                  child: Text('On time',
                      style: TransitTypography.statusBadge(scheme.accent)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 1,
              color: scheme.divider,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _MiniBadge(color: scheme.accent, scheme: scheme),
                const SizedBox(width: 8),
                Text('400 pts',
                    style: TransitTypography.bodySmall(scheme.textMid)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: scheme.bgRaised,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('12:34',
                      style: TransitTypography.stopTime(scheme.textHi)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.color, required this.scheme});

  final Color color;
  final TransitColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(Icons.star, size: 12, color: color),
    );
  }
}

class _ContrastBadge extends StatelessWidget {
  const _ContrastBadge({
    required this.ratio,
    required this.passesAA,
    required this.scheme,
  });

  final double ratio;
  final bool passesAA;
  final TransitColorScheme scheme;

  Color get _badgeColor =>
      passesAA ? const Color(0xFF2ECC71) : const Color(0xFFE74C3C);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = passesAA
        ? l10n.appearanceCustomPaletteContrastPass
        : l10n.appearanceCustomPaletteContrastFail;

    return GlassCard(
      blur: 16,
      fillOpacity: 0.05,
      borderRadius: 14,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _badgeColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TransitTypography.bodyPrimary(_badgeColor),
          ),
          const Spacer(),
          Text(
            '${ratio.toStringAsFixed(2)}:1',
            style: TransitTypography.displayNumber(_badgeColor),
          ),
        ],
      ),
    );
  }
}
