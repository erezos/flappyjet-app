# 🛒 FlappyJet IAP Store Setup Guide

## 🎯 **GOOGLE PLAY CONSOLE SETUP**

### Step 1: Access In-App Products
1. Go to Google Play Console
2. Select your FlappyJet app
3. Navigate to **Monetization** → **In-app products**
4. Click **Create product**

### Step 2: Create Gem Packs
Create these 4 products:

#### Small Gem Pack
- **Product ID**: `com.flappyjet.gems.small`
- **Name**: Small Gem Pack
- **Description**: Get 100 gems to unlock new jets and boosters
- **Default price**: $0.99 USD
- **Status**: Active

#### Medium Gem Pack  
- **Product ID**: `com.flappyjet.gems.medium`
- **Name**: Medium Gem Pack
- **Description**: Get 500 + 50 bonus gems (550 total) - Popular choice!
- **Default price**: $4.99 USD
- **Status**: Active

#### Large Gem Pack
- **Product ID**: `com.flappyjet.gems.large`
- **Name**: Large Gem Pack
- **Description**: Get 1000 + 200 bonus gems (1200 total) - Best value!
- **Default price**: $9.99 USD
- **Status**: Active

#### Mega Gem Pack
- **Product ID**: `com.flappyjet.gems.mega`
- **Name**: Mega Gem Pack
- **Description**: Get 2500 + 750 bonus gems (3250 total) - Ultimate pack!
- **Default price**: $19.99 USD
- **Status**: Active

### Step 3: Create Heart Booster Packs
Create these 3 products:

#### 24H Booster
- **Product ID**: `com.flappyjet.booster.24h`
- **Name**: 24H Heart Booster
- **Description**: 6 max hearts + faster regeneration for 24 hours
- **Default price**: $0.99 USD
- **Status**: Active

#### 48H Booster
- **Product ID**: `com.flappyjet.booster.48h`
- **Name**: 48H Heart Booster
- **Description**: 6 max hearts + faster regeneration for 48 hours - Popular!
- **Default price**: $1.79 USD
- **Status**: Active

#### 72H Booster
- **Product ID**: `com.flappyjet.booster.72h`
- **Name**: 72H Heart Booster
- **Description**: 6 max hearts + faster regeneration for 72 hours - Best value!
- **Default price**: $2.39 USD
- **Status**: Active

### Step 4: Optional Premium Jets
If you want direct jet purchases:

#### Golden Falcon
- **Product ID**: `com.flappyjet.jet.golden_falcon`
- **Name**: Golden Falcon Jet
- **Description**: Exclusive premium jet with stunning golden finish
- **Default price**: $2.99 USD
- **Status**: Active

#### Stealth Dragon
- **Product ID**: `com.flappyjet.jet.stealth_dragon`
- **Name**: Stealth Dragon Jet
- **Description**: Ultimate stealth technology jet - Most popular!
- **Default price**: $4.99 USD
- **Status**: Active

---

## 🍎 **APPLE APP STORE CONNECT SETUP**

### Step 1: Access In-App Purchases
1. Go to App Store Connect
2. Select your FlappyJet app
3. Navigate to **Features** → **In-App Purchases**
4. Click the **+** button to create new products

### Step 2: Create All Products
Use the **exact same Product IDs** as Google Play Console:

#### For Each Product:
- **Type**: Consumable (for gems, boosters) or Non-Consumable (for jets)
- **Reference Name**: Same as Google Play name
- **Product ID**: Same as Google Play (e.g., `com.flappyjet.gems.small`)
- **Price**: Same as Google Play pricing
- **Display Name**: Same as Google Play name
- **Description**: Same as Google Play description

### Step 3: Localization
Add localized names and descriptions for your target markets.

### Step 4: Review Information
- Add screenshots if required
- Set availability in all territories
- Submit for review

---

## 🔧 **TESTING SETUP**

### Google Play Console Testing
1. Go to **Testing** → **Internal testing**
2. Add test accounts
3. Upload a test build with IAP integration
4. Test purchases (they'll be free for test accounts)

### App Store Connect Testing
1. Go to **TestFlight**
2. Add internal testers
3. Upload a test build
4. Use Sandbox environment for testing
5. Create sandbox test accounts in **Users and Access** → **Sandbox Testers**

---

## ⚠️ **IMPORTANT NOTES**

### Product ID Consistency
- **CRITICAL**: Product IDs must match exactly between stores and your Flutter code
- Use the same IDs in both Google Play Console and App Store Connect
- Our Flutter code expects these exact IDs

### Pricing Strategy
- Start with competitive pricing
- Monitor conversion rates
- Consider regional pricing adjustments
- Test different price points

### Review Process
- Google Play: Usually approved within hours
- App Store: Can take 24-48 hours for review
- Both stores may reject if descriptions are unclear

### Revenue Optimization
- Mark popular items clearly (48H booster, Medium gems)
- Highlight "Best Value" options (72H booster, Large gems)
- Use psychological pricing ($0.99, $4.99, $9.99)

---

## 🚀 **NEXT STEPS AFTER SETUP**

1. **Create products in both stores**
2. **Wait for approval** (especially App Store)
3. **Test with sandbox/internal testing**
4. **Deploy to production**
5. **Monitor analytics and conversion rates**
6. **Optimize pricing based on data**

---

## 📊 **ANALYTICS TO TRACK**

- Purchase funnel conversion rates
- Most popular products
- Revenue per user (RPU)
- Average revenue per paying user (ARPPU)
- Purchase frequency
- Refund rates

This will help you optimize your monetization strategy over time!
