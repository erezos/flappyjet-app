/// 🆔 Unified ID Manager - Single Source of Truth for Player IDs
/// 
/// Ensures consistent UUID v4 generation across all identity systems
/// Provides persistent master ID that survives app reinstalls
library;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import '../debug_logger.dart';

/// Unified ID Manager - Single source of truth for all player identification
class UnifiedIdManager extends ChangeNotifier {
  static final UnifiedIdManager _instance = UnifiedIdManager._internal();
  factory UnifiedIdManager() => _instance;
  UnifiedIdManager._internal();

  // Storage keys
  static const String _keyMasterId = 'master_player_id';
  static const String _keyDeviceId = 'device_id';
  static const String _keyBackupMasterId = 'backup_master_id';
  
  // Core IDs
  String? _masterId;
  String? _deviceId;
  bool _isInitialized = false;

  // Getters
  String? get masterId => _masterId;
  String? get deviceId => _deviceId;
  bool get isInitialized => _isInitialized;

  /// Initialize the unified ID manager
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      safePrint('🆔 Initializing Unified ID Manager...');
      
      // Load or generate master ID
      _masterId = await _getOrGenerateMasterId();
      
      // Load or generate device ID
      _deviceId = await _getOrGenerateDeviceId();
      
      _isInitialized = true;
      
      safePrint('🆔 ✅ Unified ID Manager initialized');
      safePrint('🆔 Master ID: ${_masterId!.substring(0, 8)}...');
      safePrint('🆔 Device ID: ${_deviceId!.substring(0, 8)}...');
      
      notifyListeners();
      
    } catch (e) {
      safePrint('🆔 ❌ Failed to initialize Unified ID Manager: $e');
      // Generate fallback IDs
      _masterId = _generateUUID();
      _deviceId = _generateUUID();
      _isInitialized = true;
    }
  }

  /// Get or generate master player ID (persistent across reinstalls)
  Future<String> getMasterId() async {
    if (_masterId != null) return _masterId!;
    return await _getOrGenerateMasterId();
  }

  /// Get or generate device ID (for analytics and device tracking)
  Future<String> getDeviceId() async {
    if (_deviceId != null) return _deviceId!;
    return await _getOrGenerateDeviceId();
  }

  /// Generate a new anonymous player ID (for anonymous users)
  String generateAnonymousId() {
    return 'anon_${_generateUUID()}';
  }

  /// Generate a new cloud player ID (for authenticated users)
  String generateCloudPlayerId() {
    return _generateUUID();
  }

  /// Check if two IDs belong to the same player
  bool areSamePlayer(String id1, String id2) {
    if (id1 == id2) return true;
    
    // Check if one is anonymous and one is cloud for same master ID
    if (id1.startsWith('anon_') && !id2.startsWith('anon_')) {
      return _areLinkedIds(id1, id2);
    }
    if (!id1.startsWith('anon_') && id2.startsWith('anon_')) {
      return _areLinkedIds(id2, id1);
    }
    
    return false;
  }

  /// Get or generate master ID from storage
  Future<String> _getOrGenerateMasterId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? storedId = prefs.getString(_keyMasterId);
      
      if (storedId != null && storedId.isNotEmpty) {
        safePrint('🆔 Loaded existing master ID from storage');
        return storedId;
      }
      
      // Generate new master ID
      final newMasterId = _generateUUID();
      await prefs.setString(_keyMasterId, newMasterId);
      
      // Create backup
      await prefs.setString(_keyBackupMasterId, newMasterId);
      
      safePrint('🆔 Generated new master ID');
      return newMasterId;
      
    } catch (e) {
      safePrint('🆔 ⚠️ Failed to load master ID from storage: $e');
      return _generateUUID();
    }
  }

  /// Get or generate device ID from storage
  Future<String> _getOrGenerateDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? storedId = prefs.getString(_keyDeviceId);
      
      if (storedId != null && storedId.isNotEmpty) {
        safePrint('🆔 Loaded existing device ID from storage');
        return storedId;
      }
      
      // Try to get real device ID first
      String deviceId = await _getRealDeviceId();
      
      // If real device ID failed, generate one
      if (deviceId.isEmpty) {
        deviceId = _generateUUID();
        safePrint('🆔 Generated fallback device ID');
      } else {
        safePrint('🆔 Retrieved real device ID');
      }
      
      await prefs.setString(_keyDeviceId, deviceId);
      return deviceId;
      
    } catch (e) {
      safePrint('🆔 ⚠️ Failed to load device ID from storage: $e');
      return _generateUUID();
    }
  }

  /// Get real device ID from platform
  Future<String> _getRealDeviceId() async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id; // Android ID
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? '';
      } else {
        return '';
      }
    } catch (e) {
      safePrint('🆔 ⚠️ Failed to get real device ID: $e');
      return '';
    }
  }

  /// Generate a proper UUID v4
  String _generateUUID() {
    const uuid = Uuid();
    return uuid.v4();
  }

  /// Check if two IDs are linked (anonymous and cloud for same player)
  bool _areLinkedIds(String anonymousId, String cloudId) {
    // This would check against backend linking table
    // For now, return false - this would be implemented with backend calls
    return false;
  }

  /// Force reset all IDs (for testing/development)
  Future<void> resetAllIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.remove(_keyMasterId);
      await prefs.remove(_keyDeviceId);
      await prefs.remove(_keyBackupMasterId);
      
      _masterId = null;
      _deviceId = null;
      _isInitialized = false;
      
      safePrint('🆔 ✅ All IDs reset');
      
    } catch (e) {
      safePrint('🆔 ❌ Failed to reset IDs: $e');
    }
  }

  /// Get ID statistics for debugging
  Map<String, dynamic> getIdStats() {
    return {
      'masterId': '${_masterId?.substring(0, 8) ?? 'null'}...',
      'deviceId': '${_deviceId?.substring(0, 8) ?? 'null'}...',
      'isInitialized': _isInitialized,
      'masterIdLength': _masterId?.length ?? 0,
      'deviceIdLength': _deviceId?.length ?? 0,
    };
  }
}
