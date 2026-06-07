import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../data/supabase/supabase_client_provider.dart';
import '../../shared/models/reputation.dart';
import '../../shared/models/user_role.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/role_gate.dart';
import '../../shared/widgets/transit_app_bar.dart';

/// Pantalla detalle de usuario (admin). Tres tabs: Resumen / Rutas /
/// Feedback. Cualquier mutación recarga la pantalla en sitio.
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

  List<Map<String, dynamic>> _operators = [];

  Future<void> _load() async {
    if (mounted) setState(() => _error = null);
    try {
      final client = ref.read(supabaseClientProvider);
      // Operadoras activas en paralelo (las usa el selector de rol).
      // ignore: unawaited_futures
      client
          .from('operators')
          .select('id, name')
          .eq('is_active', true)
          .order('name')
          .then((rows) {
        if (mounted) {
          setState(() => _operators =
              (rows as List).cast<Map<String, dynamic>>());
        }
      });
      final results = await Future.wait([
        client
            .from('profiles')
            .select(
                'id, display_name, role, reputation_score, reputation_level, routes_created_count, created_at, is_banned, banned_at, ban_reason, operator_id')
            .eq('id', widget.userId)
            .maybeSingle(),
        client
            .from('user_routes')
            .select(
                'id, name, status, visibility, vote_count, view_count, created_at, route_color')
            .eq('author_id', widget.userId)
            .order('created_at', ascending: false),
        client
            .from('route_feedback')
            .select(
                'id, kind, description, status, created_at, route_id, proposed_change')
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
                        _UserHeader(
                          profile: _profile!,
                          feedbackCount: _feedback.length,
                          c: c,
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: c.bgRaised,
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: c.border, width: 0.5),
                          ),
                          child: TabBar(
                            dividerColor: Colors.transparent,
                            indicator: BoxDecoration(
                              color: c.accent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            indicatorSize: TabBarIndicatorSize.tab,
                            indicatorPadding: const EdgeInsets.all(4),
                            labelColor: c.accent,
                            unselectedLabelColor: c.textMid,
                            labelStyle: GoogleFonts.ibmPlexMono(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2),
                            tabs: [
                              const Tab(text: 'RESUMEN'),
                              Tab(text: 'RUTAS · ${_routes.length}'),
                              Tab(text: 'FEEDBACK · ${_feedback.length}'),
                            ],
                          ),
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _SummaryTab(
                                profile: _profile!,
                                operators: _operators,
                                c: c,
                                onChanged: _load,
                                onDeleted: () {
                                  if (context.mounted) context.pop();
                                },
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
// HEADER — avatar grande, nombre, rango, barra de progreso
// ─────────────────────────────────────────────────────────────────────
class _UserHeader extends StatelessWidget {
  const _UserHeader({
    required this.profile,
    required this.feedbackCount,
    required this.c,
  });
  final Map<String, dynamic> profile;
  final int feedbackCount;
  final TransitColorScheme c;

  bool get _isBanned => profile['is_banned'] == true;

  @override
  Widget build(BuildContext context) {
    final name = profile['display_name'] as String? ?? '?';
    final role = profile['role'] as String? ?? 'passenger';
    final score = (profile['reputation_score'] as num?)?.toInt() ?? 0;
    final routesCount =
        (profile['routes_created_count'] as num?)?.toInt() ?? 0;
    final rank = ReputationRank.forScore(score);
    final values = ReputationRank.values;
    final nextIdx = values.indexOf(rank) + 1;
    final isMax = nextIdx >= values.length;
    final nextMin = isMax ? rank.minScore : values[nextIdx].minScore;
    final progress = isMax ? 1.0 : (score / nextMin).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: GlassCard(
        blur: 16,
        fillOpacity: 0.06,
        borderRadius: 14,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: rank.color.withValues(alpha: 0.18),
                    border: Border.all(color: rank.color, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: rank.color,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: TransitTypography.heading(c.textHi),
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(rank.icon, size: 14, color: rank.color),
                              const SizedBox(width: 4),
                              Text(rank.name.toUpperCase(),
                                  style: GoogleFonts.ibmPlexMono(
                                    fontSize: 11,
                                    color: rank.color,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                  )),
                            ],
                          ),
                          _rolePill(role),
                          if (_isBanned)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFB71C1C)
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                    color: const Color(0xFFB71C1C),
                                    width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.block,
                                      size: 12,
                                      color: Color(0xFFB71C1C)),
                                  const SizedBox(width: 4),
                                  Text('BANEADO',
                                      style: GoogleFonts.ibmPlexMono(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFFB71C1C),
                                        letterSpacing: 1,
                                      )),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text('$score',
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: c.textHi,
                    )),
                Text(' XP',
                    style: TransitTypography.bodySecondary(c.textMid)),
                const Spacer(),
                if (!isMax)
                  Text('siguiente: $nextMin',
                      style: TransitTypography.bodySmall(c.textLo))
                else
                  Text('rango máximo',
                      style: TransitTypography.bodySmall(c.textLo)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: c.bgSurface,
                valueColor: AlwaysStoppedAnimation(rank.color),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _miniStat(c, Icons.route_outlined, '$routesCount', 'rutas'),
                const SizedBox(width: 14),
                _miniStat(c, Icons.feedback_outlined, '$feedbackCount',
                    'feedback'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _rolePill(String role) {
    final label = switch (role) {
      'admin' => 'ADMIN',
      'moderator' => 'MOD',
      'operatorAdmin' => 'OP. ADMIN',
      'driver' => 'CONDUCTOR',
      _ => 'PASAJERO',
    };
    final pillColor = switch (role) {
      'admin' => const Color(0xFFE91E63),
      'moderator' => const Color(0xFFFF9800),
      'operatorAdmin' => const Color(0xFF9C27B0),
      'driver' => const Color(0xFF2196F3),
      _ => c.textMid,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: pillColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
            color: pillColor.withValues(alpha: 0.5), width: 0.5),
      ),
      child: Text(label,
          style: GoogleFonts.ibmPlexMono(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: pillColor,
            letterSpacing: 1,
          )),
    );
  }

  Widget _miniStat(
      TransitColorScheme c, IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: c.textMid),
        const SizedBox(width: 4),
        Text(value,
            style: GoogleFonts.ibmPlexMono(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: c.textHi,
            )),
        const SizedBox(width: 4),
        Text(label, style: TransitTypography.bodySmall(c.textLo)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// TAB 1 — RESUMEN (acciones)
// ─────────────────────────────────────────────────────────────────────
class _SummaryTab extends StatelessWidget {
  const _SummaryTab({
    required this.profile,
    required this.operators,
    required this.c,
    required this.onChanged,
    required this.onDeleted,
    required this.client,
    required this.userId,
  });

  final Map<String, dynamic> profile;
  final List<Map<String, dynamic>> operators;
  final TransitColorScheme c;
  final VoidCallback onChanged;
  final VoidCallback onDeleted;
  final dynamic client;
  final String userId;

  static const _roles = [
    'passenger',
    'driver',
    'operatorAdmin',
    'moderator',
    'admin',
  ];
  static const _roleLabels = {
    'passenger': 'Pasajero',
    'driver': 'Conductor',
    'operatorAdmin': 'Op. Admin',
    'moderator': 'Moderador',
    'admin': 'Admin',
  };
  static const _roleIcons = {
    'passenger': Icons.person_outline,
    'driver': Icons.directions_bus_outlined,
    'operatorAdmin': Icons.apartment_outlined,
    'moderator': Icons.gavel_outlined,
    'admin': Icons.shield_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final role = profile['role'] as String? ?? 'passenger';
    final score = (profile['reputation_score'] as num?)?.toInt() ?? 0;
    final level = (profile['reputation_level'] as num?)?.toInt() ?? 0;
    final id = profile['id'] as String;
    final createdAt = profile['created_at'] as String?;
    final rank = ReputationRank.forScore(score);
    final isBanned = profile['is_banned'] == true;
    final banReason = profile['ban_reason'] as String?;
    final bannedAt = profile['banned_at'] as String?;
    final operatorId = profile['operator_id'] as String?;
    final operatorName = operatorId == null
        ? null
        : operators
            .firstWhere(
              (o) => o['id'] == operatorId,
              orElse: () => <String, dynamic>{'name': '—'},
            )['name']
            ?.toString();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        _sectionHeader(c, Icons.badge_outlined, 'Identidad'),
        const SizedBox(height: 8),
        GlassCard(
          blur: 12,
          fillOpacity: 0.04,
          borderRadius: 12,
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              _kv(c, 'ID', '${id.substring(0, 8)}...'),
              _kv(c, 'Rol', _roleLabels[role] ?? role),
              if (operatorName != null) _kv(c, 'Operadora', operatorName),
              _kv(c, 'Nivel BD', '$level'),
              _kv(c, 'Rango calc', rank.name),
              if (createdAt != null)
                _kv(c, 'Alta', createdAt.substring(0, 10)),
              if (isBanned) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB71C1C).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: const Color(0xFFB71C1C)
                            .withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.block,
                              size: 14, color: Color(0xFFB71C1C)),
                          const SizedBox(width: 6),
                          Text('USUARIO BANEADO',
                              style: GoogleFonts.ibmPlexMono(
                                fontSize: 11,
                                color: const Color(0xFFB71C1C),
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              )),
                        ],
                      ),
                      if (bannedAt != null) ...[
                        const SizedBox(height: 4),
                        Text('Desde: ${bannedAt.substring(0, 10)}',
                            style: TransitTypography.bodySmall(c.textMid)),
                      ],
                      if (banReason != null && banReason.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text('Motivo: $banReason',
                            style:
                                TransitTypography.bodySmall(c.textHi)),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        _sectionHeader(c, Icons.swap_horiz, 'Cambiar rol'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final r in _roles)
              _selectableChip(
                icon: _roleIcons[r] ?? Icons.person_outline,
                label: _roleLabels[r] ?? r,
                selected: role == r,
                color: c.accent,
                c: c,
                onTap: () => _changeRole(context, r),
              ),
          ],
        ),
        const SizedBox(height: 20),
        _sectionHeader(c, Icons.military_tech_outlined, 'Setear rango'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final r in ReputationRank.values)
              _selectableChip(
                icon: r.icon,
                label: '${_capitalize(r.name)} · ${r.minScore}',
                selected: r == rank,
                color: r.color,
                c: c,
                onTap: () => _setRank(context, r),
              ),
          ],
        ),
        const SizedBox(height: 20),
        _sectionHeader(c, Icons.star_rounded, 'XP rápido'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
                child: _xpButton(c, '+50', Icons.add, c.stateOnTime,
                    () => _addXp(context, 50))),
            const SizedBox(width: 8),
            Expanded(
                child: _xpButton(c, '+500', Icons.add, c.stateOnTime,
                    () => _addXp(context, 500))),
            const SizedBox(width: 8),
            Expanded(
                child: _xpButton(c, '−50', Icons.remove, c.stateCancelled,
                    () => _addXp(context, -50))),
          ],
        ),
        const SizedBox(height: 8),
        _xpButton(
          c,
          'Reset a 0',
          Icons.refresh,
          c.stateCancelled,
          () => _setScore(context, 0, 0),
          fullWidth: true,
        ),
        const SizedBox(height: 20),
        _sectionHeader(c, Icons.gpp_bad_outlined, 'Estado de cuenta'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _xpButton(
                c,
                isBanned ? 'Desbanear' : 'Banear',
                isBanned ? Icons.lock_open_outlined : Icons.block,
                isBanned ? c.stateOnTime : const Color(0xFFB71C1C),
                () => _toggleBan(context, !isBanned),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _xpButton(
                c,
                'Eliminar',
                Icons.delete_forever,
                const Color(0xFFB71C1C),
                () => _confirmDelete(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _sectionHeader(TransitColorScheme c, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: c.accent),
        const SizedBox(width: 6),
        Text(text.toUpperCase(),
            style: GoogleFonts.ibmPlexMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: c.accent,
              letterSpacing: 1.5,
            )),
      ],
    );
  }

  Widget _kv(TransitColorScheme c, String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
              width: 100,
              child: Text(k,
                  style: TransitTypography.bodySmall(c.textMid))),
          Expanded(
              child: Text(v,
                  style: TransitTypography.bodySecondary(c.textHi))),
        ],
      ),
    );
  }

  Widget _selectableChip({
    required IconData icon,
    required String label,
    required bool selected,
    required Color color,
    required TransitColorScheme c,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.18) : c.bgRaised,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : c.border,
            width: selected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? color : c.textMid),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? color : c.textHi,
                )),
          ],
        ),
      ),
    );
  }

  Widget _xpButton(
    TransitColorScheme c,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool fullWidth = false,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: color.withValues(alpha: 0.4), width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                )),
          ],
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  Future<void> _changeRole(BuildContext context, String role) async {
    final messenger = ScaffoldMessenger.of(context);
    // driver y operatorAdmin requieren operadora.
    String? newOperatorId = profile['operator_id'] as String?;
    if (role == 'driver' || role == 'operatorAdmin') {
      newOperatorId = await _pickOperator(context, current: newOperatorId);
      if (newOperatorId == null) return; // canceló
    } else {
      // Otros roles → desvinculan la operadora si la tenían.
      newOperatorId = null;
    }
    try {
      await client.from('profiles').update({
        'role': role,
        'operator_id': newOperatorId,
      }).eq('id', userId);
      messenger.showSnackBar(SnackBar(content: Text('Rol → $role')));
      onChanged();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<String?> _pickOperator(BuildContext context,
      {String? current}) async {
    if (operators.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No hay operadoras activas registradas')),
      );
      return null;
    }
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: c.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: c.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Selecciona operadora',
                    style: TransitTypography.heading(c.textHi)),
                const SizedBox(height: 4),
                Text(
                  'Este rol requiere asociar al usuario a una operadora.',
                  style: TransitTypography.bodySecondary(c.textMid),
                ),
                const SizedBox(height: 12),
                for (final op in operators)
                  ListTile(
                    leading: Icon(Icons.apartment,
                        color: op['id'] == current ? c.accent : c.textMid),
                    title: Text(op['name'] as String,
                        style:
                            TransitTypography.bodyPrimary(c.textHi)),
                    trailing: op['id'] == current
                        ? Icon(Icons.check, color: c.accent)
                        : null,
                    onTap: () =>
                        Navigator.of(ctx).pop(op['id'] as String),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _toggleBan(BuildContext context, bool ban) async {
    final messenger = ScaffoldMessenger.of(context);
    String? reason;
    if (ban) {
      reason = await showDialog<String>(
        context: context,
        builder: (ctx) {
          final ctrl = TextEditingController();
          return AlertDialog(
            title: const Text('Banear usuario'),
            content: TextField(
              controller: ctrl,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Motivo (opcional)',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(null),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () =>
                    Navigator.of(ctx).pop(ctrl.text.trim()),
                style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFB71C1C)),
                child: const Text('Banear'),
              ),
            ],
          );
        },
      );
      if (reason == null) return;
    }
    try {
      await client.rpc('admin_set_ban', params: {
        'p_user_id': userId,
        'p_banned': ban,
        'p_reason': reason ?? '',
      });
      messenger.showSnackBar(SnackBar(
          content: Text(ban ? 'Usuario baneado' : 'Usuario desbaneado')));
      onChanged();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: const Text(
            'Esta acción no se puede deshacer. Se borrará el perfil, sus rutas, su feedback y demás datos asociados. ¿Continuar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB71C1C)),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      // Encolar borrado de cuenta. La edge function `delete_user` se
      // encarga del cleanup en auth.users + cascada en public.
      await client.from('data_deletion_requests').insert({
        'user_id': userId,
        'status': 'requested',
        'requested_at': DateTime.now().toUtc().toIso8601String(),
      });
      try {
        await client.functions.invoke('delete_user',
            body: {'user_id': userId});
      } catch (_) {
        // Si la edge function no está desplegada, la solicitud queda
        // encolada en data_deletion_requests para procesarse offline.
      }
      messenger.showSnackBar(
          const SnackBar(content: Text('Eliminación solicitada')));
      onDeleted();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _addXp(BuildContext context, int delta) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await client
          .rpc('add_xp', params: {'p_user_id': userId, 'p_xp': delta});
      messenger.showSnackBar(SnackBar(
          content: Text('${delta >= 0 ? '+' : ''}$delta XP aplicado')));
      onChanged();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _setRank(BuildContext context, ReputationRank r) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
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

  Future<void> _setScore(
      BuildContext context, int score, int level) async {
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
// TAB 2 — RUTAS
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
        final createdAt = r['created_at'] as String?;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.push('/community/route/$id'),
            child: GlassCard(
              blur: 12,
              fillOpacity: 0.05,
              borderRadius: 12,
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _parseHex(colorHex),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: TransitTypography.bodyPrimary(c.textHi),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _badge(_routeStatusLabel(status),
                                _statusColor(c, status)),
                            _badge(_visibilityLabel(visibility), c.textMid),
                            if (createdAt != null)
                              _badge(createdAt.substring(0, 10), c.textLo),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.thumb_up_outlined,
                                size: 12, color: c.textMid),
                            const SizedBox(width: 4),
                            Text('$votes',
                                style: TransitTypography.bodySmall(
                                    c.textMid)),
                            const SizedBox(width: 12),
                            Icon(Icons.visibility_outlined,
                                size: 12, color: c.textMid),
                            const SizedBox(width: 4),
                            Text('$views',
                                style: TransitTypography.bodySmall(
                                    c.textMid)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: c.textLo),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _statusColor(TransitColorScheme c, String status) {
    switch (status) {
      case 'published':
      case 'community_approved':
        return c.stateOnTime;
      case 'review_pending':
        return c.stateDelay;
      case 'rejected':
      case 'reported':
        return c.stateCancelled;
      default:
        return c.textMid;
    }
  }

  String _routeStatusLabel(String s) => switch (s) {
        'draft' => 'Borrador',
        'published' => 'Publicada',
        'review_pending' => 'En revisión',
        'community_approved' => 'Aprobada',
        'rejected' => 'Rechazada',
        'reported' => 'Reportada',
        _ => s,
      };

  String _visibilityLabel(String s) => switch (s) {
        'private' => 'Privada',
        'public' => 'Pública',
        'unlisted' => 'No listada',
        'shared' => 'Compartida',
        _ => s,
      };

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border:
            Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Text(text,
          style: GoogleFonts.ibmPlexMono(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.5,
          )),
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
// TAB 3 — FEEDBACK
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
        final legacy =
            (f['proposed_change'] as Map?)?['legacy_route_code'];

        final statusColor = _statusColor(c, status);

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
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
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: statusColor.withValues(alpha: 0.5),
                            width: 0.5),
                      ),
                      child: Text(_feedbackStatusLabel(status).toUpperCase(),
                          style: GoogleFonts.ibmPlexMono(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                              letterSpacing: 1)),
                    ),
                    const SizedBox(width: 8),
                    Icon(_kindIcon(kind), size: 14, color: c.textMid),
                    const SizedBox(width: 4),
                    Text(_feedbackKindLabel(kind),
                        style: TransitTypography.bodySmall(c.textMid)),
                    const Spacer(),
                    if (createdAt != null)
                      Text(createdAt.substring(0, 10),
                          style: TransitTypography.bodySmall(c.textLo)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(desc,
                    style: TransitTypography.bodySecondary(c.textHi)),
                if (routeId != null || legacy != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.route_outlined,
                          size: 12, color: c.textLo),
                      const SizedBox(width: 4),
                      Text('Ruta: ${routeId ?? legacy}',
                          style: TransitTypography.bodySmall(c.textLo)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Color _statusColor(TransitColorScheme c, String status) {
    switch (status) {
      case 'applied':
      case 'accepted':
        return c.stateOnTime;
      case 'in_review':
        return c.stateDelay;
      case 'rejected':
      case 'duplicate':
        return c.stateCancelled;
      default:
        return c.textMid;
    }
  }

  IconData _kindIcon(String kind) {
    switch (kind) {
      case 'stop_change':
        return Icons.location_on_outlined;
      case 'schedule_error':
        return Icons.schedule;
      case 'info_correction':
        return Icons.edit_outlined;
      default:
        return Icons.help_outline;
    }
  }

  String _feedbackStatusLabel(String s) => switch (s) {
        'open' => 'Pendiente',
        'in_review' => 'En revisión',
        'applied' => 'Aplicado',
        'accepted' => 'Aceptado',
        'rejected' => 'Rechazado',
        'duplicate' => 'Duplicado',
        _ => s,
      };

  String _feedbackKindLabel(String k) => switch (k) {
        'stop_change' => 'Mejora de parada',
        'schedule_error' => 'Error de horario',
        'info_correction' => 'Corrección de info',
        'other' => 'Otro',
        _ => k,
      };
}
