/// 🧪 Tests for NoAdsManager - Ensures persistence works correctly
/// 
/// Tests cover:
/// - 24-hour No Ads activation and persistence
/// - App restart scenario (state restoration)
/// - Expiry validation
/// - Multiple activation scenarios
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flappy_jet_pro/game/systems/no_ads_manager.dart';

void main() {
  group('NoAdsManager Persistence Tests', () {
    late NoAdsManager noAdsManager;
    
    setUp(() async {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
      noAdsManager = NoAdsManager();
    });

    tearDown(() async {
      // Clean up after each test
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    });

    test('✅ 24-hour No Ads persists after app restart', () async {
      // Step 1: Activate 24-hour No Ads (simulating purchase)
      await noAdsManager.activate24Hours();
      
      // Verify it's active
      expect(noAdsManager.hasNoAds, true, reason: 'No Ads should be active immediately after activation');
      expect(noAdsManager.hasMonthlyNoAds, true, reason: '24-hour No Ads should be treated as monthly/temporary');
      
      // Step 2: Simulate app restart by creating a new instance
      // (In real app, this happens when app restarts and NoAdsManager singleton is recreated)
      final prefs = await SharedPreferences.getInstance();
      final savedExpiry = prefs.getInt('no_ads_monthly_expiry');
      final savedActive = prefs.getBool('no_ads_monthly_active');
      
      // Verify data was saved
      expect(savedExpiry, isNotNull, reason: 'Expiry timestamp should be saved');
      expect(savedActive, true, reason: 'Monthly active flag should be saved');
      
      // Step 3: Simulate app restart - create new manager and initialize
      final newManager = NoAdsManager();
      await newManager.initialize();
      
      // Step 4: Verify state was restored
      expect(newManager.hasNoAds, true, reason: 'No Ads should still be active after app restart');
      expect(newManager.hasMonthlyNoAds, true, reason: '24-hour No Ads should be restored after app restart');
      
      // Verify expiry is approximately 24 hours from now (within 1 second tolerance)
      final restoredExpiry = DateTime.fromMillisecondsSinceEpoch(savedExpiry!);
      final expectedExpiry = DateTime.now().add(const Duration(hours: 24));
      final difference = restoredExpiry.difference(expectedExpiry).abs();
      expect(difference.inSeconds, lessThan(2), reason: 'Expiry should be approximately 24 hours from now');
    });

    test('✅ No Ads persists even if _monthlyActive flag is missing (expiry-based restoration)', () async {
      // Simulate a scenario where expiry is saved but flag is missing (data corruption/old version)
      final prefs = await SharedPreferences.getInstance();
      final futureExpiry = DateTime.now().add(const Duration(hours: 24));
      await prefs.setInt('no_ads_monthly_expiry', futureExpiry.millisecondsSinceEpoch);
      // Intentionally NOT setting _monthlyActive flag
      
      // Initialize manager (should restore from expiry timestamp)
      await noAdsManager.initialize();
      
      // Should restore active state from expiry timestamp
      expect(noAdsManager.hasNoAds, true, reason: 'Should restore from expiry timestamp even if flag is missing');
      expect(noAdsManager.hasMonthlyNoAds, true, reason: 'Should restore monthly No Ads from expiry');
    });

    test('✅ Expired No Ads is cleared on app restart', () async {
      // Set an expired expiry timestamp
      final prefs = await SharedPreferences.getInstance();
      final pastExpiry = DateTime.now().subtract(const Duration(hours: 1));
      await prefs.setInt('no_ads_monthly_expiry', pastExpiry.millisecondsSinceEpoch);
      await prefs.setBool('no_ads_monthly_active', true);
      
      // Initialize manager (should detect and clear expired state)
      await noAdsManager.initialize();
      
      // Should detect expiry and clear the state
      expect(noAdsManager.hasNoAds, false, reason: 'Expired No Ads should be cleared');
      expect(noAdsManager.hasMonthlyNoAds, false, reason: 'Expired monthly No Ads should be cleared');
      
      // Verify state was cleaned up
      final savedExpiry = prefs.getInt('no_ads_monthly_expiry');
      final savedActive = prefs.getBool('no_ads_monthly_active');
      expect(savedExpiry, isNull, reason: 'Expired expiry should be removed');
      expect(savedActive, false, reason: 'Expired active flag should be cleared');
    });

    test('✅ Multiple 24-hour activations extend correctly', () async {
      // Activate first 24 hours
      await noAdsManager.activate24Hours();
      final firstExpiry = DateTime.now().add(const Duration(hours: 24));
      
      // Wait a bit (simulate time passing)
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Activate another 24 hours (should extend from current expiry)
      await noAdsManager.activate24Hours();
      
      // Should extend from the first expiry, not from now
      final prefs = await SharedPreferences.getInstance();
      final savedExpiry = prefs.getInt('no_ads_monthly_expiry');
      final restoredExpiry = DateTime.fromMillisecondsSinceEpoch(savedExpiry!);
      
      // Should be approximately 48 hours from first activation (24 + 24)
      final expectedExpiry = firstExpiry.add(const Duration(hours: 24));
      final difference = restoredExpiry.difference(expectedExpiry).abs();
      expect(difference.inSeconds, lessThan(2), reason: 'Second activation should extend from first expiry');
    });

    test('✅ Bosses Showdown purchase scenario (24h No Ads + app restart)', () async {
      // Simulate Bosses Showdown special offer purchase
      // This is what happens in starter_boss_pack_popup.dart
      
      // Step 1: Purchase activates 24-hour No Ads
      await noAdsManager.initialize(); // Initialize first (as done in purchase handler)
      await noAdsManager.activate24Hours();
      
      expect(noAdsManager.hasNoAds, true, reason: 'No Ads should be active after purchase');
      
      // Step 2: User closes app immediately
      // (State is saved via _saveState() in activate24Hours)
      
      // Step 3: User reopens app (simulated by new manager instance)
      final prefs = await SharedPreferences.getInstance();
      final savedExpiry = prefs.getInt('no_ads_monthly_expiry');
      expect(savedExpiry, isNotNull, reason: 'Expiry should be persisted');
      
      // Step 4: App restarts, NoAdsManager.initialize() is called (now in main.dart)
      final restartedManager = NoAdsManager();
      await restartedManager.initialize();
      
      // Step 5: Verify No Ads is still active
      expect(restartedManager.hasNoAds, true, reason: 'No Ads should persist after app restart');
      expect(restartedManager.hasMonthlyNoAds, true, reason: '24-hour No Ads should be restored');
      
      // Verify expiry is still valid (24 hours from activation)
      final restoredExpiry = DateTime.fromMillisecondsSinceEpoch(savedExpiry!);
      final now = DateTime.now();
      expect(restoredExpiry.isAfter(now), true, reason: 'Expiry should be in the future');
      
      final hoursRemaining = restoredExpiry.difference(now).inHours;
      expect(hoursRemaining, greaterThan(23), reason: 'Should have approximately 24 hours remaining');
      expect(hoursRemaining, lessThan(25), reason: 'Should not have more than 24 hours');
    });

    test('✅ Lifetime No Ads takes precedence over temporary', () async {
      // Activate 24-hour No Ads
      await noAdsManager.activate24Hours();
      expect(noAdsManager.hasNoAds, true);
      
      // Activate lifetime (should override)
      await noAdsManager.activateLifetime();
      expect(noAdsManager.hasLifetimeNoAds, true, reason: 'Lifetime should be active');
      expect(noAdsManager.hasNoAds, true, reason: 'No Ads should still be active (lifetime)');
      
      // Simulate app restart
      final restartedManager = NoAdsManager();
      await restartedManager.initialize();
      
      // Lifetime should persist
      expect(restartedManager.hasLifetimeNoAds, true, reason: 'Lifetime should persist after restart');
      expect(restartedManager.hasNoAds, true, reason: 'No Ads should be active (lifetime)');
    });

    test('✅ Invalid state (flag set but no expiry) is cleaned up', () async {
      // Simulate corrupted state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('no_ads_monthly_active', true);
      // Intentionally NOT setting expiry
      
      // Initialize should detect and clean up
      await noAdsManager.initialize();
      
      expect(noAdsManager.hasNoAds, false, reason: 'Invalid state should result in no ads');
      
      // Verify cleanup
      final savedActive = prefs.getBool('no_ads_monthly_active');
      expect(savedActive, false, reason: 'Invalid active flag should be cleared');
    });
  });
}

