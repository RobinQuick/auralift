import Foundation

// MARK: - IntensityLevel

/// Training intensity level derived from velocity loss and rep cadence.
enum IntensityLevel: String {
    case low = "low"           // < 5% velocity loss
    case medium = "medium"     // 5-10% velocity loss
    case high = "high"         // 10-20% velocity loss
    case extreme = "extreme"   // > 20% velocity loss

    var displayName: String {
        rawValue.capitalized
    }
}

// MARK: - BPMSyncEngine

/// Tracks rep cadence and training intensity for audio synchronization.
/// Detects BPM from rep timestamps and maps fatigue to intensity levels.
/// Phase 10 will add music time-stretching via syncPlayback().
final class BPMSyncEngine: ServiceProtocol {

    // MARK: - Published State

    private(set) var currentBPM: Double = 0
    private(set) var currentIntensity: IntensityLevel = .low

    // MARK: - Callbacks (Phase 10 hooks)

    var onIntensityChanged: ((IntensityLevel) -> Void)?
    var onBPMChanged: ((Double) -> Void)?

    // MARK: - Internal State

    private var repTimestamps: [TimeInterval] = []
    private let maxWindowSize = 20

    // MARK: - ServiceProtocol

    var isAvailable: Bool { true }

    func initialize() async throws {
        // Phase 10: Initialize audio time-stretching engine
    }

    // MARK: - Rep Tracking

    /// Records the current time as a rep completion timestamp.
    func recordRepTimestamp() {
        let timestamp = Date().timeIntervalSinceReferenceDate
        repTimestamps.append(timestamp)

        // Keep rolling window
        if repTimestamps.count > maxWindowSize {
            repTimestamps.removeFirst(repTimestamps.count - maxWindowSize)
        }

        let bpm = detectCadence(repTimestamps: repTimestamps)
        if bpm != currentBPM {
            currentBPM = bpm
            onBPMChanged?(bpm)
        }
    }

    // MARK: - Cadence Detection

    /// Calculates rep cadence in reps-per-minute from timestamps.
    /// Filters out intervals > 10s (rest pauses) and uses median for robustness.
    func detectCadence(repTimestamps: [TimeInterval]) -> Double {
        guard repTimestamps.count >= 2 else { return 0 }

        // Calculate inter-rep intervals
        var intervals: [TimeInterval] = []
        for i in 1..<repTimestamps.count {
            let interval = repTimestamps[i] - repTimestamps[i - 1]
            // Filter out rest pauses (> 10 seconds)
            if interval <= 10.0 && interval > 0.3 {
                intervals.append(interval)
            }
        }

        guard !intervals.isEmpty else { return 0 }

        // Use median for robustness against outliers
        let sorted = intervals.sorted()
        let medianInterval: TimeInterval
        if sorted.count % 2 == 0 {
            medianInterval = (sorted[sorted.count / 2 - 1] + sorted[sorted.count / 2]) / 2.0
        } else {
            medianInterval = sorted[sorted.count / 2]
        }

        // Convert seconds/rep → reps/minute
        return 60.0 / medianInterval
    }

    // MARK: - Intensity

    /// Maps velocity loss percentage to an intensity level.
    func updateIntensity(velocityLossPercent: Double) {
        let newIntensity: IntensityLevel
        if velocityLossPercent > 20 {
            newIntensity = .extreme
        } else if velocityLossPercent > 10 {
            newIntensity = .high
        } else if velocityLossPercent > 5 {
            newIntensity = .medium
        } else {
            newIntensity = .low
        }

        if newIntensity != currentIntensity {
            currentIntensity = newIntensity
            onIntensityChanged?(newIntensity)
        }
    }

    // MARK: - Reset

    /// Resets all state for a new session.
    func reset() {
        repTimestamps = []
        currentBPM = 0
        currentIntensity = .low
    }

    // MARK: - Phase 10 Stub

    /// Adjusts music playback rate to match a target BPM.
    /// Phase 10: Will apply time-stretch ratio = targetBPM / trackBPM
    /// using AVAudioEngine rate adjustment on the music player node.
    func syncPlayback(to targetBPM: Double) {
        // Phase 10: Apply time-stretch ratio to audio engine
        // ratio = targetBPM / originalTrackBPM
        // playerNode.rate = Float(ratio) clamped to 0.5...2.0
    }
}
