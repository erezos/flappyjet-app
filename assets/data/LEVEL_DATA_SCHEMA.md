# 📋 **LEVEL DATA SCHEMA DOCUMENTATION**

## Overview
This document defines the JSON schema for FlappyJet Story Mode levels.

---

## **Level JSON Structure**

```json
{
  "id": 1,                    // Unique level ID (1-100)
  "zone": 1,                  // Zone number (1-10)
  "name": "First Flight",     // Display name
  "objective": {              // What player must do to complete
    "type": "passObstacles",  // passObstacles | surviveTime | beatBot
    "target": 3,              // Number to achieve (3 obstacles, 15 seconds, etc.)
    "description": "Pass 3 obstacles to complete"
  },
  "difficulty": {             // Gameplay parameters
    "speedMultiplier": 1.0,   // 1.0 = normal, 1.5 = 50% faster
    "obstacleGap": 180,       // Pixels between top/bottom obstacles
    "obstacleFrequency": 2.5  // Seconds between obstacles
  },
  "reward": {                 // What player earns on completion
    "coins": 20,              // Coin reward
    "gems": 0,                // Gem reward (usually 0, except every 10th level)
    "specialReward": null     // Optional: "exclusive_skin_frozen_ace"
  },
  "theme": {                  // Visual/audio assets
    "background": "phase1_dawn_complete.png",
    "obstacles": "phase1_wooden_pipes.png",
    "music": "sky_rookie.mp3",
    "particleEffect": null    // Optional: "snow", "rain", etc.
  },
  "botBattle": null           // Null for normal levels, object for bot battles
}
```

---

## **Bot Battle Structure**

For levels with bot battles (every 7th level), add:

```json
"botBattle": {
  "botName": "Beach Buddy",      // Display name
  "botJetSkin": "green_lightning", // Jet skin ID
  "skillLevel": 0.6,             // 0.6-1.5 (60%-150% of perfect play)
  "reactionTime": 0.4,           // 0.1-0.5 seconds delay
  "mistakeRate": 0.15            // 0.02-0.20 (2%-20% chance of mistakes)
}
```

---

## **Objective Types**

### 1. **Pass Obstacles**
```json
"objective": {
  "type": "passObstacles",
  "target": 5,
  "description": "Pass 5 obstacles to complete"
}
```
- Player must successfully pass X obstacles
- Most common objective type (60% of levels)

### 2. **Survive Time**
```json
"objective": {
  "type": "surviveTime",
  "target": 30,
  "description": "Survive for 30 seconds"
}
```
- Player must stay alive for X seconds
- Used for endurance challenges (20% of levels)

### 3. **Beat Bot**
```json
"objective": {
  "type": "beatBot",
  "target": 1,
  "description": "Beat Beach Buddy in a race!"
}
```
- Player must pass more obstacles than the bot
- Used for competitive levels (15% of levels)
- Requires `botBattle` object

---

## **Difficulty Progression**

| Level Range | Speed | Gap | Frequency | Objective Range |
|-------------|-------|-----|-----------|----------------|
| 1-10 | 1.0x | 180px | 2.5s | 3-10 obstacles |
| 11-20 | 1.1x | 170px | 2.3s | 5-12 obstacles |
| 21-30 | 1.2x | 160px | 2.1s | 8-15 obstacles |
| 31-40 | 1.3x | 150px | 1.9s | 10-20 obstacles |
| 41-50 | 1.4x | 145px | 1.8s | 12-25 obstacles |

---

## **Reward Formula**

### Coins
- Levels 1-10: 20 coins
- Levels 11-20: 40 coins
- Levels 21-30: 60 coins
- Levels 31-40: 80 coins
- Levels 41-50: 100 coins
- **Bot battles: 2x coins** (e.g., 40 instead of 20)

### Gems
- Every 10th level: 10-30 gems (increases by 5 per zone)
- Level 10: 10 gems
- Level 20: 15 gems
- Level 30: 20 gems
- Level 40: 25 gems
- Level 50: 30 gems + exclusive skin

---

## **Theme Assets**

### Backgrounds (8 available)
- `phase1_dawn_complete.png` - Tropical (Zone 1)
- `phase2_sunny_complete.png` - Desert (Zone 2)
- `phase3_afternoon_complete.png` - Lava (Zone 3)
- `phase4_storm_complete.png` - Storm (Zone 4)
- `phase5_lightning_complete.png` - (can reuse)
- `phase6_altitude_complete.png` - Frozen (Zone 5)
- `phase7_stratosphere_complete.png` - (future)
- `phase8_cosmic_complete.png` - (future)

### Obstacles (8 available)
- `phase1_wooden_pipes.png` - Zone 1
- `phase2_reinforced_wood.png` - Zone 2
- `phase3_stone_pillars.png` - Zone 3
- `phase4_stone_towers.png` - (can reuse)
- `phase5_metal_lightning.png` - Zone 4
- `phase6_tech_structures.png` - Zone 5
- `phase7_crystal_energy.png` - (future)
- `phase8_energy_barriers.png` - (future)

### Music (5 available)
- `sky_rookie.mp3` - Zone 1
- `space_cadet.mp3` - Zone 2
- `storm_ace.mp3` - Zone 3
- `void_master.mp3` - Zone 4
- `legend.mp3` - Zone 5

---

## **Validation Rules**

### Required Fields
- `id` (integer, 1-100)
- `zone` (integer, 1-10)
- `name` (string, 3-50 characters)
- `objective` (object with type, target, description)
- `difficulty` (object with speedMultiplier, obstacleGap, obstacleFrequency)
- `reward` (object with coins, gems)
- `theme` (object with background, obstacles, music)

### Optional Fields
- `reward.specialReward` (string or null)
- `theme.particleEffect` (string or null)
- `botBattle` (object or null)

### Constraints
- `id` must be unique
- `zone` must match level range (1-10 = zone 1, 11-20 = zone 2, etc.)
- `objective.target` must be > 0
- `difficulty.speedMultiplier` must be 0.5-2.0
- `difficulty.obstacleGap` must be 100-250
- `difficulty.obstacleFrequency` must be 1.0-5.0
- `reward.coins` must be 0-1000
- `reward.gems` must be 0-100
- If `objective.type` is "beatBot", `botBattle` must not be null

---

## **Example: Complete Level**

```json
{
  "id": 7,
  "zone": 1,
  "name": "Beach Buddy Showdown",
  "objective": {
    "type": "beatBot",
    "target": 1,
    "description": "Beat Beach Buddy in a race!"
  },
  "difficulty": {
    "speedMultiplier": 1.05,
    "obstacleGap": 175,
    "obstacleFrequency": 2.4
  },
  "reward": {
    "coins": 40,
    "gems": 0
  },
  "theme": {
    "background": "phase1_dawn_complete.png",
    "obstacles": "phase1_wooden_pipes.png",
    "music": "sky_rookie.mp3"
  },
  "botBattle": {
    "botName": "Beach Buddy",
    "botJetSkin": "green_lightning",
    "skillLevel": 0.6,
    "reactionTime": 0.4,
    "mistakeRate": 0.15
  }
}
```

---

## **Zone Metadata Schema**

```json
{
  "id": 1,
  "name": "Tropical Islands",
  "description": "Begin your journey through sunny beaches and palm trees",
  "startLevel": 1,
  "endLevel": 10,
  "iconPath": "icons/zone_tropical.png"
}
```

---

**Last Updated:** October 5, 2025
**Version:** 1.0
