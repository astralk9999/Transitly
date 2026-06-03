import '../../core/utils/app_logger.dart';
import 'auth_repository.dart';

const _logTag = 'Auth';

AuthRepoException mapAuthError(Exception e) {
  AppLogger.warn(_logTag, 'auth error', e);
  final msg = e.toString().toLowerCase();

  if (msg.contains('invalid login credentials')) {
    return const AuthRepoException(
        AuthError.invalidCredentials, 'Invalid credentials');
  }
  if (msg.contains('already been registered') ||
      msg.contains('already registered')) {
    return const AuthRepoException(
        AuthError.emailTaken, 'Email already registered');
  }
  if (msg.contains('password should be at least 6 characters')) {
    return const AuthRepoException(
        AuthError.weakPassword, 'Password must be at least 6 characters');
  }
  if (msg.contains('email not confirmed')) {
    return const AuthRepoException(
        AuthError.emailNotVerified, 'Email not verified');
  }
  final rateMatch = RegExp(r'for security purposes,? you can only request this after (\d+) seconds').firstMatch(msg);
  if (rateMatch != null) {
    final secs = int.parse(rateMatch.group(1)!);
    return AuthRepoException(AuthError.rateLimited, 'rate_limited', secs);
  }
  return AuthRepoException(AuthError.unknown, e.toString());
}
