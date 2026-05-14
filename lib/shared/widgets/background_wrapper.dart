import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/backgrounds/app_background.dart';
import '../providers/theme_notifier.dart';
import 'smoke_background.dart';

class BackgroundWrapper extends ConsumerWidget {
  const BackgroundWrapper({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeNotifier = ref.watch(themeNotifierProvider);
    final palette = themeNotifier.palette;
    final bg = themeNotifier.background;
    final enabled = themeNotifier.backgroundEnabled;
    final opacity = themeNotifier.backgroundOpacity;
    final reduceMotion = themeNotifier.reduceMotion;

    if (!enabled) {
      return Container(color: palette.scheme.bgRoot, child: child);
    }

    return switch (bg) {
      NoneBackground() =>
        Container(color: palette.scheme.bgRoot, child: child),
      ShaderBackground() => SmokeBackground(
          color: palette.scheme.accent,
          isDark: palette.isDark,
          opacity: opacity,
          reduceMotion: reduceMotion,
          child: child,
        ),
      GradientBackground(:final colors, :final begin, :final end) =>
        _buildGradientBg(colors, begin, end, opacity, child),
      ImageBackground(
        :final assetPath,
        :final fit,
        :final alignment,
      ) =>
        _buildImageBg(assetPath, fit, alignment, opacity, child),
    };
  }

  Widget _buildGradientBg(
    List<Color> colors,
    AlignmentGeometry begin,
    AlignmentGeometry end,
    double opacity,
    Widget child,
  ) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Opacity(
          opacity: opacity,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors,
                begin: begin,
                end: end,
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }

  Widget _buildImageBg(
    String assetPath,
    BoxFit fit,
    Alignment alignment,
    double opacity,
    Widget child,
  ) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Opacity(
          opacity: opacity,
          child: Image.asset(
            assetPath,
            fit: fit,
            alignment: alignment,
          ),
        ),
        child,
      ],
    );
  }
}
