import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'No Web Firebase configuration provided',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB1rMRlnn-toQPaqDfQTkdP8ywD_bQYUb8',
    appId: '1:397493191030:android:756ebd60de94a56c23ba57',
    messagingSenderId: '397493191030',
    projectId: 'qoldas-7c44b',
    storageBucket: 'qoldas-7c44b.appspot.com',
  );
}