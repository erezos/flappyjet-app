import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../lib/game/components/jet_fire_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Universal thrust manager loads without asset and provides procedural fallback', () async {
    final mgr = JetFireStateManager();
    await mgr.onLoad();
    // Should not throw when rendering without asset
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    mgr.triggerFire();
    await mgr.renderThrust(
      canvas,
      center: const Offset(0, 0),
      width: 64,
      height: 64,
      tint: Colors.orange,
      intensity: 1.0,
      scale: 1.0,
    );
    recorder.endRecording();
  });
}


