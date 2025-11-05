# 🎯 Max Gap Shift Feature - Constrained Path Generation

## Overview
The `maxGapShift` parameter ensures that story mode levels create **playable, smooth obstacle paths** by limiting how much the gap position can change between consecutive obstacles.

## The Problem
In time-based survival levels, if obstacles spawn at completely random vertical positions, the player might encounter impossible scenarios:
- Obstacle 1 gap at Y=100
- Obstacle 2 gap at Y=500 (spawns 0.65s later)
- **Result:** Player can't physically move that far vertically in time! 💥

## The Solution: `maxGapShift`

### What It Does
Constrains the vertical position of each obstacle's gap based on the previous obstacle's position.

### How It Works

```
Previous Gap Center: Y=300
maxGapShift: 60px

Next gap can be:
- Minimum: Y=240 (300 - 60)
- Maximum: Y=360 (300 + 60)
- Random within this range
```

The gap maintains its size (e.g., 440px), but the **center position** is constrained to ensure smooth, navigable paths.

## Implementation

### 1. Schema Update (`lib/models/level_data_schema.dart`)

```dart
class DifficultyConfig {
  final double speedMultiplier;
  final double obstacleGap;
  final double obstacleFrequency;
  final double? maxGapShift;  // ✨ NEW! Optional constraint

  const DifficultyConfig({
    required this.speedMultiplier,
    required this.obstacleGap,
    required this.obstacleFrequency,
    this.maxGapShift,  // Null = unlimited (endless mode behavior)
  });
}
```

### 2. Path Generation Logic (`lib/game/systems/obstacle_manager.dart`)

**State Tracking:**
```dart
double? _previousGapCenterY;  // Tracks last obstacle's gap center
```

**First Obstacle:**
```dart
if (storyModeMaxGapShift != null && _previousGapCenterY == null) {
  // Start in middle 60% of screen
  final safeMin = screenH * 0.2;
  final safeMax = screenH * 0.8;
  gapY = safeMin + Random().nextDouble() * (safeMax - safeMin);
}
```

**Subsequent Obstacles:**
```dart
if (storyModeMaxGapShift != null && _previousGapCenterY != null) {
  final maxShift = storyModeMaxGapShift!;
  final prevCenter = _previousGapCenterY!;
  
  // Calculate allowed range
  double minCenter = (prevCenter - maxShift).clamp(minAllowed, maxAllowed);
  double maxCenter = (prevCenter + maxShift).clamp(minAllowed, maxAllowed);
  
  // Random position within constrained range
  gapY = minCenter + Random().nextDouble() * (maxCenter - minCenter);
  
  // Track for next obstacle
  _previousGapCenterY = gapY;
}
```

### 3. JSON Configuration

```json
{
  "id": 2,
  "name": "Palm Paradise Path",
  "objective": {
    "type": "surviveTime",
    "target": 25
  },
  "difficulty": {
    "speedMultiplier": 0.9,
    "obstacleGap": 440,
    "obstacleFrequency": 0.65,
    "maxGapShift": 60  // ✨ NEW! Smooth corridor
  }
}
```

## Recommended Values

### Tight Corridor (Beginner)
```json
"maxGapShift": 50
```
- Very smooth, gentle path
- Easy to predict and navigate
- Good for tutorial/early levels

### Flowing Path (Intermediate)
```json
"maxGapShift": 80
```
- Moderate variance
- Requires attention but stays fair
- Good for mid-game challenges

### Dynamic Path (Advanced)
```json
"maxGapShift": 120
```
- High variance but still possible
- Requires quick reactions
- Good for late-game difficulty

### No Constraint (Endless Mode)
```json
"maxGapShift": null  // or omit the field
```
- Completely random (current endless mode behavior)
- Maximum replayability and variety

## Why Pixels Instead of Percentage?

The constraint is based on **player physics** (vertical movement speed), not gap size:

- Player vertical speed is **constant** (~300-400 px/s)
- Spawn frequency is **known** (e.g., 0.65s)
- Therefore, max reachable distance is fixed

Using a percentage of gap size (440px × 10% = 44px) would create inconsistent difficulty across levels with different gap sizes.

## Debug Logging

The system provides detailed debug output:

```
🎯 PATH: first obstacle at 350 (maxShift=60)
🎯 PATH: prev=350, shift=+42, max=±60
🎯 PATH: prev=392, shift=-55, max=±60
🎯 PATH: prev=337, shift=+18, max=±60
```

Shows:
- Previous gap center
- Actual shift amount
- Configured max shift

## Benefits

✅ **Guaranteed Playability** - No impossible jumps  
✅ **Design Control** - Precise difficulty tuning per level  
✅ **Smooth Experience** - Flowing, learnable paths  
✅ **Maintains Variety** - Still random within constraints  
✅ **Optional Feature** - Doesn't affect endless mode  

## Usage Example

**Level 2: "Palm Paradise Path"**
- Time-based survival (25 seconds)
- Large gap (440px) for forgiveness
- Frequent obstacles (0.65s)
- **Smooth path** (maxShift: 60px)

Result: A gentle, flowing corridor that's challenging but always fair!

## Future Enhancements

Potential additions:
- `minGapShift`: Force minimum variance (prevent boring straight paths)
- `gapShiftCurve`: Gradually increase variance over time
- `pathPreset`: "sine_wave", "zigzag", "stairs" patterns
- `adaptiveShift`: Adjust based on player performance

---

**Status:** ✅ Implemented and ready for testing!  
**Test Level:** Level 2 (Palm Paradise Path) with `maxGapShift: 60`

