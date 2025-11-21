import Foundation
import AVFoundation
import Flutter

/**
 * Native Audio Engine for FlappyJet iOS - AAA Mobile Game Audio
 * 
 * Features:
 * - Ultra-low latency audio using AVAudioEngine
 * - Professional audio mixing and effects
 * - Zero MediaPlayer crashes (no AVPlayer dependency for SFX)
 * - Optimized for mobile game performance
 * - Support for iOS 12.0+
 */
@available(iOS 12.0, *)
class NativeAudioEngine: NSObject, FlutterPlugin {
    
    private static let channelName = "flappyjet.audio.native"
    private var channel: FlutterMethodChannel?
    
    // Audio engine components
    private var audioEngine: AVAudioEngine?
    private var audioPlayerNode: AVAudioPlayerNode?
    private var audioMixer: AVAudioMixerNode?
    
    // Track management
    private var soundBuffers: [String: AVAudioPCMBuffer] = [:]
    private var trackData: [String: AudioTrackData] = [:]
    private var activePlayers: [String: AVAudioPlayerNode] = [:]
    
    // Engine state
    private var isInitialized = false
    private var masterVolume: Float = 1.0
    private var musicVolume: Float = 1.0
    private var sfxVolume: Float = 1.0
    
    // Performance monitoring
    private var engineLatency: Double = 0.0
    private var activeSounds = 0
    
    struct AudioTrackData {
        let id: String
        let type: String
        let volume: Float
        let loop: Bool
        let priority: Int
        let audioData: Data
    }
    
    // MARK: - Flutter Plugin Registration
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger())
        let instance = NativeAudioEngine()
        instance.channel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    // MARK: - Flutter Method Channel Handler
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            initialize(call: call, result: result)
        case "registerTrack":
            registerTrack(call: call, result: result)
        case "playSFX":
            playSFX(call: call, result: result)
        case "playMusic":
            playMusic(call: call, result: result)
        case "stopMusic":
            stopMusic(result: result)
        case "pauseMusic":
            pauseMusic(result: result)
        case "resumeMusic":
            resumeMusic(result: result)
        case "setMasterVolume":
            setMasterVolume(call: call, result: result)
        case "getStats":
            getStats(result: result)
        case "dispose":
            dispose(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - Audio Engine Implementation
    
    private func initialize(call: FlutterMethodCall, result: @escaping FlutterResult) {
        if isInitialized {
            result(["success": true, "latency": engineLatency])
            return
        }
        
        do {
            print("🎵 Initializing Native Audio Engine for iOS...")
            
            // Configure audio session for games
            let audioSession = AVAudioSession.sharedInstance()
            // Use .playback category to ensure audio plays even with silent mode switch
            // .duckOthers will lower other audio when game sounds play
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers, .duckOthers])
            try audioSession.setActive(true)
            
            // Create audio engine
            audioEngine = AVAudioEngine()
            guard let engine = audioEngine else {
                throw NSError(domain: "AudioEngine", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create audio engine"])
            }
            
            // Get main mixer node
            audioMixer = engine.mainMixerNode
            
            // Create player node for music
            audioPlayerNode = AVAudioPlayerNode()
            guard let playerNode = audioPlayerNode else {
                throw NSError(domain: "AudioEngine", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to create player node"])
            }
            
            // Attach nodes to engine
            engine.attach(playerNode)
            
            // Connect nodes
            engine.connect(playerNode, to: audioMixer!, format: nil)
            
            // Calculate latency
            engineLatency = calculateEngineLatency()
            
            // Start the engine
            try engine.start()
            
            isInitialized = true
            
            print("🎵 ✅ Native Audio Engine initialized successfully")
            print("🎵 📊 Engine latency: \(String(format: "%.1f", engineLatency))ms")
            
            result([
                "success": true,
                "latency": engineLatency,
                "sampleRate": engine.mainMixerNode.outputFormat(forBus: 0).sampleRate
            ])
            
        } catch {
            print("🎵 ❌ Failed to initialize audio engine: \(error)")
            result([
                "success": false,
                "error": error.localizedDescription
            ])
        }
    }
    
    private func registerTrack(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard isInitialized else {
            result(false)
            return
        }
        
        guard let args = call.arguments as? [String: Any],
              let trackMap = args["track"] as? [String: Any],
              let audioData = args["audioData"] as? FlutterStandardTypedData else {
            result(false)
            return
        }
        
        guard let trackId = trackMap["id"] as? String,
              let type = trackMap["type"] as? String,
              let volume = trackMap["volume"] as? Double,
              let loop = trackMap["loop"] as? Bool,
              let priority = trackMap["priority"] as? Int else {
            result(false)
            return
        }
        
        do {
            // Store track data
            let trackData = AudioTrackData(
                id: trackId,
                type: type,
                volume: Float(volume),
                loop: loop,
                priority: priority,
                audioData: audioData.data
            )
            self.trackData[trackId] = trackData
            
            // Create audio buffer from data
            let audioBuffer = try createAudioBuffer(from: audioData.data)
            soundBuffers[trackId] = audioBuffer
            
            print("🎵 ✅ Track registered: \(trackId)")
            
            // Notify Dart side
            DispatchQueue.main.async {
                self.channel?.invokeMethod("onTrackLoaded", arguments: ["trackId": trackId])
            }
            
            result(true)
            
        } catch {
            print("🎵 ❌ Error registering track \(trackId): \(error)")
            result(false)
        }
    }
    
    private func playSFX(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard isInitialized,
              let args = call.arguments as? [String: Any],
              let trackId = args["trackId"] as? String,
              let volume = args["volume"] as? Double else {
            result(false)
            return
        }
        
        guard let buffer = soundBuffers[trackId],
              let trackData = self.trackData[trackId] else {
            print("🎵 ❌ SFX track not found: \(trackId)")
            result(false)
            return
        }
        
        do {
            // Create a new player node for this SFX
            let playerNode = AVAudioPlayerNode()
            audioEngine?.attach(playerNode)
            audioEngine?.connect(playerNode, to: audioMixer!, format: buffer.format)
            
            // Calculate final volume
            let finalVolume = Float(volume) * trackData.volume * sfxVolume * masterVolume
            playerNode.volume = finalVolume
            
            // Schedule and play the buffer
            playerNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: { [weak self] in
                DispatchQueue.main.async {
                    // Clean up the player node
                    playerNode.stop()
                    self?.audioEngine?.detach(playerNode)
                    
                    // Update active sounds count
                    if self?.activeSounds ?? 0 > 0 {
                        self?.activeSounds -= 1
                    }
                    
                    // Notify Dart side
                    self?.channel?.invokeMethod("onTrackStopped", arguments: ["trackId": trackId])
                }
            })
            
            playerNode.play()
            activeSounds += 1
            
            // Notify Dart side
            DispatchQueue.main.async {
                self.channel?.invokeMethod("onTrackStarted", arguments: ["trackId": trackId])
            }
            
            result(true)
            
        } catch {
            print("🎵 ❌ Error playing SFX \(trackId): \(error)")
            result(false)
        }
    }
    
    private func playMusic(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard isInitialized,
              let args = call.arguments as? [String: Any],
              let trackId = args["trackId"] as? String,
              let volume = args["volume"] as? Double,
              let loop = args["loop"] as? Bool else {
            result(false)
            return
        }
        
        guard let buffer = soundBuffers[trackId],
              let trackData = self.trackData[trackId],
              let playerNode = audioPlayerNode else {
            print("🎵 ❌ Music track not found: \(trackId)")
            result(false)
            return
        }
        
        do {
            // Stop current music
            stopMusicInternal()
            
            // Calculate final volume
            let finalVolume = Float(volume) * trackData.volume * musicVolume * masterVolume
            playerNode.volume = finalVolume
            
            // Schedule buffer with looping if needed
            let options: AVAudioPlayerNodeBufferOptions = loop ? [.loops] : []
            playerNode.scheduleBuffer(buffer, at: nil, options: options, completionHandler: nil)
            
            // Start playback
            playerNode.play()
            
            print("🎵 🎼 Music started: \(trackId)")
            result(true)
            
        } catch {
            print("🎵 ❌ Error playing music \(trackId): \(error)")
            result(false)
        }
    }
    
    private func stopMusic(result: @escaping FlutterResult) {
        stopMusicInternal()
        result(true)
    }
    
    private func stopMusicInternal() {
        audioPlayerNode?.stop()
        print("🎵 🛑 Music stopped")
    }
    
    private func pauseMusic(result: @escaping FlutterResult) {
        audioPlayerNode?.pause()
        print("🎵 ⏸️ Music paused")
        result(true)
    }
    
    private func resumeMusic(result: @escaping FlutterResult) {
        audioPlayerNode?.play()
        print("🎵 ▶️ Music resumed")
        result(true)
    }
    
    private func setMasterVolume(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let volume = args["volume"] as? Double else {
            result(false)
            return
        }
        
        masterVolume = Float(max(0.0, min(1.0, volume)))
        result(true)
    }
    
    private func getStats(result: @escaping FlutterResult) {
        let stats: [String: Any] = [
            "activeSounds": activeSounds,
            "loadedTracks": soundBuffers.count,
            "engineLatency": engineLatency,
            "masterVolume": masterVolume,
            "isInitialized": isInitialized
        ]
        result(stats)
    }
    
    private func dispose(result: @escaping FlutterResult) {
        isInitialized = false
        
        // Stop and clean up
        audioPlayerNode?.stop()
        audioEngine?.stop()
        
        // Clear data
        soundBuffers.removeAll()
        trackData.removeAll()
        activePlayers.removeAll()
        
        audioEngine = nil
        audioPlayerNode = nil
        audioMixer = nil
        
        print("🎵 🧹 Native Audio Engine disposed")
        result(nil)
    }
    
    // MARK: - Helper Methods
    
    private func createAudioBuffer(from data: Data) throws -> AVAudioPCMBuffer {
        // Create audio file from data
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try data.write(to: tempURL)
        
        defer {
            try? FileManager.default.removeItem(at: tempURL)
        }
        
        let audioFile = try AVAudioFile(forReading: tempURL)
        let format = audioFile.processingFormat
        let frameCount = UInt32(audioFile.length)
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            throw NSError(domain: "AudioBuffer", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create audio buffer"])
        }
        
        try audioFile.read(into: buffer)
        return buffer
    }
    
    private func calculateEngineLatency() -> Double {
        guard let engine = audioEngine else { return 20.0 }
        
        // Get the hardware sample rate and buffer duration
        let sampleRate = engine.mainMixerNode.outputFormat(forBus: 0).sampleRate
        let bufferDuration = AVAudioSession.sharedInstance().ioBufferDuration
        
        // Calculate approximate latency in milliseconds
        return bufferDuration * 1000.0
    }
}
