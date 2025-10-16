# 🏗️ **FLAPPYJET PRODUCTION-GRADE REFACTORING PLAN v1.7.0**
## **Test-Driven, Incremental, Clean Architecture Migration**

**Project**: FlappyJet Pro v1.6.4 → v1.7.0  
**Approach**: Test-Driven Development (TDD) + Clean Architecture + Atomic Commits  
**Philosophy**: "Make it work, make it right, make it fast" - Kent Beck  
**Timeline**: 10 days (80 hours)  
**Created**: October 16, 2025  

---

## 📋 **TABLE OF CONTENTS**

1. [Architecture Review](#architecture-review)
2. [Refactoring Principles](#refactoring-principles)
3. [Testing Strategy](#testing-strategy)
4. [Incremental Migration Plan](#incremental-migration-plan)
5. [Task Breakdown (Atomic Units)](#task-breakdown)
6. [Code Deletion Tracking](#code-deletion-tracking)
7. [Reference Update Checklist](#reference-update-checklist)
8. [Success Criteria](#success-criteria)

---

## 🏛️ **ARCHITECTURE REVIEW**

### **Current Architecture (v1.6.4)**

#### **App Flow**
```
main.dart (Entry Point)
  └─> LoadingScreen (System Initialization)
      ├─> Firebase, Analytics, Auth, Managers (15+ systems)
      └─> Homepage (Main Menu)
          ├─> GameScreen (Endless Mode)
          │   └─> FlappyGame (Flame Game Loop)
          ├─> WorldMapScreen (Story Mode)
          │   └─> LevelSelectionScreen
          │       └─> StoryModeGameWrapper
          │           └─> FlappyGame (Story Mode Instance)
          └─> Store, Profile, Leaderboard, etc.
```

#### **Core Game Architecture (`FlappyGame`)**
```dart
FlappyGame (FlameGame) - 1174 lines! 🚨
  ├─ Components:
  │   ├─ JetPlayer (766 lines) - Player character
  │   ├─ BotJetPlayer (543 lines) - Bot opponent
  │   ├─ DynamicObstacle - Pipes/pillars
  │   ├─ ParallaxBackground - Dynamic backgrounds
  │   └─ HUD - Score, lives, UI overlay
  │
  ├─ Systems (Separated):
  │   ├─ GameStateManager - Game state machine
  │   ├─ CollisionSystem - Manual collision (LEGACY)
  │   ├─ ObstacleManager - Spawning logic
  │   ├─ CelebrationSystem - Particles, effects
  │   └─ ThemeManager - Theme transitions
  │
  └─ MCP Systems:
      ├─ FlappyJetAudioManager - Sound/music
      ├─ HardwareParticleSystem - GPU particles
      ├─ JetEffectsSystem - Engine fire effects
      ├─ FirebaseAnalyticsManager
      ├─ MissionsManager
      ├─ AdaptiveQualityManager
      └─ LightweightPerformanceTimer
```

#### **Story Mode Architecture**
```dart
Story Mode Components:
  ├─ LevelSystemManager - Progression, unlocks, persistence
  ├─ LevelRewardManager - Rewards calculation/distribution
  ├─ ObjectiveTracker - Level objective tracking
  ├─ LevelData (Schema) - Level definitions
  └─ Zone System - 5 zones, 10 levels each
```

#### **Architectural Strengths** ✅
1. ✅ **Systems Separation**: GameStateManager, CollisionSystem, ObstacleManager extracted
2. ✅ **Singleton Managers**: LivesManager, InventoryManager, LevelSystemManager
3. ✅ **Flame Integration**: Using FlameGame, Components, Sprite, Audio
4. ✅ **Analytics**: Comprehensive tracking throughout
5. ✅ **Performance**: AdaptiveQualityManager, HardwareParticleSystem
6. ✅ **Story Mode**: Complete level system with progression

#### **Architectural Weaknesses** 🚨
1. ❌ **Manual Collision Detection**: Not using Flame's `HasCollisionDetection`, `Hitbox`, `CollisionCallbacks`
2. ❌ **No Behavior Pattern**: Custom implementations instead of Flame's `Behavior<T>`
3. ❌ **No Camera/World System**: Direct component adding, no `World` + `CameraComponent`
4. ❌ **Manual Animations**: Sin/cos calculations instead of Flame's `Effect` system
5. ❌ **God Class**: `FlappyGame` still 1174 lines with mixed concerns
6. ❌ **Vector Allocations**: New `Vector2` created every frame in `update()`
7. ❌ **No Component Grouping**: No use of `ComposedComponent` or component hierarchies
8. ❌ **Mixed Update Logic**: Game logic + rendering + state management in one class
9. ❌ **Tight Coupling**: Components directly reference game, not using proper dependency injection
10. ❌ **Inconsistent Testing**: Only 18 test files, gaps in coverage

#### **Performance Bottlenecks** ⚡
```dart
// CURRENT (Creates garbage every frame):
void update(double dt) {
  position += Vector2(velocity.x * dt, velocity.y * dt); // NEW VECTOR! 💥
  velocity += Vector2(0, gravity * dt); // NEW VECTOR! 💥
}

// Files creating Vector2 allocations:
- lib/game/components/jet_player.dart (update loop)
- lib/game/components/dynamic_obstacle.dart (update loop)
- lib/game/components/parallax_background.dart (scrolling)
- lib/game/systems/collision_system.dart (collision checks)

// Estimated: 200-300 Vector2 allocations/second = 50+ MB/hour 🚨
```

#### **Code Duplication**
1. Collision logic duplicated in `FlappyGame._checkCollisions()` (player + bot)
2. Gravity/jump physics duplicated in `JetPlayer` and `BotJetPlayer`
3. Damage visualization logic repeated
4. Animation code (bobbing, scaling) manually implemented

---

## 🎯 **REFACTORING PRINCIPLES**

### **Core Principles**

1. **Test-Driven Development (TDD)**
   - ✅ Red: Write failing test
   - ✅ Green: Make it pass (simplest way)
   - ✅ Refactor: Clean up code
   - ✅ Repeat for each small change

2. **Atomic Commits**
   - Each task = 1 commit
   - Commit message format: `[REFACTOR-X.Y] Description`
   - Example: `[REFACTOR-1.1] Add collision detection tests (baseline)`
   - Each commit should compile and pass tests

3. **Clean Code Deletion**
   - Document what's being deleted in `CODE_DELETION_LOG.md`
   - Mark deprecated code with `@Deprecated('Use X instead')` for 1 sprint
   - Then delete after confirming no usages

4. **Reference Tracking**
   - Use IDE "Find Usages" before any deletion
   - Update all imports, references, documentation
   - Run `flutter analyze` after every change

5. **Incremental Migration**
   - Step-by-step refactoring with testing after each step
   - If something breaks, investigate and fix immediately
   - No big-bang rewrites, but no parallel systems either

6. **Continuous Integration**
   - Tests run after every commit
   - Performance benchmarks tracked
   - Code coverage must not decrease

---

## 🧪 **TESTING STRATEGY**

### **Test Pyramid**

```
          /\
         /E2E\         10% - Full gameplay tests
        /------\
       /  INTE  \      30% - Component integration tests
      /----------\
     /    UNIT    \    60% - Unit tests (systems, behaviors, utils)
    /--------------\
```

### **Test Categories**

#### **1. Unit Tests** (60% of tests)
- **Target**: 80% code coverage
- **Scope**: Individual functions, classes, systems
- **Files to Test**:
  ```
  test/game/systems/
    ├─ collision_system_test.dart (NEW - Flame collision)
    ├─ game_state_manager_test.dart (EXISTS - expand)
    ├─ obstacle_manager_test.dart (NEW)
    ├─ celebration_system_test.dart (NEW)
    └─ theme_manager_test.dart (NEW)
  
  test/game/behaviors/
    ├─ gravity_behavior_test.dart (NEW)
    ├─ jump_behavior_test.dart (NEW)
    ├─ damage_visualization_behavior_test.dart (NEW)
    └─ invulnerability_behavior_test.dart (NEW)
  
  test/game/components/
    ├─ jet_player_test.dart (NEW)
    ├─ bot_jet_player_test.dart (NEW)
    ├─ dynamic_obstacle_test.dart (NEW)
    └─ parallax_background_test.dart (NEW)
  ```

#### **2. Integration Tests** (30% of tests)
- **Target**: All critical flows working together
- **Scope**: Multiple components/systems interacting
- **Files to Test**:
  ```
  test/integration/
    ├─ collision_integration_test.dart (NEW)
    ├─ story_mode_integration_test.dart (EXISTS - expand)
    ├─ endless_mode_integration_test.dart (NEW)
    ├─ bot_battle_integration_test.dart (NEW)
    └─ theme_transition_integration_test.dart (NEW)
  ```

#### **3. Performance Tests** (NEW)
- **Target**: No regressions, 20% improvement
- **Metrics**: FPS, frame time, memory, GC frequency
- **Files**:
  ```
  test/performance/
    ├─ vector_allocation_test.dart (NEW)
    ├─ collision_performance_test.dart (NEW)
    ├─ rendering_performance_test.dart (NEW)
    └─ memory_leak_test.dart (NEW)
  ```

#### **4. Golden Tests** (NEW)
- **Target**: Visual regression detection
- **Scope**: UI screens, game visuals
- **Files**:
  ```
  test/golden/
    ├─ homepage_golden_test.dart (NEW)
    ├─ world_map_golden_test.dart (NEW)
    ├─ game_screen_golden_test.dart (NEW)
    └─ level_complete_golden_test.dart (NEW)
  ```

### **Test Infrastructure Setup**

```dart
// test/helpers/test_helpers.dart (NEW)
class TestHelpers {
  /// Create a test FlappyGame with mocked dependencies
  static FlappyGame createTestGame({
    bool isStoryMode = false,
    LevelData? level,
  }) {
    return FlappyGame(
      monetization: MockMonetizationManager(),
      missions: MockMissionsManager(),
      isStoryMode: isStoryMode,
      storyModeLevel: level,
    );
  }
  
  /// Create test level data
  static LevelData createTestLevel({
    int id = 1,
    ObjectiveType type = ObjectiveType.reachScore,
  }) {
    return LevelData(/* ... */);
  }
  
  /// Run game update for N frames
  static Future<void> runFrames(FlappyGame game, int frames) async {
    for (int i = 0; i < frames; i++) {
      game.update(1 / 60); // 60 FPS
      await Future.delayed(Duration.zero); // Pump event loop
    }
  }
}

// test/helpers/mock_managers.dart (NEW)
class MockMonetizationManager extends Mock implements MonetizationManager {}
class MockMissionsManager extends Mock implements MissionsManager {}
class MockLiveManagersuManager extends Mock implements LivesManager {}
// etc.
```

### **Baseline Test Suite** (Before Refactoring)

```bash
# Step 1: Create baseline tests
flutter test test/baseline/ --coverage

# Expected Output:
# ✅ Baseline collision detection works
# ✅ Baseline scoring works
# ✅ Baseline game state transitions work
# ✅ Baseline story mode level progression works
# ✅ Baseline performance metrics recorded

# Step 2: These tests MUST pass throughout refactoring
# If baseline test fails → refactoring broke something!
```

---

## 📅 **INCREMENTAL MIGRATION PLAN**

### **Migration Strategy: Strangler Fig Pattern**

```
Week 1: Foundation + Testing
  ├─ Day 1: Setup + Baseline Tests
  ├─ Day 2: Test Infrastructure + Documentation
  └─ Day 3: Flame Collision (Tests First)

Week 2: Core Refactoring
  ├─ Day 4: Flame Collision (Implementation)
  ├─ Day 5: Behavior Pattern (Tests + Impl)
  ├─ Day 6: Effect System (Tests + Impl)
  └─ Day 7: Camera/World (Tests + Impl)

Week 3: Polish + Production
  ├─ Day 8: Performance Optimization + Tests
  ├─ Day 9: Integration Testing + Bug Fixes
  └─ Day 10: Documentation + Release Prep
```

### **Incremental Refactoring Pattern**

```dart
// Step-by-step migration (no parallel systems):
// Step 1: Add Flame collision system
// Step 2: Test thoroughly
// Step 3: Remove old collision system
// Step 4: Test again
// If anything breaks → investigate and fix immediately

class FlappyGame extends FlameGame with HasCollisionDetection {
  // Clean migration: Only new Flame collision system
  void _checkCollisions() {
    // ✅ Flame handles collision automatically via CollisionCallbacks
    // Old manual system will be deleted after testing confirms new system works
  }
}
```

---

## ✅ **TASK BREAKDOWN (ATOMIC UNITS)**

### **📦 PHASE 0: PREPARATION & BASELINE** (Day 1-2, 16h)

#### **Task 0.1: Setup Testing Infrastructure** ⏱️ 2h
```yaml
ID: REFACTOR-0.1
Priority: 🔴 CRITICAL
Dependencies: None
Test Requirement: N/A (setup task)

Acceptance Criteria:
  ✅ test/helpers/test_helpers.dart created
  ✅ test/helpers/mock_managers.dart created
  ✅ test/helpers/test_level_data.dart created
  ✅ pubspec.yaml updated with test dependencies
  ✅ flutter test runs successfully

Steps:
  1. Create test/helpers/ directory
  2. Add test dependencies:
     - mocktail: ^1.0.0
     - flame_test: ^1.15.0
     - golden_toolkit: ^0.15.0
  3. Create helper files with documentation
  4. Run flutter pub get
  5. Verify with: flutter test --dry-run

Files Created:
  + test/helpers/test_helpers.dart
  + test/helpers/mock_managers.dart
  + test/helpers/test_level_data.dart
  ~ pubspec.yaml (add dependencies)

Commit Message:
  [REFACTOR-0.1] Setup testing infrastructure and helpers
```

#### **Task 0.2: Document Current Architecture** ⏱️ 2h
```yaml
ID: REFACTOR-0.2
Priority: 🟡 HIGH
Dependencies: None
Test Requirement: N/A (documentation task)

Acceptance Criteria:
  ✅ ARCHITECTURE_v1.6.4.md created
  ✅ Component diagram generated
  ✅ System flow documented
  ✅ All public APIs listed
  ✅ Performance baseline recorded

Steps:
  1. Document FlappyGame public API
  2. List all components and their responsibilities
  3. Document system interactions
  4. Record performance metrics (baseline)
  5. Create mermaid diagrams

Files Created:
  + ARCHITECTURE_v1.6.4.md
  + docs/diagrams/component_architecture.mmd
  + docs/diagrams/system_flow.mmd
  + PERFORMANCE_BASELINE_v1.6.4.md

Commit Message:
  [REFACTOR-0.2] Document current architecture and baseline
```

#### **Task 0.3: Create Baseline Tests** ⏱️ 4h
```yaml
ID: REFACTOR-0.3
Priority: 🔴 CRITICAL
Dependencies: REFACTOR-0.1
Test Requirement: ALL TESTS MUST PASS (100% green)

Acceptance Criteria:
  ✅ test/baseline/ directory created
  ✅ Collision detection baseline test
  ✅ Scoring system baseline test
  ✅ Game state baseline test
  ✅ Story mode baseline test
  ✅ All tests passing

Tests to Create:
  1. test/baseline/collision_baseline_test.dart
     - Test jet-obstacle collision detection
     - Test ground collision
     - Test invulnerability
  
  2. test/baseline/scoring_baseline_test.dart
     - Test score increment
     - Test no double-scoring
     - Test bot scoring
  
  3. test/baseline/game_state_baseline_test.dart
     - Test game start
     - Test game over
     - Test continue mechanic
  
  4. test/baseline/story_mode_baseline_test.dart
     - Test level completion
     - Test level unlocking
     - Test reward distribution

Example Test:
  ```dart
  // test/baseline/collision_baseline_test.dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:flame_test/flame_test.dart';
  import '../../lib/game/flappy_game.dart';
  import '../helpers/test_helpers.dart';
  
  void main() {
    group('Baseline Collision Detection', () {
      testWithFlameGame(
        'Jet collides with obstacle',
        (game) async {
          final jet = game.jet;
          final obstacle = TestHelpers.createTestObstacle();
          
          await game.add(obstacle);
          await game.ready();
          
          // Move jet into obstacle
          jet.position = obstacle.position;
          game.update(0.016); // 1 frame
          
          // Baseline: Should detect collision
          expect(game.gameStateManager.isGameOver, true,
            reason: 'Collision should trigger game over');
        },
      );
      
      testWithFlameGame(
        'Jet passes through gap without collision',
        (game) async {
          final jet = game.jet;
          final obstacle = TestHelpers.createTestObstacle();
          
          await game.add(obstacle);
          await game.ready();
          
          // Position jet in gap
          jet.position.y = obstacle.position.y;
          game.update(0.016);
          
          // Baseline: Should NOT detect collision
          expect(game.gameStateManager.isGameOver, false,
            reason: 'Jet in gap should not collide');
        },
      );
    });
  }
  ```

Files Created:
  + test/baseline/collision_baseline_test.dart
  + test/baseline/scoring_baseline_test.dart
  + test/baseline/game_state_baseline_test.dart
  + test/baseline/story_mode_baseline_test.dart

Commit Message:
  [REFACTOR-0.3] Add baseline tests for current functionality
```

#### **Task 0.4: Setup Code Coverage Tracking** ⏱️ 2h
```yaml
ID: REFACTOR-0.4
Priority: 🟡 HIGH
Dependencies: REFACTOR-0.3
Test Requirement: Coverage report generated

Acceptance Criteria:
  ✅ Coverage configuration added
  ✅ Baseline coverage measured
  ✅ Coverage report HTML generated
  ✅ Coverage goals documented

Steps:
  1. Run: flutter test --coverage
  2. Install lcov: brew install lcov (Mac)
  3. Generate HTML: genhtml coverage/lcov.info -o coverage/html
  4. Document baseline coverage percentage
  5. Set target: 80% coverage

Files Created:
  + COVERAGE_BASELINE_v1.6.4.md
  ~ .gitignore (add coverage/)
  + .github/workflows/coverage.yml (CI)

Commit Message:
  [REFACTOR-0.4] Setup code coverage tracking and baseline
```

#### **Task 0.5: Create Refactoring Tracking Document** ⏱️ 1h
```yaml
ID: REFACTOR-0.5
Priority: 🟢 MEDIUM
Dependencies: None
Test Requirement: N/A (documentation)

Acceptance Criteria:
  ✅ CODE_DELETION_LOG.md created
  ✅ REFERENCE_UPDATE_CHECKLIST.md created
  ✅ REFACTORING_PROGRESS.md created

Files Created:
  + CODE_DELETION_LOG.md (track what's deleted)
  + REFERENCE_UPDATE_CHECKLIST.md (track updates)
  + REFACTORING_PROGRESS.md (daily progress)

Commit Message:
  [REFACTOR-0.5] Create refactoring tracking documents
```

#### **Task 0.6: Performance Baseline Measurement** ⏱️ 3h
```yaml
ID: REFACTOR-0.6
Priority: 🔴 CRITICAL
Dependencies: REFACTOR-0.3
Test Requirement: Benchmark tests created

Acceptance Criteria:
  ✅ Performance benchmark tests created
  ✅ FPS measured (baseline)
  ✅ Memory usage measured (baseline)
  ✅ Frame time measured (baseline)
  ✅ Vector2 allocation count measured

Benchmark Tests:
  ```dart
  // test/performance/fps_benchmark_test.dart
  void main() {
    test('FPS benchmark with 20 obstacles', () async {
      final game = TestHelpers.createTestGame();
      await game.onLoad();
      
      // Add 20 obstacles
      for (int i = 0; i < 20; i++) {
        game.add(TestHelpers.createTestObstacle());
      }
      
      final stopwatch = Stopwatch()..start();
      int frames = 0;
      
      // Run for 1 second
      while (stopwatch.elapsedMilliseconds < 1000) {
        game.update(0.016); // 60 FPS target
        frames++;
      }
      
      final fps = frames / stopwatch.elapsed.inSeconds;
      print('Baseline FPS: $fps');
      
      // Store baseline for comparison
      expect(fps, greaterThan(30), reason: 'Should maintain 30+ FPS');
    });
  }
  ```

Files Created:
  + test/performance/fps_benchmark_test.dart
  + test/performance/memory_benchmark_test.dart
  + test/performance/frame_time_benchmark_test.dart
  + PERFORMANCE_BASELINE_v1.6.4.md

Commit Message:
  [REFACTOR-0.6] Add performance baseline benchmarks
```

#### **Task 0.7: Setup CI/CD Pipeline** ⏱️ 2h
```yaml
ID: REFACTOR-0.7
Priority: 🟡 HIGH
Dependencies: REFACTOR-0.1, REFACTOR-0.3, REFACTOR-0.4
Test Requirement: CI runs and passes

Acceptance Criteria:
  ✅ GitHub Actions workflow created
  ✅ Runs on every commit
  ✅ Runs all tests
  ✅ Generates coverage report
  ✅ Fails if coverage decreases

Files Created:
  + .github/workflows/refactoring_ci.yml

Workflow:
  ```yaml
  name: Refactoring CI
  
  on: [push, pull_request]
  
  jobs:
    test:
      runs-on: macos-latest
      steps:
        - uses: actions/checkout@v3
        - uses: subosito/flutter-action@v2
          with:
            channel: stable
        - run: flutter pub get
        - run: flutter analyze
        - run: flutter test --coverage
        - run: flutter test test/baseline/
        - name: Upload coverage
          uses: codecov/codecov-action@v3
  ```

Commit Message:
  [REFACTOR-0.7] Setup CI/CD pipeline for refactoring
```

---

### **📦 PHASE 1: FLAME COLLISION SYSTEM** (Day 3-4, 16h)

#### **Task 1.1: Write Collision Tests (TDD Red)** ⏱️ 3h
```yaml
ID: REFACTOR-1.1
Priority: 🔴 CRITICAL
Dependencies: REFACTOR-0.3
Test Requirement: Tests written (but failing)

Acceptance Criteria:
  ✅ Collision tests written for Flame system
  ✅ Tests are failing (RED phase)
  ✅ Test coverage plan documented

Tests to Write:
  ```dart
  // test/game/collision/flame_collision_test.dart
  void main() {
    group('Flame Collision System', () {
      testWithFlameGame(
        'JetPlayer has CircleHitbox',
        (game) async {
          final jet = game.jet;
          
          // Test: Jet should have exactly one CircleHitbox
          final hitboxes = jet.children.whereType<CircleHitbox>();
          expect(hitboxes.length, 1);
          
          // Test: Hitbox should be 70% of jet width
          final hitbox = hitboxes.first;
          expect(hitbox.radius, jet.size.x * 0.35);
        },
      );
      
      testWithFlameGame(
        'Obstacle has two RectangleHitboxes',
        (game) async {
          final obstacle = TestHelpers.createTestObstacle();
          await game.add(obstacle);
          
          // Test: Obstacle should have top + bottom hitboxes
          final hitboxes = obstacle.children.whereType<RectangleHitbox>();
          expect(hitboxes.length, 2);
        },
      );
      
      testWithFlameGame(
        'Collision detected between jet and obstacle',
        (game) async {
          final jet = game.jet;
          final obstacle = TestHelpers.createTestObstacle();
          
          await game.add(obstacle);
          await game.ready();
          
          // Setup: Enable Flame collision
          jet.enableFlameCollision();
          obstacle.enableFlameCollision();
          
          // Action: Move jet into obstacle
          jet.position = obstacle.position;
          game.update(0.016);
          
          // Assert: Game should be over
          expect(game.gameStateManager.isGameOver, true);
        },
      );
      
      testWithFlameGame(
        'No false collision in gap',
        (game) async {
          final jet = game.jet;
          final obstacle = TestHelpers.createTestObstacle();
          
          await game.add(obstacle);
          jet.enableFlameCollision();
          obstacle.enableFlameCollision();
          
          // Position jet perfectly in gap
          jet.position.x = obstacle.position.x + 10;
          jet.position.y = obstacle.position.y;
          
          game.update(0.016);
          
          // Should NOT trigger collision
          expect(game.gameStateManager.isGameOver, false);
        },
      );
      
      testWithFlameGame(
        'Invulnerability prevents collision',
        (game) async {
          final jet = game.jet;
          final obstacle = TestHelpers.createTestObstacle();
          
          await game.add(obstacle);
          jet.enableFlameCollision();
          obstacle.enableFlameCollision();
          jet.setInvulnerable(true);
          
          // Collide while invulnerable
          jet.position = obstacle.position;
          game.update(0.016);
          
          // Should NOT game over
          expect(game.gameStateManager.isGameOver, false);
        },
      );
    });
  }
  ```

Files Created:
  + test/game/collision/flame_collision_test.dart
  + test/game/collision/hitbox_test.dart
  + test/game/collision/collision_callbacks_test.dart

Commit Message:
  [REFACTOR-1.1] Write Flame collision tests (TDD Red phase)
  
Status: Tests FAIL (expected) ❌
```

#### **Task 1.2: Add HasCollisionDetection Mixin** ⏱️ 1h
```yaml
ID: REFACTOR-1.2
Priority: 🔴 CRITICAL
Dependencies: REFACTOR-1.1
Test Requirement: Mixin added, still failing

Acceptance Criteria:
  ✅ FlappyGame extends FlameGame with HasCollisionDetection
  ✅ Quadtree collision detection configured
  ✅ Code compiles without errors
  ✅ Tests still failing (expected)

Implementation:
  ```dart
  // lib/game/flappy_game.dart
  import 'package:flame/collisions.dart';
  
  class FlappyGame extends FlameGame with HasCollisionDetection {
    @override
    Future<void> onLoad() async {
      await super.onLoad();
      
      // Configure Flame collision detection
      collisionDetection = QuadTreeCollisionDetection(
        minimumDistance: const Vector2.all(50),
        mapDimensions: size,
      );
      
      if (kDebugMode) {
        debugMode = true; // Show hitboxes in debug
      }
      
      // ... rest of onLoad
    }
  }
  ```

Files Modified:
  ~ lib/game/flappy_game.dart

Commit Message:
  [REFACTOR-1.2] Add HasCollisionDetection mixin to FlappyGame
  
Status: Tests FAIL (expected) ❌
```

#### **Task 1.3: Add CircleHitbox to JetPlayer** ⏱️ 2h
```yaml
ID: REFACTOR-1.3
Priority: 🔴 CRITICAL
Dependencies: REFACTOR-1.2
Test Requirement: Hitbox tests now pass

Acceptance Criteria:
  ✅ JetPlayer implements CollisionCallbacks
  ✅ CircleHitbox added in onLoad()
  ✅ Collision callbacks implemented
  ✅ Hitbox tests pass ✅

Implementation:
  ```dart
  // lib/game/components/jet_player.dart
  import 'package:flame/collisions.dart';
  
  class JetPlayer extends SpriteComponent 
      with HasGameReference<FlappyGame>, CollisionCallbacks {
    
    late CircleHitbox _hitbox;
    
    @override
    Future<void> onLoad() async {
      await super.onLoad();
      
      // Load sprite, setup existing code...
      
      // ✅ Add Flame hitbox
      _hitbox = CircleHitbox(
        radius: size.x * 0.35, // 70% of jet width
        anchor: Anchor.center,
        position: size / 2,
        isSolid: true,
      );
      _hitbox.collisionType = CollisionType.active;
      add(_hitbox);
      
      safePrint('✅ JetPlayer Flame hitbox created');
    }
    
    @override
    void onCollisionStart(
      Set<Vector2> intersectionPoints,
      PositionComponent other,
    ) {
      safePrint('🔥 FLAME COLLISION: ${other.runtimeType}');
      
      if (other is DynamicObstacle && !_isInvulnerable) {
        _handleObstacleCollision();
      }
    }
    
    @override
    void onCollisionEnd(PositionComponent other) {
      // Cleanup if needed
    }
    
    void _handleObstacleCollision() {
      gameRef.handleCollision();
    }
  }
  ```

Files Modified:
  ~ lib/game/components/jet_player.dart

Tests Passing:
  ✅ test/game/collision/flame_collision_test.dart::JetPlayer has CircleHitbox

Commit Message:
  [REFACTOR-1.3] Add CircleHitbox to JetPlayer with callbacks
  
Status: Some tests pass ✅, some still fail ❌
```

#### **Task 1.4: Add RectangleHitboxes to DynamicObstacle** ⏱️ 2h
```yaml
ID: REFACTOR-1.4
Priority: 🔴 CRITICAL
Dependencies: REFACTOR-1.3
Test Requirement: Obstacle hitbox tests pass

Acceptance Criteria:
  ✅ DynamicObstacle implements CollisionCallbacks
  ✅ Two RectangleHitboxes added (top + bottom)
  ✅ Passive collision type (performance)
  ✅ Hitboxes align with visual sprites
  ✅ Obstacle hitbox tests pass ✅

Implementation:
  ```dart
  // lib/game/components/dynamic_obstacle.dart
  import 'package:flame/collisions.dart';
  
  class DynamicObstacle extends PositionComponent 
      with CollisionCallbacks {
    
    late RectangleHitbox _topHitbox;
    late RectangleHitbox _bottomHitbox;
    
    @override
    Future<void> onLoad() async {
      await super.onLoad();
      
      // Calculate gap positions
      final gapTop = position.y - gapSize / 2;
      final gapBottom = position.y + gapSize / 2;
      
      // ✅ Top pillar hitbox
      _topHitbox = RectangleHitbox(
        size: Vector2(_visualWidth, gapTop),
        position: Vector2(_visualXOffset, -position.y),
        isSolid: true,
      );
      _topHitbox.collisionType = CollisionType.passive;
      add(_topHitbox);
      
      // ✅ Bottom pillar hitbox
      _bottomHitbox = RectangleHitbox(
        size: Vector2(_visualWidth, gameRef.size.y - gapBottom),
        position: Vector2(_visualXOffset, gapBottom - position.y),
        isSolid: true,
      );
      _bottomHitbox.collisionType = CollisionType.passive;
      add(_bottomHitbox);
      
      safePrint('✅ DynamicObstacle Flame hitboxes created');
    }
  }
  ```

Files Modified:
  ~ lib/game/components/dynamic_obstacle.dart

Tests Passing:
  ✅ test/game/collision/flame_collision_test.dart::Obstacle has two RectangleHitboxes

Commit Message:
  [REFACTOR-1.4] Add RectangleHitboxes to DynamicObstacle
  
Status: More tests pass ✅
```

#### **Task 1.5: Integrate Flame Collision into Game Loop** ⏱️ 2h
```yaml
ID: REFACTOR-1.5
Priority: 🔴 CRITICAL
Dependencies: REFACTOR-1.4
Test Requirement: Flame collision working, old system removed

Acceptance Criteria:
  ✅ Flame collision fully integrated
  ✅ _checkCollisions() simplified
  ✅ Old collision system no longer called
  ✅ All tests pass

Implementation:
  ```dart
  // lib/game/flappy_game.dart
  class FlappyGame extends FlameGame with HasCollisionDetection {
    @override
    Future<void> onLoad() async {
      await super.onLoad();
      
      // ... setup collision detection
      
      // ✅ Collision automatically handled by Flame via CollisionCallbacks
      // JetPlayer.onCollisionStart() will handle collision events
      safePrint('🔥 Using Flame collision detection');
    }
    
    void _checkCollisions() {
      // ✅ Flame handles collisions automatically via CollisionCallbacks
      // No manual collision checking needed!
      
      // Only manual check: ceiling collision (simple boundary check)
      if (_collisionSystem.checkCeilingCollision(_jet)) {
        _collisionSystem.handleCeilingCollision(_jet);
      }
      
      // Bot collision checks remain manual (for now - will be refactored later)
      if (_botJet != null) {
        _checkBotCollisions();
      }
    }
  }
  ```

Files Modified:
  ~ lib/game/flappy_game.dart

Commit Message:
  [REFACTOR-1.5] Integrate Flame collision into game loop
  
Status: Tests passing ✅
```

#### **Task 1.6: Add Score Trigger Zones** ⏱️ 3h
```yaml
ID: REFACTOR-1.6
Priority: 🔴 CRITICAL
Dependencies: REFACTOR-1.5
Test Requirement: Scoring tests pass

Acceptance Criteria:
  ✅ ScoreTrigger component created
  ✅ Sensor hitbox (doesn't block)
  ✅ Scores on collision once
  ✅ No double-scoring possible
  ✅ Scoring tests pass ✅

Implementation:
  ```dart
  // lib/game/components/score_trigger.dart (NEW FILE)
  import 'package:flame/collisions.dart';
  import 'package:flame/components.dart';
  import '../flappy_game.dart';
  import 'jet_player.dart';
  
  /// Invisible trigger zone for scoring
  class ScoreTrigger extends PositionComponent 
      with CollisionCallbacks, HasGameReference<FlappyGame> {
    
    final DynamicObstacle parentObstacle;
    bool scored = false;
    
    ScoreTrigger({
      required this.parentObstacle,
      required Vector2 position,
      required double gameHeight,
    }) : super(
      position: position,
      size: Vector2(10, gameHeight), // Thin vertical line
    );
    
    @override
    Future<void> onLoad() async {
      await super.onLoad();
      
      // ✅ Sensor hitbox (doesn't block movement)
      final hitbox = RectangleHitbox(
        size: size,
        isSolid: false, // SENSOR!
      );
      hitbox.collisionType = CollisionType.passive;
      add(hitbox);
      
      priority = -1; // Invisible
    }
    
    @override
    void onCollisionStart(Set<Vector2> points, PositionComponent other) {
      if (other is JetPlayer && !scored) {
        scored = true;
        gameRef.incrementScore();
        gameRef.onObstaclePassed?.call(); // Story mode
        safePrint('🎯 Score trigger activated');
      }
    }
  }
  
  // Update DynamicObstacle to add score trigger:
  class DynamicObstacle extends PositionComponent with CollisionCallbacks {
    late ScoreTrigger _scoreTrigger;
    
    @override
    Future<void> onLoad() async {
      await super.onLoad();
      
      // Add hitboxes...
      
      // ✅ Add score trigger at center
      _scoreTrigger = ScoreTrigger(
        parentObstacle: this,
        position: Vector2(position.x + _visualWidth / 2, 0),
        gameHeight: gameRef.size.y,
      );
      gameRef.add(_scoreTrigger);
    }
  }
  ```

Files Created:
  + lib/game/components/score_trigger.dart

Files Modified:
  ~ lib/game/components/dynamic_obstacle.dart

Tests Passing:
  ✅ test/baseline/scoring_baseline_test.dart (all tests)

Commit Message:
  [REFACTOR-1.6] Add score trigger zones with sensor hitboxes
  
Status: Scoring works with Flame ✅
```

#### **Task 1.7: Remove Legacy Collision System** ⏱️ 2h
```yaml
ID: REFACTOR-1.7
Priority: 🔴 CRITICAL (after validation)
Dependencies: REFACTOR-1.6 + manual testing
Test Requirement: All tests still pass

Acceptance Criteria:
  ✅ CollisionSystem class deleted
  ✅ All references removed
  ✅ All tests pass ✅
  ✅ CODE_DELETION_LOG.md updated
  ✅ Manual gameplay confirms collision works perfectly

Steps:
  1. Document deletion in CODE_DELETION_LOG.md
  2. Find all usages: grep -r "CollisionSystem" lib/
  3. Remove lib/game/systems/collision_system.dart
  4. Remove _collisionSystem field from FlappyGame
  5. Remove manual collision check loops
  6. Run flutter analyze
  7. Run all tests
  8. Manual gameplay testing (30 min)

Files Deleted:
  - lib/game/systems/collision_system.dart (54 lines deleted)

Files Modified:
  ~ lib/game/flappy_game.dart (removed _collisionSystem, simplified _checkCollisions())
  ~ CODE_DELETION_LOG.md

Commit Message:
  [REFACTOR-1.7] Remove legacy collision system (Flame handles all collision)
  
Status: Clean migration complete ✅
```

#### **Task 1.8: Integration Testing** ⏱️ 1h
```yaml
ID: REFACTOR-1.8
Priority: 🔴 CRITICAL
Dependencies: REFACTOR-1.7
Test Requirement: All integration tests pass

Acceptance Criteria:
  ✅ 50 games played in endless mode
  ✅ 10 story mode levels completed
  ✅ 5 bot battles completed
  ✅ No regressions found
  ✅ Feel identical or better

Testing Protocol:
  1. Play 50 endless mode games
  2. Test all jet skins
  3. Test all themes
  4. Complete 10 story mode levels
  5. Fight 5 bot battles
  6. Document any issues

Files Created:
  + test/integration/collision_integration_test.dart

Commit Message:
  [REFACTOR-1.8] Validate Flame collision with integration tests
  
Status: Production-ready ✅
```

---

### **📦 PHASE 2: BEHAVIOR PATTERN SYSTEM** (Day 5-6, 16h)

#### **Task 2.1: Write Behavior Tests (TDD Red)** ⏱️ 2h
```yaml
ID: REFACTOR-2.1
Priority: 🔴 CRITICAL
Dependencies: REFACTOR-1.8
Test Requirement: Behavior tests written (failing)

Tests to Write:
  ```dart
  // test/game/behaviors/gravity_behavior_test.dart
  void main() {
    group('GravityBehavior', () {
      test('applies gravity to velocity', () {
        final velocity = Vector2.zero();
        final behavior = GravityBehavior(velocity: velocity);
        
        behavior.update(1.0); // 1 second
        
        expect(velocity.y, GameConfig.gravity);
      });
      
      test('caps at terminal velocity', () {
        final velocity = Vector2(0, 1000);
        final behavior = GravityBehavior(
          velocity: velocity,
          maxFallSpeed: 800.0,
        );
        
        behavior.update(1.0);
        
        expect(velocity.y, 800.0); // Capped
      });
      
      test('creates zero allocations in update', () {
        final velocity = Vector2.zero();
        final behavior = GravityBehavior(velocity: velocity);
        
        // TODO: Add allocation tracking
        for (int i = 0; i < 1000; i++) {
          behavior.update(0.016);
        }
        
        // Assert: No Vector2 allocations
      });
    });
  }
  ```

Files Created:
  + test/game/behaviors/gravity_behavior_test.dart
  + test/game/behaviors/jump_behavior_test.dart
  + test/game/behaviors/damage_visualization_behavior_test.dart
  + test/game/behaviors/invulnerability_behavior_test.dart

Commit Message:
  [REFACTOR-2.1] Write behavior pattern tests (TDD Red)
  
Status: Tests FAIL (expected) ❌
```

#### **Task 2.2: Create GravityBehavior** ⏱️ 2h
```yaml
ID: REFACTOR-2.2
Priority: 🔴 CRITICAL
Dependencies: REFACTOR-2.1
Test Requirement: GravityBehavior tests pass

Implementation:
  ```dart
  // lib/game/behaviors/gravity_behavior.dart (NEW FILE)
  import 'package:flame/components.dart';
  import '../core/game_config.dart';
  
  /// Applies gravity physics to any component with velocity
  /// 
  /// Zero allocations: Pre-calculates gravity vector
  class GravityBehavior extends Behavior<PositionComponent> {
    final Vector2 velocity;
    final double gravityMultiplier;
    final double maxFallSpeed;
    
    // ✅ Pre-allocated vector (ZERO allocations per frame!)
    late final Vector2 _gravityVector;
    
    GravityBehavior({
      required this.velocity,
      this.gravityMultiplier = 1.0,
      this.maxFallSpeed = 800.0,
    }) {
      _gravityVector = Vector2(0, GameConfig.gravity * gravityMultiplier);
    }
    
    @override
    void update(double dt) {
      // Apply gravity (no new allocations!)
      velocity.add(_gravityVector * dt);
      
      // Cap at terminal velocity
      if (velocity.y > maxFallSpeed) {
        velocity.y = maxFallSpeed;
      }
    }
  }
  ```

Files Created:
  + lib/game/behaviors/gravity_behavior.dart

Tests Passing:
  ✅ test/game/behaviors/gravity_behavior_test.dart

Commit Message:
  [REFACTOR-2.2] Create GravityBehavior with zero allocations
  
Status: Tests pass ✅
```

#### **Task 2.3: Create JumpBehavior** ⏱️ 2h
```yaml
ID: REFACTOR-2.3
Priority: 🔴 CRITICAL
Dependencies: REFACTOR-2.2
Test Requirement: JumpBehavior tests pass

Implementation:
  ```dart
  // lib/game/behaviors/jump_behavior.dart (NEW FILE)
  import 'package:flame/components.dart';
  import '../core/game_config.dart';
  
  /// Handles jump mechanic with anticipation and follow-through
  class JumpBehavior extends Behavior<PositionComponent> {
    final Vector2 velocity;
    final double jumpForce;
    final double jumpCooldown;
    
    late final Vector2 _jumpVector;
    double _cooldownTimer = 0.0;
    
    JumpBehavior({
      required this.velocity,
      this.jumpForce = GameConfig.jumpForce,
      this.jumpCooldown = 0.1,
    }) {
      _jumpVector = Vector2(0, -jumpForce);
    }
    
    bool get canJump => _cooldownTimer <= 0;
    
    void jump() {
      if (!canJump) return;
      
      velocity.setFrom(_jumpVector);
      _cooldownTimer = jumpCooldown;
      
      // Trigger squash/stretch animation
      if (parent is SpriteComponent) {
        _playJumpAnimation();
      }
    }
    
    void _playJumpAnimation() {
      // Squash
      parent.scale = Vector2(1.2, 0.8);
      
      // Stretch
      Future.delayed(const Duration(milliseconds: 50), () {
        if (parent.isMounted) {
          parent.scale = Vector2(0.9, 1.1);
        }
      });
      
      // Return
      Future.delayed(const Duration(milliseconds: 150), () {
        if (parent.isMounted) {
          parent.scale = Vector2.all(1.0);
        }
      });
    }
    
    @override
    void update(double dt) {
      if (_cooldownTimer > 0) {
        _cooldownTimer -= dt;
      }
    }
  }
  ```

Files Created:
  + lib/game/behaviors/jump_behavior.dart

Tests Passing:
  ✅ test/game/behaviors/jump_behavior_test.dart

Commit Message:
  [REFACTOR-2.3] Create JumpBehavior with squash/stretch
  
Status: Tests pass ✅
```

#### **Task 2.4-2.5: Create DamageVisualization & Invulnerability Behaviors** ⏱️ 3h
```yaml
IDs: REFACTOR-2.4, REFACTOR-2.5
Priority: 🔴 CRITICAL
Dependencies: REFACTOR-2.3
Test Requirement: Both behavior tests pass

# Similar pattern to above tasks
# Create behaviors with tests first, then implement

Files Created:
  + lib/game/behaviors/damage_visualization_behavior.dart
  + lib/game/behaviors/invulnerability_behavior.dart

Commit Messages:
  [REFACTOR-2.4] Create DamageVisualizationBehavior
  [REFACTOR-2.5] Create InvulnerabilityBehavior
```

#### **Task 2.6: Refactor JetPlayer to Use Behaviors** ⏱️ 4h
```yaml
ID: REFACTOR-2.6
Priority: 🔴 CRITICAL
Dependencies: REFACTOR-2.5
Test Requirement: JetPlayer tests pass, code reduced

Acceptance Criteria:
  ✅ JetPlayer uses all 4 behaviors
  ✅ Lines of code reduced by 30%+
  ✅ All JetPlayer tests pass
  ✅ Gameplay identical

Before:
  - lib/game/components/jet_player.dart: 766 lines

After:
  - lib/game/components/jet_player.dart: ~500 lines
  - lib/game/behaviors/*.dart: 300 lines (4 behaviors)
  
Net: Same functionality, better organized!

Implementation:
  ```dart
  // lib/game/components/jet_player.dart (REFACTORED)
  class JetPlayer extends SpriteComponent 
      with HasGameReference<FlappyGame>, CollisionCallbacks {
    
    Vector2 velocity = Vector2.zero();
    
    // ✅ Behaviors handle specific concerns
    late GravityBehavior _gravityBehavior;
    late JumpBehavior _jumpBehavior;
    late DamageVisualizationBehavior _damageVisualization;
    late InvulnerabilityBehavior _invulnerability;
    
    @override
    Future<void> onLoad() async {
      await super.onLoad();
      
      // Load sprite, add hitbox...
      
      // ✅ Add behaviors
      _gravityBehavior = GravityBehavior(velocity: velocity);
      _jumpBehavior = JumpBehavior(velocity: velocity);
      _damageVisualization = DamageVisualizationBehavior();
      _invulnerability = InvulnerabilityBehavior(
        onActivate: () {
          _damageVisualization.setDamageState(JetDamageState.invulnerable);
        },
        onDeactivate: () {
          _damageVisualization.applyPendingState();
        },
      );
      
      add(_gravityBehavior);
      add(_jumpBehavior);
      add(_damageVisualization);
      add(_invulnerability);
    }
    
    void jump() {
      if (!gameRef.gameStateManager.isPlaying) return;
      _jumpBehavior.jump();
      gameRef.audioManager.playSfx('jump');
    }
    
    @override
    void update(double dt) {
      // ✅ Behaviors handle:
      // - Gravity (_gravityBehavior)
      // - Damage visualization (_damageVisualization)
      // - Invulnerability timer (_invulnerability)
      
      // ✅ JetPlayer only handles:
      // - Position updates
      // - Boundary checks
      
      position.add(velocity * dt);
      
      // Boundaries
      if (position.y > gameRef.size.y - size.y / 2) {
        position.y = gameRef.size.y - size.y / 2;
        velocity.y = 0;
      }
    }
  }
  ```

Files Modified:
  ~ lib/game/components/jet_player.dart (766→500 lines, -34%)

Tests Passing:
  ✅ test/game/components/jet_player_test.dart
  ✅ test/baseline/game_state_baseline_test.dart

Commit Message:
  [REFACTOR-2.6] Refactor JetPlayer to use Behavior pattern
  
Status: Cleaner, testable, modular ✅
```

#### **Task 2.7: Apply Behaviors to BotJetPlayer** ⏱️ 2h
```yaml
ID: REFACTOR-2.7
Priority: 🟡 HIGH
Dependencies: REFACTOR-2.6
Test Requirement: BotJetPlayer tests pass

# Bot reuses same behaviors (no duplication!)

Files Modified:
  ~ lib/game/components/bot_jet_player.dart

Commit Message:
  [REFACTOR-2.7] Apply behaviors to BotJetPlayer (code reuse)
```

#### **Task 2.8: Integration Testing** ⏱️ 1h
```yaml
ID: REFACTOR-2.8
Priority: 🔴 CRITICAL
Dependencies: REFACTOR-2.7
Test Requirement: All integration tests pass

# Manual testing + automated integration tests

Commit Message:
  [REFACTOR-2.8] Validate behavior pattern with integration tests
```

---

### **📦 PHASE 3: EFFECT SYSTEM & CAMERA** (Day 7-8, 16h)

#### **Tasks 3.1-3.8: Effect System Migration**
```yaml
Similar TDD pattern:
- Write tests first (TDD Red)
- Implement effects (TDD Green)
- Replace manual animations (Refactor)
- Delete old code
- Integration test

Effects to implement:
- MoveEffect (bobbing animation)
- ScaleEffect (celebration)
- ColorEffect (damage flash)
- SequenceEffect (multi-stage animations)
- CameraComponent + World

Expected outcome:
- Professional easing curves
- Smooth transitions
- Camera shake effects
- ~200 lines of manual animation code deleted
```

---

### **📦 PHASE 4: PERFORMANCE OPTIMIZATION** (Day 9, 8h)

#### **Tasks 4.1-4.6: Zero-Allocation Optimization**
```yaml
- Vector pooling
- Paint object reuse
- Collision filtering optimization
- Performance benchmarks
- Memory profiling

Expected outcome:
- 80% reduction in Vector2 allocations
- 60% reduction in collision checks
- 20%+ FPS improvement
```

---

### **📦 PHASE 5: FINAL POLISH** (Day 10, 8h)

#### **Tasks 5.1-5.5: Documentation & Release**
```yaml
- Update architecture docs
- Write migration guide
- Create release notes
- Final integration testing
- Deploy to beta
```

---

## 📝 **CODE DELETION LOG**

### **Template: CODE_DELETION_LOG.md**

```markdown
# Code Deletion Log - v1.7.0 Refactoring

## Format
Each deletion must document:
- File path
- Lines deleted
- Reason for deletion
- Replacement (if any)
- Date deleted
- Commit SHA

## Deletions

### 2025-10-16: CollisionSystem Removed
- **File**: lib/game/systems/collision_system.dart
- **Lines**: 54 lines deleted
- **Reason**: Replaced with Flame's native collision detection
- **Replacement**: HasCollisionDetection mixin, CollisionCallbacks
- **Commit**: [REFACTOR-1.7] abc123f
- **Impact**: -156 lines in FlappyGame (removed manual collision logic)

### 2025-10-17: Manual Gravity Code Removed
- **File**: lib/game/components/jet_player.dart
- **Lines**: Lines 340-365 (gravity calculation)
- **Reason**: Replaced with GravityBehavior
- **Replacement**: GravityBehavior (lib/game/behaviors/gravity_behavior.dart)
- **Commit**: [REFACTOR-2.6] def456a
- **Impact**: -266 lines in JetPlayer

### 2025-10-17: Manual Jump Animation Removed
- **File**: lib/game/components/jet_player.dart
- **Lines**: Lines 400-435 (jump animation)
- **Reason**: Replaced with JumpBehavior
- **Replacement**: JumpBehavior (lib/game/behaviors/jump_behavior.dart)
- **Commit**: [REFACTOR-2.6] def456a
- **Impact**: Included in JetPlayer refactor

## Summary Statistics

Total Lines Deleted: 476
Total Files Deleted: 1
Net Change: +300 new behavior files, -476 old code = -176 net lines
Code Quality: ⬆️ IMPROVED (more modular, testable, maintainable)
```

---

## ✅ **REFERENCE UPDATE CHECKLIST**

### **Template: REFERENCE_UPDATE_CHECKLIST.md**

```markdown
# Reference Update Checklist - v1.7.0

## When Deleting/Refactoring Code

### ✅ Step 1: Find All Usages
- [ ] Run: `grep -r "ClassName" lib/`
- [ ] Run: `grep -r "ClassName" test/`
- [ ] Use IDE "Find Usages" feature
- [ ] Check imports in all files

### ✅ Step 2: Update Imports
- [ ] Update all import statements
- [ ] Remove unused imports
- [ ] Run: `flutter analyze`

### ✅ Step 3: Update Documentation
- [ ] Update README.md (if applicable)
- [ ] Update ARCHITECTURE_v1.7.0.md
- [ ] Update inline code comments
- [ ] Update method documentation

### ✅ Step 4: Update Tests
- [ ] Update test imports
- [ ] Update test assertions
- [ ] Update mock objects
- [ ] Run: `flutter test`

### ✅ Step 5: Update Examples
- [ ] Update code examples in docs
- [ ] Update tutorial code
- [ ] Update integration test scenarios

### ✅ Step 6: Verify
- [ ] `flutter analyze` passes
- [ ] `flutter test` passes
- [ ] Manual gameplay test (5 min)
- [ ] No console errors

## Example: Collision System Refactoring

### CollisionSystem → Flame Collision
- [x] Find usages: `grep -r "CollisionSystem" lib/`
  - Found in: flappy_game.dart, test files
- [x] Update imports in flappy_game.dart
  - Removed: `import 'systems/collision_system.dart';`
  - Added: `import 'package:flame/collisions.dart';`
- [x] Update FlappyGame class
  - Removed: `late CollisionSystem _collisionSystem;`
  - Added: `with HasCollisionDetection`
- [x] Update _checkCollisions() method
  - Removed: Manual collision checks
  - Added: Flame collision callbacks
- [x] Update test/game/collision_test.dart
  - Updated: All test assertions
  - Added: New Flame collision tests
- [x] Verify
  - [x] flutter analyze: PASS
  - [x] flutter test: PASS
  - [x] Manual test: PASS
```

---

## 🎯 **SUCCESS CRITERIA**

### **Technical Metrics**

| Metric | Baseline (v1.6.4) | Target (v1.7.0) | Must Pass |
|--------|-------------------|-----------------|-----------|
| **FPS (20 obstacles)** | 48.5 | 58+ | ✅ CRITICAL |
| **Frame time (p95)** | 24ms | <17ms | ✅ CRITICAL |
| **Vector2 allocations/sec** | 900 | <180 | ✅ HIGH |
| **Memory usage** | 145 MB | <120 MB | ✅ HIGH |
| **Test coverage** | 45% | 80%+ | ✅ CRITICAL |
| **Lines of code** | 766 (JetPlayer) | <550 | ✅ MEDIUM |
| **Cyclomatic complexity** | 35 (FlappyGame) | <20 | ✅ MEDIUM |

### **Code Quality**

- ✅ All baseline tests pass
- ✅ All new tests pass
- ✅ No linter warnings
- ✅ No deprecated code
- ✅ Architecture documented
- ✅ Migration guide complete

### **Gameplay**

- ✅ No regressions
- ✅ Feel identical or better
- ✅ All modes work (endless, story, bot battles)
- ✅ All features functional
- ✅ Performance improved

---

## 📊 **PROGRESS TRACKING**

### **Daily Checklist Template**

```markdown
# Day X Progress - [Date]

## Tasks Completed
- [ ] REFACTOR-X.1: Task name
- [ ] REFACTOR-X.2: Task name
- [ ] REFACTOR-X.3: Task name

## Tests Written
- test/path/to/test_file.dart (15 tests)

## Tests Passing
- ✅ Unit: 45/45
- ✅ Integration: 12/12
- ✅ Baseline: 18/18

## Code Changes
- Files modified: 5
- Lines added: +250
- Lines deleted: -150
- Net change: +100

## Issues Found
- None

## Blockers
- None

## Tomorrow's Plan
- Start REFACTOR-Y.1
- Complete REFACTOR-Y.2
- Integration testing
```

---

## 🚀 **COMMIT STRATEGY**

### **Commit Message Format**

```
[REFACTOR-X.Y] Short description

Longer description if needed.

Changes:
- Added: Feature A
- Modified: Feature B
- Deleted: Feature C

Tests:
- test/path/test_file.dart (3 new tests)

Status: Tests passing ✅ / Tests failing ❌
```

### **Branch Strategy**

```
main (v1.6.4 - stable)
  └─> v1.7.0-refactoring (refactoring branch)
      ├─> phase-1-collision (Phase 1 work)
      ├─> phase-2-behaviors (Phase 2 work)
      ├─> phase-3-effects (Phase 3 work)
      └─> etc.
```

---

**Document Version**: 1.0  
**Last Updated**: October 16, 2025  
**Status**: READY FOR EXECUTION  
**Next Step**: Task REFACTOR-0.1 (Setup Testing Infrastructure)

---

**"Make it work, make it right, make it fast"** - Kent Beck  
**"Tests are the specifications of the code"** - Robert C. Martin  
**"Clean code is simple and direct"** - Bjarne Stroustrup

🚀 **Let's build production-grade code!**

