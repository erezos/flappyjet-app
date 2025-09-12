/// 🔧 Standardized Error Handling Utilities
/// Provides consistent error handling patterns across the application
library;
import '../../core/debug_logger.dart';

import 'package:flutter/foundation.dart';

/// Error severity levels
enum ErrorSeverity {
  low,      // Non-critical, can be ignored
  medium,   // Affects user experience but not critical functionality
  high,     // Critical functionality broken
  critical, // App stability threatened
}

/// Standardized error information
class AppError {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;
  final ErrorSeverity severity;
  final String? context;
  final DateTime timestamp;

  AppError({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
    this.severity = ErrorSeverity.medium,
    this.context,
  }) : timestamp = DateTime.now();

  @override
  String toString() {
    return '[${severity.name.toUpperCase()}] $message${code != null ? ' ($code)' : ''}${context != null ? ' in $context' : ''}';
  }
}

/// Centralized error handling utility
class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  /// Handle errors with consistent logging and reporting
  static void handleError(
    dynamic error,
    StackTrace? stackTrace, {
    String? context,
    ErrorSeverity severity = ErrorSeverity.medium,
    bool shouldReport = true,
    bool shouldRethrow = false,
  }) {
    final appError = AppError(
      message: error.toString(),
      originalError: error,
      stackTrace: stackTrace,
      severity: severity,
      context: context,
    );

    // Log error with appropriate level
    switch (severity) {
      case ErrorSeverity.low:
        safePrint('ℹ️ ${appError.toString()}');
        break;
      case ErrorSeverity.medium:
        safePrint('⚠️ ${appError.toString()}');
        break;
      case ErrorSeverity.high:
        safePrint('🚨 ${appError.toString()}');
        break;
      case ErrorSeverity.critical:
        safePrint('💥 ${appError.toString()}');
        break;
    }

    // Print stack trace for high severity errors in debug mode
    if (kDebugMode && (severity == ErrorSeverity.high || severity == ErrorSeverity.critical)) {
      safePrint('Stack trace: $stackTrace');
    }

    // TODO: Report to error tracking service (Firebase Crashlytics, Sentry, etc.)
    if (shouldReport && !kDebugMode) {
      _reportError(appError);
    }

    // Optionally rethrow for critical errors
    if (shouldRethrow && severity == ErrorSeverity.critical) {
      throw error;
    }
  }

  /// Safe async operation wrapper
  static Future<T?> safeAsync<T>(
    Future<T> Function() operation, {
    String? context,
    T? fallbackValue,
    ErrorSeverity severity = ErrorSeverity.medium,
  }) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      handleError(
        error,
        stackTrace,
        context: context,
        severity: severity,
      );
      return fallbackValue;
    }
  }

  /// Safe sync operation wrapper
  static T? safeSync<T>(
    T Function() operation, {
    String? context,
    T? fallbackValue,
    ErrorSeverity severity = ErrorSeverity.medium,
  }) {
    try {
      return operation();
    } catch (error, stackTrace) {
      handleError(
        error,
        stackTrace,
        context: context,
        severity: severity,
      );
      return fallbackValue;
    }
  }

  /// Validate and sanitize user input
  static String? validateInput(String? input, {
    int? minLength,
    int? maxLength,
    String? pattern,
    String? fieldName = 'input',
  }) {
    if (input == null || input.isEmpty) {
      handleError(
        '$fieldName cannot be empty',
        null,
        severity: ErrorSeverity.low,
      );
      return null;
    }

    if (minLength != null && input.length < minLength) {
      handleError(
        '$fieldName must be at least $minLength characters',
        null,
        severity: ErrorSeverity.low,
      );
      return null;
    }

    if (maxLength != null && input.length > maxLength) {
      handleError(
        '$fieldName must be no more than $maxLength characters',
        null,
        severity: ErrorSeverity.low,
      );
      return null;
    }

    if (pattern != null && !RegExp(pattern).hasMatch(input)) {
      handleError(
        '$fieldName format is invalid',
        null,
        severity: ErrorSeverity.low,
      );
      return null;
    }

    return input;
  }

  /// Network operation wrapper with retry logic
  static Future<T?> networkOperation<T>(
    Future<T> Function() operation, {
    String? context,
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 1),
    T? fallbackValue,
  }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (error, stackTrace) {
        attempts++;

        if (attempts >= maxRetries) {
          handleError(
            error,
            stackTrace,
            context: context,
            severity: ErrorSeverity.high,
          );
          return fallbackValue;
        }

        // Wait before retry
        await Future.delayed(retryDelay * attempts);
        safePrint('🔄 Retrying $context (attempt $attempts/$maxRetries)');
      }
    }

    return fallbackValue;
  }

  /// Report error to external service (placeholder)
  static void _reportError(AppError error) {
    // TODO: Implement error reporting to Firebase Crashlytics, Sentry, etc.
    // Example:
    // FirebaseCrashlytics.instance.recordError(error.originalError, error.stackTrace);
    safePrint('📊 Error reported: ${error.toString()}');
  }
}

/// Convenience extension for Result types
extension ResultErrorHandling<T> on T {
  /// Execute operation with error handling
  T? safe(String operation, {ErrorSeverity severity = ErrorSeverity.medium}) {
    try {
      return this;
    } catch (error, stackTrace) {
      ErrorHandler.handleError(
        error,
        stackTrace,
        context: operation,
        severity: severity,
      );
      return null;
    }
  }
}

/// API Result wrapper for consistent error handling
class ApiResult<T> {
  final T? data;
  final String? error;
  final bool success;
  final String? errorCode;

  ApiResult.success(T data)
      : data = data,
        error = null,
        success = true,
        errorCode = null;

  ApiResult.error(String error, {String? errorCode})
      : data = null,
        error = error,
        success = false,
        errorCode = errorCode;

  @override
  String toString() {
    return success ? 'Success: $data' : 'Error: $error ($errorCode)';
  }
}