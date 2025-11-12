/// 🎮 STORY MODE - LEVEL SYSTEM MANAGER
/// 
/// Central manager for all story mode level data and player progress.
/// Handles level loading, unlocking, progress tracking, and persistence.
/// 
/// ✅ MIGRATED: Now uses LevelProgressRepository for persistence (no SharedPreferences)
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../models/level_data_schema.dart';
import '../../core/debug_logger.dart';
import '../../core/repositories/level_progress_repository.dart';

class LevelSystemManager extends ChangeNotifier {
  static final LevelSystemManager _instance = LevelSystemManager._internal();
  factory LevelSystemManager() => _instance;
  LevelSystemManager._internal();

  // Dependencies
  LevelProgressRepository? _levelProgress;

  // State
  bool _isInitialized = false;
  final List<LevelData> _allLevels = [];
  final List<ZoneData> _allZones = [];
  
  // Player Progress
  int _currentLevel = 1;
  int _highestLevelUnlocked = 1;
  Set<int> _completedLevels = {};
  int _currentZone = 1;
  Set<int> _completedZones = {};
  
  // 🔥 First-attempt tracking for boss battles
  Set<int> _firstAttemptCompleted = {}; // Track which levels have been attempted at least once
  
  // Statistics (not persisted here - tracked in UserStatsRepository)
  int _totalCoinsEarned = 0;
  int _totalGemsEarned = 0;
  int _botBattlesWon = 0;
  int _botBattlesLost = 0;

  // Getters
  bool get isInitialized => _isInitialized;
  List<LevelData> get allLevels => List.unmodifiable(_allLevels);
  List<ZoneData> get allZones => List.unmodifiable(_allZones);
  int get currentLevel => _currentLevel;
  int get highestLevelUnlocked => _highestLevelUnlocked;
  Set<int> get completedLevels => Set.unmodifiable(_completedLevels);
  int get currentZone => _currentZone;
  Set<int> get completedZones => Set.unmodifiable(_completedZones);
  int get totalCoinsEarned => _totalCoinsEarned;
  int get totalGemsEarned => _totalGemsEarned;
  int get botBattlesWon => _botBattlesWon;
  int get botBattlesLost => _botBattlesLost;
  int get totalLevelsCompleted => _completedLevels.length;

  /// 🔥 Check if this is the player's first attempt at a level
  bool isFirstAttempt(int levelId) {
    return !_firstAttemptCompleted.contains(levelId);
  }

  /// Set level progress repository (call before initialize)
  void setLevelProgressRepository(LevelProgressRepository repository) {
    _levelProgress = repository;
    safePrint('📖 LevelProgressRepository injected into LevelSystemManager');
  }

  /// 🔥 Mark a level as attempted (called when level starts)
  /// ✅ MIGRATED: Now uses LevelProgressRepository
  Future<void> markLevelAttempted(int levelId) async {
    if (_firstAttemptCompleted.contains(levelId)) {
      return; // Already marked
    }
    
    _firstAttemptCompleted.add(levelId);
    
    // Save to repository
    if (_levelProgress != null) {
      await _levelProgress!.markFirstAttemptCompleted(levelId);
    }
    
    safePrint('🔥 Level $levelId: First attempt marked');
  }

  /// Initialize the level system
  Future<void> initialize() async {
    if (_isInitialized) {
      safePrint('📖 LevelSystemManager already initialized');
      return;
    }

    try {
      safePrint('📖 Initializing LevelSystemManager...');

      // Load level data from JSON files
      await _loadLevelData();
      
      // Load zones metadata
      await _loadZoneData();
      
      // Load player progress from LevelProgressRepository
      await _loadProgress();

      // ✅ FIX: Validate and fix zone unlock states (repair any inconsistencies from previous bugs)
      await _validateAndFixZoneUnlocks();

      _isInitialized = true;
      safePrint('📖 ✅ LevelSystemManager initialized successfully');
      safePrint('📖 📊 Loaded ${_allLevels.length} levels across ${_allZones.length} zones');
      safePrint('📖 📊 Current progress: Level $_currentLevel/$highestLevelUnlocked');
      
      notifyListeners();
    } catch (e, stackTrace) {
      safePrint('❌ Failed to initialize LevelSystemManager: $e');
      safePrint('Stack trace: $stackTrace');
      _isInitialized = false;
    }
  }

  /// Load level data from JSON files
  Future<void> _loadLevelData() async {
    try {
      // Load all 5 zones
      final zoneFiles = [
        'zone1_levels.json',
        'zone2_levels.json',
        'zone3_levels.json',
        'zone4_levels.json',
        'zone5_levels.json',
      ];
      
      for (int i = 0; i < zoneFiles.length; i++) {
        final zoneNumber = i + 1;
        try {
          final zoneJson = await rootBundle.loadString('assets/data/levels/${zoneFiles[i]}');
          final zoneData = json.decode(zoneJson) as Map<String, dynamic>;
          final zoneLevels = (zoneData['levels'] as List)
              .map((levelJson) => LevelData.fromJson(levelJson as Map<String, dynamic>))
              .toList();
          
          _allLevels.addAll(zoneLevels);
          
          safePrint('📖 Loaded ${zoneLevels.length} levels from Zone $zoneNumber');
        } catch (e) {
          safePrint('⚠️ Zone $zoneNumber not found or error loading: $e');
          // Don't rethrow - allow partial zone loading
        }
      }
      
      if (_allLevels.isEmpty) {
        throw Exception('No levels loaded! At least one zone must be available.');
      }
      
      safePrint('📖 ✅ Total levels loaded: ${_allLevels.length}');
    } catch (e) {
      safePrint('❌ Error loading level data: $e');
      rethrow;
    }
  }

  /// Load zone metadata from JSON
  Future<void> _loadZoneData() async {
    try {
      final zonesJson = await rootBundle.loadString('assets/data/zones.json');
      final zonesData = json.decode(zonesJson) as Map<String, dynamic>;
      final zones = (zonesData['zones'] as List)
          .map((zoneJson) => ZoneData.fromJson(zoneJson as Map<String, dynamic>))
          .toList();
      
      _allZones.addAll(zones);
      
      safePrint('📖 Loaded ${zones.length} zones');
    } catch (e) {
      safePrint('❌ Error loading zone data: $e');
      rethrow;
    }
  }

  /// Load player progress from LevelProgressRepository
  /// ✅ MIGRATED: Now uses LevelProgressRepository instead of SharedPreferences
  Future<void> _loadProgress() async {
    if (_levelProgress == null) {
      safePrint('⚠️ LevelProgressRepository not set, using default values');
      return;
    }

    try {
      final progress = await _levelProgress!.getLevelProgress();
      
      _currentLevel = progress.currentLevel;
      _highestLevelUnlocked = progress.highestUnlocked;
      _currentZone = progress.currentZone;
      
      // Parse completed levels from JSON
      _completedLevels = progress.completedLevels.toSet();
      
      // Parse completed zones from JSON
      _completedZones = progress.completedZones.toSet();
      
      // Parse first attempts from JSON
      _firstAttemptCompleted = progress.firstAttemptCompleted.toSet();
      
      safePrint('📖 Loaded progress from SQLite: Level $_currentLevel, ${_completedLevels.length} completed');
    } catch (e) {
      safePrint('❌ Error loading progress from repository: $e');
      // Use default values if loading fails
    }
  }

  /// Save player progress to LevelProgressRepository
  /// ✅ MIGRATED: Now uses LevelProgressRepository instead of SharedPreferences
  /// This method updates all progress fields in one go
  Future<void> _saveProgress() async {
    if (_levelProgress == null) {
      safePrint('⚠️ LevelProgressRepository not set, skipping save');
      return;
    }

    try {
      // Update current level and zone
      await _levelProgress!.setCurrentLevel(_currentLevel);
      await _levelProgress!.setCurrentZone(_currentZone);
      
      // Ensure highest unlocked is up to date
      if (_highestLevelUnlocked > _currentLevel) {
        await _levelProgress!.unlockLevel(_highestLevelUnlocked);
      }
      
      // Note: Completed levels/zones/first attempts are already tracked
      // via completeLevel(), completeZone(), and markFirstAttemptCompleted()
      // So we don't need to bulk update them here
      
      safePrint('📖 💾 Progress saved to SQLite');
    } catch (e) {
      safePrint('❌ Error saving progress to repository: $e');
    }
  }

  /// Validate and fix zone unlock states
  /// ✅ FIX: This repairs any inconsistencies from the previous zone completion bug
  Future<void> _validateAndFixZoneUnlocks() async {
    bool needsSave = false;

    // Check each completed zone to ensure the next zone's first level is unlocked
    for (final completedZoneId in _completedZones) {
      final nextZone = completedZoneId + 1;
      if (nextZone <= _allZones.length) {
        final nextZoneLevels = getLevelsByZone(nextZone);
        if (nextZoneLevels.isNotEmpty) {
          final firstLevelOfNextZone = nextZoneLevels.first.id;
          
          // If the first level of the next zone is not unlocked, unlock it
          if (_highestLevelUnlocked < firstLevelOfNextZone) {
            safePrint('🔧 FIX: Zone $completedZoneId is complete but level $firstLevelOfNextZone is locked');
            safePrint('🔧 FIX: Unlocking level $firstLevelOfNextZone (first level of Zone $nextZone)');
            _highestLevelUnlocked = firstLevelOfNextZone;
            needsSave = true;
          }
        }
      }
    }

    // Also ensure currentLevel is unlocked
    if (_currentLevel > _highestLevelUnlocked) {
      safePrint('🔧 FIX: Current level $_currentLevel is higher than highest unlocked $_highestLevelUnlocked');
      safePrint('🔧 FIX: Updating highest unlocked to $_currentLevel');
      _highestLevelUnlocked = _currentLevel;
      needsSave = true;
    }

    if (needsSave) {
      await _saveProgress();
      safePrint('✅ Zone unlock validation completed and fixed');
    } else {
      safePrint('✅ Zone unlock validation completed - no fixes needed');
    }
  }

  /// Get a specific level by ID
  LevelData? getLevelById(int levelId) {
    try {
      return _allLevels.firstWhere((level) => level.id == levelId);
    } catch (e) {
      safePrint('❌ Level $levelId not found');
      return null;
    }
  }

  /// Get all levels for a specific zone
  List<LevelData> getLevelsByZone(int zoneId) {
    return _allLevels.where((level) => level.zone == zoneId).toList();
  }

  /// Get a specific zone by ID
  ZoneData? getZoneById(int zoneId) {
    try {
      return _allZones.firstWhere((zone) => zone.id == zoneId);
    } catch (e) {
      safePrint('❌ Zone $zoneId not found');
      return null;
    }
  }

  /// Check if a level is unlocked
  bool isLevelUnlocked(int levelId) {
    return levelId <= _highestLevelUnlocked;
  }

  /// Check if a level is completed
  bool isLevelCompleted(int levelId) {
    return _completedLevels.contains(levelId);
  }

  /// Check if a zone is completed
  bool isZoneCompleted(int zoneId) {
    return _completedZones.contains(zoneId);
  }

  /// Check if a zone was just completed (last level just finished)
  bool wasZoneJustCompleted(int levelId) {
    final level = getLevelById(levelId);
    if (level == null) return false;

    final zoneLevels = getLevelsByZone(level.zone);
    final allZoneLevelsCompleted = zoneLevels.every((l) => _completedLevels.contains(l.id));
    
    // Zone is complete and this level is the last one in the zone
    return allZoneLevelsCompleted && levelId == zoneLevels.last.id;
  }

  /// Get zone stats for celebration screen
  Map<String, int> getZoneStats(int zoneId) {
    int coins = 0;
    int gems = 0;
    int botWins = 0;

    final zoneLevels = getLevelsByZone(zoneId);
    for (final level in zoneLevels) {
      coins += level.reward.coins;
      gems += level.reward.gems;
      if (level.botBattle != null) {
        botWins++; // Assuming all bot battles were won if level is completed
      }
    }

    return {
      'coins': coins,
      'gems': gems,
      'botWins': botWins,
    };
  }

  /// Get the current zone data
  ZoneData? getCurrentZone() {
    return getZoneById(_currentZone);
  }

  /// Get progress percentage for a zone (0-100)
  double getZoneProgress(int zoneId) {
    final zoneLevels = getLevelsByZone(zoneId);
    if (zoneLevels.isEmpty) return 0.0;
    
    final completedInZone = zoneLevels.where((level) => _completedLevels.contains(level.id)).length;
    return (completedInZone / zoneLevels.length) * 100;
  }

  /// Get all unlocked zones
  Set<int> getUnlockedZones() {
    final Set<int> unlocked = {1}; // Zone 1 always unlocked
    
    // Add zones that have been unlocked by completing previous zones
    for (int i = 1; i < _allZones.length; i++) {
      if (_completedZones.contains(i)) {
        unlocked.add(i + 1); // Unlock next zone
      }
    }
    
    return unlocked;
  }

  /// Switch to a different zone
  Future<void> setCurrentZone(int zoneId) async {
    if (zoneId < 1 || zoneId > _allZones.length) {
      safePrint('❌ Invalid zone ID: $zoneId');
      return;
    }

    final unlockedZones = getUnlockedZones();
    if (!unlockedZones.contains(zoneId)) {
      safePrint('🔒 Zone $zoneId is locked');
      return;
    }

    safePrint('🗺️ Switching to Zone $zoneId');
    _currentZone = zoneId;
    
    // Update current level to first incomplete level in this zone, or first level if all completed
    final zoneLevels = getLevelsByZone(zoneId);
    if (zoneLevels.isNotEmpty) {
      final firstIncomplete = zoneLevels.firstWhere(
        (level) => !_completedLevels.contains(level.id),
        orElse: () => zoneLevels.first,
      );
      _currentLevel = firstIncomplete.id;
    }
    
    await _saveProgress();
    notifyListeners();
  }

  /// Check if a level is being replayed (completed before)
  bool isLevelReplay(int levelId) {
    return _completedLevels.contains(levelId);
  }

  /// Unlock the next level
  Future<void> unlockNextLevel() async {
    final nextLevel = _currentLevel + 1;
    
    if (nextLevel > _allLevels.length) {
      safePrint('📖 ⚠️ No more levels to unlock (reached end)');
      return;
    }
    
    _currentLevel = nextLevel;
    _highestLevelUnlocked = nextLevel;
    
    // Update current zone based on level
    _currentZone = ((nextLevel - 1) ~/ 10) + 1;
    
    await _saveProgress();
    notifyListeners();
    
    safePrint('📖 🔓 Unlocked level $nextLevel (Zone $_currentZone)');
  }

  /// Mark a level as completed
  /// ✅ MIGRATED: Now uses LevelProgressRepository
  Future<void> completeLevel({
    required int levelId,
    required int coinsEarned,
    required int gemsEarned,
    bool? botDefeated,
  }) async {
    // Add to completed levels
    _completedLevels.add(levelId);
    
    // Save completed level to repository
    if (_levelProgress != null) {
      await _levelProgress!.completeLevel(levelId);
    }
    
    // Update totals (these are tracked locally for display, not persisted in LevelProgress)
    _totalCoinsEarned += coinsEarned;
    _totalGemsEarned += gemsEarned;
    
    // Update bot battle stats (also local display only)
    if (botDefeated != null) {
      if (botDefeated) {
        _botBattlesWon++;
      } else {
        _botBattlesLost++;
      }
    }
    
    // Check if zone is completed (all levels in zone done)
    final level = getLevelById(levelId);
    if (level != null) {
      final zoneLevels = getLevelsByZone(level.zone);
      final allZoneLevelsCompleted = zoneLevels.every((l) => _completedLevels.contains(l.id));
      
      if (allZoneLevelsCompleted && !_completedZones.contains(level.zone)) {
        _completedZones.add(level.zone);
        
        // Save completed zone to repository
        if (_levelProgress != null) {
          await _levelProgress!.completeZone(level.zone);
        }
        
        safePrint('📖 🏆 Zone ${level.zone} completed!');
        
        // Auto-advance to next zone if available
        final nextZone = level.zone + 1;
        if (nextZone <= _allZones.length) {
          _currentZone = nextZone;
          // Set current level to first level of next zone
          final nextZoneLevels = getLevelsByZone(nextZone);
          if (nextZoneLevels.isNotEmpty) {
            _currentLevel = nextZoneLevels.first.id;
            // ✅ FIX: Unlock the first level of the new zone
            _highestLevelUnlocked = _currentLevel;
          }
          safePrint('📖 ➡️ Auto-advanced to Zone $nextZone, unlocked level $_currentLevel');
        }
      }
    }
    
    // Unlock next level if this was the current level (and not already handled by zone completion)
    if (levelId == _currentLevel) {
      await unlockNextLevel();
    }
    
    await _saveProgress();
    notifyListeners();
    
    safePrint('📖 ✅ Level $levelId completed! (+$coinsEarned 🪙, +$gemsEarned 💎)');
  }

  /// Reset all progress (for testing)
  /// ✅ MIGRATED: Now uses LevelProgressRepository
  Future<void> resetProgress() async {
    _currentLevel = 1;
    _highestLevelUnlocked = 1;
    _completedLevels.clear();
    _currentZone = 1;
    _completedZones.clear();
    _totalCoinsEarned = 0;
    _totalGemsEarned = 0;
    _botBattlesWon = 0;
    _botBattlesLost = 0;
    _firstAttemptCompleted.clear(); // 🔥 Clear first attempts
    
    // Reset in repository
    if (_levelProgress != null) {
      await _levelProgress!.resetProgress();
    }
    
    notifyListeners();
    
    safePrint('📖 🔄 Progress reset to Level 1');
  }

  /// Get bot battle win rate (0-100)
  double get botWinRate {
    final totalBattles = _botBattlesWon + _botBattlesLost;
    if (totalBattles == 0) return 0.0;
    return (_botBattlesWon / totalBattles) * 100;
  }

  /// Get overall completion percentage (0-100)
  double get overallProgress {
    if (_allLevels.isEmpty) return 0.0;
    return (_completedLevels.length / _allLevels.length) * 100;
  }

  /// Dispose resources
  @override
  void dispose() {
    _allLevels.clear();
    _allZones.clear();
    _completedLevels.clear();
    _completedZones.clear();
    super.dispose();
  }
}
