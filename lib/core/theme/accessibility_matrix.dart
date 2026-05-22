class AccessibilityMatrix {
  static List<double> forMode(String mode) => switch (mode) {
        'protanopia' => _protanopia,
        'deuteranopia' => _deuteranopia,
        'tritanopia' => _tritanopia,
        'protanomaly' => _protanomaly,
        'deuteranomaly' => _deuteranomaly,
        'tritanomaly' => _tritanomaly,
        'achromatopsia' => _achromatopsia,
        'achromatomaly' => _achromatomaly,
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

  // Anomaly types: 50% blend of -opia matrix with identity
  static const _protanomaly = <double>[
    0.7835, 0.2165, 0, 0, 0,
    0.779, 0.221, 0, 0, 0,
    0, 0.621, 0.379, 0, 0,
    0, 0, 0, 1, 0,
  ];

  static const _deuteranomaly = <double>[
    0.8125, 0.1875, 0, 0, 0,
    0.85, 0.15, 0, 0, 0,
    0, 0.65, 0.35, 0, 0,
    0, 0, 0, 1, 0,
  ];

  static const _tritanomaly = <double>[
    0.975, 0.025, 0, 0, 0,
    0, 0.7165, 0.2835, 0, 0,
    0, 0.7375, 0.2625, 0, 0,
    0, 0, 0, 1, 0,
  ];

  // Total color blindness (monochromacy): luminance-only vision
  static const _achromatopsia = <double>[
    0.299, 0.587, 0.114, 0, 0,
    0.299, 0.587, 0.114, 0, 0,
    0.299, 0.587, 0.114, 0, 0,
    0, 0, 0, 1, 0,
  ];

  // Partial monochromacy: 60% luminance + 40% original color
  static const _achromatomaly = <double>[
    0.5794, 0.3522, 0.0684, 0, 0,
    0.1794, 0.7522, 0.0684, 0, 0,
    0.1794, 0.3522, 0.4684, 0, 0,
    0, 0, 0, 1, 0,
  ];
}
