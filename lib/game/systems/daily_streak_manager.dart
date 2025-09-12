import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'inventory_manager.dart';
import 'local_notification_manager.dart';
import 'lives_manager.dart';
import '../../core/debug_logger.dart';

/// Daily streak reward types
enum DailyStreakRewardType {
  coins,
  gems,
  heartBooster,
  heart,
  jetSkin,
  mysteryBox,
}

/// Individual daily streak reward
class DailyStreakReward {
  final DailyStreakRewardType type;
  final int amount;
  final String iconFrame; // Atlas frame name
  final String? jetSkinId; // For jet skin rewards
  final String displayText;
  final String description;
  
  const DailyStreakReward({
    required this.type,
    required this.amount,
    required this.iconFrame,
    required this.displayText,
    required this.description,
    this.jetSkinId,
  });
  
  /// Get reward for new players (only 1 skin owned)
  static List<DailyStreakReward> getNewPlayerRewards() {
    return [
      const DailyStreakReward(
        type: DailyStreakRewardType.coins,
        amount: 100,
        iconFrame: 'icon/coin',
        displayText: '100',
        description: '100 Coins',
      ),
      const DailyStreakReward(
        type: DailyStreakRewardType.jetSkin,
        amount: 1,
        iconFrame: 'icon/jet',
        displayText: 'Flash Strike',
        description: 'Flash Strike Jet',
        jetSkinId: 'flash_strike',
      ),
      const DailyStreakReward(
        type: DailyStreakRewardType.heartBooster,
        amount: 1, // 1 hour
        iconFrame: 'icon/boost',
        displayText: '1h',
        description: '1 Hour Heart Booster',
      ),
      const DailyStreakReward(
        type: DailyStreakRewardType.coins,
        amount: 250,
        iconFrame: 'icon/coin',
        displayText: '250',
        description: '250 Coins',
      ),
      const DailyStreakReward(
        type: DailyStreakRewardType.heart,
        amount: 1,
        iconFrame: 'icon/heart',
        displayText: '1',
        description: '1 Heart',
      ),
      const DailyStreakReward(
        type: DailyStreakRewardType.mysteryBox,
        amount: 1,
        iconFrame: 'icon/mystery',
        displayText: '?',
        description: 'Mystery Box',
      ),
      const DailyStreakReward(
        type: DailyStreakRewardType.gems,
        amount: 15,
        iconFrame: 'icon/gem',
        displayText: '15',
        description: '15 Gems',
      ),
    ];
  }
  
  /// Get reward for experienced players (multiple skins owned)
  static List<DailyStreakReward> getExperiencedPlayerRewards() {
    return [
      const DailyStreakReward(
        type: DailyStreakRewardType.coins,
        amount: 100,
        iconFrame: 'icon/coin',
        displayText: '100',
        description: '100 Coins',
      ),
      const DailyStreakReward(
        type: DailyStreakRewardType.gems,
        amount: 5,
        iconFrame: 'icon/gem',
        displayText: '5',
        description: '5 Gems',
      ),
      const DailyStreakReward(
        type: DailyStreakRewardType.heartBooster,
        amount: 1, // 1 hour
        iconFrame: 'icon/boost',
        displayText: '1h',
        description: '1 Hour Heart Booster',
      ),
      const DailyStreakReward(
        type: DailyStreakRewardType.coins,
        amount: 250,
        iconFrame: 'icon/coin',
        displayText: '250',
        description: '250 Coins',
      ),
      const DailyStreakReward(
        type: DailyStreakRewardType.heart,
        amount: 1,
        iconFrame: 'icon/heart',
        displayText: '1',
        description: '1 Heart',
      ),
      const DailyStreakReward(
        type: DailyStreakRewardType.mysteryBox,
        amount: 1,
        iconFrame: 'icon/mystery',
        displayText: '?',
        description: 'Mystery Box',
      ),
      const DailyStreakReward(
        type: DailyStreakRewardType.gems,
        amount: 15,
        iconFrame: 'icon/gem',
        displayText: '15',
        description: '15 Gems',
      ),
    ];
  }
}

/// Daily streak state
enum DailyStreakState {
  available,    // Can claim today's reward
  claimed,      // Already claimed today
  broken,       // Streak was broken, can restore with gems
  expired,      // Grace period expired
}

/// Daily Streak Manager with smart local/cloud sync
class DailyStreakManager extends ChangeNotifier {
  static final DailyStreakManager _instance = DailyStreakManager._internal();
  factory DailyStreakManager() => _instance;
  DailyStreakManager._internal();
  
  // Storage keys
  static const String _keyCurrentStreak = 'daily_streak_current';
  static const String _keyLastClaimDate = 'daily_streak_last_claim';
  static const String _keyClaimedToday = 'daily_streak_claimed_today';
  static const String _keyStreakStartDate = 'daily_streak_start_date';
  static const String _keyTotalStreaksCompleted = 'daily_streak_total_completed';
  
  // State
  int _currentStreak = 0;
  DateTime? _lastClaimDate;
  bool _claimedToday = false;
  DateTime? _streakStartDate;
  int _totalStreaksCompleted = 0;
  
  // Dependencies
  final InventoryManager _inventory = InventoryManager();
  final LivesManager _lives = LivesManager();
  
  // Getters
  int get currentStreak => _currentStreak;
  bool get claimedToday => _claimedToday;
  DateTime? get lastClaimDate => _lastClaimDate;
  int get totalStreaksCompleted => _totalStreaksCompleted;
  
  /// Get current day index (0-6) for UI display
  int get currentDayIndex => (_currentStreak - 1).clamp(0, 6);
  
  /// Get today's reward index (0-6)
  int get todayRewardIndex => _currentStreak.clamp(1, 7) - 1;
  
  /// Get current streak state
  DailyStreakState get currentState {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    if (_lastClaimDate == null) {
      return DailyStreakState.available;
    }
    
    final lastClaim = DateTime(
      _lastClaimDate!.year,
      _lastClaimDate!.month,
      _lastClaimDate!.day,
    );
    
    final daysSinceLastClaim = today.difference(lastClaim).inDays;
    
    if (daysSinceLastClaim == 0) {
      return _claimedToday ? DailyStreakState.claimed : DailyStreakState.available;
    } else if (daysSinceLastClaim == 1) {
      return DailyStreakState.available;
    } else if (daysSinceLastClaim == 2) {
      // Grace period - can restore streak with gems
      return DailyStreakState.broken;
    } else {
      return DailyStreakState.expired;
    }
  }
  
  /// Check if user should see the daily streak popup
  bool get shouldShowPopup {
    final state = currentState;
    return state == DailyStreakState.available || 
           state == DailyStreakState.broken;
  }
  
  /// Get appropriate rewards based on player's skin collection
  List<DailyStreakReward> get currentRewards {
    final ownedSkins = _inventory.ownedSkinIds;
    
    // If player only has the starter skin, give them Flash Strike on day 2
    if (ownedSkins.length <= 1) {
      return DailyStreakReward.getNewPlayerRewards();
    } else {
      return DailyStreakReward.getExperiencedPlayerRewards();
    }
  }
  
  /// Get today's reward
  DailyStreakReward get todayReward {
    final rewards = currentRewards;
    return rewards[todayRewardIndex];
  }
  
  /// Initialize the daily streak manager
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    
    _currentStreak = prefs.getInt(_keyCurrentStreak) ?? 0;
    _claimedToday = prefs.getBool(_keyClaimedToday) ?? false;
    _totalStreaksCompleted = prefs.getInt(_keyTotalStreaksCompleted) ?? 0;
    
    final lastClaimMs = prefs.getInt(_keyLastClaimDate);
    if (lastClaimMs != null) {
      _lastClaimDate = DateTime.fromMillisecondsSinceEpoch(lastClaimMs);
    }
    
    final streakStartMs = prefs.getInt(_keyStreakStartDate);
    if (streakStartMs != null) {
      _streakStartDate = DateTime.fromMillisecondsSinceEpoch(streakStartMs);
    }
    
    // Check if we need to reset daily claim status
    await _checkDailyReset();
    
    safePrint('📅 Daily Streak initialized: streak=$_currentStreak, claimed=$_claimedToday, state=${currentState.name}');
    notifyListeners();
  }
  
  /// Check if we need to reset the daily claim status
  Future<void> _checkDailyReset() async {
    if (_lastClaimDate == null) return;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastClaim = DateTime(
      _lastClaimDate!.year,
      _lastClaimDate!.month,
      _lastClaimDate!.day,
    );
    
    final daysSinceLastClaim = today.difference(lastClaim).inDays;
    
    if (daysSinceLastClaim >= 1) {
      // Reset daily claim status
      _claimedToday = false;
      await _persistData();
      
      // Check if streak should be broken
      if (daysSinceLastClaim > 2) {
        // Streak expired - reset to 0
        await _resetStreak();
        safePrint('📅 Daily streak expired and reset');
      }
    }
  }
  
  /// Claim today's reward
  Future<bool> claimTodayReward() async {
    if (currentState != DailyStreakState.available) {
      safePrint('❌ Cannot claim reward - state: ${currentState.name}');
      return false;
    }
    
    final reward = todayReward;
    
    // Apply the reward
    final success = await _applyReward(reward);
    if (!success) {
      safePrint('❌ Failed to apply reward: ${reward.description}');
      return false;
    }
    
    // Update streak
    _currentStreak++;
    _claimedToday = true;
    _lastClaimDate = DateTime.now();
    
    // Check if completed a full 7-day cycle
    if (_currentStreak % 7 == 0) {
      _totalStreaksCompleted++;
      safePrint('🎉 Completed 7-day streak cycle! Total: $_totalStreaksCompleted');
    }
    
    // Start streak tracking on first claim
    if (_streakStartDate == null) {
      _streakStartDate = DateTime.now();
    }
    
    await _persistData();
    notifyListeners();
    
    // Cancel any existing daily streak reminder since it was claimed
    LocalNotificationManager().cancelNotification(NotificationType.dailyStreakReminder);
    
    safePrint('✅ Daily streak reward claimed: ${reward.description} (streak: $_currentStreak)');
    return true;
  }
  
  /// Restore broken streak with gems
  Future<bool> restoreStreakWithGems() async {
    const gemCost = 10; // Cost to restore streak
    
    if (currentState != DailyStreakState.broken) {
      return false;
    }
    
    if (_inventory.gems < gemCost) {
      return false;
    }
    
    // Spend gems
    final success = await _inventory.spendGems(gemCost);
    if (!success) {
      return false;
    }
    
    // Reset claim status so user can claim today
    _claimedToday = false;
    await _persistData();
    notifyListeners();
    
    safePrint('💎 Streak restored with $gemCost gems');
    return true;
  }
  
  /// Apply a reward to the player's inventory
  Future<bool> _applyReward(DailyStreakReward reward) async {
    try {
      switch (reward.type) {
        case DailyStreakRewardType.coins:
          await _inventory.addCoinsWithAnimation(reward.amount);
          break;
          
        case DailyStreakRewardType.gems:
          await _inventory.grantGems(reward.amount);
          break;
          
        case DailyStreakRewardType.heartBooster:
          await _inventory.activateHeartBooster(Duration(hours: reward.amount));
          break;
          
        case DailyStreakRewardType.heart:
          await _lives.addLife();
          break;
          
        case DailyStreakRewardType.jetSkin:
          if (reward.jetSkinId != null) {
            await _inventory.unlockSkin(reward.jetSkinId!);
            safePrint('🚁 Unlocked jet skin: ${reward.jetSkinId}');
          }
          break;
          
        case DailyStreakRewardType.mysteryBox:
          await _openMysteryBox();
          break;
      }
      return true;
    } catch (e) {
      safePrint('❌ Error applying reward: $e');
      return false;
    }
  }
  
  /// Open mystery box and give random reward
  Future<void> _openMysteryBox() async {
    // Random rewards from mystery box
    final random = DateTime.now().millisecondsSinceEpoch % 4;
    
    switch (random) {
      case 0:
        await _inventory.addCoinsWithAnimation(150);
        safePrint('🎁 Mystery box: 150 coins');
        break;
      case 1:
        await _inventory.grantGems(8);
        safePrint('🎁 Mystery box: 8 gems');
        break;
      case 2:
        await _inventory.activateHeartBooster(const Duration(minutes: 30));
        safePrint('🎁 Mystery box: 30min heart booster');
        break;
      case 3:
        await _lives.addLife();
        safePrint('🎁 Mystery box: 1 heart');
        break;
    }
  }
  
  /// Reset streak to 0
  Future<void> _resetStreak() async {
    _currentStreak = 0;
    _claimedToday = false;
    _lastClaimDate = null;
    _streakStartDate = null;
    await _persistData();
    notifyListeners();
  }
  
  /// Persist data to SharedPreferences
  Future<void> _persistData() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setInt(_keyCurrentStreak, _currentStreak);
    await prefs.setBool(_keyClaimedToday, _claimedToday);
    await prefs.setInt(_keyTotalStreaksCompleted, _totalStreaksCompleted);
    
    if (_lastClaimDate != null) {
      await prefs.setInt(_keyLastClaimDate, _lastClaimDate!.millisecondsSinceEpoch);
    } else {
      await prefs.remove(_keyLastClaimDate);
    }
    
    if (_streakStartDate != null) {
      await prefs.setInt(_keyStreakStartDate, _streakStartDate!.millisecondsSinceEpoch);
    } else {
      await prefs.remove(_keyStreakStartDate);
    }
  }
  
  /// Get streak statistics for analytics
  Map<String, dynamic> getStreakStats() {
    return {
      'current_streak': _currentStreak,
      'total_completed': _totalStreaksCompleted,
      'claimed_today': _claimedToday,
      'state': currentState.name,
      'days_since_start': _streakStartDate != null 
          ? DateTime.now().difference(_streakStartDate!).inDays 
          : 0,
    };
  }
  
  /// Reset all data (for testing/debugging)
  Future<void> resetAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCurrentStreak);
    await prefs.remove(_keyLastClaimDate);
    await prefs.remove(_keyClaimedToday);
    await prefs.remove(_keyStreakStartDate);
    await prefs.remove(_keyTotalStreaksCompleted);
    
    _currentStreak = 0;
    _claimedToday = false;
    _lastClaimDate = null;
    _streakStartDate = null;
    _totalStreaksCompleted = 0;
    
    notifyListeners();
    safePrint('🔄 Daily streak data reset');
  }
}
