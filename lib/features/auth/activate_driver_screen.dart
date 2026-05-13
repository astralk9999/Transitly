import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/supabase/supabase_client_provider.dart';
import '../../../shared/providers/user_provider.dart';
import '../../../shared/widgets/smoke_background.dart';
import '../../../shared/widgets/transit_button.dart';
import 'auth_provider.dart';
import 'auth_repository.dart';

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
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _error = 'Introduce el código');
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
        setState(() => _error = 'Necesitas iniciar sesión primero');
        _isLoading = false;
        return;
      }

      final result = await client
          .rpc('claim_invitation_code', params: {'p_code': code});

      if (result != null) {
        ref.read(isDriverModeProvider.notifier).state = true;
        setState(() => _success = 'Bienvenido. Ya puedes usar el modo conductor.');
        AppLogger.info('ActivateDriver', 'code claimed successfully');
      }
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('not found') || msg.contains('no encontrado')) {
        setState(() => _error = 'Código no encontrado');
      } else if (msg.contains('expired') || msg.contains('expirado')) {
        setState(() => _error = 'El código ha expirado');
      } else if (msg.contains('max_uses') || msg.contains('agotado')) {
        setState(() => _error = 'El código ya no tiene usos disponibles');
      } else {
        setState(() => _error = 'Error al activar el código');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    final authState = ref.watch(authStateProvider).valueOrNull;
    final isAuth = authState is AuthAuthenticated;

    return Scaffold(
      backgroundColor: c.bgRoot,
      body: Stack(
        children: [
          Positioned.fill(
              child: SmokeBackground(color: c.accent, isDark: isDark)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.directions_bus, size: 64, color: Colors.white70),
                    const SizedBox(height: 16),
                    Text('Activar modo conductor',
                        style: TransitTypography.heading(c.textHi)),
                    const SizedBox(height: 8),
                    Text(
                      'Tu compañía te ha dado un código.\nIntrodúcelo aquí para activar el modo conductor.',
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
                        child: const Text(
                          'Necesitas iniciar sesión para activar el modo conductor.',
                          style: TextStyle(color: Colors.orangeAccent),
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
                        hintText: 'XXX-XXXX-XX',
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
                      label: 'ACTIVAR',
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
