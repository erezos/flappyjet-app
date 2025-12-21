/// 📊 User Stats Repository - Local storage for user statistics
/// 
/// Manages user's core stats: scores, coins, gems, hearts
/// All operations are local and instant
library;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/local_database_manager.dart';
import '../debug_logger.dart';

/// User statistics model
@immutable
class UserStats {
  final String userId;
  final String? nickname;
  final int highScore;
  final int bestStreak;
  final int totalGamesPlayed;
  final int totalScore;
  final int coins;
  final int gems;
  final int hearts;
  final DateTime? lastHeartRegen;
  final DateTime? heartBoosterExpiry;
  final String? equippedSkinId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserStats({
    required this.userId,
    this.nickname,
    required this.highScore,
    required this.bestStreak,
    required this.totalGamesPlayed,
    required this.totalScore,
    required this.coins,
    required this.gems,
    required this.hearts,
    this.lastHeartRegen,
    this.heartBoosterExpiry,
    this.equippedSkinId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserStats.fromMap(Map<String, dynamic> map) {
    return UserStats(
      userId: map['user_id'] as String,
      nickname: map['nickname'] as String?,
      highScore: map['high_score'] as int,
      bestStreak: map['best_streak'] as int,
      totalGamesPlayed: map['total_games_played'] as int,
      totalScore: map['total_score'] as int,
      coins: map['coins'] as int,
      gems: map['gems'] as int,
      hearts: map['hearts'] as int,
      lastHeartRegen: map['last_heart_regen'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_heart_regen'] as int)
          : null,
      heartBoosterExpiry: map['heart_booster_expiry'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['heart_booster_expiry'] as int)
          : null,
      equippedSkinId: map['equipped_skin_id'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'nickname': nickname,
      'high_score': highScore,
      'best_streak': bestStreak,
      'total_games_played': totalGamesPlayed,
      'total_score': totalScore,
      'coins': coins,
      'gems': gems,
      'hearts': hearts,
      'last_heart_regen': lastHeartRegen?.millisecondsSinceEpoch,
      'heart_booster_expiry': heartBoosterExpiry?.millisecondsSinceEpoch,
      'equipped_skin_id': equippedSkinId,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  UserStats copyWith({
    String? userId,
    String? nickname,
    int? highScore,
    int? bestStreak,
    int? totalGamesPlayed,
    int? totalScore,
    int? coins,
    int? gems,
    int? hearts,
    DateTime? lastHeartRegen,
    DateTime? heartBoosterExpiry,
    String? equippedSkinId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserStats(
      userId: userId ?? this.userId,
      nickname: nickname ?? this.nickname,
      highScore: highScore ?? this.highScore,
      bestStreak: bestStreak ?? this.bestStreak,
      totalGamesPlayed: totalGamesPlayed ?? this.totalGamesPlayed,
      totalScore: totalScore ?? this.totalScore,
      coins: coins ?? this.coins,
      gems: gems ?? this.gems,
      hearts: hearts ?? this.hearts,
      lastHeartRegen: lastHeartRegen ?? this.lastHeartRegen,
      heartBoosterExpiry: heartBoosterExpiry ?? this.heartBoosterExpiry,
      equippedSkinId: equippedSkinId ?? this.equippedSkinId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserStats(userId: ${userId.substring(0, 10)}..., '
           'coins: $coins, gems: $gems, hearts: $hearts, highScore: $highScore)';
  }
}

/// Repository for user statistics
class UserStatsRepository extends ChangeNotifier {
  final LocalDatabaseManager _db;
  UserStats? _cachedStats;

  UserStatsRepository(this._db);

  /// Get current user stats
  Future<UserStats> getUserStats() async {
    if (_cachedStats != null) {
      return _cachedStats!;
    }

    final result = await _db.database.query('user_stats', where: 'id = 1', limit: 1);
    
    if (result.isEmpty) {
      throw StateError('User stats not found. Database not properly initialized.');
    }

    _cachedStats = UserStats.fromMap(result.first);
    return _cachedStats!;
  }

  /// Update user ID (usually done once during initialization)
  Future<void> setUserId(String userId) async {
    await _db.database.update(
      'user_stats',
      {
        'user_id': userId,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = 1',
    );

    _cachedStats = null; // Invalidate cache
    await getUserStats(); // Reload
    
    final truncatedId = userId.length > 20 ? userId.substring(0, 20) : userId;
    safePrint('📊 User ID set: $truncatedId...');
    notifyListeners();
  }

  /// Update nickname
  Future<void> setNickname(String nickname) async {
    await _db.database.update(
      'user_stats',
      {
        'nickname': nickname,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = 1',
    );

    _cachedStats = null;
    await getUserStats();
    
    safePrint('📊 Nickname set: $nickname');
    notifyListeners();
  }

  /// Update high score (only if new score is higher)
  Future<bool> updateHighScore(int newScore) async {
    final stats = await getUserStats();
    
    if (newScore <= stats.highScore) {
      return false; // Not a new high score
    }

    await _db.database.update(
      'user_stats',
      {
        'high_score': newScore,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = 1',
    );

    // Also save to SharedPreferences as a fallback
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('stats_high_score', newScore);
    } catch (e) {
      safePrint('⚠️ Failed to save high score to SharedPreferences: $e');
    }

    _cachedStats = null;
    await getUserStats();
    
    safePrint('📊 ⭐ New high score: $newScore (was: ${stats.highScore})');
    notifyListeners();
    
    return true;
  }

  /// Update best streak (only if new streak is better)
  Future<bool> updateBestStreak(int newStreak) async {
    final stats = await getUserStats();
    
    if (newStreak <= stats.bestStreak) {
      return false;
    }

    await _db.database.update(
      'user_stats',
      {
        'best_streak': newStreak,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = 1',
    );

    _cachedStats = null;
    await getUserStats();
    
    safePrint('📊 ⭐ New best streak: $newStreak (was: ${stats.bestStreak})');
    notifyListeners();
    
    return true;
  }

  /// Increment games played
  Future<void> incrementGamesPlayed() async {
    await _db.database.rawUpdate('''
      UPDATE user_stats 
      SET total_games_played = total_games_played + 1,
          updated_at = ?
      WHERE id = 1
    ''', [DateTime.now().millisecondsSinceEpoch]);

    _cachedStats = null;
    await getUserStats();
    
    notifyListeners();
  }

  /// Add to total score
  Future<void> addToTotalScore(int score) async {
    await _db.database.rawUpdate('''
      UPDATE user_stats 
      SET total_score = total_score + ?,
          updated_at = ?
      WHERE id = 1
    ''', [score, DateTime.now().millisecondsSinceEpoch]);

    _cachedStats = null;
    notifyListeners();
  }

  /// Add coins
  Future<void> addCoins(int amount) async {
    if (amount == 0) return;

    await _db.database.rawUpdate('''
      UPDATE user_stats 
      SET coins = coins + ?,
          updated_at = ?
      WHERE id = 1
    ''', [amount, DateTime.now().millisecondsSinceEpoch]);

    _cachedStats = null;
    final stats = await getUserStats();
    
    safePrint('📊 💰 Coins ${amount > 0 ? 'added' : 'spent'}: ${amount.abs()} (balance: ${stats.coins})');
    notifyListeners();
  }

  /// Spend coins
  Future<bool> spendCoins(int amount) async {
    if (amount <= 0) return false;

    final stats = await getUserStats();
    
    if (stats.coins < amount) {
      safePrint('📊 ❌ Insufficient coins: need $amount, have ${stats.coins}');
      return false;
    }

    await addCoins(-amount);
    return true;
  }

  /// Add gems
  Future<void> addGems(int amount) async {
    if (amount == 0) return;

    await _db.database.rawUpdate('''
      UPDATE user_stats 
      SET gems = gems + ?,
          updated_at = ?
      WHERE id = 1
    ''', [amount, DateTime.now().millisecondsSinceEpoch]);

    _cachedStats = null;
    final stats = await getUserStats();
    
    safePrint('📊 💎 Gems ${amount > 0 ? 'added' : 'spent'}: ${amount.abs()} (balance: ${stats.gems})');
    notifyListeners();
  }

  /// Spend gems
  Future<bool> spendGems(int amount) async {
    if (amount <= 0) return false;

    final stats = await getUserStats();
    
    if (stats.gems < amount) {
      safePrint('📊 ❌ Insufficient gems: need $amount, have ${stats.gems}');
      return false;
    }

    await addGems(-amount);
    return true;
  }

  /// Set hearts
  Future<void> setHearts(int hearts) async {
    hearts = hearts.clamp(0, 5); // Max 5 hearts

    await _db.database.update(
      'user_stats',
      {
        'hearts': hearts,
        'last_heart_regen': DateTime.now().millisecondsSinceEpoch,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = 1',
    );

    _cachedStats = null;
    await getUserStats();
    
    safePrint('📊 ❤️ Hearts set to: $hearts');
    notifyListeners();
  }

  /// Use one heart
  Future<bool> useHeart() async {
    final stats = await getUserStats();
    
    if (stats.hearts <= 0) {
      safePrint('📊 ❌ No hearts available');
      return false;
    }

    await setHearts(stats.hearts - 1);
    return true;
  }

  /// Regenerate hearts (called by periodic timer)
  Future<void> regenerateHearts() async {
    const heartRegenMinutes = 30;
    final stats = await getUserStats();

    if (stats.hearts >= 5) {
      return; // Already at max
    }

    final now = DateTime.now();
    final lastRegen = stats.lastHeartRegen ?? now;
    final minutesSinceRegen = now.difference(lastRegen).inMinutes;

    if (minutesSinceRegen >= heartRegenMinutes) {
      final heartsToAdd = (minutesSinceRegen / heartRegenMinutes).floor();
      final newHearts = (stats.hearts + heartsToAdd).clamp(0, 5);
      
      if (newHearts > stats.hearts) {
        await setHearts(newHearts);
        safePrint('📊 ❤️ Regenerated ${newHearts - stats.hearts} hearts');
      }
    }
  }

  /// Get average score
  Future<double> getAverageScore() async {
    final stats = await getUserStats();
    
    if (stats.totalGamesPlayed == 0) {
      return 0.0;
    }

    return stats.totalScore / stats.totalGamesPlayed;
  }

  /// Set heart booster expiry
  Future<void> setHeartBoosterExpiry(DateTime? expiry) async {
    await _db.database.update(
      'user_stats',
      {
        'heart_booster_expiry': expiry?.millisecondsSinceEpoch,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = 1',
    );

    _cachedStats = null;
    await getUserStats();
    
    safePrint('📊 💖 Heart booster expiry set: ${expiry != null ? expiry.toIso8601String() : 'null'}');
    notifyListeners();
  }

  /// Set equipped skin
  Future<void> setEquippedSkin(String skinId) async {
    await _db.database.update(
      'user_stats',
      {
        'equipped_skin_id': skinId,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = 1',
    );

    _cachedStats = null;
    await getUserStats();
    
    safePrint('📊 ✈️ Equipped skin set: $skinId');
    notifyListeners();
  }

  /// Clear cache (force reload on next access)
  void clearCache() {
    _cachedStats = null;
  }
}

