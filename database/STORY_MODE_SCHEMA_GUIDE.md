# 📊 **STORY MODE DATABASE SCHEMA GUIDE**

## **Schema Overview**

```
┌─────────────────────────────────────────────────────────────────┐
│                         PLAYERS TABLE                           │
│                      (Existing - No Changes)                    │
│  • id (PK)                                                      │
│  • display_name                                                 │
│  • email                                                        │
│  • current_coins                                                │
│  • current_gems                                                 │
└─────────────────────────────────────────────────────────────────┘
                                │
                                │ (1:1)
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                  PLAYER_LEVEL_PROGRESS TABLE                    │
│                   (One row per player)                          │
├─────────────────────────────────────────────────────────────────┤
│  • id (PK)                                                      │
│  • player_id (FK → players.id) UNIQUE                          │
│  • current_level (1-100)                                        │
│  • highest_level_unlocked (1-100)                              │
│  • total_levels_completed (0-100)                              │
│  • current_zone (1-10)                                          │
│  • zones_completed (0-10)                                       │
│  • total_coins_earned                                           │
│  • total_gems_earned                                            │
│  • bot_battles_won                                              │
│  • bot_battles_lost                                             │
│  • created_at, updated_at                                       │
└─────────────────────────────────────────────────────────────────┘
                                │
                                │ (1:Many)
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                   LEVEL_COMPLETIONS TABLE                       │
│              (One row per level completion)                     │
├─────────────────────────────────────────────────────────────────┤
│  • id (PK)                                                      │
│  • player_id (FK → players.id)                                 │
│  • level_id (1-100)                                             │
│  • completed (BOOLEAN)                                          │
│  • objective_type (pass_obstacles, survive_time, beat_bot)     │
│  • objective_target                                             │
│  • objective_achieved                                           │
│  • attempts                                                     │
│  • time_taken_seconds                                           │
│  • continues_used (0-5) 🎯 FOR DIFFICULTY ANALYSIS             │
│  • continues_ad                                                 │
│  • continues_gems                                               │
│  • bot_battle (BOOLEAN)                                         │
│  • bot_defeated (BOOLEAN)                                       │
│  • bot_name                                                     │
│  • coins_earned                                                 │
│  • gems_earned                                                  │
│  • special_reward                                               │
│  • completed_at                                                 │
└─────────────────────────────────────────────────────────────────┘
                                │
                                │ (1:Many)
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    LEVEL_ATTEMPTS TABLE                         │
│              (One row per individual attempt)                   │
├─────────────────────────────────────────────────────────────────┤
│  • id (PK)                                                      │
│  • player_id (FK → players.id)                                 │
│  • level_id (1-100)                                             │
│  • attempt_number (1, 2, 3, ...)                               │
│  • success (BOOLEAN)                                            │
│  • score_achieved                                               │
│  • continues_used (0-5) 🎯 FOR DIFFICULTY ANALYSIS             │
│  • continues_ad                                                 │
│  • continues_gems                                               │
│  • failure_reason (collision, out_of_continues, quit)          │
│  • started_at, ended_at, duration_seconds                      │
└─────────────────────────────────────────────────────────────────┘
```

---

## **Table Relationships**

### **1. players → player_level_progress (1:1)**
- Each player has ONE story mode progress record
- Created on first story mode level start
- Updated after each level completion

### **2. players → level_completions (1:Many)**
- Each player can have MULTIPLE level completions
- One record per successful level completion
- Tracks performance metrics and rewards

### **3. players → level_attempts (1:Many)**
- Each player can have MULTIPLE attempts per level
- Tracks EVERY attempt (success or failure)
- Used for granular difficulty analysis

---

## **Key Fields Explained**

### **player_level_progress**

| Field | Purpose | Example |
|-------|---------|---------|
| `current_level` | Level player is currently on | 5 |
| `highest_level_unlocked` | Highest level player can access | 5 |
| `total_levels_completed` | Total levels beaten | 4 |
| `current_zone` | Current zone (1-10) | 1 |
| `zones_completed` | Zones fully completed | 0 |
| `total_coins_earned` | Total coins from story mode | 80 |
| `total_gems_earned` | Total gems from story mode | 0 |
| `bot_battles_won` | Bot battles won | 0 |
| `bot_battles_lost` | Bot battles lost | 0 |

### **level_completions (🎯 Includes Continue Tracking)**

| Field | Purpose | Example |
|-------|---------|---------|
| `level_id` | Level number (1-100) | 7 |
| `completed` | TRUE if level was beaten | TRUE |
| `objective_type` | Type of objective | "beat_bot" |
| `objective_target` | Target to achieve | 1 |
| `objective_achieved` | Actual achievement | 1 |
| `attempts` | Number of tries before success | 2 |
| `time_taken_seconds` | Time to complete | 67 |
| **`continues_used`** | **Total continues used** | **2** |
| **`continues_ad`** | **Continues via ads** | **2** |
| **`continues_gems`** | **Continues via gems** | **0** |
| `bot_battle` | TRUE if bot level | TRUE |
| `bot_defeated` | TRUE if player won | TRUE |
| `coins_earned` | Coins rewarded | 40 |
| `gems_earned` | Gems rewarded | 0 |

### **level_attempts**

| Field | Purpose | Example |
|-------|---------|---------|
| `attempt_number` | 1st, 2nd, 3rd attempt | 2 |
| `success` | TRUE if completed | FALSE |
| `score_achieved` | Obstacles passed / seconds survived | 3 |
| **`continues_used`** | **Continues used in this attempt** | **5** |
| **`continues_ad`** | **Ad continues** | **3** |
| **`continues_gems`** | **Gem continues** | **2** |
| `failure_reason` | Why attempt failed | "out_of_continues" |
| `duration_seconds` | How long attempt lasted | 45 |

---

## **Analytics Views**

### **1. level_difficulty_stats**
Analyzes difficulty of each level based on player performance.

**Key Metrics:**
- `completion_rate` - % of attempts that succeed
- `avg_continues_used` - Average continues per attempt
- `avg_continues_on_success` - Average continues when successful
- `first_try_completions` - Players who beat it without retrying

**Use Case:** Identify levels that are too hard or too easy.

**Example Query:**
```sql
-- Find levels that are too hard (>2.5 avg continues, <60% completion)
SELECT level_id, avg_continues_used, completion_rate
FROM level_difficulty_stats
WHERE avg_continues_used > 2.5 AND completion_rate < 60
ORDER BY avg_continues_used DESC;
```

### **2. player_story_summary**
Complete overview of each player's story mode stats.

**Key Metrics:**
- Current progress (level, zone)
- Total completions
- Total continues used (ad vs gems)
- Bot battle win rate

**Use Case:** Player profile, leaderboards, analytics dashboard.

### **3. zone_completion_stats**
Aggregate stats per zone.

**Key Metrics:**
- Players who reached each zone
- Total completions per zone
- Average continues per level in zone
- Average completion time

**Use Case:** Zone difficulty balancing, progression funnel analysis.

---

## **Continue Tracking Analysis** 🎯

### **Why Track Continues?**
You requested this to understand level difficulty. Here's how to use it:

### **1. Identify Too-Hard Levels**
```sql
-- Levels where players use 3+ continues on average
SELECT 
    level_id,
    avg_continues_used,
    completion_rate,
    total_attempts
FROM level_difficulty_stats
WHERE avg_continues_used >= 3.0
ORDER BY avg_continues_used DESC
LIMIT 10;
```

**Action:** Reduce difficulty (wider gap, slower speed, fewer obstacles).

### **2. Identify Too-Easy Levels**
```sql
-- Levels with high first-try completion rate
SELECT 
    level_id,
    first_try_completions,
    total_attempts,
    ROUND(first_try_completions::NUMERIC / total_attempts::NUMERIC * 100, 2) as first_try_rate
FROM level_difficulty_stats
WHERE total_attempts > 100
ORDER BY first_try_rate DESC
LIMIT 10;
```

**Action:** Increase difficulty slightly.

### **3. Track Continue Monetization**
```sql
-- See if players prefer ads or gems for continues
SELECT 
    level_id,
    SUM(continues_ad) as total_ad_continues,
    SUM(continues_gems) as total_gem_continues,
    ROUND(SUM(continues_ad)::NUMERIC / NULLIF(SUM(continues_used), 0)::NUMERIC * 100, 2) as ad_percentage
FROM level_completions
WHERE continues_used > 0
GROUP BY level_id
ORDER BY level_id;
```

**Insight:** If ad_percentage is high (>80%), players prefer ads. If low, they're spending gems!

### **4. Bot Battle Difficulty**
```sql
-- Analyze bot battles specifically
SELECT 
    lc.level_id,
    lc.bot_name,
    COUNT(*) as total_battles,
    COUNT(CASE WHEN lc.bot_defeated = TRUE THEN 1 END) as wins,
    ROUND(AVG(lc.continues_used), 2) as avg_continues,
    ROUND(COUNT(CASE WHEN lc.bot_defeated = TRUE THEN 1 END)::NUMERIC / COUNT(*)::NUMERIC * 100, 2) as win_rate
FROM level_completions lc
WHERE lc.bot_battle = TRUE
GROUP BY lc.level_id, lc.bot_name
ORDER BY lc.level_id;
```

**Action:** Adjust bot AI parameters (skillLevel, reactionTime, mistakeRate).

---

## **Migration Steps**

### **Step 1: Backup Existing Database**
```bash
# Connect to Railway
railway connect

# Backup
pg_dump > backup_before_story_mode.sql
```

### **Step 2: Run Schema**
```bash
# Apply schema
\i database/story_mode_schema.sql

# Verify tables created
\dt

# Check views
\dv
```

### **Step 3: Test with Sample Data**
```sql
-- Insert test player progress
INSERT INTO player_level_progress (player_id, current_level, highest_level_unlocked, total_levels_completed)
VALUES (1, 5, 5, 4);

-- Insert test completion
INSERT INTO level_completions (
    player_id, level_id, completed, objective_type, objective_target, 
    objective_achieved, continues_used, continues_ad, continues_gems, 
    coins_earned, gems_earned
)
VALUES (1, 4, TRUE, 'pass_obstacles', 5, 5, 1, 1, 0, 20, 0);

-- Query test data
SELECT * FROM player_story_summary WHERE player_id = 1;
```

### **Step 4: Create API Endpoints**
See `STORY_MODE_API_DESIGN.md` for endpoint specifications.

### **Step 5: Integrate with Flutter**
- Create `StoryModeApiService`
- Implement sync logic
- Test with real gameplay

---

## **Performance Considerations**

### **Indexes**
All critical indexes are already defined in the schema:
- Player lookups: `idx_player_level_progress_player_id`
- Level lookups: `idx_level_completions_level_id`
- Continue analysis: `idx_level_completions_continues`
- Time-based queries: `idx_level_completions_completed_at`

### **Query Optimization**
- Use views for complex analytics (pre-computed)
- Add caching for leaderboards (Redis)
- Batch insert for offline sync

### **Data Retention**
- Keep all `level_completions` (small, valuable)
- Archive old `level_attempts` after 90 days (large, less critical)
- Never delete `player_level_progress` (core data)

---

## **Testing Checklist**

- [ ] Schema applies without errors
- [ ] All tables created
- [ ] All indexes created
- [ ] All views work
- [ ] All functions work
- [ ] Sample data inserts successfully
- [ ] Queries return expected results
- [ ] Foreign key constraints work
- [ ] Check constraints work
- [ ] Triggers fire correctly

---

## **Rollback Plan**

If something goes wrong:

```sql
-- Drop everything (in correct order)
DROP TABLE IF EXISTS level_attempts CASCADE;
DROP TABLE IF EXISTS level_completions CASCADE;
DROP TABLE IF EXISTS player_level_progress CASCADE;
DROP VIEW IF EXISTS level_difficulty_stats CASCADE;
DROP VIEW IF EXISTS player_story_summary CASCADE;
DROP VIEW IF EXISTS zone_completion_stats CASCADE;
DROP FUNCTION IF EXISTS update_player_story_progress CASCADE;
DROP FUNCTION IF EXISTS get_next_level CASCADE;
DROP FUNCTION IF EXISTS update_updated_at_column CASCADE;

-- Restore from backup
\i backup_before_story_mode.sql
```

---

**Last Updated:** October 5, 2025
**Version:** 1.0
**Status:** Ready for Migration 🚀
