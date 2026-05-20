import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

      setState(() {
        _codes = rows.cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = AppLocalizations.of(context).invitationCodesErrorLoading;
      });
    }
  }

  Future<void> _generateCode() async {
    final maxUses = await _showGenerateDialog();
    if (maxUses == null) return;

    try {
      final client = ref.read(supabaseClientProvider);
      final session = client.auth.currentSession;
      if (session == null) return;

      final result = await client.rpc('create_invitation_code', params: {
        'p_operator_id': '00000000-0000-0000-0000-000000000000',
        'p_max_uses': maxUses,
      });

      await _loadCodes();

      if (mounted && result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).inviteCodeGenerated(result.toString()))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).invitationCodesErrorGenerating)),
        );
      }
    }
  }

  Future<int?> _showGenerateDialog() async {
    int uses = 1;

    return showDialog<int>(
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
                children: [
                  Text('Número de usos: $uses',
                      style: TransitTypography.bodyPrimary(c.textHi)),
                  const SizedBox(height: 8),
                  Slider(
                    value: uses.toDouble(),
                    min: 1,
                    max: 100,
                    divisions: 99,
                    activeColor: c.accent,
                    label: '$uses',
                    onChanged: (v) => setDialogState(() => uses = v.round()),
                  ),
                ],
              ),
              actions: [
                TransitButton(
                  label: 'CANCELAR',
                  isPrimary: false,
                  isSmall: true,
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
                TransitButton(
                  label: 'GENERAR',
                  isSmall: true,
                  onPressed: () => Navigator.of(ctx).pop(uses),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _revokeCode(String code) async {
    try {
      final client = ref.read(supabaseClientProvider);
      await client.from('invitation_codes').delete().eq('code', code);
      await _loadCodes();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).invitationCodesErrorRevoking)),
        );
      }
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
              label: 'REINTENTAR',
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

        return GlassCard(
          blur: 12,
          fillOpacity: 0.05,
          borderRadius: 12,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      code['code'] as String,
                      style: TransitTypography.bodyPrimary(c.textHi)
                          .copyWith(fontFamily: 'monospace', letterSpacing: 2),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Usos: ${code['uses'] ?? 0}/${code['max_uses'] ?? 1}',
                      style: TransitTypography.bodySmall(c.textMid),
                    ),
                    if (isExpired)
                      Text('Expirado',
                          style: TextStyle(color: c.stateCancelled, fontSize: 12)),
                  ],
                ),
              ),
              TransitButton(
                label: 'REVOCAR',
                isDanger: true,
                isSmall: true,
                onPressed: () => _revokeCode(code['code'] as String),
              ),
            ],
          ),
        );
      },
    );
  }
}
