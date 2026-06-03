
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../core/utils/app_logger.dart';
import '../../data/auth/auth_repository.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../data/analytics/posthog_service.dart';
import '../../shared/widgets/smoke_background.dart';
import '../../shared/widgets/transit_button.dart';
import '../../shared/providers/auth_provider.dart';
import 'widgets/auth_field.dart';
import 'widgets/auth_submit_button.dart';

const _logTag = 'SignIn';

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

    final l10n = AppLocalizations.of(context);
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref
          .read(authRepositoryProvider)
          .signInWithEmail(_emailController.text, _passwordController.text);
      PostHogAnalyticsService.signin('email');
    } on AuthRepoException catch (e) {
      if (mounted) {
        final msg = e.error == AuthError.rateLimited && e.secondsLeft != null
            ? l10n.authErrorRateLimited(e.secondsLeft!)
            : e.message ?? l10n.authSignInError;
        setState(() => _error = msg);
      }
    } catch (e) {
      AppLogger.warn('SignIn', 'sign in error', e);
      if (mounted) setState(() => _error = l10n.authErrorConnection);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final l10n = AppLocalizations.of(context);

    // GoRouter no tiene refreshListenable; cuando Supabase autentica
    // (Google o email) el authStateProvider emite AuthAuthenticated pero
    // el redirect_guard no se ejecuta hasta que cambia la ruta. Esto
    // navega manualmente al home en cuanto detectamos el cambio.
    ref.listen<AsyncValue<AuthSessionState>>(authStateProvider, (prev, next) {
      final state = next.valueOrNull;
      if (state is AuthAuthenticated && mounted) {
        AppLogger.info(_logTag, 'auth detected → navigating /home/inicio');
        context.go('/home/inicio');
      }
    });

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
                      Text(l10n.authSignInSubtitle,
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
                        label: l10n.authEmail,
                        hint: l10n.authEmailHint,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? l10n.authRequired : null,
                      ),
                      const SizedBox(height: 16),
                      AuthField(
                        label: l10n.authPassword,
                        hint: l10n.authPasswordHint,
                        controller: _passwordController,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? l10n.authRequiredField : null,
                      ),
                      const SizedBox(height: 24),

                      AuthSubmitButton(
                        label: l10n.authSignInButton,
                        isLoading: _isLoading,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(l10n.authNoAccount,
                              style: TransitTypography.bodySecondary(
                                  c.textMid)),
                          TextButton(
                            onPressed: () => context.go('/sign-up'),
                            child: Text(l10n.authRegister,
                                style: TransitTypography.bodySecondary(
                                    c.accent)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      TextButton(
                        onPressed: () => context.push('/recover-password'),
                        child: Text(l10n.authForgotPassword,
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
                            child: Text(l10n.authOrContinue,
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
                        label: l10n.authGoogleButton,
                        onPressed: () async {
                          try {
                            await ref
                                .read(authRepositoryProvider)
                                .signInWithGoogle();
                          } on AuthRepoException catch (e) {
                            if (mounted) {
                              final msg = e.error == AuthError.rateLimited && e.secondsLeft != null
                                  ? l10n.authErrorRateLimited(e.secondsLeft!)
                                  : e.message;
                              setState(() => _error = msg);
                            }
                          } catch (e) {
                            AppLogger.warn('SignIn', 'Google sign in error', e);
                            if (mounted) {
                              setState(() =>
                                  _error = l10n.authErrorGoogle);
                            }
                          }
                        },
                        isPrimary: false,
                      ),
                      const SizedBox(height: 12),

                      TextButton(
                        onPressed: () => context.go('/magic-link'),
                        child: Text(l10n.authMagicLink,
                            style:
                                TransitTypography.bodySmall(c.accent)),
                      ),
                      const SizedBox(height: 20),

                      // Modo invitado destacado: para usuarios que quieren
                      // explorar antes de crear cuenta.
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: c.bgRaised.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: c.border.withValues(alpha: 0.4),
                              width: 0.8),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '¿Solo quieres explorar?',
                              style: TransitTypography.bodySecondary(
                                  c.textMid),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () => context.go('/home/inicio'),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 12),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.explore_outlined,
                                        size: 18, color: c.accent),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Continuar como invitado',
                                      style: TransitTypography.bodyPrimary(
                                              c.accent)
                                          .copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
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
