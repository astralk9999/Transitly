import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/cache/hive_init.dart';
import '../../../data/cache/storage_repository.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/models/offline_region.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_text.dart';

class StorageSection extends ConsumerWidget {
  const StorageSection({required this.c, required this.l10n, super.key});

  final TransitColorScheme c;
  final AppLocalizations l10n;

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  int _fileSize(WidgetRef ref, String boxName) {
    return ref.read(storageRepositoryProvider).fileSize(boxName);
  }

  static int _directorySize(Directory dir) {
    var total = 0;
    try {
      if (!dir.existsSync()) return 0;
      for (final entity in dir.listSync(recursive: true)) {
        if (entity is File) total += entity.lengthSync();
      }
    } catch (e) {
      AppLogger.warn('Appearance', 'directory size scan failed', e);
    }
    return total;
  }

  int _computeHiveSize(WidgetRef ref) {
    var total = 0;
    const boxNames = [
      HiveBoxes.routes,
      HiveBoxes.stops,
      HiveBoxes.schedules,
      HiveBoxes.operators,
      HiveBoxes.userPreferences,
      HiveBoxes.offlineRegions,
      HiveBoxes.alerts,
      HiveBoxes.incidents,
      HiveBoxes.routeFeedback,
      HiveBoxes.routeSuggestions,
      HiveBoxes.featureRequests,
      HiveBoxes.notifications,
      HiveBoxes.editorDrafts,
      HiveBoxes.authSessionMeta,
    ];
    for (final name in boxNames) {
      total += _fileSize(ref, name);
    }
    return total;
  }

  int _computePendingSize(WidgetRef ref) {
    var total = 0;
    for (final name in [HiveBoxes.pendingActions, HiveBoxes.deadLetterActions]) {
      total += _fileSize(ref, name);
    }
    return total;
  }

  ({int sizeBytes, bool available}) _computeFmtcSize(WidgetRef ref) {
    try {
      final hivePath = ref.read(storageRepositoryProvider).boxPath(HiveBoxes.routes);
      if (hivePath == null) return (sizeBytes: 0, available: false);
      final appDir = File(hivePath).parent;
      final fmtcDir = Directory(
          '${appDir.path}${Platform.pathSeparator}fmtc${Platform.pathSeparator}store');
      if (!fmtcDir.existsSync()) return (sizeBytes: 0, available: false);
      return (sizeBytes: _directorySize(fmtcDir), available: true);
    } catch (e) {
      AppLogger.warn('Appearance', 'FMTC size unavailable', e);
      return (sizeBytes: 0, available: false);
    }
  }

  Future<void> _clearCache(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.bgSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: c.border, width: 1),
        ),
        title: Text(l10n.appearanceStorageClearCache,
            style: TransitTypography.heading(c.textHi)),
        content: Text(l10n.appearanceStorageClearCacheConfirm,
            style: TransitTypography.bodyPrimary(c.textMid)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.actionCancel,
                style: TransitTypography.bodyPrimary(c.textMid)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.appearanceStorageClearCache,
                style: TransitTypography.bodyPrimary(c.accent)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await Hive.box<OfflineRegion>(HiveBoxes.offlineRegions).clear();
    } catch (e) {
      AppLogger.warn('Appearance', 'offline regions box clear failed', e);
    }

    try {
      final hivePath = ref.read(storageRepositoryProvider).boxPath(HiveBoxes.routes);
      if (hivePath != null) {
        final appDir = File(hivePath).parent;
        final fmtcDir = Directory(
            '${appDir.path}${Platform.pathSeparator}fmtc${Platform.pathSeparator}store');
        if (fmtcDir.existsSync()) {
          await fmtcDir.delete(recursive: true);
        }
      }
    } catch (e) {
      AppLogger.warn('Appearance', 'FMTC cache delete failed', e);
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.appearanceStorageClearCacheDone),
          backgroundColor: c.bgRaised,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hiveSize = _computeHiveSize(ref);
    final pendingSize = _computePendingSize(ref);
    final fmtc = _computeFmtcSize(ref);
    final totalSize = hiveSize + pendingSize + fmtc.sizeBytes;

    return GlassCard(
      blur: 16,
      fillOpacity: 0.05,
      borderRadius: 14,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientText(
            l10n.appearanceStorageSection,
            style: TransitTypography.sectionLabel(Colors.white),
            gradient: c.gradientAccent,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(l10n.appearanceStorageTotal,
                    style: TransitTypography.bodyPrimary(c.textHi)),
              ),
              Text(_formatBytes(totalSize),
                  style: TransitTypography.bodyPrimary(c.accent)),
            ],
          ),
          const SizedBox(height: 8),
          if (fmtc.available)
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(l10n.appearanceStorageFmtc,
                        style: TransitTypography.bodySmall(c.textMid)),
                  ),
                  Text(_formatBytes(fmtc.sizeBytes),
                      style: TransitTypography.bodySmall(c.textMid)),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(l10n.appearanceStorageHive,
                      style: TransitTypography.bodySmall(c.textMid)),
                ),
                Text(_formatBytes(hiveSize),
                    style: TransitTypography.bodySmall(c.textMid)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(l10n.appearanceStoragePending,
                      style: TransitTypography.bodySmall(c.textMid)),
                ),
                Text(_formatBytes(pendingSize),
                    style: TransitTypography.bodySmall(c.textMid)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(l10n.appearanceStorageMaxInfo,
              style: TransitTypography.bodySmall(c.textLo)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _clearCache(context, ref),
              icon: Icon(Icons.delete_sweep, color: c.textMid, size: 18),
              label: Text(l10n.appearanceStorageClearCache,
                  style: TransitTypography.bodyPrimary(c.textMid)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: c.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
