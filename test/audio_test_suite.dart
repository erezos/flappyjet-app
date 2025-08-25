/// 🎵 Audio Test Suite - Complete Audio System Testing
/// Run this file to test all audio-related functionality

import 'package:flutter_test/flutter_test.dart';

// Import all audio test files
import 'unit/audio_system_test.dart' as unit_tests;
import 'integration/audio_integration_test.dart' as integration_tests;
import 'widget/main_menu_audio_test.dart' as widget_tests;

void main() {
  group('🎵 Complete Audio System Test Suite', () {
    group('Unit Tests', () {
      unit_tests.main();
    });

    group('Integration Tests', () {
      integration_tests.main();
    });

    group('Widget Tests', () {
      widget_tests.main();
    });
  });
}