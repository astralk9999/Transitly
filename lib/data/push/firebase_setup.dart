import 'package:firebase_core/firebase_core.dart';

class FirebaseSetup {
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    try {
      await Firebase.initializeApp();
      _initialized = true;
    } catch (_) {
      // Firebase not configured yet — push will be unavailable
      // App continues without push (graceful degradation)
    }
  }

  static bool get isAvailable => _initialized;
}
