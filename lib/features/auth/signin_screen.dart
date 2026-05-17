import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../shared/widgets/smoke_background.dart';
import '../../../shared/widgets/transit_button.dart';
import 'auth_provider.dart';
import 'auth_repository.dart';
import 'widgets/auth_field.dart';
import 'widgets/auth_submit_button.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref
          .read(authRepositoryProvider)
          .signInWithEmail(_emailController.text, _passwordController.text);
    } on AuthRepoException catch (e) {
      setState(() => _error = e.message ?? 'Error al iniciar sesión');
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Transitly',
                          style: TransitTypography.heading(c.textHi)),
                      const SizedBox(height: 8),
                      Text('Inicia sesión para continuar',
                          style:
                              TransitTypography.bodySecondary(c.textMid)),
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
                              style: const TextStyle(
                                  color: Colors.redAccent)),
                        ),
                        const SizedBox(height: 16),
                      ],

                      AuthField(
                        label: 'Email',
                        hint: 'tu@email.com',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 16),
                      AuthField(
                        label: 'Contraseña',
                        hint: '••••••••',
                        controller: _passwordController,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Requerida' : null,
                      ),
                      const SizedBox(height: 24),

                      AuthSubmitButton(
                        label: 'INICIAR SESIÓN',
                        isLoading: _isLoading,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('¿No tienes cuenta?',
                              style: TransitTypography.bodySecondary(
                                  c.textMid)),
                          TextButton(
                            onPressed: () => context.go('/sign-up'),
                            child: Text('Regístrate',
                                style: TransitTypography.bodySecondary(
                                    c.accent)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      TextButton(
                        onPressed: () => context.push('/recover-password'),
                        child: Text('¿Olvidaste tu contraseña?',
                            style:
                                TransitTypography.bodySmall(c.textMid)),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                              child:
                                  Divider(color: c.border)),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12),
                            child: Text('o continúa con',
                                style: TransitTypography.bodySmall(
                                    c.textLo)),
                          ),
                          Expanded(
                              child:
                                  Divider(color: c.border)),
                        ],
                      ),
                      const SizedBox(height: 12),

                      TransitButton(
                        label: 'GOOGLE',
                        onPressed: () async {
                          try {
                            await ref
                                .read(authRepositoryProvider)
                                .signInWithGoogle();
                          } on AuthRepoException catch (e) {
                            if (mounted) {
                              setState(() => _error = e.message);
                            }
                          } catch (_) {
                            if (mounted) {
                              setState(() =>
                                  _error = 'Error de conexión con Google');
                            }
                          }
                        },
                        isPrimary: false,
                      ),
                      const SizedBox(height: 12),

                      TextButton(
                        onPressed: () => context.go('/magic-link'),
                        child: Text('Acceder con enlace mágico',
                            style:
                                TransitTypography.bodySmall(c.accent)),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
