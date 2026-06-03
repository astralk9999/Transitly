import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show
        AuthChangeEvent,
        OAuthProvider,
        OtpType,
        SupabaseClient,
        User;

import '../../core/env.dart';
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
          // Email verification bypass: sistema de correos de Supabase
          // limitado en free tier. Todos los usuarios autentican directo.
          _stateController.add(AuthAuthenticated(user));
          final uidShort = user.id.length >= 8
              ? user.id.substring(0, 8)
              : user.id;
          AppLogger.info(_logTag,
              'signed in uid=$uidShort… (verification bypassed)');
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
    try {
      // CRITICAL: el plugin necesita el Web Client ID como `serverClientId`
      // para que devuelva idToken. Sin él, Google solo entrega accessToken
      // y Supabase rechaza el signInWithIdToken.
      final webClientId = Env.googleWebClientId;
      if (webClientId == null) {
        throw const AuthRepoException(
          AuthError.unknown,
          'GOOGLE_WEB_CLIENT_ID no configurado. Añádelo a dart_defines.json.',
        );
      }
      final googleSignIn = GoogleSignIn(
        scopes: const ['email', 'profile'],
        serverClientId: webClientId,
      );
      try {
        await googleSignIn.signOut();
      } catch (_) {
        AppLogger.debug(_logTag, 'Google signOut ignored (no prior session)');
      }
      final account = await googleSignIn.signIn();
      if (account == null) {
        throw const AuthRepoException(
          AuthError.providerCancelled,
          'Inicio de sesión con Google cancelado',
        );
      }
      final auth = await account.authentication;
      final idToken = auth.idToken;
      final accessToken = auth.accessToken;
      if (idToken == null) {
        throw const AuthRepoException(
          AuthError.providerCancelled,
          'Google no devolvió un id_token. Verifica el clientId en Google Cloud Console.',
        );
      }
      // Cambiar tokens de Google por sesión Supabase.
      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      AppLogger.info(_logTag, 'Google sign in OK');
    } on AuthRepoException {
      rethrow;
    } catch (e, st) {
      AppLogger.error(_logTag, 'Google sign in failed', e, st);
      throw AuthRepoException(
        AuthError.providerCancelled,
        e.toString(),
      );
    }
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
