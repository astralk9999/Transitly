import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../shared/widgets/smoke_background.dart';
import '../../../shared/widgets/transit_button.dart';
import '../../../shared/widgets/transit_input.dart';
import '../../map/map_config.dart';

class ManualRouteEditor extends StatefulWidget {
  const ManualRouteEditor({super.key});

  @override
  State<ManualRouteEditor> createState() => _ManualRouteEditorState();
}

class _ManualRouteEditorState extends State<ManualRouteEditor> {
  int _step = 0;
  final _pageController = PageController();

  // Step 1: Info
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  String _serviceType = 'urban';

  // Step 2: Trace
  final List<LatLng> _tracePoints = [];

  // Step 3: Stops
  final List<_EditorStop> _stops = [];

  // Step 4: Return
  String _returnChoice = ''; // 'invert', 'new', 'oneway'

  // Step 5: Schedules
  final Map<String, List<String>> _schedules = {
    'weekday': [],
    'saturday': [],
    'sunday': [],
  };
  final _totalTimeCtrl = TextEditingController(text: '45');

  // Map controllers
  final _traceMapCtrl = MapController();
  final _stopsMapCtrl = MapController();

  @override
  void dispose() {
    _pageController.dispose();
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _totalTimeCtrl.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    setState(() => _step = step);
    _pageController.animateToPage(step,
        duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    return Scaffold(
      backgroundColor: c.bgRoot,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.textMid),
          onPressed: () {
            if (_step > 0) {
              _goToStep(_step - 1);
            } else {
              context.pop();
            }
          },
        ),
        title: Text(_stepTitle(_step),
            style: TransitTypography.sectionTitle(c.textHi)),
        centerTitle: false,
      ),
      body: Stack(
        children: [
          Positioned.fill(child: SmokeBackground(color: c.accent, isDark: isDark)),
          Column(
        children: [
          // Step indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (i) {
                final isCompleted = i < _step;
                final isCurrent = i == _step;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCurrent
                          ? c.accent
                          : isCompleted
                              ? Colors.transparent
                              : Colors.transparent,
                      border: Border.all(
                        color: isCurrent || isCompleted ? c.accent : c.textLo,
                        width: 1.5,
                      ),
                    ),
                    child: isCompleted
                        ? Icon(Icons.check, size: 12, color: c.accent)
                        : isCurrent
                            ? Center(
                                child: Text(
                                  '${i + 1}',
                                  style: GoogleFonts.ibmPlexMono(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: c.bgRoot,
                                  ),
                                ),
                              )
                            : Center(
                                child: Text(
                                  '${i + 1}',
                                  style: GoogleFonts.ibmPlexMono(
                                    fontSize: 10,
                                    color: c.textLo,
                                  ),
                                ),
                              ),
                  ),
                );
              }),
            ),
          ),

          // Pages
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1Info(c),
                _buildStep2Trace(c, isDark),
                _buildStep3Stops(c, isDark),
                _buildStep4Return(c),
                _buildStep5Schedules(c),
                _buildStep6Review(c, isDark),
              ],
            ),
          ),
        ],
      ),
        ],
      ),
    );
  }

  String _stepTitle(int step) {
    const titles = [
      'INFORMACIÓN',
      'TRAZADO',
      'PARADAS',
      'VUELTA',
      'HORARIOS',
      'REVISIÓN',
    ];
    return titles[step];
  }

  // ── STEP 1: INFO ──

  Widget _buildStep1Info(TransitColorScheme c) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Código de línea',
              style: TransitTypography.bodySecondary(c.textMid)),
          const SizedBox(height: 6),
          TransitInput(
            hint: 'Ej: L12',
            controller: _codeCtrl,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          Text('Nombre de la ruta',
              style: TransitTypography.bodySecondary(c.textMid)),
          const SizedBox(height: 6),
          TransitInput(
            hint: 'Ej: Esteve - San Telmo',
            controller: _nameCtrl,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          Text('Tipo de servicio',
              style: TransitTypography.bodySecondary(c.textMid)),
          const SizedBox(height: 6),
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: c.bgInput,
              border: Border.all(color: c.border, width: 0.5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _serviceType,
                isExpanded: true,
                dropdownColor: c.bgSurface,
                style: TransitTypography.bodyPrimary(c.textHi),
                items: const [
                  DropdownMenuItem(value: 'urban', child: Text('Urbano')),
                  DropdownMenuItem(
                      value: 'metropolitan', child: Text('Metropolitano')),
                  DropdownMenuItem(
                      value: 'interurban', child: Text('Interurbano')),
                  DropdownMenuItem(value: 'special', child: Text('Especial')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _serviceType = v);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Operador',
              style: TransitTypography.bodySecondary(c.textMid)),
          const SizedBox(height: 6),
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: c.bgInput,
              border: Border.all(color: c.border, width: 0.5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('COMUJESA',
                style: TransitTypography.bodyPrimary(c.textMid)),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: TransitButton(
              label: 'SIGUIENTE',
              onPressed: _codeCtrl.text.isNotEmpty && _nameCtrl.text.isNotEmpty
                  ? () => _goToStep(1)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  // ── STEP 2: TRACE ──

  Widget _buildStep2Trace(TransitColorScheme c, bool isDark) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _traceMapCtrl,
          options: MapOptions(
            initialCenter: MapConfig.defaultCenter,
            initialZoom: MapConfig.defaultZoom,
            onTap: (_, point) {
              setState(() => _tracePoints.add(point));
            },
          ),
          children: [
            TileLayer(
              urlTemplate: MapConfig.tileUrl(isDark),
              subdomains: MapConfig.subdomains,
              retinaMode: true,
            ),
            if (_tracePoints.length >= 2)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _tracePoints,
                    color: c.accent,
                    strokeWidth: 3,
                  ),
                ],
              ),
            MarkerLayer(
              markers: _tracePoints.asMap().entries.map((e) {
                return Marker(
                  point: e.value,
                  width: 24,
                  height: 24,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: c.stateOnRoute,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${e.key + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        // Floating buttons
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Row(
            children: [
              if (_tracePoints.isNotEmpty)
                Expanded(
                  child: TransitButton(
                    label: 'DESHACER',
                    isPrimary: false,
                    icon: Icons.undo,
                    onPressed: () {
                      setState(() => _tracePoints.removeLast());
                    },
                  ),
                ),
              if (_tracePoints.isNotEmpty) const SizedBox(width: 8),
              Expanded(
                child: TransitButton(
                  label: 'SIGUIENTE',
                  onPressed:
                      _tracePoints.length >= 2 ? () => _goToStep(2) : null,
                ),
              ),
            ],
          ),
        ),
        // Point count
        Positioned(
          top: 8,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: c.bgSurface,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: c.border, width: 0.5),
            ),
            child: Text(
              '${_tracePoints.length} puntos',
              style: GoogleFonts.ibmPlexMono(fontSize: 12, color: c.textMid),
            ),
          ),
        ),
      ],
    );
  }

  // ── STEP 3: STOPS ──

  Widget _buildStep3Stops(TransitColorScheme c, bool isDark) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              FlutterMap(
                mapController: _stopsMapCtrl,
                options: MapOptions(
                  initialCenter: MapConfig.defaultCenter,
                  initialZoom: MapConfig.defaultZoom,
                  onTap: (_, point) => _addStopDialog(c, point),
                ),
                children: [
                  TileLayer(
                    urlTemplate: MapConfig.tileUrl(isDark),
                    subdomains: MapConfig.subdomains,
                    retinaMode: true,
                  ),
                  if (_tracePoints.length >= 2)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _tracePoints,
                          color: c.accent.withAlpha(128),
                          strokeWidth: 3,
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: _stops.asMap().entries.map((e) {
                      return Marker(
                        point: e.value.position,
                        width: 28,
                        height: 28,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: c.accent,
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: Colors.white, width: 1.5),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${e.key + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              // Stop count + next button
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: c.bgSurface,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: c.border, width: 0.5),
                      ),
                      child: Text(
                        '${_stops.length} paradas',
                        style: GoogleFonts.ibmPlexMono(
                            fontSize: 12, color: c.textMid),
                      ),
                    ),
                    const Spacer(),
                    TransitButton(
                      label: 'SIGUIENTE',
                      onPressed:
                          _stops.length >= 2 ? () => _goToStep(3) : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Stop list
        if (_stops.isNotEmpty)
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: c.bgSurface,
              border: Border(top: BorderSide(color: c.border, width: 0.5)),
            ),
            child: ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              itemCount: _stops.length,
              onReorder: (oldIdx, newIdx) {
                setState(() {
                  if (newIdx > oldIdx) newIdx--;
                  final item = _stops.removeAt(oldIdx);
                  _stops.insert(newIdx, item);
                });
              },
              itemBuilder: (context, index) {
                final stop = _stops[index];
                return ListTile(
                  key: ValueKey(stop.name + index.toString()),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Text(
                    '${index + 1}',
                    style: GoogleFonts.ibmPlexMono(
                        fontSize: 14, color: c.accent),
                  ),
                  title: Text(stop.name,
                      style: TransitTypography.bodySecondary(c.textHi)),
                  trailing: IconButton(
                    icon: Icon(Icons.close, size: 16, color: c.textLo),
                    onPressed: () => setState(() => _stops.removeAt(index)),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  void _addStopDialog(TransitColorScheme c, LatLng point) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.bgSurface,
        title: Text('Nueva parada',
            style: TransitTypography.heading(c.textHi)),
        content: TransitInput(
          hint: 'Nombre de la parada',
          controller: ctrl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('CANCELAR',
                style: TransitTypography.bodySecondary(c.textMid)),
          ),
          TextButton(
            onPressed: () {
              if (ctrl.text.isNotEmpty) {
                setState(
                    () => _stops.add(_EditorStop(ctrl.text, point)));
              }
              Navigator.of(ctx).pop();
            },
            child: Text('CONFIRMAR',
                style: TransitTypography.bodySecondary(c.accent)),
          ),
        ],
      ),
    );
  }

  // ── STEP 4: RETURN ──

  Widget _buildStep4Return(TransitColorScheme c) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('¿Cómo es la vuelta?',
              style: TransitTypography.heading(c.textHi)),
          const SizedBox(height: 16),
          _returnOption(c, 'invert', Icons.swap_horiz, 'Invertir recorrido',
              'Genera automáticamente la vuelta invirtiendo las paradas'),
          const SizedBox(height: 8),
          _returnOption(c, 'new', Icons.edit, 'Trazar nueva vuelta',
              'Dibujar un recorrido diferente para la vuelta'),
          const SizedBox(height: 8),
          _returnOption(c, 'oneway', Icons.arrow_forward, 'Solo ida',
              'Esta línea no tiene recorrido de vuelta'),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: TransitButton(
              label: 'SIGUIENTE',
              onPressed:
                  _returnChoice.isNotEmpty ? () => _goToStep(4) : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _returnOption(TransitColorScheme c, String value, IconData icon,
      String title, String subtitle) {
    final isSelected = _returnChoice == value;
    return GestureDetector(
      onTap: () => setState(() => _returnChoice = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.bgSurface,
          border: Border.all(
            color: isSelected ? c.accent : c.border,
            width: isSelected ? 1 : 0.5,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: isSelected ? c.accent : c.textMid),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TransitTypography.bodyPrimary(c.textHi)),
                  Text(subtitle,
                      style: TransitTypography.bodySmall(c.textMid)),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, size: 20, color: c.accent),
          ],
        ),
      ),
    );
  }

  // ── STEP 5: SCHEDULES ──

  Widget _buildStep5Schedules(TransitColorScheme c) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            indicatorColor: c.accent,
            labelColor: c.accent,
            unselectedLabelColor: c.textMid,
            labelStyle: GoogleFonts.ibmPlexMono(
                fontSize: 11, fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'LABORABLE'),
              Tab(text: 'SÁBADO'),
              Tab(text: 'FESTIVO'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _scheduleTab(c, 'weekday'),
                _scheduleTab(c, 'saturday'),
                _scheduleTab(c, 'sunday'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tiempo total (min)',
                    style: TransitTypography.bodySecondary(c.textMid)),
                const SizedBox(height: 6),
                SizedBox(
                  width: 120,
                  child: TransitInput(
                    hint: '45',
                    controller: _totalTimeCtrl,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TransitButton(
                    label: 'SIGUIENTE',
                    onPressed: () => _goToStep(5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _scheduleTab(TransitColorScheme c, String key) {
    final times = _schedules[key]!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...times.map((t) => Container(
                    width: 60,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.bgSurface,
                      border: Border.all(color: c.border, width: 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(t,
                        style: GoogleFonts.ibmPlexMono(
                            fontSize: 14, color: c.textHi)),
                  )),
              GestureDetector(
                onTap: () => _addTimeDialog(c, key),
                child: Container(
                  width: 60,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.bgSurface,
                    border: Border.all(color: c.accent, width: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(Icons.add, size: 18, color: c.accent),
                ),
              ),
            ],
          ),
          if (times.isNotEmpty && _stops.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Preview',
                style: TransitTypography.sectionTitle(c.textMid)),
            const SizedBox(height: 8),
            ...List.generate(_stops.length, (i) {
              final totalMin = int.tryParse(_totalTimeCtrl.text) ?? 45;
              final interval =
                  _stops.length > 1 ? totalMin / (_stops.length - 1) : 0;
              final offsetMin = (interval * i).round();
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '${_stops[i].name}  +${offsetMin}m',
                  style: TransitTypography.bodySecondary(c.textHi),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  void _addTimeDialog(TransitColorScheme c, String key) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.bgSurface,
        title: Text('Añadir hora',
            style: TransitTypography.heading(c.textHi)),
        content: TransitInput(hint: 'HH:MM', controller: ctrl),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('CANCELAR',
                style: TransitTypography.bodySecondary(c.textMid)),
          ),
          TextButton(
            onPressed: () {
              if (ctrl.text.isNotEmpty) {
                setState(() {
                  _schedules[key]!.add(ctrl.text);
                  _schedules[key]!.sort();
                });
              }
              Navigator.of(ctx).pop();
            },
            child: Text('AÑADIR',
                style: TransitTypography.bodySecondary(c.accent)),
          ),
        ],
      ),
    );
  }

  // ── STEP 6: REVIEW ──

  Widget _buildStep6Review(TransitColorScheme c, bool isDark) {
    final totalSchedules = _schedules.values
        .fold<int>(0, (sum, list) => sum + list.length);

    return Column(
      children: [
        // Map preview
        Expanded(
          child: FlutterMap(
            options: MapOptions(
              initialCenter: _tracePoints.isNotEmpty
                  ? _tracePoints[_tracePoints.length ~/ 2]
                  : MapConfig.defaultCenter,
              initialZoom: 14,
            ),
            children: [
              TileLayer(
                urlTemplate: MapConfig.tileUrl(isDark),
                subdomains: MapConfig.subdomains,
                retinaMode: true,
              ),
              if (_tracePoints.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _tracePoints,
                      color: c.accent,
                      strokeWidth: 3,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: _stops.asMap().entries.map((e) {
                  return Marker(
                    point: e.value.position,
                    width: 24,
                    height: 24,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: c.accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${e.key + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        // Summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: c.bgSurface,
            border: Border(top: BorderSide(color: c.border, width: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_codeCtrl.text} · ${_nameCtrl.text}',
                style: TransitTypography.heading(c.textHi),
              ),
              const SizedBox(height: 4),
              Text(
                'Tipo: $_serviceType · ${_stops.length} paradas · $totalSchedules horarios',
                style: TransitTypography.bodySecondary(c.textMid),
              ),
              const SizedBox(height: 4),
              Text(
                'Vuelta: ${_returnChoice == 'invert' ? 'Invertida' : _returnChoice == 'new' ? 'Nueva' : 'Solo ida'}',
                style: TransitTypography.bodySecondary(c.textMid),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TransitButton(
                      label: 'GUARDAR BORRADOR',
                      isPrimary: false,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Borrador guardado')),
                        );
                        context.pop();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TransitButton(
                      label: 'PUBLICAR',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ruta publicada')),
                        );
                        context.go('/home/mapa');
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EditorStop {
  final String name;
  final LatLng position;
  const _EditorStop(this.name, this.position);
}
