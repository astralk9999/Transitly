import 'package:flutter/material.dart';

import 'app_background.dart';

final prefabBackgrounds = <AppBackground>[
  const NoneBackground(),
  const ShaderBackground('shaders/smoke.frag', Colors.purple),
  const GradientBackground(
    [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
  ),
  // Procedurales (CustomPainter, estáticos, baratos)
  const ProceduralBackground(ProceduralPattern.softGrid),
  const ProceduralBackground(ProceduralPattern.topoLines),
  const ProceduralBackground(ProceduralPattern.beams),
  // Shaders / fondos avanzados (react-bits port)
  const LightRaysShaderBackground(),
  const BalatroShaderBackground(),
  const FloatingLinesShaderBackground(),
  const ColorBendsShaderBackground(),
  const DotFieldShaderBackground(),
  const DotGridShaderBackground(),
  const DitherShaderBackground(),
  const FaultyTerminalShaderBackground(),
  const DarkVeilShaderBackground(),
];

AppBackground backgroundFromId(String id) =>
    prefabBackgrounds.firstWhere(
      (b) => b.id == id,
      orElse: () => prefabBackgrounds.first,
    );
