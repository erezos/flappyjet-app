# FlappyJet Playable Ad

## 📋 Overview

This is a lightweight HTML5 playable ad for FlappyJet, optimized for Unity Ads User Acquisition campaigns.

**File:** `flappyjet-playable.html`

---

## ✅ Specifications

- ✅ **File Size:** < 5MB (currently ~8KB)
- ✅ **Format:** Single inlined HTML file
- ✅ **MRAID:** 2.0 compliant
- ✅ **No External Requests:** All assets embedded
- ✅ **Responsive:** Works on all screen sizes
- ✅ **Duration:** 15-30 seconds gameplay

---

## 🎮 Features

### Gameplay
- **Tap to fly** - Simple one-tap mechanic
- **Avoid obstacles** - Navigate through pipes
- **Score tracking** - Real-time score display
- **Instant restart** - Quick retry for engagement

### Design
- **Simplified FlappyJet** - Core gameplay mechanics
- **Attractive visuals** - Gradient sky, clouds, colorful jet
- **Clear CTA** - "INSTALL NOW" button
- **Engaging animations** - Bounce and pulse effects

---

## 🧪 Testing

### 1. Local Testing (Browser)
```bash
# Open in browser
open flappyjet-playable.html

# Or use a local server
python3 -m http.server 8000
# Then visit: http://localhost:8000/flappyjet-playable.html
```

### 2. Unity Ad Testing App
- **iOS:** [Download from App Store](https://apps.apple.com/app/id123456789)
- **Android:** [Download from Play Store](https://play.google.com/store/apps/details?id=com.unity3d.ads.testapp)

**Steps:**
1. Open Unity Ad Testing app
2. Tap "Test Playable Ad"
3. Select `flappyjet-playable.html` from your device
4. Test gameplay and CTA button

### 3. MRAID Compliance Testing
Visit: http://webtester.mraid.org/
- Upload `flappyjet-playable.html`
- Verify MRAID functions work correctly
- Test `mraid.open()` for CTA

---

## 📤 Upload to Unity Ads

### Step 1: Create Campaign
1. Log in to [Unity Ads Dashboard](https://dashboard.unity3d.com/)
2. Navigate to **User Acquisition** → **Campaigns**
3. Click **"Create Campaign"**

### Step 2: Upload Creative
1. Click **"Create new creative pack"**
2. Select **"Playable end card"**
3. Upload `flappyjet-playable.html`
4. **Creative pack name:** "FlappyJet Playable v1"

### Step 3: Configure Campaign
- **Target:** Android (initially)
- **Countries:** Start with tier 2-3 countries for cost efficiency
- **Budget:** Set daily budget (e.g., $50/day)
- **Bid:** Start with recommended CPI (Cost Per Install)

### Step 4: Launch
1. Review all settings
2. Submit for moderation
3. Wait for approval (usually 24-48 hours)
4. Launch campaign!

---

## 🎯 Best Practices

### Optimization Tips
1. **First 3 seconds are critical** - Make them engaging!
2. **Show CTA early** - After 10-15 seconds or first death
3. **A/B test** - Try different jet colors, obstacle styles
4. **Track metrics** - Monitor CTR (Click-Through Rate) and IPM (Installs Per Mille)

### Recommended Targeting
- **Age:** 13-35 (core mobile gaming demographic)
- **Interests:** Casual games, arcade games
- **Devices:** Mid to high-end Android devices
- **Countries:** Start with: Brazil, India, Indonesia, Mexico

---

## 📊 Expected Performance

### Industry Benchmarks (Playable Ads)
- **CTR:** 8-15% (vs 2-5% for video ads)
- **IPM:** 30-60 installs per 1000 impressions
- **CPI:** $0.50-$2.00 (varies by country)

### Budget Recommendation
- **Test Budget:** $500-$1000 to gather data
- **Scale Budget:** $2000-$5000/month for meaningful growth

---

## 🔧 Customization

### Update App Store Link
Replace the package ID in line 382:
```javascript
mraid.open('https://play.google.com/store/apps/details?id=com.flappyjet.pro.flappy_jet_pro');
```

### Adjust Difficulty
- **Easier:** Increase `obstacleGap` (line 102)
- **Harder:** Increase `obstacleSpeed` (line 103)
- **Longer gameplay:** Decrease `obstacleSpeed`

### Change Colors
- **Jet color:** Line 156 (`#4A90E2`)
- **Obstacles:** Line 188 (`#2ECC71`)
- **Background:** Line 23 (gradient)

---

## 📝 File Size Optimization

Current size: **~8KB** ✅

If you need to reduce further:
1. Minify HTML/CSS/JS (use online minifier)
2. Remove comments
3. Simplify animations
4. Reduce obstacle complexity

---

## 🚀 Next Steps

1. ✅ **Test locally** in browser
2. ✅ **Test with Unity Ad Testing app**
3. ✅ **Upload to Unity Ads Dashboard**
4. ✅ **Submit for moderation**
5. ✅ **Launch campaign**
6. 📊 **Monitor performance**
7. 🔄 **Iterate based on data**

---

## 📞 Support

- **Unity Ads Support:** https://support.unity.com/
- **Documentation:** https://docs.unity.com/acquire/
- **Community:** Unity Ads Forum

---

## 📄 License

This playable ad is for FlappyJet marketing purposes only.

---

**Created:** 2025-10-04  
**Version:** 1.0  
**File Size:** ~8KB  
**Status:** Ready for upload ✅
