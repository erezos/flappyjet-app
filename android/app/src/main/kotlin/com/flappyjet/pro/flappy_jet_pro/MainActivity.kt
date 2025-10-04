package com.flappyjet.pro.flappy_jet_pro

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val AUDIO_CHANNEL = "flappyjet.audio.native"
    private lateinit var audioEngine: NativeAudioEngine

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Initialize native audio engine
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUDIO_CHANNEL)
        audioEngine = NativeAudioEngine(this, channel)
        channel.setMethodCallHandler(audioEngine)
    }

    override fun onDestroy() {
        super.onDestroy()
        // Clean up audio engine
        if (::audioEngine.isInitialized) {
            // The dispose will be called through the method channel
        }
    }
}
