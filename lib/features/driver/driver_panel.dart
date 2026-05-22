import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/providers/user_provider.dart';

class DriverPanel extends ConsumerWidget {
  const DriverPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: c.bgRoot,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: c.textLo,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  l10n.driverPanelTitle,
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: c.accent,
                  ),
                ),
                const Spacer(),
                Text(
                  ref.watch(currentUserProvider).name,
                  style: TransitTypography.bodySecondary(c.textMid),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Divider(height: 1, thickness: 0.5, color: c.border),
          ),

          // Options
          _option(context, c, Icons.play_arrow, l10n.driverPanelStartRoute, '/driver/start'),
          _option(context, c, Icons.route, l10n.driverPanelActiveRoute, '/driver/active'),
          _option(context, c, Icons.edit, l10n.driverPanelCreateManualRoute, '/driver/editor/manual'),
          _option(context, c, Icons.fiber_manual_record, l10n.driverPanelCreateLiveRoute, '/driver/editor/live'),
          _option(context, c, Icons.history, l10n.driverPanelMyRoutes, '/driver/history'),
          _option(context, c, Icons.schedule, l10n.driverPanelImportSchedules, '/driver/ai-import'),
          _option(context, c, Icons.inbox, l10n.driverPanelManagementInbox, '/management/inbox'),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _option(BuildContext context, TransitColorScheme c, IconData icon,
      String label, String route) {
    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        child: GestureDetector(
          onTap: () {
            Navigator.of(context).pop();
            context.push(route);
          },
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: c.border, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: c.accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(label,
                      style: TransitTypography.bodyPrimary(c.textHi)),
                ),
                Icon(Icons.chevron_right, size: 20, color: c.textLo),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
