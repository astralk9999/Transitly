import 'package:flutter/material.dart';

import '../transit_colors.dart';

class AppPalette {
  final String id;
  final String name;
  final bool isDark;
  final TransitColorScheme scheme;

  const AppPalette({
    required this.id,
    required this.name,
    required this.isDark,
    required this.scheme,
  });

  Brightness get brightness =>
      isDark ? Brightness.dark : Brightness.light;

  @override
  bool operator ==(Object other) =>
      other is AppPalette && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'AppPalette(id: $id, name: $name, isDark: $isDark)';
}
