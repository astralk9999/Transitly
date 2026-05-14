import 'package:flutter/material.dart';

import 'app_background.dart';

final prefabBackgrounds = <AppBackground>[
  const NoneBackground(),
  const ShaderBackground('shaders/smoke.frag', Colors.purple),
  const GradientBackground(
    [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
  ),
  const ImageBackground('assets/bg/soft_grid.png'),
  const ImageBackground('assets/bg/topo_lines.png'),
];

AppBackground backgroundFromId(String id) =>
    prefabBackgrounds.firstWhere(
      (b) => b.id == id,
      orElse: () => prefabBackgrounds.first,
    );
