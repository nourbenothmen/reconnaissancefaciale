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
        return windows;
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
    apiKey: 'AIzaSyAStjvFXQamukYloxjXVZPgM9hvzk6rQ4w',
    appId: '1:416701148607:web:560088e3b0b5a2a01e050a',
    messagingSenderId: '416701148607',
    projectId: 'reconnfaciale-325f2',
    authDomain: 'reconnfaciale-325f2.firebaseapp.com',
    storageBucket: 'reconnfaciale-325f2.firebasestorage.app',
    measurementId: 'G-1JTV89ESMB',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDVdJyKnbO0WPp-i14LloaaWxvlTb5uZkE',
    appId: '1:416701148607:android:eed3b7eb5f9979c91e050a',
    messagingSenderId: '416701148607',
    projectId: 'reconnfaciale-325f2',
    storageBucket: 'reconnfaciale-325f2.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAStjvFXQamukYloxjXVZPgM9hvzk6rQ4w',
    appId: '1:416701148607:web:26c5a6891bbe777b1e050a',
    messagingSenderId: '416701148607',
    projectId: 'reconnfaciale-325f2',
    authDomain: 'reconnfaciale-325f2.firebaseapp.com',
    storageBucket: 'reconnfaciale-325f2.firebasestorage.app',
    measurementId: 'G-T7WHJFNLJB',
  );
}
