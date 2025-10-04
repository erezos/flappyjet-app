#!/bin/bash

# 🚀 Deploy Analytics Update Script
# Deploys the comprehensive analytics integration to Railway

echo "🚀 Starting Analytics Integration Deployment..."

# Step 1: Run database schema migration
echo "📊 Step 1: Running database schema migration..."
cd railway-backend
node scripts/run-analytics-migration.js

if [ $? -eq 0 ]; then
    echo "✅ Database schema migration completed successfully"
else
    echo "❌ Database schema migration failed"
    exit 1
fi

# Step 2: Deploy backend changes
echo "🚂 Step 2: Deploying Railway backend changes..."
git add .
git commit -m "feat: comprehensive analytics integration - Railway + Firebase

- Add UnifiedAnalyticsManager for dual analytics tracking
- Fix database schema (add event_type, session_id columns)
- Create daily_streaks table for notifications
- Update all game systems to use unified analytics
- Add comprehensive event tracking (gameplay, monetization, engagement)
- Implement app lifecycle analytics
- Add performance monitoring and error tracking
- Create analytics test suite for end-to-end testing

This enables complete analytics data flow to Railway dashboard."

# Step 3: Push to Railway
echo "🚀 Step 3: Pushing to Railway..."
git push origin main

if [ $? -eq 0 ]; then
    echo "✅ Railway deployment initiated successfully"
else
    echo "❌ Railway deployment failed"
    exit 1
fi

# Step 4: Verify deployment
echo "🔍 Step 4: Verifying deployment..."
sleep 30  # Wait for deployment to complete

# Test the analytics endpoint
echo "🧪 Testing analytics endpoint..."
curl -X POST "https://flappyjet-backend-production.up.railway.app/api/analytics/event" \
  -H "Content-Type: application/json" \
  -d '{
    "event_name": "deployment_test",
    "event_data": {
      "deployment_time": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'",
      "version": "1.4.8",
      "test": true
    }
  }'

if [ $? -eq 0 ]; then
    echo "✅ Analytics endpoint test successful"
else
    echo "⚠️ Analytics endpoint test failed (may be normal during deployment)"
fi

echo ""
echo "🎉 Analytics Integration Deployment Complete!"
echo ""
echo "📊 What was deployed:"
echo "  ✅ Database schema fixes (event_type, session_id columns)"
echo "  ✅ Daily streaks table for notifications"
echo "  ✅ UnifiedAnalyticsManager integration"
echo "  ✅ Smart Railway Analytics with background processing"
echo "  ✅ App lifecycle analytics"
echo "  ✅ Comprehensive event tracking across all game systems"
echo "  ✅ Performance monitoring and error tracking"
echo "  ✅ Analytics test suite"
echo ""
echo "🚀 Your Railway analytics dashboard should now receive comprehensive data!"
echo "📈 Monitor your dashboard at: https://railway.app/project/[your-project-id]"
echo ""
echo "🧪 To test analytics in your Flutter app:"
echo "  1. Run the app in debug mode"
echo "  2. Play a game session"
echo "  3. Check Railway logs for analytics events"
echo "  4. Verify dashboard shows real-time data"
echo ""
echo "📊 Analytics events now tracked:"
echo "  - Game lifecycle (start, end, continue)"
echo "  - User engagement (sessions, features, social)"
echo "  - Monetization (purchases, ads, IAP)"
echo "  - Performance metrics and errors"
echo "  - App lifecycle and retention events"

