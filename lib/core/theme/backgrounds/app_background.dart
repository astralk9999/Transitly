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

enum ProceduralPattern { softGrid, topoLines }

class ProceduralBackground extends AppBackground {
  final ProceduralPattern pattern;

  const ProceduralBackground(this.pattern);

  @override
  String get id => switch (pattern) {
        ProceduralPattern.softGrid => 'assets/bg/soft_grid.png',
        ProceduralPattern.topoLines => 'assets/bg/topo_lines.png',
      };

  @override
  WidgetBuilder get builder => (context) {
        return CustomPaint(
          painter: _ProceduralPainter(pattern),
          child: const SizedBox.expand(),
        );
      };
}

class _ProceduralPainter extends CustomPainter {
  _ProceduralPainter(this.pattern);

  final ProceduralPattern pattern;

  @override
  void paint(Canvas canvas, Size size) {
    switch (pattern) {
      case ProceduralPattern.softGrid:
        _drawSoftGrid(canvas, size);
      case ProceduralPattern.topoLines:
        _drawTopoLines(canvas, size);
    }
  }

  void _drawSoftGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x08FFFFFF)
      ..strokeWidth = 0.5;
    const spacing = 18.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawTopoLines(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x07FFFFFF)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxR = (size.width > size.height ? size.width : size.height) * 0.85;
    for (double r = 20; r < maxR; r += 28) {
      final path = Path();
      const segments = 72;
      for (int i = 0; i <= segments; i++) {
        final wobble = (r < 80 ? 6 : 12) * (i % 7 == 0 ? 1.0 : 0.5);
        final rx = cx + (r + wobble * (i.isEven ? 1 : -1)) * 1.6;
        final ry = cy + (r + wobble * (i.isOdd ? 1 : -1)) * 1.0;
        final px = cx + rx * (i / segments * 2 - 1) * 0.5;
        final py = cy + (ry - cy) * (i.isEven ? 1 : -1);
        if (i == 0) {
          path.moveTo(px, py);
        } else {
          path.lineTo(px, py);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ProceduralPainter old) =>
      old.pattern != pattern;
}
