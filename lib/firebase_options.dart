// Mock Firebase Options for Development
// This file provides safe defaults when Firebase is not properly configured
// Replace with real firebase_options.dart from `flutterfire configure` for production

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
/// 
/// Example for development/testing - replace with real configuration:
/// 1. Run: `flutterfire configure`
/// 2. Follow the setup wizard
/// 3. Replace this file with the generated one
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
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
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for '
          '${defaultTargetPlatform.name} - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
    }
  }

  // Mock configurations - replace with real ones
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'mock-api-key-android',
    appId: 'mock-app-id-android',
    messagingSenderId: 'mock-sender-id',
    projectId: 'flappyjet-pro-mock',
    storageBucket: 'flappyjet-pro-mock.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'mock-api-key-ios',
    appId: 'mock-app-id-ios',
    messagingSenderId: 'mock-sender-id',
    projectId: 'flappyjet-pro-mock',
    storageBucket: 'flappyjet-pro-mock.appspot.com',
    iosClientId: 'mock-client-id.apps.googleusercontent.com',
    iosBundleId: 'com.flappyjet.pro.flappyJetPro',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'mock-api-key-macos',
    appId: 'mock-app-id-macos',
    messagingSenderId: 'mock-sender-id',
    projectId: 'flappyjet-pro-mock',
    storageBucket: 'flappyjet-pro-mock.appspot.com',
    iosClientId: 'mock-client-id.apps.googleusercontent.com',
    iosBundleId: 'com.flappyjet.pro.flappyJetPro',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'mock-api-key-windows',
    appId: 'mock-app-id-windows',
    messagingSenderId: 'mock-sender-id',
    projectId: 'flappyjet-pro-mock',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'mock-api-key-linux',
    appId: 'mock-app-id-linux',
    messagingSenderId: 'mock-sender-id',
    projectId: 'flappyjet-pro-mock',
  );
} 