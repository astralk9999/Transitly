import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/utils/app_logger.dart';
import '../../core/utils/sentry_setup.dart';
import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../shared/providers/auth_provider.dart';
import '../../data/auth/auth_repository.dart';
import '../../data/supabase/supabase_client_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/providers/privacy_consent_provider.dart';
import '../../core/env.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/gradient_text.dart';

class PrivacyScreen extends ConsumerStatefulWidget {
  const PrivacyScreen({super.key});

  @override
  ConsumerState<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends ConsumerState<PrivacyScreen> {
  bool _analytics = true;
  bool _crashReporting = true;
  bool _marketing = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadConsents);
  }

  Future<void> _loadConsents() async {
    final authState = ref.read(authStateProvider).valueOrNull;
    if (authState is! AuthAuthenticated) return;
    final repo = ref.read(privacyConsentRepositoryProvider);
    final consents = await repo.getConsents(authState.user.id);
    if (!mounted) return;
    setState(() {
      _analytics = consents['analytics'] ?? true;
      _crashReporting = consents['crash_reporting'] ?? true;
      _marketing = consents['marketing'] ?? false;
      _loaded = true;
    });
  }

  Future<void> _setConsent(String kind, bool value) async {
    final authState = ref.read(authStateProvider).valueOrNull;
    if (authState is! AuthAuthenticated) return;
    final repo = ref.read(privacyConsentRepositoryProvider);
    await repo.setConsent(authState.user.id, kind, value);

    // GDPR: la retirada del consentimiento debe ser tan efectiva como
    // otorgarlo. Aplicar el cambio en caliente, sin esperar a reiniciar.
    if (kind == 'analytics' && !value) {
      await Posthog().disable();
    }
    if (kind == 'crash_reporting' && !value) {
      await SentrySetup.close();
    }
    // Reconstruye analyticsServiceProvider (observa privacyConsentsProvider):
    // al re-otorgar 'analytics' volverá a instanciar PostHog (que llama
    // a enable()); al revocar, devolverá NoopAnalyticsService.
    if (!mounted) return;
    ref.invalidate(privacyConsentsProvider);
  }

  Future<void> _requestDataExport() async {
    final authState = ref.read(authStateProvider).valueOrNull;
    if (authState is! AuthAuthenticated) return;
    final l10n = AppLocalizations.of(context);
    try {
      final client = ref.read(supabaseClientProvider);
      await client.from('data_exports').insert({
        'user_id': authState.user.id,
        'status': 'queued',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.privacyDataExportRequested)),
        );
      }
    } catch (e, st) {
      AppLogger.error('Privacy', 'data export request failed', e, st);
    }
  }

  Future<void> _showDeletionRequestDialog() async {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.bgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(l10n.privacyDeleteConfirmTitle,
            style: TransitTypography.heading(c.textHi)),
        content: Text(l10n.privacyDeleteConfirmMessage,
            style: TransitTypography.bodySecondary(c.textMid)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.privacyDeleteConfirmCancel,
                style: TransitTypography.bodySecondary(c.textMid)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.privacyDeleteConfirmAction,
                style: TransitTypography.bodyPrimary(c.stateCancelled)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final client = ref.read(supabaseClientProvider);
      final authState = ref.read(authStateProvider).valueOrNull;
      if (authState is! AuthAuthenticated) return;
      await client.from('data_deletion_requests').insert({
        'user_id': authState.user.id,
        'status': 'requested',
        'requested_at': DateTime.now().toUtc().toIso8601String(),
        'scheduled_at':
            DateTime.now().toUtc().add(const Duration(days: 30)).toIso8601String(),
      });
      try {
        await client.functions.invoke('delete_user');
      } catch (e) {
        AppLogger.warn('Privacy', 'delete_user edge function invoke failed', e);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.privacyDeletionRequested)),
        );
      }
    } catch (e, st) {
      AppLogger.error('Privacy', 'data deletion request failed', e, st);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: c.bgRoot,
      appBar: AppBar(
        title: Text(l10n.privacyTitle),
        backgroundColor: Colors.transparent,
        foregroundColor: c.textHi,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Consents Section ──
          GlassCard(
            blur: 16,
            fillOpacity: 0.05,
            borderRadius: 14,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GradientText(
                  l10n.privacySectionConsents,
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                  gradient: c.gradientAccent,
                ),
                const SizedBox(height: 16),
                _ConsentToggle(
                  icon: Icons.analytics_outlined,
                  label: l10n.privacyConsentAnalytics,
                  description: l10n.privacyConsentAnalyticsDesc,
                  value: _analytics,
                  enabled: _loaded,
                  c: c,
                  onChanged: (v) {
                    setState(() => _analytics = v);
                    unawaited(_setConsent('analytics', v));
                  },
                ),
                const SizedBox(height: 12),
                Divider(
                    height: 1,
                    thickness: 0.5,
                    color: Colors.white.withValues(alpha: 0.06)),
                const SizedBox(height: 12),
                _ConsentToggle(
                  icon: Icons.bug_report_outlined,
                  label: l10n.privacyConsentCrashReporting,
                  description: l10n.privacyConsentCrashReportingDesc,
                  value: _crashReporting,
                  enabled: _loaded,
                  c: c,
                  onChanged: (v) {
                    setState(() => _crashReporting = v);
                    unawaited(_setConsent('crash_reporting', v));
                  },
                ),
                const SizedBox(height: 12),
                Divider(
                    height: 1,
                    thickness: 0.5,
                    color: Colors.white.withValues(alpha: 0.06)),
                const SizedBox(height: 12),
                _ConsentToggle(
                  icon: Icons.campaign_outlined,
                  label: l10n.privacyConsentMarketing,
                  description: l10n.privacyConsentMarketingDesc,
                  value: _marketing,
                  enabled: _loaded,
                  c: c,
                  onChanged: (v) {
                    setState(() => _marketing = v);
                    unawaited(_setConsent('marketing', v));
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── My Data Section ──
          GlassCard(
            blur: 16,
            fillOpacity: 0.05,
            borderRadius: 14,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GradientText(
                  l10n.privacySectionMyData,
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                  gradient: c.gradientAccent,
                ),
                const SizedBox(height: 16),
                _ActionTile(
                  icon: Icons.download_outlined,
                  label: l10n.privacyDownloadData,
                  c: c,
                  onTap: _requestDataExport,
                ),
                const SizedBox(height: 12),
                Divider(
                    height: 1,
                    thickness: 0.5,
                    color: Colors.white.withValues(alpha: 0.06)),
                const SizedBox(height: 12),
                _ActionTile(
                  icon: Icons.delete_outline,
                  label: l10n.privacyRequestDeletion,
                  c: c,
                  color: c.stateCancelled,
                  onTap: _showDeletionRequestDialog,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Legal Section ──
          GlassCard(
            blur: 16,
            fillOpacity: 0.05,
            borderRadius: 14,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GradientText(
                  l10n.privacySectionLegal,
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                  gradient: c.gradientAccent,
                ),
                const SizedBox(height: 16),
                _ActionTile(
                  icon: Icons.description_outlined,
                  label: l10n.privacyTermsOfService,
                  c: c,
                  onTap: () => launchUrl(Uri.parse(Env.tosUrl),
                      mode: LaunchMode.externalApplication),
                ),
                const SizedBox(height: 12),
                Divider(
                    height: 1,
                    thickness: 0.5,
                    color: Colors.white.withValues(alpha: 0.06)),
                const SizedBox(height: 12),
                _ActionTile(
                  icon: Icons.shield_outlined,
                  label: l10n.privacyPrivacyPolicy,
                  c: c,
                  onTap: () => launchUrl(Uri.parse(Env.privacyUrl),
                      mode: LaunchMode.externalApplication),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _ConsentToggle extends StatelessWidget {
  const _ConsentToggle({
    required this.icon,
    required this.label,
    required this.description,
    required this.value,
    required this.enabled,
    required this.c,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final String description;
  final bool value;
  final bool enabled;
  final TransitColorScheme c;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: c.textMid),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TransitTypography.bodyPrimary(c.textHi)),
              const SizedBox(height: 2),
              Text(description, style: TransitTypography.bodySmall(c.textLo)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Switch.adaptive(
          value: value,
          activeTrackColor: c.accent,
          onChanged: enabled ? onChanged : null,
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.c,
    this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final TransitColorScheme c;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final inkColor = color ?? c.accent;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: inkColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TransitTypography.bodyPrimary(inkColor)),
            ),
            Icon(Icons.chevron_right, size: 20, color: inkColor),
          ],
        ),
      ),
    );
  }
}
