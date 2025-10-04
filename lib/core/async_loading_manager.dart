/// 🚀 Async Loading Manager - Non-blocking System Initialization
/// Manages progressive loading of systems without blocking app startup
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/debug_logger.dart';

enum LoadingPhase {
  instant,      // Must complete before UI shows (< 100ms)
  critical,     // Should complete quickly (< 500ms)
  important,    // Can load in background (< 2s)
  optional,     // Load when convenient (< 10s)
  background,   // Load whenever (no time limit)
}

enum SystemStatus {
  pending,
  loading,
  completed,
  failed,
  skipped,
}

class LoadingTask {
  final String name;
  final LoadingPhase phase;
  final Future<bool> Function() task;
  final List<String> dependencies;
  final bool required;
  final Duration timeout;
  
  SystemStatus status = SystemStatus.pending;
  String? errorMessage;
  DateTime? startTime;
  DateTime? endTime;
  
  LoadingTask({
    required this.name,
    required this.phase,
    required this.task,
    this.dependencies = const [],
    this.required = true,
    this.timeout = const Duration(seconds: 10),
  });
  
  Duration? get loadTime {
    if (startTime == null || endTime == null) return null;
    return endTime!.difference(startTime!);
  }
}

/// Async Loading Manager - Progressive system initialization
class AsyncLoadingManager extends ChangeNotifier {
  static final AsyncLoadingManager _instance = AsyncLoadingManager._internal();
  factory AsyncLoadingManager() => _instance;
  AsyncLoadingManager._internal();

  final Map<String, LoadingTask> _tasks = {};
  final Map<LoadingPhase, List<String>> _phaseGroups = {};
  final Set<String> _completedTasks = {};
  final Set<String> _failedTasks = {};
  
  LoadingPhase _currentPhase = LoadingPhase.instant;
  bool _isLoading = false;
  double _overallProgress = 0.0;
  
  // Getters
  bool get isLoading => _isLoading;
  double get overallProgress => _overallProgress;
  LoadingPhase get currentPhase => _currentPhase;
  Map<String, LoadingTask> get tasks => Map.unmodifiable(_tasks);
  Set<String> get completedTasks => Set.unmodifiable(_completedTasks);
  Set<String> get failedTasks => Set.unmodifiable(_failedTasks);

  /// Register a loading task
  void registerTask(LoadingTask task) {
    _tasks[task.name] = task;
    
    // Group by phase
    _phaseGroups.putIfAbsent(task.phase, () => []);
    _phaseGroups[task.phase]!.add(task.name);
    
    safePrint('🚀 Registered task: ${task.name} (${task.phase})');
  }

  /// Start progressive loading
  Future<void> startLoading() async {
    if (_isLoading) return;
    
    _isLoading = true;
    _overallProgress = 0.0;
    notifyListeners();
    
    safePrint('🚀 Starting progressive loading...');
    
    try {
      // Phase 1: Instant (must complete before UI)
      await _loadPhase(LoadingPhase.instant);
      _currentPhase = LoadingPhase.critical;
      notifyListeners();
      
      // Phase 2: Critical (should complete quickly)
      await _loadPhase(LoadingPhase.critical);
      _currentPhase = LoadingPhase.important;
      notifyListeners();
      
      // Phase 3+: Background loading (non-blocking)
      _loadBackgroundPhases();
      
    } catch (e) {
      safePrint('🚀 ❌ Loading failed: $e');
    }
    
    _isLoading = false;
    notifyListeners();
  }

  /// Load a specific phase
  Future<void> _loadPhase(LoadingPhase phase) async {
    final taskNames = _phaseGroups[phase] ?? [];
    if (taskNames.isEmpty) return;
    
    safePrint('🚀 Loading phase: $phase (${taskNames.length} tasks)');
    
    final futures = <Future<void>>[];
    
    for (final taskName in taskNames) {
      final task = _tasks[taskName]!;
      
      // Check dependencies
      if (!_areDependenciesMet(task)) {
        safePrint('🚀 ⏳ Skipping $taskName - dependencies not met');
        task.status = SystemStatus.skipped;
        continue;
      }
      
      // Start task
      futures.add(_executeTask(task));
    }
    
    // Wait for all tasks in this phase
    await Future.wait(futures);
    
    _updateProgress();
    safePrint('🚀 ✅ Phase $phase completed');
  }

  /// Load background phases (non-blocking)
  void _loadBackgroundPhases() {
    // Load important phase in background
    _loadPhase(LoadingPhase.important).then((_) {
      _currentPhase = LoadingPhase.optional;
      notifyListeners();
      
      // Load optional phase
      return _loadPhase(LoadingPhase.optional);
    }).then((_) {
      _currentPhase = LoadingPhase.background;
      notifyListeners();
      
      // Load background phase
      return _loadPhase(LoadingPhase.background);
    }).then((_) {
      safePrint('🚀 🎉 All loading phases completed!');
      _printLoadingReport();
    }).catchError((e) {
      safePrint('🚀 ⚠️ Background loading error: $e');
    });
  }

  /// Execute a single task
  Future<void> _executeTask(LoadingTask task) async {
    task.status = SystemStatus.loading;
    task.startTime = DateTime.now();
    
    safePrint('🚀 ⏳ Loading: ${task.name}');
    
    try {
      final success = await task.task().timeout(task.timeout);
      
      task.endTime = DateTime.now();
      
      if (success) {
        task.status = SystemStatus.completed;
        _completedTasks.add(task.name);
        safePrint('🚀 ✅ Completed: ${task.name} (${task.loadTime?.inMilliseconds}ms)');
      } else {
        task.status = SystemStatus.failed;
        task.errorMessage = 'Task returned false';
        _failedTasks.add(task.name);
        safePrint('🚀 ❌ Failed: ${task.name} - Task returned false');
      }
      
    } catch (e) {
      task.endTime = DateTime.now();
      task.status = SystemStatus.failed;
      task.errorMessage = e.toString();
      _failedTasks.add(task.name);
      
      if (task.required) {
        safePrint('🚀 ❌ CRITICAL FAILURE: ${task.name} - $e');
      } else {
        safePrint('🚀 ⚠️ Optional failure: ${task.name} - $e');
      }
    }
    
    notifyListeners();
  }

  /// Check if task dependencies are met
  bool _areDependenciesMet(LoadingTask task) {
    for (final dep in task.dependencies) {
      if (!_completedTasks.contains(dep)) {
        return false;
      }
    }
    return true;
  }

  /// Update overall progress
  void _updateProgress() {
    if (_tasks.isEmpty) {
      _overallProgress = 1.0;
      return;
    }
    
    final completed = _completedTasks.length + _failedTasks.length;
    _overallProgress = completed / _tasks.length;
  }

  /// Check if a system is ready
  bool isSystemReady(String systemName) {
    return _completedTasks.contains(systemName);
  }

  /// Check if a system failed
  bool isSystemFailed(String systemName) {
    return _failedTasks.contains(systemName);
  }

  /// Get system status
  SystemStatus getSystemStatus(String systemName) {
    return _tasks[systemName]?.status ?? SystemStatus.pending;
  }

  /// Wait for specific system to be ready
  Future<bool> waitForSystem(String systemName, {Duration? timeout}) async {
    if (_completedTasks.contains(systemName)) return true;
    if (_failedTasks.contains(systemName)) return false;
    
    final completer = Completer<bool>();
    late StreamSubscription subscription;
    
    subscription = Stream.periodic(Duration(milliseconds: 100)).listen((_) {
      if (_completedTasks.contains(systemName)) {
        subscription.cancel();
        completer.complete(true);
      } else if (_failedTasks.contains(systemName)) {
        subscription.cancel();
        completer.complete(false);
      }
    });
    
    if (timeout != null) {
      Timer(timeout, () {
        if (!completer.isCompleted) {
          subscription.cancel();
          completer.complete(false);
        }
      });
    }
    
    return completer.future;
  }

  /// Print loading report
  void _printLoadingReport() {
    safePrint('🚀 📊 LOADING REPORT:');
    safePrint('🚀 Total tasks: ${_tasks.length}');
    safePrint('🚀 Completed: ${_completedTasks.length}');
    safePrint('🚀 Failed: ${_failedTasks.length}');
    
    // Show timing for each phase
    for (final phase in LoadingPhase.values) {
      final taskNames = _phaseGroups[phase] ?? [];
      if (taskNames.isEmpty) continue;
      
      final phaseTasks = taskNames.map((name) => _tasks[name]!).toList();
      final completedInPhase = phaseTasks.where((t) => t.status == SystemStatus.completed).length;
      final totalTime = phaseTasks
          .where((t) => t.loadTime != null)
          .map((t) => t.loadTime!.inMilliseconds)
          .fold(0, (a, b) => a + b);
      
      safePrint('🚀 $phase: $completedInPhase/${taskNames.length} (${totalTime}ms total)');
    }
    
    // Show failed tasks
    if (_failedTasks.isNotEmpty) {
      safePrint('🚀 ❌ Failed tasks:');
      for (final taskName in _failedTasks) {
        final task = _tasks[taskName]!;
        safePrint('🚀   - $taskName: ${task.errorMessage}');
      }
    }
  }

  /// Clear all tasks (for testing)
  void clear() {
    _tasks.clear();
    _phaseGroups.clear();
    _completedTasks.clear();
    _failedTasks.clear();
    _currentPhase = LoadingPhase.instant;
    _isLoading = false;
    _overallProgress = 0.0;
  }
}
