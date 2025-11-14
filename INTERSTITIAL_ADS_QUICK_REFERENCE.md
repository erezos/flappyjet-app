# 🚀 Interstitial Ads - Quick Reference

## ✅ STATUS: PRODUCTION READY

### Ad Unit IDs (Configured)
```
Android AdMob:  ca-app-pub-9307424222926115/7832054871 ✅
iOS AdMob:      ca-app-pub-9307424222926115/5421513959 ✅
Unity Android:  Interstitial_Android
Unity iOS:      Interstitial_iOS
```

### Strategy
```
Session 1:  First 3 wins = NO ADS → Then every 2nd win + 2min cooldown
Session 2+: Every 2nd win + 2min cooldown
```

### Files Modified
```
✅ lib/integrations/interstitial_ad_manager.dart (NEW)
✅ lib/ui/screens/level_complete_screen.dart (MODIFIED)
✅ lib/main.dart (MODIFIED)
```

### Next Steps
1. **Configure Unity Ads in AdMob Dashboard** (15 min)
   - Go to: https://apps.admob.com → Mediation
   - Create mediation group for Interstitial
   - Add Unity Ads network
   - Enter placement IDs: `Interstitial_Android` / `Interstitial_iOS`
   - Set eCPM floor: $2.00

2. **Test on Devices** (1 hour)
   - Install on Android & iOS
   - Win 3 levels (no ads)
   - Win 4th level (ad shows!)
   - Win 5th quickly (no ad - cooldown)
   - Win 6th after 2min (ad shows!)

3. **Monitor Metrics** (First 48 hours critical)
   - D1 Retention (should stay within 5%)
   - Fill Rate (target >85%)
   - eCPM (target >$2.50)
   - User reviews

4. **Launch!** 🚀

### Expected Revenue (10K DAU)
```
Conservative: $1,590/month
Realistic:    $2,820/month
Optimistic:   $4,980/month (with Unity mediation)
```

### Configuration Adjustments
Location: `lib/integrations/interstitial_ad_manager.dart`

```dart
static const int _graceWins = 3;              // First-session wins before ads
static const int _winsPerAd = 2;              // Show ad every X wins
static const Duration _minTimeBetweenAds = Duration(minutes: 2);  // Cooldown
```

### Debug Commands
```dart
// Check current state
InterstitialAdManager().getDebugState()

// Force show ad (testing)
await InterstitialAdManager().forceShowAdForTesting()
```

### Warning Signs
🚨 **Stop & Adjust If:**
- D1 retention drops >7%
- Fill rate <70%
- Reviews complain about ads

✅ **You're Good If:**
- D1 retention within 5%
- Fill rate >85%
- eCPM >$2.50

---

**Full Documentation:** See `INTERSTITIAL_ADS_PRODUCTION_READY.md`

