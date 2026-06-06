import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../core/utils/app_logger.dart';
import '../../data/supabase/supabase_client_provider.dart';
import '../../data/user_routes/user_routes_repository.dart';
import '../../data/user_stops/user_stops_repository.dart';
import '../../shared/models/user_role.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_card.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/pressable.dart';
import '../../shared/widgets/role_gate.dart';
import '../../shared/widgets/shimmer_skeleton.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/transit_app_bar.dart';
import '../../shared/widgets/transit_button.dart';
import '../../shared/widgets/transit_input.dart';

class RouteModerationScreen extends ConsumerStatefulWidget {
  const RouteModerationScreen({super.key});

  @override
  ConsumerState<RouteModerationScreen> createState() =>
      _RouteModerationScreenState();
}

class _RouteModerationScreenState
    extends ConsumerState<RouteModerationScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  List<UserRouteModel> _pendingRoutes = [];
  List<UserStopModel> _pendingStops = [];
  final Map<String, String> _authorNames = {};

  bool _loadingRoutes = true;
  bool _loadingStops = true;
  String? _errorRoutes;
  String? _errorStops;
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRoutes();
    _loadStops();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRoutes() async {
    setState(() {
      _loadingRoutes = true;
      _errorRoutes = null;
    });

    try {
      final client = ref.read(supabaseClientProvider);
      final session = client.auth.currentSession;
      if (session == null) {
        setState(() {
          _loadingRoutes = false;
          _offline = true;
        });
        return;
      }

      final rows = await client
          .from('user_routes')
          .select()
          .eq('status', 'review_pending')
          .order('created_at', ascending: false);

      final data = (rows as List).cast<Map<String, dynamic>>();
      final routes = data.map(UserRouteModel.fromJson).toList();

      await _fetchAuthorNames(client, routes);

      setState(() {
        _pendingRoutes = routes;
        _loadingRoutes = false;
      });
    } catch (e) {
      AppLogger.warn('route_moderation_screen: load routes failed', e.toString());
      setState(() {
        _loadingRoutes = false;
        _errorRoutes = '';
      });
    }
  }

  Future<void> _loadStops() async {
    setState(() {
      _loadingStops = true;
      _errorStops = null;
    });

    try {
      final client = ref.read(supabaseClientProvider);
      final session = client.auth.currentSession;
      if (session == null) {
        setState(() {
          _loadingStops = false;
          _offline = true;
        });
        return;
      }

      final rows = await client
          .from('user_stops')
          .select()
          .eq('promotion_status', 'requested')
          .order('created_at', ascending: false);

      final data = (rows as List).cast<Map<String, dynamic>>();
      final stops = data.map(UserStopModel.fromJson).toList();

      await _fetchAuthorNamesForStops(client, stops);

      setState(() {
        _pendingStops = stops;
        _loadingStops = false;
      });
    } catch (e) {
      AppLogger.warn('route_moderation_screen: load stops failed', e.toString());
      setState(() {
        _loadingStops = false;
        _errorStops = '';
      });
    }
  }

  Future<void> _fetchAuthorNames(
      SupabaseClient client, List<UserRouteModel> routes) async {
    final authorIds = routes
        .map((r) => r.authorId)
        .where((id) => !_authorNames.containsKey(id))
        .toSet()
        .toList();

    if (authorIds.isEmpty) return;

    try {
      final profiles = await client
          .from('profiles')
          .select('id, display_name')
          .inFilter('id', authorIds);

      for (final p in (profiles as List)) {
        _authorNames[p['id'] as String] =
            p['display_name'] as String? ?? p['id'] as String;
      }
    } catch (_) {}
  }

  Future<void> _fetchAuthorNamesForStops(
      SupabaseClient client, List<UserStopModel> stops) async {
    final authorIds = stops
        .map((s) => s.authorId)
        .where((id) => !_authorNames.containsKey(id))
        .toSet()
        .toList();

    if (authorIds.isEmpty) return;

    try {
      final profiles = await client
          .from('profiles')
          .select('id, display_name')
          .inFilter('id', authorIds);

      for (final p in (profiles as List)) {
        _authorNames[p['id'] as String] =
            p['display_name'] as String? ?? p['id'] as String;
      }
    } catch (_) {}
  }

  String _authorLabel(String authorId) =>
      _authorNames[authorId] ?? authorId;

  String _serviceTypeLabel(String type) {
    switch (type) {
      case 'urban':
        return 'Urbano';
      case 'metropolitan':
        return 'Metropolitano';
      case 'interurban':
        return 'Interurbano';
      case 'longDistance':
        return 'Larga distancia';
      case 'special':
        return 'Especial';
      case 'school':
        return 'Escolar';
      case 'onDemand':
        return 'Bajo demanda';
      default:
        return type;
    }
  }

  String _stopTypeLabel(String type) {
    switch (type) {
      case 'custom':
        return 'Personalizada';
      case 'suggested':
        return 'Sugerida';
      default:
        return type;
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '—';
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}';
  }

  Color _parseColor(String hex) {
    try {
      final h = hex.replaceFirst('#', '');
      if (h.length == 6) {
        return Color(int.parse('FF$h', radix: 16));
      }
    } catch (_) {}
    return const Color(0xFF977DDF);
  }

  Future<void> _approveRoute(UserRouteModel route) async {
    try {
      final client = ref.read(supabaseClientProvider);
      await client
          .from('user_routes')
          .update({
            'status': 'community_approved',
            'visibility': 'public',
            'published_at': DateTime.now().toIso8601String(),
          })
          .eq('id', route.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ruta aprobada')),
        );
      }
      await _loadRoutes();
    } catch (e) {
      AppLogger.error('route_moderation: approve route failed', e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _rejectRoute(UserRouteModel route, String reason) async {
    try {
      final client = ref.read(supabaseClientProvider);
      await client
          .from('user_routes')
          .update({
            'status': 'rejected',
            'rejection_reason': reason,
          })
          .eq('id', route.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ruta rechazada')),
        );
        Navigator.of(context).pop();
      }
      await _loadRoutes();
    } catch (e) {
      AppLogger.error('route_moderation: reject route failed', e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _approveStop(UserStopModel stop) async {
    try {
      final client = ref.read(supabaseClientProvider);

      final officialCode = 'user_stop_${stop.id}';
      await client.from('stops').insert({
        'officialCode': officialCode,
        'name': stop.name,
        'lat': stop.lat,
        'lng': stop.lng,
      });

      await client
          .from('user_stops')
          .update({
            'promotion_status': 'approved',
            'official_stop_id': officialCode,
          })
          .eq('id', stop.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Parada aprobada')),
        );
      }
      await _loadStops();
    } catch (e) {
      AppLogger.error('route_moderation: approve stop failed', e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _rejectStop(UserStopModel stop, String reason) async {
    try {
      final client = ref.read(supabaseClientProvider);
      await client
          .from('user_stops')
          .update({
            'promotion_status': 'rejected',
            'admin_notes': reason,
          })
          .eq('id', stop.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Parada rechazada')),
        );
        Navigator.of(context).pop();
      }
      await _loadStops();
    } catch (e) {
      AppLogger.error('route_moderation: reject stop failed', e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showRejectDialog({
    required String title,
    required void Function(String reason) onConfirm,
  }) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final c = TransitColorScheme.of(isDark);
        return AlertDialog(
          backgroundColor: c.bgSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: c.border, width: 0.5),
          ),
          title: Text(title,
              style: TransitTypography.heading(c.textHi)),
          content: TransitInput(
            hint: 'Razón del rechazo...',
            controller: controller,
            maxLines: 3,
            onChanged: (_) {},
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancelar',
                  style: TransitTypography.bodyPrimary(c.textMid)),
            ),
            TransitButton(
              label: 'Rechazar',
              isDanger: true,
              isSmall: true,
              onPressed: () {
                final reason = controller.text.trim();
                if (reason.isEmpty) return;
                onConfirm(reason);
              },
            ),
          ],
        );
      },
    );
  }

  void _showRouteDetail(UserRouteModel route) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final routeColor = _parseColor(route.routeColor);

    showModalBottomSheet(
      context: context,
      backgroundColor: c.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: routeColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(route.name,
                        style: TransitTypography.heading(c.textHi)),
                  ),
                ],
              ),
              if (route.description != null &&
                  route.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(route.description!,
                    style: TransitTypography.bodyPrimary(c.textMid)),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  _infoChip(c, 'Autor', _authorLabel(route.authorId)),
                  const SizedBox(width: 12),
                  _infoChip(c, 'Tipo', _serviceTypeLabel(route.serviceType)),
                  const SizedBox(width: 12),
                  _infoChip(c, 'Creado', _formatDate(route.createdAt)),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TransitButton(
                      label: 'Aprobar',
                      icon: Icons.check,
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _approveRoute(route);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TransitButton(
                      label: 'Rechazar',
                      icon: Icons.close,
                      isDanger: true,
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _showRejectDialog(
                          title: 'Motivo del rechazo',
                          onConfirm: (reason) =>
                              _rejectRoute(route, reason),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showStopDetail(UserStopModel stop) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    showModalBottomSheet(
      context: context,
      backgroundColor: c.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(Icons.location_on, color: c.accent, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(stop.name,
                        style: TransitTypography.heading(c.textHi)),
                  ),
                ],
              ),
              if (stop.description != null &&
                  stop.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(stop.description!,
                    style: TransitTypography.bodyPrimary(c.textMid)),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  _infoChip(c, 'Autor', _authorLabel(stop.authorId)),
                  const SizedBox(width: 12),
                  _infoChip(c, 'Tipo', _stopTypeLabel(stop.stopType)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${stop.lat.toStringAsFixed(5)}, ${stop.lng.toStringAsFixed(5)}',
                style: TransitTypography.routeCodeSmall(c.textMid),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TransitButton(
                      label: 'Aprobar',
                      icon: Icons.check,
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _approveStop(stop);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TransitButton(
                      label: 'Rechazar',
                      icon: Icons.close,
                      isDanger: true,
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _showRejectDialog(
                          title: 'Motivo del rechazo',
                          onConfirm: (reason) =>
                              _rejectStop(stop, reason),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _infoChip(TransitColorScheme c, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label.toUpperCase(),
            style: TransitTypography.sectionLabel(c.textLo)),
        const SizedBox(height: 2),
        Text(value, style: TransitTypography.bodySmall(c.textMid)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    return RoleGate(
      allow: const [UserRole.admin],
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Column(
              children: [
                const TransitAppBar(title: 'Moderación de rutas', transparent: true),
                Material(
                  color: Colors.transparent,
                  child: TabBar(
                    controller: _tabController,
                    labelStyle:
                        TransitTypography.tabLabel(c.accent),
                    unselectedLabelStyle:
                        TransitTypography.tabLabel(c.textMid),
                    labelColor: c.accent,
                    unselectedLabelColor: c.textMid,
                    indicatorColor: c.accent,
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: 'Pendientes'),
                      Tab(text: 'Paradas'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildRoutesTab(c),
                      _buildStopsTab(c),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutesTab(TransitColorScheme c) {
    if (_loadingRoutes) {
      return ShimmerSkeleton.list(
        context: context,
        count: 5,
        builder: () => ShimmerSkeleton.routeCard(context),
      );
    }

    if (_offline) {
      return EmptyState(
        'Sin conexión',
        'Conecta a internet para revisar rutas',
        icon: Icons.cloud_off,
      );
    }

    if (_errorRoutes != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ErrorCard('Error al cargar rutas', onRetry: _loadRoutes),
        ),
      );
    }

    if (_pendingRoutes.isEmpty) {
      return EmptyState(
        'Sin rutas pendientes',
        'No hay rutas esperando moderación',
        icon: Icons.check_circle_outline,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _pendingRoutes.length,
      itemBuilder: (context, index) {
        final route = _pendingRoutes[index];
        final routeColor = _parseColor(route.routeColor);
        return Padding(
          padding: EdgeInsets.only(
            bottom: index < _pendingRoutes.length - 1 ? 10 : 0,
          ),
          child: Pressable(
            onTap: () => _showRouteDetail(route),
            child: GlassCard(
              blur: 12,
              fillOpacity: 0.05,
              borderRadius: 12,
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: routeColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          route.name,
                          style: TransitTypography.bodyPrimary(c.textHi),
                        ),
                      ),
                      StatusBadge(
                        _serviceTypeLabel(route.serviceType),
                        c.accent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.person_outline,
                          size: 14, color: c.textLo),
                      const SizedBox(width: 4),
                      Text(
                        _authorLabel(route.authorId),
                        style: TransitTypography.bodySmall(c.textMid),
                      ),
                      const Spacer(),
                      Icon(Icons.calendar_today,
                          size: 14, color: c.textLo),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(route.createdAt),
                        style: TransitTypography.bodySmall(c.textMid),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TransitButton(
                          label: 'Aprobar',
                          icon: Icons.check,
                          isSmall: true,
                          onPressed: () => _approveRoute(route),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TransitButton(
                          label: 'Rechazar',
                          icon: Icons.close,
                          isSmall: true,
                          isDanger: true,
                          onPressed: () => _showRejectDialog(
                            title: 'Motivo del rechazo',
                            onConfirm: (reason) =>
                                _rejectRoute(route, reason),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStopsTab(TransitColorScheme c) {
    if (_loadingStops) {
      return ShimmerSkeleton.list(
        context: context,
        count: 5,
        builder: () => ShimmerSkeleton.routeCard(context),
      );
    }

    if (_offline) {
      return EmptyState(
        'Sin conexión',
        'Conecta a internet para revisar paradas',
        icon: Icons.cloud_off,
      );
    }

    if (_errorStops != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ErrorCard('Error al cargar paradas', onRetry: _loadStops),
        ),
      );
    }

    if (_pendingStops.isEmpty) {
      return EmptyState(
        'Sin paradas pendientes',
        'No hay paradas solicitando promoción',
        icon: Icons.check_circle_outline,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _pendingStops.length,
      itemBuilder: (context, index) {
        final stop = _pendingStops[index];
        return Padding(
          padding: EdgeInsets.only(
            bottom: index < _pendingStops.length - 1 ? 10 : 0,
          ),
          child: Pressable(
            onTap: () => _showStopDetail(stop),
            child: GlassCard(
              blur: 12,
              fillOpacity: 0.05,
              borderRadius: 12,
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          size: 20, color: c.accent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          stop.name,
                          style: TransitTypography.bodyPrimary(c.textHi),
                        ),
                      ),
                      StatusBadge(
                        _stopTypeLabel(stop.stopType),
                        c.accent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${stop.lat.toStringAsFixed(5)}, ${stop.lng.toStringAsFixed(5)}',
                    style: TransitTypography.routeCodeSmall(c.textMid),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.person_outline,
                          size: 14, color: c.textLo),
                      const SizedBox(width: 4),
                      Text(
                        _authorLabel(stop.authorId),
                        style: TransitTypography.bodySmall(c.textMid),
                      ),
                      const Spacer(),
                      if (stop.createdAt != null) ...[
                        Icon(Icons.calendar_today,
                            size: 14, color: c.textLo),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(stop.createdAt),
                          style: TransitTypography.bodySmall(c.textMid),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TransitButton(
                          label: 'Aprobar',
                          icon: Icons.check,
                          isSmall: true,
                          onPressed: () => _approveStop(stop),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TransitButton(
                          label: 'Rechazar',
                          icon: Icons.close,
                          isSmall: true,
                          isDanger: true,
                          onPressed: () => _showRejectDialog(
                            title: 'Motivo del rechazo',
                            onConfirm: (reason) =>
                                _rejectStop(stop, reason),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
