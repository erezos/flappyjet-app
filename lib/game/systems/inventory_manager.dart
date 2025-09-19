import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/jet_skins.dart';
import '../../core/debug_logger.dart';
import 'auto_refill_manager.dart';

/// Enhanced inventory for jet skins, soft currency (coins), gems, and boosters
class InventoryManager extends ChangeNotifier {
  static final InventoryManager _instance = InventoryManager._internal();
  factory InventoryManager() => _instance;
  InventoryManager._internal();

  static const String _keyOwnedSkins = 'inv_owned_skins';
  static const String _keyEquippedSkin = 'inv_equipped_skin';
  static const String _keySoftCurrency = 'inv_soft_currency';
  static const String _keyGems = 'inv_gems';
  static const String _keyHeartBoosterExpiry = 'inv_heart_booster_expiry';

  Set<String> _ownedSkinIds = {JetSkinCatalog.starterJet.id};
  String _equippedSkinId = JetSkinCatalog.starterJet.id;
  int _softCurrency = 500; // Production: New players start with 500 coins
  int _gems = 25; // Production: New players start with 25 gems
  DateTime? _heartBoosterExpiry; // when Heart Booster expires

  // 🎁 Prize distribution properties
  String? _playerId;
  String? _authToken;

  final ValueNotifier<int> _softCurrencyNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> _gemsNotifier = ValueNotifier<int>(0);
  final ValueNotifier<bool> _heartBoosterActiveNotifier = ValueNotifier<bool>(
    false,
  );
  
  // Auto-refill manager instance
  final AutoRefillManager _autoRefillManager = AutoRefillManager();

  Set<String> get ownedSkinIds => _ownedSkinIds;
  String get equippedSkinId => _equippedSkinId;
  int get softCurrency => _softCurrency;
  int get gems => _gems;
  bool get isHeartBoosterActive =>
      _heartBoosterExpiry != null &&
      DateTime.now().isBefore(_heartBoosterExpiry!);
  DateTime? get heartBoosterExpiry => _heartBoosterExpiry;
  
  // Auto-refill booster properties
  bool get isAutoRefillActive => _autoRefillManager.isAutoRefillActive;
  DateTime? get autoRefillExpiry => _autoRefillManager.autoRefillExpiry;

  // 🎁 Prize distribution properties
  String? get playerId => _playerId;
  String? get authToken => _authToken;

  /// Get remaining time for Heart Booster (null if not active)
  Duration? get heartBoosterTimeRemaining {
    if (_heartBoosterExpiry == null) return null;
    final now = DateTime.now();
    if (now.isAfter(_heartBoosterExpiry!)) return null;
    return _heartBoosterExpiry!.difference(now);
  }

  ValueListenable<int> get softCurrencyNotifier => _softCurrencyNotifier;
  ValueListenable<int> get gemsNotifier => _gemsNotifier;
  ValueListenable<bool> get heartBoosterActiveNotifier =>
      _heartBoosterActiveNotifier;
  ValueListenable<bool> get autoRefillActiveNotifier =>
      _autoRefillManager.autoRefillActiveNotifier;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final ownedJson = prefs.getString(_keyOwnedSkins);
    if (ownedJson != null) {
      final List<dynamic> list = jsonDecode(ownedJson);
      _ownedSkinIds = list.map((e) => e.toString()).toSet();
    }
    _equippedSkinId =
        prefs.getString(_keyEquippedSkin) ?? JetSkinCatalog.starterJet.id;
    _softCurrency =
        prefs.getInt(_keySoftCurrency) ??
        500; // Production: New players start with 500 coins
    _gems =
        prefs.getInt(_keyGems) ??
        25; // Production: New players start with 25 gems

    // Load Heart Booster expiry
    final boosterExpiryMs = prefs.getInt(_keyHeartBoosterExpiry);
    if (boosterExpiryMs != null) {
      _heartBoosterExpiry = DateTime.fromMillisecondsSinceEpoch(
        boosterExpiryMs,
      );
      // Check if it's expired
      if (DateTime.now().isAfter(_heartBoosterExpiry!)) {
        _heartBoosterExpiry = null;
        await prefs.remove(_keyHeartBoosterExpiry);
      }
    }

    _softCurrencyNotifier.value = _softCurrency;
    _gemsNotifier.value = _gems;
    _heartBoosterActiveNotifier.value = isHeartBoosterActive;
    
    // Initialize auto-refill manager
    await _autoRefillManager.initialize();
    
    notifyListeners();
  }

  Future<void> grantSoftCurrency(int amount) async {
    _softCurrency += amount;
    await _persistCurrency();
    _softCurrencyNotifier.value = _softCurrency;
    notifyListeners();
  }

  /// 🔄 Restore currency from backend (for user restoration after reinstall)
  Future<void> setCurrency(int coins, int gems) async {
    _softCurrency = coins;
    _gems = gems;
    await _persistCurrency();
    await _persistGems();
    _softCurrencyNotifier.value = _softCurrency;
    _gemsNotifier.value = _gems;
    notifyListeners();
    safePrint('💰 Currency restored: $coins coins, $gems gems');
  }

  /// 🔄 Restore owned skins from backend
  Future<void> restoreOwnedSkins(Set<String> ownedSkins) async {
    _ownedSkinIds = ownedSkins;
    await _persistOwned();
    notifyListeners();
    safePrint('✈️ Owned skins restored: ${ownedSkins.length} skins');
  }

  /// 🎁 Add coins with animation support (for prize distribution)
  Future<int> addCoinsWithAnimation(int amount) async {
    _softCurrency += amount;
    await _persistCurrency();

    // Trigger coin animation event
    _triggerCoinAnimation(amount);

    _softCurrencyNotifier.value = _softCurrency;
    notifyListeners();

    safePrint(
      '💰 Coins added with animation: +$amount (Total: $_softCurrency)',
    );
    return _softCurrency;
  }

  /// Trigger coin collection animation
  void _triggerCoinAnimation(int amount) {
    // This would trigger celebration animation in the UI
    // Implementation depends on the animation system used
    safePrint('🎊 Coin animation triggered: $amount coins');
  }

  /// Ensure player has at least [min] coins (useful for development/testing)
  Future<void> ensureMinSoftCurrency(int min) async {
    if (_softCurrency < min) {
      _softCurrency = min;
      await _persistCurrency();
      _softCurrencyNotifier.value = _softCurrency;
      notifyListeners();
    }
  }

  Future<bool> spendSoftCurrency(int amount) async {
    if (_softCurrency < amount) return false;
    _softCurrency -= amount;
    await _persistCurrency();
    _softCurrencyNotifier.value = _softCurrency;
    notifyListeners();
    return true;
  }

  /// Grant gems (premium currency)
  Future<void> grantGems(int amount) async {
    _gems += amount;
    await _persistGems();
    _gemsNotifier.value = _gems;
    notifyListeners();
  }

  /// Ensure player has at least [min] gems (useful for development/testing)
  Future<void> ensureMinGems(int min) async {
    if (_gems < min) {
      _gems = min;
      await _persistGems();
      _gemsNotifier.value = _gems;
      notifyListeners();
    }
  }

  Future<bool> spendGems(int amount) async {
    if (_gems < amount) return false;
    _gems -= amount;
    await _persistGems();
    _gemsNotifier.value = _gems;
    notifyListeners();
    return true;
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

    await _persistHeartBooster();
    _heartBoosterActiveNotifier.value = isHeartBoosterActive;
    notifyListeners();

    safePrint('💖 Heart Booster activated! Duration: ${duration.inHours}h');
  }

  /// Check and update Heart Booster status (call periodically)
  Future<void> updateHeartBoosterStatus() async {
    final wasActive = _heartBoosterActiveNotifier.value;
    final isActive = isHeartBoosterActive;

    if (wasActive && !isActive) {
      // Booster just expired, clean up
      _heartBoosterExpiry = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyHeartBoosterExpiry);
      _heartBoosterActiveNotifier.value = false;
      notifyListeners();
    } else if (wasActive != isActive) {
      _heartBoosterActiveNotifier.value = isActive;
      notifyListeners();
    }
  }

  /// Activate Auto-Refill booster for the specified duration
  Future<void> activateAutoRefill(AutoRefillDuration duration) async {
    await _autoRefillManager.activateAutoRefill(duration);
    notifyListeners();
  }

  /// Check and trigger auto-refill (call when returning to homepage)
  Future<bool> checkAndTriggerAutoRefill() async {
    return await _autoRefillManager.checkAndTriggerAutoRefill();
  }

  /// Get remaining time for Auto-Refill (null if not active)
  Duration? get autoRefillTimeRemaining => _autoRefillManager.autoRefillTimeRemaining;

  Future<void> unlockSkin(String skinId) async {
    _ownedSkinIds.add(skinId);
    await _persistOwned();
    notifyListeners();
  }

  Future<bool> equipSkin(String skinId) async {
    if (!_ownedSkinIds.contains(skinId)) return false;
    _equippedSkinId = skinId;
    await _persistEquipped();
    notifyListeners();
    return true;
  }

  bool isOwned(String skinId) => _ownedSkinIds.contains(skinId);

  Future<void> _persistOwned() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyOwnedSkins, jsonEncode(_ownedSkinIds.toList()));
  }

  Future<void> _persistEquipped() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEquippedSkin, _equippedSkinId);
  }

  Future<void> _persistCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySoftCurrency, _softCurrency);
  }

  Future<void> _persistGems() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyGems, _gems);
  }

  Future<void> _persistHeartBooster() async {
    final prefs = await SharedPreferences.getInstance();
    if (_heartBoosterExpiry != null) {
      await prefs.setInt(
        _keyHeartBoosterExpiry,
        _heartBoosterExpiry!.millisecondsSinceEpoch,
      );
    } else {
      await prefs.remove(_keyHeartBoosterExpiry);
    }
  }

  /// 🎁 Set player ID for prize distribution
  void setPlayerId(String playerId) {
    _playerId = playerId;
    safePrint('🎁 Player ID set for prize distribution: $playerId');
  }

  /// 🎁 Set auth token for prize distribution
  void setAuthToken(String authToken) {
    _authToken = authToken;
    safePrint('🎁 Auth token set for prize distribution');
  }
}
