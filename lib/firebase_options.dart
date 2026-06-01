// File generated from google-services.json
// Project: gymforge-f9fe3

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCWzMixBod41zJozuGHQieYr9VDJeQtwjk',
    appId: '1:659942518247:android:d29e87f79f3a1a4bdc6142',
    messagingSenderId: '659942518247',
    projectId: 'gymforge-f9fe3',
    storageBucket: 'gymforge-f9fe3.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCWzMixBod41zJozuGHQieYr9VDJeQtwjk',
    appId: '1:659942518247:ios:placeholder',
    messagingSenderId: '659942518247',
    projectId: 'gymforge-f9fe3',
    storageBucket: 'gymforge-f9fe3.firebasestorage.app',
    iosClientId: '',
    iosBundleId: 'com.gymforge.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyBjnQ9eKa5qqw9MU8EYKUBP8-7SUezQjKU",
  authDomain: "gymforge-f9fe3.firebaseapp.com",
  projectId: "gymforge-f9fe3",
  storageBucket: "gymforge-f9fe3.firebasestorage.app",
  messagingSenderId: "659942518247",
  appId: "1:659942518247:web:ab24d33dc970411cdc6142",
  measurementId: "G-KHB4KLPR9P"
  );


}
