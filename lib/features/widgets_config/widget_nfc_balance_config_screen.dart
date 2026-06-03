import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/providers/nfc_provider.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/transit_button.dart';

class WidgetNfcBalanceConfigScreen extends ConsumerWidget {
  const WidgetNfcBalanceConfigScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final l10n = AppLocalizations.of(context);
    final nfc = ref.watch(nfcScanProvider);
    final hasBalance = nfc.result != null;

    return Scaffold(
      backgroundColor: c.bgRoot,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.textHi),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.widgetsConfigNfc, style: TransitTypography.heading(c.textHi)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlassCard(
              blur: 16,
              fillOpacity: 0.05,
              borderRadius: 14,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.credit_card, size: 48, color: c.accent),
                  const SizedBox(height: 12),
                  Text(
                    hasBalance
                        ? '${nfc.result!.balance.toStringAsFixed(2)} €'
                        : '--,-- €',
                    style: TransitTypography.displayNumber(c.textHi),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasBalance ? 'Último escaneo' : 'Sin lecturas',
                    style: TransitTypography.bodySmall(c.textMid),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'El saldo se actualiza automáticamente al escanear tu tarjeta NFC.',
              style: TransitTypography.bodySecondary(c.textMid),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TransitButton(
                label: l10n.widgetsConfigScanNow,
                onPressed: () => context.go('/home/tarjeta'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
