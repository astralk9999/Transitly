import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:firebase_messaging/firebase_messaging.dart';
// Import completo (sin `show`) para que entren los métodos de EXTENSIÓN de
// supabase_flutter como `signInWithOAuth`, que lanzan el navegador.
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa
    show AuthException;

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

  // Último estado emitido: se reenvía a cualquier nuevo suscriptor en
  // su primer evento. Sin esto, Riverpod StreamProvider se quedaba en
  // AsyncLoading cuando se subscribía DESPUÉS del último emit (típico
  // tras Google sign-in: el emit ocurría antes de que el StreamProvider
  // estuviera escuchando).
  AuthSessionState _lastState = AuthUnauthenticated();
  AuthSessionState get lastState => _lastState;

  void _emit(AuthSessionState state) {
    _lastState = state;
    _stateController.add(state);
  }

  @override
  Stream<AuthSessionState> get authState async* {
    yield _lastState;
    yield* _stateController.stream;
  }

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
          _emit(AuthAuthenticated(user));
          final uidShort = user.id.length >= 8
              ? user.id.substring(0, 8)
              : user.id;
          AppLogger.info(_logTag,
              'signed in uid=$uidShort… (verification bypassed)');
        }
      } else if (event == AuthChangeEvent.signedOut) {
        _emit(AuthUnauthenticated());
        AppLogger.info(_logTag, 'signed out');
      } else if (event == AuthChangeEvent.userUpdated) {
        final user = session?.user;
        if (user != null) {
          _emit(AuthAuthenticated(user));
        }
      }
    });

    final session = _client.auth.currentSession;
    if (session?.user != null) {
      _emit(AuthAuthenticated(session!.user));
    } else {
      _emit(AuthUnauthenticated());
    }
  }

  @override
  Future<void> signInWithEmail(String email, String password) async {
    _emit(AuthLoading());
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
    _emit(AuthLoading());
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: <String, dynamic>{'display_name': displayName},
      );

      // Red de seguridad: si Supabase tiene "Confirm email" ON o config
      // legacy, signUp retorna user pero session=null. Sin SMTP propio
      // el usuario no recibe email → quedaría atrapado. Forzamos login
      // con las credenciales recién creadas para garantizar sesión activa.
      // Reactivar cuando se configure SMTP: ver docs/SUPABASE_SETUP.md.
      if (response.session == null && response.user != null) {
        AppLogger.info(_logTag,
            'signUp returned no session, attempting auto-login');
        try {
          await _client.auth.signInWithPassword(
            email: email.trim(),
            password: password,
          );
        } catch (e) {
          AppLogger.warn(_logTag,
              'auto-login after signup failed (confirm email may still be required)',
              e);
        }
      }
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
    // Flujo OAuth WEB de Supabase (navegador / Custom Tab). A diferencia del
    // google_sign_in nativo, NO depende del SHA-1 ni de un OAuth Android client
    // en Google Cloud, así que funciona en cualquier APK firmado por cualquiera
    // (debug, release, otra máquina). Supabase gestiona el OAuth con el client
    // configurado en su panel; al terminar, redirige al deep link y el SDK
    // completa la sesión, disparando onAuthStateChange → AuthAuthenticated.
    try {
      final bool launched;
      if (kIsWeb) {
        // En web NO hay deep link: el OAuth redirige a una URL HTTP de la
        // propia app (debe estar en Supabase → Auth → URL Configuration →
        // Redirect URLs). Volvemos a /app/, donde supabase_flutter detecta
        // el token en la URL y completa la sesión.
        launched = await _client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: '${Uri.base.origin}/app/',
        );
      } else {
        // Móvil: deep link + Chrome Custom Tab (se cierra sola al volver).
        launched = await _client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: 'transitly://login-callback',
          authScreenLaunchMode: LaunchMode.inAppBrowserView,
        );
      }
      AppLogger.info(_logTag, 'Google OAuth launched=$launched');
      // No emitimos estado aquí: signInWithOAuth solo abre el navegador. La
      // sesión llega al volver por el deep link (onAuthStateChange).
    } on supa.AuthException catch (e) {
      AppLogger.error(_logTag, 'Google OAuth AuthException: ${e.message}');
      throw AuthRepoException(AuthError.unknown, e.message);
    } catch (e, st) {
      AppLogger.error(_logTag, 'Google OAuth launch failed', e, st);
      throw AuthRepoException(AuthError.providerCancelled, e.toString());
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
