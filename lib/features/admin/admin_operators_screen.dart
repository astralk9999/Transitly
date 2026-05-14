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
import '../../shared/widgets/smoke_background.dart';
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
  bool _loading = true;
  OperatorRepositoryError? _errorType;

  @override
  void initState() {
    super.initState();
    _loadOperators();
  }

  Future<void> _loadOperators() async {
    setState(() {
      _loading = true;
      _errorType = null;
    });

    try {
      final repo = ref.read(operatorRepositoryProvider);
      final operators = await repo.list();

      setState(() {
        _operators = operators;
        _loading = false;
      });
    } on OperatorRepositoryException catch (e) {
      AppLogger.warn('AdminOperators', 'load failed', e);
      setState(() {
        _loading = false;
        _errorType = e.error;
      });
    } catch (e) {
      AppLogger.warn('AdminOperators', 'load failed', e);
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
        backgroundColor: c.bgRoot,
        body: Stack(
          children: [
            Positioned.fill(
              child: SmokeBackground(color: c.accent, isDark: isDark),
            ),
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

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _operators.length,
      itemBuilder: (context, index) {
        final op = _operators[index];
        return Padding(
          padding: EdgeInsets.only(bottom: index < _operators.length - 1 ? 8 : 0),
          child: GlassCard(
            blur: 12,
            fillOpacity: 0.05,
            borderRadius: 12,
            padding: const EdgeInsets.all(12),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: c.accent.withValues(alpha: 0.12),
                child: Text(
                  op.shortName.isNotEmpty
                      ? op.shortName[0].toUpperCase()
                      : '?',
                  style: TransitTypography.bodyPrimary(c.accent),
                ),
              ),
              title: Text(
                op.name,
                style: TransitTypography.bodyPrimary(c.textHi),
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
