import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../core/utils/app_logger.dart';
import '../../data/auth/auth_repository.dart';
import '../../data/supabase/supabase_client_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/providers/user_provider.dart';
import '../../shared/widgets/transit_button.dart';
import '../../shared/providers/auth_provider.dart';

class ActivateDriverScreen extends ConsumerStatefulWidget {
  const ActivateDriverScreen({super.key});

  @override
  ConsumerState<ActivateDriverScreen> createState() =>
      _ActivateDriverScreenState();
}

class _ActivateDriverScreenState extends ConsumerState<ActivateDriverScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  String _formatCode(String value) {
    final clean = value.replaceAll('-', '').toUpperCase();
    if (clean.length <= 3) return clean;
    if (clean.length <= 7) return '${clean.substring(0, 3)}-${clean.substring(3)}';
    return '${clean.substring(0, 3)}-${clean.substring(3, 7)}-${clean.substring(7, clean.length > 9 ? 9 : clean.length)}';
  }

  Future<void> _activate() async {
    final l10n = AppLocalizations.of(context);
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _error = l10n.authActivateEnterCode);
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _success = null;
    });

    try {
      final client = ref.read(supabaseClientProvider);
      final session = client.auth.currentSession;
      if (session == null) {
        setState(() => _error = l10n.authActivateNeedSession);
        _isLoading = false;
        return;
      }

      final result = await client
          .rpc('claim_invitation_code', params: {'p_code': code});

      if (!mounted) return;
      if (result != null) {
        ref.read(isDriverModeProvider.notifier).state = true;
        // Sub-D + P1.5-06: refresca el perfil de Supabase para recoger el
        // nuevo rol antes de navegar.
        ref.invalidate(userProfileFromSupabaseProvider);
        // Detecta si el código promocionó a admin de operadora para llevar
        // al panel correcto (el mismo código sirve para ambos roles).
        String role = 'driver';
        try {
          final row = await client
              .from('profiles')
              .select('role')
              .eq('id', session.user.id)
              .maybeSingle();
          role = (row?['role'] as String?) ?? 'driver';
        } catch (_) {}
        setState(() => _success = l10n.authActivateSuccess);
        AppLogger.info('ActivateDriver', 'code claimed successfully role=$role');
        // Pequeño delay para que el usuario vea el mensaje de éxito.
        await Future<void>.delayed(const Duration(milliseconds: 800));
        if (!mounted) return;
        context.go(role == 'operator_admin' ? '/operator-admin' : '/driver');
      }
    } catch (e) {
      AppLogger.warn('ActivateDriver', 'code claim error', e);
      if (!mounted) return;
      final msg = e.toString().toLowerCase();
      if (msg.contains('not found') || msg.contains('no encontrado')) {
        setState(() => _error = l10n.authActivateCodeNotFound);
      } else if (msg.contains('expired') || msg.contains('expirado')) {
        setState(() => _error = l10n.authActivateCodeExpired);
      } else if (msg.contains('max_uses') || msg.contains('agotado')) {
        setState(() => _error = l10n.authActivateCodeDepleted);
      } else {
        setState(() => _error = l10n.authActivateError);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final l10n = AppLocalizations.of(context);

    final authState = ref.watch(authStateProvider).valueOrNull;
    final isAuth = authState is AuthAuthenticated;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.directions_bus, size: 64, color: Colors.white70),
                    const SizedBox(height: 16),
                    Text(l10n.authActivateDriverTitle,
                        style: TransitTypography.heading(c.textHi)),
                    const SizedBox(height: 8),
                    Text(
                      l10n.authActivateDriverHint,
                      style: TransitTypography.bodySecondary(c.textMid),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    if (!isAuth) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orangeAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          l10n.authActivateNeedLogin,
                          style: const TextStyle(color: Colors.orangeAccent),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (_error != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(_error!,
                            style: const TextStyle(color: Colors.redAccent)),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (_success != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: c.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(_success!,
                            style: TextStyle(color: c.accent)),
                      ),
                      const SizedBox(height: 16),
                    ],

                    TextFormField(
                      controller: _codeController,
                      enabled: isAuth && !_isLoading,
                      textAlign: TextAlign.center,
                      textCapitalization: TextCapitalization.characters,
                      style: TextStyle(
                        color: c.textHi,
                        fontSize: 24,
                        fontFamily: 'monospace',
                        letterSpacing: 4,
                      ),
                      maxLength: 11,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context).activateDriverCodeHint,
                        hintStyle: TextStyle(color: c.textLo, fontSize: 24, fontFamily: 'monospace', letterSpacing: 4),
                        counterText: '',
                        filled: true,
                        fillColor: c.bgSurface,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: c.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: c.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: c.accent, width: 2),
                        ),
                      ),
                      onChanged: (v) {
                        final formatted = _formatCode(v);
                        if (formatted != v) {
                          _codeController.value = TextEditingValue(
                            text: formatted,
                            selection: TextSelection.collapsed(offset: formatted.length),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    TransitButton(
                      label: l10n.authActivateButton,
                      isPrimary: isAuth,
                      onPressed: isAuth ? _activate : null,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
