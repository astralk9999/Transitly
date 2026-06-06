import 'package:flutter/material.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_spacing.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../core/utils/uuid.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../shared/widgets/transit_button.dart';
import '../../../shared/widgets/transit_checkbox.dart';
import '../../../shared/widgets/transit_input.dart';
import '../widgets/map_stop_picker_screen.dart';
import 'wizard_models.dart';

class StepStops extends StatefulWidget {
  const StepStops({
    super.key,
    required this.stops,
    required this.onChanged,
  });

  final List<WizardStop> stops;
  final VoidCallback onChanged;

  @override
  State<StepStops> createState() => _StepStopsState();
}

class _StepStopsState extends State<StepStops> {
  static const _stopTypeIcons = {
    'urban_custom': Icons.directions_bus,
    'hotel': Icons.hotel,
    'motel': Icons.bed,
    'gas_station': Icons.local_gas_station,
    'rest_area': Icons.local_cafe,
    'beach': Icons.beach_access,
    'airport': Icons.flight,
    'train_station': Icons.train,
    'ferry': Icons.directions_boat,
    'landmark': Icons.place,
    'custom': Icons.add_location,
  };

  void _addStop(WizardStop stop) {
    widget.stops.add(stop);
    widget.onChanged();
  }

  void _removeStop(int index) {
    widget.stops.removeAt(index);
    widget.onChanged();
  }

  void _reorder(int oldIndex, int newIndex) {
    final item = widget.stops.removeAt(oldIndex);
    widget.stops.insert(newIndex, item);
    widget.onChanged();
  }

  /// Abre la pantalla interactiva con mapa para añadir una parada:
  /// el usuario toca el mapa o busca un POI (Nominatim/OSM) en lugar
  /// de introducir coordenadas a mano.
  Future<void> _showAddStopModal() async {
    final result = await Navigator.of(context).push<WizardStop>(
      MaterialPageRoute(
        builder: (_) => const MapStopPickerScreen(),
        fullscreenDialog: true,
      ),
    );
    if (result != null) _addStop(result);
  }

  /// Variante legacy con formulario manual (lat/lng a mano) — mantenida
  /// como fallback por si el mapa no carga en el dispositivo (sin internet
  /// para tiles, etc.). Accesible desde el menú "Más opciones".
  void _showManualAddStopModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = TransitColorScheme.of(isDark);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _AddStopSheet(
        onStopCreated: (stop) {
          _addStop(stop);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = TransitColorScheme.of(isDark);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(TransitSpacing.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Paradas de la ruta',
                style: TransitTypography.heading(colors.textHi),
              ),
              const SizedBox(height: TransitSpacing.space4),
              Text(
                'Añade las paradas en el orden del recorrido. Mínimo 2: origen y destino.',
                style: TransitTypography.bodySecondary(colors.textMid),
              ),
              if (widget.stops.length == 1) ...[
                const SizedBox(height: TransitSpacing.space8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.stateDelay.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: colors.stateDelay.withValues(alpha: 0.3),
                        width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: colors.stateDelay),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Necesitas al menos otra parada para continuar.',
                          style: TransitTypography.bodySmall(colors.textMid),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: TransitSpacing.space16),
              TransitButton(
                label: 'Añadir parada',
                icon: Icons.add_location,
                isPrimary: false,
                onPressed: _showAddStopModal,
              ),
            ],
          ),
        ),
        if (widget.stops.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.directions_bus, size: 48, color: colors.textLo),
                  const SizedBox(height: TransitSpacing.space12),
                  Text(
                    'Sin paradas aún',
                    style: TransitTypography.bodyPrimary(colors.textLo),
                  ),
                  const SizedBox(height: TransitSpacing.space4),
                  Text(
                    'Añade al menos 2 paradas (origen y destino) para continuar',
                    style: TransitTypography.bodySmall(colors.textLo),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: TransitSpacing.space16,
              ),
              itemCount: widget.stops.length,
              onReorder: _reorder,
              buildDefaultDragHandles: false,
              proxyDecorator: (child, index, animation) {
                return AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    final scale = 1.0 + (animation.value * 0.02);
                    return Transform.scale(
                      scale: scale,
                      child: Material(
                        color: Colors.transparent,
                        elevation: 4,
                        child: child,
                      ),
                    );
                  },
                  child: child,
                );
              },
              itemBuilder: (context, index) {
                final stop = widget.stops[index];
                final iconData =
                    _stopTypeIcons[stop.stopType] ?? Icons.place;
                return _StopTile(
                  key: ValueKey(stop.stopId),
                  index: index,
                  name: stop.name,
                  stopType: stop.stopType,
                  lat: stop.lat,
                  lng: stop.lng,
                  suggestAsOfficial: stop.suggestAsOfficial,
                  iconData: iconData,
                  onDelete: () => _removeStop(index),
                  colors: colors,
                );
              },
            ),
          ),
      ],
    );
  }
}

class _StopTile extends StatelessWidget {
  const _StopTile({
    super.key,
    required this.index,
    required this.name,
    required this.stopType,
    required this.lat,
    required this.lng,
    required this.suggestAsOfficial,
    required this.iconData,
    required this.onDelete,
    required this.colors,
  });

  final int index;
  final String name;
  final String stopType;
  final double lat;
  final double lng;
  final bool suggestAsOfficial;
  final IconData iconData;
  final VoidCallback onDelete;
  final TransitColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TransitSpacing.space8),
      child: GlassCard(
        borderRadius: 8,
        padding: const EdgeInsets.symmetric(
          horizontal: TransitSpacing.space12,
          vertical: TransitSpacing.space8,
        ),
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: const EdgeInsets.only(right: TransitSpacing.space8),
                child: Icon(
                  Icons.drag_handle,
                  color: colors.textLo,
                  size: 20,
                ),
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Icon(iconData, size: 16, color: colors.accent),
            ),
            const SizedBox(width: TransitSpacing.space10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TransitTypography.bodyPrimary(colors.textHi),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
                    style: TransitTypography.bodySmall(colors.textLo),
                  ),
                ],
              ),
            ),
            if (suggestAsOfficial)
              Padding(
                padding: const EdgeInsets.only(right: TransitSpacing.space8),
                child: Icon(Icons.assistant, size: 16, color: colors.accent),
              ),
            Pressable(
              onTap: onDelete,
              child: Icon(Icons.close, size: 18, color: colors.stateCancelled),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddStopSheet extends StatefulWidget {
  const _AddStopSheet({required this.onStopCreated});

  final ValueChanged<WizardStop> onStopCreated;

  @override
  State<_AddStopSheet> createState() => _AddStopSheetState();
}

class _AddStopSheetState extends State<_AddStopSheet> {
  final _nameCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  String _stopType = 'custom';
  bool _suggestAsOfficial = false;
  bool _showCustomForm = false;

  static const _stopTypes = [
    'urban_custom',
    'hotel',
    'motel',
    'gas_station',
    'rest_area',
    'beach',
    'airport',
    'train_station',
    'ferry',
    'landmark',
    'custom',
  ];

  static const _stopTypeLabels = {
    'urban_custom': 'Parada urbana',
    'hotel': 'Hotel',
    'motel': 'Motel',
    'gas_station': 'Gasolinera',
    'rest_area': 'Área descanso',
    'beach': 'Playa',
    'airport': 'Aeropuerto',
    'train_station': 'Estación tren',
    'ferry': 'Ferry',
    'landmark': 'Punto de interés',
    'custom': 'Personalizada',
  };

  @override
  void dispose() {
    _nameCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  void _createStop() {
    final name = _nameCtrl.text.trim();
    final lat = double.tryParse(_latCtrl.text.trim());
    final lng = double.tryParse(_lngCtrl.text.trim());

    String? error;
    if (name.isEmpty) {
      error = 'El nombre es obligatorio';
    } else if (lat == null || lng == null) {
      error = 'Coordenadas inválidas';
    } else if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      error = 'Coordenadas fuera de rango';
    }

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    widget.onStopCreated(WizardStop(
      stopId: generateUuidV4(),
      name: name,
      lat: lat!,
      lng: lng!,
      stopType: _stopType,
      suggestAsOfficial: _suggestAsOfficial,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = TransitColorScheme.of(isDark);

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(TransitSpacing.space16),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: TransitSpacing.space16),
                Text(
                  'Añadir parada',
                  style: TransitTypography.heading(colors.textHi),
                ),
                const SizedBox(height: TransitSpacing.space20),

                Text(
                  'Buscar parada oficial',
                  style: TransitTypography.bodyPrimary(colors.textHi),
                ),
                const SizedBox(height: TransitSpacing.space8),
                const TransitInput(
                  hint: 'Nombre de la parada...',
                  maxLines: 1,
                ),
                const SizedBox(height: TransitSpacing.space16),

                Row(
                  children: [
                    Expanded(child: Divider(color: colors.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: TransitSpacing.space12),
                      child: Text(
                        'o crea una nueva',
                        style: TransitTypography.bodySmall(colors.textLo),
                      ),
                    ),
                    Expanded(child: Divider(color: colors.border)),
                  ],
                ),
                const SizedBox(height: TransitSpacing.space16),

                if (!_showCustomForm)
                  TransitButton(
                    label: 'Crear parada nueva',
                    icon: Icons.add_location,
                    isPrimary: false,
                    onPressed: () =>
                        setState(() => _showCustomForm = true),
                  ),

                if (_showCustomForm) ...[
                  TransitInput(
                    hint: 'Nombre de la parada',
                    controller: _nameCtrl,
                    maxLines: 1,
                  ),
                  const SizedBox(height: TransitSpacing.space12),
                  Row(
                    children: [
                      Expanded(
                        child: TransitInput(
                          hint: 'Latitud',
                          controller: _latCtrl,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: TransitSpacing.space8),
                      Expanded(
                        child: TransitInput(
                          hint: 'Longitud',
                          controller: _lngCtrl,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: TransitSpacing.space12),
                  GlassCard(
                    borderRadius: 6,
                    padding: const EdgeInsets.symmetric(
                      horizontal: TransitSpacing.space12,
                      vertical: TransitSpacing.space4,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _stopType,
                        isExpanded: true,
                        dropdownColor: colors.bgRaised,
                        style: TransitTypography.bodyPrimary(colors.textHi),
                        items: _stopTypes.map((t) {
                          return DropdownMenuItem(
                            value: t,
                            child: Text(
                              _stopTypeLabels[t] ?? t,
                              style:
                                  TransitTypography.bodyPrimary(colors.textHi),
                            ),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _stopType = v);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: TransitSpacing.space12),
                  TransitCheckbox(
                    _suggestAsOfficial,
                    (v) => setState(() => _suggestAsOfficial = v),
                    'Sugerir como parada oficial',
                  ),
                  const SizedBox(height: TransitSpacing.space16),
                  TransitButton(
                    label: 'Añadir parada',
                    onPressed: _createStop,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
