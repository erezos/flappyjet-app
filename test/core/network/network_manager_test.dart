/// 🧪 Network Manager Tests - Simplified test suite
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flappy_jet_pro/core/network/network_manager.dart';

void main() {
  group('NetworkManager Tests', () {
    late NetworkManager networkManager;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      networkManager = NetworkManager();
    });

    // Note: NetworkManager is a singleton, so we don't dispose in tests

    group('Initialization', () {
      test('should initialize with online state', () {
        expect(networkManager.isOnline, isTrue);
        expect(networkManager.hasActiveRequests, isFalse);
      });
    });

    group('NetworkRequest Model', () {
      test('should create request with default values', () {
        final request = NetworkRequest(endpoint: '/api/test');

        expect(request.endpoint, equals('/api/test'));
        expect(request.method, equals('GET'));
        expect(request.requiresAuth, isTrue);
        expect(request.canQueue, isTrue);
        expect(request.maxRetries, equals(3));
      });

      test('should create request with custom values', () {
        final request = NetworkRequest(
          endpoint: '/api/custom',
          method: 'POST',
          body: {'test': 'data'},
          requiresAuth: false,
          canQueue: false,
          maxRetries: 1,
        );

        expect(request.endpoint, equals('/api/custom'));
        expect(request.method, equals('POST'));
        expect(request.body!['test'], equals('data'));
        expect(request.requiresAuth, isFalse);
        expect(request.canQueue, isFalse);
        expect(request.maxRetries, equals(1));
      });
    });

    group('NetworkResult Model', () {
      test('should create success result', () {
        final result = NetworkResult.success({'data': 'test'});

        expect(result.success, isTrue);
        expect(result.data!['data'], equals('test'));
        expect(result.error, isNull);
        expect(result.fromCache, isFalse);
      });

      test('should create error result', () {
        final result = NetworkResult.error('Test error', statusCode: 400);

        expect(result.success, isFalse);
        expect(result.data, isNull);
        expect(result.error, equals('Test error'));
        expect(result.statusCode, equals(400));
      });

      test('should create cached result', () {
        final result = NetworkResult.cached({'cached': 'data'});

        expect(result.success, isTrue);
        expect(result.data!['cached'], equals('data'));
        expect(result.fromCache, isTrue);
      });
    });

    group('Network Statistics', () {
      test('should provide network stats', () {
        final stats = networkManager.getNetworkStats();

        expect(stats['isOnline'], isTrue);
        expect(stats['activeRequests'], equals(0));
        expect(stats.containsKey('queuedRequests'), isTrue);
      });
    });
  });
}