/// Mock Managers - Test doubles for game systems
/// 
/// Provides mock implementations of managers for isolated testing
library;

import 'package:flutter/foundation.dart';
import 'package:mocktail/mocktail.dart';
import '../../lib/game/systems/monetization_manager.dart';
import '../../lib/game/systems/missions_manager.dart';
import '../../lib/game/systems/lives_manager.dart';
import '../../lib/game/systems/inventory_manager.dart';
import '../../lib/game/systems/level_system_manager.dart';

/// Mock MonetizationManager for testing
class MockMonetizationManager extends Mock implements MonetizationManager {
  @override
  bool get isInitialized => true;
  
  @override
  Future<void> initialize({
    InventoryManager? inventory,
    LivesManager? lives,
  }) async {
    // No-op for testing
  }
  
  @override
  void trackPlayerEngagement(Map<String, dynamic> data) {
    // No-op for testing
  }
  
  @override
  Future<void> showRewardedAdForExtraLife({
    required VoidCallback onReward,
    VoidCallback? onAdFailure,
    Function()? onAdStart,
    Function()? onAdEnd,
    Function()? onAdLoading,
  }) async {
    // For testing: immediately call onReward
    onAdLoading?.call();
    onAdStart?.call();
    onReward();
    onAdEnd?.call();
  }
}

/// Mock MissionsManager for testing
class MockMissionsManager extends Mock implements MissionsManager {
  @override
  bool get isInitialized => true;
  
  @override
  Future<void> initialize() async {
    // No-op for testing
  }
}

/// Mock LivesManager for testing
class MockLivesManager extends Mock implements LivesManager {
  int _currentLives = 3;
  
  @override
  int get currentLives => _currentLives;
  
  @override
  int get maxLives => 3;
  
  @override
  Future<void> initialize() async {
    _currentLives = 3;
  }
  
  @override
  Future<void> consumeLife() async {
    if (_currentLives > 0) {
      _currentLives--;
    }
  }
  
  @override
  Future<void> addLife([int count = 1]) async {
    _currentLives += count;
    if (_currentLives > maxLives) {
      _currentLives = maxLives;
    }
  }
  
  @override
  Future<void> setLives(int lives) async {
    _currentLives = lives.clamp(0, maxLives);
  }
  
  @override
  Future<void> refillToMax() async {
    _currentLives = maxLives;
  }
}

/// Mock InventoryManager for testing
class MockInventoryManager extends Mock implements InventoryManager {
  int _coins = 0;
  int _gems = 0;
  String _equippedSkinId = 'starter_jet';
  
  @override
  int get softCurrency => _coins;
  
  @override
  int get gems => _gems;
  
  @override
  String get equippedSkinId => _equippedSkinId;
  
  @override
  Future<void> grantSoftCurrency(int amount) async {
    _coins += amount;
  }
  
  @override
  Future<void> grantGems(int amount) async {
    _gems += amount;
  }
  
  @override
  Future<bool> spendGems(int amount) async {
    if (_gems >= amount) {
      _gems -= amount;
      return true;
    }
    return false;
  }
}

/// Mock LevelSystemManager for testing
class MockLevelSystemManager extends Mock implements LevelSystemManager {
  int _currentLevel = 1;
  final Set<int> _completedLevels = {};
  
  @override
  bool get isInitialized => true;
  
  @override
  int get currentLevel => _currentLevel;
  
  @override
  int get highestLevelUnlocked => _currentLevel;
  
  @override
  Set<int> get completedLevels => _completedLevels;
  
  @override
  Future<void> initialize() async {
    // No-op for testing
  }
  
  @override
  Future<void> completeLevel({
    required int levelId,
    required int coinsEarned,
    required int gemsEarned,
    bool? botDefeated,
  }) async {
    _completedLevels.add(levelId);
    _currentLevel = levelId + 1;
  }
  
  @override
  bool isLevelReplay(int levelId) {
    return _completedLevels.contains(levelId);
  }
}

/// Helper to register mock fallback values for mocktail
void registerMockFallbacks() {
  // Register any fallback values needed for mocks
  // Example: registerFallbackValue(MockObject());
}

