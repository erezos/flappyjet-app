# 🚀 FlappyJet Pro - Server Deployment Guide

## 📋 **Prerequisites**

1. **Firebase Account**: Create a free Firebase account at [firebase.google.com](https://firebase.google.com)
2. **Node.js**: Install Node.js 18+ from [nodejs.org](https://nodejs.org)
3. **Firebase CLI**: Install globally with `npm install -g firebase-tools`

## 🔧 **Setup Instructions**

### 1. **Create Firebase Project**

```bash
# Login to Firebase
firebase login

# Create new project (or use existing)
firebase projects:create flappyjet-pro

# Initialize Firebase in your project
cd server/
firebase init
```

**Select these services:**
- ✅ Firestore
- ✅ Functions  
- ✅ Hosting
- ✅ Storage (optional)

### 2. **Configure Firestore**

```bash
# Deploy Firestore rules and indexes
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
```

### 3. **Deploy Cloud Functions**

```bash
cd functions/
npm install
cd ..
firebase deploy --only functions
```

### 4. **Update Flutter App Configuration**

Update `lib/game/systems/server_manager.dart`:

```dart
class ServerConfig {
  // Replace with your Firebase project URL
  static const String baseUrl = 'https://us-central1-YOUR-PROJECT-ID.cloudfunctions.net';
  // ... rest of config
}
```

## 💰 **Cost Optimization**

### **Free Tier Limits (Monthly)**
- **Functions**: 2M invocations, 400K GB-seconds
- **Firestore**: 1GB storage, 50K reads, 20K writes, 20K deletes
- **Authentication**: Unlimited users
- **Hosting**: 10GB transfer

### **Estimated Costs for 10K Active Users**
- **Functions**: ~$3-8/month
- **Firestore**: ~$2-5/month  
- **Total**: **$5-15/month**

### **Scaling Strategy**
1. **0-1K users**: Free tier sufficient
2. **1K-10K users**: $5-15/month
3. **10K-100K users**: $50-150/month
4. **100K+ users**: Consider dedicated infrastructure

## 🔒 **Security Configuration**

### 1. **API Keys Management**

Create `.env` file in functions directory:
```bash
# functions/.env
GOOGLE_PLAY_API_KEY=your_google_play_key
APP_STORE_SHARED_SECRET=your_app_store_secret
ENCRYPTION_KEY=your_32_char_encryption_key
```

### 2. **Firestore Security Rules**

The provided `firestore.rules` includes:
- ✅ User data isolation
- ✅ Score validation
- ✅ Read-only leaderboards
- ✅ Anti-cheat measures

### 3. **Rate Limiting**

Add to `functions/index.js`:
```javascript
const rateLimit = require('express-rate-limit');

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});

app.use(limiter);
```

## 📊 **Monitoring & Analytics**

### 1. **Firebase Console**
- Monitor function executions
- Track Firestore usage
- View error logs

### 2. **Custom Analytics**
```javascript
// Track custom metrics
await db.collection('metrics').add({
  event: 'daily_active_users',
  count: uniqueUsers,
  date: admin.firestore.FieldValue.serverTimestamp()
});
```

### 3. **Performance Monitoring**
```javascript
const { performance } = require('perf_hooks');

exports.monitoredFunction = functions.https.onRequest(async (req, res) => {
  const start = performance.now();
  
  // Your function logic here
  
  const duration = performance.now() - start;
  console.log(`Function executed in ${duration}ms`);
});
```

## 🚀 **Deployment Commands**

### **Development**
```bash
# Start local emulators
firebase emulators:start

# Test functions locally
curl -X POST http://localhost:5001/flappyjet-pro/us-central1/submitScore \
  -H "Content-Type: application/json" \
  -d '{"playerId":"test123","score":50}'
```

### **Production**
```bash
# Deploy everything
firebase deploy

# Deploy only functions
firebase deploy --only functions

# Deploy only Firestore rules
firebase deploy --only firestore:rules

# View logs
firebase functions:log
```

## 🔧 **Advanced Configuration**

### 1. **Custom Domain**
```bash
# Add custom domain in Firebase Console
# Update DNS records as instructed
firebase hosting:channel:deploy production --expires 30d
```

### 2. **Environment Variables**
```bash
# Set production environment variables
firebase functions:config:set someservice.key="THE API KEY" someservice.id="THE CLIENT ID"

# Get current config
firebase functions:config:get
```

### 3. **Backup Strategy**
```bash
# Export Firestore data
gcloud firestore export gs://your-bucket/backup-folder

# Schedule automated backups
# (Configure in Firebase Console > Firestore > Backups)
```

## 🐛 **Troubleshooting**

### **Common Issues**

1. **CORS Errors**
   ```javascript
   // Ensure CORS is properly configured
   const cors = require('cors')({ origin: true });
   ```

2. **Function Timeout**
   ```javascript
   // Increase timeout for heavy operations
   exports.heavyFunction = functions.runWith({
     timeoutSeconds: 300,
     memory: '1GB'
   }).https.onRequest(handler);
   ```

3. **Cold Start Optimization**
   ```javascript
   // Keep functions warm with scheduled calls
   exports.keepWarm = functions.pubsub.schedule('every 5 minutes')
     .onRun(async (context) => {
       // Minimal operation to keep functions warm
       return null;
     });
   ```

### **Debugging**
```bash
# View real-time logs
firebase functions:log --follow

# Debug specific function
firebase functions:log --only submitScore

# Check function status
firebase functions:list
```

## 📈 **Performance Optimization**

### 1. **Firestore Optimization**
- Use composite indexes for complex queries
- Implement pagination for large datasets
- Cache frequently accessed data

### 2. **Function Optimization**
- Minimize cold starts with connection pooling
- Use appropriate memory allocation
- Implement proper error handling

### 3. **Client-Side Optimization**
- Implement offline-first architecture
- Batch multiple operations
- Use compression for large payloads

## 🔄 **CI/CD Pipeline**

Create `.github/workflows/deploy.yml`:
```yaml
name: Deploy to Firebase
on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: actions/setup-node@v2
        with:
          node-version: '18'
      - run: npm ci
        working-directory: ./server/functions
      - uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          repoToken: '${{ secrets.GITHUB_TOKEN }}'
          firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
          projectId: flappyjet-pro
```

---

## 🎯 **Ready for Production!**

Your FlappyJet Pro server is now production-ready with:
- ✅ Scalable serverless architecture
- ✅ Cost-effective pricing model
- ✅ Robust security measures
- ✅ Comprehensive monitoring
- ✅ Anti-cheat protection
- ✅ Real-time leaderboards
- ✅ Adaptive missions system

**Estimated setup time**: 30-60 minutes
**Monthly cost for 10K users**: $5-15
**Scalability**: Up to 1M+ users with automatic scaling
