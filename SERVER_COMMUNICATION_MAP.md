# 🌐 FlappyJet Pro - Complete Server Communication Map

**Document Version:** 1.0  
**Last Updated:** November 4, 2025  
**Base URL:** `https://flappyjet-backend-production.up.railway.app`

---

## 📊 Overview

This document maps **every** API call the Flutter app makes to the Railway backend server, organized by feature and service.

### Summary Statistics
- **Total API Endpoints Used:** 28+
- **Services Making Calls:** 7
- **HTTP Methods:** GET, POST, PUT, DELETE
- **Authentication:** JWT Bearer tokens
- **Timeout:** 15 seconds default

---

## 🔐 1. Authentication & Player Identity

### Service: `PlayerIdentityManager`
**File:** `lib/game/systems/player_identity_manager.dart`

#### 1.1 Register New Player
```http
POST /api/auth/register
Content-Type: application/json
```

**Request Body:**
```json
{
  "deviceId": "string",
  "nickname": "string",
  "platform": "android|ios",
  "appVersion": "string",
  "countryCode": "string",
  "timezone": "string"
}
```

**Response:**
```json
{
  "success": true,
  "token": "jwt_token_here",
  "player": {
    "id": "uuid",
    "nickname": "string",
    "deviceId": "string",
    "bestScore": 0,
    "bestStreak": 0,
    "totalGamesPlayed": 0,
    "currentCoins": 500,
    "currentGems": 25,
    "currentHearts": 3,
    "isPremium": false,
    "createdAt": "timestamp"
  }
}
```

**When Called:**
- First app launch
- After nickname selection
- When device ID doesn't exist on backend

**Flutter Code Location:**
```dart
// lib/game/systems/player_identity_manager.dart:214-236
Future<bool> _attemptRegistration(PlayerRegistration registration)
```

---

#### 1.2 Login Existing Player
```http
POST /api/auth/login
Content-Type: application/json
```

**Request Body:**
```json
{
  "deviceId": "string",
  "platform": "android|ios",
  "appVersion": "string"
}
```

**Response:**
```json
{
  "success": true,
  "token": "jwt_token_here",
  "player": {
    // Same as registration response
  }
}
```

**When Called:**
- Every app launch
- After device restart
- When returning from background

**Flutter Code Location:**
```dart
// lib/game/systems/player_identity_manager.dart:184-211
Future<bool> _attemptLogin()
```

---

#### 1.3 Get Player Profile
```http
GET /api/auth/profile
Authorization: Bearer {token}
```

**Response:**
```json
{
  "success": true,
  "player": {
    "id": "uuid",
    "nickname": "string",
    "bestScore": 100,
    "bestStreak": 50,
    "totalGamesPlayed": 150,
    "currentCoins": 5000,
    "currentGems": 250,
    "currentHearts": 3,
    "isPremium": false,
    "heartBoosterExpiry": "timestamp|null",
    "autoRefillExpiry": "timestamp|null",
    "createdAt": "timestamp",
    "lastActiveAt": "timestamp"
  }
}
```

**When Called:**
- After login/registration
- When restoring user data
- After device sync

**Flutter Code Location:**
```dart
// lib/services/user_restoration_service.dart:66-104
Future<Map<String, dynamic>?> _fetchUserProfile()
```

---

#### 1.4 Update Player Nickname
```http
PUT /api/auth/update-nickname
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "nickname": "string"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Nickname updated successfully",
  "nickname": "string"
}
```

**When Called:**
- When user changes nickname in settings
- Before tournament submission
- Force sync to backend

**Flutter Code Location:**
```dart
// lib/game/systems/player_identity_manager.dart:700-750
Future<bool> updateNicknameOnBackend(String nickname)
Future<bool> forceNicknameSyncToBackend()
```

---

## 🏆 2. Leaderboard System

### Service: `RailwayLeaderboardService`
**File:** `lib/services/railway_leaderboard_service.dart`

#### 2.1 Get Global Leaderboard
```http
GET /api/leaderboard/global?limit={limit}&offset={offset}&playerId={playerId}
```

**Query Parameters:**
- `limit`: Number of entries (default: 10, max: 100)
- `offset`: Pagination offset (default: 0)
- `playerId`: Optional - includes user position if provided

**Response:**
```json
{
  "success": true,
  "leaderboard": [
    {
      "rank": 1,
      "playerId": "uuid",
      "nickname": "string",
      "score": 1000,
      "jetSkin": "default_jet",
      "theme": "Tropical Paradise",
      "timestamp": "ISO8601"
    }
  ],
  "userPosition": {
    "rank": 150,
    "playerId": "uuid",
    "nickname": "string",
    "score": 500
  },
  "pagination": {
    "limit": 10,
    "offset": 0,
    "total": 5000
  }
}
```

**When Called:**
- Opening leaderboard screen
- Refreshing leaderboard
- Every 30 seconds (auto-refresh)
- After submitting score

**Flutter Code Location:**
```dart
// lib/services/railway_leaderboard_service.dart:23-83
Future<LeaderboardResult> getGlobalLeaderboard({
  int limit = 10,
  int offset = 0,
  bool includeUserPosition = true,
})
```

---

#### 2.2 Submit Score to Leaderboard
```http
POST /api/leaderboard/submit
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "score": 150,
  "jetSkin": "neon_racer",
  "theme": "Storm Clouds",
  "gameData": {
    "playTime": 180,
    "obstacles": 30,
    "coinsCollected": 15,
    "powerUpsUsed": 2
  }
}
```

**Response:**
```json
{
  "success": true,
  "newBest": true,
  "previousBest": 100,
  "globalRank": 150,
  "message": "New personal best!"
}
```

**When Called:**
- After every game ends
- Only if score > 0
- Only if authenticated

**Flutter Code Location:**
```dart
// lib/services/railway_leaderboard_service.dart:152-218
Future<ScoreSubmissionResult> submitScore({
  required int score,
  String? jetSkin,
  String? theme,
  Map<String, dynamic>? gameData,
})
```

---

#### 2.3 Get Personal Scores
```http
GET /api/leaderboard/player/{playerId}/scores?limit={limit}
Authorization: Bearer {token}
```

**Response:**
```json
{
  "success": true,
  "scores": [
    {
      "id": "uuid",
      "score": 150,
      "jetSkin": "neon_racer",
      "theme": "Storm Clouds",
      "timestamp": "ISO8601"
    }
  ]
}
```

**When Called:**
- Opening personal stats screen
- Viewing score history

**Flutter Code Location:**
```dart
// lib/services/railway_leaderboard_service.dart:86-149
Future<PersonalScoresResult> getPersonalScores({int limit = 10})
```

---

#### 2.4 Update Player Nickname (Leaderboard Service)
```http
POST /api/leaderboard/update-nickname
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "nickname": "string"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Nickname updated successfully",
  "updatedScores": 15
}
```

**When Called:**
- When syncing nickname to leaderboard
- After nickname change in PlayerIdentityManager

**Flutter Code Location:**
```dart
// lib/services/railway_leaderboard_service.dart:220-265
Future<NicknameUpdateResult> updateNickname({required String nickname})
```

---

## 🏆 3. Tournament System

### Service: `TournamentService`
**File:** `lib/services/tournament_service.dart`

#### 3.1 Get Current Active Tournament
```http
GET /api/tournaments/current
```

**Response:**
```json
{
  "success": true,
  "tournament": {
    "id": "uuid",
    "name": "Weekend Warrior",
    "description": "Compete for top prizes!",
    "status": "active",
    "startTime": "ISO8601",
    "endTime": "ISO8601",
    "entryFee": 0,
    "maxParticipants": 1000,
    "currentParticipants": 456,
    "prizes": [
      {"rank": 1, "coins": 10000, "gems": 500},
      {"rank": 2, "coins": 5000, "gems": 250},
      {"rank": 3, "coins": 2500, "gems": 100}
    ],
    "rules": {
      "gameMode": "endless",
      "maxAttempts": 3,
      "scoringType": "highest"
    }
  }
}
```

**When Called:**
- Opening tournament screen
- Every 60 seconds (auto-refresh)
- After app launch

**Flutter Code Location:**
```dart
// lib/services/tournament_service.dart:23-80
Future<ApiResult<Tournament?>> getCurrentTournament()
```

---

#### 3.2 Register for Tournament
```http
POST /api/tournaments/{tournamentId}/register
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "playerName": "string"
}
```

**Response:**
```json
{
  "success": true,
  "participantId": "uuid",
  "message": "Successfully registered",
  "tournament": {
    "id": "uuid",
    "name": "Weekend Warrior",
    "remainingAttempts": 3
  }
}
```

**When Called:**
- Clicking "Join Tournament" button
- First time entering tournament screen

**Flutter Code Location:**
```dart
// lib/services/tournament_service.dart:83-111
Future<ApiResult<String>> registerForTournament({
  required String tournamentId,
  required String playerName,
  required String authToken,
})
```

---

#### 3.3 Submit Tournament Score
```http
POST /api/tournaments/{tournamentId}/scores
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "score": 250,
  "gameData": {
    "playTime": 300,
    "obstacles": 50,
    "coinsCollected": 25
  }
}
```

**Response:**
```json
{
  "success": true,
  "newBest": true,
  "score": 250,
  "previousBest": 150,
  "rank": 45,
  "totalGames": 2,
  "remainingAttempts": 1,
  "prize": {
    "coins": 500,
    "gems": 50
  }
}
```

**When Called:**
- After each tournament game ends
- When user completes a tournament attempt

**Flutter Code Location:**
```dart
// lib/services/tournament_service.dart:114-148
Future<ApiResult<ScoreSubmissionResult>> submitScore({
  required String tournamentId,
  required int score,
  required String authToken,
  Map<String, dynamic>? gameData,
})
```

---

#### 3.4 Get Tournament Leaderboard
```http
GET /api/tournaments/{tournamentId}/leaderboard?limit={limit}&offset={offset}
```

**Response:**
```json
{
  "success": true,
  "leaderboard": [
    {
      "rank": 1,
      "playerId": "uuid",
      "nickname": "Pro Player",
      "score": 1500,
      "gamesPlayed": 3,
      "timestamp": "ISO8601"
    }
  ],
  "pagination": {
    "limit": 50,
    "offset": 0,
    "total": 456
  }
}
```

**When Called:**
- Opening tournament leaderboard tab
- Refreshing tournament rankings
- After submitting score

**Flutter Code Location:**
```dart
// lib/services/tournament_service.dart:151-194
Future<ApiResult<TournamentLeaderboardResponse>> getTournamentLeaderboard({
  required String tournamentId,
  int limit = 50,
  int offset = 0,
})
```

---

#### 3.5 Unified Tournament Session
```http
POST /api/tournaments/session
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body (Get Status):**
```json
{
  "tournamentId": "current",
  "action": "get_status",
  "playerName": "string"
}
```

**Request Body (Submit Score):**
```json
{
  "tournamentId": "current",
  "action": "submit_score",
  "playerName": "string",
  "score": 250,
  "gameData": {...}
}
```

**Response:**
```json
{
  "success": true,
  "tournament": {
    "id": "uuid",
    "name": "Weekend Warrior",
    "status": "active"
  },
  "player": {
    "isRegistered": true,
    "bestScore": 250,
    "rank": 45,
    "gamesPlayed": 2,
    "remainingAttempts": 1
  }
}
```

**When Called:**
- Before starting tournament game (get status)
- After tournament game ends (submit score)
- Checking registration status

**Flutter Code Location:**
```dart
// lib/services/tournament_service.dart:197-283
Future<ApiResult<TournamentSessionResult>> handleTournamentSession({
  String tournamentId = 'current',
  required String action,
  int? score,
  Map<String, dynamic>? gameData,
})
```

---

## 🎁 4. Prize Distribution

### Service: `PrizeDistributionService`
**File:** `lib/services/prize_distribution_service.dart`

#### 4.1 Check Pending Prizes
```http
GET /api/tournaments/prizes/pending
Authorization: Bearer {token}
```

**Response:**
```json
{
  "success": true,
  "prizes": [
    {
      "id": "uuid",
      "tournamentId": "uuid",
      "tournamentName": "Weekend Warrior",
      "rank": 3,
      "coins": 2500,
      "gems": 100,
      "createdAt": "ISO8601"
    }
  ]
}
```

**When Called:**
- App launch
- Opening rewards screen
- After tournament ends

**Flutter Code Location:**
```dart
// Inferred from service existence
Future<List<Prize>> checkPendingPrizes()
```

---

#### 4.2 Claim Prize
```http
POST /api/tournaments/prizes/claim
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "prizeId": "uuid"
}
```

**Response:**
```json
{
  "success": true,
  "claimed": {
    "coins": 2500,
    "gems": 100
  },
  "newBalance": {
    "coins": 7500,
    "gems": 350
  }
}
```

**When Called:**
- Clicking "Claim" button on prize notification
- Auto-claim on app launch

---

## ✅ 5. Nickname Validation

### Service: `NicknameValidationService`
**File:** `lib/services/nickname_validation_service.dart`

#### 5.1 Validate Nickname
```http
POST /api/player/validate-nickname
Content-Type: application/json
```

**Request Body:**
```json
{
  "nickname": "string",
  "clientValidation": {
    "passed": true,
    "checks": ["length", "characters", "profanity"]
  }
}
```

**Response (Success):**
```json
{
  "success": true,
  "message": "Nickname is valid and available",
  "cleanedNickname": "string",
  "serverValidation": {
    "profanityCheck": "passed",
    "reservedCheck": "passed",
    "availabilityCheck": "passed"
  }
}
```

**Response (Error):**
```json
{
  "success": false,
  "error": "This nickname is already taken",
  "errorType": "taken|profanity|reserved|invalid_characters",
  "suggestion": "Try adding numbers or modifying the name",
  "cleanedNickname": "string"
}
```

**When Called:**
- As user types nickname (debounced)
- Before submitting nickname
- Real-time validation

**Flutter Code Location:**
```dart
// lib/services/nickname_validation_service.dart
Future<NicknameValidationResult> validateNickname(String nickname)
```

---

## 💰 6. In-App Purchases (IAP)

### Service: `EnhancedIAPManager` & `IAPReceiptValidator`
**Files:** 
- `lib/services/enhanced_iap_manager.dart`
- `lib/services/iap_receipt_validator.dart`

#### 6.1 Validate Purchase Receipt
```http
POST /api/purchase/validate
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body (iOS):**
```json
{
  "platform": "ios",
  "receiptData": "base64_encoded_receipt",
  "transactionId": "string",
  "productId": "com.flappyjet.coins_1000"
}
```

**Request Body (Android):**
```json
{
  "platform": "android",
  "purchaseToken": "string",
  "packageName": "com.flappyjet.pro",
  "productId": "coins_1000",
  "orderId": "string"
}
```

**Response:**
```json
{
  "success": true,
  "valid": true,
  "purchase": {
    "transactionId": "string",
    "productId": "string",
    "purchaseDate": "ISO8601",
    "amount": 1000,
    "currency": "USD"
  },
  "rewards": {
    "coins": 1000,
    "gems": 50,
    "bonus": "First purchase bonus"
  }
}
```

**When Called:**
- After Google Play/App Store purchase completes
- Before granting in-game items
- For purchase fraud detection

**Flutter Code Location:**
```dart
// lib/services/iap_receipt_validator.dart
Future<bool> validateReceipt({
  required String platform,
  required String receiptData,
  required String productId,
})
```

---

#### 6.2 Get Purchase History
```http
GET /api/purchase/history
Authorization: Bearer {token}
```

**Response:**
```json
{
  "success": true,
  "purchases": [
    {
      "id": "uuid",
      "productId": "coins_1000",
      "amount": 1000,
      "currency": "USD",
      "purchaseDate": "ISO8601",
      "status": "completed"
    }
  ],
  "totalSpent": 9.99
}
```

**When Called:**
- Opening purchase history screen
- Restoring purchases

---

## 📊 7. Analytics

### Service: `UnifiedAnalyticsManager`
**File:** `lib/core/analytics/unified_analytics_manager.dart`

#### 7.1 Send Analytics Events (Batch)
```http
POST /api/analytics/events
Content-Type: application/json
```

**Request Body:**
```json
{
  "events": [
    {
      "eventType": "game_start",
      "playerId": "uuid",
      "deviceId": "string",
      "timestamp": "ISO8601",
      "data": {
        "gameMode": "endless",
        "jetSkin": "neon_racer"
      }
    },
    {
      "eventType": "game_end",
      "playerId": "uuid",
      "deviceId": "string",
      "timestamp": "ISO8601",
      "data": {
        "score": 150,
        "playTime": 180,
        "obstacles": 30
      }
    }
  ]
}
```

**Response:**
```json
{
  "success": true,
  "received": 2,
  "processed": 2
}
```

**When Called:**
- Every 30 seconds (batch send)
- App background/foreground transitions
- After significant events

**Event Types Tracked:**
- `app_open` - App launched
- `game_start` - Game begins
- `game_end` - Game ends with score
- `level_complete` - Story mode level done
- `purchase_attempt` - IAP initiated
- `purchase_complete` - IAP successful
- `ad_watched` - Rewarded ad viewed
- `share_attempt` - User shares score
- `setting_changed` - App settings modified
- `crash_reported` - App crashed

**Flutter Code Location:**
```dart
// lib/core/analytics/unified_analytics_manager.dart
Future<void> logEvent(String eventName, Map<String, dynamic> data)
Future<void> flushEventBatch()
```

---

#### 7.2 Send Analytics Events (V2 - Enhanced)
```http
POST /api/analytics/v2/events
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "events": [
    {
      "eventType": "session_start",
      "timestamp": "ISO8601",
      "sessionId": "uuid",
      "data": {
        "appVersion": "1.4.2",
        "osVersion": "Android 14",
        "deviceModel": "Pixel 8"
      }
    }
  ]
}
```

**Response:**
```json
{
  "success": true,
  "eventsProcessed": 1,
  "sessionId": "uuid"
}
```

**When Called:**
- Same as V1, but with enhanced session tracking
- Includes user cohort data
- Better funnel analysis

---

## 🔄 8. User Data Sync & Restoration

### Service: `UserRestorationService`
**File:** `lib/services/user_restoration_service.dart`

#### 8.1 Sync Player Progress
```http
POST /api/player/sync
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "bestScore": 150,
  "bestStreak": 50,
  "totalGamesPlayed": 100,
  "currentCoins": 5000,
  "currentGems": 250,
  "currentHearts": 3,
  "ownedSkins": ["default_jet", "neon_racer"],
  "equippedSkin": "neon_racer",
  "achievements": ["first_flight", "score_100"],
  "levelProgress": {
    "zone1": {"completed": 10, "stars": 25},
    "zone2": {"completed": 8, "stars": 20}
  }
}
```

**Response:**
```json
{
  "success": true,
  "synced": true,
  "timestamp": "ISO8601",
  "conflicts": []
}
```

**When Called:**
- Every 5 minutes (if online)
- After significant progress (level complete, purchase)
- App background/foreground transitions
- Manual sync button

**Flutter Code Location:**
```dart
// lib/services/user_restoration_service.dart
Future<bool> syncPlayerProgress()
```

---

#### 8.2 Restore Player Progress
```http
GET /api/player/restore
Authorization: Bearer {token}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "bestScore": 150,
    "bestStreak": 50,
    "totalGamesPlayed": 100,
    "currentCoins": 5000,
    "currentGems": 250,
    "currentHearts": 3,
    "ownedSkins": ["default_jet", "neon_racer"],
    "equippedSkin": "neon_racer",
    "achievements": ["first_flight", "score_100"],
    "levelProgress": {...},
    "lastSync": "ISO8601"
  }
}
```

**When Called:**
- Fresh app install
- After uninstall/reinstall
- Switching devices
- "Restore Purchases" button

---

## 🎒 9. Inventory Sync

### Service: `InventorySyncService`
**File:** `lib/services/inventory_sync_service.dart`

#### 9.1 Sync Inventory
```http
POST /api/inventory/sync
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "skins": {
    "owned": ["default_jet", "neon_racer", "storm_blade"],
    "equipped": "neon_racer"
  },
  "boosters": {
    "heartBooster": {
      "active": true,
      "expiry": "ISO8601"
    },
    "autoRefill": {
      "active": false
    }
  },
  "powerUps": {
    "shield": 5,
    "magnet": 3,
    "doubleCoins": 10
  }
}
```

**Response:**
```json
{
  "success": true,
  "synced": true,
  "conflicts": []
}
```

**When Called:**
- After skin purchase
- After booster activation
- Every 5 minutes (background sync)

---

## 📱 10. Push Notifications (FCM)

### Service: `FCMService`
**Related File:** Backend handles FCM token storage

#### 10.1 Register FCM Token
```http
POST /api/fcm/register
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "fcmToken": "string",
  "platform": "android|ios",
  "deviceInfo": {
    "model": "string",
    "osVersion": "string"
  }
}
```

**Response:**
```json
{
  "success": true,
  "registered": true
}
```

**When Called:**
- App first launch
- FCM token refresh
- After login

---

#### 10.2 Update Notification Preferences
```http
PUT /api/fcm/preferences
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "enableNotifications": true,
  "enableTournamentAlerts": true,
  "enableDailyReminders": false,
  "enablePrizeAlerts": true
}
```

---

## 📈 Summary Table

| # | Endpoint | Method | Auth | Purpose | Frequency |
|---|----------|--------|------|---------|-----------|
| 1 | `/api/auth/register` | POST | No | Register new player | Once per install |
| 2 | `/api/auth/login` | POST | No | Login existing player | Every app launch |
| 3 | `/api/auth/profile` | GET | Yes | Get player data | After login |
| 4 | `/api/auth/update-nickname` | PUT | Yes | Update nickname | On change |
| 5 | `/api/leaderboard/global` | GET | No | Global rankings | Every 30s |
| 6 | `/api/leaderboard/submit` | POST | Yes | Submit score | Every game end |
| 7 | `/api/leaderboard/player/{id}/scores` | GET | Yes | Personal scores | On request |
| 8 | `/api/leaderboard/update-nickname` | POST | Yes | Sync nickname | On change |
| 9 | `/api/tournaments/current` | GET | No | Get active tournament | Every 60s |
| 10 | `/api/tournaments/{id}/register` | POST | Yes | Join tournament | Once per tournament |
| 11 | `/api/tournaments/{id}/scores` | POST | Yes | Submit tournament score | Per attempt |
| 12 | `/api/tournaments/{id}/leaderboard` | GET | No | Tournament rankings | On refresh |
| 13 | `/api/tournaments/session` | POST | Yes | Unified tournament API | Per game |
| 14 | `/api/tournaments/prizes/pending` | GET | Yes | Check prizes | App launch |
| 15 | `/api/tournaments/prizes/claim` | POST | Yes | Claim prize | On claim |
| 16 | `/api/player/validate-nickname` | POST | No | Validate nickname | On typing |
| 17 | `/api/player/sync` | POST | Yes | Sync progress | Every 5 min |
| 18 | `/api/player/restore` | GET | Yes | Restore progress | On restore |
| 19 | `/api/purchase/validate` | POST | Yes | Validate IAP | Per purchase |
| 20 | `/api/purchase/history` | GET | Yes | Purchase history | On request |
| 21 | `/api/analytics/events` | POST | No | Send analytics | Every 30s |
| 22 | `/api/analytics/v2/events` | POST | Yes | Enhanced analytics | Every 30s |
| 23 | `/api/inventory/sync` | POST | Yes | Sync inventory | Every 5 min |
| 24 | `/api/fcm/register` | POST | Yes | Register FCM token | On token refresh |
| 25 | `/api/fcm/preferences` | PUT | Yes | Update notifications | On settings change |

---

## 🔒 Authentication Pattern

**All authenticated endpoints use:**
```http
Authorization: Bearer {jwt_token}
Content-Type: application/json
```

**Token Management:**
1. Token obtained from `/api/auth/login` or `/api/auth/register`
2. Token stored in `SharedPreferences`
3. Token included in all authenticated requests
4. Token expires after 30 days
5. Token refresh handled automatically on 401/403 responses

**Token Refresh Flow:**
```dart
// Automatic token refresh on auth failure
if (response.statusCode == 401 || response.statusCode == 403) {
  final refreshed = await _refreshToken();
  if (refreshed) {
    // Retry original request with new token
  }
}
```

---

## ⚡ Network Performance

### Timeout Configuration
```dart
static const Duration requestTimeout = Duration(seconds: 15);
```

### Retry Logic
- **Max Retries:** 3
- **Backoff:** Exponential (1s, 2s, 4s)
- **Retry on:** Network errors, 5xx status codes
- **No retry on:** 4xx status codes (client errors)

### Caching Strategy
- **Leaderboard:** 30 second client-side cache
- **Tournaments:** 60 second client-side cache
- **Player Profile:** No cache (always fresh)
- **Analytics:** Batch queue (30s flush interval)

---

## 🚨 Error Handling

### HTTP Status Codes
- `200` - Success
- `201` - Created (registration, etc.)
- `400` - Bad Request (validation error)
- `401` - Unauthorized (invalid/expired token)
- `403` - Forbidden (insufficient permissions)
- `404` - Not Found
- `429` - Too Many Requests (rate limit)
- `500` - Internal Server Error
- `503` - Service Unavailable

### Error Response Format
```json
{
  "success": false,
  "error": "Human readable error message",
  "code": "ERROR_CODE_CONSTANT",
  "details": {
    "field": "nickname",
    "reason": "already_taken"
  }
}
```

---

## 📊 Data Flow Diagrams

### App Launch Flow
```
App Start
    ↓
Load Local Data
    ↓
GET /api/auth/login ───────→ Success → GET /api/auth/profile
    ↓                                            ↓
  Failed                                   Sync Local Data
    ↓                                            ↓
POST /api/auth/register                   Continue to Home
    ↓
GET /api/auth/profile
    ↓
Continue to Home
```

### Game End Flow
```
Game Ends
    ↓
Save Score Locally
    ↓
POST /api/leaderboard/submit ────→ Success → Update UI
    ↓                                            ↓
  Failed (offline)                    POST /api/analytics/events
    ↓                                            ↓
Queue for Retry                         Return to Home
    ↓
Retry on Network Available
```

### Tournament Flow
```
Open Tournament
    ↓
GET /api/tournaments/current
    ↓
User Clicks "Join"
    ↓
POST /api/tournaments/{id}/register
    ↓
Start Tournament Game
    ↓
Game Ends
    ↓
POST /api/tournaments/{id}/scores
    ↓
GET /api/tournaments/{id}/leaderboard
    ↓
Display Results
```

---

## 🎯 API Usage Frequency

**Per User Per Day (Estimated):**
```
App launches:                   3-5 times
Login calls:                    3-5 calls
Game plays:                     10-30 games
Score submissions:              10-30 calls
Leaderboard views:              5-15 calls (150-450 fetches with refresh)
Tournament checks:              2-10 calls (120-600 fetches with refresh)
Analytics events:               200-500 events (7-17 batch calls)
Progress syncs:                 24-144 calls (every 5min if online)
Nickname validations:           0-50 calls (if changing nickname)
Purchase validations:           0-2 calls
```

**Total API Calls Per Active User Per Day: ~450-1,300 calls**

---

## 🔌 Offline Handling

### Offline-Capable Operations
- ✅ Play endless mode
- ✅ Play story mode
- ✅ Earn coins/gems locally
- ✅ Purchase skins (local)
- ✅ View local leaderboard
- ✅ Complete achievements

### Requires Online
- ❌ Global leaderboard
- ❌ Tournaments
- ❌ Cloud save sync
- ❌ Nickname validation (server-side)
- ❌ IAP receipt validation
- ❌ Prize claiming

### Queue-and-Retry
When offline, these are queued:
- Score submissions
- Analytics events
- Progress syncs
- Inventory syncs

Queued calls retry when network returns.

---

## 🎭 Development vs Production

**Base URLs:**
```dart
// Development
const String DEV_BASE_URL = 'http://localhost:3000';

// Production
const String PROD_BASE_URL = 'https://flappyjet-backend-production.up.railway.app';
```

**Current Configuration:**
```dart
// lib/game/systems/player_identity_manager.dart:71
static const String baseUrl = 'https://flappyjet-backend-production.up.railway.app';
```

---

## 📋 Migration Checklist

**To move to client-only, you would need to remove/modify:**

### Services to Remove
- [x] `TournamentService` (28 endpoints)
- [x] `RailwayLeaderboardService` (global features)
- [x] `UserRestorationService` (cloud sync)
- [x] `IAPReceiptValidator` (server validation)
- [x] `NicknameValidationService` (server validation)
- [x] `PrizeDistributionService` (prize claiming)
- [x] `InventorySyncService` (cloud inventory)

### Services to Keep (Modified)
- [ ] `PlayerIdentityManager` - Keep local-only identity
- [ ] `UnifiedAnalyticsManager` - Fire-and-forget analytics only

### New Services Needed
- [ ] `LocalLeaderboardService` - Device-only rankings
- [ ] `LocalTournamentService` - Offline challenges
- [ ] `LocalBackupService` - Export/import player data

**Total Endpoints to Remove: ~25 out of 28**  
**Endpoints to Keep: ~3 (analytics only)**

---

**End of Document** 📄

This map covers all server communications in the FlappyJet Pro Flutter app. For migration to client-only architecture, refer to `CLIENT_ONLY_ARCHITECTURE_ANALYSIS.md`.


