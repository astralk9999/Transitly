import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../data/admin/admin_routes_repository.dart';
import '../../../data/supabase/supabase_client_provider.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/transit_app_bar.dart';
import '../../../shared/widgets/transit_button.dart';

/// Conductores de la operadora (admin de operadora ve SOLO los suyos; admin
/// global ve todos). Se leen de `profiles` (role='driver' + operator_id), no
/// de driver_assignments, para incluir también a los asignados por rol.
/// Incluye stats + búsqueda, como las demás pantallas de gestión.
class DriversScreen extends ConsumerStatefulWidget {
  const DriversScreen({super.key});

  @override
  ConsumerState<DriversScreen> createState() => _DriversScreenState();
}

class _DriversScreenState extends ConsumerState<DriversScreen> {
  List<Map<String, dynamic>>? _drivers;
  bool _loading = true;
  String? _error;
  String _search = '';
  String? _myOperatorId;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDrivers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final client = ref.read(supabaseClientProvider);
      final session = client.auth.currentSession;
      if (session == null) {
        setState(() {
          _loading = false;
          _drivers = [];
        });
        return;
      }
      final scope = await ref.read(manageScopeProvider.future);
      _myOperatorId = scope.operatorId;

      // Conductores = perfiles con rol 'driver'. El op-admin solo ve los de su
      // operadora; el admin global los ve todos.
      var q = client
          .from('profiles')
          .select('id, display_name, role, operator_id, created_at')
          .eq('role', 'driver');
      if (!scope.isAdmin && scope.operatorId != null) {
        q = q.eq('operator_id', scope.operatorId!);
      }
      final rows = await q.order('display_name');

      if (!mounted) return;
      setState(() {
        _drivers = (rows as List).cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = AppLocalizations.of(context).driversErrorLoading;
      });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return _drivers ?? const [];
    return (_drivers ?? const []).where((d) {
      final name = (d['display_name'] as String? ?? '').toLowerCase();
      return name.contains(q);
    }).toList();
  }

  Future<void> _revokeDriver(String driverId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final c = TransitColorScheme.of(isDark);
        return AlertDialog(
          backgroundColor: c.bgSurface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text('¿Revocar conductor?',
              style: TransitTypography.heading(c.textHi)),
          content: Text('El conductor perderá el acceso al modo conductor.',
              style: TransitTypography.bodySecondary(c.textMid)),
          actions: [
            TransitButton(
              label: AppLocalizations.of(ctx).actionCancel.toUpperCase(),
              isPrimary: false,
              isSmall: true,
              onPressed: () => Navigator.of(ctx).pop(false),
            ),
            TransitButton(
              label: AppLocalizations.of(ctx).actionRevoke.toUpperCase(),
              isDanger: true,
              isSmall: true,
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
          ],
        );
      },
    );
    if (confirm != true) return;

    try {
      final client = ref.read(supabaseClientProvider);
      // operator_id del conductor (el del op-admin, o el del propio driver).
      final operatorId = _myOperatorId ??
          (await client
              .from('profiles')
              .select('operator_id')
              .eq('id', driverId)
              .maybeSingle())?['operator_id'] as String?;
      if (operatorId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(AppLocalizations.of(context)
                  .operatorAdminMissingOperator)));
        }
        return;
      }
      await client.rpc('revoke_driver', params: {
        'p_driver_id': driverId,
        'p_operator_id': operatorId,
      });
      await _loadDrivers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text(AppLocalizations.of(context).driversErrorRevoking)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const TransitAppBar(title: 'Conductores', transparent: true),
      body: SafeArea(
        top: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _errorView(c)
                : Column(
                    children: [
                      _statsHeader(c),
                      _searchBar(c),
                      const SizedBox(height: 4),
                      Expanded(child: _list(c)),
                    ],
                  ),
      ),
    );
  }

  Widget _statsHeader(TransitColorScheme c) {
    final total = _drivers?.length ?? 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
              child: _statPill(c, Icons.people, '$total', 'Conductores',
                  c.accent)),
        ],
      ),
    );
  }

  Widget _statPill(TransitColorScheme c, IconData icon, String value,
      String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(value,
              style: TransitTypography.bodyPrimary(c.textHi)
                  .copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(width: 4),
          Text(label, style: TransitTypography.bodySmall(c.textLo)),
        ],
      ),
    );
  }

  Widget _searchBar(TransitColorScheme c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: c.bgRaised,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.border, width: 0.5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Icon(Icons.search, size: 18, color: c.textMid),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _search = v),
                style: TransitTypography.bodyPrimary(c.textHi),
                decoration: InputDecoration(
                  hintText: 'Buscar conductor',
                  hintStyle: TransitTypography.bodySecondary(c.textMid),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            if (_search.isNotEmpty)
              IconButton(
                icon: Icon(Icons.close, size: 16, color: c.textMid),
                onPressed: () {
                  _searchCtrl.clear();
                  setState(() => _search = '');
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _list(TransitColorScheme c) {
    final list = _filtered;
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 64, color: c.textLo),
            const SizedBox(height: 16),
            Text(
                _search.isNotEmpty
                    ? 'Sin resultados'
                    : 'No hay conductores asignados',
                style: TransitTypography.bodyPrimary(c.textMid)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: c.accent,
      onRefresh: _loadDrivers,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final d = list[index];
          final name = d['display_name'] as String? ?? 'Sin nombre';
          return GlassCard(
            blur: 12,
            fillOpacity: 0.05,
            borderRadius: 12,
            padding: const EdgeInsets.all(12),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: c.accent.withValues(alpha: 0.12),
                child: Text(
                  (name.isNotEmpty ? name[0] : '?').toUpperCase(),
                  style:
                      TextStyle(color: c.accent, fontWeight: FontWeight.w600),
                ),
              ),
              title: Text(name,
                  style: TransitTypography.bodyPrimary(c.textHi)),
              subtitle: Text(
                d['created_at'] != null
                    ? 'Alta ${(d['created_at'] as String).substring(0, 10)}'
                    : 'Conductor',
                style: TransitTypography.bodySmall(c.textMid),
              ),
              trailing: TransitButton(
                label: AppLocalizations.of(context).actionRevoke.toUpperCase(),
                isDanger: true,
                isSmall: true,
                onPressed: () => _revokeDriver(d['id'] as String),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _errorView(TransitColorScheme c) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          const SizedBox(height: 16),
          TransitButton(
            label: AppLocalizations.of(context).actionRetry.toUpperCase(),
            isSmall: true,
            onPressed: _loadDrivers,
          ),
        ],
      ),
    );
  }
}
