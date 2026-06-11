import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../data/mock/mock_data_extensions.dart';
import '../../data/mock/mock_data_service.dart';
import '../../data/widgets_native/widget_data_writer.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/providers/home_habitual_config_provider.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/transit_app_bar.dart';
import '../../shared/widgets/transit_button.dart';
import 'widgets/route_autocomplete.dart';
import 'widgets/widget_appearance_panel.dart';

class WidgetNextBusConfigScreen extends ConsumerStatefulWidget {
  const WidgetNextBusConfigScreen({super.key});

  @override
  ConsumerState<WidgetNextBusConfigScreen> createState() =>
      _WidgetNextBusConfigScreenState();
}

class _WidgetNextBusConfigScreenState
    extends ConsumerState<WidgetNextBusConfigScreen> {
  String? _routeId;
  String? _stopId;
  String _previewRoute = '--';
  // Vacío al inicio; build() lo sustituye por l10n.widgetsConfigUnconfigured
  // cuando no hay configuración. No podemos usar AppLocalizations aquí
  // (no hay context disponible en field initializer).
  String _previewTime = '';
  String _previewStop = '';

  @override
  void initState() {
    super.initState();
    final cfg = ref.read(homeHabitualConfigProvider);
    _routeId = cfg.routeId;
    _stopId = cfg.stopId;
    _updatePreview();
  }

  void _updatePreview() {
    final mockData = ref.read(mockDataServiceProvider);
    if (_routeId != null && _stopId != null) {
      final route = mockData.getRouteById(_routeId!);
      final deps = mockData.getNextDepartures(_routeId!, _stopId!, 1);
      final stop = mockData.getStopById(_stopId!);
      setState(() {
        _previewRoute = route?.code ?? _routeId!;
        _previewTime = deps.isNotEmpty ? deps.first.departureTime : '--:--';
        _previewStop = stop?.name ?? _stopId!;
      });
    }
  }

  Future<void> _testWidget() async {
    final mockData = ref.read(mockDataServiceProvider);
    if (_routeId == null || _stopId == null) return;
    final route = mockData.getRouteById(_routeId!);
    final stop = mockData.getStopById(_stopId!);
    final deps = mockData.getNextDepartures(_routeId!, _stopId!, 1);
    if (route != null && deps.isNotEmpty) {
      await HomeWidget.setAppGroupId('group.com.transitly.transitly');
      final now = DateTime.now();
      final parts = deps.first.departureTime.split(':');
      final depMin = (int.tryParse(parts[0]) ?? 0) * 60 +
          (parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0);
      final nowMin = now.hour * 60 + now.minute;
      var eta = depMin - nowMin;
      if (eta < 0) eta += 24 * 60;
      await WidgetDataWriter.writeNextBus(
        stopName: stop?.name ?? _stopId!,
        routeCode: route.code,
        etaMinutes: eta,
        source: 'user_config',
        updatedAt: now,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).widgetsConfigUpdated)),
        );
      }
    }
  }

  Future<void> _save() async {
    if (_routeId != null && _stopId != null) {
      await ref
          .read(homeHabitualConfigProvider.notifier)
          .save(_routeId!, _stopId!);
      _updatePreview();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).widgetsConfigSaved)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final l10n = AppLocalizations.of(context);
    final mockData = ref.watch(mockDataServiceProvider);
    final routes = mockData.routes;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: TransitAppBar(
          title: l10n.widgetsConfigNextBus, transparent: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PreviewCard(
              c: c,
              routeCode: _previewRoute,
              time: _previewTime.isEmpty
                  ? l10n.widgetsConfigUnconfigured
                  : _previewTime,
              stop: _previewStop,
            ),
            const SizedBox(height: 24),
            Text(l10n.widgetsConfigRouteLabel, style: TransitTypography.bodySecondary(c.textHi)),
            const SizedBox(height: 8),
            RouteAutocomplete(
              routes: routes,
              label: l10n.widgetsConfigRouteLabel,
              initialValue:
                  _routeId != null ? mockData.getRouteById(_routeId!) : null,
              onSelected: (r) {
                setState(() {
                  _routeId = r.id;
                  _stopId = null;
                });
              },
            ),
            if (_routeId != null) ...[
              const SizedBox(height: 16),
              Text(l10n.widgetsConfigStopLabel, style: TransitTypography.bodySecondary(c.textHi)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _stopId,
                dropdownColor: c.bgSurface,
                style: TransitTypography.bodyPrimary(c.textHi),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: c.bgInput,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: c.border),
                  ),
                ),
                items: mockData
                    .getUniqueStopsForRoute(_routeId!)
                    .map((s) => DropdownMenuItem(
                          value: s.id,
                          child: Text(s.name),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _stopId = v),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TransitButton(
                    label: l10n.widgetsConfigTestButton,
                    isPrimary: false,
                    onPressed: _routeId != null && _stopId != null
                        ? _testWidget
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TransitButton(
                    label: l10n.widgetsConfigSaveButton,
                    onPressed: _routeId != null && _stopId != null
                        ? _save
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const WidgetAppearancePanel(),
          ],
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.c,
    required this.routeCode,
    required this.time,
    required this.stop,
  });

  final TransitColorScheme c;
  final String routeCode;
  final String time;
  final String stop;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      blur: 16,
      fillOpacity: 0.05,
      borderRadius: 14,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: c.accent,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(routeCode,
                style: TransitTypography.routeCode(Colors.white)),          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(time, style: TransitTypography.displayTime(c.textHi)),
                const SizedBox(height: 4),
                Text(stop.isNotEmpty ? stop : 'Sin configurar',
                    style: TransitTypography.bodySecondary(c.textMid)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
