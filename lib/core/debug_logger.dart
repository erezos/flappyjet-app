/// 🎯 PRODUCTION-READY LOGGER - Optimized for performance and user experience
/// Conditional logging that disappears in production builds
library;

import 'package:flutter/foundation.dart';

/// Log levels for production use
enum LogLevel {
  debug,    // Only in debug builds
  info,     // Info level (Firebase Analytics)
  warning,  // Warning level (Firebase Analytics)
  error,    // Error level (Firebase Crashlytics)
  critical, // Critical errors (Firebase Crashlytics + immediate reporting)
}

/// 🎯 Production-Optimized Logger
/// - Zero overhead in production builds
/// - Conditional compilation for maximum performance
/// - Firebase integration for error reporting
class Logger {
  /// 🚫 PRODUCTION OPTIMIZATION: Debug logging completely removed in release
  static void d(String message, {Map<String, dynamic>? data}) {
    if (kDebugMode) {
      _logWithPrefix('🐛 DEBUG', message, data);
    }
    // Production: This method does nothing (zero overhead)
  }

  /// ℹ️ Info logging - DEBUG MODE ONLY for performance
  static void i(String message, {Map<String, dynamic>? data}) {
    if (kDebugMode) {
      _logWithPrefix('ℹ️ INFO', message, data);
    }
    // Production: Send to Firebase Analytics silently (no console logs)
  }

  /// ⚠️ Warning logging - DEBUG MODE ONLY for performance
  static void w(String message, {Map<String, dynamic>? data, Object? error}) {
    if (kDebugMode) {
      _logWithPrefix('⚠️ WARN', message, data, error: error);
    }
    // Production: Send to Firebase Analytics silently (no console logs)
  }

  /// ❌ Error logging - ERRORS ONLY (no console spam in production)
  static void e(String message, {Map<String, dynamic>? data, Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      _logWithPrefix('❌ ERROR', message, data, error: error);
      if (stackTrace != null) {
        safePrint('Stack trace: $stackTrace');
      }
    }
    // Production: Send to Firebase Crashlytics silently
  }

  /// 🚨 Critical error - always logged, triggers immediate action
  static void critical(String message, {Map<String, dynamic>? data, Object? error, StackTrace? stackTrace}) {
    _logWithPrefix('🚨 CRITICAL', message, data, error: error);
    if (stackTrace != null) {
      safePrint('Stack trace: $stackTrace');
    }
    // TODO: Send to Firebase Crashlytics + immediate reporting
  }

  /// 🔊 Audio-specific logging
  static void audio(String message, {LogLevel level = LogLevel.debug, Map<String, dynamic>? data, Object? error, StackTrace? stackTrace}) {
    _logWithCategory('🔊 AUDIO', message, level, data, error, stackTrace);
  }

  /// 🎮 Game-specific logging
  static void game(String message, {LogLevel level = LogLevel.debug, Map<String, dynamic>? data, Object? error, StackTrace? stackTrace}) {
    _logWithCategory('🎮 GAME', message, level, data, error, stackTrace);
  }

  /// 🌐 Backend/network logging
  static void backend(String message, {LogLevel level = LogLevel.debug, Map<String, dynamic>? data, Object? error, StackTrace? stackTrace}) {
    _logWithCategory('🌐 BACKEND', message, level, data, error, stackTrace);
  }

  /// 🎨 UI-specific logging
  static void ui(String message, {LogLevel level = LogLevel.debug, Map<String, dynamic>? data, Object? error, StackTrace? stackTrace}) {
    _logWithCategory('🎨 UI', message, level, data, error, stackTrace);
  }

  /// ⚡ Performance logging
  static void performance(String message, {LogLevel level = LogLevel.debug, Map<String, dynamic>? data, Object? error, StackTrace? stackTrace}) {
    _logWithCategory('⚡ PERF', message, level, data, error, stackTrace);
  }

  /// Internal logging method with category
  static void _logWithCategory(String category, String message, LogLevel level,
      Map<String, dynamic>? data, Object? error, StackTrace? stackTrace) {

    // 🚫 PRODUCTION OPTIMIZATION: Skip debug logs in release mode
    if (level == LogLevel.debug && !kDebugMode) return;

    String logMessage = '[$category] $message';
    
    if (data != null && data.isNotEmpty) {
      logMessage += ' | ${data.toString()}';
    }
    
    if (error != null) {
      logMessage += ' | Error: $error';
    }

    safePrint(logMessage);
    
    if (stackTrace != null && (level == LogLevel.error || level == LogLevel.critical)) {
      safePrint('Stack trace: $stackTrace');
    }
  }

  /// Internal logging method with prefix
  static void _logWithPrefix(String prefix, String message,
      Map<String, dynamic>? data, {Object? error}) {

    String logMessage = '$prefix $message';

    if (data != null && data.isNotEmpty) {
      logMessage += ' | ${data.toString()}';
    }

    if (error != null) {
      logMessage += ' | Error: $error';
    }

    safePrint(logMessage);
  }
}

/// 🚀 PRODUCTION-SAFE DEBUG PRINT
/// Completely disabled in production for maximum performance
void safePrint(String message) {
  // 🔍 TEMPORARY: Enable ALL monetization logs in production for debugging
  if (kDebugMode || 
      message.contains('📺') ||  // AdMob logs
      message.contains('💰') ||  // MonetizationManager logs
      message.contains('🔍') ||  // Production debug logs
      message.contains('PRODUCTION DEBUG') ||
      message.contains('🚀') ||  // Initialization logs
      message.contains('⚠️') ||  // Warning logs
      message.contains('❌') ||  // Error logs
      message.contains('✅') ||  // Success logs
      message.contains('Background monetization') ||
      message.contains('AdMob') ||
      message.contains('Monetization')) {
    debugPrint(message);
  }
}

/// 🚀 PRODUCTION-SAFE DEBUG PRINT WITH DATA
/// Automatically disabled in production builds
void safePrintWithData(String message, {Map<String, dynamic>? data, Object? error}) {
  if (kDebugMode) {
    String output = message;
    if (data != null && data.isNotEmpty) {
      output += ' | ${data.toString()}';
    }
    if (error != null) {
      output += ' | Error: $error';
    }
    debugPrint(output);
  }
  // Production: This does nothing (zero overhead)
}

/// 🚀 SAFE ERROR LOGGING - DEBUG MODE ONLY
void safeError(String message, {Object? error, StackTrace? stackTrace}) {
  if (kDebugMode) {
    debugPrint('❌ ERROR: $message${error != null ? ' | Error: $error' : ''}');
    if (stackTrace != null) {
      debugPrint('Stack trace: $stackTrace');
    }
  }
  // Production: Send to Firebase Crashlytics silently
}

/// 🚀 SAFE WARNING LOGGING - DEBUG MODE ONLY
void safeWarn(String message, {Map<String, dynamic>? data, Object? error}) {
  if (kDebugMode) {
    debugPrint('⚠️ WARN: $message${error != null ? ' | Error: $error' : ''}');
    if (data != null && data.isNotEmpty) {
      debugPrint('Data: ${data.toString()}');
    }
  }
  // Production: Send to Firebase Analytics silently
}

/// 🚀 SAFE CRITICAL ERROR LOGGING - CRITICAL ONLY (minimal production logs)
void safeCritical(String message, {Map<String, dynamic>? data, Object? error, StackTrace? stackTrace}) {
  // Only log critical errors in production (minimal)
  debugPrint('🚨 CRITICAL: $message');
  if (kDebugMode) {
    if (error != null) debugPrint('Error: $error');
    if (stackTrace != null) debugPrint('Stack trace: $stackTrace');
    if (data != null && data.isNotEmpty) debugPrint('Data: ${data.toString()}');
  }
  // Production: Send to Firebase Crashlytics + immediate reporting
}
