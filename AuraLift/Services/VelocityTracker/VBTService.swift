import Foundation
import CoreGraphics

// MARK: - VelocityReading

/// A single velocity measurement from one frame transition.
struct VelocityReading {
    let timestamp: TimeInterval
    let displacement: Double   // meters
    let velocity: Double       // m/s (displacement / dt)
}

// MARK: - RepVelocityResult

/// Velocity metrics for a completed rep.
struct RepVelocityResult {
    let meanConcentricVelocity: Double   // m/s
    let peakConcentricVelocity: Double   // m/s
    let meanEccentricVelocity: Double    // m/s
}

// MARK: - FatigueStatus

/// Current fatigue assessment based on velocity trend.
struct FatigueStatus {
    let velocityLossPercent: Double  // 0.0 to 1.0
    let shouldAutoStop: Bool
    let repsToFailure: Int?         // estimated reps remaining (nil if unknown)
}

// MARK: - VBTService

/// Velocity-Based Training service that tracks barbell/body velocity in real time.
/// Uses pose frame deltas to compute concentric and eccentric velocities,
/// calibrated against the user's known height for real-world measurements.
final class VBTService: ObservableObject, ServiceProtocol {

    var isAvailable: Bool { true }

    func initialize() async throws {}

    // MARK: - Published State

    @Published var currentVelocity: Double = 0         // Smoothed instantaneous velocity (m/s)
    @Published var currentConcentricVelocity: Double = 0  // Mean velocity during current concentric phase
    @Published var peakConcentricVelocity: Double = 0     // Peak during current concentric phase

    // MARK: - Configuration

    /// Joint to track for velocity computation (exercise-specific).
    private var trackingJoint: JointName = .leftWrist

    /// Calibration: meters per Vision coordinate unit.
    /// Computed from user height and detected body height in Vision coords.
    private var metersPerVisionUnit: Double = 2.0  // Default estimate (~2m frame height)

    /// Velocity loss threshold for auto-stop recommendation.
    private let autoStopThreshold: Double = 0.20  // 20% velocity loss

    // MARK: - Tracking State

    private var previousPosition: CGPoint?
    private var previousTimestamp: TimeInterval = 0

    /// Raw velocity readings for smoothing.
    private var velocityBuffer: [Double] = []
    private let smoothingWindowSize = 5

    /// Concentric phase velocity readings (reset each rep).
    private var concentricReadings: [VelocityReading] = []

    /// Eccentric phase velocity readings (reset each rep).
    private var eccentricReadings: [VelocityReading] = []

    /// Baseline velocity from first rep of set (for fatigue detection).
    private var baselineConcentricVelocity: Double?

    /// All rep velocities in current set (for trend analysis).
    private var setVelocities: [Double] = []

    /// Current movement phase from RepCounter.
    private var currentPhase: RepPhase = .idle

    /// Session-wide peak velocity.
    private(set) var sessionPeakVelocity: Double = 0

    // MARK: - Joint Mapping

    /// Maps exercise names to the joint best representing bar/load path.
    private static let exerciseTrackingJoints: [String: JointName] = [
        "Barbell Back Squat": .root,
        "Barbell Bench Press": .leftWrist,
        "Overhead Press": .leftWrist,
        "Barbell Row": .leftWrist,
        "Romanian Deadlift": .leftWrist,
        "Conventional Deadlift": .leftWrist,
        "Pull-Up": .neck,
        "Lat Pulldown": .leftWrist,
        "Hip Thrust": .leftHip,
    ]

    /// Active resistance profile modifier (1.0 = linear, affects velocity weighting).
    private var resistanceProfileModifier: Double = 1.0

    /// Active starting resistance (tare weight in kg, added to user-set weight for LP).
    private(set) var activeStartingResistance: Double = 0

    // MARK: - Configuration

    /// Configures VBT tracking for a specific exercise.
    func configure(for exerciseName: String) {
        trackingJoint = Self.exerciseTrackingJoints[exerciseName] ?? .leftWrist
        resetForNewSet()
    }

    /// Configures VBT for a machine's resistance profile.
    /// - Parameters:
    ///   - resistanceProfile: "ascending", "descending", or "linear"
    ///   - startingResistance: Tare weight of the machine (empty lever arms) in kg
    func configureMachine(resistanceProfile: String?, startingResistance: Double) {
        activeStartingResistance = startingResistance
        switch resistanceProfile?.lowercased() {
        case "ascending":
            // Machine gets heavier at lockout — velocity naturally decreases at top
            // Adjust expected velocity down by 10% to not penalize
            resistanceProfileModifier = 0.90
        case "descending":
            // Machine gets lighter at lockout — velocity naturally increases at top
            // Adjust expected velocity up by 10% to not inflate scores
            resistanceProfileModifier = 1.10
        default:
            resistanceProfileModifier = 1.0
        }
    }

    /// Calibrates the Vision→meters conversion using the user's height
    /// and their detected body height in Vision coordinates.
    func calibrate(userHeightCm: Double, bodyHeightVisionUnits: Double) {
        guard bodyHeightVisionUnits > 0.05 else { return }
        metersPerVisionUnit = (userHeightCm / 100.0) / bodyHeightVisionUnits
    }

    /// Calibrates using a default assumption if no morpho scan data is available.
    func calibrateDefault(userHeightCm: Double) {
        // Assume the user occupies ~60% of the vertical frame at typical workout distance
        metersPerVisionUnit = (userHeightCm / 100.0) / 0.6
    }

    // MARK: - Phase Tracking

    /// Updates the current phase (called by WorkoutViewModel when RepCounter phase changes).
    func updatePhase(_ phase: RepPhase) {
        let previousPhase = currentPhase
        currentPhase = phase

        // Phase transitions: reset per-phase tracking
        if phase == .descending && previousPhase != .descending {
            eccentricReadings = []
        }
        if phase == .ascending && previousPhase != .ascending {
            concentricReadings = []
        }
    }

    // MARK: - Frame Processing

    /// Processes a pose frame to compute velocity of the tracked joint.
    func processFrame(_ frame: PoseFrame) {
        guard let keypoint = frame[trackingJoint],
              keypoint.confidence >= 0.3 else { return }

        let position = keypoint.position
        let timestamp = frame.timestamp

        defer {
            previousPosition = position
            previousTimestamp = timestamp
        }

        guard let prevPos = previousPosition, previousTimestamp > 0 else { return }

        let dt = timestamp - previousTimestamp
        guard dt > 0 && dt < 0.5 else { return } // Skip if >500ms gap (likely frame drop)

        // Compute vertical displacement in Vision coords → meters
        // Most barbell exercises move primarily vertically; horizontal jitter is noise
        let dy = Double(position.y - prevPos.y) * metersPerVisionUnit
        let displacement = abs(dy)
        let rawVelocity = displacement / dt

        // Apply resistance profile modifier to normalize velocity
        let adjustedVelocity = rawVelocity * resistanceProfileModifier

        // Smooth velocity
        velocityBuffer.append(adjustedVelocity)
        if velocityBuffer.count > smoothingWindowSize {
            velocityBuffer.removeFirst()
        }
        let smoothedVelocity = velocityBuffer.reduce(0, +) / Double(velocityBuffer.count)

        let reading = VelocityReading(
            timestamp: timestamp,
            displacement: displacement,
            velocity: smoothedVelocity
        )

        // Track per-phase readings
        switch currentPhase {
        case .ascending:
            concentricReadings.append(reading)
            let concentricMean = concentricReadings.map(\.velocity).reduce(0, +) / Double(concentricReadings.count)
            let concentricPeak = concentricReadings.map(\.velocity).max() ?? 0

            DispatchQueue.main.async { [weak self] in
                self?.currentConcentricVelocity = concentricMean
                self?.peakConcentricVelocity = concentricPeak
            }

        case .descending:
            eccentricReadings.append(reading)

        default:
            break
        }

        DispatchQueue.main.async { [weak self] in
            self?.currentVelocity = smoothedVelocity
        }
    }

    // MARK: - Rep Completion

    /// Returns velocity metrics for the just-completed rep and updates fatigue tracking.
    func completeRep() -> RepVelocityResult {
        let meanConcentric = concentricReadings.isEmpty ? 0 :
            concentricReadings.map(\.velocity).reduce(0, +) / Double(concentricReadings.count)
        let peakConcentric = concentricReadings.map(\.velocity).max() ?? 0
        let meanEccentric = eccentricReadings.isEmpty ? 0 :
            eccentricReadings.map(\.velocity).reduce(0, +) / Double(eccentricReadings.count)

        // Set baseline from first rep
        if baselineConcentricVelocity == nil && meanConcentric > 0 {
            baselineConcentricVelocity = meanConcentric
        }

        // Track for fatigue analysis
        setVelocities.append(meanConcentric)

        // Update session peak
        if peakConcentric > sessionPeakVelocity {
            sessionPeakVelocity = peakConcentric
        }

        // Reset per-rep tracking
        concentricReadings = []
        eccentricReadings = []

        return RepVelocityResult(
            meanConcentricVelocity: meanConcentric,
            peakConcentricVelocity: peakConcentric,
            meanEccentricVelocity: meanEccentric
        )
    }

    // MARK: - Fatigue Detection

    /// Returns the current fatigue status based on velocity trend across the set.
    func fatigueStatus() -> FatigueStatus {
        guard let baseline = baselineConcentricVelocity,
              baseline > 0,
              let lastVelocity = setVelocities.last else {
            return FatigueStatus(velocityLossPercent: 0, shouldAutoStop: false, repsToFailure: nil)
        }

        let loss = max(0, (baseline - lastVelocity) / baseline)
        let shouldStop = loss >= autoStopThreshold

        // Estimate reps to failure using linear velocity decay model
        var repsRemaining: Int? = nil
        if setVelocities.count >= 2,
           let firstVelocity = setVelocities.first,
           let lastVelocity2 = setVelocities.last {
            let velocityPerRep = (firstVelocity - lastVelocity2) / Double(setVelocities.count - 1)
            if velocityPerRep > 0 {
                // Failure velocity ≈ 30% of baseline (minimal meaningful movement speed)
                let failureVelocity = baseline * 0.3
                let repsLeft = (lastVelocity - failureVelocity) / velocityPerRep
                repsRemaining = max(0, Int(repsLeft))
            }
        }

        return FatigueStatus(
            velocityLossPercent: loss,
            shouldAutoStop: shouldStop,
            repsToFailure: repsRemaining
        )
    }

    // MARK: - Reset

    /// Resets tracking for a new set.
    func resetForNewSet() {
        previousPosition = nil
        previousTimestamp = 0
        velocityBuffer = []
        concentricReadings = []
        eccentricReadings = []
        baselineConcentricVelocity = nil
        setVelocities = []
        currentPhase = .idle

        DispatchQueue.main.async { [weak self] in
            self?.currentVelocity = 0
            self?.currentConcentricVelocity = 0
            self?.peakConcentricVelocity = 0
        }
    }

    /// Resets all state for a new session.
    func resetForNewSession() {
        resetForNewSet()
        sessionPeakVelocity = 0
        resistanceProfileModifier = 1.0
        activeStartingResistance = 0
    }
}
