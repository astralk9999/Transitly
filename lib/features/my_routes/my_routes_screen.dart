import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../data/reputation/reputation_repository.dart';
import '../../data/supabase/supabase_client_provider.dart';
import '../../data/user_routes/user_routes_repository.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/pressable.dart';
import '../../shared/widgets/shimmer_skeleton.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/reputation_badge.dart';
import '../../shared/widgets/transit_app_bar.dart';
import '../../shared/models/enums.dart';

// TODO(l10n):
class MyRoutesScreen extends ConsumerStatefulWidget {
  const MyRoutesScreen({super.key});

  @override
  ConsumerState<MyRoutesScreen> createState() => _MyRoutesScreenState();
}

class _MyRoutesScreenState extends ConsumerState<MyRoutesScreen> {
  List<UserRouteModel> _routes = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final repo = ref.read(userRoutesRepositoryProvider);
    if (repo == null) {
      if (mounted) setState(() { _loading = false; _error = 'No autenticado'; });
      return;
    }
    try {
      final routes = await repo.getMyRoutes();
      if (mounted) setState(() { _routes = routes; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _deleteRoute(UserRouteModel route) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final c = TransitColorScheme.of(isDark);
        return AlertDialog(
          backgroundColor: c.bgSurface,
          title: Text(
            'Eliminar ruta',
            // TODO: l10n
            style: TransitTypography.heading(c.textHi),
          ),
          content: Text(
            '¿Seguro que quieres eliminar "${route.name}"? Esta acción no se puede deshacer.',
            // TODO: l10n
            style: TransitTypography.bodyPrimary(c.textMid),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Cancelar',
                style: TransitTypography.bodyPrimary(c.textMid),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                'Eliminar',
                style: TransitTypography.bodyPrimary(c.stateCancelled),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final repo = ref.read(userRoutesRepositoryProvider);
    if (repo == null) return;
    try {
      await repo.delete(route.id);
      if (mounted) {
        setState(() => _routes.removeWhere((r) => r.id == route.id));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ruta eliminada'),
            // TODO: l10n
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al eliminar ruta'),
            // TODO: l10n
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Color _hexToColor(String hex) {
    try {
      final h = hex.replaceFirst('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return const Color(0xFF977DDF);
    }
  }

  String _statusLabel(String status) {
    return switch (status) {
      'draft' => 'Borrador',
      'published' => 'Publicada',
      'review_pending' => 'En revisión',
      'community_approved' => 'Aprobada',
      _ => status,
    };
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'draft':
        return Colors.grey;
      case 'published':
        return const Color(0xFF4CAF50);
      case 'review_pending':
        return const Color(0xFFFF9800);
      case 'community_approved':
        return const Color(0xFF2196F3);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final session = ref.read(supabaseClientProvider).auth.currentSession;

    if (session == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const TransitAppBar(title: 'Mis rutas', transparent: true),
        body: EmptyState(
          'Inicia sesión',
          // TODO: l10n
          'Conéctate para ver y gestionar tus rutas',
          icon: Icons.person_outline,
          actionLabel: 'Iniciar sesión',
          onAction: () => context.push('/sign-in'),
        ),
      );
    }

    final rep = ref.watch(userReputationProvider);
    final reputation = rep.valueOrNull;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const TransitAppBar(title: 'Mis rutas', transparent: true),
      body: Column(
          children: [
            // Resumen de reputación (sin volver a poner título — ya
            // está en el TransitAppBar).
            _buildHeader(c, reputation),
            Expanded(
              child: _loading
                  ? ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: 5,
                      itemBuilder: (_, __) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ShimmerSkeleton.routeCard(context),
                      ),
                    )
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: EmptyState(
                              'Error',
                              _error!,
                              icon: Icons.error_outline,
                              actionLabel: 'Reintentar',
                              onAction: _load,
                            ),
                          ),
                        )
                      : _routes.isEmpty
                          ? EmptyState(
                              'Sin rutas',
                              // TODO: l10n
                              'Aún no has creado ninguna ruta. ¡Crea la primera!',
                              icon: Icons.route_outlined,
                            )
                          : RefreshIndicator(
                              onRefresh: _load,
                              color: c.accent,
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _routes.length,
                                itemBuilder: (context, index) =>
                                    _buildRouteCard(c, _routes[index]),
                              ),
                            ),
            ),
          ],
        ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMenu,
        backgroundColor: c.accent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final c = TransitColorScheme.of(
            Theme.of(ctx).brightness == Brightness.dark);
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: c.bgElevated,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: c.border, width: 0.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.add_road, color: c.accent),
                  title: Text('Crear ruta',
                      style: TransitTypography.bodyPrimary(c.textHi)),
                  subtitle: Text('Diseña una ruta nueva paso a paso',
                      style: TransitTypography.bodySmall(c.textMid)),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/create-route').then((_) => _load());
                  },
                ),
                Divider(height: 1, color: c.border),
                ListTile(
                  leading: Icon(Icons.qr_code_2, color: c.accent),
                  title: Text('Añadir por código',
                      style: TransitTypography.bodyPrimary(c.textHi)),
                  subtitle: Text('Pega un código o enlace de ruta compartida',
                      style: TransitTypography.bodySmall(c.textMid)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _addByCode();
                  },
                ),
                Divider(height: 1, color: c.border),
                ListTile(
                  leading: Icon(Icons.groups_outlined, color: c.accent),
                  title: Text('Explorar comunidad',
                      style: TransitTypography.bodyPrimary(c.textHi)),
                  subtitle: Text('Descubre e importa rutas de otros usuarios',
                      style: TransitTypography.bodySmall(c.textMid)),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/community');
                  },
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _addByCode() async {
    final ctrl = TextEditingController();
    final input = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Añadir por código'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Código o enlace',
            hintText: 'p.ej. ABC123 o transitly://…',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Buscar')),
        ],
      ),
    );
    if (input == null || input.isEmpty) return;

    // Extrae el código/slug de un enlace si lo pegaron entero.
    final raw = input.split(RegExp(r'[/?=#]')).where((s) => s.isNotEmpty).last;
    final repo = ref.read(userRoutesRepositoryProvider);
    if (repo == null) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      var route = await repo.getByShareCode(raw);
      route ??= await repo.getBySlug(raw);
      if (route == null) {
        messenger.showSnackBar(const SnackBar(
            content: Text('No se encontró ninguna ruta con ese código')));
        return;
      }
      await repo.importRoute(route.id);
      messenger.showSnackBar(SnackBar(
          content: Text('Ruta "${route.name}" añadida a Mis rutas')));
      await _load();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _buildHeader(TransitColorScheme c, UserReputation? reputation) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (reputation != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: GlassCard(
                blur: 8,
                fillOpacity: 0.04,
                borderRadius: 10,
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    ReputationBadge(
                      ReputationLevel.new_,
                      score: reputation.score,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_routes.length} rutas · Nivel ${reputation.level}',
                            // TODO: l10n
                            style: TransitTypography.bodyPrimary(c.textHi),
                          ),
                          if (reputation.xpToNextLevel() > 0)
                            Text(
                              '${reputation.score} XP · ${reputation.xpToNextLevel()} para siguiente nivel',
                              // TODO: l10n
                              style: TransitTypography.bodySmall(c.textMid),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRouteCard(TransitColorScheme c, UserRouteModel route) {
    final color = _hexToColor(route.routeColor);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: Key(route.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: c.stateCancelled.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.delete, color: c.stateCancelled),
        ),
        confirmDismiss: (_) async {
          await _deleteRoute(route);
          return false; // Already handled deletion
        },
        child: Pressable(
          onTap: () => context.push('/community/route/${route.id}'),
          child: GlassCard(
            blur: 8,
            fillOpacity: 0.04,
            borderRadius: 10,
            padding: EdgeInsets.zero,
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 64,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      bottomLeft: Radius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          route.name,
                          style: TransitTypography.routeName(c.textHi),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.place, size: 14, color: c.textMid),
                            const SizedBox(width: 4),
                            Text(
                              '--',
                              style: TransitTypography.bodySmall(c.textMid),
                            ),
                            const SizedBox(width: 12),
                            StatusBadge(
                              _statusLabel(route.status),
                              _statusColor(route.status),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, size: 20, color: c.textMid),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
