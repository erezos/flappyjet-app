# 🎯 Daily Streak System - Implementation Plan

Based on feedback from Nov 14, 2025

---

## ✅ Technical Verification

### 1. **24-Hour Calculation** ✅ CORRECT
**Location:** `lib/game/systems/daily_streak_manager.dart` lines 211-235

```dart
// Uses calendar day comparison, NOT 24-hour time windows
final today = DateTime(now.year, now.month, now.day);  // Strips time component
final lastClaim = DateTime(_lastClaimDate!.year, _lastClaimDate!.month, _lastClaimDate!.day);
final daysSinceLastClaim = today.difference(lastClaim).inDays;
```

**How it works:**
- Claim at 11:59 PM on Monday → Can claim again at 12:01 AM on Tuesday ✅
- Uses **calendar days**, not 24-hour periods
- This is **correct** - matches industry standard (Duolingo, Candy Crush, etc.)
- Prevents timezone manipulation exploits

**States:**
- `daysSinceLastClaim == 0` → Already claimed today OR can claim today
- `daysSinceLastClaim == 1` → Available (next day)
- `daysSinceLastClaim > 1` → Expired (streak broken)

### 2. **Duplicate Jet Detection** ✅ WORKS PERFECTLY
**Location:** `lib/game/systems/daily_streak_manager.dart` lines 518-535

```dart
if (_inventory.isOwned(reward.jetSkinId!)) {
  // Player already has this jet - give coins instead
  const duplicateJetCoins = 400; // Flash Strike equivalent value
  await _inventory.addCoinsWithAnimation(duplicateJetCoins);
  safePrint('🚁 Duplicate jet detected: ${reward.jetSkinId} → Awarded $duplicateJetCoins coins instead');
  
  // Show beautiful duplicate jet popup
  await _showDuplicateJetPopup(reward.jetSkinId!, duplicateJetCoins);
} else {
  // Normal jet unlock
  await _inventory.unlockSkin(reward.jetSkinId!);
}
```

**Result:**
- ✅ Checks if player owns the jet
- ✅ Gives 400 coins instead if duplicate
- ✅ Shows special popup notification
- ✅ Animated coin collection

### 3. **Current Rewards** 
**Location:** `lib/game/systems/daily_streak_manager.dart` lines 38-145

#### New Players (≤1 skin owned):
```
Day 1: 100 Coins
Day 2: Flash Strike Jet 🚁
Day 3: 15-Min Heart Booster
Day 4: 250 Coins
Day 5: 30-Min Heart Booster
Day 6: Mystery Box
Day 7: 15 Gems
```

#### Experienced Players (2+ skins):
```
Day 1: 100 Coins
Day 2: 5 Gems
Day 3: 15-Min Heart Booster
Day 4: 250 Coins
Day 5: 30-Min Heart Booster
Day 6: Mystery Box
Day 7: 15 Gems
```

---

## 🎯 Implementation Tasks

### Task 1: Add Backend Event Tracking ⚡ HIGH PRIORITY
**Time:** 1 hour

#### Events to Fire:
```dart
// 1. Daily Streak Claimed
UnifiedAnalyticsManager().trackEvent('daily_streak_claimed', {
  'day_in_cycle': todayRewardIndex + 1,        // 1-7
  'current_streak': _currentStreak,             // Total days
  'current_cycle': _currentCycle,               // Which 7-day cycle
  'reward_type': reward.type.name,              // coins, gems, heartBooster, etc.
  'reward_amount': reward.amount,               // Numeric value
  'reward_set': _currentCycleRewardSet,         // 'new_player' or 'experienced'
  'timestamp': DateTime.now().toIso8601String(),
});

// 2. Daily Streak Broken
UnifiedAnalyticsManager().trackEvent('daily_streak_broken', {
  'last_streak_days': _currentStreak,
  'last_cycle': _currentCycle,
  'days_missed': daysSinceLastClaim - 1,
  'total_cycles_completed': _totalStreaksCompleted,
  'timestamp': DateTime.now().toIso8601String(),
});

// 3. Daily Streak Milestone
UnifiedAnalyticsManager().trackEvent('daily_streak_milestone', {
  'milestone_days': _currentStreak,              // 7, 14, 30, 100, etc.
  'total_cycles': _currentCycle,
  'total_cycles_completed': _totalStreaksCompleted,
  'timestamp': DateTime.now().toIso8601String(),
});

// 4. Cycle Completed (already exists - line 427)
UnifiedAnalyticsManager().trackEvent('daily_streak_cycle_completed', {
  'cycle_number': _currentCycle,
  'total_cycles': _totalStreaksCompleted,
  'reward_set': _currentCycleRewardSet,
});
```

#### Where to Add:
1. **`claimTodayReward()`** - Line 485 (add `daily_streak_claimed` event)
2. **`_resetStreak()`** - Line 589 (add `daily_streak_broken` event)
3. **`claimTodayReward()`** - After line 485 (add milestone check)

#### Backend Schema:
```typescript
// Railway Backend - Event Processor
interface DailyStreakClaimedEvent {
  event: 'daily_streak_claimed';
  user_id: string;
  day_in_cycle: number;      // 1-7
  current_streak: number;     // Total consecutive days
  current_cycle: number;      // Which 7-day cycle
  reward_type: string;        // 'coins' | 'gems' | 'heartBooster' | 'jetSkin' | 'mysteryBox'
  reward_amount: number;
  reward_set: string;         // 'new_player' | 'experienced'
  timestamp: string;
}

// What backend should do:
1. Update user.daily_streak_current = current_streak
2. Update user.daily_streak_longest = MAX(current, longest)
3. Update user.daily_streak_last_claim = timestamp
4. Track for analytics dashboard
5. No need to validate rewards (trust client)
```

---

### Task 2: Improve UI Button (Bigger + Red Badge) ⚡ HIGH PRIORITY
**Time:** 30 minutes

**Location:** `lib/ui/widgets/status_bar/daily_streak_button.dart`

#### Changes Needed:

```dart
// Current icon sizes (line 69-70):
final iconSize = isLargeTablet ? 24.0 : isTablet ? 22.0 : 18.0;

// NEW: Make 20-30% bigger
final iconSize = isLargeTablet ? 32.0 : isTablet ? 28.0 : 24.0;

// Current notification dot (line 75):
final notificationDotSize = isLargeTablet ? 8.0 : isTablet ? 7.0 : 6.0;

// NEW: Replace with "1" badge (common gaming pattern)
// Remove lines 142-153 (current red dot)
// Add new badge:
if (hasNotification)
  Positioned(
    top: -4,
    right: -4,
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.5),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Text(
        '1',
        style: TextStyle(
          color: Colors.white,
          fontSize: isLargeTablet ? 12.0 : isTablet ? 11.0 : 10.0,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  ),
```

**Visual Result:**
```
Before:                 After:
┌────────┐             ┌──────────┐
│ 📅  5  │             │  📅  5   │  ← 30% bigger
│   •    │             │    ⓵     │  ← Red badge with "1"
└────────┘             └──────────┘
  Small                  More visible
```

---

### Task 3: Push Notifications ⚡ HIGH PRIORITY
**Time:** 2 hours

**Location:** `lib/game/systems/local_notification_manager.dart`

#### Notifications to Add:

1. **Morning Reminder (9 AM local)**
```dart
Future<void> scheduleDailyStreakMorningReminder() async {
  await _notificationsPlugin.zonedSchedule(
    NotificationType.dailyStreakReminder.id,
    '🎁 Daily Bonus Ready!',
    'Claim your reward and keep your ${_streakManager.currentStreak}-day streak going! 🔥',
    _nextInstance9AM(),  // 9 AM local time
    notificationDetails,
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    matchDateTimeComponents: DateTimeComponents.time,
  );
}
```

2. **Evening Warning (9 PM local)** - Only if not claimed
```dart
Future<void> scheduleDailyStreakEveningWarning() async {
  // Only schedule if they haven't claimed today
  if (!_streakManager.claimedToday) {
    await _notificationsPlugin.zonedSchedule(
      NotificationType.dailyStreakLastChance.id,
      '⚠️ Last Chance!',
      'Don\'t break your ${_streakManager.currentStreak}-day streak! Claim before midnight! 🕐',
      _nextInstance9PM(),  // 9 PM local time
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
```

3. **Milestone Celebration** - After claiming special days
```dart
Future<void> showStreakMilestoneNotification(int days) async {
  String message;
  if (days == 7) {
    message = '🎉 7-day streak! You\'re unstoppable!';
  } else if (days == 30) {
    message = '🔥 30-day streak! You\'re a legend!';
  } else if (days == 100) {
    message = '👑 100-day streak! Hall of Fame!';
  } else {
    return; // Don't send for other days
  }
  
  await _notificationsPlugin.show(
    NotificationType.dailyStreakMilestone.id,
    'Streak Milestone!',
    message,
    notificationDetails,
  );
}
```

#### Add to NotificationType enum:
```dart
enum NotificationType {
  dailyStreakReminder,        // Existing
  dailyStreakLastChance,      // NEW
  dailyStreakMilestone,       // NEW
  // ... other types
}
```

#### Schedule Logic:
```dart
// In DailyStreakManager.claimTodayReward() - After line 485
// 1. Cancel existing notifications
await LocalNotificationManager().cancelNotification(NotificationType.dailyStreakReminder);
await LocalNotificationManager().cancelNotification(NotificationType.dailyStreakLastChance);

// 2. Schedule tomorrow's morning reminder
await LocalNotificationManager().scheduleDailyStreakMorningReminder();

// 3. Check for milestones
if (_currentStreak == 7 || _currentStreak == 30 || _currentStreak == 100) {
  await LocalNotificationManager().showStreakMilestoneNotification(_currentStreak);
}

// 4. Schedule evening warning for tomorrow (will check claimedToday at 9 PM)
// This is tricky - need to schedule it to run conditionally
```

---

### Task 4: Review & Align Rewards 🎨 MEDIUM PRIORITY
**Time:** 30 minutes (discussion + approval)

#### Current Rewards Analysis:

| Day | New Players | Experienced | Analysis |
|-----|-------------|-------------|----------|
| 1 | 100 coins | 100 coins | ✅ Fair starting reward |
| 2 | **Flash Strike Jet** | 5 gems | ⚠️ HUGE difference! |
| 3 | 15-min booster | 15-min booster | ✅ Same (good) |
| 4 | 250 coins | 250 coins | ✅ Same |
| 5 | 30-min booster | 30-min booster | ✅ Same |
| 6 | Mystery Box | Mystery Box | ✅ Same |
| 7 | 15 gems | 15 gems | ✅ Same |

#### Questions for Alignment:

1. **Day 2 Jet (New Players)**
   - Flash Strike is valued at ~400 coins
   - This is a **strong retention hook** for new players
   - **Recommendation:** Keep it! It's working as intended.

2. **Day 2 Gems (Experienced Players)**
   - Only 5 gems (vs 400-coin value jet)
   - Feels underwhelming after Day 1's 100 coins
   - **Options:**
     - A) Increase to 10 gems (more valuable)
     - B) Give a different jet (rotation pool?)
     - C) Give 300 coins + 5 gems (balanced)
   - **Recommendation:** Option A (10 gems) - Simple & fair

3. **Heart Boosters**
   - Day 3: 15 minutes (+ refill to 6 hearts)
   - Day 5: 30 minutes (+ refill to 6 hearts)
   - **Question:** Is 15 min too short? Most players need 2+ lives to complete a level.
   - **Options:**
     - A) Keep as-is (15 min is fine for 2-3 quick games)
     - B) Increase to 30 min / 60 min
   - **Recommendation:** Keep as-is (players can always buy more)

4. **Mystery Box (Day 6)**
   - Current: 3 random options (150 coins, 8 gems, or 60-min booster)
   - Uses timestamp % 3 (predictable, not truly random)
   - **Recommendations:**
     - Fix randomness: Use `Random().nextInt(3)`
     - Track outcomes in analytics
     - Consider player state (e.g., if low hearts → higher chance of booster)

5. **Day 7 Finale**
   - 15 gems (premium currency)
   - Good finale reward
   - **Recommendation:** Keep as-is

#### Proposed New Reward Table:

| Day | New Players | Experienced Players | Changes |
|-----|-------------|---------------------|---------|
| 1 | 100 coins | 100 coins | No change |
| 2 | Flash Strike Jet 🚁 | **10 gems** ⬆️ | Doubled from 5 |
| 3 | 15-min booster | 15-min booster | No change |
| 4 | 250 coins | 250 coins | No change |
| 5 | 30-min booster | 30-min booster | No change |
| 6 | Mystery Box | Mystery Box | Fix randomness |
| 7 | 15 gems | 15 gems | No change |

**Total Weekly Value:**
- New Players: Jet (400) + 350 coins + 15 gems + 45 min booster + Mystery (~200) = **~1,010 value**
- Experienced: 10 gems + 350 coins + 15 gems + 45 min booster + Mystery (~200) = **~575 value** (25 gems = ~250 value)

---

## 📋 Implementation Checklist

### Phase 1: Quick Wins (2 hours)
- [ ] Add backend event tracking to `claimTodayReward()` 
- [ ] Add backend event tracking to `_resetStreak()`
- [ ] Add milestone event tracking
- [ ] Make icon 30% bigger in status bar button
- [ ] Replace red dot with "1" badge
- [ ] Test on phone + tablet

### Phase 2: Rewards Review (30 min)
- [ ] Discuss Day 2 reward for experienced players (5 → 10 gems?)
- [ ] Fix Mystery Box randomness (`Random().nextInt(3)`)
- [ ] Update reward values if approved
- [ ] Update README.md with new rewards

### Phase 3: Push Notifications (2 hours)
- [ ] Add notification types to enum
- [ ] Implement morning reminder (9 AM)
- [ ] Implement evening warning (9 PM, conditional)
- [ ] Implement milestone notifications
- [ ] Test notification scheduling
- [ ] Test notification tapping (opens app to streak popup)
- [ ] Handle timezone changes
- [ ] Request notification permissions (iOS/Android)

### Phase 4: Testing (1 hour)
- [ ] Test 24-hour rollover (simulate day change)
- [ ] Test duplicate jet detection
- [ ] Test cycle completion (Day 7 → Day 1)
- [ ] Test streak break (miss 2+ days)
- [ ] Test backend event firing
- [ ] Test notifications on real devices
- [ ] Test badge visibility
- [ ] Test icon sizing on different screens

### Phase 5: Documentation (30 min)
- [ ] Update `DAILY_STREAK_SYSTEM_COMPREHENSIVE_ANALYSIS.md`
- [ ] Update `lib/ui/widgets/daily_streak/README.md`
- [ ] Add notification documentation
- [ ] Document event schema for backend team

---

## 🎯 Success Metrics

After implementation, track:

1. **Event Firing:**
   - `daily_streak_claimed` events in backend logs ✅
   - `daily_streak_broken` events tracked ✅
   - `daily_streak_milestone` events logged ✅

2. **UI Improvements:**
   - Button is 30% larger ✅
   - Badge shows "1" instead of dot ✅
   - More visible on Story tab ✅

3. **Push Notifications:**
   - Morning reminders sent ✅
   - Evening warnings sent (if not claimed) ✅
   - Milestone celebrations sent ✅
   - Users tap notification → App opens → Streak popup shows ✅

4. **Rewards:**
   - Experienced players get 10 gems on Day 2 (if approved) ✅
   - Mystery Box uses true randomness ✅
   - Duplicate jets correctly award 400 coins ✅

---

## 🔍 Technical Questions Answered

### Q: Does the system calculate correctly (24 hours)?
**A:** ✅ YES - Uses calendar day comparison, which is correct. 
- Claim Monday 11:59 PM → Can claim Tuesday 12:01 AM
- Industry standard approach (Duolingo, Candy Crush)
- Prevents timezone exploits

### Q: Do we check for duplicate jets?
**A:** ✅ YES - Perfectly implemented!
- Checks `_inventory.isOwned(jetSkinId)`
- Gives 400 coins instead if duplicate
- Shows special popup notification

### Q: Are rewards aligned?
**A:** ⚠️ MOSTLY - One suggestion:
- Day 2 for experienced players: 5 gems → **10 gems** (more fair)
- Fix Mystery Box randomness
- Everything else looks good!

---

## 📅 Timeline

- **Phase 1 (Quick Wins):** Today - 2 hours
- **Phase 2 (Rewards Review):** Tomorrow - 30 min discussion
- **Phase 3 (Notifications):** Tomorrow - 2 hours
- **Phase 4 (Testing):** Day 3 - 1 hour
- **Phase 5 (Docs):** Day 3 - 30 min

**Total:** ~6 hours of dev work + 30 min discussion

---

## 🚀 Ready to Start?

Let me know:
1. **Approve Day 2 reward change** (5 → 10 gems for experienced)?
2. **Priority order** - Which phase first?
3. **Any other reward adjustments?**

I can start implementing immediately! 🎯

