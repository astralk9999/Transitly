import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../data/geo/geo_providers.dart';
import '../../../shared/models/operator_model.dart';
import '../../../shared/utils/string_formatting.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/smoke_background.dart';

class CityPickerScreen extends ConsumerWidget {
  const CityPickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final operatorsAsync = ref.watch(activeOperatorsProvider);

    return Scaffold(
      backgroundColor: c.bgRoot,
      body: Stack(
        children: [
          Positioned.fill(
              child: SmokeBackground(color: c.accent, isDark: isDark)),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        color: c.textHi,
                        tooltip: AppLocalizations.of(context).actionClose,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 8),
                      Text(AppLocalizations.of(context).cityPickerSelectOperator,
                          style: TransitTypography.heading(c.textHi)),
                    ],
                  ),
                ),
                Expanded(
                  child: operatorsAsync.when(
                    data: (operators) {
                      if (operators.isEmpty) {
                        return Center(
                          child: Text(AppLocalizations.of(context).cityPickerErrorOperators,
                              style: TransitTypography.bodyPrimary(c.textMid)),
                        );
                        }
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: operators.length,
                        itemBuilder: (_, i) =>
                            _OperatorTile(c: c, operator: operators[i], ref: ref),
                      );
                    },
                    loading: () => const Center(
                        child: CircularProgressIndicator()),
                    error: (_, __) => Center(
                      child: Text(AppLocalizations.of(context).cityPickerErrorOperators,
                          style: const TextStyle(color: Colors.redAccent)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OperatorTile extends ConsumerWidget {
  const _OperatorTile({
    required this.c,
    required this.operator,
    required this.ref,
  });

  final TransitColorScheme c;
  final OperatorModel operator;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef _) {
    final activeOp = ref.watch(activeOperatorProvider);

    return GlassCard(
      blur: 12,
      fillOpacity: 0.05,
      borderRadius: 12,
      padding: const EdgeInsets.all(12),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: c.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              safeBadge(operator.shortName),
              style: TextStyle(
                color: c.accent,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ),
        title: Text(
          operator.name,
          style: TransitTypography.bodyPrimary(c.textHi),
        ),
        subtitle: Text(
          operator.region,
          style: TransitTypography.bodySmall(c.textMid),
        ),
        trailing: activeOp?.id == operator.id
            ? Icon(Icons.check_circle, color: c.accent)
            : null,
        onTap: () {
          ref.read(activeOperatorProvider.notifier).state = operator;
          persistActiveOperatorId(operator.id);
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

