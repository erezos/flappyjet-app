import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'inventory_manager.dart';
import 'local_notification_manager.dart';
import 'lives_manager.dart';
import '../../core/debug_logger.dart';
import '../../core/events/event_bus.dart';

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
        amount: 15, // 15 minutes
        iconFrame: 'icon/boost',
        displayText: '15m',
        description: '15 Minutes Heart Booster',
      ),
      const DailyStreakReward(
        type: DailyStreakRewardType.coins,
        amount: 250,
        iconFrame: 'icon/coin',
        displayText: '250',
        description: '250 Coins',
      ),
      const DailyStreakReward(
        type: DailyStreakRewardType.heartBooster,
        amount: 30, // 30 minutes
        iconFrame: 'icon/boost',
        displayText: '30m',
        description: '30 Minutes Heart Booster',
      ),
      const DailyStreakReward(
        type: DailyStreakRewardType.jetSkin,
        amount: 1,
        iconFrame: 'icon/jet',
        displayText: 'Jet',
        description: 'Jet Skin',
        jetSkinId: 'progressive_jet', // ✅ UPDATED: Mystery Box → Progressive Jet System
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
        amount: 10, // ✅ UPDATED: 5 → 10 gems (more balanced vs Flash Strike jet value)
        iconFrame: 'icon/gem',
        displayText: '10',
        description: '10 Gems',
      ),
      const DailyStreakReward(
        type: DailyStreakRewardType.heartBooster,
        amount: 15, // 15 minutes
        iconFrame: 'icon/boost',
        displayText: '15m',
        description: '15 Minutes Heart Booster',
      ),
      const DailyStreakReward(
        type: DailyStreakRewardType.coins,
        amount: 250,
        iconFrame: 'icon/coin',
        displayText: '250',
        description: '250 Coins',
      ),
      const DailyStreakReward(
        type: DailyStreakRewardType.heartBooster,
        amount: 30, // 30 minutes
        iconFrame: 'icon/boost',
        displayText: '30m',
        description: '30 Minutes Heart Booster',
      ),
      const DailyStreakReward(
        type: DailyStreakRewardType.jetSkin,
        amount: 1,
        iconFrame: 'icon/jet',
        displayText: 'Jet',
        description: 'Jet Skin',
        jetSkinId: 'progressive_jet', // ✅ UPDATED: Mystery Box → Progressive Jet System
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
  expired,      // Streak was broken - must start over
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
  static const String _keyCurrentCycle = 'daily_streak_current_cycle';
  static const String _keyCycleStartDate = 'daily_streak_cycle_start';
  static const String _keyCurrentCycleRewardSet = 'daily_streak_cycle_reward_set';
  
  // State
  int _currentStreak = 0;
  DateTime? _lastClaimDate;
  bool _claimedToday = false;
  DateTime? _streakStartDate;
  int _totalStreaksCompleted = 0;
  int _currentCycle = 0;
  DateTime? _cycleStartDate;
  String? _currentCycleRewardSet; // 'new_player' or 'experienced'
  
  // ✅ FIX: Track the actual jet ID that was unlocked (for progressive jet system)
  String? _lastUnlockedJetId;
  
  // Dependencies
  final InventoryManager _inventory = InventoryManager();
  final LivesManager _lives = LivesManager();
  
  // Getters
  int get currentStreak => _currentStreak;
  bool get claimedToday => _claimedToday;
  DateTime? get lastClaimDate => _lastClaimDate;
  int get totalStreaksCompleted => _totalStreaksCompleted;
  int get currentCycle => _currentCycle;
  DateTime? get cycleStartDate => _cycleStartDate;
  String? get currentCycleRewardSet => _currentCycleRewardSet;
  
  /// ✅ FIX: Get the actual jet ID that was unlocked (for progressive jet system)
  /// Returns null if no jet was unlocked or if the last reward wasn't a jet
  String? get lastUnlockedJetId => _lastUnlockedJetId;
  
  /// Get current day index (0-6) for UI display
  int get currentDayIndex => (_currentStreak - 1).clamp(0, 6);
  
  /// Get today's reward index (0-6) - FIXED: Proper cycle management
  int get todayRewardIndex {
    // The reward index should be based on what day we're ABOUT TO claim
    // _currentStreak represents completed days, so the next day is _currentStreak + 1
    final nextDay = _currentStreak + 1;
    final dayInCycle = (nextDay - 1) % 7;
    return dayInCycle; // 0-6, maps days 1-7 to indices 0-6
  }
  
  /// Check if current cycle is complete
  bool get isCycleComplete => _currentStreak > 0 && _currentStreak % 7 == 0;
  
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
    } else {
      // Streak broken - must start over (no grace period)
      return DailyStreakState.expired;
    }
  }
  
  /// Check if user should see the daily streak popup
  bool get shouldShowPopup {
    final state = currentState;
    return state == DailyStreakState.available;
  }
  
  /// Get appropriate rewards based on current cycle's reward set
  /// FIXED: Maintains consistency throughout the cycle
  List<DailyStreakReward> get currentRewards {
    // If we're in the middle of a cycle, use the cycle's reward set
    if (_currentCycleRewardSet != null) {
      return _currentCycleRewardSet == 'new_player' 
          ? DailyStreakReward.getNewPlayerRewards()
          : DailyStreakReward.getExperiencedPlayerRewards();
    }
    
    // For new cycles, determine based on current skin count
    final ownedSkins = _inventory.ownedSkinIds;
    if (ownedSkins.length <= 1) {
      return DailyStreakReward.getNewPlayerRewards();
    } else {
      return DailyStreakReward.getExperiencedPlayerRewards();
    }
  }
  
  /// Get today's reward
  DailyStreakReward get todayReward {
    final rewards = currentRewards;
    final index = todayRewardIndex;
    
    // Validate index bounds
    if (index < 0 || index >= rewards.length) {
      safePrint('⚠️ Invalid reward index: $index (max: ${rewards.length - 1})');
      return rewards[0]; // Fallback to first reward
    }
    
    // Debug logging to prevent similar bugs
    if (kDebugMode) {
      safePrint('🎯 Daily Streak Reward Debug:');
      safePrint('  currentStreak: $_currentStreak');
      safePrint('  currentCycle: $_currentCycle');
      safePrint('  cycleRewardSet: $_currentCycleRewardSet');
      safePrint('  todayRewardIndex: $index');
      safePrint('  reward: ${rewards[index].description}');
      safePrint('  displayText: ${rewards[index].displayText}');
    }
    
    return rewards[index];
  }
  
  /// Initialize the daily streak manager
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    
    _currentStreak = prefs.getInt(_keyCurrentStreak) ?? 0;
    _claimedToday = prefs.getBool(_keyClaimedToday) ?? false;
    _totalStreaksCompleted = prefs.getInt(_keyTotalStreaksCompleted) ?? 0;
    _currentCycle = prefs.getInt(_keyCurrentCycle) ?? 0;
    _currentCycleRewardSet = prefs.getString(_keyCurrentCycleRewardSet);
    
    final lastClaimMs = prefs.getInt(_keyLastClaimDate);
    if (lastClaimMs != null) {
      _lastClaimDate = DateTime.fromMillisecondsSinceEpoch(lastClaimMs);
    }
    
    final streakStartMs = prefs.getInt(_keyStreakStartDate);
    if (streakStartMs != null) {
      _streakStartDate = DateTime.fromMillisecondsSinceEpoch(streakStartMs);
    }
    
    final cycleStartMs = prefs.getInt(_keyCycleStartDate);
    if (cycleStartMs != null) {
      _cycleStartDate = DateTime.fromMillisecondsSinceEpoch(cycleStartMs);
    }
    
    // Validate and recover state
    await _validateAndRecoverState();
    
    // Check if we need to reset daily claim status
    await _checkDailyReset();
    
    // ✅ NEW: Schedule notification if user hasn't claimed today
    if (!_claimedToday && currentState == DailyStreakState.available) {
      await _scheduleNextDayReminder();
    }
    
    safePrint('📅 Daily Streak initialized: streak=$_currentStreak, cycle=$_currentCycle, rewardSet=$_currentCycleRewardSet, claimed=$_claimedToday, state=${currentState.name}');
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
      // Reset daily claim status - CRITICAL FIX
      _claimedToday = false;
      safePrint('📅 Daily reset: _claimedToday set to false (days since last claim: $daysSinceLastClaim)');
      await _persistData();
      
      // Check if streak should be broken
      if (daysSinceLastClaim > 1) {
        // Streak broken - reset to 0 (no grace period)
        await _resetStreak();
        safePrint('📅 Daily streak broken and reset (missed $daysSinceLastClaim days)');
      }
    }
  }
  
  /// 🔄 Restore streak from backend (for user restoration after reinstall)
  Future<void> restoreStreak(int streak) async {
    _currentStreak = streak;
    _streakStartDate = DateTime.now().subtract(Duration(days: streak));
    await _persistData();
    notifyListeners();
    safePrint('🔥 Daily streak restored: $streak days');
  }
  
  /// 🔄 Restore complete cycle data from backend
  Future<void> restoreCycleData({
    required int currentCycle,
    required String cycleRewardSet,
    required int totalCyclesCompleted,
    DateTime? cycleStartDate,
  }) async {
    _currentCycle = currentCycle;
    _currentCycleRewardSet = cycleRewardSet;
    _totalStreaksCompleted = totalCyclesCompleted;
    _cycleStartDate = cycleStartDate;
    
    await _persistData();
    notifyListeners();
    safePrint('🔥 Cycle data restored: cycle=$currentCycle, rewardSet=$cycleRewardSet, totalCycles=$totalCyclesCompleted');
  }
  
  /// Validate and recover state from impossible conditions
  Future<void> _validateAndRecoverState() async {
    // Check for impossible states
    if (_currentStreak < 0) {
      safePrint('⚠️ Invalid streak: $_currentStreak, resetting to 0');
      _currentStreak = 0;
    }
    
    if (_currentCycle < 0) {
      safePrint('⚠️ Invalid cycle: $_currentCycle, resetting to 0');
      _currentCycle = 0;
    }
    
    // Check for missing cycle start date
    if (_currentCycle > 0 && _cycleStartDate == null) {
      safePrint('⚠️ Missing cycle start date, setting to now');
      _cycleStartDate = DateTime.now();
    }
    
    // Determine reward set if missing
    if (_currentCycleRewardSet == null && _currentStreak > 0) {
      final ownedSkins = _inventory.ownedSkinIds;
      _currentCycleRewardSet = ownedSkins.length <= 1 ? 'new_player' : 'experienced';
      safePrint('⚠️ Missing cycle reward set, determined: $_currentCycleRewardSet');
    }
    
    await _persistData();
  }
  
  /// Complete current cycle and start new one
  Future<void> _completeCycle() async {
    _totalStreaksCompleted++;
    _currentCycle++;
    
    // Determine reward set for new cycle
    final ownedSkins = _inventory.ownedSkinIds;
    _currentCycleRewardSet = ownedSkins.length <= 1 ? 'new_player' : 'experienced';
    
    // Reset streak for new cycle (Day 1 of new cycle)
    _currentStreak = 0;
    _cycleStartDate = DateTime.now();
    
    // ✅ CRITICAL FIX: DO NOT reset _claimedToday here!
    // The user just claimed Day 7 TODAY, so _claimedToday should remain true.
    // It will be reset to false by _checkDailyReset() when the next day arrives.
    // Resetting it here would allow double-claiming on the same day (Day 7 + Day 1).
    
    safePrint('🎉 Completed cycle $_currentCycle! Starting new cycle with $_currentCycleRewardSet rewards');
    
    // Trigger cycle completion analytics (via EventBus → Railway backend)
    EventBus().fire('daily_streak_cycle_completed', {
      'cycle_number': _currentCycle,
      'total_cycles_completed': _totalStreaksCompleted,
      'reward_set': _currentCycleRewardSet ?? 'new_player',
    });
    safePrint('🏆 daily_streak_cycle_completed event fired (cycle $_currentCycle)');
    
    await _persistData();
    notifyListeners();
  }

  /// Claim today's reward (optimized with batching)
  Future<bool> claimTodayReward() async {
    safePrint('🎯 Daily Streak Claim Debug: streak=$_currentStreak, cycle=$_currentCycle, claimedToday=$_claimedToday, state=${currentState.name}');
    
    if (currentState != DailyStreakState.available) {
      safePrint('❌ Cannot claim reward - state: ${currentState.name}');
      return false;
    }
    
    final reward = todayReward;
    
    // Apply the reward first (this is the critical operation)
    final success = await _applyReward(reward);
    if (!success) {
      safePrint('❌ Failed to apply reward: ${reward.description}');
      return false;
    }
    
    // Update local state immediately (synchronous operations)
    _currentStreak++;
    _claimedToday = true;
    _lastClaimDate = DateTime.now();
    _lastUnlockedJetId = null; // Reset - will be set by _applyReward if jet is unlocked
    
    // CRITICAL FIX: Handle cycle completion
    if (isCycleComplete) {
      safePrint('🎯 Cycle completion triggered: streak=$_currentStreak, completing cycle $_currentCycle');
      await _completeCycle();
      safePrint('🎯 After cycle completion: streak=$_currentStreak, cycle=$_currentCycle');
    }
    
    // Start streak tracking on first claim
    _streakStartDate ??= DateTime.now();
    
    // Update UI immediately
    notifyListeners();
    
    // Batch background operations (don't wait for these)
    final backgroundOperations = <Future>[
      _persistData(),
      LocalNotificationManager().cancelNotification(NotificationType.dailyStreakReminder),
      // ✅ NEW: Schedule notification for tomorrow's reminder
      _scheduleNextDayReminder(),
    ];
    
    // Execute background operations in parallel without blocking UI
    Future.wait(backgroundOperations, eagerError: false).catchError((e) {
      safePrint('⚠️ Daily streak background operations error: $e');
      return <dynamic>[]; // Return empty list for error handling
    });
    
    // ✅ FIRE BACKEND EVENT: Daily streak claimed (via EventBus → Railway backend)
    EventBus().fire('daily_streak_claimed', {
      'day_in_cycle': todayRewardIndex + 1,        // 1-7
      'current_streak': _currentStreak,             // Total consecutive days
      'current_cycle': _currentCycle,               // Which 7-day cycle
      'reward_type': reward.type.name,              // coins, gems, heartBooster, jetSkin, etc.
      'reward_amount': reward.amount,               // Numeric value
      'reward_set': _currentCycleRewardSet ?? 'new_player', // 'new_player' or 'experienced'
    });
    safePrint('🏆 daily_streak_claimed event fired (day ${todayRewardIndex + 1}, streak $_currentStreak)');
    
    // ✅ FIRE MILESTONE EVENT: For special days (7, 14, 30, 100, etc.)
    if (_currentStreak == 7 || _currentStreak == 14 || _currentStreak == 30 || 
        _currentStreak == 60 || _currentStreak == 100) {
      EventBus().fire('daily_streak_milestone', {
        'milestone_days': _currentStreak,
        'current_cycle': _currentCycle,
        'total_cycles_completed': _totalStreaksCompleted,
      });
      safePrint('🏆 daily_streak_milestone event fired (${_currentStreak} days)');
    }
    
    safePrint('✅ Daily streak reward claimed: ${reward.description} (streak: $_currentStreak, cycle: $_currentCycle)');
    return true;
  }
  
  
  /// Apply a reward to the player's inventory
  Future<bool> _applyReward(DailyStreakReward reward) async {
    try {
      switch (reward.type) {
        case DailyStreakRewardType.coins:
          await _inventory.grantSoftCurrency(
            reward.amount,
            source: 'daily_streak',
            sourceId: 'day_${_currentStreak + 1}_cycle_$_currentCycle',
          );
          break;
          
        case DailyStreakRewardType.gems:
          await _inventory.grantGems(reward.amount);
          break;
          
        case DailyStreakRewardType.heartBooster:
          // Activate the booster timer
          await _inventory.activateHeartBooster(Duration(minutes: reward.amount));
          // 🔥 CRITICAL: Refill hearts to max (6 with booster active)
          await _lives.refillToMax();
          safePrint('💖 Heart Booster activated and hearts refilled to 6!');
          break;
          
        case DailyStreakRewardType.heart:
          await _lives.addLife();
          break;
          
        case DailyStreakRewardType.jetSkin:
          if (reward.jetSkinId != null) {
            // ✅ PROGRESSIVE JET SYSTEM: Try jets in order until we find one the player doesn't own
            if (reward.jetSkinId == 'progressive_jet') {
              // Day 6 reward: Progressive jet selection
              const jetProgression = [
                'cobra_strike',
                'storm_chaser',
                'disco_fever',
                'ruby_phantom',
                'sugar_storm',
              ];
              
              String? jetToAward;
              for (final jetId in jetProgression) {
                if (!_inventory.isOwned(jetId)) {
                  jetToAward = jetId;
                  break;
                }
              }
              
              if (jetToAward != null) {
                // Found a jet they don't own - award it!
                await _inventory.unlockSkin(jetToAward);
                // ✅ AUTO-EQUIP: Automatically equip the newly unlocked jet
                await _inventory.equipSkin(jetToAward);
                _lastUnlockedJetId = jetToAward; // ✅ FIX: Store the actual unlocked jet ID
                safePrint('🚁 Progressive jet awarded and auto-equipped: $jetToAward');
              } else {
                // Player owns all jets in progression - give 500 coins instead
                const fallbackCoins = 500;
                await _inventory.addCoinsWithAnimation(fallbackCoins);
                safePrint('🚁 Player owns all progression jets → Awarded $fallbackCoins coins instead');
              }
            } else {
              // Normal jet reward (e.g., Flash Strike for new players)
              // Check if player already owns this jet
              if (_inventory.isOwned(reward.jetSkinId!)) {
                // Player already has this jet - give coins instead
                const duplicateJetCoins = 400; // Flash Strike equivalent value
                await _inventory.addCoinsWithAnimation(duplicateJetCoins);
                safePrint('🚁 Duplicate jet detected: ${reward.jetSkinId} → Awarded $duplicateJetCoins coins instead');
                
                // Show beautiful duplicate jet popup
                await _showDuplicateJetPopup(reward.jetSkinId!, duplicateJetCoins);
              } else {
                // Normal jet unlock
                await _inventory.unlockSkin(reward.jetSkinId!);
                // ✅ AUTO-EQUIP: Automatically equip the newly unlocked jet
                await _inventory.equipSkin(reward.jetSkinId!);
                _lastUnlockedJetId = reward.jetSkinId; // ✅ FIX: Store the actual unlocked jet ID
                safePrint('🚁 Unlocked and auto-equipped jet skin: ${reward.jetSkinId}');
              }
            }
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
  
  /// Callback for showing duplicate jet popup (set by UI layer)
  static Function(String jetSkinId, int coinsAwarded)? _duplicateJetCallback;
  
  /// Set the duplicate jet popup callback
  static void setDuplicateJetCallback(Function(String, int) callback) {
    _duplicateJetCallback = callback;
  }
  
  /// Show beautiful duplicate jet popup
  Future<void> _showDuplicateJetPopup(String jetSkinId, int coinsAwarded) async {
    if (_duplicateJetCallback != null) {
      _duplicateJetCallback!(jetSkinId, coinsAwarded);
    } else {
      safePrint('⚠️ Duplicate jet popup callback not set - coins awarded: $coinsAwarded');
    }
  }

  /// Open mystery box and give random reward
  Future<void> _openMysteryBox() async {
    // Random rewards from mystery box (3 options)
    final random = DateTime.now().millisecondsSinceEpoch % 3;
    
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
        await _inventory.activateHeartBooster(const Duration(minutes: 60));
        // 🔥 CRITICAL: Refill hearts to max (6 with booster active)
        await _lives.refillToMax();
        safePrint('🎁 Mystery box: 1 hour heart booster + hearts refilled to 6!');
        break;
    }
  }
  
  /// Reset streak to 0
  Future<void> _resetStreak() async {
    final previousStreak = _currentStreak;
    final previousCycle = _currentCycle;
    
    _currentStreak = 0;
    _claimedToday = false;
    _lastClaimDate = null;
    _streakStartDate = null;
    await _persistData();
    notifyListeners();
    
    // ✅ FIRE BACKEND EVENT: Daily streak broken (via EventBus → Railway backend)
    if (previousStreak > 0) {
      EventBus().fire('daily_streak_broken', {
        'last_streak_days': previousStreak,
        'last_cycle': previousCycle,
        'total_cycles_completed': _totalStreaksCompleted,
      });
      safePrint('🏆 daily_streak_broken event fired (was $previousStreak days)');
    }
  }
  
  /// Persist data to SharedPreferences
  Future<void> _persistData() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setInt(_keyCurrentStreak, _currentStreak);
    await prefs.setBool(_keyClaimedToday, _claimedToday);
    await prefs.setInt(_keyTotalStreaksCompleted, _totalStreaksCompleted);
    await prefs.setInt(_keyCurrentCycle, _currentCycle);
    
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
    
    if (_cycleStartDate != null) {
      await prefs.setInt(_keyCycleStartDate, _cycleStartDate!.millisecondsSinceEpoch);
    } else {
      await prefs.remove(_keyCycleStartDate);
    }
    
    if (_currentCycleRewardSet != null) {
      await prefs.setString(_keyCurrentCycleRewardSet, _currentCycleRewardSet!);
    } else {
      await prefs.remove(_keyCurrentCycleRewardSet);
    }
  }
  
  /// Get streak statistics for analytics
  Map<String, dynamic> getStreakStats() {
    return {
      'current_streak': _currentStreak,
      'current_cycle': _currentCycle,
      'cycle_reward_set': _currentCycleRewardSet,
      'total_completed': _totalStreaksCompleted,
      'claimed_today': _claimedToday,
      'state': currentState.name,
      'days_since_start': _streakStartDate != null 
          ? DateTime.now().difference(_streakStartDate!).inDays 
          : 0,
      'days_since_cycle_start': _cycleStartDate != null 
          ? DateTime.now().difference(_cycleStartDate!).inDays 
          : 0,
    };
  }
  
  /// Reset daily claim status (for testing new day simulation)
  Future<void> resetDailyClaimStatus() async {
    _claimedToday = false;
    await _persistData();
    safePrint('📅 Daily claim status reset for new day simulation');
  }

  /// Reset all data (for testing/debugging)
  Future<void> resetAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCurrentStreak);
    await prefs.remove(_keyLastClaimDate);
    await prefs.remove(_keyClaimedToday);
    await prefs.remove(_keyStreakStartDate);
    await prefs.remove(_keyTotalStreaksCompleted);
    await prefs.remove(_keyCurrentCycle);
    await prefs.remove(_keyCycleStartDate);
    await prefs.remove(_keyCurrentCycleRewardSet);
    
    _currentStreak = 0;
    _claimedToday = false;
    _lastClaimDate = null;
    _streakStartDate = null;
    _totalStreaksCompleted = 0;
    _currentCycle = 0;
    _cycleStartDate = null;
    _currentCycleRewardSet = null;
    
    notifyListeners();
    safePrint('🔄 Daily streak data reset');
  }

  /// ✅ NEW: Schedule next day's notification reminder
  Future<void> _scheduleNextDayReminder() async {
    try {
      // Schedule notification for next day
      await LocalNotificationManager().scheduleDailyStreakReminder();
      safePrint('📲 Daily streak notification scheduled for next day');
    } catch (e) {
      safePrint('⚠️ Failed to schedule daily streak notification: $e');
    }
  }
}
