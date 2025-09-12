/// Lightweight performance timer - replaces heavy PerformanceMonitor
/// Only tracks essential timing metrics without UI overhead
class LightweightPerformanceTimer {
  static LightweightPerformanceTimer? _instance;
  final Map<String, int> _startTimes = {};
  final Map<String, List<int>> _completedTimes = {};

  LightweightPerformanceTimer._();

  factory LightweightPerformanceTimer() {
    _instance ??= LightweightPerformanceTimer._();
    return _instance!;
  }

  /// Start timing an operation
  void startTimer(String operationName) {
    _startTimes[operationName] = DateTime.now().microsecondsSinceEpoch;
  }

  /// Stop timing and record completion
  void stopTimer(String operationName, {Map<String, dynamic>? metadata}) {
    final startTime = _startTimes.remove(operationName);
    if (startTime == null) return;

    final endTime = DateTime.now().microsecondsSinceEpoch;
    final duration = endTime - startTime;

    // Store completed time for potential analysis
    _completedTimes.putIfAbsent(operationName, () => []).add(duration);
  }

  /// Record an asset load operation
  void recordAssetLoad(String assetPath, int durationMs, bool success) {
    // Minimal implementation - just log if needed
    if (!success) {
      // Could log failures here if needed
    }
  }

  /// Get performance summary (minimal data)
  Map<String, dynamic> getSummary() {
    final summary = <String, dynamic>{};

    for (final entry in _completedTimes.entries) {
      final times = entry.value;
      if (times.isNotEmpty) {
        final avg = times.reduce((a, b) => a + b) ~/ times.length;
        summary['avg_${entry.key}'] = avg;
      }
    }

    return summary;
  }

  /// Clear all recorded data
  void clear() {
    _startTimes.clear();
    _completedTimes.clear();
  }

  /// Get performance summary (for compatibility)
  Map<String, dynamic> getPerformanceSummary() {
    return getSummary();
  }

  /// Get recent metrics (simplified)
  Map<String, dynamic> getRecentMetrics({int lastN = 1000}) {
    return getSummary();
  }

  /// Export data (simplified)
  Map<String, dynamic> exportData() {
    return getSummary();
  }
}
