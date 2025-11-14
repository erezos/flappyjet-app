# 🎮 Free-to-Play Heart System - Implementation Plan

## 📋 Overview
Transform FlappyJet into a true free-to-play game with automatic heart refills at strategic points, while maintaining engagement through limited continues within a game session.

---

## 🎯 Requirements Summary

### **Core Principle:**
Hearts are **FREE** and refill automatically when:
- Player returns to world map after game over
- Player presses "Try Again" on game over screen
- Hearts **DO NOT** refill between story mode levels (maintain tension)

### **Story Mode Flow:**
```
Start Level 1 with 3❤️ → Crash once (2❤️ remaining)
→ Pass Level 1 (2❤️ carried to Level 2)
→ Crash twice in Level 2 (0❤️ - GAME OVER)
→ Game Over Options:
   • Continue (ad/3 gems): Resume from crash, +1❤️ given (tactical continue)
   • Try Again: Restart level, hearts REFILLED to max (3 or 6)
   • Back to World Map: Hearts REFILLED to max (3 or 6)
```

### **Endless Mode Flow:**
```
Start with 3❤️ → Play until 0❤️ → GAME OVER
→ Game Over Options:
   • Continue (ad/3 gems): Resume game, +1❤️ given (tactical continue)
   • Try Again: Restart game, hearts REFILLED to max (3 or 6)
   • Close popup: Hearts REFILLED to max (3 or 6)
```

---

## 🔍 Current System Analysis

### **Existing Heart System:**
Located in `lib/game/systems/lives_manager.dart`:
- ✅ Tracks current hearts (3 base, 6 with booster)
- ✅ Has `consumeLife()` to decrement hearts
- ✅ Has `refillToMax()` to restore hearts
- ✅ Has timed regeneration (10 min per heart)

### **Current Game Over Screens:**
1. **Endless Mode**: `lib/ui/widgets/game_over_menu.dart`
   - Shows continue options (ad or gems)
   - Has restart and main menu buttons
   
2. **Story Mode**: `lib/ui/screens/level_failed_screen.dart`
   - Shows continue options (ad or gems)
   - Has "START OVER" button
   - Has back to map (X button)

### **Game Wrapper:**
`lib/ui/widgets/story_mode_game_wrapper.dart`:
- Manages story mode level flow
- Handles game over and level completion
- Transitions between levels

---

## 📊 Heart System Summary Table

| Action | Story Mode | Endless Mode | Hearts Result |
|--------|-----------|--------------|---------------|
| **Start Level/Game** | Hearts carry from previous level | Start with max hearts | No change / Max |
| **Crash** | -1 ❤️ | -1 ❤️ | Decrement |
| **Continue (ad/gems)** | +1 ❤️ | +1 ❤️ | **+1 only** |
| **Try Again** | Refill to max | Refill to max | **Full refill** |
| **Back to Map/Menu** | Refill to max | Refill to max | **Full refill** |
| **Level Complete** | Hearts carry to next | N/A | No change |

### **Key Insights:**
- **Continue = Tactical** (+1 heart, might need multiple continues)
- **Restart = Strategic** (Full refill, start from beginning)
- **Between Levels** = Tension (story mode hearts persist)
- **Timed Regen = Passive Bonus** (rewards players who take breaks, but never required)

---

## 🛠️ Implementation Plan

### **Phase 1: Story Mode Heart Logic** 📖

**Goal:** Hearts persist between levels, only refill on restart or world map return.

**Note:** We're KEEPING the existing timed regeneration system! It acts as a passive bonus for players who take breaks. If a player finishes a level with 2❤️ and leaves the app for 10 minutes, they'll come back with 3❤️. This is generous and costs us nothing!

#### **1.1: Level Start (NO Refill)**

**File: `lib/ui/widgets/story_mode_game_wrapper.dart`**
```dart
// In _initializeGame() or onLevelStart:

void _initializeGame() {
  // DO NOT refill hearts when starting a new level
  // Hearts should carry over from previous level
  
  // Only track current hearts for analytics
  final livesManager = LivesManager();
  final currentHearts = livesManager.currentLives;
  
  safePrint('🎮 Starting level ${widget.level.id} with $currentHearts ❤️');
}
```

**What NOT to do:**
- ❌ Don't call `livesManager.refillToMax()` when starting a level
- ❌ Don't reset hearts between levels

#### **1.2: Level Crash (Consume Heart)**

**File: `lib/game/flappy_game.dart`** (or game state manager)
```dart
// When player crashes in story mode:

void _handleCrash() {
  final livesManager = LivesManager();
  livesManager.consumeLife(); // Decrement by 1
  
  final remainingHearts = livesManager.currentLives;
  
  if (remainingHearts > 0) {
    // Can continue playing - hearts remain for next level
    safePrint('💔 Crashed! $remainingHearts ❤️ remaining');
  } else {
    // No hearts left - trigger game over
    _triggerGameOver();
  }
}
```

#### **1.3: Game Over Screen - "Try Again" Button**

**File: `lib/ui/screens/level_failed_screen.dart`**
```dart
// In _onStartOver() method (line 815):

void _onStartOver() async {
  if (!_canRetry()) {
    // Show heart purchase dialog (existing logic)
    await _showHeartRefillDialog();
    return;
  }

  // ✅ NEW: Refill hearts to max when restarting level
  await LivesManager().refillToMax();
  safePrint('🔄 Restarting level - Hearts refilled to max');

  // Navigate back to level objective popup
  Navigator.of(context).pushReplacement(
    MaterialPageRoute(
      builder: (context) => LevelObjectivePopup(level: widget.level),
    ),
  );
}
```

#### **1.4: Game Over Screen - "Back to World Map" (X Button)**

**File: `lib/ui/screens/level_failed_screen.dart`**
```dart
// In _onBackToMap() method (line 805):

void _onBackToMap() async {
  // ✅ NEW: Refill hearts to max when returning to world map
  await LivesManager().refillToMax();
  safePrint('🗺️ Returning to world map - Hearts refilled to max');

  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(
      builder: (context) => const WorldMapScreen(),
    ),
    (route) => route.isFirst,
  );
}
```

#### **1.5: Continue with Ad/Gems (+1 Heart)**

**File: `lib/ui/screens/level_failed_screen.dart`**
```dart
// In continue handlers:

void _onContinueWithAd() async {
  // ✅ Give +1 heart for tactical continue
  await LivesManager().addLife(1);
  safePrint('📺 Continuing with ad - +1❤️ given');
  
  widget.onContinueWithAd?.call();
}

void _onContinueWithGems() async {
  // ✅ Give +1 heart for tactical continue
  await LivesManager().addLife(1);
  safePrint('💎 Continuing with gems - +1❤️ given');
  
  widget.onContinueWithGems?.call();
}
```

---

### **Phase 2: Endless Mode Heart Logic** ♾️

**Goal:** Hearts refill after every game over (free-to-play, encourage replaying).

#### **2.1: Game Over - "Restart" Button**

**File: `lib/ui/widgets/game_over_menu.dart`**
```dart
// When player clicks "Restart":

void _onRestart() {
  // ✅ NEW: Refill hearts to max on restart
  LivesManager().refillToMax();
  safePrint('🔄 Restarting endless mode - Hearts refilled to max');
  
  widget.onRestart();
}
```

#### **2.2: Game Over - "Main Menu" Button**

**File: `lib/ui/widgets/game_over_menu.dart`**
```dart
// When player goes to main menu:

void _onMainMenu() {
  // ✅ NEW: Refill hearts to max when exiting
  LivesManager().refillToMax();
  safePrint('🏠 Exiting to main menu - Hearts refilled to max');
  
  widget.onMainMenu();
}
```

#### **2.3: Continue with Ad/Gems (+1 Heart)**

**File: `lib/ui/widgets/game_over_menu.dart`**
```dart
// When player continues after watching ad:

void _onContinueWithAd() async {
  // ✅ Give +1 heart for tactical continue
  await LivesManager().addLife(1);
  safePrint('📺 Continuing with ad - +1❤️ given (endless mode)');
  
  widget.onContinueWithAd();
}

// Same for gems (in the gem continue handler):
void _onContinueWithGems() async {
  // ✅ Give +1 heart for tactical continue
  await LivesManager().addLife(1);
  safePrint('💎 Continuing with gems - +1❤️ given (endless mode)');
  
  // Call existing continue handler
}
```

---

### **Phase 3: UI Updates** 🎨

#### **3.1: Update Heart Timer Display**

**Files to Update:**
- Any UI showing "Next heart in X:XX"
- Store heart purchase screens
- Profile/stats screens

**Changes:**
- KEEP the countdown timer display (it's a nice passive bonus!)
- Update messaging: "Hearts refill instantly when you restart or return to menu"
- Add: "Plus, hearts regenerate over time!" (highlight the passive bonus)
- Timer becomes a "nice to have" not a "must wait for"

#### **3.2: Update Game Over Messaging**

**File: `lib/ui/widgets/game_over_menu.dart`**
```dart
// Add helpful hint about free hearts:

Widget _buildGameOverHint() {
  return Text(
    '💡 Tip: Return to menu for free heart refill!',
    style: TextStyle(
      color: Colors.white.withOpacity(0.7),
      fontSize: 12,
      fontStyle: FontStyle.italic,
    ),
  );
}
```

#### **3.3: Update Store UI**

**File: `lib/ui/widgets/store/hearts_store.dart`**
- Update messaging: Hearts are free, store offers instant refills
- Change "Buy Hearts" → "Refill Now" or "Skip Wait"
- Emphasize convenience over necessity

---

## 🧪 Testing Plan

### **Story Mode Tests:**

#### **Test 1: Hearts Persist Between Levels**
1. Start Level 1 with 3 ❤️
2. Crash once (should have 2 ❤️)
3. Complete Level 1
4. **Verify:** Level 2 starts with 2 ❤️ (NOT refilled)

#### **Test 2: Try Again Refills Hearts**
1. Crash until 0 ❤️ → Game Over
2. Click "START OVER"
3. **Verify:** Level restarts with 3 ❤️ (full refill)

#### **Test 3: World Map Return Refills Hearts**
1. Crash until 0 ❤️ → Game Over
2. Click X button (back to world map)
3. **Verify:** World map shows 3 ❤️ (full refill)

#### **Test 4: Continue Gives +1 Heart**
1. Crash until 0 ❤️ → Game Over
2. Click "Continue" (ad or gems)
3. **Verify:** Game continues with 1 ❤️ (not full refill)

### **Endless Mode Tests:**

#### **Test 5: Restart Refills Hearts**
1. Play until 0 ❤️ → Game Over
2. Click "Restart"
3. **Verify:** New game starts with 3 ❤️

#### **Test 6: Continue Gives +1 Heart**
1. Play until 0 ❤️ → Game Over
2. Click "Continue" (ad or gems)
3. **Verify:** Game continues with 1 ❤️ (not full refill)

#### **Test 7: Menu Return Refills Hearts**
1. Play until 0 ❤️ → Game Over
2. Click "Main Menu"
3. **Verify:** Main menu shows 3 ❤️

### **Booster Tests:**

#### **Test 8: Booster Increases Max Hearts**
1. Activate Heart Booster (6 ❤️ max)
2. Crash 3 times (3 ❤️ remaining)
3. Return to world map
4. **Verify:** Hearts refill to 6 ❤️ (not 3)

---

## ⚠️ Potential Challenges & Solutions

### **Challenge 1: Continue Gives +1 Heart Only**
**Issue:** When player continues with 0 hearts, they need at least 1 to play.

**Solution (Confirmed):**
- Give exactly +1 heart when continuing (ad or gems)
- Works in both story and endless mode
- Creates tactical decision: continue with 1 heart or restart with full hearts
- If they crash again immediately, back to game over

**Why +1 instead of full refill:**
- More strategic gameplay (makes each continue valuable)
- Better monetization (might need multiple continues)
- Rewards skilled play (can stretch that 1 heart further)
- Clear value proposition (1 continue = 1 heart = 1 more attempt)

### **Challenge 3: Level Completion Flow**
**Issue:** What if player completes level with 0 hearts?

**Solution:**
- Shouldn't happen (game over triggers at 0 hearts)
- But if it does, treat as normal: carry 0 hearts to next level
- Player can restart or go back to map for refill

### **Challenge 2: Heart Display After Continue**
**Issue:** Player had 0 hearts, continues, now has 1 heart - UI needs to update

**Solution:**
- `LivesManager().addLife(1)` automatically updates the UI
- Heart display shows "1 ❤️" after continue
- No special tracking needed - clean and simple

---

## 📝 Code Changes Summary

### **Files to Modify:**

1. **`lib/ui/screens/level_failed_screen.dart`** (20 min)
   - Add `refillToMax()` to "Try Again" button
   - Add `refillToMax()` to "Back to Map" button
   - Add `addLife(1)` to continue handlers (+1 heart only)

2. **`lib/ui/widgets/game_over_menu.dart`** (15 min)
   - Add `refillToMax()` to restart button
   - Add `refillToMax()` to main menu button
   - Add `addLife(1)` to continue handlers (+1 heart only)

3. **`lib/ui/widgets/story_mode_game_wrapper.dart`** (10 min)
   - Remove any auto-refill on level start
   - Verify hearts persist between levels

4. **`lib/game/flappy_game.dart`** (10 min)
   - Verify crash consumes hearts correctly
   - Ensure game over triggers at 0 hearts

5. **UI/Store Updates** (20 min)
   - Update heart timer messaging (keep display, just reframe it)
   - Update messaging in store (instant + passive regen)
   - Add hints about instant refills + passive bonus

### **Total Estimated Time:** ~1.5 hours (saved 30 min!)

---

## ✅ Acceptance Criteria

### **Must Have:**
- ✅ Story mode: Hearts persist between levels
- ✅ Story mode: "Try Again" refills hearts
- ✅ Story mode: "Back to Map" refills hearts
- ✅ Story mode: "Continue" gives +1 heart only
- ✅ Endless mode: All exits refill hearts
- ✅ Endless mode: "Continue" gives +1 heart only (same as story)
- ✅ Heart booster works (6 max instead of 3)
- ✅ Timed regeneration kept as passive bonus

### **Nice to Have:**
- ✅ Helpful UI hints about free refills
- ✅ Updated store messaging
- ✅ Smooth transitions (no UI flicker)
- ✅ Analytics events for heart refills

---

## 🎯 Success Metrics

**User Engagement:**
- Average session length increases (hearts always available)
- Level retry rate increases (no heart anxiety)
- Story mode progression increases (easier to continue)

**Monetization:**
- Continues (ad/gems) become primary monetization
- Store purchases shift to boosters/skins
- Ad impressions increase (more continues)

**Player Satisfaction:**
- Reduced frustration (no waiting for hearts)
- More generous feeling (free to play anytime)
- Clear feedback about when hearts refill

---

## 🚀 Deployment Checklist

**Before Starting:**
- [ ] Review existing heart system code
- [ ] Test current story mode flow
- [ ] Test current endless mode flow
- [ ] Document any edge cases

**During Implementation:**
- [ ] Disable timer regeneration
- [ ] Add refills to all menu returns
- [ ] Add refills to all restarts
- [ ] Remove refills from continues (story mode only)
- [ ] Update UI messaging
- [ ] Remove timer displays

**After Implementation:**
- [ ] Run all test scenarios
- [ ] Verify with Heart Booster active
- [ ] Verify analytics events fire
- [ ] Test on multiple screen sizes
- [ ] Internal playtesting (5+ levels)

**Before Production:**
- [ ] Beta test with small user group
- [ ] Monitor crash reports
- [ ] Check analytics data
- [ ] Verify monetization still works
- [ ] Final approval from stakeholders

---

## 💡 Additional Considerations

### **Analytics Events to Track:**
```dart
// When hearts refill
eventBus.fire('hearts_refilled', {
  'source': 'try_again' | 'world_map' | 'main_menu' | 'continue',
  'previous_hearts': 0,
  'new_hearts': 3 | 6,
  'has_booster': true | false,
});

// When continue is used
eventBus.fire('continue_used', {
  'method': 'ad' | 'gems',
  'mode': 'story' | 'endless',
  'hearts_before': 0,
  'hearts_after': 1, // Always gives +1 heart in both modes
});
```

### **Future Enhancements:**
- Daily free refills bonus
- "Rage quit protection" - refill after 3+ failures
- "Welcome back" refill after 24h absence
- Special event: unlimited hearts for 1 hour

---

## 📊 Final Notes

This system transforms FlappyJet into a truly free-to-play game while maintaining:
- **Tension** in story mode (hearts persist between levels)
- **Generosity** in endless mode (hearts always refill)
- **Monetization** through continues and boosters
- **Player retention** through reduced friction

The key insight: Hearts are no longer a gate, they're a **session mechanic** that adds tension within a level but never blocks long-term progress.

---

**Status:** 📋 Planning Complete - Ready for Implementation
**Priority:** 🔥 High - Core gameplay change
**Risk Level:** 🟡 Medium - Requires careful testing
**Estimated Effort:** ⏱️ 2 hours development + 1 hour testing

**Next Step:** Review this plan with stakeholder, then proceed to Phase 1 implementation.

