import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../../core/utils/app_logger.dart';
import '../../data/mock/mock_data_service.dart';
import '../../data/widgets_native/widget_data_writer.dart';
import '../providers/home_habitual_config_provider.dart';
import '../providers/nfc_provider.dart';
import '../providers/user_favorites_provider.dart';

const _appGroupId = 'group.com.transitly.transitly';
const _logTag = 'WidgetSync';

final widgetSyncListenerProvider = Provider.autoDispose<void>((ref) {
  final mockData = ref.watch(mockDataServiceProvider);

  ref.listen(homeHabitualConfigProvider, (prev, next) async {
    if (!next.isConfigured) return;
    if (prev?.routeId == next.routeId && prev?.stopId == next.stopId) return;
    AppLogger.debug(_logTag, 'config changed → syncNextBus');
    try {
      final route = mockData.getRouteById(next.routeId!);
      if (route == null) return;
      final deps = mockData.getNextDepartures(next.routeId!, next.stopId!, 4);
      if (deps.isEmpty) return;
      final first = deps.first;
      final now = DateTime.now();
      final parts = first.departureTime.split(':');
      final depHour = int.tryParse(parts[0]) ?? 0;
      final depMin = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
      final depMinutes = depHour * 60 + depMin;
      final nowMinutes = now.hour * 60 + now.minute;
      var eta = depMinutes - nowMinutes;
      if (eta < 0) eta += 24 * 60;
      final stop = mockData.getStopById(next.stopId!);
      await HomeWidget.setAppGroupId(_appGroupId);
      await WidgetDataWriter.writeNextBus(
        stopName: stop?.name ?? next.stopId!,
        routeCode: route.code,
        etaMinutes: eta,
        source: 'user_config',
        updatedAt: now,
      );
    } catch (e) {
      AppLogger.warn(_logTag, 'syncNextBus failed', e);
    }
  });

  ref.listen(userFavoritesProvider, (prev, next) async {
    if (prev == next) return;
    AppLogger.debug(_logTag, 'favs changed → syncMyLine');
    try {
      if (next.isEmpty) return;
      final routeId = next.first;
      final route = mockData.getRouteById(routeId);
      if (route == null) return;
      final stops = mockData.getStopsForRoute(routeId);
      final stopId = stops.isNotEmpty ? stops.first.id : '';
      final deps = mockData.getNextDepartures(routeId, stopId, 4);
      final upcoming = deps.map((d) => {'time': d.departureTime}).toList();
      await HomeWidget.setAppGroupId(_appGroupId);
      await WidgetDataWriter.writeMyLineStatus(
        routeCode: route.code,
        upcoming: upcoming,
      );
    } catch (e) {
      AppLogger.warn(_logTag, 'syncMyLine failed', e);
    }
  });

  ref.listen(nfcScanProvider, (prev, next) async {
    if (next.status == NfcScanStatus.success && next.result != null) {
      AppLogger.debug(_logTag, 'nfc scanned → syncNfcBalance');
      try {
        await HomeWidget.setAppGroupId(_appGroupId);
        await WidgetDataWriter.writeNfcBalance(
          balance: next.result!.balance,
          scannedAt: next.result!.scannedAt,
        );
      } catch (e) {
        AppLogger.warn(_logTag, 'syncNfcBalance failed', e);
      }
    }
  });
});
