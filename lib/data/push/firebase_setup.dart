import 'package:firebase_core/firebase_core.dart';

import '../../core/utils/app_logger.dart';

class FirebaseSetup {
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    try {
      await Firebase.initializeApp();
      _initialized = true;
    } catch (e) {
      AppLogger.warn('FirebaseSetup', 'Firebase init failed; push unavailable', e);
    }
  }

  static bool get isAvailable => _initialized;
}
