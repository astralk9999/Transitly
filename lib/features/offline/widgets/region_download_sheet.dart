import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../data/offline_region/offline_region_repository_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/models/offline_region.dart';
import '../../../shared/widgets/gradient_text.dart';
import '../../../shared/widgets/transit_button.dart';

class RegionDownloadSheet extends ConsumerStatefulWidget {
  const RegionDownloadSheet({super.key});

  @override
  ConsumerState<RegionDownloadSheet> createState() =>
      _RegionDownloadSheetState();
}

class _RegionDownloadSheetState extends ConsumerState<RegionDownloadSheet> {
  final _nameController = TextEditingController();
  int _zoomMin = 12;
  int _zoomMax = 16;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  int get _estimatedTileCount {
    var count = 0;
    for (var z = _zoomMin; z <= _zoomMax; z++) {
      final tilesAtZoom = 1 << z;
      count += tilesAtZoom * tilesAtZoom;
    }
    return count;
  }

  String get _estimatedSize {
    const avgTileBytes = 15000;
    final totalBytes = _estimatedTileCount * avgTileBytes;
    if (totalBytes < 1024) return '$totalBytes B';
    if (totalBytes < 1024 * 1024) {
      return '${(totalBytes / 1024).toStringAsFixed(1)} KB';
    }
    if (totalBytes < 1024 * 1024 * 1024) {
      return '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(totalBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  Future<void> _startDownload() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isDownloading = true);

    final repo = ref.read(offlineRegionRepositoryProvider);
    final region = OfflineRegion(
      id: 'region-${DateTime.now().millisecondsSinceEpoch}',
      label: name,
      bounds: const OfflineRegionBounds(
        northLat: 36.70,
        southLat: 36.67,
        eastLng: -6.10,
        westLng: -6.15,
      ),
      zoomMin: _zoomMin,
      zoomMax: _zoomMax,
      downloadedAt: DateTime.now(),
      sizeBytes: 0,
      status: OfflineRegionStatus.downloading,
    );

    await repo.add(region);

    for (int i = 1; i <= 10; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      setState(() => _downloadProgress = i / 10);
    }

    const avgTileBytes = 15000;
    final finalSize = _estimatedTileCount * avgTileBytes;
    final readyRegion = OfflineRegion(
      id: region.id,
      label: region.label,
      bounds: region.bounds,
      zoomMin: region.zoomMin,
      zoomMax: region.zoomMax,
      downloadedAt: DateTime.now(),
      sizeBytes: finalSize,
      status: OfflineRegionStatus.ready,
    );
    await repo.add(readyRegion);

    if (mounted) {
      setState(() => _isDownloading = false);
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final l10n = AppLocalizations.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: c.bgSurface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: c.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: GradientText(
                    l10n.offlineRegionsAddRegion,
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    gradient: c.gradientAccent,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 20, color: c.textMid),
                  onPressed: () => Navigator.of(context).pop(),
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.offlineRegionsRegionName,
                      style: TransitTypography.bodySmall(c.textLo)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nameController,
                    style: TransitTypography.bodyPrimary(c.textHi),
                    cursorColor: c.accent,
                    decoration: InputDecoration(
                      hintText: l10n.offlineRegionsRegionNameHint,
                      hintStyle: TransitTypography.bodyPrimary(c.textLo),
                      filled: true,
                      fillColor: c.bgInput,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            BorderSide(color: c.border, width: 0.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            BorderSide(color: c.border, width: 0.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            BorderSide(color: c.borderFocus, width: 1),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(l10n.offlineRegionsSelectArea,
                      style: TransitTypography.bodySmall(c.textLo)),
                  const SizedBox(height: 8),
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: c.border.withValues(alpha: 0.5)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _AreaSelectorPreview(isDark: isDark, c: c),
                  ),
                  const SizedBox(height: 16),
                  Text(l10n.offlineRegionsZoomMin,
                      style: TransitTypography.bodySmall(c.textLo)),
                  Slider(
                    value: _zoomMin.toDouble(),
                    min: 8,
                    max: 15,
                    divisions: 7,
                    activeColor: c.accent,
                    label: '$_zoomMin',
                    onChanged: (v) {
                      final newZoom = v.round();
                      if (newZoom < _zoomMax) {
                        setState(() => _zoomMin = newZoom);
                      }
                    },
                  ),
                  Text(l10n.offlineRegionsZoomMax,
                      style: TransitTypography.bodySmall(c.textLo)),
                  Slider(
                    value: _zoomMax.toDouble(),
                    min: 10,
                    max: 18,
                    divisions: 8,
                    activeColor: c.accent,
                    label: '$_zoomMax',
                    onChanged: (v) {
                      final newZoom = v.round();
                      if (newZoom > _zoomMin) {
                        setState(() => _zoomMax = newZoom);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: c.bgInput,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: c.border.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Text(l10n.offlineRegionsEstimatedSize,
                            style:
                                TransitTypography.bodyPrimary(c.textMid)),
                        const Spacer(),
                        Text(_estimatedSize,
                            style: GoogleFonts.ibmPlexMono(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: c.accent,
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_isDownloading) ...[
                    LinearProgressIndicator(
                      value: _downloadProgress,
                      backgroundColor: c.border,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(c.accent),
                    ),
                    const SizedBox(height: 8),
                  ],
                  TransitButton(
                    label: _isDownloading
                        ? '${l10n.offlineRegionsActionDownload} ${(_downloadProgress * 100).round()}%'
                        : l10n.offlineRegionsActionDownload,
                    isLoading: _isDownloading,
                    onPressed: _isDownloading ? null : _startDownload,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AreaSelectorPreview extends StatelessWidget {
  const _AreaSelectorPreview({required this.isDark, required this.c});

  final bool isDark;
  final TransitColorScheme c;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? const Color(0xFF0A0A20) : const Color(0xFFE8E8F0),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map,
                    size: 40, color: c.accent.withValues(alpha: 0.4)),
                const SizedBox(height: 8),
                Text(
                  'Jerez de la Frontera',
                  style: TransitTypography.bodySmall(
                      c.textLo.withValues(alpha: 0.6)),
                ),
                Text(
                  '36.68\u00b0, -6.12\u00b0',
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 11,
                    color: c.textLo.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '\u00a9 OSM',
                style: TextStyle(fontSize: 8, color: c.textMid),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
