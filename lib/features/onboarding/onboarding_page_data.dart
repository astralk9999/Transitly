import 'package:flutter/material.dart';

class OnboardingPageData {
  final String title;
  final String description;
  final IconData icon;
  final Color? accentColor;

  const OnboardingPageData({
    required this.title,
    required this.description,
    required this.icon,
    this.accentColor,
  });
}
