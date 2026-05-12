import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../shared/widgets/smoke_background.dart';
import 'auth_provider.dart';
import 'auth_repository.dart';
import 'widgets/auth_submit_button.dart';

class EmailVerifyPendingScreen extends ConsumerStatefulWidget {
  const EmailVerifyPendingScreen({super.key});

  @override
  ConsumerState<EmailVerifyPendingScreen> createState() =>
      _EmailVerifyPendingScreenState();
}

class _EmailVerifyPendingScreenState
    extends ConsumerState<EmailVerifyPendingScreen> {
  bool _isResending = false;
  String? _feedback;

  Future<void> _resend() async {
    setState(() {
      _isResending = true;
      _feedback = null;
    });

    try {
      await ref.read(authRepositoryProvider).resendVerification();
      setState(() => _feedback = 'Email de verificación reenviado.');
    } on AuthRepoException catch (e) {
      setState(() => _feedback = e.message ?? 'Error al reenviar');
    } catch (_) {
      setState(() => _feedback = 'Error de conexión');
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

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
                    const Icon(Icons.mark_email_unread_outlined,
                        size: 64, color: Colors.white70),
                    const SizedBox(height: 16),
                    Text('Verifica tu email',
                        style: TransitTypography.heading(c.textHi)),
                    const SizedBox(height: 12),
                    Text(
                      'Te hemos enviado un email de verificación. '
                      'Revisa tu bandeja de entrada y haz clic en el enlace para continuar.',
                      style: TransitTypography.bodySecondary(c.textMid),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    if (_feedback != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: c.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(_feedback!,
                            style: TextStyle(color: c.accent)),
                      ),
                      const SizedBox(height: 16),
                    ],

                    AuthSubmitButton(
                      label: 'REENVIAR EMAIL',
                      isLoading: _isResending,
                      onPressed: _resend,
                    ),
                    const SizedBox(height: 16),

                    TextButton(
                      onPressed: () {
                        ref.read(authRepositoryProvider).signOut();
                        if (context.mounted) context.go('/sign-in');
                      },
                      child: Text('Cerrar sesión y volver',
                          style: TransitTypography.bodySmall(c.textMid)),
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
