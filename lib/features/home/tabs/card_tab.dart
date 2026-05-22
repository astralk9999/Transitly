import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../data/nfc/nfc_card_service.dart';
import '../../../data/nfc/nfc_l10n.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/providers/nfc_provider.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_text.dart';
import '../../../shared/widgets/responsive_scaffold.dart';
import '../../../shared/widgets/transit_button.dart';
import '../widgets/nfc_scan_result_card.dart';

class CardTab extends ConsumerWidget {
  const CardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final nfcAvailable = ref.watch(nfcAvailableProvider);
    final scanState = ref.watch(nfcScanProvider);
    final padding = ResponsiveScaffold.screenPadding(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ContentConstraints(
        maxWidth: 600,
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.all(padding),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 8),
                    Semantics(
                      header: true,
                      child: Text(
                        'TARJETA NFC',
                        style: GoogleFonts.ibmPlexMono(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                          color: c.textMid,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    nfcAvailable.when(
                      loading: () => _buildLoading(c),
                      error: (_, __) => _buildUnsupported(c),
                      data: (available) {
                        if (!available) return _buildUnsupported(c);
                        return _buildNfcContent(context, ref, c, scanState);
                      },
                    ),
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoading(TransitColorScheme c) {
    return SizedBox(
      height: 200,
      child: Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: c.accent),
      ),
    );
  }

  Widget _buildUnsupported(TransitColorScheme c) {
    return GlassCard(
      blur: 24,
      fillOpacity: 0.08,
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        children: [
          Icon(Icons.nfc, size: 48, color: c.textLo),
          const SizedBox(height: 16),
          Text('NFC NO DISPONIBLE',
              style: TransitTypography.sectionTitle(c.textLo)),
          const SizedBox(height: 8),
          Text(
            'La lectura de tarjetas del Consorcio de Transportes solo '
            'esta disponible en dispositivos Android con NFC.',
            style: TransitTypography.bodySecondary(c.textMid),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNfcContent(BuildContext context, WidgetRef ref,
      TransitColorScheme c, NfcScanState scanState) {
    switch (scanState.status) {
      case NfcScanStatus.idle:
        return _buildIdle(context, ref, c, scanState);
      case NfcScanStatus.scanning:
        return _buildScanning(context, ref, c);
      case NfcScanStatus.success:
        return _buildSuccess(context, ref, c, scanState);
      case NfcScanStatus.error:
        return _buildError(context, ref, c, scanState);
      case NfcScanStatus.unsupported:
        return _buildUnsupported(c);
    }
  }

  Widget _buildIdle(BuildContext context, WidgetRef ref,
      TransitColorScheme c, NfcScanState scanState) {
    return Column(
      children: [
        GlassCard(
          blur: 28,
          fillOpacity: 0.08,
          borderRadius: 20,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 44),
          child: Column(
            children: [
              Icon(Icons.nfc, size: 56, color: c.accent),
              const SizedBox(height: 20),
              GradientText(
                'ACERCA TU TARJETA',
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
                gradient: c.gradientAccent,
              ),
              const SizedBox(height: 8),
              Text(
                'Coloca tu tarjeta del Consorcio de Transportes '
                'en la parte trasera del dispositivo',
                style: TransitTypography.bodySecondary(c.textMid),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TransitButton(
                label: 'ESCANEAR TARJETA',
                icon: Icons.contactless,
                onPressed: () =>
                    ref.read(nfcScanProvider.notifier).startScan(),
              ),
            ],
          ),
        ),
        if (scanState.scanHistory.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildHistory(c, scanState.scanHistory),
        ],
      ],
    );
  }

  Widget _buildScanning(
      BuildContext context, WidgetRef ref, TransitColorScheme c) {
    return GlassCard(
      blur: 28,
      fillOpacity: 0.10,
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: c.accent,
            ),
          ),
          const SizedBox(height: 24),
          GradientText(
            'LEYENDO TARJETA...',
            style: GoogleFonts.ibmPlexMono(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
            gradient: c.gradientAccent,
          ),
          const SizedBox(height: 8),
          Text(
            'Manten la tarjeta cerca del dispositivo',
            style: TransitTypography.bodySecondary(c.textMid),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TransitButton(
            label: AppLocalizations.of(context).actionCancel.toUpperCase(),
            isPrimary: false,
            isSmall: true,
            onPressed: () =>
                ref.read(nfcScanProvider.notifier).cancelScan(),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess(BuildContext context, WidgetRef ref,
      TransitColorScheme c, NfcScanState scanState) {
    final result = scanState.result!;

    return Column(
      children: [
        NfcScanResultCard(c: c, result: result),
        const SizedBox(height: 16),
        TransitButton(
          label: 'ESCANEAR DE NUEVO',
          isPrimary: false,
          icon: Icons.contactless,
          onPressed: () =>
              ref.read(nfcScanProvider.notifier).startScan(),
        ),
        if (scanState.scanHistory.length > 1) ...[
          const SizedBox(height: 24),
          _buildHistory(c, scanState.scanHistory.skip(1).toList()),
        ],
      ],
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref,
      TransitColorScheme c, NfcScanState scanState) {
    return Column(
      children: [
        GlassCard(
          blur: 24,
          fillOpacity: 0.08,
          borderRadius: 20,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 44, color: c.stateCancelled),
              const SizedBox(height: 12),
              Text(
                'ERROR DE LECTURA',
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: c.stateCancelled,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _resolveErrorMessage(context, scanState),
                style: TransitTypography.bodySecondary(c.textMid),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TransitButton(
                label: AppLocalizations.of(context).actionRetry.toUpperCase(),
                icon: Icons.refresh,
                onPressed: () =>
                    ref.read(nfcScanProvider.notifier).startScan(),
              ),
            ],
          ),
        ),
        if (scanState.scanHistory.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildHistory(c, scanState.scanHistory),
        ],
      ],
    );
  }

  Widget _buildHistory(TransitColorScheme c, List<NfcCardResult> history) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LECTURAS ANTERIORES',
          style: GoogleFonts.ibmPlexMono(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
            color: c.textMid,
          ),
        ),
        const SizedBox(height: 8),
        GlassCard(
          blur: 16,
          fillOpacity: 0.05,
          borderRadius: 14,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Column(
            children: history.map((scan) {
              final date =
                  '${scan.scannedAt.day.toString().padLeft(2, '0')}/${scan.scannedAt.month.toString().padLeft(2, '0')}';
              final time =
                  '${scan.scannedAt.hour.toString().padLeft(2, '0')}:${scan.scannedAt.minute.toString().padLeft(2, '0')}';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Text('$date $time',
                        style: TransitTypography.bodySecondary(c.textMid)),
                    const Spacer(),
                    Text(
                      '${scan.balance.toStringAsFixed(2)} \u20AC',
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: c.accent,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _resolveErrorMessage(BuildContext context, NfcScanState scanState) {
    final l10n = AppLocalizations.of(context);
    final kind = scanState.errorKind;
    if (kind != null) {
      return kind.localizedMessage(l10n, fallback: scanState.errorMessage);
    }
    return scanState.errorMessage ?? l10n.nfcErrorUnknown;
  }
}
