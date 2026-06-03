import 'package:flutter/material.dart';

class NamedCustomPalette {
  const NamedCustomPalette({
    required this.id,
    required this.name,
    required this.colors,
  });

  final String id;
  final String name;
  final Map<String, Color> colors;

  factory NamedCustomPalette.fromHive(Map<dynamic, dynamic> raw) {
    final colorsRaw = (raw['colors'] as Map).cast<dynamic, dynamic>();
    return NamedCustomPalette(
      id: raw['id'] as String,
      name: raw['name'] as String,
          colors: colorsRaw.map((k, v) => MapEntry(
              k.toString(), Color(int.parse(v.toString(), radix: 16)))),
        );
      }

      Map<String, dynamic> toHive() => {
            'id': id,
            'name': name,
            'colors': colors.map((k, v) => MapEntry(
                k, v.toARGB32().toRadixString(16).padLeft(8, '0'))),
          };
}
