import 'package:flutter/foundation.dart';
import 'debug_logger.dart';

/// Centralized debug logging manager to reduce log spam while keeping essential info
class DebugManager {
  static bool _isInitialized = false;
  static final Map<String, int> _logCounts = {};
  static final Map<String, DateTime> _lastLogTime = {};
  
  // Log level configuration
  static const bool enableAudioLogs = kDebugMode;
  static const bool enableGameLogs = kDebugMode;
  static const bool enableNetworkLogs = kDebugMode;
  static const bool enablePerformanceLogs = kDebugMode;
  
  // Rate limiting configuration
  static const Duration logCooldown = Duration(seconds: 1);
  static const int maxRepeatedLogs = 3;
  
  static void initialize() {
    if (_isInitialized) return;
    _isInitialized = true;
    
    if (kDebugMode) {
      safePrint('🔧 DebugManager initialized - Optimized logging enabled');
    }
  }
  
  /// Audio-related logs (rate-limited to reduce DRM spam)
  static void audio(String message, {Object? error, StackTrace? stackTrace}) {
    if (!enableAudioLogs) return;
    
    // Filter out excessive DRM logs
    if (message.contains('resetDrmState') || 
        message.contains('cleanDrmObj') ||
        message.contains('MediaPlayer')) {
      return; // Skip Android MediaPlayer DRM logs entirely
    }
    
    _logWithRateLimit('AUDIO', message, error: error, stackTrace: stackTrace);
  }
  
  /// Game-related logs
  static void game(String message, {Object? error, StackTrace? stackTrace}) {
    if (!enableGameLogs) return;
    _logWithRateLimit('GAME', message, error: error, stackTrace: stackTrace);
  }
  
  /// Network-related logs
  static void network(String message, {Object? error, StackTrace? stackTrace}) {
    if (!enableNetworkLogs) return;
    _logWithRateLimit('NET', message, error: error, stackTrace: stackTrace);
  }
  
  /// Performance-related logs
  static void performance(String message, {Object? error, StackTrace? stackTrace}) {
    if (!enablePerformanceLogs) return;
    _logWithRateLimit('PERF', message, error: error, stackTrace: stackTrace);
  }
  
  /// Critical errors (always logged)
  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    safePrint('❌ ERROR: $message');
    if (error != null) safePrint('   Error: $error');
    if (stackTrace != null) safePrint('   Stack: $stackTrace');
  }
  
  /// Important info (always logged)
  static void info(String message) {
    safePrint('ℹ️ INFO: $message');
  }
  
  /// Rate-limited logging to prevent spam
  static void _logWithRateLimit(String category, String message, {Object? error, StackTrace? stackTrace}) {
    final key = '$category:${message.split(' ').take(3).join(' ')}'; // Use first 3 words as key
    final now = DateTime.now();
    
    // Check if we've logged this recently
    if (_lastLogTime.containsKey(key)) {
      final timeSinceLastLog = now.difference(_lastLogTime[key]!);
      if (timeSinceLastLog < logCooldown) {
        _logCounts[key] = (_logCounts[key] ?? 0) + 1;
        if (_logCounts[key]! > maxRepeatedLogs) {
          return; // Skip repeated logs
        }
      } else {
        _logCounts[key] = 0; // Reset count after cooldown
      }
    }
    
    _lastLogTime[key] = now;
    
    // Log with category prefix
    safePrint('$category: $message');
    if (error != null) safePrint('   Error: $error');
    if (stackTrace != null && kDebugMode) {
      // Only show stack trace in debug mode and limit to 5 lines
      final lines = stackTrace.toString().split('\n').take(5).join('\n');
      safePrint('   Stack: $lines');
    }
  }
  
  /// Get logging statistics
  static Map<String, dynamic> getStats() {
    return {
      'total_log_keys': _logCounts.length,
      'active_cooldowns': _lastLogTime.length,
      'most_frequent_logs': _logCounts.entries
          .where((e) => e.value > 1)
          .map((e) => '${e.key}: ${e.value}')
          .take(5)
          .toList(),
    };
  }
  
  /// Clear statistics
  static void clearStats() {
    _logCounts.clear();
    _lastLogTime.clear();
  }
}