
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../core/utils/app_logger.dart';
import '../../data/auth/auth_repository.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../data/analytics/posthog_service.dart';
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

    // La navegación tras login la hace go_router vía `refreshListenable`
    // (re-evalúa el redirect al cambiar el auth). NO navegamos a mano aquí:
    // con OAuth, el deep link ya dispara el redirect y una segunda navegación
    // manual montaba HomeShell dos veces → "Duplicate GlobalKey" / pantalla de
    // error. Una sola fuente de navegación evita el crash.

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo con resplandor (marca, como el splash/landing).
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [
                            c.accent.withValues(alpha: 0.30),
                            c.accent.withValues(alpha: 0.0),
                          ]),
                        ),
                        alignment: Alignment.center,
                        child: Image.asset(
                          isDark
                              ? 'assets/branding/transitly_logo_white_square.png'
                              : 'assets/branding/transitly_logo.png',
                          width: 76,
                          height: 76,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('Transitly',
                          style: TransitTypography.displayNumber(c.textHi)
                              .copyWith(fontSize: 28, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text(l10n.authSignInSubtitle,
                          style:
                              TransitTypography.bodySecondary(c.textMid),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 28),

                      // Tarjeta glass con el formulario.
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: c.bgSurface.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: c.border.withValues(alpha: 0.6), width: 0.8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [

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
                          Flexible(
                            child: Text(l10n.authNoAccount,
                                style: TransitTypography.bodySecondary(
                                    c.textMid)),
                          ),
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
                            // Flujo OAuth web: abre el navegador y vuelve por
                            // deep link. NO navegamos aquí (el await retorna al
                            // lanzar el navegador, antes del login); la
                            // navegación la hace `ref.listen(authStateProvider)`
                            // cuando llega AuthAuthenticated.
                            await ref
                                .read(authRepositoryProvider)
                                .signInWithGoogle();
                            AppLogger.info(_logTag,
                                'Google OAuth launched, waiting for deep-link callback');
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
                          ],
                        ),
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
                                    Flexible(
                                      child: Text(
                                        'Continuar como invitado',
                                        style: TransitTypography.bodyPrimary(
                                                c.accent)
                                            .copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
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
          ),
        ],
      ),
    );
  }
}
