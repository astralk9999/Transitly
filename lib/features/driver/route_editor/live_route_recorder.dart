import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../shared/widgets/transit_input.dart';
import '../../map/map_config.dart';

// Predefined GPS path based on L1 stops with intermediates
const _gpsPath = [
  LatLng(36.6819, -6.1365), // Plaza Esteve
  LatLng(36.6826, -6.1357),
  LatLng(36.6834, -6.1349), // Villamarta
  LatLng(36.6831, -6.1352),
  LatLng(36.6828, -6.1355), // Arcos
  LatLng(36.6821, -6.1347),
  LatLng(36.6815, -6.1340), // Pío XII
  LatLng(36.6807, -6.1330),
  LatLng(36.6800, -6.1320), // Descalzos
  LatLng(36.6793, -6.1303),
  LatLng(36.6786, -6.1287), // Pz. Madre de Dios
  LatLng(36.6773, -6.1313),
  LatLng(36.6760, -6.1340), // C/ Manuel Moneo
  LatLng(36.6740, -6.1350),
  LatLng(36.6720, -6.1360), // Bajada San Telmo
  LatLng(36.6710, -6.1365),
  LatLng(36.6700, -6.1370), // Cerrofruto
  LatLng(36.6690, -6.1360),
  LatLng(36.6680, -6.1350), // Constitución
  LatLng(36.6685, -6.1340),
  LatLng(36.6690, -6.1330), // Nueva Cartuja
  LatLng(36.6695, -6.1320),
  LatLng(36.6700, -6.1310), // Solidaridad
];

class LiveRouteRecorder extends StatefulWidget {
  const LiveRouteRecorder({super.key});

  @override
  State<LiveRouteRecorder> createState() => _LiveRouteRecorderState();
}

class _LiveRouteRecorderState extends State<LiveRouteRecorder> {
  bool _isRecording = false;

  // Pre-recording
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  String _serviceType = 'urban';

  // Recording state
  final List<LatLng> _trace = [];
  final List<_MarkedStop> _markedStops = [];
  int _gpsIndex = 0;
  int _elapsedSeconds = 0;
  double _totalDistanceKm = 0;
  bool _flashVisible = false;

  Timer? _gpsTimer;
  Timer? _clockTimer;
  Timer? _blinkTimer;
  bool _blinkOn = true;

  final _mapController = MapController();

  @override
  void dispose() {
    _gpsTimer?.cancel();
    _clockTimer?.cancel();
    _blinkTimer?.cancel();
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _startRecording() {
    setState(() => _isRecording = true);

    // GPS simulation every 2s
    _gpsTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_gpsIndex < _gpsPath.length) {
        final point = _gpsPath[_gpsIndex];
        setState(() {
          if (_trace.isNotEmpty) {
            _totalDistanceKm += _distKm(_trace.last, point);
          }
          _trace.add(point);
          _gpsIndex++;
        });
        _mapController.move(point, 15);
      }
    });

    // Clock every second
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsedSeconds++);
    });

    // Blink indicator
    _blinkTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      setState(() => _blinkOn = !_blinkOn);
    });
  }

  void _markStop() {
    if (_trace.isEmpty) return;
    HapticFeedback.heavyImpact();

    final pos = _trace.last;
    final n = _markedStops.length + 1;
    final distFromLast = _markedStops.isNotEmpty
        ? _distKm(_markedStops.last.position, pos)
        : _totalDistanceKm;

    setState(() {
      _markedStops.add(_MarkedStop(
        number: n,
        position: pos,
        distanceKm: distFromLast,
      ));
      _flashVisible = true;
    });

    // Flash effect
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _flashVisible = false);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'PARADA #$n MARCADA · ${distFromLast.toStringAsFixed(2)} km',
          style: GoogleFonts.ibmPlexMono(color: const Color(0xFF00C896)),
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _stopRecording(TransitColorScheme c) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.bgSurface,
        title: Text('¿Detener grabación?',
            style: TransitTypography.heading(c.textHi)),
        content: Text(
          '${_markedStops.length} paradas marcadas · ${_totalDistanceKm.toStringAsFixed(1)} km',
          style: TransitTypography.bodySecondary(c.textMid),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('CONTINUAR',
                style: TransitTypography.bodySecondary(c.textMid)),
          ),
          TextButton(
            onPressed: () {
              _gpsTimer?.cancel();
              _clockTimer?.cancel();
              _blinkTimer?.cancel();
              Navigator.of(ctx).pop();
              context.push('/driver/editor/post');
            },
            child: Text('DETENER',
                style: TransitTypography.bodySecondary(c.stateCancelled)),
          ),
        ],
      ),
    );
  }

  double _distKm(LatLng a, LatLng b) {
    const r = 6371.0;
    final dLat = (b.latitude - a.latitude) * 3.14159 / 180;
    final dLng = (b.longitude - a.longitude) * 3.14159 / 180;
    final lat1 = a.latitude * 3.14159 / 180;
    final lat2 = b.latitude * 3.14159 / 180;
    final h = _sin2(dLat / 2) +
        _cos(lat1) * _cos(lat2) * _sin2(dLng / 2);
    return 2 * r * _asin(_sqrtD(h));
  }

  // Inline math to avoid dart:math import conflicts
  static double _sin2(double x) {
    final s = _sinD(x);
    return s * s;
  }

  static double _sinD(double x) {
    // Taylor approximation good enough for small angles
    return x - (x * x * x) / 6 + (x * x * x * x * x) / 120;
  }

  static double _cos(double x) => _sinD(x + 1.5707963);

  static double _asin(double x) {
    return x + (x * x * x) / 6 + (3 * x * x * x * x * x) / 40;
  }

  static double _sqrtD(double x) {
    if (x <= 0) return 0;
    double g = x;
    for (int i = 0; i < 10; i++) {
      g = (g + x / g) / 2;
    }
    return g;
  }

  String _formatTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    if (!_isRecording) return _buildPreRecording(c);
    return _buildRecording(c, isDark);
  }

  // ── PRE-RECORDING ──

  Widget _buildPreRecording(TransitColorScheme c) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.textMid),
          onPressed: () => context.pop(),
        ),
        title: Text('GRABAR RUTA',
            style: TransitTypography.sectionTitle(c.textHi)),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Código',
                style: TransitTypography.bodySecondary(c.textMid)),
            const SizedBox(height: 6),
            TransitInput(hint: 'Ej: L12', controller: _codeCtrl),
            const SizedBox(height: 16),
            Text('Nombre',
                style: TransitTypography.bodySecondary(c.textMid)),
            const SizedBox(height: 6),
            TransitInput(
                hint: 'Ej: Esteve - San Telmo', controller: _nameCtrl),
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
                        value: 'metropolitan',
                        child: Text('Metropolitano')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _serviceType = v);
                  },
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 100,
              child: GestureDetector(
                onTap: _startRecording,
                child: Container(
                  color: c.accent,
                  alignment: Alignment.center,
                  child: Text(
                    '● EMPEZAR A GRABAR',
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: c.bgRoot,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── RECORDING ──

  Widget _buildRecording(TransitColorScheme c, bool isDark) {
    final speed =
        _elapsedSeconds > 0 ? (_totalDistanceKm / _elapsedSeconds * 3600) : 0;
    final lastStopDist = _markedStops.isNotEmpty && _trace.isNotEmpty
        ? _distKm(_markedStops.last.position, _trace.last)
        : 0.0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top),

              // ── a) HEADER ──
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: c.bgSurface,
                child: Row(
                  children: [
                    AnimatedOpacity(
                      opacity: _blinkOn ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF3B3B),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'GRABANDO RUTA',
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.0,
                        color: c.stateCancelled,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatTime(_elapsedSeconds),
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: c.textHi,
                      ),
                    ),
                  ],
                ),
              ),

              // ── b) MINI-MAPA ──
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.35,
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _gpsPath.first,
                    initialZoom: 15,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: MapConfig.tileUrl(isDark),
                      subdomains: MapConfig.subdomains,
                      retinaMode: true,
                    ),
                    if (_trace.length >= 2)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _trace,
                            color: c.accent,
                            strokeWidth: 3,
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        // Marked stops
                        ..._markedStops.map((s) => Marker(
                              point: s.position,
                              width: 24,
                              height: 24,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: c.accent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 1.5),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${s.number}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            )),
                        // Current position
                        if (_trace.isNotEmpty)
                          Marker(
                            point: _trace.last,
                            width: 16,
                            height: 16,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: c.stateOnRoute,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── c) DATOS ──
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Última parada: #${_markedStops.length} (hace ${lastStopDist.toStringAsFixed(2)} km)',
                          style: GoogleFonts.ibmPlexMono(
                              fontSize: 13, color: c.textMid),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Velocidad: ${speed.toStringAsFixed(0)} km/h',
                          style: GoogleFonts.ibmPlexMono(
                              fontSize: 13, color: c.textMid),
                        ),
                        Text(
                          'Distancia: ${_totalDistanceKm.toStringAsFixed(2)} km',
                          style: GoogleFonts.ibmPlexMono(
                              fontSize: 13, color: c.textMid),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── d) BOTÓN MARCAR PARADA ──
              Expanded(
                child: GestureDetector(
                  onTap: _markStop,
                  child: Container(
                    width: double.infinity,
                    color: c.accent,
                    alignment: Alignment.center,
                    child: Text(
                      '＋ MARCAR PARADA',
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: c.bgRoot,
                      ),
                    ),
                  ),
                ),
              ),

              // ── e) BOTÓN DETENER ──
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GestureDetector(
                    onTap: () => _stopRecording(c),
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: c.stateCancelled, width: 1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '■ DETENER',
                        style: GoogleFonts.ibmPlexMono(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: c.stateCancelled,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Flash overlay
          if (_flashVisible)
            Positioned.fill(
              child: Container(
                color: c.accent.withAlpha(77),
              ),
            ),
        ],
      ),
    );
  }
}

class _MarkedStop {
  final int number;
  final LatLng position;
  final double distanceKm;
  const _MarkedStop({
    required this.number,
    required this.position,
    required this.distanceKm,
  });
}
