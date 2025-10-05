import '../core/debug_logger.dart';

/// 🔍 Diagnostic Logger for Ad System
/// 
/// This class provides detailed logging for debugging ad issues
/// between emulator and real devices.
class AdDiagnosticLogger {
  static final AdDiagnosticLogger _instance = AdDiagnosticLogger._internal();
  factory AdDiagnosticLogger() => _instance;
  AdDiagnosticLogger._internal();

  final List<String> _logs = [];
  DateTime? _sessionStart;

  void startSession() {
    _sessionStart = DateTime.now();
    _logs.clear();
    _log('🔍 ========== AD DIAGNOSTIC SESSION STARTED ==========');
    _log('📅 Timestamp: ${_sessionStart!.toIso8601String()}');
  }

  void logInitialization(String network, bool success, {String? error}) {
    _log('🎯 INIT: $network - ${success ? "✅ SUCCESS" : "❌ FAILED"}');
    if (error != null) {
      _log('   Error: $error');
    }
  }

  void logLoadStart(String network, String adType) {
    _log('📥 LOAD START: $network - $adType');
    _log('   Time: ${_getElapsedTime()}');
  }

  void logLoadSuccess(String network, String adType, {String? placementId}) {
    _log('✅ LOAD SUCCESS: $network - $adType');
    if (placementId != null) {
      _log('   Placement: $placementId');
    }
    _log('   Time: ${_getElapsedTime()}');
  }

  void logLoadFailure(String network, String adType, String error, {String? errorCode}) {
    _log('❌ LOAD FAILED: $network - $adType');
    _log('   Error: $error');
    if (errorCode != null) {
      _log('   Code: $errorCode');
    }
    _log('   Time: ${_getElapsedTime()}');
  }

  void logShowStart(String network, String adType) {
    _log('📺 SHOW START: $network - $adType');
    _log('   Time: ${_getElapsedTime()}');
  }

  void logShowSuccess(String network, String adType) {
    _log('✅ SHOW SUCCESS: $network - $adType');
    _log('   Time: ${_getElapsedTime()}');
  }

  void logShowFailure(String network, String adType, String error) {
    _log('❌ SHOW FAILED: $network - $adType');
    _log('   Error: $error');
    _log('   Time: ${_getElapsedTime()}');
  }

  void logAdClosed(String network, bool rewardGranted) {
    _log('🚪 AD CLOSED: $network');
    _log('   Reward: ${rewardGranted ? "✅ GRANTED" : "❌ NOT GRANTED"}');
    _log('   Time: ${_getElapsedTime()}');
  }

  void logFallback(String from, String to, String reason) {
    _log('🔄 FALLBACK: $from → $to');
    _log('   Reason: $reason');
    _log('   Time: ${_getElapsedTime()}');
  }

  void logStateChange(String state, Map<String, dynamic> data) {
    _log('📊 STATE CHANGE: $state');
    data.forEach((key, value) {
      _log('   $key: $value');
    });
  }

  void logWarning(String message) {
    _log('⚠️ WARNING: $message');
  }

  void logError(String message, {Object? exception, StackTrace? stackTrace}) {
    _log('🔴 ERROR: $message');
    if (exception != null) {
      _log('   Exception: $exception');
    }
    if (stackTrace != null) {
      _log('   Stack: ${stackTrace.toString().split('\n').take(3).join('\n')}');
    }
  }

  void endSession({String? summary}) {
    _log('🔍 ========== AD DIAGNOSTIC SESSION ENDED ==========');
    if (summary != null) {
      _log('📝 Summary: $summary');
    }
    _log('⏱️ Total Duration: ${_getElapsedTime()}');
    _log('');
    
    // Print all logs
    printFullReport();
  }

  void printFullReport() {
    safePrint('');
    safePrint('╔═══════════════════════════════════════════════════════════╗');
    safePrint('║          AD DIAGNOSTIC REPORT                             ║');
    safePrint('╚═══════════════════════════════════════════════════════════╝');
    for (final log in _logs) {
      safePrint(log);
    }
    safePrint('╚═══════════════════════════════════════════════════════════╝');
    safePrint('');
  }

  void _log(String message) {
    _logs.add(message);
    safePrint(message); // Also print immediately for real-time debugging
  }

  String _getElapsedTime() {
    if (_sessionStart == null) return '0.0s';
    final elapsed = DateTime.now().difference(_sessionStart!);
    return '${elapsed.inMilliseconds / 1000}s';
  }

  List<String> get logs => List.unmodifiable(_logs);
  
  void clear() {
    _logs.clear();
  }
}
