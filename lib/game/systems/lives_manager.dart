import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/game_config.dart';
import 'inventory_manager.dart';

/// Lives/Energy system with timed regeneration and Heart Booster support
/// - Regenerates 1 heart every regen interval (10 min default, 8 min with booster)
/// - Maximum of 3 hearts (6 with Heart Booster)
/// - Persists to SharedPreferences
class LivesManager extends ChangeNotifier {
  static final LivesManager _instance = LivesManager._internal();
  factory LivesManager() => _instance;
  LivesManager._internal();

  static const String _keyLives = 'lm_lives';
  static const String _keyNextRegenAtMs = 'lm_next_regen_at_ms';
  static const String _keyBestScore = 'lm_best_score';
  static const String _keyBestStreak = 'lm_best_streak';

  final ValueNotifier<int> _livesNotifier = ValueNotifier<int>(3); // Will be updated in initialize()
  Timer? _timer;
  int _bestScore = 0;
  int _bestStreak = 0;
  bool _isInitialized = false;

  ValueListenable<int> get livesListenable => _livesNotifier;
  int get currentLives => _livesNotifier.value;
  int get bestScore => _bestScore;
  int get bestStreak => _bestStreak;

  /// Get current max hearts (3 normal, 6 with Heart Booster)
  int get maxLives {
    final inventory = InventoryManager();
    return inventory.isHeartBoosterActive ? 6 : GameConfig.maxLives;
  }

  /// Get current regen interval in seconds (10 min normal, 8 min with Heart Booster)
  int get regenIntervalSeconds {
    final inventory = InventoryManager();
    return inventory.isHeartBoosterActive ? 8 * 60 : GameConfig.lifeRegenIntervalSeconds;
  }

  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('🔄 LivesManager already initialized, skipping duplicate initialization');
      return;
    }
    
    final prefs = await SharedPreferences.getInstance();
    final storedLives = prefs.getInt(_keyLives);
    final storedNextRegenMs = prefs.getInt(_keyNextRegenAtMs);
    
    // Load best scores
    _bestScore = prefs.getInt(_keyBestScore) ?? 0;
    _bestStreak = prefs.getInt(_keyBestStreak) ?? 0;

    int lives = storedLives ?? maxLives;
    int? nextRegenMs = storedNextRegenMs;

    // Apply catch-up regeneration using current settings
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final intervalMs = regenIntervalSeconds * 1000;
    final currentMaxLives = maxLives;
    
    if (lives < currentMaxLives && nextRegenMs != null) {
      while (lives < currentMaxLives && nextRegenMs! <= nowMs) {
        lives += 1;
        nextRegenMs = nextRegenMs + intervalMs;
      }
      if (lives >= currentMaxLives) {
        nextRegenMs = null; // full
      }
    }

    _livesNotifier.value = lives.clamp(0, currentMaxLives);
    await _persist(lives: _livesNotifier.value, nextRegenAtMs: nextRegenMs);

    _startTicker();
    _isInitialized = true;
    debugPrint('🔄 LivesManager initialized with $_livesNotifier.value lives');
  }

  Future<void> consumeLife() async {
    int lives = _livesNotifier.value;
    if (lives <= 0) return;
    lives -= 1;
    _livesNotifier.value = lives;

    final prefs = await SharedPreferences.getInstance();
    int? nextRegenMs = prefs.getInt(_keyNextRegenAtMs);
    final currentMaxLives = maxLives;
    if (lives < currentMaxLives && nextRegenMs == null) {
      nextRegenMs = DateTime.now().millisecondsSinceEpoch + regenIntervalSeconds * 1000;
    }
    await _persist(lives: lives, nextRegenAtMs: nextRegenMs);
    notifyListeners();
  }

  Future<void> addLife([int amount = 1]) async {
    int lives = _livesNotifier.value;
    final currentMaxLives = maxLives;
    lives = (lives + amount).clamp(0, currentMaxLives);
    _livesNotifier.value = lives;

    int? nextRegenMs;
    if (lives >= currentMaxLives) {
      nextRegenMs = null;
    } else {
      // Keep existing timer
      final prefs = await SharedPreferences.getInstance();
      nextRegenMs = prefs.getInt(_keyNextRegenAtMs);
    }
    await _persist(lives: lives, nextRegenAtMs: nextRegenMs);
    notifyListeners();
  }

  /// Refill hearts to maximum (for store purchases)
  Future<void> refillToMax() async {
    final currentMaxLives = maxLives;
    final heartsToAdd = currentMaxLives - _livesNotifier.value;
    if (heartsToAdd > 0) {
      await addLife(heartsToAdd);
      debugPrint('💖 Hearts refilled to max: $currentMaxLives');
    }
  }

  /// Force reset manager to new player state (for development reset)
  Future<void> forceResetToNewPlayer() async {
    _isInitialized = false;
    _bestScore = 0;
    _bestStreak = 0;
    _timer?.cancel();
    _timer = null;
    
    // Set to new player defaults
    _livesNotifier.value = GameConfig.maxLives; // 3 hearts
    await _persist(lives: GameConfig.maxLives, nextRegenAtMs: null);
    
    _isInitialized = true;
    notifyListeners();
    debugPrint('🔄 LivesManager force reset to new player: ${GameConfig.maxLives} lives');
  }

  /// Set lives to a specific value (for game over scenarios)
  Future<void> setLives(int newLives) async {
    final currentMaxLives = maxLives;
    final clampedLives = newLives.clamp(0, currentMaxLives);
    _livesNotifier.value = clampedLives;

    int? nextRegenMs;
    if (clampedLives >= currentMaxLives) {
      nextRegenMs = null; // Full lives, no timer needed
    } else if (clampedLives <= 0) {
      nextRegenMs = DateTime.now().millisecondsSinceEpoch + regenIntervalSeconds * 1000; // Start timer for regeneration
    } else {
      // Keep existing timer if it exists
      final prefs = await SharedPreferences.getInstance();
      nextRegenMs = prefs.getInt(_keyNextRegenAtMs) ?? 
          (DateTime.now().millisecondsSinceEpoch + regenIntervalSeconds * 1000);
    }
    await _persist(lives: clampedLives, nextRegenAtMs: nextRegenMs);
    notifyListeners();
    debugPrint('🔄 LivesManager lives set to $clampedLives');
  }

  /// Update best score and return true if it's a new record
  Future<bool> updateBestScore(int newScore) async {
    bool isNewRecord = false;
    if (newScore > _bestScore) {
      _bestScore = newScore;
      isNewRecord = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyBestScore, _bestScore);
      notifyListeners();
    }
    return isNewRecord;
  }

  /// Update best streak and return true if it's a new record
  Future<bool> updateBestStreak(int newStreak) async {
    bool isNewRecord = false;
    if (newStreak > _bestStreak) {
      _bestStreak = newStreak;
      isNewRecord = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyBestStreak, _bestStreak);
      notifyListeners();
    }
    return isNewRecord;
  }

  Future<void> _persist({required int lives, int? nextRegenAtMs}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLives, lives);
    if (nextRegenAtMs == null) {
      await prefs.remove(_keyNextRegenAtMs);
    } else {
      await prefs.setInt(_keyNextRegenAtMs, nextRegenAtMs);
    }
  }

  void _startTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) async {
      final prefs = await SharedPreferences.getInstance();
      int lives = _livesNotifier.value;
      int? nextRegenMs = prefs.getInt(_keyNextRegenAtMs);
      final currentMaxLives = maxLives;
      
      if (lives >= currentMaxLives || nextRegenMs == null) return;

      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final intervalMs = regenIntervalSeconds * 1000;
      bool changed = false;
      while (lives < currentMaxLives && nextRegenMs! <= nowMs) {
        lives += 1;
        nextRegenMs = nextRegenMs + intervalMs;
        changed = true;
      }
      if (lives >= currentMaxLives) {
        nextRegenMs = null;
      }
      if (changed) {
        _livesNotifier.value = lives;
        await _persist(lives: lives, nextRegenAtMs: nextRegenMs);
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Time remaining until next heart in seconds; returns null if at max
  Future<int?> getSecondsUntilNextRegen() async {
    final prefs = await SharedPreferences.getInstance();
    final nextRegenMs = prefs.getInt(_keyNextRegenAtMs);
    if (nextRegenMs == null) return null;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final remaining = nextRegenMs - nowMs;
    return remaining > 0 ? (remaining / 1000).ceil() : 0;
  }
}


