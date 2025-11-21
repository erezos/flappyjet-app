# 🐛 CRITICAL BUG FIX: Retention Calculation

## Problem Identified
**Symptom:** Dashboard shows 0.5% Day 1 retention with "24 users returned"  
**Reality:** If 0.5% = 24 users, that means 4,800 total users in denominator  
**Issue:** The calculation is dividing by ALL historical users instead of just the relevant cohort!

---

## The Bug Explained

### Current (WRONG) Calculation:
```
24 returned users / 4,800 total historical users = 0.5%
```

### Correct Calculation Should Be:
```
24 returned users / 100 users who installed yesterday = 24%
```

---

## Root Cause Analysis

### Problem in SQL Query (Line 465-470)
```sql
ROUND(100.0 * COUNT(DISTINCT rs.user_id) / 
  SUM(CASE 
    WHEN cs.install_date <= CURRENT_DATE - days_since_install 
    THEN cs.cohort_size 
    ELSE 0 
  END), 1) as retention_rate
```

**What's wrong:**
- The `SUM(CASE...)` is adding up ALL cohort sizes from ALL historical install dates
- For Day 1 retention, it should ONLY include cohorts from (CURRENT_DATE - 1)
- But it's including cohorts from day 1, day 2, day 3... all the way back!

---

## The Fix

### File: `railway-backend/routes/dashboard-api.js`
### Lines: 434-477

**Replace the entire query with:**

```javascript
        const result = await db.query(`
          WITH first_sessions AS (
            SELECT 
              user_id,
              MIN(DATE(received_at)) as install_date
            FROM events
            WHERE event_type = 'user_installed' 
               OR event_type = 'app_launched'
            GROUP BY user_id
          ),
          return_sessions AS (
            SELECT DISTINCT
              fs.user_id,
              fs.install_date,
              DATE(e.received_at) as return_date,
              DATE(e.received_at) - fs.install_date as days_since_install
            FROM first_sessions fs
            JOIN events e ON fs.user_id = e.user_id
            WHERE e.event_type IN ('app_launched', 'game_started', 'level_started')
              AND DATE(e.received_at) > fs.install_date
          ),
          cohort_sizes AS (
            SELECT 
              install_date,
              COUNT(DISTINCT user_id) as cohort_size
            FROM first_sessions
            GROUP BY install_date
          )
          SELECT
            rs.days_since_install,
            COUNT(DISTINCT rs.user_id) as returned_users,
            SUM(cs.cohort_size) as cohort_size,
            ROUND(100.0 * COUNT(DISTINCT rs.user_id) / NULLIF(SUM(cs.cohort_size), 0), 1) as retention_rate
          FROM return_sessions rs
          JOIN cohort_sizes cs ON rs.install_date = cs.install_date
          WHERE rs.days_since_install IN (1, 3, 7, 14, 30)
            AND rs.install_date <= CURRENT_DATE - rs.days_since_install
          GROUP BY rs.days_since_install
          ORDER BY rs.days_since_install
        `);
```

### Key Changes:
1. **Added `cohort_size` to SELECT** - Now you can see the actual denominator!
2. **Simplified denominator** - Removed the complex `CASE` statement
3. **Fixed GROUP BY** - Changed from `days_since_install` to `rs.days_since_install`
4. **Added NULLIF** - Prevents division by zero errors
5. **Correct aggregation** - Now sums only the cohort sizes that match the join condition

---

## How to Apply the Fix

### Option 1: Direct Database (Recommended for immediate fix)
1. SSH into Railway backend
2. Edit `routes/dashboard-api.js`
3. Find line 434 (the retention query)
4. Replace with the corrected query above
5. Restart the service

### Option 2: Via Railway Dashboard
1. Go to Railway dashboard
2. Open the `flappyjet-backend` service
3. Go to Deployments → Latest deployment
4. Click "Redeploy" after making the change

### Option 3: Manual File Upload (if you have access)
Use Railway CLI or file editor to update the file directly

---

## Expected Results After Fix

### Before (WRONG):
- Day 1: **0.5%** (24 users returned)
- Day 3: **0.3%** (estimated)
- Day 7: **0.2%** (estimated)

### After (CORRECT):
- Day 1: **15-30%** (24 users returned from ~80-160 installs)
- Day 3: **10-20%** (actual cohort-based calculation)
- Day 7: **5-15%** (actual cohort-based calculation)

---

## Verification Steps

After applying the fix:

1. **Clear the cache:**
   ```bash
   # The retention endpoint is cached for 1 hour
   # Either wait 1 hour or restart the service
   ```

2. **Check the response:**
   ```bash
   curl https://flappyjet-backend-production.up.railway.app/api/dashboard/retention
   ```

3. **Verify the numbers:**
   - `returned_users`: Should be 24 (unchanged)
   - `cohort_size`: Should be ~80-200 (NOT 4,800!)
   - `retention_rate`: Should be 12-30% (NOT 0.5%!)

---

## Additional Debug Query

If you want to verify the fix is working, run this in PostgreSQL:

```sql
-- Check today's numbers
WITH first_sessions AS (
  SELECT 
    user_id,
    MIN(DATE(received_at)) as install_date
  FROM events
  WHERE event_type IN ('user_installed', 'app_launched')
  GROUP BY user_id
),
yesterday_cohort AS (
  SELECT COUNT(DISTINCT user_id) as cohort_size
  FROM first_sessions
  WHERE install_date = CURRENT_DATE - 1
),
today_returns AS (
  SELECT COUNT(DISTINCT fs.user_id) as returned_users
  FROM first_sessions fs
  JOIN events e ON fs.user_id = e.user_id
  WHERE fs.install_date = CURRENT_DATE - 1
    AND DATE(e.received_at) = CURRENT_DATE
    AND e.event_type IN ('app_launched', 'game_started')
)
SELECT 
  yc.cohort_size as yesterday_installs,
  tr.returned_users as today_returns,
  ROUND(100.0 * tr.returned_users / NULLIF(yc.cohort_size, 0), 1) as day1_retention
FROM yesterday_cohort yc, today_returns tr;
```

**Expected output:**
```
yesterday_installs | today_returns | day1_retention
------------------+---------------+---------------
       120        |      24       |     20.0
```

---

## Impact

### What This Fixes:
✅ Accurate retention metrics in dashboard  
✅ Proper cohort-based calculation  
✅ Visibility into actual user behavior  
✅ Correct denominator (cohort size, not all users)

### What This Doesn't Change:
- The raw data (events, users, etc.)
- Other dashboard metrics
- The 24 returned users count (that's correct)

---

## Status
- **File Modified:** `/Users/erezk/Projects/FlappyJet/railway-backend/routes/dashboard-api.js`
- **Lines Changed:** 434-477
- **Testing:** Local changes made, needs Railway deployment
- **Urgency:** HIGH - This affects key business metrics

---

**Next Step:** Apply this fix to the Railway backend to see accurate retention numbers!

