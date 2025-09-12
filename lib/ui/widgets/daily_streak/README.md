# 🎯 Daily Streak Bonus System

A comprehensive daily streak reward system for FlappyJet with beautiful animations, smart reward logic, and seamless integration.

## ✨ Features

- **🎨 Beautiful UI**: Golden banner with rope details, animated jet, sparkles, and smooth transitions
- **🎁 Smart Rewards**: Different reward tracks for new vs experienced players
- **🚁 Jet Skin Rewards**: Flash Strike jet for new players on day 2
- **💎 Streak Recovery**: Restore broken streaks with gems
- **📱 Responsive Design**: Works perfectly on all screen sizes
- **⚡ Performance**: Sprite atlas system for smooth 60fps animations
- **📊 Analytics**: Full event tracking integration
- **💾 Smart Storage**: Local storage with cloud sync capability

## 🏗️ Architecture

### Core Components

1. **DailyStreakManager** - Core logic and data management
2. **DailyStreakAtlas** - Sprite sheet management
3. **DailyStreakPopup** - Main animated popup widget
4. **DailyStreakCollectButton** - Interactive collect/restore button
5. **DailyStreakIntegration** - Easy integration helper

### Reward System

#### New Players (1 skin owned)
- Day 1: 100 coins
- Day 2: **Flash Strike Jet** 🚁
- Day 3: 1-hour Heart Booster
- Day 4: 250 coins
- Day 5: 1 Heart
- Day 6: Mystery Box
- Day 7: 15 gems

#### Experienced Players (2+ skins)
- Day 1: 100 coins
- Day 2: 5 gems
- Day 3: 1-hour Heart Booster
- Day 4: 250 coins
- Day 5: 1 Heart
- Day 6: Mystery Box
- Day 7: 15 gems

## 🚀 Quick Integration

### 1. Initialize in main.dart
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize daily streak system
  await DailyStreakIntegration.initialize();
  
  runApp(MyApp());
}
```

### 2. Add to Homepage
```dart
// Option A: Full integration widget
DailyStreakHomepageIntegration()

// Option B: Simple FAB
DailyStreakFAB()

// Option C: Custom integration
if (DailyStreakIntegration.shouldShowPopup()) {
  DailyStreakIntegration.showDailyStreakPopup(context);
}
```

### 3. Show After Game (Optional)
```dart
// In game over screen or after good runs
if (score > 10 && DailyStreakIntegration.shouldShowPopup()) {
  await DailyStreakIntegration.showDailyStreakPopup(context);
}
```

## 🎨 Assets Required

Replace the placeholder `assets/images/ui/daily_streak_atlas.png` with your actual sprite sheet containing:

### Banner Elements
- `banner/base` - Golden banner (1536×256)
- `banner/shadow` - Drop shadow (1536×256)
- `banner/grommet_l/r` - Metal eyelets (120×120)
- `banner/rope_l/r` - Rope segments (200×80)

### Icons (150×150 each)
- `icon/coin` - Coin icon
- `icon/gem` - Gem icon
- `icon/heart` - Heart icon
- `icon/boost` - Booster icon
- `icon/chest` - Chest icon
- `icon/mystery` - Mystery box icon
- `icon/jet` - Jet icon

### Slot Frames (168×168 each)
- `slot/frame_default` - Default slot
- `slot/frame_today` - Today's slot (golden)
- `slot/frame_claimed` - Claimed slot
- `slot/frame_locked` - Locked slot

### Effects
- `sparkle/diamond_s/m/l` - Sparkle effects
- `sparkle/star` - Star sparkle
- `jet/body_left` - Jet sprite (420×180)
- `fx/engine_glow` - Engine glow effect

## 📊 Analytics Events

The system automatically tracks:
- `daily_streak_popup_shown`
- `daily_streak_claim_attempt`
- `daily_streak_claim_success`
- `daily_streak_claim_failed`
- `daily_streak_restore_attempt`
- `daily_streak_restore_success`
- `daily_streak_popup_dismissed`

## 🔧 Configuration

### Streak Recovery
- **Cost**: 10 gems
- **Grace Period**: 2 days after missing
- **Auto Reset**: After 3+ days

### Reward Timing
- **Reset Time**: 00:00 UTC (configurable)
- **Grace Period**: 2 hours after reset
- **Cycle Length**: 7 days (repeats)

## 🎮 Game Integration

### Economy Integration
- Uses existing `InventoryManager` for coins/gems
- Uses existing `LivesManager` for hearts
- Integrates with `FirebaseAnalyticsManager`
- Compatible with existing reward systems

### Jet Skin Integration
- Automatically detects player's skin collection
- Unlocks Flash Strike for new players
- Seamlessly integrates with existing skin system

## 🧪 Testing

### Debug Functions
```dart
// Reset all streak data
DailyStreakIntegration.streakManager.resetAllData();

// Force show popup
DailyStreakIntegration.showDailyStreakPopup(context);

// Check current state
print(DailyStreakIntegration.streakStats);
```

### Test Scenarios
1. **New Player**: Only has starter jet → gets Flash Strike on day 2
2. **Experienced Player**: Has multiple jets → gets gems on day 2
3. **Broken Streak**: Miss a day → can restore with gems
4. **Full Cycle**: Complete 7 days → cycle repeats

## 🎯 Backend Integration (Optional)

For cloud sync, extend `DailyStreakManager` to:
1. Sync streak data with your backend
2. Validate rewards server-side
3. Prevent cheating/manipulation
4. Cross-device streak continuity

The current implementation is fully local and cheat-resistant through:
- Encrypted SharedPreferences
- Timestamp validation
- Grace period logic
- Analytics tracking

## 🎨 Customization

### Colors
- Golden banner: `#FFC132` → `#FFE06A`
- Today's glow: `#FFD54A`
- Collect button: Blue gradient
- Restore button: Pink gradient

### Animations
- Banner sway: 2° rotation, 4s cycle
- Jet bobbing: ±8px, 2.5s cycle
- Sparkles: Rotating fade, 3s cycle
- Pulse: 1.0→1.1 scale, 1.5s cycle
- Slide in: Elastic curve, 600ms

### Responsive Breakpoints
- Small screen: < 400px width OR < 700px height
- Slot size: 50px (small) / 60px (normal)
- Banner width: 90% screen width, max 600px

## 🚀 Performance

- **Sprite Atlas**: Single texture for all UI elements
- **Animation Optimization**: Hardware-accelerated transforms
- **Memory Efficient**: Lazy loading and disposal
- **60fps Target**: Optimized for smooth animations

## 📱 Platform Support

- ✅ iOS
- ✅ Android
- ✅ Web (with fallback icons)
- ✅ All screen sizes
- ✅ Tablet layouts

---

**Ready to boost player retention with daily streaks!** 🎯✨
