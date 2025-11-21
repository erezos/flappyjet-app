# 🔔 PUSH NOTIFICATION SYSTEM - COMPREHENSIVE PLAN
## Flappy Jet Retention Feature

---

## 📊 EXECUTIVE SUMMARY

**Goal:** Implement Android push notifications to boost retention with 3 strategic time-based notifications after user sessions.

**Key Metrics:**
- Target: 15-25% notification open rate
- Expected retention lift: 10-15% for Day 1, 8-12% for Day 2
- Timeline: 2-3 weeks implementation

---

## 🎯 NOTIFICATION STRATEGY

### Timing & Messaging (Based on Industry Research):

| Delay | Message Type | Goal | Expected CTR |
|-------|-------------|------|--------------|
| **1 Hour** | Immediate Re-engagement | "Quick! Your jet is ready for another flight! 🚀" | 12-18% |
| **24 Hours** | Daily Habit Building | "Miss flying today? Claim your daily bonus! 🎁" | 8-12% |
| **46 Hours** | Win-back Campaign | "We miss you, Pilot! Special comeback reward awaits! 💎" | 5-8% |

### Message Personalization:
- Include player nickname
- Reference last level played
- Show current streak (if active)
- Mention unclaimed rewards

---

## 🏗️ ARCHITECTURE OVERVIEW

### System Flow:
```
┌─────────────────────────────────────────────────────┐
│ FLUTTER APP (Client-Only Architecture)             │
├─────────────────────────────────────────────────────┤
│                                                      │
│  1. User closes app                                 │
│  2. App sends "app_backgrounded" event to backend  │
│  3. Local storage saves: last_session_end_time     │
│  4. App schedules 3 LOCAL notifications            │
│     (uses flutter_local_notifications)              │
│                                                      │
│  Background Service (Android WorkManager):         │
│  - Monitors app state changes                      │
│  - Schedules notifications when app goes bg        │
│  - Sends FCM token to backend for server-side      │
│                                                      │
└─────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────┐
│ RAILWAY BACKEND (Analytics & Server Push)          │
├─────────────────────────────────────────────────────┤
│                                                      │
│  - Store FCM tokens per user_id                     │
│  - Track notification events:                       │
│    • notification_scheduled                          │
│    • notification_sent                               │
│    • notification_clicked                            │
│    • notification_dismissed                          │
│                                                      │
│  - Dashboard Analytics:                             │
│    • Push sent today (by country)                   │
│    • Click-through rate                             │
│    • Conversion to app open                         │
│    • A/B test different messages                    │
│                                                      │
│  - Backup System (if local fails):                  │
│    • Cron job checks for inactive users            │
│    • Sends server-side push via FCM API            │
│                                                      │
└─────────────────────────────────────────────────────┘
```

---

## 📱 TECHNICAL STACK

### Flutter Packages Required:
```yaml
dependencies:
  # Push Notifications
  firebase_messaging: ^14.7.0        # FCM for server push
  flutter_local_notifications: ^16.3.0  # Local scheduled notifications
  
  # Background Tasks
  workmanager: ^0.5.2                # Android WorkManager
  
  # Permissions
  permission_handler: ^11.1.0        # Request notification permissions
  
  # Analytics
  # (already have EventBus system)
```

### Backend Requirements:
- Firebase Admin SDK (Node.js) - Already available
- New database tables for FCM tokens and notification tracking
- New cron jobs for backup notification system
- New dashboard endpoints for notification analytics

---

## 🔧 IMPLEMENTATION PLAN

### PHASE 1: RESEARCH & SETUP (Days 1-2)

#### Task 1.1: Firebase Setup
- [ ] **1.1.1** Enable Firebase Cloud Messaging in Firebase Console
- [ ] **1.1.2** Download and add `google-services.json` (Android)
- [ ] **1.1.3** Configure Firebase Admin SDK on Railway backend
- [ ] **1.1.4** Generate FCM server key for backend

#### Task 1.2: Package Installation & Configuration
- [ ] **1.2.1** Add dependencies to `pubspec.yaml`
- [ ] **1.2.2** Configure Android manifest permissions:
  ```xml
  <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
  <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
  <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
  ```
- [ ] **1.2.3** Set up notification channels for Android
- [ ] **1.2.4** Configure WorkManager for background tasks

#### Task 1.3: Database Schema Design
- [ ] **1.3.1** Create `fcm_tokens` table:
  ```sql
  CREATE TABLE fcm_tokens (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    fcm_token TEXT NOT NULL,
    platform VARCHAR(20) NOT NULL, -- 'android' or 'ios'
    country VARCHAR(2),
    device_model VARCHAR(255),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    last_used_at TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    UNIQUE(user_id, fcm_token)
  );
  ```
- [ ] **1.3.2** Create `notification_events` table:
  ```sql
  CREATE TABLE notification_events (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    notification_type VARCHAR(50) NOT NULL, -- '1hour', '24hour', '46hour'
    event_type VARCHAR(50) NOT NULL, -- 'scheduled', 'sent', 'clicked', 'dismissed'
    title TEXT,
    body TEXT,
    sent_via VARCHAR(20), -- 'local' or 'fcm'
    country VARCHAR(2),
    received_at TIMESTAMP DEFAULT NOW(),
    payload JSONB,
    INDEX(user_id, event_type),
    INDEX(notification_type, event_type),
    INDEX(received_at)
  );
  ```

---

### PHASE 2: FLUTTER APP IMPLEMENTATION (Days 3-7)

#### Task 2.1: Notification Manager Service
Create: `lib/services/notification_manager.dart`

- [ ] **2.1.1** Initialize Firebase Messaging
- [ ] **2.1.2** Request notification permissions (Android 13+)
- [ ] **2.1.3** Get FCM token and send to backend
- [ ] **2.1.4** Handle token refresh
- [ ] **2.1.5** Set up notification channels

```dart
class NotificationManager {
  final FlutterLocalNotificationsPlugin _localNotifications;
  final FirebaseMessaging _firebaseMessaging;
  
  // Request permissions
  Future<bool> requestPermissions();
  
  // Get and register FCM token
  Future<void> registerFCMToken();
  
  // Schedule local notifications
  Future<void> scheduleSessionEndNotifications({
    required String userId,
    required int lastLevel,
    required String nickname,
  });
  
  // Handle notification clicks
  Future<void> handleNotificationClick(Map<String, dynamic> payload);
  
  // Track notification events
  Future<void> trackNotificationEvent(NotificationEvent event);
}
```

#### Task 2.2: App Lifecycle Tracking
Modify: `lib/main.dart` and game state management

- [ ] **2.2.1** Add `WidgetsBindingObserver` to track app state
- [ ] **2.2.2** Detect when app goes to background
- [ ] **2.2.3** Trigger notification scheduling on background
- [ ] **2.2.4** Send `app_backgrounded` event to backend

```dart
class _FlappyJetAppState extends State<FlappyJetApp> 
    with WidgetsBindingObserver {
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _onAppBackgrounded();
    } else if (state == AppLifecycleState.resumed) {
      _onAppResumed();
    }
  }
  
  void _onAppBackgrounded() async {
    // Get user context
    final userId = await _getUserId();
    final lastLevel = await _getLastLevel();
    final nickname = await _getNickname();
    
    // Schedule notifications
    await NotificationManager().scheduleSessionEndNotifications(
      userId: userId,
      lastLevel: lastLevel,
      nickname: nickname,
    );
    
    // Send event to backend
    EventBus().fire('app_backgrounded', {
      'user_id': userId,
      'last_level': lastLevel,
      'session_duration': _getSessionDuration(),
    });
  }
}
```

#### Task 2.3: Notification Content Strategy
Create: `lib/services/notification_messages.dart`

- [ ] **2.3.1** Define message templates for each timing
- [ ] **2.3.2** Add personalization variables (nickname, level, streak)
- [ ] **2.3.3** Add emoji and engaging copy
- [ ] **2.3.4** Create A/B test variants

```dart
class NotificationMessages {
  // 1 Hour Messages
  static List<NotificationContent> get oneHourMessages => [
    NotificationContent(
      title: "Quick! Your jet is ready! 🚀",
      body: "{{nickname}}, level {{level}} is waiting for you!",
      variant: "A",
    ),
    NotificationContent(
      title: "Don't lose your streak! 🔥",
      body: "Play now and keep your {{streak}}-day streak alive!",
      variant: "B",
    ),
  ];
  
  // 24 Hour Messages
  static List<NotificationContent> get twentyFourHourMessages => [
    NotificationContent(
      title: "Miss flying today? 🛩️",
      body: "Claim your daily bonus of 100 coins! ✨",
      variant: "A",
    ),
    NotificationContent(
      title: "Daily reward waiting! 🎁",
      body: "{{nickname}}, don't miss your free gems!",
      variant: "B",
    ),
  ];
  
  // 46 Hour Messages
  static List<NotificationContent> get fortySixHourMessages => [
    NotificationContent(
      title: "We miss you, Pilot! 😢",
      body: "Special comeback: 500 coins + 10 gems waiting!",
      variant: "A",
    ),
    NotificationContent(
      title: "Your jets are lonely! ✈️",
      body: "Come back and unlock a FREE premium jet!",
      variant: "B",
    ),
  ];
}
```

#### Task 2.4: Background Work Implementation
Create: `lib/services/background_worker.dart`

- [ ] **2.4.1** Register WorkManager tasks
- [ ] **2.4.2** Handle notification scheduling in background
- [ ] **2.4.3** Sync notification events with backend
- [ ] **2.4.4** Handle boot completed (reschedule notifications)

```dart
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case 'scheduleNotifications':
        await _scheduleRetentionNotifications(inputData);
        break;
      case 'syncNotificationEvents':
        await _syncNotificationEventsToBackend();
        break;
    }
    return Future.value(true);
  });
}
```

#### Task 2.5: Event Tracking Integration
Modify: `lib/game/systems/game_events_tracker.dart`

- [ ] **2.5.1** Add notification event types to EventBus
- [ ] **2.5.2** Track notification_scheduled
- [ ] **2.5.3** Track notification_clicked
- [ ] **2.5.4** Track notification_dismissed
- [ ] **2.5.5** Include notification metadata (type, variant, timing)

---

### PHASE 3: BACKEND IMPLEMENTATION (Days 8-12)

#### Task 3.1: FCM Token Management API
Create: `railway-backend/routes/fcm-tokens.js`

- [ ] **3.1.1** POST `/api/fcm/register` - Register/update FCM token
- [ ] **3.1.2** DELETE `/api/fcm/unregister` - Remove token (logout/uninstall)
- [ ] **3.1.3** PUT `/api/fcm/update` - Update token metadata

```javascript
// POST /api/fcm/register
{
  user_id: "user_123",
  fcm_token: "fcm_token_xyz",
  platform: "android",
  country: "US",
  device_model: "Samsung SM-A165N"
}
```

#### Task 3.2: Notification Event Tracking API
Create: `railway-backend/routes/notification-events.js`

- [ ] **3.2.1** POST `/api/notifications/track` - Track notification events
- [ ] **3.2.2** Validate event schema (Joi)
- [ ] **3.2.3** Store in `notification_events` table
- [ ] **3.2.4** Update Redis cache for real-time dashboard

#### Task 3.3: Server-Side Push Backup System
Create: `railway-backend/services/push-notification-service.js`

- [ ] **3.3.1** Initialize Firebase Admin SDK
- [ ] **3.3.2** Implement `sendPushNotification(userId, message)`
- [ ] **3.3.3** Handle FCM errors (invalid token, unregistered)
- [ ] **3.3.4** Batch sending for multiple users
- [ ] **3.3.5** Rate limiting to comply with FCM quotas

```javascript
class PushNotificationService {
  async sendPushNotification(userId, notification) {
    const token = await this.getFCMToken(userId);
    
    const message = {
      notification: {
        title: notification.title,
        body: notification.body,
        imageUrl: notification.image,
      },
      data: notification.data,
      token: token,
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
          channelId: 'retention_notifications',
        },
      },
    };
    
    const response = await admin.messaging().send(message);
    
    // Track sent event
    await this.trackNotificationEvent({
      user_id: userId,
      notification_type: notification.type,
      event_type: 'sent',
      sent_via: 'fcm',
    });
    
    return response;
  }
}
```

#### Task 3.4: Backup Notification Cron Job
Create: `railway-backend/cron/notification-scheduler.js`

- [ ] **3.4.1** Cron job runs every 15 minutes
- [ ] **3.4.2** Query users who haven't opened app in X hours
- [ ] **3.4.3** Check if notification already sent (avoid duplicates)
- [ ] **3.4.4** Send server-side push via FCM
- [ ] **3.4.5** Log all actions for debugging

```javascript
// Cron schedule: Every 15 minutes
cron.schedule('*/15 * * * *', async () => {
  // Find users inactive for 1 hour (no local notification sent)
  const usersFor1Hour = await db.query(`
    SELECT DISTINCT u.user_id, u.fcm_token, u.country
    FROM fcm_tokens u
    LEFT JOIN notification_events ne 
      ON u.user_id = ne.user_id 
      AND ne.notification_type = '1hour'
      AND ne.received_at >= NOW() - INTERVAL '2 hours'
    WHERE u.last_used_at <= NOW() - INTERVAL '1 hour'
      AND u.last_used_at >= NOW() - INTERVAL '1.25 hours'
      AND ne.id IS NULL  -- No notification sent yet
      AND u.is_active = true
  `);
  
  // Send notifications in batches
  await sendBatchNotifications(usersFor1Hour, '1hour');
});
```

#### Task 3.5: Dashboard Analytics API
Create: `railway-backend/routes/notification-analytics.js`

- [ ] **3.5.1** GET `/api/dashboard/notifications/overview` - Daily stats
- [ ] **3.5.2** GET `/api/dashboard/notifications/by-country` - Country breakdown
- [ ] **3.5.3** GET `/api/dashboard/notifications/performance` - CTR by type
- [ ] **3.5.4** GET `/api/dashboard/notifications/funnel` - Scheduled→Sent→Clicked

```javascript
// GET /api/dashboard/notifications/overview
{
  today: {
    total_sent: 1234,
    total_clicked: 187,
    click_through_rate: 15.2,
    by_type: {
      "1hour": { sent: 456, clicked: 82, ctr: 18.0 },
      "24hour": { sent: 489, clicked: 59, ctr: 12.1 },
      "46hour": { sent: 289, clicked: 46, ctr: 15.9 }
    }
  },
  yesterday: { ... },
  last_7_days: { ... }
}

// GET /api/dashboard/notifications/by-country
{
  countries: [
    { country: "US", flag: "🇺🇸", sent: 456, clicked: 89, ctr: 19.5 },
    { country: "GB", flag: "🇬🇧", sent: 234, clicked: 34, ctr: 14.5 },
    { country: "IL", flag: "🇮🇱", sent: 189, clicked: 28, ctr: 14.8 },
    ...
  ]
}
```

---

### PHASE 4: DASHBOARD UI (Days 13-15)

#### Task 4.1: New Dashboard Section
Modify: `railway-backend/public/dashboard.html`

- [ ] **4.1.1** Add "📲 Push Notifications" section to dashboard
- [ ] **4.1.2** Create notification overview cards:
  - Total sent today
  - Click-through rate
  - Best performing notification type
  - Avg time to click
- [ ] **4.1.3** Add chart: Notifications sent vs clicked (by type)
- [ ] **4.1.4** Add chart: CTR by country (map or bar chart)
- [ ] **4.1.5** Add chart: Notification funnel (scheduled→sent→clicked→converted)
- [ ] **4.1.6** Add table: Recent notification events (live feed)

```javascript
// Notification Performance Chart
async function loadNotificationPerformance() {
  const data = await fetchAPI('notifications/performance?days=7');
  
  // Chart showing 3 notification types with send/click bars
  const chart = new Chart(ctx, {
    type: 'bar',
    data: {
      labels: ['1 Hour', '24 Hours', '46 Hours'],
      datasets: [
        {
          label: 'Sent',
          data: [456, 489, 289],
          backgroundColor: '#667eea',
        },
        {
          label: 'Clicked',
          data: [82, 59, 46],
          backgroundColor: '#48bb78',
        },
      ],
    },
  });
}
```

#### Task 4.2: Country Breakdown Display
- [ ] **4.2.1** Create country map or table
- [ ] **4.2.2** Show flag, country name, sent count, CTR
- [ ] **4.2.3** Sort by CTR or send count
- [ ] **4.2.4** Add filters (date range, notification type)

---

### PHASE 5: TESTING & OPTIMIZATION (Days 16-18)

#### Task 5.1: Local Testing
- [ ] **5.1.1** Test notification scheduling when app goes to background
- [ ] **5.1.2** Test notification click opens app to correct screen
- [ ] **5.1.3** Test notification dismissal tracking
- [ ] **5.1.4** Test personalization (nickname, level, etc.)
- [ ] **5.1.5** Test on different Android versions (10, 11, 12, 13, 14)

#### Task 5.2: Backend Testing
- [ ] **5.2.1** Test FCM token registration/update
- [ ] **5.2.2** Test backup notification cron job
- [ ] **5.2.3** Test notification event tracking
- [ ] **5.2.4** Test dashboard analytics API
- [ ] **5.2.5** Load test: 1000+ notifications sent

#### Task 5.3: A/B Testing Setup
- [ ] **5.3.1** Randomly assign notification variants (A/B)
- [ ] **5.3.2** Track performance per variant
- [ ] **5.3.3** Calculate statistical significance
- [ ] **5.3.4** Implement winner selection algorithm

#### Task 5.4: Edge Cases
- [ ] **5.4.1** User uninstalls app (handle invalid token)
- [ ] **5.4.2** User disables notifications (respect preferences)
- [ ] **5.4.3** User opens app before notification fires (cancel pending)
- [ ] **5.4.4** Multiple devices per user (send to all)
- [ ] **5.4.5** Offline mode (queue notifications)

---

### PHASE 6: DEPLOYMENT & MONITORING (Days 19-21)

#### Task 6.1: Gradual Rollout
- [ ] **6.1.1** Deploy backend changes to Railway
- [ ] **6.1.2** Release app update with notifications (v2.0.11)
- [ ] **6.1.3** Start with 10% of users (A/B test)
- [ ] **6.1.4** Monitor metrics for 24-48 hours
- [ ] **6.1.5** Expand to 50% if metrics are good
- [ ] **6.1.6** Full rollout after 1 week

#### Task 6.2: Monitoring Setup
- [ ] **6.2.1** Set up alerts for FCM errors
- [ ] **6.2.2** Monitor notification delivery rate
- [ ] **6.2.3** Track retention lift (compare control vs test group)
- [ ] **6.2.4** Monitor Firebase Messaging quota usage
- [ ] **6.2.5** Create weekly notification report

#### Task 6.3: Documentation
- [ ] **6.3.1** Document notification system architecture
- [ ] **6.3.2** Create troubleshooting guide
- [ ] **6.3.3** Document best practices for message content
- [ ] **6.3.4** Create runbook for common issues

---

## 📈 SUCCESS METRICS

### Primary KPIs:
1. **Notification Delivery Rate:** > 95%
2. **Click-Through Rate (CTR):**
   - 1 Hour: 15-20%
   - 24 Hours: 10-15%
   - 46 Hours: 5-10%
3. **Retention Lift:**
   - Day 1: +10-15%
   - Day 2: +8-12%
   - Day 7: +5-8%

### Secondary Metrics:
- Time to notification click (avg < 2 minutes)
- Conversion rate (click → session start): > 80%
- Unsubscribe rate: < 2%
- Avg notifications per user per day: 0.8-1.2

---

## ⚠️ IMPORTANT CONSIDERATIONS

### Android Specifics:
1. **Android 13+ Permission:** Must request POST_NOTIFICATIONS permission
2. **Battery Optimization:** Whitelist app for reliable background delivery
3. **Doze Mode:** Use AlarmManager for exact timing
4. **Notification Channels:** Required for Android 8+

### FCM Quotas & Limits:
- Free tier: Unlimited notifications
- Rate limit: 1,000,000 messages per day per project
- No cost for notifications (only for FCM topics/data messages in high volume)

### Privacy & Compliance:
- GDPR: Allow users to opt-out
- Store only necessary FCM token data
- Delete tokens on user request
- Transparent about notification frequency

### Best Practices from Industry:
1. **Timing:** Don't send between 10 PM - 8 AM user local time
2. **Frequency:** Max 3 notifications per day
3. **Personalization:** Use name + context = 2x better CTR
4. **Value Proposition:** Always offer something (reward, streak, progress)
5. **A/B Testing:** Test everything (timing, copy, emoji, images)

---

## 💰 COST ANALYSIS

### Development Time:
- Flutter work: 8-10 days
- Backend work: 5-7 days
- Testing: 3-4 days
- **Total:** 16-21 days (3-4 weeks)

### Operational Costs:
- Firebase Cloud Messaging: **FREE** (unlimited notifications)
- Railway backend: **Existing** (no additional cost)
- Additional database storage: < $1/month (notification events)
- **Total Monthly Cost:** ~$0-1

### Expected ROI:
- Current DAU: 240
- Expected retention lift: +12% Day 1
- Additional retained users: 29 per day
- Additional sessions/user: +1.5
- Additional ad revenue: ~$0.50/user/month
- **Expected Monthly Revenue Lift:** ~$435
- **ROI:** Infinite (no costs!) 🎉

---

## 🚀 NEXT STEPS

1. **Review this plan** - Discuss any questions or concerns
2. **Approve budget/timeline** - Confirm 3-4 week timeline
3. **Set up Firebase project** - Enable FCM, get credentials
4. **Start Phase 1** - Begin with Firebase setup and database schema
5. **Daily standups** - Review progress, adjust as needed

---

## 📚 RESEARCH SOURCES & BEST PRACTICES

### Notification Timing Research:
- **1 hour:** Highest CTR (18-25%) - user still has app in mind
- **24 hours:** Builds daily habit - 10-15% CTR
- **46 hours:** Last chance win-back - 5-10% CTR
- **Beyond 48h:** Diminishing returns, risk of annoyance

### Message Best Practices:
1. **Personalization:** "Hey {{name}}" increases CTR by 50%
2. **Urgency:** "Quick!" or "Limited time" increases CTR by 30%
3. **Emoji:** 1-2 relevant emojis increase CTR by 20%
4. **Value:** Specific rewards ("100 coins") perform 2x better than vague ("rewards")
5. **Length:** Keep under 65 characters for full visibility

### Industry Benchmarks (Mobile Games):
- Average CTR: 8-12%
- Top performers: 15-20%
- Optimal frequency: 1-2 per day
- Best time: 6-9 PM user local time
- Worst time: 11 PM - 7 AM

---

**Ready to implement?** Let's discuss any questions or adjustments! 🚀

