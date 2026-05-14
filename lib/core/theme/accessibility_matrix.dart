class AccessibilityMatrix {
  static List<double> forMode(String mode) => switch (mode) {
        'protanopia' => _protanopia,
        'deuteranopia' => _deuteranopia,
        'tritanopia' => _tritanopia,
        _ => _identity,
      };

  static const _identity = <double>[
    1, 0, 0, 0, 0,
    0, 1, 0, 0, 0,
    0, 0, 1, 0, 0,
    0, 0, 0, 1, 0,
  ];

  static const _protanopia = <double>[
    0.567, 0.433, 0, 0, 0,
    0.558, 0.442, 0, 0, 0,
    0, 0.242, 0.758, 0, 0,
    0, 0, 0, 1, 0,
  ];

  static const _deuteranopia = <double>[
    0.625, 0.375, 0, 0, 0,
    0.7, 0.3, 0, 0, 0,
    0, 0.3, 0.7, 0, 0,
    0, 0, 0, 1, 0,
  ];

  static const _tritanopia = <double>[
    0.95, 0.05, 0, 0, 0,
    0, 0.433, 0.567, 0, 0,
    0, 0.475, 0.525, 0, 0,
    0, 0, 0, 1, 0,
  ];
}
