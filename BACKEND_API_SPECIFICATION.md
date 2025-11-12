# 🚀 FlappyJet Pro - Backend API Specification
**Version:** 1.0  
**Last Updated:** November 9, 2025  
**Status:** 🟡 In Development

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Event Processing System](#event-processing-system)
4. [REST API Endpoints](#rest-api-endpoints)
5. [Event Schema & Processing](#event-schema--processing)
6. [Database Schema](#database-schema)
7. [Analytics & Metrics](#analytics--metrics)
8. [Background Jobs](#background-jobs)
9. [Migration Strategy](#migration-strategy)

---

## 🎯 Overview

### Core Principles
- **Event-Driven:** All client actions fire events, processed asynchronously
- **Non-Blocking:** Never block client gameplay
- **Eventually Consistent:** Accept data delays for better UX
- **Minimal:** Only what's essential for analytics and global features

### Key Features
| Feature | Type | Purpose |
|---------|------|---------|
| Event Ingestion | POST endpoint | Receive and queue all client events |
| Global Leaderboard | GET endpoint | Return top 100 players globally |
| Tournament System | GET/POST endpoints | Weekly tournaments with prizes |
| Prize Distribution | GET endpoint | Calculate and serve pending prizes |
| Analytics Dashboard | Internal | Real-time game metrics and insights |

### Technology Stack
- **Runtime:** Node.js + Express
- **Database:** PostgreSQL (for analytics, leaderboards, tournaments)
- **Queue:** Built-in async processing (or Redis if needed)
- **Deployment:** Railway (already configured)

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    CLIENT (Flutter App)                      │
│  - SQLite local storage                                      │
│  - Fire-and-forget events                                    │
│  - Poll for global data (leaderboards, prizes)               │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ HTTPS
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                   RAILWAY BACKEND (Express)                  │
│                                                               │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ POST /api/events/batch                                 │  │
│  │ - Accept events (200 OK immediately)                   │  │
│  │ - Queue for async processing                           │  │
│  └───────────────────────────────────────────────────────┘  │
│                            │                                  │
│  ┌─────────────────────────▼──────────────────────────────┐ │
│  │          ASYNC EVENT PROCESSOR                          │ │
│  │  - Process events in background                         │ │
│  │  - Update leaderboards                                  │ │
│  │  - Track analytics                                      │ │
│  │  - Calculate prizes                                     │ │
│  └─────────────────────────────────────────────────────────┘ │
│                            │                                  │
│  ┌─────────────────────────▼──────────────────────────────┐ │
│  │              PostgreSQL Database                        │ │
│  │  - users (user info)                                    │ │
│  │  - events (raw events for analytics)                    │ │
│  │  - leaderboard (global rankings)                        │ │
│  │  - tournaments (weekly competitions)                    │ │
│  │  - tournament_entries (participant scores)              │ │
│  │  - prizes (calculated prizes)                           │ │
│  │  - analytics (aggregated metrics)                       │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                               │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ GET /api/leaderboard/global?limit=100                  │  │
│  │ - Return cached global top 100                         │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                               │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ GET /api/tournaments/current                           │  │
│  │ - Return current tournament info                       │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                               │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ GET /api/prizes/pending?user_id=xxx                    │  │
│  │ - Return unclaimed prizes for user                     │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                               │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ CRON JOBS (Background)                                 │  │
│  │ - Tournament weekly reset                              │  │
│  │ - Prize calculation                                    │  │
│  │ - Analytics aggregation                                │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## 📡 Event Processing System

### Event Flow
```
Client → POST /api/events/batch → Queue → Async Processor → Database → Analytics
                    ↓
               200 OK (instant)
```

### Event Batching
- Client sends events in batches (up to 50 events)
- Backend accepts immediately (200 OK)
- Events queued for processing
- Processing happens async (doesn't block client)

### Event Structure (From Client)
```json
{
  "events": [
    {
      "name": "game_ended",
      "user_id": "user_BP22.250325.006...",
      "session_id": "session_ec5024c3-8d1...",
      "timestamp": "2025-11-09T14:30:00Z",
      "payload": {
        "score": 42,
        "game_mode": "endless",
        "duration_seconds": 120,
        "obstacles_dodged": 38,
        "coins_collected": 15
      }
    }
  ]
}
```

### Processing Priorities
| Priority | Events | Processing Time |
|----------|--------|----------------|
| High (P1) | `game_ended`, `tournament_score_submit` | < 1 second |
| Medium (P2) | `purchase_completed`, `prize_claimed` | < 5 seconds |
| Low (P3) | UI events, analytics events | < 30 seconds |

---

## 🔌 REST API Endpoints

### 1. Event Ingestion

#### `POST /api/events/batch`
**Purpose:** Accept batch of events from client  
**Auth:** None (user_id in payload)  
**Rate Limit:** 100 requests/minute per user

**Request Body:**
```json
{
  "events": [
    {
      "name": "event_name",
      "user_id": "user_xxx",
      "session_id": "session_xxx",
      "timestamp": "ISO8601",
      "payload": {}
    }
  ]
}
```

**Response:**
```json
{
  "success": true,
  "received": 5,
  "message": "Events queued for processing"
}
```

**Processing:**
1. Validate event schema
2. Queue events (in-memory or Redis)
3. Return 200 OK immediately
4. Process async (see Event Schema section)

---

### 2. Global Leaderboard

#### `GET /api/leaderboard/global`
**Purpose:** Get global top 100 players  
**Auth:** None (public data)  
**Cache:** 5 minutes

**Query Parameters:**
- `limit` (optional, default: 100, max: 100)
- `offset` (optional, default: 0, for pagination)

**Response:**
```json
{
  "success": true,
  "leaderboard": [
    {
      "rank": 1,
      "user_id": "user_xxx",
      "nickname": "ProPilot",
      "score": 1543,
      "timestamp": "2025-11-09T12:00:00Z"
    }
  ],
  "last_updated": "2025-11-09T14:25:00Z",
  "total_players": 50000
}
```

**Database Query:**
```sql
SELECT 
  user_id, 
  nickname, 
  high_score as score, 
  updated_at as timestamp,
  ROW_NUMBER() OVER (ORDER BY high_score DESC) as rank
FROM leaderboard
ORDER BY high_score DESC
LIMIT ? OFFSET ?
```

---

### 3. Tournament System

#### `GET /api/tournaments/current`
**Purpose:** Get current weekly tournament info  
**Auth:** None  
**Cache:** 10 minutes

**Response:**
```json
{
  "success": true,
  "tournament": {
    "tournament_id": "tournament_2025_w45",
    "name": "Weekly Championship",
    "start_date": "2025-11-03T00:00:00Z",
    "end_date": "2025-11-10T00:00:00Z",
    "status": "active",
    "prize_pool": {
      "1st": {"coins": 5000, "gems": 250},
      "2nd": {"coins": 3000, "gems": 150},
      "3rd": {"coins": 2000, "gems": 100},
      "4-10": {"coins": 1000, "gems": 50},
      "11-50": {"coins": 500, "gems": 25}
    },
    "participant_count": 15234
  }
}
```

#### `GET /api/tournaments/:id/leaderboard`
**Purpose:** Get tournament leaderboard (top 50)  
**Auth:** None  
**Cache:** 2 minutes

**Response:**
```json
{
  "success": true,
  "tournament_id": "tournament_2025_w45",
  "entries": [
    {
      "rank": 1,
      "user_id": "user_xxx",
      "nickname": "Champion",
      "score": 2341,
      "timestamp": "2025-11-09T13:00:00Z"
    }
  ],
  "user_rank": 42,
  "user_score": 156
}
```

**Query Parameters:**
- `user_id` (optional) - Include user's rank even if not in top 50

---

### 4. Prize Distribution

#### `GET /api/prizes/pending`
**Purpose:** Get unclaimed prizes for a user  
**Auth:** None (user_id in query)  
**Cache:** None (real-time)

**Query Parameters:**
- `user_id` (required)

**Response:**
```json
{
  "success": true,
  "prizes": [
    {
      "prize_id": "prize_t2025w45_user123",
      "tournament_id": "tournament_2025_w45",
      "tournament_name": "Weekly Championship",
      "rank": 3,
      "coins": 2000,
      "gems": 100,
      "awarded_at": "2025-11-10T00:05:00Z"
    }
  ]
}
```

**Processing:**
- Query `prizes` table for unclaimed prizes
- Only return prizes where `claimed_at IS NULL`

#### `POST /api/prizes/claim`
**Purpose:** Mark a prize as claimed (fire-and-forget from client)  
**Auth:** None  
**Response:** Acknowledge only

**Request Body:**
```json
{
  "prize_id": "prize_xxx",
  "user_id": "user_xxx",
  "claimed_at": "2025-11-09T14:30:00Z"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Prize claim recorded"
}
```

**Processing:**
1. Update `prizes` table: `claimed_at = ?`
2. Log to analytics
3. Return 200 OK

---

## 📊 Event Schema & Processing

### Event Categories
1. **User Lifecycle** (5 events)
2. **Game Session** (6 events)
3. **Monetization** (5 events)
4. **Social** (3 events)
5. **Progression** (4 events)
6. **UI/UX** (3 events)
7. **System** (2 events)

---

### 1. USER LIFECYCLE EVENTS

#### `user_installed`
**Trigger:** First app launch  
**Frequency:** Once per user  
**Payload:**
```json
{
  "platform": "android",
  "device_model": "Google Pixel 6",
  "os_version": "Android 13",
  "app_version": "2.0.3",
  "country": "US",
  "timezone": "America/New_York",
  "install_source": "organic"
}
```

**Backend Processing:**
```javascript
// 1. Create user record
INSERT INTO users (
  user_id, platform, device_model, os_version, 
  app_version, country, timezone, install_source,
  created_at, first_seen_at
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())
ON CONFLICT (user_id) DO NOTHING;

// 2. Analytics aggregation
UPDATE analytics_daily 
SET new_installs = new_installs + 1
WHERE date = CURRENT_DATE AND platform = ?;

// 3. Attribution tracking (if install_source != 'organic')
INSERT INTO attribution_events (user_id, source, timestamp)
VALUES (?, ?, ?);
```

**Analytics Purpose:**
- Track daily/monthly installs
- Platform distribution (iOS vs Android)
- Geographic distribution
- Attribution tracking
- Cohort analysis

---

#### `app_launched`
**Trigger:** Every app open  
**Frequency:** Multiple per day  
**Payload:**
```json
{
  "app_version": "2.0.3",
  "session_number": 42,
  "time_since_last_session": 3600
}
```

**Backend Processing:**
```javascript
// 1. Update user last seen
UPDATE users 
SET last_seen_at = NOW(), 
    session_count = session_count + 1,
    app_version = ?
WHERE user_id = ?;

// 2. DAU/MAU tracking
INSERT INTO daily_active_users (user_id, date)
VALUES (?, CURRENT_DATE)
ON CONFLICT DO NOTHING;

// 3. Session gap analysis
IF (time_since_last_session > 86400) {
  // User returned after 1+ day
  UPDATE analytics_daily
  SET returning_users = returning_users + 1
  WHERE date = CURRENT_DATE;
}
```

**Analytics Purpose:**
- Daily Active Users (DAU)
- Monthly Active Users (MAU)
- Session frequency
- User retention curves
- Churn prediction

---

### 2. GAME SESSION EVENTS

#### `game_started`
**Trigger:** Player starts a game  
**Frequency:** Multiple per session  
**Payload:**
```json
{
  "game_mode": "endless",
  "selected_jet": "jet_classic",
  "selected_skin": "skin_gold",
  "hearts_remaining": 3,
  "powerups_active": ["shield", "magnet"]
}
```

**Backend Processing:**
```javascript
// 1. Track game starts
UPDATE analytics_daily
SET games_started = games_started + 1
WHERE date = CURRENT_DATE AND game_mode = ?;

// 2. Jet/Skin popularity
INSERT INTO item_usage (item_id, usage_count, date)
VALUES (?, 1, CURRENT_DATE)
ON CONFLICT (item_id, date) 
DO UPDATE SET usage_count = usage_count + 1;
```

**Analytics Purpose:**
- Game mode popularity
- Jet/skin usage distribution
- Powerup adoption rates
- Hearts system usage

---

#### `game_ended`
**Trigger:** Game over (crash or quit)  
**Frequency:** Multiple per session  
**Priority:** **HIGH (P1)** - Updates leaderboard  
**Payload:**
```json
{
  "game_mode": "endless",
  "score": 42,
  "duration_seconds": 120,
  "obstacles_dodged": 38,
  "coins_collected": 15,
  "gems_collected": 2,
  "hearts_remaining": 0,
  "cause_of_death": "obstacle_collision",
  "max_combo": 12,
  "powerups_used": ["shield", "magnet"]
}
```

**Backend Processing:**
```javascript
// 1. Update global leaderboard (if new high score)
INSERT INTO leaderboard (user_id, high_score, updated_at)
VALUES (?, ?, NOW())
ON CONFLICT (user_id) 
DO UPDATE SET 
  high_score = GREATEST(leaderboard.high_score, EXCLUDED.high_score),
  updated_at = NOW()
WHERE EXCLUDED.high_score > leaderboard.high_score;

// 2. Update tournament entry (if active tournament)
IF (tournament_active AND game_mode == 'endless') {
  INSERT INTO tournament_entries (tournament_id, user_id, score, timestamp)
  VALUES (?, ?, ?, NOW())
  ON CONFLICT (tournament_id, user_id)
  DO UPDATE SET 
    score = GREATEST(tournament_entries.score, EXCLUDED.score),
    timestamp = NOW()
  WHERE EXCLUDED.score > tournament_entries.score;
}

// 3. Analytics aggregation
UPDATE analytics_daily
SET 
  games_completed = games_completed + 1,
  total_score = total_score + ?,
  total_playtime_seconds = total_playtime_seconds + ?,
  avg_score = total_score / games_completed
WHERE date = CURRENT_DATE;

// 4. Score distribution (for difficulty balancing)
INSERT INTO score_distribution (score_bucket, count, date)
VALUES (
  FLOOR(? / 10) * 10,  -- Round to nearest 10
  1,
  CURRENT_DATE
)
ON CONFLICT (score_bucket, date)
DO UPDATE SET count = count + 1;

// 5. Death cause analysis
UPDATE death_causes
SET count = count + 1
WHERE cause = ? AND date = CURRENT_DATE;
```

**Analytics Purpose:**
- **CRITICAL:** Global leaderboard updates
- **CRITICAL:** Tournament rankings
- Score distribution (difficulty balancing)
- Session length analysis
- Retention by score
- Death cause analysis (game balance)
- Powerup effectiveness

---

#### `level_completed` (Story Mode)
**Trigger:** Player completes a story level  
**Frequency:** Once per level per user  
**Payload:**
```json
{
  "level_id": 13,
  "zone_id": 2,
  "score": 156,
  "stars": 3,
  "time_seconds": 45,
  "hearts_remaining": 2,
  "first_attempt": false
}
```

**Backend Processing:**
```javascript
// 1. Track level completion
UPDATE analytics_levels
SET 
  completions = completions + 1,
  avg_time_seconds = (avg_time_seconds * completions + ?) / (completions + 1),
  three_star_count = three_star_count + (stars == 3 ? 1 : 0)
WHERE level_id = ?;

// 2. Progression funnel
UPDATE progression_funnel
SET player_count = player_count + 1
WHERE level_id = ?;

// 3. Difficulty analysis
IF (first_attempt) {
  UPDATE analytics_levels
  SET first_attempt_completions = first_attempt_completions + 1
  WHERE level_id = ?;
}
```

**Analytics Purpose:**
- Level difficulty analysis
- Progression funnel (where players drop off)
- Average completion time
- First-attempt success rate
- Level replay behavior

---

### 3. MONETIZATION EVENTS

#### `purchase_initiated`
**Trigger:** User taps purchase button  
**Frequency:** Variable  
**Payload:**
```json
{
  "product_id": "coins_pack_large",
  "product_type": "consumable",
  "price_usd": 4.99,
  "currency": "USD"
}
```

**Backend Processing:**
```javascript
// 1. Track purchase funnel
INSERT INTO purchase_funnel (user_id, product_id, stage, timestamp)
VALUES (?, ?, 'initiated', NOW());

// 2. Analytics
UPDATE analytics_daily
SET purchase_attempts = purchase_attempts + 1
WHERE date = CURRENT_DATE;
```

**Analytics Purpose:**
- Purchase funnel conversion
- Product popularity
- Price point analysis

---

#### `purchase_completed`
**Trigger:** IAP purchase successful  
**Frequency:** Variable  
**Priority:** **MEDIUM (P2)**  
**Payload:**
```json
{
  "product_id": "coins_pack_large",
  "product_type": "consumable",
  "price_usd": 4.99,
  "currency": "USD",
  "transaction_id": "txn_xxx",
  "store": "google_play",
  "receipt": "[encrypted]"
}
```

**Backend Processing:**
```javascript
// 1. Record purchase
INSERT INTO purchases (
  user_id, product_id, price_usd, currency,
  transaction_id, store, receipt, timestamp
) VALUES (?, ?, ?, ?, ?, ?, ?, NOW());

// 2. Update user LTV
UPDATE users
SET 
  total_revenue = total_revenue + ?,
  purchase_count = purchase_count + 1,
  last_purchase_at = NOW()
WHERE user_id = ?;

// 3. Revenue analytics
UPDATE analytics_daily
SET 
  revenue = revenue + ?,
  purchases = purchases + 1,
  paying_users = paying_users + (is_first_purchase ? 1 : 0)
WHERE date = CURRENT_DATE;

// 4. Cohort revenue
UPDATE cohort_revenue
SET total_revenue = total_revenue + ?
WHERE cohort_date = (SELECT DATE(created_at) FROM users WHERE user_id = ?);
```

**Analytics Purpose:**
- **Revenue tracking**
- LTV (Lifetime Value) calculation
- ARPU (Average Revenue Per User)
- Conversion rate (free → paying)
- Product performance
- Cohort analysis

---

#### `ad_watched`
**Trigger:** User completes rewarded ad  
**Frequency:** Multiple per session  
**Payload:**
```json
{
  "ad_network": "unity",
  "ad_type": "rewarded_video",
  "reward_type": "extra_life",
  "reward_amount": 1,
  "duration_seconds": 30
}
```

**Backend Processing:**
```javascript
// 1. Track ad impressions
INSERT INTO ad_impressions (user_id, ad_network, ad_type, timestamp)
VALUES (?, ?, ?, NOW());

// 2. Analytics
UPDATE analytics_daily
SET 
  ad_impressions = ad_impressions + 1,
  ad_revenue = ad_revenue + 0.05  -- Estimated eCPM
WHERE date = CURRENT_DATE;

// 3. User ad engagement
UPDATE users
SET 
  ad_watch_count = ad_watch_count + 1,
  last_ad_watch = NOW()
WHERE user_id = ?;
```

**Analytics Purpose:**
- Ad revenue estimation
- Ad network performance
- User ad engagement
- Reward effectiveness

---

### 4. SOCIAL EVENTS

#### `leaderboard_viewed`
**Trigger:** User opens leaderboard  
**Frequency:** Multiple per session  
**Payload:**
```json
{
  "leaderboard_type": "global",
  "user_rank": 42,
  "user_score": 156
}
```

**Backend Processing:**
```javascript
// 1. Track engagement
UPDATE analytics_daily
SET leaderboard_views = leaderboard_views + 1
WHERE date = CURRENT_DATE;

// 2. Feature usage
INSERT INTO feature_usage (user_id, feature, timestamp)
VALUES (?, 'leaderboard', NOW());
```

**Analytics Purpose:**
- Feature engagement
- Leaderboard effectiveness
- Rank distribution of viewers

---

### 5. PROGRESSION EVENTS

#### `achievement_unlocked`
**Trigger:** User unlocks achievement  
**Frequency:** Variable  
**Payload:**
```json
{
  "achievement_id": "first_flight",
  "achievement_name": "First Flight",
  "achievement_tier": "bronze",
  "timestamp": "2025-11-09T14:30:00Z"
}
```

**Backend Processing:**
```javascript
// 1. Track achievement unlocks
INSERT INTO achievement_unlocks (user_id, achievement_id, timestamp)
VALUES (?, ?, NOW());

// 2. Analytics
UPDATE analytics_achievements
SET unlock_count = unlock_count + 1
WHERE achievement_id = ?;

// 3. Rarity calculation
UPDATE achievements
SET unlock_percentage = (
  SELECT COUNT(DISTINCT user_id) * 100.0 / (SELECT COUNT(*) FROM users)
  FROM achievement_unlocks
  WHERE achievement_id = ?
)
WHERE achievement_id = ?;
```

**Analytics Purpose:**
- Achievement completion rates
- Player progression tracking
- Engagement milestones

---

#### `mission_completed`
**Trigger:** User completes daily mission  
**Frequency:** Multiple per day  
**Payload:**
```json
{
  "mission_id": "daily_score_1000",
  "mission_type": "daily",
  "reward_coins": 100,
  "reward_gems": 5,
  "completion_time_seconds": 3600
}
```

**Backend Processing:**
```javascript
// 1. Track mission completions
INSERT INTO mission_completions (user_id, mission_id, timestamp)
VALUES (?, ?, NOW());

// 2. Mission analytics
UPDATE analytics_missions
SET 
  completion_count = completion_count + 1,
  avg_completion_time = (avg_completion_time * completion_count + ?) / (completion_count + 1)
WHERE mission_id = ?;

// 3. Daily mission engagement
UPDATE analytics_daily
SET daily_mission_completions = daily_mission_completions + 1
WHERE date = CURRENT_DATE;
```

**Analytics Purpose:**
- Mission difficulty analysis
- Daily engagement tracking
- Mission popularity

---

### 6. UI/UX EVENTS

#### `screen_viewed`
**Trigger:** User navigates to screen  
**Frequency:** Multiple per session  
**Priority:** **LOW (P3)**  
**Payload:**
```json
{
  "screen_name": "store",
  "previous_screen": "homepage",
  "duration_seconds": 45
}
```

**Backend Processing:**
```javascript
// 1. Track screen views
UPDATE analytics_screens
SET view_count = view_count + 1
WHERE screen_name = ? AND date = CURRENT_DATE;

// 2. User flow analysis
INSERT INTO user_flow (user_id, from_screen, to_screen, timestamp)
VALUES (?, ?, ?, NOW());
```

**Analytics Purpose:**
- Screen popularity
- User navigation patterns
- Feature discovery

---

### 7. SYSTEM EVENTS

#### `error_occurred`
**Trigger:** App crash or error  
**Frequency:** Rare (hopefully!)  
**Priority:** **HIGH (P1)** - For stability  
**Payload:**
```json
{
  "error_type": "crash",
  "error_message": "IndexOutOfBoundsException",
  "stack_trace": "[truncated]",
  "app_version": "2.0.3",
  "platform": "android",
  "os_version": "Android 13"
}
```

**Backend Processing:**
```javascript
// 1. Log error
INSERT INTO error_logs (
  user_id, error_type, error_message, 
  stack_trace, app_version, platform, timestamp
) VALUES (?, ?, ?, ?, ?, ?, NOW());

// 2. Error rate tracking
UPDATE analytics_errors
SET error_count = error_count + 1
WHERE error_type = ? AND date = CURRENT_DATE;

// 3. Alerting (if critical)
IF (error_type == 'crash') {
  checkCrashRateAlert();
}
```

**Analytics Purpose:**
- App stability monitoring
- Crash rate tracking
- Bug prioritization
- Version-specific issues

---

## 🗄️ Database Schema

### PostgreSQL Tables

#### `users`
```sql
CREATE TABLE users (
  user_id VARCHAR(100) PRIMARY KEY,
  platform VARCHAR(20),              -- 'android' | 'ios'
  device_model VARCHAR(100),
  os_version VARCHAR(50),
  app_version VARCHAR(20),
  country VARCHAR(2),                -- ISO country code
  timezone VARCHAR(50),
  install_source VARCHAR(50),        -- 'organic' | 'facebook' | etc
  
  -- Stats
  session_count INT DEFAULT 0,
  high_score INT DEFAULT 0,
  total_revenue DECIMAL(10,2) DEFAULT 0,
  purchase_count INT DEFAULT 0,
  ad_watch_count INT DEFAULT 0,
  
  -- Timestamps
  created_at TIMESTAMP DEFAULT NOW(),
  first_seen_at TIMESTAMP,
  last_seen_at TIMESTAMP,
  last_purchase_at TIMESTAMP,
  
  -- Indexes
  INDEX idx_country (country),
  INDEX idx_last_seen (last_seen_at),
  INDEX idx_high_score (high_score DESC)
);
```

#### `events` (Raw Event Storage)
```sql
CREATE TABLE events (
  id BIGSERIAL PRIMARY KEY,
  user_id VARCHAR(100) NOT NULL,
  session_id VARCHAR(100),
  event_name VARCHAR(100) NOT NULL,
  payload JSONB,
  client_timestamp TIMESTAMP,
  server_timestamp TIMESTAMP DEFAULT NOW(),
  processed BOOLEAN DEFAULT FALSE,
  
  INDEX idx_user_events (user_id, server_timestamp DESC),
  INDEX idx_event_name (event_name),
  INDEX idx_processed (processed, server_timestamp)
);

-- Partition by month for performance
CREATE TABLE events_2025_11 PARTITION OF events
FOR VALUES FROM ('2025-11-01') TO ('2025-12-01');
```

#### `leaderboard` (Global Rankings)
```sql
CREATE TABLE leaderboard (
  user_id VARCHAR(100) PRIMARY KEY,
  nickname VARCHAR(50),
  high_score INT NOT NULL DEFAULT 0,
  updated_at TIMESTAMP DEFAULT NOW(),
  
  INDEX idx_high_score (high_score DESC),
  INDEX idx_updated (updated_at DESC)
);
```

#### `tournaments`
```sql
CREATE TABLE tournaments (
  tournament_id VARCHAR(100) PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  start_date TIMESTAMP NOT NULL,
  end_date TIMESTAMP NOT NULL,
  status VARCHAR(20) DEFAULT 'pending',  -- 'pending' | 'active' | 'ended' | 'prizes_distributed'
  prize_config JSONB,                    -- Prize structure
  participant_count INT DEFAULT 0,
  
  INDEX idx_dates (start_date, end_date),
  INDEX idx_status (status)
);
```

#### `tournament_entries`
```sql
CREATE TABLE tournament_entries (
  tournament_id VARCHAR(100),
  user_id VARCHAR(100),
  nickname VARCHAR(50),
  score INT NOT NULL,
  timestamp TIMESTAMP DEFAULT NOW(),
  
  PRIMARY KEY (tournament_id, user_id),
  FOREIGN KEY (tournament_id) REFERENCES tournaments(tournament_id),
  
  INDEX idx_tournament_score (tournament_id, score DESC)
);
```

#### `prizes`
```sql
CREATE TABLE prizes (
  prize_id VARCHAR(100) PRIMARY KEY,
  tournament_id VARCHAR(100),
  user_id VARCHAR(100) NOT NULL,
  rank INT NOT NULL,
  coins INT DEFAULT 0,
  gems INT DEFAULT 0,
  awarded_at TIMESTAMP DEFAULT NOW(),
  claimed_at TIMESTAMP,
  
  FOREIGN KEY (tournament_id) REFERENCES tournaments(tournament_id),
  
  INDEX idx_user_unclaimed (user_id, claimed_at) WHERE claimed_at IS NULL,
  INDEX idx_tournament (tournament_id)
);
```

#### `analytics_daily` (Aggregated Metrics)
```sql
CREATE TABLE analytics_daily (
  date DATE PRIMARY KEY,
  platform VARCHAR(20),
  
  -- User metrics
  new_installs INT DEFAULT 0,
  dau INT DEFAULT 0,                    -- Daily Active Users
  returning_users INT DEFAULT 0,
  
  -- Game metrics
  games_started INT DEFAULT 0,
  games_completed INT DEFAULT 0,
  total_score BIGINT DEFAULT 0,
  avg_score INT DEFAULT 0,
  total_playtime_seconds BIGINT DEFAULT 0,
  
  -- Monetization
  revenue DECIMAL(10,2) DEFAULT 0,
  purchases INT DEFAULT 0,
  paying_users INT DEFAULT 0,
  ad_impressions INT DEFAULT 0,
  ad_revenue DECIMAL(10,2) DEFAULT 0,
  
  -- Engagement
  leaderboard_views INT DEFAULT 0,
  daily_mission_completions INT DEFAULT 0,
  
  -- System
  error_count INT DEFAULT 0,
  
  UNIQUE(date, platform)
);
```

---

## 📈 Analytics & Metrics

### Key Performance Indicators (KPIs)

#### User Acquisition
- **Daily Installs:** Count of `user_installed` events
- **Install Source:** Breakdown by `install_source`
- **Geographic Distribution:** User count by `country`

#### Engagement
- **DAU (Daily Active Users):** Unique users with `app_launched` today
- **MAU (Monthly Active Users):** Unique users with `app_launched` in last 30 days
- **DAU/MAU Ratio:** Stickiness metric (target: >20%)
- **Session Frequency:** Average sessions per DAU
- **Session Length:** Average `duration_seconds` from `game_ended`

#### Retention
- **Day 1 Retention:** % users who returned next day
- **Day 7 Retention:** % users who returned after 7 days
- **Day 30 Retention:** % users who returned after 30 days

#### Monetization
- **ARPU (Average Revenue Per User):** Total revenue / Total users
- **ARPPU (Average Revenue Per Paying User):** Total revenue / Paying users
- **Conversion Rate:** Paying users / Total users
- **LTV (Lifetime Value):** Predicted revenue per user

#### Game Balance
- **Score Distribution:** Histogram of scores from `game_ended`
- **Level Difficulty:** Completion rate per level
- **Death Causes:** Breakdown of `cause_of_death`
- **Powerup Usage:** Which powerups are most effective

#### Social
- **Leaderboard Engagement:** % users who viewed leaderboard
- **Tournament Participation:** % eligible users who played in tournament

---

## ⏰ Background Jobs

### 1. Tournament Reset (Weekly)
**Schedule:** Sunday 00:00 UTC  
**Purpose:** End current tournament, start new one, calculate prizes

**Steps:**
```javascript
// 1. End current tournament
UPDATE tournaments
SET status = 'ended'
WHERE status = 'active' AND end_date <= NOW();

// 2. Calculate final rankings
SELECT user_id, nickname, score, ROW_NUMBER() OVER (ORDER BY score DESC) as rank
FROM tournament_entries
WHERE tournament_id = ?
ORDER BY score DESC;

// 3. Distribute prizes
const prizeConfig = {
  1: {coins: 5000, gems: 250},
  2: {coins: 3000, gems: 150},
  3: {coins: 2000, gems: 100},
  // ...
};

for (const entry of rankings) {
  const prize = getPrizeForRank(entry.rank, prizeConfig);
  if (prize) {
    INSERT INTO prizes (
      prize_id, tournament_id, user_id, rank, coins, gems, awarded_at
    ) VALUES (
      CONCAT('prize_', tournament_id, '_', user_id),
      tournament_id,
      user_id,
      entry.rank,
      prize.coins,
      prize.gems,
      NOW()
    );
  }
}

// 4. Mark tournament prizes distributed
UPDATE tournaments
SET status = 'prizes_distributed'
WHERE tournament_id = ?;

// 5. Create new tournament
INSERT INTO tournaments (
  tournament_id, name, start_date, end_date, status, prize_config
) VALUES (
  CONCAT('tournament_', YEAR(NOW()), '_w', WEEK(NOW())),
  'Weekly Championship',
  NOW(),
  NOW() + INTERVAL '7 days',
  'active',
  ?
);
```

---

### 2. Analytics Aggregation (Hourly)
**Schedule:** Every hour  
**Purpose:** Aggregate raw events into analytics tables

**Steps:**
```javascript
// Process events from last hour
const events = await db.query(`
  SELECT * FROM events 
  WHERE processed = false 
  AND server_timestamp >= NOW() - INTERVAL '1 hour'
`);

// Aggregate by event type
for (const event of events) {
  switch(event.event_name) {
    case 'game_ended':
      await updateGameAnalytics(event);
      break;
    case 'purchase_completed':
      await updateRevenueAnalytics(event);
      break;
    // ...
  }
}

// Mark as processed
await db.query(`
  UPDATE events 
  SET processed = true 
  WHERE id IN (?)
`, eventIds);
```

---

### 3. Leaderboard Cache Refresh (Every 5 minutes)
**Schedule:** */5 * * * *  
**Purpose:** Update cached global leaderboard

**Steps:**
```javascript
// Recalculate top 100
const top100 = await db.query(`
  SELECT user_id, nickname, high_score, updated_at
  FROM leaderboard
  ORDER BY high_score DESC
  LIMIT 100
`);

// Cache in Redis (or in-memory)
await cache.set('leaderboard:global:top100', JSON.stringify(top100), {
  EX: 300  // Expire in 5 minutes
});
```

---

## 🔄 Migration Strategy

### For Existing Users (No Data Migration Needed!)

**Your Requirement:** "I don't care about old users, no need to migrate old data, but I also don't want to break nothing for current users"

**Strategy: Graceful Degradation**

#### Backend Approach:
```javascript
// Old endpoint (keep for backward compatibility)
app.post('/api/score/submit', async (req, res) => {
  // Accept old format but don't process
  res.status(200).json({
    success: true,
    message: 'Score recorded'
  });
  
  // Silently ignore (or log for monitoring)
  // Old users will think it worked, but we don't save
});

// New endpoint (event-driven)
app.post('/api/events/batch', async (req, res) => {
  // New event-driven approach
  const events = req.body.events;
  await queueEvents(events);
  
  res.status(200).json({
    success: true,
    received: events.length
  });
});
```

#### What Happens to Old Users:
1. **Old app versions** (pre-2.0.3) will continue to work
2. Their API calls succeed (200 OK) but aren't processed
3. Their local data remains intact
4. When they update to new version, they start fresh
5. **No migration needed** - they just start with new system

#### New Users:
- Get the new event-driven architecture from day 1
- Full analytics and features
- Everything works perfectly

#### Timeline:
- **Week 1-2:** Deploy new backend alongside old
- **Week 3-4:** Monitor old endpoint usage (should decline)
- **Week 5+:** Old endpoints can be removed (usage < 1%)

---

## 🚀 Implementation Priority

### Phase 1: Core Event System (Week 1)
- ✅ Event ingestion endpoint
- ✅ Event queue (in-memory)
- ✅ Basic event processing
- ✅ Database schema
- ✅ `game_ended` processing (leaderboard updates)

### Phase 2: Tournament System (Week 2)
- ✅ Tournament endpoints
- ✅ Tournament entries processing
- ✅ Prize calculation job
- ✅ Prize distribution endpoint

### Phase 3: Analytics (Week 3)
- ✅ Analytics aggregation jobs
- ✅ Analytics dashboard (internal)
- ✅ Key metrics tracking

### Phase 4: Polish & Monitoring (Week 4)
- ✅ Error handling
- ✅ Rate limiting
- ✅ Monitoring/alerting
- ✅ Load testing

---

## 📝 API Response Standards

### Success Response
```json
{
  "success": true,
  "data": {},
  "timestamp": "2025-11-09T14:30:00Z"
}
```

### Error Response
```json
{
  "success": false,
  "error": {
    "code": "INVALID_EVENT_SCHEMA",
    "message": "Event 'game_ended' missing required field 'score'",
    "details": {}
  },
  "timestamp": "2025-11-09T14:30:00Z"
}
```

### Rate Limit Headers
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 87
X-RateLimit-Reset: 1699545600
```

---

## 🔐 Security Considerations

### 1. Data Validation
- Validate all event schemas
- Sanitize user inputs
- Check data types and ranges

### 2. Rate Limiting
- 100 requests/minute per user_id
- Exponential backoff for violations
- IP-based rate limiting as backup

### 3. Anti-Cheating
- Score validation (outlier detection)
- Timestamp validation (client vs server)
- Duplicate event detection

### 4. Privacy
- No PII stored (except user_id)
- GDPR compliant (user data deletion endpoint)
- Data retention policy (events > 90 days archived)

---

## 📊 Monitoring & Alerting

### Key Metrics to Monitor
- **Event ingestion rate** (events/second)
- **Processing latency** (P50, P95, P99)
- **Error rate** (errors/total events)
- **Database query time**
- **API response time**

### Alerts
| Alert | Threshold | Severity |
|-------|-----------|----------|
| Event processing lag | > 10 seconds | High |
| Error rate | > 5% | Critical |
| API response time | > 500ms | Medium |
| Database CPU | > 80% | High |
| Disk space | > 90% | Critical |

---

## ✅ Testing Strategy

### 1. Unit Tests
- Event schema validation
- Event processing logic
- Prize calculation
- Leaderboard updates

### 2. Integration Tests
- End-to-end event flow
- Tournament lifecycle
- Prize distribution
- API endpoints

### 3. Load Tests
- 1,000 events/second sustained
- 10,000 concurrent users
- Tournament with 100,000 participants

---

## 📚 References

- [Flutter Event Schema](EVENT_SCHEMA.md)
- [Architecture Overview](CLIENT_ONLY_WITH_EVENT_DRIVEN_ANALYTICS.md)
- [Implementation Plan](HYBRID_ARCHITECTURE_IMPLEMENTATION_PLAN.md)

---

**Last Updated:** November 9, 2025  
**Status:** Ready for implementation 🚀

