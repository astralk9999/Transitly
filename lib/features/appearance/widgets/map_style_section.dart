import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../features/map/map_config.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/providers/theme_notifier.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_text.dart';

class MapStyleSection extends ConsumerWidget {
  const MapStyleSection({required this.c, required this.l10n, super.key});

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
    final mapStyle =
        ref.watch(themeNotifierProvider.select((n) => n.mapStyle));
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
            style: TransitTypography.sectionLabel(Colors.white),
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
                return MapStylePreview(
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

class MapStylePreview extends StatelessWidget {
  const MapStylePreview({
    required this.styleKey,
    required this.label,
    required this.icon,
    required this.previewColor,
    required this.selected,
    required this.c,
    required this.onTap,
    super.key,
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
            color:
                selected ? c.accent.withValues(alpha: 0.15) : c.bgRaised,
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
