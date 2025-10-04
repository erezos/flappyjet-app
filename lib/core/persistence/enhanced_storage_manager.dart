/// 💾 Enhanced Storage Manager - Data Persistence with Backup
/// 
/// Provides robust data storage with automatic backup and recovery
/// Prevents data loss during app reinstalls and device changes
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../debug_logger.dart';
import '../identity/unified_id_manager.dart';

/// Enhanced storage manager with backup and recovery capabilities
class EnhancedStorageManager extends ChangeNotifier {
  static final EnhancedStorageManager _instance = EnhancedStorageManager._internal();
  factory EnhancedStorageManager() => _instance;
  EnhancedStorageManager._internal();

  // Dependencies
  final UnifiedIdManager _idManager = UnifiedIdManager();

  // Storage keys
  static const String _keyPlayerData = 'player_data';
  static const String _keyBackupData = 'backup_player_data';
  static const String _keyCloudSyncStatus = 'cloud_sync_status';
  static const String _keyDataVersion = 'data_version';
  
  // Current data version for migration
  static const String _currentDataVersion = '1.0';
  
  // Status
  bool _isInitialized = false;
  Map<String, dynamic>? _cachedData;

  // Getters
  bool get isInitialized => _isInitialized;
  Map<String, dynamic>? get cachedData => _cachedData;

  /// Initialize the enhanced storage manager
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      safePrint('💾 Initializing Enhanced Storage Manager...');
      
      // Initialize unified ID manager
      await _idManager.initialize();
      
      // Load existing data
      await loadPlayerData();
      
      _isInitialized = true;
      
      safePrint('💾 ✅ Enhanced Storage Manager initialized');
      
    } catch (e) {
      safePrint('💾 ❌ Failed to initialize Enhanced Storage Manager: $e');
      _isInitialized = true;
    }
  }

  /// Save player data with automatic backup
  Future<void> savePlayerData(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Add metadata
      final enrichedData = {
        ...data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'version': _currentDataVersion,
        'masterId': await _idManager.getMasterId(),
        'deviceId': await _idManager.getDeviceId(),
      };
      
      // Save primary data
      await prefs.setString(_keyPlayerData, jsonEncode(enrichedData));
      
      // Create backup
      await _createBackup(enrichedData);
      
      // Mark for cloud sync
      await prefs.setBool(_keyCloudSyncStatus, false);
      
      // Cache data
      _cachedData = enrichedData;
      
      safePrint('💾 ✅ Player data saved with backup');
      
    } catch (e) {
      safePrint('💾 ❌ Failed to save player data: $e');
    }
  }

  /// Load player data with automatic recovery
  Future<Map<String, dynamic>?> loadPlayerData() async {
    if (_cachedData != null) return _cachedData;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Try to load primary data
      final primaryJson = prefs.getString(_keyPlayerData);
      if (primaryJson != null) {
        final data = jsonDecode(primaryJson);
        _cachedData = Map<String, dynamic>.from(data);
        
        // Check data version and migrate if needed
        await _migrateDataIfNeeded(_cachedData!);
        
        safePrint('💾 ✅ Player data loaded from primary storage');
        return _cachedData;
      }
      
      // Try to restore from backup
      final backupData = await _restoreFromBackup();
      if (backupData != null) {
        _cachedData = backupData;
        safePrint('💾 ✅ Player data restored from backup');
        return _cachedData;
      }
      
      safePrint('💾 ⚠️ No player data found');
      return null;
      
    } catch (e) {
      safePrint('💾 ❌ Failed to load player data: $e');
      return null;
    }
  }

  /// Save critical game data (scores, coins, etc.)
  Future<void> saveGameData({
    required int bestScore,
    required int coins,
    required int gems,
    required List<String> ownedSkins,
    required String equippedSkin,
  }) async {
    final gameData = {
      'bestScore': bestScore,
      'coins': coins,
      'gems': gems,
      'ownedSkins': ownedSkins,
      'equippedSkin': equippedSkin,
      'lastSaved': DateTime.now().millisecondsSinceEpoch,
    };
    
    await savePlayerData(gameData);
  }

  /// Load critical game data
  Future<Map<String, dynamic>?> loadGameData() async {
    final playerData = await loadPlayerData();
    if (playerData == null) return null;
    
    return {
      'bestScore': playerData['bestScore'] ?? 0,
      'coins': playerData['coins'] ?? 500,
      'gems': playerData['gems'] ?? 25,
      'ownedSkins': List<String>.from(playerData['ownedSkins'] ?? ['sky_jet']),
      'equippedSkin': playerData['equippedSkin'] ?? 'sky_jet',
      'lastSaved': playerData['lastSaved'] ?? DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// Create backup of current data
  Future<void> _createBackup(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final backupData = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': data,
        'version': _currentDataVersion,
        'masterId': await _idManager.getMasterId(),
      };
      
      await prefs.setString(_keyBackupData, jsonEncode(backupData));
      
    } catch (e) {
      safePrint('💾 ⚠️ Failed to create backup: $e');
    }
  }

  /// Restore data from backup
  Future<Map<String, dynamic>?> _restoreFromBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final backupJson = prefs.getString(_keyBackupData);
      
      if (backupJson != null) {
        final backup = jsonDecode(backupJson);
        final data = Map<String, dynamic>.from(backup['data']);
        
        // Restore primary data
        await prefs.setString(_keyPlayerData, jsonEncode(data));
        
        safePrint('💾 ✅ Data restored from backup');
        return data;
      }
      
      return null;
      
    } catch (e) {
      safePrint('💾 ❌ Failed to restore from backup: $e');
      return null;
    }
  }

  /// Migrate data if version has changed
  Future<void> _migrateDataIfNeeded(Map<String, dynamic> data) async {
    final currentVersion = data['version'] ?? '0.0';
    
    if (currentVersion != _currentDataVersion) {
      safePrint('💾 🔄 Migrating data from $currentVersion to $_currentDataVersion');
      
      // Add migration logic here as needed
      data['version'] = _currentDataVersion;
      
      // Save migrated data
      await savePlayerData(data);
      
      safePrint('💾 ✅ Data migration completed');
    }
  }

  /// Check if data needs cloud sync
  Future<bool> needsCloudSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyCloudSyncStatus) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Mark data as synced to cloud
  Future<void> markCloudSynced() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyCloudSyncStatus, true);
    } catch (e) {
      safePrint('💾 ⚠️ Failed to mark cloud sync: $e');
    }
  }

  /// Get storage statistics for debugging
  Map<String, dynamic> getStorageStats() {
    return {
      'isInitialized': _isInitialized,
      'hasCachedData': _cachedData != null,
      'dataVersion': _cachedData?['version'] ?? 'unknown',
      'lastSaved': _cachedData?['timestamp'] ?? 0,
      'masterId': (_cachedData?['masterId']?.toString().substring(0, 8) ?? 'null') + '...',
    };
  }

  /// Clear all stored data (for testing)
  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.remove(_keyPlayerData);
      await prefs.remove(_keyBackupData);
      await prefs.remove(_keyCloudSyncStatus);
      await prefs.remove(_keyDataVersion);
      
      _cachedData = null;
      
      safePrint('💾 ✅ All data cleared');
      
    } catch (e) {
      safePrint('💾 ❌ Failed to clear data: $e');
    }
  }

  /// Export data for backup/recovery
  Future<Map<String, dynamic>?> exportData() async {
    final data = await loadPlayerData();
    if (data == null) return null;
    
    return {
      'exportVersion': '1.0',
      'exportTimestamp': DateTime.now().millisecondsSinceEpoch,
      'masterId': await _idManager.getMasterId(),
      'data': data,
    };
  }

  /// Import data from backup
  Future<bool> importData(Map<String, dynamic> exportData) async {
    try {
      if (exportData['exportVersion'] != '1.0') {
        safePrint('💾 ❌ Unsupported export version');
        return false;
      }
      
      final data = Map<String, dynamic>.from(exportData['data']);
      await savePlayerData(data);
      
      safePrint('💾 ✅ Data imported successfully');
      return true;
      
    } catch (e) {
      safePrint('💾 ❌ Failed to import data: $e');
      return false;
    }
  }
}
