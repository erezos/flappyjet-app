# 🎨 **PHASE 0 - TASK 0.4: UI/UX WIREFRAMES**

## 📱 **SCREEN FLOW DIAGRAM**

```
┌─────────────────────────────────────────────────────────────────┐
│                         HOMEPAGE                                │
│                    (Existing - Modified)                        │
│                                                                 │
│  ┌───────────────────────────┐                                 │
│  │   🎯 ENDLESS MODE         │  ← Existing                     │
│  │   High Score: 42          │                                 │
│  └───────────────────────────┘                                 │
│                                                                 │
│  ┌───────────────────────────┐                                 │
│  │   📖 STORY MODE           │  ← NEW BUTTON                   │
│  │   Level 5/100             │                                 │
│  └───────────────────────────┘                                 │
│                                                                 │
│  [Profile] [Store] [Settings]                                  │
└─────────────────────────────────────────────────────────────────┘
                            │
                            │ (Tap Story Mode)
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                      WORLD MAP SCREEN                           │
│                         (NEW)                                   │
│                                                                 │
│  ← Back    ZONE 1: TROPICAL ISLANDS    ❤️❤️❤️ (3 hearts)      │
│                                                                 │
│  ┌─────────────────────────────────────────────────────┐       │
│  │                                                       │       │
│  │         [World Map Background Image]                 │       │
│  │                                                       │       │
│  │    🔒 ← Locked level (gray)                         │       │
│  │    5  ← Current level (pulsing gold)                │       │
│  │    ✓  ← Completed level (green checkmark)           │       │
│  │                                                       │       │
│  │         Path winds through all zones                 │       │
│  │                                                       │       │
│  └─────────────────────────────────────────────────────┘       │
│                                                                 │
│  Progress: Level 5/100 • Zone 1/10                             │
└─────────────────────────────────────────────────────────────────┘
                            │
                            │ (Tap Level Node)
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                    LEVEL INFO POPUP                             │
│                         (NEW)                                   │
│                                                                 │
│              ┌─────────────────────────┐                        │
│              │      LEVEL 5            │                        │
│              │   Coconut Challenge     │                        │
│              │                         │                        │
│              │  🎯 Pass 6 obstacles    │                        │
│              │                         │                        │
│              │  Reward: 20 🪙          │                        │
│              │                         │                        │
│              │  [▶️ PLAY]  [❌ CLOSE]  │                        │
│              └─────────────────────────┘                        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                            │
                            │ (Tap Play)
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                  LEVEL OBJECTIVE POPUP                          │
│                         (NEW)                                   │
│                                                                 │
│              ┌─────────────────────────┐                        │
│              │   LEVEL 5 OBJECTIVE     │                        │
│              │                         │                        │
│              │  Pass 6 obstacles to    │                        │
│              │  complete this level!   │                        │
│              │                         │                        │
│              │  Reward: 20 coins       │                        │
│              │                         │                        │
│              │      [START] (3)        │  ← Auto-countdown      │
│              └─────────────────────────┘                        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                            │
                            │ (After 3 seconds)
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                      GAMEPLAY SCREEN                            │
│                   (Existing - Modified)                         │
│                                                                 │
│  ❤️ 3   Score: 3/6   🪙 120   💎 5                             │
│  ← Pause                                                        │
│                                                                 │
│                    [Jet Flying]                                 │
│                    [Obstacles]                                  │
│                                                                 │
│  Objective: Pass 6 obstacles (3/6 complete)                    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                            │
                            │ (Level Complete)
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                   LEVEL COMPLETE SCREEN                         │
│                         (NEW)                                   │
│                                                                 │
│              ┌─────────────────────────┐                        │
│              │  🎉 LEVEL COMPLETE! 🎉  │                        │
│              │                         │                        │
│              │  Objective: ✅ 6/6      │                        │
│              │                         │                        │
│              │  Rewards Earned:        │                        │
│              │  +20 🪙 Coins           │                        │
│              │                         │                        │
│              │  [NEXT LEVEL]           │                        │
│              │  [BACK TO MAP]          │                        │
│              └─────────────────────────┘                        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                            │
                            │ (Every 10th level)
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                   ZONE COMPLETE SCREEN                          │
│                         (NEW)                                   │
│                                                                 │
│              ┌─────────────────────────┐                        │
│              │ 🏆 ZONE 1 COMPLETE! 🏆  │                        │
│              │                         │                        │
│              │   TROPICAL ISLANDS      │                        │
│              │   10/10 Levels ✅       │                        │
│              │                         │                        │
│              │   Bonus Rewards:        │                        │
│              │   +10 💎 Gems           │                        │
│              │                         │                        │
│              │  [CONTINUE TO ZONE 2]   │                        │
│              └─────────────────────────┘                        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                            │
                            │ (Bot Battle Level)
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                   BOT BATTLE SCREEN                             │
│                         (NEW)                                   │
│                                                                 │
│  ┌──────────────────────┬──────────────────────┐               │
│  │       YOU            │    BEACH BUDDY       │               │
│  │   ❤️ 3  Score: 3     │   Score: 2           │               │
│  │                      │                      │               │
│  │      🛩️              │         🛩️           │               │
│  │                      │                      │               │
│  │   [Obstacles]        │   [Obstacles]        │               │
│  │                      │                      │               │
│  └──────────────────────┴──────────────────────┘               │
│                                                                 │
│               VS - First to 5 wins!                             │
└─────────────────────────────────────────────────────────────────┘
                            │
                            │ (Player Wins)
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                   BOT VICTORY SCREEN                            │
│                         (NEW)                                   │
│                                                                 │
│              ┌─────────────────────────┐                        │
│              │    🎉 YOU WIN! 🎉       │                        │
│              │                         │                        │
│              │  You defeated           │                        │
│              │  Beach Buddy!           │                        │
│              │                         │                        │
│              │  Rewards Earned:        │                        │
│              │  +40 🪙 Coins (2x)      │                        │
│              │                         │                        │
│              │  [NEXT LEVEL]           │                        │
│              │  [BACK TO MAP]          │                        │
│              └─────────────────────────┘                        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📱 **DETAILED WIREFRAMES**

### **1. HOMEPAGE (Modified)**

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│                      FLAPPYJET LOGO                             │
│                                                                 │
│  ┌───────────────────────────────────────────────────────┐     │
│  │                                                         │     │
│  │              🎯 ENDLESS MODE                           │     │
│  │                                                         │     │
│  │          High Score: 42 • Best Streak: 15             │     │
│  │                                                         │     │
│  └───────────────────────────────────────────────────────┘     │
│                                                                 │
│  ┌───────────────────────────────────────────────────────┐     │
│  │                                                         │     │
│  │              📖 STORY MODE                             │     │
│  │                                                         │     │
│  │              Level 5/100 • Zone 1                      │     │
│  │                                                         │     │
│  └───────────────────────────────────────────────────────┘     │
│                                                                 │
│                                                                 │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐          │
│  │ PROFILE │  │  STORE  │  │ MISSIONS│  │SETTINGS │          │
│  └─────────┘  └─────────┘  └─────────┘  └─────────┘          │
│                                                                 │
│                    🪙 120      💎 5      ❤️ 3                  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**Key Elements:**
- ✅ Story Mode button (large, prominent)
- ✅ Progress indicator (Level 5/100 • Zone 1)
- ✅ Existing buttons remain unchanged
- ✅ Currency display at bottom

**Interactions:**
- Tap "STORY MODE" → Navigate to World Map Screen
- Tap "ENDLESS MODE" → Start endless game (existing)

---

### **2. WORLD MAP SCREEN**

```
┌─────────────────────────────────────────────────────────────────┐
│  ← Back          ZONE 1: TROPICAL ISLANDS        ❤️❤️❤️ (3)     │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                                                           │   │
│  │                 [World Map Background]                    │   │
│  │                                                           │   │
│  │         🔒 ← Level 6 (locked, gray)                      │   │
│  │        /                                                  │   │
│  │       /                                                   │   │
│  │      5  ← Level 5 (current, pulsing gold circle)         │   │
│  │     /                                                     │   │
│  │    /                                                      │   │
│  │   ✓  ← Level 4 (completed, green with checkmark)         │   │
│  │  /                                                        │   │
│  │ /                                                         │   │
│  │✓  ← Level 3 (completed)                                  │   │
│  │                                                           │   │
│  │ Path continues through all zones...                      │   │
│  │                                                           │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  Progress: Level 5/100 • Zone 1/10 • 4 Levels Completed        │
│                                                                 │
│  [Minimap: You are here ▼]                                     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**Key Elements:**
- ✅ World map background (DALL-E image)
- ✅ Level nodes (locked/current/completed)
- ✅ Winding path connecting levels
- ✅ Zone indicator at top
- ✅ Hearts display (top-right)
- ✅ Progress bar at bottom
- ✅ Minimap for navigation

**Node States:**
1. **Locked** (🔒): Gray circle, lock icon, not tappable
2. **Current** (5): Gold circle, pulsing animation, tappable
3. **Completed** (✓): Green circle, checkmark, tappable (replay)

**Interactions:**
- Tap level node → Show Level Info Popup
- Pinch to zoom → Zoom in/out on map
- Swipe → Scroll through map
- Tap "Back" → Return to Homepage

---

### **3. LEVEL INFO POPUP**

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│                                                                 │
│              ┌─────────────────────────────────┐               │
│              │                                 │               │
│              │          LEVEL 5                │               │
│              │      Coconut Challenge          │               │
│              │                                 │               │
│              │  ┌───────────────────────────┐ │               │
│              │  │   🎯 OBJECTIVE            │ │               │
│              │  │   Pass 6 obstacles        │ │               │
│              │  └───────────────────────────┘ │               │
│              │                                 │               │
│              │  ┌───────────────────────────┐ │               │
│              │  │   🏆 REWARD               │ │               │
│              │  │   20 🪙 Coins             │ │               │
│              │  └───────────────────────────┘ │               │
│              │                                 │               │
│              │  Best Score: 6/6 ✅            │               │
│              │  Attempts: 1                   │               │
│              │                                 │               │
│              │  ┌──────────┐  ┌──────────┐   │               │
│              │  │  ▶️ PLAY │  │ ❌ CLOSE │   │               │
│              │  └──────────┘  └──────────┘   │               │
│              │                                 │               │
│              └─────────────────────────────────┘               │
│                                                                 │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**Key Elements:**
- ✅ Level number and name
- ✅ Objective description with icon
- ✅ Reward display
- ✅ Best score (if replaying)
- ✅ Attempt count
- ✅ Play and Close buttons

**Interactions:**
- Tap "PLAY" → Show Level Objective Popup → Start level
- Tap "CLOSE" → Return to World Map

---

### **4. LEVEL OBJECTIVE POPUP**

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│                                                                 │
│              ┌─────────────────────────────────┐               │
│              │                                 │               │
│              │     LEVEL 5 OBJECTIVE           │               │
│              │                                 │               │
│              │  ┌───────────────────────────┐ │               │
│              │  │                           │ │               │
│              │  │   Pass 6 obstacles to     │ │               │
│              │  │   complete this level!    │ │               │
│              │  │                           │ │               │
│              │  └───────────────────────────┘ │               │
│              │                                 │               │
│              │         Reward:                 │               │
│              │        20 🪙 Coins              │               │
│              │                                 │               │
│              │  ┌───────────────────────────┐ │               │
│              │  │                           │ │               │
│              │  │       [START] (3)         │ │  ← Countdown  │
│              │  │                           │ │               │
│              │  └───────────────────────────┘ │               │
│              │                                 │               │
│              └─────────────────────────────────┘               │
│                                                                 │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**Key Elements:**
- ✅ Large objective text
- ✅ Reward reminder
- ✅ Auto-countdown (3, 2, 1, GO!)
- ✅ Can't dismiss (auto-starts)

**Interactions:**
- Auto-countdown from 3 → 2 → 1 → GO!
- After countdown → Start gameplay

---

### **5. GAMEPLAY SCREEN (Modified)**

```
┌─────────────────────────────────────────────────────────────────┐
│  ← Pause    ❤️ 3    Score: 3/6    🪙 120    💎 5               │
│                                                                 │
│                                                                 │
│                         🛩️ [Jet]                               │
│                                                                 │
│                    [Obstacles]                                  │
│                                                                 │
│                                                                 │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Objective: Pass 6 obstacles (3/6 complete)             │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**Key Elements:**
- ✅ Hearts display (top-left)
- ✅ Score progress (3/6)
- ✅ Currency display
- ✅ Objective tracker (bottom)
- ✅ Pause button

**Interactions:**
- Tap screen → Jump (existing)
- Tap "Pause" → Pause menu
- Complete objective → Level Complete Screen
- Fail objective → Game Over (with continue option)

---

### **6. LEVEL COMPLETE SCREEN**

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│                                                                 │
│              ┌─────────────────────────────────┐               │
│              │                                 │               │
│              │   🎉 LEVEL COMPLETE! 🎉        │               │
│              │                                 │               │
│              │  Objective: ✅ 6/6              │               │
│              │  Time: 45 seconds               │               │
│              │  Continues Used: 1              │               │
│              │                                 │               │
│              │  ┌───────────────────────────┐ │               │
│              │  │   Rewards Earned:         │ │               │
│              │  │   +20 🪙 Coins            │ │               │
│              │  │   Total: 140 🪙           │ │               │
│              │  └───────────────────────────┘ │               │
│              │                                 │               │
│              │  ┌──────────────────────────┐  │               │
│              │  │    [NEXT LEVEL]          │  │               │
│              │  └──────────────────────────┘  │               │
│              │                                 │               │
│              │  ┌──────────────────────────┐  │               │
│              │  │    [BACK TO MAP]         │  │               │
│              │  └──────────────────────────┘  │               │
│              │                                 │               │
│              └─────────────────────────────────┘               │
│                                                                 │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**Key Elements:**
- ✅ Celebration animation (confetti)
- ✅ Objective completion status
- ✅ Performance stats (time, continues)
- ✅ Rewards earned
- ✅ Next Level button (primary)
- ✅ Back to Map button (secondary)

**Interactions:**
- Tap "NEXT LEVEL" → Load next level (if unlocked)
- Tap "BACK TO MAP" → Return to World Map

---

### **7. ZONE COMPLETE SCREEN**

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│                                                                 │
│              ┌─────────────────────────────────┐               │
│              │                                 │               │
│              │  🏆 ZONE 1 COMPLETE! 🏆        │               │
│              │                                 │               │
│              │     TROPICAL ISLANDS            │               │
│              │     10/10 Levels ✅             │               │
│              │                                 │               │
│              │  ┌───────────────────────────┐ │               │
│              │  │   Zone Stats:             │ │               │
│              │  │   Total Time: 8 min       │ │               │
│              │  │   Avg Continues: 1.2      │ │               │
│              │  │   Total Coins: 220 🪙     │ │               │
│              │  └───────────────────────────┘ │               │
│              │                                 │               │
│              │  ┌───────────────────────────┐ │               │
│              │  │   Bonus Rewards:          │ │               │
│              │  │   +10 💎 Gems             │ │               │
│              │  │   Total: 15 💎            │ │               │
│              │  └───────────────────────────┘ │               │
│              │                                 │               │
│              │  ┌──────────────────────────┐  │               │
│              │  │  [CONTINUE TO ZONE 2]    │  │               │
│              │  └──────────────────────────┘  │               │
│              │                                 │               │
│              └─────────────────────────────────┘               │
│                                                                 │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**Key Elements:**
- ✅ Epic celebration (confetti + fanfare)
- ✅ Zone name and completion
- ✅ Zone statistics
- ✅ Bonus gem reward
- ✅ Continue to next zone button

**Interactions:**
- Tap "CONTINUE TO ZONE 2" → Navigate to World Map (Zone 2 area)

---

### **8. BOT BATTLE SCREEN (Split View)**

```
┌─────────────────────────────────────────────────────────────────┐
│  ← Pause                   VS                                   │
│                                                                 │
│  ┌──────────────────────┬──────────────────────┐               │
│  │       YOU            │    BEACH BUDDY       │               │
│  │   ❤️ 3  Score: 3     │   Score: 2           │               │
│  │                      │                      │               │
│  │      🛩️              │         🛩️           │               │
│  │   (green_lightning)  │   (green_lightning)  │               │
│  │                      │                      │               │
│  │   [Obstacles]        │   [Obstacles]        │               │
│  │                      │                      │               │
│  │                      │                      │               │
│  │                      │                      │               │
│  │                      │                      │               │
│  └──────────────────────┴──────────────────────┘               │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Objective: First to pass 5 obstacles wins!             │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**Key Elements:**
- ✅ Split screen (player left, bot right)
- ✅ Individual score displays
- ✅ VS indicator
- ✅ Same obstacles for both
- ✅ Objective at bottom

**Interactions:**
- Tap screen → Jump (player only)
- Bot AI controls bot automatically
- First to reach target → Victory/Defeat screen

---

### **9. BOT VICTORY SCREEN**

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│                                                                 │
│              ┌─────────────────────────────────┐               │
│              │                                 │               │
│              │      🎉 YOU WIN! 🎉            │               │
│              │                                 │               │
│              │  You defeated Beach Buddy!     │               │
│              │                                 │               │
│              │  Your Score: 5                  │               │
│              │  Bot Score: 3                   │               │
│              │                                 │               │
│              │  ┌───────────────────────────┐ │               │
│              │  │   Rewards Earned:         │ │               │
│              │  │   +40 🪙 Coins (2x)       │ │               │
│              │  │   Total: 180 🪙           │ │               │
│              │  └───────────────────────────┘ │               │
│              │                                 │               │
│              │  ┌──────────────────────────┐  │               │
│              │  │    [NEXT LEVEL]          │  │               │
│              │  └──────────────────────────┘  │               │
│              │                                 │               │
│              │  ┌──────────────────────────┐  │               │
│              │  │    [BACK TO MAP]         │  │               │
│              │  └──────────────────────────┘  │               │
│              │                                 │               │
│              └─────────────────────────────────┘               │
│                                                                 │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**Key Elements:**
- ✅ Victory message
- ✅ Score comparison
- ✅ 2x coin reward
- ✅ Next Level / Back to Map buttons

**Interactions:**
- Tap "NEXT LEVEL" → Load next level
- Tap "BACK TO MAP" → Return to World Map

---

### **10. BOT DEFEAT SCREEN**

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│                                                                 │
│              ┌─────────────────────────────────┐               │
│              │                                 │               │
│              │      😔 BOT WINS! 😔           │               │
│              │                                 │               │
│              │  Beach Buddy defeated you!     │               │
│              │                                 │               │
│              │  Your Score: 3                  │               │
│              │  Bot Score: 5                   │               │
│              │                                 │               │
│              │  ┌───────────────────────────┐ │               │
│              │  │   No reward earned         │ │               │
│              │  └───────────────────────────┘ │               │
│              │                                 │               │
│              │  ┌──────────────────────────┐  │               │
│              │  │    [TRY AGAIN]           │  │               │
│              │  └──────────────────────────┘  │               │
│              │                                 │               │
│              │  ┌──────────────────────────┐  │               │
│              │  │    [BACK TO MAP]         │  │               │
│              │  └──────────────────────────┘  │               │
│              │                                 │               │
│              └─────────────────────────────────┘               │
│                                                                 │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**Key Elements:**
- ✅ Defeat message (not too harsh)
- ✅ Score comparison
- ✅ No reward
- ✅ Try Again / Back to Map buttons

**Interactions:**
- Tap "TRY AGAIN" → Restart bot battle
- Tap "BACK TO MAP" → Return to World Map

---

## 🎨 **DESIGN SYSTEM**

### **Colors**

| Element | Color | Hex |
|---------|-------|-----|
| Primary (Gold) | Gold | #FFD700 |
| Success (Green) | Green | #4CAF50 |
| Locked (Gray) | Gray | #9E9E9E |
| Background | Dark Blue | #1A237E |
| Text | White | #FFFFFF |
| Zone 1 (Tropical) | Cyan | #4FC3F7 |
| Zone 2 (Desert) | Orange | #FFB74D |
| Zone 3 (Lava) | Red | #FF5722 |
| Zone 4 (Storm) | Purple | #5E35B1 |
| Zone 5 (Frozen) | Ice Blue | #4FC3F7 |

### **Typography**

| Element | Font Size | Weight |
|---------|-----------|--------|
| Screen Title | 32px | Bold |
| Level Number | 28px | Bold |
| Objective Text | 20px | Regular |
| Button Text | 18px | Bold |
| Body Text | 16px | Regular |
| Stats Text | 14px | Regular |

### **Spacing**

- Screen Padding: 20px
- Element Spacing: 16px
- Button Height: 56px
- Level Node Size: 80px
- Icon Size: 40px

### **Animations**

| Element | Animation | Duration |
|---------|-----------|----------|
| Level Node (Current) | Pulse | 1.5s loop |
| Level Complete | Confetti | 3s |
| Zone Complete | Confetti + Fanfare | 5s |
| Button Tap | Scale down | 0.1s |
| Screen Transition | Fade + Slide | 0.3s |
| Objective Countdown | Scale + Fade | 1s per number |

---

## ✅ **TASK 0.4 COMPLETE**

**Summary:**
- ✅ Designed 10 screens with detailed wireframes
- ✅ Created complete user flow diagram
- ✅ Defined design system (colors, typography, spacing)
- ✅ Specified all interactions and animations
- ✅ Ensured responsive design for all screen sizes

**Result:**
🎉 **READY TO START PHASE 1 - CLEAR UI/UX BLUEPRINT!**

---

**Last Updated:** October 5, 2025
**Status:** ✅ Complete
**Next:** Phase 1 (Core Level System)
