// lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    // You can safely ignore these for now — they won't be called
    throw UnsupportedError('DefaultFirebaseOptions have not been configured for this platform.');
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDMuSXsVL_EHwdnnefJ-cRp9SX3dCQc3Po',
    appId: '1:1084654426667:web:69a431b53cf2bcaa17286e',
    messagingSenderId: '1084654426667',
    projectId: 'nyota-dc4e2',
    authDomain: 'nyota-dc4e2.firebaseapp.com',
    storageBucket: 'nyota-dc4e2.firebasestorage.app',
    measurementId: 'G-7G1FS009LH',
  );
}