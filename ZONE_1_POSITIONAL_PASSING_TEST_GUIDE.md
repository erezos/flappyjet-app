# 🎯 Zone 1 Positional Passing - Manual Testing Guide

## Overview

This feature awards points for obstacles that were **positionally passed** (jet's X position > obstacle's right edge) even if the player crashes **without passing through the gap**. This only applies to:

- **Zone 1 levels only**
- **"Pass X Obstacles" objectives** (`ObjectiveType.passObstacles`)
- **"1 vs 1" objectives** (`ObjectiveType.beatBot`)

## How It Works

1. **Normal scoring**: Player passes through gap → `ScoreZone` collision → point awarded
2. **Positional passing**: Player's jet passes obstacle's right edge (X position) → point awarded on crash (even if crashed before gap)

## Testing Instructions

### Prerequisites
- Android Emulator or iOS Simulator
- Flutter app running in debug mode
- Access to Zone 1 story mode levels

### Test Scenario 1: Pass Obstacles Objective

1. **Start a Zone 1 level** with "Pass X Obstacles" objective
   - Navigate to Story Mode → Zone 1
   - Select any level with "Pass X Obstacles" objective

2. **Play until you pass at least 1 obstacle positionally**
   - Fly forward and pass obstacles (your jet's X position goes past obstacle's right edge)
   - **Important**: Crash **before** passing through the gap
   - You should see obstacles moving left past your jet

3. **Verify points are awarded**
   - Check the objective progress indicator
   - It should show points for obstacles you positionally passed
   - Example: If you passed 3 obstacles positionally, you should see +3 progress

4. **Check console logs** (if running in debug mode)
   - Look for: `🎯 ZONE 1: Awarding X positional passing points on crash.`
   - Look for: `🎯 ZONE 1: Progress incremented via positional passing: X/Y`

### Test Scenario 2: 1 vs 1 Objective

1. **Start a Zone 1 level** with "1 vs 1" objective
   - Navigate to Story Mode → Zone 1
   - Select a level with "Beat Bot" objective

2. **Play and pass obstacles positionally**
   - Fly forward and pass obstacles
   - Crash before passing through gaps

3. **Verify score increases**
   - Check your score in the HUD
   - Score should increase for each positionally passed obstacle
   - Bot's score should remain unchanged (you didn't pass through gaps)

4. **Check console logs**
   - Look for: `🎯 ZONE 1: Bot battle score incremented via positional passing: X`

### Test Scenario 3: No Double Scoring

1. **Start a Zone 1 level**
2. **Pass an obstacle through the gap** (normal scoring)
3. **Crash immediately after**
4. **Verify**: That obstacle should NOT be counted again via positional passing
   - Console should show: `🎯 ZONE 1: Found 0 unscored positionally passed obstacles`
   - Or the obstacle should be excluded from positional passing count

### Test Scenario 4: Zone 2+ (Should NOT Work)

1. **Start a Zone 2 or higher level**
2. **Pass obstacles positionally and crash**
3. **Verify**: No points should be awarded for positional passing
   - Console should NOT show Zone 1 positional passing logs
   - Only obstacles passed through gaps should count

### Test Scenario 5: Other Objective Types (Should NOT Work)

1. **Start a Zone 1 level** with "Survive X Seconds" or other objective type
2. **Pass obstacles positionally and crash**
3. **Verify**: No points should be awarded for positional passing
   - Only applies to `passObstacles` and `beatBot` objectives

## Expected Console Logs

When the feature is working correctly, you should see:

```
🎯 ZONE 1: Found X unscored positionally passed obstacles
🎯 ZONE 1: Awarding X positional passing points on crash.
🎯 ZONE 1: Progress incremented via positional passing: X/Y
```

Or for bot battles:

```
🎯 ZONE 1: Bot battle score incremented via positional passing: X
```

## Performance Verification

The feature uses an **event-driven approach** (only checks on crash, not every frame):

- ✅ **No performance impact** during normal gameplay
- ✅ **Only runs on crash** (rare event)
- ✅ **O(n) complexity** only when needed

You can verify this by:
1. Playing normally (no crashes) → no positional passing checks
2. Crashing → one-time check of all obstacles

## Troubleshooting

### Issue: Points not awarded
- **Check**: Are you in Zone 1?
- **Check**: Is the objective type `passObstacles` or `beatBot`?
- **Check**: Did you actually pass obstacles positionally (jet X > obstacle right edge)?
- **Check**: Console logs for errors

### Issue: Double scoring
- **Check**: Are obstacles marked as `scored` after passing through gap?
- **Check**: Console logs should show "Found 0 unscored" if all obstacles were scored normally

### Issue: Works in Zone 2+
- **Bug**: This should only work in Zone 1
- **Report**: Include console logs and level details

## Success Criteria

✅ Points are awarded for positionally passed obstacles in Zone 1  
✅ Only works for `passObstacles` and `beatBot` objectives  
✅ Does NOT work in Zone 2+  
✅ Does NOT double-count obstacles passed through gaps  
✅ No performance impact during normal gameplay  

