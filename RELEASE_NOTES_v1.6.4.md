# 🎮 FlappyJet Pro - Release Notes v1.6.4

**Release Date**: October 16, 2025
**Build Number**: 48

---

## 🎯 **STORY MODE IMPROVEMENTS & BUG FIXES**

### **✨ New Features**
- **Hearts Display Fix**: Hearts now correctly display after using continue (via ad or gems) and completing levels
- **Hearts Refill on Level Completion**: Successfully completing a story mode level now refills hearts to maximum
- **Next Level Button on Replays**: Replay levels now show "Play Next Level" button if a next level exists

### **🐛 Bug Fixes**

#### **Hearts Management**
- **FIXED**: Hearts showing as 0 after continuing with ad and completing level
- **FIXED**: Hearts showing as 0 after continuing with gems and completing level
- **FIXED**: Hearts not being restored when using continue option
- **FIXED**: Hearts now refill to max after successful level completion

#### **Level Progression**
- **FIXED**: Zone 3 level 21 being unclickable after completing zone 2
- **FIXED**: Zone unlock validation now properly unlocks first level of new zones
- **FIXED**: Auto-advance to next zone now correctly updates `highestLevelUnlocked`

#### **UI/UX Improvements**
- **FIXED**: Bot name "Magma Fracture" changed to "Molten Devastator" in level 21
- **FIXED**: 11-pixel overflow in level objective popup (VS battle display)
- **FIXED**: Zone completion celebration screen overflow (all zones)
- **FIXED**: Level failed screen overflow (5.6 pixels)
- **FIXED**: Gem icon now uses custom PNG instead of generic diamond icon

#### **Duplicate Jet Bug**
- **FIXED**: Additional jet appearing after continue via ad
- **FIXED**: Additional jet appearing after continue via gems
- **CHANGED**: `resetGame()` → `continueGame()` for proper state restoration

### **🧹 Code Cleanup**
- Removed unused imports across 10+ files
- Removed unused variables and fields (analytics, particles, social sharing)
- Removed unused methods (`_generateCompetitiveLeaderboard`, `_getPlatformString`)
- Deleted broken/unused files (`skin_restoration_test.dart`, `notification_settings_widget.dart`)
- Applied `dart fix --apply` for linter warnings
- Removed deprecated backup files

### **📦 Technical Changes**
- Added `LivesManager` import to `story_mode_game_wrapper.dart`
- Updated `_onLevelCompleted()` to refill hearts asynchronously
- Updated continue handlers to restore 1 heart in `LivesManager`
- Added `_validateAndFixZoneUnlocks()` method for progress consistency
- Improved zone navigation logic in `WorldMapScreen`

### **🔄 Navigation Improvements**
- Story mode button now navigates directly to current zone
- "Back to Map" returns to the zone containing player's current level
- Zone dropdown correctly reflects player progression

---

## 📊 **Version History**
- **v1.6.4+48**: Story mode hearts management & progression fixes
- **v1.6.3+47**: Story mode implementation Phase 1 complete
- **v1.6.2+46**: Story mode core systems integration

---

## 🎯 **Next Release (v1.7.0)**
**Planned Major Refactoring**: Flame Game Engine Optimization
- Migrate to Flame's native collision detection system
- Implement Behavior pattern for component logic
- Add Flame's Effect system for animations
- Performance optimizations (vector pooling, quadtree collision)

---

**Build Configuration**:
- Flutter SDK: 3.16.0+
- Dart SDK: 3.8.0+
- Flame Engine: 1.32.0
- Target Platforms: iOS 12.0+, Android API 21+

