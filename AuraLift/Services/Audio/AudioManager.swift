import Foundation
import AVFoundation

// MARK: - SpeechPriority

/// Priority levels for voice announcements. Higher priority interrupts lower.
/// Safety priority is NEVER throttled.
enum SpeechPriority: Int, Comparable {
    case low = 0       // Rep completion
    case medium = 1    // Combo milestones
    case high = 2      // Set complete, rank up
    case safety = 3    // Form failure — always plays

    static func < (lhs: SpeechPriority, rhs: SpeechPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - SFXType

/// Procedurally generated sound effect types.
enum SFXType {
    case repComplete
    case comboTick
    case setComplete
    case rankUp
    case safetyAlert
    case personalRecord
}

// MARK: - VoiceConfig

/// Voice configuration for AVSpeechSynthesizer.
struct VoiceConfig {
    let voiceIdentifier: String?
    let pitch: Float     // 0.5 - 2.0 (1.0 default)
    let rate: Float      // 0.0 - 1.0 (AVSpeechUtteranceDefaultSpeechRate)

    static let esportAnnouncer = VoiceConfig(
        voiceIdentifier: "com.apple.voice.enhanced.en-US.Evan",
        pitch: 0.9,
        rate: 0.55
    )

    static let soberCoach = VoiceConfig(
        voiceIdentifier: "com.apple.voice.enhanced.en-US.Aaron",
        pitch: 1.0,
        rate: 0.50
    )

    static let spartanWarrior = VoiceConfig(
        voiceIdentifier: "com.apple.voice.enhanced.en-GB.Daniel",
        pitch: 0.8,
        rate: 0.52
    )
}

// MARK: - AudioManager

/// Manages AVSpeechSynthesizer for TTS voice lines and AVAudioEngine for procedural SFX.
/// Audio session configured to duck user's music automatically.
final class AudioManager: ObservableObject, ServiceProtocol {

    // MARK: - Published Settings

    @Published var masterVolume: Float {
        didSet { UserDefaults.standard.set(masterVolume, forKey: "audio.masterVolume") }
    }
    @Published var voiceVolume: Float {
        didSet { UserDefaults.standard.set(voiceVolume, forKey: "audio.voiceVolume") }
    }
    @Published var sfxVolume: Float {
        didSet { UserDefaults.standard.set(sfxVolume, forKey: "audio.sfxVolume") }
    }
    @Published var voiceEnabled: Bool {
        didSet { UserDefaults.standard.set(voiceEnabled, forKey: "audio.voiceEnabled") }
    }
    @Published var sfxEnabled: Bool {
        didSet { UserDefaults.standard.set(sfxEnabled, forKey: "audio.sfxEnabled") }
    }
    @Published var hapticsEnabled: Bool {
        didSet { UserDefaults.standard.set(hapticsEnabled, forKey: "audio.hapticsEnabled") }
    }

    // MARK: - Audio Engine

    private let synthesizer = AVSpeechSynthesizer()
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private let audioQueue = DispatchQueue(label: "com.aurea.audio", qos: .userInteractive)

    // MARK: - State

    private(set) var isAvailable: Bool = false
    private var currentPriority: SpeechPriority = .low

    // MARK: - Init

    init() {
        let defaults = UserDefaults.standard
        self.masterVolume = defaults.object(forKey: "audio.masterVolume") as? Float ?? 0.8
        self.voiceVolume = defaults.object(forKey: "audio.voiceVolume") as? Float ?? 0.8
        self.sfxVolume = defaults.object(forKey: "audio.sfxVolume") as? Float ?? 0.7
        self.voiceEnabled = defaults.object(forKey: "audio.voiceEnabled") as? Bool ?? true
        self.sfxEnabled = defaults.object(forKey: "audio.sfxEnabled") as? Bool ?? true
        self.hapticsEnabled = defaults.object(forKey: "audio.hapticsEnabled") as? Bool ?? true
    }

    // MARK: - ServiceProtocol

    func initialize() async throws {
        try configureAudioSession()
        setupAudioEngine()
        isAvailable = true
    }

    // MARK: - Audio Session

    private func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .voicePrompt, options: [.mixWithOthers, .duckOthers])
        try session.setActive(true)
    }

    // MARK: - Audio Engine Setup

    private func setupAudioEngine() {
        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        engine.attach(player)

        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1) else { return }
        engine.connect(player, to: engine.mainMixerNode, format: format)

        do {
            try engine.start()
            self.audioEngine = engine
            self.playerNode = player
        } catch {
            // Engine failed to start; SFX won't play but voice still works
        }
    }

    deinit {
        audioEngine?.stop()
        playerNode?.stop()
        synthesizer.stopSpeaking(at: .immediate)
    }

    // MARK: - Speech

    /// Speaks text using AVSpeechSynthesizer with priority-based interruption.
    /// Higher priority interrupts lower. Safety always plays.
    func speak(text: String, priority: SpeechPriority, voiceConfig: VoiceConfig) {
        guard voiceEnabled || priority == .safety else { return }

        audioQueue.async { [weak self] in
            guard let self else { return }

            // Priority interruption: higher or equal priority interrupts current
            if self.synthesizer.isSpeaking {
                if priority >= self.currentPriority {
                    self.synthesizer.stopSpeaking(at: .immediate)
                } else {
                    return // Lower priority, skip
                }
            }

            self.currentPriority = priority

            let utterance = AVSpeechUtterance(string: text)
            utterance.preUtteranceDelay = 0
            utterance.volume = self.masterVolume * self.voiceVolume

            if let identifier = voiceConfig.voiceIdentifier {
                utterance.voice = AVSpeechSynthesisVoice(identifier: identifier)
                    ?? AVSpeechSynthesisVoice(language: "en-US")
            } else {
                utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            }

            utterance.pitchMultiplier = voiceConfig.pitch
            utterance.rate = voiceConfig.rate

            self.synthesizer.speak(utterance)
        }
    }

    // MARK: - Procedural SFX

    /// Plays a procedurally generated sound effect (sine-wave based, no audio files).
    func playSFX(_ type: SFXType) {
        guard sfxEnabled else { return }
        guard let engine = audioEngine, let player = playerNode else { return }

        audioQueue.async { [weak self] in
            guard let self else { return }

            let sampleRate: Double = 44100
            let volume = self.masterVolume * self.sfxVolume
            let buffer: AVAudioPCMBuffer?

            switch type {
            case .repComplete:
                buffer = self.generateTone(frequency: 440, duration: 0.08, sampleRate: sampleRate, volume: volume)
            case .comboTick:
                buffer = self.generateSweep(startFreq: 660, endFreq: 880, duration: 0.12, sampleRate: sampleRate, volume: volume)
            case .setComplete:
                buffer = self.generateChord(frequencies: [261.6, 329.6, 392.0], duration: 0.3, sampleRate: sampleRate, volume: volume)
            case .rankUp:
                buffer = self.generateArpeggio(frequencies: [523.3, 659.3, 784.0, 1047], duration: 0.6, sampleRate: sampleRate, volume: volume)
            case .safetyAlert:
                buffer = self.generatePulsed(frequency: 300, duration: 0.4, pulseCount: 3, sampleRate: sampleRate, volume: volume)
            case .personalRecord:
                buffer = self.generateChord(frequencies: [261.6, 329.6, 392.0, 523.3], duration: 0.5, sampleRate: sampleRate, volume: volume)
            }

            guard let buffer else { return }

            if !engine.isRunning {
                try? engine.start()
            }

            if player.isPlaying {
                player.stop()
            }
            player.scheduleBuffer(buffer, completionHandler: nil)
            player.play()
        }
    }

    // MARK: - Stop All

    func stopAll() {
        audioQueue.async { [weak self] in
            self?.synthesizer.stopSpeaking(at: .immediate)
            self?.playerNode?.stop()
        }
    }

    // MARK: - Tone Generation

    private func generateTone(frequency: Double, duration: Double, sampleRate: Double, volume: Float) -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount

        guard let data = buffer.floatChannelData?[0] else { return buffer }

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let envelope = min(1.0, min(t / 0.005, (duration - t) / 0.01)) // Attack/release
            data[i] = Float(sin(2.0 * .pi * frequency * t) * envelope) * volume
        }
        return buffer
    }

    private func generateSweep(startFreq: Double, endFreq: Double, duration: Double, sampleRate: Double, volume: Float) -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount

        guard let data = buffer.floatChannelData?[0] else { return buffer }

        var phase: Double = 0
        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let progress = t / duration
            let freq = startFreq + (endFreq - startFreq) * progress
            let envelope = min(1.0, min(t / 0.005, (duration - t) / 0.01))
            data[i] = Float(sin(phase) * envelope) * volume
            phase += 2.0 * .pi * freq / sampleRate
        }
        return buffer
    }

    private func generateChord(frequencies: [Double], duration: Double, sampleRate: Double, volume: Float) -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount

        guard let data = buffer.floatChannelData?[0] else { return buffer }

        let scale = 1.0 / Double(frequencies.count)
        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let envelope = min(1.0, min(t / 0.01, (duration - t) / 0.05))
            var sample: Double = 0
            for freq in frequencies {
                sample += sin(2.0 * .pi * freq * t) * scale
            }
            data[i] = Float(sample * envelope) * volume
        }
        return buffer
    }

    private func generateArpeggio(frequencies: [Double], duration: Double, sampleRate: Double, volume: Float) -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount

        guard let data = buffer.floatChannelData?[0] else { return buffer }

        let noteCount = frequencies.count
        let noteDuration = duration / Double(noteCount)

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let noteIndex = min(Int(t / noteDuration), noteCount - 1)
            let noteT = t - Double(noteIndex) * noteDuration
            let envelope = min(1.0, min(noteT / 0.005, (noteDuration - noteT) / 0.02))
            data[i] = Float(sin(2.0 * .pi * frequencies[noteIndex] * noteT) * envelope) * volume
        }
        return buffer
    }

    private func generatePulsed(frequency: Double, duration: Double, pulseCount: Int, sampleRate: Double, volume: Float) -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount

        guard let data = buffer.floatChannelData?[0] else { return buffer }

        let pulseDuration = duration / Double(pulseCount * 2) // On/off cycle
        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let pulsePhase = t.truncatingRemainder(dividingBy: pulseDuration * 2)
            let isOn = pulsePhase < pulseDuration
            if isOn {
                let localT = pulsePhase
                let envelope = min(1.0, min(localT / 0.003, (pulseDuration - localT) / 0.01))
                data[i] = Float(sin(2.0 * .pi * frequency * t) * envelope) * volume
            } else {
                data[i] = 0
            }
        }
        return buffer
    }
}
