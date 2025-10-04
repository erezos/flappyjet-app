import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';

/// Firebase configuration manager for production readiness
class FirebaseConfig {
  static bool _initialized = false;
  
  /// Initialize Firebase with proper configuration
  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _initialized = true;
      
      if (kDebugMode) {
        print('🔥 Firebase initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Firebase initialization failed: $e');
      }
      rethrow;
    }
  }
  
  /// Check if Firebase is properly initialized
  static bool get isInitialized => _initialized;
  
  /// Get current Firebase app instance
  static FirebaseApp get app {
    if (!_initialized) {
      throw StateError('Firebase not initialized. Call FirebaseConfig.initialize() first.');
    }
    return Firebase.app();
  }
}
