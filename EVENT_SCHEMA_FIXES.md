# Event Schema Alignment - Flutter ↔ Backend

## ✅ **Fixed Issues:**

1. **Base Fields Auto-Injection:** `EventBus.fire()` now automatically adds:
   - `app_version` (from DeviceIdentityManager)
   - `platform` (from DeviceIdentityManager)

2. **Event Serialization:** `Event.toJson()` now:
   - Uses `event_type` (not `name`)
   - Uses `user_id` (not `userId`)
   - Merges payload fields into root object (backend schema is flat, not nested)

## ⚠️ **Remaining Issues to Fix:**

### **1. game_ended Event** (Critical - Leaderboard Updates!)

**Backend Expects:**
```javascript
{
  event_type: 'game_ended',
  user_id: string,
  timestamp: ISO string,
  app_version: string,
  platform: 'ios' | 'android',
  game_mode: 'endless' | 'story',
  score: number,
  duration_seconds: number,           // ✅ Flutter sends: survival_time_seconds
  obstacles_dodged: number,           // ✅ Flutter sends: obstacles_passed
  coins_collected: number,            // ❌ MISSING
  gems_collected: number,             // ❌ MISSING
  hearts_remaining: number,           // ❌ MISSING
  cause_of_death: string,             // ❌ MISSING
  max_combo: number,                  // ❌ MISSING
  powerups_used: string[],            // ❌ MISSING
}
```

**Flutter Currently Sends:**
```dart
{
  'score': _score,
  'best_score': _bestScore,           // ❌ Not in backend schema
  'best_streak': _bestStreak,         // ❌ Not in backend schema
  'theme': _currentTheme.id,          // ❌ Not in backend schema
  'theme_name': _currentTheme.displayName, // ❌ Not in backend schema
  'survival_time_seconds': getElapsedGameTime() / 1000,  // ✅ (rename to duration_seconds)
  'obstacles_passed': _score,         // ✅ (rename to obstacles_dodged)
  'continues_used': _continuesUsedThisRun, // ❌ Not in backend schema
  'game_mode': 'endless',             // ✅
  'was_clean_run': _continuesUsedThisRun == 0, // ❌ Not in backend schema
}
```

**📝 Fix Required:**
- Rename `survival_time_seconds` → `duration_seconds`
- Rename `obstacles_passed` → `obstacles_dodged`
- Add `coins_collected` (track in GameStateManager)
- Add `gems_collected` (track in GameStateManager)
- Add `hearts_remaining` (from LivesManager)
- Add `cause_of_death` (e.g., 'obstacle_collision', 'quit', 'out_of_bounds')
- Add `max_combo` (track in GameStateManager or default to 0)
- Add `powerups_used` (array of strings, or default to [])

---

### **2. continue_used Event** (New Event - Phase 2)

**Backend Expects:**
```javascript
{
  event_type: 'continue_used',
  user_id: string,
  timestamp: ISO string,
  app_version: string,
  platform: 'ios' | 'android',
  game_mode: 'endless' | 'story',
  score_at_death: number,
  continue_type: 'ad_watch' | 'gem_purchase' | 'coin_purchase',
  cost_coins: number,
  cost_gems: number,
  lives_restored: number,
  continues_used_this_run: number,
}
```

**Flutter Currently Sends:**
```dart
// ❌ Event is fired but schema is incomplete
{
  'game_mode': gameMode,
  'score': currentScore,              // ❌ Wrong field name (should be score_at_death)
  'continue_type': continueType,      // ✅
  'cost_gems': costGems,              // ✅
  'cost_coins': costCoins,            // ✅
  'continues_this_run': _continuesUsedThisRun, // ❌ Wrong field name (should be continues_used_this_run)
}
```

**📝 Fix Required:**
- Rename `score` → `score_at_death`
- Rename `continues_this_run` → `continues_used_this_run`
- Add `lives_restored` (always 1 or based on continue type)

---

### **3. level_started Event** (Story Mode - Phase 2)

**Backend Expects:**
```javascript
{
  event_type: 'level_started',
  user_id: string,
  timestamp: ISO string,
  app_version: string,
  platform: 'ios' | 'android',
  level_id: string,
  zone_id: string,
  difficulty: string,
  objective_type: string,
  hearts_remaining: number,
  attempt_number: number,
  is_first_attempt: boolean,
}
```

**Flutter Currently Sends:**
```dart
// ✅ All fields present, verify exact schema match
{
  'level_id': widget.level.id,
  'zone_id': widget.level.zoneId,
  'difficulty': widget.level.difficulty,
  'objective_type': widget.level.objectiveType,
  'attempt_number': _attemptNumber,
  'hearts_remaining': livesManager.currentLives,
  'is_first_attempt': isFirstAttempt,
}
```

**📝 Status:** ✅ **Looks correct** - verify during testing

---

### **4. level_failed Event** (Story Mode - Phase 2)

**Backend Expects:**
```javascript
{
  event_type: 'level_failed',
  user_id: string,
  timestamp: ISO string,
  app_version: string,
  platform: 'ios' | 'android',
  level_id: string,
  zone_id: string,
  cause_of_death: string,
  score: number,
  time_survived_seconds: number,
  continues_used: number,
  hearts_remaining: number,
}
```

**Flutter Currently Sends:**
```dart
// ✅ All fields present, verify exact schema match
{
  'level_id': widget.level.id,
  'zone_id': widget.level.zoneId,
  'cause_of_death': causeOfDeath,
  'score': gameStateManager.score,
  'time_survived_seconds': gameStateManager.getElapsedGameTime() ~/ 1000,
  'continues_used': gameStateManager.continuesUsedThisRun,
  'hearts_remaining': livesManager.currentLives,
}
```

**📝 Status:** ✅ **Looks correct** - verify during testing

---

### **5. currency_earned Event** (Economy - Phase 2)

**Backend Expects:**
```javascript
{
  event_type: 'currency_earned',
  user_id: string,
  timestamp: ISO string,
  app_version: string,
  platform: 'ios' | 'android',
  currency_type: 'coins' | 'gems',
  amount: number,
  source: string,
  source_id: string,
  new_balance: number,
}
```

**Flutter Currently Sends:**
```dart
// ✅ All fields present, verify exact schema match
{
  'currency_type': 'coins' or 'gems',
  'amount': amount,
  'source': source,
  'source_id': sourceId,
  'new_balance': _coins.value or _gems.value,
}
```

**📝 Status:** ✅ **Looks correct** - verify during testing

---

### **6. currency_spent Event** (Economy - Phase 2)

**Backend Expects:**
```javascript
{
  event_type: 'currency_spent',
  user_id: string,
  timestamp: ISO string,
  app_version: string,
  platform: 'ios' | 'android',
  currency_type: 'coins' | 'gems',
  amount: number,
  spent_on: string,
  item_id: string,
  new_balance: number,
}
```

**Flutter Currently Sends:**
```dart
// ✅ All fields present, verify exact schema match
{
  'currency_type': 'coins' or 'gems',
  'amount': amount,
  'spent_on': spentOn,
  'item_id': itemId,
  'new_balance': _coins.value or _gems.value,
}
```

**📝 Status:** ✅ **Looks correct** - verify during testing

---

## 🚀 **Action Plan:**

1. ✅ **DONE:** Fix base fields auto-injection in `EventBus`
2. ✅ **DONE:** Fix `Event.toJson()` serialization
3. **TODO:** Fix `game_ended` event in `GameStateManager`
4. **TODO:** Fix `continue_used` event in `GameStateManager`
5. **TODO:** Test all events end-to-end with Railway backend
6. **TODO:** Monitor Railway logs for validation errors

---

## 📊 **Testing Checklist:**

After fixes, verify in Railway logs:
- [ ] No more "❌ Invalid event" messages
- [ ] `game_ended` events are accepted and processed
- [ ] `continue_used` events are accepted
- [ ] Leaderboard updates after game ends
- [ ] All events have `app_version` and `platform`


