# 💎 FlappyJet Monetization Events - Complete Analysis

## 📊 **Executive Summary**

Your FlappyJet Pro game has a **dual-currency economy** (Coins + Gems) with jet skin purchases as the primary monetization driver. These three new events (`skin_purchased`, `item_unlocked`, `item_equipped`) are **CRITICAL** for tracking player behavior, optimizing pricing, and maximizing revenue.

---

## 🎮 **The Game Economy - How It Works**

### **Currency System:**
1. **Coins (Soft Currency)** 🪙
   - Earned through gameplay (missions, achievements, daily rewards)
   - Used to purchase Common, Rare, Epic, and Legendary jet skins
   - Prices: 299 (Common) → 599 (Rare) → 1,199 (Epic) → 2,399 (Legendary)

2. **Gems (Hard Currency)** 💎
   - **Primary monetization** - purchased with real money via IAP
   - Used for:
     - Mythic jet skins (exclusive, ~$5-10 USD worth)
     - Coin packs (converting gems to coins)
     - Heart boosters (unlimited lives for X hours)
     - Skip mission timers

### **Jet Skin System:**
- **5 Rarity Tiers:** Common → Rare → Epic → Legendary → Mythic
- **33 Total Skins** across different themes (storm, gold, neon, mythic exclusives)
- **Mythic skins are GEM-EXCLUSIVE** - This is your main revenue driver!
- Players collect, unlock, and equip skins for visual customization

---

## 🔍 **The Three New Events - What They Mean**

### **1. `skin_purchased` - THE MONEY EVENT** 💰

**What it tracks:**
```json
{
  "event_type": "skin_purchased",
  "jet_id": "neon_fury",
  "jet_name": "Neon Fury",
  "purchase_type": "gems",  // or "coins"
  "cost_coins": 0,
  "cost_gems": 500,         // 500 gems = ~$5 USD
  "rarity": "mythic"
}
```

**Why it matters:**
- **Revenue Attribution**: Track which skins generate the most gem purchases (real money!)
- **Pricing Optimization**: See if players buy more at 300 gems vs 500 gems
- **Conversion Funnel**: How many players progress from free coins to paid gems?
- **SKU Performance**: Which mythic skins are hits vs misses?

**Business Questions It Answers:**
1. Which mythic skins should we create more of? (Top performers)
2. Are coin prices balanced? (Are epic skins too cheap/expensive?)
3. What's our **gem sink rate**? (How fast do players spend purchased gems?)
4. **ARPU (Average Revenue Per User)**: Gem purchases = real revenue
5. Should we offer limited-time discounts on specific skins?

**Current State:**
- ❌ Backend was rejecting these events → **no monetization tracking!**
- ✅ After your fix, we'll see which skins drive revenue

---

### **2. `item_unlocked` - THE PROGRESSION EVENT** 🎁

**What it tracks:**
```json
{
  "event_type": "item_unlocked",
  "item_type": "skin",
  "item_id": "storm_chaser",
  "item_name": "Storm Chaser",
  "unlock_method": "purchase"  // or "achievement", "mission_reward"
}
```

**Why it matters:**
- **Collection Progress**: How many skins does the average player own?
- **Unlock Methods**: Are players buying skins or earning them?
- **Engagement Metric**: More unlocks = more invested players = higher retention
- **Achievement System**: Track if players unlock skins via achievements (free) vs purchases (paid)

**Business Questions It Answers:**
1. What % of players unlock at least 1 mythic skin?
2. Are players "completing" their collections? (All 33 skins)
3. Do achievement-based unlocks drive future gem purchases?
4. What's the **unlock velocity**? (How fast do new players unlock skins?)
5. Should we add more "free" skins to keep F2P players engaged?

**Current State:**
- Fired when a skin is added to inventory (after purchase or reward)
- Tracks both free and paid acquisition methods

---

### **3. `item_equipped` - THE ENGAGEMENT EVENT** 👕

**What it tracks:**
```json
{
  "event_type": "item_equipped",
  "item_type": "skin",
  "item_id": "golden_phoenix",
  "item_name": "Golden Phoenix"
}
```

**Why it matters:**
- **Feature Usage**: Are players actually *using* the skins they buy?
- **Buyer Satisfaction**: If they equip it immediately → they love it!
- **Variety Seeking**: Do players change skins frequently or stick to one?
- **Psychological Ownership**: Equipping = increased perceived value

**Business Questions It Answers:**
1. Do players who buy mythic skins actually equip them? (Satisfaction check)
2. What's the **equip rate** after purchase? (Buy → Immediately equip = 100%)
3. Which skins have the highest "stickiness"? (Most equipped over time)
4. Are players "skin switchers" or "skin loyalists"?
5. Should we add "skin presets" or "random skin selector" features?

**Current State:**
- Fired every time a player switches skins
- Can indicate seasonal preferences (e.g., Halloween skins in October)

---

## 📈 **How These Events Should Appear in the Dashboard**

### **Current Dashboard Sections:**

#### **1. Economy Balance Chart** (Already exists)
- Shows gems/coins earned vs spent over time
- **NEW FIX NEEDED:** Update to use `skin_purchased` events:
  ```sql
  -- Current (WRONG): Uses currency_spent with item_type
  WHERE event_type = 'currency_spent'
  
  -- Should be (RIGHT): Use skin_purchased directly
  WHERE event_type = 'skin_purchased'
  ```

#### **2. Top Jets/Skins Purchased Chart** (Already exists)
- Shows most popular purchases
- **NEW FIX NEEDED:** Currently queries `item_purchased` event (doesn't exist!)
  ```sql
  -- Current (WRONG):
  WHERE event_type = 'item_purchased'
  
  -- Should be (RIGHT):
  WHERE event_type = 'skin_purchased'
  ```

---

### **🚀 NEW DASHBOARD SECTIONS WE SHOULD ADD:**

#### **A. Monetization Funnel** (NEW)
```
👥 Total Players → 🪙 Coin Buyers → 💎 Gem Spenders → 🎨 Mythic Owners
    100%              60%              15%              8%
```
**Metrics:**
- % of players who buy at least 1 skin with coins
- % of players who buy at least 1 skin with gems (**conversion rate!**)
- % of players who own at least 1 mythic skin
- Average # of skins owned per player

**Query:**
```sql
SELECT 
  COUNT(DISTINCT user_id) as total_users,
  COUNT(DISTINCT CASE WHEN cost_coins > 0 THEN user_id END) as coin_buyers,
  COUNT(DISTINCT CASE WHEN cost_gems > 0 THEN user_id END) as gem_spenders,
  COUNT(DISTINCT CASE WHEN rarity = 'mythic' THEN user_id END) as mythic_owners
FROM events
WHERE event_type = 'skin_purchased'
  AND received_at >= CURRENT_DATE - INTERVAL '30 days'
```

---

#### **B. Skin Purchase Heatmap** (NEW)
**Visual:** Color-coded grid showing purchases by rarity + currency type

|            | Coins 🪙 | Gems 💎 |
|------------|----------|---------|
| Common     | ████ 89  | -       |
| Rare       | ███ 56   | -       |
| Epic       | ██ 32    | -       |
| Legendary  | █ 18     | -       |
| Mythic     | -        | ██ 24   |

**Shows:**
- Which rarity tier sells best
- Gem-to-coin purchase ratio
- Price sensitivity (Are legendaries too expensive?)

---

#### **C. Skin Engagement Rate** (NEW)
**Metric:** `Equip Rate = (item_equipped events) / (item_unlocked events) × 100%`

| Skin Name       | Rarity    | Unlocks | Equips | Engagement Rate |
|----------------|-----------|---------|--------|-----------------|
| Neon Fury      | Mythic    | 24      | 24     | 100% ⭐        |
| Golden Phoenix | Legendary | 18      | 16     | 89% 🔥         |
| Storm Chaser   | Epic      | 32      | 20     | 63%            |
| Blue Jet       | Common    | 89      | 12     | 13% ⚠️         |

**Insights:**
- Low engagement = Players regret buying it (bad skin design)
- High engagement = Players love it (create more like this!)
- 100% mythic engagement = Gem purchases are worth it! ✅

---

#### **D. Revenue Attribution** (NEW)
**Break down gem spending by category:**

```
💎 Total Gems Spent (Last 30 Days): 12,450 gems (~$125 USD)

📊 Spending Breakdown:
- Mythic Skins: 7,200 gems (58%) 🎨
- Coin Packs: 3,100 gems (25%) 🪙
- Heart Boosters: 1,800 gems (14%) ❤️
- Continues: 350 gems (3%) 🔄
```

**Query:**
```sql
SELECT 
  CASE 
    WHEN event_type = 'skin_purchased' AND rarity = 'mythic' THEN 'Mythic Skins'
    WHEN event_type = 'currency_spent' AND spent_on LIKE '%coin%' THEN 'Coin Packs'
    WHEN event_type = 'currency_spent' AND spent_on LIKE '%heart%' THEN 'Heart Boosters'
    ELSE 'Other'
  END as category,
  SUM(cost_gems) as total_gems,
  COUNT(*) as transaction_count
FROM events
WHERE event_type IN ('skin_purchased', 'currency_spent')
  AND received_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY category
```

---

## 🎯 **Key Business Metrics to Track**

### **1. Monetization Health:**
- **Gem Conversion Rate:** % of players who buy gems → purchase skins
- **ARPPU (Average Revenue Per Paying User):** Total gems spent ÷ # of gem spenders
- **Whale Identification:** Players who own 5+ mythic skins (VIPs!)

### **2. Pricing Optimization:**
- **Price Sensitivity:** Do 300-gem skins sell 2x more than 500-gem skins?
- **Bundle Performance:** Do coin pack buyers also buy mythic skins?
- **Discount Impact:** Track skin purchases during limited-time events

### **3. Content Strategy:**
- **Skin Popularity:** Which themes drive purchases? (Neon, Gold, Storm, etc.)
- **Collection Progress:** Average # of skins per player (engagement proxy)
- **Churn Prevention:** Do players with <3 skins churn faster?

---

## 🔧 **What We're Fixing Right Now**

### **Problem:**
The backend was **rejecting all three events** as "Unknown event type"
```
❌ Unknown event type: skin_purchased
❌ Unknown event type: item_unlocked  
❌ Unknown event type: item_equipped
```

### **Impact:**
- 🚫 **NO skin purchase tracking** → Can't optimize pricing
- 🚫 **NO revenue attribution** → Don't know which skins make money
- 🚫 **NO engagement metrics** → Can't tell if players like their purchases
- 🚫 **Dashboard charts show ZERO data** → Business is flying blind!

### **Solution:**
1. ✅ Add `skinPurchasedSchema`, `itemUnlockedSchema`, `itemEquippedSchema` to backend
2. ✅ Register them in the schema map
3. ✅ Export them for validation
4. ✅ Update dashboard queries to use correct event types
5. 🚀 Deploy to Railway → Start collecting monetization data!

---

## 📊 **Expected Results After Fix**

### **Week 1:**
- Dashboard "Top Jets/Skins Purchased" chart fills with data
- See which mythic skins are best sellers
- Identify pricing sweet spots (e.g., 400 gems vs 600 gems)

### **Week 2-4:**
- Track conversion funnel: Coin buyers → Gem buyers → Mythic owners
- Calculate ARPU and identify whales (high spenders)
- A/B test skin prices based on demand data

### **Month 1-3:**
- Optimize skin catalog (create more of what sells, retire duds)
- Design seasonal skins based on engagement patterns
- Implement dynamic pricing for underperforming skins

---

## 🚀 **Next Steps (After Backend Fix)**

### **1. Dashboard Updates** (You should ask me to do this!)
- Fix `/api/dashboard/purchases` to query `skin_purchased` not `item_purchased`
- Add "Monetization Funnel" section
- Add "Skin Engagement Rate" chart
- Add "Revenue Attribution" breakdown

### **2. Analytics Deep Dives**
- Weekly reports on gem spending patterns
- Monthly SKU performance reviews
- Quarterly pricing optimization analysis

### **3. Business Intelligence**
- Cohort analysis: Do Week 1 buyers spend more long-term?
- Retention correlation: Do skin buyers have higher D7/D30 retention?
- LTV prediction: Can we predict lifetime value from first purchase?

---

## 💡 **Why This Matters**

**Without these events tracked:**
- You're selling products blindly (no idea what works!)
- Can't optimize prices (leaving money on the table)
- No data for App Store pitches (can't show growth to investors)
- Dashboard is incomplete (can't make data-driven decisions)

**With these events tracked:**
- **Maximize revenue** by focusing on top-selling skins
- **Reduce churn** by identifying engagement patterns
- **Optimize pricing** based on actual demand data
- **Scale confidently** with data-backed content strategy

---

## ✅ **Current Status**

1. ✅ Events are firing correctly from Flutter app
2. ⏳ Backend schemas being added (in progress)
3. ⏳ Dashboard queries need updating (next step)
4. ⏳ New dashboard sections need building (ask me!)

**ETA to Full Monetization Tracking:** ~1 hour after backend deploy

---

**Questions? Ask me to:**
1. Update the dashboard queries to use these events
2. Add new monetization charts/sections
3. Build custom reports for specific business questions
4. Set up alerts for revenue anomalies (e.g., sudden drop in gem purchases)

