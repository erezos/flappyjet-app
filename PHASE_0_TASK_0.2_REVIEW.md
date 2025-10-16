# ✅ **PHASE 0 - TASK 0.2: DATABASE SCHEMA - REVIEW**

## 📋 **What We Created**

### 1. **PostgreSQL Schema** (`database/story_mode_schema.sql`)
Complete database schema with:
- ✅ 3 tables (player_level_progress, level_completions, level_attempts)
- ✅ 3 analytics views (difficulty stats, player summary, zone stats)
- ✅ 2 functions (update progress, get next level)
- ✅ 1 trigger (auto-update timestamps)
- ✅ **Continue tracking** (continues_used, continues_ad, continues_gems)
- ✅ Comprehensive indexes for performance
- ✅ Check constraints for data validation
- ✅ Sample queries for testing

### 2. **API Design** (`database/STORY_MODE_API_DESIGN.md`)
Complete REST API specification with:
- ✅ 8 endpoints (progress, start, complete, attempt, stats, leaderboard, history, sync)
- ✅ Request/response examples
- ✅ Error handling
- ✅ Authentication (JWT)
- ✅ Rate limiting
- ✅ Analytics event logging

### 3. **Schema Guide** (`database/STORY_MODE_SCHEMA_GUIDE.md`)
Comprehensive documentation with:
- ✅ Schema diagram (ASCII art)
- ✅ Table relationships
- ✅ Field explanations
- ✅ Continue tracking analysis guide
- ✅ Migration steps
- ✅ Performance considerations
- ✅ Testing checklist
- ✅ Rollback plan

---

## 🎯 **Key Features**

### **1. Continue Tracking (Your Request)** 🎯
Every level completion and attempt tracks:
- `continues_used` - Total continues used (0-5)
- `continues_ad` - Continues via watching ads
- `continues_gems` - Continues via spending gems

**Why This Matters:**
- **Difficulty Analysis:** Levels with high continue usage are too hard
- **Monetization Insights:** See if players prefer ads or gems
- **Balancing:** Adjust difficulty based on real data
- **Bot Tuning:** See which bots need AI adjustments

### **2. Three-Tier Data Model**

#### **Tier 1: player_level_progress (Summary)**
- One row per player
- Overall progress (current level, zone, totals)
- Fast lookups for UI

#### **Tier 2: level_completions (Completions)**
- One row per level completion
- Performance metrics, rewards, continues
- Used for leaderboards and player history

#### **Tier 3: level_attempts (Granular)**
- One row per individual attempt
- Every try, success or failure
- Used for deep analytics and difficulty tuning

### **3. Analytics Views**

#### **level_difficulty_stats**
```sql
SELECT * FROM level_difficulty_stats WHERE level_id = 7;
```
Returns:
- Completion rate
- Average continues used
- First-try completions
- Average attempts to complete

#### **player_story_summary**
```sql
SELECT * FROM player_story_summary WHERE player_id = 1;
```
Returns:
- Complete player progress
- Total continues used (ad vs gems)
- Bot battle win rate
- Last played timestamp

#### **zone_completion_stats**
```sql
SELECT * FROM zone_completion_stats;
```
Returns:
- Players reached per zone
- Average continues per zone
- Average completion time
- Progression funnel data

---

## 📊 **Continue Tracking Use Cases**

### **Use Case 1: Find Too-Hard Levels**
```sql
-- Levels where players use 3+ continues on average
SELECT level_id, avg_continues_used, completion_rate
FROM level_difficulty_stats
WHERE avg_continues_used >= 3.0
ORDER BY avg_continues_used DESC;
```

**Action:** Reduce difficulty (wider gap, slower speed).

### **Use Case 2: Find Too-Easy Levels**
```sql
-- Levels with high first-try completion
SELECT level_id, first_try_completions, total_attempts
FROM level_difficulty_stats
WHERE first_try_completions > total_attempts * 0.5;
```

**Action:** Increase difficulty slightly.

### **Use Case 3: Monetization Analysis**
```sql
-- See if players prefer ads or gems
SELECT 
    SUM(continues_ad) as total_ad,
    SUM(continues_gems) as total_gems,
    ROUND(SUM(continues_ad)::NUMERIC / SUM(continues_used)::NUMERIC * 100, 2) as ad_percentage
FROM level_completions
WHERE continues_used > 0;
```

**Insight:** If >80% ads, players prefer free continues. If <50%, they're spending gems!

### **Use Case 4: Bot Battle Difficulty**
```sql
-- Analyze bot performance
SELECT 
    level_id, bot_name,
    COUNT(*) as battles,
    AVG(continues_used) as avg_continues,
    COUNT(CASE WHEN bot_defeated THEN 1 END)::NUMERIC / COUNT(*) * 100 as win_rate
FROM level_completions
WHERE bot_battle = TRUE
GROUP BY level_id, bot_name;
```

**Action:** Adjust bot AI if win rate is too high/low.

---

## 🌐 **API Endpoints Summary**

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/story-mode/progress` | GET | Get player's overall progress |
| `/api/story-mode/level/start` | POST | Record level start |
| `/api/story-mode/level/complete` | POST | Record level completion |
| `/api/story-mode/level/attempt` | POST | Record individual attempt |
| `/api/story-mode/level/:id/stats` | GET | Get level difficulty stats |
| `/api/story-mode/leaderboard/zone/:id` | GET | Get zone leaderboard |
| `/api/story-mode/level/:id/history` | GET | Get player's attempt history |
| `/api/story-mode/sync` | POST | Sync offline progress |

---

## 🗄️ **Database Tables**

### **player_level_progress**
- **Purpose:** Overall story mode progress
- **Rows:** One per player
- **Key Fields:** current_level, highest_level_unlocked, total_coins_earned
- **Updates:** After each level completion

### **level_completions**
- **Purpose:** Track successful level completions
- **Rows:** One per level completion
- **Key Fields:** continues_used, continues_ad, continues_gems, coins_earned
- **Updates:** When level is completed

### **level_attempts**
- **Purpose:** Track every attempt (success or failure)
- **Rows:** One per attempt
- **Key Fields:** attempt_number, success, continues_used, failure_reason
- **Updates:** After every attempt

---

## 📈 **Performance Features**

### **Indexes**
- ✅ Player lookups (fast profile loading)
- ✅ Level lookups (fast stats queries)
- ✅ Continue analysis (fast difficulty queries)
- ✅ Time-based queries (fast leaderboards)

### **Views**
- ✅ Pre-computed analytics (no expensive joins at runtime)
- ✅ Cached results (fast dashboard loading)

### **Functions**
- ✅ `update_player_story_progress()` - Atomic progress updates
- ✅ `get_next_level()` - Fast level unlock checks

---

## 🚀 **Migration Plan**

### **Step 1: Backup**
```bash
railway connect
pg_dump > backup_before_story_mode.sql
```

### **Step 2: Apply Schema**
```bash
\i database/story_mode_schema.sql
```

### **Step 3: Verify**
```sql
\dt  -- List tables
\dv  -- List views
SELECT * FROM player_level_progress LIMIT 1;
```

### **Step 4: Test**
- Insert sample data
- Run test queries
- Verify constraints work

### **Step 5: Deploy API**
- Create `routes/story-mode.js`
- Implement all 8 endpoints
- Add to `server.js`
- Test with Postman

---

## ❓ **REVIEW QUESTIONS FOR YOU**

### 1. **Continue Tracking**
- ✅ Does the continue tracking meet your needs?
- ✅ Do you want to track anything else (e.g., which obstacle caused failure)?

### 2. **Analytics Views**
- ✅ Are the 3 views sufficient for your analytics needs?
- ✅ Do you need additional metrics?

### 3. **API Endpoints**
- ✅ Are all necessary endpoints covered?
- ✅ Do you need additional endpoints (e.g., delete progress)?

### 4. **Data Retention**
- ✅ Keep all attempts forever, or archive after 90 days?
- ✅ Any GDPR considerations for player data?

### 5. **Migration Timing**
- ✅ Apply schema now, or wait until Phase 1 is ready?
- ✅ Test on staging environment first?

---

## 📝 **NEXT STEPS**

After your approval:

### **Immediate**
1. ✅ Move to Task 0.3 (Asset Inventory)
2. ✅ Move to Task 0.4 (UI Wireframes)

### **Before Phase 1**
3. ✅ Apply database schema to Railway
4. ✅ Test schema with sample data
5. ✅ Create API endpoints (can be done in parallel with Phase 1)

### **Phase 1**
6. ✅ Implement Flutter integration
7. ✅ Test with real gameplay

---

## 🎉 **SUMMARY**

**What We Built:**
- Complete PostgreSQL schema with continue tracking
- 8 REST API endpoints
- 3 analytics views for difficulty analysis
- Comprehensive documentation

**Key Innovation:**
- **Continue tracking** lets you see exactly which levels are too hard/easy
- **Three-tier data model** balances performance and analytics depth
- **Analytics views** make it easy to query difficulty stats

**Ready for:**
- Database migration
- API implementation
- Phase 1 integration

---

**Created:** October 5, 2025
**Status:** Awaiting Review 📋
**Next:** Task 0.3 (Asset Inventory) & Task 0.4 (UI Wireframes)
