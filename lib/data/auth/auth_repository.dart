import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

enum AuthError {
  invalidCredentials,
  emailTaken,
  weakPassword,
  networkUnavailable,
  providerCancelled,
  emailNotVerified,
  rateLimited,
  unknown,
}

class AuthRepoException implements Exception {
  const AuthRepoException(this.error, [this.message, this.secondsLeft]);
  final AuthError error;
  final String? message;
  final int? secondsLeft;

  @override
  String toString() => 'AuthRepoException(${error.name}): ${message ?? ''}';
}

/// Estado de autenticación emitido por [AuthRepository.authState].
sealed class AuthSessionState {}

class AuthInitial extends AuthSessionState {}

class AuthLoading extends AuthSessionState {}

class AuthAuthenticated extends AuthSessionState {
  AuthAuthenticated(this.user);
  final User user;
}

class AuthUnauthenticated extends AuthSessionState {}

class AuthEmailVerificationPending extends AuthSessionState {
  AuthEmailVerificationPending(this.user);
  final User user;
}

/// Repositorio de autenticación. Única puerta de acceso a
/// `Supabase.auth` desde la capa de UI. Ningún widget accede a
/// `Supabase.instance.client.auth` directamente.
abstract class AuthRepository {
  Stream<AuthSessionState> get authState;

  User? get currentUser;

  Future<void> signInWithEmail(String email, String password);

  Future<void> signUpWithEmail(
    String email,
    String password,
    String displayName,
  );

  Future<void> signInWithGoogle();

  Future<void> sendMagicLink(String email);

  Future<void> recoverPassword(String email);

  Future<void> resendVerification();

  Future<void> signOut();
}
