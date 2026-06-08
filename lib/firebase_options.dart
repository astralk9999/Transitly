// ignore_for_file: public_member_api_docs

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDD_suD-cjJZb5D8BsdjSy-6QCwSRx7BOA',
    appId: '1:176890877189:android:6859d0db0a4e03be21536c',
    messagingSenderId: '176890877189',
    projectId: 'transitly-ee8cf',
    storageBucket: 'transitly-ee8cf.firebasestorage.app',
  );

  // Valores reales tomados de android/app/google-services.json (proyecto
  // transitly-ee8cf). En Android el runtime los lee del propio JSON vía el
  // plugin google-services; estos sirven de respaldo / referencia.
}
