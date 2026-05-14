import 'package:flutter/material.dart';

sealed class AppBackground {
  const AppBackground();

  String get id;

  WidgetBuilder get builder => (_) => const SizedBox.shrink();
}

class NoneBackground extends AppBackground {
  const NoneBackground();

  @override
  String get id => 'none';
}

class ImageBackground extends AppBackground {
  final String assetPath;
  final BlendMode blendMode;
  final Alignment alignment;
  final BoxFit fit;

  const ImageBackground(
    this.assetPath, {
    this.blendMode = BlendMode.srcOver,
    this.alignment = Alignment.center,
    this.fit = BoxFit.cover,
  });

  @override
  String get id => assetPath;

  @override
  WidgetBuilder get builder => (context) {
        final img = Image.asset(
          assetPath,
          fit: fit,
          alignment: alignment,
        );
        if (blendMode != BlendMode.srcOver) {
          return ColorFiltered(
            colorFilter: ColorFilter.mode(
              Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
              blendMode,
            ),
            child: img,
          );
        }
        return img;
      };
}

class ShaderBackground extends AppBackground {
  final String shaderAssetPath;
  final Color color;

  const ShaderBackground(this.shaderAssetPath, this.color);

  @override
  String get id => shaderAssetPath;
}

class GradientBackground extends AppBackground {
  final List<Color> colors;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;

  const GradientBackground(
    this.colors, {
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
  });

  @override
  String get id => 'gradient:${colors.map((c) => c.toARGB32().toRadixString(16)).join(',')}';

  @override
  WidgetBuilder get builder => (context) {
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: begin,
              end: end,
            ),
          ),
          child: const SizedBox.expand(),
        );
      };
}
