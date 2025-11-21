# 🧪 PUSH NOTIFICATION TESTING STRATEGY

## 🎯 Goal: Comprehensive testing without breaking production

---

## 🛠️ TESTING TOOLS I'LL BUILD

### 1. **Admin Test Endpoints** (Backend)

**POST `/api/test/push/send-immediate`**
- Manually trigger push notification to specific user
- Choose notification type (1hour, 24hour, 46hour)
- Choose message variant (friendly_A, casual_B, professional_C)
- Choose reward (100 coins, 10 gems, or none)

```bash
curl -X POST https://flappyjet-backend.railway.app/api/test/push/send-immediate \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "test_user_123",
    "notification_type": "1hour",
    "message_variant": "friendly_A",
    "reward_type": "coins",
    "reward_amount": 100
  }'
```

**POST `/api/test/push/schedule-all`**
- Schedule all 3 notifications for a test user
- With custom delays (e.g., 30 seconds instead of 1 hour)

```bash
curl -X POST https://flappyjet-backend.railway.app/api/test/push/schedule-all \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "test_user_123",
    "delays": [30, 60, 90]  // seconds instead of hours
  }'
```

**GET `/api/test/push/status/:user_id`**
- Check notification status for a user
- See scheduled, sent, clicked notifications
- View FCM token registration status

---

### 2. **Debug Dashboard** (Frontend)

**New page: `/test/notifications`**

Features:
- List all registered FCM tokens
- Show recent notification events
- Button to send test notification to yourself
- Real-time notification event stream
- Test notification scheduling (30s, 60s, 90s)
- A/B test different message variants

---

### 3. **Flutter Debug Menu** (In-App)

**New screen in Settings:**

"🧪 Notification Testing" (only visible in debug mode)

Buttons:
- "Schedule Test Notifications" (30s, 60s, 90s delays)
- "Clear All Pending Notifications"
- "Show FCM Token"
- "Simulate App Background"
- "Test Reward Popup (100 coins)"
- "Test Reward Popup (10 gems)"
- "View Notification Logs"

---

### 4. **Automated Tests**

**Unit Tests:**
```dart
test_notification_scheduling_test.dart
test_message_template_test.dart
test_quiet_hours_test.dart
test_reward_logic_test.dart
```

**Integration Tests:**
```dart
test_fcm_token_registration_test.dart
test_notification_tracking_test.dart
test_background_trigger_test.dart
```

**E2E Tests:**
```dart
test_full_notification_flow_test.dart
  1. User plays game
  2. User backgrounds app
  3. Notifications scheduled
  4. Wait 30s (fast-forwarded)
  5. Notification appears
  6. User clicks notification
  7. App opens to reward popup
  8. User claims reward
  9. Verify coins/gems added
```

---

## 📋 TESTING PHASES

### Phase 1: Local Development Testing (You + Me)

**Environment:** Android Emulator / Physical Device

**Tests:**
1. ✅ FCM token registration
2. ✅ Local notification scheduling
3. ✅ Notification appearance (title, body, icon)
4. ✅ Notification click → App opens
5. ✅ Reward popup displays
6. ✅ Rewards added to user balance
7. ✅ Event tracking (scheduled, sent, clicked)
8. ✅ Message variants (friendly, casual, professional)
9. ✅ Quiet hours (10 PM - 8 AM block)
10. ✅ Daily limit (max 3 per day)

**Timeline:** 2 days

---

### Phase 2: Staging Environment (Railway Test)

**Environment:** Railway backend + Test build

**Tests:**
1. ✅ Backend FCM token storage
2. ✅ Backup FCM sending (cron job)
3. ✅ Dashboard analytics display
4. ✅ Country-based analytics
5. ✅ Notification event tracking
6. ✅ Error handling (invalid token, etc.)
7. ✅ Load testing (100+ users)

**Timeline:** 1 day

---

### Phase 3: Beta Testing (10% of Real Users)

**Environment:** Production with feature flag

**Implementation:**
```dart
// Feature flag in Firebase Remote Config
final enablePushNotifications = RemoteConfig.instance.getBool('enable_push_notifications');

if (enablePushNotifications) {
  await NotificationManager().initialize();
}
```

**Metrics to Monitor:**
- FCM token registration rate
- Notification delivery rate (should be >95%)
- Click-through rate (should be >10%)
- App crashes (should be 0 increase)
- User complaints (should be minimal)
- Retention lift (comparing test vs control group)

**A/B Test Groups:**
- Control: 90% (no notifications)
- Test: 10% (with notifications)

**Timeline:** 3-4 days

---

### Phase 4: Full Rollout (100% of Users)

**If Phase 3 metrics are good:**
- ✅ CTR > 10%
- ✅ No crash rate increase
- ✅ Retention lift detected
- ✅ User feedback positive

**Then:**
- Enable for 50% of users
- Monitor for 2 days
- Enable for 100% of users

**Timeline:** 1 week

---

## 🎮 MANUAL TESTING SCENARIOS

### Scenario 1: Happy Path
1. User plays game (completes Level 3)
2. User closes app (home button)
3. **After 1 hour:** Notification appears
   - Title: "Quick! Your jet is ready! 🚀"
   - Body: "Pilot, level 4 is waiting for you!"
4. User clicks notification
5. App opens to reward popup:
   - "Welcome back! Here's 100 coins! 💰"
6. User claims reward
7. Verify: User has +100 coins
8. User can continue playing

### Scenario 2: Quiet Hours
1. User closes app at 9:30 PM
2. 1-hour notification should wait until 8:00 AM
3. Notification appears at 8:00 AM (not 10:30 PM)

### Scenario 3: Already Returned
1. User closes app
2. Notification scheduled for 1 hour
3. User opens app after 30 minutes (before notification)
4. Notification should be cancelled
5. No notification appears

### Scenario 4: Multiple Notifications
1. User closes app
2. 1-hour notification scheduled
3. User doesn't open app
4. 24-hour notification scheduled
5. User still doesn't open app
6. 46-hour notification scheduled
7. User opens app from 46-hour notification
8. Gets special "comeback" reward (10 gems)

### Scenario 5: Daily Limit
1. User closes app 5 times in one day
2. Only 3 notifications are sent (max limit)
3. Other notifications are skipped
4. Next day, limit resets

---

## 🐛 EDGE CASES TO TEST

### Device/System:
- [ ] Battery saver mode enabled
- [ ] Do Not Disturb mode enabled
- [ ] Notification permission denied
- [ ] App is uninstalled (token cleanup)
- [ ] App is force-stopped
- [ ] Device is offline (notification queued)
- [ ] Multiple devices for same user
- [ ] Android versions: 10, 11, 12, 13, 14

### App State:
- [ ] App is in foreground (no notification)
- [ ] App is in background
- [ ] App is killed by system
- [ ] User is already in-game when notification arrives
- [ ] User opens app from notification while in-game

### Notification System:
- [ ] FCM token refresh
- [ ] Invalid FCM token (send fails)
- [ ] Network error during send
- [ ] User has no FCM token (fallback to local only)
- [ ] Notification is dismissed (not clicked)
- [ ] Notification channel is disabled

### Rewards:
- [ ] User already has max coins (999,999)
- [ ] User already has max gems (99,999)
- [ ] Reward popup is dismissed without claiming
- [ ] User claims reward twice (should prevent duplicate)

---

## 📊 SUCCESS METRICS

### Technical Metrics:
- **FCM token registration:** >98% of users
- **Notification delivery:** >95% success rate
- **App crash rate:** No increase
- **Battery usage:** No significant increase

### Business Metrics:
- **Click-through rate:**
  - 1 hour: >15%
  - 24 hours: >10%
  - 46 hours: >5%
- **Retention lift:**
  - Day 1: +10-15%
  - Day 2: +8-12%
- **User complaints:** <1%
- **Opt-out rate:** <5%

---

## 🚨 ROLLBACK PLAN

**If things go wrong:**

**Immediate Rollback (< 5 minutes):**
1. Set Firebase Remote Config: `enable_push_notifications = false`
2. All apps will stop scheduling notifications
3. Monitor metrics for 1 hour

**Partial Rollback:**
1. Reduce test group from 10% to 1%
2. Investigate issues
3. Fix and redeploy

**Full Rollback:**
1. Remove notification scheduling code
2. Keep tracking infrastructure (for future)
3. Disable backend cron jobs

---

## 🎯 TESTING CHECKLIST

Before Production Launch:

**Flutter App:**
- [ ] Notification permissions requested correctly
- [ ] FCM token registered on app start
- [ ] Local notifications schedule on background
- [ ] Notification click opens app correctly
- [ ] Reward popup displays beautifully
- [ ] Rewards are added to user balance
- [ ] Event tracking works (EventBus)
- [ ] Quiet hours respected (10 PM - 8 AM)
- [ ] Daily limit enforced (max 3)
- [ ] Message variants randomized
- [ ] No memory leaks
- [ ] No battery drain

**Backend:**
- [ ] FCM token API works
- [ ] Notification tracking API works
- [ ] Backup FCM sending works (cron)
- [ ] Dashboard displays metrics correctly
- [ ] Country analytics work
- [ ] Error handling robust
- [ ] Load tested (1000+ users)
- [ ] Firebase Admin SDK configured
- [ ] Database queries optimized
- [ ] Redis caching works

**Dashboard:**
- [ ] New "Push Notifications" section added
- [ ] Sent count accurate
- [ ] Clicked count accurate
- [ ] CTR calculated correctly
- [ ] Country breakdown works
- [ ] Charts render properly
- [ ] Real-time updates work

**Tests:**
- [ ] All unit tests pass
- [ ] All integration tests pass
- [ ] All E2E tests pass
- [ ] Manual testing complete
- [ ] Edge cases verified
- [ ] Performance acceptable

---

## 🎉 READY TO BUILD!

Once you complete the database migration, I'll build:

1. **All testing endpoints** for easy manual testing
2. **Debug dashboard** for monitoring
3. **In-app debug menu** for testing
4. **Automated tests** (unit, integration, E2E)
5. **Complete push notification system**

**Let me know when database migration is done!** ✅

Then I'll start building everything! 🚀

