/// 🎯 Adaptive Missions Manager - Dynamic daily missions based on player skill
library;

import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'lives_manager.dart';
import 'inventory_manager.dart';

/// Mission types that adapt to player skill level
enum MissionType {
  playGames,        // Play X games
  reachScore,       // Reach Y score in a single game
  maintainStreak,   // Get Z consecutive games above threshold
  useContinue,      // Use continue R times
  changeNickname,   // One-time mission (nickname change)
  collectCoins,     // Collect X coins (from any source)
  surviveTime,      // Survive for X seconds in a game
}

/// Mission difficulty levels that determine rewards
enum MissionDifficulty {
  easy,    // 75-125 coins
  medium,  // 150-250 coins  
  hard,    // 300-500 coins
  expert,  // 600-1000 coins
}

/// Individual mission data
class Mission {
  final String id;
  final MissionType type;
  final MissionDifficulty difficulty;
  final String title;
  final String description;
  final int target;
  final int reward;
  final int progress;
  final bool completed;
  final DateTime createdAt;
  final DateTime? completedAt;

  Mission({
    required this.id,
    required this.type,
    required this.difficulty,
    required this.title,
    required this.description,
    required this.target,
    required this.reward,
    this.progress = 0,
    this.completed = false,
    required this.createdAt,
    this.completedAt,
  });

  /// Create a copy with updated progress
  Mission copyWith({
    int? progress,
    bool? completed,
    DateTime? completedAt,
  }) {
    return Mission(
      id: id,
      type: type,
      difficulty: difficulty,
      title: title,
      description: description,
      target: target,
      reward: reward,
      progress: progress ?? this.progress,
      completed: completed ?? this.completed,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'difficulty': difficulty.name,
      'title': title,
      'description': description,
      'target': target,
      'reward': reward,
      'progress': progress,
      'completed': completed,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
    };
  }

  /// Create from JSON
  factory Mission.fromJson(Map<String, dynamic> json) {
    return Mission(
      id: json['id'],
      type: MissionType.values.firstWhere((e) => e.name == json['type']),
      difficulty: MissionDifficulty.values.firstWhere((e) => e.name == json['difficulty']),
      title: json['title'],
      description: json['description'],
      target: json['target'],
      reward: json['reward'],
      progress: json['progress'] ?? 0,
      completed: json['completed'] ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      completedAt: json['completedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['completedAt'])
          : null,
    );
  }
}

/// Player statistics for adaptive mission generation
class PlayerStats {
  final int bestScore;
  final int bestStreak;
  final int totalGamesPlayed;
  final int totalContinuesUsed;
  final int averageScore;
  final int gamesPlayedToday;
  final DateTime lastPlayedDate;
  final bool hasChangedNickname;

  PlayerStats({
    required this.bestScore,
    required this.bestStreak,
    required this.totalGamesPlayed,
    required this.totalContinuesUsed,
    required this.averageScore,
    required this.gamesPlayedToday,
    required this.lastPlayedDate,
    required this.hasChangedNickname,
  });

  /// Determine player skill level for mission adaptation
  PlayerSkillLevel get skillLevel {
    if (bestScore < 10) return PlayerSkillLevel.beginner;
    if (bestScore < 25) return PlayerSkillLevel.novice;
    if (bestScore < 50) return PlayerSkillLevel.intermediate;
    if (bestScore < 100) return PlayerSkillLevel.advanced;
    return PlayerSkillLevel.expert;
  }
}

enum PlayerSkillLevel {
  beginner,    // Score < 10
  novice,      // Score 10-24
  intermediate,// Score 25-49
  advanced,    // Score 50-99
  expert,      // Score 100+
}

/// Adaptive Missions Manager - Core system for dynamic daily missions
class MissionsManager extends ChangeNotifier {
  static final MissionsManager _instance = MissionsManager._internal();
  factory MissionsManager() => _instance;
  MissionsManager._internal();

  static const String _keyDailyMissions = 'missions_daily';
  static const String _keyLastResetDate = 'missions_last_reset';
  static const String _keyCompletedMissions = 'missions_completed_history';

  List<Mission> _dailyMissions = [];
  PlayerStats? _playerStats;
  DateTime? _lastResetDate;
  bool _isInitialized = false;

  List<Mission> get dailyMissions => _dailyMissions;
  PlayerStats? get playerStats => _playerStats;
  bool get isInitialized => _isInitialized;

  /// Initialize missions system
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _loadPlayerStats();
    await _loadDailyMissions();
    await _checkDailyReset();
    
    _isInitialized = true;
    notifyListeners();
  }

  /// Load player statistics from various sources
  Future<void> _loadPlayerStats() async {
    final prefs = await SharedPreferences.getInstance();
    final livesManager = LivesManager();
    
    // Get basic stats
    final bestScore = livesManager.bestScore;
    final bestStreak = livesManager.bestStreak;
    
    // Get extended stats from preferences
    final totalGamesPlayed = prefs.getInt('stats_total_games') ?? 0;
    final totalContinuesUsed = prefs.getInt('stats_total_continues') ?? 0;
    final averageScore = totalGamesPlayed > 0 
        ? (prefs.getInt('stats_total_score') ?? 0) ~/ totalGamesPlayed
        : 0;
    final gamesPlayedToday = prefs.getInt('stats_games_today') ?? 0;
    final lastPlayedMs = prefs.getInt('stats_last_played') ?? 0;
    final lastPlayedDate = lastPlayedMs > 0 
        ? DateTime.fromMillisecondsSinceEpoch(lastPlayedMs)
        : DateTime.now().subtract(const Duration(days: 1));
    final hasChangedNickname = prefs.getBool('stats_nickname_changed') ?? false;

    _playerStats = PlayerStats(
      bestScore: bestScore,
      bestStreak: bestStreak,
      totalGamesPlayed: totalGamesPlayed,
      totalContinuesUsed: totalContinuesUsed,
      averageScore: averageScore,
      gamesPlayedToday: gamesPlayedToday,
      lastPlayedDate: lastPlayedDate,
      hasChangedNickname: hasChangedNickname,
    );
  }

  /// Load daily missions from storage
  Future<void> _loadDailyMissions() async {
    final prefs = await SharedPreferences.getInstance();
    final missionsJson = prefs.getString(_keyDailyMissions);
    final lastResetMs = prefs.getInt(_keyLastResetDate) ?? 0;
    
    _lastResetDate = lastResetMs > 0 
        ? DateTime.fromMillisecondsSinceEpoch(lastResetMs)
        : DateTime.now().subtract(const Duration(days: 1));

    if (missionsJson != null) {
      try {
        final List<dynamic> missionsList = jsonDecode(missionsJson);
        _dailyMissions = missionsList
            .map((json) => Mission.fromJson(json))
            .toList();
      } catch (e) {
        debugPrint('🎯 Error loading missions: $e');
        _dailyMissions = [];
      }
    }
  }

  /// Check if daily reset is needed (24 hours passed)
  Future<void> _checkDailyReset() async {
    final now = DateTime.now();
    final lastReset = _lastResetDate ?? DateTime.now().subtract(const Duration(days: 1));
    
    // Check if it's a new day (24 hours passed)
    if (now.difference(lastReset).inHours >= 24) {
      await _generateNewDailyMissions();
      await _saveDailyMissions();
      
      // Reset daily stats
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('stats_games_today', 0);
      
      _lastResetDate = now;
      await prefs.setInt(_keyLastResetDate, now.millisecondsSinceEpoch);
      
      debugPrint('🎯 Daily missions reset completed');
    }
  }

  /// Generate new adaptive daily missions based on player skill
  Future<void> _generateNewDailyMissions() async {
    if (_playerStats == null) return;

    final random = math.Random();
    final missions = <Mission>[];
    final now = DateTime.now();

    // Generate 4 missions: 2 easy, 1 medium, 1 hard/expert
    missions.add(_generatePlayGamesMission(_playerStats!, MissionDifficulty.easy, now));
    missions.add(_generateScoreMission(_playerStats!, MissionDifficulty.easy, now));
    missions.add(_generateStreakMission(_playerStats!, MissionDifficulty.medium, now));
    
    // Fourth mission varies based on player behavior
    final fourthMissionTypes = [MissionType.useContinue, MissionType.collectCoins, MissionType.surviveTime];
    if (!_playerStats!.hasChangedNickname && random.nextBool()) {
      missions.add(_generateNicknameMission(now));
    } else {
      final randomType = fourthMissionTypes[random.nextInt(fourthMissionTypes.length)];
      final difficulty = _playerStats!.skillLevel.index >= 3 ? MissionDifficulty.hard : MissionDifficulty.medium;
      missions.add(_generateMissionByType(randomType, _playerStats!, difficulty, now));
    }

    _dailyMissions = missions;
  }

  /// Generate play games mission
  Mission _generatePlayGamesMission(PlayerStats stats, MissionDifficulty difficulty, DateTime createdAt) {
    int target;
    int reward;
    
    switch (stats.skillLevel) {
      case PlayerSkillLevel.beginner:
        target = 3;
        reward = 75;
        break;
      case PlayerSkillLevel.novice:
        target = 4;
        reward = 100;
        break;
      case PlayerSkillLevel.intermediate:
        target = 5;
        reward = 150;
        break;
      case PlayerSkillLevel.advanced:
        target = 6;
        reward = 200;
        break;
      case PlayerSkillLevel.expert:
        target = 8;
        reward = 300;
        break;
    }

    return Mission(
      id: 'daily_play_${createdAt.millisecondsSinceEpoch}',
      type: MissionType.playGames,
      difficulty: difficulty,
      title: 'Take Flight',
      description: 'Play $target games today',
      target: target,
      reward: reward,
      createdAt: createdAt,
    );
  }

  /// Generate score mission adapted to player skill
  Mission _generateScoreMission(PlayerStats stats, MissionDifficulty difficulty, DateTime createdAt) {
    int target;
    int reward;
    
    final baseScore = stats.bestScore;
    
    if (baseScore <= 5) {
      target = 3;
      reward = 75;
    } else if (baseScore <= 10) {
      target = (baseScore * 0.6).round().clamp(5, 8);
      reward = 100;
    } else if (baseScore <= 25) {
      target = (baseScore * 0.7).round();
      reward = 150;
    } else if (baseScore <= 50) {
      target = (baseScore * 0.75).round();
      reward = 200;
    } else {
      target = (baseScore * 0.8).round();
      reward = 300;
    }

    return Mission(
      id: 'daily_score_${createdAt.millisecondsSinceEpoch}',
      type: MissionType.reachScore,
      difficulty: difficulty,
      title: 'Sky Achievement',
      description: 'Reach $target points in a single game',
      target: target,
      reward: reward,
      createdAt: createdAt,
    );
  }

  /// Generate streak mission
  Mission _generateStreakMission(PlayerStats stats, MissionDifficulty difficulty, DateTime createdAt) {
    int streakLength;
    int scoreThreshold;
    int reward;
    
    switch (stats.skillLevel) {
      case PlayerSkillLevel.beginner:
        streakLength = 2;
        scoreThreshold = 3;
        reward = 100;
        break;
      case PlayerSkillLevel.novice:
        streakLength = 3;
        scoreThreshold = 5;
        reward = 150;
        break;
      case PlayerSkillLevel.intermediate:
        streakLength = 3;
        scoreThreshold = 10;
        reward = 200;
        break;
      case PlayerSkillLevel.advanced:
        streakLength = 4;
        scoreThreshold = 20;
        reward = 300;
        break;
      case PlayerSkillLevel.expert:
        streakLength = 5;
        scoreThreshold = 30;
        reward = 500;
        break;
    }

    return Mission(
      id: 'daily_streak_${createdAt.millisecondsSinceEpoch}',
      type: MissionType.maintainStreak,
      difficulty: difficulty,
      title: 'Consistency Master',
      description: 'Score above $scoreThreshold in $streakLength consecutive games',
      target: streakLength,
      reward: reward,
      createdAt: createdAt,
    );
  }

  /// Generate nickname change mission (one-time)
  Mission _generateNicknameMission(DateTime createdAt) {
    return Mission(
      id: 'daily_nickname_${createdAt.millisecondsSinceEpoch}',
      type: MissionType.changeNickname,
      difficulty: MissionDifficulty.easy,
      title: 'Personal Touch',
      description: 'Change your nickname to personalize your profile',
      target: 1,
      reward: 200,
      createdAt: createdAt,
    );
  }

  /// Generate mission by specific type
  Mission _generateMissionByType(MissionType type, PlayerStats stats, MissionDifficulty difficulty, DateTime createdAt) {
    switch (type) {
      case MissionType.useContinue:
        return Mission(
          id: 'daily_continue_${createdAt.millisecondsSinceEpoch}',
          type: MissionType.useContinue,
          difficulty: difficulty,
          title: 'Never Give Up',
          description: 'Use continue ${difficulty == MissionDifficulty.hard ? 4 : 2} times',
          target: difficulty == MissionDifficulty.hard ? 4 : 2,
          reward: difficulty == MissionDifficulty.hard ? 300 : 150,
          createdAt: createdAt,
        );
      
      case MissionType.collectCoins:
        final target = difficulty == MissionDifficulty.hard ? 500 : 250;
        return Mission(
          id: 'daily_coins_${createdAt.millisecondsSinceEpoch}',
          type: MissionType.collectCoins,
          difficulty: difficulty,
          title: 'Treasure Hunter',
          description: 'Collect $target coins from any source',
          target: target,
          reward: difficulty == MissionDifficulty.hard ? 200 : 100,
          createdAt: createdAt,
        );
      
      case MissionType.surviveTime:
        final target = stats.skillLevel.index >= 3 ? 60 : 30;
        return Mission(
          id: 'daily_survive_${createdAt.millisecondsSinceEpoch}',
          type: MissionType.surviveTime,
          difficulty: difficulty,
          title: 'Endurance Test',
          description: 'Survive for $target seconds in a single game',
          target: target,
          reward: difficulty == MissionDifficulty.hard ? 400 : 200,
          createdAt: createdAt,
        );
      
      default:
        return _generatePlayGamesMission(stats, difficulty, createdAt);
    }
  }

  /// Update mission progress
  Future<void> updateMissionProgress(MissionType type, int amount) async {
    bool hasUpdates = false;
    
    for (int i = 0; i < _dailyMissions.length; i++) {
      final mission = _dailyMissions[i];
      if (mission.type == type && !mission.completed) {
        int newProgress;
        
        // For reach score missions, use the highest score achieved
        if (type == MissionType.reachScore) {
          newProgress = math.max(mission.progress, amount);
        } else {
          // For other missions, accumulate progress
          newProgress = (mission.progress + amount).clamp(0, mission.target);
        }
        
        final isCompleted = newProgress >= mission.target;
        
        _dailyMissions[i] = mission.copyWith(
          progress: newProgress,
          completed: isCompleted,
          completedAt: isCompleted ? DateTime.now() : null,
        );
        
        hasUpdates = true;
        
        if (isCompleted) {
          await _onMissionCompleted(_dailyMissions[i]);
          debugPrint('🎯 ✅ Mission "${mission.title}" completed! Progress: $newProgress/${mission.target}');
        } else {
          debugPrint('🎯 📈 Mission "${mission.title}" progress: $newProgress/${mission.target}');
        }
      }
    }
    
    if (hasUpdates) {
      await _saveDailyMissions();
      notifyListeners();
    }
  }

  /// Handle mission completion
  Future<void> _onMissionCompleted(Mission mission) async {
    debugPrint('🎯 Mission completed: ${mission.title} - Reward: ${mission.reward} coins');
    
    // Grant reward (coins)
    try {
      final inventory = InventoryManager();
      await inventory.grantSoftCurrency(mission.reward);
      debugPrint('💰 Mission reward granted: ${mission.reward} coins');
    } catch (e) {
      debugPrint('⚠️ Failed to grant mission reward: $e');
    }
    
    // Track completion for analytics
    await _trackMissionCompletion(mission);
  }

  /// Track mission completion for analytics
  Future<void> _trackMissionCompletion(Mission mission) async {
    final prefs = await SharedPreferences.getInstance();
    final completedMissions = prefs.getStringList(_keyCompletedMissions) ?? [];
    completedMissions.add('${mission.id}:${mission.reward}:${DateTime.now().millisecondsSinceEpoch}');
    await prefs.setStringList(_keyCompletedMissions, completedMissions);
  }

  /// Save daily missions to storage
  Future<void> _saveDailyMissions() async {
    final prefs = await SharedPreferences.getInstance();
    final missionsJson = jsonEncode(_dailyMissions.map((m) => m.toJson()).toList());
    await prefs.setString(_keyDailyMissions, missionsJson);
  }

  /// Update player stats (called from game events)
  Future<void> updatePlayerStats({
    int? newScore,
    bool? usedContinue,
    bool? changedNickname,
    int? coinsEarned,
    int? survivalTime,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (newScore != null) {
      await prefs.setInt('stats_total_games', (_playerStats?.totalGamesPlayed ?? 0) + 1);
      await prefs.setInt('stats_games_today', (_playerStats?.gamesPlayedToday ?? 0) + 1);
      await prefs.setInt('stats_total_score', 
          (prefs.getInt('stats_total_score') ?? 0) + newScore);
      await prefs.setInt('stats_last_played', DateTime.now().millisecondsSinceEpoch);
      
      // Update mission progress
      await updateMissionProgress(MissionType.playGames, 1);
      if (newScore > 0) {
        await updateMissionProgress(MissionType.reachScore, newScore);
      }
    }
    
    if (usedContinue == true) {
      await prefs.setInt('stats_total_continues', (_playerStats?.totalContinuesUsed ?? 0) + 1);
      await updateMissionProgress(MissionType.useContinue, 1);
    }
    
    if (changedNickname == true) {
      await prefs.setBool('stats_nickname_changed', true);
      await updateMissionProgress(MissionType.changeNickname, 1);
    }
    
    if (coinsEarned != null && coinsEarned > 0) {
      await updateMissionProgress(MissionType.collectCoins, coinsEarned);
    }
    
    if (survivalTime != null && survivalTime > 0) {
      await updateMissionProgress(MissionType.surviveTime, survivalTime);
    }
    
    // Reload stats
    await _loadPlayerStats();
    notifyListeners();
  }

  /// Force refresh missions (for testing or manual refresh)
  Future<void> forceRefreshMissions() async {
    await _generateNewDailyMissions();
    await _saveDailyMissions();
    _lastResetDate = DateTime.now();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLastResetDate, DateTime.now().millisecondsSinceEpoch);
    
    notifyListeners();
  }

  /// Get completion percentage for all daily missions
  double get dailyCompletionPercentage {
    if (_dailyMissions.isEmpty) return 0.0;
    final completed = _dailyMissions.where((m) => m.completed).length;
    return completed / _dailyMissions.length;
  }

  /// Get total rewards earned today
  int get totalRewardsEarnedToday {
    return _dailyMissions
        .where((m) => m.completed)
        .fold(0, (sum, mission) => sum + mission.reward);
  }
}
