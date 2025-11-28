# 🎮 FlappyJet Google Ads Playable Ads

## 📋 Created Playable Ads

### 1. `playable-ad-classic.html` (8 KB)
**Theme:** Classic Night Sky
- Deep space gradient background with stars
- Core tap-to-fly gameplay
- Gem collection system
- **CTA:** "DOWNLOAD FREE"
- **Best for:** General audience, broad reach campaigns

### 2. `playable-ad-collect-jets.html` (9 KB)  
**Theme:** Sunset Jet Collection
- Warm orange/gold sunset gradient
- Collect different jet icons while flying
- Shows 5 collectible jets during gameplay
- **CTA:** "GET ALL JETS FREE"
- **Best for:** Collectors, completionists, users who love unlockables

### 3. `playable-ad-boss-battle.html` (9 KB)
**Theme:** Intense Boss Fight
- Dark red/black combat atmosphere
- Player vs Boss battle with health bars
- Auto-shooting bullets at boss
- Win/Lose conditions
- **CTA:** "FIGHT MORE BOSSES"
- **Best for:** Competitive players, action game enthusiasts

---

## ✅ Google Ads Specifications Met

| Requirement | Status |
|-------------|--------|
| File size < 5MB | ✅ All under 10KB |
| Single HTML file | ✅ Self-contained |
| MRAID 2.0 compliant | ✅ Included |
| No external requests | ✅ All inline |
| Responsive design | ✅ Adapts to screen |
| Touch controls | ✅ Tap to play |
| Clear CTA | ✅ Install button |
| Duration 15-30s | ✅ Quick gameplay |

---

## 🧪 Testing

### Local Browser Testing
```bash
# Open in browser
open playable-ad-classic.html

# Or use local server
python3 -m http.server 8000
# Visit: http://localhost:8000/playable-ad-classic.html
```

### Mobile Testing
1. Upload to a web server or use ngrok
2. Open on your phone
3. Test touch controls and responsiveness

### MRAID Testing
- Use MRAID testing tools: http://webtester.mraid.org/
- Upload your HTML file to test MRAID functions

---

## 📤 Google Ads Upload

### Step 1: Create Campaign
1. Go to [Google Ads](https://ads.google.com)
2. Create new **App Campaign** for installs
3. Select your FlappyJet app

### Step 2: Add Creative Assets
1. In the campaign, click "Add assets"
2. Select "HTML5"
3. Upload your playable HTML file
4. Preview and verify functionality

### Step 3: Campaign Settings
- **Bid strategy:** Target CPA or Maximize conversions
- **Budget:** Start with $20-50/day for testing
- **Targeting:** 
  - Age: 13-35
  - Interests: Mobile games, Arcade games, Casual games
  - Countries: Start with US, UK, CA, AU (high quality)

---

## 🎯 A/B Testing Strategy

Test these variants to find best performer:
1. **Classic** - Widest appeal
2. **Collect Jets** - Appeals to collectors
3. **Boss Battle** - Appeals to action seekers

Monitor these KPIs:
- **CTR** (Click-Through Rate): Target 5-15%
- **CVR** (Conversion Rate): Target 10-30%
- **CPI** (Cost Per Install): Track and optimize
- **IPM** (Installs Per Mille): Target 30-60

---

## 🔧 Customization

### Change App Store Link
Find this line in each file and update:
```javascript
const url='https://play.google.com/store/apps/details?id=com.flappyjet.pro.flappy_jet_pro';
```

### Adjust Difficulty
- **Easier:** Decrease `grav` (gravity), increase gap sizes
- **Harder:** Increase `obstSpeed`, decrease gap sizes

### Change Colors
Look for `createLinearGradient` and hex color codes like `#4A90E2`

---

## 📊 Expected Performance

| Metric | Industry Average | Target |
|--------|-----------------|--------|
| CTR | 2-5% (video) | 8-15% (playable) |
| CVR | 5-10% | 15-25% |
| CPI | $1-3 | $0.50-1.50 |
| IPM | 20-40 | 40-80 |

**Note:** Playable ads typically outperform video ads by 2-3x!

---

## 📞 Support

- **Google Ads Help:** https://support.google.com/google-ads
- **Playable Ads Best Practices:** Search "Google playable ads specifications"

---

**Created:** November 27, 2025
**Files:** 3 playable HTML5 ads
**Total Size:** ~26 KB
**Status:** Ready for upload ✅
