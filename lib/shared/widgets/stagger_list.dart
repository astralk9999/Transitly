import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/transit_animations.dart';
import '../../core/utils/app_logger.dart';
import '../providers/theme_notifier.dart';

class StaggerList extends StatefulWidget {
  const StaggerList({
    super.key,
    required this.children,
    this.staggerDelay = const Duration(milliseconds: 50),
    this.duration = const Duration(milliseconds: 250),
    this.maxAnimated = 10,
  });

  final List<Widget> children;
  final Duration staggerDelay;
  final Duration duration;
  final int maxAnimated;

  @override
  State<StaggerList> createState() => _StaggerListState();
}

class _StaggerListState extends State<StaggerList>
    with TickerProviderStateMixin {
  final List<AnimationController> _controllers = [];
  final List<Animation<double>> _opacities = [];
  final List<Animation<Offset>> _offsets = [];
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _buildControllers();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _startStagger();
    }
  }

  void _buildControllers() {
    for (final ctrl in _controllers) {
      ctrl.dispose();
    }
    _controllers.clear();
    _opacities.clear();
    _offsets.clear();

    final count = widget.children.length.clamp(0, widget.maxAnimated);
    for (int i = 0; i < count; i++) {
      final ctrl = AnimationController(
        vsync: this,
        duration: widget.duration,
      );
      _controllers.add(ctrl);
      _opacities.add(CurvedAnimation(
        parent: ctrl,
        curve: TransitAnimations.transitEaseOut,
      ));
      _offsets.add(Tween<Offset>(
        begin: const Offset(0, 0.08),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: ctrl,
        curve: TransitAnimations.transitEaseOut,
      )));
    }
  }

  Future<void> _startStagger() async {
    if (!mounted) return;
    var reduceMotion = false;
    try {
      final container = ProviderScope.containerOf(context);
      final tn = container.read(themeNotifierProvider);
      reduceMotion = tn.reduceMotion;
    } catch (e) {
      AppLogger.warn('StaggerList', 'reduceMotion unavailable', e);
    }
    final animate = TransitAnimations.shouldAnimate(context) && !reduceMotion;

    for (int i = 0; i < _controllers.length; i++) {
      if (!mounted) return;
      if (animate) {
        await Future.delayed(widget.staggerDelay);
      }
      if (!mounted) return;
      if (animate) {
        unawaited(_controllers[i].forward());
      } else {
        _controllers[i].value = 1.0;
      }
    }
  }

  @override
  void didUpdateWidget(StaggerList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.children.length != widget.children.length) {
      _buildControllers();
      _startStagger();
    }
  }

  @override
  void dispose() {
    for (final ctrl in _controllers) {
      ctrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < widget.children.length; i++)
          if (i < _controllers.length)
            SlideTransition(
              position: _offsets[i],
              child: FadeTransition(
                opacity: _opacities[i],
                child: widget.children[i],
              ),
            )
          else
            widget.children[i],
      ],
    );
  }
}
