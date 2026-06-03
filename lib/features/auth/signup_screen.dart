import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../core/utils/app_logger.dart';
import '../../data/auth/auth_repository.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/smoke_background.dart';
import '../../shared/providers/auth_provider.dart';
import 'widgets/auth_field.dart';
import 'widgets/auth_submit_button.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _birthdateController = TextEditingController();
  DateTime? _selectedBirthdate;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _birthdateController.addListener(() {
      final text = _birthdateController.text;
      final parts = text.split('/');
      if (parts.length == 3) {
        final day = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final year = int.tryParse(parts[2]);
        if (day != null && month != null && year != null) {
          _selectedBirthdate = DateTime(year, month, day);
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _birthdateController.dispose();
    super.dispose();
  }

  DateTime? _parseBirthdate() {
    if (_selectedBirthdate != null) return _selectedBirthdate;
    final parts = _birthdateController.text.split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }

  bool _isAtLeast16() {
    final birthdate = _parseBirthdate();
    if (birthdate == null) return false;
    final today = DateTime.now();
    var age = today.year - birthdate.year;
    if (today.month < birthdate.month ||
        (today.month == birthdate.month && today.day < birthdate.day)) {
      age--;
    }
    return age >= 16;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context);

    if (!_isAtLeast16()) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.signupAgeGateTitle),
          content: Text(l10n.signupAgeGateUnder16),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.actionClose),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref.read(authRepositoryProvider).signUpWithEmail(
            _emailController.text,
            _passwordController.text,
            _nameController.text,
          );
      if (mounted) {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.authVerifyTitle),
            content: Text(l10n.authVerifySignupSent(_emailController.text)),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  if (mounted) context.go('/sign-in');
                },
                child: Text(l10n.actionClose),
              ),
            ],
          ),
        );
      }
    } on AuthRepoException catch (e) {
      if (mounted) {
        final msg = e.error == AuthError.rateLimited && e.secondsLeft != null
            ? l10n.authErrorRateLimited(e.secondsLeft!)
            : e.message ?? l10n.authSignUpError;
        setState(() => _error = msg);
      }
    } catch (e) {
      AppLogger.warn('SignUp', 'sign up error', e);
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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.textHi),
          onPressed: () => context.pop(),
        ),
      ),
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
                      Text(l10n.authSignUpTitle,
                          style: TransitTypography.heading(c.textHi)),
                      const SizedBox(height: 8),
                      Text(l10n.authSignUpSubtitle,
                          style: TransitTypography.bodySecondary(c.textMid)),
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

                      AuthField(
                        label: l10n.authName,
                        hint: l10n.authNameHint,
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? l10n.authRequired : null,
                      ),
                      const SizedBox(height: 16),
                      AuthField(
                        label: l10n.signupAgeGateLabel,
                        hint: 'DD/MM/AAAA',
                        controller: _birthdateController,
                        keyboardType: TextInputType.none,
                        textInputAction: TextInputAction.next,
                        onTap: () async {
                          final now = DateTime.now();
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedBirthdate ??
                                DateTime(now.year - 16, 1, 1),
                            firstDate: DateTime(1900),
                            lastDate: now,
                            helpText: l10n.signupAgeGateLabel,
                          );
                          if (picked != null) {
                            setState(() {
                              _selectedBirthdate = picked;
                              _birthdateController.text =
                                  '${picked.day}/${picked.month}/${picked.year}';
                            });
                          }
                        },
                        validator: (_) {
                          if (_parseBirthdate() == null) {
                            return l10n.authRequired;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      AuthField(
                        label: l10n.authEmail,
                        hint: l10n.authEmailHint,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          if (v == null || v.isEmpty) return l10n.authRequired;
                          if (!v.contains('@')) return l10n.authInvalidEmail;
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      AuthField(
                        label: l10n.authPassword,
                        hint: l10n.authPasswordMinHint,
                        controller: _passwordController,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        validator: (v) {
                          if (v == null || v.isEmpty) return l10n.authRequiredField;
                          if (v.length < 6) return l10n.authMinChars;
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      AuthSubmitButton(
                        label: l10n.authSignUpButton,
                        isLoading: _isLoading,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(l10n.authAlreadyHaveAccount,
                              style:
                                  TransitTypography.bodySecondary(c.textMid)),
                          TextButton(
                            onPressed: () => context.go('/sign-in'),
                            child: Text(l10n.authSignInLink,
                                style: TransitTypography.bodySecondary(
                                    c.accent)),
                          ),
                        ],
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
