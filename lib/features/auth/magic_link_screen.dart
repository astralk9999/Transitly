import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../shared/widgets/smoke_background.dart';
import 'auth_provider.dart';
import 'auth_repository.dart';
import 'widgets/auth_field.dart';
import 'widgets/auth_submit_button.dart';

class MagicLinkScreen extends ConsumerStatefulWidget {
  const MagicLinkScreen({super.key});

  @override
  ConsumerState<MagicLinkScreen> createState() => _MagicLinkScreenState();
}

class _MagicLinkScreenState extends ConsumerState<MagicLinkScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Introduce un email válido');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref.read(authRepositoryProvider).sendMagicLink(email);
      setState(() => _sent = true);
    } on AuthRepoException catch (e) {
      setState(() => _error = e.message ?? 'Error al enviar el enlace');
    } catch (_) {
      setState(() => _error = 'Error de conexión');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                    Text('Enlace mágico',
                        style: TransitTypography.heading(c.textHi)),
                    const SizedBox(height: 8),
                    Text(
                      _sent
                          ? 'Revisa tu email. Te hemos enviado un enlace para acceder.'
                          : 'Te enviamos un enlace de acceso a tu email',
                      style: TransitTypography.bodySecondary(c.textMid),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

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

                    if (!_sent) ...[
                      AuthField(
                        label: 'Email',
                        hint: 'tu@email.com',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: 24),
                      AuthSubmitButton(
                        label: 'ENVIAR ENLACE',
                        isLoading: _isLoading,
                        onPressed: _submit,
                      ),
                    ],

                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => context.go('/sign-in'),
                      child: Text('Volver al inicio de sesión',
                          style: TransitTypography.bodySmall(c.accent)),
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
