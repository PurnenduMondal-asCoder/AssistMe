// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCbQyzuZrQNVPQ9EIc_ojx_j5L-O4RYYcQ',
    appId: '1:1019736121024:web:9b901f500b5b6910b29725',
    messagingSenderId: '1019736121024',
    projectId: 'assistant-655db',
    authDomain: 'assistant-655db.firebaseapp.com',
    storageBucket: 'assistant-655db.firebasestorage.app',
    measurementId: 'G-HTDY72WHTM',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAAG-2zkHd4JG-tMI4TsCjWIbt5yMoYszg',
    appId: '1:1019736121024:android:3fc1d95f99a045c5b29725',
    messagingSenderId: '1019736121024',
    projectId: 'assistant-655db',
    storageBucket: 'assistant-655db.firebasestorage.app',
  );
}
