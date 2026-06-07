import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../core/utils/app_logger.dart';
import '../../data/supabase/supabase_client_provider.dart';
import '../../shared/models/user_role.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/role_gate.dart';
import '../../shared/widgets/transit_app_bar.dart';

/// Bandeja de solicitudes administrativas. 4 tabs con contadores
/// dinámicos y rediseño visual coherente con el resto del admin.
class AdminRequestsScreen extends ConsumerStatefulWidget {
  const AdminRequestsScreen({super.key});

  @override
  ConsumerState<AdminRequestsScreen> createState() =>
      _AdminRequestsScreenState();
}

class _AdminRequestsScreenState extends ConsumerState<AdminRequestsScreen> {
  int _rgpd = 0;
  int _routes = 0;
  int _ops = 0;
  int _escalated = 0;

  void _updateCount({int? rgpd, int? routes, int? ops, int? escalated}) {
    if (!mounted) return;
    setState(() {
      if (rgpd != null) _rgpd = rgpd;
      if (routes != null) _routes = routes;
      if (ops != null) _ops = ops;
      if (escalated != null) _escalated = escalated;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    return RoleGate(
      allow: const [UserRole.admin],
      child: DefaultTabController(
        length: 4,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: const TransitAppBar(
              title: 'Solicitudes', transparent: true),
          body: Column(
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                decoration: BoxDecoration(
                  color: c.bgRaised,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.border, width: 0.5),
                ),
                child: TabBar(
                  isScrollable: true,
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
                    _tabLabel('RGPD', _rgpd, Icons.delete_outline,
                        const Color(0xFFB71C1C)),
                    _tabLabel('RUTAS', _routes, Icons.route_outlined,
                        const Color(0xFF2196F3)),
                    _tabLabel('ALTA OP.', _ops, Icons.business_outlined,
                        const Color(0xFF9C27B0)),
                    _tabLabel('ESCALADO', _escalated,
                        Icons.report_outlined, const Color(0xFFFF9800)),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _RgpdTab(onCount: (n) => _updateCount(rgpd: n)),
                    _RoutesTab(onCount: (n) => _updateCount(routes: n)),
                    _OperatorAppsTab(onCount: (n) => _updateCount(ops: n)),
                    _EscalatedTab(
                        onCount: (n) => _updateCount(escalated: n)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabLabel(String text, int count, IconData icon, Color color) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(text),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Base para tabs: loading + error + lista + refresh.
abstract class _RequestsTabState<T extends ConsumerStatefulWidget>
    extends ConsumerState<T> {
  List<Map<String, dynamic>>? rows;
  bool loading = true;
  String? error;

  Future<List<Map<String, dynamic>>> fetch();
  Widget buildRow(Map<String, dynamic> row, TransitColorScheme c);
  String get emptyMessage;
  IconData get emptyIcon;
  void Function(int) get onCount;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await fetch();
      if (!mounted) return;
      setState(() {
        rows = data;
        loading = false;
      });
      onCount(data.length);
    } catch (e) {
      AppLogger.warn(
          'AdminRequests', '${runtimeType.toString()} fetch failed', e);
      if (!mounted) return;
      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: c.stateCancelled),
              const SizedBox(height: 12),
              Text('No se pudieron cargar las solicitudes',
                  style: TransitTypography.bodyPrimary(c.textHi),
                  textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(error!,
                  style: TransitTypography.bodySmall(c.textLo),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    final list = rows ?? [];
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(emptyIcon, size: 64, color: c.textLo),
              const SizedBox(height: 12),
              Text(emptyMessage,
                  style: TransitTypography.bodyPrimary(c.textMid),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refrescar'),
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: buildRow(list[i], c),
        ),
      ),
    );
  }

  Future<void> patch({
    required String table,
    required String idColumn,
    required String idValue,
    required Map<String, dynamic> values,
    bool includeReviewer = true,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final client = ref.read(supabaseClientProvider);
      final uid = client.auth.currentUser?.id;
      final payload = <String, dynamic>{
        ...values,
        if (includeReviewer && uid != null) 'reviewed_by': uid,
        if (includeReviewer)
          'reviewed_at': DateTime.now().toUtc().toIso8601String(),
      };
      await client.from(table).update(payload).eq(idColumn, idValue);
      AppLogger.info(
          'AdminRequests', '$table $idValue → ${values['status']}');
      messenger.showSnackBar(
          SnackBar(content: Text('Estado → ${values['status']}')));
      await _load();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}

// ─────────────────────────────────────────────────────────────────────
// Helper widgets compartidos
// ─────────────────────────────────────────────────────────────────────
Widget _cardHeader(TransitColorScheme c, IconData icon, String label,
    Color color, String? whenIso) {
  return Row(
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: color.withValues(alpha: 0.5), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(label.toUpperCase(),
                style: GoogleFonts.ibmPlexMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: 1)),
          ],
        ),
      ),
      const Spacer(),
      if (whenIso != null && whenIso.length >= 10)
        Text(whenIso.substring(0, 10),
            style: TransitTypography.bodySmall(c.textLo)),
    ],
  );
}

Widget _actionRow({
  required TransitColorScheme c,
  required String rejectLabel,
  required String acceptLabel,
  required VoidCallback onReject,
  required VoidCallback onAccept,
  Color? acceptColor,
  IconData? acceptIcon,
}) {
  return Row(
    children: [
      Expanded(
        child: OutlinedButton.icon(
          onPressed: onReject,
          icon: const Icon(Icons.close, size: 16),
          label: Text(rejectLabel),
          style: OutlinedButton.styleFrom(
            foregroundColor: c.textMid,
            side: BorderSide(color: c.border),
          ),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: FilledButton.icon(
          onPressed: onAccept,
          icon: Icon(acceptIcon ?? Icons.check, size: 16),
          label: Text(acceptLabel),
          style: FilledButton.styleFrom(
            backgroundColor: acceptColor ?? c.accent,
          ),
        ),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────
// Tab 1 — Borrado RGPD
// ─────────────────────────────────────────────────────────────────────
class _RgpdTab extends ConsumerStatefulWidget {
  const _RgpdTab({required this.onCount});
  final void Function(int) onCount;
  @override
  ConsumerState<_RgpdTab> createState() => _RgpdTabState();
}

class _RgpdTabState extends _RequestsTabState<_RgpdTab> {
  @override
  String get emptyMessage => 'Sin solicitudes RGPD pendientes';
  @override
  IconData get emptyIcon => Icons.delete_outline;
  @override
  void Function(int) get onCount => widget.onCount;

  @override
  Future<List<Map<String, dynamic>>> fetch() async {
    final client = ref.read(supabaseClientProvider);
    // data_deletion_requests usa `requested_at` (no created_at),
    // status TEXT con valor 'requested' para pendientes.
    final rows = await client
        .from('data_deletion_requests')
        .select()
        .eq('status', 'requested')
        .order('requested_at', ascending: false);
    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  @override
  Widget buildRow(Map<String, dynamic> row, TransitColorScheme c) {
    final userId = row['user_id'] as String?;
    final requestedAt = row['requested_at'] as String?;
    final scheduledAt = row['scheduled_at'] as String?;
    return GlassCard(
      blur: 12,
      fillOpacity: 0.05,
      borderRadius: 12,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(c, Icons.delete_outline, 'Borrado de cuenta',
              const Color(0xFFB71C1C), requestedAt),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.person_outline, size: 14, color: c.textMid),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  userId == null
                      ? 'Usuario desconocido'
                      : '${userId.substring(0, 8)}…',
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 12,
                    color: c.textHi,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (scheduledAt != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: c.textMid),
                const SizedBox(width: 6),
                Text(
                  'Programado: ${scheduledAt.substring(0, 10)}',
                  style: TransitTypography.bodySmall(c.textMid),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          _actionRow(
            c: c,
            rejectLabel: 'Cancelar',
            acceptLabel: 'Aprobar borrado',
            acceptColor: const Color(0xFFB71C1C),
            acceptIcon: Icons.delete_forever,
            onReject: () => patch(
              table: 'data_deletion_requests',
              idColumn: 'id',
              idValue: row['id'] as String,
              values: {'status': 'cancelled'},
              includeReviewer: false,
            ),
            onAccept: () => patch(
              table: 'data_deletion_requests',
              idColumn: 'id',
              idValue: row['id'] as String,
              values: {'status': 'completed'},
              includeReviewer: false,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Tab 2 — Sugerencias de rutas
// ─────────────────────────────────────────────────────────────────────
class _RoutesTab extends ConsumerStatefulWidget {
  const _RoutesTab({required this.onCount});
  final void Function(int) onCount;
  @override
  ConsumerState<_RoutesTab> createState() => _RoutesTabState();
}

class _RoutesTabState extends _RequestsTabState<_RoutesTab> {
  @override
  String get emptyMessage => 'Sin sugerencias de rutas pendientes';
  @override
  IconData get emptyIcon => Icons.route_outlined;
  @override
  void Function(int) get onCount => widget.onCount;

  @override
  Future<List<Map<String, dynamic>>> fetch() async {
    final client = ref.read(supabaseClientProvider);
    // route_suggestions.status enum: open / considered / accepted /
    // rejected. Pendientes = open + considered.
    final rows = await client
        .from('route_suggestions')
        .select()
        .inFilter('status', const ['open', 'considered'])
        .order('created_at', ascending: false);
    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  @override
  Widget buildRow(Map<String, dynamic> row, TransitColorScheme c) {
    final status = (row['status'] as String?) ?? 'open';
    final votes = (row['votes'] as num?)?.toInt() ?? 0;
    final motivation = row['motivation']?.toString() ?? '';
    final frequency = row['desired_frequency']?.toString();
    return GlassCard(
      blur: 12,
      fillOpacity: 0.05,
      borderRadius: 12,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(
              c,
              Icons.route_outlined,
              status == 'considered' ? 'En estudio' : 'Sugerencia',
              status == 'considered'
                  ? const Color(0xFFFF9800)
                  : const Color(0xFF2196F3),
              row['created_at'] as String?),
          const SizedBox(height: 10),
          Text(
            motivation.isEmpty ? '(sin descripción)' : motivation,
            style: TransitTypography.bodyPrimary(c.textHi),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _miniBadge(c,
                  icon: Icons.thumb_up_outlined,
                  label: '$votes votos',
                  color: c.accent),
              if (frequency != null && frequency.isNotEmpty)
                _miniBadge(c,
                    icon: Icons.schedule,
                    label: frequency,
                    color: c.textMid),
            ],
          ),
          const SizedBox(height: 12),
          _actionRow(
            c: c,
            rejectLabel: 'Rechazar',
            acceptLabel: 'Aceptar',
            onReject: () => patch(
              table: 'route_suggestions',
              idColumn: 'id',
              idValue: row['id'] as String,
              values: {'status': 'rejected'},
              includeReviewer: false,
            ),
            onAccept: () => patch(
              table: 'route_suggestions',
              idColumn: 'id',
              idValue: row['id'] as String,
              values: {'status': 'accepted'},
              includeReviewer: false,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Tab 3 — Alta de operador
// ─────────────────────────────────────────────────────────────────────
class _OperatorAppsTab extends ConsumerStatefulWidget {
  const _OperatorAppsTab({required this.onCount});
  final void Function(int) onCount;
  @override
  ConsumerState<_OperatorAppsTab> createState() => _OperatorAppsTabState();
}

class _OperatorAppsTabState extends _RequestsTabState<_OperatorAppsTab> {
  @override
  String get emptyMessage => 'Sin solicitudes de alta de operador';
  @override
  IconData get emptyIcon => Icons.business_outlined;
  @override
  void Function(int) get onCount => widget.onCount;

  @override
  Future<List<Map<String, dynamic>>> fetch() async {
    final client = ref.read(supabaseClientProvider);
    final rows = await client
        .from('operator_applications')
        .select()
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  @override
  Widget buildRow(Map<String, dynamic> row, TransitColorScheme c) {
    final name = row['operator_name']?.toString() ?? '?';
    final slug = row['operator_slug']?.toString();
    final country = row['country']?.toString() ?? '';
    final region = row['region']?.toString() ?? '';
    final email = row['contact_email']?.toString();
    final phone = row['contact_phone']?.toString();
    final justification = row['justification']?.toString();
    return GlassCard(
      blur: 12,
      fillOpacity: 0.05,
      borderRadius: 12,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(c, Icons.business_outlined, 'Alta de operador',
              const Color(0xFF9C27B0), row['created_at'] as String?),
          const SizedBox(height: 10),
          Text(name, style: TransitTypography.bodyPrimary(c.textHi)),
          if (slug != null && slug.isNotEmpty)
            Text('@$slug',
                style: TransitTypography.bodySmall(c.textLo)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              if (region.isNotEmpty)
                _miniBadge(c,
                    icon: Icons.public,
                    label: '$region · $country',
                    color: const Color(0xFF2196F3))
              else if (country.isNotEmpty)
                _miniBadge(c,
                    icon: Icons.public,
                    label: country,
                    color: const Color(0xFF2196F3)),
              if (email != null && email.isNotEmpty)
                _miniBadge(c,
                    icon: Icons.email_outlined,
                    label: email,
                    color: c.textMid),
              if (phone != null && phone.isNotEmpty)
                _miniBadge(c,
                    icon: Icons.phone_outlined,
                    label: phone,
                    color: c.textMid),
            ],
          ),
          if (justification != null && justification.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: c.bgRaised,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: c.border, width: 0.5),
              ),
              child: Text(justification,
                  style: TransitTypography.bodySecondary(c.textHi)),
            ),
          ],
          const SizedBox(height: 12),
          _actionRow(
            c: c,
            rejectLabel: 'Rechazar',
            acceptLabel: 'Aprobar',
            onReject: () => patch(
              table: 'operator_applications',
              idColumn: 'id',
              idValue: row['id'] as String,
              values: {'status': 'rejected'},
            ),
            onAccept: () => patch(
              table: 'operator_applications',
              idColumn: 'id',
              idValue: row['id'] as String,
              values: {'status': 'approved'},
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Tab 4 — Incidencias y feedback escalados
// ─────────────────────────────────────────────────────────────────────
class _EscalatedTab extends ConsumerStatefulWidget {
  const _EscalatedTab({required this.onCount});
  final void Function(int) onCount;
  @override
  ConsumerState<_EscalatedTab> createState() => _EscalatedTabState();
}

class _EscalatedTabState extends _RequestsTabState<_EscalatedTab> {
  @override
  String get emptyMessage => 'Sin incidencias escaladas';
  @override
  IconData get emptyIcon => Icons.report_outlined;
  @override
  void Function(int) get onCount => widget.onCount;

  @override
  Future<List<Map<String, dynamic>>> fetch() async {
    final client = ref.read(supabaseClientProvider);
    final inc = await client
        .from('incidents')
        .select()
        .eq('escalated_to_admin', true)
        .order('created_at', ascending: false);
    final fb = await client
        .from('route_feedback')
        .select()
        .eq('escalated_to_admin', true)
        .order('created_at', ascending: false);
    final all = <Map<String, dynamic>>[
      ...(inc as List<dynamic>).cast<Map<String, dynamic>>().map(
            (m) => {...m, '_kind': 'incident'},
          ),
      ...(fb as List<dynamic>).cast<Map<String, dynamic>>().map(
            (m) => {...m, '_kind': 'feedback'},
          ),
    ];
    all.sort((a, b) => (b['created_at']?.toString() ?? '')
        .compareTo(a['created_at']?.toString() ?? ''));
    return all;
  }

  @override
  Widget buildRow(Map<String, dynamic> row, TransitColorScheme c) {
    final kind = row['_kind'] as String? ?? 'incident';
    final isIncident = kind == 'incident';
    final desc = row['description']?.toString() ?? '?';
    final status = row['status']?.toString() ?? '';
    return GlassCard(
      blur: 12,
      fillOpacity: 0.05,
      borderRadius: 12,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(
              c,
              isIncident ? Icons.warning_amber : Icons.feedback_outlined,
              isIncident ? 'Incidencia' : 'Feedback',
              const Color(0xFFFF9800),
              row['created_at'] as String?),
          const SizedBox(height: 10),
          Text(desc,
              style: TransitTypography.bodyPrimary(c.textHi),
              maxLines: 5,
              overflow: TextOverflow.ellipsis),
          if (status.isNotEmpty) ...[
            const SizedBox(height: 8),
            _miniBadge(c,
                icon: Icons.flag_outlined,
                label: status,
                color: c.textMid),
          ],
          const SizedBox(height: 12),
          _actionRow(
            c: c,
            rejectLabel: 'Rechazar',
            acceptLabel: isIncident ? 'Resolver' : 'Aplicar',
            onReject: () => patch(
              table: isIncident ? 'incidents' : 'route_feedback',
              idColumn: 'id',
              idValue: row['id'] as String,
              values: {
                'status': 'rejected',
                'escalated_to_admin': false
              },
            ),
            onAccept: () => patch(
              table: isIncident ? 'incidents' : 'route_feedback',
              idColumn: 'id',
              idValue: row['id'] as String,
              values: {
                'status': isIncident ? 'resolved' : 'applied',
                'escalated_to_admin': false,
                if (isIncident)
                  'resolved_at': DateTime.now().toUtc().toIso8601String(),
                if (!isIncident)
                  'resolved_at': DateTime.now().toUtc().toIso8601String(),
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Mini badge compartido
// ─────────────────────────────────────────────────────────────────────
Widget _miniBadge(TransitColorScheme c,
    {required IconData icon,
    required String label,
    required Color color}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(4),
      border:
          Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 3),
        Flexible(
          child: Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              )),
        ),
      ],
    ),
  );
}
