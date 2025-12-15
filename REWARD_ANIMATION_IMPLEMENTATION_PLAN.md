# Reward Flying Animation Implementation Plan

## Overview
Replace the reward claim popup with a smooth coin/gem flying animation from the card to the balance display.

## Current Flow Analysis

### Event Firing (CRITICAL - Must Preserve)
✅ **Events are fired at Manager level, NOT in UI:**
- `mission_completed` event: Fired in `MissionsManager.claimMissionReward()` (line 992)
- `achievement_claimed` event: Fired in `AchievementsManager.claimAchievementReward()` (line 1254)
- **These will NOT be affected by removing the popup** ✅

### Current Claim Flow
1. User clicks "Claim" → `UnifiedRewardCard.onClaimReward`
2. `daily_missions_screen.dart._claimReward()` called
3. `MissionsManager.claimMissionReward()` called (fires event ✅)
4. `RewardClaimPopup` shown (blocking dialog)
5. User closes popup
6. Card updates to "claimed" state

## Implementation Steps

### Phase 1: Create Animation Widget
**File:** `lib/ui/widgets/animations/reward_flying_animation.dart`
- Create reusable `RewardFlyingAnimation` widget
- Supports both coins and gems
- Uses `AnimationController` with `Tween<Offset>` for position
- Includes scale/rotation effects for polish
- Duration: 800ms with `Curves.easeOut`

### Phase 2: Add Position Tracking
**Files:**
- `lib/ui/widgets/rewards/unified_reward_card.dart` - Add `GlobalKey` to reward icon
- `lib/ui/screens/daily_missions_screen.dart` - Add `GlobalKey` to `CoinsGemsDisplay`

### Phase 3: Integrate Animation
**File:** `lib/ui/screens/daily_missions_screen.dart`
- Modify `_claimReward()` to:
  1. Get source position (reward icon)
  2. Get target position (balance display)
  3. Trigger animation
  4. Grant reward (events fire automatically ✅)
  5. Remove card after animation
- Modify `_claimAchievementReward()` similarly

### Phase 4: Testing
- Test single claim (mission)
- Test single claim (achievement)
- Test multiple rapid claims (queue handling)
- Test with different screen sizes
- Test with scroll position changes
- Verify events still fire (check logs)
- Verify balance updates correctly

## Technical Details

### Animation Widget API
```dart
RewardFlyingAnimation({
  required Offset startPosition,
  required Offset endPosition,
  required RewardType type, // coin or gem
  required int amount,
  required VoidCallback onComplete,
})
```

### Position Calculation
- Use `GlobalKey` + `RenderBox.localToGlobal(Offset.zero)`
- Wait for layout with `WidgetsBinding.instance.addPostFrameCallback()`
- Account for scroll offset if needed

### Animation Queue
- Use `List<AnimationTask>` to queue multiple animations
- Process one at a time with slight delay between

## Risk Mitigation

### Event Firing
✅ **SAFE** - Events fire in manager methods, not UI
- `mission_completed`: `MissionsManager.claimMissionReward()` line 992
- `achievement_claimed`: `AchievementsManager.claimAchievementReward()` line 1254

### Performance
- Limit concurrent animations (max 2)
- Dispose controllers properly
- Use `AnimatedBuilder` instead of `setState`

### Edge Cases
- Layout not ready → Wait with `addPostFrameCallback`
- Widget disposed → Check `mounted` before operations
- Scroll position → Use `Scrollable.of(context)`
- Multiple claims → Queue animations

## Progress Tracking

- [x] Phase 1: Create Animation Widget ✅
- [x] Phase 2: Add Position Tracking ✅
- [x] Phase 3: Integrate Animation ✅
- [ ] Phase 4: Testing

## Event Firing Verification ✅

**CRITICAL:** Events are fired at Manager level, NOT in UI:

1. **`mission_completed` event:**
   - Location: `MissionsManager.claimMissionReward()` line 992
   - Fires: `eventBus.fire('mission_completed', {...})`
   - ✅ **NOT affected by removing popup** - fires before UI changes

2. **`achievement_claimed` event:**
   - Location: `AchievementsManager.claimAchievementReward()` line 1254
   - Fires: `eventBus.fire('achievement_claimed', {...})`
   - ✅ **NOT affected by removing popup** - fires before UI changes

**Flow:**
1. User clicks "Claim" → `_claimReward()` called
2. `MissionsManager.claimMissionReward()` called
3. **Event fires here** ✅ (line 992)
4. Reward granted via `InventoryManager`
5. Animation triggered (NEW)
6. Card removed from list

**Conclusion:** ✅ All events are preserved - no events lost!

