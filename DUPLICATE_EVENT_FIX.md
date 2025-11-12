# 🎯 DUPLICATE `game_ended` EVENT FIX

**Date:** 2025-11-09  
**Issue:** `event_type: undefined` errors in backend logs caused by duplicate event firing

---

## 🐛 **ROOT CAUSE:**

The `game_ended` event was being fired **TWICE** on every game over:

### **Call Stack:**

1. **Collision Detection** → `_handleCollision()` called
2. **GameStateManager checks if game over** → `_gameStateManager.onLifeLost()` called
   - If last life lost → `setGameOver()` called INSIDE `onLifeLost()` → **✅ FIRST `game_ended` event fired (CORRECT)**
3. **Then `_gameOver()` is called** (line 651 in `flappy_game.dart`)
   - Which calls `setGameOver()` AGAIN (line 853) → **❌ SECOND `game_ended` event fired (DUPLICATE!)**

### **Why This Caused `event_type: undefined`:**

The second `game_ended` event likely had some issue with how it was serialized, resulting in missing required fields when sent to the backend.

---

## ✅ **FIXES APPLIED:**

### **1. Removed Duplicate Event Firing from `hybrid_leaderboard_service.dart`** (First Fix)

**File:** `lib/services/hybrid_leaderboard_service.dart` (line 304)

**Before:**
```dart
_eventBus.fire('game_ended', {
  'score': score,
  'game_mode': gameMode,
  'survival_time_seconds': survivalTimeSeconds,
  // ... old schema fields
});
```

**After:**
```dart
// NOTE: game_ended event is now fired from GameStateManager with correct schema
// This duplicate event firing has been removed to prevent schema conflicts
// See: game_state_manager.dart setGameOver() method
```

---

### **2. Removed Duplicate `setGameOver()` Call from `flappy_game.dart`** (Second Fix - CRITICAL)

**File:** `lib/game/flappy_game.dart` (line 853)

**Before:**
```dart
void _gameOver() {
  onGameOver?.call();
  
  // 🔥 CRITICAL: Set game over state and notify UI (triggers game over menu)
  _gameStateManager.setGameOver(); // ❌ DUPLICATE CALL - Removed!
  
  // ... rest of game over logic
}
```

**After:**
```dart
void _gameOver() {
  onGameOver?.call();
  
  // NOTE: setGameOver() is already called by GameStateManager.onLifeLost() 
  // Calling it again here would fire a duplicate game_ended event!
  
  // ... rest of game over logic (kept)
}
```

**Reasoning:** `setGameOver()` is already called by `GameStateManager.onLifeLost()` when the player loses their last life. Calling it again in `_gameOver()` causes the `game_ended` event to fire twice!

---

## 📊 **EXPECTED RESULT:**

**Before:**
- Backend logs: `❌ Invalid event` with `event_type: undefined` every ~30 seconds
- Flutter logs: Two `📤 Event fired: game_ended` messages on every game over

**After:**
- Backend logs: No more `event_type: undefined` errors ✅
- Flutter logs: Only ONE `📤 Event fired: game_ended` message on game over ✅

---

## 🧪 **TESTING STEPS:**

1. **Hot Restart Flutter App:** `flutter run` (ensure changes are applied)
2. **Play a game and die**
3. **Check Flutter logs:**
   - Should see ONLY ONE `📤 Event fired: game_ended` message
4. **Check Railway backend logs:**
   - Should see NO MORE `event_type: undefined` errors
   - Should see successful event processing: `✅ Event processed successfully`

---

## 📝 **FILES MODIFIED:**

1. ✅ `lib/services/hybrid_leaderboard_service.dart` - Removed old duplicate event firing
2. ✅ `lib/game/flappy_game.dart` - Removed duplicate `setGameOver()` call

---

## 🎉 **SUMMARY:**

The `event_type: undefined` error was caused by **TWO duplicate sources** of `game_ended` event firing:
1. **Old analytics system** (`hybrid_leaderboard_service.dart`) - Fixed previously ✅
2. **Duplicate `setGameOver()` call** (`flappy_game.dart`) - Fixed now ✅

With both fixes applied, the `game_ended` event should now fire **ONLY ONCE** per game over with the correct schema!

