import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' show LatLngBounds;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/cache/hive_box_provider.dart';
import '../../../data/fmtc/fmtc_region_service.dart';
import '../../../data/offline_region/offline_region_repository_provider.dart';
import '../../../data/route/local/route_local_repository.dart';
import '../../../data/schedule/local/schedule_local_repository.dart';
import '../../../data/stop/local/stop_local_repository.dart';
import '../../../data/supabase/supabase_client_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/offline_region.dart';
import '../../../shared/models/route_model.dart';
import '../../../shared/models/schedule_model.dart';
import '../../../shared/models/stop_model.dart';
import '../../../shared/providers/theme_notifier.dart';
import '../../../shared/widgets/gradient_text.dart';
import '../../../shared/widgets/transit_button.dart';
import 'region_status_badge.dart';

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

  static const _logTag = 'RegionDownload';

  Future<void> _startDownload() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isDownloading = true);

    final repo = ref.read(offlineRegionRepositoryProvider);
    final bounds = const OfflineRegionBounds(
      northLat: 36.70,
      southLat: 36.67,
      eastLng: -6.10,
      westLng: -6.15,
    );

    final regionId = 'region-${DateTime.now().millisecondsSinceEpoch}';
    final region = OfflineRegion(
      id: regionId,
      label: name,
      bounds: bounds,
      zoomMin: _zoomMin,
      zoomMax: _zoomMax,
      downloadedAt: DateTime.now(),
      sizeBytes: 0,
      status: OfflineRegionStatus.downloading,
    );
    await repo.add(region);

    try {
      final client = ref.read(supabaseClientProvider);
      setState(() => _downloadProgress = 0.1);

      final result = await client.rpc(
        'export_region_data',
        params: <String, dynamic>{
          'p_north': bounds.northLat,
          'p_south': bounds.southLat,
          'p_east': bounds.eastLng,
          'p_west': bounds.westLng,
          'p_zoom_min': _zoomMin,
          'p_zoom_max': _zoomMax,
        },
      );

      setState(() => _downloadProgress = 0.5);

      if (result is Map<String, dynamic>) {
        final stopBox = ref.read(stopsBoxProvider);
        final routeBox = ref.read(routesBoxProvider);
        final scheduleBox = ref.read(schedulesBoxProvider);

        final stopRepo = StopLocalRepository(stopBox);
        final routeRepo = RouteLocalRepository(routeBox);
        final scheduleRepo = ScheduleLocalRepository(scheduleBox);

        final stopsRaw = result['stops'] as List<dynamic>? ?? const <dynamic>[];
        final routesRaw =
            result['routes'] as List<dynamic>? ?? const <dynamic>[];
        final schedulesRaw =
            result['schedules'] as List<dynamic>? ?? const <dynamic>[];

        if (stopsRaw.isNotEmpty) {
          final stops = stopsRaw
              .map((e) => _stopFromRow(e as Map<String, dynamic>))
              .toList(growable: false);
          await stopRepo.upsertAll(stops);
        }

        if (routesRaw.isNotEmpty) {
          final routes = routesRaw
              .map((e) => _routeFromRow(e as Map<String, dynamic>))
              .toList(growable: false);
          await routeRepo.upsertAll(routes);
        }

        if (schedulesRaw.isNotEmpty) {
          final schedules = schedulesRaw
              .map((e) => _scheduleFromRow(e as Map<String, dynamic>))
              .toList(growable: false);
          await scheduleRepo.upsertAll(schedules);
        }
      }

      setState(() => _downloadProgress = 0.5);

      // Descarga real de tiles con FMTC del estilo activo. La RPC anterior
      // pobló metadata (stops/routes/schedules); ahora descargamos las
      // tiles para que el mapa funcione visualmente en offline.
      final style = ref.read(themeNotifierProvider).mapStyle;
      try {
        final tileStream = await FmtcRegionService.downloadRegion(
          style: style,
          bounds: LatLngBounds(
            LatLng(bounds.southLat, bounds.westLng),
            LatLng(bounds.northLat, bounds.eastLng),
          ),
          minZoom: _zoomMin,
          maxZoom: _zoomMax,
        );
        final estimatedTotal = _estimatedTileCount.clamp(1, 1000000);
        await for (final downloaded in tileStream) {
          if (!mounted) break;
          final tileProgress = (downloaded / estimatedTotal).clamp(0.0, 1.0);
          setState(() {
            _downloadProgress = 0.5 + tileProgress * 0.4;
          });
        }
      } catch (e) {
        AppLogger.warn(_logTag, 'fmtc tiles download failed', e);
        // Continúa: metadata sí descargada, tiles no.
      }

      setState(() => _downloadProgress = 0.95);

      const avgTileBytes = 15000;
      final finalSize = _estimatedTileCount * avgTileBytes;
      final readyRegion = OfflineRegion(
        id: regionId,
        label: name,
        bounds: bounds,
        zoomMin: _zoomMin,
        zoomMax: _zoomMax,
        downloadedAt: DateTime.now(),
        sizeBytes: finalSize,
        status: OfflineRegionStatus.ready,
        dataSyncedAt: DateTime.now(),
      );
      await repo.add(readyRegion);

      setState(() => _downloadProgress = 1.0);
      AppLogger.info(_logTag, 'region exported: $name ($regionId)');

      if (mounted) {
        setState(() => _isDownloading = false);
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      AppLogger.warn(_logTag, 'export_region_data failed, saving as error', e);
      final errorRegion = OfflineRegion(
        id: regionId,
        label: name,
        bounds: bounds,
        zoomMin: _zoomMin,
        zoomMax: _zoomMax,
        downloadedAt: DateTime.now(),
        sizeBytes: 0,
        status: OfflineRegionStatus.error,
      );
      await repo.add(errorRegion);

      if (mounted) {
        setState(() => _isDownloading = false);
        Navigator.of(context).pop(true);
      }
    }
  }

  StopModel _stopFromRow(Map<String, dynamic> row) {
    final geom = row['geom'] as Map<String, dynamic>?;
    final coords =
        (geom?['coordinates'] as List<dynamic>?) ?? const <dynamic>[0, 0];
    final lng = (coords.isNotEmpty ? coords[0] as num : 0).toDouble();
    final lat = (coords.length > 1 ? coords[1] as num : 0).toDouble();
    final access = (row['accessibility'] as Map<String, dynamic>?) ??
        const <String, dynamic>{};
    final meta =
        (row['metadata'] as Map<String, dynamic>?) ?? const <String, dynamic>{};

    return StopModel(
      id: row['id'] as String,
      name: row['name'] as String,
      officialCode: row['code'] as String? ?? '',
      lat: lat,
      lng: lng,
      municipality: meta['municipality'] as String? ?? '',
      zoneId: meta['zoneId'] as String?,
      hasShelter: access['hasShelter'] as bool? ?? false,
      hasBench: access['hasBench'] as bool? ?? false,
      isAccessible: access['isAccessible'] as bool? ?? false,
      hasDisplay: access['hasDisplay'] as bool? ?? false,
      photoUrl: meta['photoUrl'] as String?,
      notes: meta['notes'] as String?,
    );
  }

  RouteModel _routeFromRow(Map<String, dynamic> row) {
    final meta =
        (row['metadata'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    final colorHex = row['color'] as String?;
    final routeColor = colorHex != null && colorHex.isNotEmpty
        ? _parseHexColor(colorHex)
        : const Color(0xFF888888);
    final statusStr = row['status'] as String? ?? 'official';

    return RouteModel(
      id: row['id'] as String,
      operatorId: row['operator_id'] as String? ?? '',
      code: row['code'] as String? ?? '',
      name: row['name'] as String,
      serviceType:
          ServiceType.fromString(meta['serviceType'] as String? ?? 'urban'),
      routeColor: routeColor,
      isCircular: meta['isCircular'] as bool? ?? false,
      status: RouteStatus.fromString(statusStr),
      active: statusStr != 'suspended',
    );
  }

  ScheduleModel _scheduleFromRow(Map<String, dynamic> row) {
    final raw = row['departure_time'] as String;
    final hhmm = raw.length >= 5 ? raw.substring(0, 5) : raw;
    return ScheduleModel(
      id: row['id'] as String,
      routeId: row['route_id'] as String,
      departureTime: hhmm,
      dayType: DayType.fromString(row['day_type'] as String? ?? 'weekday'),
    );
  }

  static const Color _defaultRouteColor = Color(0xFF888888);

  static Color _parseHexColor(String hex) {
    try {
      var clean = hex.startsWith('#') ? hex.substring(1) : hex;
      if (clean.startsWith('0x') || clean.startsWith('0X')) {
        clean = clean.substring(2);
      }
      if (clean.length != 6 && clean.length != 8) return _defaultRouteColor;
      if (clean.length == 6) clean = 'FF$clean';
      final value = int.tryParse(clean, radix: 16);
      if (value == null) return _defaultRouteColor;
      return Color(value);
    } catch (_) {
      return _defaultRouteColor;
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
                  tooltip: 'Cerrar',
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
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: c.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      AppLocalizations.of(context).offlineRegionDemoLimitation,
                      style: TextStyle(color: c.textMid, fontSize: 12),
                    ),
                  ),
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
                  RegionStatusBadge(
                    isDownloading: _isDownloading,
                    progress: _downloadProgress,
                    c: c,
                  ),
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
      color: c.bgRoot,
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
