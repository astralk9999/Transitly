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

  RouteModel? selectedRoute;
  StopModel? selectedStop;

  showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: c.bgSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          final stopsForRoute = selectedRoute != null
              ? _uniqueStopsFor(mockData, selectedRoute!.id)
              : <StopModel>[];
          final canSave = selectedRoute != null && selectedStop != null;

          // Este sheet ya NO contiene los buscadores con teclado: cada campo
          // abre un selector buscable a pantalla casi completa (el teclado
          // queda abajo y la lista arriba, sin taparse). Así el padding solo
          // necesita respetar la safe area y la nav bar de la app.
          final mq = MediaQuery.of(ctx);
          final bottomInset =
              (24 + mq.padding.bottom + HomeBottomNav.height).clamp(16.0, 100.0);

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
                // Campo Línea: abre selector buscable.
                _PickerField(
                  c: c,
                  label: l10n.homeConfigureHabitualRoute,
                  value: selectedRoute == null
                      ? null
                      : '${selectedRoute!.code} · ${selectedRoute!.name}',
                  onTap: () async {
                    final picked = await _showSearchPicker<RouteModel>(
                      context: ctx,
                      c: c,
                      title: l10n.homeConfigureHabitualRoute,
                      items: routes,
                      labelOf: (r) => '${r.code} · ${r.name}',
                      matches: (r, q) =>
                          r.code.toLowerCase().contains(q) ||
                          r.name.toLowerCase().contains(q),
                    );
                    if (picked != null) {
                      setSheetState(() {
                        selectedRoute = picked;
                        selectedStop = null; // resetea la parada al cambiar línea
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                // Campo Parada: deshabilitado hasta elegir línea.
                _PickerField(
                  c: c,
                  label: selectedRoute == null
                      ? l10n.homeConfigureHabitualSelectRouteFirst
                      : l10n.homeConfigureHabitualStop,
                  value: selectedStop?.name,
                  enabled: selectedRoute != null,
                  onTap: () async {
                    final picked = await _showSearchPicker<StopModel>(
                      context: ctx,
                      c: c,
                      title: l10n.homeConfigureHabitualStop,
                      items: stopsForRoute,
                      labelOf: (s) => s.name,
                      sublabelOf: (s) =>
                          s.officialCode.isEmpty ? null : s.officialCode,
                      matches: (s, q) =>
                          s.name.toLowerCase().contains(q) ||
                          s.officialCode.toLowerCase().contains(q),
                    );
                    if (picked != null) {
                      setSheetState(() => selectedStop = picked);
                    }
                  },
                ),
                const SizedBox(height: 24),
                TransitButton(
                  label: l10n.actionSave,
                  onPressed: canSave
                      ? () async {
                          final container = ProviderScope.containerOf(ctx);
                          final nav = Navigator.of(ctx);
                          await ref
                              .read(homeHabitualConfigProvider.notifier)
                              .save(selectedRoute!.id, selectedStop!.id);
                          unawaited(
                              WidgetRefreshService.refreshNow(container));
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

/// Campo táctil que muestra el valor elegido (o un placeholder) y abre el
/// selector buscable al pulsarlo. Sustituye al Autocomplete cuyo desplegable
/// quedaba tapado por el teclado dentro del bottom sheet.
class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.c,
    required this.label,
    required this.value,
    required this.onTap,
    this.enabled = true,
  });

  final TransitColorScheme c;
  final String label;
  final String? value;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: c.border, width: 0.5),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  hasValue ? value! : label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: hasValue
                      ? TransitTypography.bodyPrimary(c.textHi)
                      : TransitTypography.bodyPrimary(c.textMid),
                ),
              ),
              Icon(hasValue ? Icons.edit : Icons.search, color: c.textMid, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

/// Selector buscable a pantalla casi completa: campo de búsqueda arriba
/// (autofocus) y lista filtrada debajo, scrollable. El teclado aparece abajo
/// sin tapar la lista (el problema del Autocomplete en bottom sheet).
Future<T?> _showSearchPicker<T>({
  required BuildContext context,
  required TransitColorScheme c,
  required String title,
  required List<T> items,
  required String Function(T) labelOf,
  required bool Function(T, String) matches,
  String? Function(T)? sublabelOf,
}) {
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: c.bgSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: (ctx) => _SearchPickerBody<T>(
      c: c,
      title: title,
      items: items,
      labelOf: labelOf,
      matches: matches,
      sublabelOf: sublabelOf,
    ),
  );
}

class _SearchPickerBody<T> extends StatefulWidget {
  const _SearchPickerBody({
    required this.c,
    required this.title,
    required this.items,
    required this.labelOf,
    required this.matches,
    this.sublabelOf,
  });

  final TransitColorScheme c;
  final String title;
  final List<T> items;
  final String Function(T) labelOf;
  final bool Function(T, String) matches;
  final String? Function(T)? sublabelOf;

  @override
  State<_SearchPickerBody<T>> createState() => _SearchPickerBodyState<T>();
}

class _SearchPickerBodyState<T> extends State<_SearchPickerBody<T>> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final mq = MediaQuery.of(context);
    final q = _query.trim().toLowerCase();
    final filtered =
        q.isEmpty ? widget.items : widget.items.where((e) => widget.matches(e, q)).toList();

    return Padding(
      // Eleva todo el contenido por encima del teclado.
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: FractionallySizedBox(
        heightFactor: 0.9,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: c.textLo,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(widget.title,
                        style: TransitTypography.heading(c.textHi)),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: c.textMid),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                autofocus: true,
                style: TransitTypography.bodyPrimary(c.textHi),
                cursorColor: c.accent,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Buscar…',
                  hintStyle: TransitTypography.bodyPrimary(c.textMid),
                  prefixIcon: Icon(Icons.search, color: c.textMid),
                  filled: true,
                  fillColor: c.bgInput,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: c.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: c.border, width: 0.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: c.accent, width: 1),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text('Sin resultados',
                            style: TransitTypography.bodySecondary(c.textMid)),
                      )
                    : ListView.builder(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final item = filtered[i];
                          final sub = widget.sublabelOf?.call(item);
                          return ListTile(
                            title: Text(widget.labelOf(item),
                                style: TransitTypography.bodyPrimary(c.textHi)),
                            subtitle: (sub == null || sub.isEmpty)
                                ? null
                                : Text(sub,
                                    style: TransitTypography.bodySmall(c.textLo)),
                            onTap: () => Navigator.of(context).pop(item),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
