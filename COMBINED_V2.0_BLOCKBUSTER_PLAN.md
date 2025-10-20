# 🚀 **FLAPPYJET v2.0.0 "BLOCKBUSTER" COMBINED REFACTORING PLAN**

**Date**: October 20, 2025  
**Version**: 2.0.0+50 → 2.0.0+70 (20 releases)  
**Timeline**: 8 weeks (56 days)  
**Team Size**: 1 developer (you + AI assistant)  
**Goal**: Transform FlappyJet into a 2025 blockbuster with Flame best practices + offline-first architecture

---

## 📋 **EXECUTIVE SUMMARY**

This plan combines TWO major refactorings into ONE cohesive upgrade:

### **Part A: Flame Architecture** (from previous plan)
- ✅ World + Camera component system
- ✅ Modern component lifecycle
- ✅ Proper collision detection
- ✅ Performance optimization

### **Part B: Offline-First + Event-Driven** (NEW)
- ✅ All data stored locally (Hive database)
- ✅ Fire-and-forget analytics (no blocking)
- ✅ Eventually consistent leaderboard
- ✅ Optional cloud backup (Google/Apple Sign-In)

**Why Combined?**
- 🎯 **Single disruption** for users
- 🎯 **Faster delivery** (8 weeks vs 10 weeks separate)
- 🎯 **Better architecture** (designed together from start)
- 🎯 **Less refactoring** (do it once, do it right)

---

## 🎯 **SUCCESS CRITERIA**

### **Must Have (P0):**
- ✅ Game works 100% offline (no network required for gameplay)
- ✅ All user data stored locally (progress, balance, jets, settings)
- ✅ Zero blocking operations (no network wait times)
- ✅ Analytics events fire asynchronously (fire-and-forget)
- ✅ Leaderboard updates eventually (5-15 min delay acceptable)
- ✅ No crashes, no data loss
- ✅ Same gameplay experience for endless + story mode

### **Nice to Have (P1):**
- ✅ Optional Google/Apple Sign-In (cloud backup)
- ✅ Advanced analytics dashboard (Railway backend)
- ✅ Camera shake effects
- ✅ Improved particle effects

### **Future (P2):**
- 🔮 Social features (friend challenges)
- 🔮 Live tournaments
- 🔮 Clan system

---

## 📦 **DELIVERABLES**

### **Client-Side (Flutter/Flame):**
1. ✅ Refactored game architecture (World + Camera)
2. ✅ Local database (Hive) for all user data
3. ✅ Event service (buffered, async)
4. ✅ Offline-first leaderboard (cached, periodic sync)
5. ✅ Optional sign-in system (Google/Apple)

### **Backend (Railway Pro + Firebase):**
1. ✅ Event ingestion API (bulk events)
2. ✅ Event processing pipeline (Bull + Redis queue)
3. ✅ Leaderboard aggregation system
4. ✅ Analytics dashboard (basic metrics)
5. ✅ Firebase Firestore (cloud backup for signed-in users)

### **Documentation:**
1. ✅ Architecture documentation
2. ✅ API documentation
3. ✅ Migration guide
4. ✅ Testing guide

---

## 🗓️ **8-WEEK TIMELINE**

```
Week 1-2: Foundation (Flame + Local Storage)
Week 3-4: Event System + Backend API
Week 5-6: Leaderboard + Analytics
Week 7: Optional Sign-In + Cloud Backup
Week 8: Testing + Polish + Launch
```

---

## 📅 **DETAILED WEEKLY BREAKDOWN**

### **WEEK 1: FLAME FOUNDATION + LOCAL STORAGE SETUP** (Oct 20-26)

**Goal**: Establish core architecture foundation

#### **Day 1-2: Complete Flame World + Camera Integration**
- [x] Task 1.1: FlappyWorld created ✅
- [x] Task 1.2: FlappyCamera created ✅
- [ ] Task 1.3: Integrate World + Camera into FlappyGame
  - Modify `onLoad()` to create World + Camera
  - Update `_createGameComponents()` to add to World
  - Test endless mode + story mode
  - Test all 3 objective types
- [ ] Task 1.4: Update all component references
  - Replace `_jet` with `world.player`
  - Replace `_background` with `world.background`
  - Update `ObstacleManager` to use World
  - Update collision system references
  - **Estimated**: 12 hours

**Test Checklist**:
- [ ] Endless mode works
- [ ] Story mode works (all 3 objectives)
- [ ] Collisions work correctly
- [ ] HUD updates correctly
- [ ] Background scrolls correctly

#### **Day 3-4: Setup Local Database (Hive)**
- [ ] Task 1.5: Install and configure Hive
  - Add `hive: ^2.2.3` and `hive_flutter: ^1.1.0`
  - Create Hive initialization
  - Define data models (TypeAdapters)
- [ ] Task 1.6: Create local storage services
  - `LocalUserDataService` (progress, balance, gems)
  - `LocalInventoryService` (jets, skins, purchases)
  - `LocalSettingsService` (audio, theme, preferences)
  - `LocalLeaderboardCache` (top 15, last update time)
- [ ] Task 1.7: Migrate SharedPreferences to Hive
  - Copy existing data to Hive
  - Remove SharedPreferences dependencies
  - **Estimated**: 14 hours

**Test Checklist**:
- [ ] All data migrates correctly
- [ ] Data persists after app restart
- [ ] No data loss during migration

#### **Day 5: Remove Backend Dependencies from Gameplay**
- [ ] Task 1.8: Audit all backend calls in game loop
  - Identify all `http` requests during gameplay
  - Move to async queues or remove entirely
- [ ] Task 1.9: Make gameplay fully offline
  - Score submission → Event queue (async)
  - Leaderboard fetch → Local cache (async update)
  - Tournament standings → Local cache (async update)
  - **Estimated**: 8 hours

**Test Checklist**:
- [ ] Game works in airplane mode
- [ ] No blocking network calls
- [ ] Gameplay feels instant (no lag)

**Week 1 Deliverable**: Flame architecture integrated + Local storage working + Gameplay 100% offline

---

### **WEEK 2: EVENT SERVICE FOUNDATION** (Oct 27 - Nov 2)

**Goal**: Build fire-and-forget event system

#### **Day 1-2: Create Event Service (Client)**
- [ ] Task 2.1: Design event schema
  ```dart
  class GameEvent {
    String eventId;          // UUID
    String userId;           // Device UUID
    String eventType;        // "level_completed", "game_started", etc.
    DateTime timestamp;      // ISO 8601
    Map<String, dynamic> eventData;  // Event-specific data
    Map<String, dynamic> deviceInfo; // OS, app version, country
    Map<String, dynamic> userState;  // Total score, level, gems, etc.
  }
  ```
- [ ] Task 2.2: Create `EventService` class
  - Queue events locally (Hive)
  - Batch send when online (every 30 seconds or 50 events)
  - Retry failed sends (exponential backoff)
  - **Estimated**: 10 hours

#### **Day 3-4: Instrument Game with Events**
- [ ] Task 2.3: Add events to gameplay
  - `game_started` (endless/story mode)
  - `game_ended` (score, duration, obstacles passed)
  - `level_started` (story mode)
  - `level_completed` (story mode, objective type)
  - `level_failed` (story mode)
  - `obstacle_passed`
  - `collision` (obstacle/ground/ceiling)
  - `continue_used` (ad/gems)
- [ ] Task 2.4: Add events to UI
  - `screen_viewed` (homepage, leaderboard, shop, etc.)
  - `button_clicked` (play, shop, settings, etc.)
  - `purchase_initiated` (gems, skins, premium)
  - `purchase_completed`
  - `ad_viewed` (rewarded, interstitial)
  - **Estimated**: 12 hours

#### **Day 5: Test Event System**
- [ ] Task 2.5: Create event testing tool
  - View queued events in debug mode
  - Manual event send trigger
  - Event validation tool
- [ ] Task 2.6: Test offline + online scenarios
  - Play offline → Events queue locally
  - Go online → Events batch send
  - Verify events on backend (logs)
  - **Estimated**: 6 hours

**Test Checklist**:
- [ ] Events queue locally when offline
- [ ] Events send when online
- [ ] No events lost
- [ ] No blocking during gameplay

**Week 2 Deliverable**: Event system working + All gameplay instrumented + Async event sending

---

### **WEEK 3: BACKEND EVENT API + PROCESSING** (Nov 3-9)

**Goal**: Build Railway backend to receive and process events

#### **Day 1-2: Event Ingestion API**
- [ ] Task 3.1: Create Express.js API
  - `POST /api/events` (bulk event submission)
  - Rate limiting (100 events/min per user)
  - Event validation (schema check)
  - Response: `{ success: true, eventsReceived: 50 }`
- [ ] Task 3.2: Setup Bull + Redis queue
  - Event queue (high priority)
  - Processing queue (background)
  - Dead letter queue (failed events)
  - **Estimated**: 12 hours

#### **Day 3-4: Event Processing Workers**
- [ ] Task 3.3: Create event processor
  - Parse events
  - Validate data integrity
  - Store in Postgres (partitioned by date)
  - Handle malformed events (log + discard)
- [ ] Task 3.4: Create event aggregators
  - Leaderboard aggregator (scores)
  - Tournament aggregator (weekly scores)
  - Analytics aggregator (daily metrics)
  - **Estimated**: 14 hours

#### **Day 5: Database Schema + Optimization**
- [ ] Task 3.5: Design Postgres schema
  ```sql
  -- Events table (partitioned by day)
  CREATE TABLE events_YYYYMMDD (
    event_id UUID PRIMARY KEY,
    user_id UUID NOT NULL,
    event_type VARCHAR(50) NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL,
    event_data JSONB,
    device_info JSONB,
    user_state JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
  );
  CREATE INDEX idx_user_id ON events_YYYYMMDD(user_id);
  CREATE INDEX idx_event_type ON events_YYYYMMDD(event_type);
  CREATE INDEX idx_timestamp ON events_YYYYMMDD(timestamp);

  -- Leaderboard table
  CREATE TABLE leaderboard (
    user_id UUID PRIMARY KEY,
    nickname VARCHAR(50),
    best_score INT NOT NULL,
    total_games INT DEFAULT 0,
    last_updated TIMESTAMPTZ DEFAULT NOW()
  );
  CREATE INDEX idx_best_score ON leaderboard(best_score DESC);
  ```
- [ ] Task 3.6: Setup daily partition creation (cron job)
  - **Estimated**: 8 hours

**Test Checklist**:
- [ ] API accepts events
- [ ] Events queue correctly
- [ ] Workers process events
- [ ] Data stored in Postgres

**Week 3 Deliverable**: Backend API working + Event processing pipeline + Database schema

---

### **WEEK 4: LEADERBOARD SYSTEM (EVENTUALLY CONSISTENT)** (Nov 10-16)

**Goal**: Replace real-time leaderboard with eventually consistent system

#### **Day 1-2: Leaderboard Aggregation**
- [ ] Task 4.1: Create leaderboard worker
  - Runs every 5 minutes (cron)
  - Processes `game_ended` events
  - Updates `leaderboard` table
  - Checks for new high scores
  - Validates scores (anti-cheat)
- [ ] Task 4.2: Anti-cheat validation
  - Max humanly possible score: 500 obstacles
  - Flag scores > 500 for review
  - Ban repeat offenders (device ID)
  - **Estimated**: 12 hours

#### **Day 3-4: Leaderboard API**
- [ ] Task 4.3: Create leaderboard endpoints
  - `GET /api/leaderboard/global?limit=15` (top 15)
  - `GET /api/leaderboard/user/:userId` (user rank)
  - Response includes: `{ rank, nickname, score, lastUpdated }`
- [ ] Task 4.4: Client-side leaderboard service
  - Fetch leaderboard every 5 minutes (background)
  - Cache locally (Hive)
  - Display cache if offline
  - Show "Last updated X mins ago"
  - **Estimated**: 12 hours

#### **Day 5: Tournament System**
- [ ] Task 4.5: Weekly tournament aggregation
  - Runs every hour (cron)
  - Aggregates weekly scores (Monday-Sunday)
  - Stores in `tournaments` table
  - Calculates winners (top 15)
- [ ] Task 4.6: Tournament rewards (Firebase Firestore)
  - Store unclaimed rewards: `/users/{userId}/rewards/`
  - Client checks on app open (async)
  - Show reward popup if unclaimed
  - **Estimated**: 10 hours

**Test Checklist**:
- [ ] Leaderboard updates after playing
- [ ] Delay is 5-15 minutes (acceptable)
- [ ] Anti-cheat flags suspicious scores
- [ ] Tournament calculates correctly

**Week 4 Deliverable**: Eventually consistent leaderboard + Tournament system + Anti-cheat

---

### **WEEK 5: FIREBASE INTEGRATION + ANALYTICS** (Nov 17-23)

**Goal**: Setup Firebase for analytics + cloud backup

#### **Day 1-2: Firebase Analytics**
- [ ] Task 5.1: Configure Firebase Analytics
  - Add Firebase SDK (already exists)
  - Configure event forwarding
  - Events send to both Firebase + Railway
- [ ] Task 5.2: Setup BigQuery export
  - Enable BigQuery export
  - Create automated reports
  - Daily/weekly/monthly aggregations
  - **Estimated**: 8 hours

#### **Day 3-4: Firebase Firestore (Cloud Backup)**
- [ ] Task 5.3: Design Firestore schema
  ```
  /users/{userId}/
    - profile: { nickname, createdAt, lastSeen }
    - gameData: { level, gems, balance, highScore }
    - inventory: { jets: [], skins: [] }
    - settings: { audio, theme, preferences }
    - rewards: { unclaimed: [] }
  ```
- [ ] Task 5.4: Create FirestoreBackupService
  - Upload user data (only for signed-in users)
  - Download user data on app open
  - Conflict resolution (server wins)
  - **Estimated**: 14 hours

#### **Day 5: Firebase Cloud Messaging (Push Notifications)**
- [ ] Task 5.5: Setup FCM
  - Configure push notifications
  - Send tournament winner notifications
  - Send daily reward notifications
  - Handle notification taps
  - **Estimated**: 8 hours

**Test Checklist**:
- [ ] Events go to Firebase
- [ ] BigQuery has data
- [ ] Firestore backup works
- [ ] Push notifications work

**Week 5 Deliverable**: Firebase Analytics + Firestore backup + Push notifications

---

### **WEEK 6: OPTIONAL SIGN-IN SYSTEM** (Nov 24-30)

**Goal**: Add Google/Apple Sign-In for cloud backup

#### **Day 1-2: Google Sign-In (Android + iOS)**
- [ ] Task 6.1: Configure Google Sign-In
  - Already exists (`google_sign_in` package)
  - Update to use Firestore backup
  - Link device UUID to Google account
- [ ] Task 6.2: Sign-In UI flow
  - "Backup to Cloud" button in settings
  - Explain benefits (restore on reinstall)
  - Show signed-in status
  - **Estimated**: 10 hours

#### **Day 3-4: Apple Sign-In (iOS only)**
- [ ] Task 6.3: Configure Apple Sign-In
  - Add `sign_in_with_apple` package
  - Configure iOS entitlements
  - Link device UUID to Apple account
- [ ] Task 6.4: Unified sign-in service
  - `AuthService` handles Google + Apple
  - Auto-restore on sign-in
  - Manual backup trigger
  - **Estimated**: 12 hours

#### **Day 5: Cloud Restore Flow**
- [ ] Task 6.5: Implement restore flow
  - On app open: Check if signed in
  - If signed in: Fetch Firestore data
  - If conflict: Show merge dialog
  - Merge strategies: Server wins, Client wins, Keep both
  - **Estimated**: 8 hours

**Test Checklist**:
- [ ] Google Sign-In works
- [ ] Apple Sign-In works
- [ ] Cloud backup works
- [ ] Restore works after reinstall
- [ ] Anonymous users unaffected

**Week 6 Deliverable**: Optional sign-in + Cloud backup + Restore flow

---

### **WEEK 7: ANALYTICS DASHBOARD + OPTIMIZATION** (Dec 1-7)

**Goal**: Create backend dashboard and optimize performance

#### **Day 1-2: Analytics Dashboard (React Admin)**
- [ ] Task 7.1: Setup React admin dashboard
  - Install `react-admin` framework
  - Connect to Railway Postgres
  - Basic authentication
- [ ] Task 7.2: Create analytics views
  - Daily Active Users (DAU)
  - Retention (1-day, 7-day, 30-day)
  - Level completion rates
  - Revenue (IAP, ads)
  - **Estimated**: 12 hours

#### **Day 3-4: Performance Optimization**
- [ ] Task 7.3: Client-side optimization
  - Reduce event payload size (compression)
  - Batch events more aggressively (100 events)
  - Implement event deduplication
- [ ] Task 7.4: Backend optimization
  - Add Redis caching (leaderboard, tournaments)
  - Optimize Postgres queries (indexes)
  - Implement connection pooling
  - **Estimated**: 12 hours

#### **Day 5: Load Testing**
- [ ] Task 7.5: Load test backend
  - Simulate 10K concurrent users
  - Simulate 1M events/day
  - Identify bottlenecks
  - Fix performance issues
  - **Estimated**: 8 hours

**Test Checklist**:
- [ ] Dashboard shows accurate data
- [ ] Backend handles 10K concurrent users
- [ ] Event processing keeps up with load
- [ ] No performance degradation

**Week 7 Deliverable**: Analytics dashboard + Optimized backend + Load tested

---

### **WEEK 8: TESTING + POLISH + LAUNCH** (Dec 8-14)

**Goal**: Comprehensive testing and launch preparation

#### **Day 1-2: Comprehensive Testing**
- [ ] Task 8.1: Functionality testing
  - Test all game modes (endless, story)
  - Test all objectives (1v1, pass X, survive Y)
  - Test all UI screens
  - Test offline mode
  - Test online mode
  - Test sign-in flow
  - Test cloud backup/restore
- [ ] Task 8.2: Edge case testing
  - Poor network conditions
  - Airplane mode
  - Background/foreground
  - App killed during gameplay
  - Low storage
  - **Estimated**: 14 hours

#### **Day 3: Bug Fixing**
- [ ] Task 8.3: Fix all critical bugs
  - P0 (blocking): Must fix
  - P1 (major): Should fix
  - P2 (minor): Nice to fix
  - **Estimated**: 8 hours

#### **Day 4: Polish + Documentation**
- [ ] Task 8.4: Visual polish
  - UI consistency check
  - Animation smoothness
  - Loading indicators
  - Error messages
- [ ] Task 8.5: Update documentation
  - Architecture doc
  - API doc (backend)
  - Migration guide (for future devs)
  - **Estimated**: 6 hours

#### **Day 5: Launch Preparation**
- [ ] Task 8.6: Prepare release
  - Version bump: 2.0.0+70
  - Release notes
  - App Store screenshots
  - Google Play listing
- [ ] Task 8.7: Deploy backend
  - Deploy Railway backend
  - Configure environment variables
  - Setup monitoring (Railway metrics)
  - **Estimated**: 6 hours

**Test Checklist**:
- [ ] All functionality works
- [ ] No critical bugs
- [ ] Performance is smooth
- [ ] Backend is stable
- [ ] Documentation complete

**Week 8 Deliverable**: v2.0.0 ready for launch! 🚀

---

## 🧪 **TESTING STRATEGY**

### **Unit Tests:**
- `EventService` (queue, batch, retry)
- `LocalUserDataService` (CRUD operations)
- `LeaderboardAggregator` (score validation)
- `FirestoreBackupService` (upload/download/merge)

### **Integration Tests:**
- Offline gameplay → Event queueing → Online sync
- Sign-in → Cloud backup → Reinstall → Restore
- Play game → Submit score → Leaderboard update (eventually)

### **End-to-End Tests:**
- Complete game session (endless mode)
- Complete level (story mode)
- Win tournament → Receive reward
- Delete app → Reinstall → Sign in → Restore data

### **Performance Tests:**
- 10K concurrent API requests
- 1M events/day processing
- Leaderboard query under 100ms
- Event batch send under 500ms

---

## 📊 **RISK MITIGATION**

### **Risk 1: Timeline Overrun**
**Mitigation**: 
- Built-in buffer (2 days per week)
- Prioritize P0 features, defer P1/P2
- Daily progress tracking

### **Risk 2: Backend Costs Exceed Budget**
**Mitigation**:
- Implement aggressive event batching
- Use Redis caching extensively
- Monitor Railway usage daily
- Set cost alerts ($100/month threshold)

### **Risk 3: Data Loss During Migration**
**Mitigation**:
- Beta test with small user group
- Implement rollback mechanism
- Keep SharedPreferences as backup for 1 month

### **Risk 4: Leaderboard Delay Frustrates Users**
**Mitigation**:
- Show "Last updated X mins ago" clearly
- Add manual refresh button
- Optimize to 5-min delay (acceptable)

### **Risk 5: Event Storm (Malicious Users)**
**Mitigation**:
- Rate limiting (100 events/min per user)
- Event validation (schema + business logic)
- Device fingerprinting + banning
- Cost alerts

---

## 💰 **COST BREAKDOWN**

### **Development Costs:**
- 8 weeks × 40 hours/week = 320 hours
- Your time: Priceless 😄

### **Infrastructure Costs:**
**Month 1-2 (Development):**
- Railway Pro: $50/month (testing with low traffic)
- Firebase: $0/month (free tier)
- **Total**: $50/month

**Month 3-6 (Growth to 5K DAU):**
- Railway Pro: $75-100/month (event processing + database)
- Firebase: $25/month (Firestore + BigQuery)
- **Total**: $100-125/month

**Month 7-12 (Growth to 20K DAU):**
- Railway Pro: $150-200/month (scaled workers + database)
- Firebase: $50-75/month (more Firestore usage)
- **Total**: $200-275/month

**Year 2 (50K+ DAU):**
- Railway Pro: $300-500/month (optimized, scaled)
- Firebase: $150-200/month (heavy usage)
- **Total**: $450-700/month

**ROI**: With 50K DAU + monetization, expect $5K-10K/month revenue → 10-20x ROI

---

## 📈 **SUCCESS METRICS**

### **Technical Metrics:**
- ✅ 100% offline gameplay (no network required)
- ✅ <100ms event queue time (instant)
- ✅ <500ms event batch send (imperceptible)
- ✅ 5-15 min leaderboard delay (industry standard)
- ✅ 99.9% uptime (backend)
- ✅ <100ms leaderboard API response

### **User Metrics:**
- ✅ Same retention as v1.7.0 (or better)
- ✅ Same engagement (session length, games/day)
- ✅ Improved loading time (no network wait)
- ✅ <1% bug reports (critical issues)

### **Business Metrics:**
- ✅ 10K+ DAU by Month 6
- ✅ 50K+ DAU by Year 2
- ✅ $500-700/month infrastructure cost (profitable)
- ✅ 10-20x ROI (revenue vs. infrastructure)

---

## 🚀 **LAUNCH CHECKLIST**

### **Pre-Launch (Week 8, Day 5):**
- [ ] All P0 bugs fixed
- [ ] All P1 bugs triaged
- [ ] Backend deployed to Railway Pro
- [ ] Firebase configured (Analytics, Firestore, FCM)
- [ ] Monitoring setup (Railway metrics, Firebase console)
- [ ] Cost alerts configured ($100/month threshold)
- [ ] Documentation complete
- [ ] App Store screenshots ready
- [ ] Release notes written

### **Launch Day:**
- [ ] Deploy backend (Railway)
- [ ] Submit to App Store (iOS)
- [ ] Submit to Google Play (Android)
- [ ] Monitor error rates (Firebase Crashlytics)
- [ ] Monitor backend performance (Railway metrics)
- [ ] Monitor user feedback (reviews, support)

### **Post-Launch (Week 1-4):**
- [ ] Daily monitoring (errors, crashes, performance)
- [ ] Weekly analytics review (DAU, retention, engagement)
- [ ] Monthly cost review (Railway, Firebase)
- [ ] User feedback analysis (reviews, support tickets)
- [ ] Hotfix critical bugs within 24 hours

---

## 🎯 **NEXT STEPS (RIGHT NOW!)**

Based on your answers:
1. ✅ Data loss acceptable
2. ✅ Leaderboard delay acceptable
3. ✅ Combined refactoring (8 weeks)
4. ✅ Railway Pro sufficient
5. ✅ UUID (not ADID) + optional sign-in
6. ✅ Priority C (both architecture + UX)

**Let's start Week 1, Day 1-2: Complete Flame World + Camera Integration!**

I've already completed:
- ✅ Task 1.1: FlappyWorld created
- ✅ Task 1.2: FlappyCamera created

**Next**: Task 1.3 - Integrate World + Camera into FlappyGame

**Ready to continue?** 🚀

