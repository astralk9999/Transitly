import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../core/utils/app_logger.dart';
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
    if (q.isEmpty) return _operators;
    return _operators.where((o) {
      return o.name.toLowerCase().contains(q) ||
          o.slug.toLowerCase().contains(q) ||
          o.region.toLowerCase().contains(q);
    }).toList();
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
      await repo.create(result);
      _showSnack(l10n.adminOperatorsCreated);
      await _loadOperators();
    } catch (e) {
      AppLogger.warn('AdminOperators', 'create failed', e);
      if (mounted) {
        _showSnack('${l10n.adminOperatorsError}: $e');
      }
    }
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
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            onChanged: (v) => setState(() => _filter = v),
            style: TransitTypography.bodyPrimary(c.textHi),
            decoration: InputDecoration(
              hintText: 'Buscar por nombre, slug o región',
              hintStyle: TransitTypography.bodySecondary(c.textLo),
              prefixIcon: Icon(Icons.search, color: c.textLo, size: 20),
              filled: true,
              fillColor: c.bgRaised,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: c.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: c.border),
              ),
            ),
          ),
        ),
        if (filtered.isEmpty)
          Expanded(
            child: EmptyState(
              'Sin resultados',
              'Ningún operador coincide con "$_filter"',
              icon: Icons.search_off,
            ),
          )
        else
          Expanded(child: _buildOperatorList(filtered, c, l10n)),
      ],
    );
  }

  Widget _buildOperatorList(
      List<OperatorModel> operators, TransitColorScheme c, AppLocalizations l10n) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: operators.length,
      itemBuilder: (context, index) {
        final op = operators[index];
        final avatarColor = _hexToColor(op.color) ?? c.accent;
        return Padding(
          padding: EdgeInsets.only(bottom: index < operators.length - 1 ? 8 : 0),
          child: GlassCard(
            blur: 12,
            fillOpacity: op.isActive ? 0.05 : 0.02,
            borderRadius: 12,
            padding: const EdgeInsets.all(12),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: avatarColor.withValues(alpha: 0.12),
                child: Text(
                  op.shortName.isNotEmpty
                      ? op.shortName[0].toUpperCase()
                      : '?',
                  style: TransitTypography.bodyPrimary(avatarColor),
                ),
              ),
              title: Row(
                children: [
                  Flexible(
                    child: Text(
                      op.name,
                      style: TransitTypography.bodyPrimary(
                        op.isActive ? c.textHi : c.textLo,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!op.isActive) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: c.stateCancelled.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'INACTIVO',
                        style: TransitTypography.bodySmall(c.stateCancelled),
                      ),
                    ),
                  ],
                ],
              ),
              subtitle: Text(
                op.region.isNotEmpty
                    ? '${op.slug} · ${op.region}'
                    : op.slug,
                style: TransitTypography.bodySecondary(c.textMid),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: c.accent, size: 20),
                    tooltip: l10n.adminOperatorsEdit,
                    onPressed: () => _onEdit(op),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline,
                        color: c.stateCancelled, size: 20),
                    tooltip: l10n.adminOperatorsDelete,
                    onPressed: () => _onDelete(op),
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
