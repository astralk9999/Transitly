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
    apiKey: 'AIzaSyD-placeholder-key',
    appId: '1:000000000000:android:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'transitly-ee8cf',
    storageBucket: 'transitly-ee8cf.firebasestorage.app',
  );

  // TODO: ejecutar `dart run flutterfire_cli configure --project=transitly-ee8cf --platforms=android`
  // tras hacer `firebase login` manualmente. Sustituir los placeholders de arriba
  // por los valores reales generados.
}
