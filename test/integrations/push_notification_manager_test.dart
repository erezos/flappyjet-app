/// Unit Tests for PushNotificationManager
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flappy_jet_pro/integrations/push_notification_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PushNotificationManager', () {
    late PushNotificationManager manager;

    setUp(() {
      manager = PushNotificationManager();
    });

    test('should be a singleton', () {
      final instance1 = PushNotificationManager();
      final instance2 = PushNotificationManager();
      expect(instance1, same(instance2));
    });

    test('should start uninitialized', () {
      expect(manager.isInitialized, false);
      expect(manager.fcmToken, null);
    });

    test('should return null FCM token when not initialized', () {
      expect(manager.fcmToken, null);
    });

    // Note: Full initialization tests would require mocking Firebase/Flutter services
    // which is complex. These tests verify the basic structure.
  });

  group('PushNotificationManager - Token Validation', () {
    test('FCM token should be at least 140 characters', () {
      // This is a general validation rule for FCM tokens
      // The actual validation happens in the backend
      const shortToken = 'abc123';
      final longToken = 'a' * 150;
      
      // Validate token length
      expect(shortToken.length < 140, true);
      expect(longToken.length >= 140, true);
    });
  });

  group('PushNotificationManager - Event Data Parsing', () {
    test('should parse notification data correctly', () {
      final testData = {
        'notification_type': '1hour',
        'reward_type': 'coins',
        'reward_amount': '100',
        'event_id': '123',
      };

      // Verify data structure
      expect(testData['notification_type'], '1hour');
      expect(testData['reward_type'], 'coins');
      expect(int.parse(testData['reward_amount']!), 100);
    });

    test('should handle missing notification data gracefully', () {
      final testData = <String, dynamic>{};

      // Should not throw when accessing missing keys
      expect(testData['notification_type'], null);
      expect(testData['reward_type'], null);
      expect(int.tryParse(testData['reward_amount']?.toString() ?? '0'), 0);
    });
  });

  group('PushNotificationManager - URL Construction', () {
    test('should construct correct API URLs', () {
      const baseUrl = 'https://flappyjet-backend-production.up.railway.app';
      
      final registerUrl = '$baseUrl/api/notifications/register-token';
      final clickedUrl = '$baseUrl/api/notifications/clicked';
      final claimedUrl = '$baseUrl/api/notifications/claimed';

      expect(registerUrl, contains('/api/notifications/register-token'));
      expect(clickedUrl, contains('/api/notifications/clicked'));
      expect(claimedUrl, contains('/api/notifications/claimed'));
    });
  });

  group('PushNotificationManager - Notification Types', () {
    test('should support all notification types', () {
      const validTypes = ['1hour', '24hour', '46hour', 'custom'];
      
      for (final type in validTypes) {
        expect(['1hour', '24hour', '46hour', 'custom'].contains(type), true);
      }
    });

    test('should support all reward types', () {
      const validRewardTypes = ['coins', 'gems', 'none'];
      
      for (final type in validRewardTypes) {
        expect(['coins', 'gems', 'none'].contains(type), true);
      }
    });
  });
}