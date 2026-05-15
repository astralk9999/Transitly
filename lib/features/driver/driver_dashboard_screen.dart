import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/geo/geo_providers.dart';
import '../../../data/mock/mock_data_service.dart';
import '../../../data/supabase/supabase_client_provider.dart';
import '../../../shared/models/operator_model.dart';
import '../../../shared/models/route_model.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/providers/user_provider.dart';
import '../../../shared/widgets/smoke_background.dart';
import '../../../shared/widgets/transit_button.dart';
import '../map/map_config.dart';

class DriverDashboardScreen extends ConsumerStatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  ConsumerState<DriverDashboardScreen> createState() =>
      _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends ConsumerState<DriverDashboardScreen> {
  OperatorModel? _selectedOperator;
  RouteModel? _selectedRoute;
  List<RouteModel> _availableRoutes = [];
  bool _isLoadingRoutes = false;

  bool _isTracking = false;
  bool _isPaused = false;
  final List<LatLng> _positions = [];
  LatLng? _currentPosition;
  double _tripDistanceKm = 0;
  int _elapsedSeconds = 0;

  StreamSubscription<Position>? _gpsSub;
  Timer? _insertTimer;
  Timer? _clockTimer;

  @override
  void dispose() {
    _stopTracking();
    super.dispose();
  }

  Future<void> _loadRoutes() async {
    if (_selectedOperator == null) return;
    setState(() => _isLoadingRoutes = true);

    try {
      final mockData = ref.read(mockDataServiceProvider);
      final client = ref.read(supabaseClientProvider);
      final session = client.auth.currentSession;

      if (session != null) {
        final response = await client
            .from('routes')
            .select()
            .eq('operator_id', _selectedOperator!.id)
            .eq('source', 'official');

        final routes = response as List<dynamic>;
        _availableRoutes = routes
            .map((r) {
              final code = r['code'] as String;
              return mockData.routes.firstWhere(
                (mr) => mr.code == code,
                orElse: () => mockData.routes.first,
              );
            })
            .toList();
      } else {
        _availableRoutes = mockData.routes;
      }
    } catch (_) {
      final mockData = ref.read(mockDataServiceProvider);
      _availableRoutes = mockData.routes;
    } finally {
      if (mounted) setState(() => _isLoadingRoutes = false);
    }
  }

  Future<void> _startTracking() async {
    if (_selectedRoute == null) return;

    final locationService = ref.read(locationServiceProvider);
    try {
      if (_positions.isNotEmpty) _positions.clear();
      _tripDistanceKm = 0;
      _elapsedSeconds = 0;

      LocationPermission perm;
      try {
        perm = await Geolocator.checkPermission();
      } catch (_) {
        perm = LocationPermission.denied;
      }

      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Permiso de ubicación requerido')),
          );
        }
        return;
      }

      final positionStream = locationService.subscribe(
        settings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      );

      _gpsSub = positionStream.listen((pos) {
        if (!_isTracking || _isPaused) return;
        final point = LatLng(pos.latitude, pos.longitude);
        if (_currentPosition != null) {
          _tripDistanceKm += _haversineKm(_currentPosition!, point);
        }
        _positions.add(point);
        _currentPosition = point;
        if (mounted) setState(() {});
      });

      setState(() {
        _isTracking = true;
        _isPaused = false;
      });

      _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _elapsedSeconds++;
        if (mounted) setState(() {});
      });

      _insertTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        _insertBusPosition();
      });
    } catch (e) {
      AppLogger.warn('DriverDashboard', 'tracking start error', e);
    }
  }

  Future<void> _insertBusPosition() async {
    if (_currentPosition == null || _selectedRoute == null) return;

    try {
      final client = ref.read(supabaseClientProvider);
      final session = client.auth.currentSession;
      if (session == null) return;

      await client.from('bus_positions').insert({
        'route_id': _selectedRoute!.id,
        'driver_id': session.user.id,
        'source': 'driver',
        'geom':
            'SRID=4326;POINT(${_currentPosition!.longitude} ${_currentPosition!.latitude})',
        'bearing': 0,
        'recorded_at': DateTime.now().toUtc().toIso8601String(),
        'expires_at': DateTime.now()
            .toUtc()
            .add(const Duration(minutes: 2))
            .toIso8601String(),
      });
    } catch (e) {
      AppLogger.warn('DriverDashboard', 'bus_position insert failed', e);
    }
  }

  void _pauseTracking() {
    setState(() => _isPaused = !_isPaused);
  }

  void _stopTracking() {
    _gpsSub?.cancel();
    _gpsSub = null;
    _insertTimer?.cancel();
    _insertTimer = null;
    _clockTimer?.cancel();
    _clockTimer = null;
    if (mounted) {
      setState(() {
        _isTracking = false;
        _isPaused = false;
      });
    }
  }

  String _formatTime(int sec) {
    final h = sec ~/ 3600;
    final m = (sec % 3600) ~/ 60;
    final s = sec % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double _haversineKm(LatLng a, LatLng b) {
    const r = 6371.0;
    final dLat = (b.latitude - a.latitude) * pi / 180;
    final dLng = (b.longitude - a.longitude) * pi / 180;
    final lat1 = a.latitude * pi / 180;
    final lat2 = b.latitude * pi / 180;
    final h = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLng / 2) * sin(dLng / 2);
    return 2 * r * asin(sqrt(h));
  }

  Widget _buildRouteChips(TransitColorScheme c, MockDataService mockData) {
    final routes = <RouteModel>[];
    if (_availableRoutes.isEmpty) {
      for (final r in mockData.routes) {
        routes.add(r);
        if (routes.length >= 6) break;
      }
    } else {
      routes.addAll(_availableRoutes.take(6));
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: routes
          .map((route) => _RouteChip(
                c: c,
                route: route,
                selected: _selectedRoute?.id == route.id,
                onTap: () => setState(() => _selectedRoute = route),
              ))
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final user = ref.watch(currentUserProvider);
    final mockData = ref.watch(mockDataServiceProvider);

    if (_selectedOperator == null) {
      _selectedOperator = mockData.operator_;
    }

    return Scaffold(
      backgroundColor: c.bgRoot,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.textMid),
          onPressed: () => context.pop(),
        ),
        title: Text('Modo conductor',
            style: TransitTypography.sectionTitle(c.textHi)),
      ),
      body: Stack(
        children: [
          Positioned.fill(
              child: SmokeBackground(color: c.accent, isDark: isDark)),
          SafeArea(
            child: _isTracking
                ? _buildTrackingView(c)
                : _buildSetupView(c, user, mockData),
          ),
        ],
      ),
    );
  }

  Widget _buildSetupView(TransitColorScheme c, UserModel user,
      MockDataService mockData) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hola ${user.name}',
              style: TransitTypography.heading(c.textHi)),
          if (_selectedOperator != null)
            Text('Operador: ${_selectedOperator!.name}',
                style: TransitTypography.bodySecondary(c.textMid)),
          const SizedBox(height: 24),

          Text('Seleccionar ruta',
              style: TransitTypography.sectionTitle(c.textMid)),
          const SizedBox(height: 12),

          if (_isLoadingRoutes)
            const Center(child: CircularProgressIndicator())
          else ...[
            _buildRouteChips(c, mockData),
          ],
          const SizedBox(height: 24),

          TransitButton(
            label: _selectedRoute != null
                ? 'INICIAR VIAJE'
                : 'SELECCIONA UNA RUTA',
            isPrimary: _selectedRoute != null,
            onPressed:
                _selectedRoute != null ? _startTracking : null,
          ),
          const SizedBox(height: 16),

          if (_availableRoutes.isEmpty) ...[
            Text('Sin rutas cargadas',
                style: TransitTypography.bodySmall(c.textMid)),
            const SizedBox(height: 8),
            TransitButton(
              label: 'CARGAR RUTAS',
              isPrimary: false,
              isSmall: true,
              onPressed: _loadRoutes,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrackingView(TransitColorScheme c) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: c.bgSurface,
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _isPaused
                      ? Colors.orangeAccent
                      : Colors.greenAccent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _isPaused ? 'PAUSADO' : 'EN VIVO',
                style: TransitTypography.bodyPrimary(_isPaused
                        ? Colors.orangeAccent
                        : Colors.greenAccent)
                    .copyWith(
                        fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(_formatTime(_elapsedSeconds),
                  style: TransitTypography.bodyPrimary(c.textHi)
                      .copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w600)),
              const SizedBox(width: 16),
              Text('${_tripDistanceKm.toStringAsFixed(1)} km',
                  style: TransitTypography.bodySecondary(c.textMid)),
            ],
          ),
        ),
        Expanded(
          child: FlutterMap(
            options: MapOptions(
              initialCenter:
                  _currentPosition ?? const LatLng(36.685, -6.126),
              initialZoom: 15,
            ),
            children: [
              TileLayer(
                urlTemplate: MapConfig.tileUrl('light'),
                subdomains: MapConfig.subdomains,
                retinaMode: true,
              ),
              if (_positions.length >= 2)
                PolylineLayer(polylines: [
                  Polyline(
                    points: _positions,
                    color: c.accent,
                    strokeWidth: 3,
                  ),
                ]),
              if (_currentPosition != null)
                MarkerLayer(markers: [
                  Marker(
                    point: _currentPosition!,
                    width: 20,
                    height: 20,
                    child: Container(
                      decoration: BoxDecoration(
                        color: c.stateOnRoute,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ]),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TransitButton(
                    label: _isPaused ? 'REANUDAR' : 'PAUSAR',
                    isPrimary: false,
                    isSmall: true,
                    onPressed: _pauseTracking,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TransitButton(
                    label: 'FINALIZAR',
                    isDanger: true,
                    isSmall: true,
                    onPressed: () {
                      _stopTracking();
                      if (mounted) context.pop();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RouteChip extends StatelessWidget {
  const _RouteChip({
    required this.c,
    required this.route,
    required this.selected,
    this.onTap,
  });

  final TransitColorScheme c;
  final RouteModel route;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? c.accent.withValues(alpha: 0.2)
              : c.bgSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? c.accent : c.border,
            width: 0.5,
          ),
        ),
        child: Text(
          '${route.code} · ${route.name}',
          style: TextStyle(
            color: selected ? c.accent : c.textMid,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
