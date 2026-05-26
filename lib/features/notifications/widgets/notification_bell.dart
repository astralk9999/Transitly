import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/transit_animations.dart';
import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/providers/theme_notifier.dart';

class NotificationBell extends ConsumerStatefulWidget {
  const NotificationBell({
    super.key,
    required this.unreadCount,
    required this.onTap,
  });

  final int unreadCount;
  final VoidCallback onTap;

  @override
  ConsumerState<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends ConsumerState<NotificationBell>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _rotation;
  int _prevCount = 0;

  @override
  void initState() {
    super.initState();
    _prevCount = widget.unreadCount;
  }

  @override
  void didUpdateWidget(NotificationBell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.unreadCount > _prevCount) {
      _triggerShake();
    }
    _prevCount = widget.unreadCount;
  }

  void _triggerShake() {
    final reduceMotion = ref.read(themeNotifierProvider).reduceMotion;
    if (reduceMotion) return;

    _controller?.dispose();
    _controller = AnimationController(
      vsync: this,
      duration: TransitAnimations.shake,
    );

    _rotation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.05), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.05, end: 0.05), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.05, end: -0.05), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.05, end: 0.0), weight: 1),
    ]).animate(
      CurvedAnimation(parent: _controller!, curve: Curves.easeInOut),
    );

    _controller!.forward();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = widget.unreadCount > 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final l10n = AppLocalizations.of(context);

    Widget bell = Material(
      color: c.bgRaised,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: hasUnread ? c.accent : c.border,
          width: hasUnread ? 1.5 : 0.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: widget.onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.notifications_outlined,
                color: hasUnread ? c.accent : c.textMid,
                size: 20,
              ),
              if (hasUnread)
                Positioned(
                  top: -3,
                  right: -4,
                  child: _BadgeCount(c: c, unreadCount: widget.unreadCount),
                ),
            ],
          ),
        ),
      ),
    );

    if (_rotation != null) {
      bell = RotationTransition(
        turns: _rotation!,
        child: bell,
      );
    }

    return Semantics(
      label: l10n.notificationsBellSemantics(widget.unreadCount),
      child: bell,
    );
  }
}

class _BadgeCount extends StatelessWidget {
  const _BadgeCount({required this.c, required this.unreadCount});

  final TransitColorScheme c;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    final badgeText = unreadCount > 99 ? '99+' : '$unreadCount';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      height: 10,
      constraints: const BoxConstraints(minWidth: 16),
      decoration: BoxDecoration(
        color: c.accent,
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            color: c.accent.withValues(alpha: 0.5),
          ),
        ],
      ),
      child: Text(
        badgeText,
        style: TransitTypography.bodySmall(c.textHi).copyWith(
          fontSize: 8,
          height: 1.0,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
