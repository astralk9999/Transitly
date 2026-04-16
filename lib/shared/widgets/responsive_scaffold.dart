import 'package:flutter/material.dart';

enum ScreenSize { compact, medium, expanded, large }

class ResponsiveScaffold extends StatelessWidget {
  const ResponsiveScaffold({
    super.key,
    required this.child,
    this.maxContentWidth = 1200,
  });

  final Widget child;
  final double maxContentWidth;

  static ScreenSize screenSizeOf(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 600) return ScreenSize.compact;
    if (width < 900) return ScreenSize.medium;
    if (width < 1024) return ScreenSize.expanded;
    return ScreenSize.large;
  }

  static double screenPadding(BuildContext context) {
    return switch (screenSizeOf(context)) {
      ScreenSize.compact => 16,
      ScreenSize.medium => 24,
      ScreenSize.expanded || ScreenSize.large => 32,
    };
  }

  static int gridColumns(BuildContext context) {
    return switch (screenSizeOf(context)) {
      ScreenSize.compact => 1,
      ScreenSize.medium => 2,
      ScreenSize.expanded || ScreenSize.large => 3,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxContentWidth),
        child: child,
      ),
    );
  }
}

class ContentConstraints extends StatelessWidget {
  const ContentConstraints({
    super.key,
    required this.child,
    this.maxWidth = 800,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
