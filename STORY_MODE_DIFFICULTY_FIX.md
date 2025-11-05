# Story Mode Difficulty Fix

## Issue Summary
The story mode level difficulty settings (`obstacleFrequency`, `obstacleGap`, `speedMultiplier`) defined in the JSON level data were not being applied to the game. The game was using hardcoded difficulty values from `GameConfig` and `DifficultySystem` instead.

## Root Cause
The `ObstacleManager` class was using score-based difficulty calculations from `GameConfig.getSpawnInterval()` and `DifficultySystem` for ALL games (both endless and story mode), completely ignoring the level-specific difficulty configuration from `LevelData.difficulty`.

## Changes Made

### 1. Updated `ObstacleManager` (`lib/game/systems/obstacle_manager.dart`)
Added three new fields to support story mode difficulty overrides:
```dart
// 🎯 STORY MODE: Override difficulty settings for story mode levels
double? storyModeObstacleFrequency;  // Seconds between obstacles
double? storyModeObstacleGap;        // Gap size in pixels
double? storyModeSpeedMultiplier;    // Speed multiplier
```

Modified the `update()` method to use story mode frequency when set:
```dart
// 🎯 STORY MODE: Use story mode frequency if set, otherwise use score-based interval
final spawnInterval = storyModeObstacleFrequency ?? GameConfig.getSpawnInterval(score);
```

Modified `_spawnObstacle()` to branch between story mode and endless mode difficulty:
```dart
if (storyModeObstacleGap != null && storyModeSpeedMultiplier != null) {
  // Story mode: Use fixed level settings
  gap = storyModeObstacleGap!;
  speed = DifficultySystem.getBaseObstacleSpeed() * storyModeSpeedMultiplier!;
} else {
  // Endless mode: Use continuous difficulty curves + variance + breathers
  gap = DifficultySystem.getGapRatioContinuous(score) * screenH;
  speed = DifficultySystem.getBaseSpeedContinuous(score);
  // ... (existing endless mode logic)
}
```

### 2. Updated `FlappyGame` (`lib/game/flappy_game.dart`)
Modified the story mode initialization to pass difficulty settings to the obstacle manager:
```dart
// 🎯 STORY MODE: Set story mode obstacle asset and difficulty settings if in story mode
if (isStoryMode && storyModeLevel != null) {
  _obstacleManager.storyModeObstacleAsset = 'obstacles/${storyModeLevel!.theme.obstacles}';
  _obstacleManager.storyModeObstacleFrequency = storyModeLevel!.difficulty.obstacleFrequency;
  _obstacleManager.storyModeObstacleGap = storyModeLevel!.difficulty.obstacleGap;
  _obstacleManager.storyModeSpeedMultiplier = storyModeLevel!.difficulty.speedMultiplier;
  
  safePrint('🎯 STORY MODE: Applying level difficulty - gap=${storyModeLevel!.difficulty.obstacleGap}, freq=${storyModeLevel!.difficulty.obstacleFrequency}s, speed=${storyModeLevel!.difficulty.speedMultiplier}x');
}
```

### 3. Fixed Level 2 Configuration
Updated Level 2 (`Palm Paradise Path`) `obstacleFrequency` to `0.65` seconds as requested:
- Original design: `1.3s` (obstacles every 1.3 seconds)
- User request: "reduce frequency by half to see more obstacles"
- New value: `0.65s` (obstacles every 0.65 seconds = twice as frequent)

## How Difficulty Settings Work

### Obstacle Frequency
- **Lower value** = MORE frequent obstacles (e.g., `0.65s` = obstacles every 0.65 seconds)
- **Higher value** = LESS frequent obstacles (e.g., `3.0s` = obstacles every 3 seconds)

### Obstacle Gap
- Measured in pixels
- Smaller gap = harder (e.g., `175px`)
- Larger gap = easier (e.g., `195px`)

### Speed Multiplier
- Multiplies the base obstacle speed (`200 px/s`)
- `0.9x` = 10% slower (easier)
- `1.0x` = normal speed
- `1.2x` = 20% faster (harder)

## Example: Level 2 Configuration
```json
{
  "id": 2,
  "name": "Palm Paradise Path",
  "objective": {
    "type": "surviveTime",
    "target": 25,
    "description": "Survive for 25 seconds"
  },
  "difficulty": {
    "speedMultiplier": 0.9,      // 10% slower obstacles
    "obstacleGap": 195,           // Large gap (easier)
    "obstacleFrequency": 0.65     // Obstacles every 0.65s (frequent!)
  }
}
```

## Testing
To verify the fix is working, look for this log message when starting a story mode level:
```
🎯 STORY MODE: Applying level difficulty - gap=195.0, freq=0.65s, speed=0.9x
```

And when obstacles spawn:
```
🎯 STORY MODE OBSTACLE: gap=195.0, speed=180.0, freq=0.65s
```

## Impact
- ✅ Story mode levels now use their configured difficulty settings
- ✅ Endless mode continues to use dynamic difficulty progression
- ✅ Each level can have unique challenge characteristics
- ✅ Level designers have full control over obstacle behavior per level

