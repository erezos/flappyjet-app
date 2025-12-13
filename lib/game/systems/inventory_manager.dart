import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/jet_skins.dart';
import '../../core/debug_logger.dart';
import '../../core/repositories/user_stats_repository.dart';
import '../../core/repositories/inventory_repository.dart';
import '../../core/events/event_bus.dart';
import 'auto_refill_manager.dart';

/// Enhanced inventory for jet skins, soft currency (coins), gems, and boosters
/// 
/// ✅ Phase 2: Migrated to SQLite-based storage
/// ✅ Removed backend restoration (no longer needed)
/// ✅ Event-driven analytics (fire-and-forget)
class InventoryManager extends ChangeNotifier {
  static final InventoryManager _instance = InventoryManager._internal();
  factory InventoryManager() => _instance;
  InventoryManager._internal();

  // Dependencies
  UserStatsRepository? _userStats;
  InventoryRepository? _inventory;
  EventBus? _eventBus;
  bool _isInitialized = false;

  // Cached state (loaded from database)
  Set<String> _ownedSkinIds = {JetSkinCatalog.starterJet.id};
  String _equippedSkinId = JetSkinCatalog.starterJet.id;
  int _softCurrency = 500;
  int _gems = 25;
  DateTime? _heartBoosterExpiry;

  // UI notifiers
  final ValueNotifier<int> _softCurrencyNotifier = ValueNotifier<int>(500);
  final ValueNotifier<int> _gemsNotifier = ValueNotifier<int>(25);
  final ValueNotifier<bool> _heartBoosterActiveNotifier = ValueNotifier<bool>(false);
  
  // Auto-refill manager instance
  final AutoRefillManager _autoRefillManager = AutoRefillManager();

  // Public getters
  Set<String> get ownedSkinIds => _ownedSkinIds;
  String get equippedSkinId => _equippedSkinId;
  int get softCurrency => _softCurrency;
  int get gems => _gems;
  bool get isHeartBoosterActive =>
      _heartBoosterExpiry != null && DateTime.now().isBefore(_heartBoosterExpiry!);
  DateTime? get heartBoosterExpiry => _heartBoosterExpiry;
  static const String _keyStarterHeartBoosterGranted =
      'inv_starter_heart_booster_granted_v1';
  
  // Auto-refill booster properties
  bool get isAutoRefillActive => _autoRefillManager.isAutoRefillActive;
  DateTime? get autoRefillExpiry => _autoRefillManager.autoRefillExpiry;

  /// Get remaining time for Heart Booster (null if not active)
  Duration? get heartBoosterTimeRemaining {
    if (_heartBoosterExpiry == null) return null;
    final now = DateTime.now();
    if (now.isAfter(_heartBoosterExpiry!)) return null;
    return _heartBoosterExpiry!.difference(now);
  }

  ValueListenable<int> get softCurrencyNotifier => _softCurrencyNotifier;
  ValueListenable<int> get gemsNotifier => _gemsNotifier;
  ValueListenable<bool> get heartBoosterActiveNotifier => _heartBoosterActiveNotifier;
  ValueListenable<bool> get autoRefillActiveNotifier => _autoRefillManager.autoRefillActiveNotifier;

  /// Initialize with repositories
  Future<void> initialize({
    required UserStatsRepository userStats,
    required InventoryRepository inventory,
    required EventBus eventBus,
  }) async {
    if (_isInitialized) {
      safePrint('🎒 InventoryManager already initialized');
      return;
    }

    _userStats = userStats;
    _inventory = inventory;
    _eventBus = eventBus;

    await _loadFromDatabase();
    await _autoRefillManager.initialize();
    
    _isInitialized = true;
    safePrint('🎒 InventoryManager initialized (SQLite-based)');
    notifyListeners();
  }

  /// Check if initialized (for safe access from UI)
  bool get isInitialized => _isInitialized;

  /// Load current state from database
  Future<void> _loadFromDatabase() async {
    if (_userStats == null || _inventory == null) {
      throw StateError('InventoryManager not initialized. Call initialize() first.');
    }

    // Load from user_stats
    final stats = await _userStats!.getUserStats();
    _softCurrency = stats.coins;
    _gems = stats.gems;
    _equippedSkinId = stats.equippedSkinId ?? JetSkinCatalog.starterJet.id;
    
    // Load heart booster expiry
    if (stats.heartBoosterExpiry != null) {
      _heartBoosterExpiry = stats.heartBoosterExpiry;
      // Check if expired
      if (DateTime.now().isAfter(_heartBoosterExpiry!)) {
        _heartBoosterExpiry = null;
        // Clear from database
        await _userStats!.setHeartBoosterExpiry(null);
      }
    }

    // Load from inventory
    final items = await _inventory!.getAllItems();
    _ownedSkinIds = items
        .where((item) => item.itemType == 'skin')
        .map((item) => item.itemId)
        .toSet();
    
    // Ensure starter skin is always owned
    if (!_ownedSkinIds.contains(JetSkinCatalog.starterJet.id)) {
      _ownedSkinIds.add(JetSkinCatalog.starterJet.id);
      await _inventory!.addItem('skin', JetSkinCatalog.starterJet.id);
    }

    // Update notifiers
    _softCurrencyNotifier.value = _softCurrency;
    _gemsNotifier.value = _gems;
    _heartBoosterActiveNotifier.value = isHeartBoosterActive;
  }

  /// Grant coins to user
  /// Grant soft currency (coins) to user
  /// [source] - Where the coins came from (e.g., 'mission_completed', 'level_completed', 'ad_watched')
  /// [sourceId] - Specific ID of the source (e.g., 'daily_mission_3', 'level_13')
  Future<void> grantSoftCurrency(int amount, {String source = 'game_reward', String? sourceId}) async {
    if (amount <= 0) return;

    final balanceBefore = _softCurrency;
    await _userStats!.addCoins(amount);
    _softCurrency += amount;
    _softCurrencyNotifier.value = _softCurrency;
    
    // Fire event for analytics
    _eventBus?.fire('currency_earned', {
      'currency_type': 'coins',
      'amount': amount,
      'source': source,
      'source_id': sourceId ?? source,
      'balance_before': balanceBefore,
      'balance_after': _softCurrency,
    });
    
    notifyListeners();
  }

  /// Add coins with animation (legacy method for compatibility)
  Future<void> addCoinsWithAnimation(int amount) async {
    return grantSoftCurrency(amount);
  }

  /// Spend coins
  /// [spentOn] - What the coins were spent on (e.g., 'skin_purchase', 'booster_purchase', 'continue')
  /// [itemId] - Specific item ID (e.g., 'skin_gold', 'booster_shield')
  Future<bool> spendSoftCurrency(int amount, {String spentOn = 'purchase', String? itemId}) async {
    if (amount <= 0) return false;

    final balanceBefore = _softCurrency;
    final success = await _userStats!.spendCoins(amount);
    if (!success) {
      return false;
    }

    _softCurrency -= amount;
    _softCurrencyNotifier.value = _softCurrency;
    
    // Fire event for analytics
    _eventBus?.fire('currency_spent', {
      'currency_type': 'coins',
      'amount': amount,
      'spent_on': spentOn,
      'item_id': itemId ?? spentOn,
      'balance_before': balanceBefore,
      'balance_after': _softCurrency,
    });
    
    notifyListeners();
    return true;
  }

  /// Grant gems to user
  /// [source] - Where the gems came from (e.g., 'mission_completed', 'purchase', 'prize_claimed')
  /// [sourceId] - Specific ID of the source
  Future<void> grantGems(int amount, {String source = 'game_reward', String? sourceId}) async {
    if (amount <= 0) return;

    final balanceBefore = _gems;
    await _userStats!.addGems(amount);
    _gems += amount;
    _gemsNotifier.value = _gems;
    
    // Fire event for analytics
    _eventBus?.fire('currency_earned', {
      'currency_type': 'gems',
      'amount': amount,
      'source': source,
      'source_id': sourceId ?? source,
      'balance_before': balanceBefore,
      'balance_after': _gems,
    });
    
    notifyListeners();
  }

  /// Spend gems
  /// [spentOn] - What the gems were spent on (e.g., 'skin_purchase', 'booster_purchase', 'continue')
  /// [itemId] - Specific item ID
  Future<bool> spendGems(int amount, {String spentOn = 'purchase', String? itemId}) async {
    if (amount <= 0) return false;

    final balanceBefore = _gems;
    final success = await _userStats!.spendGems(amount);
    if (!success) {
      return false;
    }

    _gems -= amount;
    _gemsNotifier.value = _gems;
    
    // Fire event for analytics
    _eventBus?.fire('currency_spent', {
      'currency_type': 'gems',
      'amount': amount,
      'spent_on': spentOn,
      'item_id': itemId ?? spentOn,
      'balance_before': balanceBefore,
      'balance_after': _gems,
    });
    
    notifyListeners();
    return true;
  }

  /// Ensure player has at least [min] coins (useful for development/testing)
  Future<void> ensureMinSoftCurrency(int min) async {
    if (_softCurrency < min) {
      final needed = min - _softCurrency;
      await grantSoftCurrency(needed);
    }
  }

  /// Ensure player has at least [min] gems (useful for development/testing)
  Future<void> ensureMinGems(int min) async {
    if (_gems < min) {
      final needed = min - _gems;
      await grantGems(needed);
    }
  }

  /// Activate Heart Booster for the specified duration
  Future<void> activateHeartBooster(Duration duration) async {
    final now = DateTime.now();
    final newExpiry = now.add(duration);

    // If already active, extend the duration from current expiry
    if (_heartBoosterExpiry != null && _heartBoosterExpiry!.isAfter(now)) {
      _heartBoosterExpiry = _heartBoosterExpiry!.add(duration);
    } else {
      _heartBoosterExpiry = newExpiry;
    }

    await _userStats!.setHeartBoosterExpiry(_heartBoosterExpiry);
    _heartBoosterActiveNotifier.value = isHeartBoosterActive;
    
    // Fire event for analytics
    _eventBus?.fire('powerup_activated', {
      'powerup_type': 'heart_booster',
      'duration_hours': duration.inHours,
      'expiry': _heartBoosterExpiry!.toIso8601String(),
    });
    
    notifyListeners();
    safePrint('💖 Heart Booster activated! Duration: ${duration.inHours}h');
  }

  /// Starter booster: grant once for brand-new players (silent 24h, 6 hearts)
  Future<bool> grantStarterHeartBoosterIfEligible({
    required bool isFirstTimeUser,
  }) async {
    if (!isFirstTimeUser) return false;
    final prefs = await SharedPreferences.getInstance();
    final alreadyGranted =
        prefs.getBool(_keyStarterHeartBoosterGranted) ?? false;
    if (alreadyGranted) return false;

    await activateHeartBooster(const Duration(hours: 24));
    await prefs.setBool(_keyStarterHeartBoosterGranted, true);
    return true;
  }

  /// Check and update Heart Booster status (call periodically)
  Future<void> updateHeartBoosterStatus() async {
    final wasActive = _heartBoosterActiveNotifier.value;
    final isActive = isHeartBoosterActive;

    if (wasActive && !isActive) {
      // Booster just expired, clean up
      _heartBoosterExpiry = null;
      await _userStats!.setHeartBoosterExpiry(null);
      _heartBoosterActiveNotifier.value = false;
      
      // Fire event for analytics
      _eventBus?.fire('powerup_expired', {
        'powerup_type': 'heart_booster',
      });
      
      notifyListeners();
    } else if (wasActive != isActive) {
      _heartBoosterActiveNotifier.value = isActive;
      notifyListeners();
    }
  }

  /// Activate Auto-Refill booster for the specified duration
  Future<void> activateAutoRefill(AutoRefillDuration duration) async {
    await _autoRefillManager.activateAutoRefill(duration);
    
    // Fire event for analytics
    _eventBus?.fire('powerup_activated', {
      'powerup_type': 'auto_refill',
      'duration_hours': duration.hours,
    });
    
    notifyListeners();
  }

  /// Check and trigger auto-refill (call when returning to menu/tab navigation)
  Future<bool> checkAndTriggerAutoRefill() async {
    return await _autoRefillManager.checkAndTriggerAutoRefill();
  }

  /// Get remaining time for Auto-Refill (null if not active)
  Duration? get autoRefillTimeRemaining => _autoRefillManager.autoRefillTimeRemaining;

  @visibleForTesting
  Future<void> resetForTesting() async {
    _isInitialized = false;
    _userStats = null;
    _inventory = null;
    _eventBus = null;
    _ownedSkinIds = {JetSkinCatalog.starterJet.id};
    _equippedSkinId = JetSkinCatalog.starterJet.id;
    _softCurrency = 500;
    _gems = 25;
    _heartBoosterExpiry = null;
    _softCurrencyNotifier.value = _softCurrency;
    _gemsNotifier.value = _gems;
    _heartBoosterActiveNotifier.value = false;
  }

  /// Unlock a skin
  Future<void> unlockSkin(String skinId) async {
    if (_ownedSkinIds.contains(skinId)) {
      safePrint('✈️ Skin $skinId already owned');
      return;
    }

    _ownedSkinIds.add(skinId);
    await _inventory!.addItem('skin', skinId);
    
    // Fire event for analytics
    _eventBus?.fire('item_unlocked', {
      'item_type': 'skin',
      'item_id': skinId,
      'acquisition_method': 'purchase',
    });
    
    safePrint('✈️ ✅ Skin unlocked: $skinId');
    notifyListeners();
  }

  /// Equip a skin
  Future<bool> equipSkin(String skinId) async {
    if (!_ownedSkinIds.contains(skinId)) {
      safePrint('✈️ ❌ Cannot equip skin $skinId - not owned');
      return false;
    }
    
    // Skip if already equipped
    if (_equippedSkinId == skinId) {
      safePrint('✈️ ⚡ Skin $skinId already equipped - skipping');
      return true;
    }
    
    // Unequip old skin
    if (_equippedSkinId.isNotEmpty) {
      await _inventory!.unequipItem('skin', _equippedSkinId);
    }
    
    // Equip new skin
    _equippedSkinId = skinId;
    await _inventory!.equipItem('skin', skinId);
    await _userStats!.setEquippedSkin(skinId);
    
    // Fire event for analytics
    _eventBus?.fire('item_equipped', {
      'item_type': 'skin',
      'item_id': skinId,
    });
    
    safePrint('✈️ ✅ Skin equipped: $skinId');
    notifyListeners();
    return true;
  }

  /// Check if a skin is owned
  bool isOwned(String skinId) => _ownedSkinIds.contains(skinId);

  /// Refresh state from database (useful after external updates)
  Future<void> refresh() async {
    await _loadFromDatabase();
    notifyListeners();
  }
}

