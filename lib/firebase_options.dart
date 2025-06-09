import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
          'DefaultFirebaseOptions have not been configured for macOS - '
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
    apiKey: "AIzaSyCbetcwqLmqhblWFbBejMU8AHQ3V59SAjo",
    authDomain: "smp-mobile-app-462206.firebaseapp.com",
    projectId: "smp-mobile-app-462206",
    storageBucket: "smp-mobile-app-462206.firebasestorage.app",
    messagingSenderId: "690685991196",
    appId: "1:690685991196:web:b1daf779e2c3a59dd882d9",
    measurementId: "G-9GMGQWHPCH"
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCbetcwqLmqhblWFbBejMU8AHQ3V59SAjo',
    appId: '1:690685991196:android:7e0b9c8f9b8a9c8dd882d9',
    messagingSenderId: '690685991196',
    projectId: 'smp-mobile-app-462206',
    storageBucket: 'smp-mobile-app-462206.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCbetcwqLmqhblWFbBejMU8AHQ3V59SAjo',
    appId: '1:690685991196:ios:8e1c0d9f0c9b0d9ed882d9',
    messagingSenderId: '690685991196',
    projectId: 'smp-mobile-app-462206',
    storageBucket: 'smp-mobile-app-462206.firebasestorage.app',
    iosBundleId: 'com.sunsetcoding.smpMentorMenteeMobileApp',
  );
}