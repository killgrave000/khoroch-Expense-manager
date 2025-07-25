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
        return ios;
      case TargetPlatform.macOS:
        return macos;
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
    apiKey: 'AIzaSyDme_lrnUdbs6ENB9mTct6VYTmRoUo-Fwk',
    appId: '1:190952475216:web:c8a331c94aa9b9d6c91f55',
    messagingSenderId: '190952475216',
    projectId: 'khoroch-9861a',
    authDomain: 'khoroch-9861a.firebaseapp.com',
    storageBucket: 'khoroch-9861a.firebasestorage.app',
    measurementId: 'G-5ZB7NNXRP5',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDyx5qMNTRpFGeOVvS5EZF1w35_BOFrRY8',
    appId: '1:190952475216:android:b703876c45c648fdc91f55',
    messagingSenderId: '190952475216',
    projectId: 'khoroch-9861a',
    storageBucket: 'khoroch-9861a.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA2FDZqTorBUp--cDDdH5J0Cnp7JY4zgkA',
    appId: '1:190952475216:ios:c829d65a052b2459c91f55',
    messagingSenderId: '190952475216',
    projectId: 'khoroch-9861a',
    storageBucket: 'khoroch-9861a.firebasestorage.app',
    iosBundleId: 'com.example.khoroch',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyA2FDZqTorBUp--cDDdH5J0Cnp7JY4zgkA',
    appId: '1:190952475216:ios:c829d65a052b2459c91f55',
    messagingSenderId: '190952475216',
    projectId: 'khoroch-9861a',
    storageBucket: 'khoroch-9861a.firebasestorage.app',
    iosBundleId: 'com.example.khoroch',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDme_lrnUdbs6ENB9mTct6VYTmRoUo-Fwk',
    appId: '1:190952475216:web:d3683927a387c343c91f55',
    messagingSenderId: '190952475216',
    projectId: 'khoroch-9861a',
    authDomain: 'khoroch-9861a.firebaseapp.com',
    storageBucket: 'khoroch-9861a.firebasestorage.app',
    measurementId: 'G-VQ7LCSHY0M',
  );
}
