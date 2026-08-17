import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return android;
      case TargetPlatform.linux:
        return android;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBHruvXF94Suc0dmjm_8NiBT3pH_JaEy2E',
    appId: '1:1050173012384:android:8f902195b1abf51a978cc5',
    messagingSenderId: '1050173012384',
    projectId: 'agroshare-f1f57',
    storageBucket: 'agroshare-f1f57.appspot.com',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBHruvXF94Suc0dmjm_8NiBT3pH_JaEy2E',
    appId: '1:1050173012384:web:8f902195b1abf51a978cc5',
    messagingSenderId: '1050173012384',
    projectId: 'agroshare-f1f57',
    storageBucket: 'agroshare-f1f57.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBHruvXF94Suc0dmjm_8NiBT3pH_JaEy2E',
    appId: '1:1050173012384:ios:8f902195b1abf51a978cc5',
    messagingSenderId: '1050173012384',
    projectId: 'agroshare-f1f57',
    storageBucket: 'agroshare-f1f57.appspot.com',
    iosBundleId: 'com.example.agroshare',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBHruvXF94Suc0dmjm_8NiBT3pH_JaEy2E',
    appId: '1:1050173012384:ios:8f902195b1abf51a978cc5',
    messagingSenderId: '1050173012384',
    projectId: 'agroshare-f1f57',
    storageBucket: 'agroshare-f1f57.appspot.com',
    iosBundleId: 'com.example.agroshare',
  );
}
