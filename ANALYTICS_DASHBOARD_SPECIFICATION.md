# 📊 FlappyJet Pro - Analytics Dashboard Specification
**Version:** 1.0  
**Last Updated:** November 9, 2025  
**Purpose:** Real-time game analytics and business intelligence

---

## 📋 Table of Contents

1. [Dashboard Overview](#dashboard-overview)
2. [Your Requested Dashboards](#your-requested-dashboards)
3. [Recommended Additional Dashboards](#recommended-additional-dashboards)
4. [Data Availability Analysis](#data-availability-analysis)
5. [Missing Events & Gaps](#missing-events--gaps)
6. [Dashboard Implementation](#dashboard-implementation)

---

## 🎯 Dashboard Overview

### Dashboard Categories
1. **📈 Overview Dashboard** - High-level KPIs (Executive view)
2. **👥 User Engagement Dashboard** - DAU, retention, sessions
3. **🎮 Game Performance Dashboard** - Games played, levels, difficulty
4. **💰 Economy Dashboard** - Coins/gems flow, spending, earning
5. **💳 Monetization Dashboard** - Revenue, ARPU, conversion
6. **🏆 Social Dashboard** - Leaderboards, tournaments, competition
7. **⚙️ Technical Dashboard** - Errors, performance, stability

---

## ✅ YOUR REQUESTED DASHBOARDS

Let me analyze each of your requests:

### 1. **DAU - Users Who Played Today** ✅ GOOD

**What You Want:**
- Count of unique users who launched a game today

**Industry Best Practice: EXPAND THIS**
You should track:
- **DAU (Daily Active Users)** - Users who **opened the app** today
- **DGPU (Daily Game-Playing Users)** - Users who **started a game** today
- **Ratio: DGPU/DAU** - What % of users who open the app actually play?

**Why?** 
- If DAU is high but DGPU is low, users are opening but not engaging
- Helps identify onboarding or UI friction issues

**Data Source:**
```javascript
// DAU (app opened)
SELECT COUNT(DISTINCT user_id) 
FROM events 
WHERE event_name = 'app_launched' 
AND DATE(timestamp) = CURRENT_DATE;

// DGPU (game started)
SELECT COUNT(DISTINCT user_id)
FROM events
WHERE event_name = 'game_started'
AND DATE(timestamp) = CURRENT_DATE;
```

**✅ WE HAVE THIS DATA** - Events: `app_launched`, `game_started`

---

### 2. **Number of Games Today** ✅ GOOD

**What You Want:**
- Total count of games played today

**Industry Best Practice: EXPAND THIS**
You should track:
- **Total Games Started** - All `game_started` events
- **Total Games Completed** - All `game_ended` events
- **Completion Rate** - (Completed / Started) × 100%
- **Games per User** - Total games / DGPU
- **Breakdown by Mode** - Endless vs Story

**Why?**
- Completion rate shows if users are rage-quitting
- Games per user shows engagement depth
- Mode breakdown shows feature popularity

**Data Source:**
```javascript
// Games started
SELECT COUNT(*) 
FROM events 
WHERE event_name = 'game_started' 
AND DATE(timestamp) = CURRENT_DATE;

// Games completed
SELECT COUNT(*) 
FROM events 
WHERE event_name = 'game_ended' 
AND DATE(timestamp) = CURRENT_DATE;

// By game mode
SELECT 
  payload->>'game_mode' as mode,
  COUNT(*) as count
FROM events
WHERE event_name = 'game_ended'
AND DATE(timestamp) = CURRENT_DATE
GROUP BY mode;
```

**✅ WE HAVE THIS DATA** - Events: `game_started`, `game_ended`

---

### 3. **Total Coins Spent Today - Details on What** ⚠️ **MISSING DATA**

**What You Want:**
- Sum of coins spent
- Breakdown: skins, boosters, continues, etc.

**Industry Best Practice: PERFECT REQUEST**
This is essential for economy balancing!

**Current Problem: ❌ WE DON'T HAVE THIS EVENT**

**What We Need to Add:**
```javascript
// NEW EVENT: currency_spent
{
  "name": "currency_spent",
  "payload": {
    "currency_type": "coins",        // or "gems"
    "amount": 500,
    "spent_on": "skin_purchase",     // or "booster", "continue", "jet_unlock"
    "item_id": "skin_gold",          // specific item
    "balance_before": 1500,
    "balance_after": 1000
  }
}
```

**Dashboard Query:**
```javascript
// Total coins spent
SELECT SUM(payload->>'amount')
FROM events
WHERE event_name = 'currency_spent'
AND payload->>'currency_type' = 'coins'
AND DATE(timestamp) = CURRENT_DATE;

// Breakdown by category
SELECT 
  payload->>'spent_on' as category,
  SUM((payload->>'amount')::int) as total_spent,
  COUNT(*) as transaction_count,
  AVG((payload->>'amount')::int) as avg_transaction
FROM events
WHERE event_name = 'currency_spent'
AND payload->>'currency_type' = 'coins'
AND DATE(timestamp) = CURRENT_DATE
GROUP BY category
ORDER BY total_spent DESC;
```

**🔴 ACTION REQUIRED:** Add `currency_spent` event to Flutter app

---

### 4. **Total Gems Spent Today - Details on What** ⚠️ **MISSING DATA**

**What You Want:**
- Sum of gems spent
- Breakdown: skins, boosters, continues, etc.

**Same as #3** - Need `currency_spent` event with `currency_type: "gems"`

**🔴 ACTION REQUIRED:** Add `currency_spent` event to Flutter app

---

### 5. **Total Coins Earned Today - Details on How** ⚠️ **MISSING DATA**

**What You Want:**
- Sum of coins earned
- Breakdown: missions, levels, ads, purchases

**Industry Best Practice: CRITICAL FOR ECONOMY**
You need to track:
- **Sources:** Missions, levels, ads, prizes, purchases
- **Per-user average**
- **Sink-vs-source ratio** (spent vs earned)

**Current Problem: ❌ WE DON'T HAVE THIS EVENT**

**What We Need to Add:**
```javascript
// NEW EVENT: currency_earned
{
  "name": "currency_earned",
  "payload": {
    "currency_type": "coins",        // or "gems"
    "amount": 100,
    "source": "mission_completed",   // or "level_completed", "ad_watched", "prize_claimed", "purchase"
    "source_id": "daily_mission_3",  // specific mission/level/etc
    "balance_before": 1000,
    "balance_after": 1100
  }
}
```

**Dashboard Query:**
```javascript
// Total coins earned
SELECT SUM((payload->>'amount')::int)
FROM events
WHERE event_name = 'currency_earned'
AND payload->>'currency_type' = 'coins'
AND DATE(timestamp) = CURRENT_DATE;

// Breakdown by source
SELECT 
  payload->>'source' as source,
  SUM((payload->>'amount')::int) as total_earned,
  COUNT(*) as transaction_count,
  AVG((payload->>'amount')::int) as avg_earned
FROM events
WHERE event_name = 'currency_earned'
AND payload->>'currency_type' = 'coins'
AND DATE(timestamp) = CURRENT_DATE
GROUP BY source
ORDER BY total_earned DESC;
```

**🔴 ACTION REQUIRED:** Add `currency_earned` event to Flutter app

---

### 6. **Total Gems Earned Today - Details on How** ⚠️ **MISSING DATA**

**What You Want:**
- Sum of gems earned
- Breakdown: missions, levels, purchases, prizes

**Same as #5** - Need `currency_earned` event with `currency_type: "gems"`

**🔴 ACTION REQUIRED:** Add `currency_earned` event to Flutter app

---

### 7. **Number of Levels Completed Today** ✅ GOOD

**What You Want:**
- Count of completed levels

**Industry Best Practice: EXPAND THIS**
- **Completions by Level** - Which levels are completed most?
- **Unique Players per Level** - Progression funnel
- **Average Attempts** - Difficulty indicator
- **3-Star Rate** - Quality of completion

**Data Source:**
```javascript
// Total completions
SELECT COUNT(*)
FROM events
WHERE event_name = 'level_completed'
AND DATE(timestamp) = CURRENT_DATE;

// By level
SELECT 
  payload->>'level_id' as level,
  COUNT(*) as completions,
  COUNT(DISTINCT user_id) as unique_players,
  AVG((payload->>'stars')::int) as avg_stars
FROM events
WHERE event_name = 'level_completed'
AND DATE(timestamp) = CURRENT_DATE
GROUP BY level
ORDER BY level;
```

**✅ WE HAVE THIS DATA** - Event: `level_completed`

---

### 8. **Number of Continues Used Today** ⚠️ **MISSING DATA**

**What You Want:**
- Count of continue purchases (after death)

**Industry Best Practice: CRITICAL METRIC**
This shows:
- **Difficulty perception** - Too many continues = too hard
- **Monetization opportunity** - Continues are a revenue source
- **User frustration** - High continues = poor experience

**Current Problem: ❌ WE DON'T HAVE THIS EVENT**

**What We Need to Add:**
```javascript
// NEW EVENT: continue_used
{
  "name": "continue_used",
  "payload": {
    "game_mode": "endless",
    "score_at_death": 42,
    "continue_type": "ad_watch",     // or "coin_purchase", "gem_purchase"
    "cost_coins": 0,                 // 0 if ad, X if purchased
    "cost_gems": 0,
    "lives_restored": 1
  }
}
```

**Dashboard Query:**
```javascript
// Total continues
SELECT COUNT(*)
FROM events
WHERE event_name = 'continue_used'
AND DATE(timestamp) = CURRENT_DATE;

// By type
SELECT 
  payload->>'continue_type' as type,
  COUNT(*) as count
FROM events
WHERE event_name = 'continue_used'
AND DATE(timestamp) = CURRENT_DATE
GROUP BY type;
```

**🔴 ACTION REQUIRED:** Add `continue_used` event to Flutter app

---

### 9. **Levels Extra Data** ✅ MOSTLY GOOD

**What You Want:**
- Per-level metrics: games played, success, failure, continues

**Industry Best Practice: PERFECT - This is a "Progression Funnel"**

**Data We Have:**
- ✅ Games played per level - `level_started` (if we have it)
- ✅ Success count - `level_completed`
- ❌ Failure count - Need `level_failed` event
- ❌ Continues used per level - Need `continue_used` with `level_id`

**Current Problem: Missing some events**

**What We Need to Add:**
```javascript
// NEW EVENT: level_started
{
  "name": "level_started",
  "payload": {
    "level_id": 13,
    "zone_id": 2,
    "attempt_number": 3,    // How many times tried this level
    "hearts_remaining": 2
  }
}

// NEW EVENT: level_failed
{
  "name": "level_failed",
  "payload": {
    "level_id": 13,
    "zone_id": 2,
    "score": 42,
    "cause_of_death": "obstacle_collision",
    "time_survived_seconds": 30,
    "hearts_remaining": 0
  }
}
```

**Dashboard Query:**
```javascript
// Progression funnel per level
SELECT 
  l.level_id,
  COUNT(DISTINCT CASE WHEN l.event_name = 'level_started' THEN l.user_id END) as players_started,
  COUNT(DISTINCT CASE WHEN l.event_name = 'level_completed' THEN l.user_id END) as players_completed,
  COUNT(DISTINCT CASE WHEN l.event_name = 'level_failed' THEN l.user_id END) as players_failed,
  (COUNT(DISTINCT CASE WHEN l.event_name = 'level_completed' THEN l.user_id END) * 100.0 / 
   NULLIF(COUNT(DISTINCT CASE WHEN l.event_name = 'level_started' THEN l.user_id END), 0)) as completion_rate,
  COUNT(c.id) as continues_used
FROM events l
LEFT JOIN events c ON c.event_name = 'continue_used' 
  AND c.payload->>'level_id' = l.payload->>'level_id'
  AND DATE(c.timestamp) = CURRENT_DATE
WHERE l.event_name IN ('level_started', 'level_completed', 'level_failed')
AND DATE(l.timestamp) = CURRENT_DATE
GROUP BY l.payload->>'level_id'
ORDER BY l.payload->>'level_id';
```

**🔴 ACTION REQUIRED:** Add `level_started` and `level_failed` events

---

### 10. **Split by User Params (OS, App Version, Country)** ✅ PERFECT

**What You Want:**
- Filter all metrics by platform, version, country

**Industry Best Practice: ESSENTIAL**
This is called **segmentation** and it's critical for:
- A/B testing
- Platform-specific issues
- Geographic insights
- Version rollout tracking

**Data We Have:**
- ✅ OS/Platform - from `user_installed` and stored in `users` table
- ✅ App Version - from `user_installed` and `app_launched`
- ✅ Country - from `user_installed`

**Dashboard Implementation:**
```javascript
// Example: DAU by platform
SELECT 
  u.platform,
  COUNT(DISTINCT e.user_id) as dau
FROM events e
JOIN users u ON e.user_id = u.user_id
WHERE e.event_name = 'app_launched'
AND DATE(e.timestamp) = CURRENT_DATE
GROUP BY u.platform;

// Example: Games by country
SELECT 
  u.country,
  COUNT(*) as games_played
FROM events e
JOIN users u ON e.user_id = u.user_id
WHERE e.event_name = 'game_ended'
AND DATE(e.timestamp) = CURRENT_DATE
GROUP BY u.country
ORDER BY games_played DESC
LIMIT 10;
```

**✅ WE HAVE THIS DATA** - From `users` table

---

## 🚀 RECOMMENDED ADDITIONAL DASHBOARDS

Based on gaming industry best practices, here are **critical dashboards you're missing**:

### 1. **Retention Dashboard** ⭐⭐⭐⭐⭐ **CRITICAL**

**Why You Need This:**
Retention is THE most important metric in mobile gaming. If users don't come back, nothing else matters.

**Metrics:**
- **D1 Retention** - % users who return next day (target: 40%+)
- **D3 Retention** - % users who return after 3 days (target: 25%+)
- **D7 Retention** - % users who return after 7 days (target: 15%+)
- **D30 Retention** - % users who return after 30 days (target: 5%+)
- **Retention Curve** - Visual graph of retention over time
- **Cohort Analysis** - Retention by install date

**Dashboard Query:**
```javascript
// D1 Retention
WITH installs AS (
  SELECT user_id, DATE(timestamp) as install_date
  FROM events
  WHERE event_name = 'user_installed'
),
day1_returns AS (
  SELECT DISTINCT i.user_id
  FROM installs i
  JOIN events e ON i.user_id = e.user_id
  WHERE e.event_name = 'app_launched'
  AND DATE(e.timestamp) = i.install_date + INTERVAL '1 day'
)
SELECT 
  COUNT(DISTINCT r.user_id) * 100.0 / COUNT(DISTINCT i.user_id) as d1_retention
FROM installs i
LEFT JOIN day1_returns r ON i.user_id = r.user_id
WHERE i.install_date = CURRENT_DATE - INTERVAL '1 day';
```

**Data We Have:**
- ✅ `user_installed` event (install date)
- ✅ `app_launched` event (return tracking)

---

### 2. **Revenue Dashboard** ⭐⭐⭐⭐⭐ **CRITICAL**

**Why You Need This:**
Money keeps the game alive. You need to understand your revenue streams.

**Metrics:**
- **Total Revenue Today** - Sum of all purchases
- **ARPU (Average Revenue Per User)** - Total revenue / Total users
- **ARPPU (Average Revenue Per Paying User)** - Total revenue / Paying users
- **Conversion Rate** - Paying users / Total users
- **Revenue by Product** - Which IAPs are most popular?
- **Revenue by Source** - Ads vs IAP
- **LTV by Cohort** - Lifetime value per install date

**Dashboard Query:**
```javascript
// Revenue metrics
SELECT 
  SUM((payload->>'price_usd')::decimal) as total_revenue,
  COUNT(DISTINCT user_id) as paying_users,
  SUM((payload->>'price_usd')::decimal) / COUNT(DISTINCT user_id) as arppu,
  COUNT(*) as transactions
FROM events
WHERE event_name = 'purchase_completed'
AND DATE(timestamp) = CURRENT_DATE;

// ARPU (need total user count)
SELECT 
  (SELECT SUM((payload->>'price_usd')::decimal) 
   FROM events 
   WHERE event_name = 'purchase_completed' 
   AND DATE(timestamp) = CURRENT_DATE) / 
  (SELECT COUNT(DISTINCT user_id) 
   FROM events 
   WHERE event_name = 'app_launched' 
   AND DATE(timestamp) = CURRENT_DATE) as arpu;
```

**Data We Have:**
- ✅ `purchase_completed` event (with price, product)
- ✅ `ad_watched` event (for ad revenue estimation)

---

### 3. **Session Analytics Dashboard** ⭐⭐⭐⭐ **IMPORTANT**

**Why You Need This:**
Session quality indicates engagement depth.

**Metrics:**
- **Average Session Length** - How long users play per session
- **Sessions per DAU** - How often users return per day
- **Session Depth** - Games per session
- **Session Distribution** - Histogram of session lengths

**Dashboard Query:**
```javascript
// Average session metrics
WITH sessions AS (
  SELECT 
    user_id,
    session_id,
    MIN(timestamp) as session_start,
    MAX(timestamp) as session_end,
    COUNT(CASE WHEN event_name = 'game_started' THEN 1 END) as games_in_session
  FROM events
  WHERE DATE(timestamp) = CURRENT_DATE
  GROUP BY user_id, session_id
)
SELECT 
  AVG(EXTRACT(EPOCH FROM (session_end - session_start))) as avg_session_seconds,
  AVG(games_in_session) as avg_games_per_session,
  COUNT(*) / COUNT(DISTINCT user_id) as sessions_per_user
FROM sessions;
```

**Data We Have:**
- ✅ Session tracking (session_id in all events)
- ✅ Timestamps on all events

---

### 4. **Funnel Analytics Dashboard** ⭐⭐⭐⭐ **IMPORTANT**

**Why You Need This:**
See where users drop off in key flows.

**Key Funnels:**

**A) Onboarding Funnel:**
```
Install → Tutorial Start → Tutorial Complete → First Game → Second Game
```

**B) Monetization Funnel:**
```
Store Viewed → Product Clicked → Purchase Initiated → Purchase Completed
```

**C) Level Progression Funnel:**
```
Level 1 Start → Level 1 Complete → Level 2 Start → ... → Level 50 Complete
```

**Dashboard Query:**
```javascript
// Onboarding funnel
SELECT 
  COUNT(DISTINCT CASE WHEN event_name = 'user_installed' THEN user_id END) as installs,
  COUNT(DISTINCT CASE WHEN event_name = 'tutorial_started' THEN user_id END) as tutorial_starts,
  COUNT(DISTINCT CASE WHEN event_name = 'tutorial_completed' THEN user_id END) as tutorial_completes,
  COUNT(DISTINCT CASE WHEN event_name = 'game_started' THEN user_id END) as first_games
FROM events
WHERE DATE(timestamp) = CURRENT_DATE;
```

**Data We Have:**
- ⚠️ Partial - Need `tutorial_started` and `tutorial_completed` events
- ✅ Have `screen_viewed` for store funnel
- ✅ Have `purchase_initiated` and `purchase_completed`

---

### 5. **Technical Health Dashboard** ⭐⭐⭐⭐ **IMPORTANT**

**Why You Need This:**
Crashes and errors destroy user experience.

**Metrics:**
- **Crash Rate** - Crashes / Sessions
- **Error Count** - By error type
- **ANR Rate** (Android) - App Not Responding events
- **Errors by Version** - Which versions are buggy?
- **Errors by Device** - Device-specific issues

**Dashboard Query:**
```javascript
// Crash rate
SELECT 
  COUNT(CASE WHEN event_name = 'error_occurred' 
    AND payload->>'error_type' = 'crash' THEN 1 END) * 100.0 /
  COUNT(DISTINCT session_id) as crash_rate
FROM events
WHERE DATE(timestamp) = CURRENT_DATE;

// Errors by type
SELECT 
  payload->>'error_type' as error_type,
  COUNT(*) as count
FROM events
WHERE event_name = 'error_occurred'
AND DATE(timestamp) = CURRENT_DATE
GROUP BY error_type
ORDER BY count DESC;
```

**Data We Have:**
- ✅ `error_occurred` event

---

### 6. **Competitive Features Dashboard** ⭐⭐⭐ **GOOD TO HAVE**

**Why You Need This:**
Leaderboards and tournaments drive engagement.

**Metrics:**
- **Tournament Participation Rate** - % of DAU who entered
- **Tournament Completion Rate** - % who submitted scores
- **Leaderboard Views** - Engagement with rankings
- **Average Tournament Score** - Difficulty balance
- **Prize Claim Rate** - % of prizes claimed

**Dashboard Query:**
```javascript
// Tournament metrics
SELECT 
  COUNT(DISTINCT CASE WHEN t.event_name = 'tournament_entered' THEN t.user_id END) * 100.0 /
  COUNT(DISTINCT a.user_id) as participation_rate
FROM events a
LEFT JOIN events t ON a.user_id = t.user_id 
  AND t.event_name = 'tournament_entered'
  AND DATE(t.timestamp) = CURRENT_DATE
WHERE a.event_name = 'app_launched'
AND DATE(a.timestamp) = CURRENT_DATE;
```

**Data We Have:**
- ⚠️ Partial - Need `tournament_entered` event
- ✅ Have `leaderboard_viewed`
- ✅ Have `prize_claimed`

---

### 7. **Balance & Difficulty Dashboard** ⭐⭐⭐ **GOOD TO HAVE**

**Why You Need This:**
Too hard = frustration. Too easy = boredom.

**Metrics:**
- **Score Distribution** - Histogram of scores
- **Death Cause Analysis** - What kills players most?
- **Level First-Attempt Success Rate** - Difficulty per level
- **Average Attempts per Level** - How many tries to beat?
- **Powerup Usage** - Are powerups helping?

**Dashboard Query:**
```javascript
// Death causes
SELECT 
  payload->>'cause_of_death' as cause,
  COUNT(*) as deaths
FROM events
WHERE event_name = 'game_ended'
AND DATE(timestamp) = CURRENT_DATE
GROUP BY cause
ORDER BY deaths DESC;

// Level difficulty
SELECT 
  payload->>'level_id' as level,
  AVG(payload->>'attempt_number'::int) as avg_attempts
FROM events
WHERE event_name = 'level_completed'
AND DATE(timestamp) = CURRENT_DATE
GROUP BY level;
```

**Data We Have:**
- ✅ `game_ended` has `cause_of_death`
- ⚠️ Need to add `attempt_number` to events

---

## 📋 DATA AVAILABILITY ANALYSIS

### ✅ **Data We HAVE** (Ready to Use)

| Metric | Event Source | Status |
|--------|--------------|--------|
| DAU | `app_launched` | ✅ Ready |
| Games Started | `game_started` | ✅ Ready |
| Games Completed | `game_ended` | ✅ Ready |
| Level Completions | `level_completed` | ✅ Ready |
| Revenue | `purchase_completed` | ✅ Ready |
| Ad Views | `ad_watched` | ✅ Ready |
| Errors | `error_occurred` | ✅ Ready |
| User Params | `users` table | ✅ Ready |
| Achievements | `achievement_unlocked` | ✅ Ready |
| Missions | `mission_completed` | ✅ Ready |

---

### ⚠️ **Data We're MISSING** (Need to Add)

| Metric | Missing Event | Priority |
|--------|---------------|----------|
| **Coins Spent** | `currency_spent` | 🔴 HIGH |
| **Gems Spent** | `currency_spent` | 🔴 HIGH |
| **Coins Earned** | `currency_earned` | 🔴 HIGH |
| **Gems Earned** | `currency_earned` | 🔴 HIGH |
| **Continues Used** | `continue_used` | 🔴 HIGH |
| **Level Started** | `level_started` | 🟡 MEDIUM |
| **Level Failed** | `level_failed` | 🟡 MEDIUM |
| **Tournament Entry** | `tournament_entered` | 🟡 MEDIUM |
| **Tutorial Events** | `tutorial_started`, `tutorial_completed` | 🟢 LOW |

---

## 🔴 MISSING EVENTS TO ADD

### Priority 1: Economy Tracking (CRITICAL)

#### `currency_spent`
```json
{
  "name": "currency_spent",
  "user_id": "user_xxx",
  "session_id": "session_xxx",
  "timestamp": "2025-11-09T14:30:00Z",
  "payload": {
    "currency_type": "coins",        // or "gems"
    "amount": 500,
    "spent_on": "skin_purchase",     // category
    "item_id": "skin_gold",          // specific item
    "balance_before": 1500,
    "balance_after": 1000,
    "transaction_id": "txn_local_xxx"
  }
}
```

**Fire When:**
- Player buys skin/jet with coins/gems
- Player buys booster with coins/gems
- Player uses continue with coins/gems
- Player buys hearts with coins/gems

---

#### `currency_earned`
```json
{
  "name": "currency_earned",
  "user_id": "user_xxx",
  "session_id": "session_xxx",
  "timestamp": "2025-11-09T14:30:00Z",
  "payload": {
    "currency_type": "coins",        // or "gems"
    "amount": 100,
    "source": "mission_completed",   // how earned
    "source_id": "daily_mission_3",  // specific source
    "balance_before": 1000,
    "balance_after": 1100
  }
}
```

**Fire When:**
- Mission completed (reward coins/gems)
- Level completed (reward coins/gems)
- Ad watched (reward coins/gems)
- Prize claimed (reward coins/gems)
- Daily login reward
- Achievement reward

---

#### `continue_used`
```json
{
  "name": "continue_used",
  "user_id": "user_xxx",
  "session_id": "session_xxx",
  "timestamp": "2025-11-09T14:30:00Z",
  "payload": {
    "game_mode": "endless",          // or "story"
    "level_id": 13,                  // if story mode
    "score_at_death": 42,
    "continue_type": "ad_watch",     // or "coin_purchase", "gem_purchase"
    "cost_coins": 0,                 // cost if purchased
    "cost_gems": 0,
    "lives_restored": 1
  }
}
```

**Fire When:**
- Player watches ad for continue
- Player buys continue with coins
- Player buys continue with gems

---

### Priority 2: Level Progression (IMPORTANT)

#### `level_started`
```json
{
  "name": "level_started",
  "user_id": "user_xxx",
  "session_id": "session_xxx",
  "timestamp": "2025-11-09T14:30:00Z",
  "payload": {
    "level_id": 13,
    "zone_id": 2,
    "attempt_number": 3,             // How many times tried
    "hearts_remaining": 2,
    "boosters_active": ["shield"]
  }
}
```

**Fire When:**
- Player starts a story mode level

---

#### `level_failed`
```json
{
  "name": "level_failed",
  "user_id": "user_xxx",
  "session_id": "session_xxx",
  "timestamp": "2025-11-09T14:30:00Z",
  "payload": {
    "level_id": 13,
    "zone_id": 2,
    "score": 42,
    "cause_of_death": "obstacle_collision",
    "time_survived_seconds": 30,
    "hearts_remaining": 0,
    "attempt_number": 3
  }
}
```

**Fire When:**
- Player fails a story mode level (runs out of hearts)

---

### Priority 3: Social Features (NICE TO HAVE)

#### `tournament_entered`
```json
{
  "name": "tournament_entered",
  "user_id": "user_xxx",
  "session_id": "session_xxx",
  "timestamp": "2025-11-09T14:30:00Z",
  "payload": {
    "tournament_id": "tournament_2025_w45",
    "tournament_name": "Weekly Championship"
  }
}
```

**Fire When:**
- Player plays their first game in a tournament period

---

## 📊 DASHBOARD IMPLEMENTATION

### Technology Recommendations

**Option 1: Metabase (Open Source)** ⭐ **RECOMMENDED**
- Free, open-source
- Easy setup on Railway
- SQL-based dashboards
- Beautiful visualizations
- Role-based access

**Option 2: Apache Superset**
- More powerful than Metabase
- Steeper learning curve
- Better for large scale

**Option 3: Custom Dashboard (React + Chart.js)**
- Full control
- More development time
- Can embed in your admin panel

---

### Sample Dashboard Layout

```
┌──────────────────────────────────────────────────────────┐
│  📊 FLAPPYJET PRO - EXECUTIVE DASHBOARD                  │
│  Last Updated: 2 minutes ago                             │
├──────────────────────────────────────────────────────────┤
│                                                           │
│  ┌─────────────┬─────────────┬─────────────┬──────────┐ │
│  │ DAU         │ Revenue     │ ARPU        │ Crashes  │ │
│  │ 12,543 ▲5%  │ $2,345 ▲12% │ $0.19 ▲7%   │ 23 ▼45%  │ │
│  └─────────────┴─────────────┴─────────────┴──────────┘ │
│                                                           │
│  ┌──────────────────────────────────────────────────────┐│
│  │ 📈 DAU TREND (Last 30 Days)                          ││
│  │ [Line Chart: Shows upward trend]                     ││
│  └──────────────────────────────────────────────────────┘│
│                                                           │
│  ┌────────────────────────┬────────────────────────────┐ │
│  │ 🎮 Games Today         │ 💰 Economy Today           │ │
│  │ • Started: 45,231      │ • Coins Earned: 1.2M       │ │
│  │ • Completed: 42,109    │ • Coins Spent: 890K        │ │
│  │ • Completion: 93%      │ • Net Flow: +310K ✅       │ │
│  │                        │                            │ │
│  │ [Bar Chart: By Mode]   │ [Pie Chart: By Source]    │ │
│  └────────────────────────┴────────────────────────────┘ │
│                                                           │
│  ┌──────────────────────────────────────────────────────┐│
│  │ 🏆 TOP PERFORMERS TODAY                              ││
│  │ Level 13: 3,521 completions (78% success rate)       ││
│  │ Mission "Score 1000": 8,234 completions             ││
│  │ Skin "Gold Jet": 234 purchases ($1,170 revenue)     ││
│  └──────────────────────────────────────────────────────┘│
│                                                           │
│  Filters: [All Platforms ▼] [All Countries ▼] [Today ▼] │
└──────────────────────────────────────────────────────────┘
```

---

## ✅ FINAL RECOMMENDATIONS

### Your Requested Dashboards: **8/10 Ready**

✅ **READY:**
- DAU tracking
- Number of games
- Levels completed
- User segmentation (OS, version, country)

❌ **NEED TO ADD EVENTS:**
- Coins/Gems spent tracking → Add `currency_spent` event
- Coins/Gems earned tracking → Add `currency_earned` event
- Continues tracking → Add `continue_used` event
- Level extra data → Add `level_started`, `level_failed` events

### Industry Best Practices: **ADD THESE CRITICAL DASHBOARDS**

1. ⭐⭐⭐⭐⭐ **Retention Dashboard** - Most important metric
2. ⭐⭐⭐⭐⭐ **Revenue Dashboard** - ARPU, LTV, conversion
3. ⭐⭐⭐⭐ **Session Analytics** - Engagement depth
4. ⭐⭐⭐⭐ **Funnel Analytics** - Drop-off analysis
5. ⭐⭐⭐⭐ **Technical Health** - Crash/error tracking
6. ⭐⭐⭐ **Competitive Features** - Tournament/leaderboard
7. ⭐⭐⭐ **Balance Dashboard** - Difficulty analysis

---

## 🚀 ACTION PLAN

### Step 1: Add Missing Events (Week 1)
1. Implement `currency_spent` event
2. Implement `currency_earned` event
3. Implement `continue_used` event
4. Implement `level_started` event
5. Implement `level_failed` event
6. Implement `tournament_entered` event

### Step 2: Backend Event Processing (Week 2)
1. Add event handlers for new events
2. Create aggregation queries
3. Test data flow

### Step 3: Dashboard Setup (Week 3)
1. Install Metabase on Railway
2. Create dashboard templates
3. Build your requested dashboards
4. Build recommended dashboards

### Step 4: Iteration (Week 4)
1. Review with team
2. Add custom metrics
3. Set up alerts
4. Train team on usage

---

**Ready to proceed?** 🚀

Should we:
1. **Start adding the missing events to Flutter app?**
2. **Set up Metabase on Railway first?**
3. **Something else?**

