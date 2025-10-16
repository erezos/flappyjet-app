# 🌐 **STORY MODE API ENDPOINTS DESIGN**

## Overview
This document defines the REST API endpoints for Story Mode integration with Railway backend.

---

## **BASE URL**
```
Production: https://flappyjet-backend-production.up.railway.app
Development: http://localhost:3000
```

---

## **ENDPOINTS**

### **1. GET /api/story-mode/progress**
Get player's overall story mode progress.

#### **Request**
```http
GET /api/story-mode/progress
Authorization: Bearer <jwt_token>
```

#### **Response (200 OK)**
```json
{
  "success": true,
  "data": {
    "currentLevel": 5,
    "highestLevelUnlocked": 5,
    "totalLevelsCompleted": 4,
    "currentZone": 1,
    "zonesCompleted": 0,
    "totalCoinsEarned": 80,
    "totalGemsEarned": 0,
    "botBattlesWon": 0,
    "botBattlesLost": 0,
    "lastPlayed": "2025-10-05T12:34:56Z"
  }
}
```

#### **Response (404 Not Found)**
```json
{
  "success": false,
  "error": "No story mode progress found",
  "data": {
    "currentLevel": 1,
    "highestLevelUnlocked": 1,
    "totalLevelsCompleted": 0
  }
}
```

---

### **2. POST /api/story-mode/level/start**
Record that a player started a level attempt.

#### **Request**
```http
POST /api/story-mode/level/start
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "levelId": 5,
  "attemptNumber": 1
}
```

#### **Response (200 OK)**
```json
{
  "success": true,
  "data": {
    "attemptId": 12345,
    "levelId": 5,
    "startedAt": "2025-10-05T12:34:56Z"
  }
}
```

---

### **3. POST /api/story-mode/level/complete**
Record level completion (success or failure).

#### **Request**
```http
POST /api/story-mode/level/complete
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "levelId": 5,
  "completed": true,
  "objectiveType": "pass_obstacles",
  "objectiveTarget": 6,
  "objectiveAchieved": 6,
  "attempts": 1,
  "timeTakenSeconds": 45,
  "continuesUsed": 2,
  "continuesAd": 2,
  "continuesGems": 0,
  "botBattle": false,
  "botDefeated": null,
  "botName": null,
  "coinsEarned": 20,
  "gemsEarned": 0,
  "specialReward": null
}
```

#### **Response (200 OK)**
```json
{
  "success": true,
  "data": {
    "completionId": 67890,
    "levelId": 5,
    "completed": true,
    "coinsEarned": 20,
    "gemsEarned": 0,
    "nextLevelUnlocked": 6,
    "zoneCompleted": false
  }
}
```

#### **Response (200 OK - Zone Completed)**
```json
{
  "success": true,
  "data": {
    "completionId": 67890,
    "levelId": 10,
    "completed": true,
    "coinsEarned": 20,
    "gemsEarned": 10,
    "nextLevelUnlocked": 11,
    "zoneCompleted": true,
    "zoneNumber": 1,
    "zoneName": "Tropical Islands"
  }
}
```

---

### **4. POST /api/story-mode/level/attempt**
Record a single attempt (including failures).

#### **Request**
```http
POST /api/story-mode/level/attempt
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "levelId": 7,
  "attemptNumber": 2,
  "success": false,
  "scoreAchieved": 3,
  "continuesUsed": 5,
  "continuesAd": 3,
  "continuesGems": 2,
  "failureReason": "out_of_continues",
  "durationSeconds": 67
}
```

#### **Response (200 OK)**
```json
{
  "success": true,
  "data": {
    "attemptId": 11111,
    "levelId": 7,
    "attemptNumber": 2,
    "recorded": true
  }
}
```

---

### **5. GET /api/story-mode/level/:levelId/stats**
Get difficulty statistics for a specific level (for analytics).

#### **Request**
```http
GET /api/story-mode/level/7/stats
Authorization: Bearer <jwt_token>
```

#### **Response (200 OK)**
```json
{
  "success": true,
  "data": {
    "levelId": 7,
    "totalAttempts": 1523,
    "completions": 1205,
    "completionRate": 79.12,
    "avgContinuesUsed": 1.85,
    "avgContinuesOnSuccess": 1.42,
    "maxContinuesUsed": 5,
    "firstTryCompletions": 234,
    "avgAttemptsToComplete": 2.3
  }
}
```

---

### **6. GET /api/story-mode/leaderboard/zone/:zoneId**
Get zone completion leaderboard (fastest completions).

#### **Request**
```http
GET /api/story-mode/leaderboard/zone/1?limit=100
Authorization: Bearer <jwt_token>
```

#### **Response (200 OK)**
```json
{
  "success": true,
  "data": {
    "zone": 1,
    "zoneName": "Tropical Islands",
    "leaderboard": [
      {
        "rank": 1,
        "playerName": "ProGamer123",
        "totalTime": 450,
        "avgContinuesUsed": 0.5,
        "completedAt": "2025-10-05T10:00:00Z"
      },
      {
        "rank": 2,
        "playerName": "SpeedRunner",
        "totalTime": 478,
        "avgContinuesUsed": 1.2,
        "completedAt": "2025-10-05T11:30:00Z"
      }
    ]
  }
}
```

---

### **7. GET /api/story-mode/level/:levelId/history**
Get player's attempt history for a specific level.

#### **Request**
```http
GET /api/story-mode/level/7/history
Authorization: Bearer <jwt_token>
```

#### **Response (200 OK)**
```json
{
  "success": true,
  "data": {
    "levelId": 7,
    "attempts": [
      {
        "attemptNumber": 1,
        "success": false,
        "scoreAchieved": 2,
        "continuesUsed": 5,
        "failureReason": "out_of_continues",
        "startedAt": "2025-10-05T12:00:00Z",
        "durationSeconds": 45
      },
      {
        "attemptNumber": 2,
        "success": true,
        "scoreAchieved": 5,
        "continuesUsed": 2,
        "failureReason": null,
        "startedAt": "2025-10-05T12:10:00Z",
        "durationSeconds": 67
      }
    ],
    "totalAttempts": 2,
    "bestScore": 5,
    "completed": true
  }
}
```

---

### **8. POST /api/story-mode/sync**
Sync all story mode progress from client to server (for offline play support).

#### **Request**
```http
POST /api/story-mode/sync
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "progress": {
    "currentLevel": 15,
    "highestLevelUnlocked": 15,
    "totalLevelsCompleted": 14,
    "currentZone": 2,
    "totalCoinsEarned": 280,
    "totalGemsEarned": 10
  },
  "completions": [
    {
      "levelId": 14,
      "completed": true,
      "continuesUsed": 1,
      "coinsEarned": 40,
      "completedAt": "2025-10-05T12:00:00Z"
    }
  ]
}
```

#### **Response (200 OK)**
```json
{
  "success": true,
  "data": {
    "synced": true,
    "progressUpdated": true,
    "completionsRecorded": 1,
    "conflicts": []
  }
}
```

---

## **ERROR RESPONSES**

### **400 Bad Request**
```json
{
  "success": false,
  "error": "Invalid level ID",
  "details": "Level ID must be between 1 and 100"
}
```

### **401 Unauthorized**
```json
{
  "success": false,
  "error": "Authentication required",
  "details": "Please provide a valid JWT token"
}
```

### **403 Forbidden**
```json
{
  "success": false,
  "error": "Level not unlocked",
  "details": "You must complete level 4 first"
}
```

### **500 Internal Server Error**
```json
{
  "success": false,
  "error": "Database error",
  "details": "Failed to save level completion"
}
```

---

## **AUTHENTICATION**

All endpoints require JWT authentication via the `Authorization` header:

```http
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

The JWT token should contain:
```json
{
  "playerId": 12345,
  "email": "player@example.com",
  "iat": 1696512000,
  "exp": 1696598400
}
```

---

## **RATE LIMITING**

- **General endpoints:** 100 requests per minute
- **Completion endpoints:** 20 requests per minute (prevent spam)
- **Leaderboard endpoints:** 10 requests per minute

---

## **ANALYTICS EVENTS**

All story mode actions should also log to `analytics_events` table:

### **Event Types**
- `story_level_start` - Player started a level
- `story_level_complete` - Player completed a level
- `story_level_failed` - Player failed a level
- `story_zone_complete` - Player completed a zone
- `story_bot_battle_won` - Player won a bot battle
- `story_bot_battle_lost` - Player lost a bot battle
- `story_continue_used` - Player used a continue (track ad vs gems)

### **Example Event**
```json
{
  "player_id": 12345,
  "event_type": "story_level_complete",
  "event_category": "story_mode",
  "event_data": {
    "level_id": 7,
    "continues_used": 2,
    "continues_ad": 2,
    "continues_gems": 0,
    "time_taken": 67,
    "coins_earned": 40,
    "bot_battle": true,
    "bot_defeated": true
  },
  "created_at": "2025-10-05T12:34:56Z"
}
```

---

## **IMPLEMENTATION CHECKLIST**

### **Backend (Railway)**
- [ ] Create story mode route file (`routes/story-mode.js`)
- [ ] Implement all 8 endpoints
- [ ] Add JWT authentication middleware
- [ ] Add rate limiting
- [ ] Add analytics event logging
- [ ] Write integration tests
- [ ] Deploy to Railway

### **Frontend (Flutter)**
- [ ] Create `StoryModeApiService` class
- [ ] Implement API calls for all endpoints
- [ ] Add offline queue for sync
- [ ] Handle authentication errors
- [ ] Add retry logic for failed requests
- [ ] Write unit tests

---

**Last Updated:** October 5, 2025
**Version:** 1.0
**Status:** Ready for Implementation 🚀
