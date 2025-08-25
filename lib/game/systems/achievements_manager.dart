/// 🏅 Achievements Manager - Permanent achievements system
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Achievement categories for organization
enum AchievementCategory {
  score,      // Score-based achievements
  streak,     // Consecutive games achievements  
  collection, // Jet collection achievements
  survival,   // Time-based achievements
  special,    // Special one-time achievements
  mastery,    // Advanced skill achievements
}

/// Achievement rarity affects rewards and prestige
enum AchievementRarity {
  bronze,   // 50-100 coins
  silver,   // 150-300 coins
  gold,     // 400-700 coins
  platinum, // 800-1500 coins
  diamond,  // 2000+ coins + gems
}

/// Individual achievement definition
class Achievement {
  final String id;
  final String title;
  final String description;
  final AchievementCategory category;
  final AchievementRarity rarity;
  final int target;
  final int coinReward;
  final int gemReward;
  final String iconPath;
  final bool isSecret; // Hidden until unlocked
  final int progress;
  final bool unlocked;
  final DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.rarity,
    required this.target,
    required this.coinReward,
    this.gemReward = 0,
    required this.iconPath,
    this.isSecret = false,
    this.progress = 0,
    this.unlocked = false,
    this.unlockedAt,
  });

  /// Create a copy with updated progress
  Achievement copyWith({
    int? progress,
    bool? unlocked,
    DateTime? unlockedAt,
  }) {
    return Achievement(
      id: id,
      title: title,
      description: description,
      category: category,
      rarity: rarity,
      target: target,
      coinReward: coinReward,
      gemReward: gemReward,
      iconPath: iconPath,
      isSecret: isSecret,
      progress: progress ?? this.progress,
      unlocked: unlocked ?? this.unlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  /// Progress percentage (0.0 to 1.0)
  double get progressPercentage => (progress / target).clamp(0.0, 1.0);

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'progress': progress,
      'unlocked': unlocked,
      'unlockedAt': unlockedAt?.millisecondsSinceEpoch,
    };
  }

  /// Create from JSON (only progress data, definition comes from registry)
  Achievement withProgressFromJson(Map<String, dynamic> json) {
    return copyWith(
      progress: json['progress'] ?? 0,
      unlocked: json['unlocked'] ?? false,
      unlockedAt: json['unlockedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['unlockedAt'])
          : null,
    );
  }
}

/// Achievements Manager - Handles all permanent achievements
class AchievementsManager extends ChangeNotifier {
  static final AchievementsManager _instance = AchievementsManager._internal();
  factory AchievementsManager() => _instance;
  AchievementsManager._internal();

  static const String _keyAchievements = 'achievements_progress';
  
  final Map<String, Achievement> _achievements = {};
  bool _isInitialized = false;

  Map<String, Achievement> get achievements => Map.unmodifiable(_achievements);
  bool get isInitialized => _isInitialized;

  /// Get achievements by category
  List<Achievement> getAchievementsByCategory(AchievementCategory category) {
    return _achievements.values
        .where((achievement) => achievement.category == category)
        .toList()
        ..sort((a, b) => a.rarity.index.compareTo(b.rarity.index));
  }

  /// Get unlocked achievements
  List<Achievement> get unlockedAchievements {
    return _achievements.values
        .where((achievement) => achievement.unlocked)
        .toList()
        ..sort((a, b) => b.unlockedAt!.compareTo(a.unlockedAt!));
  }

  /// Get total achievements unlocked
  int get totalUnlocked => _achievements.values.where((a) => a.unlocked).length;

  /// Get total possible achievements
  int get totalAchievements => _achievements.length;

  /// Get completion percentage
  double get completionPercentage => totalAchievements > 0 
      ? totalUnlocked / totalAchievements 
      : 0.0;

  /// Initialize achievements system
  Future<void> initialize() async {
    if (_isInitialized) return;

    _registerAllAchievements();
    await _loadProgress();
    
    _isInitialized = true;
    notifyListeners();
  }

  /// Register all achievement definitions
  void _registerAllAchievements() {
    // === SCORE ACHIEVEMENTS ===
    _registerAchievement(Achievement(
      id: 'first_flight',
      title: 'First Flight',
      description: 'Score your first point',
      category: AchievementCategory.score,
      rarity: AchievementRarity.bronze,
      target: 1,
      coinReward: 50,
      iconPath: 'achievements/first_flight.png',
    ));

    _registerAchievement(Achievement(
      id: 'rookie_pilot',
      title: 'Rookie Pilot',
      description: 'Score 10 points in a single game',
      category: AchievementCategory.score,
      rarity: AchievementRarity.bronze,
      target: 10,
      coinReward: 100,
      iconPath: 'achievements/rookie_pilot.png',
    ));

    _registerAchievement(Achievement(
      id: 'sky_navigator',
      title: 'Sky Navigator',
      description: 'Score 25 points in a single game',
      category: AchievementCategory.score,
      rarity: AchievementRarity.silver,
      target: 25,
      coinReward: 200,
      iconPath: 'achievements/sky_navigator.png',
    ));

    _registerAchievement(Achievement(
      id: 'ace_pilot',
      title: 'Ace Pilot',
      description: 'Score 50 points in a single game',
      category: AchievementCategory.score,
      rarity: AchievementRarity.gold,
      target: 50,
      coinReward: 400,
      gemReward: 5,
      iconPath: 'achievements/ace_pilot.png',
    ));

    _registerAchievement(Achievement(
      id: 'sky_master',
      title: 'Sky Master',
      description: 'Score 100 points in a single game',
      category: AchievementCategory.score,
      rarity: AchievementRarity.platinum,
      target: 100,
      coinReward: 800,
      gemReward: 10,
      iconPath: 'achievements/sky_master.png',
    ));

    _registerAchievement(Achievement(
      id: 'legendary_aviator',
      title: 'Legendary Aviator',
      description: 'Score 200 points in a single game',
      category: AchievementCategory.score,
      rarity: AchievementRarity.diamond,
      target: 200,
      coinReward: 2000,
      gemReward: 25,
      iconPath: 'achievements/legendary_aviator.png',
      isSecret: true,
    ));

    // === STREAK ACHIEVEMENTS ===
    _registerAchievement(Achievement(
      id: 'consistent_flyer',
      title: 'Consistent Flyer',
      description: 'Score above 5 in 3 consecutive games',
      category: AchievementCategory.streak,
      rarity: AchievementRarity.silver,
      target: 3,
      coinReward: 150,
      iconPath: 'achievements/consistent_flyer.png',
    ));

    _registerAchievement(Achievement(
      id: 'streak_master',
      title: 'Streak Master',
      description: 'Score above 10 in 5 consecutive games',
      category: AchievementCategory.streak,
      rarity: AchievementRarity.gold,
      target: 5,
      coinReward: 500,
      gemReward: 8,
      iconPath: 'achievements/streak_master.png',
    ));

    _registerAchievement(Achievement(
      id: 'unstoppable_force',
      title: 'Unstoppable Force',
      description: 'Score above 20 in 7 consecutive games',
      category: AchievementCategory.streak,
      rarity: AchievementRarity.platinum,
      target: 7,
      coinReward: 1000,
      gemReward: 15,
      iconPath: 'achievements/unstoppable_force.png',
    ));

    // === COLLECTION ACHIEVEMENTS ===
    _registerAchievement(Achievement(
      id: 'jet_collector',
      title: 'Jet Collector',
      description: 'Own 3 different jets',
      category: AchievementCategory.collection,
      rarity: AchievementRarity.silver,
      target: 3,
      coinReward: 300,
      iconPath: 'achievements/jet_collector.png',
    ));

    _registerAchievement(Achievement(
      id: 'fleet_commander',
      title: 'Fleet Commander',
      description: 'Own 5 different jets',
      category: AchievementCategory.collection,
      rarity: AchievementRarity.gold,
      target: 5,
      coinReward: 600,
      gemReward: 10,
      iconPath: 'achievements/fleet_commander.png',
    ));

    _registerAchievement(Achievement(
      id: 'jet_master',
      title: 'Jet Master',
      description: 'Own all available jets',
      category: AchievementCategory.collection,
      rarity: AchievementRarity.diamond,
      target: 8, // Adjust based on total jets available
      coinReward: 2500,
      gemReward: 50,
      iconPath: 'achievements/jet_master.png',
    ));

    // === SURVIVAL ACHIEVEMENTS ===
    _registerAchievement(Achievement(
      id: 'endurance_rookie',
      title: 'Endurance Rookie',
      description: 'Survive for 30 seconds in a single game',
      category: AchievementCategory.survival,
      rarity: AchievementRarity.bronze,
      target: 30,
      coinReward: 100,
      iconPath: 'achievements/endurance_rookie.png',
    ));

    _registerAchievement(Achievement(
      id: 'marathon_flyer',
      title: 'Marathon Flyer',
      description: 'Survive for 60 seconds in a single game',
      category: AchievementCategory.survival,
      rarity: AchievementRarity.silver,
      target: 60,
      coinReward: 250,
      iconPath: 'achievements/marathon_flyer.png',
    ));

    _registerAchievement(Achievement(
      id: 'iron_wings',
      title: 'Iron Wings',
      description: 'Survive for 120 seconds in a single game',
      category: AchievementCategory.survival,
      rarity: AchievementRarity.gold,
      target: 120,
      coinReward: 600,
      gemReward: 12,
      iconPath: 'achievements/iron_wings.png',
    ));

    // === SPECIAL ACHIEVEMENTS ===
    _registerAchievement(Achievement(
      id: 'identity_established',
      title: 'Identity Established',
      description: 'Change your nickname for the first time',
      category: AchievementCategory.special,
      rarity: AchievementRarity.bronze,
      target: 1,
      coinReward: 100,
      iconPath: 'achievements/identity_established.png',
    ));

    _registerAchievement(Achievement(
      id: 'never_give_up',
      title: 'Never Give Up',
      description: 'Use continue 10 times total',
      category: AchievementCategory.special,
      rarity: AchievementRarity.silver,
      target: 10,
      coinReward: 200,
      iconPath: 'achievements/never_give_up.png',
    ));

    _registerAchievement(Achievement(
      id: 'coin_collector',
      title: 'Coin Collector',
      description: 'Collect 1000 coins total',
      category: AchievementCategory.special,
      rarity: AchievementRarity.gold,
      target: 1000,
      coinReward: 500,
      gemReward: 5,
      iconPath: 'achievements/coin_collector.png',
    ));

    // === MASTERY ACHIEVEMENTS ===
    _registerAchievement(Achievement(
      id: 'perfectionist',
      title: 'Perfectionist',
      description: 'Complete 50 daily missions',
      category: AchievementCategory.mastery,
      rarity: AchievementRarity.platinum,
      target: 50,
      coinReward: 1500,
      gemReward: 20,
      iconPath: 'achievements/perfectionist.png',
    ));

    _registerAchievement(Achievement(
      id: 'dedication_incarnate',
      title: 'Dedication Incarnate',
      description: 'Play for 30 days total',
      category: AchievementCategory.mastery,
      rarity: AchievementRarity.diamond,
      target: 30,
      coinReward: 3000,
      gemReward: 100,
      iconPath: 'achievements/dedication_incarnate.png',
      isSecret: true,
    ));
  }

  /// Register a single achievement
  void _registerAchievement(Achievement achievement) {
    _achievements[achievement.id] = achievement;
  }

  /// Load achievement progress from storage
  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final progressJson = prefs.getString(_keyAchievements);
    
    if (progressJson != null) {
      try {
        final Map<String, dynamic> progressData = jsonDecode(progressJson);
        
        for (final entry in progressData.entries) {
          final achievementId = entry.key;
          final progressJson = entry.value as Map<String, dynamic>;
          
          if (_achievements.containsKey(achievementId)) {
            _achievements[achievementId] = _achievements[achievementId]!
                .withProgressFromJson(progressJson);
          }
        }
      } catch (e) {
        debugPrint('🏅 Error loading achievement progress: $e');
      }
    }
  }

  /// Save achievement progress to storage
  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final progressData = <String, dynamic>{};
    
    for (final achievement in _achievements.values) {
      if (achievement.progress > 0 || achievement.unlocked) {
        progressData[achievement.id] = achievement.toJson();
      }
    }
    
    await prefs.setString(_keyAchievements, jsonEncode(progressData));
  }

  /// Update achievement progress
  Future<void> updateProgress(String achievementId, int progress) async {
    if (!_achievements.containsKey(achievementId)) return;
    
    final achievement = _achievements[achievementId]!;
    if (achievement.unlocked) return; // Already unlocked
    
    final newProgress = (achievement.progress + progress).clamp(0, achievement.target);
    final shouldUnlock = newProgress >= achievement.target;
    
    _achievements[achievementId] = achievement.copyWith(
      progress: newProgress,
      unlocked: shouldUnlock,
      unlockedAt: shouldUnlock ? DateTime.now() : null,
    );
    
    if (shouldUnlock) {
      await _onAchievementUnlocked(achievement);
    }
    
    await _saveProgress();
    notifyListeners();
  }

  /// Set achievement progress to specific value
  Future<void> setProgress(String achievementId, int progress) async {
    if (!_achievements.containsKey(achievementId)) return;
    
    final achievement = _achievements[achievementId]!;
    if (achievement.unlocked) return;
    
    final newProgress = progress.clamp(0, achievement.target);
    final shouldUnlock = newProgress >= achievement.target;
    
    _achievements[achievementId] = achievement.copyWith(
      progress: newProgress,
      unlocked: shouldUnlock,
      unlockedAt: shouldUnlock ? DateTime.now() : null,
    );
    
    if (shouldUnlock) {
      await _onAchievementUnlocked(achievement);
    }
    
    await _saveProgress();
    notifyListeners();
  }

  /// Handle achievement unlock
  Future<void> _onAchievementUnlocked(Achievement achievement) async {
    debugPrint('🏅 Achievement unlocked: ${achievement.title}');
    debugPrint('🏅 Rewards: ${achievement.coinReward} coins, ${achievement.gemReward} gems');
    
    // Grant rewards (will be integrated with InventoryManager)
    // await InventoryManager().grantSoftCurrency(achievement.coinReward);
    // if (achievement.gemReward > 0) {
    //   await InventoryManager().grantGems(achievement.gemReward);
    // }
    
    // Track unlock for analytics
    await _trackAchievementUnlock(achievement);
  }

  /// Track achievement unlock for analytics
  Future<void> _trackAchievementUnlock(Achievement achievement) async {
    final prefs = await SharedPreferences.getInstance();
    final unlockedList = prefs.getStringList('achievements_unlocked_history') ?? [];
    unlockedList.add('${achievement.id}:${DateTime.now().millisecondsSinceEpoch}');
    await prefs.setStringList('achievements_unlocked_history', unlockedList);
  }

  /// Check and update score-based achievements
  Future<void> checkScoreAchievements(int score) async {
    await updateProgress('first_flight', score >= 1 ? 1 : 0);
    await setProgress('rookie_pilot', score);
    await setProgress('sky_navigator', score);
    await setProgress('ace_pilot', score);
    await setProgress('sky_master', score);
    await setProgress('legendary_aviator', score);
  }

  /// Check and update survival achievements
  Future<void> checkSurvivalAchievements(int survivalTimeSeconds) async {
    await setProgress('endurance_rookie', survivalTimeSeconds);
    await setProgress('marathon_flyer', survivalTimeSeconds);
    await setProgress('iron_wings', survivalTimeSeconds);
  }

  /// Check and update collection achievements
  Future<void> checkCollectionAchievements(int ownedJetsCount) async {
    await setProgress('jet_collector', ownedJetsCount);
    await setProgress('fleet_commander', ownedJetsCount);
    await setProgress('jet_master', ownedJetsCount);
  }

  /// Check and update special achievements
  Future<void> checkSpecialAchievements({
    bool? nicknameChanged,
    int? continuesUsed,
    int? totalCoinsCollected,
    int? missionsCompleted,
    int? daysPlayed,
  }) async {
    if (nicknameChanged == true) {
      await updateProgress('identity_established', 1);
    }
    
    if (continuesUsed != null) {
      await setProgress('never_give_up', continuesUsed);
    }
    
    if (totalCoinsCollected != null) {
      await setProgress('coin_collector', totalCoinsCollected);
    }
    
    if (missionsCompleted != null) {
      await setProgress('perfectionist', missionsCompleted);
    }
    
    if (daysPlayed != null) {
      await setProgress('dedication_incarnate', daysPlayed);
    }
  }

  /// Get achievements that should be displayed (non-secret or unlocked)
  List<Achievement> get visibleAchievements {
    return _achievements.values
        .where((achievement) => !achievement.isSecret || achievement.unlocked)
        .toList()
        ..sort((a, b) {
          // Sort by: unlocked first, then by rarity, then by category
          if (a.unlocked != b.unlocked) {
            return a.unlocked ? -1 : 1;
          }
          if (a.category != b.category) {
            return a.category.index.compareTo(b.category.index);
          }
          return a.rarity.index.compareTo(b.rarity.index);
        });
  }

  /// Get recently unlocked achievements (last 7 days)
  List<Achievement> get recentlyUnlocked {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return unlockedAchievements
        .where((achievement) => 
            achievement.unlockedAt != null && 
            achievement.unlockedAt!.isAfter(weekAgo))
        .toList();
  }

  /// Get total rewards earned from achievements
  Map<String, int> get totalRewardsEarned {
    int totalCoins = 0;
    int totalGems = 0;
    
    for (final achievement in unlockedAchievements) {
      totalCoins += achievement.coinReward;
      totalGems += achievement.gemReward;
    }
    
    return {'coins': totalCoins, 'gems': totalGems};
  }
}
