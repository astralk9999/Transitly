import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/theme/transit_animations.dart';

class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.97,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final bool enabled;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;
  bool _hovered = false;

  bool get _isWeb => kIsWeb;

  @override
  Widget build(BuildContext context) {
    final animate = TransitAnimations.shouldAnimate(context);
    final effectiveScale =
        (_pressed && widget.enabled && animate) ? widget.scale : 1.0;
    final effectiveOpacity =
        (_hovered && widget.enabled && animate) ? 0.9 : 1.0;

    Widget child = AnimatedScale(
      scale: effectiveScale,
      duration: TransitAnimations.durationButton,
      curve: TransitAnimations.transitEaseOut,
      child: AnimatedOpacity(
        opacity: effectiveOpacity,
        duration: TransitAnimations.durationButton,
        child: widget.child,
      ),
    );

    if (_isWeb && widget.enabled) {
      child = MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: child,
      );
    }

    return GestureDetector(
      onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel:
          widget.enabled ? () => setState(() => _pressed = false) : null,
      onTap: widget.enabled ? widget.onTap : null,
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }
}
