/// 🎮 Level Progress Repository - Story mode progress storage
/// 
/// Manages level completion, zone progress, and bot battle stats
/// All operations are local and instant
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../database/local_database_manager.dart';
import '../debug_logger.dart';

/// Level progress model
@immutable
class LevelProgress {
  final String userId;
  final int currentLevel;
  final int highestUnlocked;
  final List<int> completedLevels;
  final int currentZone;
  final List<int> completedZones;
  final List<int> firstAttemptCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LevelProgress({
    required this.userId,
    required this.currentLevel,
    required this.highestUnlocked,
    required this.completedLevels,
    required this.currentZone,
    required this.completedZones,
    required this.firstAttemptCompleted,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LevelProgress.fromMap(Map<String, dynamic> map) {
    return LevelProgress(
      userId: map['user_id'] as String,
      currentLevel: map['current_level'] as int,
      highestUnlocked: map['highest_unlocked'] as int,
      completedLevels: List<int>.from(jsonDecode(map['completed_levels'] as String)),
      currentZone: map['current_zone'] as int,
      completedZones: List<int>.from(jsonDecode(map['completed_zones'] as String)),
      firstAttemptCompleted: List<int>.from(jsonDecode(map['first_attempt_completed'] as String)),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'current_level': currentLevel,
      'highest_unlocked': highestUnlocked,
      'completed_levels': jsonEncode(completedLevels),
      'current_zone': currentZone,
      'completed_zones': jsonEncode(completedZones),
      'first_attempt_completed': jsonEncode(firstAttemptCompleted),
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  LevelProgress copyWith({
    String? userId,
    int? currentLevel,
    int? highestUnlocked,
    List<int>? completedLevels,
    int? currentZone,
    List<int>? completedZones,
    List<int>? firstAttemptCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LevelProgress(
      userId: userId ?? this.userId,
      currentLevel: currentLevel ?? this.currentLevel,
      highestUnlocked: highestUnlocked ?? this.highestUnlocked,
      completedLevels: completedLevels ?? this.completedLevels,
      currentZone: currentZone ?? this.currentZone,
      completedZones: completedZones ?? this.completedZones,
      firstAttemptCompleted: firstAttemptCompleted ?? this.firstAttemptCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'LevelProgress(currentLevel: $currentLevel, highestUnlocked: $highestUnlocked, '
           'completedLevels: ${completedLevels.length}, currentZone: $currentZone)';
  }
}

/// Repository for level progress
class LevelProgressRepository extends ChangeNotifier {
  final LocalDatabaseManager _db;
  LevelProgress? _cachedProgress;

  LevelProgressRepository(this._db);

  /// Get current level progress
  Future<LevelProgress> getLevelProgress() async {
    if (_cachedProgress != null) {
      return _cachedProgress!;
    }

    final result = await _db.database.query('level_progress', where: 'id = 1', limit: 1);
    
    if (result.isEmpty) {
      throw StateError('Level progress not found. Database not properly initialized.');
    }

    _cachedProgress = LevelProgress.fromMap(result.first);
    return _cachedProgress!;
  }

  /// Update user ID (usually done once during initialization)
  Future<void> setUserId(String userId) async {
    await _db.database.update(
      'level_progress',
      {
        'user_id': userId,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = 1',
    );

    _cachedProgress = null;
    await getLevelProgress();
    
    safePrint('🎮 Level progress user ID set');
    notifyListeners();
  }

  /// Set current level
  Future<void> setCurrentLevel(int level) async {
    await _db.database.update(
      'level_progress',
      {
        'current_level': level,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = 1',
    );

    _cachedProgress = null;
    await getLevelProgress();
    
    safePrint('🎮 Current level set to: $level');
    notifyListeners();
  }

  /// Unlock a level (update highest unlocked if necessary)
  Future<void> unlockLevel(int level) async {
    final progress = await getLevelProgress();

    if (level <= progress.highestUnlocked) {
      return; // Already unlocked
    }

    await _db.database.update(
      'level_progress',
      {
        'highest_unlocked': level,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = 1',
    );

    _cachedProgress = null;
    await getLevelProgress();
    
    safePrint('🎮 🔓 Level $level unlocked');
    notifyListeners();
  }

  /// Mark a level as completed
  Future<void> completeLevel(int level) async {
    final progress = await getLevelProgress();

    if (progress.completedLevels.contains(level)) {
      return; // Already completed
    }

    final updatedCompleted = [...progress.completedLevels, level];

    await _db.database.update(
      'level_progress',
      {
        'completed_levels': jsonEncode(updatedCompleted),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = 1',
    );

    _cachedProgress = null;
    await getLevelProgress();
    
    safePrint('🎮 ✅ Level $level completed');
    notifyListeners();
  }

  /// Mark a level as completed on first attempt (for boss battles)
  Future<void> markFirstAttemptCompleted(int level) async {
    final progress = await getLevelProgress();

    if (progress.firstAttemptCompleted.contains(level)) {
      return; // Already marked
    }

    final updatedFirstAttempts = [...progress.firstAttemptCompleted, level];

    await _db.database.update(
      'level_progress',
      {
        'first_attempt_completed': jsonEncode(updatedFirstAttempts),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = 1',
    );

    _cachedProgress = null;
    await getLevelProgress();
    
    safePrint('🎮 🏆 Level $level completed on first attempt!');
    notifyListeners();
  }

  /// Set current zone
  Future<void> setCurrentZone(int zone) async {
    await _db.database.update(
      'level_progress',
      {
        'current_zone': zone,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = 1',
    );

    _cachedProgress = null;
    await getLevelProgress();
    
    safePrint('🎮 Current zone set to: $zone');
    notifyListeners();
  }

  /// Mark a zone as completed
  Future<void> completeZone(int zone) async {
    final progress = await getLevelProgress();

    if (progress.completedZones.contains(zone)) {
      return; // Already completed
    }

    final updatedCompleted = [...progress.completedZones, zone];

    await _db.database.update(
      'level_progress',
      {
        'completed_zones': jsonEncode(updatedCompleted),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = 1',
    );

    _cachedProgress = null;
    await getLevelProgress();
    
    safePrint('🎮 🌟 Zone $zone completed!');
    notifyListeners();
  }

  /// Check if a level is completed
  Future<bool> isLevelCompleted(int level) async {
    final progress = await getLevelProgress();
    return progress.completedLevels.contains(level);
  }

  /// Check if a zone is completed
  Future<bool> isZoneCompleted(int zone) async {
    final progress = await getLevelProgress();
    return progress.completedZones.contains(zone);
  }

  /// Check if level was completed on first attempt
  Future<bool> wasCompletedOnFirstAttempt(int level) async {
    final progress = await getLevelProgress();
    return progress.firstAttemptCompleted.contains(level);
  }

  /// Reset progress to level 1 (for testing/debugging)
  Future<void> resetProgress() async {
    final now = DateTime.now();

    await _db.database.update(
      'level_progress',
      {
        'current_level': 1,
        'highest_unlocked': 1,
        'completed_levels': jsonEncode(<int>[]),
        'current_zone': 1,
        'completed_zones': jsonEncode(<int>[]),
        'first_attempt_completed': jsonEncode(<int>[]),
        'updated_at': now.millisecondsSinceEpoch,
      },
      where: 'id = 1',
    );

    _cachedProgress = null;
    await getLevelProgress();
    
    safePrint('🎮 🔄 Level progress reset to level 1');
    notifyListeners();
  }

  /// Clear cache (force reload on next access)
  void clearCache() {
    _cachedProgress = null;
  }
}

