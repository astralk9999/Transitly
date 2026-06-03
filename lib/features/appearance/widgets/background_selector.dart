import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/backgrounds/prefab_backgrounds.dart';
import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/providers/theme_notifier.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_text.dart';

class BackgroundSection extends ConsumerWidget {
  const BackgroundSection({required this.c, required this.l10n, super.key});

  final TransitColorScheme c;
  final AppLocalizations l10n;

  String _bgName(String id) {
    return switch (id) {
      'none' => l10n.appearanceBgNone,
      'shaders/smoke.frag' => l10n.appearanceBgSmoke,
      _ when id.startsWith('gradient:') => l10n.appearanceBgGradient,
      'procedural:softGrid' => l10n.appearanceBgGrid,
      'procedural:topoLines' => l10n.appearanceBgTopo,
      'procedural:beams' => l10n.appearanceBgBeams,
      'shader:lightRays' => l10n.appearanceBgLightRays,
      'shader:balatro' => l10n.appearanceBgBalatro,
      'shader:floatingLines' => l10n.appearanceBgFloatingLines,
      'shader:colorBends' => l10n.appearanceBgColorBends,
      'shader:dotField' => l10n.appearanceBgDotField,
      'shader:dotGrid' => l10n.appearanceBgDotGrid,
      'shader:dither' => l10n.appearanceBgDither,
      'shader:faultyTerminal' => l10n.appearanceBgFaultyTerminal,
      'shader:darkVeil' => l10n.appearanceBgDarkVeil,
      _ => id,
    };
  }

  IconData _bgIcon(String id) {
    return switch (id) {
      'none' => Icons.block,
      'shaders/smoke.frag' => Icons.blur_on,
      _ when id.startsWith('gradient:') => Icons.gradient,
      'procedural:softGrid' => Icons.grid_4x4,
      'procedural:topoLines' => Icons.show_chart,
      'procedural:beams' => Icons.flare,
      'shader:lightRays' => Icons.wb_sunny_outlined,
      'shader:balatro' => Icons.blur_circular,
      'shader:floatingLines' => Icons.timeline,
      'shader:colorBends' => Icons.waves,
      'shader:dotField' => Icons.scatter_plot,
      'shader:dotGrid' => Icons.grid_on,
      'shader:dither' => Icons.texture,
      'shader:faultyTerminal' => Icons.developer_mode,
      'shader:darkVeil' => Icons.dark_mode,
      _ => Icons.wallpaper,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bgId =
        ref.watch(themeNotifierProvider.select((n) => n.backgroundId));
    final bgEnabled =
        ref.watch(themeNotifierProvider.select((n) => n.backgroundEnabled));
    final bgOpacity =
        ref.watch(themeNotifierProvider.select((n) => n.backgroundOpacity));

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
            style: TransitTypography.sectionLabel(Colors.white),
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
            height: 84,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: prefabBackgrounds.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final bg = prefabBackgrounds[i];
                final selected = bg.id == bgId;
                return BgPreview(
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

class BgPreview extends StatelessWidget {
  const BgPreview({
    required this.id,
    required this.name,
    required this.icon,
    required this.selected,
    required this.c,
    required this.onTap,
    super.key,
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
          width: 88,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
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
              Icon(icon, size: 22, color: selected ? c.accent : c.textMid),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  name,
                  style: TransitTypography.bodySmall(
                    selected ? c.accent : c.textMid,
                  ),
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
