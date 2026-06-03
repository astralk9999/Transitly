import 'package:shared_preferences/shared_preferences.dart';

class BootCanary {
  BootCanary._();

  static const _kLastBootStatus = 'boot.lastStatus';
  static const _kPendingSensitiveChange = 'boot.pendingSensitive';
  static const _kCrashStreak = 'boot.crashStreak';

  static Future<BootCanaryState> startBoot() async {
    final prefs = await SharedPreferences.getInstance();
    final lastStatus = prefs.getString(_kLastBootStatus);
    final pendingChange = prefs.getString(_kPendingSensitiveChange);
    final crashStreak = prefs.getInt(_kCrashStreak) ?? 0;

    await prefs.setString(_kLastBootStatus, 'BOOTING');

    return BootCanaryState(
      lastStatusWas: lastStatus,
      pendingChange: pendingChange,
      crashStreak: crashStreak,
    );
  }

  static Future<void> markStable() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastBootStatus, 'STABLE');
    await prefs.setInt(_kCrashStreak, 0);
    await prefs.remove(_kPendingSensitiveChange);
  }

  static Future<void> markPendingSensitive(String change) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPendingSensitiveChange, change);
  }

  static Future<void> incrementCrashStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final n = (prefs.getInt(_kCrashStreak) ?? 0) + 1;
    await prefs.setInt(_kCrashStreak, n);
  }
}

class BootCanaryState {
  const BootCanaryState({
    this.lastStatusWas,
    this.pendingChange,
    this.crashStreak = 0,
  });

  final String? lastStatusWas;
  final String? pendingChange;
  final int crashStreak;

  bool get crashed => lastStatusWas == 'BOOTING';
  bool get inRecoveryMode => crashStreak >= 2;
}
