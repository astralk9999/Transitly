import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../data/mock/mock_data_service.dart';
import '../../../data/widgets_native/widget_refresh_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/models/route_model.dart';
import '../../../shared/models/stop_model.dart';
import '../../../shared/providers/home_habitual_config_provider.dart';
import '../../../shared/widgets/transit_button.dart';
import 'home_bottom_nav.dart';

void showHabitualConfigSheet(BuildContext context, WidgetRef ref) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final c = TransitColorScheme.of(isDark);
  final mockData = ref.read(mockDataServiceProvider);
  final l10n = AppLocalizations.of(context);

  final routes = mockData.routes;

  final selectedRoute = _HabitualSheetState<RouteModel>();
  final selectedStop = _HabitualSheetState<StopModel>();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: c.bgSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          // Paradas únicas (dedupe por stopId) para la ruta elegida.
          // getStopsForRoute devuelve outbound+inbound; sin dedupe
          // aparecían paradas duplicadas o de sentido contrario.
          final stopsForRoute = selectedRoute.value != null
              ? _uniqueStopsFor(mockData, selectedRoute.value!.id)
              : <StopModel>[];
          final canSave =
              selectedRoute.value != null && selectedStop.value != null;

          // Padding inferior que respeta: teclado + safe area + nav bar
          // de la app. Sin sumar HomeBottomNav.height los botones quedan
          // tapados por la navegación.
          final mq = MediaQuery.of(ctx);
          final bottomInset = (24 +
              mq.viewInsets.bottom +
              mq.padding.bottom +
              HomeBottomNav.height)
              .clamp(16.0, 100.0);

          return Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 32,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: c.textLo,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  l10n.homeConfigureHabitualTitle,
                  style: TransitTypography.heading(c.textHi),
                ),
                const SizedBox(height: 20),
                // Autocomplete: el usuario escribe parte del código o
                // nombre (ej. "L1", "estadio") y se filtra. Si tu app
                // crece a cientos de líneas, esto sigue siendo usable.
                Autocomplete<RouteModel>(
                  displayStringForOption: (r) => '${r.code} · ${r.name}',
                  optionsBuilder: (textEditingValue) {
                    final q = textEditingValue.text.trim().toLowerCase();
                    if (q.isEmpty) return routes;
                    return routes.where((r) =>
                        r.code.toLowerCase().contains(q) ||
                        r.name.toLowerCase().contains(q));
                  },
                  onSelected: (r) {
                    setSheetState(() {
                      selectedRoute.value = r;
                      selectedStop.value = null;
                    });
                  },
                  fieldViewBuilder:
                      (ctx, controller, focusNode, onSubmitted) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      style: TransitTypography.bodyPrimary(c.textHi),
                      decoration: _sheetInputDecoration(
                        c,
                        l10n.homeConfigureHabitualRoute,
                      ).copyWith(
                        suffixIcon: Icon(Icons.search, color: c.textMid),
                      ),
                    );
                  },
                  optionsViewBuilder: (ctx, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        color: c.bgRaised,
                        elevation: 4,
                        borderRadius: BorderRadius.circular(8),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 240),
                          child: ListView.builder(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: options.length,
                            itemBuilder: (_, i) {
                              final r = options.elementAt(i);
                              return ListTile(
                                dense: true,
                                title: Text(
                                  '${r.code} · ${r.name}',
                                  style:
                                      TransitTypography.bodyPrimary(c.textHi),
                                ),
                                onTap: () => onSelected(r),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                // Sustituido el DropdownButtonFormField por un Autocomplete:
                // con muchas paradas el dropdown se desbordaba en toda la
                // pantalla y era imposible buscar. Ahora el usuario teclea
                // parte del nombre y la lista se filtra en sitio.
                Autocomplete<StopModel>(
                  displayStringForOption: (s) => s.name,
                  // Reset del input cuando cambia la ruta: el initialValue
                  // se evalúa solo al construir. Usamos clave dinámica:
                  key: ValueKey('stop-ac-${selectedRoute.value?.id}-'
                      '${selectedStop.value?.id}'),
                  optionsBuilder: (textEditingValue) {
                    if (selectedRoute.value == null) {
                      return const Iterable<StopModel>.empty();
                    }
                    final q = textEditingValue.text.trim().toLowerCase();
                    if (q.isEmpty) return stopsForRoute;
                    return stopsForRoute.where((s) =>
                        s.name.toLowerCase().contains(q) ||
                        s.officialCode.toLowerCase().contains(q));
                  },
                  initialValue: TextEditingValue(
                      text: selectedStop.value?.name ?? ''),
                  onSelected: (s) {
                    setSheetState(() {
                      selectedStop.value = s;
                    });
                  },
                  fieldViewBuilder:
                      (ctx, controller, focusNode, onSubmitted) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      enabled: selectedRoute.value != null,
                      style: TransitTypography.bodyPrimary(c.textHi),
                      decoration: _sheetInputDecoration(
                        c,
                        selectedRoute.value == null
                            ? l10n.homeConfigureHabitualSelectRouteFirst
                            : l10n.homeConfigureHabitualStop,
                      ).copyWith(
                        suffixIcon: Icon(Icons.search, color: c.textMid),
                      ),
                    );
                  },
                  optionsViewBuilder: (ctx, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        color: c.bgRaised,
                        elevation: 4,
                        borderRadius: BorderRadius.circular(8),
                        child: ConstrainedBox(
                          constraints:
                              const BoxConstraints(maxHeight: 240),
                          child: ListView.builder(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: options.length,
                            itemBuilder: (_, i) {
                              final s = options.elementAt(i);
                              return ListTile(
                                dense: true,
                                title: Text(
                                  s.name,
                                  style: TransitTypography.bodyPrimary(
                                      c.textHi),
                                ),
                                subtitle: s.officialCode.isEmpty
                                    ? null
                                    : Text(
                                        s.officialCode,
                                        style: TransitTypography.bodySmall(
                                            c.textLo),
                                      ),
                                onTap: () => onSelected(s),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                TransitButton(
                  label: l10n.actionSave,
                  onPressed: canSave
                      ? () async {
                          // Capturamos container y nav antes del await
                          // para no usar BuildContext tras async gap.
                          final container =
                              ProviderScope.containerOf(ctx);
                          final nav = Navigator.of(ctx);
                          await ref
                              .read(homeHabitualConfigProvider.notifier)
                              .save(selectedRoute.value!.id,
                                  selectedStop.value!.id);
                          // Refresca los widgets nativos inmediatamente
                          // tras guardar (antes el usuario tenía que
                          // esperar 30 min al sistema Android para verlos
                          // actualizados con la nueva línea habitual).
                          unawaited(WidgetRefreshService.refreshNow(
                              container));
                          nav.pop();
                        }
                      : null,
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

/// Paradas únicas de una ruta (dedupe por stopId), preservando el orden
/// del primer encuentro. Necesario porque routeStops contiene outbound
/// y inbound; sin dedupe el usuario vería "Plaza del Caballo" dos veces.
List<StopModel> _uniqueStopsFor(MockDataService mock, String routeId) {
  final seen = <String>{};
  final result = <StopModel>[];
  for (final s in mock.getStopsForRoute(routeId)) {
    if (seen.add(s.id)) result.add(s);
  }
  return result;
}

InputDecoration _sheetInputDecoration(TransitColorScheme c, String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: TransitTypography.bodySmall(c.textMid),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: c.border, width: 0.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: c.accent, width: 1),
    ),
    contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
  );
}

class _HabitualSheetState<T> {
  T? value;
}
