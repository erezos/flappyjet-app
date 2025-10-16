# 🏛️ FlappyJet Architecture Documentation - v1.6.4 (Pre-Refactoring Baseline)

**Version**: v1.6.4+48  
**Date**: October 16, 2025  
**Purpose**: Baseline architecture documentation before v1.7.0 refactoring  
**Status**: CURRENT PRODUCTION ARCHITECTURE (before Flame optimization)

---

## 📊 **Architecture Overview**

FlappyJet is a Flutter/Flame casual mobile game with:
- **Game Modes**: Endless mode + 50-level story mode with bot battles
- **Monetization**: AdMob (rewarded ads, banners)
- **Backend**: Railway.app (tournaments, leaderboards, analytics)
- **Game Engine**: Flame 1.32.0 (not fully utilizing native features)

---

## 🎮 **Game Flow**

```
App Launch (main.dart)
    ↓
LoadingScreen (Initialize 15+ systems)
    ↓
Homepage (Main Menu)
    ├─→ Endless Mode (GameScreen → FlappyGame)
    ├─→ Story Mode (WorldMapScreen → LevelSelectionScreen → StoryModeGameWrapper → FlappyGame)
    ├─→ Tournaments (TournamentsScreen)
    ├─→ Store (StoreScreen)
    ├─→ Profile (ProfileScreen)
    └─→ Leaderboard (LeaderboardScreen)
```

---

## 🔧 **Core Components**

### **1. Main Entry Point** (`lib/main.dart`)

**Responsibilities**:
- Flutter initialization
- Firebase setup
- System manager initialization (15+ managers)
- Navigation to homepage

**Initialization Flow**:
```dart
main() async
    ├─ WidgetsFlutterBinding.ensureInitialized()
    ├─ Firebase.initializeApp()
    ├─ LoadingScreen
    │   ├─ Phase 1: Instant systems (< 100ms)
    │   │   ├─ AnonymousIdentityManager
    │   │   ├─ AudioSettingsManager
    │   │   ├─ GameDataManager
    │   │   └─ GameStateManager
    │   └─ Phase 2: Background systems (parallel)
    │       ├─ FirebaseAnalyticsManager
    │       ├─ PlayerIdentityManager
    │       ├─ MonetizationManager
    │       ├─ MissionsManager
    │       ├─ AchievementsManager
    │       ├─ LivesManager
    │       └─ 10+ more...
    └─ Navigate to Homepage
```

**Key Managers**:
- Total: 15+ singleton managers
- Critical: LivesManager, InventoryManager, MonetizationManager
- Performance impact: ~2-3 second initialization

---

## 🎯 **FlappyGame Class** (`lib/game/flappy_game.dart`)

**Lines of Code**: 1,174 lines (🚨 God Class)  
**Extends**: `FlameGame`  
**Complexity**: High (cyclomatic complexity ~35)

### **Responsibilities** (Too Many!)

1. **Game Loop Management**
   - `update(double dt)` - Main game loop
   - `onLoad()` - Initialization
   - Component lifecycle

2. **Collision Detection** (Manual)
   - `_checkCollisions()` - Manual collision loop
   - Checking jet vs obstacles
   - Checking bot vs obstacles
   - Ground/ceiling collision

3. **State Management**
   - Game state (waiting/playing/game over)
   - Score tracking
   - Lives management
   - Theme transitions

4. **Component Management**
   - Creating components
   - Adding/removing from game
   - Priority management

5. **Audio Management**
   - Music playback
   - Sound effects
   - Theme music transitions

6. **Analytics Integration**
   - Game start tracking
   - Game end tracking
   - Score submission

7. **Story Mode Integration**
   - Level objectives
   - Bot battles
   - Reward distribution

8. **Monetization**
   - Rewarded ads
   - Continue system
   - Life management

### **Key Methods**

```dart
class FlappyGame extends FlameGame {
    // Public API
    Future<void> handleTap()
    void resetGame()
    void continueGame()
    void addExtraLife()
    
    // Game Loop
    @override
    Future<void> onLoad()
    @override
    void update(double dt)
    
    // Internal (Private)
    void _handleGameStart()
    void _checkCollisions()  // 🚨 Manual collision detection
    void _handleCollision()
    void _handleScore()
    void _gameOver()
    
    // Components
    late JetPlayer _jet
    BotJetPlayer? _botJet
    late HUD _hud
    late ParallaxBackground _background
    
    // Systems
    late GameStateManager _gameStateManager
    late CollisionSystem _collisionSystem  // 🚨 Legacy manual collision
    late ObstacleManager _obstacleManager
    late CelebrationSystem _celebrationSystem
    late ThemeManager _themeManager
    late FlappyJetAudioManager _audioManager
    late HardwareParticleSystem _hardwareParticleSystem
}
```

---

## 🛩️ **JetPlayer Component** (`lib/game/components/jet_player.dart`)

**Lines of Code**: 766 lines (🚨 Too complex)  
**Extends**: `SpriteComponent`  
**Mixins**: `HasGameReference<FlappyGame>`

### **Responsibilities** (Should be extracted to Behaviors)

1. **Physics** (Manual)
   - Gravity calculation: `velocity.y += GameConfig.gravity * dt`
   - Terminal velocity capping
   - Position updates

2. **Jump Mechanics** (Manual)
   - Jump force application
   - Jump cooldown
   - Animation (squash/stretch)

3. **Damage State Management** (Manual)
   - Visual damage indicators
   - Color tinting (healthy/damaged/critical)
   - Invulnerability visual effects

4. **Invulnerability Timer** (Manual)
   - Timer countdown
   - State transitions
   - Pending state queuing

5. **Collision Response** (Manual)
   - Handles collision events from game
   - Updates damage state
   - Triggers effects

6. **Animation** (Manual)
   - Bobbing animation (sin wave calculation)
   - Rotation based on velocity
   - Scale effects

### **Current Implementation Issues**

```dart
// ❌ Manual gravity (should use GravityBehavior)
void update(double dt) {
    velocity.y += GameConfig.gravity * dt;  // New Vector2 allocation!
    if (velocity.y > maxFallSpeed) velocity.y = maxFallSpeed;
    position.y += velocity.y * dt;  // Another allocation!
}

// ❌ Manual jump (should use JumpBehavior)
void jump() {
    velocity.y = -GameConfig.jumpForce;
    // Manual squash/stretch animation
    scale = Vector2(1.2, 0.8);  // Allocation!
    Future.delayed(...);
}

// ❌ Manual damage visualization (should use DamageVisualizationBehavior)
void _updateDamageState() {
    if (_damageState == JetDamageState.critical) {
        final pulse = sin(_time * 8);  // Manual calculation
        paint.colorFilter = ColorFilter.mode(Colors.red.withOpacity(pulse), ...);
    }
}

// ❌ Manual invulnerability (should use InvulnerabilityBehavior)
void _updateInvulnerability(double dt) {
    if (_invulnerabilityTime > 0) {
        _invulnerabilityTime -= dt;
        if (_invulnerabilityTime <= 0) {
            _isInvulnerable = false;
        }
    }
}
```

### **Performance Issues**

- **Vector2 Allocations**: Creating new Vector2 objects every frame
- **Estimated**: 60 allocations/second just from JetPlayer
- **Impact**: Garbage collection pressure, frame drops

---

## 🤖 **BotJetPlayer Component** (`lib/game/components/bot_jet_player.dart`)

**Lines of Code**: 543 lines  
**Code Duplication**: 70% similar to JetPlayer

### **Duplicated Code**

- Gravity physics (identical to JetPlayer)
- Jump mechanics (identical to JetPlayer)
- Damage visualization (similar logic)
- Animation calculations (similar patterns)

**This is a prime target for Behavior pattern refactoring!**

---

## 🚧 **DynamicObstacle Component** (`lib/game/components/dynamic_obstacle.dart`)

**Responsibilities**:
- Obstacle spawning and movement
- Gap size calculation
- Visual rendering
- **NO collision detection** (handled by CollisionSystem)

### **Current Flow**

```dart
DynamicObstacle created by ObstacleManager
    ↓
Added to FlappyGame
    ↓
update(dt): position.x -= scrollSpeed * dt  // ❌ Vector allocation
    ↓
FlappyGame._checkCollisions() manually checks collision
    ↓
If collision → _handleCollision()
```

---

## 🎯 **Collision System** (`lib/game/systems/collision_system.dart`)

**Lines of Code**: 54 lines  
**Type**: Manual collision detection (🚨 Should use Flame's collision system)

### **Current Implementation**

```dart
class CollisionSystem {
    bool checkCollision(JetPlayer jet, DynamicObstacle obstacle, Size gameSize) {
        // ❌ Manual rectangle overlap calculation
        final jetRect = Rect.fromCenter(
            center: Offset(jet.position.x, jet.position.y),
            width: GameConfig.jetSize,
            height: GameConfig.jetSize,
        );
        
        final topRect = Rect.fromLTWH(
            obstacle.position.x,
            0,
            GameConfig.obstacleWidth,
            obstacle.position.y - gapSize / 2,
        );
        
        final bottomRect = Rect.fromLTWH(
            obstacle.position.x,
            obstacle.position.y + gapSize / 2,
            GameConfig.obstacleWidth,
            gameSize.height - (obstacle.position.y + gapSize / 2),
        );
        
        return jetRect.overlaps(topRect) || jetRect.overlaps(bottomRect);
    }
    
    // Called every frame for every obstacle (O(n) per frame)
}
```

### **Performance Characteristics**

- **Time Complexity**: O(n) where n = number of obstacles
- **Called**: Every frame (60 times per second)
- **Checks**: ~10-20 collision checks per frame
- **Total**: 600-1200 checks per second

### **Problems**

1. ❌ Not using Flame's quadtree spatial partitioning
2. ❌ Checking all obstacles even if far away
3. ❌ Manual rectangle math (error-prone)
4. ❌ No built-in collision callbacks
5. ❌ Duplicated logic for bot collisions

---

## 📊 **State Management** (`lib/game/systems/game_state_manager.dart`)

**Lines of Code**: 178 lines  
**Type**: ChangeNotifier singleton  
**Status**: ✅ Well-designed (already extracted)

### **Responsibilities**

- Game state machine (waiting/playing/game over)
- Score tracking
- Lives management
- Continue system
- Theme progression

### **Public API**

```dart
class GameStateManager extends ChangeNotifier {
    // State
    bool get isWaitingToStart
    bool get isGameOver
    bool get isPlaying
    int get score
    int get lives
    GameTheme get currentTheme
    
    // Actions
    void startGame()
    void setGameOver()
    void resetGame()
    void continueGame()
    bool handleCollision()
    void updateScore(int newScore)
}
```

**Status**: ✅ Good separation, keep as-is

---

## 🎨 **Story Mode Architecture**

### **Level System Manager** (`lib/game/systems/level_system_manager.dart`)

**Lines of Code**: 505 lines  
**Type**: ChangeNotifier singleton  
**Status**: ✅ Well-designed

**Responsibilities**:
- Load level data from JSON
- Track player progression
- Unlock system
- Zone management
- Persistence (SharedPreferences)

**Data Flow**:
```
assets/data/levels/zone1_levels.json
    ↓
LevelSystemManager.initialize()
    ↓
Parse JSON → LevelData objects
    ↓
Track progress (completed levels, current level, unlocked zones)
    ↓
Save to SharedPreferences
```

### **Level Data Schema** (`lib/models/level_data_schema.dart`)

```dart
class LevelData {
    final int id;
    final String name;
    final int zone;
    final LevelObjective objective;
    final LevelDifficulty difficulty;
    final LevelReward reward;
    final LevelTheme theme;
    final BotBattle? botBattle;
}

enum ObjectiveType {
    reachScore,      // Reach X points
    surviveTime,     // Survive X seconds
    collectCoins,    // Collect X coins
    noCrash,         // Complete without crashing
    beatBot,         // Beat bot opponent
}
```

### **Story Mode Game Wrapper** (`lib/ui/widgets/story_mode_game_wrapper.dart`)

**Responsibilities**:
- Wraps FlappyGame for story mode
- Tracks level objectives
- Shows game over menu with continue options
- Handles level completion
- Grants rewards

**Integration with FlappyGame**:
```dart
FlappyGame(
    isStoryMode: true,
    storyModeLevel: levelData,
    onObstaclePassed: () => _objectiveTracker.increment(),
    onGameOver: () => _showGameOverMenu(),
)
```

---

## 🎨 **UI Architecture**

### **Screen Structure**

```
lib/ui/
├── screens/
│   ├── homepage.dart (Main menu)
│   ├── game_screen.dart (Endless mode wrapper)
│   ├── world_map_screen.dart (Story mode map)
│   ├── level_selection_screen.dart (Level list)
│   ├── level_complete_screen.dart (Victory screen)
│   ├── level_failed_screen.dart (Failure screen)
│   ├── zone_completion_celebration_screen.dart (Zone complete)
│   ├── tournaments_screen.dart
│   ├── store_screen.dart
│   └── profile_screen.dart
└── widgets/
    ├── story_mode_game_wrapper.dart (Story mode game container)
    ├── text_3d_widget.dart (Custom 3D text)
    ├── gem_3d_icon.dart (Gem display)
    └── daily_streak/ (Daily streak UI)
```

---

## 🔊 **Audio System** (`lib/game/systems/flappy_jet_audio_manager.dart`)

**Type**: Singleton using Flame Audio  
**Status**: ✅ Modern Flame Audio (good)

**Capabilities**:
- Music playback with looping
- Sound effects
- Volume control
- Mute/unmute

**Usage**:
```dart
FlappyJetAudioManager.instance
    .playMusic('sky_rookie.mp3', volume: 0.7)
    .playSfx('jump.wav')
    .playScore()
    .playCollision()
```

---

## 💰 **Monetization System** (`lib/game/systems/monetization_manager.dart`)

**Integration**: AdMob with Unity Ads mediation

**Features**:
- Rewarded ads for extra lives
- Banner ads
- Interstitial ads
- Ad frequency capping

**Flow**:
```dart
Player crashes → Game Over → Menu
    ↓
"Continue with Ad" button
    ↓
MonetizationManager.showRewardedAdForExtraLife()
    ↓
Ad shown → onReward callback
    ↓
FlappyGame.continueGame() → Restore 1 life
```

---

## 📈 **Analytics System**

### **Firebase Analytics** (`lib/game/systems/firebase_analytics_manager.dart`)

**Events Tracked**:
- Game start (with jet skin, theme, player level)
- Game end (score, survival time, cause of death)
- Level complete (story mode)
- Continue usage (ad/gems)
- Store purchases
- Achievement unlocks

### **Comprehensive Analytics** (`lib/core/analytics/comprehensive_analytics_manager.dart`)

**Additional Tracking**:
- Session analytics
- Lifecycle events
- Performance metrics
- User flow tracking

---

## ⚡ **Performance Systems**

### **Adaptive Quality Manager** (`lib/game/systems/adaptive_quality.dart`)

**Purpose**: Adjust game quality based on device performance

**Profiles**:
- Low: Reduced particles, lower fps target
- Medium: Balanced quality
- High: Full effects, 60 FPS
- Ultra: Maximum quality

**Dynamic Adjustment**:
```dart
_qualityManager.updatePerformanceMetrics(dt)
    ↓
Monitor FPS
    ↓
If FPS < target → Reduce quality
If FPS > target + margin → Increase quality
```

### **Hardware Particle System** (`lib/game/systems/hardware_particle_system.dart`)

**Type**: GPU-accelerated particle rendering  
**Status**: ✅ Optimized

**Pre-renders particle sprites for reuse**:
- Crash particles
- Celebration particles
- Score particles
- Jump trail particles

---

## 🗄️ **Data Persistence**

### **SharedPreferences Usage**

```dart
Keys Used:
- 'best_score' → int (high score)
- 'best_streak' → int (longest streak)
- 'inv_soft_currency' → int (coins)
- 'inv_gems' → int (gems)
- 'inv_equipped_skin' → String (current jet)
- 'inv_owned_skins' → List<String>
- 'lives_current' → int
- 'lives_last_refill_time' → int (timestamp)
- 'story_mode_current_level' → int
- 'story_mode_completed_levels' → List<int>
- 'story_mode_current_zone' → int
- ... (50+ keys total)
```

### **Hive Usage** (Limited)

Currently only used for:
- Tournament data caching
- Offline leaderboard

---

## 🌐 **Backend Integration** (Railway.app)

### **Endpoints**

```
Base URL: https://flappyjet-backend-production.up.railway.app

GET  /api/tournaments/current
POST /api/tournaments/:id/sessions/submit_score
GET  /api/analytics/user/:userId
POST /api/analytics/events
```

### **Services**

- **TournamentService** (`lib/services/tournament_service.dart`)
  - Submit scores
  - Get rankings
  - Fetch rewards

- **InventorySyncService** (`lib/services/inventory_sync_service.dart`)
  - Sync coins/gems with backend
  - Cloud backup

---

## 📊 **Performance Baseline (v1.6.4)**

### **Measured Metrics**

| Metric | Value | Status |
|--------|-------|--------|
| **Average FPS** | 48.5 | 🟡 Below target (60) |
| **Frame Time (p95)** | 24ms | 🟡 Above target (17ms) |
| **Memory Usage** | 145 MB | 🟡 Could be lower |
| **GC Frequency** | 3 per second | 🔴 Too high |
| **Vector2 Allocations/sec** | ~900 | 🔴 Excessive |

### **Performance Issues Identified**

1. **Vector2 Allocations** (🔴 Critical)
   - Creating new Vector2 objects in update loops
   - Estimated 900 allocations per second
   - Causes GC pressure

2. **Manual Collision Detection** (🟡 High)
   - O(n) collision checks every frame
   - Not using spatial partitioning
   - Checking distant obstacles

3. **Manual Animations** (🟡 Medium)
   - Sin/cos calculations every frame
   - Manual timing and easing
   - Could use Flame Effects

4. **Component Complexity** (🟡 Medium)
   - JetPlayer: 766 lines
   - FlappyGame: 1,174 lines
   - High cyclomatic complexity

---

## 🎯 **Architectural Strengths**

✅ **Good Separations**:
1. GameStateManager extracted and well-designed
2. Audio system using modern Flame Audio
3. Story mode data well-structured
4. Hardware particle system optimized
5. Adaptive quality system

✅ **Clean Data Models**:
- LevelData schema is comprehensive
- Clear objective types
- Good reward structure

✅ **Good Integration**:
- Firebase services well-integrated
- Analytics tracking comprehensive
- Backend communication solid

---

## 🚨 **Architectural Weaknesses**

❌ **Not Using Flame Features**:
1. Manual collision (should use HasCollisionDetection)
2. No Behavior pattern (should use Behavior<T>)
3. Manual animations (should use Effect system)
4. No Camera/World separation
5. Manual physics calculations

❌ **Code Organization**:
1. FlappyGame god class (1,174 lines)
2. JetPlayer too complex (766 lines)
3. Code duplication (JetPlayer vs BotJetPlayer)
4. Mixed responsibilities

❌ **Performance**:
1. Vector2 allocations in update loops
2. Inefficient collision detection
3. No object pooling
4. Paint object creation every frame

---

## 📋 **Component Inventory**

### **Game Components**

| Component | LOC | Status | Priority |
|-----------|-----|--------|----------|
| FlappyGame | 1,174 | 🔴 Refactor | HIGH |
| JetPlayer | 766 | 🔴 Refactor | HIGH |
| BotJetPlayer | 543 | 🔴 Refactor | HIGH |
| DynamicObstacle | ~200 | 🟡 Optimize | MEDIUM |
| ParallaxBackground | ~150 | 🟢 Keep | LOW |
| HUD | ~140 | 🟢 Keep | LOW |

### **Systems**

| System | LOC | Status | Priority |
|--------|-----|--------|----------|
| CollisionSystem | 54 | 🔴 Replace | HIGH |
| GameStateManager | 178 | 🟢 Keep | - |
| ObstacleManager | ~120 | 🟢 Keep | LOW |
| CelebrationSystem | ~100 | 🟡 Enhance | MEDIUM |
| ThemeManager | ~80 | 🟢 Keep | LOW |
| LevelSystemManager | 505 | 🟢 Keep | - |

### **UI Screens**

Total: 15+ screens  
Status: ✅ Well-organized, minimal changes needed

---

## 🎯 **Refactoring Targets for v1.7.0**

### **Phase 1: Collision System**
- Replace CollisionSystem with Flame's collision detection
- Add HasCollisionDetection mixin
- Add hitboxes to components
- Expected: 30% FPS improvement

### **Phase 2: Behavior Pattern**
- Extract gravity → GravityBehavior
- Extract jump → JumpBehavior
- Extract damage visualization → DamageVisualizationBehavior
- Extract invulnerability → InvulnerabilityBehavior
- Expected: 34% LOC reduction in JetPlayer

### **Phase 3: Effect System**
- Replace manual animations with Flame Effects
- Add Camera + World components
- Screen shake effects
- Expected: 200 lines deleted, smoother animations

### **Phase 4: Performance**
- Vector pooling
- Paint object reuse
- Collision optimization
- Expected: 80% reduction in allocations

---

## 📊 **Dependencies Map**

```
FlappyGame
    ├─ depends on → GameStateManager ✅
    ├─ depends on → CollisionSystem 🔴 (will remove)
    ├─ depends on → ObstacleManager ✅
    ├─ depends on → AudioManager ✅
    ├─ depends on → MonetizationManager ✅
    └─ depends on → MissionsManager ✅

JetPlayer
    ├─ depends on → FlappyGame (HasGameReference)
    ├─ depends on → GameConfig
    ├─ depends on → JetSkin data
    └─ creates → Physics, Jump, Damage, Invulnerability 🔴 (will extract)

StoryModeGameWrapper
    ├─ wraps → FlappyGame
    ├─ depends on → LevelSystemManager ✅
    ├─ depends on → LevelRewardManager ✅
    ├─ depends on → ObjectiveTracker ✅
    └─ depends on → MonetizationManager ✅
```

---

## 🔧 **Test Coverage (Current)**

```
Total Test Files: 18
Coverage: ~45%

Tested:
✅ Daily streak system
✅ Game state manager
✅ Core components (partial)
✅ Some UI screens

Not Tested:
❌ Collision system
❌ JetPlayer behaviors
❌ Story mode integration (partial)
❌ Many game systems
```

**Target for v1.7.0**: 80% coverage

---

## 📁 **File Structure**

```
lib/
├── main.dart (187 lines)
├── game/
│   ├── flappy_game.dart (1,174 lines) 🔴
│   ├── components/
│   │   ├── jet_player.dart (766 lines) 🔴
│   │   ├── bot_jet_player.dart (543 lines) 🔴
│   │   ├── dynamic_obstacle.dart
│   │   └── parallax_background.dart
│   ├── systems/
│   │   ├── collision_system.dart (54 lines) 🔴 DELETE
│   │   ├── game_state_manager.dart (178 lines) ✅
│   │   ├── level_system_manager.dart (505 lines) ✅
│   │   ├── obstacle_manager.dart
│   │   ├── celebration_system.dart
│   │   └── 10+ more managers...
│   └── core/
│       ├── game_config.dart
│       ├── game_themes.dart
│       └── jet_skins.dart
├── ui/
│   ├── screens/ (15 screens)
│   └── widgets/ (20+ widgets)
├── models/
│   └── level_data_schema.dart ✅
└── services/
    ├── tournament_service.dart
    └── inventory_sync_service.dart
```

---

## 🎯 **Summary**

### **What Works Well**
1. ✅ Modular systems architecture
2. ✅ Clean data models
3. ✅ Good Firebase integration
4. ✅ Story mode implementation
5. ✅ Comprehensive analytics

### **What Needs Improvement**
1. 🔴 Not using Flame collision system
2. 🔴 No Behavior pattern
3. 🔴 Manual animations
4. 🔴 Performance issues (Vector2 allocations)
5. 🔴 God classes (FlappyGame, JetPlayer)

### **Expected Improvements (v1.7.0)**
- **Performance**: 48.5 → 58+ FPS (+20%)
- **Code Quality**: -34% LOC in critical classes
- **Maintainability**: Behavior pattern, less duplication
- **Test Coverage**: 45% → 80% (+35%)
- **Architecture**: Proper Flame patterns

---

**This architecture served us well for v1.6.4, but v1.7.0 will be a major leap forward in code quality, performance, and maintainability!** 🚀

---

**Next**: See [PRODUCTION_REFACTORING_PLAN_v1.7.0.md](PRODUCTION_REFACTORING_PLAN_v1.7.0.md) for the complete refactoring strategy.

