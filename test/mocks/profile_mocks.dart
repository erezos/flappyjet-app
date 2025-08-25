/// 🎭 Profile Screen Test Mocks
/// Mock objects for testing profile screen functionality safely
library;

import 'package:flutter/foundation.dart';
import 'package:flappy_jet_pro/game/systems/player_identity_manager.dart';
import 'package:flappy_jet_pro/game/systems/profile_manager.dart';
import 'package:flappy_jet_pro/game/systems/inventory_manager.dart';
import 'package:flappy_jet_pro/game/core/jet_skins.dart';
import 'package:flappy_jet_pro/game/core/economy_config.dart';

/// Mock PlayerIdentityManager for testing
class MockPlayerIdentityManager extends ChangeNotifier {
  String _playerName = 'TestPlayer';
  String _playerId = 'test_player_123';
  bool _isInitialized = false;
  
  String get playerName => _playerName;
  String get playerId => _playerId;
  bool get isInitialized => _isInitialized;
  
  Future<void> updatePlayerName(String newName) async {
    _playerName = newName;
    notifyListeners();
  }
  
  Future<void> initialize() async {
    _isInitialized = true;
    notifyListeners();
  }
  
  // Test helper methods
  void setTestPlayerName(String name) {
    _playerName = name;
    notifyListeners();
  }
}

/// Mock ProfileManager for testing
class MockProfileManager extends ChangeNotifier {
  String _nickname = 'MockNickname';
  bool _isInitialized = false;
  
  String get nickname => _nickname;
  bool get isInitialized => _isInitialized;
  
  Future<void> initialize() async {
    _isInitialized = true;
    notifyListeners();
  }
  
  Future<void> setNickname(String newNickname) async {
    _nickname = newNickname;
    notifyListeners();
  }
  
  // Test helper methods
  void setTestNickname(String nickname) {
    _nickname = nickname;
    notifyListeners();
  }
  
  void simulateInitializationFailure() {
    throw Exception('Failed to initialize profile');
  }
}

/// Mock InventoryManager for testing
class MockInventoryManager extends ChangeNotifier {
  String _equippedSkinId = 'sky_jet';
  Set<String> _ownedSkinIds = {'sky_jet', 'flames'};
  int _softCurrency = 1000;
  int _gems = 50;
  bool _isInitialized = false;
  DateTime? _heartBoosterExpiry;
  final ValueNotifier<int> _softCurrencyNotifier = ValueNotifier(1000);
  final ValueNotifier<int> _gemsNotifier = ValueNotifier(50);
  final ValueNotifier<bool> _heartBoosterActiveNotifier = ValueNotifier(false);
  
  String get equippedSkinId => _equippedSkinId;
  Set<String> get ownedSkinIds => _ownedSkinIds;
  int get softCurrency => _softCurrency;
  int get gems => _gems;
  ValueNotifier<int> get softCurrencyNotifier => _softCurrencyNotifier;
  ValueNotifier<int> get gemsNotifier => _gemsNotifier;
  ValueNotifier<bool> get heartBoosterActiveNotifier => _heartBoosterActiveNotifier;
  bool get isInitialized => _isInitialized;
  DateTime? get heartBoosterExpiry => _heartBoosterExpiry;
  bool get isHeartBoosterActive => _heartBoosterExpiry != null && DateTime.now().isBefore(_heartBoosterExpiry!);
  Duration? get heartBoosterTimeRemaining => _heartBoosterExpiry != null ? _heartBoosterExpiry!.difference(DateTime.now()) : null;
  
  Future<void> initialize() async {
    _isInitialized = true;
    notifyListeners();
  }
  
  Future<bool> equipSkin(String skinId) async {
    if (_ownedSkinIds.contains(skinId)) {
      _equippedSkinId = skinId;
      notifyListeners();
      return true;
    }
    return false;
  }
  
  Future<bool> unlockSkin(String skinId) async {
    _ownedSkinIds.add(skinId);
    notifyListeners();
    return true;
  }
  
  Future<bool> spendSoftCurrency(int amount) async {
    if (_softCurrency >= amount) {
      _softCurrency -= amount;
      _softCurrencyNotifier.value = _softCurrency;
      notifyListeners();
      return true;
    }
    return false;
  }
  
  Future<bool> spendGems(int amount) async {
    if (_gems >= amount) {
      _gems -= amount;
      _gemsNotifier.value = _gems;
      notifyListeners();
      return true;
    }
    return false;
  }
  
  bool isOwned(String skinId) => _ownedSkinIds.contains(skinId);
  
  Future<void> grantSoftCurrency(int amount) async {
    _softCurrency += amount;
    _softCurrencyNotifier.value = _softCurrency;
    notifyListeners();
  }
  
  Future<void> grantGems(int amount) async {
    _gems += amount;
    _gemsNotifier.value = _gems;
    notifyListeners();
  }
  
  Future<void> ensureMinSoftCurrency(int min) async {
    if (_softCurrency < min) {
      _softCurrency = min;
      _softCurrencyNotifier.value = _softCurrency;
      notifyListeners();
    }
  }
  
  Future<void> ensureMinGems(int min) async {
    if (_gems < min) {
      _gems = min;
      _gemsNotifier.value = _gems;
      notifyListeners();
    }
  }
  
  Future<void> activateHeartBooster(Duration duration) async {
    _heartBoosterExpiry = DateTime.now().add(duration);
    _heartBoosterActiveNotifier.value = true;
    notifyListeners();
  }
  
  Future<void> updateHeartBoosterStatus() async {
    final wasActive = isHeartBoosterActive;
    final isActive = _heartBoosterExpiry != null && DateTime.now().isBefore(_heartBoosterExpiry!);
    if (wasActive != isActive) {
      _heartBoosterActiveNotifier.value = isActive;
      notifyListeners();
    }
  }
  
  // Test helper methods
  void setTestCurrency(int coins, int gems) {
    _softCurrency = coins;
    _gems = gems;
    _softCurrencyNotifier.value = coins;
    _gemsNotifier.value = gems;
    notifyListeners();
  }
  
  void setTestOwnedSkins(Set<String> skins) {
    _ownedSkinIds = skins;
    notifyListeners();
  }
  
  void setTestEquippedSkin(String skinId) {
    _equippedSkinId = skinId;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _softCurrencyNotifier.dispose();
    _gemsNotifier.dispose();
    _heartBoosterActiveNotifier.dispose();
    super.dispose();
  }
}

/// Mock JetSkinCatalog for testing
class MockJetSkinCatalog {
  static final Map<String, JetSkin> _testSkins = {
    'sky_jet': JetSkin(
      id: 'sky_jet',
      displayName: 'Sky Jet',
      assetPath: 'jets/sky_jet.png',
      price: 0.0,
      description: 'Default starter jet',
      rarity: JetRarity.common,
      isPurchased: true,
      isEquipped: true,
      category: JetSkinCategory.classic,
      tags: ['starter', 'free'],
    ),
    'flames': JetSkin(
      id: 'flames',
      displayName: 'Flames',
      assetPath: 'jets/flames.png',
      price: 100.0,
      description: 'Fiery jet with flame effects',
      rarity: JetRarity.rare,
      isPurchased: false,
      isEquipped: false,
      category: JetSkinCategory.military,
      tags: ['fire', 'effects'],
    ),
    'diamond_jet': JetSkin(
      id: 'diamond_jet',
      displayName: 'Diamond Jet',
      assetPath: 'jets/diamond_jet.png',
      price: 500.0,
      description: 'Luxurious diamond-encrusted jet',
      rarity: JetRarity.legendary,
      isPurchased: false,
      isEquipped: false,
      category: JetSkinCategory.futuristic,
      tags: ['luxury', 'diamond'],
    ),
  };
  
  static JetSkin get starterJet => _testSkins['sky_jet']!;
  
  static JetSkin? getSkinById(String id) => _testSkins[id];
  
  static List<JetSkin> getAllSkins() => _testSkins.values.toList();
  
  static Future<void> initializeFromAssets() async {
    // Mock initialization
  }
  
  // Test helper methods
  static void addTestSkin(JetSkin skin) {
    _testSkins[skin.id] = skin;
  }
  
  static void clearTestSkins() {
    _testSkins.clear();
  }
  
  static void resetToDefaults() {
    _testSkins.clear();
    _testSkins.addAll({
      'sky_jet': JetSkin(
        id: 'sky_jet',
        displayName: 'Sky Jet',
        assetPath: 'jets/sky_jet.png',
        price: 0.0,
        description: 'Default starter jet',
        rarity: JetRarity.common,
        isPurchased: true,
        isEquipped: true,
        category: JetSkinCategory.classic,
        tags: ['starter', 'free'],
      ),
      'flames': JetSkin(
        id: 'flames',
        displayName: 'Flames',
        assetPath: 'jets/flames.png',
        price: 100.0,
        description: 'Fiery jet with flame effects',
        rarity: JetRarity.rare,
        isPurchased: false,
        isEquipped: false,
        category: JetSkinCategory.military,
        tags: ['fire', 'effects'],
      ),
    });
  }
}

/// Mock EconomyConfig for testing
class MockEconomyConfig {
  int getSkinCoinPrice(JetSkin skin) {
    return skin.price.toInt();
  }
}

/// Test data factory for creating consistent test scenarios
class ProfileTestData {
  static MockPlayerIdentityManager createPlayerIdentity({
    String name = 'TestPlayer',
    String id = 'test_123',
  }) {
    final mock = MockPlayerIdentityManager();
    mock.setTestPlayerName(name);
    return mock;
  }
  
  static MockProfileManager createProfile({
    String nickname = 'TestNickname',
    bool initialized = true,
  }) {
    final mock = MockProfileManager();
    mock.setTestNickname(nickname);
    if (initialized) {
      mock.initialize();
    }
    return mock;
  }
  
  static MockInventoryManager createInventory({
    String equippedSkin = 'sky_jet',
    Set<String>? ownedSkins,
    int coins = 1000,
    int gems = 50,
  }) {
    final mock = MockInventoryManager();
    mock.setTestEquippedSkin(equippedSkin);
    mock.setTestOwnedSkins(ownedSkins ?? {'sky_jet', 'flames'});
    mock.setTestCurrency(coins, gems);
    mock.initialize();
    return mock;
  }
  
  /// Create a complete set of mocks for profile testing
  static ProfileTestMocks createFullMockSet({
    String playerName = 'TestPlayer',
    String nickname = 'TestNickname',
    String equippedSkin = 'sky_jet',
    int coins = 1000,
    int gems = 50,
  }) {
    return ProfileTestMocks(
      playerIdentity: createPlayerIdentity(name: playerName),
      profile: createProfile(nickname: nickname),
      inventory: createInventory(
        equippedSkin: equippedSkin,
        coins: coins,
        gems: gems,
      ),
      economy: MockEconomyConfig(),
    );
  }
}

/// Container for all profile-related mocks
class ProfileTestMocks {
  final MockPlayerIdentityManager playerIdentity;
  final MockProfileManager profile;
  final MockInventoryManager inventory;
  final MockEconomyConfig economy;
  
  ProfileTestMocks({
    required this.playerIdentity,
    required this.profile,
    required this.inventory,
    required this.economy,
  });
  
  /// Dispose all mocks properly
  void dispose() {
    playerIdentity.dispose();
    profile.dispose();
    inventory.dispose();
  }
}
