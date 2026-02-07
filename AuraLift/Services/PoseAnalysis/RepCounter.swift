import Foundation
import Combine

// MARK: - RepPhase

/// Tracks where the user is in the rep cycle.
enum RepPhase {
    case idle           // No movement detected
    case descending     // Eccentric phase (angle decreasing toward bottom)
    case atBottom       // Reached bottom of rep
    case ascending      // Concentric phase (angle increasing toward top)
    case atTop          // Reached top / lockout
}

// MARK: - RepEvent

/// Emitted when a rep is completed.
struct RepEvent {
    let repNumber: Int
    let formScore: Double
    let romDegrees: Double
    let concentricDuration: TimeInterval
    let eccentricDuration: TimeInterval
    let barPathDeviation: Double
    let issues: [FormIssue]
    let meanConcentricVelocity: Double   // m/s (from VBTService)
    let peakConcentricVelocity: Double   // m/s (from VBTService)
}

// MARK: - RepCounter

/// Detects exercise repetitions from a stream of PoseFrames using
/// angle-based phase detection (descending → bottom → ascending → top).
final class RepCounter: ObservableObject {

    // MARK: - Published State

    @Published var repCount: Int = 0
    @Published var currentPhase: RepPhase = .idle
    @Published var currentFormScore: Double = 0
    @Published var currentROM: Double = 0
    @Published var activeFormIssues: [FormIssue] = []

    // MARK: - Rep Callback

    var onRepCompleted: ((RepEvent) -> Void)?

    // MARK: - Configuration

    private var exerciseProfile: ExerciseFormProfile?
    private let formAnalyzer: FormAnalyzer
    private var vbtService: VBTService?

    // Thresholds
    private let phaseChangeThreshold: Double = 8.0  // Degrees of change to confirm phase transition
    private let bottomThresholdPercent: Double = 0.3 // Bottom 30% of ROM range
    private let topThresholdPercent: Double = 0.8    // Top 80% of ROM range

    // MARK: - Tracking State

    private var angleHistory: [Double] = []
    private var formScoresThisRep: [Double] = []
    private var romMinAngle: Double = 999
    private var romMaxAngle: Double = 0
    private var eccentricStartTime: TimeInterval = 0
    private var concentricStartTime: TimeInterval = 0
    private var issuesThisRep: [FormIssue] = []
    private var barPathDeviationThisRep: [Double] = []

    private let angleHistorySize = 5 // Smoothing window

    // MARK: - Init

    init(formAnalyzer: FormAnalyzer, vbtService: VBTService? = nil) {
        self.formAnalyzer = formAnalyzer
        self.vbtService = vbtService
    }

    // MARK: - Configuration

    /// Configures the rep counter for a specific exercise.
    func configure(for exerciseName: String) {
        exerciseProfile = FormAnalyzer.profiles[exerciseName]
        formAnalyzer.configure(for: exerciseName)
        reset()
    }

    /// Resets all counters (call between exercises or sets).
    func reset() {
        repCount = 0
        currentPhase = .idle
        currentFormScore = 0
        currentROM = 0
        angleHistory = []
        formScoresThisRep = []
        romMinAngle = 999
        romMaxAngle = 0
        eccentricStartTime = 0
        concentricStartTime = 0
        issuesThisRep = []
        barPathDeviationThisRep = []
        formAnalyzer.resetBarPath()
    }

    /// Resets per-set state (keeps rep count, resets bar path).
    func resetForNewSet() {
        formAnalyzer.resetBarPath()
    }

    // MARK: - Frame Processing

    /// Process a single pose frame for rep detection and form analysis.
    func processFrame(_ frame: PoseFrame) {
        guard let profile = exerciseProfile, frame.isValid else { return }

        // Get current tracking angle
        guard let currentAngle = frame.angle(
            vertex: profile.trackingAngleJoints.vertex,
            from: profile.trackingAngleJoints.from,
            to: profile.trackingAngleJoints.to
        ) else { return }

        // Run form analysis
        let result = formAnalyzer.analyze(frame)
        formScoresThisRep.append(result.score)
        currentFormScore = result.score
        currentROM = result.romDegrees
        activeFormIssues = result.issues

        // Collect issues
        for issue in result.issues where !issuesThisRep.contains(where: { $0.name == issue.name }) {
            issuesThisRep.append(issue)
        }
        barPathDeviationThisRep.append(result.barPathDeviation)

        // Smooth angle with history
        angleHistory.append(currentAngle)
        if angleHistory.count > angleHistorySize {
            angleHistory.removeFirst()
        }
        let smoothedAngle = angleHistory.reduce(0, +) / Double(angleHistory.count)

        // Track ROM
        romMinAngle = min(romMinAngle, smoothedAngle)
        romMaxAngle = max(romMaxAngle, smoothedAngle)

        // Determine expected direction
        let isTopHighAngle = profile.topAngle > profile.bottomAngle
        let angleRange = abs(profile.topAngle - profile.bottomAngle)
        let bottomZone = isTopHighAngle
            ? profile.bottomAngle + angleRange * bottomThresholdPercent
            : profile.topAngle + angleRange * (1 - bottomThresholdPercent)
        let topZone = isTopHighAngle
            ? profile.topAngle - angleRange * (1 - topThresholdPercent)
            : profile.bottomAngle - angleRange * topThresholdPercent

        // Feed VBTService for velocity tracking
        vbtService?.processFrame(frame)

        // Phase state machine
        updatePhase(
            angle: smoothedAngle,
            timestamp: frame.timestamp,
            isTopHighAngle: isTopHighAngle,
            bottomZone: bottomZone,
            topZone: topZone
        )
    }

    // MARK: - Phase State Machine

    private func updatePhase(
        angle: Double,
        timestamp: TimeInterval,
        isTopHighAngle: Bool,
        bottomZone: Double,
        topZone: Double
    ) {
        let isDescending = isTopHighAngle ? (angle < (angleHistory.first ?? angle)) : (angle > (angleHistory.first ?? angle))
        let isAscending = !isDescending

        let isInBottomZone = isTopHighAngle ? (angle <= bottomZone) : (angle >= bottomZone)
        let isInTopZone = isTopHighAngle ? (angle >= topZone) : (angle <= topZone)

        let previousPhase = currentPhase

        switch currentPhase {
        case .idle:
            if isInTopZone {
                currentPhase = .atTop
            }

        case .atTop:
            if isDescending && !isInTopZone {
                currentPhase = .descending
                eccentricStartTime = timestamp
                resetRepTracking()
            }

        case .descending:
            if isInBottomZone {
                currentPhase = .atBottom
            }

        case .atBottom:
            if isAscending && !isInBottomZone {
                currentPhase = .ascending
                concentricStartTime = timestamp
            }

        case .ascending:
            if isInTopZone {
                currentPhase = .atTop
                completeRep(timestamp: timestamp)
            }
        }

        // Notify VBTService of phase changes
        if currentPhase != previousPhase {
            vbtService?.updatePhase(currentPhase)
        }
    }

    // MARK: - Rep Completion

    private func completeRep(timestamp: TimeInterval) {
        repCount += 1

        let avgFormScore = formScoresThisRep.isEmpty ? 0 :
            formScoresThisRep.reduce(0, +) / Double(formScoresThisRep.count)
        let rom = romMaxAngle - romMinAngle
        let eccentricDuration = concentricStartTime > 0 ? concentricStartTime - eccentricStartTime : 0
        let concentricDuration = timestamp - concentricStartTime
        let avgBarPath = barPathDeviationThisRep.isEmpty ? 0 :
            barPathDeviationThisRep.reduce(0, +) / Double(barPathDeviationThisRep.count)

        // Get velocity data from VBTService
        let velocityResult = vbtService?.completeRep()

        let event = RepEvent(
            repNumber: repCount,
            formScore: avgFormScore,
            romDegrees: rom,
            concentricDuration: concentricDuration,
            eccentricDuration: eccentricDuration,
            barPathDeviation: avgBarPath,
            issues: issuesThisRep,
            meanConcentricVelocity: velocityResult?.meanConcentricVelocity ?? 0,
            peakConcentricVelocity: velocityResult?.peakConcentricVelocity ?? 0
        )

        onRepCompleted?(event)
    }

    private func resetRepTracking() {
        formScoresThisRep = []
        romMinAngle = 999
        romMaxAngle = 0
        issuesThisRep = []
        barPathDeviationThisRep = []
    }
}
