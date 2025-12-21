# 📊 Analytics & Backend Data Dashboard Review
## Comprehensive Analysis for Gaming Industry Standards

**Date**: January 2025  
**Version**: 2.3.13  
**Status**: Analysis & Recommendations (No Code Changes)

---

## 📋 EXECUTIVE SUMMARY

This document provides a comprehensive review of:
- ✅ Events currently being fired (EventBus + Firebase)
- ✅ Data being collected and analyzed
- ✅ Schema consistency and mismatches
- ❌ Missing critical events
- 🎯 Recommendations aligned with top gaming industry standards

---

## 🔍 PART 1: CURRENT EVENT INVENTORY

### 1.1 EventBus Events (Backend → Railway `/api/events`)

#### **Core Gameplay Events**
| Event Name | Parameters | Status | Notes |
|------------|-----------|--------|-------|
| `game_started` | `game_mode`, `selected_jet`, `selected_skin`, `hearts_remaining`, `powerups_active` | ✅ | Fired in endless mode |
| `game_ended` | `game_mode`, `score`, `duration_seconds`, `obstacles_dodged`, `coins_collected`, `gems_collected`, `hearts_remaining`, `cause_of_death`, `max_combo`, `powerups_used`, `level_id` (story), `zone_id` (story) | ✅ | Comprehensive |
| `level_started` | `level_id`, `zone_id`, `level_name` | ✅ | Story mode only |
| `level_completed` | `level_id`, `zone_id`, `score`, `time_taken`, `coins_earned` | ✅ | Story mode |
| `level_failed` | `level_id`, `zone_id`, `score`, `attempts` | ✅ | Story mode |
| `bonus_collected` | `bonus_type`, `value`, `position_x`, `position_y` | ✅ | In-game bonuses |

#### **Tournament Events**
| Event Name | Parameters | Status | Notes |
|------------|-----------|--------|-------|
| `tournament_level_started` | `tournament_id`, `level_id`, `round` | ✅ | Linear tournaments |
| `tournament_level_completed` | `tournament_id`, `level_id`, `score`, `time_taken`, `round` | ✅ | Linear tournaments |
| `tournament_round_started` | `tournament_id`, `round` | ✅ | Playoff tournaments |
| `playoff_battle_started` | `tournament_id`, `opponent_id`, `round` | ✅ | Playoff battles |
| `playoff_battle_won` | `tournament_id`, `opponent_id`, `score`, `round` | ✅ | Playoff battles |
| `playoff_battle_lost` | `tournament_id`, `opponent_id`, `score`, `round` | ✅ | Playoff battles |
| `tournament_start_over` | `tournament_id`, `reason` | ✅ | User restarts |

#### **Monetization Events**
| Event Name | Parameters | Status | Notes |
|------------|-----------|--------|-------|
| `skin_purchased` | `jet_id`, `jet_name`, `purchase_type`, `cost_coins`, `cost_gems`, `rarity` | ✅ | Coin/gem purchases |
| `special_offer_purchased` | `offer_id`, `product_id`, `price_usd`, `skins_unlocked[]`, `skin_equipped` | ✅ | Christmas & Boss Pack |
| `no_ads_purchased` | `product_type`, `price_usd`, `timestamp` | ✅ | Lifetime/monthly |
| `currency_bundle_purchased` | `bundle_id`, `gems`, `coins`, `price_usd`, `timestamp` | ✅ | Currency bundles |
| `bundle_purchased` | `bundle_id`, `bundle_type`, `price_usd` | ✅ | Generic bundles |
| `ad_revenue` | `ad_type`, `ad_format`, `revenue_micros`, `revenue_usd`, `currency`, `precision`, `is_real_revenue` | ✅ | Real ad revenue |
| `interstitial_shown` | `context`, `ad_unit_id`, `placement` | ✅ | Ad impressions |
| `interstitial_dismissed` | `context`, `ad_unit_id` | ✅ | Ad dismissals |
| `interstitial_clicked` | `context`, `ad_unit_id` | ✅ | Ad clicks |
| `loss_streak_ad_shown` | `streak_count`, `ad_unit_id` | ✅ | Loss streak ads |
| `tournament_interstitial_shown` | `tournament_id`, `placement` | ✅ | Tournament ads |
| `tournament_interstitial_cooldown` | `tournament_id`, `cooldown_seconds` | ✅ | Ad cooldown |

#### **Progression & Engagement Events**
| Event Name | Parameters | Status | Notes |
|------------|-----------|--------|-------|
| `achievement_unlocked` | `achievement_id`, `category`, `rarity`, `reward_coins`, `reward_gems` | ✅ | Achievement system |
| `achievement_claimed` | `achievement_id`, `reward_coins`, `reward_gems` | ✅ | Claimed rewards |
| `mission_unlocked` | `mission_id`, `mission_type` | ✅ | Mission system |
| `mission_completed` | `mission_id`, `mission_type`, `reward_coins`, `reward_gems` | ✅ | Mission completion |
| `item_unlocked` | `item_type`, `item_id`, `acquisition_method` | ✅ | Generic unlocks |
| `item_equipped` | `item_type`, `item_id` | ✅ | Equipment changes |
| `currency_earned` | `currency_type`, `amount`, `source`, `source_id`, `balance_before`, `balance_after` | ✅ | Coins/gems earned |
| `currency_spent` | `currency_type`, `amount`, `spent_on`, `item_id`, `balance_before`, `balance_after` | ✅ | Coins/gems spent |
| `powerup_activated` | `powerup_type`, `duration_seconds` | ✅ | Powerup usage |
| `powerup_expired` | `powerup_type` | ✅ | Powerup expiry |
| `continue_used` | `gems_cost`, `current_score`, `context` | ✅ | Continue purchases |
| `daily_streak_claimed` | `streak_days`, `reward_type`, `reward_value` | ✅ | Daily rewards |
| `daily_streak_cycle_completed` | `cycle_number`, `total_days` | ✅ | Streak cycles |
| `daily_streak_milestone` | `milestone_days`, `reward_type` | ✅ | Milestone rewards |
| `daily_streak_broken` | `previous_streak_days`, `reason` | ✅ | Streak breaks |

#### **User Identity & Social Events**
| Event Name | Parameters | Status | Notes |
|------------|-----------|--------|-------|
| `user_installed` | Device metadata | ✅ | First install |
| `app_launched` | `session_count`, `timestamp` | ✅ | App opens |
| `nickname_changed` | `new_nickname_length`, `timestamp` | ✅ | Profile updates |
| `rate_us_initialized` | `session_count`, `has_rated`, `declined` | ✅ | Rate us system |
| `rate_us_popup_shown` | `session_count`, `trigger` | ✅ | Rate popup shown |
| `rate_us_rate_tapped` | `rating`, `session_count` | ✅ | User rates |
| `rate_us_prompt_shown` | `platform` | ✅ | Native prompt |
| `rate_us_store_opened` | `platform`, `session_count` | ✅ | Store opened |
| `rate_us_maybe_later` | `session_count` | ✅ | User defers |
| `rate_us_declined` | `session_count` | ✅ | User declines |
| `rate_us_completed` | `rating`, `platform`, `session_count` | ✅ | Rating completed |

#### **Conversion Events (Google Ads)**
| Event Name | Parameters | Status | Notes |
|------------|-----------|--------|-------|
| `conversion_games_played_3` | `games_played`, `timestamp` | ✅ | Google Ads conversion |
| `conversion_games_played_5` | `games_played`, `timestamp` | ✅ | Google Ads conversion |
| `conversion_games_played_10` | `games_played`, `timestamp` | ✅ | Google Ads conversion |
| `conversion_sessions_3` | `sessions`, `timestamp` | ✅ | Google Ads conversion |
| `conversion_sessions_6` | `sessions`, `timestamp` | ✅ | Google Ads conversion |
| `conversion_level_completed_3` | `level`, `timestamp` | ✅ | Google Ads conversion |
| `conversion_level_completed_5` | `level`, `timestamp` | ✅ | Google Ads conversion |
| `conversion_level_completed_10` | `level`, `timestamp` | ✅ | Google Ads conversion |

---

### 1.2 Firebase Analytics Events (Firebase → Google Analytics)

#### **Gameplay Events**
- `game_start` - Via UnifiedAnalyticsManager
- `game_end` - Via UnifiedAnalyticsManager
- `level_up` - Via UnifiedAnalyticsManager

#### **Monetization Events**
- `purchase` - Generic purchase event
- `iap_purchase_attempt` - Purchase attempts
- `iap_purchase_failed` - Failed purchases
- `iap_unavailable` - IAP not available

#### **Engagement Events**
- `user_engagement` - Session tracking
- `app_launch` - App lifecycle
- `app_inactive` - App lifecycle
- `app_hidden` - App lifecycle
- `feature_usage` - Feature tracking
- `social_share` - Social sharing
- `app_rating` - Rating tracking

#### **Progression Events**
- `mission_complete` - Mission completion
- `achievement_unlock` - Achievement unlocks
- `tournament_event` - Tournament actions

#### **Ad Events**
- `ad_event` - Generic ad events
- `ad_revenue` - Ad revenue tracking

#### **Error Events**
- `app_error` - Error tracking
- `performance_metric` - Performance tracking

---

## ⚠️ PART 2: CRITICAL ISSUES & SCHEMA MISMATCHES

### 2.1 Schema Mismatches

#### **Issue #1: Event Name Inconsistency**
- **EventBus**: Uses `game_started` (past tense)
- **Firebase**: Uses `game_start` (present tense)
- **Impact**: Backend and Firebase have different event names for same action
- **Recommendation**: Standardize on one naming convention (prefer `game_start` for consistency)

#### **Issue #2: Parameter Name Inconsistencies**
- **EventBus `game_ended`**: Uses `duration_seconds`
- **Firebase `game_end`**: Uses `survival_time_seconds`
- **Impact**: Same metric, different parameter names
- **Recommendation**: Use consistent parameter names across both systems

#### **Issue #3: Missing Purchase Details**
- **EventBus `special_offer_purchased`**: Missing `purchase_token`, `platform`, `transaction_id`
- **EventBus `skin_purchased`**: Missing `transaction_id` for IAP purchases
- **Impact**: Cannot validate purchases or handle refunds
- **Recommendation**: Add purchase validation fields

#### **Issue #4: Incomplete Ad Revenue Data**
- **Current**: Tracks `revenue_usd`, `revenue_micros`, `currency`
- **Missing**: `ad_network`, `ad_unit_id`, `placement_id`, `mediation_network`
- **Impact**: Cannot analyze which ad networks/placements perform best
- **Recommendation**: Add ad network and placement tracking

#### **Issue #5: Tournament Event Gaps**
- **Missing**: `tournament_entry_created`, `tournament_leaderboard_viewed`, `tournament_reward_claimed`
- **Impact**: Cannot track full tournament funnel
- **Recommendation**: Add missing tournament lifecycle events

---

### 2.2 Missing Critical Events (Gaming Industry Standards)

#### **🎮 Gameplay Events Missing**
1. **`game_paused`** - When user pauses game
2. **`game_resumed`** - When user resumes game
3. **`obstacle_hit`** - When player hits obstacle (for difficulty tuning)
4. **`shield_activated`** - When shield powerup is used
5. **`shield_deactivated`** - When shield expires or is consumed
6. **`combo_achieved`** - When player achieves combo (currently tracked but not fired)
7. **`high_score_achieved`** - When new personal best is set
8. **`level_retry`** - When user retries a failed level
9. **`level_skipped`** - If level skipping is implemented
10. **`boss_defeated`** - When boss is defeated (story mode)

#### **💰 Monetization Events Missing**
1. **`store_opened`** - When user opens store
2. **`store_item_viewed`** - When user views specific item
3. **`store_item_dismissed`** - When user closes item view
4. **`purchase_intent`** - When user taps purchase button (before IAP flow)
5. **`purchase_cancelled`** - When user cancels IAP flow
6. **`purchase_restored`** - When user restores previous purchases
7. **`special_offer_viewed`** - When special offer popup is shown
8. **`special_offer_dismissed`** - When user dismisses special offer
9. **`insufficient_currency_shown`** - When insufficient currency popup appears
10. **`currency_source_viewed`** - When user views "get more gems" screen
11. **`iap_product_loaded`** - When IAP products are successfully loaded
12. **`iap_product_failed`** - When IAP products fail to load

#### **📊 User Engagement Events Missing**
1. **`screen_viewed`** - Track all screen views (home, store, profile, tournaments, etc.)
2. **`screen_time`** - Time spent on each screen
3. **`button_clicked`** - Track important button clicks (with context)
4. **`tutorial_started`** - When tutorial begins
5. **`tutorial_completed`** - When tutorial finishes
6. **`tutorial_skipped`** - When tutorial is skipped
7. **`notification_received`** - When push notification is received
8. **`notification_opened`** - When user opens app from notification
9. **`deep_link_opened`** - When app opens from deep link
10. **`social_share_attempted`** - When user attempts to share
11. **`social_share_completed`** - When share is successful

#### **🏆 Progression Events Missing**
1. **`zone_unlocked`** - When new zone is unlocked
2. **`zone_completed`** - When all levels in zone are completed
3. **`skin_collection_viewed`** - When user views skin collection
4. **`skin_previewed`** - When user previews a skin before purchase
5. **`leaderboard_viewed`** - When user views leaderboard
6. **`leaderboard_refreshed`** - When user refreshes leaderboard
7. **`achievement_list_viewed`** - When user views achievements
8. **`mission_list_viewed`** - When user views missions

#### **🎯 Tournament Events Missing**
1. **`tournament_entry_created`** - When user enters tournament
2. **`tournament_info_viewed`** - When user views tournament details
3. **`tournament_leaderboard_viewed`** - When user views tournament leaderboard
4. **`tournament_reward_claimed`** - When user claims tournament reward
5. **`tournament_bracket_viewed`** - When user views playoff bracket
6. **`tournament_match_viewed`** - When user views specific match

#### **📱 App Lifecycle Events Missing**
1. **`app_foregrounded`** - When app comes to foreground
2. **`app_backgrounded`** - When app goes to background
3. **`session_start`** - Explicit session start (separate from app_launch)
4. **`session_end`** - Explicit session end with duration
5. **`crash_detected`** - When crash is detected (if using crash reporting)
6. **`performance_degraded`** - When FPS drops below threshold

#### **🔔 Notification Events Missing**
1. **`notification_permission_requested`** - When permission is requested
2. **`notification_permission_granted`** - When permission is granted
3. **`notification_permission_denied`** - When permission is denied
4. **`notification_scheduled`** - When notification is scheduled
5. **`notification_delivered`** - When notification is delivered (backend)

---

## 🎯 PART 3: GAMING INDUSTRY STANDARDS COMPARISON

### 3.1 Industry Standard Event Categories

#### **✅ Well Covered**
- ✅ Core gameplay events (start, end, level progression)
- ✅ Monetization events (purchases, ad revenue)
- ✅ Progression events (achievements, missions)
- ✅ User engagement (sessions, app lifecycle)

#### **⚠️ Partially Covered**
- ⚠️ Tournament events (missing entry/leaderboard/reward events)
- ⚠️ Store events (missing view/dismiss/intent events)
- ⚠️ Social events (missing share completion tracking)

#### **❌ Missing Critical Categories**
- ❌ **Funnel Analysis**: No screen_viewed events for funnel tracking
- ❌ **Retention Metrics**: Missing session quality indicators
- ❌ **Churn Indicators**: Missing inactivity/abandonment events
- ❌ **A/B Testing**: No experiment/variant tracking
- ❌ **Error Tracking**: Basic error tracking but missing context
- ❌ **Performance Monitoring**: Missing FPS, load times, memory usage

---

## 📈 PART 4: DATA COLLECTION ANALYSIS

### 4.1 Currently Collected Data

#### **User Identity**
- ✅ User ID (device-based)
- ✅ Session ID
- ✅ Platform (iOS/Android)
- ✅ App version
- ✅ Device locale
- ✅ Country (server-side geolocation)

#### **Gameplay Metrics**
- ✅ Score, survival time, coins/gems collected
- ✅ Obstacles dodged, combos
- ✅ Lives remaining, powerups used
- ✅ Cause of death

#### **Monetization Metrics**
- ✅ Purchase amounts, currencies
- ✅ Ad revenue (real and estimated)
- ✅ Purchase types (IAP, coins, gems)

#### **Progression Metrics**
- ✅ Level completion, zone progress
- ✅ Achievement unlocks, mission completions
- ✅ Skin ownership, equipment

### 4.2 Missing Data Points

#### **User Segmentation**
- ❌ Player tier (new, casual, hardcore, whale)
- ❌ Days since install
- ❌ Total playtime (cumulative)
- ❌ Average session duration
- ❌ Play frequency (daily, weekly)

#### **Gameplay Quality**
- ❌ Average score per session
- ❌ Death frequency by obstacle type
- ❌ Powerup usage patterns
- ❌ Difficulty progression tracking

#### **Monetization Quality**
- ❌ Time to first purchase
- ❌ Purchase frequency
- ❌ Average revenue per user (ARPU)
- ❌ Lifetime value (LTV) indicators
- ❌ Conversion funnel drop-off points

#### **Technical Performance**
- ❌ Frame rate (FPS)
- ❌ Load times
- ❌ Memory usage
- ❌ Network latency
- ❌ Crash frequency

---

## 🔧 PART 5: SCHEMA STANDARDIZATION RECOMMENDATIONS

### 5.1 Event Naming Convention

**Current Issues:**
- Mixed past/present tense (`game_started` vs `game_start`)
- Inconsistent prefixes (`tournament_*` vs `playoff_*`)

**Recommendation:**
- Use **present tense** for all events (`game_start`, `game_end`, `purchase_complete`)
- Use **consistent prefixes** (`tournament_*` for all tournament events)
- Use **snake_case** consistently (already doing this ✅)

### 5.2 Parameter Standardization

**Standard Parameters for ALL Events:**
```json
{
  "event_type": "string (required)",
  "user_id": "string (required)",
  "session_id": "string (required)",
  "timestamp": "ISO8601 (required)",
  "app_version": "string (required)",
  "platform": "ios|android (required)",
  "locale": "string (optional)",
  "country": "string (optional, server-side)"
}
```

**Gameplay Event Standard Parameters:**
```json
{
  "game_mode": "endless|story|tournament",
  "score": "integer",
  "duration_seconds": "integer",
  "selected_jet": "string",
  "theme": "string"
}
```

**Purchase Event Standard Parameters:**
```json
{
  "product_id": "string",
  "product_name": "string",
  "price_usd": "float",
  "currency": "string",
  "purchase_type": "iap|coins|gems",
  "transaction_id": "string (for IAP)",
  "purchase_token": "string (for IAP validation)",
  "platform": "ios|android"
}
```

### 5.3 Event Categories

**Recommended Event Categories:**
1. **gameplay_*** - All gameplay events
2. **monetization_*** - All purchase/revenue events
3. **progression_*** - All progression events
4. **engagement_*** - All user engagement events
5. **tournament_*** - All tournament events
6. **technical_*** - All technical/performance events

---

## 🚀 PART 6: PRIORITY RECOMMENDATIONS

### **Priority 1: Critical (Implement Immediately)**
1. ✅ **Standardize event names** - Fix `game_started` vs `game_start`
2. ✅ **Add purchase validation fields** - `transaction_id`, `purchase_token`
3. ✅ **Add screen_viewed events** - Critical for funnel analysis
4. ✅ **Add store funnel events** - `store_opened`, `item_viewed`, `purchase_intent`
5. ✅ **Add tournament entry/reward events** - Complete tournament funnel

### **Priority 2: High Value (Implement Soon)**
1. ✅ **Add session quality metrics** - Session duration, actions per session
2. ✅ **Add churn indicators** - Inactivity tracking, abandonment events
3. ✅ **Add ad network tracking** - Which networks/placements perform best
4. ✅ **Add tutorial tracking** - Track tutorial completion rates
5. ✅ **Add notification engagement** - Track notification effectiveness

### **Priority 3: Nice to Have (Future Enhancements)**
1. ✅ **A/B testing events** - Experiment/variant tracking
2. ✅ **Performance monitoring** - FPS, load times, memory
3. ✅ **Social sharing completion** - Track successful shares
4. ✅ **Deep link tracking** - Track deep link effectiveness
5. ✅ **Player tier classification** - Auto-classify player segments

---

## 📊 PART 7: DASHBOARD METRICS RECOMMENDATIONS

### 7.1 Key Performance Indicators (KPIs)

#### **User Acquisition**
- Daily/Monthly Active Users (DAU/MAU)
- New User Acquisition Rate
- User Retention (D1, D7, D30)
- Churn Rate

#### **Engagement**
- Average Session Duration
- Sessions per User per Day
- Actions per Session
- Screen Views per Session

#### **Monetization**
- Revenue per User (ARPU)
- Conversion Rate (Free → Paid)
- Average Revenue per Paying User (ARPPU)
- Time to First Purchase
- Purchase Frequency
- Lifetime Value (LTV)

#### **Gameplay**
- Average Score
- Average Survival Time
- Level Completion Rate
- Tournament Participation Rate
- Achievement Unlock Rate

#### **Technical**
- Crash Rate
- Average FPS
- Load Time
- Error Rate

### 7.2 Funnel Analysis

**Recommended Funnels:**
1. **Onboarding Funnel**: Install → Tutorial → First Game → First Purchase
2. **Store Funnel**: Store Open → Item View → Purchase Intent → Purchase Complete
3. **Tournament Funnel**: Tournament View → Entry → Gameplay → Reward Claim
4. **Level Progression Funnel**: Level Start → Attempt → Complete/Fail → Retry

---

## 🎮 PART 8: GAMING INDUSTRY BEST PRACTICES

### 8.1 Event Tracking Best Practices

#### **✅ Currently Following**
- ✅ Fire-and-forget architecture (non-blocking)
- ✅ Event queuing for offline scenarios
- ✅ Automatic retry logic
- ✅ Batch sending for efficiency

#### **⚠️ Needs Improvement**
- ⚠️ Event deduplication (prevent duplicate events)
- ⚠️ Event validation (ensure required fields present)
- ⚠️ Event versioning (handle schema changes)
- ⚠️ Event sampling (for high-frequency events)

### 8.2 Data Privacy Compliance

#### **Current Status**
- ✅ User ID is device-based (not PII)
- ✅ No personal information in events
- ✅ Country detection is server-side

#### **Recommendations**
- ✅ Add GDPR/CCPA compliance flags
- ✅ Add user consent tracking
- ✅ Add data deletion events
- ✅ Add privacy settings change events

---

## 📝 PART 9: IMPLEMENTATION CHECKLIST

### Phase 1: Schema Standardization (Week 1)
- [ ] Standardize event names (past → present tense)
- [ ] Standardize parameter names across EventBus and Firebase
- [ ] Add missing purchase validation fields
- [ ] Document event schema in centralized location

### Phase 2: Critical Missing Events (Week 2)
- [ ] Add `screen_viewed` events for all major screens
- [ ] Add store funnel events (`store_opened`, `item_viewed`, `purchase_intent`)
- [ ] Add tournament entry/reward events
- [ ] Add tutorial tracking events

### Phase 3: Enhanced Tracking (Week 3)
- [ ] Add session quality metrics
- [ ] Add churn indicators
- [ ] Add ad network/placement tracking
- [ ] Add notification engagement tracking

### Phase 4: Dashboard Integration (Week 4)
- [ ] Update backend to handle new events
- [ ] Create dashboard views for new metrics
- [ ] Set up alerts for critical KPIs
- [ ] Document dashboard usage

---

## 🔍 PART 10: SPECIFIC FINDINGS

### 10.1 Event Name Mismatches

| EventBus | Firebase | Recommendation |
|----------|----------|----------------|
| `game_started` | `game_start` | Use `game_start` |
| `game_ended` | `game_end` | Use `game_end` |
| `level_started` | `level_start` | Use `level_start` |
| `level_completed` | `level_complete` | Use `level_complete` |

### 10.2 Parameter Name Mismatches

| EventBus Parameter | Firebase Parameter | Recommendation |
|-------------------|-------------------|----------------|
| `duration_seconds` | `survival_time_seconds` | Use `duration_seconds` |
| `selected_jet` | `selected_jet` | ✅ Consistent |
| `cause_of_death` | `cause_of_death` | ✅ Consistent |

### 10.3 Missing Event Parameters

**`special_offer_purchased`:**
- Missing: `purchase_token`, `transaction_id`, `platform`
- Missing: `offer_show_count` (how many times shown before purchase)
- Missing: `time_to_purchase_seconds` (time from offer shown to purchase)

**`ad_revenue`:**
- Missing: `ad_network` (AdMob, Unity, etc.)
- Missing: `ad_unit_id` (specific ad unit)
- Missing: `placement_id` (where ad was shown)
- Missing: `mediation_network` (which network won the auction)

**`game_ended`:**
- Missing: `device_model` (for performance analysis)
- Missing: `fps_average` (average frame rate during game)
- Missing: `battery_level` (if available)

---

## 🎯 PART 11: TOP GAMING STANDARDS COMPLIANCE

### 11.1 Industry Leaders Comparison

#### **Supercell (Clash of Clans, Clash Royale)**
- ✅ Tracks every screen view
- ✅ Tracks every button click with context
- ✅ Tracks purchase intent (not just completion)
- ✅ Tracks tutorial completion rates
- ✅ Tracks social sharing effectiveness

#### **King (Candy Crush)**
- ✅ Tracks level attempt patterns
- ✅ Tracks powerup usage by level
- ✅ Tracks difficulty tuning metrics
- ✅ Tracks retention by player segment

#### **Rovio (Angry Birds)**
- ✅ Tracks ad placement effectiveness
- ✅ Tracks IAP product load success rates
- ✅ Tracks purchase funnel drop-offs
- ✅ Tracks notification engagement

### 11.2 Our Compliance Status

| Standard | Status | Gap |
|----------|--------|-----|
| Screen view tracking | ❌ Missing | Need `screen_viewed` events |
| Purchase funnel | ⚠️ Partial | Missing `purchase_intent`, `purchase_cancelled` |
| Tutorial tracking | ❌ Missing | Need tutorial events |
| Ad network tracking | ⚠️ Partial | Missing network/placement details |
| Session quality | ⚠️ Partial | Missing quality indicators |
| Churn prediction | ❌ Missing | Need inactivity/abandonment events |

---

## 📋 PART 12: SUMMARY & NEXT STEPS

### 12.1 Current State
- ✅ **Good**: Comprehensive gameplay and monetization tracking
- ✅ **Good**: Dual tracking (EventBus + Firebase)
- ✅ **Good**: Offline event queuing
- ⚠️ **Needs Work**: Schema consistency
- ❌ **Missing**: Screen view tracking
- ❌ **Missing**: Store funnel tracking
- ❌ **Missing**: Tutorial tracking

### 12.2 Immediate Actions Required
1. **Fix schema mismatches** (event names, parameter names)
2. **Add screen_viewed events** (critical for funnel analysis)
3. **Add store funnel events** (purchase intent tracking)
4. **Add purchase validation fields** (transaction_id, purchase_token)
5. **Add tournament entry/reward events** (complete tournament funnel)

### 12.3 Long-term Enhancements
1. **A/B testing framework** (experiment tracking)
2. **Performance monitoring** (FPS, load times)
3. **Player segmentation** (auto-classify player tiers)
4. **Predictive analytics** (churn prediction, LTV estimation)

---

## 📚 APPENDIX: Event Schema Reference

### A.1 Complete Event List (Current)

**EventBus Events (77 total):**
- Core Gameplay: 5 events
- Tournament: 7 events
- Monetization: 13 events
- Progression: 15 events
- User Identity: 12 events
- Conversion: 8 events
- Daily Streak: 4 events
- Other: 13 events

**Firebase Events (20+ total):**
- Gameplay: 3 events
- Monetization: 4 events
- Engagement: 6 events
- Progression: 3 events
- Technical: 4 events

### A.2 Recommended New Events (40+)

See Part 2.2 for complete list of missing events.

---

---

## 💰 PART 13: GOOGLE ADS ATTRIBUTION & ROI ANALYSIS

### 13.1 Current State: Campaign Attribution Tracking

#### **✅ What We Have**
- ✅ Firebase Analytics initialized (automatically tracks `first_open` with campaign parameters)
- ✅ Conversion events fired to Firebase (for Google Ads optimization)
- ✅ User install date tracked (`installDate` in `DeviceIdentityManager`)
- ✅ Revenue tracking (IAP purchases and ad revenue)
- ✅ User ID tracking (device-based, persistent)

#### **❌ What's Missing (Critical Gaps)**

**1. Campaign Attribution Data Capture**
- ❌ **NOT capturing `first_open` event** - Firebase automatically fires this with campaign parameters, but we're not listening to it
- ❌ **NOT storing campaign parameters** - No code to extract and store:
  - `source` (e.g., "google")
  - `medium` (e.g., "cpc")
  - `campaign` (e.g., "summer_sale_2025")
  - `campaign_id` (Google Ads campaign ID)
  - `ad_group` (Google Ads ad group)
  - `ad_group_id` (Google Ads ad group ID)
  - `keyword` (search keyword if applicable)
  - `gclid` (Google Click ID)
  - `creative` (ad creative identifier)
- ❌ **NOT linking campaign to user** - User ID is generated but not linked to acquisition campaign in backend

**2. User Acquisition Cost (CAC) Tracking**
- ❌ **NO Google Ads cost data import** - No mechanism to:
  - Import daily campaign spend from Google Ads API
  - Import cost per install (CPI) from Google Ads
  - Link cost data to users by campaign
- ❌ **NO CAC calculation** - Cannot calculate:
  - Cost per user per campaign
  - Cost per install (CPI)
  - Cost per acquisition (CPA)
  - Cost per conversion (CPC for in-app conversions)

**3. Revenue Attribution**
- ⚠️ **Revenue tracked but NOT linked to campaign** - We track:
  - IAP revenue (`special_offer_purchased`, `no_ads_purchased`, `currency_bundle_purchased`)
  - Ad revenue (`ad_revenue` event)
  - BUT: Revenue events don't include `campaign_id` or `acquisition_source`
- ❌ **NO revenue split by campaign** - Cannot answer:
  - Which campaigns generate most revenue?
  - What's the ROI per campaign?
  - Which campaigns have best LTV?

**4. Cohort Analysis Capabilities**
- ⚠️ **Date cohorts possible** - We have `installDate`, so we can create:
  - Daily cohorts (users who installed on same day)
  - Weekly cohorts
  - Monthly cohorts
- ❌ **Campaign cohorts NOT possible** - Missing campaign data means:
  - Cannot create cohorts by Google Ads campaign
  - Cannot compare campaign performance over time
  - Cannot track campaign-specific retention
  - Cannot track campaign-specific LTV

---

### 13.2 How Firebase Analytics Handles Campaign Attribution

**Firebase Analytics automatically:**
1. Captures `first_open` event with campaign parameters when app is first opened
2. Stores campaign parameters in Firebase Analytics dashboard
3. Links campaign to user via Firebase Analytics User ID
4. Provides campaign data in Firebase Analytics reports

**BUT:**
- Campaign data is **only in Firebase Analytics**, not in our backend
- We need to **manually extract** campaign data from Firebase or use Firebase Analytics API
- Campaign data is **not automatically sent** to our EventBus/backend

---

### 13.3 Required Implementation for ROI Analysis

#### **Phase 1: Capture Campaign Attribution (Critical)**

**1.1 Listen to Firebase `first_open` Event**
```dart
// Need to add listener in FirebaseAnalyticsManager or main.dart
FirebaseAnalytics.instance.logEvent(
  name: 'first_open',
  parameters: {
    // Firebase automatically adds campaign parameters:
    // 'source', 'medium', 'campaign', 'campaign_id', 'gclid', etc.
  }
);
```

**1.2 Extract Campaign Parameters**
- Use Firebase Analytics API or Firebase Remote Config
- Or: Use `FirebaseAnalytics.instance.getAppInstanceId()` to get user ID
- Query Firebase Analytics for campaign data per user

**1.3 Store Campaign Data in Backend**
- Fire `user_acquired` event to EventBus with campaign parameters:
```dart
EventBus().fire('user_acquired', {
  'user_id': userId,
  'install_date': installDate.toIso8601String(),
  'source': campaignSource,        // e.g., "google"
  'medium': campaignMedium,         // e.g., "cpc"
  'campaign': campaignName,         // e.g., "summer_sale_2025"
  'campaign_id': campaignId,        // Google Ads campaign ID
  'ad_group': adGroupName,
  'ad_group_id': adGroupId,
  'keyword': keyword,               // If search campaign
  'gclid': gclid,                   // Google Click ID
  'creative': creativeId,
  'platform': platform,             // "ios" or "android"
  'country': country,               // From device or IP
});
```

**1.4 Link Campaign to All Future Events**
- Add `campaign_id` to all events (via EventBus enrichment)
- Or: Store campaign_id in user profile and join in backend

#### **Phase 2: Import Google Ads Cost Data**

**2.1 Google Ads API Integration**
- Set up Google Ads API access
- Create scheduled job to import daily campaign spend:
  - Campaign ID
  - Campaign name
  - Date
  - Cost (USD)
  - Impressions
  - Clicks
  - Installs (if available)

**2.2 Cost Data Storage**
- Store in backend database:
```sql
CREATE TABLE campaign_costs (
  id SERIAL PRIMARY KEY,
  campaign_id VARCHAR(255) NOT NULL,
  campaign_name VARCHAR(255),
  date DATE NOT NULL,
  cost_usd DECIMAL(10,2) NOT NULL,
  impressions INTEGER,
  clicks INTEGER,
  installs INTEGER,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(campaign_id, date)
);
```

**2.3 Link Cost to Users**
- Match users by `campaign_id` from `user_acquired` event
- Calculate CAC per campaign:
```sql
SELECT 
  campaign_id,
  COUNT(DISTINCT user_id) as users_acquired,
  SUM(cost_usd) as total_cost,
  SUM(cost_usd) / COUNT(DISTINCT user_id) as cac_per_user
FROM campaign_costs cc
JOIN user_acquisitions ua ON cc.campaign_id = ua.campaign_id
WHERE cc.date = '2025-01-15'
GROUP BY campaign_id;
```

#### **Phase 3: Revenue Attribution by Campaign**

**3.1 Add Campaign ID to Revenue Events**
- Modify all purchase events to include `campaign_id`:
```dart
EventBus().fire('special_offer_purchased', {
  'offer_id': offerId,
  'product_id': productId,
  'price_usd': priceUsd,
  'campaign_id': userCampaignId,  // ← ADD THIS
  'acquisition_source': 'google_ads',  // ← ADD THIS
  // ... existing fields
});
```

- Modify `ad_revenue` event to include `campaign_id`:
```dart
EventBus().fire('ad_revenue', {
  'ad_type': adType,
  'revenue_usd': revenueUsd,
  'campaign_id': userCampaignId,  // ← ADD THIS
  'acquisition_source': 'google_ads',  // ← ADD THIS
  // ... existing fields
});
```

**3.2 Calculate Revenue per Campaign**
```sql
SELECT 
  ua.campaign_id,
  COUNT(DISTINCT ua.user_id) as total_users,
  SUM(CASE WHEN e.event_type = 'special_offer_purchased' THEN e.price_usd ELSE 0 END) as iap_revenue,
  SUM(CASE WHEN e.event_type = 'ad_revenue' THEN e.revenue_usd ELSE 0 END) as ad_revenue,
  SUM(CASE WHEN e.event_type IN ('special_offer_purchased', 'ad_revenue') 
      THEN COALESCE(e.price_usd, e.revenue_usd, 0) ELSE 0 END) as total_revenue
FROM user_acquisitions ua
LEFT JOIN events e ON ua.user_id = e.user_id
WHERE ua.campaign_id = 'campaign_123'
GROUP BY ua.campaign_id;
```

**3.3 Calculate ROI per Campaign**
```sql
SELECT 
  cc.campaign_id,
  cc.campaign_name,
  COUNT(DISTINCT ua.user_id) as users_acquired,
  cc.cost_usd as total_cost,
  SUM(CASE WHEN e.event_type = 'special_offer_purchased' THEN e.price_usd ELSE 0 END) as iap_revenue,
  SUM(CASE WHEN e.event_type = 'ad_revenue' THEN e.revenue_usd ELSE 0 END) as ad_revenue,
  (SUM(CASE WHEN e.event_type IN ('special_offer_purchased', 'ad_revenue') 
      THEN COALESCE(e.price_usd, e.revenue_usd, 0) ELSE 0 END) - cc.cost_usd) as net_profit,
  (SUM(CASE WHEN e.event_type IN ('special_offer_purchased', 'ad_revenue') 
      THEN COALESCE(e.price_usd, e.revenue_usd, 0) ELSE 0 END) / cc.cost_usd) * 100 as roi_percentage
FROM campaign_costs cc
JOIN user_acquisitions ua ON cc.campaign_id = ua.campaign_id
LEFT JOIN events e ON ua.user_id = e.user_id
WHERE cc.date >= '2025-01-01'
GROUP BY cc.campaign_id, cc.campaign_name, cc.cost_usd;
```

#### **Phase 4: Cohort Analysis Implementation**

**4.1 Date-Based Cohorts (Currently Possible)**
```sql
-- Daily cohorts
SELECT 
  DATE(ua.install_date) as cohort_date,
  COUNT(DISTINCT ua.user_id) as cohort_size,
  COUNT(DISTINCT CASE WHEN e.event_type = 'game_started' 
    AND DATE(e.timestamp) = DATE(ua.install_date) + INTERVAL '1 day' 
    THEN e.user_id END) as d1_retention,
  COUNT(DISTINCT CASE WHEN e.event_type = 'game_started' 
    AND DATE(e.timestamp) = DATE(ua.install_date) + INTERVAL '7 days' 
    THEN e.user_id END) as d7_retention,
  COUNT(DISTINCT CASE WHEN e.event_type = 'game_started' 
    AND DATE(e.timestamp) = DATE(ua.install_date) + INTERVAL '30 days' 
    THEN e.user_id END) as d30_retention
FROM user_acquisitions ua
LEFT JOIN events e ON ua.user_id = e.user_id
GROUP BY DATE(ua.install_date)
ORDER BY cohort_date DESC;
```

**4.2 Campaign-Based Cohorts (Requires Campaign Data)**
```sql
-- Campaign cohorts with retention
SELECT 
  ua.campaign_id,
  DATE(ua.install_date) as cohort_date,
  COUNT(DISTINCT ua.user_id) as cohort_size,
  COUNT(DISTINCT CASE WHEN e.event_type = 'game_started' 
    AND DATE(e.timestamp) = DATE(ua.install_date) + INTERVAL '1 day' 
    THEN e.user_id END) as d1_retention,
  COUNT(DISTINCT CASE WHEN e.event_type = 'game_started' 
    AND DATE(e.timestamp) = DATE(ua.install_date) + INTERVAL '7 days' 
    THEN e.user_id END) as d7_retention,
  SUM(CASE WHEN e.event_type IN ('special_offer_purchased', 'ad_revenue') 
      THEN COALESCE(e.price_usd, e.revenue_usd, 0) ELSE 0 END) as cohort_revenue,
  SUM(CASE WHEN e.event_type IN ('special_offer_purchased', 'ad_revenue') 
      THEN COALESCE(e.price_usd, e.revenue_usd, 0) ELSE 0 END) / 
    COUNT(DISTINCT ua.user_id) as ltv_per_user
FROM user_acquisitions ua
LEFT JOIN events e ON ua.user_id = e.user_id
WHERE ua.campaign_id IS NOT NULL
GROUP BY ua.campaign_id, DATE(ua.install_date)
ORDER BY cohort_date DESC, ua.campaign_id;
```

---

### 13.4 Missing Events for ROI Analysis

#### **Critical Missing Events**

1. **`user_acquired`** - Fired on first install with campaign parameters
   ```json
   {
     "event_type": "user_acquired",
     "user_id": "user_123",
     "install_date": "2025-01-15T10:30:00Z",
     "source": "google",
     "medium": "cpc",
     "campaign": "summer_sale_2025",
     "campaign_id": "123456789",
     "ad_group": "action_game_ads",
     "ad_group_id": "987654321",
     "keyword": "flappy bird game",
     "gclid": "EAIaIQobChMI...",
     "creative": "creative_123",
     "platform": "android",
     "country": "US"
   }
   ```

2. **`campaign_cost_imported`** - Fired when Google Ads cost data is imported
   ```json
   {
     "event_type": "campaign_cost_imported",
     "campaign_id": "123456789",
     "date": "2025-01-15",
     "cost_usd": 1500.00,
     "impressions": 50000,
     "clicks": 2500,
     "installs": 100
   }
   ```

3. **`revenue_attributed`** - Fired when revenue is attributed to campaign (optional, can be calculated)
   ```json
   {
     "event_type": "revenue_attributed",
     "user_id": "user_123",
     "campaign_id": "123456789",
     "revenue_type": "iap",  // or "ads"
     "revenue_usd": 4.99,
     "product_id": "starter_boss_pack",
     "timestamp": "2025-01-20T15:45:00Z"
   }
   ```

---

### 13.5 Backend Schema Requirements

#### **New Tables Needed**

**1. `user_acquisitions` Table**
```sql
CREATE TABLE user_acquisitions (
  id SERIAL PRIMARY KEY,
  user_id VARCHAR(255) NOT NULL UNIQUE,
  install_date TIMESTAMP NOT NULL,
  source VARCHAR(50),              -- "google", "organic", "referral"
  medium VARCHAR(50),               -- "cpc", "organic", "referral"
  campaign VARCHAR(255),            -- Campaign name
  campaign_id VARCHAR(255),         -- Google Ads campaign ID
  ad_group VARCHAR(255),
  ad_group_id VARCHAR(255),
  keyword VARCHAR(255),
  gclid VARCHAR(255),               -- Google Click ID
  creative VARCHAR(255),
  platform VARCHAR(10),            -- "ios" or "android"
  country VARCHAR(2),               -- ISO country code
  created_at TIMESTAMP DEFAULT NOW(),
  INDEX idx_campaign_id (campaign_id),
  INDEX idx_install_date (install_date)
);
```

**2. `campaign_costs` Table**
```sql
CREATE TABLE campaign_costs (
  id SERIAL PRIMARY KEY,
  campaign_id VARCHAR(255) NOT NULL,
  campaign_name VARCHAR(255),
  date DATE NOT NULL,
  cost_usd DECIMAL(10,2) NOT NULL,
  impressions INTEGER,
  clicks INTEGER,
  installs INTEGER,                -- From Google Ads if available
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(campaign_id, date),
  INDEX idx_campaign_date (campaign_id, date)
);
```

**3. Modify `events` Table**
- Add `campaign_id` column (nullable, for revenue attribution)
- Add index on `campaign_id` for faster cohort queries

---

### 13.6 Current System Capabilities Assessment

#### **✅ Can Currently Do:**
- Track install date per user
- Track revenue per user (IAP + ads)
- Create date-based cohorts (daily/weekly/monthly)
- Calculate basic LTV (lifetime value) per user
- Track user engagement over time

#### **❌ Cannot Currently Do:**
- Identify which Google Ads campaign a user came from
- Calculate cost per user per campaign
- Calculate ROI per campaign
- Create campaign-based cohorts
- Compare campaign performance (retention, LTV, ROI)
- Optimize ad spend based on campaign ROI
- Attribute revenue to specific campaigns

---

### 13.7 Implementation Priority for ROI Analysis

#### **Priority 1: Critical (Week 1-2)**
1. ✅ **Capture `first_open` event** with campaign parameters
2. ✅ **Fire `user_acquired` event** to EventBus with all campaign data
3. ✅ **Store campaign data in backend** (`user_acquisitions` table)
4. ✅ **Add `campaign_id` to all revenue events** (IAP + ads)

#### **Priority 2: High Value (Week 3-4)**
1. ✅ **Set up Google Ads API integration** for cost data import
2. ✅ **Create `campaign_costs` table** and import daily spend
3. ✅ **Calculate CAC per campaign** (cost / users acquired)
4. ✅ **Calculate ROI per campaign** (revenue / cost)

#### **Priority 3: Advanced Analytics (Week 5-6)**
1. ✅ **Create campaign cohort analysis** dashboard
2. ✅ **Track campaign-specific retention** (D1, D7, D30)
3. ✅ **Track campaign-specific LTV** (lifetime value)
4. ✅ **Create ROI optimization recommendations** (which campaigns to scale/stop)

---

### 13.8 Recommended Dashboard Metrics

#### **Campaign Performance Dashboard**
- **Acquisition Metrics:**
  - Users acquired per campaign
  - Cost per install (CPI)
  - Cost per acquisition (CPA)
  
- **Revenue Metrics:**
  - IAP revenue per campaign
  - Ad revenue per campaign
  - Total revenue per campaign
  - Average revenue per user (ARPU) per campaign
  
- **ROI Metrics:**
  - ROI % per campaign (revenue / cost * 100)
  - Net profit per campaign (revenue - cost)
  - Payback period (days to recover CAC)
  
- **Engagement Metrics:**
  - D1/D7/D30 retention per campaign
  - Sessions per user per campaign
  - Average session duration per campaign
  
- **Cohort Analysis:**
  - Campaign cohorts over time
  - Retention curves by campaign
  - LTV curves by campaign

---

---

## 🚀 PART 14: SCALABILITY & PERFORMANCE ANALYSIS
### Data Ingestion, Storage, Analysis & Dashboard Performance

### 14.1 Current Architecture Assessment

#### **Client-Side (Flutter App) - EventBus**

**Current Configuration:**
- ✅ **Batching**: Events batched in groups of 50 (`_maxBatchSize = 50`)
- ✅ **Queue Management**: Max 100 events in memory queue (`_maxQueueSize = 100`)
- ✅ **Auto-Flush**: Every 15 seconds (`_autoFlushInterval = 15s`)
- ✅ **Persistence**: SQLite local storage for offline events
- ✅ **Retry Logic**: Events retry on failure (stored in SQLite)
- ✅ **Background Flush**: Events flushed when app goes to background

**Current Capacity:**
- **Events per batch**: 50 events
- **Max queue size**: 100 events (auto-flush triggers)
- **Flush frequency**: Every 15 seconds OR when queue is full
- **Theoretical max throughput**: ~200 events/second per user (if queue fills instantly)
- **Realistic throughput**: ~3-7 events/second per user (typical gameplay)

**Scalability Concerns:**
- ⚠️ **Single HTTP request per batch** - Could be bottleneck with many concurrent users
- ⚠️ **No compression** - Events sent as JSON (could be gzipped)
- ⚠️ **Synchronous database writes** - Each event writes to SQLite immediately (could batch)
- ⚠️ **No event sampling** - All events sent (could sample high-frequency events)

#### **Backend (Railway) - Event Processing**

**Current Endpoint:** `/api/events` (POST)
- ✅ Accepts array of events (batched, max 100 per batch)
- ✅ Fire-and-forget pattern (returns 200 immediately, processes async)
- ✅ PostgreSQL database (Railway Pro)
- ✅ Redis caching (optional, graceful degradation)
- ✅ Connection pooling (100 max connections, 10 min)

**Database Schema:**
```sql
CREATE TABLE events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_type VARCHAR(50) NOT NULL,
  user_id VARCHAR(255) NOT NULL,
  payload JSONB NOT NULL,  -- Full event data stored as JSONB
  received_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  processed_at TIMESTAMP WITH TIME ZONE,  -- NULL = unprocessed
  processing_attempts INT DEFAULT 0,
  processing_error TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Indexes:**
- ✅ `idx_events_type_received` - For event type queries
- ✅ `idx_events_user_received` - For user-specific queries
- ✅ `idx_events_received_processed` - For unprocessed events
- ✅ `idx_events_payload_gin` - GIN index on JSONB payload (for payload queries)

**Event Processing:**
- ✅ **EventProcessor** validates events against Joi schemas
- ✅ Stores raw events in PostgreSQL (JSONB payload)
- ✅ Processes events in parallel (Promise.all)
- ✅ Retry logic for failed events (max 3 attempts)
- ✅ Special event handling (e.g., nickname_changed updates users table)

**Caching:**
- ✅ Redis caching for dashboard queries (5-minute TTL)
- ✅ Graceful degradation (no-op cache if Redis unavailable)
- ✅ CacheManager with automatic Redis reconnection

**Dashboard:**
- ✅ Materialized views for common aggregations
- ✅ Redis caching for all dashboard queries
- ✅ Query timeout handling (12 seconds)
- ✅ Connection pool retry logic

---

### 14.2 Data Ingestion Scalability Analysis

#### **Event Volume Projections**

**Scenario 1: Moderate Traffic (1,000 DAU)**
- Average events per user per day: 50 events
- Total daily events: 50,000 events
- Peak hour (20% of traffic): 10,000 events/hour
- Peak minute: ~167 events/minute
- **Current system**: ✅ **HANDLES** (well within capacity)

**Scenario 2: High Traffic (10,000 DAU)**
- Average events per user per day: 50 events
- Total daily events: 500,000 events
- Peak hour: 100,000 events/hour
- Peak minute: ~1,667 events/minute
- Peak second: ~28 events/second
- **Current system**: ⚠️ **MIGHT HANDLE** (depends on backend)

**Scenario 3: Marketing Launch (100,000 DAU)**
- Average events per user per day: 50 events
- Total daily events: 5,000,000 events
- Peak hour: 1,000,000 events/hour
- Peak minute: ~16,667 events/minute
- Peak second: ~278 events/second
- **Current system**: ❌ **WILL STRUGGLE** (needs optimization)

#### **Bottleneck Analysis**

**Client-Side Bottlenecks:**
1. **SQLite writes** - Each event writes immediately (could batch)
2. **Network requests** - Single HTTP POST per batch (could use connection pooling)
3. **JSON encoding** - No compression (could gzip)

**Backend Bottlenecks (Assumed):**
1. **Database writes** - Inserting events one-by-one (should batch insert)
2. **Database indexes** - May slow down writes if not optimized
3. **Query performance** - Aggregations on large event tables
4. **API rate limiting** - No visible rate limiting (could be overwhelmed)

---

### 14.3 Recommended Data Ingestion Architecture

#### **Phase 1: Client-Side Optimizations (Immediate)**

**1.1 Batch SQLite Writes**
```dart
// Current: Each event writes immediately
await _db!.insert('events', {...});  // ❌ Slow

// Recommended: Batch writes
final batch = _db!.batch();
for (final event in events) {
  batch.insert('events', {...});
}
await batch.commit(noResult: true);  // ✅ Fast
```

**1.2 Add Compression**
```dart
// Current: Plain JSON
body: json.encode(events.map((e) => e.toJson()).toList())

// Recommended: Gzip compression
import 'dart:io';
import 'package:archive/archive.dart';

final jsonData = json.encode(events.map((e) => e.toJson()).toList());
final compressed = gzip.encode(utf8.encode(jsonData));
headers: {
  'Content-Type': 'application/json',
  'Content-Encoding': 'gzip',  // ← Add this
}
body: compressed
```

**1.3 Increase Batch Size (Conditional)**
```dart
// Current: 50 events per batch
static const int _maxBatchSize = 50;

// Recommended: Dynamic batch size based on event size
static int _calculateBatchSize(List<Event> events) {
  final totalSize = events.fold(0, (sum, e) => sum + e.toJson().toString().length);
  if (totalSize > 100000) return 25;  // Smaller batches for large events
  if (totalSize > 50000) return 50;    // Current size
  return 100;  // Larger batches for small events
}
```

**1.4 Add Event Sampling (Optional)**
```dart
// For high-frequency events (e.g., bonus_collected)
static bool _shouldSample(String eventName) {
  const highFrequencyEvents = ['bonus_collected', 'obstacle_dodged'];
  if (highFrequencyEvents.contains(eventName)) {
    return Random().nextInt(10) < 1;  // Sample 10% of events
  }
  return true;  // Send all other events
}
```

#### **Phase 2: Backend Optimizations (Critical)**

**2.1 Batch Database Inserts** ⚠️ **CRITICAL - NOT CURRENTLY IMPLEMENTED**
```javascript
// Current: One INSERT per event (in event-processor.js)
async storeEvent(event) {
  const query = `
    INSERT INTO events (event_type, user_id, payload, received_at)
    VALUES ($1, $2, $3, NOW())
    RETURNING id
  `;
  // ❌ Slow - one INSERT per event
}

// Recommended: Batch INSERT
async storeBatch(events) {
  const values = events.map((e, i) => 
    `($${i*3+1}, $${i*3+2}, $${i*3+3}, NOW())`
  ).join(', ');
  
  const query = `
    INSERT INTO events (event_type, user_id, payload, received_at)
    VALUES ${values}
    RETURNING id
  `;
  // ✅ Fast - 50-100 events per INSERT
}
```

**2.2 Connection Pooling** ✅ **ALREADY IMPLEMENTED**
- ✅ PostgreSQL connection pool: 100 max, 10 min
- ✅ Connection pool monitoring (every 5 minutes)
- ✅ Warnings at 80% utilization
- ✅ Error logging when pool exhausted
- ⚠️ **May need to increase** to 150-200 for high traffic

**2.3 Optimize Database Schema** ⚠️ **PARTIALLY IMPLEMENTED**

**Current Schema (Actual):**
```sql
CREATE TABLE events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_type VARCHAR(50) NOT NULL,
  user_id VARCHAR(255) NOT NULL,
  payload JSONB NOT NULL,  -- Full event data
  received_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  processed_at TIMESTAMP WITH TIME ZONE,
  processing_attempts INT DEFAULT 0,
  processing_error TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Existing indexes:
CREATE INDEX idx_events_type_received ON events(event_type, received_at);
CREATE INDEX idx_events_user_received ON events(user_id, received_at);
CREATE INDEX idx_events_received_processed ON events(received_at, processed_at) WHERE processed_at IS NULL;
CREATE INDEX idx_events_payload_gin ON events USING GIN (payload);  -- ✅ Already has GIN index!
```

**Recommended Additional Optimizations:**
```sql
-- 1. Partition by date (for time-series data) - ⚠️ NOT IMPLEMENTED
CREATE TABLE events_2025_01 PARTITION OF events
  FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');

-- 2. Add campaign_id column (for ROI analysis) - ⚠️ NOT IMPLEMENTED
ALTER TABLE events ADD COLUMN campaign_id VARCHAR(255);
CREATE INDEX idx_events_campaign_timestamp ON events(campaign_id, received_at DESC) WHERE campaign_id IS NOT NULL;

-- 3. Add revenue columns (for faster revenue queries) - ⚠️ NOT IMPLEMENTED
ALTER TABLE events ADD COLUMN revenue_usd DECIMAL(10,2);
ALTER TABLE events ADD COLUMN revenue_type VARCHAR(20);  -- 'iap' or 'ads'
CREATE INDEX idx_events_campaign_revenue ON events(campaign_id, revenue_usd) WHERE revenue_usd > 0;

-- 4. Add session_id index (if frequently queried) - ⚠️ NOT IMPLEMENTED
CREATE INDEX idx_events_session ON events(user_id, session_id, received_at);
```

**2.4 Implement Event Processing Queue** ⚠️ **NOT IMPLEMENTED - OPTIONAL BUT RECOMMENDED**

**Current Implementation:**
- ✅ Events processed immediately after API response (fire-and-forget)
- ✅ Parallel processing (Promise.all) for batch
- ❌ No message queue (direct database writes)

**Recommended: Use Bull Queue (Already in package.json!)**
```javascript
// railway-backend already has 'bull' package installed!
// Just needs to be configured

// 1. API receives events → Push to queue
const Queue = require('bull');
const eventQueue = new Queue('events', {
  redis: { host: redisHost, port: redisPort }
});

app.post('/api/events', async (req, res) => {
  const events = req.body;
  await eventQueue.addBatch(events);  // ✅ Already implemented in routes/events.js!
  res.status(200).json({ received: events.length });
});

// 2. Worker processes queue → Batch insert to database
eventQueue.process(async (job) => {
  const events = job.data;  // Array of events
  await db.batchInsert('events', events);  // Batch insert
});
```

**Note:** The code already checks for `req.app.locals.eventQueue` in `routes/events.js` (line 105-112), but queue is not initialized in `server.js`. This is a **quick win** - just need to initialize Bull queue!

---

### 14.4 Data Analysis & Aggregation Strategy

#### **Current State: Unknown**
- ❓ How are aggregations calculated?
- ❓ Are they real-time or batch?
- ❓ What's the query performance?
- ❓ Are there materialized views?

#### **Recommended: Hybrid Approach**

**Real-Time Metrics (Last 24 hours):**
- Use in-memory cache (Redis) for recent events
- Update cache on each event
- Query cache for dashboard (fast, <100ms)

**Historical Metrics (Last 7+ days):**
- Use pre-aggregated tables (materialized views)
- Update hourly/daily via batch jobs
- Query pre-aggregated data (fast, <500ms)

**Example: Revenue Aggregation**

**Real-Time (Redis):**
```javascript
// On each revenue event
await redis.incrby('revenue:today:campaign:123', 4.99);
await redis.incrby('revenue:today:total', 4.99);

// Query dashboard
const campaignRevenue = await redis.get('revenue:today:campaign:123');
```

**Historical (Materialized View):**
```sql
-- Create materialized view
CREATE MATERIALIZED VIEW daily_revenue_by_campaign AS
SELECT 
  DATE(timestamp) as date,
  campaign_id,
  SUM(CASE WHEN event_type = 'special_offer_purchased' THEN price_usd ELSE 0 END) as iap_revenue,
  SUM(CASE WHEN event_type = 'ad_revenue' THEN revenue_usd ELSE 0 END) as ad_revenue,
  COUNT(DISTINCT user_id) as paying_users
FROM events
WHERE event_type IN ('special_offer_purchased', 'ad_revenue')
  AND timestamp >= NOW() - INTERVAL '30 days'
GROUP BY DATE(timestamp), campaign_id;

-- Refresh hourly
REFRESH MATERIALIZED VIEW CONCURRENTLY daily_revenue_by_campaign;

-- Query dashboard (fast!)
SELECT * FROM daily_revenue_by_campaign 
WHERE date >= '2025-01-01' 
ORDER BY date DESC, campaign_id;
```

---

### 14.5 Dashboard Performance Optimization

#### **Query Optimization Strategies**

**1. Pre-Aggregate Common Metrics**
```sql
-- Create aggregated tables updated hourly
CREATE TABLE hourly_metrics (
  hour TIMESTAMP NOT NULL,
  campaign_id VARCHAR(255),
  event_type VARCHAR(255),
  event_count INTEGER,
  revenue_usd DECIMAL(10,2),
  unique_users INTEGER,
  PRIMARY KEY (hour, campaign_id, event_type)
);

-- Update via scheduled job
INSERT INTO hourly_metrics
SELECT 
  DATE_TRUNC('hour', timestamp) as hour,
  campaign_id,
  event_type,
  COUNT(*) as event_count,
  SUM(COALESCE(price_usd, revenue_usd, 0)) as revenue_usd,
  COUNT(DISTINCT user_id) as unique_users
FROM events
WHERE timestamp >= NOW() - INTERVAL '1 hour'
GROUP BY DATE_TRUNC('hour', timestamp), campaign_id, event_type
ON CONFLICT (hour, campaign_id, event_type) DO UPDATE SET
  event_count = EXCLUDED.event_count,
  revenue_usd = EXCLUDED.revenue_usd,
  unique_users = EXCLUDED.unique_users;
```

**2. Use Read Replicas**
- Primary database: Write events
- Read replica: Query dashboard (doesn't slow down writes)

**3. Implement Caching Layer**
```javascript
// Cache dashboard queries for 5 minutes
app.get('/api/dashboard/campaign-performance', async (req, res) => {
  const cacheKey = `dashboard:campaign:${req.query.date}`;
  const cached = await redis.get(cacheKey);
  
  if (cached) {
    return res.json(JSON.parse(cached));
  }
  
  // Query database
  const data = await db.query(/* ... */);
  
  // Cache for 5 minutes
  await redis.setex(cacheKey, 300, JSON.stringify(data));
  
  res.json(data);
});
```

**4. Paginate Large Results**
```sql
-- Don't return all events, paginate
SELECT * FROM events 
WHERE campaign_id = '123' 
ORDER BY timestamp DESC 
LIMIT 100 OFFSET 0;  -- Page 1

SELECT * FROM events 
WHERE campaign_id = '123' 
ORDER BY timestamp DESC 
LIMIT 100 OFFSET 100;  -- Page 2
```

---

### 14.6 Infrastructure Requirements

#### **Current: Railway Backend (Assumed)**
- ❓ Database type and size
- ❓ Connection limits
- ❓ Compute resources
- ❓ Auto-scaling capabilities

#### **Recommended Infrastructure for High Traffic**

**Database:**
- **Type**: PostgreSQL (recommended) or MySQL
- **Size**: Start with 100GB, scale to 1TB+ as needed
- **Connection Pool**: 50-100 connections
- **Read Replicas**: 2-3 replicas for dashboard queries
- **Backup**: Daily automated backups

**Application Server:**
- **Compute**: 2-4 CPU cores, 4-8GB RAM
- **Auto-scaling**: Scale to 5-10 instances under load
- **Load Balancer**: Distribute traffic across instances

**Caching Layer:**
- **Redis**: 2GB+ memory for real-time metrics
- **TTL**: 5-15 minutes for dashboard cache

**Message Queue (Optional but Recommended):**
- **Redis Queue** or **RabbitMQ** for event processing
- Decouples API from database writes
- Allows horizontal scaling of workers

**Monitoring:**
- **Database Performance**: Query slow logs, connection pool usage
- **API Performance**: Response times, error rates
- **Event Processing**: Queue depth, processing lag
- **Dashboard Performance**: Query times, cache hit rates

---

### 14.7 Performance Benchmarks & Targets

#### **Target Performance Metrics**

**Data Ingestion:**
- ✅ **Event Processing**: <100ms per batch (50 events)
- ✅ **Database Write**: <50ms per batch insert
- ✅ **API Response**: <200ms (including queue push)
- ✅ **Throughput**: 10,000+ events/second (with queue)

**Data Analysis:**
- ✅ **Real-Time Queries**: <100ms (from Redis cache)
- ✅ **Historical Queries**: <500ms (from materialized views)
- ✅ **Dashboard Load**: <1 second (with caching)

**Scalability:**
- ✅ **Concurrent Users**: 100,000+ DAU
- ✅ **Events per Day**: 5,000,000+ events
- ✅ **Peak Events/Second**: 500+ events/second

#### **Current System Capacity (Based on Actual Backend)**

**Current Backend Capabilities:**
- ✅ **Database**: PostgreSQL with connection pooling (100 max connections)
- ✅ **Caching**: Redis (optional, graceful degradation)
- ✅ **Event Storage**: JSONB payload (flexible, queryable)
- ✅ **Processing**: Parallel processing (Promise.all)
- ✅ **Dashboard**: Redis caching (5-minute TTL) + materialized views
- ✅ **Connection Pool**: 100 max, 10 min, with monitoring

**Current Capacity (Estimated):**
- ⚠️ **Max DAU**: ~50,000 (should handle with current setup)
- ⚠️ **Events per Day**: ~2,500,000 (should handle)
- ⚠️ **Peak Events/Second**: ~100-150 events/second (may struggle at higher traffic)

**Bottlenecks Identified:**
1. **Event Storage**: One INSERT per event (not batched) - ⚠️ **CRITICAL**
2. **No Message Queue**: Direct database writes (could overwhelm DB)
3. **Dashboard Queries**: Complex aggregations on large event table
4. **Connection Pool**: 100 connections may be insufficient for high traffic

**With Recommended Optimizations:**
- ✅ **Max DAU**: 100,000+ (with batch inserts + message queue)
- ✅ **Events per Day**: 5,000,000+ (with batch inserts + message queue)
- ✅ **Peak Events/Second**: 500+ events/second (with message queue)

---

### 14.8 Implementation Roadmap for Scalability

#### **Phase 1: Immediate Optimizations (Week 1)**
1. ✅ **Batch SQLite writes** on client (reduce I/O)
2. ✅ **Add gzip compression** to HTTP requests (reduce bandwidth)
3. ✅ **Increase batch size** conditionally (reduce requests)
4. ✅ **Add database indexes** (improve query performance)

#### **Phase 2: Backend Optimizations (Week 2-3)**
1. ✅ **Implement batch database inserts** (50-100 events per INSERT)
2. ✅ **Add connection pooling** (prevent connection exhaustion)
3. ✅ **Create materialized views** for common aggregations
4. ✅ **Add read replicas** for dashboard queries

#### **Phase 3: Advanced Scaling (Week 4-6)**
1. ✅ **Implement message queue** (Redis/RabbitMQ) for event processing
2. ✅ **Add Redis caching** for real-time metrics
3. ✅ **Implement dashboard query caching** (5-minute TTL)
4. ✅ **Set up monitoring** and alerting

#### **Phase 4: Production Hardening (Ongoing)**
1. ✅ **Load testing** with realistic traffic patterns
2. ✅ **Performance monitoring** and optimization
3. ✅ **Auto-scaling** configuration
4. ✅ **Disaster recovery** planning

---

### 14.9 Cost Estimation

#### **Infrastructure Costs (Monthly)**

**Small Scale (10K DAU):**
- Database: $50-100/month (Railway/Heroku)
- Compute: $50-100/month
- Redis: $20-50/month
- **Total: ~$150-250/month**

**Medium Scale (100K DAU):**
- Database: $200-500/month (managed PostgreSQL)
- Compute: $200-500/month (auto-scaling)
- Redis: $50-100/month
- **Total: ~$500-1,100/month**

**Large Scale (1M+ DAU):**
- Database: $1,000-3,000/month (managed PostgreSQL with replicas)
- Compute: $1,000-3,000/month (multiple instances)
- Redis: $200-500/month
- **Total: ~$2,200-6,500/month**

---

### 14.10 Monitoring & Alerting

#### **Key Metrics to Monitor**

**Data Ingestion:**
- Event queue depth (should be <1000)
- Event processing lag (should be <5 seconds)
- API response times (should be <200ms)
- Database write latency (should be <50ms)

**Data Analysis:**
- Query execution times (should be <500ms)
- Cache hit rates (should be >80%)
- Materialized view refresh times (should be <5 minutes)

**Infrastructure:**
- Database connection pool usage (should be <80%)
- CPU usage (should be <70%)
- Memory usage (should be <80%)
- Disk I/O (should be <80% of capacity)

**Alerting Thresholds:**
- ⚠️ **Warning**: Queue depth >500, Query time >1s, CPU >70%
- 🚨 **Critical**: Queue depth >2000, Query time >5s, CPU >90%, Database connections >90%

---

**Document Status**: Ready for Review & Discussion  
**Next Steps**: Review findings, prioritize implementation, create implementation plan

