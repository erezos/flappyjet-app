/// 🔄 Auto-Refill Manager - Automatic heart refilling system
/// Handles auto-refill boosters that instantly refill hearts when returning to menu
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/debug_logger.dart';
import 'lives_manager.dart';
import 'player_identity_manager.dart';
import '../../core/network/network_manager.dart';

/// Auto-Refill booster duration options
enum AutoRefillDuration {
  oneHour(1, "1H Auto-Refill", "1 Hour Auto-Refill"),
  twelveHours(12, "12H Auto-Refill", "12 Hours Auto-Refill"), 
  threeDays(72, "3D Auto-Refill", "3 Days Auto-Refill");

  const AutoRefillDuration(this.hours, this.shortName, this.displayName);
  
  final int hours;
  final String shortName;
  final String displayName;
}

/// Auto-Refill Manager
/// Manages auto-refill boosters that automatically refill hearts when returning to menu
class AutoRefillManager extends ChangeNotifier {
  static final AutoRefillManager _instance = AutoRefillManager._internal();
  factory AutoRefillManager() => _instance;
  AutoRefillManager._internal();

  // SharedPreferences keys
  static const String _keyAutoRefillExpiry = 'auto_refill_expiry';
  static const String _keyLastAutoRefillCheck = 'last_auto_refill_check';

  DateTime? _autoRefillExpiry;
  DateTime? _lastAutoRefillCheck;
  bool _isInitialized = false;
  Timer? _statusUpdateTimer;
  
  // API call deduplication
  bool _isSyncingWithBackend = false;
  bool _isTriggeringAutoRefill = false;
  DateTime? _lastBackendSyncAttempt;

  final ValueNotifier<bool> _autoRefillActiveNotifier = ValueNotifier<bool>(false);

  // Getters
  bool get isAutoRefillActive => 
    _autoRefillExpiry != null && DateTime.now().isBefore(_autoRefillExpiry!);
  
  DateTime? get autoRefillExpiry => _autoRefillExpiry;
  bool get isInitialized => _isInitialized;
  
  ValueListenable<bool> get autoRefillActiveNotifier => _autoRefillActiveNotifier;

  /// Get remaining time for Auto-Refill (null if not active)
  Duration? get autoRefillTimeRemaining {
    if (_autoRefillExpiry == null) return null;
    final now = DateTime.now();
    if (now.isAfter(_autoRefillExpiry!)) return null;
    return _autoRefillExpiry!.difference(now);
  }

  /// Initialize Auto-Refill system
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load auto-refill expiry
      final expiryMs = prefs.getInt(_keyAutoRefillExpiry);
      if (expiryMs != null) {
        _autoRefillExpiry = DateTime.fromMillisecondsSinceEpoch(expiryMs);
        // Check if it's expired
        if (DateTime.now().isAfter(_autoRefillExpiry!)) {
          _autoRefillExpiry = null;
          await prefs.remove(_keyAutoRefillExpiry);
        }
      }

      // Load last check time
      final lastCheckMs = prefs.getInt(_keyLastAutoRefillCheck);
      if (lastCheckMs != null) {
        _lastAutoRefillCheck = DateTime.fromMillisecondsSinceEpoch(lastCheckMs);
      }

      _autoRefillActiveNotifier.value = isAutoRefillActive;
      _isInitialized = true;
      
      // Start periodic status updates
      _startStatusUpdateTimer();
      
      safePrint('🔄 AutoRefillManager initialized - Active: $isAutoRefillActive');
      notifyListeners();
    } catch (e) {
      safePrint('❌ AutoRefillManager initialization error: $e');
    }
  }

  /// Activate auto-refill booster for the specified duration
  Future<void> activateAutoRefill(AutoRefillDuration duration) async {
    if (!_isInitialized) return;

    try {
      final now = DateTime.now();
      final newExpiry = now.add(Duration(hours: duration.hours));

      // If already active, extend the duration from current expiry
      if (_autoRefillExpiry != null && _autoRefillExpiry!.isAfter(now)) {
        _autoRefillExpiry = _autoRefillExpiry!.add(Duration(hours: duration.hours));
      } else {
        _autoRefillExpiry = newExpiry;
      }

      await _persistAutoRefill();
      _autoRefillActiveNotifier.value = isAutoRefillActive;
      notifyListeners();

      // Sync with backend if authenticated
      await _syncWithBackend(duration.hours);

      safePrint('🔄 Auto-Refill activated! Duration: ${duration.hours}h, Expiry: $_autoRefillExpiry');
    } catch (e) {
      safePrint('❌ Auto-Refill activation error: $e');
    }
  }

  /// Check and trigger auto-refill if conditions are met
  /// Call this when returning to homepage
  Future<bool> checkAndTriggerAutoRefill() async {
    if (!_isInitialized || !isAutoRefillActive) {
      return false;
    }

    try {
      final livesManager = LivesManager();
      final currentHearts = livesManager.currentLives;
      final maxHearts = livesManager.maxLives;

      // Don't refill if already at max
      if (currentHearts >= maxHearts) {
        return false;
      }

      // Check cooldown to prevent spam (minimum 5 seconds between auto-refills)
      final now = DateTime.now();
      if (_lastAutoRefillCheck != null) {
        final timeSinceLastCheck = now.difference(_lastAutoRefillCheck!);
        if (timeSinceLastCheck.inSeconds < 5) {
          return false;
        }
      }

      // Trigger auto-refill
      await livesManager.refillToMax();
      _lastAutoRefillCheck = now;
      
      // Persist last check time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyLastAutoRefillCheck, now.millisecondsSinceEpoch);

      // Sync with backend
      await _syncAutoRefillTrigger();

      safePrint('🔄 Auto-Refill triggered! Hearts: $currentHearts → $maxHearts');
      return true;
    } catch (e) {
      safePrint('❌ Auto-Refill trigger error: $e');
      return false;
    }
  }

  /// Check and update auto-refill status (call periodically)
  Future<void> updateAutoRefillStatus() async {
    if (!_isInitialized) return;

    final wasActive = _autoRefillActiveNotifier.value;
    final isActive = isAutoRefillActive;

    if (wasActive && !isActive) {
      // Auto-refill just expired, clean up
      _autoRefillExpiry = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyAutoRefillExpiry);
      _autoRefillActiveNotifier.value = false;
      safePrint('🔄 Auto-Refill expired and cleaned up');
      notifyListeners();
    } else if (wasActive != isActive) {
      _autoRefillActiveNotifier.value = isActive;
      notifyListeners();
    }
  }

  /// Force reset manager to new player state (for development reset)
  Future<void> forceResetToNewPlayer() async {
    _isInitialized = false;
    _autoRefillExpiry = null;
    _lastAutoRefillCheck = null;
    _statusUpdateTimer?.cancel();
    _statusUpdateTimer = null;

    // Clear SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAutoRefillExpiry);
    await prefs.remove(_keyLastAutoRefillCheck);

    _autoRefillActiveNotifier.value = false;
    _isInitialized = true;
    _startStatusUpdateTimer();
    notifyListeners();
    safePrint('🔄 AutoRefillManager force reset to new player');
  }

  /// Restore auto-refill from backend (for user restoration after reinstall)
  Future<void> restoreAutoRefill(DateTime? expiryTime) async {
    if (!_isInitialized) return;

    try {
      _autoRefillExpiry = expiryTime;
      
      // Check if it's expired
      if (_autoRefillExpiry != null && DateTime.now().isAfter(_autoRefillExpiry!)) {
        _autoRefillExpiry = null;
      }

      await _persistAutoRefill();
      _autoRefillActiveNotifier.value = isAutoRefillActive;
      notifyListeners();
      safePrint('🔄 Auto-Refill restored: ${_autoRefillExpiry != null ? 'Active until $_autoRefillExpiry' : 'Inactive'}');
    } catch (e) {
      safePrint('❌ Auto-Refill restoration error: $e');
    }
  }

  /// Persist auto-refill state to SharedPreferences
  Future<void> _persistAutoRefill() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_autoRefillExpiry == null) {
        await prefs.remove(_keyAutoRefillExpiry);
      } else {
        await prefs.setInt(_keyAutoRefillExpiry, _autoRefillExpiry!.millisecondsSinceEpoch);
      }
    } catch (e) {
      safePrint('❌ Auto-Refill persistence error: $e');
    }
  }

  /// Sync auto-refill activation with backend (with deduplication)
  Future<void> _syncWithBackend(int durationHours) async {
    // Prevent multiple simultaneous API calls
    if (_isSyncingWithBackend) {
      safePrint('🔄 Auto-Refill backend sync already in progress, skipping');
      return;
    }

    // Rate limiting: don't sync more than once per 5 seconds
    final now = DateTime.now();
    if (_lastBackendSyncAttempt != null) {
      final timeSinceLastSync = now.difference(_lastBackendSyncAttempt!);
      if (timeSinceLastSync.inSeconds < 5) {
        safePrint('🔄 Auto-Refill backend sync rate limited, skipping');
        return;
      }
    }

    _isSyncingWithBackend = true;
    _lastBackendSyncAttempt = now;

    try {
      final playerIdentity = PlayerIdentityManager();
      if (!playerIdentity.isAuthenticated) {
        safePrint('🔄 Auto-Refill sync skipped - not authenticated');
        return;
      }

      final networkManager = NetworkManager();
      final result = await networkManager.request(NetworkRequest(
        endpoint: '/api/player/activate-auto-refill',
        method: 'POST',
        body: {'durationHours': durationHours},
        canQueue: true, // Allow offline queueing
        priority: 3, // Medium priority
      ));

      if (result.success) {
        safePrint('🔄 ✅ Auto-Refill synced to backend: ${durationHours}h');
      } else {
        safePrint('🔄 ⚠️ Auto-Refill backend sync failed: ${result.error}');
      }
    } catch (e) {
      safePrint('🔄 ❌ Auto-Refill backend sync error: $e');
      // Don't throw - local functionality should work even if backend fails
    } finally {
      _isSyncingWithBackend = false;
    }
  }

  /// Sync auto-refill trigger with backend (with deduplication)
  Future<void> _syncAutoRefillTrigger() async {
    // Prevent multiple simultaneous trigger calls
    if (_isTriggeringAutoRefill) {
      safePrint('🔄 Auto-Refill trigger already in progress, skipping');
      return;
    }

    _isTriggeringAutoRefill = true;

    try {
      final playerIdentity = PlayerIdentityManager();
      if (!playerIdentity.isAuthenticated) {
        safePrint('🔄 Auto-Refill trigger skipped - not authenticated');
        return;
      }

      final networkManager = NetworkManager();
      final result = await networkManager.request(NetworkRequest(
        endpoint: '/api/player/check-auto-refill',
        method: 'POST',
        body: {},
        canQueue: true, // Allow offline queueing
        priority: 4, // Lower priority than activation
      ));

      if (result.success) {
        safePrint('🔄 ✅ Auto-Refill trigger synced to backend');
      } else {
        safePrint('🔄 ⚠️ Auto-Refill trigger sync failed: ${result.error}');
      }
    } catch (e) {
      safePrint('🔄 ❌ Auto-Refill trigger sync error: $e');
      // Don't throw - local functionality should work even if backend fails
    } finally {
      _isTriggeringAutoRefill = false;
    }
  }

  /// Start periodic status update timer
  void _startStatusUpdateTimer() {
    _statusUpdateTimer?.cancel();
    _statusUpdateTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      updateAutoRefillStatus();
    });
  }

  @override
  void dispose() {
    _statusUpdateTimer?.cancel();
    super.dispose();
  }
}
