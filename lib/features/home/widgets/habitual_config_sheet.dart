import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../data/mock/mock_data_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/models/route_model.dart';
import '../../../shared/models/stop_model.dart';
import '../../../shared/providers/home_habitual_config_provider.dart';
import '../../../shared/widgets/transit_button.dart';

void showHabitualConfigSheet(BuildContext context, WidgetRef ref) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final c = TransitColorScheme.of(isDark);
  final mockData = ref.read(mockDataServiceProvider);
  final l10n = AppLocalizations.of(context);

  final routes = mockData.routes;

  final selectedRoute = _HabitualSheetState<RouteModel>();
  final selectedStop = _HabitualSheetState<StopModel>();
  final routeController = _SheetDropdownController();
  final stopController = _SheetDropdownController();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: c.bgSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          final stopsForRoute = selectedRoute.value != null
              ? mockData.getStopsForRoute(selectedRoute.value!.id)
              : <StopModel>[];
          final canSave =
              selectedRoute.value != null && selectedStop.value != null;

          return Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              24 + MediaQuery.of(ctx).viewInsets.bottom,
            ),
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
                DropdownButtonFormField<RouteModel>(
                  key: routeController.key,
                  value: selectedRoute.value,
                  isExpanded: true,
                  decoration: _sheetInputDecoration(
                    c,
                    l10n.homeConfigureHabitualRoute,
                  ),
                  dropdownColor: c.bgRaised,
                  style: TransitTypography.bodyPrimary(c.textHi),
                  hint: Text(
                    l10n.homeConfigureHabitualRoute,
                    style: TransitTypography.bodySecondary(c.textMid),
                  ),
                  items: routes.map((r) {
                    return DropdownMenuItem<RouteModel>(
                      value: r,
                      child: Text(
                        '${r.code} · ${r.name}',
                        style: TransitTypography.bodyPrimary(c.textHi),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (v) {
                    setSheetState(() {
                      selectedRoute.value = v;
                      selectedStop.value = null;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<StopModel>(
                  key: stopController.key,
                  value: selectedStop.value,
                  isExpanded: true,
                  decoration: _sheetInputDecoration(
                    c,
                    l10n.homeConfigureHabitualStop,
                  ),
                  dropdownColor: c.bgRaised,
                  style: TransitTypography.bodyPrimary(c.textHi),
                  hint: Text(
                    selectedRoute.value == null
                        ? l10n.homeConfigureHabitualSelectRouteFirst
                        : l10n.homeConfigureHabitualStop,
                    style: TransitTypography.bodySecondary(c.textMid),
                  ),
                  items: selectedRoute.value == null
                      ? null
                      : stopsForRoute.map((s) {
                          return DropdownMenuItem<StopModel>(
                            value: s,
                            child: Text(
                              s.name,
                              style: TransitTypography.bodyPrimary(c.textHi),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                  onChanged: (v) {
                    setSheetState(() {
                      selectedStop.value = v;
                    });
                  },
                ),
                const SizedBox(height: 24),
                TransitButton(
                  label: l10n.actionSave,
                  onPressed: canSave
                      ? () {
                          ref
                              .read(homeHabitualConfigProvider.notifier)
                              .save(selectedRoute.value!.id,
                                  selectedStop.value!.id);
                          Navigator.of(ctx).pop();
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

class _SheetDropdownController {
  final key = GlobalKey<FormFieldState<dynamic>>();
}
