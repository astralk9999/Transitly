import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../core/utils/app_logger.dart';
import '../../data/supabase/supabase_client_provider.dart';
import '../../shared/models/user_role.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/role_gate.dart';
import '../../shared/widgets/transit_app_bar.dart';

/// Sub P1.5-04: bandeja unificada con 4 tabs de solicitudes que el admin
/// debe procesar.
class AdminRequestsScreen extends ConsumerWidget {
  const AdminRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    return RoleGate(
      allow: const [UserRole.admin],
      child: DefaultTabController(
        length: 4,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              Column(
                children: [
                  const TransitAppBar(title: 'Solicitudes', transparent: true),
                  Material(
                    color: Colors.transparent,
                    child: TabBar(
                      isScrollable: true,
                      labelColor: c.accent,
                      unselectedLabelColor: c.textMid,
                      indicatorColor: c.accent,
                      tabs: const [
                        Tab(icon: Icon(Icons.delete_outline), text: 'RGPD'),
                        Tab(icon: Icon(Icons.route_outlined), text: 'Rutas'),
                        Tab(icon: Icon(Icons.business_outlined), text: 'Alta op.'),
                        Tab(icon: Icon(Icons.report_outlined), text: 'Escalado'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: const [
                        _RgpdTab(),
                        _RoutesTab(),
                        _OperatorAppsTab(),
                        _EscalatedTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tab base con estado loading + lista + error.
abstract class _RequestsTabState<T extends ConsumerStatefulWidget>
    extends ConsumerState<T> {
  List<Map<String, dynamic>>? rows;
  bool loading = true;
  String? error;

  Future<List<Map<String, dynamic>>> fetch();
  Widget buildRow(Map<String, dynamic> row, TransitColorScheme c);
  String get emptyMessage;
  IconData get emptyIcon;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
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
    } catch (e) {
      AppLogger.warn('AdminRequests', '${runtimeType.toString()} fetch failed', e);
      if (!mounted) return;
      setState(() {
        loading = false;
        error = 'No se pudieron cargar las solicitudes';
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error!, style: TransitTypography.bodyPrimary(c.textMid)),
            const SizedBox(height: 12),
            TextButton(onPressed: _load, child: const Text('Reintentar')),
          ],
        ),
      );
    }
    final list = rows ?? [];
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(emptyIcon, size: 64, color: c.textLo),
            const SizedBox(height: 12),
            Text(emptyMessage,
                style: TransitTypography.bodyPrimary(c.textMid)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
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
  }) async {
    final client = ref.read(supabaseClientProvider);
    final uid = client.auth.currentUser?.id;
    final payload = <String, dynamic>{
      ...values,
      if (uid != null) 'reviewed_by': uid,
      'reviewed_at': DateTime.now().toUtc().toIso8601String(),
    };
    await client.from(table).update(payload).eq(idColumn, idValue);
    AppLogger.info('AdminRequests', '$table $idValue → ${values['status']}');
    await _load();
  }
}

// ---------------------------------------------------------------------------
// Tab 1: Borrado RGPD
// ---------------------------------------------------------------------------
class _RgpdTab extends ConsumerStatefulWidget {
  const _RgpdTab();
  @override
  ConsumerState<_RgpdTab> createState() => _RgpdTabState();
}

class _RgpdTabState extends _RequestsTabState<_RgpdTab> {
  @override
  String get emptyMessage => 'Sin solicitudes RGPD pendientes';
  @override
  IconData get emptyIcon => Icons.delete_outline;

  @override
  Future<List<Map<String, dynamic>>> fetch() async {
    final client = ref.read(supabaseClientProvider);
    final rows = await client
        .from('data_deletion_requests')
        .select()
        .eq('status', 'requested')
        .order('created_at', ascending: false);
    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  @override
  Widget buildRow(Map<String, dynamic> row, TransitColorScheme c) {
    final userId = row['user_id'] as String?;
    return GlassCard(
      blur: 12,
      fillOpacity: 0.05,
      borderRadius: 12,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(userId ?? '?',
              style: TransitTypography.bodyPrimary(c.textHi)
                  .copyWith(fontFamily: 'monospace')),
          const SizedBox(height: 4),
          Text('Solicitado: ${row['created_at']}',
              style: TransitTypography.bodySmall(c.textLo)),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(
                onPressed: () => patch(
                  table: 'data_deletion_requests',
                  idColumn: 'id',
                  idValue: row['id'] as String,
                  values: {'status': 'rejected'},
                ),
                child: Text('Cancelar', style: TextStyle(color: c.textMid)),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => patch(
                  table: 'data_deletion_requests',
                  idColumn: 'id',
                  idValue: row['id'] as String,
                  values: {'status': 'approved'},
                ),
                style: FilledButton.styleFrom(backgroundColor: c.stateCancelled),
                child: const Text('Aprobar borrado'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 2: Sugerencias de rutas (route_suggestions pendientes)
// ---------------------------------------------------------------------------
class _RoutesTab extends ConsumerStatefulWidget {
  const _RoutesTab();
  @override
  ConsumerState<_RoutesTab> createState() => _RoutesTabState();
}

class _RoutesTabState extends _RequestsTabState<_RoutesTab> {
  @override
  String get emptyMessage => 'Sin sugerencias de rutas pendientes';
  @override
  IconData get emptyIcon => Icons.route_outlined;

  @override
  Future<List<Map<String, dynamic>>> fetch() async {
    final client = ref.read(supabaseClientProvider);
    final rows = await client
        .from('route_suggestions')
        .select()
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  @override
  Widget buildRow(Map<String, dynamic> row, TransitColorScheme c) {
    return GlassCard(
      blur: 12,
      fillOpacity: 0.05,
      borderRadius: 12,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(row['title']?.toString() ?? row['route_name']?.toString() ?? '?',
              style: TransitTypography.bodyPrimary(c.textHi)),
          const SizedBox(height: 4),
          if (row['description'] != null)
            Text(row['description'].toString(),
                style: TransitTypography.bodySmall(c.textMid)),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(
                onPressed: () => patch(
                  table: 'route_suggestions',
                  idColumn: 'id',
                  idValue: row['id'] as String,
                  values: {'status': 'rejected'},
                ),
                child: Text('Rechazar', style: TextStyle(color: c.textMid)),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => patch(
                  table: 'route_suggestions',
                  idColumn: 'id',
                  idValue: row['id'] as String,
                  values: {'status': 'approved'},
                ),
                style: FilledButton.styleFrom(backgroundColor: c.accent),
                child: const Text('Aprobar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 3: Alta de operador (operator_applications pendientes)
// ---------------------------------------------------------------------------
class _OperatorAppsTab extends ConsumerStatefulWidget {
  const _OperatorAppsTab();
  @override
  ConsumerState<_OperatorAppsTab> createState() => _OperatorAppsTabState();
}

class _OperatorAppsTabState extends _RequestsTabState<_OperatorAppsTab> {
  @override
  String get emptyMessage => 'Sin solicitudes de alta de operador';
  @override
  IconData get emptyIcon => Icons.business_outlined;

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
    return GlassCard(
      blur: 12,
      fillOpacity: 0.05,
      borderRadius: 12,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(row['operator_name']?.toString() ?? '?',
              style: TransitTypography.bodyPrimary(c.textHi)),
          const SizedBox(height: 4),
          Text(
            '${row['country'] ?? ''} · ${row['region'] ?? ''} · '
            '${row['contact_email'] ?? ''}',
            style: TransitTypography.bodySmall(c.textMid),
          ),
          if (row['justification'] != null) ...[
            const SizedBox(height: 6),
            Text(row['justification'].toString(),
                style: TransitTypography.bodySecondary(c.textLo)),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(
                onPressed: () => patch(
                  table: 'operator_applications',
                  idColumn: 'id',
                  idValue: row['id'] as String,
                  values: {'status': 'rejected'},
                ),
                child: Text('Rechazar', style: TextStyle(color: c.textMid)),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => patch(
                  table: 'operator_applications',
                  idColumn: 'id',
                  idValue: row['id'] as String,
                  values: {'status': 'approved'},
                ),
                style: FilledButton.styleFrom(backgroundColor: c.accent),
                child: const Text('Aprobar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 4: Incidencias y feedback escalado a admin
// ---------------------------------------------------------------------------
class _EscalatedTab extends ConsumerStatefulWidget {
  const _EscalatedTab();
  @override
  ConsumerState<_EscalatedTab> createState() => _EscalatedTabState();
}

class _EscalatedTabState extends _RequestsTabState<_EscalatedTab> {
  @override
  String get emptyMessage => 'Sin incidencias escaladas';
  @override
  IconData get emptyIcon => Icons.report_outlined;

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
    all.sort((a, b) =>
        (b['created_at']?.toString() ?? '').compareTo(a['created_at']?.toString() ?? ''));
    return all;
  }

  @override
  Widget buildRow(Map<String, dynamic> row, TransitColorScheme c) {
    final kind = row['_kind'] as String? ?? 'incident';
    final isIncident = kind == 'incident';
    return GlassCard(
      blur: 12,
      fillOpacity: 0.05,
      borderRadius: 12,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isIncident ? Icons.warning_amber : Icons.feedback_outlined,
                size: 16,
                color: c.accent,
              ),
              const SizedBox(width: 6),
              Text(isIncident ? 'Incidencia' : 'Feedback',
                  style: TransitTypography.bodySmall(c.accent)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            row['title']?.toString() ??
                row['description']?.toString() ??
                row['comment']?.toString() ??
                '?',
            style: TransitTypography.bodyPrimary(c.textHi),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Spacer(),
              FilledButton(
                onPressed: () => patch(
                  table: isIncident ? 'incidents' : 'route_feedback',
                  idColumn: 'id',
                  idValue: row['id'] as String,
                  values: {'escalated_to_admin': false},
                ),
                style: FilledButton.styleFrom(backgroundColor: c.accent),
                child: const Text('Marcar resuelto'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
