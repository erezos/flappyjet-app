/// 🎒 Inventory Sync Service - Synchronizes skin purchases with Railway backend
/// 
/// Handles all skin synchronization operations with robust error handling,
/// retry logic, and offline queuing following blockbuster gaming standards.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/debug_logger.dart';
import '../core/network/network_manager.dart';
import '../game/systems/player_identity_manager.dart';

/// Pending sync operation for retry queue
class PendingSync {
  final String skinId;
  final bool equipped;
  final String acquiredMethod;
  final DateTime timestamp;
  int retryCount = 0;
  
  PendingSync({
    required this.skinId,
    required this.equipped,
    required this.acquiredMethod,
  }) : timestamp = DateTime.now();
  
  Map<String, dynamic> toJson() => {
    'skinId': skinId,
    'equipped': equipped,
    'acquiredMethod': acquiredMethod,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'retryCount': retryCount,
  };
  
  factory PendingSync.fromJson(Map<String, dynamic> json) {
    final sync = PendingSync(
      skinId: json['skinId'],
      equipped: json['equipped'],
      acquiredMethod: json['acquiredMethod'],
    );
    sync.retryCount = json['retryCount'] ?? 0;
    return sync;
  }
}

/// Sync result for tracking success/failure
class SyncResult {
  final bool success;
  final String? error;
  final String? skinId;
  final bool wasQueued;
  
  SyncResult.success(this.skinId) 
    : success = true, error = null, wasQueued = false;
  
  SyncResult.error(this.error, {this.skinId, this.wasQueued = false}) 
    : success = false;
  
  SyncResult.queued(this.skinId) 
    : success = false, error = 'Queued for retry', wasQueued = true;
}

/// Inventory Sync Service - Singleton for managing skin synchronization
class InventorySyncService extends ChangeNotifier {
  static final InventorySyncService _instance = InventorySyncService._internal();
  factory InventorySyncService() => _instance;
  InventorySyncService._internal();

  // Dependencies
  final NetworkManager _networkManager = NetworkManager();
  final PlayerIdentityManager _playerIdentity = PlayerIdentityManager();
  
  // State
  bool _isInitialized = false;
  bool _isSyncing = false;
  final List<PendingSync> _pendingSyncs = [];
  Timer? _syncTimer;
  Timer? _retryTimer;
  
  // Configuration
  static const Duration _retryInterval = Duration(minutes: 2);
  static const int _maxRetries = 5;
  static const Duration _requestTimeout = Duration(seconds: 15);
  
  // Getters
  bool get isInitialized => _isInitialized;
  bool get isSyncing => _isSyncing;
  int get pendingSyncCount => _pendingSyncs.length;
  bool get hasPendingSyncs => _pendingSyncs.isNotEmpty;

  /// Initialize the sync service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      safePrint('🎒 🚀 Initializing Inventory Sync Service...');
      
      // Start retry timer for pending syncs
      _startRetryTimer();
      
      // Process any existing pending syncs
      await _processPendingSyncs();
      
      _isInitialized = true;
      safePrint('🎒 ✅ Inventory Sync Service initialized successfully');
      
    } catch (e) {
      safePrint('🎒 ❌ Failed to initialize Inventory Sync Service: $e');
      rethrow;
    }
  }

  /// Sync single skin to backend
  Future<SyncResult> syncSkin(String skinId, {
    bool equipped = false, 
    String acquiredMethod = 'purchase'
  }) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    safePrint('🎒 Syncing skin: $skinId (equipped: $equipped, method: $acquiredMethod)');
    
    // Check if user is authenticated
    if (!_playerIdentity.isAuthenticated) {
      safePrint('🎒 ⚠️ User not authenticated - queuing sync for later');
      _queueSync(PendingSync(
        skinId: skinId,
        equipped: equipped,
        acquiredMethod: acquiredMethod,
      ));
      return SyncResult.queued(skinId);
    }
    
    try {
      _isSyncing = true;
      notifyListeners();
      
      final request = NetworkRequest(
        endpoint: '/api/inventory/sync-skin',
        method: 'POST',
        body: {
          'skinId': skinId,
          'equipped': equipped,
          'acquiredMethod': acquiredMethod,
        },
        requiresAuth: true,
        canQueue: true,
        timeout: _requestTimeout,
        priority: 2, // High priority for purchases
        deduplicationKey: 'sync-skin-$skinId-$equipped',
      );
      
      final result = await _networkManager.request(request);
      
      if (result.success) {
        safePrint('🎒 ✅ Skin synced successfully: $skinId');
        return SyncResult.success(skinId);
      } else {
        safePrint('🎒 ❌ Skin sync failed: ${result.error}');
        _queueSync(PendingSync(
          skinId: skinId,
          equipped: equipped,
          acquiredMethod: acquiredMethod,
        ));
        return SyncResult.error(result.error, skinId: skinId, wasQueued: true);
      }
      
    } catch (e) {
      safePrint('🎒 ❌ Skin sync error: $e');
      _queueSync(PendingSync(
        skinId: skinId,
        equipped: equipped,
        acquiredMethod: acquiredMethod,
      ));
      return SyncResult.error(e.toString(), skinId: skinId, wasQueued: true);
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Sync all owned skins to backend (batch operation)
  Future<SyncResult> syncAllSkins(Set<String> ownedSkins, String equippedSkin) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    if (ownedSkins.isEmpty) {
      safePrint('🎒 ⚠️ No skins to sync');
      return SyncResult.success(null);
    }
    
    safePrint('🎒 Batch syncing ${ownedSkins.length} skins (equipped: $equippedSkin)');
    
    // Check if user is authenticated
    if (!_playerIdentity.isAuthenticated) {
      safePrint('🎒 ⚠️ User not authenticated - queuing all skins for later');
      for (final skinId in ownedSkins) {
        _queueSync(PendingSync(
          skinId: skinId,
          equipped: skinId == equippedSkin,
          acquiredMethod: 'purchase',
        ));
      }
      return SyncResult.queued(null);
    }
    
    try {
      _isSyncing = true;
      notifyListeners();
      
      final skins = ownedSkins.map((skinId) => {
        'skinId': skinId,
        'equipped': skinId == equippedSkin,
        'acquiredMethod': 'purchase', // Default for batch sync
      }).toList();
      
      final request = NetworkRequest(
        endpoint: '/api/inventory/sync-batch',
        method: 'POST',
        body: {'skins': skins},
        requiresAuth: true,
        canQueue: true,
        timeout: _requestTimeout,
        priority: 1, // Highest priority for full sync
        deduplicationKey: 'sync-batch-${ownedSkins.length}',
      );
      
      final result = await _networkManager.request(request);
      
      if (result.success) {
        safePrint('🎒 ✅ All skins synced successfully: ${ownedSkins.length} skins');
        return SyncResult.success(null);
      } else {
        safePrint('🎒 ❌ Batch skin sync failed: ${result.error}');
        // Queue individual skins for retry
        for (final skinId in ownedSkins) {
          _queueSync(PendingSync(
            skinId: skinId,
            equipped: skinId == equippedSkin,
            acquiredMethod: 'purchase',
          ));
        }
        return SyncResult.error(result.error, wasQueued: true);
      }
      
    } catch (e) {
      safePrint('🎒 ❌ Batch skin sync error: $e');
      // Queue individual skins for retry
      for (final skinId in ownedSkins) {
        _queueSync(PendingSync(
          skinId: skinId,
          equipped: skinId == equippedSkin,
          acquiredMethod: 'purchase',
        ));
      }
      return SyncResult.error(e.toString(), wasQueued: true);
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Get current inventory status from backend
  Future<Map<String, dynamic>?> getInventoryStatus() async {
    if (!_playerIdentity.isAuthenticated) {
      safePrint('🎒 ⚠️ Cannot get inventory status - not authenticated');
      return null;
    }
    
    try {
      final request = NetworkRequest(
        endpoint: '/api/inventory/status',
        method: 'GET',
        requiresAuth: true,
        canQueue: false,
        timeout: _requestTimeout,
        priority: 3, // Normal priority
      );
      
      final result = await _networkManager.request(request);
      
      if (result.success) {
        safePrint('🎒 ✅ Retrieved inventory status from backend');
        return result.data;
      } else {
        safePrint('🎒 ❌ Failed to get inventory status: ${result.error}');
        return null;
      }
      
    } catch (e) {
      safePrint('🎒 ❌ Error getting inventory status: $e');
      return null;
    }
  }

  /// Queue sync for later retry
  void _queueSync(PendingSync sync) {
    // Check if sync already exists
    final existingIndex = _pendingSyncs.indexWhere(
      (s) => s.skinId == sync.skinId && s.equipped == sync.equipped
    );
    
    if (existingIndex != -1) {
      // Update existing sync
      _pendingSyncs[existingIndex] = sync;
    } else {
      // Add new sync
      _pendingSyncs.add(sync);
    }
    
    safePrint('🎒 📝 Queued sync: ${sync.skinId} (${_pendingSyncs.length} pending)');
    notifyListeners();
  }

  /// Start retry timer for pending syncs
  void _startRetryTimer() {
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(_retryInterval, (timer) {
      _processPendingSyncs();
    });
  }

  /// Process pending syncs
  Future<void> _processPendingSyncs() async {
    if (_pendingSyncs.isEmpty || !_playerIdentity.isAuthenticated) {
      return;
    }
    
    safePrint('🎒 🔄 Processing ${_pendingSyncs.length} pending syncs...');
    
    final syncs = List<PendingSync>.from(_pendingSyncs);
    _pendingSyncs.clear();
    
    for (final sync in syncs) {
      if (sync.retryCount >= _maxRetries) {
        safePrint('🎒 ❌ Max retries exceeded for skin: ${sync.skinId}');
        continue;
      }
      
      sync.retryCount++;
      final result = await syncSkin(
        sync.skinId,
        equipped: sync.equipped,
        acquiredMethod: sync.acquiredMethod,
      );
      
      if (!result.success && result.wasQueued) {
        // Re-queue if still failed
        _pendingSyncs.add(sync);
      }
    }
    
    notifyListeners();
  }

  /// Force sync all pending operations (for recovery scenarios)
  Future<void> forceSyncAll() async {
    if (_pendingSyncs.isEmpty) {
      safePrint('🎒 ⚠️ No pending syncs to force');
      return;
    }
    
    safePrint('🎒 🔥 Force syncing ${_pendingSyncs.length} pending operations...');
    
    final syncs = List<PendingSync>.from(_pendingSyncs);
    _pendingSyncs.clear();
    
    for (final sync in syncs) {
      await syncSkin(
        sync.skinId,
        equipped: sync.equipped,
        acquiredMethod: sync.acquiredMethod,
      );
    }
    
    notifyListeners();
  }

  /// Clear all pending syncs (for testing/debugging)
  void clearPendingSyncs() {
    safePrint('🎒 🧹 Clearing ${_pendingSyncs.length} pending syncs');
    _pendingSyncs.clear();
    notifyListeners();
  }

  /// Dispose resources
  @override
  void dispose() {
    _syncTimer?.cancel();
    _retryTimer?.cancel();
    super.dispose();
  }
}
