/// 🎯 Campaign Attribution Manager
/// 
/// Captures and stores campaign attribution data from Firebase first_open event
/// and enriches all events with campaign_id for ROI analysis.
/// 
/// Follows Flame game engine best practices:
/// - Non-blocking initialization
/// - Fire-and-forget event tracking
/// - Offline-first design
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:play_install_referrer/play_install_referrer.dart';
import '../../../core/debug_logger.dart';
import '../events/event_bus.dart';
import '../identity/device_identity_manager.dart';

/// Campaign attribution data model
class CampaignData {
  final String? source; // e.g., "google"
  final String? medium; // e.g., "cpc"
  final String? campaign; // e.g., "summer_sale_2025"
  final String? campaignId; // Google Ads campaign ID
  final String? adGroup;
  final String? adGroupId;
  final String? keyword;
  final String? gclid; // Google Click ID
  final String? creative;
  final DateTime? installDate;

  CampaignData({
    this.source,
    this.medium,
    this.campaign,
    this.campaignId,
    this.adGroup,
    this.adGroupId,
    this.keyword,
    this.gclid,
    this.creative,
    this.installDate,
  });

  bool get hasCampaignData => campaignId != null || source != null;

  Map<String, dynamic> toJson() {
    return {
      if (source != null) 'source': source,
      if (medium != null) 'medium': medium,
      if (campaign != null) 'campaign': campaign,
      if (campaignId != null) 'campaign_id': campaignId,
      if (adGroup != null) 'ad_group': adGroup,
      if (adGroupId != null) 'ad_group_id': adGroupId,
      if (keyword != null) 'keyword': keyword,
      if (gclid != null) 'gclid': gclid,
      if (creative != null) 'creative': creative,
      if (installDate != null) 'install_date': installDate!.toIso8601String(),
    };
  }

  factory CampaignData.fromJson(Map<String, dynamic> json) {
    return CampaignData(
      source: json['source'] as String?,
      medium: json['medium'] as String?,
      campaign: json['campaign'] as String?,
      campaignId: json['campaign_id'] as String?,
      adGroup: json['ad_group'] as String?,
      adGroupId: json['ad_group_id'] as String?,
      keyword: json['keyword'] as String?,
      gclid: json['gclid'] as String?,
      creative: json['creative'] as String?,
      installDate: json['install_date'] != null
          ? DateTime.parse(json['install_date'] as String)
          : null,
    );
  }
}

/// Campaign Attribution Manager
/// 
/// Manages campaign attribution data from Firebase first_open event
/// and provides campaign_id for event enrichment.
class CampaignAttributionManager {
  static final CampaignAttributionManager _instance =
      CampaignAttributionManager._internal();
  factory CampaignAttributionManager() => _instance;
  CampaignAttributionManager._internal();

  static const String _keyCampaignData = 'campaign_attribution_data';
  static const String _keyUserAcquiredFired = 'user_acquired_event_fired';

  CampaignData? _campaignData;
  bool _isInitialized = false;
  bool _userAcquiredFired = false;

  /// Get current campaign data
  CampaignData? get campaignData => _campaignData;
  String? get campaignId => _campaignData?.campaignId;
  bool get isInitialized => _isInitialized;
  bool get hasCampaignData => _campaignData?.hasCampaignData ?? false;

  /// Initialize campaign attribution manager
  /// 
  /// Should be called during app initialization (non-blocking)
  Future<void> initialize(FirebaseAnalytics analytics) async {
    if (_isInitialized) return;

    try {
      safePrint('🎯 Initializing Campaign Attribution Manager...');

      // Load saved campaign data
      await _loadCampaignData();

      // Check if user_acquired event was already fired
      await _loadUserAcquiredFlag();

      // Set up Firebase first_open listener
      await _setupFirstOpenListener(analytics);

      _isInitialized = true;
      safePrint('🎯 ✅ Campaign Attribution Manager initialized');
      if (_campaignData != null) {
        safePrint('🎯 Campaign ID: ${_campaignData!.campaignId ?? 'none'}');
      }
    } catch (e) {
      safePrint('🎯 ❌ Campaign Attribution Manager initialization failed: $e');
      // Don't block app initialization - attribution is non-critical
    }
  }

  /// Load saved campaign data from SharedPreferences
  Future<void> _loadCampaignData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyCampaignData);
      if (jsonString != null) {
        final json = Map<String, dynamic>.from(jsonDecode(jsonString));
        _campaignData = CampaignData.fromJson(json);
        safePrint('🎯 Loaded campaign data: ${_campaignData!.campaignId ?? 'none'}');
      }
    } catch (e) {
      safePrint('🎯 Failed to load campaign data: $e');
    }
  }

  /// Load user_acquired event flag
  Future<void> _loadUserAcquiredFlag() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _userAcquiredFired = prefs.getBool(_keyUserAcquiredFired) ?? false;
    } catch (e) {
      safePrint('🎯 Failed to load user_acquired flag: $e');
    }
  }

  /// Set up Firebase first_open event listener
  /// 
  /// Note: Firebase Analytics doesn't expose first_open parameters directly in Flutter.
  /// Campaign data can come from:
  /// 1. Firebase Dynamic Links / App Links (deep links with campaign params)
  /// 2. Install referrer (Android) / App Store Connect (iOS)
  /// 3. Firebase Analytics API (requires backend integration)
  /// 
  /// For now, we'll capture campaign data from:
  /// - Deep links (if implemented)
  /// - Install referrer (Android)
  /// - Manual capture via captureCampaignData()
  Future<void> _setupFirstOpenListener(FirebaseAnalytics analytics) async {
    try {
      // TODO: Implement deep link handling for campaign parameters
      // TODO: Implement install referrer reading (Android)
      // TODO: Implement Firebase Analytics API integration (backend)
      
      safePrint('🎯 Campaign attribution ready (will capture from deep links/referrer)');
      
      // If this is first launch and we don't have campaign data yet,
      // try to get it from install referrer (Android) or mark as organic
      if (!_userAcquiredFired && _campaignData == null) {
        // Will be handled by checkAndCaptureFirstOpen()
      }
    } catch (e) {
      safePrint('🎯 Failed to setup first_open listener: $e');
    }
  }

  /// Capture campaign data from Firebase first_open event
  /// 
  /// This should be called when Firebase first_open event is detected
  /// or when app is launched for the first time.
  Future<void> captureCampaignData(Map<String, dynamic>? parameters) async {
    if (parameters == null || parameters.isEmpty) {
      safePrint('🎯 No campaign parameters in first_open event');
      return;
    }

    try {
      // Extract campaign parameters from Firebase first_open event
      final campaignData = CampaignData(
        source: parameters['source'] as String?,
        medium: parameters['medium'] as String?,
        campaign: parameters['campaign'] as String?,
        campaignId: parameters['campaign_id'] as String? ??
            parameters['gclid']?.toString().substring(0, 10), // Fallback to gclid prefix
        adGroup: parameters['ad_group'] as String?,
        adGroupId: parameters['ad_group_id'] as String?,
        keyword: parameters['keyword'] as String?,
        gclid: parameters['gclid'] as String?,
        creative: parameters['creative'] as String?,
        installDate: DateTime.now(),
      );

      // Only save if we have meaningful campaign data
      if (campaignData.hasCampaignData) {
        _campaignData = campaignData;
        await _saveCampaignData(campaignData);
        safePrint('🎯 ✅ Campaign data captured: ${campaignData.campaignId ?? campaignData.source}');

        // Fire user_acquired event if not already fired
        if (!_userAcquiredFired) {
          await _fireUserAcquiredEvent(campaignData);
        }
      } else {
        safePrint('🎯 No campaign data found (organic install)');
      }
    } catch (e) {
      safePrint('🎯 Failed to capture campaign data: $e');
    }
  }

  /// Save campaign data to SharedPreferences
  Future<void> _saveCampaignData(CampaignData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(data.toJson());
      await prefs.setString(_keyCampaignData, jsonString);
    } catch (e) {
      safePrint('🎯 Failed to save campaign data: $e');
    }
  }

  /// Fire user_acquired event to EventBus
  /// 
  /// This event is fired once per user on first install with campaign data.
  Future<void> _fireUserAcquiredEvent(CampaignData campaignData) async {
    if (_userAcquiredFired) {
      safePrint('🎯 user_acquired event already fired, skipping');
      return;
    }

    try {
      // Get user ID and platform from DeviceIdentityManager
      final identityManager = DeviceIdentityManager();
      final userId = identityManager.userId;
      final platform = identityManager.platform;
      final installDate = campaignData.installDate ?? identityManager.installDate ?? DateTime.now();
      
      final eventData = {
        ...campaignData.toJson(),
        'user_id': userId,
        'platform': platform,
        'install_date': installDate.toIso8601String(),
      };

      // Fire user_acquired event
      EventBus().fire('user_acquired', eventData);

      // Mark as fired
      _userAcquiredFired = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyUserAcquiredFired, true);

      safePrint('🎯 ✅ user_acquired event fired with campaign data');
    } catch (e) {
      safePrint('🎯 Failed to fire user_acquired event: $e');
    }
  }

  /// Get campaign_id for event enrichment
  /// 
  /// Returns campaign_id if available, null otherwise.
  String? getCampaignId() {
    return _campaignData?.campaignId;
  }

  /// Check if this is a first install (for capturing first_open)
  /// 
  /// This should be called on app launch to detect first install.
  /// If no campaign data is found, marks as organic install.
  Future<bool> checkAndCaptureFirstOpen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasLaunchedBefore = prefs.getBool('has_launched_before') ?? false;

      if (!hasLaunchedBefore) {
        // First launch - mark as launched
        await prefs.setBool('has_launched_before', true);

        // ✅ NEW: Try to get campaign data from Android Install Referrer first
        if (_campaignData == null && Platform.isAndroid) {
          safePrint('🎯 Attempting to read Android Install Referrer...');
          final referrerData = await _readAndroidInstallReferrer();
          if (referrerData != null && referrerData.hasCampaignData) {
            _campaignData = referrerData;
            await _saveCampaignData(referrerData);
            safePrint('🎯 ✅ Campaign data captured from Install Referrer: ${referrerData.campaignId ?? referrerData.source}');
          }
        }

        // If we still don't have campaign data, mark as organic
        // Campaign data will be captured from:
        // 1. Android Install Referrer (✅ IMPLEMENTED)
        // 2. Deep links (if user came from a link)
        // 3. Firebase Analytics API (backend integration - future)
        if (_campaignData == null) {
          // Mark as organic install
          // ✅ FIXED: Set campaign_id to 'organic' so backend can identify organic installs
          final organicData = CampaignData(
            source: 'organic',
            medium: 'organic',
            campaignId: 'organic', // ✅ FIXED: Set campaign_id for organic installs
            installDate: DateTime.now(),
          );
          await captureCampaignData(organicData.toJson());
          safePrint('🎯 First launch - marked as organic install');
        } else {
          safePrint('🎯 First launch - campaign data already captured');
        }

        // Fire user_acquired event if not already fired
        if (!_userAcquiredFired && _campaignData != null) {
          await _fireUserAcquiredEvent(_campaignData!);
        }

        return true;
      }

      return false;
    } catch (e) {
      safePrint('🎯 Failed to check first open: $e');
      return false;
    }
  }

  /// Read Android Install Referrer to get campaign attribution data
  /// 
  /// ✅ NEW: Implements Android Install Referrer API to capture campaign data
  /// This provides accurate campaign attribution for Google Ads installs
  /// 
  /// Returns CampaignData if referrer data is found, null otherwise.
  /// Follows Flame game engine best practices: non-blocking, error-handled
  Future<CampaignData?> _readAndroidInstallReferrer() async {
    // Only works on Android
    if (!Platform.isAndroid) {
      safePrint('🎯 Install Referrer: Not Android platform, skipping');
      return null;
    }

    try {
      safePrint('🎯 Reading Android Install Referrer...');
      
      // Get install referrer details using static method
      // ✅ FIXED: Use correct API - PlayInstallReferrer.installReferrer is a static getter
      final referrerDetails = await PlayInstallReferrer.installReferrer;
      
      final referrerUrl = referrerDetails.installReferrer;
      if (referrerUrl == null || referrerUrl.isEmpty) {
        safePrint('🎯 Install Referrer: Empty referrer URL');
        return null;
      }

      safePrint('🎯 Install Referrer URL: $referrerUrl');

      // Parse referrer URL to extract campaign parameters
      // Format: utm_source=google&utm_medium=cpc&utm_campaign=summer_sale&gclid=...
      final campaignData = _parseReferrerUrl(referrerUrl);
      
      if (campaignData != null && campaignData.hasCampaignData) {
        safePrint('🎯 ✅ Install Referrer: Campaign data extracted - ${campaignData.campaignId ?? campaignData.source}');
        return campaignData;
      } else {
        safePrint('🎯 Install Referrer: No valid campaign data in referrer URL');
        return null;
      }
    } on PlatformException catch (e) {
      // ✅ ERROR HANDLING: Platform-specific errors (e.g., iOS, Google Play Services unavailable)
      if (e.code == 'UNAVAILABLE' || e.message?.contains('iOS') == true) {
        safePrint('🎯 Install Referrer: Not available on this platform');
      } else {
        safePrint('🎯 ⚠️ Install Referrer error: ${e.code} - ${e.message}');
      }
      return null;
    } catch (e) {
      // ✅ ERROR HANDLING: Don't fail silently, but don't block app initialization
      safePrint('🎯 ⚠️ Failed to read Install Referrer (non-critical): $e');
      return null;
    }
  }

  /// Parse referrer URL to extract campaign parameters
  /// 
  /// Handles UTM parameters and Google Ads parameters (gclid, etc.)
  /// Returns CampaignData with extracted parameters
  CampaignData? _parseReferrerUrl(String referrerUrl) {
    try {
      // Parse URL parameters
      final uri = Uri.parse('?$referrerUrl'); // Add ? prefix for proper parsing
      final params = uri.queryParameters;

      // Extract UTM parameters
      final source = params['utm_source'] ?? params['source'];
      final medium = params['utm_medium'] ?? params['medium'];
      final campaign = params['utm_campaign'] ?? params['campaign'];
      final term = params['utm_term'] ?? params['term'];
      final content = params['utm_content'] ?? params['content'];

      // Extract Google Ads parameters
      final gclid = params['gclid'];
      final campaignId = params['campaign_id'] ?? 
                        params['campaignid'] ?? 
                        (gclid != null ? 'gclid_${gclid.substring(0, 10)}' : null);
      
      // Extract ad group and keyword
      final adGroup = params['ad_group'] ?? params['adgroup'];
      final adGroupId = params['ad_group_id'] ?? params['adgroupid'];
      final keyword = params['keyword'] ?? term;

      // Only create CampaignData if we have meaningful data
      if (source != null || medium != null || campaign != null || gclid != null) {
        return CampaignData(
          source: source ?? 'google', // Default to 'google' if gclid present
          medium: medium ?? 'cpc', // Default to 'cpc' if gclid present
          campaign: campaign,
          campaignId: campaignId,
          adGroup: adGroup,
          adGroupId: adGroupId,
          keyword: keyword,
          gclid: gclid,
          creative: content,
          installDate: DateTime.now(),
        );
      }

      return null;
    } catch (e) {
      safePrint('🎯 ⚠️ Failed to parse referrer URL: $e');
      return null;
    }
  }

  /// Manually capture campaign data (for deep links, install referrer, etc.)
  /// 
  /// This can be called from:
  /// - Deep link handler (when user opens app from campaign link)
  /// - Install referrer reader (Android) - ✅ IMPLEMENTED
  /// - Firebase Analytics API integration (backend)
  Future<void> captureCampaignDataFromSource({
    String? source,
    String? medium,
    String? campaign,
    String? campaignId,
    String? adGroup,
    String? adGroupId,
    String? keyword,
    String? gclid,
    String? creative,
  }) async {
    final campaignData = CampaignData(
      source: source,
      medium: medium,
      campaign: campaign,
      campaignId: campaignId,
      adGroup: adGroup,
      adGroupId: adGroupId,
      keyword: keyword,
      gclid: gclid,
      creative: creative,
      installDate: DateTime.now(),
    );

    await captureCampaignData(campaignData.toJson());
  }
}

