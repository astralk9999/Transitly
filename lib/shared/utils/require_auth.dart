import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/generated/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../../data/auth/auth_repository.dart';

Future<bool> requireAuth(
  BuildContext context,
  WidgetRef ref, {
  String? action,
}) async {
  final authState = ref.read(authStateProvider).valueOrNull;
  if (authState is AuthAuthenticated) return true;

  final l10n = AppLocalizations.of(context);
  final message = action != null
      ? l10n.requireAuthAction(action)
      : l10n.requireAuthGeneric;

  if (!context.mounted) return false;

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: l10n.actionSignIn,
          onPressed: () => context.push('/signin'),
        ),
      ),
    );
  return false;
}
