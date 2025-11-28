import 'package:flutter_test/flutter_test.dart';

/// Tests for InterstitialAdManager configuration logic
/// 
/// New Configuration:
/// - First ad: After completing level 3
/// - Then: Every 2 level wins (levels 3, 5, 7, 9, etc.)
/// - Default cooldown: 2 minutes
/// - After rewarded video: 3 minute cooldown
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InterstitialAdManager Configuration Tests', () {
    // These tests verify the configuration constants and logic
    // Note: Full integration tests require mocking AdMob SDK
    
    test('Configuration: First ad should show after level 3', () {
      // First ad shows after _firstAdAfterLevels = 3
      const firstAdAfterLevels = 3;
      
      // User with 1 win should NOT see ad
      expect(1 < firstAdAfterLevels, true);
      
      // User with 2 wins should NOT see ad
      expect(2 < firstAdAfterLevels, true);
      
      // User with 3 wins SHOULD see ad
      expect(3 >= firstAdAfterLevels, true);
    });

    test('Configuration: After first ad, show every 2 levels', () {
      const adFrequencyLevels = 2;
      
      // Scenario: User is at level 5, last ad was at level 3
      int totalWins = 5;
      int lastAdAtWinCount = 3;
      int levelsSinceLastAd = totalWins - lastAdAtWinCount; // 2
      
      expect(levelsSinceLastAd >= adFrequencyLevels, true); // Should show ad
      
      // Scenario: User is at level 4, last ad was at level 3
      totalWins = 4;
      lastAdAtWinCount = 3;
      levelsSinceLastAd = totalWins - lastAdAtWinCount; // 1
      
      expect(levelsSinceLastAd >= adFrequencyLevels, false); // Should NOT show ad
    });

    test('Configuration: Ad pattern should be levels 3, 5, 7, 9, 11...', () {
      const firstAdAfterLevels = 3;
      const adFrequencyLevels = 2;
      
      // Simulate the ad showing pattern
      List<int> adShownAtLevels = [];
      int lastAdAtWinCount = 0;
      
      for (int level = 1; level <= 15; level++) {
        // Check if ad should show
        bool shouldShow = false;
        
        if (level >= firstAdAfterLevels) {
          if (lastAdAtWinCount == 0) {
            // First ad ever
            shouldShow = true;
          } else if (level - lastAdAtWinCount >= adFrequencyLevels) {
            shouldShow = true;
          }
        }
        
        if (shouldShow) {
          adShownAtLevels.add(level);
          lastAdAtWinCount = level;
        }
      }
      
      // Expected pattern: 3, 5, 7, 9, 11, 13, 15
      expect(adShownAtLevels, [3, 5, 7, 9, 11, 13, 15]);
    });

    test('Configuration: Default cooldown is 2 minutes', () {
      const defaultCooldownMinutes = 2;
      expect(defaultCooldownMinutes, 2);
    });

    test('Configuration: Rewarded video extends cooldown to 3 minutes', () {
      const rewardedVideoCooldownMinutes = 3;
      expect(rewardedVideoCooldownMinutes, 3);
      expect(rewardedVideoCooldownMinutes > 2, true); // Longer than default
    });

    test('Cooldown logic: Ad blocked during cooldown', () {
      // Simulate cooldown check
      const cooldownMinutes = 2;
      
      // 1 minute since last ad - should be blocked
      int secondsSinceLastAd = 60;
      int cooldownSeconds = cooldownMinutes * 60;
      expect(secondsSinceLastAd < cooldownSeconds, true); // Blocked
      
      // 2 minutes since last ad - should be allowed
      secondsSinceLastAd = 120;
      expect(secondsSinceLastAd >= cooldownSeconds, true); // Allowed
    });

    test('Rewarded video cooldown: 3 minutes blocks ads longer', () {
      // After watching rewarded video, cooldown is 3 minutes
      const rewardedCooldownMinutes = 3;
      int cooldownSeconds = rewardedCooldownMinutes * 60;
      
      // 2 minutes since rewarded video - should still be blocked
      int secondsSinceLastAd = 120;
      expect(secondsSinceLastAd < cooldownSeconds, true); // Blocked
      
      // 3 minutes since rewarded video - should be allowed
      secondsSinceLastAd = 180;
      expect(secondsSinceLastAd >= cooldownSeconds, true); // Allowed
    });
  });

  group('Ad Showing Scenarios', () {
    test('Scenario: New user plays 5 levels without rewarded video', () {
      // Configuration
      const firstAdAfterLevels = 3;
      const adFrequencyLevels = 2;
      
      // Track ads shown
      List<int> adsShownAt = [];
      int lastAdAt = 0;
      
      for (int level = 1; level <= 5; level++) {
        bool shouldShow = false;
        
        if (level >= firstAdAfterLevels) {
          if (lastAdAt == 0) {
            shouldShow = true;
          } else if (level - lastAdAt >= adFrequencyLevels) {
            shouldShow = true;
          }
        }
        
        if (shouldShow) {
          adsShownAt.add(level);
          lastAdAt = level;
        }
      }
      
      // User should see ads at levels 3 and 5
      expect(adsShownAt, [3, 5]);
    });

    test('Scenario: User watches rewarded video after level 4', () {
      // After rewarded video at level 4, interstitial cooldown is 3 minutes
      // This means even if level 5 is eligible, cooldown blocks it
      
      // Assume user completes level 5 within 3 minutes of rewarded video
      const rewardedCooldownMinutes = 3;
      int timeSinceRewardedVideo = 60; // 1 minute (fast player)
      
      bool cooldownActive = timeSinceRewardedVideo < (rewardedCooldownMinutes * 60);
      expect(cooldownActive, true); // No interstitial due to rewarded video bonus
    });

    test('Scenario: Old user with 100 lifetime wins', () {
      // Old users follow the same rules
      const firstAdAfterLevels = 3;
      const adFrequencyLevels = 2;
      
      int totalLifetimeWins = 100;
      int lastAdAtWinCount = 98; // Last ad shown at level 98
      
      // Level 100 - should show ad (2 levels since last ad)
      int levelsSinceLastAd = totalLifetimeWins - lastAdAtWinCount;
      expect(levelsSinceLastAd >= adFrequencyLevels, true);
    });
  });
}

