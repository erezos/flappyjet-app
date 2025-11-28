import 'package:flutter/foundation.dart';

/// Production-ready app configuration
class AppConfig {
  // Environment detection
  static bool get isProduction => kReleaseMode;
  static bool get isDevelopment => kDebugMode;
  
  // Firebase configuration
  static const String firebaseProjectId = 'flappyjet-b31f9';
  static const String firebaseProjectNumber = '861286493216';
  
  // App information
  static const String appName = 'FlappyJet Pro';
  // Note: Use PackageInfo.fromPlatform() for dynamic version, not this constant
  // This is kept for reference only - actual version comes from pubspec.yaml
  static const String packageName = 'com.flappyjet.pro.flappy_jet_pro';
  
  // Backend configuration
  static const String backendUrl = 'https://flappyjet-backend-production.up.railway.app';
  static const String apiVersion = 'v1';
  
  // Security configuration
  static const bool enableAnalytics = true;
  static const bool enableCrashlytics = true;
  static const bool enablePerformanceMonitoring = true;
  
  // IAP configuration
  static const bool enableIAP = true;
  static const bool enableIAPPromotion = true;
  
  // Debug configuration
  static bool get enableDebugLogs => isDevelopment;
  static bool get enableNetworkLogs => isDevelopment;
  
  /// Get full API URL
  static String get apiUrl => '$backendUrl/api/$apiVersion';
  
  /// Check if running in production mode
  static bool get isProductionMode => isProduction;
}
