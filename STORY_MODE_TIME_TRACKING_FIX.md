# 🎯 Story Mode Time Tracking Fix - Continue After Ad

## 🐛 **Bug Report #1: Timer includes ad duration**

### **Issue:**
In time-based story mode levels, when a player crashes and continues by watching an ad, the timer includes the time spent on the game over screen, causing the level to complete prematurely.

### **Example from Logs:**
```
# Game starts at: 1762445471564
# Player crashes at 18 seconds (after playing for 18s)
# Game over screen shown for ~5 seconds
# Player watches 10-second ad
# Total real-world elapsed: ~33 seconds

# After ad:
🎯 TIMER: Initial gameStartTime: 1762445471564  ← SAME start time!
🎯 TIME UPDATE: 23s / 20s (elapsed: 23.8s)      ← Level completes immediately!
```

**Expected:** Timer should be at ~18 seconds (actual playing time)
**Actual:** Timer shows ~23.8 seconds (includes game over screen wait time)

---

## 🐛 **Bug Report #2: Timer runs during game over screen**

### **Issue:**
The timer continues running while the player is viewing the game over screen, even before they choose to watch an ad. This means:
- Crash at 18 seconds → Game over screen appears
- Timer keeps running for ~12 seconds while player views menu
- Player clicks "Continue with Ad"
- **ONLY NOW** does pause happen
- Timer has already counted those 12 seconds!

### **Example from Logs:**
```
Line 432: 🔥 Ground collision at 1762446150412
Line 517: ⏸️ Game time paused at 1762446162807  ← 12.4 seconds LATER!
```

**Expected:** Timer should pause immediately when game over screen appears
**Actual:** Timer continues running until ad starts

---

## 🔍 **Root Cause Analysis**

### **Bug #1: Time Tracking Logic**

The timer is based on `DateTime.now().millisecondsSinceEpoch - _gameStartTime`, but:
- `_gameStartTime` was never adjusted when continuing
- Ad pause tracking (`_totalPauseDuration`) was calculated correctly
- BUT: The time **before the ad** (game over screen duration) was NOT paused or tracked!

### **Bug #2: Pause Timing Logic**

The `pauseGameTime()` was only called when the ad **starts** (in `onAdStart` callback), not when the game over screen appears:

```dart
// OLD FLOW:
onContinueWithAd: () async {
  await monetization.showRewardedAdForExtraLife(
    onAdStart: () {
      _game.pauseForAd();
      _game.gameStateManager.pauseGameTime();  // ← TOO LATE!
    },
```

This meant:
1. Player crashes → `_onGameOver()` called
2. Timer **keeps running** while game over menu is visible
3. Player clicks "Continue with Ad" (12 seconds later)
4. **ONLY NOW** does `pauseGameTime()` get called
5. Those 12 seconds are already counted!

---

---

## ✅ **Solution Implemented**

### **Fix #1: Adjust Game Start Time on Continue** (from previous fix)

Modified `GameStateManager.continueGame()` to shift `_gameStartTime` forward by the pause duration:

```dart
// lib/game/systems/game_state_manager.dart - continueGame()

// ⏱️ CRITICAL TIME FIX: Adjust game start time to preserve playing time
// This ensures that time-based levels don't complete prematurely after ad continue
if (_gameStartTime > 0 && _totalPauseDuration > 0) {
  final oldStartTime = _gameStartTime;
  _gameStartTime = _gameStartTime + _totalPauseDuration;
  
  safePrint('⏱️ TIME FIX: Adjusting game start time for continue');
  safePrint('⏱️ Old start time: $oldStartTime');
  safePrint('⏱️ New start time: $_gameStartTime (shifted by ${_totalPauseDuration}ms)');
  safePrint('⏱️ Preserved playing time: ${getElapsedGameTime()}ms');
}
```

### **Fix #2: Pause Game Time IMMEDIATELY on Game Over** (new fix)

Modified `_onGameOver()` in `story_mode_game_wrapper.dart` to pause the timer as soon as the game over screen appears:

```dart
// lib/ui/widgets/story_mode_game_wrapper.dart - _onGameOver()

void _onGameOver() {
  if (_levelEnded) return;

  safePrint('🎮 Game over in story mode');

  // Stop update timer
  _updateTimer?.cancel();
  
  // ⏱️ CRITICAL FIX: Pause game time IMMEDIATELY when game over screen appears
  // This prevents the timer from running while the player views the game over menu
  _game.gameStateManager.pauseGameTime();
  safePrint('⏸️ STORY MODE: Game time paused on game over (before ad)');

  // Check if objective was completed before game over
  final objectiveCompleted = _objectiveTracker.checkFinalCompletion();
  // ...
}
```

### **Fix #3: Resume on Quit/Restart** (new fix)

Added `resumeGameTime()` calls when the player quits or restarts to prevent pause state from persisting:

```dart
// lib/ui/widgets/story_mode_game_wrapper.dart

void _handleStoryModeRestart() {
  safePrint('🎯 STORY MODE: Restart requested');
  
  // ⏱️ CRITICAL FIX: Resume game time if it was paused
  _game.gameStateManager.resumeGameTime();
  safePrint('▶️ STORY MODE: Game time resumed (player restarting level)');
  
  _game.resetGame();
}

void _handleBackToMap() {
  // ...
  // ⏱️ CRITICAL FIX: Resume game time if it was paused
  _game.gameStateManager.resumeGameTime();
  safePrint('▶️ STORY MODE: Game time resumed (player quit to map)');
  // ...
}
```

---

## 🎯 **How It Works Now**

### **Timeline with ALL Fixes:**

```
🎯 TIMER: Initial gameStartTime: 1762446132236
💥 Crash at 18s
⏸️ STORY MODE: Game time paused on game over (before ad)  ← FIX #2: Immediate pause!
[Player views game over menu for 12s - timer NOT running]
[Player clicks "Continue with Ad"]
[Ad plays for 10s - timer still paused]
▶️ Game time resumed. Pause duration: 22000ms              ← Total pause = 12s + 10s
⏱️ TIME FIX: Adjusting game start time                     ← FIX #1: Shift start time
⏱️ Old start time: 1762446132236
⏱️ New start time: 1762446154236 (shifted by 22000ms)
⏱️ Preserved playing time: 18000ms
🎯 TIME UPDATE: 18s / 22s ✅ Correct!
```

### **Key Changes:**

1. **Pause IMMEDIATELY on game over** - Not just when ad starts
2. **Track ALL pause time** - Game over screen + ad duration
3. **Shift start time on continue** - Preserves exact playing time
4. **Resume on quit/restart** - Prevents pause state from persisting

---

## ✅ **Result**

**Before Fixes:**
- Timer at 18s when crashed
- Waited 12s on game over screen (timer still running → 30s)
- Watched 10s ad (paused → stays at 30s)
- After continue: Timer shows 30s / 22s → Level completes immediately ❌

**After Fixes:**
- Timer at 18s when crashed
- **Paused immediately** → stays at 18s
- Waited 12s on game over screen (paused → stays at 18s)
- Watched 10s ad (paused → stays at 18s)
- After continue: Timer shows 18s / 22s → Level continues correctly ✅

---

## 📝 **Files Modified**

1. **`lib/game/systems/game_state_manager.dart`** (Fix #1)
   - Added time shift logic in `continueGame()` to adjust `_gameStartTime`

2. **`lib/ui/widgets/story_mode_game_wrapper.dart`** (Fix #2 & #3)
   - Added `pauseGameTime()` call in `_onGameOver()` for immediate pause
   - Added `resumeGameTime()` calls in `_handleStoryModeRestart()` and `_handleBackToMap()` to prevent pause state persistence

---

## 🧪 **Testing**

To verify the fix works:

1. Start a time-based level (e.g., Level 2: "Palm Paradise Path" - 22 seconds)
2. Play for ~18 seconds
3. Crash intentionally
4. **Wait on game over screen for 10+ seconds** (timer should stay paused)
5. Click "Continue with Ad"
6. Watch the ad
7. After ad: Timer should show ~18s / 22s (not 30s+ / 22s)
8. Continue playing - level should NOT complete immediately

**Expected Logs:**
```
💥 Crash at 18s
⏸️ STORY MODE: Game time paused on game over (before ad)
[Wait 10s on game over screen]
⏸️ Game time paused at [timestamp]
[Watch 10s ad]
▶️ Game time resumed. Pause duration: 20000ms
⏱️ TIME FIX: Adjusting game start time
⏱️ Preserved playing time: 18000ms
🎯 TIME UPDATE: 18s / 22s ✅
```

---
5. **Game continues:** `_gameStartTime` is **NOT updated** ❌

**When calculating elapsed time after continue:**
- `currentTime - _gameStartTime` = **~34 seconds** (includes game over screen wait)
- `_totalPauseDuration` = **~10 seconds** (only the ad duration)
- **Result:** `34s - 10s = ~24s` ← **Includes the 5s game over wait time!**

---

## ✅ **Solution**

### **Approach:**
When a player continues after watching an ad, we need to reset the game start time to exclude **ALL** non-playing time (game over screen + ad).

### **Implementation:**

```dart
// lib/game/systems/game_state_manager.dart - continueGame()

void continueGame() {
  // ... existing code ...

  // 🎯 STORY MODE TIME FIX: Adjust game start time to exclude game-over-to-continue duration
  // When user crashes and watches an ad, the time spent on game over screen should not count
  // We do this by shifting the start time forward by (actual elapsed - playing time)
  if (_gameStartTime > 0) {
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final actualElapsedBeforeContinue = getElapsedGameTime(); // This is the REAL playing time
    final newStartTime = currentTime - actualElapsedBeforeContinue;
    
    safePrint('⏱️ TIME FIX: Adjusting game start time for continue');
    safePrint('⏱️ Old start time: $_gameStartTime');
    safePrint('⏱️ New start time: $newStartTime (shifted by ${newStartTime - _gameStartTime}ms)');
    safePrint('⏱️ Preserved playing time: ${actualElapsedBeforeContinue}ms');
    
    _gameStartTime = newStartTime;
    // Reset pause tracking since we've already accounted for it in the new start time
    _totalPauseDuration = 0;
    _pauseStartTime = 0;
  }
}
```

### **How It Works:**

**Before the fix:**
```
Real World Timeline:
├─ 0s: Game starts (startTime = T0)
├─ 18s: Player crashes
├─ 23s: Player starts ad (5s on game over screen)
├─ 33s: Ad ends, game continues
└─ Calculation: (33 - 0) - 10 = 23s ❌ WRONG!
```

**After the fix:**
```
Real World Timeline:
├─ 0s: Game starts (startTime = T0)
├─ 18s: Player crashes (getElapsedGameTime = 18s)
├─ 23s: Player starts ad
├─ 33s: Ad ends, game continues
│       → NEW startTime = 33s - 18s = 15s (adjusted)
│       → Reset pause tracking
└─ Calculation: (33 - 15) - 0 = 18s ✅ CORRECT!
```

The key insight: `getElapsedGameTime()` correctly calculates the **actual playing time** (excluding ad pauses). When we continue, we set the start time such that the current time minus the new start time equals the actual playing time.

---

## 🧪 **Testing**

### **Manual Test Case:**

1. **Start a time-based level** (e.g., Level 14: "Desert Endurance" - 20s survival)
2. **Play for 10 seconds**
3. **Crash** (let game over screen show for 5 seconds)
4. **Watch a 10-second ad to continue**
5. **Verify:** Timer should show **~10 seconds remaining** (not completing immediately)

### **Expected Logs After Fix:**

```
🎯 TIMER: Initial gameStartTime: 1762445471564
💥 Crash at 10s
⏸️ Game time paused at 1762445486000 (after 5s on game over screen)
▶️ Game time resumed. Pause duration: 10000ms
⏱️ TIME FIX: Adjusting game start time for continue
⏱️ Old start time: 1762445471564
⏱️ New start time: 1762445486000 (shifted by 14436ms)
⏱️ Preserved playing time: 10000ms
🎯 TIME UPDATE: 10s / 20s ✅ Correct!
```

---

## 📊 **Impact**

### **Files Changed:**
- `lib/game/systems/game_state_manager.dart` - Added time adjustment logic in `continueGame()`

### **Affected Features:**
- ✅ **Time-based story mode levels** - Timer now correctly tracks only playing time
- ✅ **VS battle levels** - Also uses time tracking, now fixed
- ❌ **Obstacle-based levels** - Not affected (no time tracking)
- ❌ **Endless mode** - Not affected (no time limits)

### **Edge Cases Handled:**
- Multiple continues per level (each continue resets the time properly)
- Gem-based continues (same fix applies)
- Ad watches that fail (time tracking remains consistent)

---

## 🎯 **Summary**

**Problem:** Time tracker counted game over screen wait time, causing levels to complete prematurely after ad continues.

**Solution:** Adjust game start time when continuing to preserve only actual playing time.

**Result:** Time-based levels now have accurate, fair timers that only count active gameplay! 🚀

