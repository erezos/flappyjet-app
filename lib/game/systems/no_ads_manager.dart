/// 🚫 NO ADS MANAGER - Tracks No Ads purchase state
/// 
/// Manages lifetime and monthly No Ads subscriptions
/// Integrates with MonetizationManager and AdMobMediationService
library;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/debug_logger.dart';

/// Manages No Ads purchase state (lifetime and monthly subscriptions)
class NoAdsManager extends ChangeNotifier {
  static final NoAdsManager _instance = NoAdsManager._internal();
  factory NoAdsManager() => _instance;
  NoAdsManager._internal();

  static const String _prefLifetimePurchased = 'no_ads_lifetime_purchased';
  static const String _prefMonthlyExpiry = 'no_ads_monthly_expiry';
  static const String _prefMonthlyActive = 'no_ads_monthly_active';

  bool _lifetimePurchased = false;
  bool _monthlyActive = false;
  DateTime? _monthlyExpiry;

  /// Whether user has lifetime No Ads
  bool get hasLifetimeNoAds => _lifetimePurchased;

  /// Whether user has active monthly No Ads subscription
  bool get hasMonthlyNoAds => _monthlyActive && _isMonthlyValid();

  /// Whether user has any form of No Ads (lifetime or active monthly)
  bool get hasNoAds => _lifetimePurchased || (_monthlyActive && _isMonthlyValid());

  /// Check if monthly subscription is still valid
  bool _isMonthlyValid() {
    if (_monthlyExpiry == null) return false;
    return DateTime.now().isBefore(_monthlyExpiry!);
  }

  /// Initialize from shared preferences
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _lifetimePurchased = prefs.getBool(_prefLifetimePurchased) ?? false;
      _monthlyActive = prefs.getBool(_prefMonthlyActive) ?? false;
      
      final expiryTimestamp = prefs.getInt(_prefMonthlyExpiry);
      if (expiryTimestamp != null) {
        _monthlyExpiry = DateTime.fromMillisecondsSinceEpoch(expiryTimestamp);
      }

      // Check if monthly subscription has expired
      if (_monthlyActive && !_isMonthlyValid()) {
        _monthlyActive = false;
        await _saveState();
      }

      safePrint('🚫 No Ads Manager initialized - Lifetime: $_lifetimePurchased, Monthly: $_monthlyActive');
      notifyListeners();
    } catch (e) {
      safePrint('🚫 ⚠️ Error initializing No Ads Manager: $e');
    }
  }

  /// Activate lifetime No Ads
  Future<void> activateLifetime() async {
    if (_lifetimePurchased) {
      safePrint('🚫 Lifetime No Ads already active');
      return;
    }

    _lifetimePurchased = true;
    await _saveState();
    
    safePrint('🚫 ✅ Lifetime No Ads activated!');
    notifyListeners();
  }

  /// Activate monthly No Ads subscription
  Future<void> activateMonthly() async {
    // Calculate expiry (30 days from now)
    _monthlyExpiry = DateTime.now().add(const Duration(days: 30));
    _monthlyActive = true;
    await _saveState();
    
    safePrint('🚫 ✅ Monthly No Ads activated until ${_monthlyExpiry}');
    notifyListeners();
  }

  /// Renew monthly subscription (extend by 30 days)
  Future<void> renewMonthly() async {
    if (_monthlyExpiry == null) {
      // First time activation
      await activateMonthly();
      return;
    }

    // Extend from current expiry or now, whichever is later
    final baseDate = _monthlyExpiry!.isAfter(DateTime.now()) 
        ? _monthlyExpiry! 
        : DateTime.now();
    _monthlyExpiry = baseDate.add(const Duration(days: 30));
    _monthlyActive = true;
    await _saveState();
    
    safePrint('🚫 ✅ Monthly No Ads renewed until ${_monthlyExpiry}');
    notifyListeners();
  }

  /// Activate temporary No Ads (24 hours)
  Future<void> activate24Hours() async {
    // Extend from current expiry or now, whichever is later
    final baseDate = _monthlyExpiry?.isAfter(DateTime.now()) == true
        ? _monthlyExpiry!
        : DateTime.now();
    _monthlyExpiry = baseDate.add(const Duration(hours: 24));
    _monthlyActive = true;
    await _saveState();
    
    safePrint('🚫 ✅ 24 Hours No Ads activated until ${_monthlyExpiry}');
    notifyListeners();
  }

  /// Activate temporary No Ads (1 week)
  Future<void> activate1Week() async {
    // Extend from current expiry or now, whichever is later
    final baseDate = _monthlyExpiry?.isAfter(DateTime.now()) == true
        ? _monthlyExpiry!
        : DateTime.now();
    _monthlyExpiry = baseDate.add(const Duration(days: 7));
    _monthlyActive = true;
    await _saveState();
    
    safePrint('🚫 ✅ 1 Week No Ads activated until ${_monthlyExpiry}');
    notifyListeners();
  }

  /// Extend No Ads by a specific duration (for bundles)
  Future<void> extendNoAds(Duration duration) async {
    // Extend from current expiry or now, whichever is later
    final baseDate = _monthlyExpiry?.isAfter(DateTime.now()) == true
        ? _monthlyExpiry!
        : DateTime.now();
    _monthlyExpiry = baseDate.add(duration);
    _monthlyActive = true;
    await _saveState();
    
    safePrint('🚫 ✅ No Ads extended until ${_monthlyExpiry}');
    notifyListeners();
  }

  /// Save state to shared preferences
  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefLifetimePurchased, _lifetimePurchased);
      await prefs.setBool(_prefMonthlyActive, _monthlyActive);
      
      if (_monthlyExpiry != null) {
        await prefs.setInt(_prefMonthlyExpiry, _monthlyExpiry!.millisecondsSinceEpoch);
      } else {
        await prefs.remove(_prefMonthlyExpiry);
      }
    } catch (e) {
      safePrint('🚫 ⚠️ Error saving No Ads state: $e');
    }
  }

  /// Check and update monthly subscription status (call periodically)
  Future<void> checkMonthlyStatus() async {
    if (_monthlyActive && !_isMonthlyValid()) {
      _monthlyActive = false;
      await _saveState();
      safePrint('🚫 Monthly No Ads subscription expired');
      notifyListeners();
    }
  }

  /// Get status description for debugging
  String getStatusDescription() {
    if (_lifetimePurchased) {
      return 'Lifetime No Ads - Active';
    } else if (hasMonthlyNoAds) {
      final daysRemaining = _monthlyExpiry!.difference(DateTime.now()).inDays;
      return 'Monthly No Ads - $daysRemaining days remaining';
    } else {
      return 'No Ads - Not Active';
    }
  }
}

