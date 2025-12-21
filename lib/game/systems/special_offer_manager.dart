/// 🎁 SPECIAL OFFER MANAGER
/// 
/// Manages special offers that can be shown anywhere in the app
/// Handles offer tracking, cooldowns, and context-based triggering
library;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/debug_logger.dart';
import '../core/special_offer_config.dart';

/// Manages special offers and their display logic
class SpecialOfferManager extends ChangeNotifier {
  static final SpecialOfferManager _instance = SpecialOfferManager._internal();
  factory SpecialOfferManager() => _instance;
  SpecialOfferManager._internal();

  // Storage keys
  static const String _prefShowCountPrefix = 'special_offer_show_count_';
  static const String _prefLastDismissPrefix = 'special_offer_last_dismiss_';
  static const String _prefCooldownPeriodKey = 'special_offer_cooldown_minutes';

  // Active offers (can be loaded from Remote Config)
  List<SpecialOffer> _activeOffers = DefaultSpecialOffers.all;
  
  // Session tracking
  final Map<String, int> _sessionShowCount = {};
  final Map<String, DateTime> _lastDismissTime = {};
  
  // Configuration
  int _cooldownMinutes = 30; // Default 30 minutes cooldown

  /// Get all active offers
  List<SpecialOffer> get activeOffers => List.unmodifiable(_activeOffers);

  /// Initialize from shared preferences
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _cooldownMinutes = prefs.getInt(_prefCooldownPeriodKey) ?? 30;
      
      safePrint('🎁 Special Offer Manager initialized with ${_activeOffers.length} offers');
      notifyListeners();
    } catch (e) {
      safePrint('🎁 ⚠️ Error initializing Special Offer Manager: $e');
    }
  }

  /// Update active offers (e.g., from Remote Config)
  void updateOffers(List<SpecialOffer> offers) {
    _activeOffers = offers;
    safePrint('🎁 Updated offers: ${offers.length} active');
    notifyListeners();
  }

  /// Get offers that should be shown for a given context
  List<SpecialOffer> getOffersForContext(String context) {
    final validOffers = _activeOffers
        .where((offer) => offer.isValid)
        .where((offer) => offer.shouldShowForContext(context))
        .where((offer) => _canShowOffer(offer))
        .toList();

    // Sort by priority (higher first)
    validOffers.sort((a, b) => (b.priority ?? 0).compareTo(a.priority ?? 0));

    return validOffers;
  }

  /// Check if an offer can be shown (respects cooldown, max show count, etc.)
  bool _canShowOffer(SpecialOffer offer) {
    // Check max show count
    if (offer.maxShowCount != null) {
      final showCount = _getShowCount(offer.id);
      if (showCount >= offer.maxShowCount!) {
        return false;
      }
    }

    // Check cooldown
    final lastDismiss = _getLastDismissTime(offer.id);
    if (lastDismiss != null) {
      final cooldownEnd = lastDismiss.add(Duration(minutes: _cooldownMinutes));
      if (DateTime.now().isBefore(cooldownEnd)) {
        return false;
      }
    }

    // Check session show count (prevent spam)
    final sessionCount = _sessionShowCount[offer.id] ?? 0;
    if (sessionCount >= 2) {
      return false; // Max 2 times per session
    }

    return true;
  }

  /// Record that an offer was shown
  Future<void> recordOfferShown(String offerId) async {
    _sessionShowCount[offerId] = (_sessionShowCount[offerId] ?? 0) + 1;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentCount = prefs.getInt('$_prefShowCountPrefix$offerId') ?? 0;
      await prefs.setInt('$_prefShowCountPrefix$offerId', currentCount + 1);
    } catch (e) {
      safePrint('🎁 ⚠️ Error recording offer shown: $e');
    }
  }

  /// Record that an offer was dismissed
  Future<void> recordOfferDismissed(String offerId) async {
    _lastDismissTime[offerId] = DateTime.now();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        '$_prefLastDismissPrefix$offerId',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      safePrint('🎁 ⚠️ Error recording offer dismissed: $e');
    }
  }

  /// Get show count for an offer
  int _getShowCount(String offerId) {
    // This would typically load from SharedPreferences
    // For now, return session count
    return _sessionShowCount[offerId] ?? 0;
  }

  /// Get last dismiss time for an offer
  DateTime? _getLastDismissTime(String offerId) {
    return _lastDismissTime[offerId];
  }

  /// Reset session data (call on app start)
  void resetSession() {
    _sessionShowCount.clear();
  }

  /// Set cooldown period
  Future<void> setCooldownMinutes(int minutes) async {
    _cooldownMinutes = minutes;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefCooldownPeriodKey, minutes);
    } catch (e) {
      safePrint('🎁 ⚠️ Error setting cooldown: $e');
    }
  }
}

