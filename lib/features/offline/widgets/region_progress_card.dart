import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/models/offline_region.dart';
import '../../../shared/widgets/glass_card.dart';

class RegionProgressCard extends StatelessWidget {
  const RegionProgressCard({
    super.key,
    required this.region,
    required this.isDark,
    required this.c,
    required this.l10n,
    required this.onDelete,
  });

  final OfflineRegion region;
  final bool isDark;
  final TransitColorScheme c;
  final AppLocalizations l10n;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final statusText = switch (region.status) {
      OfflineRegionStatus.ready => l10n.offlineRegionsStatusReady,
      OfflineRegionStatus.downloading => l10n.offlineRegionsStatusDownloading,
      OfflineRegionStatus.error => l10n.offlineRegionsStatusError,
      OfflineRegionStatus.stale => l10n.offlineRegionsStatusStale,
    };

    final statusColor = switch (region.status) {
      OfflineRegionStatus.ready => c.stateOnTime,
      OfflineRegionStatus.downloading => c.stateOnRoute,
      OfflineRegionStatus.error => c.stateCancelled,
      OfflineRegionStatus.stale => c.stateDelay,
    };

    final dateFmt =
        DateFormat.yMMMd().add_jm().format(region.downloadedAt.toLocal());

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: ValueKey(region.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: c.stateCancelled.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(Icons.delete_outline, color: c.stateCancelled),
        ),
        confirmDismiss: (_) async {
          onDelete();
          return false;
        },
        child: GlassCard(
          blur: 16,
          fillOpacity: 0.05,
          borderRadius: 14,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(region.label,
                        style: TransitTypography.heading(c.textHi)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border:
                          Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      statusText,
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.sd_storage_outlined,
                    label: l10n.offlineRegionsSize,
                    value: _formatBytes(region.sizeBytes),
                    c: c,
                  ),
                  const SizedBox(width: 16),
                  _InfoChip(
                    icon: Icons.calendar_today,
                    label: l10n.offlineRegionsDownloaded,
                    value: dateFmt,
                    c: c,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.zoom_in,
                    label: 'Zoom',
                    value: '${region.zoomMin}-${region.zoomMax}',
                    c: c,
                  ),
                  const SizedBox(width: 16),
                ],
              ),
              if (region.dataSyncedAt != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.sync, size: 12, color: c.stateOnTime),
                    const SizedBox(width: 4),
                    Text(
                      l10n.offlineRegionsDataSynced,
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: c.stateOnTime,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat.yMMMd()
                          .add_jm()
                          .format(region.dataSyncedAt!.toLocal()),
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 9,
                        color: c.textLo,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.c,
  });

  final IconData icon;
  final String label;
  final String value;
  final TransitColorScheme c;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: c.textLo),
        const SizedBox(width: 4),
        Text('$label ',
            style: GoogleFonts.ibmPlexMono(
                fontSize: 10, color: c.textLo)),
        Text(value,
            style: GoogleFonts.ibmPlexMono(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: c.textMid)),
      ],
    );
  }
}
