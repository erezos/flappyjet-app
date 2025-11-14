# 🐛 Daily Missions Real-Time Update Issue

**Date:** November 14, 2025  
**Severity:** Medium (UX issue, not data loss)  
**Difficulty:** ⭐⭐☆☆☆ (Easy Fix)

---

## 🔍 Problem Description

**User Report:**
> "I played on my real device alot of games - then went to the daily mission tab, it looked like i didn't progress in none of the missions, but when i closed the app and reopened it, i could claim all missions."

**What's Happening:**
- Mission progress **IS being tracked correctly** in the background
- Mission progress **IS being saved to SharedPreferences**
- Mission UI **DOES NOT update in real-time** when viewing the missions screen
- Progress only appears after closing and reopening the app

---

## 🔬 Root Cause Analysis

### Current Architecture:

1. **MissionsManager is a Singleton** (`lib/game/systems/missions_manager.dart`)
   - Extends `ChangeNotifier`
   - Initialized once in `main.dart` (line 170, 273)
   - Calls `notifyListeners()` when progress updates (line 541)

2. **Daily Missions Screen** (`lib/ui/screens/daily_missions_screen.dart`)
   - Tries to use `context.watch<MissionsManager>()` (line 416)
   - **BUT: MissionsManager is NOT provided via Provider!**
   - Falls back to `widget.missionsManager` (line 418)
   - Gets manager from `MissionsPage` which passes it as a parameter

3. **The Problem:**
   ```dart
   // Line 416 in daily_missions_screen.dart
   try {
     missionsManager = context.watch<MissionsManager>();  // ❌ FAILS - not in Provider
   } catch (e) {
     missionsManager = widget.missionsManager;  // ✅ Uses singleton instance
   }
   ```

4. **Why It Doesn't Update:**
   - `widget.missionsManager` is the singleton instance
   - Singleton calls `notifyListeners()` when progress updates
   - **BUT: The screen is NOT listening to the notifier!**
   - `context.watch()` fails because MissionsManager isn't in Provider tree
   - Widget parameter doesn't rebuild when notifier changes

5. **Why It Works After Restart:**
   - On restart, missions are loaded from SharedPreferences
   - Initial build shows correct data from storage
   - But real-time updates still don't work

---

## ✅ Solution Options

### Option 1: Add ChangeNotifierProvider (Recommended) ⭐⭐⭐⭐⭐
**Difficulty:** Easy (5 minutes)  
**Risk:** Very Low

Add MissionsManager to Provider tree in `main.dart`:

```dart
// In main.dart after initialization
return MultiProvider(
  providers: [
    ChangeNotifierProvider.value(value: _missions),
    ChangeNotifierProvider.value(value: _achievements),
    // ... other providers
  ],
  child: MaterialApp(...),
);
```

**Pros:**
- Proper Flutter architecture
- Automatic UI updates when missions change
- Works everywhere in the app
- Zero performance impact

**Cons:**
- Requires refactoring main.dart MaterialApp widget

---

### Option 2: Use AnimatedBuilder (Quick Fix) ⭐⭐⭐⭐☆
**Difficulty:** Very Easy (2 minutes)  
**Risk:** None

Wrap the missions list in AnimatedBuilder to listen to the singleton:

```dart
// In daily_missions_screen.dart _buildDailyMissions()
return AnimatedBuilder(
  animation: widget.missionsManager,  // Listen to notifier
  builder: (context, _) {
    final missions = widget.missionsManager.dailyMissions;
    // ... rest of UI code
  },
);
```

**Pros:**
- Immediate fix
- No refactoring needed
- Works with current singleton pattern
- Lightweight

**Cons:**
- Not as elegant as Provider
- Rebuilds entire widget tree on changes

---

### Option 3: Manual Refresh Button ⭐⭐☆☆☆
**Difficulty:** Very Easy (1 minute)  
**Risk:** None

Add a refresh button to manually update:

```dart
IconButton(
  icon: Icon(Icons.refresh),
  onPressed: () => setState(() {}),
)
```

**Pros:**
- Trivial to implement
- Zero risk

**Cons:**
- Poor UX (user has to remember to refresh)
- Doesn't solve the core issue

---

## 🎯 Recommended Solution: **Option 1 + Option 2**

### Phase 1: Quick Fix (Deploy Now) - Option 2
Use `AnimatedBuilder` for immediate fix:

```dart
// lib/ui/screens/daily_missions_screen.dart line 410
Widget _buildDailyMissions(BuildContext context, Size screenSize) {
  return AnimatedBuilder(
    animation: widget.missionsManager,  // ✅ Listen to singleton changes
    builder: (context, _) {
      final missionsManager = widget.missionsManager;
      
      if (!missionsManager.isInitialized) {
        return const Center(child: CircularProgressIndicator(...));
      }
      
      final missions = missionsManager.dailyMissions;
      // ... rest of existing code
    },
  );
}
```

### Phase 2: Proper Architecture (Next Update) - Option 1
Add Provider to app:

```dart
// lib/main.dart after all initialization (line 335+)
return MultiProvider(
  providers: [
    ChangeNotifierProvider.value(value: _missions),
    ChangeNotifierProvider.value(value: _achievements),
  ],
  child: MaterialApp(
    home: HomeNavigatorScreen(
      monetization: _monetization,
      // Remove these parameters - use Provider instead
      // missions: _missions,  ❌ Remove
      // achievements: _achievements,  ❌ Remove
    ),
  ),
);
```

Then update screens to use `context.watch<MissionsManager>()` instead of widget parameters.

---

## 📊 Testing Plan

### Test Case 1: Real-Time Progress
1. Open app, go to Daily Missions tab
2. Keep missions tab open
3. Navigate to Story Mode or Endless Mode
4. Play games (pass obstacles, score points, etc.)
5. Navigate back to Daily Missions tab
6. **Expected:** Progress bars update immediately ✅
7. **Current:** Progress bars stay at 0 ❌

### Test Case 2: Completion
1. Complete a mission while on another screen
2. Navigate to Daily Missions tab
3. **Expected:** Mission shows "Claim Reward" button ✅
4. **Current:** Mission shows no progress ❌

### Test Case 3: Multi-Mission Update
1. Play 5 games in a row
2. Navigate to missions tab
3. **Expected:** All affected missions show progress ✅
4. **Current:** No missions show progress ❌

---

## 🛠️ Implementation Estimate

### Option 2 (Quick Fix):
- **Time:** 5 minutes
- **Files Changed:** 1 (`daily_missions_screen.dart`)
- **Lines Changed:** ~10 lines
- **Risk:** None
- **Testing:** 10 minutes

### Option 1 (Proper Fix):
- **Time:** 30 minutes
- **Files Changed:** 3-4 (`main.dart`, `home_navigator_screen.dart`, `missions_page.dart`, `daily_missions_screen.dart`)
- **Lines Changed:** ~50 lines
- **Risk:** Low (needs thorough testing)
- **Testing:** 20 minutes

---

## 💡 Additional Findings

### Similar Issues in Other Screens:
After fixing missions, check these screens for similar patterns:
1. **Achievements Screen** - Same pattern, same fix needed
2. **Daily Streak** - May have similar issue
3. **Leaderboard** - Check if updates in real-time

### Code Smell Identified:
```dart
// This pattern appears in multiple places:
try {
  manager = context.watch<Manager>();  // Tries Provider
} catch (e) {
  manager = widget.manager;  // Falls back to widget param
}
```

This indicates the app is in **transition** from singleton pattern to Provider pattern but incomplete.

---

## 🚀 Recommendation

**Deploy Option 2 immediately** (5 minutes):
- Quick fix, zero risk
- Solves user's immediate problem
- Can ship in next build

**Plan Option 1 for next major update** (proper architecture):
- Refactor to use Provider throughout
- Remove widget parameter passing
- Cleaner, more maintainable code

---

**Priority:** Medium-High  
**User Impact:** High (confusing UX, looks like a bug)  
**Fix Difficulty:** Very Easy  
**Estimated Total Time:** 15 minutes (fix + test)

