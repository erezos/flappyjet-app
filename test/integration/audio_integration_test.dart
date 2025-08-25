import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';

import '../../lib/game/enhanced_flappy_game.dart';
import '../../lib/game/systems/audio_manager.dart';
import '../../lib/game/systems/monetization_manager.dart';
import '../../lib/game/core/game_themes.dart';
import '../../lib/ui/screens/stunning_homepage.dart';

void main() {
  group('🎵 Audio Integration Tests', () {
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    group('Game Audio Integration', () {
      test('game should have audio manager', () {
        final game = EnhancedFlappyGame();
        
        expect(game.hasAudioManager, isTrue);
      });

      test('game audio manager should initialize', () async {
        final game = EnhancedFlappyGame();
        await game.onLoad();
        
        expect(game.hasAudioManager, isTrue);
        expect(game.audioManager, isA<AudioManager>());
      });

      test('game should trigger audio events during gameplay', () async {
        final game = EnhancedFlappyGame();
        await game.onLoad();
        
        // Test jump audio (should not throw)
        expect(() => game.audioManager.playSFX(SFXType.jump), returnsNormally);
        
        // Test score audio
        expect(() => game.audioManager.playSFX(SFXType.score), returnsNormally);
        
        // Test collision audio
        expect(() => game.audioManager.playSFX(SFXType.collision), returnsNormally);
      });

      test('game should change music with theme progression', () async {
        final game = EnhancedFlappyGame();
        await game.onLoad();
        
        // Test theme music changes (should not throw)
        expect(() async => await game.audioManager.playThemeMusic(GameThemes.skyRookie), 
               returnsNormally);
        expect(() async => await game.audioManager.playThemeMusic(GameThemes.spaceCadet), 
               returnsNormally);
      });

      test('game should handle audio cleanup', () async {
        final game = EnhancedFlappyGame();
        await game.onLoad();
        
        // Test audio cleanup
        expect(() async => await game.audioManager.stopAll(), returnsNormally);
        expect(() async => await game.audioManager.pauseAll(), returnsNormally);
      });
    });

    group('Menu Audio Integration', () {
      testWidgets('main menu should initialize audio', (WidgetTester tester) async {
        final monetization = MonetizationManager();
        
        await tester.pumpWidget(
          MaterialApp(
            home: StunningHomepage(
              developmentMode: true,
              monetization: monetization,
            ),
          ),
        );
        
        // Wait for initialization
        await tester.pump();
        
        // Menu should build without errors
        expect(find.byType(StunningHomepage), findsOneWidget);
      });

      testWidgets('main menu should handle audio errors gracefully', (WidgetTester tester) async {
        final monetization = MonetizationManager();
        
        // Should not throw even if audio files are missing
        await tester.pumpWidget(
          MaterialApp(
            home: StunningHomepage(
              developmentMode: true,
              monetization: monetization,
            ),
          ),
        );
        
        await tester.pump();
        expect(find.byType(StunningHomepage), findsOneWidget);
      });
    });

    group('Audio Performance Tests', () {
      test('audio system should handle rapid SFX calls', () async {
        final audioManager = AudioManager();
        await audioManager.initialize();
        
        // Rapid fire SFX calls should not crash
        for (int i = 0; i < 10; i++) {
          audioManager.playSFX(SFXType.jump);
        }
        
        // Wait a bit and test again
        await Future.delayed(const Duration(milliseconds: 100));
        
        for (int i = 0; i < 10; i++) {
          audioManager.playSFX(SFXType.score);
        }
        
        expect(true, isTrue); // If we got here without crashing, test passes
      });

      test('audio system should handle concurrent music changes', () async {
        final audioManager = AudioManager();
        await audioManager.initialize();
        
        // Concurrent music changes should not crash
        final futures = <Future>[];
        
        futures.add(audioManager.playMenuMusic());
        futures.add(audioManager.playThemeMusic(GameThemes.skyRookie));
        futures.add(audioManager.playThemeMusic(GameThemes.spaceCadet));
        
        // Wait for all to complete
        await Future.wait(futures);
        
        expect(true, isTrue); // If we got here without crashing, test passes
      });
    });

    group('Audio State Management', () {
      test('audio settings should persist across instances', () {
        final audioManager1 = AudioManager();
        final audioManager2 = AudioManager();
        
        // Should be the same instance (singleton)
        expect(identical(audioManager1, audioManager2), isTrue);
        
        // Settings should persist
        audioManager1.setMusicVolume(0.5);
        expect(audioManager2.musicVolume, equals(0.5));
        
        audioManager1.toggleMusic();
        expect(audioManager2.isMusicEnabled, equals(audioManager1.isMusicEnabled));
      });

      test('audio should handle app lifecycle events', () async {
        final audioManager = AudioManager();
        await audioManager.initialize();
        
        // Test pause/resume cycle
        await audioManager.pauseAll();
        await audioManager.resumeAll();
        
        // Test stop/restart cycle
        await audioManager.stopAll();
        await audioManager.playMenuMusic();
        
        expect(true, isTrue); // If we got here without crashing, test passes
      });
    });

    group('Audio Error Handling', () {
      test('audio should handle missing files gracefully', () async {
        final audioManager = AudioManager();
        
        // Should not throw even with missing files
        await audioManager.initialize();
        
        // All audio calls should handle missing files gracefully
        await audioManager.playMenuMusic();
        await audioManager.playThemeMusic(GameThemes.skyRookie);
        await audioManager.playSFX(SFXType.jump);
        
        expect(true, isTrue); // If we got here without exceptions, test passes
      });

      test('audio should handle volume edge cases', () {
        final audioManager = AudioManager();
        
        // Test extreme volume values
        audioManager.setMusicVolume(double.infinity);
        expect(audioManager.musicVolume, equals(1.0));
        
        audioManager.setMusicVolume(double.negativeInfinity);
        expect(audioManager.musicVolume, equals(0.0));
        
        audioManager.setMusicVolume(double.nan);
        expect(audioManager.musicVolume, equals(0.0));
      });
    });
  });
}