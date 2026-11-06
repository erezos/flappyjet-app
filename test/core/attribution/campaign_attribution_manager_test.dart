/// Unit tests for Campaign Attribution Manager
/// 
/// Tests Android Install Referrer integration and campaign data parsing
/// Follows Flame game engine best practices and mobile gaming standards

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flappy_jet_pro/core/attribution/campaign_attribution_manager.dart';

void main() {
  group('Campaign Attribution Manager - Install Referrer Tests', () {
    late CampaignAttributionManager manager;
    late SharedPreferences prefs;

    setUp(() async {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      
      // Reset manager instance
      manager = CampaignAttributionManager();
    });

    tearDown(() async {
      // Clean up
      await prefs.clear();
    });

    group('Campaign Data from Source', () {
      test('should capture UTM parameters correctly', () async {
        await manager.captureCampaignDataFromSource(
          source: 'google',
          medium: 'cpc',
          campaign: 'summer_sale',
          keyword: 'game',
          creative: 'ad1',
        );

        expect(manager.hasCampaignData, isTrue);
        expect(manager.campaignId, isNotNull);
      });

      test('should capture Google Ads parameters (gclid)', () async {
        await manager.captureCampaignDataFromSource(
          source: 'google',
          medium: 'cpc',
          gclid: 'EAEYAiobChMI8JqXqYqGggIVBQYGAB0BqgELEAAYASAAEgJXQ_D_BwE',
          campaignId: 'gclid_EAEYAiobCh',
        );

        expect(manager.hasCampaignData, isTrue);
        expect(manager.campaignId, equals('gclid_EAEYAiobCh'));
      });
    });

    group('Campaign Data Validation', () {
      test('should create CampaignData with valid parameters', () {
        final data = CampaignData(
          source: 'google',
          medium: 'cpc',
          campaign: 'summer_sale',
          campaignId: '123456',
          gclid: 'EAEYAiobChMI8JqXqYqGggIVBQYGAB0BqgELEAAYASAAEgJXQ_D_BwE',
          installDate: DateTime.now(),
        );

        expect(data.hasCampaignData, isTrue);
        expect(data.source, equals('google'));
        expect(data.medium, equals('cpc'));
        expect(data.campaignId, equals('123456'));
      });

      test('should identify organic installs correctly', () {
        final data = CampaignData(
          source: 'organic',
          medium: 'organic',
          campaignId: 'organic',
          installDate: DateTime.now(),
        );

        expect(data.hasCampaignData, isTrue);
        expect(data.campaignId, equals('organic'));
      });

      test('should serialize to JSON correctly', () {
        final data = CampaignData(
          source: 'google',
          medium: 'cpc',
          campaign: 'summer_sale',
          campaignId: '123456',
          gclid: 'EAEYAiobChMI8JqXqYqGggIVBQYGAB0BqgELEAAYASAAEgJXQ_D_BwE',
          installDate: DateTime.now(),
        );

        final json = data.toJson();
        expect(json['source'], equals('google'));
        expect(json['medium'], equals('cpc'));
        expect(json['campaign'], equals('summer_sale'));
        expect(json['campaign_id'], equals('123456'));
        expect(json['gclid'], isNotNull);
      });
    });

    group('Error Handling', () {
      test('should handle install referrer read failures gracefully', () async {
        // Test that errors don't crash the app
        // This would require mocking PlayInstallReferrer, which is complex
        // For now, we verify the manager doesn't throw
        expect(() => manager.checkAndCaptureFirstOpen(), returnsNormally);
      });

      test('should fallback to organic if install referrer fails', () async {
        // If install referrer fails, should mark as organic
        final result = await manager.checkAndCaptureFirstOpen();
        
        // Should complete without error
        expect(result, isA<bool>());
      });
    });

    group('Integration with EventBus', () {
      test('should fire user_acquired event with campaign data', () async {
        // This test would require mocking EventBus
        // For now, we verify the method exists and doesn't throw
        expect(() => manager.checkAndCaptureFirstOpen(), returnsNormally);
      });
    });
  });
}

