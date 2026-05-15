import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../data/offline_region/domain/offline_region_repository.dart';
import '../../data/offline_region/offline_region_repository_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/models/offline_region.dart';
import '../../shared/providers/is_dark_provider.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/smoke_background.dart';
import '../../shared/widgets/transit_app_bar.dart';
import '../../shared/widgets/transit_button.dart';
import 'widgets/region_download_sheet.dart';

class OfflineRegionsScreen extends ConsumerStatefulWidget {
  const OfflineRegionsScreen({super.key});

  @override
  ConsumerState<OfflineRegionsScreen> createState() =>
      _OfflineRegionsScreenState();
}

class _OfflineRegionsScreenState extends ConsumerState<OfflineRegionsScreen> {
  int _refreshCounter = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = isDarkMode(ref, context);
    final c = TransitColorScheme.of(isDark);
    final l10n = AppLocalizations.of(context);
    final repo = ref.watch(offlineRegionRepositoryProvider);

    return Scaffold(
      backgroundColor: c.bgRoot,
      body: Stack(
        children: [
          Positioned.fill(
            child: SmokeBackground(color: c.accent, isDark: isDark),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                TransitAppBar(
                  title: l10n.offlineRegionsTitle,
                  showBack: true,
                  transparent: true,
                ),
                Expanded(
                  key: ValueKey(_refreshCounter),
                  child: _RegionList(
                    repo: repo,
                    isDark: isDark,
                    c: c,
                    l10n: l10n,
                    onRefresh: () => setState(() => _refreshCounter++),
                    onShowDownload: () => _showDownloadSheet(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: c.accent,
        onPressed: () => _showDownloadSheet(context),
        tooltip: l10n.offlineRegionsAddRegion,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Future<void> _showDownloadSheet(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const RegionDownloadSheet(),
    );
    if (result == true && mounted) {
      setState(() {});
    }
  }
}

// ── Region list ─────────────────────────────────────────────────────

class _RegionList extends StatelessWidget {
  const _RegionList({
    required this.repo,
    required this.isDark,
    required this.c,
    required this.l10n,
    required this.onRefresh,
    required this.onShowDownload,
  });

  final OfflineRegionRepository repo;
  final bool isDark;
  final TransitColorScheme c;
  final AppLocalizations l10n;
  final VoidCallback onRefresh;
  final VoidCallback onShowDownload;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<OfflineRegion>>(
      future: repo.forUser('_current_'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _ShimmerList(c: c);
        }
        if (snapshot.hasError) {
          return Center(
            child: EmptyState(
              l10n.adminOperatorsError,
              snapshot.error.toString(),
              icon: Icons.error_outline,
              actionLabel: l10n.actionRetry,
              onAction: onRefresh,
            ),
          );
        }
        final regions = snapshot.data ?? <OfflineRegion>[];
        if (regions.isEmpty) {
          return EmptyState(
            l10n.offlineRegionsEmpty,
            l10n.offlineRegionsEmptySubtitle,
            icon: Icons.map_outlined,
            actionLabel: l10n.offlineRegionsAddRegion,
            onAction: onShowDownload,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
          itemCount: regions.length,
          itemBuilder: (context, index) {
            return _RegionCard(
              region: regions[index],
              isDark: isDark,
              c: c,
              l10n: l10n,
              onDelete: () => _confirmDelete(context, regions[index]),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, OfflineRegion region) {
    final c = TransitColorScheme.of(isDark);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.bgSurface,
        title: Text(l10n.offlineRegionsDeleteConfirm,
            style: TransitTypography.heading(c.textHi)),
        content: Text(l10n.offlineRegionsDeleteDesc,
            style: TransitTypography.bodyPrimary(c.textMid)),
        actions: [
          TransitButton(
            label: l10n.actionCancel,
            isPrimary: false,
            isSmall: true,
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TransitButton(
            label: l10n.offlineRegionsActionDelete,
            isDanger: true,
            isSmall: true,
            onPressed: () {
              repo.delete(region.id);
              Navigator.of(ctx).pop();
              onRefresh();
            },
          ),
        ],
      ),
    );
  }
}

// ── Region card ─────────────────────────────────────────────────────

class _RegionCard extends StatelessWidget {
  const _RegionCard({
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

// ── Shimmer placeholder ─────────────────────────────────────────────

class _ShimmerList extends StatelessWidget {
  const _ShimmerList({required this.c});

  final TransitColorScheme c;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            fillOpacity: 0.03,
            borderRadius: 14,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 140,
                  height: 16,
                  decoration: BoxDecoration(
                    color: c.textLo.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 80,
                      height: 12,
                      decoration: BoxDecoration(
                        color: c.textLo.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 120,
                      height: 12,
                      decoration: BoxDecoration(
                        color: c.textLo.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

