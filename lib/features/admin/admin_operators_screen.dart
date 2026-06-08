import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../core/utils/app_logger.dart';
import '../../data/admin/admin_routes_repository.dart';
import '../../data/operator/domain/operator_repository.dart';
import '../../data/operator/operator_repository_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/models/operator_model.dart';
import '../../shared/models/user_role.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_card.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/role_gate.dart';
import '../../shared/widgets/shimmer_skeleton.dart';
import '../../shared/widgets/transit_app_bar.dart';
import 'widgets/operator_form_dialog.dart';

enum _OpSortMode { nameAsc, nameDesc, regionAsc, statusActiveFirst }
enum _OpStatusFilter { all, active, inactive }

class AdminOperatorsScreen extends ConsumerStatefulWidget {
  const AdminOperatorsScreen({super.key});

  @override
  ConsumerState<AdminOperatorsScreen> createState() =>
      _AdminOperatorsScreenState();
}

class _AdminOperatorsScreenState extends ConsumerState<AdminOperatorsScreen> {
  List<OperatorModel> _operators = [];
  String _filter = '';
  bool _loading = true;
  OperatorRepositoryError? _errorType;
  _OpStatusFilter _statusFilter = _OpStatusFilter.all;
  _OpSortMode _sort = _OpSortMode.statusActiveFirst;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadOperators();
  }

  Color? _hexToColor(String hex) {
    final clean = hex.trim().replaceFirst('#', '');
    if (clean.length != 6) return null;
    final v = int.tryParse(clean, radix: 16);
    return v == null ? null : Color(0xFF000000 | v);
  }

  List<OperatorModel> get _filteredOperators {
    final q = _filter.trim().toLowerCase();
    var list = _operators.where((o) {
      if (q.isNotEmpty &&
          !o.name.toLowerCase().contains(q) &&
          !o.slug.toLowerCase().contains(q) &&
          !o.region.toLowerCase().contains(q)) {
        return false;
      }
      return switch (_statusFilter) {
        _OpStatusFilter.active => o.isActive,
        _OpStatusFilter.inactive => !o.isActive,
        _OpStatusFilter.all => true,
      };
    }).toList();
    switch (_sort) {
      case _OpSortMode.nameAsc:
        list.sort((a, b) => a.name.compareTo(b.name));
      case _OpSortMode.nameDesc:
        list.sort((a, b) => b.name.compareTo(a.name));
      case _OpSortMode.regionAsc:
        list.sort((a, b) {
          final cmp = a.region.compareTo(b.region);
          return cmp != 0 ? cmp : a.name.compareTo(b.name);
        });
      case _OpSortMode.statusActiveFirst:
        list.sort((a, b) {
          if (a.isActive == b.isActive) return a.name.compareTo(b.name);
          return a.isActive ? -1 : 1;
        });
    }
    return list;
  }

  Future<void> _loadOperators() async {
    setState(() {
      _loading = true;
      _errorType = null;
    });

    try {
      final repo = ref.read(operatorRepositoryProvider);
      final operators = await repo.list();

      if (!mounted) return;
      setState(() {
        _operators = operators;
        _loading = false;
      });
    } on OperatorRepositoryException catch (e) {
      AppLogger.warn('AdminOperators', 'load failed', e);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorType = e.error;
      });
    } catch (e) {
      AppLogger.warn('AdminOperators', 'load failed', e);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorType = OperatorRepositoryError.unknown;
      });
    }
  }

  Future<void> _onCreate() async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<OperatorModel>(
      context: context,
      builder: (_) => const OperatorFormDialog(),
    );
    if (result == null || !mounted) return;

    try {
      final repo = ref.read(operatorRepositoryProvider);
      final created = await repo.create(result);
      _showSnack(l10n.adminOperatorsCreated);
      await _loadOperators();
      // Genera un código de un uso para que alguien se registre como
      // admin de esta operadora y luego pueda generar conductores.
      if (mounted) await _offerAdminCode(created.id, created.name);
    } catch (e) {
      AppLogger.warn('AdminOperators', 'create failed', e);
      if (mounted) {
        _showSnack('${l10n.adminOperatorsError}: $e');
      }
    }
  }

  /// Genera un código para que alguien se convierta en ADMIN de esta
  /// operadora. El admin elige si es de un solo uso o reutilizable (con
  /// caducidad). Quien lo canjee en "Activar" pasa a operator_admin de ella.
  Future<void> _offerAdminCode(String operatorId, String name) async {
    final opts = await _askCodeOptions(name);
    if (opts == null || !mounted) return;
    final String code;
    try {
      code = await ref.read(adminRoutesRepositoryProvider).createInvitationCode(
            operatorId: operatorId,
            kind: 'operator_admin',
            maxUses: opts.maxUses,
            expiresDays: opts.expiresDays,
          );
    } catch (e) {
      AppLogger.warn('AdminOperators', 'operator_admin code failed', e);
      if (mounted) _showSnack('No se pudo generar el código: $e');
      return;
    }
    if (!mounted) return;
    final c = TransitColorScheme.of(
        Theme.of(context).brightness == Brightness.dark);
    final modeLabel = opts.maxUses == 1
        ? 'un solo uso'
        : 'reutilizable (${opts.maxUses} usos)';
    final expLabel = opts.expiresDays > 0
        ? ' · caduca en ${opts.expiresDays} días'
        : ' · sin caducidad';
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.bgElevated,
        title: const Text('Código de admin de operadora'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Comparte este código ($modeLabel$expLabel). Quien lo '
                'introduzca en "Activar" se convertirá en admin de $name y '
                'podrá generar conductores y más admins.'),
            const SizedBox(height: 12),
            SelectableText(code,
                style: TransitTypography.heading(c.accent)
                    .copyWith(letterSpacing: 3, fontFamily: 'monospace')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              Navigator.pop(ctx);
            },
            child: const Text('Copiar y cerrar'),
          ),
        ],
      ),
    );
  }

  /// Pregunta el modo del código: un solo uso o reutilizable con caducidad.
  Future<_CodeOptions?> _askCodeOptions(String name) {
    final c = TransitColorScheme.of(
        Theme.of(context).brightness == Brightness.dark);
    return showModalBottomSheet<_CodeOptions>(
      context: context,
      backgroundColor: c.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        var single = true;
        var days = 30;
        var maxUses = 5;
        return StatefulBuilder(builder: (ctx, setSheet) {
          Widget choice(String label, bool value) => Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => setSheet(() => single = value),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: single == value
                          ? c.accent.withValues(alpha: 0.18)
                          : c.bgRaised,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: single == value ? c.accent : c.border,
                          width: single == value ? 1.4 : 0.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(label,
                        style: TransitTypography.bodyPrimary(
                            single == value ? c.accent : c.textHi)),
                  ),
                ),
              );
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
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
                          borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Código de admin · $name',
                      style: TransitTypography.heading(c.textHi)),
                  const SizedBox(height: 12),
                  Row(children: [
                    choice('Un solo uso', true),
                    const SizedBox(width: 8),
                    choice('Reutilizable', false),
                  ]),
                  if (!single) ...[
                    const SizedBox(height: 16),
                    Text('Usos máximos: $maxUses',
                        style: TransitTypography.bodyPrimary(c.textHi)),
                    Slider(
                      value: maxUses.toDouble(),
                      min: 2,
                      max: 50,
                      divisions: 48,
                      activeColor: c.accent,
                      label: '$maxUses',
                      onChanged: (v) => setSheet(() => maxUses = v.round()),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(days > 0 ? 'Caduca en: $days días' : 'Sin caducidad',
                      style: TransitTypography.bodyPrimary(c.textHi)),
                  Slider(
                    value: days.toDouble(),
                    min: 0,
                    max: 365,
                    divisions: 73,
                    activeColor: c.accent,
                    label: days > 0 ? '$days d' : 'sin',
                    onChanged: (v) => setSheet(() => days = v.round()),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: c.accent),
                      onPressed: () => Navigator.pop(
                          ctx,
                          _CodeOptions(
                            maxUses: single ? 1 : maxUses,
                            expiresDays: days,
                          )),
                      child: const Text('Generar código'),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Future<void> _onEdit(OperatorModel op) async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<OperatorModel>(
      context: context,
      builder: (_) => OperatorFormDialog(operator: op),
    );
    if (result == null || !mounted) return;

    try {
      final repo = ref.read(operatorRepositoryProvider);
      await repo.update(result);
      _showSnack(l10n.adminOperatorsUpdated);
      await _loadOperators();
    } catch (e) {
      AppLogger.warn('AdminOperators', 'update failed', e);
      if (mounted) {
        _showSnack('${l10n.adminOperatorsError}: $e');
      }
    }
  }

  Future<void> _onDelete(OperatorModel op) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.adminOperatorsDeleteConfirm),
        content: Text(op.name),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              MaterialLocalizations.of(ctx).cancelButtonLabel,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n.adminOperatorsDelete,
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final repo = ref.read(operatorRepositoryProvider);
      await repo.delete(op.id);
      _showSnack(l10n.adminOperatorsDeleted);
      await _loadOperators();
    } catch (e) {
      AppLogger.warn('AdminOperators', 'delete failed', e);
      if (mounted) {
        _showSnack('${l10n.adminOperatorsError}: $e');
      }
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                TransitAppBar(
                  title: l10n.adminOperatorsTitle,
                  actions: [
                    IconButton(
                      icon: Icon(Icons.add, color: c.accent),
                      tooltip: l10n.adminOperatorsCreate,
                      onPressed: _onCreate,
                    ),
                  ],
                ),
                Expanded(child: _buildContent(c, l10n)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(TransitColorScheme c, AppLocalizations l10n) {
    if (_loading) {
      return ShimmerSkeleton.list(
        context: context,
        count: 6,
        builder: () => ShimmerSkeleton.routeCard(context),
      );
    }

    if (_errorType != null) {
      final message = switch (_errorType!) {
        OperatorRepositoryError.denied => l10n.adminOperatorsErrorDenied,
        OperatorRepositoryError.network => l10n.adminOperatorsErrorNetwork,
        _ => l10n.adminOperatorsErrorUnknown,
      };
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ErrorCard(message, onRetry: _loadOperators),
        ),
      );
    }

    if (_operators.isEmpty) {
      return EmptyState(
        l10n.adminOperatorsEmpty,
        l10n.adminOperatorsEmpty,
        icon: Icons.business_outlined,
      );
    }

    final filtered = _filteredOperators;

    return Column(
      children: [
        _statsHeader(c),
        _searchBar(c, l10n),
        _filtersBar(c, l10n),
        const SizedBox(height: 8),
        if (filtered.isEmpty)
          Expanded(
            child: EmptyState(
              'Sin resultados',
              _filter.isEmpty
                  ? 'Ningún operador coincide con los filtros'
                  : 'Ningún operador coincide con "$_filter"',
              icon: Icons.search_off,
            ),
          )
        else
          Expanded(
            child: RefreshIndicator(
              color: c.accent,
              onRefresh: _loadOperators,
              child: _buildOperatorList(filtered, c, l10n),
            ),
          ),
      ],
    );
  }

  // ── Stats header ────────────────────────────────────────────
  Widget _statsHeader(TransitColorScheme c) {
    final total = _operators.length;
    final active = _operators.where((o) => o.isActive).length;
    final inactive = total - active;
    final regions = _operators.map((o) => o.region).toSet().length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
              child: _statPill(c, Icons.business, '$total', 'Total', c.accent)),
          const SizedBox(width: 8),
          Expanded(
              child: _statPill(c, Icons.check_circle_outline, '$active',
                  'Activos', const Color(0xFF4CAF50))),
          const SizedBox(width: 8),
          Expanded(
              child: _statPill(c, Icons.pause_circle_outline, '$inactive',
                  'Inactivos', c.textMid)),
          const SizedBox(width: 8),
          Expanded(
              child: _statPill(c, Icons.public, '$regions', 'Regiones',
                  const Color(0xFF2196F3))),
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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(value,
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: c.textHi,
                  )),
            ],
          ),
          const SizedBox(height: 2),
          Text(label,
              style: TransitTypography.bodySmall(c.textLo),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  // ── Search bar ──────────────────────────────────────────────
  Widget _searchBar(TransitColorScheme c, AppLocalizations l10n) {
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
                controller: _searchController,
                onChanged: (v) => setState(() => _filter = v),
                style: TransitTypography.bodyPrimary(c.textHi),
                decoration: InputDecoration(
                  hintText: 'Nombre, slug o región',
                  hintStyle: TransitTypography.bodySecondary(c.textMid),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            if (_filter.isNotEmpty)
              IconButton(
                icon: Icon(Icons.close, size: 16, color: c.textMid),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _filter = '');
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }

  // ── Filters bar (status + sort) ─────────────────────────────
  Widget _filtersBar(TransitColorScheme c, AppLocalizations l10n) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _filterChip(
            c,
            icon: Icons.list,
            label: 'Todos',
            selected: _statusFilter == _OpStatusFilter.all,
            color: c.accent,
            onTap: () =>
                setState(() => _statusFilter = _OpStatusFilter.all),
          ),
          const SizedBox(width: 6),
          _filterChip(
            c,
            icon: Icons.check_circle_outline,
            label: 'Activos',
            selected: _statusFilter == _OpStatusFilter.active,
            color: const Color(0xFF4CAF50),
            onTap: () =>
                setState(() => _statusFilter = _OpStatusFilter.active),
          ),
          const SizedBox(width: 6),
          _filterChip(
            c,
            icon: Icons.pause_circle_outline,
            label: 'Inactivos',
            selected: _statusFilter == _OpStatusFilter.inactive,
            color: c.textMid,
            onTap: () =>
                setState(() => _statusFilter = _OpStatusFilter.inactive),
          ),
          const SizedBox(width: 6),
          PopupMenuButton<_OpSortMode>(
            initialValue: _sort,
            position: PopupMenuPosition.under,
            onSelected: (v) => setState(() => _sort = v),
            itemBuilder: (_) => const [
              PopupMenuItem(
                  value: _OpSortMode.statusActiveFirst,
                  child: Text('Activos primero')),
              PopupMenuItem(
                  value: _OpSortMode.nameAsc, child: Text('Nombre A-Z')),
              PopupMenuItem(
                  value: _OpSortMode.nameDesc,
                  child: Text('Nombre Z-A')),
              PopupMenuItem(
                  value: _OpSortMode.regionAsc,
                  child: Text('Por región')),
            ],
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: c.bgRaised,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: c.border, width: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sort, size: 14, color: c.textMid),
                  const SizedBox(width: 4),
                  Text(_sortLabel(_sort),
                      style: TransitTypography.bodySmall(c.textHi)),
                  const SizedBox(width: 2),
                  Icon(Icons.arrow_drop_down, size: 16, color: c.textMid),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(
    TransitColorScheme c, {
    required IconData icon,
    required String label,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.18) : c.bgRaised,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? color : c.border,
              width: selected ? 1.2 : 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? color : c.textMid),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                  fontSize: 12,
                  color: selected ? color : c.textHi,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                )),
          ],
        ),
      ),
    );
  }

  String _sortLabel(_OpSortMode s) {
    return switch (s) {
      _OpSortMode.statusActiveFirst => 'Activos↑',
      _OpSortMode.nameAsc => 'A-Z',
      _OpSortMode.nameDesc => 'Z-A',
      _OpSortMode.regionAsc => 'Región',
    };
  }

  Widget _buildOperatorList(
      List<OperatorModel> operators, TransitColorScheme c, AppLocalizations l10n) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: operators.length,
      itemBuilder: (context, index) {
        final op = operators[index];
        final brand = _hexToColor(op.color) ?? c.accent;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _onEdit(op),
            child: GlassCard(
              blur: 12,
              fillOpacity: op.isActive ? 0.05 : 0.02,
              borderRadius: 12,
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Avatar circular con borde del color de marca
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: brand.withValues(
                          alpha: op.isActive ? 0.18 : 0.08),
                      border: Border.all(
                          color: op.isActive
                              ? brand
                              : brand.withValues(alpha: 0.4),
                          width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      op.shortName.isNotEmpty
                          ? op.shortName[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: brand,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                op.name,
                                style: TransitTypography.bodyPrimary(
                                  op.isActive ? c.textHi : c.textLo,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (op.isActive
                                        ? const Color(0xFF4CAF50)
                                        : c.textMid)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: (op.isActive
                                          ? const Color(0xFF4CAF50)
                                          : c.textMid)
                                      .withValues(alpha: 0.5),
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                op.isActive ? 'ACTIVO' : 'INACTIVO',
                                style: GoogleFonts.ibmPlexMono(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                  color: op.isActive
                                      ? const Color(0xFF4CAF50)
                                      : c.textMid,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _miniBadge(c,
                                icon: Icons.tag,
                                label: op.slug,
                                color: c.textMid),
                            if (op.region.isNotEmpty)
                              _miniBadge(c,
                                  icon: Icons.public,
                                  label: op.region,
                                  color: const Color(0xFF2196F3)),
                            _miniBadge(c,
                                icon: Icons.palette_outlined,
                                label: op.color.isEmpty
                                    ? '—'
                                    : op.color.toUpperCase(),
                                color: brand),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(Icons.vpn_key_outlined,
                        color: c.accent, size: 20),
                    tooltip: 'Generar código de admin',
                    onPressed: () => _offerAdminCode(op.id, op.name),
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline,
                        color: c.stateCancelled, size: 20),
                    tooltip: l10n.adminOperatorsDelete,
                    onPressed: () => _onDelete(op),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _miniBadge(TransitColorScheme c,
      {required IconData icon,
      required String label,
      required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              )),
        ],
      ),
    );
  }
}

/// Opciones para generar un codigo de admin de operadora.
class _CodeOptions {
  const _CodeOptions({required this.maxUses, required this.expiresDays});
  final int maxUses;
  final int expiresDays;
}
