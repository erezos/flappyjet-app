# 🏆 Tournament System Implementation Plan

> **Status:** IN PROGRESS  
> **Started:** 2025-12-03  
> **Updated:** 2025-12-04  
> **Phase:** 2 of 4 (Content - Moving Obstacles)

---

## 📋 Table of Contents

1. [Big Picture](#big-picture)
2. [Phase 1 Scope](#phase-1-scope)
3. [Architecture](#architecture)
4. [Task Breakdown](#task-breakdown)
5. [Progress Log](#progress-log)
6. [Files Inventory](#files-inventory)
7. [JSON Schemas](#json-schemas)
8. [Event Tracking](#event-tracking)
9. [Testing Checklist](#testing-checklist)

---

## 🎯 Big Picture

### What We're Building (All Phases)

```
PHASE 1: Foundation          PHASE 2: Content           PHASE 3: Economy         PHASE 4: Social
─────────────────────        ─────────────────          ─────────────────        ───────────────
• New Tournament Tab         • Moving obstacles         • Free tickets           • Victory sharing
• JSON config system         • Custom themes            • Special deals          • Missions
• Entry/Tries flow           • Custom skins             • Heart power-up         • Achievements
• Basic gameplay             • Multiple tournaments     • IAP bundles            • Trophy system
• Continue system            • 1v1 visuals
• Event tracking
```

### Key Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Architecture | Client-only, async events | No blocking server calls |
| Hearts | Use player's current max (3 or 6) | Simpler, respects boosters |
| Ticket usage | Auto-apply if available | Better UX |
| Continue cost | 3 gems or ad (like story) | Consistency |
| Re-entry | Unlimited (pay each time) | More engagement |
| Rewards | Keep partial on fail | Less frustration |

---

## 📦 Phase 1 Scope

### In Scope ✅
- [x] Remove old tournaments/leaderboards/endless code
- [x] Tournament JSON configuration system ✅
- [x] TournamentConfig model ✅ (17 tests)
- [x] TournamentEntry model (player state) ✅ (24 tests)
- [x] TournamentManager (state machine) ✅ (36 tests)
- [ ] Tournament Hub screen (replace tab)
- [ ] Tournament Info popup
- [ ] Tournament Progress screen
- [ ] Tournament gameplay integration
- [ ] Game Over with tournament context
- [ ] Special deal popup (out of tries)
- [ ] Victory screen (basic)
- [x] Event tracking for all actions ✅
- [ ] 1 complete working tournament

### Out of Scope (Future Phases) ❌
- ~~Moving obstacles (Phase 2)~~ ✅ COMPLETED
- Custom tournament skins (Phase 2)
- Free tickets as collectible (Phase 3)
- Social sharing (Phase 4)
- Tournament missions/achievements (Phase 4)
- Trophy system (Phase 4)

---

## 🎪 Phase 2: Moving Obstacles (COMPLETED ✅)

### Goals Achieved
- Created modular obstacle movement system following Flame best practices
- Supports 4 movement types: static, verticalOscillate, horizontalApproach, diagonal
- Zero per-frame allocations for performance
- Weighted random pattern selection
- Full integration with existing obstacle system

### Files Created

| File | Purpose | Tests |
|------|---------|-------|
| `lib/game/components/obstacle_movement_config.dart` | Movement configuration model | 28 tests |
| `lib/game/behaviors/obstacle_movement_behavior.dart` | Flame behavior for movement | 18 tests |

### Files Modified

| File | Changes |
|------|---------|
| `lib/game/components/dynamic_obstacle.dart` | Added `movementConfig` parameter, movement behavior integration |
| `lib/game/systems/obstacle_manager.dart` | Added `patternSelector`, `configurePatterns()`, movement config passing |

### Movement Types

| Type | Description | Parameters |
|------|-------------|------------|
| `static` | No movement (default) | - |
| `verticalOscillate` | Sine wave up/down | `amplitude`, `frequency` |
| `horizontalApproach` | Moves towards player faster | `approachSpeed` |
| `diagonal` | Moves at angle | `angle`, `speed` |

### JSON Configuration (Example)

```json
{
  "obstacles": {
    "pattern_mix": [
      { "type": "static", "weight": 60 },
      { "type": "verticalOscillate", "weight": 40, "params": { "amplitude": 30, "frequency": 0.5 } }
    ]
  }
}
```

### Test Coverage
- **ObstacleMovementConfig:** 28 tests covering construction, parsing, calculations, equality
- **ObstacleMovementBehavior:** 18 tests covering all movement types, clamping, utilities

---

## 🏗️ Architecture

### State Management

```
┌─────────────────────────────────────────────────────────────────┐
│                    CLIENT-ONLY ARCHITECTURE                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   TournamentManager (Singleton, ChangeNotifier)                  │
│   ├── TournamentConfig (loaded from JSON/RemoteConfig)          │
│   ├── TournamentEntry? (active tournament state)                │
│   ├── SharedPreferences (persistence)                           │
│   └── EventBus (async, non-blocking analytics)                  │
│                                                                  │
│   Flow:                                                          │
│   1. User enters tournament → deduct fee → create entry         │
│   2. Play rounds → update progress → fire events                │
│   3. Win/Lose → grant rewards → clear entry                     │
│   4. All state in SharedPreferences, events async to backend    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### File Structure (New)

```
lib/
├── game/systems/
│   └── tournament_manager.dart           # State management
├── game/components/
│   ├── obstacle_movement_config.dart     # 🎪 Movement configuration model
│   └── dynamic_obstacle.dart             # Updated with movement support
├── game/behaviors/
│   └── obstacle_movement_behavior.dart   # 🎪 Flame movement behavior
├── models/
│   ├── tournament_config.dart            # JSON → Model
│   └── tournament_entry.dart             # Player progress
├── ui/screens/
│   ├── tournament_hub_screen.dart        # Main tab (replaces old)
│   ├── tournament_progress_screen.dart   # Bracket/rounds view
│   └── tournament_game_wrapper.dart      # Gameplay wrapper
├── ui/widgets/tournament/                # Reuse folder name
│   ├── tournament_card.dart              # Hub card widget
│   ├── tournament_info_popup.dart        # Entry/info modal
│   ├── tournament_special_deal.dart      # Out of tries offer
│   ├── tournament_victory_screen.dart    # Completion screen
│   └── playoff_bracket_screen.dart       # Playoff bracket display
assets/data/
└── tournaments.json                      # Tournament definitions (4 tournaments)
test/
├── game/components/
│   └── obstacle_movement_config_test.dart # 🎪 28 tests
├── game/behaviors/
│   └── obstacle_movement_behavior_test.dart # 🎪 18 tests
└── ui/widgets/tournament/
    ├── tournament_card_test.dart         # 17 tests
    ├── tournament_info_popup_test.dart   # 23 tests
    └── playoff_bracket_screen_test.dart  # Bracket tests
```

---

## ✅ Task Breakdown

### TASK 1: Remove Old Code [COMPLETED ✅]
**Goal:** Clean slate by removing unused tournaments/leaderboards/endless code

#### Sub-tasks:
- [x] 1.1 Audit all files containing tournament/leaderboard/endless
- [x] 1.2 Identify files to DELETE completely
- [x] 1.3 Identify files to MODIFY (remove references)
- [x] 1.4 Delete old tournament widgets (lib/ui/widgets/tournament/) - 6 files deleted
- [x] 1.5 Delete old tournament widgets (lib/ui/widgets/tournaments/) - 4 files deleted
- [x] 1.6 Delete old tournament screens - 4 files deleted
- [x] 1.7 Delete old tournament models - 8 files deleted
- [x] 1.8 Delete old tournament services - 3 files deleted
- [x] 1.9 Update navigation to use new TournamentHubScreen
- [x] 1.10 Remove old tests - 4 test files deleted
- [x] 1.11 Verify app compiles (flutter analyze passed)

### TASK 2: Create Tournament JSON & Config Model [COMPLETED ✅]
**Goal:** Define tournament structure and parse it

#### Sub-tasks:
- [x] 2.1 Create tournaments.json with 2 sample tournaments (Rookie Cup, Challenger Cup)
- [x] 2.2 Create TournamentConfig model
- [x] 2.3 Create TournamentLevel model
- [x] 2.4 Create TournamentReward model
- [x] 2.5 Add JSON parsing with error handling
- [x] 2.6 Add loadAllTournaments() method
- [x] 2.7 Write unit tests for parsing (17 tests)

**Files Created:**
- `lib/models/tournament_config.dart` - Complete config model with all nested types
- `assets/data/tournaments.json` - Sample tournament definitions
- `test/models/tournament_config_test.dart` - 17 passing tests

### TASK 3: Create TournamentEntry Model [COMPLETED ✅]
**Goal:** Track player's tournament progress

#### Sub-tasks:
- [x] 3.1 Define TournamentEntry fields (progress, rewards, round results)
- [x] 3.2 Add JSON serialization (toJson/fromJson)
- [x] 3.3 Add JSON string serialization for SharedPreferences
- [x] 3.4 Write unit tests (24 tests)

**Files Created:**
- `lib/models/tournament_entry.dart` - Entry model with RoundResult
- `test/models/tournament_entry_test.dart` - 24 passing tests

### TASK 4: Create TournamentManager [COMPLETED ✅]
**Goal:** State machine for tournament lifecycle

#### Sub-tasks:
- [x] 4.1 Create singleton with ChangeNotifier
- [x] 4.2 Implement enterTournament() with free ticket support
- [x] 4.3 Implement startRound()
- [x] 4.4 Implement completeRound() with reward tracking
- [x] 4.5 Implement failRound()
- [x] 4.6 Implement useContinue()
- [x] 4.7 Implement completeTournament() with bonus rewards
- [x] 4.8 Implement abandonTournament()
- [x] 4.9 Add persistence (SharedPreferences)
- [x] 4.10 Add event firing (EventBus)
- [x] 4.11 Write unit tests (36 tests)

**Files Created:**
- `lib/game/systems/tournament_manager.dart` - Full state management
- `test/game/systems/tournament_manager_test.dart` - 36 passing tests

### TASK 5: Create Tournament UI [IN PROGRESS 🔄]
**Goal:** All tournament screens and widgets

#### Sub-tasks:
- [x] 5.1 Create TournamentHubScreen ✅
- [x] 5.2 Create TournamentCard widget ✅ (17 tests)
- [x] 5.3 Create TournamentInfoPopup ✅ (23 tests)
- [ ] 5.4 Create TournamentProgressScreen
- [ ] 5.5 Create TournamentSpecialDeal popup
- [ ] 5.6 Create TournamentVictoryScreen
- [x] 5.7 Update navigation to use new tab ✅
- [x] 5.8 Add responsive design ✅
- [x] 5.9 Write widget tests ✅ (40 tests)

**Files Created:**
- `lib/ui/screens/tournament_hub_screen.dart` - Main hub with tournament list
- `lib/ui/widgets/tournament/tournament_card.dart` - Tournament display card
- `lib/ui/widgets/tournament/tournament_info_popup.dart` - Entry popup
- `lib/ui/widgets/tournament/tournament_game_wrapper.dart` - Game wrapper for tournament mode
- `lib/ui/widgets/tournament/tournament_round_failed_popup.dart` - Round failed popup
- `lib/ui/widgets/tournament/tournament_round_complete_popup.dart` - Round complete popup
- `lib/ui/widgets/tournament/tournament_victory_screen.dart` - Tournament victory celebration
- `lib/ui/widgets/tournament/tournament_failed_screen.dart` - Tournament failed with special deal
- `test/ui/widgets/tournament/tournament_card_test.dart` - 17 tests
- `test/ui/widgets/tournament/tournament_info_popup_test.dart` - 23 tests
- `test/ui/widgets/tournament/tournament_round_popups_test.dart` - Round popup tests
- `test/ui/widgets/tournament/tournament_result_screens_test.dart` - Victory/Failed screen tests

### TASK 6: Integrate Gameplay [PENDING]
**Goal:** Connect tournaments to actual gameplay

#### Sub-tasks:
- [ ] 6.1 Create TournamentGameWrapper
- [ ] 6.2 Load level from tournament config
- [ ] 6.3 Handle hearts (use player's max)
- [ ] 6.4 Handle continues (3 gems or ad)
- [ ] 6.5 Handle round completion
- [ ] 6.6 Handle game over in tournament context
- [ ] 6.7 Integration tests

### TASK 7: Event Tracking [PENDING]
**Goal:** Track all tournament actions for analytics

#### Sub-tasks:
- [ ] 7.1 Add event schemas to backend
- [ ] 7.2 Fire tournament_entered
- [ ] 7.3 Fire tournament_round_started
- [ ] 7.4 Fire tournament_round_won
- [ ] 7.5 Fire tournament_round_lost
- [ ] 7.6 Fire tournament_continue_used
- [ ] 7.7 Fire tournament_completed
- [ ] 7.8 Fire tournament_abandoned
- [ ] 7.9 Fire tournament_special_deal_*
- [ ] 7.10 Verify events in dashboard

---

## 📝 Progress Log

### 2025-12-04

**Moving Obstacles Infrastructure - COMPLETED ✅**

Implemented complete moving obstacles system for tournaments:

1. **ObstacleMovementConfig** (`lib/game/components/obstacle_movement_config.dart`)
   - Immutable configuration for obstacle movement
   - Factory constructors: `verticalOscillate()`, `horizontalApproach()`, `diagonal()`
   - `fromPattern()` factory for tournament JSON parsing
   - Pre-calculated properties: `angularFrequency`, `angleRadians`, `diagonalVelocity*`
   - `ObstaclePatternSelector` for weighted random pattern selection

2. **ObstacleMovementBehavior** (`lib/game/behaviors/obstacle_movement_behavior.dart`)
   - Flame behavior component pattern (zero per-frame allocations)
   - Vertical oscillation with sine wave
   - Horizontal approach acceleration
   - Diagonal movement with angle calculation
   - Screen clamping to prevent off-screen movement
   - Extension methods for easy attachment

3. **DynamicObstacle Updates**
   - Added `movementConfig` parameter (defaults to static)
   - Added `_addMovementBehavior()` in `onLoad()`
   - Movement behavior automatically added when config has movement

4. **ObstacleManager Updates**
   - Added `patternSelector` property
   - Added `configurePatterns()` method for tournament level setup
   - Pattern selection integrated into obstacle spawning

5. **Test Coverage:** 46 tests passing
   - `test/game/components/obstacle_movement_config_test.dart` - 28 tests
   - `test/game/behaviors/obstacle_movement_behavior_test.dart` - 18 tests

**Next Steps:**
- Connect tournament gameplay to use pattern selector
- Asset generation for tournament banners
- Integration testing with actual tournament flow

---

### 2025-12-03

**Session Start**
- Created implementation plan document
- Audited existing tournament/leaderboard files (59 files found)

**Task 1 Completed: Remove Old Code ✅**
- Deleted 25+ files related to old tournament system
- Files removed:
  - `lib/ui/widgets/tournaments/` - 4 files
  - `lib/ui/widgets/tournament/` - 6 files
  - `lib/ui/screens/tournaments_*.dart` - 4 files
  - `lib/models/tournament*.dart` - 8 files
  - `lib/services/tournament_service.dart`
  - `lib/services/prize_distribution_service.dart`
  - `lib/game/controllers/tournament_controller.dart`
  - `lib/game/systems/leaderboard_data_migrator.dart`
  - `test/ui/widgets/tournaments/` - 4 test files
- Created `TournamentHubScreen` placeholder
- Updated navigation to use new screen
- Removed tournament code from `flappy_game.dart`
- App compiles successfully (`flutter analyze` passed)

**Currently Working On:**
- Task 2: Create TournamentConfig model (parse JSON)

---

## 📁 Files Inventory

### Files to DELETE (Old Tournament System)

#### Widgets - lib/ui/widgets/tournaments/
| File | Purpose | Status |
|------|---------|--------|
| global_leaderboard_tab.dart | Old leaderboard | TO DELETE |
| personal_scores_tab.dart | Old scores | TO DELETE |
| personal_stats_screen.dart | Old stats | TO DELETE |
| weekly_contest_tab.dart | Old contest | TO DELETE |

#### Widgets - lib/ui/widgets/tournament/
| File | Purpose | Status |
|------|---------|--------|
| prize_notification_widget.dart | Old prizes | TO DELETE |
| tournament_header.dart | Old header | TO DELETE |
| tournament_leaderboard_widget.dart | Old leaderboard | TO DELETE |
| tournament_prize_pool_widget.dart | Old prizes | TO DELETE |
| tournament_registration_card.dart | Old registration | TO DELETE |
| tournament_stats_card.dart | Old stats | TO DELETE |

#### Models - lib/models/
| File | Purpose | Status |
|------|---------|--------|
| tournament.dart | Old model | TO DELETE |
| tournament.g.dart | Generated | TO DELETE |
| tournament_leaderboard_entry.dart | Old model | TO DELETE |
| tournament_leaderboard_entry.g.dart | Generated | TO DELETE |
| tournament_participant.dart | Old model | TO DELETE |
| tournament_participant.g.dart | Generated | TO DELETE |
| tournament_session_result.dart | Old model | TO DELETE |
| tournament_session_result.g.dart | Generated | TO DELETE |
| pending_prize.dart | Old prizes | EVALUATE |

#### Screens - lib/ui/screens/
| File | Purpose | Status |
|------|---------|--------|
| tournament_screen.dart | Old screen | TO DELETE |
| tournaments_screen.dart | Old screen | TO DELETE |
| tournaments_page.dart | Old page | TO DELETE |
| leaderboard_screen.dart | Old leaderboard | TO DELETE |
| prize_celebration_screen.dart | Old prizes | EVALUATE |

#### Services - lib/services/
| File | Purpose | Status |
|------|---------|--------|
| tournament_service.dart | Old service | TO DELETE |
| railway_leaderboard_service.dart | Old leaderboard | EVALUATE |
| hybrid_leaderboard_service.dart | Old hybrid | EVALUATE |
| prize_service.dart | Old prizes | EVALUATE |
| prize_distribution_service.dart | Old prizes | EVALUATE |

#### Systems - lib/game/systems/
| File | Purpose | Status |
|------|---------|--------|
| leaderboard_manager.dart | Old manager | EVALUATE |
| leaderboard_data_migrator.dart | Old migrator | TO DELETE |
| global_leaderboard_service.dart | Old global | EVALUATE |

#### Controllers - lib/game/controllers/
| File | Purpose | Status |
|------|---------|--------|
| tournament_controller.dart | Old controller | TO DELETE |

### Files to MODIFY (Remove References)

| File | What to Remove | Status |
|------|---------------|--------|
| main.dart | Tournament initialization | PENDING |
| home_navigator_screen.dart | Tournament tab | PENDING |
| bottom_navigator_bar.dart | Tournament icon | PENDING |
| game_state_manager.dart | Tournament state | PENDING |
| player_identity_manager.dart | Leaderboard refs | PENDING |
| profile_screen.dart | Tournament stats | PENDING |
| dev_reset_manager.dart | Tournament reset | PENDING |
| database_schema.dart | Tournament tables | PENDING |
| local_database_manager.dart | Tournament queries | PENDING |

---

## 📄 JSON Schemas

### tournaments.json (Phase 1)

```json
{
  "version": "1.0.0",
  "tournaments": [
    {
      "id": "rookie_cup_001",
      "name": "Rookie Cup",
      "description": "Perfect for beginners!",
      "tier": "bronze",
      "status": "active",
      
      "entry": {
        "type": "coins",
        "amount": 500,
        "free_ticket_tier": "bronze"
      },
      
      "tries": {
        "count": 3
      },
      
      "continues": {
        "max_per_try": 5,
        "gem_cost": 3,
        "ad_available": true
      },
      
      "levels": [
        {
          "round": 1,
          "name": "Warm Up",
          "background": "desert",
          "opponent_jet": null,
          "difficulty": {
            "speedMultiplier": 0.95,
            "obstacleGap": 400,
            "obstacleFrequency": 2.5,
            "maxGapShift": 40,
            "requiredDistance": 50
          },
          "obstacles": {
            "pattern_mix": [
              { "type": "static", "weight": 100 }
            ]
          },
          "reward": { "coins": 100, "gems": 0 }
        }
      ],
      
      "completion_reward": {
        "coins": 1000,
        "gems": 20,
        "skin_id": null
      },
      
      "lose_all_tries_offer": {
        "enabled": true,
        "discount_percent": 50,
        "extra_tries": 2,
        "base_gem_cost": 200
      },
      
      "display": {
        "banner_image": "tournament_rookie_banner",
        "icon": "trophy_bronze",
        "color_primary": "#CD7F32"
      },
      
      "unlock_requirement": null
    }
  ]
}
```

---

## 📊 Event Tracking

### Tournament Events

| Event | Payload | Dashboard Use |
|-------|---------|--------------|
| tournament_entered | tournament_id, entry_type, entry_amount, used_ticket | Entry funnel |
| tournament_round_started | tournament_id, round, try_number | Round analytics |
| tournament_round_won | tournament_id, round, time_seconds, hearts_used, continues_used | Success rate |
| tournament_round_lost | tournament_id, round, try_number | Difficulty tuning |
| tournament_try_failed | tournament_id, round, try_number | Try analysis |
| tournament_completed | tournament_id, total_tries, total_continues | Completion rate |
| tournament_abandoned | tournament_id, round_reached, tries_used | Drop-off |
| tournament_continue_used | tournament_id, round, method, cost | Continue economy |
| tournament_special_deal_shown | tournament_id, round_reached | Offer impressions |
| tournament_special_deal_bought | tournament_id, gem_cost, tries_added | Offer conversion |
| tournament_special_deal_declined | tournament_id | Offer rejection |

---

## 🧪 Testing Checklist

### Unit Tests
- [ ] TournamentConfig parsing (valid JSON)
- [ ] TournamentConfig parsing (invalid JSON)
- [ ] TournamentEntry serialization
- [ ] TournamentManager state transitions
- [ ] Entry with coins
- [ ] Entry with gems
- [ ] Entry with free ticket
- [ ] Round completion
- [ ] Round failure
- [ ] Continue usage
- [ ] Tournament completion
- [ ] Tournament abandonment
- [ ] Special deal purchase

### Widget Tests
- [ ] TournamentHubScreen renders
- [ ] TournamentCard displays correctly
- [ ] TournamentInfoPopup shows fees
- [ ] TournamentProgressScreen shows rounds
- [ ] TournamentVictoryScreen shows rewards

### Integration Tests
- [ ] Full tournament flow (enter → play → win)
- [ ] Full tournament flow (enter → play → lose all tries)
- [ ] Continue flow (gems)
- [ ] Continue flow (ad)
- [ ] Special deal flow
- [ ] State persistence across app restart

---

## 🔗 Related Files

- PRD: See conversation history (2025-12-03)
- Old system removal: This document, Files Inventory section
- JSON schema: This document, JSON Schemas section

---

*Last Updated: 2025-12-04*

