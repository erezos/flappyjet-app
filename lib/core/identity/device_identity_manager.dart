/// 🆔 Device Identity Manager - Hybrid Architecture User Identification
/// 
/// Generates and manages unique user IDs for the hybrid architecture.
/// No authentication required - uses device-based identification.
/// 
/// ID Format: user_[deviceId]_[timestamp]
/// Example: user_a1b2c3d4e5f6_1699459200
library;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../debug_logger.dart';

/// Device Identity Manager for hybrid architecture
/// 
/// Features:
/// - Device-based unique ID generation
/// - Session tracking
/// - No authentication required
/// - Offline-first design
class DeviceIdentityManager extends ChangeNotifier {
  static final DeviceIdentityManager _instance = DeviceIdentityManager._internal();
  factory DeviceIdentityManager() => _instance;
  DeviceIdentityManager._internal();

  // Storage keys
  static const String _keyUserId = 'hybrid_user_id';
  static const String _keySessionId = 'current_session_id';
  static const String _keyInstallDate = 'install_date';
  static const String _keyLastSessionDate = 'last_session_date';
  static const String _keyNickname = 'user_nickname'; // ✅ NEW: Nickname storage
  
  // Identity state
  String? _userId;
  String? _sessionId;
  DateTime? _installDate;
  DateTime? _lastSessionDate;
  bool _isInitialized = false;
  bool _isFirstLaunch = false;
  String _nickname = 'Pilot'; // ✅ NEW: Default nickname
  
  // Device info
  String? _deviceModel;
  String? _osVersion;
  String? _appVersion;
  String? _platform;

  // Getters
  String get userId => _userId ?? '';
  String get sessionId => _sessionId ?? '';
  String get nickname => _nickname; // ✅ NEW: Nickname getter
  DateTime? get installDate => _installDate;
  DateTime? get lastSessionDate => _lastSessionDate;
  bool get isInitialized => _isInitialized;
  bool get isFirstLaunch => _isFirstLaunch;
  
  String get deviceModel => _deviceModel ?? 'unknown';
  String get osVersion => _osVersion ?? 'unknown';
  String get appVersion => _appVersion ?? '0.0.0';
  String get platform => _platform ?? 'unknown';

  /// Initialize the device identity system
  /// 
  /// Call this once during app startup (in main.dart)
  /// 
  /// Returns the user ID
  Future<String> initialize() async {
    if (_isInitialized) return _userId!;

    try {
      safePrint('🆔 Initializing Device Identity Manager...');
      
      // Collect device information first
      await _collectDeviceInfo();
      
      // Load or generate user ID
      await _initializeUserId();
      
      // Load nickname
      await _loadNickname(); // ✅ NEW: Load saved nickname
      
      // Generate session ID for this app launch
      await _initializeSessionId();
      
      // Track session dates
      await _updateSessionDates();
      
      _isInitialized = true;
      
      safePrint('🆔 ✅ Device Identity Manager initialized');
      safePrint('🆔 User ID: ${_userId!.substring(0, 20)}...');
      safePrint('🆔 Session ID: ${_sessionId!.substring(0, 20)}...');
      safePrint('🆔 Nickname: $_nickname'); // ✅ NEW: Log nickname
      safePrint('🆔 Platform: $_platform');
      safePrint('🆔 Device: $_deviceModel');
      safePrint('🆔 First Launch: $_isFirstLaunch');
      
      notifyListeners();
      
      return _userId!;
      
    } catch (e, stackTrace) {
      safePrint('🆔 ❌ Failed to initialize Device Identity Manager: $e');
      safePrint('Stack trace: $stackTrace');
      
      // Generate fallback IDs
      _userId = await _generateFallbackUserId();
      _sessionId = _generateSessionId();
      _isInitialized = true;
      
      return _userId!;
    }
  }

  /// Initialize user ID (load existing or generate new)
  Future<void> _initializeUserId() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if user ID already exists
    _userId = prefs.getString(_keyUserId);
    
    if (_userId == null || _userId!.isEmpty) {
      // First launch - generate new user ID
      _isFirstLaunch = true;
      _userId = await _generateUserId();
      await prefs.setString(_keyUserId, _userId!);
      
      // Store install date
      _installDate = DateTime.now();
      await prefs.setInt(_keyInstallDate, _installDate!.millisecondsSinceEpoch);
      
      safePrint('🆔 Generated new user ID (first launch)');
    } else {
      // Existing user
      _isFirstLaunch = false;
      
      // Load install date
      final installMs = prefs.getInt(_keyInstallDate) ?? DateTime.now().millisecondsSinceEpoch;
      _installDate = DateTime.fromMillisecondsSinceEpoch(installMs);
      
      safePrint('🆔 Loaded existing user ID');
    }
  }

  /// Generate new session ID for this app launch
  Future<void> _initializeSessionId() async {
    _sessionId = _generateSessionId();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySessionId, _sessionId!);
    
    safePrint('🆔 Generated new session ID');
  }

  /// Update session tracking dates
  Future<void> _updateSessionDates() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    
    // Load last session date
    final lastSessionMs = prefs.getInt(_keyLastSessionDate);
    if (lastSessionMs != null) {
      _lastSessionDate = DateTime.fromMillisecondsSinceEpoch(lastSessionMs);
    }
    
    // Update last session date to now
    await prefs.setInt(_keyLastSessionDate, now.millisecondsSinceEpoch);
  }

  /// Generate a unique user ID
  /// 
  /// Format: user_[deviceId]_[timestamp]
  /// 
  /// Priority:
  /// 1. Real device ID (Android ID / iOS IDFV)
  /// 2. Fallback to UUID v4
  Future<String> _generateUserId() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      String deviceId = '';

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id; // Android ID (unique per device+app)
        safePrint('🆔 Using Android ID for user identification');
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? ''; // IDFV (unique per vendor)
        safePrint('🆔 Using iOS IDFV for user identification');
      }

      // Fallback to UUID if device ID not available
      if (deviceId.isEmpty) {
        deviceId = const Uuid().v4();
        safePrint('🆔 ⚠️ Device ID unavailable, using UUID fallback');
      }

      // Format: user_[deviceId]_[timestamp]
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return 'user_${deviceId}_$timestamp';
      
    } catch (e) {
      safePrint('🆔 ❌ Failed to generate user ID: $e');
      return await _generateFallbackUserId();
    }
  }

  /// Generate fallback user ID (pure UUID-based)
  Future<String> _generateFallbackUserId() async {
    final uuid = const Uuid().v4();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'user_${uuid}_$timestamp';
  }

  /// Generate session ID
  /// 
  /// Format: session_[uuid]
  String _generateSessionId() {
    final uuid = const Uuid().v4();
    return 'session_$uuid';
  }

  /// Collect device information for analytics
  Future<void> _collectDeviceInfo() async {
    try {
      // Platform
      _platform = Platform.operatingSystem; // 'android' | 'ios'
      
      // Device info
      final deviceInfo = DeviceInfoPlugin();
      
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        _deviceModel = '${androidInfo.manufacturer} ${androidInfo.model}';
        _osVersion = 'Android ${androidInfo.version.release}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        _deviceModel = iosInfo.model;
        _osVersion = '${iosInfo.systemName} ${iosInfo.systemVersion}';
      }
      
      // App version
      final packageInfo = await PackageInfo.fromPlatform();
      _appVersion = packageInfo.version;
      
      safePrint('🆔 Device info collected: $_deviceModel, $_osVersion, $_appVersion');
      
    } catch (e) {
      safePrint('🆔 ⚠️ Failed to collect device info: $e');
      _deviceModel = 'unknown';
      _osVersion = 'unknown';
      _appVersion = '0.0.0';
    }
  }

  /// Get days since install
  int get daysSinceInstall {
    if (_installDate == null) return 0;
    return DateTime.now().difference(_installDate!).inDays;
  }

  /// Get days since last session
  int get daysSinceLastSession {
    if (_lastSessionDate == null) return 0;
    return DateTime.now().difference(_lastSessionDate!).inDays;
  }

  /// Reset identity (for testing/debugging only)
  /// 
  /// WARNING: This will generate a new user ID, effectively creating a new user
  Future<void> resetIdentity() async {
    if (!kDebugMode) {
      safePrint('🆔 ⚠️ Identity reset only allowed in debug mode');
      return;
    }
    
    safePrint('🆔 ⚠️ Resetting identity...');
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keySessionId);
    await prefs.remove(_keyInstallDate);
    await prefs.remove(_keyLastSessionDate);
    
    _userId = null;
    _sessionId = null;
    _installDate = null;
    _lastSessionDate = null;
    _isInitialized = false;
    _isFirstLaunch = false;
    
    safePrint('🆔 ✅ Identity reset complete');
    
    // Re-initialize
    await initialize();
  }

  /// Get device metadata for events
  Map<String, dynamic> getDeviceMetadata() {
    return {
      'platform': _platform ?? 'unknown',
      'deviceModel': _deviceModel ?? 'unknown',
      'osVersion': _osVersion ?? 'unknown',
      'appVersion': _appVersion ?? '0.0.0',
      'nickname': _nickname, // ✅ NEW: Include nickname in metadata
    };
  }

  /// Get session metadata for events
  Map<String, dynamic> getSessionMetadata() {
    return {
      'daysSinceInstall': daysSinceInstall,
      'daysSinceLastSession': daysSinceLastSession,
      'isFirstLaunch': _isFirstLaunch,
    };
  }

  // ============================================================================
  // ✅ NEW: Nickname Management
  // ============================================================================

  /// Load nickname from storage
  Future<void> _loadNickname() async {
    final prefs = await SharedPreferences.getInstance();
    _nickname = prefs.getString(_keyNickname) ?? 'Pilot';
    safePrint('🆔 Loaded nickname: $_nickname');
  }

  /// Set player nickname
  /// 
  /// This updates the nickname for all future events
  Future<void> setNickname(String newNickname) async {
    if (newNickname.isEmpty || newNickname.length > 50) {
      safePrint('🆔 ⚠️ Invalid nickname length (must be 1-50 characters)');
      return;
    }

    _nickname = newNickname.trim();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyNickname, _nickname);
    
    safePrint('🆔 ✅ Nickname updated: $_nickname');
    notifyListeners();
  }
}

