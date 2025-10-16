# ✅ Reference Update Checklist - v1.7.0 Refactoring

**Purpose**: Ensure all code references are updated when refactoring  
**Created**: October 16, 2025  
**Status**: ACTIVE

---

## 🎯 **Standard Update Process**

### **Before Any Deletion/Refactoring**

#### Step 1: Find All Usages 🔍
```bash
# Search entire codebase
grep -r "ClassName" lib/
grep -r "ClassName" test/
grep -r "ClassName" integration_test/

# Use IDE features
# VS Code: Right-click → Find All References
# Android Studio: Alt+F7
```

#### Step 2: Document Findings 📝
- [ ] List all files using this code
- [ ] Note import statements
- [ ] Note method calls
- [ ] Note type references

#### Step 3: Plan Updates 📋
- [ ] Identify replacement code
- [ ] Plan import changes
- [ ] Plan method call changes
- [ ] Plan test updates

### **During Refactoring**

#### Step 4: Update Imports 📦
```dart
// Before
import 'systems/collision_system.dart';

// After
import 'package:flame/collisions.dart';
```

- [ ] Update all import statements
- [ ] Remove unused imports
- [ ] Add new imports
- [ ] Organize imports (flutter analyze)

#### Step 5: Update Code References 🔧
- [ ] Update class instantiations
- [ ] Update method calls
- [ ] Update type annotations
- [ ] Update parameter passing

#### Step 6: Update Documentation 📚
- [ ] Update README.md
- [ ] Update ARCHITECTURE.md
- [ ] Update inline comments
- [ ] Update method documentation
- [ ] Update example code

#### Step 7: Update Tests 🧪
- [ ] Update test imports
- [ ] Update test setup
- [ ] Update mock objects
- [ ] Update assertions
- [ ] Add new tests if needed

### **After Refactoring**

#### Step 8: Verify Changes ✅
- [ ] Run `flutter analyze`
- [ ] Run `flutter test`
- [ ] Run `flutter test --coverage`
- [ ] Manual gameplay test (5 min)
- [ ] Check console for errors

#### Step 9: Update Tracking Documents 📊
- [ ] Update CODE_DELETION_LOG.md
- [ ] Update REFACTORING_PROGRESS.md
- [ ] Update this checklist

#### Step 10: Commit 💾
- [ ] Use proper commit message format
- [ ] Include "Status: Tests passing ✅"
- [ ] Push to refactoring branch

---

## 📖 **Reference Update Examples**

### Example 1: Collision System Refactoring

#### Original Code
```dart
// lib/game/flappy_game.dart
import 'systems/collision_system.dart';

class FlappyGame extends FlameGame {
  late CollisionSystem _collisionSystem;
  
  void _checkCollisions() {
    _collisionSystem.checkCollision(_jet, obstacle, size);
  }
}
```

#### Updated Code
```dart
// lib/game/flappy_game.dart
import 'package:flame/collisions.dart';

class FlappyGame extends FlameGame with HasCollisionDetection {
  // No _collisionSystem field needed
  
  void _checkCollisions() {
    // Flame handles this automatically via CollisionCallbacks
  }
}
```

#### Checklist
- [x] Found usages: flappy_game.dart, test files
- [x] Updated imports
- [x] Removed _collisionSystem field
- [x] Updated _checkCollisions() method
- [x] Updated test/game/collision_test.dart
- [x] flutter analyze: PASS
- [x] flutter test: PASS
- [x] Manual test: PASS

### Example 2: JetPlayer Behavior Refactoring

#### Original Code
```dart
// lib/game/components/jet_player.dart
class JetPlayer extends SpriteComponent {
  @override
  void update(double dt) {
    // Manual gravity
    velocity.y += GameConfig.gravity * dt;
    
    // Manual position update
    position.y += velocity.y * dt;
  }
}
```

#### Updated Code
```dart
// lib/game/components/jet_player.dart
import '../behaviors/gravity_behavior.dart';

class JetPlayer extends SpriteComponent {
  late GravityBehavior _gravityBehavior;
  
  @override
  Future<void> onLoad() async {
    _gravityBehavior = GravityBehavior(velocity: velocity);
    add(_gravityBehavior);
  }
  
  @override
  void update(double dt) {
    // Behavior handles gravity automatically
    position.y += velocity.y * dt;
  }
}
```

#### Checklist
- [x] Found usages: jet_player.dart
- [x] Created gravity_behavior.dart
- [x] Added behavior import
- [x] Added _gravityBehavior field
- [x] Updated onLoad()
- [x] Simplified update()
- [x] Updated test/game/components/jet_player_test.dart
- [x] Added test/game/behaviors/gravity_behavior_test.dart
- [x] flutter analyze: PASS
- [x] flutter test: PASS

---

## 🗂️ **Refactoring-Specific Checklists**

### Phase 1: Collision System

#### Files to Update
- [ ] lib/game/flappy_game.dart
  - [ ] Remove CollisionSystem import
  - [ ] Add Flame collisions import
  - [ ] Remove _collisionSystem field
  - [ ] Add HasCollisionDetection mixin
  - [ ] Update _checkCollisions() method
- [ ] lib/game/components/jet_player.dart
  - [ ] Add CollisionCallbacks mixin
  - [ ] Add CircleHitbox
  - [ ] Implement onCollisionStart()
  - [ ] Implement onCollisionEnd()
- [ ] lib/game/components/dynamic_obstacle.dart
  - [ ] Add CollisionCallbacks mixin
  - [ ] Add RectangleHitboxes (top + bottom)
  - [ ] Enable passive collision
- [ ] test/game/collision_test.dart
  - [ ] Update all test assertions
  - [ ] Add Flame collision tests
  - [ ] Update mock setup

#### Verification
- [ ] All baseline tests pass
- [ ] New collision tests pass
- [ ] No false positives/negatives
- [ ] Performance equal or better

### Phase 2: Behavior Pattern

#### Files to Update
- [ ] lib/game/components/jet_player.dart
  - [ ] Add behavior imports
  - [ ] Remove manual gravity code
  - [ ] Remove manual jump code
  - [ ] Remove manual damage visualization
  - [ ] Add behavior fields
  - [ ] Add behaviors in onLoad()
- [ ] lib/game/components/bot_jet_player.dart
  - [ ] Same updates as jet_player.dart
- [ ] test/game/components/jet_player_test.dart
  - [ ] Update behavior assertions
  - [ ] Add behavior-specific tests

#### New Files Created
- [ ] lib/game/behaviors/gravity_behavior.dart
- [ ] lib/game/behaviors/jump_behavior.dart
- [ ] lib/game/behaviors/damage_visualization_behavior.dart
- [ ] lib/game/behaviors/invulnerability_behavior.dart
- [ ] test/game/behaviors/gravity_behavior_test.dart
- [ ] test/game/behaviors/jump_behavior_test.dart
- [ ] test/game/behaviors/damage_visualization_behavior_test.dart
- [ ] test/game/behaviors/invulnerability_behavior_test.dart

#### Verification
- [ ] JetPlayer LOC reduced by 30%+
- [ ] All JetPlayer tests pass
- [ ] Bot tests pass
- [ ] Gameplay feels identical

### Phase 3: Effect System

#### Files to Update
- [ ] lib/game/components/jet_player.dart
  - [ ] Remove manual bobbing animation
  - [ ] Add MoveEffect for bobbing
- [ ] lib/game/systems/celebration_system.dart
  - [ ] Remove manual scale animations
  - [ ] Add ScaleEffect + SequenceEffect
- [ ] lib/game/flappy_game.dart
  - [ ] Add CameraComponent
  - [ ] Add World component
  - [ ] Move components to world
  - [ ] Add camera shake effects

#### Verification
- [ ] Animations look smoother
- [ ] Professional easing curves
- [ ] Camera shake works
- [ ] No animation jank

---

## 📊 **Progress Tracker**

### Overall Status

| Phase | Files Updated | Tests Updated | Status |
|-------|--------------|---------------|---------|
| **Phase 0** | 0/7 | 0/4 | 🔴 Not Started |
| **Phase 1** | 0/4 | 0/6 | 🔴 Not Started |
| **Phase 2** | 0/2 | 0/8 | 🔴 Not Started |
| **Phase 3** | 0/3 | 0/4 | 🔴 Not Started |
| **Phase 4** | 0/5 | 0/3 | 🔴 Not Started |

### Legend
- 🔴 Not Started
- 🟡 In Progress
- 🟢 Complete
- ✅ Verified

---

## 🚨 **Common Issues & Solutions**

### Issue 1: Import Not Found
**Problem**: `Error: 'X' isn't defined for the type 'Y'`  
**Solution**: 
1. Check if import statement is correct
2. Run `flutter pub get`
3. Check if file exists at import path
4. Verify package version in pubspec.yaml

### Issue 2: Tests Failing After Refactor
**Problem**: Tests that passed before now fail  
**Solution**:
1. Check if test setup still matches new code
2. Update mock objects
3. Update test assertions
4. Add new tests for new behavior

### Issue 3: Flutter Analyze Warnings
**Problem**: Unused imports, undefined references  
**Solution**:
1. Remove unused imports
2. Update all references to renamed/moved code
3. Run `flutter analyze --fix` for auto-fixes
4. Manually fix remaining issues

### Issue 4: Gameplay Regression
**Problem**: Game feels different after refactor  
**Solution**:
1. Check baseline tests still pass
2. Compare frame times (before vs after)
3. Review behavior parameters (gravity, jump force, etc.)
4. Use feature flag to compare old vs new

---

**Last Updated**: October 16, 2025  
**Next Review**: After each phase completion  
**Maintained By**: Development Team

