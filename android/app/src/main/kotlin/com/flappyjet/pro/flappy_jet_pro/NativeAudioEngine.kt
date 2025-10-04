package com.flappyjet.pro.flappy_jet_pro

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioFocusRequest
import android.media.MediaPlayer
import android.media.SoundPool
import android.os.Build
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.*
import java.io.File
import java.util.concurrent.ConcurrentHashMap
import kotlin.io.path.createTempFile
import kotlin.math.min

/**
 * Native Audio Engine for FlappyJet - AAA Mobile Game Audio
 * 
 * Features:
 * - Ultra-low latency SFX using SoundPool + seamless music using MediaPlayer
 * - Professional audio mixing and effects
 * - Proper MediaPlayer usage for music (no ANRs or crashes)
 * - Optimized for mobile game performance
 * - Support for Android 7.0+ (API 24+)
 */
class NativeAudioEngine(private val context: Context, private val channel: MethodChannel) : MethodCallHandler {
    
    companion object {
        private const val TAG = "FlappyJetAudio"
        private const val MAX_STREAMS = 16
    }

    // Audio system components - HYBRID ARCHITECTURE
    private var soundPool: SoundPool? = null        // For SFX only
    private var musicPlayer: MediaPlayer? = null    // For music only
    private var audioManager: AudioManager? = null
    
    // Audio Focus Management (Android Best Practice)
    private var audioFocusRequest: AudioFocusRequest? = null
    private var hasAudioFocus = false
    
    // Track management - HYBRID SYSTEM
    private val soundMap = ConcurrentHashMap<String, Int>()           // SFX tracks only
    private val musicAssets = ConcurrentHashMap<String, ByteArray>()  // Music data cache
    private val activeStreams = ConcurrentHashMap<Int, String>()      // Active SFX streams
    
    // Engine state
    private var isInitialized = false
    private var masterVolume = 1.0f
    private var musicVolume = 1.0f
    private var sfxVolume = 1.0f
    private var currentMusicTrackId: String? = null
    private var isMusicPlaying = false
    private var wasMusicPausedByFocusLoss = false
    
    // Performance monitoring
    private var activeSounds = 0
    
    // Coroutine scope for async operations
    private val engineScope = CoroutineScope(Dispatchers.Main + SupervisorJob())

    // AudioTrackData class removed - no longer needed with hybrid system

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initialize" -> initialize(call, result)
            "registerTrack" -> registerTrack(call, result)
            "playSFX" -> playSFX(call, result)
            "playMusic" -> playMusic(call, result)
            "stopMusic" -> stopMusic(result)
            "pauseMusic" -> pauseMusic(result)
            "resumeMusic" -> resumeMusic(result)
            "setMasterVolume" -> setMasterVolume(call, result)
            "getStats" -> getStats(result)
            "dispose" -> dispose(result)
            else -> result.notImplemented()
        }
    }

    private fun initialize(call: MethodCall, result: Result) {
        if (isInitialized) {
            result.success(mapOf("success" to true, "engineType" to "MediaPlayer+SoundPool"))
            return
        }

        try {
            Log.d(TAG, "Initializing Native Audio Engine...")
            
            // Get audio manager
            audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
            
            // Create optimized SoundPool for SFX
            val audioAttributes = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_GAME)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()

            soundPool = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                SoundPool.Builder()
                    .setMaxStreams(MAX_STREAMS)
                    .setAudioAttributes(audioAttributes)
                    .build()
            } else {
                @Suppress("DEPRECATION")
                SoundPool(MAX_STREAMS, AudioManager.STREAM_MUSIC, 0)
            }

            // Set up SoundPool callbacks
            soundPool?.setOnLoadCompleteListener { _, soundId, status ->
                if (status == 0) {
                    engineScope.launch {
                        channel.invokeMethod("onTrackLoaded", mapOf("trackId" to findTrackIdBySoundId(soundId)))
                    }
                }
            }
            
            // Initialize Audio Focus Management (Best Practice)
            setupAudioFocus()

            isInitialized = true
            
            Log.d(TAG, "Native Audio Engine initialized successfully - Hybrid MediaPlayer+SoundPool")
            
            result.success(mapOf(
                "success" to true,
                "engineType" to "MediaPlayer+SoundPool",
                "maxStreams" to MAX_STREAMS
            ))
            
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize audio engine", e)
            result.success(mapOf(
                "success" to false,
                "error" to e.message
            ))
        }
    }

    private fun registerTrack(call: MethodCall, result: Result) {
        if (!isInitialized) {
            result.success(false)
            return
        }

        try {
            val trackMap = call.argument<Map<String, Any>>("track") ?: return result.success(false)
            val audioData = call.argument<ByteArray>("audioData") ?: return result.success(false)
            
            val trackId = trackMap["id"] as String
            val type = trackMap["type"] as String
            val volume = (trackMap["volume"] as Double).toFloat()
            val loop = trackMap["loop"] as Boolean
            val priority = trackMap["priority"] as Int
            
            // No need to store track data anymore - direct processing
            
            when (type) {
                "sfx" -> {
                    // Load into SoundPool for low-latency playback
                    // Create a temporary file for SoundPool loading
                    val tempFile = createTempFile("audio_", ".tmp").toFile()
                    try {
                        tempFile.writeBytes(audioData)
                        val soundId = soundPool?.load(tempFile.absolutePath, priority)
                        if (soundId != null && soundId > 0) {
                            soundMap[trackId] = soundId
                            Log.d(TAG, "SFX track registered: $trackId (soundId: $soundId)")
                            result.success(true)
                        } else {
                            Log.e(TAG, "Failed to load SFX track: $trackId")
                            result.success(false)
                        }
                    } finally {
                        // Clean up temp file
                        tempFile.delete()
                    }
                }
                "music" -> {
                    // CRITICAL FIX: Cache music data for MediaPlayer (not SoundPool)
                    // SoundPool causes automatic stops for long music tracks
                    musicAssets[trackId] = audioData
                    Log.d(TAG, "Music track cached for MediaPlayer: $trackId (${audioData.size} bytes)")
                    result.success(true)
                }
                else -> {
                    Log.w(TAG, "Unknown track type: $type")
                    result.success(false)
                }
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "Error registering track", e)
            result.success(false)
        }
    }

    private fun playSFX(call: MethodCall, result: Result) {
        if (!isInitialized) {
            result.success(false)
            return
        }

        try {
            val trackId = call.argument<String>("trackId") ?: return result.success(false)
            val volume = (call.argument<Double>("volume") ?: 1.0).toFloat()
            
            val soundId = soundMap[trackId]
            if (soundId != null) {
                val finalVolume = volume * sfxVolume * masterVolume
                val streamId = soundPool?.play(soundId, finalVolume, finalVolume, 1, 0, 1.0f)
                
                if (streamId != null && streamId > 0) {
                    activeStreams[streamId] = trackId
                    activeSounds++
                    
                    // Notify Dart side
                    engineScope.launch {
                        channel.invokeMethod("onTrackStarted", mapOf("trackId" to trackId))
                    }
                    
                    result.success(true)
                } else {
                    result.success(false)
                }
            } else {
                Log.w(TAG, "SFX track not found: $trackId")
                result.success(false)
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "Error playing SFX", e)
            result.success(false)
        }
    }

    private fun playMusic(call: MethodCall, result: Result) {
        if (!isInitialized) {
            result.success(false)
            return
        }

        try {
            val trackId = call.argument<String>("trackId") ?: return result.success(false)
            val volume = (call.argument<Double>("volume") ?: 1.0).toFloat()
            val loop = call.argument<Boolean>("loop") ?: true
            
            // Request audio focus before playing music
            if (!requestAudioFocus()) {
                Log.w(TAG, "Could not gain audio focus for music playback")
                result.success(false)
                return
            }
            
            // Stop current music if playing
            stopMusicInternal()
            
            // ULTIMATE FIX: Use MediaPlayer for music (industry standard)
            // SoundPool automatically stops long music tracks - this is the root cause!
            val musicData = musicAssets[trackId]
            if (musicData != null) {
                try {
                    // Create temporary file for MediaPlayer
                    val tempFile = createTempFile("music_", ".mp3").toFile()
                    tempFile.writeBytes(musicData)
                    
                    // Initialize MediaPlayer with proper settings
                    musicPlayer = MediaPlayer().apply {
                        setDataSource(tempFile.absolutePath)
                        setAudioAttributes(
                            AudioAttributes.Builder()
                                .setUsage(AudioAttributes.USAGE_GAME)
                                .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                                .build()
                        )
                        isLooping = loop
                        setVolume(volume * musicVolume * masterVolume, volume * musicVolume * masterVolume)
                        
                        // Set up completion listener
                        setOnCompletionListener { 
                            if (!isLooping) {
                                isMusicPlaying = false
                                currentMusicTrackId = null
                            }
                        }
                        
                        // Set up error listener
                        setOnErrorListener { _, what, extra ->
                            Log.e(TAG, "MediaPlayer error: what=$what, extra=$extra")
                            isMusicPlaying = false
                            currentMusicTrackId = null
                            false
                        }
                        
                        // Prepare and start
                        prepareAsync()
                        setOnPreparedListener { mediaPlayer ->
                            mediaPlayer.start()
                            currentMusicTrackId = trackId
                            isMusicPlaying = true
                            
                            // Clean up temp file
                            tempFile.delete()
                            
                            Log.d(TAG, "Music started with MediaPlayer: $trackId (seamless looping: $loop)")
                        }
                    }
                    
                    result.success(true)
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to create MediaPlayer for: $trackId", e)
                    result.success(false)
                }
            } else {
                Log.w(TAG, "Music track not cached: $trackId")
                result.success(false)
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "Error playing music", e)
            result.success(false)
        }
    }


    private fun stopMusic(result: Result) {
        stopMusicInternal()
        result.success(true)
    }

    private fun stopMusicInternal() {
        try {
            // Stop MediaPlayer if playing
            musicPlayer?.let { player ->
                if (player.isPlaying) {
                    player.stop()
                }
                player.release()
                musicPlayer = null
            }
            
            currentMusicTrackId = null
            isMusicPlaying = false
            
            // Notify Dart side
            engineScope.launch {
                channel.invokeMethod("onMusicStopped", mapOf<String, Any>())
            }
            
            // Release audio focus when music stops
            abandonAudioFocus()
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping music", e)
        }
    }

    private fun pauseMusic(result: Result) {
        try {
            musicPlayer?.let { player ->
                if (player.isPlaying) {
                    player.pause()
                    Log.d(TAG, "Music paused")
                }
            }
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Error pausing music", e)
            result.success(false)
        }
    }

    private fun resumeMusic(result: Result) {
        try {
            musicPlayer?.let { player ->
                if (!player.isPlaying) {
                    player.start()
                    Log.d(TAG, "Music resumed")
                }
            }
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Error resuming music", e)
            result.success(false)
        }
    }

    private fun setMasterVolume(call: MethodCall, result: Result) {
        try {
            val volume = (call.argument<Double>("volume") ?: 1.0).toFloat()
            masterVolume = volume.coerceIn(0.0f, 1.0f)
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Error setting master volume", e)
            result.success(false)
        }
    }

    private fun getStats(result: Result) {
        try {
            val stats = mapOf(
                "activeSounds" to activeSounds,
                "loadedTracks" to soundMap.size,
                "musicAssets" to musicAssets.size,
                "masterVolume" to masterVolume,
                "isInitialized" to isInitialized
            )
            result.success(stats)
        } catch (e: Exception) {
            Log.e(TAG, "Error getting stats", e)
            result.success(emptyMap<String, Any>())
        }
    }

    private fun dispose(result: Result) {
        try {
            isInitialized = false
            
            // Stop and release music
            stopMusicInternal()
            
            // Release SoundPool
            soundPool?.release()
            soundPool = null
            
            // Clear data structures
            soundMap.clear()
            musicAssets.clear()
            activeStreams.clear()
            
            // Cancel coroutines
            engineScope.cancel()
            
            Log.d(TAG, "Native Audio Engine disposed")
            result.success(null)
            
        } catch (e: Exception) {
            Log.e(TAG, "Error disposing audio engine", e)
            result.success(null)
        }
    }

    // calculateEngineLatency function removed - not needed with MediaPlayer

    private fun findTrackIdBySoundId(soundId: Int): String? {
        return soundMap.entries.find { it.value == soundId }?.key
    }
    
    // ==================== AUDIO FOCUS MANAGEMENT ====================
    // Best practice for Android audio apps to prevent conflicts
    
    private fun setupAudioFocus() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val audioAttributes = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_GAME)
                .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                .build()
                
            audioFocusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
                .setAudioAttributes(audioAttributes)
                .setAcceptsDelayedFocusGain(true)
                .setOnAudioFocusChangeListener(audioFocusChangeListener)
                .build()
        }
    }
    
    private fun requestAudioFocus(): Boolean {
        return try {
            val result = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                audioFocusRequest?.let { request ->
                    audioManager?.requestAudioFocus(request)
                } ?: AudioManager.AUDIOFOCUS_REQUEST_FAILED
            } else {
                @Suppress("DEPRECATION")
                audioManager?.requestAudioFocus(
                    audioFocusChangeListener,
                    AudioManager.STREAM_MUSIC,
                    AudioManager.AUDIOFOCUS_GAIN
                ) ?: AudioManager.AUDIOFOCUS_REQUEST_FAILED
            }
            
            hasAudioFocus = result == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
            Log.d(TAG, "Audio focus request result: $result")
            hasAudioFocus
        } catch (e: Exception) {
            Log.e(TAG, "Error requesting audio focus", e)
            false
        }
    }
    
    private fun abandonAudioFocus() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                audioFocusRequest?.let { request ->
                    audioManager?.abandonAudioFocusRequest(request)
                }
            } else {
                @Suppress("DEPRECATION")
                audioManager?.abandonAudioFocus(audioFocusChangeListener)
            }
            hasAudioFocus = false
            Log.d(TAG, "Audio focus abandoned")
        } catch (e: Exception) {
            Log.e(TAG, "Error abandoning audio focus", e)
        }
    }
    
    private val audioFocusChangeListener = AudioManager.OnAudioFocusChangeListener { focusChange ->
        when (focusChange) {
            AudioManager.AUDIOFOCUS_GAIN -> {
                // Regained audio focus
                hasAudioFocus = true
                if (wasMusicPausedByFocusLoss && currentMusicTrackId != null) {
                    // Resume music that was paused by focus loss
                    musicPlayer?.let { player ->
                        if (!player.isPlaying) {
                            player.start()
                            wasMusicPausedByFocusLoss = false
                            Log.d(TAG, "Music resumed after regaining audio focus")
                        }
                    }
                }
            }
            AudioManager.AUDIOFOCUS_LOSS -> {
                // Lost audio focus permanently
                hasAudioFocus = false
                if (isMusicPlaying) {
                    stopMusicInternal()
                    Log.d(TAG, "Music stopped due to permanent audio focus loss")
                }
            }
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT -> {
                // Lost audio focus temporarily
                hasAudioFocus = false
                if (isMusicPlaying) {
                    musicPlayer?.let { player ->
                        if (player.isPlaying) {
                            player.pause()
                            wasMusicPausedByFocusLoss = true
                            Log.d(TAG, "Music paused due to transient audio focus loss")
                        }
                    }
                }
            }
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK -> {
                // Lost audio focus but can duck (lower volume)
                // For games, we typically pause instead of ducking
                if (isMusicPlaying) {
                    musicPlayer?.let { player ->
                        if (player.isPlaying) {
                            player.pause()
                            wasMusicPausedByFocusLoss = true
                            Log.d(TAG, "Music paused due to transient audio focus loss (ducking)")
                        }
                    }
                }
            }
        }
    }
    
    // ==================== END OF NATIVE AUDIO ENGINE ====================
    
}
