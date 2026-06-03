import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/backgrounds/app_background.dart';
import '../providers/theme_notifier.dart';
import '../providers/theme_provider.dart';
import 'backgrounds/balatro_background.dart';
import 'backgrounds/floating_lines_background.dart';
import 'backgrounds/light_rays_background.dart';
import 'backgrounds/painter_backgrounds.dart';
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

    final themeMode = ref.watch(themeModeProvider);
    final brightness = MediaQuery.platformBrightnessOf(context);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system && brightness == Brightness.dark);
    final scheme = isDark
        ? (palette.darkScheme ?? palette.scheme)
        : (palette.lightScheme ?? palette.scheme);

    if (!enabled) {
      return Container(color: scheme.bgRoot, child: child);
    }

    // En la paleta por defecto, accent/neonCyan/neonPurple son los tres
    // tonos morados-azules — usarlos juntos hacía que TODOS los fondos
    // multicolor se vieran azules. En su lugar derivamos 3 tonos del
    // accent con LUMINOSIDADES distintas: así siempre hay contraste sin
    // introducir hues ajenos a la paleta del usuario.
    Color withLightness(Color base, double mul) {
      final hsl = HSLColor.fromColor(base);
      final newL = (hsl.lightness * mul).clamp(0.05, 0.95);
      return hsl.withLightness(newL).toColor();
    }

    final schemeColors = <Color>[
      scheme.accent,                          // tono medio (paleta)
      withLightness(scheme.accent, 1.55),     // tono claro del accent
      withLightness(scheme.accent, 0.5),      // tono oscuro del accent
    ];

    // Color secundario para los shaders de 2 colores (Balatro): una
    // versión claramente más clara del accent, garantiza contraste
    // sin meter un color foráneo.
    final accentLight = withLightness(scheme.accent, 1.4);

    return switch (bg) {
      NoneBackground() =>
        Container(color: scheme.bgRoot, child: child),
      ShaderBackground() => SmokeBackground(
          color: scheme.accent,
          isDark: isDark,
          opacity: opacity,
          reduceMotion: reduceMotion,
          child: child,
        ),
      GradientBackground(:final begin, :final end) =>
        // Ignoramos los colors hardcoded del prefab y usamos el scheme
        // activo para que el gradiente respete la paleta del usuario.
        _buildGradientBg(
          [scheme.bgRoot, scheme.accent.withValues(alpha: 0.5), scheme.bgRaised],
          begin,
          end,
          opacity,
          child,
        ),
      ImageBackground(
        :final assetPath,
        :final fit,
        :final alignment,
      ) =>
        _buildImageBg(assetPath, fit, alignment, opacity, child),
      ProceduralBackground() => Stack(
        fit: StackFit.expand,
        children: [
          Container(color: scheme.bgRoot),
          Opacity(opacity: opacity, child: bg.builder(context)),
          child,
        ],
      ),
      LightRaysShaderBackground() => Stack(
        fit: StackFit.expand,
        children: [
          Container(color: scheme.bgRoot),
          LightRaysBackground(
            color: scheme.accent,
            origin: LightRaysOrigin.topCenter,
            speed: 0.7,
            // Intensidad reducida: rayos más cortos, más spread, menos saturación.
            lightSpread: 0.9,
            rayLength: 2.2,
            saturation: 0.55,
            fadeDistance: 0.7,
            opacity: opacity,
            reduceMotion: reduceMotion,
          ),
          child,
        ],
      ),
      BalatroShaderBackground() => Stack(
        fit: StackFit.expand,
        children: [
          Container(color: scheme.bgRoot),
          BalatroBackground(
            // accent + versión clara del accent + bgRoot. Sin colores foráneos.
            color1: scheme.accent,
            color2: accentLight,
            color3: scheme.bgRoot,
            spinSpeed: 4.0,
            pixelFilter: 1200.0,
            isRotate: false,
            opacity: opacity,
            reduceMotion: reduceMotion,
          ),
          child,
        ],
      ),
      FloatingLinesShaderBackground() => Stack(
        fit: StackFit.expand,
        children: [
          Container(color: scheme.bgRoot),
          FloatingLinesBackground(
            color1: schemeColors[0],
            color2: schemeColors[1],
            color3: schemeColors[2],
            opacity: opacity,
            reduceMotion: reduceMotion,
          ),
          child,
        ],
      ),
      ColorBendsShaderBackground() => Stack(
        fit: StackFit.expand,
        children: [
          Container(color: scheme.bgRoot),
          ColorBendsBackground(
            colors: schemeColors,
            opacity: opacity,
            reduceMotion: reduceMotion,
          ),
          child,
        ],
      ),
      DotFieldShaderBackground() => Stack(
        fit: StackFit.expand,
        children: [
          Container(color: scheme.bgRoot),
          DotFieldBackground(
            colors: schemeColors,
            opacity: opacity,
            reduceMotion: reduceMotion,
          ),
          child,
        ],
      ),
      DotGridShaderBackground() => Stack(
        fit: StackFit.expand,
        children: [
          Container(color: scheme.bgRoot),
          DotGridBackground(
            colors: schemeColors,
            opacity: opacity,
            reduceMotion: reduceMotion,
          ),
          child,
        ],
      ),
      DitherShaderBackground() => Stack(
        fit: StackFit.expand,
        children: [
          Container(color: scheme.bgRoot),
          DitherBackground(
            colors: schemeColors,
            opacity: opacity,
            reduceMotion: reduceMotion,
          ),
          child,
        ],
      ),
      FaultyTerminalShaderBackground() => Stack(
        fit: StackFit.expand,
        children: [
          Container(color: scheme.bgRoot),
          FaultyTerminalBackground(
            colors: schemeColors,
            opacity: opacity,
            reduceMotion: reduceMotion,
          ),
          child,
        ],
      ),
      DarkVeilShaderBackground() => Stack(
        fit: StackFit.expand,
        children: [
          Container(color: scheme.bgRoot),
          DarkVeilBackground(
            colors: schemeColors,
            opacity: opacity,
            reduceMotion: reduceMotion,
          ),
          child,
        ],
      ),
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
