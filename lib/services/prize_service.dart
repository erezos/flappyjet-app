/// 🏆 Prize Service - Background Prize Polling and Claiming
/// 
/// Polls backend for pending prizes, manages local claiming, and shows celebration UI
library;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/pending_prize.dart';
import '../core/repositories/prize_repository.dart';
import '../game/systems/inventory_manager.dart';
import '../core/events/event_bus.dart';
import '../core/identity/device_identity_manager.dart';
import '../core/debug_logger.dart';

class PrizeService extends ChangeNotifier {
  final PrizeRepository _prizeRepository;
  final InventoryManager _inventory;
  final EventBus _eventBus;
  final DeviceIdentityManager _identity;

  Timer? _pollTimer;
  bool _isInitialized = false;
  bool _isChecking = false;

  // Configuration
  static const Duration _pollInterval = Duration(minutes: 10);
  static const Duration _startupDelay = Duration(seconds: 5);
  static const String _baseUrl =
      'https://flappyjet-production.up.railway.app';

  // State
  List<PendingPrize> _unclaimedPrizes = [];
  DateTime? _lastCheckTime;

  PrizeService({
    required PrizeRepository prizeRepository,
    required InventoryManager inventory,
    required EventBus eventBus,
    required DeviceIdentityManager identity,
  })  : _prizeRepository = prizeRepository,
        _inventory = inventory,
        _eventBus = eventBus,
        _identity = identity;

  // ============================================================================
  // GETTERS
  // ============================================================================

  bool get isInitialized => _isInitialized;
  bool get isChecking => _isChecking;
  List<PendingPrize> get unclaimedPrizes => List.unmodifiable(_unclaimedPrizes);
  int get unclaimedPrizeCount => _unclaimedPrizes.length;
  bool get hasUnclaimedPrizes => _unclaimedPrizes.isNotEmpty;
  DateTime? get lastCheckTime => _lastCheckTime;

  // ============================================================================
  // INITIALIZATION
  // ============================================================================

  /// Initialize the prize service
  Future<void> initialize() async {
    if (_isInitialized) {
      safePrint('🏆 PrizeService already initialized');
      return;
    }

    safePrint('🏆 Initializing PrizeService...');

    try {
      // Load unclaimed prizes from local storage
      _unclaimedPrizes = await _prizeRepository.getUnclaimedPrizes();
      safePrint('🏆 Loaded ${_unclaimedPrizes.length} unclaimed prizes from storage');

      // Schedule initial check after a delay (to avoid blocking startup)
      Future.delayed(_startupDelay, () {
        checkForPrizes();
      });

      // Start periodic polling
      _startPolling();

      _isInitialized = true;
      safePrint('🏆 ✅ PrizeService initialized');
      notifyListeners();
    } catch (e) {
      safePrint('🏆 ❌ Error initializing PrizeService: $e');
    }
  }

  /// Start periodic polling for prizes
  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      checkForPrizes();
    });
    safePrint('🏆 Background polling started (every ${_pollInterval.inMinutes} minutes)');
  }

  /// Stop polling (for cleanup)
  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    safePrint('🏆 Background polling stopped');
  }

  // ============================================================================
  // PRIZE CHECKING
  // ============================================================================

  /// Check backend for pending prizes
  Future<void> checkForPrizes() async {
    if (_isChecking) {
      safePrint('🏆 Already checking for prizes, skipping...');
      return;
    }

    _isChecking = true;
    _lastCheckTime = DateTime.now();
    notifyListeners();

    try {
      safePrint('🏆 Checking backend for pending prizes...');

      // Call backend API to get pending prizes
      final userId = _identity.userId;
      final url = Uri.parse('$_baseUrl/api/prizes/pending?user_id=$userId');
      
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final prizesJson = data['prizes'] as List<dynamic>? ?? [];
        final newPrizes = prizesJson
            .map((json) => PendingPrize.fromJson(json as Map<String, dynamic>))
            .toList();

        safePrint('🏆 Found ${newPrizes.length} pending prizes from backend');

        // Save to local storage
        if (newPrizes.isNotEmpty) {
          await _prizeRepository.savePrizes(newPrizes);
          _unclaimedPrizes = await _prizeRepository.getUnclaimedPrizes();

          safePrint('🏆 ✅ ${newPrizes.length} new prizes ready to claim!');

          // Fire event
          _eventBus.fire('prize_available', {
            'count': newPrizes.length,
            'total_coins': newPrizes.fold<int>(0, (sum, p) => sum + p.coins),
            'total_gems': newPrizes.fold<int>(0, (sum, p) => sum + p.gems),
          });

          notifyListeners();
        } else {
          safePrint('🏆 No new prizes found');
        }
      } else if (response.statusCode == 404) {
        safePrint('🏆 No prizes available (404)');
      } else {
        safePrint('🏆 ⚠️ Unexpected status code: ${response.statusCode}');
      }
    } catch (e) {
      safePrint('🏆 ⚠️ Error checking for prizes: $e');
      // Not a critical error, will retry on next poll
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  /// Manually trigger a prize check (for "Check for Prizes" button)
  Future<bool> manualCheck() async {
    safePrint('🏆 Manual prize check triggered');
    await checkForPrizes();
    return hasUnclaimedPrizes;
  }

  // ============================================================================
  // PRIZE CLAIMING
  // ============================================================================

  /// Claim a prize (award locally and notify backend)
  Future<bool> claimPrize(PendingPrize prize) async {
    if (prize.isClaimed) {
      safePrint('🏆 ⚠️ Prize ${prize.prizeId} already claimed');
      return false;
    }

    try {
      safePrint('🏆 Claiming prize ${prize.prizeId}...');

      // 1. Award locally FIRST (instant, never fails)
      await _inventory.grantSoftCurrency(
        prize.coins,
        source: 'prize_claimed',
        sourceId: prize.prizeId,
      );
      await _inventory.grantGems(
        prize.gems,
        source: 'prize_claimed',
        sourceId: prize.prizeId,
      );
      safePrint('🏆 ✅ Awarded ${prize.coins} coins + ${prize.gems} gems locally');

      // 2. Mark as claimed in local storage
      final claimedAt = DateTime.now();
      await _prizeRepository.markPrizeClaimed(prize.prizeId, claimedAt);
      safePrint('🏆 ✅ Marked prize as claimed in local storage');

      // 3. Update local list
      _unclaimedPrizes = await _prizeRepository.getUnclaimedPrizes();
      notifyListeners();

      // 4. Notify backend (fire-and-forget, non-blocking)
      _notifyBackendPrizeClaimed(prize, claimedAt);

      // 5. Fire event for analytics
      _eventBus.fire('prize_claimed', {
        'prize_id': prize.prizeId,
        'tournament_id': prize.tournamentId,
        'tournament_name': prize.tournamentName,
        'rank': prize.rank,
        'coins': prize.coins,
        'gems': prize.gems,
        'claimed_at': claimedAt.toIso8601String(),
      });

      safePrint('🏆 ✅ Prize claimed successfully!');
      return true;
    } catch (e) {
      safePrint('🏆 ❌ Error claiming prize: $e');
      return false;
    }
  }

  /// Claim all unclaimed prizes at once
  Future<int> claimAllPrizes() async {
    if (!hasUnclaimedPrizes) return 0;

    safePrint('🏆 Claiming all ${_unclaimedPrizes.length} prizes...');
    int claimedCount = 0;

    for (final prize in List.from(_unclaimedPrizes)) {
      final success = await claimPrize(prize);
      if (success) claimedCount++;
    }

    safePrint('🏆 ✅ Claimed $claimedCount prizes');
    return claimedCount;
  }

  /// Notify backend that a prize was claimed (fire-and-forget)
  void _notifyBackendPrizeClaimed(PendingPrize prize, DateTime claimedAt) {
    // Fire-and-forget: don't await, don't block
    final url = Uri.parse('$_baseUrl/api/prizes/claim');
    final body = jsonEncode({
      'prize_id': prize.prizeId,
      'user_id': _identity.userId,
      'claimed_at': claimedAt.toIso8601String(),
    });

    http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    ).timeout(const Duration(seconds: 5)).then((response) {
      if (response.statusCode == 200) {
        safePrint('🏆 ✅ Backend notified of prize claim');
      } else {
        safePrint('🏆 ⚠️ Backend notification failed (non-critical): ${response.statusCode}');
      }
    }).catchError((e) {
      safePrint('🏆 ⚠️ Backend notification error (non-critical): $e');
    });
  }

  // ============================================================================
  // CLEANUP
  // ============================================================================

  /// Clean up old claimed prizes (called periodically or manually)
  Future<void> cleanupOldPrizes({int daysOld = 30}) async {
    safePrint('🏆 Cleaning up old claimed prizes (older than $daysOld days)...');
    await _prizeRepository.deleteOldClaimedPrizes(daysOld: daysOld);
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}

