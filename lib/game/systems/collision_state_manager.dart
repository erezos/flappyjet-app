/// 🎯 COLLISION STATE MANAGER - Prevents duplicate scoring and collision bugs
/// Fixes the +5 score bug by managing collision states properly
library;
import '../../core/debug_logger.dart';

import 'dart:collection';
import 'package:flame/components.dart';

/// Collision state for tracking individual collisions
enum CollisionState {
  none,        // No collision detected
  approaching, // Object is approaching collision zone
  colliding,   // Currently colliding
  passed,      // Object has been passed (scored)
  processed,   // Collision has been fully processed
}

/// Individual collision tracker for game objects
class CollisionTracker {
  final String objectId;
  final Vector2 position;
  CollisionState state;
  DateTime lastStateChange;
  bool hasScored;
  bool hasDamaged;
  int framesSinceLastUpdate;
  
  CollisionTracker({
    required this.objectId,
    required this.position,
    this.state = CollisionState.none,
  }) : lastStateChange = DateTime.now(),
       hasScored = false,
       hasDamaged = false,
       framesSinceLastUpdate = 0;

  /// Update collision state with validation
  void updateState(CollisionState newState) {
    if (newState != state) {
      safePrint('🎯 Collision [$objectId]: ${state.name} → ${newState.name}');
      state = newState;
      lastStateChange = DateTime.now();
      framesSinceLastUpdate = 0;
    } else {
      framesSinceLastUpdate++;
    }
  }

  /// Check if collision can score (prevents duplicate scoring)
  bool canScore() {
    return !hasScored && 
           (state == CollisionState.passed || state == CollisionState.approaching) &&
           framesSinceLastUpdate > 2; // Prevent immediate re-scoring
  }

  /// Mark as scored (prevents duplicate scoring)
  void markScored() {
    hasScored = true;
    safePrint('🏆 Score marked for [$objectId] - preventing duplicates');
  }

  /// Check if collision can cause damage
  bool canDamage() {
    return !hasDamaged && 
           state == CollisionState.colliding &&
           framesSinceLastUpdate > 1; // Prevent frame-perfect double hits
  }

  /// Mark as damaged (prevents duplicate damage)
  void markDamaged() {
    hasDamaged = true;
    safePrint('💥 Damage marked for [$objectId] - preventing duplicates');
  }

  /// Check if tracker is stale and should be cleaned up
  bool isStale() {
    final age = DateTime.now().difference(lastStateChange);
    return age.inSeconds > 10 || // 10 seconds without state change
           (state == CollisionState.processed && age.inSeconds > 2);
  }
}

/// 🎯 COLLISION STATE MANAGER - Centralized collision tracking
class CollisionStateManager {
  static CollisionStateManager? _instance;
  static CollisionStateManager get instance => _instance ??= CollisionStateManager._();
  
  CollisionStateManager._();

  // Active collision trackers
  final Map<String, CollisionTracker> _trackers = {};
  final Queue<String> _recentlyProcessed = Queue<String>();
  
  // Performance tracking
  int _totalCollisionsDetected = 0;
  int _duplicateCollisionsPrevented = 0;
  int _scoresAwarded = 0;
  int _damageDealt = 0;
  
  // Configuration
  static const int maxRecentlyProcessed = 50;
  static const double scoringZoneWidth = 10.0; // Pixels
  static const int cleanupInterval = 120; // frames (2 seconds at 60fps)
  
  int _frameCounter = 0;

  /// Register or update collision tracker
  CollisionTracker registerCollision({
    required String objectId,
    required Vector2 objectPosition,
    required Vector2 playerPosition,
    required double objectWidth,
  }) {
    _totalCollisionsDetected++;
    
    // Get or create tracker
    CollisionTracker tracker = _trackers[objectId] ?? CollisionTracker(
      objectId: objectId,
      position: objectPosition.clone(),
    );

    // Calculate collision state based on positions
    final CollisionState newState = _calculateCollisionState(
      playerPosition: playerPosition,
      objectPosition: objectPosition,
      objectWidth: objectWidth,
      currentState: tracker.state,
    );

    // Update state
    tracker.updateState(newState);
    tracker.position.setFrom(objectPosition);
    
    // Store tracker
    _trackers[objectId] = tracker;
    
    return tracker;
  }

  /// Calculate collision state based on positions
  CollisionState _calculateCollisionState({
    required Vector2 playerPosition,
    required Vector2 objectPosition,
    required double objectWidth,
    required CollisionState currentState,
  }) {
    final playerX = playerPosition.x;
    final objectLeft = objectPosition.x;
    final objectRight = objectPosition.x + objectWidth;

    // Check if player is colliding with object
    if (playerX >= objectLeft && playerX <= objectRight) {
      return CollisionState.colliding;
    }

    // Check if player has passed the object (scoring zone)
    if (playerX > objectRight && playerX <= objectRight + scoringZoneWidth) {
      // Only transition to passed if we were approaching or colliding
      if (currentState == CollisionState.approaching || 
          currentState == CollisionState.colliding) {
        return CollisionState.passed;
      }
    }

    // Check if player is approaching
    if (playerX < objectLeft && playerX > objectLeft - scoringZoneWidth) {
      return CollisionState.approaching;
    }

    // Player is far from object
    if (playerX > objectRight + scoringZoneWidth) {
      return CollisionState.processed;
    }

    return CollisionState.none;
  }

  /// Process scoring with duplicate prevention
  bool processScoring(String objectId) {
    final tracker = _trackers[objectId];
    if (tracker == null) return false;

    // Check if already processed recently
    if (_recentlyProcessed.contains(objectId)) {
      _duplicateCollisionsPrevented++;
      safePrint('🚫 Duplicate scoring prevented for [$objectId]');
      return false;
    }

    // Check if can score
    if (!tracker.canScore()) {
      safePrint('🚫 Scoring not allowed for [$objectId] - state: ${tracker.state.name}, hasScored: ${tracker.hasScored}');
      return false;
    }

    // Award score
    tracker.markScored();
    _scoresAwarded++;
    
    // Add to recently processed
    _recentlyProcessed.add(objectId);
    if (_recentlyProcessed.length > maxRecentlyProcessed) {
      _recentlyProcessed.removeFirst();
    }

    safePrint('🏆 Score awarded for [$objectId] - Total scores: $_scoresAwarded');
    return true;
  }

  /// Process damage with duplicate prevention
  bool processDamage(String objectId) {
    final tracker = _trackers[objectId];
    if (tracker == null) return false;

    // Check if can damage
    if (!tracker.canDamage()) {
      _duplicateCollisionsPrevented++;
      safePrint('🚫 Duplicate damage prevented for [$objectId]');
      return false;
    }

    // Deal damage
    tracker.markDamaged();
    _damageDealt++;

    safePrint('💥 Damage dealt for [$objectId] - Total damage: $_damageDealt');
    return true;
  }

  /// Get collision state for object
  CollisionState? getCollisionState(String objectId) {
    return _trackers[objectId]?.state;
  }

  /// Check if object has been scored
  bool hasScored(String objectId) {
    return _trackers[objectId]?.hasScored ?? false;
  }

  /// Check if object has caused damage
  bool hasDamaged(String objectId) {
    return _trackers[objectId]?.hasDamaged ?? false;
  }

  /// Update system (call every frame)
  void update() {
    _frameCounter++;
    
    // Cleanup stale trackers periodically
    if (_frameCounter % cleanupInterval == 0) {
      _cleanupStaleTrackers();
    }
  }

  /// Remove stale collision trackers
  void _cleanupStaleTrackers() {
    final toRemove = <String>[];
    
    for (final entry in _trackers.entries) {
      if (entry.value.isStale()) {
        toRemove.add(entry.key);
      }
    }
    
    for (final key in toRemove) {
      _trackers.remove(key);
    }
    
    if (toRemove.isNotEmpty) {
      safePrint('🧹 Cleaned up ${toRemove.length} stale collision trackers');
    }
  }

  /// Remove specific collision tracker
  void removeTracker(String objectId) {
    _trackers.remove(objectId);
    safePrint('🗑️ Removed collision tracker for [$objectId]');
  }

  /// Clear all trackers (for game reset)
  void clearAll() {
    final count = _trackers.length;
    _trackers.clear();
    _recentlyProcessed.clear();
    _frameCounter = 0;
    
    safePrint('🧹 Cleared all collision trackers ($count removed)');
  }

  /// Get performance metrics
  Map<String, dynamic> getPerformanceMetrics() {
    final duplicateRate = _totalCollisionsDetected > 0 
        ? (_duplicateCollisionsPrevented / _totalCollisionsDetected * 100).toStringAsFixed(1)
        : '0.0';
    
    return {
      'active_trackers': _trackers.length,
      'total_collisions_detected': _totalCollisionsDetected,
      'duplicates_prevented': _duplicateCollisionsPrevented,
      'duplicate_prevention_rate_percent': duplicateRate,
      'scores_awarded': _scoresAwarded,
      'damage_dealt': _damageDealt,
      'recently_processed_count': _recentlyProcessed.length,
      'frame_counter': _frameCounter,
    };
  }

  /// Get debug information for specific object
  Map<String, dynamic>? getDebugInfo(String objectId) {
    final tracker = _trackers[objectId];
    if (tracker == null) return null;
    
    return {
      'object_id': objectId,
      'state': tracker.state.name,
      'has_scored': tracker.hasScored,
      'has_damaged': tracker.hasDamaged,
      'frames_since_update': tracker.framesSinceLastUpdate,
      'last_state_change': tracker.lastStateChange.toIso8601String(),
      'position': '(${tracker.position.x.toStringAsFixed(1)}, ${tracker.position.y.toStringAsFixed(1)})',
    };
  }
}

/// 🎯 COLLISION EXTENSIONS - Convenience methods
extension CollisionManagerExtensions on CollisionStateManager {
  /// Quick collision check with automatic registration
  bool checkCollision({
    required String objectId,
    required Vector2 objectPosition,
    required Vector2 playerPosition,
    required double objectWidth,
    required double objectHeight,
    required double playerWidth,
    required double playerHeight,
  }) {
    // Register collision
    registerCollision(
      objectId: objectId,
      objectPosition: objectPosition,
      playerPosition: playerPosition,
      objectWidth: objectWidth,
    );
    
    // Check for actual collision (AABB)
    final playerLeft = playerPosition.x;
    final playerRight = playerPosition.x + playerWidth;
    final playerTop = playerPosition.y;
    final playerBottom = playerPosition.y + playerHeight;
    
    final objectLeft = objectPosition.x;
    final objectRight = objectPosition.x + objectWidth;
    final objectTop = objectPosition.y;
    final objectBottom = objectPosition.y + objectHeight;
    
    return playerRight > objectLeft &&
           playerLeft < objectRight &&
           playerBottom > objectTop &&
           playerTop < objectBottom;
  }
}