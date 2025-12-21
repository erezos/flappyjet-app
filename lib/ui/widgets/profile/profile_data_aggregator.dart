/// 📊 Profile Data Aggregator
/// 
/// Centralized service to aggregate all profile-related data from various managers.
/// Provides a single source of truth for profile page display.
library;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../game/systems/inventory_manager.dart';
import '../../../game/systems/achievements_manager.dart';
import '../../../game/systems/missions_manager.dart';
import '../../../game/systems/tournament_manager.dart';
import '../../../game/systems/player_identity_manager.dart';
import '../../../game/systems/profile_manager.dart';
import '../../../game/systems/level_system_manager.dart';
import '../../../core/repositories/user_stats_repository.dart';
import '../../../core/database/local_database_manager.dart';
import '../../../core/debug_logger.dart';
import '../../../game/core/jet_skins.dart';

/// Aggregated profile data for display
class ProfileData {
  final String nickname;
  final int userLevel;
  final int highestScore;
  final int missionsCompleted;
  final int achievementsCompleted;
  final int tournamentsWon;
  final int totalJetsOwned;
  final int totalJetsAvailable;
  final String equippedJetId;
  
  const ProfileData({
    required this.nickname,
    required this.userLevel,
    required this.highestScore,
    required this.missionsCompleted,
    required this.achievementsCompleted,
    required this.tournamentsWon,
    required this.totalJetsOwned,
    required this.totalJetsAvailable,
    required this.equippedJetId,
  });
  
  /// Collection completion percentage
  double get collectionCompletionPercentage {
    if (totalJetsAvailable == 0) return 0.0;
    return (totalJetsOwned / totalJetsAvailable).clamp(0.0, 1.0);
  }
}

/// Profile Data Aggregator Service
/// 
/// Singleton service that aggregates profile data from multiple sources.
/// Caches data and provides reactive updates via ChangeNotifier.
class ProfileDataAggregator extends ChangeNotifier {
  static final ProfileDataAggregator _instance = ProfileDataAggregator._internal();
  factory ProfileDataAggregator() => _instance;
  ProfileDataAggregator._internal();
  
  // Dependencies
  final InventoryManager _inventory = InventoryManager();
  final AchievementsManager _achievements = AchievementsManager();
  final MissionsManager _missions = MissionsManager();
  final TournamentManager _tournaments = TournamentManager();
  final PlayerIdentityManager _playerIdentity = PlayerIdentityManager();
  final ProfileManager _profile = ProfileManager();
  final LevelSystemManager _levelSystemManager = LevelSystemManager();
  UserStatsRepository? _userStats;
  
  // Cached data
  ProfileData? _cachedData;
  bool _isInitialized = false;
  
  ProfileData? get profileData => _cachedData;
  bool get isInitialized => _isInitialized;
  
  /// Initialize the aggregator
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Try to get UserStatsRepository from LocalDatabaseManager
      try {
        final dbManager = LocalDatabaseManager();
        if (dbManager.isInitialized) {
          _userStats = UserStatsRepository(dbManager);
          safePrint('📊 ProfileDataAggregator: UserStatsRepository initialized');
        }
      } catch (e) {
        safePrint('⚠️ ProfileDataAggregator: Could not initialize UserStatsRepository: $e');
        // Continue without it - fallbacks will be used
      }
      
      // Initialize dependencies
      // Note: InventoryManager.initialize() requires eventBus, but it's already initialized in main.dart
      // We'll skip re-initialization here since it's a singleton
      // await _inventory.initialize(); // Skip - already initialized in main.dart
      await _achievements.initialize();
      await _missions.initialize();
      await _tournaments.initialize();
      await _playerIdentity.initialize();
      await _profile.initialize();
      
      // Listen to LevelSystemManager for level changes
      if (_levelSystemManager.isInitialized) {
        _levelSystemManager.addListener(_onLevelSystemChanged);
      }
      
      // Load initial data
      await refresh();
      
      _isInitialized = true;
      notifyListeners();
      
      safePrint('📊 ProfileDataAggregator initialized');
    } catch (e) {
      safePrint('❌ ProfileDataAggregator initialization error: $e');
    }
  }
  
  /// Set UserStatsRepository (called from main.dart or game initialization)
  void setUserStatsRepository(UserStatsRepository userStats) {
    _userStats = userStats;
  }
  
  /// Refresh all profile data
  Future<void> refresh() async {
    try {
      final data = await _aggregateData();
      _cachedData = data;
      notifyListeners();
    } catch (e) {
      safePrint('❌ ProfileDataAggregator refresh error: $e');
    }
  }
  
  /// Aggregate all profile data from various sources
  Future<ProfileData> _aggregateData() async {
    // Get nickname (prefer PlayerIdentityManager, fallback to ProfileManager)
    final nickname = _playerIdentity.playerName.isNotEmpty
        ? _playerIdentity.playerName
        : _profile.nickname;
    
    // Get user level (calculated from stats)
    final userLevel = await _calculateUserLevel();
    
    // Get highest score
    final highestScore = await _getHighestScore();
    
    // Get missions completed count
    final missionsCompleted = await _getMissionsCompleted();
    
    // Get achievements completed count
    final achievementsCompleted = _achievements.totalUnlocked;
    
    // Get tournaments won count
    final tournamentsWon = await _getTournamentsWon();
    
    // Get jet collection data
    final ownedJets = _inventory.ownedSkinIds;
    final totalJetsOwned = ownedJets.length;
    // Get total available jets from catalog
    final allJets = JetSkinCatalog.getAllSkins();
    final totalJetsAvailable = allJets.length;
    
    // Get equipped jet
    final equippedJetId = _inventory.equippedSkinId;
    
    return ProfileData(
      nickname: nickname,
      userLevel: userLevel,
      highestScore: highestScore,
      missionsCompleted: missionsCompleted,
      achievementsCompleted: achievementsCompleted,
      tournamentsWon: tournamentsWon,
      totalJetsOwned: totalJetsOwned,
      totalJetsAvailable: totalJetsAvailable,
      equippedJetId: equippedJetId,
    );
  }
  
  /// Get user's current story mode level
  /// 
  /// Uses LevelSystemManager to get the actual current level in story mode,
  /// which represents the player's progress through the game.
  Future<int> _calculateUserLevel() async {
    try {
      // Use LevelSystemManager to get the current story mode level
      if (_levelSystemManager.isInitialized) {
        return _levelSystemManager.currentLevel;
      }
      
      // Fallback: If LevelSystemManager not initialized, try to get from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final currentLevel = prefs.getInt('current_level') ?? 1;
      return currentLevel;
    } catch (e) {
      safePrint('⚠️ Error getting user level: $e');
      return 1; // Default to level 1
    }
  }
  
  /// Get highest score
  Future<int> _getHighestScore() async {
    try {
      // Try to initialize UserStatsRepository if not already initialized
      if (_userStats == null) {
        try {
          final dbManager = LocalDatabaseManager();
          if (dbManager.isInitialized) {
            _userStats = UserStatsRepository(dbManager);
            safePrint('📊 ProfileDataAggregator: UserStatsRepository initialized in _getHighestScore');
          }
        } catch (e) {
          safePrint('⚠️ ProfileDataAggregator: Could not initialize UserStatsRepository in _getHighestScore: $e');
        }
      }
      
      // If UserStatsRepository is available, use it
      if (_userStats != null) {
        try {
          final stats = await _userStats!.getUserStats();
          return stats.highScore;
        } catch (e) {
          safePrint('⚠️ Error getting high score from UserStatsRepository: $e');
        }
      }
      
      // Fallback: Try to get from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('stats_high_score') ?? 0;
    } catch (e) {
      safePrint('⚠️ Error getting highest score: $e');
      return 0;
    }
  }
  
  /// Get total missions completed (all time)
  Future<int> _getMissionsCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Use the same key as MissionsManager
      final completedMissions = prefs.getStringList('missions_completed_history') ?? [];
      return completedMissions.length;
    } catch (e) {
      safePrint('⚠️ Error getting missions completed: $e');
      return 0;
    }
  }
  
  /// Get tournaments won count
  Future<int> _getTournamentsWon() async {
    try {
      // Get from tournament history - count successful completions
      final history = _tournaments.history;
      final wonTournaments = history.where((entry) => entry.success).length;
      return wonTournaments;
    } catch (e) {
      safePrint('⚠️ Error getting tournaments won: $e');
      return 0;
    }
  }
  
  /// Called when LevelSystemManager notifies changes
  void _onLevelSystemChanged() {
    // Refresh profile data when level changes
    refresh();
  }
  
  @override
  void dispose() {
    // Remove listener when aggregator is disposed
    if (_levelSystemManager.isInitialized) {
      _levelSystemManager.removeListener(_onLevelSystemChanged);
    }
    super.dispose();
  }
}

