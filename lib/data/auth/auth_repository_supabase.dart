import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show
        AuthChangeEvent,
        OtpType,
        SupabaseClient,
        User;

import '../../core/utils/app_logger.dart';
import '../../core/utils/sentry_setup.dart';
import 'auth_helpers.dart';
import 'auth_repository.dart';

class AuthRepositorySupabase implements AuthRepository {
  AuthRepositorySupabase(this._client);

  final SupabaseClient _client;

  static const _logTag = 'Auth';

  final StreamController<AuthSessionState> _stateController =
      StreamController<AuthSessionState>.broadcast();

  @override
  Stream<AuthSessionState> get authState => _stateController.stream;

  @override
  User? get currentUser => _client.auth.currentUser;

  void init() {
    _client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      final event = data.event;

      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.tokenRefreshed) {
        if (session?.user != null) {
          final user = session!.user;
          final emailVerified =
              user.emailConfirmedAt != null ||
              user.identities?.any((i) =>
                  i.identityData?['email_verified'] == true) == true;
          if (emailVerified) {
            _stateController.add(AuthAuthenticated(user));
            // PII: no loguear el UUID completo; prefijo suficiente para correlacionar.
            final uidShort = user.id.length >= 8
                ? user.id.substring(0, 8)
                : user.id;
            AppLogger.info(_logTag, 'signed in uid=$uidShort…');
          } else {
            _stateController.add(AuthEmailVerificationPending(user));
          }
        }
      } else if (event == AuthChangeEvent.signedOut) {
        _stateController.add(AuthUnauthenticated());
        AppLogger.info(_logTag, 'signed out');
      } else if (event == AuthChangeEvent.userUpdated) {
        final user = session?.user;
        if (user != null) {
          _stateController.add(AuthAuthenticated(user));
        }
      }
    });

    final session = _client.auth.currentSession;
    if (session?.user != null) {
      _stateController.add(AuthAuthenticated(session!.user));
    } else {
      _stateController.add(AuthUnauthenticated());
    }
  }

  @override
  Future<void> signInWithEmail(String email, String password) async {
    _stateController.add(AuthLoading());
    try {
      await SentrySetup.trace('auth.signIn', 'task', () => _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      ));
    } on AuthRepoException {
      rethrow;
    } catch (e, st) {
      if (e is Exception) {
        throw mapAuthError(e);
      }
      AppLogger.error(_logTag, 'signInWithEmail failed', e, st);
      throw const AuthRepoException(AuthError.unknown, 'Error inesperado');
    }
  }

  @override
  Future<void> signUpWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    _stateController.add(AuthLoading());
    try {
      await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: <String, dynamic>{'display_name': displayName},
      );
    } catch (e, st) {
      if (e is Exception) {
        throw mapAuthError(e);
      }
      AppLogger.error(_logTag, 'signUpWithEmail failed', e, st);
      throw const AuthRepoException(AuthError.unknown, 'Error inesperado');
    }
  }

  @override
  Future<void> signInWithGoogle() async {
    _stateController.add(AuthLoading());
    /// Google Sign-In requires platform setup (OAuth consent screen,
    /// redirect URIs in Supabase dashboard). Stub hasta F4.2.
    throw const AuthRepoException(
      AuthError.providerCancelled,
      'Google Sign-In pendiente de configuración de plataforma',
    );
  }

  @override
  Future<void> sendMagicLink(String email) async {
    try {
      await _client.auth.signInWithOtp(email: email.trim());
    } catch (e, st) {
      if (e is Exception) {
        throw mapAuthError(e);
      }
      AppLogger.error(_logTag, 'sendMagicLink failed', e, st);
      throw const AuthRepoException(AuthError.unknown, 'Error inesperado');
    }
  }

  @override
  Future<void> recoverPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email.trim());
    } catch (e, st) {
      if (e is Exception) {
        throw mapAuthError(e);
      }
      AppLogger.error(_logTag, 'recoverPassword failed', e, st);
      throw const AuthRepoException(AuthError.unknown, 'Error inesperado');
    }
  }

  @override
  Future<void> resendVerification() async {
    try {
      await _client.auth.resend(
        type: OtpType.signup,
        email: currentUser?.email,
      );
    } catch (e, st) {
      if (e is Exception) {
        throw mapAuthError(e);
      }
      AppLogger.error(_logTag, 'resendVerification failed', e, st);
      throw const AuthRepoException(AuthError.unknown, 'Error inesperado');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      try {
        await FirebaseMessaging.instance.deleteToken();
      } catch (_) {
        AppLogger.warn('Auth', 'FCM token delete failed — continuing sign out');
      }
      await _client.auth.signOut();
    } catch (e, st) {
      AppLogger.error(_logTag, 'signOut failed', e, st);
    }
  }

  void dispose() {
    _stateController.close();
  }
}
