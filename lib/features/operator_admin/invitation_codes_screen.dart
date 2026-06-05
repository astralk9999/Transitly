import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../data/supabase/supabase_client_provider.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/smoke_background.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/transit_button.dart';

class InvitationCodesScreen extends ConsumerStatefulWidget {
  const InvitationCodesScreen({super.key});

  @override
  ConsumerState<InvitationCodesScreen> createState() =>
      _InvitationCodesScreenState();
}

class _InvitationCodesScreenState extends ConsumerState<InvitationCodesScreen> {
  List<Map<String, dynamic>>? _codes;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCodes();
  }

  Future<void> _loadCodes() async {
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
          _codes = [];
        });
        return;
      }

      final rows = await client
          .from('invitation_codes')
          .select()
          .eq('created_by', session.user.id)
          .order('created_at', ascending: false);

      if (!mounted) return;
      setState(() {
        _codes = rows.cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = AppLocalizations.of(context).invitationCodesErrorLoading;
      });
    }
  }

  Future<void> _generateCode() async {
    final params = await _showGenerateDialog();
    if (params == null) return;

    try {
      final client = ref.read(supabaseClientProvider);
      final session = client.auth.currentSession;
      if (session == null) return;

      final operatorId = await _resolveOperatorId(client, session.user.id);
      if (operatorId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).operatorAdminMissingOperator)),
          );
        }
        return;
      }
      final result = await client.rpc('create_invitation_code', params: {
        'p_operator_id': operatorId,
        'p_max_uses': params.maxUses,
        'p_expires_days': params.expiresDays,
      });

      await _loadCodes();

      if (mounted && result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)
                .inviteCodeGenerated(result.toString())),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).invitationCodesErrorGenerating),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<_GenerateParams?> _showGenerateDialog() async {
    int uses = 1;
    int expiresDays = 30;

    return showDialog<_GenerateParams>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final c = TransitColorScheme.of(isDark);

        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: c.bgSurface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              title: Text('Generar código',
                  style: TransitTypography.heading(c.textHi)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Número de usos: $uses',
                      style: TransitTypography.bodyPrimary(c.textHi)),
                  const SizedBox(height: 4),
                  Slider(
                    value: uses.toDouble(),
                    min: 1,
                    max: 100,
                    divisions: 99,
                    activeColor: c.accent,
                    label: '$uses',
                    onChanged: (v) => setDialogState(() => uses = v.round()),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    expiresDays > 0
                        ? 'Caduca en $expiresDays días'
                        : 'Sin caducidad',
                    style: TransitTypography.bodyPrimary(c.textHi),
                  ),
                  const SizedBox(height: 4),
                  Slider(
                    value: expiresDays.toDouble(),
                    min: 0,
                    max: 90,
                    divisions: 90,
                    activeColor: c.accent,
                    label: expiresDays > 0 ? '$expiresDays' : 'nunca',
                    onChanged: (v) =>
                        setDialogState(() => expiresDays = v.round()),
                  ),
                ],
              ),
              actions: [
                TransitButton(
                  label: AppLocalizations.of(ctx).actionCancel.toUpperCase(),
                  isPrimary: false,
                  isSmall: true,
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
                TransitButton(
                  label: AppLocalizations.of(ctx).actionGenerate.toUpperCase(),
                  isSmall: true,
                  onPressed: () => Navigator.of(ctx).pop(
                    _GenerateParams(maxUses: uses, expiresDays: expiresDays),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _shareCode(String code) async {
    final operator = await _resolveOperatorName();
    final message = operator != null
        ? 'Te invito a unirte como conductor en $operator. '
            'Usa este código en la app Transitly: $code'
        : 'Te invito como conductor. Código: $code';
    await Share.share(message, subject: 'Código de invitación Transitly');
  }

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Código copiado: $code'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<String?> _resolveOperatorName() async {
    try {
      final client = ref.read(supabaseClientProvider);
      final session = client.auth.currentSession;
      if (session == null) return null;
      final operatorId = await _resolveOperatorId(client, session.user.id);
      if (operatorId == null) return null;
      final row = await client
          .from('operators')
          .select('name')
          .eq('id', operatorId)
          .maybeSingle();
      return row?['name'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> _revokeCode(String code) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Revocar código'),
        content: Text('¿Revocar el código $code? Los usos previos se preservan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Revocar',
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final client = ref.read(supabaseClientProvider);
      await client.rpc('revoke_invitation_code', params: {'p_code': code});
      await _loadCodes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Código revocado: $code'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).invitationCodesErrorRevoking),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<String?> _resolveOperatorId(dynamic client, String userId) async {
    try {
      final row = await client
          .from('profiles')
          .select('operator_id')
          .eq('id', userId)
          .maybeSingle();
      return row?['operator_id'] as String?;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    return Scaffold(
      backgroundColor: c.bgRoot,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _generateCode,
        backgroundColor: c.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(AppLocalizations.of(context).inviteGenerateCode),
      ),
      body: Stack(
        children: [
          Positioned.fill(
              child: SmokeBackground(color: c.accent, isDark: isDark)),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        color: c.textHi,
                        tooltip: AppLocalizations.of(context).actionBack,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 8),
                      Text('Códigos de invitación',
                          style: TransitTypography.heading(c.textHi)),
                    ],
                  ),
                ),
                Expanded(
                  child: _buildContent(c),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(TransitColorScheme c) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            const SizedBox(height: 16),
            TransitButton(
              label: AppLocalizations.of(context).actionRetry.toUpperCase(),
              isSmall: true,
              onPressed: _loadCodes,
            ),
          ],
        ),
      );
    }

    if (_codes == null || _codes!.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.vpn_key_outlined, size: 64, color: c.textLo),
            const SizedBox(height: 16),
            Text('No hay códigos generados',
                style: TransitTypography.bodyPrimary(c.textMid)),
            Text('Crea un código para invitar conductores',
                style: TransitTypography.bodySecondary(c.textLo)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _codes!.length,
      itemBuilder: (context, index) {
        final code = _codes![index];
        final isExpired = code['expires_at'] != null &&
            DateTime.parse(code['expires_at'] as String).isBefore(DateTime.now());

        final codeStr = code['code'] as String;
        final expiresAt = code['expires_at'] as String?;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GlassCard(
            blur: 12,
            fillOpacity: isExpired ? 0.02 : 0.05,
            borderRadius: 12,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        codeStr,
                        style: TransitTypography.bodyPrimary(
                          isExpired ? c.textLo : c.textHi,
                        ).copyWith(
                          fontFamily: 'monospace',
                          letterSpacing: 2,
                          fontSize: 16,
                          decoration: isExpired
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                    ),
                    if (isExpired)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: c.stateCancelled.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'EXPIRADO',
                          style: TransitTypography.bodySmall(c.stateCancelled),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Usos: ${code['uses'] ?? 0}/${code['max_uses'] ?? 1}'
                  '${expiresAt != null ? ' · ${_formatExpires(expiresAt)}' : ''}',
                  style: TransitTypography.bodySmall(c.textMid),
                ),
                if (!isExpired) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.copy, color: c.accent, size: 20),
                        tooltip: 'Copiar',
                        onPressed: () => _copyCode(codeStr),
                      ),
                      IconButton(
                        icon: Icon(Icons.share, color: c.accent, size: 20),
                        tooltip: 'Compartir',
                        onPressed: () => _shareCode(codeStr),
                      ),
                      const Spacer(),
                      TransitButton(
                        label: AppLocalizations.of(context)
                            .actionRevoke
                            .toUpperCase(),
                        isDanger: true,
                        isSmall: true,
                        onPressed: () => _revokeCode(codeStr),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatExpires(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = d.difference(now);
      if (diff.isNegative) return 'caducó';
      if (diff.inDays > 0) return 'caduca en ${diff.inDays}d';
      if (diff.inHours > 0) return 'caduca en ${diff.inHours}h';
      return 'caduca en <1h';
    } catch (_) {
      return '';
    }
  }
}

class _GenerateParams {
  const _GenerateParams({required this.maxUses, required this.expiresDays});
  final int maxUses;
  final int expiresDays;
}
