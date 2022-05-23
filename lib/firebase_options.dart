// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
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
    apiKey: 'AIzaSyARL1oOWB944zWh_sn1rqycjUBmmeO4bXo',
    appId: '1:236118574266:web:7bbfa15101a818c42fae83',
    messagingSenderId: '236118574266',
    projectId: 'indoorlocation-b7778',
    authDomain: 'indoorlocation-b7778.firebaseapp.com',
    storageBucket: 'indoorlocation-b7778.appspot.com',
    measurementId: 'G-EMPPJNMW57',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD1HgEcGBSqCGT-fdHwXBnfCAKZbQgjibY',
    appId: '1:236118574266:android:e4df8e0b681c71342fae83',
    messagingSenderId: '236118574266',
    projectId: 'indoorlocation-b7778',
    storageBucket: 'indoorlocation-b7778.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDqmS3qNLiGFqsEzVH5P8Nb1kjuE9BM-ug',
    appId: '1:236118574266:ios:6543bb1d4b47ccef2fae83',
    messagingSenderId: '236118574266',
    projectId: 'indoorlocation-b7778',
    storageBucket: 'indoorlocation-b7778.appspot.com',
    iosClientId: '236118574266-i4s9f3jglj7k9e8sugc0e2n73d4erufa.apps.googleusercontent.com',
    iosBundleId: 'com.example.indoorLocation',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDqmS3qNLiGFqsEzVH5P8Nb1kjuE9BM-ug',
    appId: '1:236118574266:ios:6543bb1d4b47ccef2fae83',
    messagingSenderId: '236118574266',
    projectId: 'indoorlocation-b7778',
    storageBucket: 'indoorlocation-b7778.appspot.com',
    iosClientId: '236118574266-i4s9f3jglj7k9e8sugc0e2n73d4erufa.apps.googleusercontent.com',
    iosBundleId: 'com.example.indoorLocation',
  );
}
