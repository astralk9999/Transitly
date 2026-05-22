import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../data/offline_region/domain/offline_region_repository.dart';
import '../../data/offline_region/offline_region_repository_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/models/offline_region.dart';
import '../../shared/providers/is_dark_provider.dart';
import '../../shared/providers/user_provider.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/smoke_background.dart';
import '../../shared/widgets/transit_app_bar.dart';
import '../../shared/widgets/transit_button.dart';
import 'widgets/region_download_sheet.dart';
import 'widgets/region_progress_card.dart';

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
    final userId = ref.watch(currentUserProvider.select((u) => u.id));

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
                    userId: userId,
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
    required this.userId,
  });

  final OfflineRegionRepository repo;
  final bool isDark;
  final TransitColorScheme c;
  final AppLocalizations l10n;
  final VoidCallback onRefresh;
  final VoidCallback onShowDownload;
  final String? userId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<OfflineRegion>>(
      future: repo.forUser(userId ?? ''),
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
            return RegionProgressCard(
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
