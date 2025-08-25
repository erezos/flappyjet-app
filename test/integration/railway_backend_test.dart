/// 🚂 Railway Backend Integration Test
/// Tests the connection and basic functionality with the production backend

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

void main() {
  group('Railway Backend Integration Tests', () {
    const String backendUrl = 'https://flappyjet-backend-production.up.railway.app';
    
    test('Health check endpoint should respond', () async {
      final response = await http.get(Uri.parse('$backendUrl/health'));
      
      expect(response.statusCode, 200);
      
      final healthData = jsonDecode(response.body);
      expect(healthData['status'], 'healthy');
      expect(healthData['environment'], 'production');
      
      print('✅ Backend health check passed: ${healthData['status']}');
    });
    
    test('API documentation endpoint should respond', () async {
      final response = await http.get(Uri.parse(backendUrl));
      
      expect(response.statusCode, 200);
      
      final apiData = jsonDecode(response.body);
      expect(apiData['message'], contains('FlappyJet'));
      expect(apiData['endpoints'], isNotNull);
      
      print('✅ API documentation available');
      print('📋 Available endpoints: ${apiData['endpoints'].keys.join(', ')}');
    });
    
    test('User registration should work', () async {
      final deviceId = 'test-device-${DateTime.now().millisecondsSinceEpoch}';
      
      final response = await http.post(
        Uri.parse('$backendUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'deviceId': deviceId,
          'nickname': 'FlutterTestPlayer',
          'platform': 'ios',
          'appVersion': '1.0.0',
        }),
      );
      
      expect(response.statusCode, 200);
      
      final authData = jsonDecode(response.body);
      expect(authData['success'], true);
      expect(authData['isNewPlayer'], true);
      expect(authData['token'], isNotNull);
      expect(authData['player']['nickname'], 'FlutterTestPlayer');
      
      print('✅ User registration successful');
      print('👤 Player ID: ${authData['player']['id']}');
      print('🪙 Starting coins: ${authData['player']['current_coins']}');
      print('💎 Starting gems: ${authData['player']['current_gems']}');
    });
    
    test('Daily missions should be available', () async {
      // First register a user
      final deviceId = 'test-missions-${DateTime.now().millisecondsSinceEpoch}';
      
      final authResponse = await http.post(
        Uri.parse('$backendUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'deviceId': deviceId,
          'nickname': 'MissionsTestPlayer',
          'platform': 'ios',
        }),
      );
      
      final authData = jsonDecode(authResponse.body);
      final token = authData['token'];
      
      // Get daily missions
      final missionsResponse = await http.get(
        Uri.parse('$backendUrl/api/missions/daily'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      expect(missionsResponse.statusCode, 200);
      
      final missionsData = jsonDecode(missionsResponse.body);
      expect(missionsData['success'], true);
      expect(missionsData['missions'], isA<List>());
      expect(missionsData['missions'].length, greaterThan(0));
      
      print('✅ Daily missions loaded: ${missionsData['missions'].length} missions');
      
      for (final mission in missionsData['missions']) {
        print('🎯 ${mission['title']}: ${mission['description']} (${mission['reward']} coins)');
      }
    });
    
    test('Global leaderboard should be accessible', () async {
      final response = await http.get(
        Uri.parse('$backendUrl/api/leaderboard/global'),
      );
      
      expect(response.statusCode, 200);
      
      final leaderboardData = jsonDecode(response.body);
      expect(leaderboardData['success'], true);
      expect(leaderboardData['leaderboard'], isA<List>());
      expect(leaderboardData['pagination'], isNotNull);
      
      print('✅ Global leaderboard accessible');
      print('📊 Current entries: ${leaderboardData['leaderboard'].length}');
    });
    
    test('Score submission should work', () async {
      // Register user and get token
      final deviceId = 'test-score-${DateTime.now().millisecondsSinceEpoch}';
      
      final authResponse = await http.post(
        Uri.parse('$backendUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'deviceId': deviceId,
          'nickname': 'ScoreTestPlayer',
          'platform': 'ios',
        }),
      );
      
      final authData = jsonDecode(authResponse.body);
      final token = authData['token'];
      
      // Submit a test score
      final scoreResponse = await http.post(
        Uri.parse('$backendUrl/api/leaderboard/submit'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'score': 25,
          'survivalTime': 30,
          'skinUsed': 'sky_jet',
          'coinsEarned': 12,
          'gemsEarned': 2,
          'gameDuration': 30000,
        }),
      );
      
      expect(scoreResponse.statusCode, 200);
      
      final scoreData = jsonDecode(scoreResponse.body);
      expect(scoreData['success'], true);
      expect(scoreData['rank'], isA<int>());
      expect(scoreData['isPersonalBest'], true);
      
      print('✅ Score submission successful');
      print('🏆 Player rank: ${scoreData['rank']}');
      print('🎯 Score: 25 points');
    });
  });
  
  group('Railway Server Manager Integration', () {
    test('RailwayServerManager should initialize correctly', () async {
      // This would test the actual RailwayServerManager class
      // but requires the Flutter app context
      print('🚂 RailwayServerManager integration test would run here');
      print('📱 This requires running within the Flutter app context');
    });
  });
}
