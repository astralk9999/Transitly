import 'dart:math';
import 'dart:ui' as ui;

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

enum ProceduralPattern {
  softGrid,
  topoLines,
  beams,
  // NOTA: aurora, balatro, floatingLines, dither, colorBends, dotField
  // se eliminaron del enum porque ahora tienen versión REAL con shader
  // (AuroraShaderBackground, BalatroShaderBackground, etc.).
}

// Fondos shader port de react-bits (id: 'shader:*').
// Aurora eliminado a petición del usuario (no quedaba bien en móvil).

class LightRaysShaderBackground extends AppBackground {
  const LightRaysShaderBackground();
  @override
  String get id => 'shader:lightRays';
}

class BalatroShaderBackground extends AppBackground {
  const BalatroShaderBackground();
  @override
  String get id => 'shader:balatro';
}

class FloatingLinesShaderBackground extends AppBackground {
  const FloatingLinesShaderBackground();
  @override
  String get id => 'shader:floatingLines';
}

class ColorBendsShaderBackground extends AppBackground {
  const ColorBendsShaderBackground();
  @override
  String get id => 'shader:colorBends';
}

class DotFieldShaderBackground extends AppBackground {
  const DotFieldShaderBackground();
  @override
  String get id => 'shader:dotField';
}

class DotGridShaderBackground extends AppBackground {
  const DotGridShaderBackground();
  @override
  String get id => 'shader:dotGrid';
}

class DitherShaderBackground extends AppBackground {
  const DitherShaderBackground();
  @override
  String get id => 'shader:dither';
}

class FaultyTerminalShaderBackground extends AppBackground {
  const FaultyTerminalShaderBackground();
  @override
  String get id => 'shader:faultyTerminal';
}

class DarkVeilShaderBackground extends AppBackground {
  const DarkVeilShaderBackground();
  @override
  String get id => 'shader:darkVeil';
}

class ProceduralBackground extends AppBackground {
  final ProceduralPattern pattern;

  const ProceduralBackground(this.pattern);

  @override
  String get id => switch (pattern) {
        ProceduralPattern.softGrid => 'procedural:softGrid',
        ProceduralPattern.topoLines => 'procedural:topoLines',
        ProceduralPattern.beams => 'procedural:beams',
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
      case ProceduralPattern.beams:
        _drawBeams(canvas, size);
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

  // Curvas de nivel tipo mapa topográfico. Usamos ruido determinista
  // (sin librería) sumando varias sinusoides desplazadas. Cada curva es
  // un loop horizontal de izquierda a derecha modulado por el "ruido".
  void _drawTopoLines(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x14FFFFFF)
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke;
    const lines = 22;
    final dy = size.height / lines;
    for (int i = 0; i < lines; i++) {
      final baseY = i * dy + dy * 0.5;
      final phase = i * 0.6;
      final path = Path()..moveTo(0, baseY);
      const step = 6.0;
      for (double x = 0; x <= size.width; x += step) {
        final t = x / size.width;
        final n = sin(t * pi * 3 + phase) * 14 +
            sin(t * pi * 7 + phase * 1.7) * 6 +
            sin(t * pi * 13 + phase * 0.9) * 3;
        path.lineTo(x, baseY + n);
      }
      canvas.drawPath(path, paint);
    }
  }

  // Haces de luz radiales que llenan toda la pantalla. Más haces y
  // un gradient sutil del centro hacia los bordes.
  void _drawBeams(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxR = sqrt(size.width * size.width + size.height * size.height) / 2;
    const beams = 24;
    for (int i = 0; i < beams; i++) {
      final angle = (i / beams) * 2 * pi;
      final alpha = i.isEven ? 0x18 : 0x0C;
      final paint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(cx, cy),
          Offset(cx + cos(angle) * maxR, cy + sin(angle) * maxR),
          [
            Color((alpha << 24) | 0xFFFFFF),
            const Color(0x00FFFFFF),
          ],
        )
        ..strokeWidth = i.isEven ? 2.5 : 1.5;
      canvas.drawLine(
        Offset(cx, cy),
        Offset(cx + cos(angle) * maxR, cy + sin(angle) * maxR),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ProceduralPainter old) =>
      old.pattern != pattern;
}

