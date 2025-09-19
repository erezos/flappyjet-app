/// 🔐 IAP Configuration
/// Handles secure configuration for in-app purchase validation
library;

import 'package:flutter/foundation.dart';

class IAPConfig {
  // Apple App Store Configuration
  static const String _appleSharedSecretDev = '34c180c01e864a0e8ff69e0f0e6c7c18';
  static const String _appleSharedSecretProd = '34c180c01e864a0e8ff69e0f0e6c7c18';
  
  // Google Play Store Configuration
  static const String _androidPackageName = 'com.erezos.flappyjet';
  
  /// Get Apple shared secret based on build mode
  static String get appleSharedSecret {
    if (kDebugMode) {
      return _appleSharedSecretDev;
    } else {
      return _appleSharedSecretProd;
    }
  }
  
  /// Get Android package name
  static String get androidPackageName => _androidPackageName;
  
  /// Check if Apple configuration is valid
  static bool get isAppleConfigured {
    return appleSharedSecret != 'CONFIGURE_IN_APP_STORE_CONNECT' && 
           appleSharedSecret.isNotEmpty;
  }
  
  /// Check if Android configuration is valid
  static bool get isAndroidConfigured {
    return androidPackageName.isNotEmpty;
  }
}
