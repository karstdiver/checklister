import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAqTKXdp4nk26NMUr8KPZLQ9jNxbEOrCU8',
    appId: '1:821052652843:android:0315dd6f772106bf63d96e',
    messagingSenderId: '821052652843',
    projectId: 'checklister-firebase-dev',
    storageBucket: 'checklister-firebase-dev.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCLdxgLTHDaplz2rUydb59ExkxiBNZyxFY',
    appId: '1:821052652843:ios:ab8434cbe569e0d463d96e',
    messagingSenderId: '821052652843',
    projectId: 'checklister-firebase-dev',
    storageBucket: 'checklister-firebase-dev.firebasestorage.app',
    iosBundleId: 'com.checklister.checklister',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAW24TU9HvqJYfAgiE2h0tL4HANZO_5AlU',
    appId: '1:821052652843:web:cf020fbc253f74bd63d96e',
    messagingSenderId: '821052652843',
    projectId: 'checklister-firebase-dev',
    authDomain: 'checklister-firebase-dev.firebaseapp.com',
    storageBucket: 'checklister-firebase-dev.firebasestorage.app',
    measurementId: 'G-XP344YJLNN',
  );

}