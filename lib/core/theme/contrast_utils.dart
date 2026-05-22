import 'dart:math' as math;

import 'package:flutter/material.dart';

double relativeLuminance(Color c) {
  double linearize(double ch) {
    return ch <= 0.03928
        ? ch / 12.92
        : math.pow((ch + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * linearize(c.r) +
      0.7152 * linearize(c.g) +
      0.0722 * linearize(c.b);
}

double contrastRatio(Color a, Color b) {
  final l1 = relativeLuminance(a);
  final l2 = relativeLuminance(b);
  final lighter = math.max(l1, l2);
  final darker = math.min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

bool meetsWcagAA(Color foreground, Color background,
    {bool largeText = false}) {
  final ratio = contrastRatio(foreground, background);
  return largeText ? ratio >= 3.0 : ratio >= 4.5;
}
