import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_spacing.dart';
import '../../core/theme/transit_typography.dart';
import '../../data/notification/notification_repository_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/models/app_notification.dart';
import '../../shared/providers/notification_stream_provider.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/transit_app_bar.dart';
import '../../shared/widgets/transit_button.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final notifsAsync = ref.watch(notificationStreamProvider);

    return Scaffold(
      backgroundColor: c.bgRoot,
      body: SafeArea(
        child: Column(
          children: [
            TransitAppBar(
              title: l10n.notificationsTitle,
              showBack: true,
              actions: [
                if (notifsAsync.valueOrNull?.any((n) => !n.read) ?? false)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: TransitButton(
                      label: l10n.notificationsMarkAllRead,
                      isPrimary: false,
                      onPressed: () => _markAllRead(ref, l10n, context),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: notifsAsync.when(
                data: (notifications) {
                  if (notifications.isEmpty) {
                    return EmptyState(
                      l10n.notificationsEmpty,
                      '',
                      icon: Icons.notifications_none_outlined,
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: TransitSpacing.space16,
                      vertical: TransitSpacing.space8,
                    ),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notif = notifications[index];
                      return _NotificationTile(
                        notification: notif,
                        isDark: isDark,
                        c: c,
                        l10n: l10n,
                        onDismiss: () =>
                            _markRead(ref, notif.id, l10n, context),
                      );
                    },
                  );
                },
                loading: () => _LoadingList(c: c, isDark: isDark),
                error: (_, __) => Center(
                  child: EmptyState(
                    l10n.notificationsEmpty,
                    '',
                    icon: Icons.notifications_none_outlined,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _markAllRead(WidgetRef ref, AppLocalizations l10n, BuildContext context) {
    final repo = ref.read(notificationRepositoryProvider);
    final notifs = ref.read(notificationStreamProvider).valueOrNull ?? [];
    for (final n in notifs.where((n) => !n.read)) {
      unawaited(repo.markRead(n.id));
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.notificationsAllRead),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _markRead(
      WidgetRef ref, String id, AppLocalizations l10n, BuildContext context) {
    final repo = ref.read(notificationRepositoryProvider);
    unawaited(repo.markRead(id));
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.isDark,
    required this.c,
    required this.l10n,
    required this.onDismiss,
  });

  final AppNotification notification;
  final bool isDark;
  final TransitColorScheme c;
  final AppLocalizations l10n;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final unread = !notification.read;

    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: c.accent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.mark_email_read_outlined,
            color: c.accent, size: 22),
      ),
      confirmDismiss: (direction) async {
        onDismiss();
        return false;
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: GestureDetector(
          onTap: () {
            final deeplink = notification.payload['deeplink'];
            if (deeplink is String && deeplink.isNotEmpty) {
              context.push(deeplink);
            }
            if (unread) {
              onDismiss();
            }
          },
          child: GlassCard(
            blur: 16,
            fillOpacity: 0.05,
            borderRadius: 14,
            useAccentBorder: unread,
            accentColor: c.accent,
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _NotificationIcon(type: notification.type, size: 20, c: c),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _typeLabel(notification.type, l10n),
                              style: unread
                                  ? GoogleFonts.dmSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: c.textHi,
                                    )
                                  : TransitTypography.subheading(c.textMid),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _relativeTime(notification.createdAt, l10n),
                            style: TransitTypography.bodySmall(
                              unread ? c.accent : c.textLo,
                            ),
                          ),
                        ],
                      ),
                      if (_bodyText(notification).isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          _bodyText(notification),
                          style: TransitTypography.bodySecondary(
                            unread ? c.textMid : c.textLo,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _typeLabel(AppNotificationType type, AppLocalizations l10n) {
    return switch (type) {
      AppNotificationType.incidentResolved =>
        l10n.notificationTypeIncidentResolved,
      AppNotificationType.routePromoted =>
        l10n.notificationTypeRoutePromoted,
      AppNotificationType.shareReceived =>
        l10n.notificationTypeShareReceived,
      AppNotificationType.featureRequestReplied =>
        l10n.notificationTypeFeatureRequestReplied,
      AppNotificationType.busApproachingFavorite =>
        l10n.notificationTypeBusApproaching,
      AppNotificationType.custom => l10n.notificationTypeCustom,
    };
  }

  String _bodyText(AppNotification notif) {
    final body = notif.payload['body'];
    if (body is String && body.isNotEmpty) return body;
    final title = notif.payload['title'];
    if (title is String && title.isNotEmpty) return title;
    return '';
  }

  String _relativeTime(DateTime time, AppLocalizations l10n) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return l10n.notificationTimeNow;
    if (diff.inHours < 1) return l10n.notificationTimeMinutes(diff.inMinutes);
    if (diff.inDays < 1) return l10n.notificationTimeHours(diff.inHours);
    return l10n.notificationTimeDays(diff.inDays);
  }
}

class _NotificationIcon extends StatelessWidget {
  const _NotificationIcon({
    required this.type,
    required this.size,
    required this.c,
  });

  final AppNotificationType type;
  final double size;
  final TransitColorScheme c;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: c.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(_icon, size: size, color: c.accent),
    );
  }

  IconData get _icon {
    return switch (type) {
      AppNotificationType.incidentResolved => Icons.report_problem_outlined,
      AppNotificationType.routePromoted => Icons.route_outlined,
      AppNotificationType.shareReceived => Icons.share_outlined,
      AppNotificationType.featureRequestReplied => Icons.forum_outlined,
      AppNotificationType.busApproachingFavorite =>
        Icons.directions_bus_outlined,
      AppNotificationType.custom => Icons.notifications_outlined,
    };
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList({required this.c, required this.isDark});

  final TransitColorScheme c;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: c.bgRaised,
      highlightColor: c.border,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: TransitSpacing.space16,
          vertical: TransitSpacing.space8,
        ),
        itemCount: 6,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: c.bgSurface,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }
}
