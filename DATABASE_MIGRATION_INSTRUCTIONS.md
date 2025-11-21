# 📊 DATABASE MIGRATION - COPY & PASTE FOR RAILWAY CLI

## 🎯 Instructions:

1. Go to Railway dashboard
2. Select your PostgreSQL database
3. Click "Connect" → "PostgreSQL CLI"
4. Copy and paste the **ENTIRE SQL BLOCK** below
5. Press Enter
6. Verify success messages

---

## 📋 SQL TO RUN (Copy Everything Below):

```sql
-- ============================================================================
-- PUSH NOTIFICATIONS SCHEMA MIGRATION
-- Railway Backend - FlappyJet
-- ============================================================================

-- 1. FCM TOKENS TABLE
CREATE TABLE IF NOT EXISTS fcm_tokens (
  id SERIAL PRIMARY KEY,
  user_id VARCHAR(255) NOT NULL,
  fcm_token TEXT NOT NULL,
  platform VARCHAR(20) NOT NULL CHECK (platform IN ('android', 'ios')),
  country VARCHAR(2),
  timezone VARCHAR(50),
  device_model VARCHAR(255),
  os_version VARCHAR(50),
  app_version VARCHAR(20),
  is_active BOOLEAN DEFAULT true,
  last_notification_sent_at TIMESTAMP,
  last_notification_clicked_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  last_used_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, fcm_token)
);

CREATE INDEX idx_fcm_tokens_user_id ON fcm_tokens(user_id);
CREATE INDEX idx_fcm_tokens_active ON fcm_tokens(is_active) WHERE is_active = true;
CREATE INDEX idx_fcm_tokens_last_used ON fcm_tokens(last_used_at);
CREATE INDEX idx_fcm_tokens_country ON fcm_tokens(country);

-- 2. NOTIFICATION EVENTS TABLE
CREATE TABLE IF NOT EXISTS notification_events (
  id SERIAL PRIMARY KEY,
  user_id VARCHAR(255) NOT NULL,
  notification_type VARCHAR(50) NOT NULL CHECK (notification_type IN ('1hour', '24hour', '46hour', 'custom')),
  event_type VARCHAR(50) NOT NULL CHECK (event_type IN ('scheduled', 'sent', 'clicked', 'dismissed', 'failed')),
  title TEXT,
  body TEXT,
  message_variant VARCHAR(20),
  sent_via VARCHAR(20) CHECK (sent_via IN ('local', 'fcm', 'both')),
  reward_type VARCHAR(20) CHECK (reward_type IN ('coins', 'gems', 'none')),
  reward_amount INTEGER,
  reward_claimed BOOLEAN DEFAULT false,
  last_level_played INTEGER,
  current_streak INTEGER,
  games_played_count INTEGER,
  country VARCHAR(2),
  timezone VARCHAR(50),
  scheduled_for TIMESTAMP,
  sent_at TIMESTAMP,
  clicked_at TIMESTAMP,
  received_at TIMESTAMP DEFAULT NOW(),
  payload JSONB,
  error_message TEXT,
  fcm_response JSONB
);

CREATE INDEX idx_notification_events_user_id ON notification_events(user_id);
CREATE INDEX idx_notification_events_type ON notification_events(notification_type, event_type);
CREATE INDEX idx_notification_events_received_at ON notification_events(received_at);
CREATE INDEX idx_notification_events_country ON notification_events(country);
CREATE INDEX idx_notification_events_variant ON notification_events(message_variant);
CREATE INDEX idx_notification_events_reward ON notification_events(reward_type, reward_claimed);
CREATE INDEX idx_notification_funnel ON notification_events(notification_type, event_type, received_at);

-- 3. NOTIFICATION PREFERENCES TABLE
CREATE TABLE IF NOT EXISTS notification_preferences (
  id SERIAL PRIMARY KEY,
  user_id VARCHAR(255) NOT NULL UNIQUE,
  enable_1hour BOOLEAN DEFAULT true,
  enable_24hour BOOLEAN DEFAULT true,
  enable_46hour BOOLEAN DEFAULT true,
  quiet_hours_start TIME DEFAULT '22:00:00',
  quiet_hours_end TIME DEFAULT '08:00:00',
  max_notifications_per_day INTEGER DEFAULT 3,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_notification_prefs_user_id ON notification_preferences(user_id);

-- 4. HELPER FUNCTIONS
CREATE OR REPLACE FUNCTION get_active_fcm_token(p_user_id VARCHAR)
RETURNS TEXT AS $$
  SELECT fcm_token
  FROM fcm_tokens
  WHERE user_id = p_user_id
    AND is_active = true
    AND platform = 'android'
  ORDER BY last_used_at DESC
  LIMIT 1;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION is_in_quiet_hours(p_user_id VARCHAR, p_timezone VARCHAR)
RETURNS BOOLEAN AS $$
DECLARE
  v_prefs RECORD;
  v_user_time TIME;
BEGIN
  SELECT * INTO v_prefs
  FROM notification_preferences
  WHERE user_id = p_user_id;
  
  IF NOT FOUND THEN
    v_prefs.quiet_hours_start := '22:00:00';
    v_prefs.quiet_hours_end := '08:00:00';
  END IF;
  
  v_user_time := (NOW() AT TIME ZONE p_timezone)::TIME;
  
  IF v_prefs.quiet_hours_start > v_prefs.quiet_hours_end THEN
    RETURN v_user_time >= v_prefs.quiet_hours_start OR v_user_time < v_prefs.quiet_hours_end;
  ELSE
    RETURN v_user_time >= v_prefs.quiet_hours_start AND v_user_time < v_prefs.quiet_hours_end;
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION check_daily_notification_limit(p_user_id VARCHAR)
RETURNS BOOLEAN AS $$
DECLARE
  v_count INTEGER;
  v_limit INTEGER;
BEGIN
  SELECT COALESCE(max_notifications_per_day, 3) INTO v_limit
  FROM notification_preferences
  WHERE user_id = p_user_id;
  
  SELECT COUNT(*) INTO v_count
  FROM notification_events
  WHERE user_id = p_user_id
    AND event_type = 'sent'
    AND received_at >= CURRENT_DATE;
  
  RETURN v_count < v_limit;
END;
$$ LANGUAGE plpgsql;

-- 5. VERIFICATION
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'fcm_tokens') THEN
    RAISE NOTICE '✅ fcm_tokens table created';
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'notification_events') THEN
    RAISE NOTICE '✅ notification_events table created';
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'notification_preferences') THEN
    RAISE NOTICE '✅ notification_preferences table created';
  END IF;
  
  RAISE NOTICE '🎉 Push notification schema migration complete!';
END $$;
```

---

## ✅ Expected Output:

You should see:
```
CREATE TABLE
CREATE INDEX
CREATE INDEX
CREATE INDEX
CREATE INDEX
CREATE TABLE
CREATE INDEX
... (more CREATE INDEX)
CREATE TABLE
CREATE INDEX
CREATE FUNCTION
CREATE FUNCTION
CREATE FUNCTION
NOTICE:  ✅ fcm_tokens table created
NOTICE:  ✅ notification_events table created
NOTICE:  ✅ notification_preferences table created
NOTICE:  🎉 Push notification schema migration complete!
DO
```

---

## 🔍 Verify Tables Created:

After running the SQL above, verify with:

```sql
-- Check tables exist
\dt fcm_tokens
\dt notification_events
\dt notification_preferences

-- Check row counts (should all be 0 initially)
SELECT COUNT(*) FROM fcm_tokens;
SELECT COUNT(*) FROM notification_events;
SELECT COUNT(*) FROM notification_preferences;
```

---

## ❌ If You Get Errors:

**"relation already exists"**
- ✅ This is OK! It means tables already exist
- Skip to verification step above

**Permission denied**
- Make sure you're connected to the correct database
- Check Railway database user has CREATE TABLE permissions

**Syntax error**
- Make sure you copied the ENTIRE SQL block
- Including the closing `$$;` at the end

---

## ✅ Once Done, Reply:

```
✅ Database migration done
Tables created: fcm_tokens, notification_events, notification_preferences
```

Then I'll proceed with building the entire push notification system! 🚀

