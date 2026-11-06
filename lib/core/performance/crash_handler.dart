/// 💥 Crash Handler
/// 
/// Global error handler for Flutter app
/// Catches all unhandled errors and reports them
/// 
/// Follows Flame game engine best practices:
/// - Never crashes the app
/// - Logs all errors
/// - Reports to backend
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../debug_logger.dart';
import 'performance_tracker.dart';

/// Global Crash Handler
/// 
/// Catches all unhandled errors and exceptions
class CrashHandler {
  static final CrashHandler _instance = CrashHandler._internal();
  factory CrashHandler() => _instance;
  CrashHandler._internal();

  bool _isInitialized = false;
  final PerformanceTracker _performanceTracker = PerformanceTracker();

  /// Initialize crash handler
  void initialize() {
    if (_isInitialized) return;

    try {
      safePrint('💥 Initializing Crash Handler...');

      // Set up Flutter error handlers
      FlutterError.onError = (FlutterErrorDetails details) {
        _handleError(
          error: details.exception,
          stackTrace: details.stack,
          context: details.context?.toString(),
          fatal: false, // Flutter errors are usually non-fatal
        );
      };

      // Set up zone error handler for async errors
      runZonedGuarded(() {
        // App will run in this zone
      }, (error, stackTrace) {
        _handleError(
          error: error,
          stackTrace: stackTrace,
          context: 'Zone error',
          fatal: true, // Zone errors are usually fatal
        );
      });

      _isInitialized = true;
      safePrint('💥 ✅ Crash Handler initialized');
    } catch (e) {
      safePrint('💥 ❌ Crash Handler initialization failed: $e');
    }
  }

  /// Handle error
  void _handleError({
    required dynamic error,
    required StackTrace? stackTrace,
    String? context,
    required bool fatal,
  }) {
    try {
      final errorType = error.runtimeType.toString();
      final errorMessage = error.toString();
      final stackTraceStr = stackTrace?.toString();

      safePrint('💥 Error caught: $errorType - $errorMessage');
      if (stackTrace != null) {
        safePrint('💥 Stack trace: $stackTrace');
      }

      // Report to performance tracker
      if (fatal) {
        _performanceTracker.trackCrash(
          crashType: errorType,
          crashMessage: errorMessage,
          stackTrace: stackTraceStr,
          context: context,
        );
      } else {
        _performanceTracker.trackError(
          errorType: errorType,
          errorMessage: errorMessage,
          stackTrace: stackTraceStr,
          context: context,
        );
      }
    } catch (e) {
      // Even error handling can fail - just log it
      safePrint('💥 ❌ Failed to handle error: $e');
    }
  }

  /// Manually report an error
  void reportError({
    required dynamic error,
    StackTrace? stackTrace,
    String? context,
    bool fatal = false,
  }) {
    _handleError(
      error: error,
      stackTrace: stackTrace,
      context: context,
      fatal: fatal,
    );
  }
}

