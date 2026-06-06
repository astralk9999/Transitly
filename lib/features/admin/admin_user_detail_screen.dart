import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../data/supabase/supabase_client_provider.dart';
import '../../shared/models/reputation.dart';
import '../../shared/models/user_role.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/role_gate.dart';
import '../../shared/widgets/transit_app_bar.dart';

/// Pantalla detalle de usuario (admin). 3 tabs:
///   - Resumen: rol, XP, rangos, acciones rápidas
///   - Rutas: user_routes creadas por el usuario
///   - Feedback: route_feedback que ha enviado
class AdminUserDetailScreen extends ConsumerStatefulWidget {
  const AdminUserDetailScreen({super.key, required this.userId});
  final String userId;

  @override
  ConsumerState<AdminUserDetailScreen> createState() =>
      _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState
    extends ConsumerState<AdminUserDetailScreen> {
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _routes = [];
  List<Map<String, dynamic>> _feedback = [];
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
    try {
      final client = ref.read(supabaseClientProvider);
      final results = await Future.wait([
        client
            .from('profiles')
            .select(
                'id, display_name, role, reputation_score, reputation_level, routes_created_count, created_at')
            .eq('id', widget.userId)
            .maybeSingle(),
        client
            .from('user_routes')
            .select('id, name, status, visibility, vote_count, view_count, created_at, route_color')
            .eq('author_id', widget.userId)
            .order('created_at', ascending: false),
        client
            .from('route_feedback')
            .select('id, kind, description, status, created_at, route_id, proposed_change')
            .eq('author_id', widget.userId)
            .order('created_at', ascending: false),
      ]);
      if (!mounted) return;
      setState(() {
        _profile = results[0] as Map<String, dynamic>?;
        _routes = (results[1] as List).cast<Map<String, dynamic>>();
        _feedback = (results[2] as List).cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Error cargando datos: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final name = (_profile?['display_name'] as String?) ?? 'Usuario';

    return RoleGate(
      allow: const [UserRole.admin],
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: TransitAppBar(title: name, transparent: true),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(_error!,
                            style: TransitTypography.bodyPrimary(c.textHi)),
                      ),
                    )
                  : Column(
                      children: [
                        TabBar(
                          indicatorColor: c.accent,
                          labelColor: c.accent,
                          unselectedLabelColor: c.textMid,
                          tabs: [
                            const Tab(text: 'Resumen'),
                            Tab(text: 'Rutas (${_routes.length})'),
                            Tab(text: 'Feedback (${_feedback.length})'),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _SummaryTab(
                                profile: _profile!,
                                c: c,
                                onChanged: _load,
                                client: ref.read(supabaseClientProvider),
                                userId: widget.userId,
                              ),
                              _RoutesTab(routes: _routes, c: c),
                              _FeedbackTab(feedback: _feedback, c: c),
                            ],
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Tab 1 — Resumen
// ─────────────────────────────────────────────────────────────────────
class _SummaryTab extends StatelessWidget {
  const _SummaryTab({
    required this.profile,
    required this.c,
    required this.onChanged,
    required this.client,
    required this.userId,
  });

  final Map<String, dynamic> profile;
  final TransitColorScheme c;
  final VoidCallback onChanged;
  final dynamic client;
  final String userId;

  static const _roles = ['passenger', 'driver', 'operatorAdmin', 'moderator', 'admin'];
  static const _roleLabels = {
    'passenger': 'Pasajero',
    'driver': 'Conductor',
    'operatorAdmin': 'Op. Admin',
    'moderator': 'Moderador',
    'admin': 'Admin',
  };

  @override
  Widget build(BuildContext context) {
    final role = profile['role'] as String? ?? 'passenger';
    final score = (profile['reputation_score'] as num?)?.toInt() ?? 0;
    final level = (profile['reputation_level'] as num?)?.toInt() ?? 0;
    final routesCount = (profile['routes_created_count'] as num?)?.toInt() ?? 0;
    final createdAt = profile['created_at'] as String?;
    final id = profile['id'] as String;
    final rank = ReputationRank.forScore(score);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GlassCard(
          blur: 12,
          fillOpacity: 0.05,
          borderRadius: 12,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(rank.icon, color: rank.color, size: 28),
                  const SizedBox(width: 8),
                  Text('$score XP',
                      style: TransitTypography.heading(c.textHi)),
                ],
              ),
              const SizedBox(height: 6),
              Text('Nivel BD: $level · Rango calc: ${rank.name}',
                  style: TransitTypography.bodySmall(c.textLo)),
              const SizedBox(height: 12),
              _kv(c, 'ID', '${id.substring(0, 8)}...'),
              _kv(c, 'Rol actual', _roleLabels[role] ?? role),
              _kv(c, 'Rutas creadas', '$routesCount'),
              if (createdAt != null)
                _kv(c, 'Alta', createdAt.substring(0, 10)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _section(c, 'Cambiar rol'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final r in _roles)
              ChoiceChip(
                label: Text(_roleLabels[r] ?? r),
                selected: role == r,
                onSelected: (_) => _changeRole(context, r),
                selectedColor: c.accent.withValues(alpha: 0.3),
                backgroundColor: c.bgRaised,
              ),
          ],
        ),
        const SizedBox(height: 16),
        _section(c, 'Setear rango'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final r in ReputationRank.values)
              ActionChip(
                avatar: Icon(r.icon, size: 16, color: r.color),
                label: Text('${r.name} (${r.minScore})'),
                onPressed: () => _setRank(context, r),
                backgroundColor: r == rank
                    ? r.color.withValues(alpha: 0.18)
                    : c.bgRaised,
              ),
          ],
        ),
        const SizedBox(height: 16),
        _section(c, 'XP rápido'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => _addXp(context, 50),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('+50'),
            ),
            OutlinedButton.icon(
              onPressed: () => _addXp(context, 500),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('+500'),
            ),
            OutlinedButton.icon(
              onPressed: () => _addXp(context, -50),
              icon: const Icon(Icons.remove, size: 16),
              label: const Text('-50'),
              style: OutlinedButton.styleFrom(
                  foregroundColor: c.stateCancelled),
            ),
            OutlinedButton.icon(
              onPressed: () => _setScore(context, 0, 0),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reset 0'),
              style: OutlinedButton.styleFrom(
                  foregroundColor: c.stateCancelled),
            ),
          ],
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _section(TransitColorScheme c, String text) {
    return Text(text,
        style: TransitTypography.sectionTitle(c.accent));
  }

  Widget _kv(TransitColorScheme c, String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
              width: 110,
              child: Text(k,
                  style: TransitTypography.bodySmall(c.textMid))),
          Expanded(
              child: Text(v,
                  style: TransitTypography.bodySecondary(c.textHi))),
        ],
      ),
    );
  }

  Future<void> _changeRole(BuildContext context, String role) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await client.from('profiles').update({'role': role}).eq('id', userId);
      messenger.showSnackBar(SnackBar(content: Text('Rol → $role')));
      onChanged();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _addXp(BuildContext context, int delta) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await client.rpc('add_xp',
          params: {'p_user_id': userId, 'p_xp': delta});
      messenger.showSnackBar(SnackBar(
          content: Text('${delta >= 0 ? '+' : ''}$delta XP')));
      onChanged();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  /// Setea el rango directo: pone score al umbral mínimo + 1 (para
  /// dejar margen visible) y delega en add_xp para recalcular nivel.
  Future<void> _setRank(BuildContext context, ReputationRank r) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      // Resetear y luego dar el XP justo para entrar al rango: así
      // dispara notificación rank_up y deja al usuario con la barra
      // a 0% del nuevo rango.
      await client.from('profiles').update({
        'reputation_score': 0,
        'reputation_level': 0,
      }).eq('id', userId);
      if (r.minScore > 0) {
        await client.rpc('add_xp',
            params: {'p_user_id': userId, 'p_xp': r.minScore});
      }
      messenger.showSnackBar(SnackBar(content: Text('Rango → ${r.name}')));
      onChanged();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _setScore(BuildContext context, int score, int level) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await client.from('profiles').update({
        'reputation_score': score,
        'reputation_level': level,
      }).eq('id', userId);
      messenger.showSnackBar(const SnackBar(content: Text('XP reseteado')));
      onChanged();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}

// ─────────────────────────────────────────────────────────────────────
// Tab 2 — Rutas
// ─────────────────────────────────────────────────────────────────────
class _RoutesTab extends StatelessWidget {
  const _RoutesTab({required this.routes, required this.c});
  final List<Map<String, dynamic>> routes;
  final TransitColorScheme c;

  @override
  Widget build(BuildContext context) {
    if (routes.isEmpty) {
      return const EmptyState(
        'Sin rutas',
        'Este usuario no ha creado rutas todavía',
        icon: Icons.route_outlined,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: routes.length,
      itemBuilder: (_, i) {
        final r = routes[i];
        final id = r['id'] as String;
        final name = r['name'] as String? ?? 'Sin nombre';
        final status = r['status'] as String? ?? 'draft';
        final visibility = r['visibility'] as String? ?? 'private';
        final votes = (r['vote_count'] as num?)?.toInt() ?? 0;
        final views = (r['view_count'] as num?)?.toInt() ?? 0;
        final colorHex = r['route_color'] as String? ?? '#977DDF';

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GlassCard(
            blur: 12,
            fillOpacity: 0.05,
            borderRadius: 12,
            padding: EdgeInsets.zero,
            child: ListTile(
              onTap: () => context.push('/route/$id'),
              leading: Container(
                width: 12,
                height: 40,
                decoration: BoxDecoration(
                  color: _parseHex(colorHex),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              title: Text(name,
                  style: TransitTypography.bodyPrimary(c.textHi)),
              subtitle: Text(
                '$status · $visibility · 👍 $votes · 👁 $views',
                style: TransitTypography.bodySmall(c.textMid),
              ),
              trailing: Icon(Icons.chevron_right, color: c.textLo),
            ),
          ),
        );
      },
    );
  }

  Color _parseHex(String hex) {
    try {
      final clean = hex.replaceFirst('#', '');
      if (clean.length == 6) return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {}
    return const Color(0xFF977DDF);
  }
}

// ─────────────────────────────────────────────────────────────────────
// Tab 3 — Feedback
// ─────────────────────────────────────────────────────────────────────
class _FeedbackTab extends StatelessWidget {
  const _FeedbackTab({required this.feedback, required this.c});
  final List<Map<String, dynamic>> feedback;
  final TransitColorScheme c;

  @override
  Widget build(BuildContext context) {
    if (feedback.isEmpty) {
      return const EmptyState(
        'Sin feedback',
        'Este usuario no ha enviado feedback todavía',
        icon: Icons.feedback_outlined,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: feedback.length,
      itemBuilder: (_, i) {
        final f = feedback[i];
        final kind = f['kind'] as String? ?? '?';
        final desc = f['description'] as String? ?? '';
        final status = f['status'] as String? ?? 'open';
        final createdAt = f['created_at'] as String?;
        final routeId = f['route_id'] as String?;
        final legacy = (f['proposed_change'] as Map?)?['legacy_route_code'];

        Color statusColor;
        switch (status) {
          case 'applied':
            statusColor = c.stateOnTime;
          case 'rejected':
            statusColor = c.stateCancelled;
          case 'in_review':
            statusColor = c.stateDelay;
          default:
            statusColor = c.textMid;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GlassCard(
            blur: 12,
            fillOpacity: 0.05,
            borderRadius: 12,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color: statusColor.withValues(alpha: 0.5),
                            width: 0.5),
                      ),
                      child: Text(status,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusColor)),
                    ),
                    const SizedBox(width: 8),
                    Text(kind,
                        style: TransitTypography.bodySmall(c.textMid)),
                    const Spacer(),
                    if (createdAt != null)
                      Text(createdAt.substring(0, 10),
                          style: TransitTypography.bodySmall(c.textLo)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(desc,
                    style: TransitTypography.bodySecondary(c.textHi)),
                if (routeId != null || legacy != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Ruta: ${routeId ?? legacy}',
                    style: TransitTypography.bodySmall(c.textLo),
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
