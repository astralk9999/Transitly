import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/transit_colors.dart';
import '../../../../core/theme/transit_typography.dart';
import '../../../../data/mock/mock_data_service.dart';
import '../editor_controller.dart';

/// Sub P2-04: bottom sheet con buscador sobre el catálogo de paradas mock,
/// con selección múltiple y botón "Añadir N paradas" al final.
class StopPickerSheet extends ConsumerStatefulWidget {
  const StopPickerSheet({super.key, required this.onPicked});

  final void Function(List<EditorStop> picked) onPicked;

  @override
  ConsumerState<StopPickerSheet> createState() => _StopPickerSheetState();
}

class _StopPickerSheetState extends ConsumerState<StopPickerSheet> {
  String _filter = '';
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    final mockData = ref.read(mockDataServiceProvider);
    final all = mockData.stops;
    final filtered = _filter.isEmpty
        ? all
        : all.where((s) {
            final q = _filter.toLowerCase();
            return s.name.toLowerCase().contains(q) ||
                s.officialCode.toLowerCase().contains(q);
          }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: c.bgSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: c.textLo.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Añadir paradas existentes',
                        style: TransitTypography.heading(c.textHi)),
                    const SizedBox(height: 12),
                    TextField(
                      onChanged: (v) => setState(() => _filter = v),
                      style: TransitTypography.bodyPrimary(c.textHi),
                      decoration: InputDecoration(
                        hintText: 'Buscar por nombre o código',
                        hintStyle:
                            TransitTypography.bodySecondary(c.textLo),
                        prefixIcon:
                            Icon(Icons.search, color: c.textLo, size: 20),
                        filled: true,
                        fillColor: c.bgRaised,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: c.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: c.border),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'Sin resultados',
                          style: TransitTypography.bodyPrimary(c.textMid),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final stop = filtered[i];
                          final selected = _selected.contains(stop.id);
                          return CheckboxListTile(
                            value: selected,
                            onChanged: (v) {
                              setState(() {
                                if (v == true) {
                                  _selected.add(stop.id);
                                } else {
                                  _selected.remove(stop.id);
                                }
                              });
                            },
                            title: Text(stop.name,
                                style:
                                    TransitTypography.bodyPrimary(c.textHi)),
                            subtitle: Text(stop.officialCode,
                                style:
                                    TransitTypography.bodySecondary(c.textMid)),
                            activeColor: c.accent,
                          );
                        },
                      ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: _selected.isEmpty
                          ? null
                          : () {
                              final picked = all
                                  .where((s) => _selected.contains(s.id))
                                  .map((s) => EditorStop(
                                        s.name,
                                        LatLng(s.lat, s.lng),
                                      ))
                                  .toList();
                              widget.onPicked(picked);
                              Navigator.of(context).pop();
                            },
                      icon: const Icon(Icons.add_location_alt_outlined),
                      label: Text(_selected.isEmpty
                          ? 'Selecciona al menos una'
                          : 'Añadir ${_selected.length} paradas'),
                      style: FilledButton.styleFrom(
                        backgroundColor: c.accent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

