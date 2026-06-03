import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../core/utils/uuid.dart';
import '../../../shared/providers/map_search_provider.dart';
import '../../../shared/providers/user_location_provider.dart';
import '../../../shared/widgets/transit_button.dart';
import '../steps/wizard_models.dart';

/// Pantalla interactiva para añadir una parada tocando el mapa.
///
/// El usuario puede:
/// - Tocar cualquier punto del mapa → coloca un pin.
/// - Buscar un lugar real (Nominatim/OSM) → centra el mapa y coloca pin.
/// - Confirmar el nombre + tipo y devolver un `WizardStop` al wizard.
///
/// Devuelve el `WizardStop` con `Navigator.pop(stop)` o `null` si se cancela.
class MapStopPickerScreen extends ConsumerStatefulWidget {
  const MapStopPickerScreen({super.key, this.initialCenter});

  /// Centro opcional del mapa. Si es null, intenta GPS, si no, Jerez.
  final LatLng? initialCenter;

  @override
  ConsumerState<MapStopPickerScreen> createState() =>
      _MapStopPickerScreenState();
}

class _MapStopPickerScreenState extends ConsumerState<MapStopPickerScreen> {
  static const _jerezCenter = LatLng(36.6850, -6.1261);

  final _mapController = MapController();
  final _searchCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _searchFocus = FocusNode();

  LatLng? _pinPosition;
  String _stopType = 'custom';
  bool _showSearchResults = false;

  static const _stopTypes = {
    'urban_custom': ('Parada urbana', Icons.directions_bus),
    'hotel': ('Hotel', Icons.hotel),
    'motel': ('Motel', Icons.bed),
    'gas_station': ('Gasolinera', Icons.local_gas_station),
    'rest_area': ('Área descanso', Icons.local_cafe),
    'beach': ('Playa', Icons.beach_access),
    'airport': ('Aeropuerto', Icons.flight),
    'train_station': ('Estación tren', Icons.train),
    'ferry': ('Ferry', Icons.directions_boat),
    'landmark': ('Punto interés', Icons.place),
    'custom': ('Personalizada', Icons.add_location),
  };

  @override
  void dispose() {
    _searchCtrl.dispose();
    _nameCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onMapTap(TapPosition tapPos, LatLng latlng) {
    setState(() {
      _pinPosition = latlng;
      _showSearchResults = false;
    });
    _searchFocus.unfocus();
  }

  void _selectSearchResult(MapSearchResult r) {
    if (r.lat == null || r.lng == null) return;
    final pos = LatLng(r.lat!, r.lng!);
    setState(() {
      _pinPosition = pos;
      _showSearchResults = false;
      if (_nameCtrl.text.trim().isEmpty) _nameCtrl.text = r.title;
    });
    _mapController.move(pos, 16);
    _searchFocus.unfocus();
  }

  void _confirm() {
    final name = _nameCtrl.text.trim();
    if (_pinPosition == null) {
      _toast('Toca el mapa para elegir la ubicación');
      return;
    }
    if (name.isEmpty) {
      _toast('El nombre es obligatorio');
      return;
    }
    final stop = WizardStop(
      stopId: generateUuidV4(),
      name: name,
      lat: _pinPosition!.latitude,
      lng: _pinPosition!.longitude,
      stopType: _stopType,
    );
    Navigator.of(context).pop(stop);
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final userLoc = ref.watch(userLocationLatLngProvider);
    final initial = widget.initialCenter ?? userLoc ?? _jerezCenter;
    final searchResults = ref.watch(mapSearchResultsProvider);

    return Scaffold(
      backgroundColor: c.bgRoot,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header con búsqueda ──
            _SearchHeader(
              c: c,
              controller: _searchCtrl,
              focusNode: _searchFocus,
              onChanged: (q) {
                ref.read(mapSearchQueryProvider.notifier).state = q;
                setState(() => _showSearchResults = q.trim().isNotEmpty);
              },
              onClose: () => Navigator.of(context).pop(),
            ),

            // ── Resultados de búsqueda (overlay sobre mapa) ──
            if (_showSearchResults)
              Expanded(
                child: searchResults.when(
                  data: (results) {
                    if (results.isEmpty) {
                      return Center(
                        child: Text(
                          'Sin resultados',
                          style: TransitTypography.bodySecondary(c.textMid),
                        ),
                      );
                    }
                    return ListView.separated(
                      itemCount: results.length,
                      separatorBuilder: (_, __) =>
                          Divider(color: c.border, height: 1),
                      itemBuilder: (_, i) {
                        final r = results[i];
                        return ListTile(
                          leading: Icon(
                            r.type == MapSearchResultType.place
                                ? Icons.place
                                : r.type == MapSearchResultType.stop
                                    ? Icons.directions_bus
                                    : Icons.route,
                            color: c.accent,
                          ),
                          title: Text(r.title,
                              style: TransitTypography.bodyPrimary(c.textHi)),
                          subtitle: r.subtitle.isEmpty
                              ? null
                              : Text(r.subtitle,
                                  style: TransitTypography.bodySecondary(
                                      c.textMid)),
                          onTap: () => _selectSearchResult(r),
                        );
                      },
                    );
                  },
                  loading: () => Center(
                    child: CircularProgressIndicator(color: c.accent),
                  ),
                  error: (_, __) => Center(
                    child: Text(
                      'Error al buscar',
                      style: TransitTypography.bodySecondary(c.textMid),
                    ),
                  ),
                ),
              )
            else
              // ── Mapa principal ──
              Expanded(
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: initial,
                        initialZoom: 14,
                        onTap: _onMapTap,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.transitly.transitly',
                        ),
                        if (_pinPosition != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _pinPosition!,
                                width: 40,
                                height: 40,
                                child: Icon(
                                  Icons.location_on,
                                  size: 40,
                                  color: c.accent,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    // Hint flotante
                    if (_pinPosition == null)
                      Positioned(
                        top: 12,
                        left: 16,
                        right: 16,
                        child: Material(
                          color: c.bgSurface,
                          borderRadius: BorderRadius.circular(8),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Icon(Icons.touch_app, color: c.accent),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Toca el mapa para elegir la ubicación de la parada',
                                    style: TransitTypography.bodySecondary(
                                        c.textHi),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            // ── Form inferior (nombre + tipo + confirmar) ──
            if (!_showSearchResults)
              _BottomForm(
                c: c,
                nameCtrl: _nameCtrl,
                stopType: _stopType,
                pinSelected: _pinPosition != null,
                stopTypes: _stopTypes,
                onTypeChanged: (v) => setState(() => _stopType = v),
                onConfirm: _confirm,
              ),
          ],
        ),
      ),
    );
  }
}

class _SearchHeader extends StatelessWidget {
  const _SearchHeader({
    required this.c,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClose,
  });

  final TransitColorScheme c;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      color: c.bgSurface,
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: c.textHi),
            onPressed: onClose,
          ),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              style: TransitTypography.bodyPrimary(c.textHi),
              decoration: InputDecoration(
                hintText: 'Buscar lugar (hotel, gasolinera...)',
                hintStyle: TransitTypography.bodySecondary(c.textMid),
                prefixIcon: Icon(Icons.search, color: c.textMid),
                border: InputBorder.none,
              ),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomForm extends StatelessWidget {
  const _BottomForm({
    required this.c,
    required this.nameCtrl,
    required this.stopType,
    required this.pinSelected,
    required this.stopTypes,
    required this.onTypeChanged,
    required this.onConfirm,
  });

  final TransitColorScheme c;
  final TextEditingController nameCtrl;
  final String stopType;
  final bool pinSelected;
  final Map<String, (String, IconData)> stopTypes;
  final ValueChanged<String> onTypeChanged;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + mq.padding.bottom),
      decoration: BoxDecoration(
        color: c.bgSurface,
        border: Border(top: BorderSide(color: c.border, width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: nameCtrl,
            style: TransitTypography.bodyPrimary(c.textHi),
            decoration: InputDecoration(
              labelText: 'Nombre de la parada',
              labelStyle: TransitTypography.bodySecondary(c.textMid),
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
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: stopTypes.entries.map((e) {
                final selected = e.key == stopType;
                final (label, icon) = e.value;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => onTypeChanged(e.key),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? c.accent.withValues(alpha: 0.15)
                            : c.bgRaised,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? c.accent : c.border,
                          width: selected ? 1.5 : 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(icon,
                              size: 18,
                              color: selected ? c.accent : c.textMid),
                          const SizedBox(width: 6),
                          Text(label,
                              style: TransitTypography.bodySmall(
                                  selected ? c.accent : c.textMid)),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          TransitButton(
            label: pinSelected
                ? 'Confirmar parada'
                : 'Toca el mapa primero',
            onPressed: pinSelected ? onConfirm : null,
          ),
        ],
      ),
    );
  }
}
