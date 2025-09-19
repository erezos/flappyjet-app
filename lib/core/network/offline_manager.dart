/// 📱 Offline Manager - AAA Mobile Game Standard
/// 
/// Handles offline queue and data synchronization
/// Based on patterns from successful mobile games like Clash Royale, Pokemon GO
library;

import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../debug_logger.dart';
import 'network_manager.dart';

/// Queued network request for offline processing
class QueuedRequest {
  final String id;
  final NetworkRequest request;
  final DateTime queuedAt;
  final int attempts;
  final int priority; // Higher number = higher priority

  QueuedRequest({
    required this.id,
    required this.request,
    required this.queuedAt,
    this.attempts = 0,
    this.priority = 1,
  });

  QueuedRequest copyWith({
    int? attempts,
    int? priority,
  }) {
    return QueuedRequest(
      id: id,
      request: request,
      queuedAt: queuedAt,
      attempts: attempts ?? this.attempts,
      priority: priority ?? this.priority,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'endpoint': request.endpoint,
    'method': request.method,
    'body': request.body,
    'headers': request.headers,
    'requiresAuth': request.requiresAuth,
    'queuedAt': queuedAt.millisecondsSinceEpoch,
    'attempts': attempts,
    'priority': priority,
  };

  factory QueuedRequest.fromJson(Map<String, dynamic> json) {
    return QueuedRequest(
      id: json['id'],
      request: NetworkRequest(
        endpoint: json['endpoint'],
        method: json['method'],
        body: json['body'] != null ? Map<String, dynamic>.from(json['body']) : null,
        headers: json['headers'] != null ? Map<String, String>.from(json['headers']) : null,
        requiresAuth: json['requiresAuth'] ?? true,
      ),
      queuedAt: DateTime.fromMillisecondsSinceEpoch(json['queuedAt']),
      attempts: json['attempts'] ?? 0,
      priority: json['priority'] ?? 1,
    );
  }
}

/// Offline Manager - Handles request queuing and synchronization
class OfflineManager extends ChangeNotifier {
  static final OfflineManager _instance = OfflineManager._internal();
  factory OfflineManager() => _instance;
  OfflineManager._internal();

  // Configuration
  static const String _keyOfflineQueue = 'offline_queue_v2';
  static const int maxQueueSize = 1000;
  static const int maxRetryAttempts = 5;
  static const Duration maxQueueAge = Duration(days: 7);
  static const Duration processingInterval = Duration(seconds: 30);
  
  // State
  final List<QueuedRequest> _queue = [];
  bool _isProcessing = false;
  
  // Getters
  int get queueSize => _queue.length;
  bool get isProcessing => _isProcessing;
  List<QueuedRequest> get queue => List.unmodifiable(_queue);

  /// Initialize offline manager
  Future<void> initialize() async {
    await _loadQueue();
    _startPeriodicProcessing();
    safePrint('📱 Offline Manager initialized - Queue size: ${_queue.length}');
  }

  /// Queue a request for offline processing
  Future<void> queueRequest(NetworkRequest request) async {
    // Don't queue if already at max capacity
    if (_queue.length >= maxQueueSize) {
      safePrint('📱 ⚠️ Queue at max capacity, dropping oldest requests');
      _removeOldestRequests(100); // Remove 100 oldest requests
    }

    // Generate unique ID for the request
    final id = _generateRequestId();
    
    // Determine priority based on request type
    final priority = _determinePriority(request);
    
    final queuedRequest = QueuedRequest(
      id: id,
      request: request,
      queuedAt: DateTime.now(),
      priority: priority,
    );

    _queue.add(queuedRequest);
    
    // Sort queue by priority (higher priority first)
    _queue.sort((a, b) => b.priority.compareTo(a.priority));
    
    await _saveQueue();
    notifyListeners();
    
    safePrint('📱 ✅ Request queued: ${request.endpoint} (Priority: $priority)');
  }

  /// Process the offline queue
  Future<void> processQueue(
    Future<NetworkResult<Map<String, dynamic>>> Function(NetworkRequest) requestHandler
  ) async {
    if (_isProcessing || _queue.isEmpty) return;

    _isProcessing = true;
    notifyListeners();

    try {
      final requestsToProcess = List<QueuedRequest>.from(_queue);
      final processedIds = <String>[];
      
      for (final queuedRequest in requestsToProcess) {
        // Skip if request is too old
        if (DateTime.now().difference(queuedRequest.queuedAt) > maxQueueAge) {
          processedIds.add(queuedRequest.id);
          safePrint('📱 🗑️ Removing expired request: ${queuedRequest.request.endpoint}');
          continue;
        }

        // Skip if too many attempts
        if (queuedRequest.attempts >= maxRetryAttempts) {
          processedIds.add(queuedRequest.id);
          safePrint('📱 ❌ Max retries exceeded: ${queuedRequest.request.endpoint}');
          continue;
        }

        try {
          // Process the request
          final result = await requestHandler(queuedRequest.request);
          
          if (result.success) {
            // Request succeeded - remove from queue
            processedIds.add(queuedRequest.id);
            safePrint('📱 ✅ Offline request processed: ${queuedRequest.request.endpoint}');
          } else {
            // Request failed - increment attempts
            final updatedRequest = queuedRequest.copyWith(
              attempts: queuedRequest.attempts + 1,
            );
            
            final index = _queue.indexWhere((r) => r.id == queuedRequest.id);
            if (index != -1) {
              _queue[index] = updatedRequest;
            }
            
            safePrint('📱 ⚠️ Offline request failed (attempt ${updatedRequest.attempts}): ${queuedRequest.request.endpoint}');
          }
        } catch (e) {
          safePrint('📱 ❌ Error processing offline request: $e');
          
          // Increment attempts on error
          final updatedRequest = queuedRequest.copyWith(
            attempts: queuedRequest.attempts + 1,
          );
          
          final index = _queue.indexWhere((r) => r.id == queuedRequest.id);
          if (index != -1) {
            _queue[index] = updatedRequest;
          }
        }

        // Add small delay between requests to avoid overwhelming server
        await Future.delayed(Duration(milliseconds: 100));
      }

      // Remove successfully processed requests
      _queue.removeWhere((request) => processedIds.contains(request.id));
      
      await _saveQueue();
      
      if (processedIds.isNotEmpty) {
        safePrint('📱 ✅ Processed ${processedIds.length} offline requests');
      }
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Clear all queued requests
  Future<void> clearQueue() async {
    _queue.clear();
    await _saveQueue();
    notifyListeners();
    safePrint('📱 🗑️ Offline queue cleared');
  }

  /// Remove specific request from queue
  Future<void> removeRequest(String requestId) async {
    _queue.removeWhere((request) => request.id == requestId);
    await _saveQueue();
    notifyListeners();
  }

  /// Get queue statistics
  Map<String, dynamic> getQueueStats() {
    final now = DateTime.now();
    final priorities = <int, int>{};
    final ages = <Duration>[];
    
    for (final request in _queue) {
      priorities[request.priority] = (priorities[request.priority] ?? 0) + 1;
      ages.add(now.difference(request.queuedAt));
    }
    
    return {
      'totalRequests': _queue.length,
      'isProcessing': _isProcessing,
      'priorityDistribution': priorities,
      'averageAge': ages.isNotEmpty 
        ? ages.map((age) => age.inMinutes).reduce((a, b) => a + b) / ages.length 
        : 0,
      'oldestRequest': ages.isNotEmpty 
        ? ages.map((age) => age.inMinutes).reduce((a, b) => a > b ? a : b)
        : 0,
    };
  }

  /// Load queue from storage
  Future<void> _loadQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_keyOfflineQueue);
      
      if (queueJson != null) {
        final queueData = jsonDecode(queueJson) as List;
        _queue.clear();
        
        for (final requestData in queueData) {
          try {
            final queuedRequest = QueuedRequest.fromJson(requestData);
            _queue.add(queuedRequest);
          } catch (e) {
            safePrint('📱 ⚠️ Failed to parse queued request: $e');
          }
        }
        
        // Remove expired requests
        final now = DateTime.now();
        _queue.removeWhere((request) => 
          now.difference(request.queuedAt) > maxQueueAge
        );
        
        // Sort by priority
        _queue.sort((a, b) => b.priority.compareTo(a.priority));
      }
    } catch (e) {
      safePrint('📱 ⚠️ Failed to load offline queue: $e');
      _queue.clear();
    }
  }

  /// Save queue to storage
  Future<void> _saveQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueData = _queue.map((request) => request.toJson()).toList();
      await prefs.setString(_keyOfflineQueue, jsonEncode(queueData));
    } catch (e) {
      safePrint('📱 ⚠️ Failed to save offline queue: $e');
    }
  }

  /// Start periodic queue processing
  void _startPeriodicProcessing() {
    // This would typically be handled by the NetworkManager
    // when it detects connectivity changes
  }

  /// Generate unique request ID
  String _generateRequestId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(999999);
    return 'req_${timestamp}_$random';
  }

  /// Determine request priority based on type
  int _determinePriority(NetworkRequest request) {
    // Critical game data (highest priority)
    if (request.endpoint.contains('/leaderboard/submit') ||
        request.endpoint.contains('/player/sync')) {
      return 10;
    }
    
    // Analytics and missions (medium priority)
    if (request.endpoint.contains('/analytics/') ||
        request.endpoint.contains('/missions/')) {
      return 5;
    }
    
    // Everything else (normal priority)
    return 1;
  }

  /// Remove oldest requests to make room
  void _removeOldestRequests(int count) {
    if (_queue.length <= count) {
      _queue.clear();
      return;
    }
    
    // Sort by queue time (oldest first) and remove
    _queue.sort((a, b) => a.queuedAt.compareTo(b.queuedAt));
    _queue.removeRange(0, count);
    
    // Re-sort by priority
    _queue.sort((a, b) => b.priority.compareTo(a.priority));
  }
}
